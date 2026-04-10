# Bike Buddy — Functional Requirements

## What it does

A daily GitHub Action that finds the next UCI Men's Elite road race featuring
any rider on a personal watchlist, then publishes the result as a JSON file on
GitHub Pages.

---

## Inputs

### Rider watchlist
- Plain text file committed to the repo (`riders.txt`), one rider name per line.
- Names must match how they appear in the Domestique startlist (`firstName lastName`).

---

## Data sources

Both variables are embedded in the same page and extracted with a single HTTP request:

```
GET https://www.domestiquecycling.com/en/cycling-races/
```

### 1. Race calendar — `var race_calendar`
Full-season catalog of all races. Used for filtering and selecting the next race.
- Keyed by numeric ID; each entry has `state`, `category`, `dateStart`, `dateEnd`, `url`.
- Filter to `category` in `["1.UWT", "2.UWT"]` and `state` in `["upcoming", "ongoing"]`.

### 2. Stage detail — `var matchcenter`
Rolling ~2-week window of active/nearby races with per-stage detail. Used to enrich the selected race.
- Contains `time.start/end`, `distance`, `location`, `stageType`, `stageNumber`, `stageUrlMap`.
- Joined to `race_calendar` via `edition.url` == `race_calendar[*].url`.
- If the selected race has no matchcenter entry, enrichment fields are `null`.

### 3. Startlist — Domestique edition page
```
GET {edition_url}startlist/
```
The startlist is embedded as `var edition_data = {...}` in the page HTML.
Edition URL comes directly from `race_calendar`, so no slug derivation is needed.

---

## Processing logic

1. Fetch the Domestique races page; extract both `race_calendar` and `matchcenter`.
2. Filter `race_calendar` to UWT road races with `state` `"upcoming"` or `"ongoing"`.
3. Sort by `dateStart`; take the earliest date as the next race date.
4. Collect all races on that date (usually one).
5. For each race, join `matchcenter` by URL to populate enrichment fields.
6. Fetch the startlist for each race; check against `riders.txt`.
7. Set `startlist_status` to `"matched"`, `"no_match"`, or `"unavailable"`.
8. Write `output.json`.

---

## Output

### File
- `output.json` deployed to the `gh-pages` branch via GitHub Pages.

### Schema

```json
{
  "generated_at": "2026-04-10T00:55:54Z",
  "race_date": "2026-04-06",
  "races": [
    {
      "name": "Itzulia Basque Country",
      "date": "2026-04-06",
      "url": "https://www.domestiquecycling.com/en/cycling-races/itzulia-basque-country/2026/startlist/",
      "country": "Spain",
      "time_start": "12:05",
      "time_end": "16:30",
      "distance": 176.2,
      "location_start": "Eibar",
      "location_end": "Eibar",
      "stage_info": "Stage 5 of 6",
      "startlist_status": "no_match",
      "matched_riders": []
    }
  ]
}
```

`stage_info` is `null` for single-stage races or when matchcenter has no entry for the race.
Enrichment fields (`time_start`, `time_end`, `distance`, `location_start`, `location_end`, `stage_info`) are `null` when the race is not yet in the matchcenter window.

When no upcoming races are found:
```json
{
  "generated_at": "2026-04-10T00:00:00Z",
  "race_date": null,
  "races": []
}
```

---

## GitHub Action

- **Trigger**: Daily cron (`0 18 * * *` — 18:00 UTC) and `workflow_dispatch`.
- **Steps**:
  1. Checkout repo.
  2. Install `jq`.
  3. Run `find_next_race.sh`.
  4. Deploy `output.json` to `gh-pages` via `peaceiris/actions-gh-pages`.
- **Runtime**: bash, `curl`, `jq`. No Node, Python, or Playwright.

---

## Debug logging

Set `BIKE_BUDDY_DEBUG=1` to enable verbose logging to `debug.log` and dump the raw
`race_calendar` and `matchcenter` data to `debug_race_calendar.json` and
`debug_matchcenter.json`. Off by default. Can be set in a `.env` file in the repo root
(loaded automatically if present; ignored in CI where the file won't exist).

---

## Out of scope

- UI or frontend beyond the raw JSON endpoint.
- Women's races or non-road disciplines.
- Historical race results.
- Notifications / alerts (Slack, email, etc.).
