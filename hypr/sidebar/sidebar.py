#!/usr/bin/env python3
"""
Hyprland Sidebar — боковая панель управления (GtkLayerShell)
Win+P → SIGUSR1 → быстрое открытие/закрытие
"""
import gi, os, sys, signal, subprocess, glob, threading, time, json

gi.require_version("Gtk",          "3.0")
gi.require_version("GdkPixbuf",    "2.0")
gi.require_version("GtkLayerShell","0.1")
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib, GtkLayerShell

# ─── Пути ────────────────────────────────────────────────────────────────────
HOME          = os.path.expanduser("~")
HYPR_DIR      = os.path.join(HOME, ".config", "hypr")
SCRIPTS_DIR   = os.path.join(HYPR_DIR, "scripts")
WALLPAPER_DIR = os.path.join(HOME, "wallpapers")
BUILTIN_WP    = os.path.join(HYPR_DIR, "assets", "wallpapers")
CACHE_DIR     = os.path.join(HOME, ".cache")
THUMB_DIR     = os.path.join(CACHE_DIR, "sidebar_thumbs")
PID_FILE      = os.path.join(CACHE_DIR, "sidebar.pid")
THEME_FILE    = os.path.join(CACHE_DIR, "sidebar_theme")
WP_IDX_FILE   = os.path.join(CACHE_DIR, "wallpaper_index")
MODE_FILE     = os.path.join(CACHE_DIR, "hypr_window_mode")
WAYBAR_POS    = os.path.join(CACHE_DIR, "waybar_position")

os.makedirs(THUMB_DIR, exist_ok=True)
os.makedirs(CACHE_DIR, exist_ok=True)

# ─── 4 Основных стиля с подстилями ──────────────────────────────────────────
STYLE_GROUPS = [
    {
        "title": "⬛  ЧЁРНЫЙ СТИЛЬ (FULL BLACK)",
        "category": "black",
        "styles": [
            ("solid",   "⬛ Чистый OLED",      "Абсолютный черный, 100% непрозрачный, без блюра"),
            ("stealth", "🌑 Графитовый",       "Матовый темно-серый, мягкое размытие"),
            ("glass",   "🧊 Дымчатое стекло",  "Полупрозрачный темный обсидиан с глубоким блюром"),
        ]
    },
    {
        "title": "⬜  БЕЛЫЙ СТИЛЬ (TOTAL WHITE)",
        "category": "white",
        "styles": [
            ("clean", "⬜ Чистый белый",       "Яркий контрастный белый, строгие рамки"),
            ("glass", "🥛 Белое стекло",       "Матовое белое акриловое стекло с блюром"),
            ("latte", "☕ Catppuccin Latte",   "Мягкий пастельный кремово-светлый стиль"),
        ]
    },
    {
        "title": "🍎  APPLE MACOS (CUPERTINO)",
        "category": "macos",
        "styles": [
            ("glass", "💎 macOS Liquid Glass", "Полная прозрачность, 4-проходный blur,  меню"),
            ("dark",  "🌘 macOS Dark Glass",   "Темное матовое стекло в стиле Sonoma"),
            ("light", "🌖 macOS Light Glass",  "Светлое матовое стекло с мягкой тенью"),
        ]
    },
    {
        "title": "⚡  КИБЕР & НОРД (CYBER / NORD)",
        "category": "cyber",
        "styles": [
            ("neon", "👾 Cyber Neon",          "Неоновый киберпанк (cyan/magenta), подсветка"),
            ("nord", "❄  Nord Arctic",         "Арктический нордический стиль с синими тонами"),
        ]
    }
]

