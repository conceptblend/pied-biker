---
date: 2026-04-04
status: accepted
---

# ADR 5: GitHub Pages for Output Delivery

## Context

After each run, the tool produces an `output.json` file with the next upcoming race that includes a watched rider. This file needs to be served at a stable, publicly accessible URL so other tools or users can consume it. Options considered: S3, a separate hosting service, or GitHub Pages. GitHub Pages is free, requires no external accounts, and is directly integrated with the repository.

## Decision

Push `output.json` to the `gh-pages` branch after each run, served via GitHub Pages.

## Consequences

- Zero cost; no external services required.
- The URL is stable and predictable (e.g., `https://{user}.github.io/{repo}/output.json`).
- The `gh-pages` branch must be created and GitHub Pages must be enabled on the repository once before the workflow can publish.
- Each workflow run commits to `gh-pages`, which creates a commit history; this is noisy but harmless.
