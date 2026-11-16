-- Theme converted for Hyprland Lua
hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(e5e5ea88)", "rgba(63636644)" }, angle = 45 },
            inactive_border = "rgba(2c2c2e55)",
        },
        layout = "dwindle",
    },
    decoration = {
        rounding = 16,
        active_opacity = 0.86,
        inactive_opacity = 0.76,
        fullscreen_opacity = 0.98,
        blur = {
            enabled = true,
            size = 7,
            passes = 3,
            vibrancy = 0.25,
            brightness = 1.02,
            contrast = 1.05,
        },
        shadow = {
            enabled = true,
            range = 22,
            render_power = 3,
            color = "rgba(00000060)",
        },
    },
})
