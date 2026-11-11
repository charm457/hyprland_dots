#!/usr/bin/env bash
# ==============================================================================
# window_mode.sh — Управление режимами окон:
# 1. Обычный (Tiling)   — Строгий тайлинг, окна автоматически разделяются,
#                         все новые окна открываются только обычными.
# 2. Свободный (Floating) — Плавающие окна как в Windows, свободное перемещение
#                         и изменение размера, новые окна открываются плавающими.
# ==============================================================================

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
MODE_FILE="$CACHE_DIR/hypr_window_mode"
LANG_FILE="$CACHE_DIR/dots_lang"
mkdir -p "$CACHE_DIR"

APP_LANG="ru"
[[ -f "$LANG_FILE" ]] && APP_LANG=$(cat "$LANG_FILE")

get_mode() {
    if [[ -f "$MODE_FILE" ]]; then
        cat "$MODE_FILE"
    else
        echo "tiling"
    fi
}

set_tiling() {
    echo "tiling" > "$MODE_FILE"

    # Снимаем fullscreen если был
    hyprctl dispatch fullscreen 0 &>/dev/null || true

    # Гарантируем, что ВСЕ новые окна открываются ТОЛЬКО обычными (тайловыми)
    hyprctl keyword windowrule "tile 1, match:class .*" &>/dev/null || true

    # Все текущие открытые окна переводим в тайлинг (settiled)
    if command -v jq &>/dev/null; then
        hyprctl clients -j 2>/dev/null | jq -r '.[] | .address' | while read -r addr; do
            if [[ -n "$addr" && "$addr" != "null" ]]; then
                hyprctl dispatch settiled "address:$addr" &>/dev/null || true
            fi
        done
    else
        hyprctl dispatch settiled &>/dev/null || true
    fi

    # Исключения для системных диалогов сохраняем в float
    hyprctl keyword windowrule "float 1, match:class ^(pavucontrol|blueman-manager|nm-connection-editor|wlogout)$" &>/dev/null || true
    hyprctl keyword windowrule "float 1, match:title ^(Open File|Save File|Choose Wallpaper)$" &>/dev/null || true

    if command -v notify-send &>/dev/null; then
        if [[ "$APP_LANG" == "en" ]]; then
            notify-send -a "Window Mode" -i view-grid "Default Mode (Tiling)" "All windows strictly split and tile" -t 1800
        else
            notify-send -a "Режим окон" -i view-grid "Обычный режим (Тайлинг)" "Все окна открываются только обычными и разделяются" -t 1800
        fi
    fi
}

set_floating() {
    echo "floating" > "$MODE_FILE"

    # Снимаем fullscreen если был
    hyprctl dispatch fullscreen 0 &>/dev/null || true

    # Гарантируем, что ВСЕ новые окна открываются свободно плавающими
    hyprctl keyword windowrule "float 1, match:class .*" &>/dev/null || true

    # Все текущие открытые окна переводим в свободный плавающий режим (setfloating)
    if command -v jq &>/dev/null; then
        hyprctl clients -j 2>/dev/null | jq -r '.[] | .address' | while read -r addr; do
            if [[ -n "$addr" && "$addr" != "null" ]]; then
                hyprctl dispatch setfloating "address:$addr" &>/dev/null || true
            fi
        done
    else
        hyprctl dispatch setfloating &>/dev/null || true
    fi

    if command -v notify-send &>/dev/null; then
        if [[ "$APP_LANG" == "en" ]]; then
            notify-send -a "Window Mode" -i preferences-system-windows "Free Mode (Floating)" "Windows float freely like in Windows (Super+LMB drag, Super+RMB resize)" -t 1800
        else
            notify-send -a "Режим окон" -i preferences-system-windows "Свободный режим (Плавающий)" "Свободные окна как в Windows (Super+ЛКМ тянуть, Super+ПКМ размер)" -t 1800
        fi
    fi
}

toggle_single_window() {
    hyprctl dispatch togglefloating &>/dev/null || true
}

cycle_mode() {
    local cur
    cur=$(get_mode)
    if [[ "$cur" == "floating" || "$cur" == "windows" ]]; then
        set_tiling
    else
        set_floating
    fi
}

init_mode() {
    local cur
    cur=$(get_mode)
    if [[ "$cur" == "floating" || "$cur" == "windows" ]]; then
        set_floating
    else
        set_tiling
    fi
}

case "${1:-status}" in
    tiling|default)
        set_tiling
        ;;
    floating|free|windows)
        set_floating
        ;;
    cycle|toggle)
        cycle_mode
        ;;
    toggle_floating|float)
        toggle_single_window
        ;;
    init)
        init_mode
        ;;
    status)
        get_mode
        ;;
    *)
        echo "Использование: $0 [tiling | floating | cycle | toggle_floating | init | status]"
        exit 1
        ;;
esac
