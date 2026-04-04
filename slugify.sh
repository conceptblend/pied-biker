#!/bin/zsh
# Usage: ./slugify.sh "Ronde van Vlaanderen"
# Outputs: ronde-van-vlaanderen

input="$1"

echo "$input" \
  | iconv -t ASCII//TRANSLIT 2>/dev/null \
  | tr '[:upper:]' '[:lower:]' \
  | tr ' ' '-' \
  | tr -cd '[:alnum:]-' \
  | sed 's/-\{2,\}/-/g' \
  | sed 's/^-//;s/-$//' \
  && echo
