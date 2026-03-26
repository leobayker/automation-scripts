#!/usr/bin/env bash
set -euo pipefail

# setup_mvt_ubuntu.sh
# Idempotent bootstrap script to prepare Ubuntu 22.04+ for Mobile Verification Toolkit (MVT)
# - removes cdrom apt source entries (fixes "insert the disc" apt errors)
# - apt update & upgrade
# - installs required system packages (git, wget, adb, libimobiledevice, build deps, etc.)
# - installs pipx (via apt if available) and ensures PATH
# - installs mvt via pipx
# - runs initial mvt-iocs download
# - creates udev rules so adb/idevice* work without sudo (adds user to plugdev)
# - notes about libimobiledevice limitations
#
# Usage: save as ~/setup_mvt_ubuntu.sh, then run:
#   chmod +x ~/setup_mvt_ubuntu.sh
#   ./setup_mvt_ubuntu.sh
# You will be prompted for sudo password.

info(){ printf "[INFO] %s\n" "$*"; }
warn(){ printf "[WARN] %s\n" "$*"; }
err(){ printf "[ERROR] %s\n" "$*"; }

# --- Ensure script not run as root (we use sudo where needed) ---
if [ "$(id -u)" -eq 0 ]; then
  warn "It is recommended to run this script as a regular user (it will use sudo)."
fi

# --- Remove any cdrom entries from sources.list (fixes apt 'insert disc' errors) ---
if [ -f /etc/apt/sources.list ]; then
  if sudo grep -q "cdrom:" /etc/apt/sources.list 2>/dev/null; then
    info "Removing cdrom entries from /etc/apt/sources.list"
    sudo sed -i.bak '/cdrom:/d' /etc/apt/sources.list || true
    info "Backup of original file saved as /etc/apt/sources.list.bak"
  fi
fi

# --- Update & upgrade ---
info "Updating package lists"
sudo apt-get update -y
info "Upgrading installed packages (can take a while)"
sudo apt-get upgrade -y

# --- Install recommended base packages ---
PKGS=(
  git wget curl unzip jq sqlite3 ca-certificates tzdata
  build-essential pkg-config autoconf automake libtool
  python3 python3-venv python3-pip python3-distutils
  libssl-dev libffi-dev libreadline-dev libsqlite3-dev zlib1g-dev
  libxml2 libxml2-dev libxslt1-dev
  libusb-1.0-0-dev libplist-dev libplist++-dev libusbmuxd-tools usbmuxd ifuse
  libimobiledevice6 libimobiledevice-utils
  android-tools-adb android-tools-fastboot
)
info "Installing system packages via apt (this may take a few minutes)"
sudo apt-get install -y "${PKGS[@]}"

# --- Install pipx (prefer apt package if available) ---
if command -v pipx >/dev/null 2>&1; then
  info "pipx is already installed: $(pipx --version 2>/dev/null || echo 'unknown')"
else
  info "Installing pipx"
  if sudo apt-get install -y pipx >/dev/null 2>&1; then
    info "pipx installed via apt"
  else
    info "apt pipx not available or failed; installing pipx with pip (user)"
    python3 -m pip install --user pipx
  fi
fi

# Ensure pipx path is available in current session and in ~/.profile
PIPX_BIN_PATH="$HOME/.local/bin"
if [[ ":$PATH:" != *":$PIPX_BIN_PATH:"* ]]; then
  info "Adding $PIPX_BIN_PATH to PATH for current session"
  export PATH="$PIPX_BIN_PATH:$PATH"
fi
PROFILE_LINE='export PATH="$HOME/.local/bin:$PATH"'
if ! grep -Fq "$PROFILE_LINE" "$HOME/.profile" 2>/dev/null; then
  info "Appending PATH update to ~/.profile"
  printf "\n# added by setup_mvt_ubuntu.sh\n%s\n" "$PROFILE_LINE" >> "$HOME/.profile"
else
  info "~/.profile already contains local bin PATH entry"
fi

