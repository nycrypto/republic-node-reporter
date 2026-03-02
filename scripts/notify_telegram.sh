#!/usr/bin/env bash
set -euo pipefail

# Load variables from .env if present
if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

: "${TELEGRAM_BOT_TOKEN:?Missing TELEGRAM_BOT_TOKEN}"
: "${TELEGRAM_CHAT_ID:?Missing TELEGRAM_CHAT_ID}"

REPORT="$(bash scripts/node_report.sh 2>&1)"

curl -fsS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=${TELEGRAM_CHAT_ID}" \
  --data-urlencode "text=${REPORT}"
