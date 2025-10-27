#!/usr/bin/env bash
set -euo pipefail

STATE_DIR=".github/automation"
STATE_FILE="$STATE_DIR/daily_state.json"
LOGFILE="$STATE_DIR/commits.log"
TODAY=$(date -u +%F)

# Folosim commit author = kimberlyjones6039
git config user.name "kimberlyjones6039"
git config user.email "mateigarcia130@gmail.com"

mkdir -p "$STATE_DIR"

# Încarcă starea curentă (date, target, commits_made)
if [ -f "$STATE_FILE" ]; then
  read -r STATE_DATE STATE_TARGET STATE_COUNT <<EOF
$(python - <<PY
import json
s=json.load(open("$STATE_FILE"))
print(s.get("date",""), s.get("target",0), s.get("commits_made",0))
PY
)
EOF
else
  STATE_DATE=""
  STATE_TARGET=0
  STATE_COUNT=0
fi

# Dacă e o nouă zi, alege un target aleator între 5 și 15 și resetează contorul
if [ "$STATE_DATE" != "$TODAY" ]; then
  STATE_TARGET=$(python - <<PY
import random
print(random.randint(5,15))
PY
)
  STATE_COUNT=0
fi

# Daca mai sunt commit-uri de făcut azi, creăm unul (max 1 pe rulare)
if [ "$STATE_COUNT" -lt "$STATE_TARGET" ]; then
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "Commit $((STATE_COUNT+1))/${STATE_TARGET} at ${TIMESTAMP}" >> "$LOGFILE"
  STATE_COUNT=$((STATE_COUNT+1))

  # Salvăm starea actualizată
  python - <<PY
import json
s={"date":"$TODAY","target":$STATE_TARGET,"commits_made":$STATE_COUNT}
open("$STATE_FILE","w").write(json.dumps(s))
PY

  git add "$LOGFILE" "$STATE_FILE"
  git commit -m "ci: automated daily commit (${TIMESTAMP}) #${STATE_COUNT}/${STATE_TARGET}"
  git push
else
  echo "Target ${STATE_TARGET} commits already reached for ${TODAY} (${STATE_COUNT})"
fi

