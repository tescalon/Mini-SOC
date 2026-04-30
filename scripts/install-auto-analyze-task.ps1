# install-auto-analyze-task.ps1
# Installe auto-analyze.ps1 comme tache planifiee Windows sur PC2.
# Lancer en administrateur une seule fois.

$scriptDest = "C:\soc\auto-analyze.ps1"
if (!(Test-Path "C:\soc")) { New-Item -ItemType Directory -Path "C:\soc" -Force | Out-Null }

$src = Join-Path $PSScriptRoot "auto-analyze.ps1"
Copy-Item $src $scriptDest -Force
Write-Host "Script copie : $scriptDest" -ForegroundColor Green

$action    = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File $scriptDest"
$trigger   = New-ScheduledTaskTrigger -AtStartup
$settings  = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

Register-ScheduledTask -TaskName "TheHive-AutoAnalyze" `
    -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null

Write-Host "Tache planifiee creee - demarre au prochain reboot" -ForegroundColor Green
Write-Host "Demarrer maintenant : Start-ScheduledTask -TaskName 'TheHive-AutoAnalyze'" -ForegroundColor Yellow