<#
.SYNOPSIS
    Enables Remote Desktop (RDP) on this Windows machine.
.DESCRIPTION
    - Flips the RDP registry switch on
    - Opens the Windows Firewall for Remote Desktop
    - Enables Network Level Authentication (NLA)
    - Verifies the service is listening on port 3389
    - Warns if Group Policy is overriding the setting

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

Write-Host "`n=== Enabling Remote Desktop ===" -ForegroundColor Cyan

# 1. Enable RDP connections
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
    -Name 'fDenyTSConnections' -Value 0
Write-Host "[+] RDP connections enabled (fDenyTSConnections = 0)"

# 2. Open the firewall for RDP
Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
Write-Host "[+] Firewall opened for Remote Desktop"

# 3. Require Network Level Authentication (more secure)
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' `
    -Name 'UserAuthentication' -Value 1
Write-Host "[+] Network Level Authentication enabled"

# 4. Make sure the service is running and starts automatically
Set-Service -Name TermService -StartupType Automatic
Start-Service -Name TermService -ErrorAction SilentlyContinue
Write-Host "[+] TermService set to Automatic and started"

# --- Verification ---
Write-Host "`n=== Verification ===" -ForegroundColor Cyan

$svc = Get-Service TermService
Write-Host ("TermService status : {0}" -f $svc.Status)

$listen = Get-NetTCPConnection -LocalPort 3389 -State Listen -ErrorAction SilentlyContinue
if ($listen) {
    Write-Host "[+] Listening on port 3389" -ForegroundColor Green
} else {
    Write-Host "[!] NOT listening on port 3389 yet" -ForegroundColor Red
}

# --- Group Policy override check ---
$gp = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' `
    -Name 'fDenyTSConnections' -ErrorAction SilentlyContinue
if ($gp -and $gp.fDenyTSConnections -eq 1) {
    Write-Host "`n[WARNING] Group Policy is forcing RDP OFF (fDenyTSConnections = 1)." -ForegroundColor Red
    Write-Host "          The changes above may be reverted on gpupdate or reboot." -ForegroundColor Red
    Write-Host "          You likely need IT/admin to allow RDP via policy." -ForegroundColor Red
}

# --- Show this machine's LAN IPs for convenience ---
Write-Host "`n=== Connect to one of these IPs from your Linux box ===" -ForegroundColor Cyan
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
    Select-Object IPAddress, InterfaceAlias | Format-Table -AutoSize

Write-Host "Done. From Linux:  xfreerdp /v:<IP-above> /u:<YourUser> /multimon`n" -ForegroundColor Green
