#!/usr/bin/env bash
# ==============================================================================
# lang_ctl.sh — Переключение языка интерфейса сборки (ru / en)
# ==============================================================================

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
LANG_FILE="$CACHE_DIR/dots_lang"
PID_FILE="$CACHE_DIR/sidebar.pid"
mkdir -p "$CACHE_DIR"

get_lang() {
    if [[ -f "$LANG_FILE" ]]; then
        cat "$LANG_FILE"
    else
        echo "en"
    fi
}

set_lang() {
    local l="$1"
    if [[ "$l" != "ru" && "$l" != "en" ]]; then
        l="en"
    fi
    echo "$l" > "$LANG_FILE"

    # Перезапускаем sidebar если запущен
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            sleep 0.2
            python3 "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/sidebar/sidebar.py" &>> /tmp/sidebar.log &
        fi
    fi

    if command -v notify-send &>/dev/null; then
        if [[ "$l" == "en" ]]; then
            notify-send -a "Language" -i preferences-desktop-locale "Interface Language" "Set to English" -t 2000
        else
            notify-send -a "Язык" -i preferences-desktop-locale "Язык интерфейса" "Установлен русский" -t 2000
        fi
    fi
    echo "$l"
}

toggle_lang() {
    local cur
    cur=$(get_lang)
    if [[ "$cur" == "ru" ]]; then
        set_lang "en"
    else
        set_lang "ru"
    fi
}

case "${1:-get}" in
    get)    get_lang ;;
    set)    set_lang "$2" ;;
    toggle) toggle_lang ;;
    *)
        echo "Usage: $0 [get | set <en|ru> | toggle]"
        exit 1
        ;;
esac
