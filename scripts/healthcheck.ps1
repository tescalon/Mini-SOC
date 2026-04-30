# healthcheck.ps1
# Verifie l etat de tous les services du Mini-SOC.
#
# Usage : .\healthcheck.ps1 -PC1_IP "192.168.1.52" -PC2_IP "192.168.1.28"

param(
    [Parameter(Mandatory=$true)] [string]$PC1_IP,
    [Parameter(Mandatory=$true)] [string]$PC2_IP
)

function Test-Service {
    param([string]$Name, [string]$Url)
    try {
        Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop | Out-Null
        Write-Host "  [OK] $Name" -ForegroundColor Green
    } catch {
        Write-Host "  [KO] $Name ($Url)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Mini-SOC Healthcheck ===" -ForegroundColor Cyan
Write-Host "PC1 - SIEM ($PC1_IP)" -ForegroundColor Yellow
Test-Service "Elasticsearch" "http://${PC1_IP}:9200"
Test-Service "Kibana"        "http://${PC1_IP}:5601"
Test-Service "Logstash"      "http://${PC1_IP}:9600"
Write-Host "PC2 - SOAR + CTI ($PC2_IP)" -ForegroundColor Yellow
Test-Service "TheHive"  "http://${PC2_IP}:9000"
Test-Service "Cortex"   "http://${PC2_IP}:9001"
Test-Service "OpenCTI"  "http://${PC2_IP}:8080"
Write-Host "Termine." -ForegroundColor Cyan