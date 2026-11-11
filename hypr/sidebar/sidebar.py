#!/usr/bin/env python3
"""
Hyprland Sidebar — правая панель (daemon-режим)
Win+P → SIGUSR1 → toggle
"""
import gi, os, sys, signal, subprocess, glob, threading, time, json

gi.require_version("Gtk",          "3.0")
gi.require_version("GdkPixbuf",    "2.0")
gi.require_version("GtkLayerShell","0.1")
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib, GtkLayerShell

# ─── Пути ────────────────────────────────────────────────────────────────────
HOME          = os.path.expanduser("~")
WALLPAPER_DIR = os.path.join(HOME, "wallpapers")
THUMB_DIR     = os.path.join(HOME, ".cache", "sidebar_thumbs")
PID_FILE      = os.path.join(HOME, ".cache", "sidebar.pid")
THEME_FILE    = os.path.join(HOME, ".cache", "sidebar_theme")
WP_IDX_FILE   = os.path.join(HOME, ".cache", "wallpaper_index")
WAYBAR_CSS    = os.path.join(HOME, ".config", "waybar", "style.css")
WAYBAR_CFG    = os.path.join(HOME, ".config", "waybar", "config")

os.makedirs(THUMB_DIR, exist_ok=True)

# ─── 22 темы ─────────────────────────────────────────────────────────────────
THEMES = {
    "⬛  Total Black":   dict(wb_bg="rgba(0,0,0,0.96)",          wb_text="#bbbbbb", wb_active="#ffffff", wb_accent="#444444", hr_a="383838", hr_i="0d0d0d"),
    "⬜  Total White":   dict(wb_bg="rgba(248,248,248,0.97)",     wb_text="#222222", wb_active="#000000", wb_accent="#0055cc", hr_a="0055cc", hr_i="cccccc"),
    "🌫  Ash":           dict(wb_bg="rgba(28,28,28,0.93)",        wb_text="#999999", wb_active="#dddddd", wb_accent="#666666", hr_a="555555", hr_i="222222"),
    "🌑  Void":          dict(wb_bg="rgba(2,2,2,0.98)",           wb_text="#444444", wb_active="#888888", wb_accent="#333333", hr_a="222222", hr_i="050505"),
    "🌊  Ocean":         dict(wb_bg="rgba(5,18,38,0.92)",         wb_text="#7ecfff", wb_active="#ffffff", wb_accent="#00aaff", hr_a="00aaff", hr_i="051226"),
    "🧊  Ice":           dict(wb_bg="rgba(10,30,55,0.93)",        wb_text="#aaddff", wb_active="#ffffff", wb_accent="#55bbff", hr_a="55bbff", hr_i="0a1e37"),
    "🌃  Midnight":      dict(wb_bg="rgba(5,5,25,0.95)",          wb_text="#6677cc", wb_active="#aabbff", wb_accent="#4455bb", hr_a="4455bb", hr_i="050516"),
    "🫐  Blueberry":     dict(wb_bg="rgba(15,10,40,0.94)",        wb_text="#9988dd", wb_active="#ccbbff", wb_accent="#7766cc", hr_a="7766cc", hr_i="0f0a28"),
    "🧛  Dracula":       dict(wb_bg="rgba(18,10,28,0.93)",        wb_text="#bd93f9", wb_active="#f8f8f2", wb_accent="#ff79c6", hr_a="ff79c6", hr_i="28143c"),
    "🔮  Amethyst":      dict(wb_bg="rgba(20,8,35,0.94)",         wb_text="#cc88ff", wb_active="#ffffff", wb_accent="#9944ee", hr_a="9944ee", hr_i="140823"),
    "🌸  Sakura":        dict(wb_bg="rgba(30,8,25,0.93)",         wb_text="#ff99cc", wb_active="#ffddee", wb_accent="#ee5599", hr_a="ee5599", hr_i="1e0819"),
    "🌿  Forest":        dict(wb_bg="rgba(5,18,8,0.93)",          wb_text="#66cc77", wb_active="#aaffbb", wb_accent="#33aa44", hr_a="33aa44", hr_i="050f06"),
    "🐉  Matrix":        dict(wb_bg="rgba(0,8,0,0.96)",           wb_text="#00cc00", wb_active="#00ff00", wb_accent="#008800", hr_a="00bb00", hr_i="000800"),
    "🍃  Mint":          dict(wb_bg="rgba(5,22,20,0.93)",         wb_text="#66ddcc", wb_active="#aaffee", wb_accent="#22bbaa", hr_a="22bbaa", hr_i="050f0e"),
    "🌅  Sunset":        dict(wb_bg="rgba(22,8,3,0.93)",          wb_text="#ffaa55", wb_active="#ffffff", wb_accent="#ff6600", hr_a="ff6600", hr_i="321005"),
    "🍂  Autumn":        dict(wb_bg="rgba(25,10,2,0.94)",         wb_text="#dd8844", wb_active="#ffcc88", wb_accent="#cc5522", hr_a="cc5522", hr_i="190a02"),
    "🌋  Lava":          dict(wb_bg="rgba(20,3,3,0.95)",          wb_text="#ff5533", wb_active="#ffaa88", wb_accent="#cc2200", hr_a="cc2200", hr_i="140202"),
    "🌼  Gold":          dict(wb_bg="rgba(20,15,2,0.94)",         wb_text="#ddbb44", wb_active="#ffee88", wb_accent="#aa8800", hr_a="aa8800", hr_i="140f02"),
    "🌈  Nord":          dict(wb_bg="rgba(20,24,33,0.93)",        wb_text="#88c0d0", wb_active="#eceff4", wb_accent="#5e81ac", hr_a="5e81ac", hr_i="141821"),
    "🎮  Cyberpunk":     dict(wb_bg="rgba(5,0,15,0.95)",          wb_text="#ff00aa", wb_active="#ffff00", wb_accent="#00ffcc", hr_a="ff00aa", hr_i="05000f"),
    "☕  Espresso":      dict(wb_bg="rgba(18,10,6,0.95)",         wb_text="#c9a87c", wb_active="#ffe0b2", wb_accent="#8d6240", hr_a="8d6240", hr_i="120a06"),
    "🩶  Gruvbox":       dict(wb_bg="rgba(20,18,14,0.94)",        wb_text="#d5c4a1", wb_active="#fbf1c7", wb_accent="#d79921", hr_a="d79921", hr_i="14120e"),
}

