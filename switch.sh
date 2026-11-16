#!/usr/bin/env bash
# ==============================================================================
# switch.sh — переключение между профилями конфигов (main / cybrdots / macos)
# ==============================================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-main}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$CACHE_DIR"

if [[ "$TARGET" != "main" && "$TARGET" != "cybrdots" && "$TARGET" != "macos" ]]; then
    echo "Использование: $0 [main | cybrdots | macos]"
    exit 1
fi

# Находим корневую директорию репозитория
REPO_DIR="$DIR"
if [[ ! -d "$REPO_DIR/hypr" ]]; then
    if [[ -d "$HOME/hyprland_dots/hypr" ]]; then
        REPO_DIR="$HOME/hyprland_dots"
    elif [[ -d "$HOME/hyprland_configs/hypr" ]]; then
        REPO_DIR="$HOME/hyprland_configs"
    elif [[ -d "$HOME/dotfiles/hypr" ]]; then
        REPO_DIR="$HOME/dotfiles"
    fi
fi

echo "Переключаем профиль на: $TARGET..."

# 1. Запоминаем текущий профиль в кэше
echo "$TARGET" > "$CACHE_DIR/active_profile"

# 2. Синхронизируем базовые конфиги в ~/.config
mkdir -p "$CONFIG_DIR/hypr" "$CONFIG_DIR/waybar" "$CONFIG_DIR/kitty" "$CONFIG_DIR/yazi" "$HOME/wallpapers"
if [[ -d "$REPO_DIR/hypr" ]]; then
    cp -rf "$REPO_DIR/hypr/"* "$CONFIG_DIR/hypr/" 2>/dev/null || true
    cp -rf "$REPO_DIR/waybar/"* "$CONFIG_DIR/waybar/" 2>/dev/null || true
    cp -rf "$REPO_DIR/kitty/"* "$CONFIG_DIR/kitty/" 2>/dev/null || true
    [[ -d "$REPO_DIR/yazi" ]] && cp -rf "$REPO_DIR/yazi/"* "$CONFIG_DIR/yazi/" 2>/dev/null || true
    chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh "$CONFIG_DIR/hypr/sidebar/"*.sh "$CONFIG_DIR/hypr/sidebar/sidebar.py" 2>/dev/null || true
fi

# 3. Применение целевого профиля
if [[ "$TARGET" == "cybrdots" ]]; then
    # ==========================================
    # ПРОФИЛЬ: КИБЕРПАНК (CYBERPUNK NEON)
    # ==========================================
    echo "cyber_neon" > "$CACHE_DIR/sidebar_theme"
    echo "bottom" > "$CACHE_DIR/waybar_position"

    # Hyprland темы (Неоновые рамки, градиент, свечение)
    [[ -f "$REPO_DIR/hypr/themes/cyber/neon.conf" ]] && cp -f "$REPO_DIR/hypr/themes/cyber/neon.conf" "$CONFIG_DIR/hypr/current_theme.conf"
    [[ -f "$REPO_DIR/hypr/themes/cyber/neon.lua" ]]  && cp -f "$REPO_DIR/hypr/themes/cyber/neon.lua"  "$CONFIG_DIR/hypr/current_theme.lua"

    # Waybar Layout (Конфиг панели снизу)
    if [[ -f "$REPO_DIR/waybar/config.cyber" ]]; then
        cp -f "$REPO_DIR/waybar/config.cyber" "$CONFIG_DIR/waybar/config"
    fi

    # Waybar CSS (Неоновые светящиеся стили)
    [[ -f "$REPO_DIR/waybar/themes/cyber_neon.css" ]] && cp -f "$REPO_DIR/waybar/themes/cyber_neon.css" "$CONFIG_DIR/waybar/style.css"

    # Kitty conf (Киберпанк неоновый терминал)
    [[ -f "$REPO_DIR/kitty/themes/cyber_neon.conf" ]] && cp -f "$REPO_DIR/kitty/themes/cyber_neon.conf" "$CONFIG_DIR/kitty/theme.conf"

    # Обои (Samurai / Cyber)
    WP=""
    if [[ -f "$CACHE_DIR/cybrdots_wallpaper" && -f "$(cat "$CACHE_DIR/cybrdots_wallpaper")" ]]; then
        WP=$(cat "$CACHE_DIR/cybrdots_wallpaper")
    elif [[ -f "$HOME/wallpapers/samurai-2560x1440.png" ]]; then
        WP="$HOME/wallpapers/samurai-2560x1440.png"
    elif [[ -d "$HOME/wallpapers" ]]; then
        WP=$(find "$HOME/wallpapers" -type f \( -name "*samurai*" -o -name "*cyber*" -o -name "*.png" -o -name "*.jpg" -o -name "*.webp" \) 2>/dev/null | head -n 1)
    fi

    if [[ -n "$WP" && -f "$WP" ]]; then
        echo "$WP" > "$CACHE_DIR/current_wallpaper"
        pkill swaybg 2>/dev/null || true
        sleep 0.1
        nohup swaybg -i "$WP" -m stretch </dev/null &>/dev/null &
    fi

    # Уведомление
    if command -v notify-send &>/dev/null; then
        notify-send -a "Стиль оформления" -i preferences-desktop-theme "Киберпанк профиль активирован" "Неоновый Waybar внизу, обои Samurai, Kitty Cyber Neon" -t 2500
    fi
