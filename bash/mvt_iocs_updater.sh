#!/usr/bin/env bash
set -euo pipefail

# fetch_iocs_for_mvt_final.sh
# Final version per user's request.
# - Завантажує та оновлює декілька репозиторіїв з IOC/STIX2
# - Завантажує URLhaus, витягує домени і конвертує в STIX2
# - Копіює результуючі .stix2 файли прямо в ~/.local/share/mvt/indicators/
# - Робить бекап перезаписуваних файлів у ~/.local/share/mvt/indicators/backup_TIMESTAMP/
# - При повторному запуску оновлює репозиторії та лише замінює змінені файли
# Вимоги: git, wget, python3

# --- Налаштування ---
DEST="$HOME/.local/share/mvt/indicators"
TMPDIR="$HOME/.cache/mvt_iocs_final_tmp"
BACKUP_ROOT="$DEST/backup_$(date +%F_%H%M%S)"
CUSTOM_DIR="$HOME/custom_iocs"   # додаткові ручні файли (не обов'язково)

# Список git-репозиторіїв для клонування/оновлення (швидко додавай/редагуй тут)
REPOS=(
  "https://github.com/mvt-project/mvt-indicators.git"
  "https://github.com/AmnestyTech/investigations.git"
  "https://github.com/citizenlab/malware-indicators.git"
  "https://github.com/AssoEchap/stalkerware-indicators.git"
)

# Додаткові прямі .stix2 або raw посилання (wget буде намагатися їх завантажити)
RAW_STIX_URLS=(
  "https://raw.githubusercontent.com/AmnestyTech/investigations/master/2021-07-18_nso/pegasus.stix2"
)

# URLhaus CSV (буде зконвертований у STIX2 та покладений у DEST)
URLHAUS_CSV_URL="https://urlhaus.abuse.ch/downloads/csv_recent/"
URLHAUS_STIX_BASENAME="urlhaus_mobile_from_recent.stix2"

# Фільтри для URLhaus -> доменів (можна відредагувати при потребі)
# Мінімальні фільтри, щоб зменшити шум: шукаємо APK/IPA/mobile в шляху, або субдомени m., mobile., api., app., dl., update.
MOBILE_KEYWORDS=("/mobile/" "/android" "/ios" ".apk" ".ipa" "play.google" "itunes.apple" "app=" "/app/" "/m/")
MOBILE_SUBS=("m" "mobile" "api" "app" "dl" "update" "push" "cdn")
MIN_DOMAIN_LEN=4
MAX_URLHAUS_DOMAINS=0   # 0 = no limit

# --- Підготовка ---
mkdir -p "$DEST"
mkdir -p "$TMPDIR"
mkdir -p "$CUSTOM_DIR"

echo "[+] Destination indicators dir: $DEST"
echo "[+] Temp dir: $TMPDIR"

# --- Клон/оновлення репозиторіїв ---
for repo in "${REPOS[@]}"; do
  name=$(basename "$repo" .git)
  localdir="$TMPDIR/$name"
  echo "\n[repo] Processing $repo -> $localdir"
  if [ -d "$localdir/.git" ]; then
    echo " - updating existing clone"
    git -C "$localdir" pull --quiet || echo "git pull failed for $name"
  else
    echo " - cloning"
    git clone --depth 1 "$repo" "$localdir" || echo "git clone failed for $repo"
  fi
  # знайдемо всі .stix2 та .json (IOC) і підготуємо їх для копіювання
  find "$localdir" -type f \( -iname '*.stix2' -o -iname '*.json' \) -print0 | while IFS= read -r -d '' f; do
    base=$(basename "$f")
    destfile="$DEST/$base"
    if [ -f "$destfile" ]; then
      if ! cmp -s "$f" "$destfile"; then
        echo " - UPDATED: $base (will backup existing and copy new)"
        mkdir -p "$BACKUP_ROOT"
        mv "$destfile" "$BACKUP_ROOT/"
        cp -a "$f" "$destfile"
      else
        echo " - SKIP (identical): $base"
      fi
    else
      echo " - NEW: copying $base"
      cp -a "$f" "$destfile"
    fi
  done
done

# --- Завантажити raw .stix2 посилання ---
for url in "${RAW_STIX_URLS[@]}"; do
  out="$DEST/$(basename "$url")"
  echo "\n[raw] Fetching $url -> $out"
  if curl -fsS -o "$out" "$url" ; then
    echo " - saved $out"
  else
    echo " - failed to download $url (skipping)"
    rm -f "$out" 2>/dev/null || true
  fi
done

