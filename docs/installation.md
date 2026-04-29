# Guide d'installation â€” Mini-SOC

Ce guide dÃ©crit les Ã©tapes complÃ¨tes pour dÃ©ployer la stack depuis zÃ©ro sur les trois machines.

---

## PrÃ©requis

| Machine | OS | RAM min | Logiciels |
|---|---|---|---|
| PC1 (SIEM) | Ubuntu / Windows + WSL2 | 8 Go | Docker, Docker Compose v2 |
| PC2 (SOAR + CTI) | Ubuntu / Windows + WSL2 | 12 Go | Docker, Docker Compose v2 |
| PC3 (cobaye) | Windows 11 | 4 Go | Sysmon, Winlogbeat 8.13 |

---

## PC1 â€” ELK Stack

### 1. Cloner le repo et configurer les secrets

```bash
git clone https://github.com/tescalon/Mini-SOC.git
cd Mini-SOC/elk
cp ../.env.example .env
# Ã‰diter .env : renseigner ELASTIC_PASSWORD, KIBANA_PASSWORD, KIBANA_ENCRYPTION_KEY
nano .env
```

### 2. DÃ©marrer la stack

```bash
docker compose up -d
```

Elasticsearch met environ 60 secondes Ã  Ãªtre prÃªt. VÃ©rifier :

```bash
curl -u elastic:$ELASTIC_PASSWORD http://localhost:9200
```

### 3. CrÃ©er le mot de passe kibana_system

Cette Ã©tape est obligatoire avant que Kibana puisse dÃ©marrer correctement :

```bash
curl -u elastic:$ELASTIC_PASSWORD \
  -X POST http://localhost:9200/_security/user/kibana_system/_password \
  -H "Content-Type: application/json" \
  -d '{"password":"VALEUR_DE_KIBANA_PASSWORD_DANS_ENV"}'
```

Puis relancer Kibana :

```bash
docker compose restart kibana
```

### 4. AccÃ©der Ã  Kibana

`http://PC1_IP:5601` â€” identifiant : `elastic`, mot de passe : valeur de `ELASTIC_PASSWORD`.

---

## PC2 â€” TheHive + Cortex

### 1. Configurer les secrets

```bash
cd Mini-SOC/thehive
cp ../.env.example .env
# Renseigner THEHIVE_SECRET
nano .env
```

### 2. DÃ©marrer (Cassandra dÃ©marre en dernier, attendre le healthcheck)

```bash
docker compose up -d
# Attendre ~2 minutes que Cassandra soit healthy
docker compose ps
```

### 3. Premier accÃ¨s TheHive

`http://PC2_IP:9000` â€” crÃ©er le compte admin Ã  la premiÃ¨re connexion.

### 4. CrÃ©er la clÃ© API Cortex pour TheHive

Dans Cortex (`http://PC2_IP:9001`) :
- CrÃ©er un compte admin
- Aller dans **Organizations** > crÃ©er une organisation
- GÃ©nÃ©rer une **API Key**
- Copier la clÃ© dans le `.env` : `CORTEX_API_KEY=...`
- Relancer TheHive : `docker compose restart thehive`

---

## PC2 â€” OpenCTI

```bash
cd Mini-SOC/opencti
cp ../.env.example .env
# Renseigner toutes les variables OPENCTI_, RABBITMQ_, MINIO_
nano .env
docker compose up -d
# Si les Attack Patterns restent vides aprÃ¨s import, scaler les workers :
docker compose up -d --scale worker=3
```

---

## PC3 â€” Winlogbeat + Sysmon

### Installer Sysmon

```powershell
# TÃ©lÃ©charger Sysmon depuis https://docs.microsoft.com/sysinternals
# Utiliser la config SwiftOnSecurity
.\Sysmon64.exe -accepteula -i sysmonconfig.xml
```

### Configurer Winlogbeat

Ã‰diter `winlogbeat\winlogbeat.yml` : remplacer `PC1_IP` par l'IP rÃ©elle de PC1.

```powershell
# Installer le service
cd "C:\Program Files\Winlogbeat"
.\install-service-winlogbeat.ps1

# Tester la configuration
.\winlogbeat.exe test config -c winlogbeat.yml

# DÃ©marrer
Start-Service winlogbeat
```

### VÃ©rifier que les logs arrivent dans Kibana

Kibana > **Discover** > index `logs-*` > filtrer sur `host.name : NOM_PC3`.

---

## VÃ©rification globale

Depuis PC3, lancer le healthcheck :

```powershell
.\scripts\healthcheck.ps1 -PC1_IP "192.168.1.X" -PC2_IP "192.168.1.Y"
```

Tous les services doivent afficher `[OK]`.

---

## Tester les rÃ¨gles de dÃ©tection

```powershell
# Lancer tous les scÃ©narios d'attaque simulÃ©e
.\scripts\attack-simulation.ps1

# Ou un scÃ©nario prÃ©cis
.\scripts\attack-simulation.ps1 -Scenario brute-force
```

Les alertes remontent dans **Kibana > Security > Alerts** sous 5 minutes.
Un case est crÃ©Ã© automatiquement dans TheHive via webhook.
