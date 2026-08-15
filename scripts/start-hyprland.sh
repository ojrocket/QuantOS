#!/usr/bin/env bash
set -Eeuo pipefail

export XDG_CURRENT_DESKTOP="Hyprland"
export XDG_SESSION_TYPE="wayland"
export XDG_SESSION_DESKTOP="Hyprland"

if ! command -v hyprland >/dev/null 2>&1; then
  echo "Hyprland is not installed on this system." >&2
  exit 1
fi

if command -v waybar >/dev/null 2>&1; then
  waybar -c "$HOME/.config/waybar/config.jsonc" -s "$HOME/.config/waybar/style.css" &
fi

if command -v mako >/dev/null 2>&1; then
  mako &
fi

exec hyprland
