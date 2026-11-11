#!/usr/bin/env bash
# ==============================================================================
# INSTALL.SH — Универсальный установщик и обновлятор сборки Hyprland
# Поддерживает:
# 1. Установку на чистый Hyprland (с проверкой пакетов и зависимостей)
# 2. Обновление / замену поверх существующей сборки с авто-бэкапом
# ==============================================================================

set -e

# Цвета для вывода в терминал
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
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$CONFIG_DIR/hypr_backup_$TIMESTAMP"

print_header() {
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
    echo -e "${BOLD}${MAGENTA}  Универсальный установщик сборки Hyprland${RESET}"
    echo -e "${BLUE}  • Стили: Black, White, macOS Glass, Cyber${RESET}"
    echo -e "${BLUE}  • Режимы окон: Плитка / Monocle с Waybar / Windows Mode${RESET}"
    echo -e "${CYAN}------------------------------------------------------------${RESET}\n"
}

log_info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

log_ok() {
    echo -e "${GREEN}[OK]${RESET} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

log_err() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

# ------------------------------------------------------------------------------
# Определение дистрибутива и пакетного менеджера
# ------------------------------------------------------------------------------
detect_pkg_manager() {
    if command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    elif command -v xbps-install &>/dev/null; then
        echo "xbps"
    else
        echo "unknown"
    fi
}

# ------------------------------------------------------------------------------
# Проверка и установка зависимостей
# ------------------------------------------------------------------------------
check_and_install_deps() {
    local pm
    pm=$(detect_pkg_manager)
    log_info "Определен пакетный менеджер: ${BOLD}$pm${RESET}"

    # Список ключевых утилит
    local core_deps=("hyprland" "waybar" "kitty" "swaybg" "playerctl" "brightnessctl" "python3")
    local missing=()

    for dep in "${core_deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    # Проверка Python GTK Layer Shell (для боковой панели)
    local py_gls_ok=false
    if python3 -c "import gi; gi.require_version('GtkLayerShell', '0.1'); from gi.repository import GtkLayerShell" 2>/dev/null; then
        py_gls_ok=true
    else
        missing+=("gtk-layer-shell" "python-gobject")
    fi

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_ok "Все основные зависимости установлены!"
        return 0
    fi

    log_warn "Обнаружены отсутствующие пакеты: ${YELLOW}${missing[*]}${RESET}"
    read -rp "Установить отсутствующие зависимости автоматически? (y/N): " ans
    if [[ "$ans" =~ ^[YyДд]$ ]]; then
        case "$pm" in
            pacman)
                log_info "Установка через pacman / yay..."
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
                log_info "Установка через dnf..."
                sudo dnf install -y hyprland waybar kitty swaybg dunst rofi-wayland playerctl brightnessctl python3 python3-gobject gtk3 gtk-layer-shell jq || true
                ;;
            apt)
                log_info "Установка через apt..."
                sudo apt-get update
                sudo apt-get install -y waybar kitty playerctl brightnessctl python3 python3-gi gir1.2-gtk-3.0 jq || true
                ;;
            *)
                log_warn "Автоматическая установка для $pm не настроена. Пожалуйста, установите: ${missing[*]}"
                ;;
        esac
    else
        log_info "Пропуск установки пакетов по запросу пользователя."
    fi
}

# ------------------------------------------------------------------------------
# Резервное копирование существующих конфигов
# ------------------------------------------------------------------------------
backup_existing_configs() {
    local has_backup=false

    for dir in "$HYPR_DST" "$WAYBAR_DST" "$KITTY_DST"; do
        if [[ -d "$dir" ]]; then
            has_backup=true
            break
        fi
    done

    if [[ "$has_backup" == true ]]; then
        log_info "Создание резервной копии старых конфигов в: ${BOLD}$BACKUP_DIR${RESET}"
        mkdir -p "$BACKUP_DIR"
        [[ -d "$HYPR_DST" ]]   && cp -r "$HYPR_DST"   "$BACKUP_DIR/hypr"
        [[ -d "$WAYBAR_DST" ]] && cp -r "$WAYBAR_DST" "$BACKUP_DIR/waybar"
        [[ -d "$KITTY_DST" ]]  && cp -r "$KITTY_DST"  "$BACKUP_DIR/kitty"
        log_ok "Резервная копия успешно сохранена!"
    else
        log_info "Предыдущих конфигов не обнаружено — чистая установка."
    fi
}

