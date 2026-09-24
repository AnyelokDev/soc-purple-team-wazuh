# SOC Purple Team en vivo · Wazuh × Fable 5.1

Demo de *purple team* con un dashboard web en vivo que muestra el flujo
**ataque → detección → análisis → regla** sobre alertas **reales** de Wazuh.
El panel lee `/var/ossec/logs/alerts/alerts.json`, empuja cada alerta al navegador
por SSE (Server-Sent Events) y pinta una cuadrícula MITRE ATT&CK con un porcentaje
de cobertura que sube en directo.

La idea central: se atacan varias técnicas. Wazuh detecta unas (verde) y otras no
(huecos, rojo). El hueco real fue el **escaneo de red (T1046 / T1595)**: el `nmap`
desde Kali llegaba al servidor, pero el Wazuh de fábrica no tenía ninguna regla que
interpretara esos eventos, así que el escaneo era invisible. Fable 5.1 escribió un
decoder y las reglas de correlación **100098–100100**, las ajustó contra los eventos
reales del servidor, y el mismo escaneo pasó a generar una alerta de nivel 8 mapeada a
T1046 y T1595 (cobertura del 43 % al 71 %). Eso es **detección como código**.

**T1136 (Create Account) es un enriquecimiento, no un hueco.** La regla de fábrica 5902
("New user added") ya detecta la creación de cuentas y la mapea a T1136. La regla
**100200** hereda de ella, sube el nivel de 8 a 10 (dentro del umbral de respuesta
activa) y añade la descripción de persistencia.

![Panel en vivo: escaneo detectado por la regla 100100, cobertura 71 %](evidencia/08_panel_71_flujo_completo.png)

<sup>Panel durante la demo: flujo ataque → detección → análisis → regla, cuadrícula MITRE
ATT&CK y log de alertas reales. El escaneo desde Kali ya entra por la regla 100100 y
T1595 / T1046 pasan a cerrado (71 %). T1110 y T1136 siguen en rojo porque todavía no se
han lanzado esos ataques.</sup>

## Cómo se escribieron las reglas

Yo diseñé el flujo, monté el SOC, lancé los ataques y dirigí el trabajo. Dentro de ese
flujo, **Fable 5.1 (vía Claude Code) generó de forma autónoma el decoder y las reglas de
detección** y las fue mejorando a partir de lo que el Wazuh real registraba, hasta que el
escaneo quedó detectado. También escribió la regla de persistencia 100200 y el panel.
El script `scripts/close_gap_t1136.sh` solo aplica la 100200 ya escrita, y lo ejecuto yo
durante la demo.

La etapa "Fable 5.1" del panel muestra el mapeo MITRE de cada alerta. Durante la demo el
panel no consulta al modelo: todo lo que muestra sale de `alerts.json`.

> 📄 **Informe completo con evidencias:**
> [`docs/Informe-SOC-Purple-Team-Wazuh.pdf`](docs/Informe-SOC-Purple-Team-Wazuh.pdf)
> · las 22 capturas de la demo están en [`evidencia/`](evidencia/).

## Arquitectura

```
  Kali externa (o la propia EC2)          EC2 Amazon Linux · IP TU_IP_EC2
  ───────────────────────────             ─────────────────────────────────────
   ataques (nmap, ssh, useradd)  ──────▶   Wazuh manager 4.14.7
                                              │  genera alerts.json
                                              ▼
                                           server.py  (stdlib, tail -F + SSE)
                                              │  escucha en 0.0.0.0:8080
                                              ▼
                                           index.html  ◀── navegador (dashboard en vivo)
```

> **Reemplaza `TU_IP_EC2`** por la IP pública de tu propia EC2 en este README y en
> `docs/GUION_DEMO.txt` antes de arrancar la demo (es la dirección donde se abre el panel).

- **`dashboard/server.py`** — backend en Python de solo librería estándar. Hace
  `tail -F` de `alerts.json` (vía `sudo -n tail`), expone SSE en `/stream`, sirve
  `index.html` en `/`, y ofrece `/api/recent` y `/health`. Escucha en `0.0.0.0:8080`.
