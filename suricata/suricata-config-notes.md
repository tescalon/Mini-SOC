# Configuration Suricata - Mini-SOC Lab

Suricata 7.0.3 tourne dans WSL2 sur PC1 (Windows 11).

## Installation

```bash
sudo apt update && sudo apt install -y suricata
suricata-update
```

## Configuration

Les fichiers de configuration sont dans WSL :
- `/etc/suricata/suricata.yaml` - config principale
- `/etc/filebeat/filebeat.yml` - config Filebeat vers ELK

## Demarrage

```bash
bash scripts/suricata-start.sh
```

## Regles

- **Source** : Emerging Threats Open
- **Nombre** : 49 864 signatures actives
- **Mise a jour** : `sudo suricata-update`

## Logs

```bash
# Alertes en temps reel
sudo tail -f /var/log/suricata/fast.log

# Logs JSON enrichis
sudo tail -f /var/log/suricata/eve.json | python3 -m json.tool
```

## Integration ELK

Filebeat est configure pour envoyer `eve.json` vers Elasticsearch sur PC1.
Les alertes arrivent dans l'index `filebeat-*`.

La regle Kibana `Alertes Suricata` surveille :
```
event.module : suricata AND event.kind : alert
AND NOT destination.port : (9200 or 5601 or 5044)
AND NOT source.port : (9200 or 5601 or 5044)
AND NOT suricata.eve.alert.signature : "GPL ATTACK_RESPONSE id check returned root"
```

## Chaine complete

```
Suricata -> eve.json -> Filebeat -> Elasticsearch -> Kibana Rule -> TheHive -> Cortex
```
