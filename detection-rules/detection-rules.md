# RÃ¨gles de dÃ©tection Kibana SIEM

Toutes les rÃ¨gles sont configurÃ©es dans **Kibana > Security > Rules**.
Index cible : `logs-*`
Chaque rÃ¨gle est mappÃ©e sur une technique MITRE ATT&CK.

---

## Vue d'ensemble

| RÃ¨gle | Type | Event ID | SÃ©vÃ©ritÃ© | Score de risque | MITRE |
|---|---|---|---|---|---|
| Brute Force connexion | Threshold | 4625 | High | 75 | T1110 |
| PowerShell encodÃ© | Query | 4104 | High | 73 | T1059.001 |
| CrÃ©ation de compte local | Query | 4720 | Medium | 50 | T1136.001 |
| Ajout dans groupe Admins | Query | 4732 | High | 80 | T1078.003 |
| Service Windows crÃ©Ã© | Query | 7045 | High | 70 | T1543.003 |

---

## DÃ©tail des rÃ¨gles

### RÃ¨gle 1 â€” Brute Force (Threshold)
- **Type** : Threshold
- **Query** : `winlog.event_id : 4625`
- **Condition** : Group by `winlog.event_data.TargetUserName` â€” dÃ©clenche Ã  partir de 5 Ã©checs
- **Runs every** : 5 minutes | **Look-back** : 1 minute
- **Pourquoi** : L'Event ID 4625 est gÃ©nÃ©rÃ© Ã  chaque Ã©chec d'authentification Windows. En regroupant par nom d'utilisateur cible, on dÃ©tecte une tentative de brute force sur un compte spÃ©cifique sans se noyer dans les faux positifs.

### RÃ¨gle 2 â€” PowerShell encodÃ© (Query)
- **Type** : Query
- **Query** : `winlog.event_id : 4104 AND winlog.event_data.ScriptBlockText : *EncodedCommand*`
- **Pourquoi** : L'Event ID 4104 capture les blocs de script PowerShell (Script Block Logging). La prÃ©sence de `-EncodedCommand` dans le script est un indicateur classique d'obfuscation utilisÃ©e par les attaquants pour contourner les politiques d'exÃ©cution.

### RÃ¨gle 3 â€” CrÃ©ation de compte local (Query)
- **Type** : Query
- **Query** : `winlog.event_id : 4720`
- **Pourquoi** : La crÃ©ation d'un compte local en dehors d'un process RH est suspecte, surtout sur un poste de travail. Souvent associÃ© Ã  de la persistance (T1136).

### RÃ¨gle 4 â€” Ajout dans le groupe Administrateurs (Query)
- **Type** : Query
- **Query** : `winlog.event_id : 4732`
- **Pourquoi** : L'ajout d'un compte dans le groupe local Administrators (ou Administrateurs en franÃ§ais) correspond Ã  une Ã©lÃ©vation de privilÃ¨ges. CorrÃ©lÃ© avec la rÃ¨gle 3, cela constitue un scÃ©nario complet de crÃ©ation + escalade.

### RÃ¨gle 5 â€” Service Windows crÃ©Ã© (Query)
- **Type** : Query
- **Query** : `winlog.event_id : 7045`
- **Pourquoi** : Les malwares persistants s'installent souvent comme service Windows. L'Event ID 7045 dans le journal System signale l'installation d'un nouveau service â€” lÃ©gitime ou malveillant.

---

## Webhook vers TheHive

ConfigurÃ© dans **Kibana > Stack Management > Connectors** (type : Webhook).

| ParamÃ¨tre | Valeur |
|---|---|
| URL | `http://PC2_IP:9000/api/v0/alert` |
| MÃ©thode | POST |
| Header | `Authorization: Bearer CLE_API_THEHIVE` |
| Header | `Content-Type: application/json` |

Body :
```json
{
  "title": "{{rule.name}}",
  "description": "Alerte SIEM â€” SÃ©vÃ©ritÃ© : {{rule.severity}}",
  "type": "external",
  "source": "Kibana SIEM",
  "sourceRef": "{{rule.id}}",
  "severity": 2,
  "tags": ["kibana", "automatic"]
}
```

---

## ScÃ©narios testÃ©s et validÃ©s

| ScÃ©nario | Script | RÃ©sultat Kibana | Case TheHive |
|---|---|---|---|
| Brute force 15 tentatives | `attack-simulation.ps1 -Scenario brute-force` | Alerte High | CrÃ©Ã© automatiquement |
| Ajout dans Administrateurs | `attack-simulation.ps1 -Scenario account` | Alerte High | CrÃ©Ã© automatiquement |
| PowerShell -EncodedCommand | `attack-simulation.ps1 -Scenario powershell` | Alerte High | CrÃ©Ã© automatiquement |
| T1547.001 Reg Key Run | Atomic Red Team | Exit code 0 | â€” |
| T1082 System Info Discovery | Atomic Red Team | Exit code 0 | â€” |
