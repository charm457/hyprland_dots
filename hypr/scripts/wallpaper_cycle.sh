#!/usr/bin/env bash
# ==============================================================================
# wallpaper_cycle.sh — Цикличная смена обоев
# ==============================================================================

WALLPAPER_DIR="$HOME/wallpapers"
STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper_index"
CACHE_WP="${XDG_CACHE_HOME:-$HOME/.cache}/current_wallpaper"

mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"

# Собираем список обоев из ~/wallpapers
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | sort)

TOTAL=${#WALLPAPERS[@]}
if [[ $TOTAL -eq 0 ]]; then
    if command -v notify-send &>/dev/null; then
        notify-send -a "Обои" "Нет изображений в $WALLPAPER_DIR" -i image
    fi
    exit 1
fi

INDEX=0
if [[ -f "$STATE_FILE" ]]; then
    INDEX=$(cat "$STATE_FILE")
fi

case "${1:-next}" in
    next)
        INDEX=$(( (INDEX + 1) % TOTAL ))
        ;;
    prev)
        INDEX=$(( (INDEX - 1 + TOTAL) % TOTAL ))
        ;;
    rand|random)
        INDEX=$(( RANDOM % TOTAL ))
        ;;
esac

echo "$INDEX" > "$STATE_FILE"
WALLPAPER="${WALLPAPERS[$INDEX]}"
echo "$WALLPAPER" > "$CACHE_WP"
BASENAME=$(basename "$WALLPAPER")

# Обновляем swaybg
pkill swaybg 2>/dev/null || true
sleep 0.1
swaybg -i "$WALLPAPER" -m stretch &

if command -v notify-send &>/dev/null; then
    notify-send -a "Обои" "[$((INDEX+1))/$TOTAL] $BASENAME" -i "$WALLPAPER" -t 1800
fi
