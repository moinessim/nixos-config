#!/usr/bin/env bash

ITEM_NAME="${NAME:-$1}"
SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-/opt/homebrew/bin/sketchybar}"

# Get available disk space for the root partition
disk_free=$(df -h / | awk 'NR==2{print $4}')

"$SKETCHYBAR_BIN" --set "$ITEM_NAME" label="${disk_free}"
