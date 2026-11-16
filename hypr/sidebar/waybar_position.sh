#!/usr/bin/env bash
# Wrapper forwarding to scripts/waybar_position.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/../scripts/waybar_position.sh" ]]; then
    exec "$SCRIPT_DIR/../scripts/waybar_position.sh" "$@"
elif [[ -f "$HOME/.config/hypr/scripts/waybar_position.sh" ]]; then
    exec "$HOME/.config/hypr/scripts/waybar_position.sh" "$@"
fi
