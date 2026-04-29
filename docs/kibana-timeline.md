# Timeline d'attaque - Kibana SIEM

**Nom** : Simulation attaque complete - 29/04/2026
**Machine cible** : DESKTOP-SFHHTTT (PC3)
**Duree** : 10:40:48 - 10:41:10 (22 secondes)
**Total evenements** : 19

---

## Sequence d'attaque reconstituee

| Heure | Event ID | Description | Technique MITRE |
|---|---|---|---|
| 10:40:48 | 4625 | Debut brute force - fakeadmin tentative 1 | T1110 |
| 10:40:48 - 10:40:54 | 4625 x15 | 15 echecs authentification en 6 secondes | T1110 |
| 10:41:08 | 4720 | Creation compte testSOC_lab | T1136.001 |
| 10:41:08 | 4732 | Ajout testSOC_lab dans Utilisateurs | T1078.003 |
| 10:41:08 | 4732 | Ajout testSOC_lab dans Administrateurs | T1078.003 |
| 10:41:10 | 4726 | Suppression compte testSOC_lab | - |

---

## Requete Kibana utilisee

```
winlog.event_id : (4625 or 4104 or 4720 or 4732 or 4726)
```

---

## Observations

- Le brute force a dure exactement 6 secondes (400ms entre chaque tentative)
- La creation de compte a suivi immediatement apres le brute force (20 secondes plus tard)
- L'escalade de privileges (ajout Administrateurs) s'est produite dans la meme seconde que la creation
- La suppression du compte 2 secondes apres l'ajout simule un attaquant qui nettoie ses traces
- Aucun Event ID 4624 (succes de connexion) entre les 4625 - l'attaque a echoue