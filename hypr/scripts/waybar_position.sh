#!/usr/bin/env bash
# ==============================================================================
# waybar_position.sh — переключение позиции Waybar (top / bottom / hidden)
# ==============================================================================

STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar_position"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/config"

export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

start_waybar() {
    pkill -x waybar 2>/dev/null || true
    sleep 0.3
    if command -v hyprctl &>/dev/null; then
        hyprctl dispatch exec -- waybar
    else
        waybar &
    fi
}

get_current() {
    [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" || echo "top"
}

apply_position() {
    local POS="$1"
    echo "$POS" > "$STATE_FILE"

    if [[ "$POS" == "hidden" ]]; then
        pkill -x waybar 2>/dev/null || true
        if command -v notify-send &>/dev/null; then
            notify-send -a "Waybar" "Панель скрыта" "Super+Alt+P — вернуть панель" -t 2000
        fi
        return
    fi

    python3 - <<EOF
import json

try:
    with open("$CONFIG") as f:
        data = json.load(f)

    data["position"] = "$POS"
    data.pop("width", None)
    data["height"] = 36

    with open("$CONFIG", "w") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
except Exception as e:
    print(f"Error updating waybar config: {e}")
EOF

    start_waybar
    if command -v notify-send &>/dev/null; then
        notify-send -a "Waybar" "Позиция панели: $POS" -t 1800
    fi
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
