-- Theme converted for Hyprland Lua
hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(222222aa)", "rgba(77777788)" }, angle = 45 },
            inactive_border = "rgba(0000001a)",
        },
        layout = "dwindle",
    },
    decoration = {
        rounding = 16,
        active_opacity = 0.85,
        inactive_opacity = 0.75,
        fullscreen_opacity = 0.98,
        blur = {
            enabled = true,
            size = 7,
            passes = 3,
            brightness = 1.15,
            contrast = 1.05,
        },
        shadow = {
            enabled = true,
            range = 22,
            render_power = 3,
            color = "rgba(00000028)",
        },
    },
})
