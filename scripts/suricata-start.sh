#!/bin/bash
set -e
echo '=== Demarrage Suricata ==='
sudo pkill suricata 2>/dev/null || true
sudo rm -f /var/run/suricata.pid
sleep 2
sudo suricata -c /etc/suricata/suricata.yaml -i eth0 -D --pidfile /var/run/suricata.pid
sleep 5
[ -f /var/run/suricata.pid ] && echo "[OK] Suricata PID $(cat /var/run/suricata.pid)" || { echo '[ERREUR]'; exit 1; }
systemctl is-active --quiet filebeat || sudo systemctl start filebeat
echo '[OK] Filebeat actif'
echo ''
echo '=== Dernieres alertes ==='
sudo tail -5 /var/log/suricata/fast.log 2>/dev/null || echo 'Pas encore d alertes'
echo '[OK] IDS operationnel - tester : curl http://testmynids.org/uid/index.html'