- **`dashboard/index.html`** — panel de una sola página. Cuadrícula MITRE, log en
  vivo, flujo de 4 nodos y botón "Reiniciar demo" (usa `localStorage`).
- **`dashboard/run.sh`** — arranque/parada: `start | stop | restart | status | logs`.
- **`wazuh-rules/`** — reglas y decoders custom de Wazuh.
- **`scripts/`** — script que aplica la regla 100200 (T1136) y script del auto-bloqueo.
- **`docs/GUION_DEMO.txt`** — guion paso a paso de la demo.
- **`docs/Informe-SOC-Purple-Team-Wazuh.pdf`** — informe técnico completo: diseño,
  reglas, problemas encontrados y anexo de evidencias.
- **`evidencia/`** — las 22 capturas de la demo, numeradas en orden cronológico
  (del 43 % inicial al 100 %, con la regla 100200 aplicada al final).
- **`report/`** — fuente LaTeX del informe (`.tex`, clase y bibliografía).
- **`LICENSE`** — licencia MIT.

## Requisitos

- Amazon Linux con **Wazuh manager 4.14.7** instalado y corriendo.
- **Python 3.9+** (solo librería estándar, sin dependencias).
- El usuario que arranca el panel debe poder `sudo -n tail` sobre `alerts.json`.
- Puerto **8080/TCP** abierto en el grupo de seguridad para el navegador.

## Montaje y arranque

### 1. Desplegar reglas y decoders de Wazuh

```bash
sudo cp wazuh-rules/local_rules.xml    /var/ossec/etc/rules/local_rules.xml
sudo cp wazuh-rules/local_decoder.xml  /var/ossec/etc/decoders/local_decoder.xml
sudo chown wazuh:wazuh /var/ossec/etc/rules/local_rules.xml /var/ossec/etc/decoders/local_decoder.xml
sudo systemctl restart wazuh-manager
```

> Nota: `local_rules.xml` y `local_decoder.xml` ya incluyen las reglas de recon
> (T1046/T1595) y su decoder. La regla 100200 (T1136) está aparte en
> `local_rules_t1136.xml` a propósito, porque se aplica **en vivo** durante la demo.

### 2. Arrancar el dashboard

```bash
cd dashboard
./run.sh start        # arranca en http://0.0.0.0:8080
./run.sh status       # comprueba /health
./run.sh logs         # sigue el log
```

Abre `http://TU_IP_EC2:8080` (o la IP pública de tu EC2) en el navegador.
Debe indicar "en vivo" arriba a la derecha.

### 3. (Opcional) Activar auto-bloqueo

`scripts/enable_active_response.sh` activa `firewall-drop` ante alertas de nivel ≥ 10.
**Antes de correrlo**, edita el script y reemplaza los placeholders `IP_GESTION_SSH`
e `IP_GESTION_NAVEGADOR` por tus IPs públicas de gestión, o perderás el acceso SSH.

## Reglas y decoders custom (técnica MITRE)

| Archivo | ID regla | Nivel | Técnica MITRE | Qué hace |
|---|---|---|---|---|
| `local_rules.xml` / `local_rules_scan.xml` | 100099 | 1 | — (base) | Conexión SSH cerrada sin autenticar. Evento base para correlación. |
| `local_rules.xml` / `local_rules_scan.xml` | 100098 | 1 | — (base) | Sonda con protocolo inválido en el puerto SSH (nmap `-A`). Evento base. |
| `local_rules.xml` / `local_rules_scan.xml` | 100100 | 8 | **T1046** (Network Service Discovery), **T1595** (Active Scanning) | **Cierre del hueco real.** ≥2 eventos base desde la misma IP en 5 min ⇒ escaneo de red/servicios. Sin ella, el Wazuh de fábrica no alerta del escaneo. |
| `local_rules_t1136.xml` | 100200 | 10 | **T1136** (Create Account) | **Enriquecimiento.** Hereda de la regla de fábrica 5902 ("New user added"), que ya detecta la creación de cuentas y la mapea a T1136. Sube el nivel de 8 a 10 y añade la descripción de persistencia. Se aplica en vivo. |
| `local_decoder.xml` / `local_decoder_scan.xml` | decoder `sshd-banner-invalid` | — | — | Extrae `srcip`/`srcport` de las sondas no-SSH de nmap que OpenSSH 9.x registra como "banner exchange … invalid format". |