elif [[ "$TARGET" == "macos" ]]; then
    # ==========================================
    # ПРОФИЛЬ: MACOS LIQUID GLASS (CUPERTINO)
    # ==========================================
    echo "macos_glass" > "$CACHE_DIR/sidebar_theme"
    echo "top" > "$CACHE_DIR/waybar_position"

    # Hyprland темы (Cupertino скругление 16px, стекло, плавные macOS анимации)
    [[ -f "$REPO_DIR/hypr/themes/macos/glass.conf" ]] && cp -f "$REPO_DIR/hypr/themes/macos/glass.conf" "$CONFIG_DIR/hypr/current_theme.conf"
    [[ -f "$REPO_DIR/hypr/themes/macos/glass.lua" ]]  && cp -f "$REPO_DIR/hypr/themes/macos/glass.lua"  "$CONFIG_DIR/hypr/current_theme.lua"

    # Waybar Layout (Конфиг панели сверху с меню )
    if [[ -f "$REPO_DIR/waybar/config.macos" ]]; then
        cp -f "$REPO_DIR/waybar/config.macos" "$CONFIG_DIR/waybar/config"
    fi

    # Waybar CSS (Dynamic Island стекло)
    [[ -f "$REPO_DIR/waybar/themes/macos_glass.css" ]] && cp -f "$REPO_DIR/waybar/themes/macos_glass.css" "$CONFIG_DIR/waybar/style.css"

    # Kitty conf (macOS Glass / Dark)
    [[ -f "$REPO_DIR/kitty/themes/macos_glass.conf" ]] && cp -f "$REPO_DIR/kitty/themes/macos_glass.conf" "$CONFIG_DIR/kitty/theme.conf"

    # Обои (macOS Ventura / Sonoma / Monterey)
    WP=""
    if [[ -f "$CACHE_DIR/macos_wallpaper" && -f "$(cat "$CACHE_DIR/macos_wallpaper")" ]]; then
        WP=$(cat "$CACHE_DIR/macos_wallpaper")
    elif [[ -d "$HOME/wallpapers" ]]; then
        WP=$(find "$HOME/wallpapers" -type f \( -name "*macos*" -o -name "*sonoma*" -o -name "*ventura*" -o -name "*monterey*" -o -name "*apple*" -o -name "*bigsur*" -o -name "*.png" -o -name "*.jpg" -o -name "*.webp" \) 2>/dev/null | head -n 1)
    fi

    if [[ -n "$WP" && -f "$WP" ]]; then
        echo "$WP" > "$CACHE_DIR/current_wallpaper"
        pkill swaybg 2>/dev/null || true
        sleep 0.1
        nohup swaybg -i "$WP" -m stretch </dev/null &>/dev/null &
    fi

    # Уведомление
    if command -v notify-send &>/dev/null; then
        notify-send -a "Стиль оформления" -i preferences-desktop-theme "Профиль macOS активирован" "Верхняя панель с меню , горизонтальные Spaces, плавные анимации и стекло" -t 2500
    fi
