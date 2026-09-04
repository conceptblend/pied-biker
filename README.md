# Pied Biker

A daily GitHub Action that finds the next UCI Men's Elite road race (WorldTour)
featuring any rider on a personal watchlist, and publishes the result as a
static JSON file on GitHub Pages.

Shell scripts + `jq` only — no runtime dependency, no server. See
[CLAUDE.md](CLAUDE.md) for the guiding principles and [REQUIREMENTS.md](REQUIREMENTS.md)
for full functional detail.

## Workflow

```mermaid
sequenceDiagram
    participant Cron as GitHub Actions<br/>(cron: daily 18:00 UTC)
    participant Orchestrator as find_next_race.sh
    participant Fetch as fetch_races.sh
    participant Domestique as domestiquecycling.com
    participant Startlist as fetch_startlist.sh
    participant Pages as gh-pages branch

    Cron->>Orchestrator: run
    Orchestrator->>Fetch: fetch_races.sh
    Fetch->>Domestique: GET /cycling-races/ (race_calendar)
    Fetch->>Domestique: GET matchcenter (enrichment)
    Domestique-->>Fetch: HTML w/ embedded JSON
    Fetch-->>Orchestrator: JSON-lines, sorted by date<br/>(1.UWT/2.UWT, upcoming/ongoing)

    Orchestrator->>Orchestrator: select_next_date()<br/>(ongoing multi-stage wins,<br/>else first date > today)

    loop each race on next_date
        Orchestrator->>Startlist: fetch_startlist.sh EDITION_URL
        Startlist->>Domestique: GET edition page
        Domestique-->>Startlist: HTML w/ embedded startList
        Startlist-->>Orchestrator: rider names
        Orchestrator->>Orchestrator: match against riders.txt<br/>→ matched / no_match / unavailable
    end

    Orchestrator->>Orchestrator: write output.json
    Cron->>Pages: copy output.json → _deploy/, deploy
```

## Files

- `riders.txt` — watchlist, one rider name per line (`firstName lastName`, matching Domestique's startlist format)
- `find_next_race.sh` — orchestrator: picks the next race date and matches riders against its startlist
- `fetch_races.sh` — scrapes Domestique's race calendar + matchcenter enrichment
- `fetch_startlist.sh` — scrapes a race edition's startlist
- `output.json` — generated result, published to the `gh-pages` branch (see [output.json.example](output.json.example) for shape)
- `.github/workflows/update-with-next-race.yml` — the scheduled GitHub Action
- `LADRs/` — lightweight architecture decision records explaining key choices

## Local usage

```sh
chmod +x *.sh
./find_next_race.sh   # writes output.json
```

Set `BIKE_BUDDY_DEBUG=1` in `.env` to log verbose progress to `debug.log`.

Run `./test.sh` to exercise `find_next_race.sh`'s date-selection logic against fixture data.
