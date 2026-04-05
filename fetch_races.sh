#!/bin/bash
# Fetches upcoming UWT Road races from Domestique matchcenter.
# Outputs one JSON object per line, sorted by race start date.
# Filters: category 1.UWT or 2.UWT, discipline Road, start date >= today.
# Multi-stage races are deduplicated to stage 1 only.

today=$(date +%Y-%m-%d)
url="https://www.domestiquecycling.com/en/cycling-races/"

html=$(curl -s "$url")
matchcenter=$(echo "$html" | grep -o 'var matchcenter = {.*' | sed 's/var matchcenter = //')

echo "$matchcenter" | jq -r --arg today "$today" '
  .stageUrlMap as $urlmap
  | .stages
  | map(select(
      (.race.category == "1.UWT" or .race.category == "2.UWT")
      and .race.discipline == "Road"
      and .edition.date[0] >= $today
    ))
  | group_by(.race.raceId)
  | map(sort_by(.stageNumber) | first)
  | sort_by(.edition.date[0])
  | .[]
  | {
      date: .edition.date[0],
      title: .race.title,
      edition_url: .edition.url,
      country: .race.country.full,
      time_start: .time.start,
      time_end: .time.end,
      distance: .distance,
      location_start: .location[0],
      location_end: .location[1],
      stage_type: .stageType,
      total_stages: ($urlmap[(.race.raceId | tostring)] | length)
    }
  | @json
'
