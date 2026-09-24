#!/usr/bin/env bash
# Uso: ./run.sh start | stop | restart | status | logs
cd "$(dirname "$0")"
PIDF=server.pid
case "${1:-start}" in
  start)
    if [ -f $PIDF ] && kill -0 "$(cat $PIDF)" 2>/dev/null; then echo "ya corre (pid $(cat $PIDF))"; exit 0; fi
    nohup python3 server.py >> server.log 2>&1 & echo $! > $PIDF
    sleep 1; echo "arrancado pid $(cat $PIDF) -> http://0.0.0.0:8080";;
  stop)
    [ -f $PIDF ] && kill "$(cat $PIDF)" 2>/dev/null && rm -f $PIDF && echo detenido || echo "no corre";;
  restart) "$0" stop; sleep 1; "$0" start;;
  status)  [ -f $PIDF ] && kill -0 "$(cat $PIDF)" 2>/dev/null && curl -s http://127.0.0.1:8080/health || echo "no corre";;
  logs)    tail -f server.log;;
esac
