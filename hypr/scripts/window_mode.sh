#!/usr/bin/env bash
# ==============================================================================
# window_mode.sh — Управление режимами окон:
# 1. Tiling   — Плитка / Авто-тайлинг (стандартный Hyprland)
# 2. Monocle  — На весь экран с Waybar (fullscreen 1)
# 3. Windows  — Обычный режим Windows (плавающие окна, перекрытие, drag&drop)
# ==============================================================================

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
MODE_FILE="$CACHE_DIR/hypr_window_mode"
mkdir -p "$CACHE_DIR"

get_mode() {
    if [[ -f "$MODE_FILE" ]]; then
        cat "$MODE_FILE"
    else
        echo "tiling"
    fi
}

set_monocle() {
    # Режим "На полный экран, но с Waybar"
    echo "monocle" > "$MODE_FILE"
    
    # Снимаем глобальный float если был
    hyprctl keyword windowrulev2 "unset, class:^(.*)$" &>/dev/null || true

    # Разворачиваем текущее окно на полный экран с сохранением Waybar (fullscreen 1)
    hyprctl dispatch fullscreen 1 &>/dev/null || true

    pkill -RTMIN+8 waybar 2>/dev/null || true
    if command -v notify-send &>/dev/null; then
        notify-send -a "Hyprland Layout" -i view-fullscreen "Режим окон: На весь экран" "Окно развернуто на весь экран (Waybar сохранён)" -t 1800
    fi
}

set_windows() {
    # Режим "Как на обычной Windows" — плавающие окна
    echo "windows" > "$MODE_FILE"

    # Снимаем fullscreen если был
    hyprctl dispatch fullscreen 0 &>/dev/null || true

    # Новые окна будут открываться плавающими
    hyprctl keyword windowrulev2 "float, class:^(.*)$" &>/dev/null || true

    # Делаем все окна на текущем workspace плавающими
    if command -v jq &>/dev/null; then
        local active_ws
        active_ws=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id')
        if [[ -n "$active_ws" && "$active_ws" != "null" ]]; then
            hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.workspace.id == $active_ws and .floating == false) | .address" | while read -r addr; do
                if [[ -n "$addr" ]]; then
                    hyprctl dispatch togglefloating "address:$addr" &>/dev/null || true
                fi
            done
        fi
    else
        hyprctl dispatch togglefloating &>/dev/null || true
    fi

    pkill -RTMIN+8 waybar 2>/dev/null || true
    if command -v notify-send &>/dev/null; then
        notify-send -a "Hyprland Layout" -i preferences-system-windows "Режим окон: Windows" "Плавающие окна как в обычной Windows (Super+ЛКМ тянуть, Super+ПКМ размер)" -t 2000
    fi
}

set_tiling() {
    # Режим "Плиточный тайлинг"
    echo "tiling" > "$MODE_FILE"

    # Снимаем fullscreen
    hyprctl dispatch fullscreen 0 &>/dev/null || true

    # Отключаем глобальный float для новых окон
    hyprctl keyword windowrulev2 "unset, class:^(.*)$" &>/dev/null || true

    # Возвращаем плавающие окна обратно в плитку на текущем workspace
    if command -v jq &>/dev/null; then
        local active_ws
        active_ws=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id')
        if [[ -n "$active_ws" && "$active_ws" != "null" ]]; then
            hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.workspace.id == $active_ws and .floating == true) | .address" | while read -r addr; do
                if [[ -n "$addr" ]]; then
                    hyprctl dispatch togglefloating "address:$addr" &>/dev/null || true
                fi
            done
        fi
    else
        hyprctl dispatch togglefloating &>/dev/null || true
    fi

    pkill -RTMIN+8 waybar 2>/dev/null || true
    if command -v notify-send &>/dev/null; then
        notify-send -a "Hyprland Layout" -i view-grid "Режим окон: Плитка" "Автоматическое тайлинговое разделение окон" -t 1800
    fi
}

toggle_floating() {
    hyprctl dispatch togglefloating &>/dev/null || true
}

cycle_mode() {
    local cur
    cur=$(get_mode)
    case "$cur" in
        tiling)
            set_monocle
            ;;
        monocle)
            set_windows
            ;;
        windows)
            set_tiling
            ;;
        *)
            set_tiling
            ;;
    esac
}

status_icon() {
    local cur
    cur=$(get_mode)
    case "$cur" in
        monocle)
            echo "⛶ Макс"
            ;;
        windows)
            echo "🪟 Win"
            ;;
        *)
            echo "▦ Плитка"
            ;;
    esac
}

case "${1:-status}" in
    monocle)
        set_monocle
        ;;
    windows)
        set_windows
        ;;
    tiling)
        set_tiling
        ;;
    toggle_floating|float)
        toggle_floating
        ;;
    cycle)
        cycle_mode
        ;;
    status)
        get_mode
        ;;
    status_icon)
        status_icon
        ;;
    *)
        echo "Использование: $0 [monocle | windows | tiling | toggle_floating | cycle | status | status_icon]"
        exit 1
        ;;
esac
