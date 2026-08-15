#!/usr/bin/env bash
set -Eeuo pipefail

# QuantOS local autostart for a smooth Hyprland desktop experience.
# This file is intentionally minimal and safe to extend.

# Ensure the user environment is loaded.
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland

# Kick off background services only when available.
if command -v wl-paste >/dev/null 2>&1; then
    :
fi

if command -v mako >/dev/null 2>&1; then
    mako &
fi

if command -v waybar >/dev/null 2>&1; then
    waybar &
fi

if command -v kanshi >/dev/null 2>&1; then
    kanshi &
fi
