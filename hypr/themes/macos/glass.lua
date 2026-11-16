-- Theme converted for Hyprland Lua
hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 14,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(ffffff88)", "rgba(88888844)" }, angle = 45 },
            inactive_border = "rgba(ffffff1f)",
        },
        layout = "dwindle",
    },
    decoration = {
        rounding = 16,
        active_opacity = 0.8,
        inactive_opacity = 0.7,
        fullscreen_opacity = 0.95,
        blur = {
            enabled = true,
            size = 8,
            passes = 4,
            vibrancy = 0.35,
            vibrancy_darkness = 0.15,
            brightness = 1.06,
            contrast = 1.1,
            noise = 0.02,
        },
        shadow = {
            enabled = true,
            range = 28,
            render_power = 3,
            color = "rgba(00000050)",
        },
    },
})
