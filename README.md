# Mini-SOC Open Source

[![Stack](https://img.shields.io/badge/SIEM-ELK%208.13-005571)](./elk/)
[![SOAR](https://img.shields.io/badge/SOAR-TheHive%204%20%2B%20Cortex%203-orange)](./thehive/)
[![CTI](https://img.shields.io/badge/CTI-OpenCTI%206-blueviolet)](./opencti/)
[![OS](https://img.shields.io/badge/OS-Windows%2011%20%2B%20Sysmon-blue)](./winlogbeat/)

Projet personnel de cybersécurité. Déploiement d'une stack SOC open source complète sur 3 machines physiques. L'objectif était de simuler un vrai environnement de détection : collecter des événements Windows réels, les corréler dans un SIEM, déclencher des alertes, créer des cases de réponse automatiquement et enrichir avec de la Threat Intelligence.

Tout est fonctionnel et testé avec de vrais scénarios d'attaque simulés localement.

---

## Architecture

3 machines physiques, chacune avec un rôle distinct :

| Machine | Rôle | CPU | RAM | Stack |
| :--- | :--- | :--- | :--- | :--- |
| **PC1** | SIEM | i7-1355U | 16 Go | ELK Stack 8.13 (Docker) |
| **PC2** | SOAR + CTI | i5-6500 | 12 Go | TheHive 4 + Cortex 3 + OpenCTI 6 (Docker) |
| **PC3** | Machine cobaye | — | — | Windows 11 + Sysmon + Winlogbeat |

---

## Flux de données

C'est la partie centrale du projet, comment un événement Windows devient une alerte enrichie avec du contexte Threat Intel.

```
[PC3 - Windows 11]
  Sysmon + Winlogbeat
       │
       │ (Beats protocol, port 5044)
       ▼
[PC1 - Logstash]
  Parsing + enrichissement
       │
       ▼
[PC1 - Elasticsearch]
  Stockage + indexation
       │
       ▼
[PC1 - Kibana SIEM]
  Règles de détection (threshold / query)
  Mapping MITRE ATT&CK
       │
       │ (Webhook sur déclenchement de règle)
       ▼
[PC2 - TheHive]
  Création automatique d'un case
  Assignation + timeline
       │
       ▼
[PC2 - Cortex]
  Analyzers automatiques :
  VirusTotal, AbuseIPDB, MaxMind GeoIP,
  TorProject, URLhaus...
       │
       ▼
[PC2 - OpenCTI]
  Enrichissement MITRE ATT&CK
  Corrélation avec IOCs connus
  Base de Threat Intelligence
```

---

## Services

| Service | Adresse | Identifiant |
| :--- | :--- | :--- |
| Kibana | `http://PC1:5601` | elastic |
| TheHive | `http://PC2:9000` | admin@thehive.local |
| Cortex | `http://PC2:9001` | admin |
| OpenCTI | `http://PC2:8080` | admin@soc.local |

---

## Structure du repo

```
.
├── elk/                          # PC1 - SIEM
│   ├── docker-compose.yml        # ELK Stack 8.13
│   └── logstash/
│       ├── config/logstash.yml
│       └── pipeline/main.conf    # Parsing Beats + Syslog
│
├── thehive/                      # PC2 - SOAR
│   └── docker-compose.yml        # TheHive 4 + Cortex 3 + Cassandra
│
├── opencti/                      # PC2 - CTI
│   └── docker-compose.yml        # OpenCTI 6 + MinIO + RabbitMQ
│
├── winlogbeat/                   # PC3 - Collecte
│   └── winlogbeat.yml            # Config agent Windows
│
├── detection-rules/
│   └── detection-rules.md        # Règles Kibana SIEM (MITRE ATT&CK)
│
└── scripts/
    ├── attack-simulation.ps1     # Simulation de scénarios d'attaque
    └── healthcheck.ps1           # Vérification état des services
```

---

## Démarrage rapide

**Prérequis :** Docker Desktop avec WSL2, 28 Go de RAM au total sur les deux machines.

Copier les fichiers `.env.example` en `.env` sur chaque machine et remplir les mots de passe, puis :

```bash
# Sur PC1
cd elk && docker compose up -d

# Sur PC2
cd thehive && docker compose up -d
cd ../opencti && docker compose up -d
```

Vérifier que tout est up depuis PC3 :

```powershell
.\scripts\healthcheck.ps1 -PC1_IP "192.168.1.X" -PC2_IP "192.168.1.Y"
```

---

## Règles de détection

5 règles actives dans Kibana SIEM, toutes mappées sur MITRE ATT&CK :

| Règle | Event ID | Sévérité | Technique MITRE |
| :--- | :--- | :--- | :--- |
| Brute Force (threshold ≥5) | 4625 | High | T1110 |
| PowerShell encodé | 4104 | High | T1059.001 |
| Création de compte | 4720 | Medium | T1136.001 |
| Ajout groupe Admins | 4732 | High | T1078.003 |
| Service Windows créé | 7045 | High | T1543.003 |

[→ Détail complet des règles](./detection-rules/detection-rules.md)

---

## Simulation d'attaques

Le script `attack-simulation.ps1` génère de vrais événements Windows pour valider les règles de détection. À exécuter en admin sur PC3.

```powershell
# Tous les scénarios d'un coup
.\scripts\attack-simulation.ps1

# Scénario ciblé
.\scripts\attack-simulation.ps1 -Scenario brute-force
.\scripts\attack-simulation.ps1 -Scenario powershell
.\scripts\attack-simulation.ps1 -Scenario account
```

Après exécution, les alertes remontent dans Kibana sous 5 minutes, un case est créé automatiquement dans TheHive via webhook, et Cortex lance les analyzers configurés sur les IOCs extraits.

---

## Analyzers Cortex actifs

| Analyzer | Type | Utilité |
| :--- | :--- | :--- |
| MaxMind_GeoIP | IP | Géolocalisation |
| IP-API | IP | Infos ASN/organisation |
| AbuseIPDB | IP | Réputation IP |
| TorProject | IP | Détection nœuds Tor |
| VirusTotal | Hash/URL/IP | Réputation multi-sources |
| URLhaus | URL | Base malware URLs |
| Abuse_Finder | Email/IP/Domain | Contacts abuse |
| GoogleDNS | Domain | Résolution DNS passive |

---

## Stack complète

```
SIEM     : Elasticsearch 8.13 + Logstash 8.13 + Kibana 8.13
SOAR     : TheHive 4.1.24 + Cortex 3.1.8
CTI      : OpenCTI 6.0.5
Collecte : Winlogbeat 8.13 + Sysmon (config SwiftOnSecurity)
Infra    : Docker Desktop + WSL2 + Windows 11
```

---

## Ce qui reste à faire

- Intégrer Shuffle (SOAR open source) pour automatiser les playbooks de réponse
- Ajouter des règles de détection sur les logs réseau (pfSense → Logstash via syslog)
- Relier ce SOC au homelab réseau pour superviser les deux projets depuis Kibana
- Déployer un agent Elastic sur les pfSense pour enrichir la visibilité réseau
- Tester des scénarios plus avancés (lateral movement, persistence via scheduled tasks)
