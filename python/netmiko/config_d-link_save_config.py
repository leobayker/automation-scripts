#!/usr/bin/env python3
"""
config_d-link_save_config.py
-----------------------------
Save running config and upload to FTP on D-Link DGS switches.

Operations:
  1. Save config to flash (save all / save config config_id 1)
  2. Upload config to FTP server

Usage:
  1. Copy credentials_example.py → credentials.py and fill in your values.
  2. Uncomment the operation you need below.
  3. python3 config_d-link_save_config.py

Requirements:
  pip install netmiko
"""

from netmiko import ConnectHandler
from credentials import all_dgs, dgs_site_01, sw_site_01_1, FTP_HOST, FTP_USER, FTP_PASS

TARGET = all_dgs

# ---------------------------------------------------------------------------
# Operation 1: Save config on all switches
# ---------------------------------------------------------------------------
for device in TARGET:
    ssh = ConnectHandler(**device)
    output = ssh.send_config_set([
        'save all',
        'save config config_id 1',
    ])
    print(f"\n\n-------------- Device {device['host']} --------------")
    print(output)
    print("-------------------- End -------------------")


# ---------------------------------------------------------------------------
# Operation 2: Upload config to FTP (single device example)
# Run manually per device — adjust dest_file name as needed
# ---------------------------------------------------------------------------
# ssh = ConnectHandler(**sw_site_01_1)
# output = ssh.send_command(
#     f'upload cfg_toFTP {FTP_HOST} tcp_port 21 dest_file cfg_site_01_1.txt',
#     expect_string="Connecting to server................... Done."
# )
# print(output)
# output = ssh.send_command(f'{FTP_USER}', expect_string="Pass:")
# print(output)
# ssh.send_command(FTP_PASS)
