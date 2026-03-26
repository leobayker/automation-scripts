# credentials_example.py
# Copy this file to credentials.py and fill in your actual values.
# credentials.py is in .gitignore — NEVER commit it.

from netmiko import ConnectHandler

# ---------------------------------------------------------------------------
# Shared credentials
# ---------------------------------------------------------------------------
SSH_USER = "your_username"
SSH_PASS = "your_password"
SSH_PORT = "22"
READ_TIMEOUT = 90

# ---------------------------------------------------------------------------
# MikroTik routers
# ---------------------------------------------------------------------------
core = {
    'device_type': 'mikrotik_routeros',
    'host': '10.10.0.1',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

site_01 = {
    'device_type': 'mikrotik_routeros',
    'host': '10.10.1.1',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

site_02 = {
    'device_type': 'mikrotik_routeros',
    'host': '10.10.2.1',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

site_03 = {
    'device_type': 'mikrotik_routeros',
    'host': '10.10.3.1',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

site_04 = {
    'device_type': 'mikrotik_routeros',
    'host': '10.10.4.1',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

site_05 = {
    'device_type': 'mikrotik_routeros',
    'host': '10.10.5.1',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

site_06 = {
    'device_type': 'mikrotik_routeros',
    'host': '10.10.6.1',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

site_07 = {
    'device_type': 'mikrotik_routeros',
    'host': '10.10.7.1',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

all_routers = [core, site_01, site_02, site_03, site_04, site_05, site_06, site_07]

# ---------------------------------------------------------------------------
# D-Link DGS switches
# ---------------------------------------------------------------------------
sw_site_01_1 = {
    'device_type': 'dlink_ds',
    'host': '10.10.1.2',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_01_2 = {
    'device_type': 'dlink_ds',
    'host': '10.10.1.3',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_01_3_poe = {
    'device_type': 'dlink_ds',
    'host': '10.10.1.4',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_02_1 = {
    'device_type': 'dlink_ds',
    'host': '10.10.2.2',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_02_2 = {
    'device_type': 'dlink_ds',
    'host': '10.10.2.3',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_02_3 = {
    'device_type': 'dlink_ds',
    'host': '10.10.2.4',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_02_4 = {
    'device_type': 'dlink_ds',
    'host': '10.10.2.5',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_02_5_poe = {
    'device_type': 'dlink_ds',
    'host': '10.10.2.6',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_02_6_poe = {
    'device_type': 'dlink_ds',
    'host': '10.10.2.7',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_02_7_poe = {
    'device_type': 'dlink_ds',
    'host': '10.10.2.8',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_03_1 = {
    'device_type': 'dlink_ds',
    'host': '10.10.3.2',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_03_2 = {
    'device_type': 'dlink_ds',
    'host': '10.10.3.3',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_03_3 = {
    'device_type': 'dlink_ds',
    'host': '10.10.3.4',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_03_4 = {
    'device_type': 'dlink_ds',
    'host': '10.10.3.5',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_03_5_poe = {
    'device_type': 'dlink_ds',
    'host': '10.10.3.6',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_03_6_poe = {
    'device_type': 'dlink_ds',
    'host': '10.10.3.7',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_03_7_poe = {
    'device_type': 'dlink_ds',
    'host': '10.10.3.8',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_04_1 = {
    'device_type': 'dlink_ds',
    'host': '10.10.4.2',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_04_2 = {
    'device_type': 'dlink_ds',
    'host': '10.10.4.3',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_04_3 = {
    'device_type': 'dlink_ds',
    'host': '10.10.4.4',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_04_4_poe = {
    'device_type': 'dlink_ds',
    'host': '10.10.4.5',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_04_5 = {
    'device_type': 'dlink_ds',
    'host': '10.10.4.6',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_05_1 = {
    'device_type': 'dlink_ds',
    'host': '10.10.5.2',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_06_1 = {
    'device_type': 'dlink_ds',
    'host': '10.10.6.2',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_07_1 = {
    'device_type': 'dlink_ds',
    'host': '10.10.7.2',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_07_2 = {
    'device_type': 'dlink_ds',
    'host': '10.10.7.3',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_07_3 = {
    'device_type': 'dlink_ds',
    'host': '10.10.7.4',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

sw_site_07_4 = {
    'device_type': 'dlink_ds',
    'host': '10.10.7.5',
    'port': SSH_PORT,
    'username': SSH_USER,
    'password': SSH_PASS,
    'read_timeout_override': READ_TIMEOUT,
}

# ---------------------------------------------------------------------------
# DGS switch groups
# ---------------------------------------------------------------------------
all_dgs = [
    sw_site_01_1, sw_site_01_2, sw_site_01_3_poe,
    sw_site_02_1, sw_site_02_2, sw_site_02_3, sw_site_02_4,
    sw_site_02_5_poe, sw_site_02_6_poe, sw_site_02_7_poe,
    sw_site_03_1, sw_site_03_2, sw_site_03_3, sw_site_03_4,
    sw_site_03_5_poe, sw_site_03_6_poe, sw_site_03_7_poe,
    sw_site_04_1, sw_site_04_2, sw_site_04_3, sw_site_04_4_poe, sw_site_04_5,
    sw_site_05_1,
    sw_site_06_1,
    sw_site_07_1, sw_site_07_2, sw_site_07_3, sw_site_07_4,
]

dgs_site_01 = [sw_site_01_1, sw_site_01_2, sw_site_01_3_poe]
dgs_site_02 = [sw_site_02_1, sw_site_02_2, sw_site_02_3, sw_site_02_4,
               sw_site_02_5_poe, sw_site_02_6_poe, sw_site_02_7_poe]
dgs_site_03 = [sw_site_03_1, sw_site_03_2, sw_site_03_3, sw_site_03_4,
               sw_site_03_5_poe, sw_site_03_6_poe, sw_site_03_7_poe]
dgs_site_04 = [sw_site_04_1, sw_site_04_2, sw_site_04_3, sw_site_04_4_poe, sw_site_04_5]
dgs_site_07 = [sw_site_07_1, sw_site_07_2, sw_site_07_3, sw_site_07_4]

# ---------------------------------------------------------------------------
# FTP server for config backups
# ---------------------------------------------------------------------------
FTP_HOST = "10.10.0.5"
FTP_USER = "your_ftp_user"
FTP_PASS = "your_ftp_password"
