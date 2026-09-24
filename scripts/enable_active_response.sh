#!/usr/bin/env bash
# Activa el auto-bloqueo (firewall-drop) en Wazuh ante alertas nivel>=10 (fuerza bruta 5712).
# Pone tus IPs de gestion en la lista blanca para no perder acceso. Reversible: usa el .bak.
set -e
CONF=/var/ossec/etc/ossec.conf
sudo cp "$CONF" "$CONF.bak-$(date +%Y%m%d-%H%M%S)"
sudo python3 - <<'PY'
import re
p="/var/ossec/etc/ossec.conf"; s=open(p).read()
new_ar="""  <active-response>
    <command>firewall-drop</command>
    <location>local</location>
    <level>10</level>
    <timeout>600</timeout>
  </active-response>"""
s2=re.sub(r"  <active-response>\s*active-response options here\s*</active-response>", new_ar, s, count=1)
assert s2!=s, "no se encontro el placeholder <active-response>"
s=s2
for ip in ["IP_GESTION_SSH","IP_GESTION_NAVEGADOR"]:   # <-- REEMPLAZA por tus IPs publicas de gestion (SSH y navegador del panel)
    if f"<white_list>{ip}</white_list>" not in s:
        s=s.replace("    <white_list>172.31.0.2</white_list>",
                    f"    <white_list>172.31.0.2</white_list>\n    <white_list>{ip}</white_list>",1)
open(p,"w").write(s); print("ossec.conf actualizado")
PY
python3 -c "import xml.dom.minidom as m; m.parse('/var/ossec/etc/ossec.conf'); print('XML valido')"
sudo systemctl restart wazuh-manager
sleep 10
sudo /var/ossec/bin/wazuh-control status | grep -E "execd|analysisd"
echo "Listo. Auto-bloqueo activo para alertas nivel>=10."
