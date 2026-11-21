#!/usr/bin/env bash
# Forwarder to root switch.sh or local logic
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_SWITCH="$DIR/../../switch.sh"
[[ ! -f "$ROOT_SWITCH" ]] && ROOT_SWITCH="$HOME/hyprland_configs/switch.sh"
[[ ! -f "$ROOT_SWITCH" ]] && ROOT_SWITCH="$HOME/hyprland_dots/switch.sh"
[[ ! -f "$ROOT_SWITCH" ]] && ROOT_SWITCH="$HOME/.config/hypr/switch.sh"

if [[ -f "$ROOT_SWITCH" ]]; then
    exec bash "$ROOT_SWITCH" "$@"
else
    echo "switch.sh не найден."
    exit 1
fi
