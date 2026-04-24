#!/usr/bin/env bash

ITEM_NAME="${NAME:-$1}"
SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-/opt/homebrew/bin/sketchybar}"
timestamp=$(date '+%a %b %e %I:%M %p' | tr -s ' ')
"$SKETCHYBAR_BIN" --set "$ITEM_NAME" label="$timestamp"
