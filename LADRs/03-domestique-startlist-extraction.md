---
date: 2026-04-04
status: accepted
---

# ADR 3: Domestique Startlist Extraction via HTML Grep

## Context

Domestique Cycling publishes startlists for UCI races at predictable URLs (`/en/cycling-races/{slug}/{year}/startlist/`). The startlist data is embedded in the initial HTML as a JS variable (e.g., `var startList = [...]`), meaning the full dataset is present in the raw HTML response — no JavaScript execution is required to read it. Using Playwright or another headless browser would work but adds substantial complexity and a heavy dependency.

## Decision

Extract startlists from Domestique by curling the HTML page and grepping for the embedded JS variable. No headless browser.

## Consequences

- Works today with curl and grep/sed alone; no extra dependencies.
- The extraction is tied to the specific JS variable name and surrounding HTML structure. Any change to that structure breaks the parser.
- If Domestique ever migrates to client-side rendering (i.e., the startlist data is fetched via XHR after page load), this approach will stop working and a fallback strategy will be needed.