Las técnicas T1110, T1078, T1021 y T1548 las cubre Wazuh con sus reglas de fábrica
(fuerza bruta SSH, login válido, servicios remotos y escalada con sudo); no requieren
reglas custom.

## Comandos de ataque de la demo

### Opción A — desde Kali contra la EC2 (como se hizo en la demo)

En la demo real, el escaneo y los intentos de acceso se lanzaron **desde una Kali en
VirtualBox contra la IP pública de la EC2** (`TU_IP_EC2`). Es lo que muestran las
capturas 05 a 13.

```bash
# En Kali:
# Recon / escaneo  -> T1595 + T1046 (regla 100100)
sudo nmap -sS -sV -A TU_IP_EC2

# Intentos de acceso con usuarios inexistentes  -> T1110 + T1021
# (hydra por contraseña no sirve: el SSH solo acepta clave; ver captura 10)
for i in $(seq 1 15); do ssh -o BatchMode=yes -o ConnectTimeout=3 baduser$i@TU_IP_EC2 true 2>/dev/null; done
```

El login válido (T1078), la escalada con `sudo` (T1548) y la creación de cuentas (T1136)
se generan en la propia EC2 al entrar por SSH con la clave y ejecutar los comandos de
administración.

### Opción B — reproducirlo desde la propia EC2 (sin Kali)

Si no tienes una máquina atacante, puedes generar los mismos eventos desde la EC2
contra `127.0.0.1`. Es la alternativa para reproducir la demo, no lo que se hizo en ella:

```bash
# Recon / escaneo  -> T1595 + T1046
python3 -c "import socket;[socket.create_connection(('127.0.0.1',22),2).recv(64) for _ in range(3)]"

# Fuerza bruta SSH  -> T1110 + T1021
for i in $(seq 1 8); do ssh -o BatchMode=yes -o ConnectTimeout=2 admin@127.0.0.1 true 2>/dev/null; done

# Login valido  -> T1078
ssh ec2-user@127.0.0.1 true

# Escalada de privilegios  -> T1548
sudo -k; sudo id
```

### T1136: enriquecimiento de la regla en vivo

```bash
# 1. Se crea una cuenta: la regla de fábrica 5902 ya la detecta (nivel 8) y la mapea
#    a T1136 -> la casilla pasa a verde
sudo useradd demo_attacker

# 2. Aplico la regla 100200, escrita por Fable: sube el nivel a 10 y añade la
#    descripción de persistencia
./scripts/close_gap_t1136.sh      # espera ~10 s a que Wazuh reinicie

# 3. Misma acción: ahora entra por la 100200 con nivel 10, dentro del umbral de
#    respuesta activa
sudo userdel demo_attacker; sudo useradd demo_attacker2
```

![Panel al 100 % con la regla 100200 activa](evidencia/22_panel_100_regla_100200_t1136.png)

<sup>Tras aplicar la regla 100200, la creación de `demo_attacker2` entra en el log como
"Persistencia: cuenta local creada" con nivel 10 y la etiqueta T1136. La cobertura ya
era del 100 % gracias a la regla de fábrica 5902 (captura 14).</sup>

### Limpieza tras la demo

```bash
sudo userdel demo_attacker2
# Deshacer reglas: restaura los .bak de /var/ossec/etc/rules/ y reinicia wazuh-manager.
```

El guion completo, con lo que decir en cada paso, está en `docs/GUION_DEMO.txt`.

## Licencia

Distribuido bajo licencia MIT. Ver [`LICENSE`](LICENSE).
