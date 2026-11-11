#!/usr/bin/env bash
# ==============================================================================
# init_desktop.sh — Безопасный автозапуск компонентов рабочего стола
# Работает как на чистой установке, так и на готовой системе
# ==============================================================================

HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
WALLPAPERS_DIR="$HOME/wallpapers"
mkdir -p "$CACHE_DIR"

# 1. Запуск Polkit агента аутентификации (проверяем популярные пути)
start_polkit() {
    local agents=(
        "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
        "/usr/libexec/polkit-gnome-authentication-agent-1"
        "/usr/lib/hyprpolkitagent/hyprpolkitagent"
        "/usr/lib/polkit-kde-authentication-agent-1"
        "/usr/lib/mate-polkit/polkit-mate-authentication-agent-1"
        "/usr/bin/lxpolkit"
    )

    for agent in "${agents[@]}"; do
        if [[ -x "$agent" ]]; then
            pkill -f "$(basename "$agent")" 2>/dev/null || true
            "$agent" &
            return 0
        fi
    done
}

# 2. Инициализация обоев с защитой от сбоев
start_wallpaper() {
    pkill swaybg 2>/dev/null || true
    sleep 0.2

    local wp=""

    # Проверяем кэш
    if [[ -f "$CACHE_DIR/current_wallpaper" ]]; then
        local cached
        cached=$(cat "$CACHE_DIR/current_wallpaper")
        if [[ -f "$cached" ]]; then
            wp="$cached"
        fi
    fi

    # Проверяем папку ~/wallpapers/
    if [[ -z "$wp" && -d "$WALLPAPERS_DIR" ]]; then
        wp=$(find "$WALLPAPERS_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | head -n 1)
    fi

    if [[ -n "$wp" && -f "$wp" ]]; then
        echo "$wp" > "$CACHE_DIR/current_wallpaper"
        swaybg -i "$wp" -m stretch &
    else
        # Безопасный фоллбэк: стильный черный сплошной фон
        swaybg -c "#0a0a0a" &
    fi
}

# 3. Инициализация активной темы
init_theme() {
    local cur="black_solid"
    if [[ -f "$CACHE_DIR/sidebar_theme" ]]; then
        cur=$(cat "$CACHE_DIR/sidebar_theme")
    fi

    local cat="${cur%%_*}"
    local sub="${cur#*_}"
    if [[ -z "$cat" || -z "$sub" || "$cat" == "$sub" ]]; then
        cat="black"
        sub="solid"
    fi

    "$HYPR_DIR/scripts/theme_ctl.sh" set "$cat" "$sub" &>/dev/null || true
}

# Запуск служб
start_polkit &
start_wallpaper &
init_theme
"$HYPR_DIR/scripts/window_mode.sh" init &>/dev/null || true

# Сетевой апплет
if command -v nm-applet &>/dev/null; then
    pkill nm-applet 2>/dev/null || true
    nm-applet --indicator &
fi

# Уведомления (Dunst / Mako)
if command -v dunst &>/dev/null; then
    pkill dunst 2>/dev/null || true
    dunst &
elif command -v mako &>/dev/null; then
    pkill mako 2>/dev/null || true
    mako &
fi

# Панель Waybar (строго один экземпляр)
killall -9 waybar 2>/dev/null || pkill -9 -x waybar 2>/dev/null || true
sleep 0.3
waybar &

# Боковая панель Sidebar (фоновый демон)
if [[ -f "$HYPR_DIR/sidebar/sidebar.py" ]]; then
    pkill -f "sidebar.py" 2>/dev/null || true
    sleep 1.2
    python3 "$HYPR_DIR/sidebar/sidebar.py" &>> /tmp/sidebar.log &
fi
