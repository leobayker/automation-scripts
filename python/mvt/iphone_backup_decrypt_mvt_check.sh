#!/usr/bin/env bash
set -euo pipefail

# iphone_backup_auto_pw.sh  (itunes-only password workflow)
# - Не намагається увімкнути шифрування на пристрої.
# - Припускає: якщо потрібен пароль — ти задаєш його через iTunes.
# - Скрипт робить backup (idevicebackup2), потім просить пароль тільки для дешифрування.
# - Опціонально: можна передати --password <pw> для спроби non-interactive decryption.
#
# Usage: ./iphone_backup_auto_pw.sh [--password <pw>]

BACKUP_BASE="$HOME/iphone_backups"
DECRYPTED_BASE="$HOME/iphone_backups_decrypted"
MVT_OUTPUT_BASE="$HOME/mvt_results_from_backup"

info(){ printf "\e[1;34m[INFO]\e[0m %s\n" "$*"; }
warn(){ printf "\e[1;33m[WARN]\e[0m %s\n" "$*"; }
err(){ printf "\e[1;31m[ERROR]\e[0m %s\n" "$*"; }

# --- parse optional arg ---
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
  --password, -p   optionally provide backup password (used ONLY for decryption attempts)
EOF
      exit 0
      ;;
    *)
      echo "Unknown arg: $1"; exit 2
      ;;
  esac
done

# --- checks ---
for cmd in idevice_id idevicepair idevicebackup2 mvt-ios; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "Required command not found: $cmd. Install libimobiledevice and mvt."
    exit 3
  fi
done

# --- device discovery & pairing ---
UDID=$(idevice_id -l | head -n1 || true)
if [ -z "$UDID" ]; then
  err "No device detected. Connect iPhone, unlock and press Trust."
  exit 4
fi
info "Device UDID: $UDID"

info "Pairing (if required) — unlock device and press Trust if prompted..."
set +e
idevicepair pair >/dev/null 2>&1 || true
set -e

# --- unique directories ---
TS=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_BASE/${UDID}_${TS}"
DECRYPT_DIR="$DECRYPTED_BASE/${UDID}_${TS}"
MVT_OUTPUT_DIR="$MVT_OUTPUT_BASE/${UDID}_${TS}"
mkdir -p "$BACKUP_DIR" "$DECRYPT_DIR" "$MVT_OUTPUT_DIR"

info "Backup dir: $BACKUP_DIR"
info "Decrypted dir: $DECRYPT_DIR"
info "MVT results dir: $MVT_OUTPUT_DIR"

# --- NOTE: do NOT attempt to enable encryption here ---
info "NOTE: this script does NOT enable encryption on the device."
info "If you want encrypted backups, set the backup password via iTunes on a Windows/macOS machine before connecting the phone to this Ubuntu host."
info "Proceeding to perform a backup (will NOT try to enable encryption)."

# --- perform backup ---
info "Starting full backup (may take a while)..."
# Let idevicebackup2 handle prompting itself if it needs a password (we don't set BACKUP_PASSWORD here)
if idevicebackup2 backup --full "$BACKUP_DIR" 2>&1 | tee "$BACKUP_DIR/backup_command.log"; then
  info "Backup finished: $BACKUP_DIR"
else
  warn "Backup command exited non-zero — check $BACKUP_DIR/backup_command.log for details. Continuing to decryption attempt."
fi

# --- decryption with mvt (only here we accept password) ---
info "Decrypting backup using mvt-ios. Script will prompt for the backup password ONLY at this stage (unless --password was provided)."

DECRYPT_OK=0
if [ -n "$USER_PW" ]; then
  info "Trying non-interactive mvt decrypt using provided --password."
  if mvt-ios decrypt-backup -p "$USER_PW" -d "$DECRYPT_DIR" "$BACKUP_DIR"; then
    info "Decryption successful using provided --password."
    DECRYPT_OK=1
  else
    warn "Non-interactive decryption with provided --password failed."
  fi
fi

if [ $DECRYPT_OK -eq 0 ]; then
  for attempt in 1 2 3; do
    read -rsp "Enter backup password for decryption (attempt $attempt of 3): " ENTERED_PW
    echo
    if [ -z "$ENTERED_PW" ]; then
      warn "Empty password entered; try again."
      continue
    fi
    info "Attempting decryption (attempt $attempt)..."
    if mvt-ios decrypt-backup -p "$ENTERED_PW" -d "$DECRYPT_DIR" "$BACKUP_DIR"; then
      info "Decryption succeeded."
      DECRYPT_OK=1
      break
    else
      warn "Decryption failed with that password."
    fi
  done
fi

if [ $DECRYPT_OK -eq 0 ]; then
  err "All decryption attempts failed. You can retry manually later with:"
  echo "  mvt-ios decrypt-backup -d \"$DECRYPT_DIR\" \"$BACKUP_DIR\""
  exit 7
fi

# quick sanity check
if find "$DECRYPT_DIR" -maxdepth 2 -type f -name 'Manifest.db' | grep -q .; then
  info "Manifest.db found in decrypted copy — decryption likely OK."
else
  warn "Manifest.db NOT found in decrypted copy — decryption may be incomplete or failed."
fi

# --- run MVT check-backup on decrypted copy ---
info "Running mvt-ios check-backup --output \"$MVT_OUTPUT_DIR\" \"$DECRYPT_DIR\""
mvt-ios download-iocs || warn "mvt-ios download-iocs failed (non-fatal)."
if mvt-ios check-backup --output "$MVT_OUTPUT_DIR" "$DECRYPT_DIR"; then
  info "MVT check-backup finished. Results: $MVT_OUTPUT_DIR"
else
  warn "MVT check-backup finished with errors or no detections. Check logs in $MVT_OUTPUT_DIR"
fi

# --- final summary ---
echo
info "Summary:"
echo "  Raw backup:     $BACKUP_DIR"
echo "  Decrypted copy: $DECRYPT_DIR"
echo "  MVT results:    $MVT_OUTPUT_DIR"
info "Done."
exit 0

