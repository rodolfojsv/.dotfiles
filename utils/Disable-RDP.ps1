<#
.SYNOPSIS
    Disables Remote Desktop (RDP) on this Windows machine.
.DESCRIPTION
    Reverses Enable-RDP.ps1:
    - Flips the RDP registry switch off
    - Closes the Windows Firewall for Remote Desktop
    - Verifies nothing is listening on port 3389

    Run on the Windows machine in an elevated (Administrator) PowerShell.
    This script self-elevates if not already running as admin.
#>

# --- Self-elevate to Administrator if needed ---
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Not running as admin -- relaunching elevated..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Write-Host "`n=== Disabling Remote Desktop ===" -ForegroundColor Cyan

# 1. Disable RDP connections
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
    -Name 'fDenyTSConnections' -Value 1
Write-Host "[+] RDP connections disabled (fDenyTSConnections = 1)"

# 2. Close the firewall for RDP
Disable-NetFirewallRule -DisplayGroup 'Remote Desktop'
Write-Host "[+] Firewall closed for Remote Desktop"

# --- Verification ---
Write-Host "`n=== Verification ===" -ForegroundColor Cyan

$listen = Get-NetTCPConnection -LocalPort 3389 -State Listen -ErrorAction SilentlyContinue
if ($listen) {
    Write-Host "[!] Still listening on port 3389 (existing sessions may keep it open until they close / reboot)" -ForegroundColor Yellow
} else {
    Write-Host "[+] Not listening on port 3389" -ForegroundColor Green
}

Write-Host "`nDone. RDP is disabled.`n" -ForegroundColor Green
