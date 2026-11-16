-- Theme converted for Hyprland Lua
hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border = { colors = { "rgb(666666)", "rgb(222222)" }, angle = 45 },
            inactive_border = "rgb(141416)",
        },
        layout = "dwindle",
    },
    decoration = {
        rounding = 18,
        active_opacity = 0.98,
        inactive_opacity = 0.92,
        fullscreen_opacity = 1.0,
        blur = {
            enabled = true,
            size = 8,
            passes = 3,
            vibrancy = 0.2,
            brightness = 0.95,
            contrast = 1.15,
        },
        shadow = {
            enabled = true,
            range = 25,
            render_power = 3,
            color = "rgba(00000088)",
        },
    },
})