# ─── GTK CSS ─────────────────────────────────────────────────────────────────
GTK_CSS = """
* { transition: none; }
window {
    background-color: #0a0a0a;
    color: #d0d0d0;
    border-radius: 12px;
}
.root-box { background-color: #0a0a0a; }
.section-label {
    color: #454545;
    font-size: 10px;
    font-weight: bold;
    padding: 10px 2px 5px 2px;
    letter-spacing: 1.5px;
}
.header-label {
    color: #e0e0e0;
    font-size: 14px;
    font-weight: bold;
    padding: 10px 2px 10px 2px;
}
/* Плеер */
.player-box {
    background-color: #111111;
    border-radius: 10px;
    border: 1px solid #1e1e1e;
    padding: 6px;
    margin: 2px 0px;
}
.player-title {
    color: #e0e0e0;
    font-size: 11px;
    font-weight: bold;
}
.player-artist {
    color: #666666;
    font-size: 10px;
}
.player-btn {
    background-color: transparent;
    color: #888888;
    border: none;
    border-radius: 18px;
    padding: 4px 8px;
    font-size: 14px;
    min-width: 30px;
    min-height: 30px;
}
.player-title {
    color: #e0e0e0;
    font-size: 12px;
    font-weight: bold;
}
.player-artist {
    color: #666666;
    font-size: 11px;
}
.player-btn {
    background-color: transparent;
    color: #888888;
    border: none;
    border-radius: 20px;
    padding: 6px 10px;
    font-size: 16px;
    min-width: 36px;
    min-height: 36px;
}
.player-btn:hover {
    background-color: #1e1e1e;
    color: #ffffff;
}
.player-btn.play {
    color: #cccccc;
    font-size: 18px;
}
/* 2×2 матрица */
.toggle-btn {
    background-color: #111111;
    color: #777777;
    border-radius: 10px;
    border: 1px solid #1e1e1e;
    padding: 10px 6px;
    font-size: 11px;
    min-height: 60px;
    min-width: 120px;
}
.toggle-btn:hover {
    background-color: #1a1a1a;
    color: #bbbbbb;
}
.toggle-btn.on {
    background-color: #0f1f10;
    color: #55cc66;
    border: 1px solid #224422;
}
.toggle-btn.on-airplane {
    background-color: #1a1000;
    color: #ddaa00;
    border: 1px solid #443300;
}
.toggle-btn.on-power {
    background-color: #001520;
    color: #2299dd;
    border: 1px solid #004466;
}
/* Обои и темы */
.action-btn {
    background-color: #161616;
    color: #b0b0b0;
    border-radius: 8px;
    border: 1px solid #242424;
    padding: 8px 12px;
    font-size: 13px;
    min-height: 38px;
}
.action-btn:hover { background-color: #202020; color: #ffffff; }
.theme-btn {
    background-color: #111111;
    color: #999999;
    border-radius: 7px;
    border: 1px solid #1e1e1e;
    padding: 7px 12px;
    font-size: 12px;
    min-height: 36px;
}
.theme-btn:hover { background-color: #1a1a1a; color: #dddddd; }
.theme-btn.active-theme {
    background-color: #0f1a2a;
    color: #7eb2ff;
    border: 1px solid #2a4a88;
}
.wp-btn {
    padding: 2px;
    border-radius: 5px;
    border: 2px solid transparent;
    background-color: transparent;
}
.wp-btn:hover { border-color: #444444; }
.wp-btn.active-wp { border-color: #7eb2ff; }
scrollbar { background-color: #0a0a0a; min-width: 3px; }
scrollbar slider { background-color: #2a2a2a; border-radius: 3px; min-width: 3px; }
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
    except:
        return ""

def get_wallpapers():
    files = []
    for ext in ("*.jpg","*.jpeg","*.png","*.webp","*.JPG","*.PNG"):
        files += glob.glob(os.path.join(WALLPAPER_DIR, ext))
    return sorted(set(files))

def get_current_wp_index():
    try:
        return int(open(WP_IDX_FILE).read().strip())
    except:
        return 0

def set_wallpaper(path, idx):
    try:
        open(WP_IDX_FILE, "w").write(str(idx))
    except:
        pass
    run_bg(f'pkill swaybg; sleep 0.15; swaybg -i "{path}" -m stretch')

def thumb_path(wp):
    return os.path.join(THUMB_DIR, os.path.basename(wp) + ".thumb.png")

def ensure_thumb(wp):
    tp = thumb_path(wp)
    if os.path.exists(tp):
        return tp
    try:
        pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(wp, 82, 54, False)
        pb.savev(tp, "png", [], [])
        return tp
    except:
        return None

def apply_theme(name):
    t = THEMES[name]
    try:
        open(THEME_FILE, "w").write(name)
    except:
        pass
    try:
        open(WAYBAR_CSS, "w").write(build_waybar_css(t))
        # Перезагружаем waybar, а потом скрываем/показываем сайдбар,
        # чтобы он пересоздал свой слой ПОСЛЕ waybar и не вытеснял его с верхнего края.
        run_bg("pkill -USR2 waybar; sleep 1; kill -USR1 $(cat ~/.cache/sidebar.pid 2>/dev/null); sleep 0.3; kill -USR1 $(cat ~/.cache/sidebar.pid 2>/dev/null)")
    except Exception as e:
        print(f"[theme css] {e}", flush=True)
    run_bg(f'hyprctl keyword general:col.active_border "rgb({t["hr_a"]})"')
    run_bg(f'hyprctl keyword general:col.inactive_border "rgb({t["hr_i"]})"')

def build_waybar_css(t):
    return f"""/* sidebar-theme */
