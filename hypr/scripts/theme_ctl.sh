#!/usr/bin/env bash
# ==============================================================================
# theme_ctl.sh — Контроллер стилей и тем оформления
# ==============================================================================

HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
WAYBAR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
KITTY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
THEME_CACHE="$CACHE_DIR/sidebar_theme"
WALLPAPER_CACHE="$CACHE_DIR/current_wallpaper"

mkdir -p "$CACHE_DIR"

get_current_theme() {
    if [[ -f "$THEME_CACHE" ]]; then
        cat "$THEME_CACHE"
    else
        echo "black_solid"
    fi
}

menu_icon() {
    local cur
    cur=$(get_current_theme)
    if [[ "$cur" == macos* ]]; then
        echo ""
    elif [[ "$cur" == cyber* ]]; then
        echo "󰊠"
    elif [[ "$cur" == white* ]]; then
        echo "󰄛"
    else
        echo "󰣇"
    fi
}

apply_theme() {
    local category="$1"
    local substyle="$2"
    local theme_key="${category}_${substyle}"

    local hypr_theme="$HYPR_DIR/themes/$category/$substyle.conf"
    local waybar_theme="$WAYBAR_DIR/themes/${theme_key}.css"
    local kitty_theme="$KITTY_DIR/themes/${theme_key}.conf"

    if [[ ! -f "$hypr_theme" ]]; then
        echo "Ошибка: конфиг Hyprland не найден: $hypr_theme"
        return 1
    fi

    # 1. Hyprland конфиг темы
    cp "$hypr_theme" "$HYPR_DIR/current_theme.conf"
    if command -v hyprctl &>/dev/null; then
        hyprctl reload &>/dev/null
    fi

    # 2. Waybar CSS (копируем файл целиком, чтобы GTK не кэшировал импорты)
    if [[ -f "$waybar_theme" ]]; then
        cp -f "$waybar_theme" "$WAYBAR_DIR/style.css"
        # Перезагружаем Waybar для 100% применения новых цветов и скруглений
        pkill -USR2 waybar 2>/dev/null || true
        ( pkill -x waybar 2>/dev/null; sleep 0.15; waybar &>/dev/null & ) &
    fi

    # 3. Kitty конфиг темы (копируем файл напрямую, исключая сбои относительных путей)
    if [[ -f "$kitty_theme" ]]; then
        cp -f "$kitty_theme" "$KITTY_DIR/theme.conf"
        # 1. Мгновенное обновление через remote-control
        kitty @ set-colors --all "$KITTY_DIR/theme.conf" 2>/dev/null || true
        # 2. Сигнал SIGUSR1 всем запущенным процессам Kitty
        pkill -SIGUSR1 -x kitty 2>/dev/null || true
        pkill -SIGUSR1 -f kitty 2>/dev/null || true
    fi

    # 4. Сохраняем активную тему
    echo "$theme_key" > "$THEME_CACHE"

    # 5. Уведомление
    local lang_cache="$CACHE_DIR/dots_lang"
    local app_lang="ru"
    [[ -f "$lang_cache" ]] && app_lang=$(cat "$lang_cache")

    if command -v notify-send &>/dev/null; then
        if [[ "$app_lang" == "en" ]]; then
            notify-send -a "Theme Controller" -i preferences-desktop-theme "Theme Applied: ${category^}" "Style: ${substyle^}" -t 2000
        else
            notify-send -a "Стиль оформления" -i preferences-desktop-theme "Стиль: ${category^}" "Подстиль: ${substyle^}" -t 2000
        fi
    fi

    echo "Theme applied: $theme_key"
}

case "${1:-get}" in
    set)
        apply_theme "$2" "$3" "$4"
        ;;
    get)
        get_current_theme
        ;;
    menu_icon)
        menu_icon
        ;;
    list)
        echo "Доступные стили:"
        echo "  black  -> solid, stealth, glass"
        echo "  white  -> clean, glass, latte"
        echo "  macos  -> glass, dark, light"
        echo "  cyber  -> neon, nord"
        ;;
    *)
        echo "Использование: $0 [set <категория> <подстиль> [--with-wallpaper] | get | menu_icon | list]"
        exit 1
        ;;
esac
