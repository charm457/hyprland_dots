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
        "Super + E                    󰉋 Customized File Manager (Smart)"
        "Super + Shift + E            󰉋 Yazi (Fast Terminal Explorer)"
        "Super + Alt + E              󰉋 Dolphin / GUI Explorer"
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
        "Super + E                    󰉋 Кастомный менеджер файлов (Умный)"
        "Super + Shift + E            󰉋 Yazi (быстрый проводник в терминале)"
        "Super + Alt + E              󰉋 Dolphin / графический проводник"
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

PROFILE_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/active_profile"
ACTIVE_PROFILE="main"
[[ -f "$PROFILE_CACHE" ]] && ACTIVE_PROFILE=$(cat "$PROFILE_CACHE")

ROFI_RADIUS="12px"
if [[ "$ACTIVE_PROFILE" == "cybrdots" ]]; then
    ROFI_RADIUS="0px"
elif [[ "$ACTIVE_PROFILE" == "macos" ]]; then
    ROFI_RADIUS="16px"
fi

printf "%s\n" "${BINDS[@]}" | rofi -dmenu -i -p "$PROMPT" \
    -theme-str "window {width: 680px; border-radius: ${ROFI_RADIUS};} inputbar {children: [ \"prompt\", \"entry\" ];} prompt {enabled: true; padding: 8px; text-color: inherit;} listview {columns: 1; lines: 16;}"
