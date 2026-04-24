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
VPNUTIL_BIN="${VPNUTIL_BIN:-$(command -v vpnutil)}"

mkdir -p "$STATE_DIR"

is_enabled() {
  [ -f "$ENABLED_FILE" ]
}

status_text() {
  "$VPNUTIL_BIN" status "$VPN_NAME" 2>/dev/null || true
}

is_connected() {
  status_text | grep -Eqi '(^|[^[:alpha:]])Connected([^[:alpha:]]|$)'
}

refresh_sketchybar() {
  if [ -x "$SKETCHYBAR_BIN" ]; then
    "$SKETCHYBAR_BIN" --trigger "$REFRESH_EVENT" >/dev/null 2>&1 || true
  fi
}

print_status() {
  local enabled="off"
  local connected="off"

  if is_enabled; then
    enabled="on"
  fi

  if is_connected; then
    connected="on"
  fi

  printf 'enabled=%s\n' "$enabled"
  printf 'connected=%s\n' "$connected"
  printf 'vpn_name=%s\n' "$VPN_NAME"
}

enable_vpn() {
  touch "$ENABLED_FILE"
  "$VPNUTIL_BIN" start "$VPN_NAME" >/dev/null 2>&1 || true
  refresh_sketchybar
}

disable_vpn() {
  rm -f "$ENABLED_FILE"
  "$VPNUTIL_BIN" stop "$VPN_NAME" >/dev/null 2>&1 || true
  refresh_sketchybar
}

usage() {
  cat <<'EOF'
Usage: tm-vpn [enable|disable|toggle|status]

enable   Persist desired state as connected and start the VPN
disable  Persist desired state as disconnected and stop the VPN
toggle   Switch between enable and disable
status   Print enabled and connected status
EOF
}

command="${1:-status}"

case "$command" in
  enable|on|start)
    enable_vpn
    ;;
  disable|off|stop)
    disable_vpn
    ;;
  toggle)
    if is_enabled; then
      disable_vpn
    else
      enable_vpn
    fi
    ;;
  status)
    print_status
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
