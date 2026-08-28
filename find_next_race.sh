#!/bin/bash
# Main orchestrator. Finds the next upcoming UWT road race(s) and reports
# matched riders — or a status message if the startlist isn't available yet.
#
# startlist_status values:
#   "matched"     — startlist available, ≥1 watched rider found
#   "no_match"    — startlist available, no watched riders found
#   "unavailable" — startlist not yet published

SCRIPT_DIR="$(dirname "$0")"
[ -f "${SCRIPT_DIR}/.env" ] && source "${SCRIPT_DIR}/.env"
LOG_FILE="${SCRIPT_DIR}/debug.log"
log() { [ -n "$BIKE_BUDDY_DEBUG" ] && echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [find_next_race] $*" >> "$LOG_FILE"; }

# Picks which date to report as "the next race" from race JSON-lines. A
# multi-stage race already underway (state == "ongoing") is always "the next
# race" — its stage-1 start date is in the past, so it must bypass the
# "strictly after today" rule below (added in a01c17d to stop a same-day
# one-day race from being reported during the midday cron run).
select_next_date() {
  local races_json="$1" today="$2"
  local ongoing_date
  ongoing_date=$(echo "$races_json" | jq -r 'select(.state == "ongoing" and .stage_type == "multi-stage") | .date' | sort -u | head -1)
  if [ -n "$ongoing_date" ]; then
    echo "$ongoing_date"
  else
    echo "$races_json" | jq -r '.date' | sort -u | awk -v today="$today" '$0 > today' | head -1
  fi
}

# Everything below runs only when the script is executed directly — test.sh
# sources this file to exercise select_next_date() with fixture data instead.
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  return 0
fi

generated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
log "--- run started generated_at=$generated_at ---"

# Load preferred riders (one per line, skip blank lines)
riders=()
while IFS= read -r line; do riders+=("$line"); done < <(grep -v '^[[:space:]]*$' "${SCRIPT_DIR}/riders.txt")
log "Loaded ${#riders[@]} riders from riders.txt"

# Fetch race list as JSON lines, sorted by date
log "Fetching race list..."
races_json=$("${SCRIPT_DIR}/fetch_races.sh")
log "fetch_races returned $(echo "$races_json" | grep -c . || echo 0) lines"

if [ -z "$races_json" ]; then
  jq -n --arg ga "$generated_at" \
    '{generated_at: $ga, race_date: null, races: []}' > "${SCRIPT_DIR}/output.json"
  echo "No upcoming races found. Wrote empty output.json."
  exit 0
fi

today=$(date -u +%Y-%m-%d)
next_date=$(select_next_date "$races_json" "$today")
log "next_date=$next_date"

# Collect all races on that date
next_date_races=()
while IFS= read -r line; do next_date_races+=("$line"); done \
  < <(echo "$races_json" | jq -c --arg d "$next_date" 'select(.date == $d)')

output_races_json="[]"

log "Races on next_date: ${#next_date_races[@]}"

for race_json in "${next_date_races[@]}"; do
  edition_url=$(echo "$race_json" | jq -r '.edition_url')
  race_name=$(echo "$race_json"  | jq -r '.title')
  race_date=$(echo "$race_json"  | jq -r '.date')

  # Build stage_info
  stage_type=$(echo "$race_json"   | jq -r '.stage_type')
  stage_number=$(echo "$race_json" | jq -r '.stage_number')
  total_stages=$(echo "$race_json" | jq -r '.total_stages')
  if [ "$stage_type" = "multi-stage" ] && [ "$total_stages" -gt 1 ] 2>/dev/null; then
    stage_info="Stage ${stage_number} of ${total_stages}"
  else
    stage_info=""
  fi

  log "Processing race: $race_name ($race_date) url=$edition_url"
  startlist=$("${SCRIPT_DIR}/fetch_startlist.sh" "$edition_url")
  log "Startlist for $race_name: $(echo "$startlist" | grep -c . || echo 0) riders"

  if [ -z "$startlist" ]; then
    status="unavailable"
    riders_json="[]"
  else
    matched_riders=()
    for rider in "${riders[@]}"; do
      if echo "$startlist" | grep -qxF "$rider"; then
        matched_riders+=("$rider")
      fi
    done

    if [ ${#matched_riders[@]} -gt 0 ]; then
      status="matched"
      riders_json=$(printf '%s\n' "${matched_riders[@]}" | jq -R . | jq -s .)
    else
      status="no_match"
      riders_json="[]"
    fi
  fi

  output_races_json=$(echo "$output_races_json" | jq \
    --arg     name           "$race_name" \
    --arg     date           "$race_date" \
    --arg     url            "${edition_url}startlist/" \
    --arg     country        "$(echo "$race_json" | jq -r '.country')" \
    --argjson time_start     "$(echo "$race_json" | jq '.time_start')" \
    --argjson time_end       "$(echo "$race_json" | jq '.time_end')" \
    --argjson distance       "$(echo "$race_json" | jq '.distance')" \
    --argjson location_start "$(echo "$race_json" | jq '.location_start')" \
    --argjson location_end   "$(echo "$race_json" | jq '.location_end')" \
    --arg     stage_info     "$stage_info" \
    --arg     status         "$status" \
    --argjson matched        "$riders_json" \
    '. += [{
      name: $name,
      date: $date,
      url: $url,
      country: $country,
      time_start: $time_start,
      time_end: $time_end,
      distance: $distance,
      location_start: $location_start,
      location_end: $location_end,
      stage_info: (if $stage_info == "" then null else $stage_info end),
      startlist_status: $status,
      matched_riders: $matched
    }]')

  log "Result for $race_name: status=$status matched=${#matched_riders[@]}"
  echo "${status}: ${race_name} (${race_date})"
done

jq -n \
  --arg     ga    "$generated_at" \
  --arg     rd    "$next_date" \
  --argjson races "$output_races_json" \
  '{generated_at: $ga, race_date: $rd, races: $races}' \
  > "${SCRIPT_DIR}/output.json"

log "Wrote output.json."
