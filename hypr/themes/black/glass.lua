-- Theme converted for Hyprland Lua
hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(ffffff44)", "rgba(88888822)" }, angle = 45 },
            inactive_border = "rgba(00000055)",
        },
        layout = "dwindle",
    },
    decoration = {
        rounding = 14,
        active_opacity = 0.86,
        inactive_opacity = 0.78,
        fullscreen_opacity = 0.98,
        blur = {
            enabled = true,
            size = 7,
            passes = 3,
            vibrancy = 0.2,
            brightness = 1.05,
            contrast = 1.1,
        },
        shadow = {
            enabled = true,
            range = 20,
            render_power = 3,
            color = "rgba(00000088)",
        },
    },
})
