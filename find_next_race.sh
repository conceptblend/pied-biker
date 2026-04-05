#!/bin/bash
# Main orchestrator. Finds the next UWT road race containing a preferred rider,
# then writes output.json.

SCRIPT_DIR="$(dirname "$0")"
generated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Load preferred riders into an array (one per line, skip blank lines)
riders=()
while IFS= read -r line; do riders+=("$line"); done < <(grep -v '^[[:space:]]*$' "${SCRIPT_DIR}/riders.txt")

# Fetch race list as JSON lines from matchcenter
races_json=$("${SCRIPT_DIR}/fetch_races.sh")

if [ -z "$races_json" ]; then
  jq -n --arg ga "$generated_at" \
    '{generated_at: $ga, race_date: null, races: []}' > "${SCRIPT_DIR}/output.json"
  echo "No upcoming races found. Wrote empty output.json."
  exit 0
fi

# Collect unique dates in order
dates=()
while IFS= read -r line; do dates+=("$line"); done < <(echo "$races_json" | jq -r '.date' | sort -u)

for race_date in "${dates[@]}"; do
  # All races on this date
  date_races=()
  while IFS= read -r line; do date_races+=("$line"); done < <(echo "$races_json" | jq -c --arg d "$race_date" 'select(.date == $d)')

  matched_races_json="[]"
  found_any=0

  for race_json in "${date_races[@]}"; do
    edition_url=$(echo "$race_json" | jq -r '.edition_url')
    race_name=$(echo "$race_json"  | jq -r '.title')
    startlist=$("${SCRIPT_DIR}/fetch_startlist.sh" "$edition_url")

    if [ -z "$startlist" ]; then
      continue
    fi

    # Check which preferred riders appear in the startlist
    matched_riders=()
    for rider in "${riders[@]}"; do
      if echo "$startlist" | grep -qxF "$rider"; then
        matched_riders+=("$rider")
      fi
    done

    if [ ${#matched_riders[@]} -gt 0 ]; then
      found_any=1

      # Build stage_info: "Stage 1 of N" for multi-stage, null for single-stage
      stage_type=$(echo "$race_json" | jq -r '.stage_type')
      total_stages=$(echo "$race_json" | jq -r '.total_stages')
      if [ "$stage_type" = "multi-stage" ] && [ "$total_stages" -gt 1 ] 2>/dev/null; then
        stage_info="Stage 1 of ${total_stages}"
      else
        stage_info=""
      fi

      riders_json=$(printf '%s\n' "${matched_riders[@]}" | jq -R . | jq -s .)

      matched_races_json=$(echo "$matched_races_json" | jq \
        --arg     name          "$race_name" \
        --arg     date          "$race_date" \
        --arg     url           "${edition_url}startlist/" \
        --arg     country       "$(echo "$race_json" | jq -r '.country')" \
        --arg     time_start    "$(echo "$race_json" | jq -r '.time_start')" \
        --arg     time_end      "$(echo "$race_json" | jq -r '.time_end')" \
        --argjson distance      "$(echo "$race_json" | jq '.distance')" \
        --arg     location_start "$(echo "$race_json" | jq -r '.location_start')" \
        --arg     location_end   "$(echo "$race_json" | jq -r '.location_end')" \
        --arg     stage_info    "$stage_info" \
        --argjson matched       "$riders_json" \
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
          matched_riders: $matched
        }]')
    fi
  done

  if [ "$found_any" -eq 1 ]; then
    jq -n \
      --arg     ga    "$generated_at" \
      --arg     rd    "$race_date" \
      --argjson races "$matched_races_json" \
      '{generated_at: $ga, race_date: $rd, races: $races}' > "${SCRIPT_DIR}/output.json"
    echo "Found matching races on ${race_date}. Wrote output.json."
    exit 0
  fi
done

# No matches in entire season
jq -n --arg ga "$generated_at" \
  '{generated_at: $ga, race_date: null, races: []}' > "${SCRIPT_DIR}/output.json"
echo "No matching races found this season. Wrote empty output.json."
