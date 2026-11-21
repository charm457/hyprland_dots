#!/usr/bin/env bash
# ==============================================================================
# switch.sh — ТОТАЛЬНОЕ переключение между профилями конфигов (main / cybrdots / macos)
# Полностью заменяет hyprland.conf, waybar/config, waybar/style.css, kitty/theme.conf,
# обои и анимации под выбранный стиль.
# ==============================================================================

set -u

export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-main}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$CACHE_DIR"

if [[ "$TARGET" != "main" && "$TARGET" != "cybrdots" && "$TARGET" != "macos" ]]; then
    echo "Использование: $0 [main | cybrdots | macos]"
    exit 1
fi

# Находим корневую директорию репозитория / dotfiles
REPO_DIR="$DIR"
if [[ ! -d "$REPO_DIR/hypr/profiles" ]]; then
    if [[ -d "$HOME/hyprland_dots/hypr/profiles" ]]; then
        REPO_DIR="$HOME/hyprland_dots"
    elif [[ -d "$HOME/hyprland_configs/hypr/profiles" ]]; then
        REPO_DIR="$HOME/hyprland_configs"
    elif [[ -d "$CONFIG_DIR/hypr/profiles" ]]; then
        REPO_DIR="$CONFIG_DIR"
    elif [[ -d "$HOME/dotfiles/hypr/profiles" ]]; then
        REPO_DIR="$HOME/dotfiles"
    fi
fi

# Определяем путь к каталогу профиля
PROF_DIR=""
if [[ -d "$REPO_DIR/hypr/profiles/$TARGET" ]]; then
    PROF_DIR="$REPO_DIR/hypr/profiles/$TARGET"
elif [[ -d "$CONFIG_DIR/hypr/profiles/$TARGET" ]]; then
    PROF_DIR="$CONFIG_DIR/hypr/profiles/$TARGET"
fi

if [[ -z "$PROF_DIR" || ! -d "$PROF_DIR" ]]; then
    echo "Ошибка: Каталог профиля '$TARGET' не найден!"
    exit 1
fi

echo "Применение ТОТАЛЬНОЙ трансформации профиля: $TARGET..."

# 1. Запоминаем текущий профиль в кэше
echo "$TARGET" > "$CACHE_DIR/active_profile"

# 2. Обновляем общие скрипты, менеджер файлов и сайдбар (если доступны из REPO_DIR)
mkdir -p "$CONFIG_DIR/hypr" "$CONFIG_DIR/waybar" "$CONFIG_DIR/kitty" "$CONFIG_DIR/yazi" "$HOME/wallpapers"
if [[ -d "$REPO_DIR/hypr" && "$(realpath -q "$REPO_DIR/hypr" 2>/dev/null)" != "$(realpath -q "$CONFIG_DIR/hypr" 2>/dev/null)" ]]; then
    cp -rf "$REPO_DIR/hypr/scripts" "$CONFIG_DIR/hypr/" 2>/dev/null || true
    cp -rf "$REPO_DIR/hypr/sidebar" "$CONFIG_DIR/hypr/" 2>/dev/null || true
    cp -rf "$REPO_DIR/hypr/profiles" "$CONFIG_DIR/hypr/" 2>/dev/null || true
    cp -rf "$REPO_DIR/hypr/themes" "$CONFIG_DIR/hypr/" 2>/dev/null || true
    [[ -d "$REPO_DIR/kitty/themes" ]] && cp -rf "$REPO_DIR/kitty/themes" "$CONFIG_DIR/kitty/" 2>/dev/null || true
    [[ -d "$REPO_DIR/waybar/themes" ]] && cp -rf "$REPO_DIR/waybar/themes" "$CONFIG_DIR/waybar/" 2>/dev/null || true
    [[ -d "$REPO_DIR/yazi" ]] && cp -rf "$REPO_DIR/yazi/"* "$CONFIG_DIR/yazi/" 2>/dev/null || true
    cp -f "$REPO_DIR/switch.sh" "$CONFIG_DIR/hypr/switch.sh" 2>/dev/null || true
    chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh "$CONFIG_DIR/hypr/sidebar/"*.sh "$CONFIG_DIR/hypr/sidebar/sidebar.py" "$CONFIG_DIR/hypr/switch.sh" 2>/dev/null || true
