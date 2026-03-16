#!/usr/bin/env bash
# Quick diagnostics for VMware Fusion display issues on NixOS
# Run this inside the VM and paste the output here.
set -euo pipefail

echo "== 1) vmtoolsd status =="
systemctl status vmware --no-pager || systemctl status vmtoolsd --no-pager || true
echo

echo "== 2) vmtoolsd processes =="
ps aux | egrep 'vmtoolsd|vmware' || true
echo

echo "== 3) lsmod (vmw/drm) =="
lsmod | egrep 'vmw|vmwgfx|vmw_pvscsi|drm|modeset' || true
echo

echo "== 4) Session type and user info =="
echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE"
echo "USER=$USER"
loginctl show-session $(loginctl | awk '/^\s*\w/ {if ($3=="'$USER'") {print $1; exit}}') -p Type 2>/dev/null || true
echo

echo "== 5) xrandr and DPI =="
if command -v xrandr >/dev/null 2>&1; then
  xrandr --verbose || true
else
  echo "xrandr: not found"
fi
echo
if command -v xrdb >/dev/null 2>&1; then
  xrdb -query || true
else
  echo "xrdb: not found"
fi
echo
if command -v xset >/dev/null 2>&1; then
  xset q | sed -n '1,200p' || true
else
  echo "xset: not found"
fi
echo

echo "== 6) Xorg journal/search =="
sudo journalctl -b _COMM=Xorg | egrep -i 'vmware|vmwgfx|vmw|glamor|modeset|drm' || true
echo

echo "== 7) OpenGL renderer (glxinfo) =="
if command -v glxinfo >/dev/null 2>&1; then
  glxinfo | egrep 'OpenGL renderer|OpenGL vendor|direct rendering' || true
else
  echo "glxinfo: not found; try: nix-shell -p mesa_utils --run \"glxinfo | egrep 'OpenGL renderer|OpenGL vendor|direct rendering'\""
fi
echo

echo "== 8) /dev/dri and dmesg =="
ls -l /dev/dri || true
sudo dmesg | egrep -i 'vmw|vmwgfx|drm|glamor' | tail -n 200 || true
echo

echo "== 9) NixOS config videoDrivers check =="
grep -nR "videoDrivers" /etc/nixos /etc/profile.d /etc/X11 2>/dev/null || true
nixos-option services.xserver.videoDrivers 2>/dev/null || true
echo

echo "== 10) Wayland info (if applicable) =="
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
ps aux | egrep -i 'wayland|weston|sway|gnome-shell' | sed -n '1,200p' || true

echo "== End of report =="

echo "(If some commands fail due to missing programs, run with nix-shell as suggested in the output.)"
