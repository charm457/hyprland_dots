-- Theme converted for Hyprland Lua
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = { colors = { "rgb(0066cc)", "rgb(3399ff)" }, angle = 45 },
            inactive_border = "rgb(cccccc)",
        },
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        active_opacity = 0.98,
        inactive_opacity = 0.94,
        fullscreen_opacity = 1.0,
        blur = {
            enabled = false,
        },
        shadow = {
            enabled = true,
            range = 14,
            render_power = 2,
            color = "rgba(00000022)",
        },
    },
})
