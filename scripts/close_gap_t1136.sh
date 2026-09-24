#!/usr/bin/env bash
set -e; cd "$(dirname "$0")"
sudo cp /var/ossec/etc/rules/local_rules.xml /var/ossec/etc/rules/local_rules.xml.bak-$(date +%Y%m%d-%H%M%S)
sudo grep -q 'id="100200"' /var/ossec/etc/rules/local_rules.xml || sudo tee -a /var/ossec/etc/rules/local_rules.xml < ../wazuh-rules/local_rules_t1136.xml >/dev/null
sudo chown wazuh:wazuh /var/ossec/etc/rules/local_rules.xml
sudo systemctl restart wazuh-manager; sleep 10
sudo /var/ossec/bin/wazuh-control status | grep analysisd
echo "Hueco T1136 cerrado. Repite 'sudo useradd ...' y la casilla pasa a verde."
