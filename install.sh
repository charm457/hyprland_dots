#!/usr/bin/env bash
# ==============================================================================
# INSTALL.SH — Hyprland Dotfiles Installer & Updater
# Supports clean install, full reinstall with auto-rollback, package update check,
# seamless update with automatic backups, and EN/RU languages.
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
SNAPSHOT_DIR="$CONFIG_DIR/hypr_snapshot_pre_reinstall_$TIMESTAMP"
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
        echo -e "${BLUE}  • Режимы окон: Обычный (тайлинг) / Свободный (плавающий как в Windows)${RESET}"
        echo -e "${BLUE}  • Сайдбар: Монохромный (чёрный/белый под тему), управление в 1 строку${RESET}"
    else
        echo -e "${BOLD}${MAGENTA}  Universal Hyprland Dotfiles Installer & Manager${RESET}"
        echo -e "${BLUE}  • Styles: Black, White, macOS Glass, Cyber (with sub-themes)${RESET}"
        echo -e "${BLUE}  • Window Modes: Default (Tiling) / Free (Floating like Windows)${RESET}"
        echo -e "${BLUE}  • Sidebar: Pure Monochrome (Black/White adaptive), compact layout${RESET}"
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

check_and_offer_sys_update() {
    local pm
    pm=$(detect_pkg_manager)
    local has_updates=false

    if [[ "$INSTALL_LANG" == "ru" ]]; then
        log_info "Проверка доступных обновлений пакетов системы..."
    else
        log_info "Checking for available system package updates..."
    fi

    case "$pm" in
        pacman)
            if command -v checkupdates &>/dev/null; then
                if checkupdates 2>/dev/null | grep -q .; then
                    has_updates=true
                fi
            elif pacman -Qu 2>/dev/null | grep -q .; then
                has_updates=true
            fi
            ;;
        dnf)
            if ! dnf check-update --quiet &>/dev/null; then
                # dnf check-update returns exit code 100 when updates are available
                [[ $? -eq 100 ]] && has_updates=true
            fi
            ;;
        apt)
            local apt_pending
            apt_pending=$(apt-get -s upgrade 2>/dev/null | grep -E '^[0-9]+ upgraded' || true)
            if [[ -n "$apt_pending" && ! "$apt_pending" =~ ^0\ upgraded ]]; then
                has_updates=true
            fi
            ;;
    esac

    if [[ "$has_updates" == true ]]; then
        local ans=""
        if [[ "$INSTALL_LANG" == "ru" ]]; then
            log_warn "Обнаружены доступные обновления системных пакетов!"
            read -rp "Желаете обновить пакеты системы сейчас? (y/N): " ans
        else
            log_warn "Available system package updates detected!"
            read -rp "Would you like to upgrade system packages now? (y/N): " ans
        fi

        if [[ "$ans" =~ ^[YyДд]$ ]]; then
            if [[ "$INSTALL_LANG" == "ru" ]]; then
                log_info "Запуск обновления системы..."
            else
                log_info "Running system upgrade..."
            fi

            case "$pm" in
                pacman)
                    if command -v yay &>/dev/null; then
                        yay -Syu || log_warn "Обновление через yay завершилось с предупреждением."
                    elif command -v paru &>/dev/null; then
                        paru -Syu || log_warn "Обновление через paru завершилось с предупреждением."
                    else
                        sudo pacman -Syu || log_warn "Обновление через pacman завершилось с предупреждением."
                    fi
                    ;;
                dnf)
                    sudo dnf upgrade -y || log_warn "Обновление через dnf завершилось с предупреждением."
                    ;;
                apt)
                    sudo apt-get update && sudo apt-get upgrade -y || log_warn "Обновление через apt завершилось с предупреждением."
                    ;;
            esac
            log_ok "Процесс обновления пакетов завершен!"
        else
            if [[ "$INSTALL_LANG" == "ru" ]]; then
                log_info "Обновление пакетов пропущено пользователем."
            else
                log_info "Package upgrade skipped by user."
            fi
        fi
    else
        if [[ "$INSTALL_LANG" == "ru" ]]; then
            log_ok "Системные пакеты в актуальном состоянии."
        else
            log_ok "System packages are up to date."
        fi
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

    # Основные исполняемые команды
    local core_cmds=("hyprland" "waybar" "kitty" "swaybg" "playerctl" "brightnessctl" "python3" "dunst" "jq" "libnotify")
    local missing_cmds=()

    for cmd in "${core_cmds[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_cmds+=("$cmd")
        fi
    done

    # Проверка Python GTK и GtkLayerShell для сайдбара
    local missing_gtk=false
    if ! python3 -c "import gi; gi.require_version('Gtk', '3.0'); gi.require_version('GtkLayerShell', '0.1'); from gi.repository import Gtk, GtkLayerShell" 2>/dev/null; then
        missing_gtk=true
    fi

    # Проверка утилиты скриншотов
    local missing_screenshot=false
    if ! command -v grimblast &>/dev/null && (! command -v grim &>/dev/null || ! command -v slurp &>/dev/null); then
        missing_screenshot=true
    fi

    if [[ ${#missing_cmds[@]} -eq 0 && "$missing_gtk" == false && "$missing_screenshot" == false ]]; then
        if [[ "$INSTALL_LANG" == "ru" ]]; then
            log_ok "Все ключевые зависимости установлены!"
        else
            log_ok "All key dependencies are installed!"
        fi
        return 0
    fi

    if [[ "$INSTALL_LANG" == "ru" ]]; then
        log_warn "Обнаружены отсутствующие компоненты: ${YELLOW}${missing_cmds[*]}${RESET}"
        read -rp "Установить все необходимые библиотеки и пакеты? (y/N): " ans
    else
        log_warn "Missing components detected: ${YELLOW}${missing_cmds[*]}${RESET}"
        read -rp "Install all required packages and libraries? (y/N): " ans
    fi

    if [[ ! "$ans" =~ ^[YyДд]$ ]]; then
        if [[ "$INSTALL_LANG" == "ru" ]]; then
            log_warn "Продолжаем установку без автоматической установки пакетов."
        else
            log_warn "Continuing without automatic package installation."
        fi
        return 0
    fi

    case "$pm" in
        pacman)
            local arch_pkgs=(
                "hyprland" "waybar" "kitty" "swaybg" "dunst" "rofi-wayland"
                "playerctl" "brightnessctl" "grim" "slurp" "wl-clipboard" "libnotify"
                "python" "python-gobject" "gtk3" "gtk-layer-shell" "jq"
                "ttf-jetbrains-mono-nerd" "ttf-font-awesome" "polkit-gnome"
                "yazi" "dolphin"
            )
            if command -v yay &>/dev/null; then
                yay -S --needed --noconfirm "${arch_pkgs[@]}" grimblast-git || true
            elif command -v paru &>/dev/null; then
                paru -S --needed --noconfirm "${arch_pkgs[@]}" grimblast-git || true
            else
                sudo pacman -S --needed --noconfirm "${arch_pkgs[@]}" || true
                # Если grimblast отсутствует, устанавливаем скрипт напрямую
                if ! command -v grimblast &>/dev/null; then
                    log_info "Установка утилиты grimblast..."
                    sudo curl -sSL https://raw.githubusercontent.com/hyprwm/contrib/main/grimblast/grimblast -o /usr/local/bin/grimblast 2>/dev/null && sudo chmod +x /usr/local/bin/grimblast || true
                fi
            fi
            ;;
        dnf)
            local dnf_pkgs=(
                "hyprland" "waybar" "kitty" "swaybg" "dunst" "rofi-wayland"
                "playerctl" "brightnessctl" "grim" "slurp" "wl-clipboard" "libnotify"
                "python3" "python3-gobject" "gtk3" "gtk-layer-shell" "jq"
                "fontawesome-fonts" "polkit-gnome"
            )
            sudo dnf install -y "${dnf_pkgs[@]}" || true
            if ! command -v grimblast &>/dev/null; then
                sudo curl -sSL https://raw.githubusercontent.com/hyprwm/contrib/main/grimblast/grimblast -o /usr/local/bin/grimblast 2>/dev/null && sudo chmod +x /usr/local/bin/grimblast || true
            fi
            ;;
        apt)
            sudo apt-get update || true
            local apt_pkgs=(
                "waybar" "kitty" "swaybg" "dunst" "playerctl" "brightnessctl"
                "grim" "slurp" "wl-clipboard" "libnotify-bin" "python3"
                "python3-gi" "gir1.2-gtk-3.0" "libgtk-layer-shell0" "jq"
                "fonts-font-awesome" "policykit-1-gnome"
            )
            sudo apt-get install -y "${apt_pkgs[@]}" || true
            ;;
        *)
            log_warn "Неподдерживаемый пакетный менеджер. Убедитесь, что установлены: ${core_cmds[*]} python-gobject gtk-layer-shell"
            ;;
    esac

    # Финальная проверка работоспособности библиотек
    if ! python3 -c "import gi; gi.require_version('Gtk', '3.0'); gi.require_version('GtkLayerShell', '0.1'); from gi.repository import Gtk, GtkLayerShell" 2>/dev/null; then
        if [[ "$INSTALL_LANG" == "ru" ]]; then
            log_warn "GtkLayerShell для Python не найден в системе. Сайдбар будет открываться, но без эксклюзивного резервирования зоны."
            log_info "Для Arch Linux: sudo pacman -S gtk-layer-shell python-gobject"
        else
            log_warn "Python GtkLayerShell library not found. Sidebar will run without layer exclusive zone."
            log_info "For Arch Linux: sudo pacman -S gtk-layer-shell python-gobject"
        fi
    else
        log_ok "Все библиотеки и зависимости успешно проверены!"
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
    if [[ -t 0 && -d "$HYPR_DST" && "${NON_INTERACTIVE:-false}" != "true" && "${FORCE_CLEAN:-false}" != "true" ]]; then
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

    # 4. Yazi (кастомный современный менеджер файлов)
    if [[ -d "$SCRIPT_DIR/yazi" ]]; then
        mkdir -p "$CONFIG_DIR/yazi"
        cp -rf "$SCRIPT_DIR/yazi/"* "$CONFIG_DIR/yazi/" 2>/dev/null || true
    fi

    # 5. Копируем switch.sh в hypr/scripts и корень hypr
    cp -f "$SCRIPT_DIR/switch.sh" "$HYPR_DST/scripts/switch.sh" 2>/dev/null || true
    cp -f "$SCRIPT_DIR/switch.sh" "$HYPR_DST/switch.sh" 2>/dev/null || true

    # 6. Выдача прав на выполнение
    chmod +x "$HYPR_DST/scripts/"*.sh 2>/dev/null || true
    chmod +x "$HYPR_DST/sidebar/"*.sh 2>/dev/null || true
    chmod +x "$HYPR_DST/sidebar/sidebar.py" 2>/dev/null || true
    chmod +x "$HYPR_DST/switch.sh" 2>/dev/null || true
    chmod +x "$SCRIPT_DIR/switch.sh" 2>/dev/null || true

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

        # Исключаем дублирование Waybar: убиваем любые старые копии и запускаем ровно один процесс
        killall -9 waybar 2>/dev/null || pkill -9 -x waybar 2>/dev/null || true
        sleep 0.4
        nohup waybar </dev/null &>/dev/null &

        pkill -SIGUSR1 kitty 2>/dev/null || true
        pkill -9 -f "sidebar.py" 2>/dev/null || true
        rm -f "$CACHE_DIR/sidebar.pid" 2>/dev/null || true
        sleep 0.3
        python3 "$HYPR_DST/sidebar/sidebar.py" &>> /tmp/sidebar.log &

        if [[ "$INSTALL_LANG" == "ru" ]]; then
            log_ok "Окружение успешно перезагружено без перезахода!"
        else
            log_ok "Environment reloaded live!"
        fi
    fi
}