* {{ font-family: "JetBrainsMono Nerd Font","Font Awesome 7 Free",sans-serif;
     font-size: 13px; min-height: 0; border: none; border-radius: 0; }}
window#waybar {{ background: {t["wb_bg"]}; color: {t["wb_text"]}; border-radius: 12px; transition: none; }}
#workspaces {{ padding: 0 6px; }}
#workspaces button {{ padding: 0 7px; color: #454545; background: transparent;
    border-radius: 6px; font-size: 12px; min-width: 24px; }}
#workspaces button.active {{ color: {t["wb_active"]}; background: rgba(126,178,255,0.10);
    border-bottom: 2px solid {t["wb_accent"]}; border-radius: 6px 6px 0 0; }}
#workspaces button:hover {{ color: #aaaaaa; background: rgba(255,255,255,0.06); }}
#workspaces button.urgent {{ color: #ff6e6e; background: rgba(255,110,110,0.15); }}
#window {{ color: {t["wb_text"]}; padding: 0 10px; font-size: 12px; font-style: italic; }}
#clock {{ color: {t["wb_active"]}; font-weight: bold; font-size: 14px; padding: 0 16px; }}
#pulseaudio,#network,#battery,#tray,#custom-power {{ padding: 0 10px; color: {t["wb_text"]}; }}
#pulseaudio:hover,#network:hover,#battery:hover,#custom-power:hover {{
    color: {t["wb_active"]}; background: rgba(255,255,255,0.06); border-radius: 6px; }}
