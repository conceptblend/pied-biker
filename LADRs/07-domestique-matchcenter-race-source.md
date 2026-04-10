---
date: 2026-04-05
status: superseded by ADR 9
---

# ADR 7: Domestique matchcenter as Race Calendar Source

## Context

The UCI API (ADR 2) provided a full-season race calendar but race names frequently diverged from the slugs Domestique uses in its URLs, causing startlist fetches to fail silently. Domestique's own `/en/cycling-races/` page embeds a `var matchcenter = {...}` JavaScript variable containing race metadata — including the canonical `edition.url` — which eliminates slug derivation entirely. This also consolidates to a single data source (Domestique) for both the race calendar and startlists.

The matchcenter structure provides all the display fields requested: `race.title`, `edition.date`, `time.start/end`, `distance`, `location`, and `race.country.full`. It also includes `stageUrlMap` which gives the total stage count for multi-stage races.

**Limitation:** The matchcenter is a rolling ~2-week window around the current date — not a full season calendar. Races more than ~1 week in the future may not yet appear.

## Decision

Replace the UCI API with the Domestique `matchcenter` variable as the race calendar source.

- Filter stages to `race.category` in `["1.UWT", "2.UWT"]` and `race.discipline == "Road"`.
- Filter to `edition.date[0] > today` (strictly tomorrow or later).
- Deduplicate multi-stage races by `race.raceId` — keep the lowest-numbered stage (stage 1).
- Use `stageUrlMap[race.raceId]` length for total stage count.
- Use `edition.url + "startlist/"` to build the startlist URL directly (no slug derivation needed).
- For multi-stage races, include `stage_info: "Stage 1 of N"` in output; null for single-stage.

> **Note (2026-04-10):** Superseded by ADR 9. The matchcenter window (~2 weeks) proved too narrow — races not yet "live" were absent, returning zero results. The new approach uses `race_calendar` (full season) for filtering and matchcenter only for enrichment.

## Consequences

- Race names and URLs are always in sync — no slug mismatch failures.
- Richer output: country, time, distance, location, and stage info are now included.
- **Limited lookahead:** the matchcenter window is ~2 weeks. If no watched rider competes in the next ~2 weeks, the output will be an empty result even if matches exist later in the season. This is a trade-off accepted in exchange for eliminating slug fragility.
- No auth or API key needed; same as the UCI API.
- If Domestique renames or restructures the `matchcenter` variable, extraction breaks.

> **Date filter note:** The filter uses `> today`. The action runs daily at 18:00 UTC — after most races have finished for the day — so same-day races are deliberately excluded. "Next race" always means tomorrow or later.
