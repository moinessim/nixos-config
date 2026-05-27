#!/usr/bin/env bash

SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-/opt/homebrew/bin/sketchybar}"

# Get display info
DISPLAYS=$("$SKETCHYBAR_BIN" --query displays)

# Find the ID of the display with the largest width
# and its width
read -r BIGGEST_ID BIGGEST_WIDTH <<< $(echo "$DISPLAYS" | jq -r 'sort_by(.frame.w) | reverse | .[0] | "\(.["arrangement-id"]) \(.frame.w)"')

THRESHOLD=1400
ITEMS=(cpu mem disk vpn wifi)

if [ -z "$BIGGEST_WIDTH" ] || [ "${BIGGEST_WIDTH%.*}" -lt "$THRESHOLD" ]; then
  # If even the biggest display is too small, hide them everywhere
  for item in "${ITEMS[@]}"; do
    "$SKETCHYBAR_BIN" --set "$item" drawing=off
  done
else
  # Show them only on the biggest display to avoid overlap on smaller ones
  for item in "${ITEMS[@]}"; do
    "$SKETCHYBAR_BIN" --set "$item" drawing=on display="$BIGGEST_ID"
  done
fi
