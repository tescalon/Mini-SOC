# Workflow analyste - TheHive 4

Documentation du processus de reponse aux incidents applique durant le lab.

---

## Case #2 - Brute Force fakeadmin

**Titre** : Brute Force - fakeadmin - PC3
**Severite** : High
**TLP** : Amber
**Statut** : Resolved - True Positive
**Assignee** : tes@tes

### Observables

| Type | Valeur | IOC |
|---|---|---|
| ip | IP de PC3 | Oui |
| hostname | DESKTOP-SFHHTTT | Oui |
| other | fakeadmin | Oui |

### Tasks executees

| Task | Statut | Notes |
|---|---|---|
| Investigation | Completed | 15 echecs 4625 sur fakeadmin en 6s. Confirme True Positive. T1110. |
| Containment | Completed | IP source locale - pas de blocage firewall necessaire en lab |
| Eradication | Completed | Aucune persistance installee |
| Recovery | Completed | Integrite systeme verifiee |
| Lessons Learned | Completed | Regle Kibana declenchee correctement, webhook TheHive fonctionnel |

### Resolution

- **Type** : True Positive
- **Summary** : Brute force confirme sur fakeadmin depuis PC3. 15 echecs Event 4625 en 6 secondes. Simule via attack-simulation.ps1. Aucun acces reussi. Technique MITRE T1110.

---

## Analyzers Cortex testes

| Analyzer | Observable | Resultat |
|---|---|---|
| AbuseIPDB_2_0 | 185.220.101.1 | Score 100/100 - Tor - 50 rapports |
| VirusTotal_GetReport_3_1 | 185.220.110.1 | 0/91 - IP propre |

---

## Templates de case crees

### Brute Force Investigation
Tasks : Investigation, Containment, Eradication, Recovery, Lessons Learned
TLP : Amber
Tags : brute-force