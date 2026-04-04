#!/bin/bash
# Main orchestrator. Finds the next UCI race containing a preferred rider,
# then writes output.json.

source "$(dirname "$0")/config.sh"

SCRIPT_DIR="$(dirname "$0")"
generated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Load preferred riders into an array (one per line, skip blank lines)
riders=()
while IFS= read -r line; do riders+=("$line"); done < <(grep -v '^[[:space:]]*$' "${SCRIPT_DIR}/riders.txt")

# Fetch full race list as TSV: DATE\tRACE_NAME
races_tsv=$("${SCRIPT_DIR}/fetch_races.sh")

if [ -z "$races_tsv" ]; then
  jq -n --arg ga "$generated_at" \
    '{generated_at: $ga, race_date: null, races: []}' > "${SCRIPT_DIR}/output.json"
  echo "No upcoming races found. Wrote empty output.json."
  exit 0
fi

# Collect unique dates in order (dates are simple YYYY-MM-DD, safe to word-split)
dates=()
while IFS= read -r line; do dates+=("$line"); done < <(echo "$races_tsv" | awk -F'\t' '{print $1}' | sort -u)

for race_date in "${dates[@]}"; do
  # All races on this date — use line-by-line splitting to preserve names with spaces
  race_names=()
  while IFS= read -r line; do race_names+=("$line"); done < <(echo "$races_tsv" | awk -F'\t' -v d="$race_date" '$1 == d {print $2}')

  matched_races_json="[]"
  found_any=0

  for race_name in "${race_names[@]}"; do
    slug=$("${SCRIPT_DIR}/slugify.sh" "$race_name")
    startlist=$("${SCRIPT_DIR}/fetch_startlist.sh" "$slug" "$YEAR")

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
      race_url="https://www.domestiquecycling.com/en/cycling-races/${slug}/${YEAR}/startlist/"

      # Build matched_riders JSON array
      riders_json=$(printf '%s\n' "${matched_riders[@]}" | jq -R . | jq -s .)

      # Append this race to matched_races_json
      matched_races_json=$(echo "$matched_races_json" | jq \
        --arg name "$race_name" \
        --arg date "$race_date" \
        --arg url "$race_url" \
        --argjson matched "$riders_json" \
        '. += [{"name": $name, "date": $date, "url": $url, "matched_riders": $matched}]')
    fi
  done

  if [ "$found_any" -eq 1 ]; then
    jq -n \
      --arg ga "$generated_at" \
      --arg rd "$race_date" \
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
