#Requires -RunAsAdministrator
<#
.SYNOPSIS
    ad_backup.ps1 — Automated Active Directory backup to network share.

.DESCRIPTION
    Exports critical AD data on a schedule:
      - System State backup via Windows Server Backup (wbadmin)
      - AD database and SYSVOL state info
      - Domain controller metadata (DCDiag summary)
      - Timestamped versioned folders for retention management

    Designed to run as a Scheduled Task on a Domain Controller.

.PARAMETER BackupRoot
    UNC path or local path for backup destination.
    Default: \\backup-server\ad-backups  (edit to match your environment)

.PARAMETER RetentionDays
    Number of days to keep old backups. Default: 30

.EXAMPLE
    .\ad_backup.ps1
    .\ad_backup.ps1 -BackupRoot "D:\Backups\AD" -RetentionDays 14

.NOTES
    Requirements:
      - Windows Server Backup feature installed: Add-WindowsFeature Windows-Server-Backup
      - Run as Domain Admin on a Domain Controller
      - Scheduled Task: daily at 02:00, runs as SYSTEM or Domain Admin
#>

[CmdletBinding()]
param(
    [string]$BackupRoot = "\\backup-server\ad-backups",
    [int]$RetentionDays = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
$Timestamp   = Get-Date -Format "yyyy-MM-dd_HH-mm"
$BackupDir   = Join-Path $BackupRoot $Timestamp
$LogFile     = Join-Path $BackupRoot "ad_backup_$Timestamp.log"
$DcName      = $env:COMPUTERNAME
$Domain      = (Get-WmiObject Win32_ComputerSystem).Domain

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $line = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
Write-Log "=== AD Backup Started === DC: $DcName | Domain: $Domain"
Write-Log "Destination: $BackupDir"

# Create backup directory
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
Write-Log "Backup directory created: $BackupDir"

# --- 1. DCDiag summary ---
Write-Log "Running DCDiag..."
$DcDiagOut = Join-Path $BackupDir "dcdiag_$Timestamp.txt"
try {
    dcdiag /test:replications /test:services /test:connectivity 2>&1 |
        Out-File -FilePath $DcDiagOut -Encoding UTF8
    Write-Log "DCDiag output saved: $DcDiagOut"
} catch {
    Write-Log "DCDiag failed: $_" "WARN"
}

# --- 2. Replication status ---
Write-Log "Collecting replication status..."
$ReplOut = Join-Path $BackupDir "repadmin_$Timestamp.txt"
try {
    repadmin /replsummary 2>&1 | Out-File -FilePath $ReplOut -Encoding UTF8
    Write-Log "Replication summary saved: $ReplOut"
} catch {
    Write-Log "repadmin failed: $_" "WARN"
}

# --- 3. Domain Controller info ---
Write-Log "Exporting DC metadata..."
$DcInfoOut = Join-Path $BackupDir "dc_info_$Timestamp.txt"
try {
    $DcInfo = @"
Backup Date : $Timestamp
DC Name     : $DcName
Domain      : $Domain
OS Version  : $((Get-WmiObject Win32_OperatingSystem).Caption)
IP Address  : $((Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object -First 1).IPAddress)
FSMO Roles  :
$((netdom query fsmo 2>&1) -join "`n")
"@
    $DcInfo | Out-File -FilePath $DcInfoOut -Encoding UTF8
    Write-Log "DC info saved: $DcInfoOut"
} catch {
    Write-Log "DC info export failed: $_" "WARN"
}

# --- 4. System State backup via wbadmin ---
Write-Log "Starting System State backup (wbadmin)..."
$WbadminLog = Join-Path $BackupDir "wbadmin_$Timestamp.txt"
try {
    $WbArgs = "start systemstatebackup -backupTarget:`"$BackupDir`" -quiet"
    $proc = Start-Process -FilePath "wbadmin.exe" `
                          -ArgumentList $WbArgs `
                          -Wait -PassThru `
                          -RedirectStandardOutput $WbadminLog `
                          -NoNewWindow
    if ($proc.ExitCode -eq 0) {
        Write-Log "System State backup completed successfully."
    } else {
        Write-Log "wbadmin exited with code $($proc.ExitCode) — check $WbadminLog" "WARN"
    }
} catch {
    Write-Log "wbadmin failed: $_" "WARN"
}

# --- 5. Retention — remove old backups ---
Write-Log "Applying retention policy: $RetentionDays days..."
try {
    $Cutoff = (Get-Date).AddDays(-$RetentionDays)
    Get-ChildItem -Path $BackupRoot -Directory |
        Where-Object { $_.CreationTime -lt $Cutoff } |
        ForEach-Object {
            Write-Log "Removing old backup: $($_.FullName)"
            Remove-Item -Path $_.FullName -Recurse -Force
        }
    Write-Log "Retention cleanup complete."
} catch {
    Write-Log "Retention cleanup failed: $_" "WARN"
}

Write-Log "=== AD Backup Finished ==="
