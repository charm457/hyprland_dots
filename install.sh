#!/usr/bin/env bash
# ==============================================================================
# INSTALL.SH — Hyprland Dotfiles Installer & Updater
# Supports clean install, seamless update with automatic backups, and EN/RU languages.
# ==============================================================================

set -e

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
HYPR_DST="$CONFIG_DIR/hypr"
WAYBAR_DST="$CONFIG_DIR/waybar"
KITTY_DST="$CONFIG_DIR/kitty"
WALLPAPER_DST="$HOME/wallpapers"
SCREENSHOTS_DST="$HOME/Screenshots"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$CONFIG_DIR/hypr_backup_$TIMESTAMP"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
LANG_FILE="$CACHE_DIR/dots_lang"

mkdir -p "$CACHE_DIR"
INSTALL_LANG="en"
[[ -f "$LANG_FILE" ]] && INSTALL_LANG=$(cat "$LANG_FILE")

log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_ok()   { echo -e "${GREEN}[OK]${RESET} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_err()  { echo -e "${RED}[ERROR]${RESET} $1"; }

print_banner() {
    clear 2>/dev/null || true
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
  _  _                  _                 _   ___        _       
 | || | _   _  _ __  _ __| | __ _  _ _   __| | |   \  ___ | |_  ___
 | __ || |_| || '_ \| '_/| |/ _` || ' \ / _` | | |) |/ _ \|  _|(_-<
 |_||_| \__, || .__/|_|  |_|\__,_||_||_|\__,_| |___/ \___/ \__|/__/
        |___/ |_|                                                  
EOF
    echo -e "${RESET}"
    if [[ "$INSTALL_LANG" == "ru" ]]; then
        echo -e "${BOLD}${MAGENTA}  Универсальный установщик и менеджер сборки Hyprland${RESET}"
        echo -e "${BLUE}  • Стили: Black, White, macOS Glass, Cyber (с подстилями)${RESET}"
        echo -e "${BLUE}  • Режимы окон: Плитка / Monocle с Waybar / Windows Mode${RESET}"
    else
        echo -e "${BOLD}${MAGENTA}  Universal Hyprland Dotfiles Installer & Manager${RESET}"
        echo -e "${BLUE}  • Styles: Black, White, macOS Glass, Cyber (with sub-themes)${RESET}"
        echo -e "${BLUE}  • Window Modes: Tiling / Fullscreen with Waybar / Windows Floating${RESET}"
    fi
    echo -e "${CYAN}------------------------------------------------------------${RESET}\n"
}

select_language() {
    if [[ -n "${FORCE_LANG:-}" ]]; then
        INSTALL_LANG="$FORCE_LANG"
        echo "$INSTALL_LANG" > "$LANG_FILE"
        return
    fi

    echo -e "${BOLD}Select Language / Выберите язык интерфейса:${RESET}"
    echo -e "  ${GREEN}1)${RESET} English (Default)"
    echo -e "  ${CYAN}2)${RESET} Русский"
    read -rp "Choice / Выбор [1/2, default 1]: " lchoice
    if [[ "$lchoice" == "2" ]]; then
        INSTALL_LANG="ru"
    else
        INSTALL_LANG="en"
    fi
    echo "$INSTALL_LANG" > "$LANG_FILE"
    print_banner
}

detect_pkg_manager() {
    if command -v pacman &>/dev/null; then echo "pacman"
    elif command -v dnf &>/dev/null; then echo "dnf"
    elif command -v apt-get &>/dev/null; then echo "apt"
    elif command -v zypper &>/dev/null; then echo "zypper"
    elif command -v xbps-install &>/dev/null; then echo "xbps"
    else echo "unknown"
    fi
}

check_and_install_deps() {
    local pm
    pm=$(detect_pkg_manager)
    if [[ "$INSTALL_LANG" == "ru" ]]; then
        log_info "Определен пакетный менеджер: ${BOLD}$pm${RESET}"
    else
        log_info "Detected package manager: ${BOLD}$pm${RESET}"
    fi

    local core_deps=("hyprland" "waybar" "kitty" "swaybg" "playerctl" "brightnessctl" "python3" "grimblast")
    local missing=()

    for dep in "${core_deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if ! python3 -c "import gi; gi.require_version('GtkLayerShell', '0.1'); from gi.repository import GtkLayerShell" 2>/dev/null; then
        missing+=("gtk-layer-shell" "python-gobject")
    fi

    if [[ ${#missing[@]} -eq 0 ]]; then
        if [[ "$INSTALL_LANG" == "ru" ]]; then
            log_ok "Все основные зависимости установлены!"
        else
            log_ok "All core dependencies are installed!"
        fi
        return 0
    fi

    if [[ "$INSTALL_LANG" == "ru" ]]; then
        log_warn "Отсутствуют пакеты: ${YELLOW}${missing[*]}${RESET}"
        read -rp "Установить недостающие зависимости? (y/N): " ans
    else
        log_warn "Missing packages: ${YELLOW}${missing[*]}${RESET}"
        read -rp "Install missing dependencies automatically? (y/N): " ans
    fi

    if [[ "$ans" =~ ^[YyДд]$ ]]; then
        case "$pm" in
            pacman)
                local arch_pkgs=(
                    "hyprland" "waybar" "kitty" "swaybg" "dunst" "rofi-wayland"
                    "playerctl" "brightnessctl" "grimblast-git" "libnotify"
                    "python" "python-gobject" "gtk3" "gtk-layer-shell" "jq"
                    "ttf-jetbrains-mono-nerd" "ttf-font-awesome" "polkit-gnome"
                )
                if command -v yay &>/dev/null; then
                    yay -S --needed "${arch_pkgs[@]}" || true
                elif command -v paru &>/dev/null; then
                    paru -S --needed "${arch_pkgs[@]}" || true
                else
                    sudo pacman -S --needed hyprland waybar kitty swaybg dunst playerctl brightnessctl python python-gobject gtk3 gtk-layer-shell jq polkit-gnome || true
                fi
                ;;
            dnf)
                sudo dnf install -y hyprland waybar kitty swaybg dunst rofi-wayland playerctl brightnessctl python3 python3-gobject gtk3 gtk-layer-shell jq || true
                ;;
            apt)
                sudo apt-get update
                sudo apt-get install -y waybar kitty playerctl brightnessctl python3 python3-gi gir1.2-gtk-3.0 jq || true
                ;;
            *)
                log_warn "Unsupported package manager for auto-install. Please install manually: ${missing[*]}"
                ;;
        esac
    fi
}

