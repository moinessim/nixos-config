#!/usr/bin/env bash

ITEM_NAME="${NAME:-$1}"
SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-/opt/homebrew/bin/sketchybar}"
CTL_SCRIPT="${HOME}/.config/topmanage-vpn/ctl.sh"

enabled="off"
connected="off"

if [ -x "$CTL_SCRIPT" ]; then
  while IFS='=' read -r key value; do
    case "$key" in
      enabled) enabled="$value" ;;
      connected) connected="$value" ;;
    esac
  done < <("$CTL_SCRIPT" status)
fi

icon="VPN"
label="Off"
icon_color="0xff7f8c8d"
label_color="0xff7f8c8d"

if [ "$enabled" = "on" ] && [ "$connected" = "on" ]; then
  label="On"
  icon_color="0xff8bd5ca"
  label_color="0xff8bd5ca"
elif [ "$enabled" = "on" ]; then
  label="Wait"
  icon_color="0xfff5a97f"
  label_color="0xfff5a97f"
fi

"$SKETCHYBAR_BIN" --set "$ITEM_NAME" \
  icon="$icon" \
  label="$label" \
  icon.color="$icon_color" \
  label.color="$label_color"
