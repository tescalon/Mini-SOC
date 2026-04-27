# Troubleshooting - Problemes rencontres et solutions

## ELK Stack

### Kibana : unable to authenticate user [kibana]
Cause   : ELASTICSEARCH_USERNAME=kibana au lieu de kibana_system
Solution: Corriger dans docker-compose.yml puis docker compose up -d --force-recreate kibana

### curl -u ne fonctionne pas dans PowerShell
Cause   : PowerShell aliase curl vers Invoke-WebRequest
Solution: Utiliser curl.exe ou docker exec elasticsearch curl ...

### Webhook Kibana vers TheHive : date manquante
Cause   : API v1 TheHive exige un champ date
Solution: Utiliser api/v0/alert au lieu de api/v1/alert

## Cortex

### No module named cortexutils
Cause   : Image Cortex sans Python ni cortexutils
Solution: Creer Dockerfile custom (voir thehive/Dockerfile-cortex)

### GPG error apt.corretto.aws lors du build Docker
Cause   : Cle GPG Amazon expiree
Solution: rm -f /etc/apt/sources.list.d/corretto.list avant apt-get update

## OpenCTI

### Attack Patterns vides malgre import reussi
Cause   : Worker seul trop lent pour 83000 messages RabbitMQ
Solution: Scale a 3 workers - supprimer container_name du worker dans compose :
  docker compose up -d --scale worker=3

### OpenCTI redemarre en boucle apres suppression index ES
Cause   : Cache Redis corrompu
Solution:
  docker compose down
  docker volume rm opencti_redis_data opencti_rabbitmq_data
  docker compose up -d redis rabbitmq minio
  Start-Sleep 20
  docker compose up -d opencti worker connector-mitre

## Git / GitHub

### remote: GH007 push would publish private email
Solution:
  git config user.email tescalon@users.noreply.github.com
  git commit --amend --reset-author --no-edit
  git push origin main --force

### Updates were rejected - fetch first
Solution: git pull origin main --rebase puis git push

## Winlogbeat / PC cobaye

### net localgroup Administrators - groupe inexistant (Windows francais)
Solution: Utiliser Administrateurs (avec s) en francais

### Winlogbeat bloque a l arret
Solution: Stop-Process -Name winlogbeat -Force puis Start-Service winlogbeat

### IP PC1 change apres reboot (DHCP)
Solution: Mettre a jour winlogbeat.yml et redemarrer le service
  Restart-Service winlogbeat