# ------------------------------------------------------------------------------
# Копирование и развертывание конфигов
# ------------------------------------------------------------------------------
deploy_configs() {
    log_info "Развертывание новых конфигураций..."

    mkdir -p "$CONFIG_DIR" "$WALLPAPER_DST" "$HOME/.cache/sidebar_thumbs"

    local clean_mode=true
    if [[ "${AUTO_MERGE:-false}" == "true" ]]; then
        clean_mode=false
    elif [[ -t 0 && -d "$HYPR_DST" && "${NON_INTERACTIVE:-false}" != "true" ]]; then
        echo -e "\n${YELLOW}Внимание: Обнаружены существующие конфиги Hyprland!${RESET}"
        echo -e "${BLUE}(Они уже сохранены в бэкап: $BACKUP_DIR)${RESET}"
        echo -e "Как применить новую сборку?"
        echo -e "  ${GREEN}1)${RESET} ${BOLD}Чистая замена (Рекомендуется)${RESET} — исключает конфликты и остаточный 'мусор' старой сборки"
        echo -e "  ${CYAN}2)${RESET} ${BOLD}Перезапись поверх (Merge)${RESET} — обновить файлы сборки, но оставить ваши личные файлы нетронутыми"
        read -rp "Ваш выбор [1/2, по умолчанию 1]: " mode_choice
        if [[ "$mode_choice" == "2" ]]; then
            clean_mode=false
        fi
    fi

    if [[ "$clean_mode" == true ]]; then
        log_info "Выполняется чистая замена (старые файлы сохранены в бэкапе)..."
        rm -rf "$HYPR_DST" "$WAYBAR_DST"
    else
        log_info "Выполняется обновление поверх существующих файлов..."
    fi

    # 1. Hyprland конфиги
    mkdir -p "$HYPR_DST"
    cp -r "$SCRIPT_DIR/hypr/"* "$HYPR_DST/"

    # 2. Waybar конфиги
    mkdir -p "$WAYBAR_DST"
    cp -r "$SCRIPT_DIR/waybar/"* "$WAYBAR_DST/"

    # 3. Kitty конфиги
    mkdir -p "$KITTY_DST"
    # Сохраняем userprefs.conf если он уже был настроен пользователем
    if [[ -f "$KITTY_DST/userprefs.conf" ]]; then
        mv "$KITTY_DST/userprefs.conf" "/tmp/userprefs_backup.conf" 2>/dev/null || true
    fi
    cp -r "$SCRIPT_DIR/kitty/"* "$KITTY_DST/"
    if [[ -f "/tmp/userprefs_backup.conf" ]]; then
        mv "/tmp/userprefs_backup.conf" "$KITTY_DST/userprefs.conf" 2>/dev/null || true
    fi

    # 4. Стартовые обои (не перезаписываем личные, если уже есть)
    if [[ -d "$SCRIPT_DIR/hypr/assets/wallpapers" ]]; then
        for wp in "$SCRIPT_DIR/hypr/assets/wallpapers/"*.png; do
            if [[ -f "$wp" ]]; then
                local bname
                bname=$(basename "$wp")
                if [[ ! -f "$WALLPAPER_DST/$bname" ]]; then
                    cp "$wp" "$WALLPAPER_DST/"
                fi
            fi
        done
    fi

    # 5. Выдача прав на исполнение скриптов
    chmod +x "$HYPR_DST/scripts/"*.sh 2>/dev/null || true
    chmod +x "$HYPR_DST/sidebar/"*.sh 2>/dev/null || true
    chmod +x "$HYPR_DST/sidebar/sidebar.py" 2>/dev/null || true
    chmod +x "$HYPR_DST/change_wallpaper.sh" 2>/dev/null || true

    log_ok "Конфигурационные файлы успешно скопированы и права выданы!"
}

# ------------------------------------------------------------------------------
# Живая перезагрузка Hyprland и компонентов
# ------------------------------------------------------------------------------
reload_environment() {
    if pgrep -x "Hyprland" &>/dev/null; then
        log_info "Hyprland запущен. Применяем изменения на лету..."

        # 1. Применяем тему по умолчанию
        if [[ -x "$HYPR_DST/scripts/theme_ctl.sh" ]]; then
            "$HYPR_DST/scripts/theme_ctl.sh" set black solid &>/dev/null || true
        fi

        # 2. Перезагрузка Hyprland
        if command -v hyprctl &>/dev/null; then
            hyprctl reload &>/dev/null || true
        fi

        # 3. Перезагрузка Waybar
        pkill waybar 2>/dev/null || true
        sleep 0.3
        waybar &>/dev/null &

        # 4. Перезагрузка открытых Kitty
        pkill -SIGUSR1 kitty 2>/dev/null || true

        # 5. Перезапуск Sidebar
        pkill -f "sidebar.py" 2>/dev/null || true
        sleep 0.5
        python3 "$HYPR_DST/sidebar/sidebar.py" &>> /tmp/sidebar.log &

        log_ok "Окружение успешно перезагружено без перезахода в систему!"
    else
        log_info "Hyprland сейчас не активен. Конфиги готовы для следующего входа!"
    fi
}

