-- ==========================================
-- THEME: CYBRCORE LUCID CYBERPUNK
-- ==========================================
hl.config({
    general = {
        border_size = 1,
        gaps_in     = 4,
        gaps_out    = 2,
        col = {
            active_border   = "rgba(F24848FF)",
            inactive_border = "rgba(29BECC00)",
        },
        layout = "dwindle",
    },
    decoration = {
        rounding       = 24,
        rounding_power = 1.0,
        active_opacity   = 1.0,
        inactive_opacity = 0.95,
        fullscreen_opacity = 1.0,
        blur = {
            enabled           = true,
            size              = 6,
            passes            = 4,
            noise             = 0.05,
            ignore_opacity    = true,
            new_optimizations = true,
        },
        shadow = {
            enabled = false,
        },
    },
    animations = {
        enabled = false,
    },
})
