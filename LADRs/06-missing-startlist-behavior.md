---
date: 2026-04-04
status: accepted
---

# ADR 6: Missing Startlist Treated as No Match

## Context

Domestique does not always publish startlists far in advance. When the tool queries an upcoming race and gets a 404 or an empty startlist, there are two options: (a) treat the race as unresolvable and skip that date entirely, or (b) treat it as a race with no watched riders and continue to the next date. Option (a) risks silently missing a race that has no startlist yet. Option (b) means we might report a later race when the actual next match would have been the skipped one.

## Decision

Treat a missing or empty startlist (404 or no data) as "no match" — do not abort; continue to the next date.

## Consequences

- The workflow never stalls waiting for a startlist to be published.
- If the actual next race with a watched rider hasn't had its startlist published yet, the tool will incorrectly report a later race as the next match.
- This is an acceptable trade-off: the workflow runs weekly, so once the startlist is published the next run will self-correct and report the right race.
