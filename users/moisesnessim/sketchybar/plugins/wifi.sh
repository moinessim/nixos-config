#!/usr/bin/env bash

ITEM_NAME="${NAME:-$1}"
SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-/opt/homebrew/bin/sketchybar}"
state_file="/tmp/sketchybar_wifi_${UID}.state"
iface=$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/ { getline; print $2; exit }')
[ -z "$iface" ] && iface="en0"

stats=$(netstat -ibn | awk -v iface="$iface" '$1 == iface { rx = $7; tx = $10 } END { print rx, tx }')
rx=$(printf '%s\n' "$stats" | awk '{ print $1 }')
tx=$(printf '%s\n' "$stats" | awk '{ print $2 }')
now=$(date +%s)

down_bps=0
up_bps=0

if [ -f "$state_file" ]; then
  read -r prev_time prev_rx prev_tx < "$state_file"
  delta_time=$((now - prev_time))
  if [ "$delta_time" -gt 0 ]; then
    down_bps=$(((rx - prev_rx) / delta_time))
    up_bps=$(((tx - prev_tx) / delta_time))
  fi
fi

printf '%s %s %s\n' "$now" "$rx" "$tx" > "$state_file"

format_speed() {
  local bytes_per_sec="$1"

  if [ "$bytes_per_sec" -ge 1000000 ]; then
    awk -v value="$bytes_per_sec" 'BEGIN { printf "%.1f MB/s", value / 1000000 }'
  elif [ "$bytes_per_sec" -ge 1000 ]; then
    awk -v value="$bytes_per_sec" 'BEGIN { printf "%.0f KB/s", value / 1000 }'
  else
    printf '%d B/s' "$bytes_per_sec"
  fi
}

label="$(format_speed "$down_bps") / $(format_speed "$up_bps")"
"$SKETCHYBAR_BIN" --set "$ITEM_NAME" label="$label"