backup_existing_configs() {
    local has_backup=false

    for dir in "$HYPR_DST" "$WAYBAR_DST" "$KITTY_DST"; do
        if [[ -d "$dir" ]]; then
            has_backup=true
            break
        fi
    done

    if [[ "$has_backup" == true ]]; then
        if [[ "$INSTALL_LANG" == "ru" ]]; then
            log_info "Создание резервной копии старых конфигов в: ${BOLD}$BACKUP_DIR${RESET}"
        else
            log_info "Backing up existing configs to: ${BOLD}$BACKUP_DIR${RESET}"
        fi
        mkdir -p "$BACKUP_DIR"
        [[ -d "$HYPR_DST" ]]   && cp -r "$HYPR_DST"   "$BACKUP_DIR/hypr"
        [[ -d "$WAYBAR_DST" ]] && cp -r "$WAYBAR_DST" "$BACKUP_DIR/waybar"
        [[ -d "$KITTY_DST" ]]  && cp -r "$KITTY_DST"  "$BACKUP_DIR/kitty"
        if [[ "$INSTALL_LANG" == "ru" ]]; then
            log_ok "Резервная копия успешно сохранена!"
        else
            log_ok "Backup created successfully!"
        fi
    fi
}

deploy_configs() {
    if [[ "$INSTALL_LANG" == "ru" ]]; then
        log_info "Развертывание конфигураций..."
    else
        log_info "Deploying configurations..."
    fi

    mkdir -p "$CONFIG_DIR" "$WALLPAPER_DST" "$SCREENSHOTS_DST" "$CACHE_DIR/sidebar_thumbs"

    local clean_mode=true
    if [[ -t 0 && -d "$HYPR_DST" && "${NON_INTERACTIVE:-false}" != "true" ]]; then
        if [[ "$INSTALL_LANG" == "ru" ]]; then
            echo -e "\n${YELLOW}Обнаружены существующие конфиги Hyprland!${RESET}"
            echo -e "${BLUE}(Они сохранены в бэкап: $BACKUP_DIR)${RESET}"
            echo -e "Как применить новую сборку?"
            echo -e "  ${GREEN}1)${RESET} ${BOLD}Чистая замена (Рекомендуется)${RESET} — исключает конфликты со старой сборкой"
            echo -e "  ${CYAN}2)${RESET} ${BOLD}Перезапись поверх (Merge)${RESET} — обновить файлы, сохранив ваши сторонние скрипты"
            read -rp "Ваш выбор [1/2, по умолчанию 1]: " mode_choice
        else
            echo -e "\n${YELLOW}Existing Hyprland configuration detected!${RESET}"
            echo -e "${BLUE}(Backed up to: $BACKUP_DIR)${RESET}"
            echo -e "How would you like to install?"
            echo -e "  ${GREEN}1)${RESET} ${BOLD}Clean Replacement (Recommended)${RESET} — prevents leftover config conflicts"
            echo -e "  ${CYAN}2)${RESET} ${BOLD}Merge / Overwrite${RESET} — overwrite repo files, keep your custom scripts"
            read -rp "Choice [1/2, default 1]: " mode_choice
        fi

        if [[ "$mode_choice" == "2" ]]; then
            clean_mode=false
        fi
    fi

    if [[ "$clean_mode" == true ]]; then
        rm -rf "$HYPR_DST" "$WAYBAR_DST"
    fi

    # 1. Hyprland
    mkdir -p "$HYPR_DST"
    cp -r "$SCRIPT_DIR/hypr/"* "$HYPR_DST/"

    # 2. Waybar
    mkdir -p "$WAYBAR_DST"
    cp -r "$SCRIPT_DIR/waybar/"* "$WAYBAR_DST/"

    # 3. Kitty
    mkdir -p "$KITTY_DST"
    if [[ -f "$KITTY_DST/userprefs.conf" ]]; then
        mv "$KITTY_DST/userprefs.conf" "/tmp/userprefs_backup.conf" 2>/dev/null || true
    fi
    cp -r "$SCRIPT_DIR/kitty/"* "$KITTY_DST/"
    if [[ -f "/tmp/userprefs_backup.conf" ]]; then
        mv "/tmp/userprefs_backup.conf" "$KITTY_DST/userprefs.conf" 2>/dev/null || true
    fi

    # 4. Make all scripts executable
    chmod +x "$HYPR_DST/scripts/"*.sh 2>/dev/null || true
    chmod +x "$HYPR_DST/sidebar/"*.sh 2>/dev/null || true
    chmod +x "$HYPR_DST/sidebar/sidebar.py" 2>/dev/null || true
    chmod +x "$HYPR_DST/change_wallpaper.sh" 2>/dev/null || true

    if [[ "$INSTALL_LANG" == "ru" ]]; then
        log_ok "Файлы успешно скопированы и права выданы!"
    else
        log_ok "Configuration files deployed and permissions granted!"
    fi
}

