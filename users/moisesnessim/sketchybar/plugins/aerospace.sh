#!/usr/bin/env bash

SPACE_ID="$1"
ITEM_NAME="${NAME:-$2}"
SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-/opt/homebrew/bin/sketchybar}"
AEROSPACE_BIN="${AEROSPACE_BIN:-/opt/homebrew/bin/aerospace}"

# Step 1: Build aerospace monitor → NSScreen display mapping
declare -A DISPLAY_MAP
while IFS=" " read -r aero_id display_id; do
  DISPLAY_MAP["$aero_id"]="$display_id"
done < <("$AEROSPACE_BIN" list-monitors --format '%{monitor-id} %{monitor-appkit-nsscreen-screens-id}' 2>/dev/null)

# Step 2: Find which monitor shows this workspace as visible
# If found, update display and highlight
for mon_id in "${!DISPLAY_MAP[@]}"; do
  VISIBLE_ON_MON=$("$AEROSPACE_BIN" list-workspaces --monitor "$mon_id" --visible 2>/dev/null)
  if [ "$VISIBLE_ON_MON" = "$SPACE_ID" ]; then
    "$SKETCHYBAR_BIN" --set "$ITEM_NAME" \
      display="${DISPLAY_MAP[$mon_id]}" \
      background.color=0xff8aadf4 \
      background.drawing=on \
      label.color=0xff1e2030
    exit 0
  fi
done

# Not visible on any monitor — unhighlight (keep current display)
"$SKETCHYBAR_BIN" --set "$ITEM_NAME" \
  background.color=0x00000000 \
  background.drawing=off \
  label.color=0xffe8e8e8
