-- Theme converted for Hyprland Lua
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = { colors = { "rgb(4a4f5a)", "rgb(2a2e38)" }, angle = 45 },
            inactive_border = "rgb(181a1f)",
        },
        layout = "dwindle",
    },
    decoration = {
        rounding = 12,
        active_opacity = 0.94,
        inactive_opacity = 0.88,
        fullscreen_opacity = 1.0,
        blur = {
            enabled = true,
            size = 5,
            passes = 2,
            brightness = 1.0,
            contrast = 1.0,
        },
        shadow = {
            enabled = true,
            range = 15,
            render_power = 2,
            color = "rgba(00000066)",
        },
    },
})
