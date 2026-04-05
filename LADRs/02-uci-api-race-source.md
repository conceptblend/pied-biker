---
date: 2026-04-04
status: superseded by ADR 7
---

# ADR 2: UCI API as Race Calendar Source

## Context

We need a reliable, machine-readable source of upcoming UCI Men's Elite road races. ProcyclingStats is a popular alternative but requires scraping HTML or paying for API access. The UCI website exposes a public JSON endpoint (`/api/calendar/upcoming`) that returns structured race data including names, dates, and categories, with no authentication required.

## Decision

Use the UCI public JSON API as the authoritative race calendar source.

## Consequences

- No auth token or payment needed.
- Clean, structured JSON means no HTML parsing for the calendar itself.
- The API is undocumented and unofficial; it may change or disappear without notice.
- The `seasonId` parameter must be updated manually each year (e.g., `1056` for 2026).