fi

# 3. ТОТАЛЬНАЯ замена конфигов из hypr/profiles/<target>
# 3.1 Hyprland config (.conf и .lua для Hyprland 0.57+)
if [[ -f "$PROF_DIR/hyprland.conf" ]]; then
    cp -f "$PROF_DIR/hyprland.conf" "$CONFIG_DIR/hypr/hyprland.conf"
    echo " -> Hyprland config заменен на $TARGET"
fi
if [[ -f "$PROF_DIR/hyprland.lua" ]]; then
    cp -f "$PROF_DIR/hyprland.lua" "$CONFIG_DIR/hypr/hyprland.lua"
    echo " -> Hyprland Lua config заменен на $TARGET"
fi

# 3.2 Waybar config
if [[ -f "$PROF_DIR/waybar/config" ]]; then
    cp -f "$PROF_DIR/waybar/config" "$CONFIG_DIR/waybar/config"
    echo " -> Waybar config заменен на $TARGET"
fi

# 3.3 Waybar style.css
if [[ -f "$PROF_DIR/waybar/style.css" ]]; then
    cp -f "$PROF_DIR/waybar/style.css" "$CONFIG_DIR/waybar/style.css"
    echo " -> Waybar style.css заменен на $TARGET"
fi

# 3.4 Kitty theme
if [[ -f "$PROF_DIR/kitty/theme.conf" ]]; then
    cp -f "$PROF_DIR/kitty/theme.conf" "$CONFIG_DIR/kitty/theme.conf"
    echo " -> Kitty theme заменен на $TARGET"
fi

# 4. Установка обоев и специфичных настроек под каждый профиль
WP=""
if [[ "$TARGET" == "macos" ]]; then
    echo "macos_glass" > "$CACHE_DIR/sidebar_theme"
    echo "top" > "$CACHE_DIR/waybar_position"
    [[ -f "$REPO_DIR/hypr/themes/macos/glass.conf" ]] && cp -f "$REPO_DIR/hypr/themes/macos/glass.conf" "$CONFIG_DIR/hypr/current_theme.conf" 2>/dev/null || true
    [[ -f "$REPO_DIR/hypr/themes/macos/glass.lua" ]] && cp -f "$REPO_DIR/hypr/themes/macos/glass.lua" "$CONFIG_DIR/hypr/current_theme.lua" 2>/dev/null || true

    # Для macOS сохраняем текущие обои пользователя (не навязываем sonoma)
    if [[ -f "$CACHE_DIR/current_wallpaper" && -f "$(cat "$CACHE_DIR/current_wallpaper")" ]]; then
        WP=$(cat "$CACHE_DIR/current_wallpaper")
    elif [[ -d "$HOME/wallpapers" ]]; then
        WP=$(find "$HOME/wallpapers" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) 2>/dev/null | head -n 1)
    fi

    NOTIFY_TITLE="macOS Profile"
    NOTIFY_BODY=" Apple Menu Bar сверху, аутентичные анимации и стекло"

elif [[ "$TARGET" == "cybrdots" ]]; then
    echo "cyber_neon" > "$CACHE_DIR/sidebar_theme"
    echo "top" > "$CACHE_DIR/waybar_position"
    [[ -f "$REPO_DIR/hypr/themes/cyber/neon.conf" ]] && cp -f "$REPO_DIR/hypr/themes/cyber/neon.conf" "$CONFIG_DIR/hypr/current_theme.conf" 2>/dev/null || true
    [[ -f "$REPO_DIR/hypr/themes/cyber/neon.lua" ]] && cp -f "$REPO_DIR/hypr/themes/cyber/neon.lua" "$CONFIG_DIR/hypr/current_theme.lua" 2>/dev/null || true

    # Обои Cyberpunk / Samurai
    if [[ -f "$CACHE_DIR/cybrdots_wallpaper" && -f "$(cat "$CACHE_DIR/cybrdots_wallpaper")" ]]; then
        WP=$(cat "$CACHE_DIR/cybrdots_wallpaper")
    elif [[ -f "$HOME/wallpapers/samurai-2560x1440.png" ]]; then
        WP="$HOME/wallpapers/samurai-2560x1440.png"
    elif [[ -d "$HOME/wallpapers" ]]; then
        WP=$(find "$HOME/wallpapers" -type f \( -name "*samurai*" -o -name "*cyber*" -o -name "*.png" -o -name "*.jpg" -o -name "*.webp" \) 2>/dev/null | head -n 1)
    fi

    NOTIFY_TITLE="Cyberpunk Profile"
    NOTIFY_BODY="Неоновый Waybar (Hunty edition), неон #ff007f/#00f0ff, Kitty Cyber Neon"

