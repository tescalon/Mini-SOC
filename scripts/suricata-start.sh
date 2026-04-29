#!/bin/bash
# suricata-start.sh
# Demarre Suricata 7 dans WSL2 et verifie que Filebeat tourne.
# A lancer depuis WSL sur PC1 apres chaque reboot.
#
# Usage : bash scripts/suricata-start.sh

set -e

echo "=== Demarrage Suricata ==="

# Tuer les instances existantes proprement
sudo pkill suricata 2>/dev/null || true
sudo rm -f /var/run/suricata.pid
sleep 2

# Demarrer Suricata en mode daemon sur eth0
sudo suricata -c /etc/suricata/suricata.yaml -i eth0 -D --pidfile /var/run/suricata.pid
sleep 5

# Verifier que Suricata tourne
if [ -f /var/run/suricata.pid ]; then
    PID=$(cat /var/run/suricata.pid)
    echo "[OK] Suricata demarre - PID $PID"
else
    echo "[ERREUR] Suricata ne tourne pas - verifier les logs :"
    echo "  sudo tail -20 /var/log/suricata/suricata.log"
    exit 1
fi

# Verifier Filebeat
if systemctl is-active --quiet filebeat; then
    echo "[OK] Filebeat actif"
else
    echo "[INFO] Demarrage Filebeat..."
    sudo systemctl start filebeat
    sleep 3
    if systemctl is-active --quiet filebeat; then
        echo "[OK] Filebeat demarre"
    else
        echo "[ERREUR] Filebeat ne demarre pas - verifier la config"
        exit 1
    fi
fi

# Afficher les derniers evenements
echo ""
echo "=== Dernieres alertes Suricata ==="
sudo tail -5 /var/log/suricata/fast.log 2>/dev/null || echo "Pas encore d'alertes"

echo ""
echo "=== Stats Filebeat (derniers 30s) ==="
sudo journalctl -u filebeat --no-pager --since "1 minute ago" 2>/dev/null | \
    grep "acked" | tail -1 | python3 -c "
import sys, json
line = sys.stdin.read()
if line:
    try:
        data = json.loads(line.split('filebeat')[1].strip() if 'filebeat' in line else line)
        acked = data.get('monitoring',{}).get('metrics',{}).get('libbeat',{}).get('output',{}).get('events',{}).get('acked',0)
        print(f'Evenements envoyes a Elasticsearch : {acked}')
    except:
        pass
" || echo "Filebeat en cours de demarrage..."

echo ""
echo "[OK] Stack IDS operationnelle"
echo "Tester la detection : curl http://testmynids.org/uid/index.html"
echo "Surveiller les alertes : sudo tail -f /var/log/suricata/fast.log"
