#!/usr/bin/env python3
"""
mikrotik_config.py
------------------
Mass command deployment to all MikroTik routers via SSH using Netmiko.

Real-world use case: change SSH service port across all sites simultaneously.
Adapt COMMANDS list for any RouterOS batch operation.

Usage:
  1. Copy credentials_example.py → credentials.py and fill in your values.
  2. Edit COMMANDS and TARGET below.
  3. python3 mikrotik_config.py

Requirements:
  pip install netmiko
"""

from netmiko import ConnectHandler
from credentials import all_routers

# ---------------------------------------------------------------------------
# Edit here — RouterOS commands to run on every router
# ---------------------------------------------------------------------------
COMMANDS = [
    '/ip service set 6 port=53199',   # Example: change SSH port on all routers
]

# Target group: all_routers, or a custom list from credentials.py
TARGET = all_routers

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
for device in TARGET:
    ssh = ConnectHandler(**device)
    output = ssh.send_config_set(COMMANDS)
    print(f"\n\n-------------- Device {device['host']} --------------")
    print(output)
    print("-------------------- End -------------------")
