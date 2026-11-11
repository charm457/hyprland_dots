#!/usr/bin/env bash
# ==============================================================================
# audio_output.sh — Управление и надежное переключение аудиовыходов
# Поддерживает PipeWire и PulseAudio, перемещает активные потоки звука
# ==============================================================================

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
LANG_FILE="$CACHE_DIR/dots_lang"
APP_LANG="ru"
[[ -f "$LANG_FILE" ]] && APP_LANG=$(cat "$LANG_FILE")

get_default_sink() {
    pactl get-default-sink 2>/dev/null || true
}

list_sinks_json() {
    # Возвращает JSON массив: [{"name": "...", "desc": "...", "active": bool}]
    local def_sink
    def_sink=$(get_default_sink)

    python3 - <<EOF
import subprocess, json

def parse_sinks():
    try:
        out = subprocess.check_output("pactl list sinks", shell=True, stderr=subprocess.DEVNULL, timeout=2).decode()
    except Exception:
        return []

    sinks = []
    cur_name = None
    cur_desc = None
    for line in out.splitlines():
        line = line.strip()
        if line.startswith("Name:"):
            cur_name = line.split(":", 1)[1].strip()
        elif line.startswith("Description:"):
            cur_desc = line.split(":", 1)[1].strip()
            if cur_name and cur_desc:
                # Упрощаем и очищаем имя для интерфейса
                clean_desc = cur_desc
                if "Built-in" in clean_desc or "Internal" in clean_desc:
                    clean_desc = "🔈 " + clean_desc
                elif "Headphone" in clean_desc or "Headset" in clean_desc:
                    clean_desc = "🎧 " + clean_desc
                elif "HDMI" in clean_desc or "DisplayPort" in clean_desc:
                    clean_desc = "🖥 " + clean_desc
                elif "Blue" in clean_desc or "Wireless" in clean_desc:
                    clean_desc = "󰂯 " + clean_desc
                else:
                    clean_desc = "🔊 " + clean_desc

                sinks.append({
                    "name": cur_name,
                    "desc": clean_desc,
                    "raw_desc": cur_desc
                })
                cur_name, cur_desc = None, None
    return sinks

sinks = parse_sinks()
print(json.dumps(sinks, ensure_ascii=False))
EOF
}

set_sink() {
    local target="$1"
    if [[ -z "$target" ]]; then
        echo "Ошибка: не указан аудиовыход."
        return 1
    fi

    # 1. Устанавливаем целевой синк по умолчанию
    pactl set-default-sink "$target" 2>/dev/null || true

    # 2. Перемещаем все текущие играющие потоки на новый синк
    pactl list short sink-inputs 2>/dev/null | while read -r input_id rest; do
        if [[ -n "$input_id" ]]; then
            pactl move-sink-input "$input_id" "$target" 2>/dev/null || true
        fi
    done

    # 3. Получаем человекопонятное имя для уведомления
    local friendly_name
    friendly_name=$(pactl list sinks 2>/dev/null | grep -A 2 "Name: $target" | grep "Description:" | cut -d: -f2- | xargs)
    [[ -z "$friendly_name" ]] && friendly_name="$target"

    if command -v notify-send &>/dev/null; then
        if [[ "$APP_LANG" == "en" ]]; then
            notify-send -a "Audio Output" -i audio-speakers "Output Switched" "$friendly_name" -t 2000
        else
            notify-send -a "Аудиовыход" -i audio-speakers "Звук переключен" "$friendly_name" -t 2000
        fi
    fi

    echo "Успешно переключено на: $target"
}

toggle_mute() {
    pactl set-sink-mute @DEFAULT_SINK@ toggle 2>/dev/null || true
}

get_volume() {
    local out
    out=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null)
    local vol
    vol=$(echo "$out" | grep -o -E '[0-9]+%' | head -n 1 | tr -d '%')
    echo "${vol:-50}"
}

set_volume() {
    local val="$1"
    pactl set-sink-volume @DEFAULT_SINK@ "${val}%" 2>/dev/null || true
}

is_muted() {
    local out
    out=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)
    if [[ "$out" == *"yes"* ]]; then
        echo "true"
    else
        echo "false"
    fi
}

case "${1:-list}" in
    list)
        list_sinks_json
        ;;
    default)
        get_default_sink
        ;;
    set)
        set_sink "$2"
        ;;
    get_vol|volume)
        get_volume
        ;;
    set_vol)
        set_volume "$2"
        ;;
    mute)
        toggle_mute
        ;;
    is_muted)
        is_muted
        ;;
    *)
        echo "Использование: $0 [list | default | set <sink_name> | volume | set_vol <0-100> | mute | is_muted]"
        exit 1
        ;;
esac