# ==============================================================================
# ПОЛНАЯ ПЕРЕУСТАНОВКА С АВТОМАТИЧЕСКИМ ОТКАТОМ (Full Reinstall with Rollback)
# ==============================================================================
full_reinstall() {
    if [[ "$INSTALL_LANG" == "ru" ]]; then
        log_info "Начало полной переустановки с защитой авто-отката..."
    else
        log_info "Starting full reinstall with automated rollback safety..."
    fi

    # 1. Создаем контрольный снапшот текущей рабочей версии
    mkdir -p "$SNAPSHOT_DIR"
    [[ -d "$HYPR_DST" ]]   && cp -r "$HYPR_DST"   "$SNAPSHOT_DIR/hypr"
    [[ -d "$WAYBAR_DST" ]] && cp -r "$WAYBAR_DST" "$SNAPSHOT_DIR/waybar"
    [[ -d "$KITTY_DST" ]]  && cp -r "$KITTY_DST"  "$SNAPSHOT_DIR/kitty"

    if [[ "$INSTALL_LANG" == "ru" ]]; then
        log_ok "Контрольный снимок текущей сборки создан: $SNAPSHOT_DIR"
    else
        log_ok "Pre-reinstall safety snapshot created: $SNAPSHOT_DIR"
    fi

    # Функция экстренного авто-отката при сбое
    rollback_on_failure() {
        local exit_code=$?
        trap - ERR
        echo ""
        if [[ "$INSTALL_LANG" == "ru" ]]; then
            log_err "В процессе переустановки произошла ошибка (код: $exit_code)!"
            log_warn "Запускаем автоматический откат к предыдущей рабочей версии..."
        else
            log_err "An error occurred during reinstall (exit code: $exit_code)!"
            log_warn "Triggering automatic rollback to previous working version..."
        fi

        if [[ -d "$SNAPSHOT_DIR" ]]; then
            [[ -d "$SNAPSHOT_DIR/hypr" ]]   && rm -rf "$HYPR_DST"   && cp -r "$SNAPSHOT_DIR/hypr" "$HYPR_DST"
            [[ -d "$SNAPSHOT_DIR/waybar" ]] && rm -rf "$WAYBAR_DST" && cp -r "$SNAPSHOT_DIR/waybar" "$WAYBAR_DST"
            [[ -d "$SNAPSHOT_DIR/kitty" ]]  && rm -rf "$KITTY_DST"  && cp -r "$SNAPSHOT_DIR/kitty" "$KITTY_DST"

            reload_environment

            if [[ "$INSTALL_LANG" == "ru" ]]; then
                log_ok "Авто-откат успешно завершен! Предыдущая версия восстановлена и запущена."
            else
                log_ok "Auto-rollback completed! Previous working version restored and running."
            fi
        else
            log_err "Snapshot not found, cannot rollback."
        fi
        exit "$exit_code"
    }

    # Включаем ловушку на ошибку
    trap rollback_on_failure ERR

    # 2. Проверка и предложение обновить системные пакеты
    check_and_offer_sys_update

    # 3. Проверка и установка всех библиотек
    check_and_install_deps

    # 4. Полная очистка целевых директорий
    rm -rf "$HYPR_DST" "$WAYBAR_DST" "$KITTY_DST"

    # 5. Развертывание свежих файлов
    FORCE_CLEAN=true NON_INTERACTIVE=true deploy_configs

    # 6. Проверка валидности Python скриптов
    python3 -m py_compile "$HYPR_DST/sidebar/sidebar.py"

    # 7. Перезагрузка и запуск
    reload_environment

    # Отключаем ловушку после успешного завершения
    trap - ERR

    if [[ "$INSTALL_LANG" == "ru" ]]; then
        log_ok "Полная чистая переустановка успешно завершена!"
    else
        log_ok "Full clean reinstall completed successfully!"
    fi
}

