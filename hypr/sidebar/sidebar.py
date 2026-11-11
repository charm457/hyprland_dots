#!/usr/bin/env python3
"""
Hyprland Sidebar — боковая панель управления (GtkLayerShell)
Win+P → SIGUSR1 → быстрое открытие/закрытие
Включает:
- Локализацию (EN / RU)
- Компактный плеер со встроенным регулятором громкости
- Надежное переключение устройств вывода звука (динамики / наушники / Bluetooth / HDMI)
- Регулятор яркости
- Режимы окон, Waybar позицию, галерею обоев, темы оформления
"""
import gi, os, sys, signal, subprocess, glob, threading, time, json, re

gi.require_version("Gtk",          "3.0")
gi.require_version("GdkPixbuf",    "2.0")
gi.require_version("GtkLayerShell","0.1")
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib, GtkLayerShell

# ─── Пути ────────────────────────────────────────────────────────────────────
HOME          = os.path.expanduser("~")
HYPR_DIR      = os.path.join(HOME, ".config", "hypr")
SCRIPTS_DIR   = os.path.join(HYPR_DIR, "scripts")
WALLPAPER_DIR = os.path.join(HOME, "wallpapers")
CACHE_DIR     = os.path.join(HOME, ".cache")
THUMB_DIR     = os.path.join(CACHE_DIR, "sidebar_thumbs")
PID_FILE      = os.path.join(CACHE_DIR, "sidebar.pid")
THEME_FILE    = os.path.join(CACHE_DIR, "sidebar_theme")
WP_IDX_FILE   = os.path.join(CACHE_DIR, "wallpaper_index")
MODE_FILE     = os.path.join(CACHE_DIR, "hypr_window_mode")
WAYBAR_POS    = os.path.join(CACHE_DIR, "waybar_position")
LANG_FILE     = os.path.join(CACHE_DIR, "dots_lang")

os.makedirs(THUMB_DIR, exist_ok=True)
os.makedirs(CACHE_DIR, exist_ok=True)

# ─── Языковые строки (Локализация) ──────────────────────────────────────────
LOCALES = {
    "en": {
        "title": "⚙  SETTINGS",
        "lang_btn": "🌐 RU",
        "modes_title": "WINDOW MODES",
        "mode_tiling": "▦  Tiling (Auto-split)",
        "mode_monocle": "⛶  Fullscreen (with Waybar)",
        "mode_windows": "🪟  Windows Mode (Floating)",
        "mode_tiling_desc": "Automatic dynamic tiling",
        "mode_monocle_desc": "Maximize window, keep Waybar visible",
        "mode_windows_desc": "Floating stacking windows like Windows",
        "music_title": "NOW PLAYING & VOLUME",
        "output_title": "AUDIO OUTPUT DEVICE",
        "output_connected": "Connected:",
        "refresh_btn": "🔄 Refresh",
        "bright_title": "BRIGHTNESS",
        "wireless_title": "CONNECTIVITY",
        "wifi": "󰤨  Wi-Fi",
        "bt": "󰂯  Bluetooth",
        "airplane": "✈  Airplane",
        "power": "🔋 Battery Saver",
        "waybar_title": "WAYBAR POSITION",
        "wb_top": "⬆ Top",
        "wb_bottom": "⬇ Bottom",
        "wb_hide": "👁 Hide",
        "wp_title": "WALLPAPERS",
        "themes_title": "THEMES & STYLES",
        "no_music": "Nothing Playing",
    },
    "ru": {
        "title": "⚙  НАСТРОЙКИ",
        "lang_btn": "🌐 EN",
        "modes_title": "РЕЖИМ ОКОН",
        "mode_tiling": "▦  Плитка (Tiling)",
        "mode_monocle": "⛶  На весь экран (с Waybar)",
        "mode_windows": "🪟  Как в Windows (Плавающий)",
        "mode_tiling_desc": "Автоматическое разделение окон",
        "mode_monocle_desc": "Окна развернуты на экран, Waybar виден",
        "mode_windows_desc": "Плавающие окна, свободное перемещение",
        "music_title": "МУЗЫКА И ГРОМКОСТЬ",
        "output_title": "ВЫВОД ЗВУКА",
        "output_connected": "Подключено:",
        "refresh_btn": "🔄 Обновить",
        "bright_title": "ЯРКОСТЬ",
        "wireless_title": "БЕСПРОВОДНАЯ СВЯЗЬ",
        "wifi": "󰤨  Wi-Fi",
        "bt": "󰂯  Bluetooth",
        "airplane": "✈  Авиарежим",
        "power": "🔋 Экономия",
        "waybar_title": "ПАНЕЛЬ WAYBAR",
        "wb_top": "⬆ Вверху",
        "wb_bottom": "⬇ Внизу",
        "wb_hide": "👁 Скрыть",
        "wp_title": "ОБОИ",
        "themes_title": "ДИЗАЙН И СТИЛИЗАЦИЯ",
        "no_music": "Ничего не играет",
    }
}

def get_current_lang():
    try:
        if os.path.exists(LANG_FILE):
            l = open(LANG_FILE).read().strip()
            if l in LOCALES: return l
    except Exception:
        pass
    return "ru"

