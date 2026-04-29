# Regles de detection Kibana SIEM

| Regle | Type | Event ID | Severite | Risk | MITRE |
|---|---|---|---|---|---|
| Brute Force connexion | Threshold >=5 | 4625 | High | 75 | T1110 |
| PowerShell encode | Query | 4104 | High | 73 | T1059.001 |
| Compte ajoute groupe Admins | Query | 4732 | High | 80 | T1078.003 |
| Connexion RDP | Query | 4624 LogonType 10 | Medium | 55 | T1021.001 |
| Acces LSASS - Credential Dump | Query | Sysmon 10 lsass | Critical | 90 | T1003.001 |

## Details

### Regle 1 - Brute Force (Threshold)
- Index : logs-*
- Query : winlog.event_id : 4625
- Threshold : Group by winlog.event_data.TargetUserName >= 5
- Runs every: 5m | Look-back: 1m

### Regle 2 - PowerShell encode
- Query : winlog.event_id : 4104 AND winlog.event_data.ScriptBlockText : *EncodedCommand*

### Regle 3 - Compte ajoute groupe Admins
- Query : winlog.event_id : 4732

### Regle 4 - Connexion RDP
- Query : winlog.event_id : 4624 AND winlog.event_data.LogonType : 10

### Regle 5 - Acces LSASS
- Query : winlog.event_id : 10 AND winlog.event_data.TargetImage : *lsass*

## Webhook TheHive
- URL    : http://IP_PC2:9000/api/v0/alert
- Method : POST
- Headers: Authorization: Bearer CLE_API | Content-Type: application/json
- Body   : {"title":"{{rule.name}}","description":"Alerte SIEM - Severite : {{rule.severity}}","type":"external","source":"Kibana SIEM","sourceRef":"{{rule.id}}","severity":2,"tags":["kibana","automatic"]}

## Scenarios testes et valides
- Brute force 15 tentatives -> alerte High Kibana + case TheHive auto
- Ajout compte Administrateurs -> alerte High
- PowerShell -EncodedCommand -> alerte High
- T1547.001 Reg Key Run (Atomic Red Team) -> Exit code 0
- T1082 System Information Discovery -> Exit code 0