reload_environment() {
    if pgrep -x "Hyprland" &>/dev/null; then
        if [[ "$INSTALL_LANG" == "ru" ]]; then
            log_info "Hyprland активен. Применяем изменения на лету..."
        else
            log_info "Hyprland is running. Applying changes live..."
        fi

        if [[ -x "$HYPR_DST/scripts/theme_ctl.sh" ]]; then
            "$HYPR_DST/scripts/theme_ctl.sh" set black solid &>/dev/null || true
        fi

        command -v hyprctl &>/dev/null && hyprctl reload &>/dev/null || true
        pkill waybar 2>/dev/null || true
        sleep 0.3
        waybar &>/dev/null &

        pkill -SIGUSR1 kitty 2>/dev/null || true
        pkill -f "sidebar.py" 2>/dev/null || true
        sleep 0.5
        python3 "$HYPR_DST/sidebar/sidebar.py" &>> /tmp/sidebar.log &

        if [[ "$INSTALL_LANG" == "ru" ]]; then
            log_ok "Окружение успешно перезагружено без перезахода!"
        else
            log_ok "Environment reloaded live!"
        fi
    fi
}

restore_backup() {
    local backups=("$CONFIG_DIR"/hypr_backup_*)
    if [[ ! -e "${backups[0]}" ]]; then
        log_warn "No backups found."
        return 0
    fi

    echo -e "\nAvailable backups:"
    local i=1
    for b in "${backups[@]}"; do
        echo "  $i) $(basename "$b")"
        ((i++))
    done

    read -rp "Select backup number to restore (or 0 to cancel): " choice
    if [[ "$choice" -ge 1 && "$choice" -le "${#backups[@]}" ]]; then
        local target="${backups[$((choice - 1))]}"
        log_info "Restoring from $target..."
        [[ -d "$target/hypr" ]]   && rm -rf "$HYPR_DST"   && cp -r "$target/hypr" "$HYPR_DST"
        [[ -d "$target/waybar" ]] && rm -rf "$WAYBAR_DST" && cp -r "$target/waybar" "$WAYBAR_DST"
        [[ -d "$target/kitty" ]]  && rm -rf "$KITTY_DST"  && cp -r "$target/kitty" "$KITTY_DST"
        log_ok "Backup restored!"
        reload_environment
    fi
}