restore_backup() {
    local backups=("$CONFIG_DIR"/hypr_backup_* "$CONFIG_DIR"/hypr_snapshot_pre_reinstall_*)
    local valid_backups=()
    for b in "${backups[@]}"; do
        [[ -d "$b" ]] && valid_backups+=("$b")
    done

    if [[ ${#valid_backups[@]} -eq 0 ]]; then
        log_warn "No backups found."
        return 0
    fi

    echo -e "\nAvailable backups / Доступные резервные копии:"
    local i=1
    for b in "${valid_backups[@]}"; do
        echo "  $i) $(basename "$b")"
        ((i++))
    done

    read -rp "Select backup number / Выберите номер бэкапа (0 to cancel): " choice
    if [[ "$choice" -ge 1 && "$choice" -le "${#valid_backups[@]}" ]]; then
        local target="${valid_backups[$((choice - 1))]}"
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
            --reinstall) action="reinstall" ;;
            --restore) action="restore" ;;
        esac
    done

    select_language

    case "$action" in
        fresh)
            check_and_offer_sys_update
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
        reinstall)
            full_reinstall
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
        echo -e "  ${YELLOW}3)${RESET} ${BOLD}Полная переустановка с авто-откатом${RESET} (Clean Reinstall + Rollback)"
        echo -e "  ${BLUE}4)${RESET} Создать только резервную копию (бэкап)"
        echo -e "  ${MAGENTA}5)${RESET} Восстановить конфиги из бэкапа"
        echo -e "  ${RED}6)${RESET} Выход"
        echo ""
        read -rp "Введите пункт [1-6]: " choice
    else
        echo -e "${BOLD}Select Action:${RESET}"
        echo -e "  ${GREEN}1)${RESET} ${BOLD}Install on Fresh Hyprland${RESET} (with package check)"
        echo -e "  ${CYAN}2)${RESET} ${BOLD}Update Existing Setup${RESET} (with auto-backup)"
        echo -e "  ${YELLOW}3)${RESET} ${BOLD}Full Reinstall with Auto-Rollback${RESET} (Clean Reinstall + Rollback)"
        echo -e "  ${BLUE}4)${RESET} Create backup only"
        echo -e "  ${MAGENTA}5)${RESET} Restore from previous backup"
        echo -e "  ${RED}6)${RESET} Exit"
        echo ""
        read -rp "Enter choice [1-6]: " choice
    fi

    case "$choice" in
        1)
            check_and_offer_sys_update
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
            full_reinstall
            ;;
        4)
            backup_existing_configs
            ;;
        5)
            restore_backup
            ;;
        6)
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
        echo -e "  • ${BOLD}Win + E${RESET}               — Кастомный файловый менеджер (Smart)"
        echo -e "  • ${BOLD}Win + Shift + E${RESET}       — Yazi (быстрый файловый менеджер в терминале)"
        echo -e "  • ${BOLD}Win + Alt + E${RESET}         — Dolphin (графический файловый менеджер)"
        echo -e "  • ${BOLD}Win + Shift + S${RESET}       — Скриншот области (сохранение в ~/Screenshots)"
        echo -e "  • ${BOLD}Win + W${RESET}               — Смена режима окон: [Обычный (тайлинг) ↔ Свободный (плавающий)]"
        echo -e "  • ${BOLD}Win + V${RESET}               — Переключить выбранное окно (плавающее / тайл)"
        echo -e "  • ${BOLD}Win + F${RESET}               — Полный экран"
    else
        echo -e "${CYAN}Keybindings Cheat Sheet:${RESET}"
        echo -e "  • ${BOLD}Win + /  or  Win + F1${RESET}  — Keybindings Help Window"
        echo -e "  • ${BOLD}Win + P${RESET}               — Control Sidebar"
        echo -e "  • ${BOLD}Win + E${RESET}               — Custom File Manager (Smart)"
        echo -e "  • ${BOLD}Win + Shift + E${RESET}       — Yazi (Fast Terminal File Manager)"
        echo -e "  • ${BOLD}Win + Alt + E${RESET}         — Dolphin (GUI File Manager)"
        echo -e "  • ${BOLD}Win + Shift + S${RESET}       — Screenshot Area (saves to ~/Screenshots)"
        echo -e "  • ${BOLD}Win + W${RESET}               — Cycle Window Mode: [Default (Tiling) ↔ Free (Floating)]"
        echo -e "  • ${BOLD}Win + V${RESET}               — Toggle Active Window (Floating / Tiled)"
        echo -e "  • ${BOLD}Win + F${RESET}               — Fullscreen Mode"
    fi
}

main "$@"
