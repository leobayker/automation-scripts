# bash

Bash setup and maintenance scripts for infrastructure and security tooling on Ubuntu 22.04+.

---

## Scripts

| Script | Purpose |
|---|---|
| `setup_mvt_ubuntu.sh` | Bootstrap Ubuntu 22.04+ for MVT mobile forensics |
| `mvt_iocs_updater.sh` | Download and refresh IOC/STIX2 threat intelligence feeds |

See [`../python/mvt/README.md`](../python/mvt/README.md) for full MVT workflow documentation.

---

## Usage

```bash
chmod +x setup_mvt_ubuntu.sh mvt_iocs_updater.sh

# One-time setup
./setup_mvt_ubuntu.sh

# Update IOCs (run regularly or before each check session)
./mvt_iocs_updater.sh
```
