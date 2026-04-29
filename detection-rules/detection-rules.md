# Regles de detection Kibana SIEM

Configurees dans Kibana > Security > Rules.
Toutes les regles Windows sont mappees sur MITRE ATT&CK.

---

## Vue d'ensemble

| Regle | Source | Type | Event/Query | Severite | MITRE |
|---|---|---|---|---|---|
| Brute Force connexion | Winlogbeat | Threshold | 4625 >= 5 | High | T1110 |
| PowerShell encode | Winlogbeat | Query | 4104 | High | T1059.001 |
| Creation de compte local | Winlogbeat | Query | 4720 | Medium | T1136.001 |
| Ajout dans groupe Admins | Winlogbeat | Query | 4732 | High | T1078.003 |
| Service Windows cree | Winlogbeat | Query | 7045 | High | T1543.003 |
| Alertes Suricata | Filebeat | Query | event.module:suricata | High | Reseau |

---

## Regles Windows

### Regle 1 - Brute Force (Threshold)
- **Index** : logs-*
- **Query** : `winlog.event_id : 4625`
- **Condition** : Group by `winlog.event_data.TargetUserName` >= 5
- **Runs every** : 5 minutes | **Look-back** : 1 minute
- **Pourquoi** : 5 echecs d'authentification sur le meme compte en 1 minute = brute force.

### Regle 2 - PowerShell encode (Query)
- **Query** : `winlog.event_id : 4104 AND winlog.event_data.ScriptBlockText : *EncodedCommand*`
- **Pourquoi** : -EncodedCommand est utilise pour obfusquer les payloads malveillants.

### Regle 3 - Creation de compte local (Query)
- **Query** : `winlog.event_id : 4720`
- **Pourquoi** : Creation de compte hors process RH = persistance potentielle.

### Regle 4 - Ajout dans le groupe Administrateurs (Query)
- **Query** : `winlog.event_id : 4732`
- **Pourquoi** : Elevation de privileges. Combine avec 4720 = creation + escalade.

### Regle 5 - Service Windows cree (Query)
- **Query** : `winlog.event_id : 7045`
- **Pourquoi** : Les malwares persistants s'installent souvent comme service Windows.

---

## Regle reseau (Suricata)

### Regle 6 - Alertes Suricata (Query)
- **Index** : filebeat-*
- **Query** :
```
event.module : suricata AND event.kind : alert
AND NOT destination.port : (9200 or 5601 or 5044)
AND NOT source.port : (9200 or 5601 or 5044)
AND NOT suricata.eve.alert.signature : "GPL ATTACK_RESPONSE id check returned root"
```
- **Runs every** : 5 minutes
- **Pourquoi** : Detecte les alertes reseau generees par Suricata (49 864 regles ET).
  Les exclusions evitent le bruit du trafic interne ELK.

---

## Webhook vers TheHive

Configure dans Kibana > Stack Management > Connectors (type : Webhook).

| Parametre | Valeur |
|---|---|
| URL | `http://PC2_IP:9000/api/v0/alert` |
| Methode | POST |
| Header | `Authorization: Bearer CLE_API_THEHIVE` |
| Header | `Content-Type: application/json` |

Body :
```json
{
  "title": "{{rule.name}}",
  "description": "Alerte SIEM - Severite : {{rule.severity}}",
  "type": "external",
  "source": "Kibana SIEM",
  "sourceRef": "{{rule.id}}",
  "severity": 2,
  "tags": ["kibana", "automatic"]
}
```

---

## Scenarios testes et valides

| Scenario | Outil | Resultat Kibana | Case TheHive |
|---|---|---|---|
| Brute force 15 tentatives | attack-simulation.ps1 | Alerte High | Cree automatiquement |
| Ajout dans Administrateurs | attack-simulation.ps1 | Alerte High | Cree automatiquement |
| PowerShell -EncodedCommand | attack-simulation.ps1 | Alerte High | Cree automatiquement |
| ET USER_AGENTS BlackSun | curl -A BlackSun | Alerte High | Cree automatiquement |
| GPL ATTACK_RESPONSE | curl testmynids.org | Detecte par Suricata | - |
