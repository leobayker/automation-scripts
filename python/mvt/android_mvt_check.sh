#!/usr/bin/env bash
set -euo pipefail

# check_android_mvt.sh
# Завдання: перевірка Android-пристрою через MVT
# Використання: chmod +x check_android_mvt.sh && ./check_android_mvt.sh

# --- Директорії для результатів ---
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULT_DIR="$HOME/mvt_android_results/$TIMESTAMP"
mkdir -p "$RESULT_DIR"

echo "[INFO] MVT results directory: $RESULT_DIR"

# --- Перевірка, чи підключений Android ---
if ! command -v adb &>/dev/null; then
    echo "[ERROR] adb не встановлено. Встановіть пакет 'adb'."
    exit 1
fi

DEVICE_COUNT=$(adb devices | awk 'NR>1 && $2=="device"' | wc -l)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "[ERROR] Android-пристроїв не знайдено. Переконайтеся, що увімкнено налагодження по USB та пристрій розблокований."
    exit 1
fi

DEVICE_ID=$(adb devices | awk 'NR>1 && $2=="device" {print $1}' | head -n1)
echo "[INFO] Знайдено Android-пристрій: $DEVICE_ID"

# --- Підключення через ADB ---
echo "[INFO] Перевірка з'єднання з пристроєм..."
adb -s "$DEVICE_ID" wait-for-device
adb -s "$DEVICE_ID" shell getprop ro.build.version.release >/dev/null
echo "[INFO] З'єднання встановлено."

# --- Запуск MVT ---
if ! command -v mvt-android &>/dev/null; then
    echo "[ERROR] MVT не встановлено. Виконайте 'pipx install mvt'."
    exit 1
fi

echo "[INFO] Запуск MVT для перевірки пристрою..."
mvt-android check-adb --output "$RESULT_DIR" --iocs ~/.local/share/mvt/indicators/custom/*.stix2

echo "[INFO] Перевірка завершена. Результати у: $RESULT_DIR"