# ─── Стили оформления ────────────────────────────────────────────────────────
STYLE_GROUPS = [
    {
        "title_en": "⬛  TOTAL BLACK (OLED)",
        "title_ru": "⬛  ЧЁРНЫЙ СТИЛЬ (TOTAL BLACK)",
        "category": "black",
        "styles": [
            ("solid",   "⬛ Pure OLED Black",    "⬛ Чистый OLED",      "100% solid pitch black, zero blur"),
            ("stealth", "🌑 Matte Stealth",      "🌑 Графитовый",       "Matte dark graphite with subtle blur"),
            ("glass",   "🧊 Smoked Glass",       "🧊 Дымчатое стекло",  "Smoked obsidian glass with deep blur"),
        ]
    },
    {
        "title_en": "🍎  APPLE MACOS / IOS",
        "title_ru": "🍎  APPLE MACOS / IOS",
        "category": "macos",
        "styles": [
            ("pitch_dark", "🖤 macOS / iOS Total Black", "🖤 macOS Total Black (OLED)", "Pitch black OLED with crisp dark-white symbols"),
            ("glass",      "💎 macOS Liquid Glass",       "💎 macOS Стекло (Glass)",      "Full transparency, 4-pass blur, floating island"),
            ("dark",       "🌘 macOS Dark Glass",         "🌘 macOS Темная Sonoma",       "Sonoma dark frosted glass aesthetic"),
            ("light",      "🌖 macOS Light Glass",        "🌖 macOS Светлая",             "Cupertino frosted light glass"),
        ]
    },
    {
        "title_en": "⬜  TOTAL WHITE",
        "title_ru": "⬜  БЕЛЫЙ СТИЛЬ (TOTAL WHITE)",
        "category": "white",
        "styles": [
            ("clean", "⬜ Snow Clean",           "⬜ Чистый белый",      "High-contrast minimalist bright white"),
            ("glass", "🥛 Frosted Glass",        "🥛 Белое стекло",      "Frosted acrylic glass with soft glow"),
            ("latte", "☕ Catppuccin Latte",     "☕ Catppuccin Latte",  "Soothing warm pastel cream aesthetic"),
        ]
    },
    {
        "title_en": "⚡  CYBER & NORD",
        "title_ru": "⚡  КИБЕР & НОРД (CYBER / NORD)",
        "category": "cyber",
        "styles": [
            ("neon", "👾 Cyber Neon",   "👾 Cyber Neon",  "Cyan/magenta synthwave neon glow"),
            ("nord", "❄  Nord Arctic",  "❄  Nord Arctic", "Cold Nordic frost with arctic blue accents"),
        ]
    }
]

