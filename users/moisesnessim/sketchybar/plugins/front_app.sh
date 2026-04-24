#!/usr/bin/env bash

ITEM_NAME="${NAME:-$1}"
SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-/opt/homebrew/bin/sketchybar}"
if [ -n "$INFO" ]; then
  app_name="$INFO"
else
  app_name=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)
fi

"$SKETCHYBAR_BIN" --set "$ITEM_NAME" label="${app_name:-Finder}"
