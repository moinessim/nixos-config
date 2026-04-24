#!/usr/bin/env bash

ITEM_NAME="${NAME:-$1}"
SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-/opt/homebrew/bin/sketchybar}"
volume="${INFO:-$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)}"
muted=$(osascript -e 'output muted of (get volume settings)' 2>/dev/null)

icon=VOL
if [ "$muted" = "true" ] || [ -z "$volume" ] || [ "$volume" -eq 0 ] 2>/dev/null; then
  icon=MUT
  volume=0
elif [ "$volume" -lt 35 ] 2>/dev/null; then
  icon=LOW
fi

"$SKETCHYBAR_BIN" --set "$ITEM_NAME" icon="$icon" label="${volume}%"
