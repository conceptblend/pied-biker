# Bike Buddy — Functional Requirements

## What it does

A weekly GitHub Action that finds the next UCI Men's Elite road race featuring
any rider on a personal watchlist, then publishes the result as a JSON file on
GitHub Pages.

---

## Inputs

### Rider watchlist
- Plain text file committed to the repo (e.g. `riders.txt`), one rider name per
  line.
- Names must match how they appear in the Domestique startlist
  (`firstName lastName`).

### Season ID
- UCI API `seasonId` hardcoded in a config file (currently `1056` for 2026).
- Updated manually at the start of each new season.

---

## Data sources

### 1. Upcoming races — UCI API
```
GET https://www.uci.org/api/calendar/upcoming?discipline=ROA&raceCategory=ME&seasonId={seasonId}
```
Returns all upcoming Men's Elite road races in JSON. No auth required.

### 2. Startlist — Domestique
```
GET https://www.domestiquecycling.com/en/cycling-races/{race-slug}/{year}/startlist/
```
The startlist is embedded in the page as a `window.*` JavaScript variable.
Prefer extracting it with `curl` + shell text processing. Fall back to Playwright
only if the data is not present in the initial HTML response.

**Slug derivation**: lowercase the UCI race name, replace spaces with hyphens
(e.g. `Ronde van Vlaanderen` → `ronde-van-vlaanderen`). Edge cases with
accented characters or punctuation will need handling.

---

## Processing logic

1. Fetch upcoming races from UCI API.
2. Walk races in chronological order, starting from tomorrow.
3. For each race date, fetch the startlist from Domestique for every race on
   that date.
4. Check each startlist for any rider in the watchlist.
5. **If at least one match is found on a given date**: collect all races on that
   date that have at least one match. Stop searching. That date is the result.
6. **If no matches on that date**: advance to the next date and repeat.
7. **If no matches found for the entire remaining season**: publish an empty
   result (see Output schema).

---

## Output

### File
- `output.json` committed to the `gh-pages` branch.
- Accessible via GitHub Pages at a stable URL.

### Schema

```json
{
  "generated_at": "2026-04-04T12:00:00Z",
  "race_date": "2026-04-05",
  "races": [
    {
      "name": "Ronde van Vlaanderen",
      "date": "2026-04-05",
      "url": "https://www.domestiquecycling.com/en/cycling-races/ronde-van-vlaanderen/2026/startlist/",
      "matched_riders": ["Mathieu van der Poel", "Tadej Pogacar"]
    }
  ]
}
```

When no matches are found for the season:
```json
{
  "generated_at": "2026-04-04T12:00:00Z",
  "race_date": null,
  "races": []
}
```

---

## GitHub Action

- **Trigger**: Weekly cron (`0 6 * * 1` — Monday 06:00 UTC, or similar).
- **Steps**:
  1. Fetch UCI race list → parse with `jq`.
  2. For each candidate date, fetch Domestique startlist pages with `curl`.
  3. Extract and filter using `jq` / shell.
  4. Write `output.json`.
  5. Push `output.json` to `gh-pages` branch.
- **Runtime**: Shell (`zsh` or `bash`), `curl`, `jq`. No Node, no Python, no
  Playwright unless the Domestique extraction proves impossible otherwise.

---

## Out of scope

- UI or frontend beyond the raw JSON endpoint.
- Women's races or non-road disciplines.
- Historical race results.
- Notifications / alerts (Slack, email, etc.).
- Automatic season ID detection.

---

## Open questions

1. **Domestique slug mapping** — The simple `lowercase + hyphenize` transform
   may break for races with accented names (e.g. `Critérium du Dauphiné` →
   `critérium-du-dauphiné` vs `criterium-du-dauphine`). Needs validation
   against real Domestique URLs.

2. **Startlist availability** — Domestique startlists aren't always published
   far in advance. If the next race has no startlist yet, should we skip it and
   look further ahead, or treat "no startlist" as "no match"?

3. **Multi-stage races** — A race like the Tour de France spans ~3 weeks. Does
   it appear as one entry with a start date, or multiple daily entries? The UCI
   API appears to use the race start date only. Is that the right anchor?

4. **gh-pages setup** — Does the `gh-pages` branch already exist, and is GitHub
   Pages enabled on this repo? If not, first-run setup is required.
