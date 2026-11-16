-- Theme converted for Hyprland Lua
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = { colors = { "rgb(88c0d0)", "rgb(81a1c1)" }, angle = 45 },
            inactive_border = "rgb(2e3440)",
        },
        layout = "dwindle",
    },
    decoration = {
        rounding = 12,
        active_opacity = 0.92,
        inactive_opacity = 0.85,
        fullscreen_opacity = 1.0,
        blur = {
            enabled = true,
            size = 5,
            passes = 2,
        },
        shadow = {
            enabled = true,
            range = 16,
            render_power = 2,
            color = "rgba(00000044)",
        },
    },
})
