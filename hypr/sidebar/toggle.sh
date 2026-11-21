#!/usr/bin/env bash
# toggle.sh — мгновенное открытие/закрытие sidebar через SIGUSR1 с авто-синхронизацией

export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
export GDK_BACKEND=wayland

PID_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/sidebar.pid"
CONFIG_SCRIPT="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/sidebar/sidebar.py"
REPO_SCRIPT="$HOME/hyprland_dots/hypr/sidebar/sidebar.py"
[[ ! -f "$REPO_SCRIPT" ]] && REPO_SCRIPT="$HOME/hyprland_configs/hypr/sidebar/sidebar.py"

# Авто-синхронизация из репозитория при наличии свежей версии
if [[ -f "$REPO_SCRIPT" ]]; then
    if [[ ! -f "$CONFIG_SCRIPT" || "$REPO_SCRIPT" -nt "$CONFIG_SCRIPT" ]]; then
        mkdir -p "$(dirname "$CONFIG_SCRIPT")"
        cp -f "$REPO_SCRIPT" "$CONFIG_SCRIPT"
        chmod +x "$CONFIG_SCRIPT"
    fi
fi

SCRIPT="$CONFIG_SCRIPT"
[[ ! -f "$SCRIPT" && -f "$REPO_SCRIPT" ]] && SCRIPT="$REPO_SCRIPT"

launch_sidebar() {
    if command -v hyprctl &>/dev/null && pgrep -x Hyprland &>/dev/null; then
        if hyprctl dispatch "hl.dsp.exec_cmd(\"python3 $SCRIPT --show\")" &>/dev/null; then
            return 0
        elif hyprctl dispatch exec "python3 $SCRIPT --show" &>/dev/null; then
            return 0
        fi
    fi
    nohup python3 "$SCRIPT" --show </dev/null &>> /tmp/sidebar.log &
    disown || true
}

if [[ -f "$PID_FILE" ]]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        # Если файл скрипта новее PID (произошло обновление), перезапускаем на свежую версию
        if [[ -f "$SCRIPT" && "$SCRIPT" -nt "$PID_FILE" ]]; then
            kill -9 "$PID" 2>/dev/null || true
            rm -f "$PID_FILE"
            sleep 0.2
            launch_sidebar
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
    launch_sidebar
fi
