# Mini-SOC Open Source

[![Stack](https://img.shields.io/badge/SIEM-ELK%208.13-005571)](./elk/)
[![SOAR](https://img.shields.io/badge/SOAR-TheHive%204%20%2B%20Cortex%203-orange)](./thehive/)
[![CTI](https://img.shields.io/badge/CTI-OpenCTI%206-blueviolet)](./opencti/)
[![OS](https://img.shields.io/badge/OS-Windows%2011%20%2B%20Sysmon-blue)](./winlogbeat/)
[![License](https://img.shields.io/badge/license-MIT-green)](./LICENSE)

Projet personnel de cybersÃ©curitÃ©. DÃ©ploiement d'une stack SOC open source complÃ¨te sur 3 machines physiques. L'objectif Ã©tait de simuler un environnement de dÃ©tection rÃ©aliste : collecter des Ã©vÃ©nements Windows, les corrÃ©ler dans un SIEM, dÃ©clencher des alertes, crÃ©er des cases de rÃ©ponse automatiquement et enrichir avec de la Threat Intelligence.

Tout est fonctionnel et testÃ© avec de vrais scÃ©narios d'attaque simulÃ©s localement.

---

## Architecture

3 machines physiques avec des rÃ´les bien sÃ©parÃ©s :

| Machine | RÃ´le | CPU | RAM | Stack |
| :--- | :--- | :--- | :--- | :--- |
| **PC1** | SIEM | i7-1355U | 16 Go | ELK Stack 8.13 (Docker) |
| **PC2** | SOAR + CTI | i5-6500 | 12 Go | TheHive 4 + Cortex 3 + OpenCTI 6 (Docker) |
| **PC3** | Machine cobaye | â€” | â€” | Windows 11 + Sysmon + Winlogbeat |

---

## Flux de donnÃ©es

Comment un Ã©vÃ©nement Windows devient une alerte enrichie avec du contexte Threat Intel :

```
[PC3 â€” Windows 11]
  Sysmon + Winlogbeat
       â”‚
       â”‚  Beats protocol â€” port 5044
       â–¼
[PC1 â€” Logstash]
  Parsing + enrichissement des logs
       â”‚
       â–¼
[PC1 â€” Elasticsearch]
  Stockage + indexation
       â”‚
       â–¼
[PC1 â€” Kibana SIEM]
  RÃ¨gles de dÃ©tection (Threshold / Query)
  Mapping MITRE ATT&CK
       â”‚
       â”‚  Webhook sur dÃ©clenchement de rÃ¨gle
       â–¼
[PC2 â€” TheHive]
  CrÃ©ation automatique d'un case
  Assignation + timeline
       â”‚
       â–¼
[PC2 â€” Cortex]
  Analyzers automatiques :
  VirusTotal, AbuseIPDB, MaxMind GeoIP,
  TorProject, URLhaus...
       â”‚
       â–¼
[PC2 â€” OpenCTI]
  Enrichissement MITRE ATT&CK
  CorrÃ©lation avec IOCs connus
  Base de Threat Intelligence
```

---

## Services

| Service | Port | Identifiant par dÃ©faut |
| :--- | :--- | :--- |
| Kibana | `http://PC1:5601` | elastic |
| TheHive | `http://PC2:9000` | admin@thehive.local |
| Cortex | `http://PC2:9001` | admin |
| OpenCTI | `http://PC2:8080` | admin@soc.local |

---

## DÃ©marrage rapide

**PrÃ©requis :** Docker + Docker Compose v2, 28 Go de RAM au total sur les deux machines.

```bash
# Copier et remplir les secrets sur chaque machine
cp .env.example .env

# PC1 â€” SIEM
cd elk && docker compose up -d

# PC2 â€” SOAR + CTI (dans cet ordre : TheHive crÃ©e le rÃ©seau partagÃ©)
cd thehive && docker compose up -d
cd ../opencti && docker compose up -d
```

VÃ©rifier que tout est up depuis PC3 :

```powershell
.\scripts\healthcheck.ps1 -PC1_IP "192.168.1.X" -PC2_IP "192.168.1.Y"
```

Le guide complet d'installation est disponible dans [docs/installation.md](./docs/installation.md).

---

## RÃ¨gles de dÃ©tection

5 rÃ¨gles actives dans Kibana SIEM, toutes mappÃ©es sur MITRE ATT&CK :

| RÃ¨gle | Event ID | SÃ©vÃ©ritÃ© | Technique MITRE |
| :--- | :--- | :--- | :--- |
| Brute Force (threshold â‰¥ 5) | 4625 | High | T1110 |
| PowerShell encodÃ© | 4104 | High | T1059.001 |
| CrÃ©ation de compte local | 4720 | Medium | T1136.001 |
| Ajout dans groupe Admins | 4732 | High | T1078.003 |
| Service Windows crÃ©Ã© | 7045 | High | T1543.003 |

[â†’ DÃ©tail complet des rÃ¨gles et du webhook TheHive](./detection-rules/detection-rules.md)

---

## Simulation d'attaques

Le script `attack-simulation.ps1` gÃ©nÃ¨re de vrais Ã©vÃ©nements Windows pour valider les rÃ¨gles. Ã€ exÃ©cuter en administrateur sur PC3.

```powershell
# Tous les scÃ©narios d'un coup
.\scripts\attack-simulation.ps1

# ScÃ©nario ciblÃ©
.\scripts\attack-simulation.ps1 -Scenario brute-force
.\scripts\attack-simulation.ps1 -Scenario powershell
.\scripts\attack-simulation.ps1 -Scenario account
```

AprÃ¨s exÃ©cution, les alertes remontent dans Kibana sous 5 minutes. Un case est crÃ©Ã© automatiquement dans TheHive via webhook, et Cortex lance les analyzers configurÃ©s sur les IOCs extraits.

---

## Analyzers Cortex actifs

| Analyzer | Type | UtilitÃ© |
| :--- | :--- | :--- |
| MaxMind_GeoIP | IP | GÃ©olocalisation |
| IP-API | IP | Infos ASN / organisation |
| AbuseIPDB | IP | Score de rÃ©putation |
| TorProject | IP | DÃ©tection nÅ“uds Tor |
| VirusTotal | Hash / URL / IP | RÃ©putation multi-sources |
| URLhaus | URL | Base malware URLs |
| Abuse_Finder | Email / IP / Domain | Contacts abuse |
| GoogleDNS | Domain | RÃ©solution DNS passive |

---

## Structure du repo

```
.
â”œâ”€â”€ elk/                              # PC1 â€” SIEM
â”‚   â”œâ”€â”€ docker-compose.yml
â”‚   â””â”€â”€ logstash/
â”‚       â”œâ”€â”€ config/logstash.yml
â”‚       â””â”€â”€ pipeline/main.conf        # Parsing Beats + Syslog UDP
â”‚
â”œâ”€â”€ thehive/                          # PC2 â€” SOAR
â”‚   â”œâ”€â”€ docker-compose.yml            # TheHive 4 + Cortex 3 + Cassandra + ES
â”‚   â””â”€â”€ Dockerfile-cortex             # Image Cortex avec Python3 + cortexutils
â”‚
â”œâ”€â”€ opencti/                          # PC2 â€” CTI
â”‚   â””â”€â”€ docker-compose.yml            # OpenCTI 6 + connecteurs MITRE/URLhaus/MalwareBazaar
â”‚
â”œâ”€â”€ winlogbeat/
â”‚   â””â”€â”€ winlogbeat.yml                # Config agent Windows (PC3)
â”‚
â”œâ”€â”€ detection-rules/
â”‚   â””â”€â”€ detection-rules.md            # RÃ¨gles Kibana SIEM + webhook TheHive
â”‚
â”œâ”€â”€ scripts/
â”‚   â”œâ”€â”€ attack-simulation.ps1         # GÃ©nÃ¨re de vrais Ã©vÃ©nements d'attaque
â”‚   â””â”€â”€ healthcheck.ps1               # VÃ©rifie l'Ã©tat de tous les services
â”‚
â”œâ”€â”€ docs/
â”‚   â”œâ”€â”€ installation.md               # Guide d'installation complet
â”‚   â””â”€â”€ screenshots/                  # Captures d'Ã©cran du SOC en fonctionnement
â”‚
â”œâ”€â”€ .env.example                      # Variables d'environnement (template)
â””â”€â”€ .gitignore
```

---

## Stack complÃ¨te

```
SIEM     : Elasticsearch 8.13 + Logstash 8.13 + Kibana 8.13
SOAR     : TheHive 4.1.24 + Cortex 3.1.8
CTI      : OpenCTI 6.0.5
Collecte : Winlogbeat 8.13 + Sysmon (config SwiftOnSecurity)
Infra    : Docker + Docker Compose v2 + Windows 11 / Ubuntu
```

---

## Ce qui pourrait Ãªtre ajoutÃ©

- RÃ¨gles Sigma converties automatiquement en rÃ¨gles Kibana (via sigma-cli)
- DÃ©tection rÃ©seau avec Suricata ou Zeek sur le segment LAN
- Dashboard OpenCTI corrÃ©lant les IOCs dÃ©tectÃ©s par Kibana avec la base CTI
- Authentification centralisÃ©e (SSO) entre les services
