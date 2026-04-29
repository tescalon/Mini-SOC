# auto-analyze.ps1
# Lance automatiquement AbuseIPDB et VirusTotal sur tous les nouveaux
# observables IP dans TheHive. Tourne en boucle toutes les 5 minutes.
#
# Installe comme tache planifiee sur PC2 avec :
#   .\install-auto-analyze-task.ps1
#
# Usage manuel :
#   powershell.exe -ExecutionPolicy Bypass -File auto-analyze.ps1

$THEHIVE   = "http://localhost:9000"
$API_KEY   = "CLE_API_THEHIVE"
$ANALYZERS = @("AbuseIPDB_2_0", "VirusTotal_GetReport_3_1")
$processed = @{}

Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Auto-analyze demarre" -ForegroundColor Cyan
Write-Host "Surveillance des observables IP toutes les 5 minutes..." -ForegroundColor Cyan

while ($true) {
    try {
        # Recuperer tous les observables IP dans TheHive
        $body = '{"query":[{"_name":"listObservable"},{"_name":"filter","_field":"dataType","_value":"ip"}]}'
        $obs = (Invoke-WebRequest `
            -Uri "$THEHIVE/api/v1/query?name=artifacts" `
            -Method POST `
            -Headers @{
                Authorization  = "Bearer $API_KEY"
                "Content-Type" = "application/json"
            } `
            -Body $body -UseBasicParsing).Content | ConvertFrom-Json

        foreach ($o in $obs) {
            $key = "$($o._id)"
            # Traiter uniquement les observables pas encore analyses dans cette session
            if (-not $processed.ContainsKey($key)) {
                foreach ($analyzer in $ANALYZERS) {
                    $b = @{
                        artifactId = $o._id
                        cortexId   = "Cortex-SOC"
                        analyzerId = $analyzer
                    } | ConvertTo-Json
                    try {
                        Invoke-WebRequest `
                            -Uri "$THEHIVE/api/connector/cortex/job" `
                            -Method POST `
                            -Headers @{
                                Authorization  = "Bearer $API_KEY"
                                "Content-Type" = "application/json"
                            } `
                            -Body $b -UseBasicParsing | Out-Null
                        Write-Host "$(Get-Date -Format 'HH:mm:ss') - $analyzer lance sur $($o.data)" `
                            -ForegroundColor Green
                    } catch {
                        Write-Host "$(Get-Date -Format 'HH:mm:ss') - Erreur $analyzer sur $($o.data)" `
                            -ForegroundColor Red
                    }
                }
                $processed[$key] = $true
            }
        }
    } catch {
        Write-Host "$(Get-Date -Format 'HH:mm:ss') - Erreur connexion TheHive" -ForegroundColor Yellow
    }

    Start-Sleep -Seconds 300
}
