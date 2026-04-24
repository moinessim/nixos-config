#!/usr/bin/env bash

SPACE_ID="$1"
ITEM_NAME="${NAME:-$2}"
SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-/opt/homebrew/bin/sketchybar}"
AEROSPACE_BIN="${AEROSPACE_BIN:-/opt/homebrew/bin/aerospace}"
FOCUSED_WORKSPACE="${AEROSPACE_FOCUSED_WORKSPACE:-$("$AEROSPACE_BIN" list-workspaces --focused 2>/dev/null)}"

if [ "$SPACE_ID" = "$FOCUSED_WORKSPACE" ]; then
  "$SKETCHYBAR_BIN" --set "$ITEM_NAME" \
    background.color=0xff8aadf4 \
    background.drawing=on \
    label.color=0xff1e2030
else
  "$SKETCHYBAR_BIN" --set "$ITEM_NAME" \
    background.color=0x00000000 \
    background.drawing=off \
    label.color=0xffe8e8e8
fi