# --- URLhaus: завантажити CSV, відфільтрувати домени, створити STIX і покласти у DEST ---
echo "\n[urlhaus] Downloading URLhaus CSV..."
URLHAUS_CSV="$TMPDIR/urlhaus_recent.csv"
if wget -q -O "$URLHAUS_CSV" "$URLHAUS_CSV_URL" ; then
  echo " - saved $URLHAUS_CSV"
  # Екстрагуємо колону з URL (2nd field), видаляємо заголовок
  tail -n +2 "$URLHAUS_CSV" | cut -d',' -f2 | tr -d '"' > "$TMPDIR/urlhaus_urls_raw.txt"
  # Фільтрація на Python
  python3 - <<PY
import urllib.parse, re, sys
raw="$TMPDIR/urlhaus_urls_raw.txt"
out="$TMPDIR/urlhaus_filtered_domains.txt"
mpk=${MOBILE_KEYWORDS[*]!}
msub=${MOBILE_SUBS[*]!}
minlen=${MIN_DOMAIN_LEN}
maxdomains=${MAX_URLHAUS_DOMAINS}
mpk_list=[k.lower() for k in mpk.split()] if isinstance(mpk,str) else []
msub_list=[k.lower() for k in msub.split()] if isinstance(msub,str) else []
domains=set()
with open(raw) as fh:
    for line in fh:
        u=line.strip()
        if not u: continue
        if not re.match(r'^https?://', u, re.I):
            u='http://' + u
        try:
            p=urllib.parse.urlparse(u)
            host=p.hostname
            path=(p.path or '') + ('?' + p.query if p.query else '')
            if not host: continue
            h=host.lower()
        except:
            continue
        matched=False
        if any(kw in path.lower() for kw in mpk_list):
            matched=True
        if not matched and len(h.split('.'))>=3:
            sub=h.split('.')[0]
            if any(sub.startswith(s) for s in msub_list):
                matched=True
        if not matched and any(s in h for s in msub_list):
            matched=True
        if matched and len(h)>=minlen:
            domains.add(h)
        if maxdomains>0 and len(domains)>=maxdomains:
            break
with open(out,'w') as fo:
    for d in sorted(domains): fo.write(d+'\n')
print('URLhaus filtered domains ->', out, 'count=', len(domains))
PY
  FILTERED="$TMPDIR/urlhaus_filtered_domains.txt"
  if [ -s "$FILTERED" ]; then
    # Конвертуємо у STIX2 і покладемо у DEST
    STIX_OUT="$DEST/$URLHAUS_STIX_BASENAME"
    python3 - <<PY2
import sys,uuid,json,datetime
inp='$FILTERED'; out='$STIX_OUT'
now=datetime.datetime.utcnow().replace(microsecond=0).isoformat()+'Z'
bundle={'type':'bundle','id':'bundle--'+str(uuid.uuid4()),'objects':[]}
with open(inp) as f:
    for line in f:
        d=line.strip()
        if not d: continue
        obj={'type':'indicator','spec_version':'2.1','id':'indicator--'+str(uuid.uuid4()),'created':now,'modified':now,'name':d,'pattern':f"[domain-name:value = '{d}']",'pattern_type':'stix','valid_from':now,'labels':['malicious','mobile','urlhaus']}
        bundle['objects'].append(obj)
with open(out,'w') as fo: json.dump(bundle,fo,indent=2)
print('Wrote STIX ->', out)
PY2
  else
    echo " - No filtered domains produced"
  fi
else
  echo " - failed to download urlhaus csv"
fi

# --- Додатково: скопіювати локальні .stix2 із ~/custom_iocs якщо такі є ---
if [ -d "$CUSTOM_DIR" ]; then
  echo "\n[local] copying user stix files from $CUSTOM_DIR -> $DEST"
  find "$CUSTOM_DIR" -maxdepth 1 -type f -name '*.stix2' -print0 | while IFS= read -r -d '' f; do
    base=$(basename "$f")
    destfile="$DEST/$base"
    if [ -f "$destfile" ]; then
      if ! cmp -s "$f" "$destfile"; then
        mkdir -p "$BACKUP_ROOT"
        mv "$destfile" "$BACKUP_ROOT/"
        cp -a "$f" "$destfile"
        echo " - updated $base (backup saved)"
      else
        echo " - skip identical $base"
      fi
    else
      cp -a "$f" "$destfile"
      echo " - added $base"
    fi
  done
fi

# --- Права та власник ---
chmod 644 "$DEST"/*.stix2 2>/dev/null || true
chown "$USER":"$USER" "$DEST"/*.stix2 2>/dev/null || true

# --- Підсумок ---
echo "\nDone. Summary:"
echo " - backed up files (if any) -> $BACKUP_ROOT"
echo " - total stix files in $DEST: " $(find "$DEST" -maxdepth 1 -type f -name '*.stix2' | wc -l)

echo "You can now run: mvt-ios download-iocs && mvt-ios check-backup --output ~/mvt_results ~/decrypt/"

# cleanup tmp
rm -rf "$TMPDIR"

exit 0

