-- ==============================================================================
-- HYPRLAND LUA CONFIGURATION — CYBERPUNK HUD PROFILE (Arch Tech / Circuit)
-- ==============================================================================

local home = os.getenv("HOME") or "/home/linux"

------------------
---- MONITORS ----
------------------
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("GTK_USE_PORTAL", "1")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("GDK_BACKEND", "wayland")
hl.env("QT_WAYLAND_FORCE_DPI", "physical")
hl.env("FREETYPE_PROPERTIES", "truetype:interpreter-version=35")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function ()
    hl.exec_cmd(home .. "/.config/hypr/scripts/init_desktop.sh")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgb(ff003c)", "rgb(00f0ff)" }, angle = 45 },
            inactive_border = "rgb(140926)",
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 2,
        rounding_power = 2,
        active_opacity   = 0.94,
        inactive_opacity = 0.85,
        fullscreen_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 24,
            render_power = 3,
            color        = "rgba(ff003c73)",
            color_inactive = "rgba(00000099)",
        },

        blur = {
            enabled  = true,
            size     = 6,
            passes   = 3,
            vibrancy = 0.35,
            contrast = 1.15,
        },
    },

    animations = {
        enabled = true,
    },

    input = {
        kb_layout = "us,ru",
        kb_variant = "",
        kb_options = "grp:alt_shift_toggle",
        follow_mouse = 1,
        touchpad = {
            natural_scroll = false,
        },
    },

    dwindle = {
        preserve_split = true,
    },
})

--------------------
---- ANIMATIONS ----
--------------------
hl.curve("cyberFast", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "cyberFast", style = "popin 90%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "cyberFast", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "cyberFast", style = "popin 90%" })
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "cyberFast", style = "slide" })

-- Подключение активной темы оформления (Cyber Neon, Nord)
pcall(dofile, home .. "/.config/hypr/current_theme.lua")

---------------------
---- MY PROGRAMS ----
---------------------
local mainMod     = "SUPER"
local terminal    = "kitty"
local fileManager = home .. "/.config/hypr/scripts/file_manager.sh"
local menu        = "rofi -show drun"

---------------------
---- KEYBINDINGS ----
---------------------
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/file_manager.sh yazi"))
hl.bind(mainMod .. " + ALT + E",   hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/file_manager.sh gui"))
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + space",  hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())

-- Режимы окон
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/window_mode.sh cycle"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/window_mode.sh tiling"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/window_mode.sh floating"))
hl.bind(mainMod .. " + V",         hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/window_mode.sh toggle_floating"))
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen(0))

-- Скрытие окон в фон (Special workspace / Minimized)
hl.bind(mainMod .. " + H",             hl.dsp.window.move({ workspace = "special:minimized" }))
hl.bind(mainMod .. " + U",             hl.dsp.workspace.toggle_special("minimized"))
hl.bind(mainMod .. " + minus",         hl.dsp.workspace.toggle_special("minimized"))
hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.window.move({ workspace = "special:minimized" }))

-- Сайдбар управления (Win+P, Ctrl+P, Super+Ctrl+P)
hl.bind(mainMod .. " + P",        hl.dsp.exec_cmd(home .. "/.config/hypr/sidebar/toggle.sh"))
hl.bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd(home .. "/.config/hypr/sidebar/toggle.sh"))
hl.bind("CTRL + P",               hl.dsp.exec_cmd(home .. "/.config/hypr/sidebar/toggle.sh"))

-- Waybar позиция
hl.bind(mainMod .. " + ALT + P",    hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/waybar_position.sh toggle"))
hl.bind(mainMod .. " + ALT + up",   hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/waybar_position.sh top"))
hl.bind(mainMod .. " + ALT + down", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/waybar_position.sh bottom"))
hl.bind(mainMod .. " + ALT + H",    hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/waybar_position.sh hide"))

-- Смена обоев
hl.bind(mainMod .. " + bracketright", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/wallpaper_cycle.sh next"))
hl.bind(mainMod .. " + bracketleft",  hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/wallpaper_cycle.sh prev"))

-- Навигация и фокус
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Рабочие столы (1..10)
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Перемещение и изменение размера окон мышью
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Изменение размера окон стрелками
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }),   { repeating = true })
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -40, y = 0, relative = true }),  { repeating = true })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0, y = -40, relative = true }),  { repeating = true })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0, y = 40, relative = true }),   { repeating = true })

-- Мультимедиа и системные клавиши
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"), { repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"))
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s +10%"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { repeating = true })

-- Скриншоты
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/screenshot.sh area"))
hl.bind(mainMod .. " + ALT + S",   hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/screenshot.sh menu"))
hl.bind("Print",                   hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/screenshot.sh full"))
hl.bind(mainMod .. " + Print",     hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/screenshot.sh window"))

-- Справка по клавишам и язык
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/keybinds_help.sh"))
hl.bind(mainMod .. " + F1",    hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/keybinds_help.sh"))
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/lang_ctl.sh toggle"))

--------------------------------
---- WINDOW RULES --------------
--------------------------------
local float_classes = {
    "pavucontrol",
    "blueman-manager",
    "nm-connection-editor",
    "wlogout",
}

for _, cls in ipairs(float_classes) do
    hl.window_rule({
        name = "float-" .. cls,
        match = { class = "^(" .. cls .. ")$" },
        float = true,
    })
end

local float_titles = {
    "Open File",
    "Save File",
    "Choose Wallpaper",
}

for _, t in ipairs(float_titles) do
    hl.window_rule({
        name = "float-" .. t:gsub(" ", "-"),
        match = { title = "^(" .. t .. ")$" },
        float = true,
    })
end

hl.window_rule({
    name = "filemanager-float",
    match = { class = "^(FileManager|yazi)$" },
    float = true,
})
hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})
