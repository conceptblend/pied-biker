---
date: 2026-04-05
status: accepted
---

# ADR 8: Always Report the Next Race with a Startlist Status

## Context

The original processing logic (ADR 6) skipped races with missing or empty startlists and advanced to the next date in search of a match. This caused silent failures: Domestique frequently does not publish startlists until a few days before the race, so the tool would skip the actual next race and report a later one — or return an empty result if nothing further in the matchcenter window had a startlist yet.

The root problem is that the tool was conflating two separate concerns: _which race is next_ and _are my riders in it_. Startlist availability should not affect race selection.

## Decision

Always report the next upcoming race (the first date in the matchcenter that satisfies the base filter criteria), regardless of startlist availability. Include a `startlist_status` field on each race object:

- `"matched"` — startlist is available and at least one watched rider is confirmed
- `"no_match"` — startlist is available but none of the watched riders appear
- `"unavailable"` — startlist has not been published yet

`matched_riders` is always present; it is an empty array when status is not `"matched"`.

## Consequences

- The output always reflects the true next race — no silent skipping.
- Consumers can branch on `startlist_status` to decide how to display the result (e.g. show a "check back soon" message when `"unavailable"`).
- A race with `"no_match"` is still reported; the consumer knows the next race exists but no watched riders are starting.
- `race_date` in the output is the date of the reported race, not the date of the first rider match.
