#!/usr/bin/env bash
set -euo pipefail

# iphone_unencrypted_backup_and_check.sh
# Purpose: attempt to create an unencrypted backup and run MVT checks;
# - does NOT try to enable/disable encryption on device
# - if backup is encrypted, prompts for password for decryption (optional)
#
# Usage:
#   ./iphone_unencrypted_backup_and_check.sh
#   ./iphone_unencrypted_backup_and_check.sh --password 'MyPass'    # optional, used only for decryption attempt
#
# Notes:
# - If device has encryption enabled and you do not know the password,
#   you CANNOT produce an unencrypted backup of previously encrypted data.
#   See script messages for options.

BACKUP_BASE="$HOME/iphone_backups"
DECRYPT_BASE="$HOME/iphone_backups_decrypted"
MVT_OUT_BASE="$HOME/mvt_results_from_backup"

info(){ printf "\e[1;34m[INFO]\e[0m %s\n" "$*"; }
warn(){ printf "\e[1;33m[WARN]\e[0m %s\n" "$*"; }
err(){ printf "\e[1;31m[ERROR]\e[0m %s\n" "$*"; }

# parse optional --password
USER_PW=""
while [ $# -gt 0 ]; do
  case "$1" in
    --password|-p)
      shift
      USER_PW="${1-}"
      shift
      ;;
    --help|-h)
      cat <<EOF
Usage: $0 [--password <pw>]
  Attempts an unencrypted backup (does not enable/disable device encryption).
  --password, -p  optional: use provided password for decryption attempt if backup is encrypted.
EOF
      exit 0
      ;;
    *)
      echo "Unknown arg: $1"; exit 2
      ;;
  esac
done

# checks
for cmd in idevice_id idevicepair idevicebackup2 mvt-ios python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "Required command not found: $cmd. Install it before running this script."
    exit 3
  fi
done

# device
UDID=$(idevice_id -l | head -n1 || true)
if [ -z "$UDID" ]; then
  err "No device detected. Connect iPhone, unlock and press Trust on the device."
  exit 4
fi
info "Device UDID: $UDID"

info "Pairing (best-effort). Unlock device and press Trust if requested..."
set +e
idevicepair pair >/dev/null 2>&1 || true
set -e

TS=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_BASE/${UDID}_${TS}"
DECRYPT_DIR="$DECRYPT_BASE/${UDID}_${TS}"
MVT_DIR="$MVT_OUT_BASE/${UDID}_${TS}"
mkdir -p "$BACKUP_DIR" "$DECRYPT_DIR" "$MVT_DIR"

info "Backup path: $BACKUP_DIR"
info "Decrypted path: $DECRYPT_DIR"
info "MVT output: $MVT_DIR"

# perform backup (no BACKUP_PASSWORD env used)
info "Starting idevicebackup2 backup (this will be unencrypted if device allows it)..."
idevicebackup2 backup --full "$BACKUP_DIR" 2>&1 | tee "$BACKUP_DIR/backup_command.log" || {
  warn "Backup command failed or returned non-zero. Check $BACKUP_DIR/backup_command.log"
}

# check Manifest.plist to see whether backup ended up encrypted
MANIFEST_PLIST="$BACKUP_DIR/Manifest.plist"
if [ ! -f "$MANIFEST_PLIST" ]; then
  warn "Manifest.plist not found in backup directory. Backup may have failed or idevicebackup2 layout differs. Check $BACKUP_DIR"
  exit 5
fi

info "Inspecting Manifest.plist for IsEncrypted..."
ISENCRYPTED=$(python3 - <<PY
import plistlib,sys
p="$MANIFEST_PLIST"
try:
    with open(p,'rb') as f:
        d=plistlib.load(f)
    v = d.get('IsEncrypted')
    print('true' if v else 'false')
except Exception as e:
    print('error')
PY
)

if [ "$ISENCRYPTED" = "error" ]; then
  warn "Couldn't read Manifest.plist cleanly. Proceeding cautiously."
fi

if [ "$ISENCRYPTED" = "true" ]; then
  warn "The backup is ENCRYPTED (IsEncrypted: true)."
  echo
  echo "Options:"
  echo "  1) Provide the backup password now to attempt decryption (enter at prompt)"
  echo "  2) Skip decryption and keep encrypted backup (you won't be able to run MVT checks on encrypted data)"
  read -rp "Choose 1 (decrypt) or 2 (skip, default 1): " CH
  CH=${CH:-1}
  if [ "$CH" = "2" ]; then
    info "Skipping decryption. Encrypted backup is at: $BACKUP_DIR"
    info "You can retry later with known password: mvt-ios decrypt-backup -d \"$DECRYPT_DIR\" \"$BACKUP_DIR\""
    exit 0
  fi

  # attempt decryption: try provided --password first, otherwise prompt interactively up to 3 attempts
  DECRYPTED=0
  if [ -n "$USER_PW" ]; then
    info "Trying non-interactive decryption using supplied --password..."
    if mvt-ios decrypt-backup -p "$USER_PW" -d "$DECRYPT_DIR" "$BACKUP_DIR"; then
      info "Decryption successful."
      DECRYPTED=1
    else
      warn "Non-interactive decryption failed with supplied password."
    fi
  fi

  if [ $DECRYPTED -eq 0 ]; then
    for i in 1 2 3; do
      read -rsp "Enter backup password for decryption (attempt $i of 3): " P
      echo
      if [ -z "$P" ]; then
        warn "Empty password — try again."
        continue
      fi
      if mvt-ios decrypt-backup -p "$P" -d "$DECRYPT_DIR" "$BACKUP_DIR"; then
        info "Decryption successful."
        DECRYPTED=1
        break
      else
        warn "Decryption failed with that password."
      fi
    done
  fi

  if [ $DECRYPTED -eq 0 ]; then
    err "All decryption attempts failed. Without the correct password you cannot analyze encrypted backup. Options: recover/find password, or reset device (will lose encrypted backups)."
    echo "Reference: MVT/libimobiledevice behavior re: encrypted backups."
    exit 6
  fi

  # run mvt on decrypted directory
  info "Running mvt-ios check-backup on decrypted copy..."
  mvt-ios download-iocs || warn "download-iocs failed (non-fatal)"
  if mvt-ios check-backup --output "$MVT_DIR" "$DECRYPT_DIR"; then
    info "MVT check complete. Results: $MVT_DIR"
  else
    warn "MVT finished with errors or no detections. Check $MVT_DIR for logs."
  fi

else
  info "Backup appears UNENCRYPTED (IsEncrypted: false). Running MVT checks directly on backup."
  mvt-ios download-iocs || warn "download-iocs failed (non-fatal)"
  if mvt-ios check-backup --output "$MVT_DIR" "$BACKUP_DIR"; then
    info "MVT check complete. Results: $MVT_DIR"
  else
    warn "MVT finished with errors or no detections. Check $MVT_DIR for logs."
  fi
fi

info "Done. Raw backup: $BACKUP_DIR"
[ -d "$DECRYPT_DIR" ] && info "Decrypted dir (if any): $DECRYPT_DIR"
info "MVT results: $MVT_DIR"
exit 0