#pulseaudio.muted {{ color: #555555; }}
#network.disconnected {{ color: #ff6e6e; }}
#battery.warning {{ color: #ffcc44; }}
#battery.critical {{ color: #ff6e6e; animation: blink 1s linear infinite; }}
#battery.charging {{ color: #88ddaa; }}
@keyframes blink {{ to {{ color: {t["wb_active"]}; }} }}
#tray {{ padding: 0 8px; }}
#custom-power {{ color: {t["wb_text"]}; font-size: 15px; padding: 0 14px; }}
#custom-power:hover {{ color: #ff6e6e; background: rgba(255,110,110,0.10); border-radius: 6px; }}
tooltip {{ background: rgba(0,0,0,0.92); border: 1px solid #2a2a2a;
           border-radius: 8px; color: {t["wb_active"]}; font-size: 12px; }}
"""

# ─── Статус переключателей ────────────────────────────────────────────────────
def get_wifi_state():
    out = run_out("rfkill list wifi")
    return "Soft blocked: no" in out

def get_bt_state():
    out = run_out("rfkill list bluetooth")
    lines = out.splitlines()
    for i, l in enumerate(lines):
        if "Soft blocked:" in l:
            return "Soft blocked: no" in l
    return False

def get_airplane_state():
    # Самолётный режим = wifi И bluetooth заблокированы
    return not get_wifi_state() and not get_bt_state()

def get_power_profile():
    out = run_out("powerprofilesctl get")
    return out  # "balanced", "power-saver", "performance"

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
    return run_out("playerctl metadata title 2>/dev/null") or "—"

def player_get_artist():
    return run_out("playerctl metadata artist 2>/dev/null") or ""

def player_get_status():
    return run_out("playerctl status 2>/dev/null")  # Playing / Paused / Stopped

# ─── Waybar margin ────────────────────────────────────────────────────────────
def get_waybar_height_px():
    """Возвращает высоту waybar + margin-top в пикселях"""
    try:
        d = json.load(open(WAYBAR_CFG))
        pos = d.get("position", "top")
        if pos not in ("top", "bottom"):
            return 0
        h  = d.get("height", 36)
        mt = d.get("margin-top", 0) if pos == "top" else 0
        mb = d.get("margin-bottom", 0) if pos == "bottom" else 0
        return h + mt + mb + 8   # +8px запас
    except:
        return 48

# ─── Sidebar ─────────────────────────────────────────────────────────────────
class Sidebar:
    def __init__(self):
        self.visible   = True
        self._wp_btns  = []
        self._th_btns  = {}
        self._tog_btns = {}   # name → button
        self._player_title_lbl  = None
        self._player_artist_lbl = None
        self._play_btn          = None
        self._refresh_timer     = None

        self.window = Gtk.Window(type=Gtk.WindowType.TOPLEVEL)
        self.window.set_title("sidebar")
        self.window.connect("destroy", self._quit)
        self.window.connect("key-press-event", self._on_key)

        # LayerShell — панель строго справа, резервирует место (exclusive zone),
        # плиточные окна сдвигаются влево, сайдбар не съезжает.
        GtkLayerShell.init_for_window(self.window)
        GtkLayerShell.set_layer(self.window, GtkLayerShell.Layer.TOP)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.RIGHT,  True)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.TOP,    True)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.BOTTOM, True)
        GtkLayerShell.set_exclusive_zone(self.window, 295)
        GtkLayerShell.set_namespace(self.window, "sidebar")
        GtkLayerShell.set_keyboard_mode(self.window, GtkLayerShell.KeyboardMode.ON_DEMAND)

        # Без отступа сверху — панель на одном уровне с верхним краем экрана,
        # как и обычные окна. exlusive_zone zelf отожмёт плиточные окна вправо.
        GtkLayerShell.set_margin(self.window, GtkLayerShell.Edge.TOP, 0)

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
        self.window.show_all()

        # Обновляем плеер и toggles каждые 3 секунды
        self._refresh_timer = GLib.timeout_add(3000, self._refresh_dynamic)

    # ── Signals ──────────────────────────────────────────────────────────────
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
        except:
            pass
        Gtk.main_quit()

    # ── Динамическое обновление ───────────────────────────────────────────────
    def _refresh_dynamic(self):
        """Обновляет плеер и статусы кнопок"""
        def _do():
            # Плеер
            if self._player_title_lbl:
                title  = player_get_title()
                artist = player_get_artist()
                status = player_get_status()
                GLib.idle_add(self._update_player_ui, title, artist, status)
            # Toggles
            states = {
                "wifi":     get_wifi_state(),
                "bt":       get_bt_state(),
                "airplane": get_airplane_state(),
                "power":    get_power_profile() == "power-saver",
            }
            GLib.idle_add(self._update_toggle_ui, states)
        threading.Thread(target=_do, daemon=True).start()
        return True  # продолжать таймер

    def _update_player_ui(self, title, artist, status):
        if self._player_title_lbl:
            self._player_title_lbl.set_text(title[:32] + "…" if len(title) > 32 else title)
        if self._player_artist_lbl:
            self._player_artist_lbl.set_text(artist[:30] if artist else "")
        if self._play_btn:
            icon = "⏸" if status == "Playing" else "▶"
            self._play_btn.set_label(icon)
        return False

    def _update_toggle_ui(self, states):
        mapping = {
            "wifi":     ("wifi",     "on",         "on"),
            "bt":       ("bt",       "on",         "on"),
            "airplane": ("airplane", "on-airplane","on-airplane"),
            "power":    ("power",    "on-power",   "on-power"),
        }
        for key, (bname, cls_on, _) in mapping.items():
            btn = self._tog_btns.get(bname)
            if not btn:
                continue
            if states.get(key):
                btn.get_style_context().add_class(cls_on)
            else:
                btn.get_style_context().remove_class("on")
                btn.get_style_context().remove_class("on-airplane")
                btn.get_style_context().remove_class("on-power")
        return False

    # ── UI ───────────────────────────────────────────────────────────────────
    def _build_ui(self):
        sw = Gtk.ScrolledWindow()
        sw.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        sw.set_size_request(295, -1)

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        root.get_style_context().add_class("root-box")
        root.set_border_width(10)

        root.pack_start(self._lbl("⚙  Настройки", "header-label"), False, False, 0)

        # Плеер
        root.pack_start(self._lbl("МУЗЫКА"),      False, False, 0)
        root.pack_start(self._make_player(),       False, False, 0)

        # 2×2 матрица
        root.pack_start(self._lbl("УПРАВЛЕНИЕ"),  False, False, 0)
        root.pack_start(self._make_toggles(),      False, False, 0)

        # Обои
        root.pack_start(self._lbl("ОБОИ"),        False, False, 0)
        root.pack_start(self._make_wallpapers(),   False, False, 0)

        # Темы
        root.pack_start(self._lbl("ТЕМА"),        False, False, 0)
        root.pack_start(self._make_themes(),       True,  True,  0)

        sw.add(root)
        self.window.add(sw)

    def _lbl(self, text, css="section-label"):
        l = Gtk.Label(label=text, xalign=0)
        l.get_style_context().add_class(css)
        return l

    # ── Плеер ────────────────────────────────────────────────────────────────
    def _make_player(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        box.get_style_context().add_class("player-box")
        box.set_margin_top(2); box.set_margin_bottom(4)

        self._player_title_lbl = Gtk.Label(label=player_get_title(), xalign=0)
        self._player_title_lbl.get_style_context().add_class("player-title")
        self._player_title_lbl.set_max_width_chars(28)
        self._player_title_lbl.set_ellipsize(3)  # PANGO_ELLIPSIZE_END

        self._player_artist_lbl = Gtk.Label(label=player_get_artist(), xalign=0)
        self._player_artist_lbl.get_style_context().add_class("player-artist")
        self._player_artist_lbl.set_max_width_chars(28)
        self._player_artist_lbl.set_ellipsize(3)

        box.pack_start(self._player_title_lbl,  False, False, 0)
        box.pack_start(self._player_artist_lbl, False, False, 0)

        # Кнопки управления
        ctrl = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
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

    # ── 2×2 Матрица переключателей ───────────────────────────────────────────
    def _make_toggles(self):
        grid = Gtk.Grid()
        grid.set_row_spacing(5)
        grid.set_column_spacing(5)
        grid.set_margin_top(4); grid.set_margin_bottom(4)
        grid.set_column_homogeneous(True)
        grid.set_row_homogeneous(True)

        wifi_on     = get_wifi_state()
        bt_on       = get_bt_state()
        airplane_on = get_airplane_state()
        power_on    = get_power_profile() == "power-saver"

        items = [
            ("wifi",     "󰤨  Сеть",          wifi_on,     "on",         toggle_wifi),
            ("bt",       "󰂯  Bluetooth",      bt_on,       "on",         toggle_bt),
            ("airplane", "✈  Авиарежим",      airplane_on, "on-airplane",toggle_airplane),
            ("power",    "🔋 Экономия",       power_on,    "on-power",   toggle_power_saver),
        ]
        positions = [(0,0),(0,1),(1,0),(1,1)]

        for (key, label, is_on, cls_on, action), (row, col) in zip(items, positions):
            btn = Gtk.Button(label=label)
            btn.get_style_context().add_class("toggle-btn")
            if is_on:
                btn.get_style_context().add_class(cls_on)
            self._tog_btns[key] = btn

            def _clicked(w, act=action, k=key, c=cls_on):
                act()
                time.sleep(0.3)
                # Обновляем состояние
                states = {
                    "wifi":     get_wifi_state(),
                    "bt":       get_bt_state(),
                    "airplane": get_airplane_state(),
                    "power":    get_power_profile() == "power-saver",
                }
                GLib.idle_add(self._update_toggle_ui, states)

            btn.connect("clicked", _clicked)
            grid.attach(btn, col, row, 1, 1)

        return grid

    # ── Обои ─────────────────────────────────────────────────────────────────
    def _make_wallpapers(self):
        wallpapers  = get_wallpapers()
        current_idx = get_current_wp_index()

        sw = Gtk.ScrolledWindow()
        sw.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        sw.set_min_content_height(185)
        sw.set_max_content_height(185)

        fb = Gtk.FlowBox()
        fb.set_max_children_per_line(3)
        fb.set_min_children_per_line(3)
        fb.set_selection_mode(Gtk.SelectionMode.NONE)
        fb.set_row_spacing(4); fb.set_column_spacing(4)
        fb.set_margin_top(4);  fb.set_margin_bottom(4)

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
                except:
                    img = Gtk.Image.new_from_icon_name("image-missing", Gtk.IconSize.BUTTON)
            else:
                img = Gtk.Image.new_from_icon_name("image-loading", Gtk.IconSize.DIALOG)
                threading.Thread(target=self._load_thumb, args=(path, btn, img), daemon=True).start()

            btn.add(img)
            btn.set_tooltip_text(os.path.basename(path))
            btn.connect("clicked", self._on_wp, path, idx)
            self._wp_btns.append(btn)
            fb.add(btn)

        sw.add(fb)
        return sw

    def _load_thumb(self, path, btn, img):
        tp = ensure_thumb(path)
        if tp:
            def _up():
                try:
                    pb = GdkPixbuf.Pixbuf.new_from_file(tp)
                    img.set_from_pixbuf(pb)
                except:
                    pass
                return False
            GLib.idle_add(_up)

    def _on_wp(self, btn, path, idx):
        for b in self._wp_btns:
            b.get_style_context().remove_class("active-wp")
        btn.get_style_context().add_class("active-wp")
        set_wallpaper(path, idx)

    # ── Темы ─────────────────────────────────────────────────────────────────
    def _make_themes(self):
        sw = Gtk.ScrolledWindow()
        sw.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        sw.set_min_content_height(280)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        box.set_margin_top(4); box.set_margin_bottom(14)

        current = ""
        try:
            current = open(THEME_FILE).read().strip()
        except:
            pass

        self._th_btns = {}
        for name in THEMES:
            btn = Gtk.Button(label=name)
            btn.set_property("xalign", 0.05)
            btn.get_style_context().add_class("theme-btn")
            if name == current:
                btn.get_style_context().add_class("active-theme")
            btn.connect("clicked", self._on_theme, name)
            self._th_btns[name] = btn
            box.pack_start(btn, False, False, 0)

        sw.add(box)
        return sw

    def _on_theme(self, btn, name):
        for b in self._th_btns.values():
            b.get_style_context().remove_class("active-theme")
        btn.get_style_context().add_class("active-theme")
        threading.Thread(target=apply_theme, args=(name,), daemon=True).start()


# ─── Main ─────────────────────────────────────────────────────────────────────
_sidebar = None

def main():
    global _sidebar

    os.makedirs(os.path.dirname(PID_FILE), exist_ok=True)
    open(PID_FILE, "w").write(str(os.getpid()))

    def _sig_exit(*_):
        try:
            os.remove(PID_FILE)
        except:
            pass
        GLib.idle_add(Gtk.main_quit)

    signal.signal(signal.SIGTERM, _sig_exit)
    signal.signal(signal.SIGINT,  _sig_exit)

    GLib.unix_signal_add(GLib.PRIORITY_HIGH, signal.SIGUSR1,
                         lambda: (_sidebar.toggle() if _sidebar else None) or True)
    GLib.unix_signal_add(GLib.PRIORITY_HIGH, signal.SIGTERM,
                         lambda: (
                             os.remove(PID_FILE) if os.path.exists(PID_FILE) else None,
                             Gtk.main_quit()
                         ) or True)

    _sidebar = Sidebar()
    Gtk.main()

if __name__ == "__main__":
    main()
