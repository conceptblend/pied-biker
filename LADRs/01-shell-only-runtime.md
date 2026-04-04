---
date: 2026-04-04
status: accepted
---

# ADR 1: Shell-Only Runtime

## Context

The tool needs to run inside a GitHub Action. Using Node.js or Python would require explicit setup steps (actions/setup-node, actions/setup-python) and dependency installation. Playwright or similar browser automation adds even more overhead. The task — fetching a JSON API and parsing embedded HTML — is well within the capability of curl and jq, which are available in every GitHub-hosted runner without any setup.

## Decision

Use shell (bash/zsh) + curl + jq only. No Node.js, no Python, no Playwright.

## Consequences

- No setup steps needed in the workflow; the Action starts immediately.
- Dependencies are minimal and pre-installed on all GitHub-hosted runners.
- Regex-based HTML parsing is inherently fragile. If Domestique changes its page structure or moves to client-side rendering, the extraction logic will break and require manual intervention.
