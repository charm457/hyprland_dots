#!/bin/bash
# waybar_position.sh — переключение позиции Waybar
# Только: top ↔ bottom ↔ hidden

STATE_FILE="$HOME/.cache/waybar_position"
CONFIG="$HOME/.config/waybar/config"

export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

start_waybar() {
    pkill -x waybar 2>/dev/null
    sleep 0.5
    hyprctl dispatch exec -- waybar
}

get_current() {
    [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" || echo "top"
}

apply_position() {
    local POS="$1"
    echo "$POS" > "$STATE_FILE"

    if [[ "$POS" == "hidden" ]]; then
        pkill -x waybar 2>/dev/null
        notify-send "Waybar" "Панель скрыта  ·  Super+Alt+P — показать" -t 2000
        return
    fi

    python3 - <<EOF
import json

with open("$CONFIG") as f:
    data = json.load(f)

data["position"] = "$POS"
data.pop("width", None)
data["height"] = 36

with open("$CONFIG", "w") as f:
    json.dump(data, f, indent=4, ensure_ascii=False)
EOF

    start_waybar
    notify-send "Waybar" "Позиция панели: $POS" -t 2000
}

ACTION="${1:-toggle}"

case "$ACTION" in
    top|bottom)
        apply_position "$ACTION"
        ;;
    hide|hidden)
        apply_position "hidden"
        ;;
    show)
        CURRENT=$(get_current)
        [[ "$CURRENT" == "hidden" ]] && CURRENT="top"
        apply_position "$CURRENT"
        ;;
    toggle)
        CURRENT=$(get_current)
        case "$CURRENT" in
            top)    apply_position "bottom" ;;
            bottom) apply_position "hidden" ;;
            hidden) apply_position "top"    ;;
            *)      apply_position "top"    ;;
        esac
        ;;
    *)
        echo "Использование: $0 [top|bottom|hide|show|toggle]"
        exit 1
        ;;
esac
