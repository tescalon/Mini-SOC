# attack-simulation.ps1
# Simule des scenarios d'attaque Windows pour tester les regles Kibana SIEM.
# A lancer en administrateur sur PC3 (machine cobaye Windows 11).
#
# Usage :
#   .\attack-simulation.ps1                        # Tous les scenarios
#   .\attack-simulation.ps1 -Scenario brute-force  # Scenario specifique
#   .\attack-simulation.ps1 -Scenario powershell
#   .\attack-simulation.ps1 -Scenario account

param(
    [string]$Scenario = "all"
)

function Invoke-BruteForce {
    Write-Host "[*] Scenario : Brute Force (T1110) - 15 echecs Event 4625" -ForegroundColor Yellow
    1..15 | ForEach-Object {
        $pass = ConvertTo-SecureString "wrongpass$_" -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential("fakeadmin", $pass)
        try {
            Start-Process cmd -Credential $cred -NoNewWindow -ErrorAction SilentlyContinue
        } catch {}
        Start-Sleep -Milliseconds 400
    }
    Write-Host "[OK] Brute force termine - 15 echecs generes" -ForegroundColor Green
}

function Invoke-PowerShellEncoded {
    Write-Host "[*] Scenario : PowerShell encode (T1059.001) - Event 4104" -ForegroundColor Yellow
    $cmd = "Write-Host 'Test SOC PowerShell encode - Mini-SOC Lab'"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
    powershell.exe -EncodedCommand $encoded
    Write-Host "[OK] PowerShell encode execute - Event 4104 genere" -ForegroundColor Green
}

function Invoke-AccountCreation {
    Write-Host "[*] Scenario : Creation compte + escalade (T1136.001 + T1078.003)" -ForegroundColor Yellow
    net user testSOC_lab P@ssSOC2024! /add
    Write-Host "  [+] Compte testSOC_lab cree - Event 4720" -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    net localgroup Administrateurs testSOC_lab /add 2>$null
    net localgroup Administrators testSOC_lab /add 2>$null
    Write-Host "  [+] Ajout dans Administrateurs - Event 4732" -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    net user testSOC_lab /delete
    Write-Host "  [+] Compte supprime - Event 4726" -ForegroundColor Cyan
    Write-Host "[OK] Scenario compte termine" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Mini-SOC Attack Simulation ===" -ForegroundColor Magenta
Write-Host "Les alertes remontent dans Kibana sous 5 minutes." -ForegroundColor White
Write-Host ""

switch ($Scenario) {
    "brute-force" { Invoke-BruteForce }
    "powershell"  { Invoke-PowerShellEncoded }
    "account"     { Invoke-AccountCreation }
    "all" {
        Invoke-BruteForce
        Start-Sleep -Seconds 3
        Invoke-PowerShellEncoded
        Start-Sleep -Seconds 3
        Invoke-AccountCreation
        Write-Host ""
        Write-Host "[OK] Tous les scenarios executes" -ForegroundColor Green
        Write-Host "Verifier Kibana > Security > Alerts dans 5 minutes" -ForegroundColor Yellow
    }
    default {
        Write-Host "Scenario inconnu : $Scenario" -ForegroundColor Red
        Write-Host "Scenarios disponibles : brute-force, powershell, account, all"
        exit 1
    }
}
