#!/usr/bin/env bash

ITEM_NAME="${NAME:-$1}"
SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-/opt/homebrew/bin/sketchybar}"
battery_info=$(pmset -g batt)
percentage=$(printf '%s\n' "$battery_info" | awk -F';' '/InternalBattery/ {
  gsub(/^.*	/, "", $1)
  gsub(/%.*/, "", $1)
  print $1
  exit
}')

if printf '%s\n' "$battery_info" | grep -q 'AC Power'; then
  icon=AC
else
  icon=BAT
  if [ -n "$percentage" ] && [ "$percentage" -lt 20 ]; then
    icon=LOW
  elif [ -n "$percentage" ] && [ "$percentage" -lt 50 ]; then
    icon=MID
  elif [ -n "$percentage" ] && [ "$percentage" -lt 80 ]; then
    icon=BAT
  else
    icon=FULL
  fi
fi

"$SKETCHYBAR_BIN" --set "$ITEM_NAME" icon="$icon" label="${percentage:-?}%"
