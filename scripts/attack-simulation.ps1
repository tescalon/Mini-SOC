# attack-simulation.ps1 - Simuler des attaques sur le PC cobaye
param([string]$Scenario = "all")
Write-Host "=== Mini-SOC Attack Simulation ===" -ForegroundColor Cyan

function Test-BruteForce {
    Write-Host "[*] Brute Force (Event ID 4625)" -ForegroundColor Yellow
    1..15 | ForEach-Object {
        $pass = ConvertTo-SecureString "wrongpass$_" -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential("fakeadmin", $pass)
        try { Start-Process cmd -Credential $cred -NoNewWindow -ErrorAction SilentlyContinue } catch {}
        Start-Sleep -Milliseconds 400
    }
    Write-Host "[+] 15 echecs de connexion generes" -ForegroundColor Green
}

function Test-PowerShell {
    Write-Host "[*] PowerShell encode (Event ID 4104)" -ForegroundColor Yellow
    $cmd = "Write-Host 'Test SOC PowerShell encode'"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
    powershell.exe -EncodedCommand $encoded
    Write-Host "[+] OK" -ForegroundColor Green
}

function Test-AccountCreation {
    Write-Host "[*] Creation compte (Event IDs 4720, 4732)" -ForegroundColor Yellow
    net user testSOC_lab P@ssSOC2024! /add 2>$null
    net localgroup Administrators testSOC_lab /add 2>$null
    Start-Sleep -Seconds 2
    net user testSOC_lab /delete 2>$null
    Write-Host "[+] OK" -ForegroundColor Green
}

switch ($Scenario) {
    "brute-force" { Test-BruteForce }
    "powershell"  { Test-PowerShell }
    "account"     { Test-AccountCreation }
    "all" { Test-BruteForce; Start-Sleep 3; Test-PowerShell; Start-Sleep 3; Test-AccountCreation }
}
Write-Host "Verifie Kibana > Security > Alerts dans 5 minutes" -ForegroundColor Cyan
