#!/bin/bash
# Usage: ./fetch_startlist.sh EDITION_URL
# Outputs newline-separated rider names (firstName lastName) to stdout.
# Empty output if no startlist found or parse fails.

SCRIPT_DIR="$(dirname "$0")"
[ -f "${SCRIPT_DIR}/.env" ] && source "${SCRIPT_DIR}/.env"
LOG_FILE="${SCRIPT_DIR}/debug.log"
log() { [ -n "$BIKE_BUDDY_DEBUG" ] && echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [fetch_startlist] $*" >> "$LOG_FILE"; }

EDITION_URL=$1
URL="${EDITION_URL}startlist/"

log "Fetching startlist. url=$URL"
html=$(curl -s "$URL")
log "HTML fetched. size=$(echo "$html" | wc -c | tr -d ' ') bytes"

# Data is embedded as: var edition_data = {...,"startList":[...],...};
json=$(echo "$html" | grep -o 'var edition_data = {.*}' | sed 's/var edition_data = //')
log "edition_data extracted. empty=$([ -z "$json" ] && echo yes || echo no)"

riders=$(echo "$json" | jq -r '.startList[].riders[].title' 2>/dev/null)
log "Riders found: $(echo "$riders" | grep -c . || echo 0)"
echo "$riders"
