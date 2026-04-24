#!/usr/bin/env bash

ITEM_NAME="${NAME:-$1}"
SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-/opt/homebrew/bin/sketchybar}"
vm_stat_output=$(vm_stat)
page_size=$(printf '%s\n' "$vm_stat_output" | awk '/page size of/ { print $8; exit }')
[ -z "$page_size" ] && page_size=4096

active=$(printf '%s\n' "$vm_stat_output" | awk '/Pages active/ { gsub(/\./, "", $3); print $3; exit }')
wired=$(printf '%s\n' "$vm_stat_output" | awk '/Pages wired down/ { gsub(/\./, "", $4); print $4; exit }')
compressed=$(printf '%s\n' "$vm_stat_output" | awk '/Pages occupied by compressor/ { gsub(/\./, "", $5); print $5; exit }')
free=$(printf '%s\n' "$vm_stat_output" | awk '/Pages free/ { gsub(/\./, "", $3); print $3; exit }')
inactive=$(printf '%s\n' "$vm_stat_output" | awk '/Pages inactive/ { gsub(/\./, "", $3); print $3; exit }')
speculative=$(printf '%s\n' "$vm_stat_output" | awk '/Pages speculative/ { gsub(/\./, "", $3); print $3; exit }')

used=$((active + wired + compressed))
total=$((used + free + inactive + speculative))

if [ "$total" -gt 0 ]; then
  pct=$((used * 100 / total))
else
  pct=0
fi

"$SKETCHYBAR_BIN" --set "$ITEM_NAME" label="${pct}%"
