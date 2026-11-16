-- Theme converted for Hyprland Lua
hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(0066cc88)", "rgba(ffffffaa)" }, angle = 45 },
            inactive_border = "rgba(ffffff55)",
        },
        layout = "dwindle",
    },
    decoration = {
        rounding = 14,
        active_opacity = 0.88,
        inactive_opacity = 0.8,
        fullscreen_opacity = 0.98,
        blur = {
            enabled = true,
            size = 7,
            passes = 3,
            brightness = 1.12,
            contrast = 1.05,
        },
        shadow = {
            enabled = true,
            range = 18,
            render_power = 2,
            color = "rgba(00000025)",
        },
    },
})