# ─── GTK CSS ─────────────────────────────────────────────────────────────────
GTK_CSS = """
* { transition: none; font-family: "JetBrainsMono Nerd Font", "SF Pro Display", sans-serif; }
window {
    background-color: #0c0c0e;
    color: #d0d0d5;
    border-radius: 16px;
    border: 2px solid #282830;
    box-shadow: 0 10px 35px rgba(0, 0, 0, 0.75);
}
.root-box { background-color: transparent; }

/* Всегда видимая полоса прокрутки */
scrollbar, scrollbar.vertical {
    background-color: transparent;
    border: none;
    min-width: 8px;
    margin: 4px 2px;
}
scrollbar trough, scrollbar.vertical trough {
    background-color: rgba(255, 255, 255, 0.06);
    border-radius: 6px;
    min-width: 8px;
}
scrollbar slider, scrollbar.vertical slider {
    background-color: rgba(255, 255, 255, 0.28);
    border-radius: 6px;
    min-width: 6px;
    min-height: 36px;
    margin: 1px;
}
scrollbar slider:hover, scrollbar.vertical slider:hover {
    background-color: rgba(255, 255, 255, 0.45);
}
scrollbar slider:active, scrollbar.vertical slider:active {
    background-color: #70c0ff;
}

.section-label {
    color: #6a7080;
    font-size: 10px;
    font-weight: bold;
    padding: 7px 2px 3px 2px;
    letter-spacing: 1.2px;
}
.header-label {
    color: #ffffff;
    font-size: 15px;
    font-weight: bold;
    padding: 4px 2px;
}
.lang-btn {
    background-color: #141418;
    color: #64b5f6;
    border-radius: 10px;
    border: 1px solid #222530;
    padding: 2px 10px;
    font-size: 11px;
    font-weight: bold;
}
.lang-btn:hover { background-color: #1e2230; color: #ffffff; }

/* Плеер со встроенной громкостью */
.player-box {
    background-color: #0a0a0c;
    border-radius: 12px;
    border: 1px solid #1a1a20;
    padding: 8px 10px 6px 10px;
    margin: 2px 0px 4px 0px;
}
.player-title {
    color: #ffffff;
    font-size: 11px;
    font-weight: bold;
}
.player-artist {
    color: #7b8090;
    font-size: 10px;
}
.player-btn {
    background-color: transparent;
    color: #9da3b4;
    border: none;
    border-radius: 14px;
    padding: 2px 6px;
    font-size: 13px;
    min-width: 26px;
    min-height: 26px;
}
.player-btn:hover {
    background-color: #1c1e28;
    color: #ffffff;
}
.player-btn.play {
    color: #ffffff;
    font-size: 15px;
}
.vol-row {
    margin-top: 4px;
    padding-top: 4px;
    border-top: 1px solid #14141a;
}
.vol-mute-btn {
    background-color: transparent;
    color: #8c90a0;
    border: none;
    font-size: 13px;
    padding: 0 4px;
}
.vol-mute-btn:hover { color: #ffffff; }
.vol-lbl {
    font-size: 10px;
    color: #7b8090;
    font-weight: bold;
    min-width: 32px;
}
scale trough {
    background-color: #1a1a22;
    border-radius: 4px;
    min-height: 5px;
}
scale highlight {
    background-color: #70c0ff;
    border-radius: 4px;
}

/* Карточка аудиовыхода */
.sink-box {
    background-color: #0a0a0c;
    border-radius: 12px;
    border: 1px solid #1a1a20;
    padding: 8px 10px;
    margin: 2px 0 4px 0;
}
.sink-status-lbl {
    font-size: 10px;
    color: #80d0ff;
    padding-top: 4px;
}
.sink-refresh-btn {
    background-color: #14141a;
    color: #8c90a0;
    border-radius: 6px;
    border: 1px solid #22222a;
    padding: 3px 8px;
    font-size: 10px;
}
.sink-refresh-btn:hover {
    background-color: #1e202a;
    color: #ffffff;
}

/* Карточка яркости */
.bright-box {
    background-color: #0a0a0c;
    border-radius: 12px;
    border: 1px solid #1a1a20;
    padding: 6px 10px;
    margin: 2px 0 4px 0;
}

/* Переключатели Wi-Fi / BT */
.toggle-btn {
    background-color: #0a0a0c;
    color: #8c90a0;
    border-radius: 10px;
    border: 1px solid #1a1a20;
    padding: 6px;
    font-size: 11px;
    min-height: 44px;
}
.toggle-btn:hover { background-color: #14141a; color: #cccccc; }
.toggle-btn.on {
    background-color: #0d2212;
    color: #44dd66;
    border: 1px solid #1a4022;
}
.toggle-btn.on-airplane {
    background-color: #261805;
    color: #ffaa00;
    border: 1px solid #482f00;
}
.toggle-btn.on-power {
    background-color: #0c1a26;
    color: #80d0ff;
    border: 1px solid #163650;
}

/* Режимы окон */
.mode-btn {
    background-color: #0a0a0c;
    color: #9da2b0;
    border-radius: 8px;
    border: 1px solid #1a1a20;
    padding: 6px 8px;
    font-size: 11px;
    min-height: 32px;
}
.mode-btn:hover { background-color: #161822; color: #ffffff; }
.mode-btn.active-mode {
    background-color: #101c28;
    color: #80d0ff;
    border: 1px solid #204060;
    font-weight: bold;
}

/* Темы */
.theme-btn {
    background-color: #0a0a0c;
    color: #a0a5b5;
    border-radius: 8px;
    border: 1px solid #1a1a20;
    padding: 6px 10px;
    font-size: 12px;
    min-height: 32px;
}
.theme-btn:hover { background-color: #161822; color: #ffffff; }
.theme-btn.active-theme {
    background-color: #132238;
    color: #64b5f6;
    border: 1px solid #244c82;
    font-weight: bold;
}

/* Waybar позиция */
.pos-btn {
    background-color: #0a0a0c;
    color: #8c90a0;
    border-radius: 6px;
    border: 1px solid #1a1a20;
    padding: 5px 8px;
    font-size: 11px;
}
.pos-btn:hover { background-color: #161822; color: #ffffff; }
.pos-btn.active-pos {
    background-color: #181a24;
    color: #ffffff;
    border: 1px solid #2d3240;
}

/* Обои */
.wp-btn {
    padding: 2px;
    border-radius: 6px;
    border: 2px solid transparent;
    background-color: transparent;
}
.wp-btn:hover { border-color: #383c48; }
.wp-btn.active-wp { border-color: #4da3ff; }
scrollbar { background-color: transparent; min-width: 4px; }
scrollbar slider { background-color: #222530; border-radius: 3px; min-width: 4px; }
"""

# ─── Вспомогательные функции ─────────────────────────────────────────────────
def run_bg(cmd):
    subprocess.Popen(cmd, shell=True,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                     start_new_session=True)

def run_out(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL,
                                       timeout=3).decode().strip()
    except Exception:
        return ""

# Обои
def get_wallpapers():
    files = []
    for ext in ("*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.PNG"):
        files += glob.glob(os.path.join(WALLPAPER_DIR, ext))
    return sorted(set(files))

def get_current_wp_index():
    try:
        return int(open(WP_IDX_FILE).read().strip())
    except Exception:
        return 0

def set_wallpaper(path, idx):
    try:
        open(WP_IDX_FILE, "w").write(str(idx))
        open(os.path.join(CACHE_DIR, "current_wallpaper"), "w").write(path)
    except Exception:
        pass
    run_bg(f'pkill swaybg 2>/dev/null; sleep 0.15; swaybg -i "{path}" -m stretch')

def thumb_path(wp):
    return os.path.join(THUMB_DIR, os.path.basename(wp) + ".thumb.png")

def ensure_thumb(wp):
    tp = thumb_path(wp)
    if os.path.exists(tp):
        return tp
    try:
        pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(wp, 84, 50, False)
        pb.savev(tp, "png", [], [])
        return tp
    except Exception:
        return None

def get_active_theme():
    try:
        return open(THEME_FILE).read().strip()
    except Exception:
        return "black_solid"

def get_active_mode():
    try:
        return open(MODE_FILE).read().strip()
    except Exception:
        return "tiling"

def get_waybar_pos():
    try:
        return open(WAYBAR_POS).read().strip()
    except Exception:
        return "top"

# ─── Сеть и оборудование ─────────────────────────────────────────────────────
def get_wifi_state():
    out = run_out("rfkill list wifi")
    return "Soft blocked: no" in out

def get_bt_state():
    out = run_out("rfkill list bluetooth")
    for l in out.splitlines():
        if "Soft blocked:" in l:
            return "Soft blocked: no" in l
    return False

def get_airplane_state():
    return not get_wifi_state() and not get_bt_state()

