#!/bin/bash
# toggle.sh — мгновенное открытие/закрытие sidebar через SIGUSR1

export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
export GDK_BACKEND=wayland

PID_FILE="$HOME/.cache/sidebar.pid"
SCRIPT="$HOME/.config/hypr/sidebar/sidebar.py"

if [[ -f "$PID_FILE" ]]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        # Демон жив — просто переключаем видимость (мгновенно!)
        kill -USR1 "$PID"
        exit 0
    fi
    rm -f "$PID_FILE"
fi

# Демон не запущен — стартуем
python3 "$SCRIPT" &>> /tmp/sidebar.log &