# ------------------------------------------------------------------------------
# Восстановление из бэкапа
# ------------------------------------------------------------------------------
restore_backup() {
    local backups=("$CONFIG_DIR"/hypr_backup_*)
    if [[ ! -e "${backups[0]}" ]]; then
        log_warn "Резервных копий не найдено."
        return 0
    fi

    echo -e "\nДоступные резервные копии:"
    local i=1
    for b in "${backups[@]}"; do
        echo "  $i) $(basename "$b")"
        ((i++))
    done

    read -rp "Выберите номер бэкапа для восстановления (или 0 для отмены): " choice
    if [[ "$choice" -ge 1 && "$choice" -le "${#backups[@]}" ]]; then
        local target="${backups[$((choice - 1))]}"
        log_info "Восстановление из $target..."
        [[ -d "$target/hypr" ]]   && rm -rf "$HYPR_DST"   && cp -r "$target/hypr" "$HYPR_DST"
        [[ -d "$target/waybar" ]] && rm -rf "$WAYBAR_DST" && cp -r "$target/waybar" "$WAYBAR_DST"
        [[ -d "$target/kitty" ]]  && rm -rf "$KITTY_DST"  && cp -r "$target/kitty" "$KITTY_DST"
        log_ok "Восстановление завершено!"
        reload_environment
    else
        log_info "Отмена восстановления."
    fi
}

# ------------------------------------------------------------------------------
# Меню и запуск
# ------------------------------------------------------------------------------
main() {
    print_header

    case "${1:-}" in
        --fresh)
            check_and_install_deps
            backup_existing_configs
            deploy_configs
            reload_environment
            exit 0
            ;;
        --update)
            backup_existing_configs
            deploy_configs
            reload_environment
            exit 0
            ;;
        --no-deps)
            backup_existing_configs
            deploy_configs
            reload_environment
            exit 0
            ;;
        --restore)
            restore_backup
            exit 0
            ;;
    esac

    echo -e "${BOLD}Выберите действие:${RESET}"
    echo -e "  ${GREEN}1)${RESET} ${BOLD}Установка на чистый Hyprland${RESET} (с проверкой пакетов и зависимостей)"
    echo -e "  ${CYAN}2)${RESET} ${BOLD}Обновление поверх готовой сборки${RESET} (с авто-бэкапом старых конфигов)"
    echo -e "  ${YELLOW}3)${RESET} Создать только резервную копию (бэкап)"
    echo -e "  ${MAGENTA}4)${RESET} Восстановить конфиги из предыдущего бэкапа"
    echo -e "  ${RED}5)${RESET} Выход"
    echo ""
    read -rp "Введите пункт [1-5]: " choice

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
            echo "Выход."
            exit 0
            ;;
        *)
            log_err "Неверный выбор."
            exit 1
            ;;
    esac

    echo -e "\n${GREEN}${BOLD}✔ Готово!${RESET}"
    echo -e "${CYAN}Горячие клавиши:${RESET}"
    echo -e "  • ${BOLD}Win + P${RESET}        — Открыть боковую панель настроек (Стили, Обои, Режимы окон)"
    echo -e "  • ${BOLD}Win + Z / M${RESET}    — Развернуть окно на весь экран ${BOLD}с сохранением Waybar${RESET}"
    echo -e "  • ${BOLD}Win + V${RESET}        — Плавающее окно (как в Windows)"
    echo -e "  • ${BOLD}Win + W${RESET}        — Циклическое переключение режимов: [Плитка ↔ Макс с Waybar ↔ Windows]"
    echo -e "  • ${BOLD}Win + F${RESET}        — Полный экран без Waybar"
    echo -e "  • ${BOLD}Win + Alt + P${RESET}  — Переключение позиции Waybar (верх / низ / скрыть)\n"
}

main "$@"