main() {
    local action=""
    for arg in "$@"; do
        case "$arg" in
            --lang=ru|-ru) FORCE_LANG="ru" ;;
            --lang=en|-en) FORCE_LANG="en" ;;
            --fresh) action="fresh" ;;
            --update) action="update" ;;
            --restore) action="restore" ;;
        esac
    done

    select_language

    case "$action" in
        fresh)
            check_and_install_deps
            backup_existing_configs
            deploy_configs
            reload_environment
            exit 0
            ;;
        update)
            backup_existing_configs
            deploy_configs
            reload_environment
            exit 0
            ;;
        restore)
            restore_backup
            exit 0
            ;;
    esac

    if [[ "$INSTALL_LANG" == "ru" ]]; then
        echo -e "${BOLD}Выберите действие:${RESET}"
        echo -e "  ${GREEN}1)${RESET} ${BOLD}Установка на чистый Hyprland${RESET} (с проверкой пакетов)"
        echo -e "  ${CYAN}2)${RESET} ${BOLD}Обновление поверх готовой сборки${RESET} (с авто-бэкапом)"
        echo -e "  ${YELLOW}3)${RESET} Создать только резервную копию (бэкап)"
        echo -e "  ${MAGENTA}4)${RESET} Восстановить конфиги из бэкапа"
        echo -e "  ${RED}5)${RESET} Выход"
        echo ""
        read -rp "Введите пункт [1-5]: " choice
    else
        echo -e "${BOLD}Select Action:${RESET}"
        echo -e "  ${GREEN}1)${RESET} ${BOLD}Install on Fresh Hyprland${RESET} (with package check)"
        echo -e "  ${CYAN}2)${RESET} ${BOLD}Update Existing Setup${RESET} (with auto-backup)"
        echo -e "  ${YELLOW}3)${RESET} Create backup only"
        echo -e "  ${MAGENTA}4)${RESET} Restore from previous backup"
        echo -e "  ${RED}5)${RESET} Exit"
        echo ""
        read -rp "Enter choice [1-5]: " choice
    fi

    case "$choice" in
        1)
            check_and_install_deps
            backup_existing_configs
            deploy_configs
            reload_environment
            ;;
        2)
            backup_existing_configs
            deploy_configs
            reload_environment
            ;;
        3)
            backup_existing_configs
            ;;
        4)
            restore_backup
            ;;
        5)
            exit 0
            ;;
        *)
            log_err "Invalid selection."
            exit 1
            ;;
    esac

    echo -e "\n${GREEN}${BOLD}✔ Done / Готово!${RESET}"
    if [[ "$INSTALL_LANG" == "ru" ]]; then
        echo -e "${CYAN}Горячие клавиши:${RESET}"
        echo -e "  • ${BOLD}Win + /  или  Win + F1${RESET} — Окно со всеми горячими клавишами"
        echo -e "  • ${BOLD}Win + P${RESET}               — Боковая панель настроек"
        echo -e "  • ${BOLD}Win + Shift + S${RESET}       — Скриншот области (сохранение в ~/Screenshots)"
        echo -e "  • ${BOLD}Win + Z / M${RESET}           — На весь экран с сохранением Waybar"
        echo -e "  • ${BOLD}Win + V${RESET}               — Плавающее окно (как в Windows)"
        echo -e "  • ${BOLD}Win + W${RESET}               — Смена режима окон: [Плитка ↔ Макс с Waybar ↔ Windows]"
    else
        echo -e "${CYAN}Keybindings Cheat Sheet:${RESET}"
        echo -e "  • ${BOLD}Win + /  or  Win + F1${RESET}  — Keybindings Help Window"
        echo -e "  • ${BOLD}Win + P${RESET}               — Control Sidebar"
        echo -e "  • ${BOLD}Win + Shift + S${RESET}       — Screenshot Area (saves to ~/Screenshots)"
        echo -e "  • ${BOLD}Win + Z / M${RESET}           — Fullscreen WITH Waybar (Monocle)"
        echo -e "  • ${BOLD}Win + V${RESET}               — Floating Window (like Windows)"
        echo -e "  • ${BOLD}Win + W${RESET}               — Cycle Window Modes: [Tiling ↔ Max with Waybar ↔ Windows]"
    fi
}

main "$@"
