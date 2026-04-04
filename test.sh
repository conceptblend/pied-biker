#!/bin/zsh
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
# slugify.sh tests
# ---------------------------------------------------------------------------
echo "slugify.sh tests:"

assert_eq "Ronde van Vlaanderen" \
  "ronde-van-vlaanderen" \
  "$(./slugify.sh 'Ronde van Vlaanderen')"

assert_eq "Critérium du Dauphiné" \
  "criterium-du-dauphine" \
  "$(./slugify.sh 'Critérium du Dauphiné')"

assert_eq "Paris-Roubaix" \
  "paris-roubaix" \
  "$(./slugify.sh 'Paris-Roubaix')"

assert_eq "GP Samyn" \
  "gp-samyn" \
  "$(./slugify.sh 'GP Samyn')"

assert_eq "Strade Bianche" \
  "strade-bianche" \
  "$(./slugify.sh 'Strade Bianche')"

# ---------------------------------------------------------------------------
# fetch_startlist.sh live test (requires network)
# ---------------------------------------------------------------------------
echo ""
echo "fetch_startlist.sh live tests (requires network):"

# This test hits the live Domestique API
assert_contains "Ronde van Vlaanderen 2026 startlist contains Tadej Pogacar" \
  "Tadej Pogacar" \
  "$(./fetch_startlist.sh ronde-van-vlaanderen 2026)"

# ---------------------------------------------------------------------------
# output.json schema test (requires network — hits live UCI + Domestique APIs)
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

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