else
    # ==========================================
    # ПРОФИЛЬ: КЛАССИЧЕСКИЙ (MAIN MONOCHROME)
    # ==========================================
    echo "top" > "$CACHE_DIR/waybar_position"
    cur="black_solid"
    [[ -f "$CACHE_DIR/main_theme" ]] && cur=$(cat "$CACHE_DIR/main_theme")
    cat="${cur%%_*}"
    sub="${cur#*_}"
    if [[ -z "$cat" || -z "$sub" || "$cat" == "$sub" ]]; then
        cat="black"
        sub="solid"
    fi
    echo "${cat}_${sub}" > "$CACHE_DIR/sidebar_theme"

    # Hyprland темы
    [[ -f "$REPO_DIR/hypr/themes/$cat/$sub.conf" ]] && cp -f "$REPO_DIR/hypr/themes/$cat/$sub.conf" "$CONFIG_DIR/hypr/current_theme.conf"
    [[ -f "$REPO_DIR/hypr/themes/$cat/$sub.lua" ]]  && cp -f "$REPO_DIR/hypr/themes/$cat/$sub.lua"  "$CONFIG_DIR/hypr/current_theme.lua"

    # Waybar Layout (Конфиг панели сверху)
    if [[ -f "$REPO_DIR/waybar/config.main" ]]; then
        cp -f "$REPO_DIR/waybar/config.main" "$CONFIG_DIR/waybar/config"
    fi

    # Waybar CSS
    [[ -f "$REPO_DIR/waybar/themes/${cat}_${sub}.css" ]] && cp -f "$REPO_DIR/waybar/themes/${cat}_${sub}.css" "$CONFIG_DIR/waybar/style.css"

    # Kitty conf
    [[ -f "$REPO_DIR/kitty/themes/${cat}_${sub}.conf" ]] && cp -f "$REPO_DIR/kitty/themes/${cat}_${sub}.conf" "$CONFIG_DIR/kitty/theme.conf"

    # Обои
    WP=""
    if [[ -f "$CACHE_DIR/main_wallpaper" && -f "$(cat "$CACHE_DIR/main_wallpaper")" ]]; then
        WP=$(cat "$CACHE_DIR/main_wallpaper")
    elif [[ -f "$HOME/wallpapers/ikebukuro-2560x1440.png" ]]; then
        WP="$HOME/wallpapers/ikebukuro-2560x1440.png"
    elif [[ -d "$HOME/wallpapers" ]]; then
        WP=$(find "$HOME/wallpapers" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.webp" \) 2>/dev/null | head -n 1)
    fi

    if [[ -n "$WP" && -f "$WP" ]]; then
        echo "$WP" > "$CACHE_DIR/current_wallpaper"
        pkill swaybg 2>/dev/null || true
        sleep 0.1
        nohup swaybg -i "$WP" -m stretch </dev/null &>/dev/null &
    fi

    # Уведомление
    if command -v notify-send &>/dev/null; then
        notify-send -a "Стиль оформления" -i preferences-desktop-theme "Классический профиль активирован" "Стандартный профиль Hyprland (Waybar вверху)" -t 2500
    fi
fi

# 4. Перезагрузка Hyprland
if command -v hyprctl &>/dev/null && pgrep -x Hyprland &>/dev/null; then
    hyprctl reload &>/dev/null || true
fi

# 5. Обновление Kitty
if command -v kitty &>/dev/null; then
    kitty @ set-colors --all "$CONFIG_DIR/kitty/theme.conf" &>/dev/null || true
    pkill -SIGUSR1 -x kitty 2>/dev/null || true
    pkill -SIGUSR1 -f kitty 2>/dev/null || true
fi

# 6. Перезапуск Waybar
killall -9 waybar 2>/dev/null || pkill -9 -x waybar 2>/dev/null || true
sleep 0.3
nohup waybar </dev/null &>/dev/null &

# 7. Перезапуск Sidebar для обновления стилей и отступов
pkill -9 -f "sidebar.py" 2>/dev/null || true
rm -f "$CACHE_DIR/sidebar.pid" 2>/dev/null || true
sleep 0.2
if [[ -f "$CONFIG_DIR/hypr/sidebar/sidebar.py" ]]; then
    python3 "$CONFIG_DIR/hypr/sidebar/sidebar.py" &>> /tmp/sidebar.log &
fi

echo "Успешно активирован профиль: $TARGET"