def get_power_profile():
    return run_out("powerprofilesctl get")

def toggle_wifi():
    if get_wifi_state(): run_bg("rfkill block wifi")
    else: run_bg("rfkill unblock wifi")

def toggle_bt():
    if get_bt_state(): run_bg("rfkill block bluetooth")
    else: run_bg("rfkill unblock bluetooth")

def toggle_airplane():
    if get_airplane_state(): run_bg("rfkill unblock all")
    else: run_bg("rfkill block all")

def toggle_power_saver():
    p = get_power_profile()
    if p == "power-saver": run_bg("powerprofilesctl set balanced")
    else: run_bg("powerprofilesctl set power-saver")

# ─── Аудио и Яркость (через audio_output.sh) ─────────────────────────────────
def get_volume():
    out = run_out(f'bash "{SCRIPTS_DIR}/audio_output.sh" volume')
    try: return int(out)
    except: return 50

def set_volume(val):
    run_bg(f'bash "{SCRIPTS_DIR}/audio_output.sh" set_vol {int(val)}')

def is_audio_muted():
    return run_out(f'bash "{SCRIPTS_DIR}/audio_output.sh" is_muted') == "true"

def toggle_audio_mute():
    run_bg(f'bash "{SCRIPTS_DIR}/audio_output.sh" mute')

def get_audio_sinks():
    out = run_out(f'bash "{SCRIPTS_DIR}/audio_output.sh" list')
    try: return json.loads(out)
    except: return []

def get_default_sink():
    return run_out(f'bash "{SCRIPTS_DIR}/audio_output.sh" default')

def switch_audio_sink(sink_name):
    run_bg(f'bash "{SCRIPTS_DIR}/audio_output.sh" set "{sink_name}"')

def get_brightness():
    try:
        out = run_out("brightnessctl -m")
        m = re.search(r'(\d+)%', out)
        if m: return int(m.group(1))
    except Exception:
        pass
    return 70

def set_brightness(val):
    run_bg(f"brightnessctl set {int(val)}%")

# ─── Плеер ───────────────────────────────────────────────────────────────────
def player_get_title(lang="ru"):
    no_m = LOCALES[lang]["no_music"]
    return run_out("playerctl metadata title 2>/dev/null") or no_m

def player_get_artist():
    return run_out("playerctl metadata artist 2>/dev/null") or "—"

def player_get_status():
    return run_out("playerctl status 2>/dev/null")


