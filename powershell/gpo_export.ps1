#Requires -Modules GroupPolicy
<#
.SYNOPSIS
    gpo_export.ps1 — Export all GPOs to versioned backup folder.

.DESCRIPTION
    Exports all Group Policy Objects in the domain to a timestamped folder.
    Each GPO is exported as a separate subfolder (standard GPO backup format).
    Also generates a summary report (CSV + TXT) for documentation.

    Designed to run as a Scheduled Task on a Domain Controller.

.PARAMETER BackupRoot
    Destination path for GPO backups.
    Default: \\backup-server\gpo-backups  (edit to match your environment)

.PARAMETER RetentionDays
    Number of days to keep old backup sets. Default: 60

.EXAMPLE
    .\gpo_export.ps1
    .\gpo_export.ps1 -BackupRoot "D:\Backups\GPO" -RetentionDays 30

.NOTES
    Requirements:
      - RSAT: Group Policy Management Tools
      - Run as Domain Admin on a Domain Controller or management workstation
      - Module: GroupPolicy (included with GPMC / RSAT)
#>

[CmdletBinding()]
param(
    [string]$BackupRoot   = "\\backup-server\gpo-backups",
    [int]$RetentionDays   = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Import-Module GroupPolicy -ErrorAction Stop

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
$Timestamp  = Get-Date -Format "yyyy-MM-dd_HH-mm"
$BackupDir  = Join-Path $BackupRoot $Timestamp
$LogFile    = Join-Path $BackupRoot "gpo_export_$Timestamp.log"
$CsvReport  = Join-Path $BackupDir  "gpo_inventory_$Timestamp.csv"
$TxtReport  = Join-Path $BackupDir  "gpo_inventory_$Timestamp.txt"
$Domain     = (Get-WmiObject Win32_ComputerSystem).Domain

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
Write-Log "=== GPO Export Started === Domain: $Domain"
Write-Log "Destination: $BackupDir"

New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

# --- 1. Get all GPOs ---
Write-Log "Retrieving all GPOs..."
$AllGPOs = Get-GPO -All -Domain $Domain
Write-Log "Found $($AllGPOs.Count) GPO(s)."

# --- 2. Export each GPO ---
$Results = @()
$Success = 0
$Failed  = 0

foreach ($GPO in $AllGPOs) {
    try {
        $BackupResult = Backup-GPO -Guid $GPO.Id -Path $BackupDir -Domain $Domain
        Write-Log "OK: $($GPO.DisplayName) → $($BackupResult.BackupDirectory)"
        $Results += [PSCustomObject]@{
            Name         = $GPO.DisplayName
            Id           = $GPO.Id
            Status       = $GPO.GpoStatus
            Created      = $GPO.CreationTime
            Modified     = $GPO.ModificationTime
            BackupId     = $BackupResult.Id
            BackupStatus = "OK"
        }
        $Success++
    } catch {
        Write-Log "FAILED: $($GPO.DisplayName) — $_" "WARN"
        $Results += [PSCustomObject]@{
            Name         = $GPO.DisplayName
            Id           = $GPO.Id
            Status       = $GPO.GpoStatus
            Created      = $GPO.CreationTime
            Modified     = $GPO.ModificationTime
            BackupId     = ""
            BackupStatus = "FAILED: $_"
        }
        $Failed++
    }
}

# --- 3. Save inventory report ---
Write-Log "Saving inventory report..."
$Results | Export-Csv -Path $CsvReport -NoTypeInformation -Encoding UTF8
Write-Log "CSV report: $CsvReport"

$TxtContent = @"
GPO Export Report
=================
Date     : $Timestamp
Domain   : $Domain
Total    : $($AllGPOs.Count)
Success  : $Success
Failed   : $Failed

GPO List:
---------
$($Results | Format-Table Name, Status, Modified, BackupStatus -AutoSize | Out-String)
"@
$TxtContent | Out-File -FilePath $TxtReport -Encoding UTF8
Write-Log "TXT report: $TxtReport"

# --- 4. Retention cleanup ---
Write-Log "Applying retention: $RetentionDays days..."
try {
    $Cutoff = (Get-Date).AddDays(-$RetentionDays)
    Get-ChildItem -Path $BackupRoot -Directory |
        Where-Object { $_.CreationTime -lt $Cutoff } |
        ForEach-Object {
            Write-Log "Removing old export: $($_.FullName)"
            Remove-Item -Path $_.FullName -Recurse -Force
        }
    Write-Log "Retention cleanup complete."
} catch {
    Write-Log "Retention cleanup failed: $_" "WARN"
}

Write-Log "=== GPO Export Finished === Success: $Success | Failed: $Failed ==="

# Exit with error code if any GPO failed
if ($Failed -gt 0) { exit 1 }
