# install-auto-analyze-task.ps1
# Installe auto-analyze.ps1 comme tache planifiee Windows sur PC2.
# Lance en admin une seule fois.

$scriptDest = "C:\soc\auto-analyze.ps1"

# Copier le script dans C:\soc
if (!(Test-Path "C:\soc")) {
    New-Item -ItemType Directory -Path "C:\soc" -Force | Out-Null
}

$repoScript = Join-Path $PSScriptRoot "auto-analyze.ps1"
if (Test-Path $repoScript) {
    Copy-Item $repoScript $scriptDest -Force
    Write-Host "Script copie dans $scriptDest" -ForegroundColor Green
} else {
    Write-Host "Fichier source introuvable : $repoScript" -ForegroundColor Red
    exit 1
}

# Creer la tache planifiee
$action    = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File $scriptDest"
$trigger   = New-ScheduledTaskTrigger -AtStartup
$settings  = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -RestartOnIdle $false
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

Register-ScheduledTask `
    -TaskName "TheHive-AutoAnalyze" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Force | Out-Null

Write-Host "Tache planifiee TheHive-AutoAnalyze creee" -ForegroundColor Green
Write-Host "Elle demarrera automatiquement au prochain reboot." -ForegroundColor Yellow
Write-Host "Pour demarrer maintenant :" -ForegroundColor Yellow
Write-Host "  Start-ScheduledTask -TaskName 'TheHive-AutoAnalyze'" -ForegroundColor White
