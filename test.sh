#!/bin/bash
PASS=0
FAIL=0

assert_eq() {
  local desc=$1 expected=$2 actual=$3
  if [[ "$actual" == "$expected" ]]; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc"
    echo "    expected: $expected"
    echo "    actual:   $actual"
    ((FAIL++))
  fi
}

assert_contains() {
  local desc=$1 needle=$2 haystack=$3
  if echo "$haystack" | grep -q "$needle"; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc"
    echo "    expected to contain: $needle"
    echo "    actual: $haystack"
    ((FAIL++))
  fi
}

# ---------------------------------------------------------------------------
# fetch_startlist.sh live test (requires network)
# ---------------------------------------------------------------------------
echo ""
echo "fetch_startlist.sh live tests (requires network):"

# Uses edition URL directly (no more slug+year)
assert_contains "RvV 2026 startlist contains Tadej Pogacar" \
  "Tadej Pogacar" \
  "$(./fetch_startlist.sh 'https://www.domestiquecycling.com/en/cycling-races/ronde-van-vlaanderen/2026/')"

# ---------------------------------------------------------------------------
# output.json schema + content tests (requires network)
# ---------------------------------------------------------------------------
echo ""
echo "output.json schema tests (requires network):"

./find_next_race.sh

assert_eq "output.json exists" \
  "0" \
  "$([[ -f output.json ]]; echo $?)"

assert_contains "output.json contains generated_at" \
  "generated_at" \
  "$(jq 'keys[]' output.json 2>/dev/null)"

assert_contains "output.json contains race_date" \
  "race_date" \
  "$(jq 'keys[]' output.json 2>/dev/null)"

assert_contains "output.json contains races array" \
  "races" \
  "$(jq 'keys[]' output.json 2>/dev/null)"

# If a race was found, validate the enriched fields are present
if jq -e '.races | length > 0' output.json >/dev/null 2>&1; then
  assert_contains "race object contains country" \
    "country" \
    "$(jq '.races[0] | keys[]' output.json 2>/dev/null)"

  assert_contains "race object contains distance" \
    "distance" \
    "$(jq '.races[0] | keys[]' output.json 2>/dev/null)"

  assert_contains "race object contains location_start" \
    "location_start" \
    "$(jq '.races[0] | keys[]' output.json 2>/dev/null)"

  assert_contains "race object contains stage_info key" \
    "stage_info" \
    "$(jq '.races[0] | keys[]' output.json 2>/dev/null)"

  assert_contains "race object contains startlist_status" \
    "startlist_status" \
    "$(jq '.races[0] | keys[]' output.json 2>/dev/null)"

  status=$(jq -r '.races[0].startlist_status' output.json 2>/dev/null)
  assert_contains "startlist_status is a valid value" \
    "$status" \
    "matched no_match unavailable"
else
  echo "  SKIP: enriched field tests (no races in output — matchcenter window may be empty)"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
