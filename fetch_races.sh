#!/bin/zsh
# Fetches UCI race calendar and outputs DATE\tRACE_NAME (tab-separated), sorted chronologically.
# Filters to races strictly after today.

source "$(dirname "$0")/config.sh"

today=$(date +%Y-%m-%d)
url="https://www.uci.org/api/calendar/upcoming?discipline=ROA&raceCategory=ME&seasonId=${SEASON_ID}"

curl -s "$url" \
  | jq -r '.items[].items[] | (.competitionDate | split("T")[0]) as $date | .items[].name | [$date, .] | @tsv' \
  | awk -F'\t' -v today="$today" '$1 > today' \
  | sort
