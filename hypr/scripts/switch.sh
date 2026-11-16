#!/usr/bin/env bash
# Forwarder / alias to root switch.sh
ROOT_SWITCH="$HOME/hyprland_dots/switch.sh"
[[ ! -f "$ROOT_SWITCH" ]] && ROOT_SWITCH="$HOME/hyprland_configs/switch.sh"
[[ ! -f "$ROOT_SWITCH" ]] && ROOT_SWITCH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/switch.sh"

if [[ -f "$ROOT_SWITCH" ]]; then
    exec bash "$ROOT_SWITCH" "$@"
else
    echo "switch.sh не найден в корне репозитория."
    exit 1
fi
