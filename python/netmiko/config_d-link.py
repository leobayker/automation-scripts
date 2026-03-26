#!/usr/bin/env python3
"""
config_d-link.py
----------------
Generate SSL certificate and enable HTTPS on all D-Link DGS switches.

Usage:
  1. Copy credentials_example.py → credentials.py and fill in your values.
  2. Adjust TARGET group if needed (all_dgs or site-specific group).
  3. python3 config_d-link.py

Requirements:
  pip install netmiko
"""

from netmiko import ConnectHandler
from credentials import all_dgs

TARGET = all_dgs

for device in TARGET:
    ssh = ConnectHandler(**device)
    output = ssh.send_config_set([
        'config ssl certificate generate',
        'enable ssl',
    ])
    print(f"\n\n-------------- Device {device['host']} --------------")
    print(output)
    print("-------------------- End -------------------")
