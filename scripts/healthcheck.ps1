# healthcheck.ps1 - Verifier l'etat du SOC
param([string]$PC1_IP = "192.168.1.22", [string]$PC2_IP = "192.168.1.51")
Write-Host "=== SOC Healthcheck ===" -ForegroundColor Cyan
$services = @(
    @{Name="Elasticsearch"; Url="http://${PC1_IP}:9200"},
    @{Name="Kibana";        Url="http://${PC1_IP}:5601"},
    @{Name="TheHive";       Url="http://${PC2_IP}:9000"},
    @{Name="Cortex";        Url="http://${PC2_IP}:9001"},
    @{Name="OpenCTI";       Url="http://${PC2_IP}:8080"}
)
foreach ($svc in $services) {
    try {
        Invoke-WebRequest -Uri $svc.Url -TimeoutSec 5 -ErrorAction Stop | Out-Null
        Write-Host "[OK] $($svc.Name)" -ForegroundColor Green
    } catch {
        Write-Host "[KO] $($svc.Name) - $($svc.Url)" -ForegroundColor Red
    }
}
