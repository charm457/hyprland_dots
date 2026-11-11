#!/usr/bin/env bash
# toggle.sh — мгновенное открытие/закрытие sidebar через SIGUSR1

export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
export GDK_BACKEND=wayland

PID_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/sidebar.pid"
SCRIPT="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/sidebar/sidebar.py"

if [[ -f "$PID_FILE" ]]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        # Если файл скрипта новее PID (произошло обновление), перезапускаем на свежую версию
        if [[ -f "$SCRIPT" && "$SCRIPT" -nt "$PID_FILE" ]]; then
            kill -9 "$PID" 2>/dev/null || true
            rm -f "$PID_FILE"
            sleep 0.2
            python3 "$SCRIPT" --show &>> /tmp/sidebar.log &
            exit 0
        fi
        # Демон жив — переключаем видимость
        kill -USR1 "$PID"
        exit 0
    fi
    rm -f "$PID_FILE"
fi

# Демон не запущен — стартуем с открытием
if [[ -f "$SCRIPT" ]]; then
    python3 "$SCRIPT" --show &>> /tmp/sidebar.log &
fi
