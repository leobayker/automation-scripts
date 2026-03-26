# automation-scripts

Python, PowerShell, and Bash automation scripts for network infrastructure management.

Built for real production use across a multi-site network: MikroTik routers + D-Link DGS switches + Windows Server stack.

---

## Repository Structure

```
automation-scripts/
├── python/
│   ├── netmiko/          # SSH-based mass config management (MikroTik, D-Link DGS)
│   └── mvt/              # Mobile device security audit automation (iOS/Android)
├── powershell/           # AD / GPO backup and administration
├── bash/                 # Linux setup and environment scripts
├── credentials_example.py
└── .gitignore
```

---

## Scripts Overview

### Python / Netmiko

| Script | Description |
|---|---|
| `python/netmiko/mikrotik_config.py` | Execute RouterOS commands on all MikroTik routers simultaneously |
| `python/netmiko/config_d-link.py` | Generate SSL cert and enable HTTPS on all D-Link DGS switches |
| `python/netmiko/config_d-link_save_config.py` | Save config to flash + FTP upload on all switches |

Tested on: MikroTik CCR series • D-Link DGS-3000, DGS-1210

### Python / MVT

| Script | Description |
|---|---|
| `python/mvt/mvt_ios_check.py` | Automated MVT check for iOS with IOC updates from CERT-UA |
| `python/mvt/mvt_android_check.py` | Automated MVT check for Android devices |

### PowerShell

| Script | Description |
|---|---|
| `powershell/ad_backup.ps1` | Active Directory backup automation |
| `powershell/gpo_export.ps1` | GPO export with versioned backup |

### Bash

| Script | Description |
|---|---|
| `bash/mvt_env_setup.sh` | MVT environment setup on Ubuntu 22.04 |

---

## Getting Started

```bash
git clone https://github.com/leobayker/automation-scripts.git
cd automation-scripts

pip install netmiko

cp credentials_example.py credentials.py
# Edit credentials.py — add your device IPs and credentials
```

---

## Security

- `credentials.py` is in `.gitignore` — never commit it
- All device names and IPs in this repo are anonymized (site-01..site-07, 10.10.X.X)
- No real hostnames, passwords, or internal DNS records
