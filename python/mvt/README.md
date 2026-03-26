# python/mvt — Mobile Device Security Checks

Bash scripts for automated mobile device forensic analysis using [Mobile Verification Toolkit (MVT)](https://github.com/mvt-project/mvt).

Built for real operational use: batch iOS and Android checks with IOC feeds from CERT-UA, Amnesty Tech, CitizenLab, and URLhaus.

---

## Scripts

| Script | Purpose |
|---|---|
| `setup_mvt_ubuntu.sh` | One-time environment bootstrap on Ubuntu 22.04+ |
| `mvt_iocs_updater.sh` | Download and update IOC/STIX2 feeds from multiple sources |
| `iphone_backup_decrypt_mvt_check.sh` | Full iOS check: encrypted backup → decrypt → MVT analysis |
| `iphone_unencrypted_backup_and_check.sh` | iOS check when backup password is unknown (unencrypted path) |
| `android_mvt_check.sh` | Android check via ADB |

---

## Requirements

- Ubuntu 22.04+
- `libimobiledevice`, `idevicebackup2`, `adb` — installed by `setup_mvt_ubuntu.sh`
- `mvt-ios`, `mvt-android` — installed via pipx by `setup_mvt_ubuntu.sh`
- iPhone: backup password must be set via iTunes on Windows/macOS **before** connecting to Linux
- Android: USB Debugging must be enabled (Developer Options → USB Debugging)

---

## Initial Setup (one-time)

```bash
# 1. Make scripts executable
chmod +x setup_mvt_ubuntu.sh mvt_iocs_updater.sh \
         iphone_backup_decrypt_mvt_check.sh \
         iphone_unencrypted_backup_and_check.sh \
         android_mvt_check.sh

# 2. Run environment bootstrap (installs all dependencies)
./setup_mvt_ubuntu.sh

# 3. Open a new terminal to reload PATH, then verify
which mvt-ios mvt-android idevicebackup2 adb

# 4. Download IOC indicators
./mvt_iocs_updater.sh
```

---

## iOS Check — Encrypted Backup (recommended)

**Prerequisites:** backup password set via iTunes on Windows/macOS.

```bash
# Connect iPhone via USB → Unlock → Trust This Computer
./iphone_backup_decrypt_mvt_check.sh

# Or pass password non-interactively
./iphone_backup_decrypt_mvt_check.sh --password 'YourBackupPassword'
```

**What it does:**
1. Detects device UDID via `idevice_id`
2. Creates timestamped dirs: `~/iphone_backups/`, `~/iphone_backups_decrypted/`, `~/mvt_results_from_backup/`
3. Runs `idevicebackup2 backup --full`
4. Prompts for backup password → runs `mvt-ios decrypt-backup`
5. Runs `mvt-ios check-backup` on decrypted copy
6. Saves results to `~/mvt_results_from_backup/{UDID}_{timestamp}/`

---

## iOS Check — Forgotten Password / No Encryption

```bash
./iphone_unencrypted_backup_and_check.sh
```

**What it does:**
- Attempts backup without enabling encryption
- Reads `Manifest.plist` to detect if backup is encrypted
- If encrypted: prompts for password (3 attempts) or offers to skip decryption
- If unencrypted: runs MVT checks directly on backup

> ⚠️ If password is unknown and device reset is not acceptable — use this script. Note: factory reset loses all settings, Wi-Fi profiles, VPN certificates, app data.

---

## Android Check

```bash
# On the phone: Settings → About phone → tap Build number 7 times
# Settings → Developer options → USB Debugging = ON
# Connect phone, accept "Allow USB debugging" prompt

./android_mvt_check.sh
```

**What it does:**
1. Checks `adb` availability and connected devices
2. Connects via ADB to first detected device
3. Runs `mvt-android check-adb` with IOC feeds from `~/.local/share/mvt/indicators/`
4. Saves results to `~/mvt_android_results/{timestamp}/`

---

## IOC Update

```bash
./mvt_iocs_updater.sh
```

**Sources:**
- `mvt-project/mvt-indicators`
- `AmnestyTech/investigations` (Pegasus STIX2)
- `citizenlab/malware-indicators`
- `AssoEchap/stalkerware-indicators`
- URLhaus CSV (filtered for mobile-relevant domains → converted to STIX2)

**Behavior:**
- Clones/pulls repos, copies `.stix2` and `.json` files to `~/.local/share/mvt/indicators/`
- If file changed → backs up old version to `~/.local/share/mvt/indicators/backup_{timestamp}/`
- Idempotent — safe to re-run anytime

---

## Output Structure

```
~/iphone_backups/{UDID}_{timestamp}/        # raw iTunes-style backup
~/iphone_backups_decrypted/{UDID}_{timestamp}/   # decrypted copy
~/mvt_results_from_backup/{UDID}_{timestamp}/    # MVT JSON results + logs
~/mvt_android_results/{timestamp}/              # Android MVT results
~/.local/share/mvt/indicators/                   # IOC STIX2 files
```

---

## Quick Reference

| Task | Command |
|---|---|
| First-time setup | `./setup_mvt_ubuntu.sh` |
| Update IOCs | `./mvt_iocs_updater.sh` |
| Check iOS (encrypted) | `./iphone_backup_decrypt_mvt_check.sh` |
| Check iOS (no password) | `./iphone_unencrypted_backup_and_check.sh` |
| Check Android | `./android_mvt_check.sh` |

---

## Notes

- `libimobiledevice` in distro repos may be outdated for iOS 16+/17+. If pairing fails — build from source per [upstream docs](https://github.com/libimobiledevice/libimobiledevice)
- All results are stored locally, never transmitted
- IOC feeds include CERT-UA threat intelligence for Ukrainian-specific threats