# ─── Класс Sidebar ───────────────────────────────────────────────────────────
class Sidebar:
    def __init__(self):
        self.visible   = False
        self.lang      = get_current_lang()
        self._wp_btns  = []
        self._th_btns  = {}
        self._mode_btns= {}
        self._pos_btns = {}
        self._tog_btns = {}
        self._player_title_lbl  = None
        self._player_artist_lbl = None
        self._play_btn          = None
        self._vol_scale         = None
        self._vol_lbl           = None
        self._vol_mute_btn      = None
        self._sink_combo        = None
        self._sink_status_lbl   = None
        self._bright_scale      = None
        self._bright_lbl        = None
        self._refresh_timer     = None

        self.window = Gtk.Window(type=Gtk.WindowType.TOPLEVEL)
        self.window.set_title("sidebar")
        self.window.connect("destroy", self._quit)
        self.window.connect("key-press-event", self._on_key)

        # LayerShell
        GtkLayerShell.init_for_window(self.window)
        GtkLayerShell.set_layer(self.window, GtkLayerShell.Layer.TOP)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.LEFT,   True)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.RIGHT,  False)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.TOP,    True)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.BOTTOM, True)

        # Отступы: располагается строго ниже Waybar (тачбара), на том же уровне что и обычные окна
        pos = get_waybar_pos()
        top_m = 52 if pos != "bottom" else 12
        bot_m = 52 if pos == "bottom" else 12
        GtkLayerShell.set_margin(self.window, GtkLayerShell.Edge.TOP,    top_m)
        GtkLayerShell.set_margin(self.window, GtkLayerShell.Edge.BOTTOM, bot_m)
        GtkLayerShell.set_margin(self.window, GtkLayerShell.Edge.LEFT,   12)
        GtkLayerShell.set_margin(self.window, GtkLayerShell.Edge.RIGHT,  0)

        # Эксклюзивная зона: в скрытом состоянии 0
        GtkLayerShell.set_exclusive_zone(self.window, 0)
        GtkLayerShell.set_namespace(self.window, "sidebar")
        GtkLayerShell.set_keyboard_mode(self.window, GtkLayerShell.KeyboardMode.ON_DEMAND)

        try:
            self.window.set_wmclass("sidebar", "Sidebar")
        except Exception:
            pass

        # CSS
        prov = Gtk.CssProvider()
        prov.load_from_data(GTK_CSS.encode())
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), prov, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        self._build_ui()

        # При старте демон запускается скрытым в фоне, открывается только по Win+P
        if "--show" in sys.argv:
            self.toggle()

        self._refresh_timer = GLib.timeout_add(3000, self._refresh_dynamic)

    def toggle(self):
        GLib.idle_add(self._do_toggle)

    def _do_toggle(self):
        if self.visible:
            GtkLayerShell.set_exclusive_zone(self.window, 0)
            self.window.hide()
            self.visible = False
        else:
            self.lang = get_current_lang()
            pos = get_waybar_pos()
            top_m = 52 if pos != "bottom" else 12
            bot_m = 52 if pos == "bottom" else 12
            GtkLayerShell.set_margin(self.window, GtkLayerShell.Edge.TOP,    top_m)
            GtkLayerShell.set_margin(self.window, GtkLayerShell.Edge.BOTTOM, bot_m)
            GtkLayerShell.set_margin(self.window, GtkLayerShell.Edge.LEFT,   12)
            GtkLayerShell.set_margin(self.window, GtkLayerShell.Edge.RIGHT,  0)
            # При открытии слева резервируем 308px под сайдбар:
            # Hyprland автоматически ужимает обычные окна вправо на том же уровне!
            GtkLayerShell.set_exclusive_zone(self.window, 308)
            self._refresh_dynamic()
            self.window.show_all()
            self.visible = True
        return False

    def _on_key(self, w, event):
        if event.keyval == Gdk.KEY_Escape:
            GtkLayerShell.set_exclusive_zone(self.window, 0)
            self.window.hide()
            self.visible = False

    def _quit(self, *_):
        try:
            os.remove(PID_FILE)
        except Exception:
            pass
        Gtk.main_quit()

    def _refresh_dynamic(self):
        def _do():
            title  = player_get_title(self.lang)
            artist = player_get_artist()
            status = player_get_status()
            GLib.idle_add(self._update_player_ui, title, artist, status)

            states = {
                "wifi":     get_wifi_state(),
                "bt":       get_bt_state(),
                "airplane": get_airplane_state(),
                "power":    get_power_profile() == "power-saver",
            }
            mode = get_active_mode()
            theme = get_active_theme()
            pos = get_waybar_pos()
            vol = get_volume()
            muted = is_audio_muted()
            bright = get_brightness()
            sinks = get_audio_sinks()
            def_sink = get_default_sink()

            GLib.idle_add(self._update_states_ui, states, mode, theme, pos, vol, muted, bright, sinks, def_sink)
        threading.Thread(target=_do, daemon=True).start()
        return True

    def _update_player_ui(self, title, artist, status):
        if self._player_title_lbl:
            self._player_title_lbl.set_text(title[:26] + "…" if len(title) > 26 else title)
        if self._player_artist_lbl:
            self._player_artist_lbl.set_text(artist[:24] if artist else "")
        if self._play_btn:
            icon = "⏸" if status == "Playing" else "▶"
            self._play_btn.set_label(icon)
        return False

    def _update_states_ui(self, states, active_mode, active_theme, waybar_pos, vol, muted, bright, sinks, def_sink):
        # Toggles
        mapping = {
            "wifi":     ("wifi",     "on"),
            "bt":       ("bt",       "on"),
            "airplane": ("airplane", "on-airplane"),
            "power":    ("power",    "on-power"),
        }
        for key, (bname, cls_on) in mapping.items():
            btn = self._tog_btns.get(bname)
            if not btn: continue
            if states.get(key): btn.get_style_context().add_class(cls_on)
            else:
                btn.get_style_context().remove_class("on")
                btn.get_style_context().remove_class("on-airplane")
                btn.get_style_context().remove_class("on-power")

        # Режим окон
        for m_name, btn in self._mode_btns.items():
            if m_name == active_mode: btn.get_style_context().add_class("active-mode")
            else: btn.get_style_context().remove_class("active-mode")

        # Тема
        for th_key, btn in self._th_btns.items():
            if th_key == active_theme: btn.get_style_context().add_class("active-theme")
            else: btn.get_style_context().remove_class("active-theme")

        # Waybar позиция
        for p_name, btn in self._pos_btns.items():
            if p_name == waybar_pos: btn.get_style_context().add_class("active-pos")
            else: btn.get_style_context().remove_class("active-pos")

        # Громкость
        if self._vol_scale and not self._vol_scale.has_grab():
            self._vol_scale.set_value(vol)
        if self._vol_lbl:
            self._vol_lbl.set_text(f"{vol}%")
        if self._vol_mute_btn:
            self._vol_mute_btn.set_label("󰝟" if muted else "󰕾")

        # Яркость
        if self._bright_scale and not self._bright_scale.has_grab():
            self._bright_scale.set_value(bright)
        if self._bright_lbl:
            self._bright_lbl.set_text(f"{bright}%")

        # Аудиовыходы
        if self._sink_combo and sinks:
            self._sink_combo.handler_block_by_func(self._on_sink_changed)
            self._sink_combo.remove_all()
            active_idx = 0
            for i, s in enumerate(sinks):
                s_name = s.get("name", "")
                s_desc = s.get("desc", s_name)
                self._sink_combo.append(s_name, s_desc[:30])
                if s_name == def_sink:
                    active_idx = i
                    if self._sink_status_lbl:
                        conn_txt = LOCALES[self.lang]["output_connected"]
                        self._sink_status_lbl.set_text(f"● {conn_txt} {s.get('raw_desc', s_name)[:26]}")
            self._sink_combo.set_active(active_idx)
            self._sink_combo.handler_unblock_by_func(self._on_sink_changed)

        return False

    # ─── UI ──────────────────────────────────────────────────────────────────
    def _build_ui(self):
        sw = Gtk.ScrolledWindow()
        sw.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.ALWAYS)
        sw.set_overlay_scrolling(False)
        sw.set_size_request(280, -1)

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        root.get_style_context().add_class("root-box")
        root.set_border_width(10)

        t = LOCALES[self.lang]

        # Верхняя плашка: Заголовок + Кнопка смены языка
        top_bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        lbl_head = Gtk.Label(label=t["title"], xalign=0)
        lbl_head.get_style_context().add_class("header-label")
        top_bar.pack_start(lbl_head, True, True, 0)

        lang_btn = Gtk.Button(label=t["lang_btn"])
        lang_btn.get_style_context().add_class("lang-btn")
        lang_btn.connect("clicked", self._toggle_lang)
        top_bar.pack_end(lang_btn, False, False, 0)
        root.pack_start(top_bar, False, False, 0)

        # 1. Режим окон
        root.pack_start(self._lbl(t["modes_title"]), False, False, 0)
        root.pack_start(self._make_window_modes(t), False, False, 0)

        # 2. Плеер со встроенным регулятором громкости
        root.pack_start(self._lbl(t["music_title"]), False, False, 0)
        root.pack_start(self._make_player(t), False, False, 0)

        # 3. Выбор устройства вывода звука
        root.pack_start(self._lbl(t["output_title"]), False, False, 0)
        root.pack_start(self._make_audio_sinks(t), False, False, 0)

        # 4. Яркость
        root.pack_start(self._lbl(t["bright_title"]), False, False, 0)
        root.pack_start(self._make_brightness(), False, False, 0)

        # 5. Переключатели Wi-Fi / BT
        root.pack_start(self._lbl(t["wireless_title"]), False, False, 0)
        root.pack_start(self._make_toggles(t), False, False, 0)

        # 6. Waybar позиция
        root.pack_start(self._lbl(t["waybar_title"]), False, False, 0)
        root.pack_start(self._make_waybar_pos(t), False, False, 0)

        # 7. Обои
        root.pack_start(self._lbl(t["wp_title"]), False, False, 0)
        root.pack_start(self._make_wallpapers(), False, False, 0)

        # 8. Стили и Темы
        root.pack_start(self._lbl(t["themes_title"]), False, False, 0)
        root.pack_start(self._make_themes(), True, True, 0)

        sw.add(root)
        self.window.add(sw)

    def _lbl(self, text):
        l = Gtk.Label(label=text, xalign=0)
        l.get_style_context().add_class("section-label")
        return l

    def _toggle_lang(self, _):
        new_l = "en" if self.lang == "ru" else "ru"
        open(LANG_FILE, "w").write(new_l)
        run_bg(f'bash "{SCRIPTS_DIR}/lang_ctl.sh" set {new_l}')

    # ─── 1. Режимы окон ───────────────────────────────────────────────────────
    def _make_window_modes(self, t):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        box.set_margin_top(2); box.set_margin_bottom(4)

        current_mode = get_active_mode()
        modes = [
            ("tiling",  t["mode_tiling"],  t["mode_tiling_desc"]),
            ("monocle", t["mode_monocle"], t["mode_monocle_desc"]),
            ("windows", t["mode_windows"], t["mode_windows_desc"]),
        ]

        for m_key, title, tooltip in modes:
            btn = Gtk.Button(label=title)
            btn.set_property("xalign", 0.05)
            btn.get_style_context().add_class("mode-btn")
            btn.set_tooltip_text(tooltip)
            if m_key == current_mode:
                btn.get_style_context().add_class("active-mode")
            btn.connect("clicked", self._on_mode_click, m_key)
            self._mode_btns[m_key] = btn
            box.pack_start(btn, False, False, 0)

        return box

    def _on_mode_click(self, btn, m_key):
        for k, b in self._mode_btns.items():
            b.get_style_context().remove_class("active-mode")
        btn.get_style_context().add_class("active-mode")
        run_bg(f'bash "{SCRIPTS_DIR}/window_mode.sh" {m_key}')

    # ─── 2. Плеер со встроенным регулятором громкости (без эквалайзера) ────────
    def _make_player(self, t):
        pbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        pbox.get_style_context().add_class("player-box")

        # 1-я строка: Название трека + управление (⏮ ▶ ⏭)
        top_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)

        info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=1)
        self._player_title_lbl = Gtk.Label(label=player_get_title(self.lang), xalign=0)
        self._player_title_lbl.get_style_context().add_class("player-title")
        self._player_title_lbl.set_max_width_chars(24)
        self._player_title_lbl.set_ellipsize(3)

        self._player_artist_lbl = Gtk.Label(label=player_get_artist(), xalign=0)
        self._player_artist_lbl.get_style_context().add_class("player-artist")
        self._player_artist_lbl.set_max_width_chars(24)
        self._player_artist_lbl.set_ellipsize(3)

        info_box.pack_start(self._player_title_lbl, False, False, 0)
        info_box.pack_start(self._player_artist_lbl, False, False, 0)
        top_row.pack_start(info_box, True, True, 0)

        ctrl = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=2)
        status = player_get_status()
        play_icon = "⏸" if status == "Playing" else "▶"

        for icon, cmd, is_play in [
            ("⏮", "playerctl previous", False),
            (play_icon, "playerctl play-pause", True),
            ("⏭", "playerctl next", False),
        ]:
            btn = Gtk.Button(label=icon)
            btn.get_style_context().add_class("player-btn")
            if is_play:
                btn.get_style_context().add_class("play")
                self._play_btn = btn
            btn.connect("clicked", lambda _, c=cmd: run_bg(c))
            ctrl.pack_start(btn, False, False, 0)

        top_row.pack_end(ctrl, False, False, 0)
        pbox.pack_start(top_row, False, False, 0)

        # 2-я строка: Встроенная громкость (вместо эквалайзера)
        vol_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        vol_row.get_style_context().add_class("vol-row")

        self._vol_mute_btn = Gtk.Button(label="󰕾")
        self._vol_mute_btn.get_style_context().add_class("vol-mute-btn")
        self._vol_mute_btn.connect("clicked", self._on_mute_clicked)
        vol_row.pack_start(self._vol_mute_btn, False, False, 0)

        cur_vol = get_volume()
        vol_adj = Gtk.Adjustment(value=cur_vol, lower=0, upper=100, step_increment=2, page_increment=10)
        self._vol_scale = Gtk.Scale(orientation=Gtk.Orientation.HORIZONTAL, adjustment=vol_adj)
        self._vol_scale.set_draw_value(False)
        self._vol_scale.connect("value-changed", self._on_vol_changed)
        vol_row.pack_start(self._vol_scale, True, True, 0)

        self._vol_lbl = Gtk.Label(label=f"{cur_vol}%", xalign=1)
        self._vol_lbl.get_style_context().add_class("vol-lbl")
        vol_row.pack_end(self._vol_lbl, False, False, 0)

        pbox.pack_start(vol_row, False, False, 0)
        return pbox

    def _on_vol_changed(self, scale):
        val = int(scale.get_value())
        if self._vol_lbl: self._vol_lbl.set_text(f"{val}%")
        set_volume(val)

    def _on_mute_clicked(self, _):
        toggle_audio_mute()
        time.sleep(0.15)
        m = is_audio_muted()
        if self._vol_mute_btn:
            self._vol_mute_btn.set_label("󰝟" if m else "󰕾")

    # ─── 3. Выбор устройства вывода звука (Надежное переключение) ─────────────
    def _make_audio_sinks(self, t):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        box.get_style_context().add_class("sink-box")

        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        self._sink_combo = Gtk.ComboBoxText()
        row.pack_start(self._sink_combo, True, True, 0)

        ref_btn = Gtk.Button(label=t["refresh_btn"])
        ref_btn.get_style_context().add_class("sink-refresh-btn")
        ref_btn.connect("clicked", lambda _: self._refresh_dynamic())
        row.pack_end(ref_btn, False, False, 0)
        box.pack_start(row, False, False, 0)

        self._sink_status_lbl = Gtk.Label(label="", xalign=0)
        self._sink_status_lbl.get_style_context().add_class("sink-status-lbl")
        box.pack_start(self._sink_status_lbl, False, False, 0)

        sinks = get_audio_sinks()
        def_s = get_default_sink()
        active_idx = 0
        for i, s in enumerate(sinks):
            s_name = s.get("name", "")
            s_desc = s.get("desc", s_name)
            self._sink_combo.append(s_name, s_desc[:30])
            if s_name == def_s:
                active_idx = i
                conn_txt = t["output_connected"]
                self._sink_status_lbl.set_text(f"● {conn_txt} {s.get('raw_desc', s_name)[:26]}")
        if sinks:
            self._sink_combo.set_active(active_idx)
        self._sink_combo.connect("changed", self._on_sink_changed)

        return box

    def _on_sink_changed(self, combo):
        sink_name = combo.get_active_id()
        if sink_name:
            switch_audio_sink(sink_name)
            time.sleep(0.2)
            self._refresh_dynamic()

    # ─── 4. Регулятор яркости ────────────────────────────────────────────────
    def _make_brightness(self):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        box.get_style_context().add_class("bright-box")

        icon_lbl = Gtk.Label(label="☀️")
        box.pack_start(icon_lbl, False, False, 0)

        cur_b = get_brightness()
        bright_adj = Gtk.Adjustment(value=cur_b, lower=5, upper=100, step_increment=2, page_increment=10)
        self._bright_scale = Gtk.Scale(orientation=Gtk.Orientation.HORIZONTAL, adjustment=bright_adj)
        self._bright_scale.set_draw_value(False)
        self._bright_scale.connect("value-changed", self._on_bright_changed)
        box.pack_start(self._bright_scale, True, True, 0)

        self._bright_lbl = Gtk.Label(label=f"{cur_b}%", xalign=1)
        self._bright_lbl.get_style_context().add_class("vol-lbl")
        box.pack_end(self._bright_lbl, False, False, 0)

        return box

    def _on_bright_changed(self, scale):
        val = int(scale.get_value())
        if self._bright_lbl: self._bright_lbl.set_text(f"{val}%")
        set_brightness(val)

    # ─── 5. Переключатели Wi-Fi / BT ─────────────────────────────────────────
    def _make_toggles(self, t):
        grid = Gtk.Grid()
        grid.set_row_spacing(4); grid.set_column_spacing(4)
        grid.set_margin_top(2); grid.set_margin_bottom(4)
        grid.set_column_homogeneous(True); grid.set_row_homogeneous(True)

        items = [
            ("wifi",     t["wifi"],     get_wifi_state(),     "on",         toggle_wifi),
            ("bt",       t["bt"],       get_bt_state(),       "on",         toggle_bt),
            ("airplane", t["airplane"], get_airplane_state(), "on-airplane",toggle_airplane),
            ("power",    t["power"],    get_power_profile() == "power-saver", "on-power", toggle_power_saver),
        ]
        positions = [(0,0),(0,1),(1,0),(1,1)]

        for (key, label, is_on, cls_on, action), (row, col) in zip(items, positions):
            btn = Gtk.Button(label=label)
            btn.get_style_context().add_class("toggle-btn")
            if is_on: btn.get_style_context().add_class(cls_on)
            self._tog_btns[key] = btn

            def _clicked(w, act=action):
                act()
                time.sleep(0.3)
                self._refresh_dynamic()

            btn.connect("clicked", _clicked)
            grid.attach(btn, col, row, 1, 1)

        return grid

    # ─── 6. Waybar Позиция ───────────────────────────────────────────────────
    def _make_waybar_pos(self, t):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        box.set_margin_top(2); box.set_margin_bottom(4)
        box.set_homogeneous(True)

        cur_pos = get_waybar_pos()
        positions = [
            ("top",    t["wb_top"]),
            ("bottom", t["wb_bottom"]),
            ("hide",   t["wb_hide"]),
        ]

        for p_key, label in positions:
            btn = Gtk.Button(label=label)
            btn.get_style_context().add_class("pos-btn")
            if p_key == cur_pos: btn.get_style_context().add_class("active-pos")
            btn.connect("clicked", self._on_pos_click, p_key)
            self._pos_btns[p_key] = btn
            box.pack_start(btn, True, True, 0)

        return box

    def _on_pos_click(self, btn, p_key):
        for k, b in self._pos_btns.items():
            b.get_style_context().remove_class("active-pos")
        btn.get_style_context().add_class("active-pos")
        run_bg(f'bash "{SCRIPTS_DIR}/waybar_position.sh" {p_key}')

    # ─── 7. Обои ─────────────────────────────────────────────────────────────
    def _make_wallpapers(self):
        wallpapers  = get_wallpapers()
        current_idx = get_current_wp_index()

        sw = Gtk.ScrolledWindow()
        sw.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        sw.set_min_content_height(100)
        sw.set_max_content_height(100)

        fb = Gtk.FlowBox()
        fb.set_max_children_per_line(3); fb.set_min_children_per_line(3)
        fb.set_selection_mode(Gtk.SelectionMode.NONE)
        fb.set_row_spacing(4); fb.set_column_spacing(4)

        self._wp_btns = []
        for idx, path in enumerate(wallpapers):
            btn = Gtk.Button()
            btn.get_style_context().add_class("wp-btn")
            if idx == current_idx: btn.get_style_context().add_class("active-wp")

            tp = thumb_path(path)
            if os.path.exists(tp):
                try:
                    pb  = GdkPixbuf.Pixbuf.new_from_file(tp)
                    img = Gtk.Image.new_from_pixbuf(pb)
                except Exception:
                    img = Gtk.Image.new_from_icon_name("image-missing", Gtk.IconSize.BUTTON)
            else:
                img = Gtk.Image.new_from_icon_name("image-loading", Gtk.IconSize.BUTTON)
                threading.Thread(target=self._load_thumb, args=(path, img), daemon=True).start()

            btn.add(img)
            btn.set_tooltip_text(os.path.basename(path))
            btn.connect("clicked", self._on_wp, path, idx)
            self._wp_btns.append(btn)
            fb.add(btn)

        sw.add(fb)
        return sw

    def _load_thumb(self, path, img):
        tp = ensure_thumb(path)
        if tp:
            def _up():
                try:
                    pb = GdkPixbuf.Pixbuf.new_from_file(tp)
                    img.set_from_pixbuf(pb)
                except Exception:
                    pass
                return False
            GLib.idle_add(_up)

    def _on_wp(self, btn, path, idx):
        for b in self._wp_btns:
            b.get_style_context().remove_class("active-wp")
        btn.get_style_context().add_class("active-wp")
        set_wallpaper(path, idx)

    # ─── 8. Стили и Темы ─────────────────────────────────────────────────────
    def _make_themes(self):
        sw = Gtk.ScrolledWindow()
        sw.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        sw.set_min_content_height(280)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        box.set_margin_top(2); box.set_margin_bottom(10)

        current_theme = get_active_theme()

        self._th_btns = {}
        for group in STYLE_GROUPS:
            title = group["title_ru"] if self.lang == "ru" else group["title_en"]
            grp_lbl = Gtk.Label(label=title, xalign=0)
            grp_lbl.get_style_context().add_class("section-label")
            grp_lbl.set_margin_top(4)
            box.pack_start(grp_lbl, False, False, 0)

            cat = group["category"]
            for substyle, label_en, label_ru, tooltip in group["styles"]:
                label = label_ru if self.lang == "ru" else label_en
                theme_key = f"{cat}_{substyle}"
                btn = Gtk.Button(label=label)
                btn.set_property("xalign", 0.05)
                btn.get_style_context().add_class("theme-btn")
                btn.set_tooltip_text(tooltip)
                if theme_key == current_theme:
                    btn.get_style_context().add_class("active-theme")

                btn.connect("clicked", self._on_theme, cat, substyle, theme_key)
                self._th_btns[theme_key] = btn
                box.pack_start(btn, False, False, 0)

        sw.add(box)
        return sw

    def _on_theme(self, btn, cat, substyle, theme_key):
        for b in self._th_btns.values():
            b.get_style_context().remove_class("active-theme")
        btn.get_style_context().add_class("active-theme")
        run_bg(f'bash "{SCRIPTS_DIR}/theme_ctl.sh" set {cat} {substyle}')


# ─── Main ─────────────────────────────────────────────────────────────────────
_sidebar = None

def main():
    global _sidebar

    os.makedirs(os.path.dirname(PID_FILE), exist_ok=True)
    open(PID_FILE, "w").write(str(os.getpid()))

    def _sig_exit(*_):
        try:
            os.remove(PID_FILE)
        except Exception:
            pass
        GLib.idle_add(Gtk.main_quit)

    signal.signal(signal.SIGTERM, _sig_exit)
    signal.signal(signal.SIGINT,  _sig_exit)

    GLib.unix_signal_add(GLib.PRIORITY_HIGH, signal.SIGUSR1,
                         lambda: (_sidebar.toggle() if _sidebar else None) or True)

    _sidebar = Sidebar()
    Gtk.main()

if __name__ == "__main__":
    main()
