---
date: 2026-04-04
status: accepted
---

# ADR 4: Slug Derivation via iconv Transliteration

## Context

UCI race names often contain accented characters (e.g., `Critérium du Dauphiné`, `Liège–Bastogne–Liège`) while Domestique URL slugs use plain ASCII with hyphens. We need a deterministic, automated way to transform a UCI name into the correct Domestique slug without maintaining a full lookup table for every race.

## Decision

Derive Domestique URL slugs from UCI race names using the following pipeline: strip accents with `iconv -t ASCII//TRANSLIT`, lowercase with `tr`, replace spaces with hyphens, strip non-alphanumeric characters (except hyphens), collapse consecutive hyphens, and trim leading/trailing hyphens.

## Consequences

- Handles the common case of accented characters automatically.
- A small number of edge cases will still produce incorrect slugs — for example, abbreviations like "GP" that Domestique may expand, special punctuation not handled by TRANSLIT, or races whose Domestique slug differs from the UCI name for other reasons.
- A manual override map (e.g., a `slug-overrides.txt` lookup file) may be needed eventually to patch known failures without touching the core logic.