# ─── GTK CSS ─────────────────────────────────────────────────────────────────
GTK_CSS = """
* { transition: none; font-family: "JetBrainsMono Nerd Font", "SF Pro Display", sans-serif; }
window {
    background-color: rgba(10, 10, 12, 0.96);
    color: #d0d0d0;
    border-radius: 14px;
    border-left: 1px solid rgba(255, 255, 255, 0.08);
}
.root-box { background-color: transparent; }
.section-label {
    color: #606570;
    font-size: 10px;
    font-weight: bold;
    padding: 10px 2px 4px 2px;
    letter-spacing: 1.2px;
}
.header-label {
    color: #ffffff;
    font-size: 15px;
    font-weight: bold;
    padding: 6px 2px 8px 2px;
}

/* Плеер */
.player-box {
    background-color: #131418;
    border-radius: 10px;
    border: 1px solid #20222a;
    padding: 8px;
    margin: 2px 0px 6px 0px;
}
.player-title {
    color: #ffffff;
    font-size: 11px;
    font-weight: bold;
}
.player-artist {
    color: #777c88;
    font-size: 10px;
}
.player-btn {
    background-color: transparent;
    color: #888899;
    border: none;
    border-radius: 16px;
    padding: 4px 8px;
    font-size: 14px;
    min-width: 32px;
    min-height: 32px;
}
.player-btn:hover {
    background-color: #222530;
    color: #ffffff;
}
.player-btn.play {
    color: #ffffff;
    font-size: 16px;
}

/* Переключатели Wi-Fi / BT */
.toggle-btn {
    background-color: #131418;
    color: #888c99;
    border-radius: 9px;
    border: 1px solid #20222a;
    padding: 8px 6px;
    font-size: 11px;
    min-height: 52px;
}
.toggle-btn:hover {
    background-color: #1a1b22;
    color: #cccccc;
}
.toggle-btn.on {
    background-color: #102416;
    color: #44dd66;
    border: 1px solid #1e4428;
}
.toggle-btn.on-airplane {
    background-color: #281a08;
    color: #ffaa00;
    border: 1px solid #503300;
}
.toggle-btn.on-power {
    background-color: #081d2e;
    color: #33aaff;
    border: 1px solid #104060;
}

/* Режимы окон */
.mode-btn {
    background-color: #131418;
    color: #999ea8;
    border-radius: 8px;
    border: 1px solid #20222a;
    padding: 7px 8px;
    font-size: 11px;
    min-height: 34px;
}
.mode-btn:hover {
    background-color: #1e2028;
    color: #ffffff;
}
.mode-btn.active-mode {
    background-color: #0d2847;
    color: #4da3ff;
    border: 1px solid #1a5bb0;
    font-weight: bold;
}

/* Кнопки стилей и тем */
.theme-btn {
    background-color: #131418;
    color: #a0a4b0;
    border-radius: 8px;
    border: 1px solid #20222a;
    padding: 7px 10px;
    font-size: 12px;
    min-height: 34px;
}
.theme-btn:hover {
    background-color: #1c1e26;
    color: #ffffff;
}
.theme-btn.active-theme {
    background-color: #162a4a;
    color: #64b5f6;
    border: 1px solid #2b5c9e;
    font-weight: bold;
}

/* Waybar позиция */
.pos-btn {
    background-color: #131418;
    color: #888c99;
    border-radius: 6px;
    border: 1px solid #20222a;
    padding: 5px 8px;
    font-size: 11px;
}
.pos-btn:hover {
    background-color: #1c1e26;
    color: #ffffff;
}
.pos-btn.active-pos {
    background-color: #222530;
    color: #ffffff;
    border: 1px solid #3d4455;
}

/* Обои */
.wp-btn {
    padding: 2px;
    border-radius: 6px;
    border: 2px solid transparent;
    background-color: transparent;
}
.wp-btn:hover { border-color: #444c5c; }
.wp-btn.active-wp { border-color: #4da3ff; }
scrollbar { background-color: transparent; min-width: 4px; }
scrollbar slider { background-color: #2a2e38; border-radius: 3px; min-width: 4px; }
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

def get_wallpapers():
    files = []
    # Сначала проверяем ~/wallpapers
    for ext in ("*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.PNG"):
        files += glob.glob(os.path.join(WALLPAPER_DIR, ext))
    # Если пусто — добавляем встроенные
    if not files and os.path.isdir(BUILTIN_WP):
        for ext in ("*.png", "*.jpg", "*.webp"):
            files += glob.glob(os.path.join(BUILTIN_WP, ext))
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
        pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(wp, 84, 52, False)
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

# ─── Статусы сети и железа ───────────────────────────────────────────────────
def get_wifi_state():
    out = run_out("rfkill list wifi")
    return "Soft blocked: no" in out

def get_bt_state():
    out = run_out("rfkill list bluetooth")
    lines = out.splitlines()
    for l in lines:
        if "Soft blocked:" in l:
            return "Soft blocked: no" in l
    return False

def get_airplane_state():
    return not get_wifi_state() and not get_bt_state()

def get_power_profile():
    return run_out("powerprofilesctl get")

def toggle_wifi():
    if get_wifi_state():
        run_bg("rfkill block wifi")
    else:
        run_bg("rfkill unblock wifi")

def toggle_bt():
    if get_bt_state():
        run_bg("rfkill block bluetooth")
    else:
        run_bg("rfkill unblock bluetooth")

def toggle_airplane():
    if get_airplane_state():
        run_bg("rfkill unblock all")
    else:
        run_bg("rfkill block all")

def toggle_power_saver():
    p = get_power_profile()
    if p == "power-saver":
        run_bg("powerprofilesctl set balanced")
    else:
        run_bg("powerprofilesctl set power-saver")

# ─── Плеер ───────────────────────────────────────────────────────────────────
def player_get_title():
    return run_out("playerctl metadata title 2>/dev/null") or "Ничего не играет"

def player_get_artist():
    return run_out("playerctl metadata artist 2>/dev/null") or "—"

def player_get_status():
    return run_out("playerctl status 2>/dev/null")

# ─── Класс Sidebar ───────────────────────────────────────────────────────────
class Sidebar:
    def __init__(self):
        self.visible   = True
        self._wp_btns  = []
        self._th_btns  = {}
        self._mode_btns= {}
        self._pos_btns = {}
        self._tog_btns = {}
        self._player_title_lbl  = None
        self._player_artist_lbl = None
        self._play_btn          = None
        self._refresh_timer     = None

        self.window = Gtk.Window(type=Gtk.WindowType.TOPLEVEL)
        self.window.set_title("sidebar")
        self.window.connect("destroy", self._quit)
        self.window.connect("key-press-event", self._on_key)

        # LayerShell
        GtkLayerShell.init_for_window(self.window)
        GtkLayerShell.set_layer(self.window, GtkLayerShell.Layer.TOP)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.RIGHT,  True)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.TOP,    True)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.BOTTOM, True)
        GtkLayerShell.set_exclusive_zone(self.window, 320)
        GtkLayerShell.set_namespace(self.window, "sidebar")
        GtkLayerShell.set_keyboard_mode(self.window, GtkLayerShell.KeyboardMode.ON_DEMAND)
        GtkLayerShell.set_margin(self.window, GtkLayerShell.Edge.TOP, 0)

        try:
            self.window.set_wmclass("sidebar", "Sidebar")
        except Exception:
            pass

        # Применяем CSS
        prov = Gtk.CssProvider()
        prov.load_from_data(GTK_CSS.encode())
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), prov, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        self._build_ui()
        self.window.show_all()

        # Таймер динамического обновления плеера и состояний
        self._refresh_timer = GLib.timeout_add(3000, self._refresh_dynamic)

    def toggle(self):
        GLib.idle_add(self._do_toggle)

    def _do_toggle(self):
        if self.visible:
            self.window.hide()
            self.visible = False
        else:
            self._refresh_dynamic()
            self.window.show_all()
            self.visible = True
        return False

    def _on_key(self, w, event):
        if event.keyval == Gdk.KEY_Escape:
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
            # Плеер
            title  = player_get_title()
            artist = player_get_artist()
            status = player_get_status()
            GLib.idle_add(self._update_player_ui, title, artist, status)

            # Переключатели
            states = {
                "wifi":     get_wifi_state(),
                "bt":       get_bt_state(),
                "airplane": get_airplane_state(),
                "power":    get_power_profile() == "power-saver",
            }
            mode = get_active_mode()
            theme = get_active_theme()
            pos = get_waybar_pos()
            GLib.idle_add(self._update_states_ui, states, mode, theme, pos)
        threading.Thread(target=_do, daemon=True).start()
        return True

    def _update_player_ui(self, title, artist, status):
        if self._player_title_lbl:
            self._player_title_lbl.set_text(title[:32] + "…" if len(title) > 32 else title)
        if self._player_artist_lbl:
            self._player_artist_lbl.set_text(artist[:30] if artist else "")
        if self._play_btn:
            icon = "⏸" if status == "Playing" else "▶"
            self._play_btn.set_label(icon)
        return False

    def _update_states_ui(self, states, active_mode, active_theme, waybar_pos):
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
            if states.get(key):
                btn.get_style_context().add_class(cls_on)
            else:
                btn.get_style_context().remove_class("on")
                btn.get_style_context().remove_class("on-airplane")
                btn.get_style_context().remove_class("on-power")

        # Режим окон
        for m_name, btn in self._mode_btns.items():
            if m_name == active_mode:
                btn.get_style_context().add_class("active-mode")
            else:
                btn.get_style_context().remove_class("active-mode")

        # Тема
        for th_key, btn in self._th_btns.items():
            if th_key == active_theme:
                btn.get_style_context().add_class("active-theme")
            else:
                btn.get_style_context().remove_class("active-theme")

        # Waybar позиция
        for p_name, btn in self._pos_btns.items():
            if p_name == waybar_pos:
                btn.get_style_context().add_class("active-pos")
            else:
                btn.get_style_context().remove_class("active-pos")

        return False

    # ─── UI ──────────────────────────────────────────────────────────────────
    def _build_ui(self):
        sw = Gtk.ScrolledWindow()
        sw.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        sw.set_size_request(310, -1)

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        root.get_style_context().add_class("root-box")
        root.set_border_width(12)

        # Заголовок
        root.pack_start(self._lbl("⚙  ПАНЕЛЬ УПРАВЛЕНИЯ", "header-label"), False, False, 0)

        # 1. Режим окон
        root.pack_start(self._lbl("РЕЖИМ ОКОН"), False, False, 0)
        root.pack_start(self._make_window_modes(), False, False, 0)

        # 2. Плеер
        root.pack_start(self._lbl("МУЗЫКА"), False, False, 0)
        root.pack_start(self._make_player(), False, False, 0)

        # 3. 2×2 Матрица переключателей
        root.pack_start(self._lbl("БЕСПРОВОДНАЯ СВЯЗЬ"), False, False, 0)
        root.pack_start(self._make_toggles(), False, False, 0)

        # 4. Waybar позиция
        root.pack_start(self._lbl("ПАНЕЛЬ WAYBAR"), False, False, 0)
        root.pack_start(self._make_waybar_pos(), False, False, 0)

        # 5. Обои
        root.pack_start(self._lbl("ОБОИ"), False, False, 0)
        root.pack_start(self._make_wallpapers(), False, False, 0)

        # 6. Стили и Темы
        root.pack_start(self._lbl("ДИЗАЙН И СТИЛИЗАЦИЯ"), False, False, 0)
        root.pack_start(self._make_themes(), True, True, 0)

        sw.add(root)
        self.window.add(sw)

    def _lbl(self, text, css="section-label"):
        l = Gtk.Label(label=text, xalign=0)
        l.get_style_context().add_class(css)
        return l

    # ─── 1. Режим окон ───────────────────────────────────────────────────────
    def _make_window_modes(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        box.set_margin_top(2)
        box.set_margin_bottom(6)

        current_mode = get_active_mode()

        modes = [
            ("tiling",  "▦  Плитка (Tiling)",             "Автоматическое разделение окон"),
            ("monocle", "⛶  На весь экран (с Waybar)",    "Окна развернуты на экран, Waybar виден"),
            ("windows", "🪟  Как в Windows (Плавающий)",   "Плавающие окна, свободное перемещение"),
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
        script = os.path.join(SCRIPTS_DIR, "window_mode.sh")
        run_bg(f'bash "{script}" {m_key}')

    # ─── 2. Плеер ────────────────────────────────────────────────────────────
    def _make_player(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        box.get_style_context().add_class("player-box")

        self._player_title_lbl = Gtk.Label(label=player_get_title(), xalign=0)
        self._player_title_lbl.get_style_context().add_class("player-title")
        self._player_title_lbl.set_max_width_chars(30)
        self._player_title_lbl.set_ellipsize(3)

        self._player_artist_lbl = Gtk.Label(label=player_get_artist(), xalign=0)
        self._player_artist_lbl.get_style_context().add_class("player-artist")
        self._player_artist_lbl.set_max_width_chars(30)
        self._player_artist_lbl.set_ellipsize(3)

        box.pack_start(self._player_title_lbl,  False, False, 0)
        box.pack_start(self._player_artist_lbl, False, False, 0)

        ctrl = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        ctrl.set_halign(Gtk.Align.CENTER)

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

        box.pack_start(ctrl, False, False, 0)
        return box

    # ─── 3. Переключатели ────────────────────────────────────────────────────
    def _make_toggles(self):
        grid = Gtk.Grid()
        grid.set_row_spacing(5)
        grid.set_column_spacing(5)
        grid.set_margin_top(2)
        grid.set_margin_bottom(6)
        grid.set_column_homogeneous(True)
        grid.set_row_homogeneous(True)

        items = [
            ("wifi",     "󰤨  Wi-Fi",       get_wifi_state(),     "on",         toggle_wifi),
            ("bt",       "󰂯  Bluetooth",   get_bt_state(),       "on",         toggle_bt),
            ("airplane", "✈  Авиарежим",   get_airplane_state(), "on-airplane",toggle_airplane),
            ("power",    "🔋 Экономия",    get_power_profile() == "power-saver", "on-power", toggle_power_saver),
        ]
        positions = [(0,0),(0,1),(1,0),(1,1)]

        for (key, label, is_on, cls_on, action), (row, col) in zip(items, positions):
            btn = Gtk.Button(label=label)
            btn.get_style_context().add_class("toggle-btn")
            if is_on:
                btn.get_style_context().add_class(cls_on)
            self._tog_btns[key] = btn

            def _clicked(w, act=action):
                act()
                time.sleep(0.3)
                self._refresh_dynamic()

            btn.connect("clicked", _clicked)
            grid.attach(btn, col, row, 1, 1)

        return grid

    # ─── 4. Waybar Позиция ───────────────────────────────────────────────────
    def _make_waybar_pos(self):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        box.set_margin_top(2)
        box.set_margin_bottom(6)
        box.set_homogeneous(True)

        cur_pos = get_waybar_pos()
        positions = [
            ("top",    "⬆ Вверху"),
            ("bottom", "⬇ Внизу"),
            ("hide",   "👁 Скрыть"),
        ]

        for p_key, label in positions:
            btn = Gtk.Button(label=label)
            btn.get_style_context().add_class("pos-btn")
            if p_key == cur_pos:
                btn.get_style_context().add_class("active-pos")
            btn.connect("clicked", self._on_pos_click, p_key)
            self._pos_btns[p_key] = btn
            box.pack_start(btn, True, True, 0)

        return box

    def _on_pos_click(self, btn, p_key):
        for k, b in self._pos_btns.items():
            b.get_style_context().remove_class("active-pos")
        btn.get_style_context().add_class("active-pos")
        script = os.path.join(SCRIPTS_DIR, "waybar_position.sh")
        run_bg(f'bash "{script}" {p_key}')

    # ─── 5. Обои ─────────────────────────────────────────────────────────────
    def _make_wallpapers(self):
        wallpapers  = get_wallpapers()
        current_idx = get_current_wp_index()

        sw = Gtk.ScrolledWindow()
        sw.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        sw.set_min_content_height(140)
        sw.set_max_content_height(140)

        fb = Gtk.FlowBox()
        fb.set_max_children_per_line(3)
        fb.set_min_children_per_line(3)
        fb.set_selection_mode(Gtk.SelectionMode.NONE)
        fb.set_row_spacing(4); fb.set_column_spacing(4)
        fb.set_margin_top(2);  fb.set_margin_bottom(4)

        self._wp_btns = []
        for idx, path in enumerate(wallpapers):
            btn = Gtk.Button()
            btn.get_style_context().add_class("wp-btn")
            if idx == current_idx:
                btn.get_style_context().add_class("active-wp")

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

    # ─── 6. Стили и Темы ─────────────────────────────────────────────────────
    def _make_themes(self):
        sw = Gtk.ScrolledWindow()
        sw.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        sw.set_min_content_height(340)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        box.set_margin_top(2)
        box.set_margin_bottom(12)

        current_theme = get_active_theme()

        self._th_btns = {}
        for group in STYLE_GROUPS:
            # Заголовок группы
            grp_lbl = Gtk.Label(label=group["title"], xalign=0)
            grp_lbl.get_style_context().add_class("section-label")
            grp_lbl.set_margin_top(6)
            box.pack_start(grp_lbl, False, False, 0)

            cat = group["category"]
            for substyle, label, tooltip in group["styles"]:
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
        script = os.path.join(SCRIPTS_DIR, "theme_ctl.sh")
        run_bg(f'bash "{script}" set {cat} {substyle}')


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
