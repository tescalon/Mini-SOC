# Mini-SOC Open Source

[![Stack](https://img.shields.io/badge/SIEM-ELK%208.13-005571)](./elk/)
[![SOAR](https://img.shields.io/badge/SOAR-TheHive%204%20%2B%20Cortex%203-orange)](./thehive/)
[![CTI](https://img.shields.io/badge/CTI-OpenCTI%206-blueviolet)](./opencti/)
[![IDS](https://img.shields.io/badge/IDS-Suricata%207-red)](./suricata/)
[![OS](https://img.shields.io/badge/OS-Windows%2011%20%2B%20WSL2-blue)](./winlogbeat/)

Stack SOC open source complete deployee sur 3 machines physiques.
Detection reseau (Suricata) + detection endpoint (Winlogbeat/Sysmon) + SIEM (ELK) +
reponse aux incidents (TheHive) + enrichissement automatique (Cortex) +
Threat Intelligence (OpenCTI). Tout est fonctionnel et teste avec de vrais
scenarios d'attaque simules localement.

---

## Architecture

| Machine | Role | CPU | RAM | Stack |
| :--- | :--- | :--- | :--- | :--- |
| **PC1** | SIEM + IDS | i7-1355U | 16 Go | ELK 8.13 + Suricata 7 (WSL2) |
| **PC2** | SOAR + CTI | i5-6500 | 12 Go | TheHive 4 + Cortex 3 + OpenCTI 6 |
| **PC3** | Cobaye | - | - | Windows 11 + Sysmon + Winlogbeat |

---

## Flux de donnees complet

```
[PC3 - Windows 11]          [PC1 - WSL2]
  Sysmon + Winlogbeat          Suricata IDS
  Events Windows               49 864 regles ET
       |                            |
       | Beats port 5044            | Filebeat
       v                            v
[PC1 - Logstash]  <---------  [PC1 - Elasticsearch]
  Parsing + enrichissement         Stockage + indexation
                                         |
                                         v
                               [PC1 - Kibana SIEM]
                               Regles de detection
                               MITRE ATT&CK mapping
                                         |
                                         | Webhook
                                         v
                               [PC2 - TheHive]
                               Cases automatiques
                               Workflow analyste IR
                                         |
                                         v
                               [PC2 - Cortex]
                               AbuseIPDB, VirusTotal,
                               MaxMind GeoIP, TorProject
                                         |
                                         v
                               [PC2 - OpenCTI]
                               MITRE ATT&CK enrichi
                               30 000 objets STIX 2.1
                               Threat Intelligence
```

---

## Detection : regles Kibana SIEM

### Regles Windows (Winlogbeat + Sysmon)

| Regle | Event ID | Severite | MITRE |
| :--- | :--- | :--- | :--- |
| Brute Force (threshold >= 5) | 4625 | High | T1110 |
| PowerShell encode | 4104 | High | T1059.001 |
| Creation de compte local | 4720 | Medium | T1136.001 |
| Ajout dans groupe Admins | 4732 | High | T1078.003 |
| Service Windows cree | 7045 | High | T1543.003 |

### Regles reseau (Suricata)

| Regle | Source | Severite | Description |
| :--- | :--- | :--- | :--- |
| Alertes Suricata | filebeat-* | High | Toutes alertes Suricata ET/GPL |

**49 864 signatures** Emerging Threats chargees, mise a jour automatique quotidienne.

---

## Services

| Service | Port | Identifiant |
| :--- | :--- | :--- |
| Kibana | `http://PC1:5601` | elastic |
| TheHive | `http://PC2:9000` | admin@thehive.local |
| Cortex | `http://PC2:9001` | admin |
| OpenCTI | `http://PC2:8080` | admin@soc.local |

---

## Demarrage rapide

```bash
# PC1 - ELK
cd elk && docker compose up -d

# PC2 - SOAR + CTI
cd thehive && docker compose up -d
cd ../opencti && docker compose up -d
```

Suricata sur PC1 (WSL2) :
```bash
bash scripts/suricata-start.sh
```

Guide complet : [docs/installation.md](./docs/installation.md)

---

## Automatisation : chaine complete

Quand une alerte est detectee, la chaine suivante se declenche automatiquement :

1. **Suricata** detecte le trafic suspect -> alerte dans `eve.json`
2. **Filebeat** envoie vers Elasticsearch
3. **Kibana** rule engine se declenche toutes les 5 minutes
4. **Webhook** cree un case dans TheHive
5. **auto-analyze.ps1** detecte les nouveaux observables et lance Cortex
6. **Cortex** enrichit chaque IP avec AbuseIPDB + VirusTotal
7. **OpenCTI** fournit le contexte Threat Intelligence

---

## Analyzers Cortex actifs

| Analyzer | Type | Utilite |
| :--- | :--- | :--- |
| AbuseIPDB_2_0 | IP | Score de reputation, signalements |
| VirusTotal_GetReport_3_1 | IP/Hash/URL | Analyse multi-sources 91 moteurs |
| MaxMind_GeoIP_4_0 | IP | Geolocalisation |
| TorProject_1_0 | IP | Detection noeuds Tor |
| IP-API_1_1 | IP | ASN, organisation |
| Abuse_Finder_3_0 | IP/Domain | Contacts abuse |
| GoogleDNS_resolve_1_0_0 | Domain | Resolution DNS passive |

---

## Travaux pratiques realises

### Phase A - OpenCTI

- Import MITRE ATT&CK complet : 29 991 objets STIX, 953 442 relations
- Creation acteur fictif **Lab Attacker** lie a T1110, T1059.001, T1078.003
- Ajout IOCs : IP Tor 185.220.101.1, indicator STIX, observable IPv4
- Rapport de menace STIX 2.1 exporte
- Documentation : [docs/opencti-report.md](./docs/opencti-report.md)

### Phase B - TheHive / Cortex

- Case complet workflow analyste : Investigation > Containment > Eradication > Recovery > Lessons Learned
- Resolution True Positive avec summary de cloture
- AbuseIPDB : score 100/100 sur 185.220.101.1 (noeud Tor, 50 rapports)
- VirusTotal : analyse multi-sources sur IP
- Script auto-analyze.ps1 : enrichissement automatique Cortex
- Documentation : [docs/thehive-workflow.md](./docs/thehive-workflow.md)

### Phase C - Kibana SIEM

- Dashboard custom 6 panels : alertes par severite, top Event IDs, timeline, usernames cibles, alertes par regle, machines supervisees
- Timeline d'attaque complete : 19 evenements en 22 secondes
- Sequence documentee : T1110 > T1136.001 > T1078.003
- Documentation : [docs/kibana-timeline.md](./docs/kibana-timeline.md)

### Phase D - Suricata IDS

- Suricata 7.0.3 dans WSL2, 49 864 regles Emerging Threats
- Filebeat -> Elasticsearch : 428+ alertes reseau indexees
- Regle Kibana : `event.module:suricata AND event.kind:alert`
- Chaine complete validee : Suricata -> ELK -> TheHive -> Cortex
- Detection testee : GPL ATTACK_RESPONSE, ET USER_AGENTS BlackSun

---

## Structure du repo

```
.
|-- elk/
|   |-- docker-compose.yml
|   `-- logstash/
|       |-- config/logstash.yml
|       `-- pipeline/main.conf
|
|-- thehive/
|   |-- docker-compose.yml
|   `-- Dockerfile-cortex
|
|-- opencti/
|   `-- docker-compose.yml
|
|-- suricata/
|   |-- suricata.yaml          # Config Suricata WSL
|   `-- filebeat.yml           # Config Filebeat -> ELK
|
|-- winlogbeat/
|   `-- winlogbeat.yml
|
|-- detection-rules/
|   `-- detection-rules.md
|
|-- scripts/
|   |-- attack-simulation.ps1
|   |-- healthcheck.ps1
|   |-- auto-analyze.ps1       # Enrichissement Cortex automatique
|   |-- install-auto-analyze-task.ps1
|   `-- suricata-start.sh
|
|-- docs/
|   |-- installation.md
|   |-- opencti-report.md
|   |-- thehive-workflow.md
|   |-- kibana-timeline.md
|   |-- screenshots/
|   `-- stix-exports/
|
|-- .env.example
`-- .gitignore
```

---

## Stack complete

```
SIEM     : Elasticsearch 8.13 + Logstash 8.13 + Kibana 8.13
IDS      : Suricata 7.0.3 (WSL2) + 49 864 regles Emerging Threats
SOAR     : TheHive 4.1.24 + Cortex 3.1.8
CTI      : OpenCTI 6.0.5 + connecteurs MITRE/URLhaus/MalwareBazaar
Collecte : Winlogbeat 8.13 + Sysmon + Filebeat 8.x
Infra    : Docker + WSL2 + Windows 11
```

---

## Ce qui pourrait etre ajoute

- Regles Sigma converties automatiquement en regles Kibana (via sigma-cli)
- Suricata en mode IPS (inline) pour bloquer le trafic malveillant
- Dashboard OpenCTI correlant les IOCs detectes par Kibana
- Authentification centralisee (SSO) entre les services
- Zeek pour l'analyse de protocoles reseau avancee
