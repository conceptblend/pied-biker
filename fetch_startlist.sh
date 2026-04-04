#!/bin/zsh
# Usage: ./fetch_startlist.sh SLUG YEAR
# Outputs newline-separated rider names (firstName lastName) to stdout.
# Empty output if no startlist found or parse fails.

SLUG=$1
YEAR=$2
URL="https://www.domestiquecycling.com/en/cycling-races/${SLUG}/${YEAR}/startlist/"

html=$(curl -s "$URL")

# Data is embedded as: var edition_data = {...,"startList":[...],...};
json=$(echo "$html" | grep -o 'var edition_data = {.*}' | sed 's/var edition_data = //')

echo "$json" | jq -r '.startList[].riders[].title' 2>/dev/null
