#!/usr/bin/env python3
"""
Purple Team Live Dashboard - backend (stdlib only).

- Hace tail -F de /var/ossec/logs/alerts/alerts.json (via `sudo -n tail`, o directo si ya es root).
- Expone SSE en /stream con cada alerta nueva (y replay del historial de esta sesion al conectar).
- Sirve index.html desde el mismo directorio en / .
- Escucha en 0.0.0.0:8080.
"""
import json
import os
import queue
import subprocess
import sys
import threading
import time
from collections import deque
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

ALERTS_FILE = os.environ.get("ALERTS_FILE", "/var/ossec/logs/alerts/alerts.json")
HOST = os.environ.get("HOST", "0.0.0.0")
PORT = int(os.environ.get("PORT", "8080"))
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
INDEX_HTML = os.path.join(BASE_DIR, "index.html")
HISTORY_MAX = 300
HEARTBEAT_SECS = 15

history = deque(maxlen=HISTORY_MAX)
clients = set()          # set[queue.Queue]
clients_lock = threading.Lock()
stats = {"alerts_seen": 0, "parse_errors": 0, "started": time.time(), "tail_restarts": 0}


def log(msg):
    print(time.strftime("%H:%M:%S"), msg, flush=True)


def compact(alert):
    """Extrae solo lo que el dashboard necesita."""
    rule = alert.get("rule", {}) or {}
    mitre = rule.get("mitre", {}) or {}
    ids = mitre.get("id") or []
    if isinstance(ids, str):
        ids = [ids]
    return {
        "id": alert.get("id"),
        "ts": alert.get("timestamp"),
        "rx": time.time(),
        "description": rule.get("description", ""),
        "level": rule.get("level", 0),
        "rule_id": rule.get("id"),
        "mitre": ids,
        "tactic": mitre.get("tactic") or [],
        "technique": mitre.get("technique") or [],
        "agent": (alert.get("agent") or {}).get("name", ""),
        "srcip": (alert.get("data") or {}).get("srcip", ""),
        "user": (alert.get("data") or {}).get("dstuser") or (alert.get("data") or {}).get("srcuser") or "",
    }


def broadcast(event):
    history.append(event)
    stats["alerts_seen"] += 1
    with clients_lock:
        dead = []
        for q in clients:
            try:
                q.put_nowait(event)
            except queue.Full:
                dead.append(q)
        for q in dead:
            clients.discard(q)


def tail_cmd():
    cmd = ["tail", "-n", "0", "-F", ALERTS_FILE]
    if os.geteuid() != 0:
        cmd = ["sudo", "-n"] + cmd
    return cmd


def tailer():
    """Sigue alerts.json para siempre; `tail -F` sobrevive a la rotacion diaria de Wazuh."""
    while True:
        cmd = tail_cmd()
        log(f"tail: {' '.join(cmd)}")
        try:
            proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        except Exception as e:
            log(f"tail: no se pudo lanzar ({e}); reintento en 5s")
            time.sleep(5)
            continue
        buf = b""
        for raw in proc.stdout:
            # Una alerta por linea; algunas lineas muy largas pueden venir partidas -> acumular hasta JSON valido
            buf += raw
            if not raw.endswith(b"\n"):
                continue
            line = buf.strip()
            buf = b""
            if not line:
                continue
            try:
                alert = json.loads(line.decode("utf-8", "replace"))
            except json.JSONDecodeError:
                stats["parse_errors"] += 1
                continue
            ev = compact(alert)
            log(f"alerta lvl={ev['level']} mitre={ev['mitre']} :: {ev['description'][:70]}")
            broadcast(ev)
        err = proc.stderr.read().decode("utf-8", "replace").strip()
        log(f"tail termino (rc={proc.poll()}) {err[:200]}; reinicio en 3s")
        stats["tail_restarts"] += 1
        time.sleep(3)


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "PurpleTeamLive/1.0"

    def log_message(self, fmt, *args):  # menos ruido; solo errores
        if args and str(args[1:2]).startswith("('5"):
            log(f"http {self.address_string()} {fmt % args}")

    def _send(self, code, body, ctype="text/plain; charset=utf-8", extra=None):
        if isinstance(body, str):
            body = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        u = urlparse(self.path)
        path = u.path
        if path in ("/", "/index.html"):
            try:
                with open(INDEX_HTML, "rb") as f:
                    self._send(200, f.read(), "text/html; charset=utf-8")
            except FileNotFoundError:
                self._send(404, "index.html no encontrado")
        elif path == "/stream":
            self.stream(parse_qs(u.query))
        elif path == "/api/recent":
            self._send(200, json.dumps(list(history)), "application/json")
        elif path == "/health":
            body = dict(stats, clients=len(clients), history=len(history), uptime=round(time.time() - stats["started"]))
            self._send(200, json.dumps(body), "application/json")
        else:
            self._send(404, "not found")

    def stream(self, qs):
        replay = qs.get("replay", ["1"])[0] != "0"
        q = queue.Queue(maxsize=1000)
        with clients_lock:
            clients.add(q)
        log(f"SSE conectado {self.address_string()} (clientes={len(clients)}, replay={replay})")
        try:
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Connection", "keep-alive")
            self.send_header("X-Accel-Buffering", "no")
            self.end_headers()
            self.wfile.write(b"retry: 2000\n\n")
            self.wfile.write(("event: hello\ndata: " + json.dumps({"history": len(history), "server_time": time.time()}) + "\n\n").encode())
            if replay:
                for ev in list(history):
                    self.wfile.write(("event: alert\ndata: " + json.dumps(dict(ev, replay=True)) + "\n\n").encode())
            self.wfile.flush()
            while True:
                try:
                    ev = q.get(timeout=HEARTBEAT_SECS)
                    self.wfile.write(("event: alert\ndata: " + json.dumps(ev) + "\n\n").encode())
                except queue.Empty:
                    self.wfile.write(b": ping\n\n")
                self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError, ConnectionAbortedError):
            pass
        except Exception as e:
            log(f"SSE error: {e}")
        finally:
            with clients_lock:
                clients.discard(q)
            log(f"SSE desconectado {self.address_string()} (clientes={len(clients)})")
            self.close_connection = True


def main():
    threading.Thread(target=tailer, daemon=True, name="tailer").start()
    srv = ThreadingHTTPServer((HOST, PORT), Handler)
    srv.daemon_threads = True
    log(f"Dashboard en http://{HOST}:{PORT}  (alertas: {ALERTS_FILE})")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
