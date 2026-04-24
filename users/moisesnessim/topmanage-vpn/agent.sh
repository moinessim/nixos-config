#!/usr/bin/env bash

set -euo pipefail

USER_NAME="${USER:-$(id -un)}"
export PATH="/etc/profiles/per-user/$USER_NAME/bin:/run/current-system/sw/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

VPN_NAME="${TOPMANAGE_VPN_NAME:-TopManage}"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="$STATE_ROOT/topmanage-vpn"
ENABLED_FILE="$STATE_DIR/enabled"
SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-/opt/homebrew/bin/sketchybar}"
REFRESH_EVENT="topmanage_vpn_change"
POLL_SECONDS="${TOPMANAGE_VPN_POLL_SECONDS:-15}"
VPNUTIL_BIN="${VPNUTIL_BIN:-$(command -v vpnutil)}"

mkdir -p "$STATE_DIR"

is_enabled() {
  [ -f "$ENABLED_FILE" ]
}

is_connected() {
  "$VPNUTIL_BIN" status "$VPN_NAME" 2>/dev/null | grep -Eqi '(^|[^[:alpha:]])Connected([^[:alpha:]]|$)'
}

refresh_sketchybar() {
  if [ -x "$SKETCHYBAR_BIN" ]; then
    "$SKETCHYBAR_BIN" --trigger "$REFRESH_EVENT" >/dev/null 2>&1 || true
  fi
}

previous_state="unknown"

while true; do
  desired="disabled"
  actual="disconnected"

  if is_enabled; then
    desired="enabled"
  fi

  if is_connected; then
    actual="connected"
  fi

  if [ "$desired" = "enabled" ] && [ "$actual" = "disconnected" ]; then
    "$VPNUTIL_BIN" start "$VPN_NAME" >/dev/null 2>&1 || true
    actual="connecting"
  elif [ "$desired" = "disabled" ] && [ "$actual" = "connected" ]; then
    "$VPNUTIL_BIN" stop "$VPN_NAME" >/dev/null 2>&1 || true
    actual="disconnecting"
  fi

  current_state="$desired:$actual"
  if [ "$current_state" != "$previous_state" ]; then
    refresh_sketchybar
    previous_state="$current_state"
  fi

  sleep "$POLL_SECONDS"
done
