# Bike Buddy — Tasks

## Status legend
- [x] done
- [~] in progress
- [ ] todo

---

## Phase 1 — Core implementation

### T1 · Config & watchlist
- [x] `riders.txt` — watchlist, one `firstName lastName` per line

### T2 · Race fetcher
- [x] `fetch_races.sh` — fetches Domestique races page, extracts `race_calendar` and `matchcenter`, outputs enriched JSON lines sorted by date
  - Filter `race_calendar` to `category` in `["1.UWT", "2.UWT"]` and `state` in `["upcoming", "ongoing"]`
  - Join `matchcenter` by URL for enrichment (time, distance, location, stage info)
  - Trailing `;` stripped from both JS variables before jq processing

### T3 · Startlist fetcher
- [x] `fetch_startlist.sh EDITION_URL` — curls Domestique edition page, extracts rider names from `var edition_data`
  - Output: newline-separated `firstName lastName`, empty on failure

### T4 · Main orchestrator
- [x] `find_next_race.sh` — orchestrates T2/T3, writes `output.json`
  - Selects earliest date from race list
  - Fetches startlist for each race on that date
  - Sets `startlist_status`: `matched`, `no_match`, or `unavailable`
  - Always reports the next race regardless of startlist availability (ADR 8)
  - Sources `.env` if present (for `BIKE_BUDDY_DEBUG`)

### T5 · GitHub Action
- [x] `.github/workflows/update-with-next-race.yml`
  - Daily cron: `0 18 * * *`
  - `workflow_dispatch` for manual runs
  - Steps: checkout → install jq → run `find_next_race.sh` → deploy `output.json` to `gh-pages`

### T6 · Tests
- [x] `test.sh` — integration tests

---

## Phase 2 — LADRs

- [x] `LADRs/01-shell-only-runtime.md`
- [x] `LADRs/02-uci-api-race-source.md` *(superseded by ADR 7)*
- [x] `LADRs/03-domestique-startlist-extraction.md`
- [x] `LADRs/04-slug-derivation-strategy.md` *(superseded by ADR 7)*
- [x] `LADRs/05-gh-pages-output-delivery.md`
- [x] `LADRs/06-missing-startlist-behavior.md` *(superseded by ADR 8)*
- [x] `LADRs/07-domestique-matchcenter-race-source.md` *(superseded by ADR 9)*
- [x] `LADRs/08-report-next-race-with-status.md`
- [x] `LADRs/09-race-calendar-baseline-matchcenter-enrichment.md`
