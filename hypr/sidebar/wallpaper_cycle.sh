#!/usr/bin/env bash
# Wrapper forwarding to scripts/wallpaper_cycle.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/../scripts/wallpaper_cycle.sh" ]]; then
    exec "$SCRIPT_DIR/../scripts/wallpaper_cycle.sh" "$@"
elif [[ -f "$HOME/.config/hypr/scripts/wallpaper_cycle.sh" ]]; then
    exec "$HOME/.config/hypr/scripts/wallpaper_cycle.sh" "$@"
fi
