#!/usr/bin/env bash
# ==============================================================================
# file_manager.sh — Кастомизированный менеджер файлов
# Поддерживает Yazi (быстрый TUI-проводник с превью) и Dolphin/Thunar (GUI)
# ==============================================================================

MODE="${1:-smart}"
shift 2>/dev/null || true
TARGET_DIR="${1:-$HOME}"

launch_yazi() {
    if command -v yazi &>/dev/null; then
        kitty --class FileManager,yazi --title "󰉋 File Manager" -e yazi "$TARGET_DIR" &
        return 0
    elif command -v ranger &>/dev/null; then
        kitty --class FileManager,ranger --title "󰉋 File Manager" -e ranger "$TARGET_DIR" &
        return 0
    fi
    return 1
}

launch_gui() {
    if command -v dolphin &>/dev/null; then
        dolphin "$TARGET_DIR" &
        return 0
    elif command -v thunar &>/dev/null; then
        thunar "$TARGET_DIR" &
        return 0
    elif command -v nemo &>/dev/null; then
        nemo "$TARGET_DIR" &
        return 0
    elif command -v nautilus &>/dev/null; then
        nautilus "$TARGET_DIR" &
        return 0
    fi
    return 1
}

case "$MODE" in
    yazi)
        launch_yazi || launch_gui || kitty -e bash
        ;;
    gui)
        launch_gui || launch_yazi || kitty -e bash
        ;;
    smart|*)
        if command -v yazi &>/dev/null; then
            launch_yazi
        elif command -v dolphin &>/dev/null; then
            launch_gui
        elif command -v thunar &>/dev/null; then
            launch_gui
        else
            launch_yazi || kitty -e bash
        fi
        ;;
esac
