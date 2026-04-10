---
date: 2026-04-10
status: accepted
---

# ADR 9: race_calendar as Baseline, matchcenter as Enrichment

## Context

ADR 7 used `matchcenter` as the sole data source for race filtering. This worked initially but broke when the next upcoming race was not yet within matchcenter's rolling window (approximately 2 weeks around the current date). The filter produced zero results even though future UWT races existed on the calendar.

Domestique's `/en/cycling-races/` page also embeds a second JavaScript variable, `var race_calendar = {...}`, which is a comprehensive full-season catalog of all races (376 entries in 2026). Each entry is keyed by a numeric ID and includes `state` (`"finished"`, `"ongoing"`, or `"upcoming"`), `category`, `dateStart`, `dateEnd`, and a `url` field that matches the `edition.url` in matchcenter — making the two datasets joinable.

`race_calendar` lacks the per-stage detail that matchcenter provides (time, distance, location, stage type/number, stage count), but it has reliable state-based filtering and full-season coverage.

## Decision

Use `race_calendar` as the source of truth for filtering, and join `matchcenter` to enrich the selected race.

**Filtering (from `race_calendar`):**
- Filter to `category` in `["1.UWT", "2.UWT"]`
- Filter to `state` in `["upcoming", "ongoing"]` — no date arithmetic needed
- Sort by `dateStart`; take the earliest date as the "next race"

**Join key:** `race_calendar[*].url` === `matchcenter.stages[].edition.url`

**Enrichment (from `matchcenter`, null if no match):**
- `time_start` / `time_end` — from `.time.start` / `.time.end`
- `distance` — from `.distance`
- `location_start` / `location_end` — from `.location[0]` / `.location[1]`
- `stage_type` — from `.stageType`
- `stage_number` — from `.stageNumber` (reflects the currently active stage for ongoing races)
- `total_stages` — from `stageUrlMap[raceId] | length`

Both variables are extracted from the same single HTTP request. Trailing semicolons from the JavaScript statement terminator (`};`) are stripped before passing to jq.

## Consequences

- Full-season coverage: races are found as soon as they appear in `race_calendar`, regardless of matchcenter window.
- Enrichment is best-effort: if a race is not yet in matchcenter, all enrichment fields are `null` in the output. Consumers must handle nulls.
- `stage_number` reflects the actual current stage for ongoing multi-stage races — not a hardcoded "Stage 1".
- Still a single HTTP request; no additional network cost.
- If Domestique renames or restructures either variable, extraction breaks (same risk as ADR 7).
- `ongoing` races are included so that a currently-running multi-stage race is reported as the "next" race while it is in progress.
