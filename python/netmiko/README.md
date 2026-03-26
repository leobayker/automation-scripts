# python/netmiko

SSH-based mass configuration management for MikroTik routers and D-Link DGS switches using [Netmiko](https://github.com/ktbyers/netmiko).

---

## Scripts

| Script | Target | Purpose |
|---|---|---|
| `mikrotik_config.py` | MikroTik RouterOS | Mass command deployment to all routers simultaneously |
| `config_d-link.py` | D-Link DGS | SSL certificate generation + HTTPS enable across all switches |
| `config_d-link_save_config.py` | D-Link DGS | Save config to flash + optional FTP upload |

---

## Requirements

```bash
pip install netmiko
```

---

## Setup

```bash
# 1. Copy credentials template
cp ../../credentials_example.py ../../credentials.py

# 2. Fill in credentials.py — SSH user/pass, device IPs, FTP details
# credentials.py is gitignored — never commit it
```

---

## Usage

### MikroTik — change SSH port on all routers

Edit `COMMANDS` in `mikrotik_config.py`:

```python
COMMANDS = [
    '/ip service set 6 port=53199',
]
```

```bash
python3 mikrotik_config.py
```

### D-Link — enable SSL on all switches

```bash
python3 config_d-link.py
```

### D-Link — save config on all switches

```bash
python3 config_d-link_save_config.py
```

### D-Link — upload config to FTP (single device)

Uncomment Operation 2 in `config_d-link_save_config.py`, set target device and filename.

---

## Architecture

```
credentials.py              # All credentials + device inventory (gitignored)
  ├── all_routers           # All MikroTik routers
  ├── all_dgs               # All D-Link switches
  ├── dgs_site_01..07       # Per-site switch groups
  └── FTP_HOST/USER/PASS    # FTP server for config uploads
```

Key design decisions:
- `read_timeout_override: 90` on all devices — DGS switches can be slow
- Site-based grouping — run operations on subset of devices without editing the script
- FTP credentials in `credentials.py`, never inline in scripts
