# Rapport de menace - Simulation Mini-SOC Lab

**Date** : 29/04/2026
**Auteur** : tes@tes
**Plateforme** : OpenCTI 6.0.5
**Format** : STIX 2.1

---

## Contexte

Rapport produit dans OpenCTI suite aux simulations d'attaque realisees sur PC3 (machine cobaye Windows 11).
Le rapport documente les techniques observees, les IOCs identifies et l'acteur fictif utilise en lab.

---

## Acteur - Lab Attacker

- **Type** : Intrusion Set
- **Sophistication** : minimal
- **Resource level** : individual
- **Motivation** : organizational-gain
- **Aliases** : SimulatedThreat

---

## Techniques MITRE ATT&CK observees

| Technique | ID | Description |
|---|---|---|
| Brute Force | T1110 | 15 echecs authentification Event ID 4625 |
| PowerShell | T1059.001 | Execution -EncodedCommand Event ID 4104 |
| Local Accounts | T1078.003 | Ajout dans Administrateurs Event ID 4732 |
| Create Local Account | T1136.001 | Creation compte testSOC_lab Event ID 4720 |

---

## IOCs

| Type | Valeur | Source |
|---|---|---|
| IPv4 | 185.220.101.1 | Simulation - noeud Tor connu |
| username | fakeadmin | Compte cible brute force |
| hostname | DESKTOP-SFHHTTT | Machine cobaye PC3 |

---

## Enrichissement Cortex

### AbuseIPDB - 185.220.101.1
- **Score** : 100/100
- **Rapports** : 50 en 90 jours
- **Tor** : True
- **ISP** : Artikel10 e.V. (Allemagne)
- **Categories** : Web App Attack, Brute Force, Hacking, Port Scan, SQL Injection

### VirusTotal - 185.220.110.1
- **Detection** : 0/91
- **ASN** : 60893 - Art of Automation B.V.
- **Pays** : NL

---

## Fichier STIX 2.1

Le bundle STIX exporte depuis OpenCTI est disponible dans :
`docs/stix-exports/rapport-simulation.json`

Il contient :
- L'objet rapport (type: report)
- L'acteur Lab Attacker (type: intrusion-set)
- Les 3 techniques MITRE liees (type: attack-pattern)
- L'IOC IP (type: ipv4-addr)
- L'indicator STIX (type: indicator)
- Les relations entre ces objets (type: relationship)