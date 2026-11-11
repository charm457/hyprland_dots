#!/bin/bash
# Цикличная смена обоев из ~/wallpapers/
# Использование: wallpaper_cycle.sh [next|prev]

WALLPAPER_DIR="$HOME/wallpapers"
STATE_FILE="$HOME/.cache/wallpaper_index"

# Собираем список обоев (сортированный)
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort)

TOTAL=${#WALLPAPERS[@]}
if [[ $TOTAL -eq 0 ]]; then
    notify-send "Обои" "Папка $WALLPAPER_DIR пуста" -i image
    exit 1
fi

# Читаем текущий индекс
INDEX=0
if [[ -f "$STATE_FILE" ]]; then
    INDEX=$(cat "$STATE_FILE")
fi

# Переключаем
case "${1:-next}" in
    next)
        INDEX=$(( (INDEX + 1) % TOTAL ))
        ;;
    prev)
        INDEX=$(( (INDEX - 1 + TOTAL) % TOTAL ))
        ;;
esac

echo "$INDEX" > "$STATE_FILE"

WALLPAPER="${WALLPAPERS[$INDEX]}"
BASENAME=$(basename "$WALLPAPER")

# Убиваем старый swaybg и запускаем новый
pkill swaybg 2>/dev/null
sleep 0.1
swaybg -i "$WALLPAPER" -m stretch &

notify-send "Обои" "[$((INDEX+1))/$TOTAL] $BASENAME" -i "$WALLPAPER" -t 2000
