#!/usr/bin/env bash

ITEM_NAME="${NAME:-$1}"
SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-/opt/homebrew/bin/sketchybar}"
cores=$(sysctl -n hw.ncpu)
usage=$(ps -A -o %cpu= | awk -v cores="$cores" '{ sum += $1 } END { if (cores > 0) printf "%d", sum / cores; else print 0 }')
"$SKETCHYBAR_BIN" --set "$ITEM_NAME" label="${usage}%"
