#!/usr/bin/env bash
# ==============================================================================
# keybinds_help.sh — Всплывающее окно со всеми комбинациями клавиш
# Вызов: Super + /  или  Super + F1
# ==============================================================================

LANG_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/dots_lang"
APP_LANG="ru"
[[ -f "$LANG_CACHE" ]] && APP_LANG=$(cat "$LANG_CACHE")

if [[ "$APP_LANG" == "en" ]]; then
    PROMPT="⌨ Keybindings Cheatsheet"
    BINDS=(
        "Super + Return               󰞷 Launch Kitty Terminal"
        "Super + Space / D            󰀻 Application Launcher (Rofi)"
        "Super + P                    󰒓 Toggle Control Sidebar (Settings)"
        "Super + /  or  Super + F1    󰋖 Show this Keybindings Cheatsheet"
        "Super + Q                    󰅙 Close active window"
        "Super + Shift + M            󰐥 Exit Hyprland"
        "─────────────────────────────────────────────────────────────"
        "Super + W                    󰕰 Cycle Window Mode [Default ↔ Free]"
        "Super + Shift + T            ▦ Default Mode (Strict Tiling)"
        "Super + Shift + W            🪟 Free Mode (Floating Windows)"
        "Super + V                    󰉈 Toggle Active Window (Float / Tile)"
        "Super + F                    󰊓 Fullscreen Mode"
        "Super + LMB (drag)           󰆾 Drag Floating Window with Mouse"
        "Super + RMB (drag)           󰩨 Resize Floating Window with Mouse"
        "─────────────────────────────────────────────────────────────"
        "Super + Shift + S            󰹑 Screenshot Area (Save to ~/Screenshots)"
        "Print                        󰹑 Screenshot Full Screen"
        "Super + Print                󰹑 Screenshot Active Window"
        "Super + Alt + S              󰹑 Screenshot Interactive Menu"
        "─────────────────────────────────────────────────────────────"
        "Super + Alt + P              󰍹 Waybar Position: Top ↔ Bottom ↔ Hide"
        "Super + ]  /  [              󰸉 Next / Previous Wallpaper"
        "Super + 1..0                 󱂬 Switch Workspace 1..10"
        "Super + Shift + 1..0         󱂬 Move Window to Workspace 1..10"
    )
else
    PROMPT="⌨ Горячие клавиши (Шпаргалка)"
    BINDS=(
        "Super + Return               󰞷 Запуск терминала Kitty"
        "Super + Space / D            󰀻 Меню приложений (Rofi)"
        "Super + P                    󰒓 Боковая панель настроек (Сайдбар)"
        "Super + /  или  Super + F1   󰋖 Это окно горячих клавиш"
        "Super + Q                    󰅙 Закрыть активное окно"
        "Super + Shift + M            󰐥 Выход из Hyprland"
        "─────────────────────────────────────────────────────────────"
        "Super + W                    󰕰 Смена режима [Обычный ↔ Свободный]"
        "Super + Shift + T            ▦ Обычный режим (тайлинг, авто-разделение)"
        "Super + Shift + W            🪟 Свободный режим (плавающие окна)"
        "Super + V                    󰉈 Переключить окно (плавающее / плитка)"
        "Super + F                    󰊓 Полный экран"
        "Super + ЛКМ (тянуть)         󰆾 Перемещать окно мышью"
        "Super + ПКМ (тянуть)         󰩨 Менять размер окна мышью"
        "─────────────────────────────────────────────────────────────"
        "Super + Shift + S            󰹑 Скриншот области (в ~/Screenshots)"
        "Print                        󰹑 Скриншот всего экрана"
        "Super + Print                󰹑 Скриншот активного окна"
        "Super + Alt + S              󰹑 Меню скриншотов"
        "─────────────────────────────────────────────────────────────"
        "Super + Alt + P              󰍹 Положение Waybar: Верх ↔ Низ ↔ Скрыть"
        "Super + ]  /  [              󰸉 Следующие / предыдущие обои"
        "Super + 1..0                 󱂬 Переключение рабочего стола 1..10"
        "Super + Shift + 1..0         󱂬 Перенести окно на стол 1..10"
    )
fi

printf "%s\n" "${BINDS[@]}" | rofi -dmenu -i -p "$PROMPT" \
    -theme-str 'window {width: 650px; border-radius: 16px;} listview {lines: 16;}'