else
    echo "black_solid" > "$CACHE_DIR/sidebar_theme"
    echo "top" > "$CACHE_DIR/waybar_position"
    [[ -f "$REPO_DIR/hypr/themes/black/solid.conf" ]] && cp -f "$REPO_DIR/hypr/themes/black/solid.conf" "$CONFIG_DIR/hypr/current_theme.conf" 2>/dev/null || true
    [[ -f "$REPO_DIR/hypr/themes/black/solid.lua" ]] && cp -f "$REPO_DIR/hypr/themes/black/solid.lua" "$CONFIG_DIR/hypr/current_theme.lua" 2>/dev/null || true

    # Обои Main
    if [[ -f "$CACHE_DIR/main_wallpaper" && -f "$(cat "$CACHE_DIR/main_wallpaper")" ]]; then
        WP=$(cat "$CACHE_DIR/main_wallpaper")
    elif [[ -f "$HOME/wallpapers/ikebukuro-2560x1440.png" ]]; then
        WP="$HOME/wallpapers/ikebukuro-2560x1440.png"
    elif [[ -d "$HOME/wallpapers" ]]; then
        WP=$(find "$HOME/wallpapers" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.webp" \) 2>/dev/null | head -n 1)
    fi

    NOTIFY_TITLE="Main Monochrome Profile"
    NOTIFY_BODY="Классический чистый сетап Hyprland, строгий монохром и лаконичный Waybar"
fi

# Применение обоев через swaybg
if [[ -n "$WP" && -f "$WP" ]]; then
    echo "$WP" > "$CACHE_DIR/current_wallpaper"
    pkill swaybg 2>/dev/null || true
    sleep 0.1
    nohup swaybg -i "$WP" -m stretch </dev/null &>/dev/null &
    disown || true
fi

# 5. Перезагрузка Hyprland
if command -v hyprctl &>/dev/null && pgrep -x Hyprland &>/dev/null; then
    hyprctl reload &>/dev/null || true
fi

# 6. Обновление цветов Kitty на лету
if command -v kitty &>/dev/null; then
    kitty @ set-colors --all "$CONFIG_DIR/kitty/theme.conf" &>/dev/null || true
    pkill -SIGUSR1 -x kitty 2>/dev/null || true
    pkill -SIGUSR1 -f kitty 2>/dev/null || true
fi

# 7. Полный перезапуск Waybar под новый профиль
killall -9 waybar 2>/dev/null || pkill -9 -x waybar 2>/dev/null || true
sleep 0.3
nohup waybar </dev/null &>/dev/null &
disown || true

# 8. Перезапуск Sidebar для применения темы и геометрии
pkill -9 -f "sidebar.py" 2>/dev/null || true
rm -f "$CACHE_DIR/sidebar.pid" 2>/dev/null || true
sleep 0.2
if [[ -f "$CONFIG_DIR/hypr/sidebar/sidebar.py" ]]; then
    nohup python3 "$CONFIG_DIR/hypr/sidebar/sidebar.py" </dev/null &>> /tmp/sidebar.log &
    disown || true
fi

# 9. Уведомление
if command -v notify-send &>/dev/null; then
    notify-send -a "Профиль оформления" -i preferences-desktop-theme "$NOTIFY_TITLE" "$NOTIFY_BODY" -t 3000
fi

echo "Профиль '$TARGET' успешно активирован на 100%!"
