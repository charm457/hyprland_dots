#!/usr/bin/env bash
# ==============================================================================
# switch.sh — переключение между профилями конфигов (main / cybrdots)
# ==============================================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-main}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$CACHE_DIR"

if [[ "$TARGET" != "main" && "$TARGET" != "cybrdots" ]]; then
    echo "Использование: $0 [main | cybrdots]"
    exit 1
fi

# Находим корневую директорию репозитория
REPO_DIR="$DIR"
if [[ ! -d "$REPO_DIR/.git" ]]; then
    if [[ -d "$HOME/hyprland_dots/.git" ]]; then
        REPO_DIR="$HOME/hyprland_dots"
    elif [[ -d "$HOME/hyprland_configs/.git" ]]; then
        REPO_DIR="$HOME/hyprland_configs"
    elif [[ -d "$HOME/dotfiles/.git" ]]; then
        REPO_DIR="$HOME/dotfiles"
    fi
fi

echo "Переключаем профиль на: $TARGET..."

# 1. Сохраняем текущие обои и состояние
CURRENT_BRANCH="main"
if [[ -d "$REPO_DIR/.git" ]]; then
    CURRENT_BRANCH=$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
fi

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

# 2. Если в git есть соответствующая ветка, переключаем её
if [[ -d "$REPO_DIR/.git" ]]; then
    cd "$REPO_DIR"
    if git show-ref --verify --quiet "refs/heads/$TARGET" || git show-ref --verify --quiet "refs/remotes/origin/$TARGET"; then
        git reset --hard HEAD >/dev/null 2>&1 || true
        git clean -fd >/dev/null 2>&1 || true
        git checkout -f "$TARGET" >/dev/null 2>&1 || true
    fi
fi

# 3. Синхронизируем файлы профиля в ~/.config
if [[ -d "$REPO_DIR/hypr" ]]; then
    mkdir -p "$HOME/.config/hypr" "$HOME/.config/waybar" "$HOME/.config/kitty"
    cp -rf "$REPO_DIR/hypr/"* "$HOME/.config/hypr/" 2>/dev/null || true
    cp -rf "$REPO_DIR/waybar/"* "$HOME/.config/waybar/" 2>/dev/null || true
    cp -rf "$REPO_DIR/kitty/"* "$HOME/.config/kitty/" 2>/dev/null || true
    chmod +x "$HOME/.config/hypr/scripts/"*.sh "$HOME/.config/hypr/sidebar/"*.sh "$HOME/.config/hypr/sidebar/sidebar.py" 2>/dev/null || true
fi

# 4. Применение обоев под целевой профиль
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

# 5. Применение темы оформления
THEME_CTL="$HOME/.config/hypr/scripts/theme_ctl.sh"
[[ ! -f "$THEME_CTL" && -f "$REPO_DIR/hypr/scripts/theme_ctl.sh" ]] && THEME_CTL="$REPO_DIR/hypr/scripts/theme_ctl.sh"

if [[ -f "$THEME_CTL" ]]; then
    if [[ "$TARGET" == "cybrdots" ]]; then
        "$THEME_CTL" set "cyber" "neon" &>/dev/null || true
    else
        cur="black_solid"
        [[ -f "$CACHE_DIR/sidebar_theme" ]] && cur=$(cat "$CACHE_DIR/sidebar_theme")
        cat="${cur%%_*}"
        sub="${cur#*_}"
        if [[ -z "$cat" || -z "$sub" || "$cat" == "$sub" ]]; then
            cat="black"
            sub="solid"
        fi
        "$THEME_CTL" set "$cat" "$sub" &>/dev/null || true
    fi
fi

# 6. Перезагрузка Hyprland
if command -v hyprctl &>/dev/null && pgrep -x Hyprland &>/dev/null; then
    hyprctl reload &>/dev/null || true
fi

# 7. Обновление Kitty
pkill -SIGUSR1 -x kitty 2>/dev/null || true
pkill -SIGUSR1 -f kitty 2>/dev/null || true

# 8. Перезапуск Waybar
if pgrep -x waybar &>/dev/null; then
    killall -9 waybar 2>/dev/null || pkill -9 -x waybar 2>/dev/null || true
    sleep 0.3
    nohup waybar </dev/null &>/dev/null &
fi

# 9. Уведомление
if command -v notify-send &>/dev/null; then
    if [[ "$TARGET" == "cybrdots" ]]; then
        notify-send -a "Стиль оформления" -i preferences-desktop-theme "Киберпанк профиль активирован" "Неоновый Waybar, обои Samurai, Kitty cybrcore" -t 2500
    else
        notify-send -a "Стиль оформления" -i preferences-desktop-theme "Классический профиль активирован" "Стандартный профиль Hyprland" -t 2500
    fi
fi

echo "Успешно активирован профиль: $TARGET"
