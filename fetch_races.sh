#!/bin/bash
# Fetches upcoming UWT Road races from Domestique.
# Uses race_calendar as baseline filter, matchcenter for enrichment.
# Outputs one JSON object per line, sorted by race start date.
# Filters: category 1.UWT or 2.UWT, state upcoming or ongoing.

SCRIPT_DIR="$(dirname "$0")"
[ -f "${SCRIPT_DIR}/.env" ] && source "${SCRIPT_DIR}/.env"
LOG_FILE="${SCRIPT_DIR}/debug.log"
log() { [ -n "$BIKE_BUDDY_DEBUG" ] && echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [fetch_races] $*" >> "$LOG_FILE"; }

today=$(date +%Y-%m-%d)
url="https://www.domestiquecycling.com/en/cycling-races/"

log "Fetching races. today=$today url=$url"
html=$(curl -s "$url")
log "HTML fetched. size=$(echo "$html" | wc -c | tr -d ' ') bytes"

race_calendar=$(echo "$html" | grep -o 'var race_calendar = {.*' | sed 's/var race_calendar = //;s/;$//')
log "race_calendar extracted. empty=$([ -z "$race_calendar" ] && echo yes || echo no)"
if [ -n "$BIKE_BUDDY_DEBUG" ]; then
  echo "$race_calendar" | jq . > "${SCRIPT_DIR}/debug_race_calendar.json" 2>/dev/null
  log "race_calendar dumped to debug_race_calendar.json"
fi

matchcenter=$(echo "$html" | grep -o 'var matchcenter = {.*' | sed 's/var matchcenter = //;s/;$//')
log "matchcenter extracted. empty=$([ -z "$matchcenter" ] && echo yes || echo no)"
if [ -n "$BIKE_BUDDY_DEBUG" ]; then
  echo "$matchcenter" | jq . > "${SCRIPT_DIR}/debug_matchcenter.json" 2>/dev/null
  log "matchcenter dumped to debug_matchcenter.json"
fi

total_entries=$(echo "$race_calendar" | jq '[to_entries[].value] | length' 2>/dev/null)
log "Total entries in race_calendar: $total_entries"

after_category=$(echo "$race_calendar" | jq '[to_entries[].value | select(.category == "1.UWT" or .category == "2.UWT")] | length' 2>/dev/null)
log "After category filter (1.UWT or 2.UWT): $after_category"

after_state=$(echo "$race_calendar" | jq '[to_entries[].value | select((.category == "1.UWT" or .category == "2.UWT") and (.state == "upcoming" or .state == "ongoing"))] | length' 2>/dev/null)
log "After state filter (upcoming or ongoing): $after_state"

sample_date=$(echo "$race_calendar" | jq -r '[to_entries[].value | select((.category == "1.UWT" or .category == "2.UWT") and (.state == "upcoming" or .state == "ongoing"))] | first | .dateStart' 2>/dev/null)
log "Sample dateStart from filtered results: $sample_date"

echo "$race_calendar" | jq -r --argjson matchcenter "${matchcenter:-{\}}" '
  ($matchcenter | .stages // [] | map({(.edition.url): .}) | add // {}) as $mc_by_url
  | [to_entries[].value
     | select((.category == "1.UWT" or .category == "2.UWT")
              and (.state == "upcoming" or .state == "ongoing"))]
  | sort_by(.dateStart)
  | .[]
  | . as $race
  | ($mc_by_url[$race.url] // null) as $mc
  | {
      date:           $race.dateStart,
      title:          $race.title,
      edition_url:    $race.url,
      country:        $race.country.full,
      time_start:     (if $mc then $mc.time.start  else null end),
      time_end:       (if $mc then $mc.time.end    else null end),
      distance:       (if $mc then $mc.distance    else null end),
      location_start: (if $mc then $mc.location[0] else null end),
      location_end:   (if $mc then $mc.location[1] else null end),
      stage_type:     (if $mc then $mc.stageType      else null end),
      stage_number:   (if $mc then $mc.stageNumber   else null end),
      total_stages:   (if $mc then ($matchcenter.stageUrlMap[($mc.race.raceId | tostring)] | length) else null end)
    }
  | @json
'
