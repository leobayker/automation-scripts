# powershell

PowerShell automation scripts for Windows Server / Active Directory administration.

---

## Scripts

| Script | Purpose |
|---|---|
| `ad_backup.ps1` | System State backup + DC metadata + replication status export |
| `gpo_export.ps1` | Full GPO export with versioned folders, CSV/TXT inventory report |

---

## Requirements

- Windows Server 2016/2019/2022
- Run as **Domain Admin** on a Domain Controller
- `ad_backup.ps1` — Windows Server Backup feature: `Add-WindowsFeature Windows-Server-Backup`
- `gpo_export.ps1` — RSAT Group Policy Management: `Add-WindowsFeature GPMC`

---

## Usage

### AD Backup

```powershell
# Default destination: \\backup-server\ad-backups
.\ad_backup.ps1

# Custom path and retention
.\ad_backup.ps1 -BackupRoot "D:\Backups\AD" -RetentionDays 14
```

**What it exports:**
- System State backup via `wbadmin` (includes AD database, SYSVOL, registry)
- DCDiag output (replication, services, connectivity tests)
- Replication summary via `repadmin /replsummary`
- DC metadata: hostname, domain, OS, IP, FSMO roles

**Output structure:**
```
\\backup-server\ad-backups\
  2026-03-26_02-00\
    WindowsImageBackup\        # wbadmin System State
    dcdiag_2026-03-26_02-00.txt
    repadmin_2026-03-26_02-00.txt
    dc_info_2026-03-26_02-00.txt
  ad_backup_2026-03-26_02-00.log
```

---

### GPO Export

```powershell
# Default destination: \\backup-server\gpo-backups
.\gpo_export.ps1

# Custom path and retention
.\gpo_export.ps1 -BackupRoot "D:\Backups\GPO" -RetentionDays 30
```

**What it exports:**
- All GPOs via `Backup-GPO` (standard GPMC backup format — importable via GPMC)
- CSV inventory: Name, ID, Status, Created, Modified, BackupStatus
- TXT summary report

**Output structure:**
```
\\backup-server\gpo-backups\
  2026-03-26_02-00\
    {GPO-GUID-1}\              # standard GPO backup folder
    {GPO-GUID-2}\
    gpo_inventory_2026-03-26_02-00.csv
    gpo_inventory_2026-03-26_02-00.txt
  gpo_export_2026-03-26_02-00.log
```

**Restore a GPO from backup:**
```powershell
# Via GPMC GUI: Group Policy Management → Group Policy Objects → right-click → Manage Backups
# Via PowerShell:
Restore-GPO -Name "PolicyName" -Path "\\backup-server\gpo-backups\2026-03-26_02-00"
```

---

## Scheduled Task Setup

Run both scripts daily via Task Scheduler on a Domain Controller:

```powershell
# Create scheduled task for AD backup (runs at 02:00 daily as SYSTEM)
$Action  = New-ScheduledTaskAction -Execute "powershell.exe" `
           -Argument "-NonInteractive -ExecutionPolicy Bypass -File C:\Scripts\ad_backup.ps1"
$Trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
$Settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 2)
Register-ScheduledTask -TaskName "AD Backup" -Action $Action `
    -Trigger $Trigger -Settings $Settings -RunLevel Highest -User "SYSTEM"

# Same pattern for GPO export at 02:30
```

---

## Notes

- Both scripts are idempotent — safe to re-run manually anytime
- Exit code `1` from `gpo_export.ps1` indicates at least one GPO failed to export
- Retention cleanup removes entire timestamped folders older than `RetentionDays`
- Backup destination should be on a separate server/share, not on the DC itself
