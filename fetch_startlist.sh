#!/bin/bash
# Usage: ./fetch_startlist.sh EDITION_URL
# Outputs newline-separated rider names (firstName lastName) to stdout.
# Empty output if no startlist found or parse fails.

EDITION_URL=$1
URL="${EDITION_URL}startlist/"

html=$(curl -s "$URL")

# Data is embedded as: var edition_data = {...,"startList":[...],...};
json=$(echo "$html" | grep -o 'var edition_data = {.*}' | sed 's/var edition_data = //')

echo "$json" | jq -r '.startList[].riders[].title' 2>/dev/null
