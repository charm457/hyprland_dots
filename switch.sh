#!/usr/bin/env bash
# switch.sh — переключение между профилями конфигов (main / cybrdots)

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-main}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$CACHE_DIR"

if [[ "$TARGET" != "main" && "$TARGET" != "cybrdots" ]]; then
    echo "Использование: $0 [main | cybrdots]"
    exit 1
fi

cd "$DIR"
echo "Переключаем профиль на: $TARGET..."

# Текущая ветка до переключения
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

# Сохраняем текущие обои для активного профиля
if [[ -f "$CACHE_DIR/current_wallpaper" ]]; then
    CURRENT_WP=$(cat "$CACHE_DIR/current_wallpaper")
    if [[ -n "$CURRENT_WP" && -f "$CURRENT_WP" ]]; then
        if [[ "$CURRENT_BRANCH" == "cybrdots" ]]; then
            echo "$CURRENT_WP" > "$CACHE_DIR/cybrdots_wallpaper"
        else
            echo "$CURRENT_WP" > "$CACHE_DIR/main_wallpaper"
        fi
    fi
fi

# Сбрасываем сгенерированные файлы тем перед переключением веток
git reset --hard HEAD >/dev/null 2>&1 || true
git clean -fd >/dev/null 2>&1 || true

# Принудительное переключение ветки
git checkout -f "$TARGET"

# 1. Применение обоев под целевой профиль
WP=""
if [[ "$TARGET" == "cybrdots" ]]; then
    if [[ -f "$CACHE_DIR/cybrdots_wallpaper" && -f "$(cat "$CACHE_DIR/cybrdots_wallpaper")" ]]; then
        WP=$(cat "$CACHE_DIR/cybrdots_wallpaper")
    elif [[ -f "$HOME/wallpapers/samurai-2560x1440.png" ]]; then
        WP="$HOME/wallpapers/samurai-2560x1440.png"
    elif [[ -d "$HOME/wallpapers" ]]; then
        WP=$(find "$HOME/wallpapers" -type f \( -name "*.png" -o -name "*.jpg" \) 2>/dev/null | head -n 1)
    fi
else
    if [[ -f "$CACHE_DIR/main_wallpaper" && -f "$(cat "$CACHE_DIR/main_wallpaper")" ]]; then
        WP=$(cat "$CACHE_DIR/main_wallpaper")
    elif [[ -f "$HOME/wallpapers/ikebukuro-2560x1440.png" ]]; then
        WP="$HOME/wallpapers/ikebukuro-2560x1440.png"
    elif [[ -d "$HOME/wallpapers" ]]; then
        WP=$(find "$HOME/wallpapers" -type f \( -name "*.png" -o -name "*.jpg" \) 2>/dev/null | head -n 1)
    fi
fi

if [[ -n "$WP" && -f "$WP" ]]; then
    echo "$WP" > "$CACHE_DIR/current_wallpaper"
    pkill swaybg 2>/dev/null || true
    sleep 0.1
    nohup swaybg -i "$WP" -m stretch </dev/null &>/dev/null &
fi

# 2. Восстановление темы для main
if [[ "$TARGET" == "main" && -f "$DIR/hypr/scripts/theme_ctl.sh" ]]; then
    cur="black_solid"
    [[ -f "$CACHE_DIR/sidebar_theme" ]] && cur=$(cat "$CACHE_DIR/sidebar_theme")
    cat="${cur%%_*}"
    sub="${cur#*_}"
    if [[ -z "$cat" || -z "$sub" || "$cat" == "$sub" ]]; then
        cat="black"
        sub="solid"
    fi
    "$DIR/hypr/scripts/theme_ctl.sh" set "$cat" "$sub" &>/dev/null || true
fi

# 3. Перезагрузка Hyprland при активной сессии
if command -v hyprctl &>/dev/null && pgrep -x Hyprland &>/dev/null; then
    hyprctl reload &>/dev/null || true
fi

# 4. Обновление стилей Kitty терминала
pkill -SIGUSR1 -x kitty 2>/dev/null || true
pkill -SIGUSR1 -f kitty 2>/dev/null || true

# 5. Перезапуск Waybar под новый профиль
if pgrep -x waybar &>/dev/null; then
    killall -9 waybar 2>/dev/null || true
    sleep 0.3
    nohup waybar </dev/null &>/dev/null &
fi

# 6. Перезагрузка стилей SwayNC
if pgrep -x swaync &>/dev/null; then
    swaync-client -R 2>/dev/null || true
    swaync-client -rs 2>/dev/null || true
fi

# 7. Уведомление
if command -v notify-send &>/dev/null; then
    if [[ "$TARGET" == "cybrdots" ]]; then
        notify-send -a "Стиль оформления" -i preferences-desktop-theme "Киберпанк профиль активирован" "Неоновый Waybar, обои Samurai, Kitty cybrcore" -t 2500
    else
        notify-send -a "Стиль оформления" -i preferences-desktop-theme "Классический профиль активирован" "Стандартный профиль Hyprland" -t 2500
    fi
fi

echo "Успешно активирован профиль: $TARGET"
