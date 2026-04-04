# Bike Buddy — Tasks

## Status legend
- [ ] todo
- [x] done
- [~] in progress

---

## Phase 1 — Core implementation

### T1 · Config & watchlist
- [ ] `riders.txt` — sample watchlist (one rider per line, `firstName lastName`)
- [ ] `config.sh` — exports `SEASON_ID=1056` and `YEAR=2026`

### T2 · Slug normalization
- [ ] `slugify.sh RACE_NAME` — normalizes a UCI race name to a Domestique URL slug
  - Strip accents via `iconv -t ASCII//TRANSLIT`
  - Lowercase + replace spaces with hyphens
  - Strip punctuation (apostrophes, periods, commas)

### T3 · UCI race fetcher
- [ ] `fetch_races.sh` — fetches UCI calendar, outputs TSV lines: `DATE\tRACE_NAME`
  - Filter to dates strictly after today
  - Sort chronologically
  - Dedup (multi-day races appear once per start date)

### T4 · Domestique startlist fetcher
- [ ] `fetch_startlist.sh SLUG YEAR` — curls Domestique page, extracts rider names
  - Grep for `var startList` or `startList:` JS variable in raw HTML
  - Output newline-separated `firstName lastName` list, or empty on failure

### T5 · Main logic
- [ ] `find_next_race.sh` — orchestrates T3/T4, writes `output.json`
  - Walk UCI races chronologically from tomorrow
  - For each date, check all races' startlists against `riders.txt`
  - Stop at first date with ≥1 match; collect all matching races that day
  - Emit `output.json` matching the schema in REQUIREMENTS.md
  - Handle no-match-all-season case (empty result)

### T6 · GitHub Action
- [ ] `.github/workflows/bike-buddy.yml`
  - Weekly cron trigger: `0 6 * * 1`
  - Steps: checkout → run `find_next_race.sh` → push `output.json` to `gh-pages`
  - Use `peaceiris/actions-gh-pages` or manual git push to gh-pages

### T7 · Tests
- [ ] `test.sh` — validates each script in isolation
  - Test `slugify.sh` with plain names, accented names, multi-word names
  - Test `fetch_startlist.sh` extracts known rider from live Domestique page
  - Test `find_next_race.sh` output validates against expected JSON schema
  - Exit non-zero on any failure

---

## Phase 2 — LADRs

- [ ] `LADRs/01-shell-only-runtime.md`
- [ ] `LADRs/02-uci-api-race-source.md`
- [ ] `LADRs/03-domestique-startlist-extraction.md`
- [ ] `LADRs/04-slug-derivation-strategy.md`
- [ ] `LADRs/05-gh-pages-output-delivery.md`
- [ ] `LADRs/06-missing-startlist-behavior.md`
