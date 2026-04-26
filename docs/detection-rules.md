# Regles de detection Kibana SIEM

## Regle 1 - Brute Force (Threshold)
Type: Threshold | Severite: High | Risk: 75
Index: logs-*
Query: winlog.event_id : 4625
Threshold: Group by winlog.event_data.TargetUserName >= 5
Runs every: 5m | Look-back: 1m
MITRE: T1110 - Brute Force

## Regle 2 - PowerShell encode
Type: Query | Severite: High | Risk: 73
Query: winlog.event_id : 4104 AND winlog.event_data.ScriptBlockText : *EncodedCommand*
MITRE: T1059.001 - PowerShell

## Regle 3 - Creation de compte
Type: Query | Severite: Medium | Risk: 50
Query: winlog.event_id : 4720
MITRE: T1136.001 - Create Local Account

## Regle 4 - Ajout groupe Admins
Type: Query | Severite: High | Risk: 80
Query: winlog.event_id : 4732
MITRE: T1078.003 - Local Accounts

## Regle 5 - Service Windows cree
Type: Query | Severite: High | Risk: 70
Query: winlog.event_id : 7045
MITRE: T1543.003 - Windows Service
