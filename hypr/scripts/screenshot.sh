#!/usr/bin/env bash
# ==============================================================================
# screenshot.sh — Утилита скриншотов с сохранением в ~/Screenshots
# ==============================================================================

DIR="${SCREENSHOT_DIR:-$HOME/Screenshots}"
mkdir -p "$DIR"

FILENAME="Screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"
FILEPATH="$DIR/$FILENAME"

# Определение языка уведомлений (ru / en)
LANG_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/dots_lang"
APP_LANG="ru"
[[ -f "$LANG_CACHE" ]] && APP_LANG=$(cat "$LANG_CACHE")

notify_saved() {
    if [[ "$APP_LANG" == "en" ]]; then
        notify-send -a "Screenshot" -i "$FILEPATH" "Screenshot Saved & Copied" "$FILENAME" -t 3000
    else
        notify-send -a "Скриншот" -i "$FILEPATH" "Скриншот сохранен и скопирован" "$FILENAME" -t 3000
    fi
}

notify_cancelled() {
    if [[ "$APP_LANG" == "en" ]]; then
        notify-send -a "Screenshot" "Screenshot Cancelled" -t 1500
    else
        notify-send -a "Скриншот" "Снимок отменен" -t 1500
    fi
}

take_area() {
    if command -v grimblast &>/dev/null; then
        if grimblast --cursor copy area "$FILEPATH"; then
            notify_saved
        else
            notify_cancelled
        fi
    elif command -v grim &>/dev/null && command -v slurp &>/dev/null; then
        local geometry
        geometry=$(slurp)
        if [[ -n "$geometry" ]]; then
            sleep 0.1
            grim -g "$geometry" "$FILEPATH"
            wl-copy < "$FILEPATH"
            notify_saved
        else
            notify_cancelled
        fi
    fi
}

take_full() {
    if command -v grimblast &>/dev/null; then
        grimblast --cursor copy output "$FILEPATH"
        notify_saved
    elif command -v grim &>/dev/null; then
        grim "$FILEPATH"
        wl-copy < "$FILEPATH"
        notify_saved
    fi
}

take_window() {
    if command -v grimblast &>/dev/null; then
        if grimblast --cursor copy active "$FILEPATH"; then
            notify_saved
        else
            notify_cancelled
        fi
    elif command -v grim &>/dev/null && command -v hyprctl &>/dev/null; then
        local box
        box=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        if [[ -n "$box" && "$box" != "null,null nullxnull" ]]; then
            grim -g "$box" "$FILEPATH"
            wl-copy < "$FILEPATH"
            notify_saved
        fi
    fi
}

take_delay() {
    local sec="${1:-5}"
    for ((i=sec; i>0; i--)); do
        notify-send -a "Screenshot" "Timer: $i sec..." -t 900
        sleep 1
    done
    take_full
}

show_menu() {
    local opt_area="  Выделить область (Area)"
    local opt_full="  Весь экран (Fullscreen)"
    local opt_win="  Активное окно (Window)"
    local opt_delay="  Задержка 5 сек (5s Delay)"

    if [[ "$APP_LANG" == "en" ]]; then
        opt_area="  Select Area"
        opt_full="  Fullscreen"
        opt_win="  Active Window"
        opt_delay="  5 Seconds Delay"
    fi

    local choice
    choice=$(printf "%s\n%s\n%s\n%s" "$opt_area" "$opt_full" "$opt_win" "$opt_delay" | rofi -dmenu -p "Screenshot" -theme-str 'window {width: 320px;}')

    case "$choice" in
        *"$opt_area"*)  take_area ;;
        *"$opt_full"*)  take_full ;;
        *"$opt_win"*)   take_window ;;
        *"$opt_delay"*) take_delay 5 ;;
    esac
}

case "${1:-area}" in
    area)   take_area ;;
    full)   take_full ;;
    window) take_window ;;
    delay)  take_delay "${2:-5}" ;;
    menu)   show_menu ;;
    *)
        echo "Usage: $0 [area | full | window | delay <sec> | menu]"
        exit 1
        ;;
esac