# Try to ensure pipx path is recognized by shell config
if command -v pipx >/dev/null 2>&1; then
  info "Running 'pipx ensurepath' (if available)"
  pipx ensurepath >/dev/null 2>&1 || true
fi

# --- Install MVT via pipx ---
if command -v mvt-ios >/dev/null 2>&1 || command -v mvt-android >/dev/null 2>&1; then
  info "MVT already appears installed"
else
  info "Installing MVT via pipx"
  if command -v pipx >/dev/null 2>&1; then
    pipx install mvt || {
      warn "pipx install failed; trying upgrade"
      pipx upgrade mvt || true
    }
  else
    warn "pipx not found; installing mvt with pip as fallback"
    python3 -m pip install --user mvt
  fi
fi

# --- Ensure mvt command works and download iocs (initial fetch) ---
if command -v mvt-ios >/dev/null 2>&1; then
  info "Running initial 'mvt-ios download-iocs' to fetch indicators (may take a few seconds)"
  mvt-ios download-iocs || warn "mvt-ios download-iocs exited with non-zero code"
fi
if command -v mvt-android >/dev/null 2>&1; then
  info "Running initial 'mvt-android download-iocs' to fetch indicators"
  mvt-android download-iocs || warn "mvt-android download-iocs exited with non-zero code"
fi

# --- Helpful optional tools for iOS/Android forensic workflow ---
info "Installing / configuring additional helpful utilities"
sudo apt-get install -y ssdeep yara || true

# --- udev rules for Android/iOS devices (so adb and idevice* work without sudo) ---
# We create /etc/udev/rules.d/51-android.rules and add common vendor ids.
# Default uses MODE=0660 and GROUP=plugdev (more secure). If you prefer open access use MODE=0666.
UDEV_FILE="/etc/udev/rules.d/51-android.rules"
info "Writing udev rules to $UDEV_FILE (MODE=0660, GROUP=plugdev)"
sudo tee "$UDEV_FILE" > /dev/null <<'UDEV'
# Google
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0660", GROUP="plugdev"
# Xiaomi (example vendor 2717)
SUBSYSTEM=="usb", ATTR{idVendor}=="2717", MODE="0660", GROUP="plugdev"
# Samsung
SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0660", GROUP="plugdev"
# Huawei
SUBSYSTEM=="usb", ATTR{idVendor}=="12d1", MODE="0660", GROUP="plugdev"
# OnePlus / Oppo / Vivo — add if needed
# Apple (for libimobiledevice)
SUBSYSTEM=="usb", ATTR{idVendor}=="05ac", MODE="0660", GROUP="plugdev"
UDEV

info "Reloading udev rules and triggering"
sudo udevadm control --reload-rules
sudo udevadm trigger

# Ensure plugdev group exists and add user to it
if ! getent group plugdev >/dev/null; then
  info "Group plugdev doesn't exist — creating"
  sudo groupadd plugdev || true
fi
info "Adding current user to plugdev group (so adb/idevice work without sudo)"
sudo usermod -aG plugdev "$USER" || true

info "To activate new group membership run 'newgrp plugdev' or logout/login."

# --- Notes about libimobiledevice ---
info "Note: libimobiledevice in distro repos may be older than Apple's latest changes."
info "If you run into 'idevicebackup2' or pairing issues with iOS 16+/17+, consider building libimobiledevice & libusbmuxd from source following upstream docs."

# --- Final messages ---
info "Bootstrap finished."
info "Recommended next steps:"
cat <<EOF
  - Open a NEW terminal (this loads updated PATH from ~/.profile)
  - Verify commands: which mvt-ios mvt-android idevicebackup2 adb
  - To perform iOS checks you may need to pair the device: 'idevicepair pair' (unlock device and tap Trust)
  - If idevicebackup2 fails to produce a full iTunes-style encrypted backup, create the encrypted backup with iTunes on a Windows VM (recommended) and copy it to Ubuntu for MVT analysis.

  - To apply plugdev immediately (no logout/login): run
      newgrp plugdev
    Then check:
      adb devices
      ideviceinfo
EOF

exit 0

