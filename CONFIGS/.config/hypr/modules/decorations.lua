-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 3, -- (css_gaps) size of the gaps between windows
        gaps_out = 5, -- (css_gaps) size of the gaps between windows and monitor edges
        float_gaps = -1, -- (css_gaps) size of the gaps between floating windows
        gaps_workspaces = 5, -- (css_gaps) size of the gaps between workspaces


        border_size = 2, -- (int) size of the border around windows

        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 }, -- (gradient) border color for the active window
            inactive_border = "rgba(595959aa)", -- (gradient) border color for inactive windows

            nogroup_border_active = "rgba(ffff00ff)", -- (gradient) border color for active windows that cannot be added to a group
            nogroup_border = "rgba(ffffaaff)", -- (gradient) border color for windows that cannot be added to a group
        },

        resize_on_border = true, -- (bool) enables resizing windows by clicking and dragging on borders and gaps
        extend_border_grab_area = 15, -- (int) extends the area around the border where you can click and drag on, only used when general:resize_on_border is on
        hover_icon_on_border = true, -- (bool) show a cursor icon when hovering over borders, only used when general:resize_on_border is on

        resize_corner = 0, -- (int) force floating windows to use a specific corner when being resized (1-4 going clockwise from top left, 0 to disable)

        allow_tearing = false, -- (bool) whether to allow tearing floating windows off of their groups by dragging them by the border, only applies if general:resize_on_border is true
        no_focus_fallback = false, -- (bool) if true, will not fall back to the next available window when moving focus in a direction where no window was found
        modal_parent_blocking = true, -- (bool) whether parent windows of modals will be interactive

        -- locale = "" -- (string) overrides the system locale (e.g. en_US, es)

        snap = {
            enabled = true, -- (bool) enable snapping for floating windows
            window_gap = 10, -- (int) minimum gap in pixels between windows before snapping
            monitor_gap = 10, -- (int) minimum gap in pixels between window and monitor edges before snapping
            border_overlap = false, -- (bool) if true, windows snap such that only one border’s worth of space is between them
            respect_gaps = false, -- (bool) if true, snapping will respect gaps between windows(set in general:gaps_in)
        },
    },

    decoration = {
        rounding = 10, -- (int) rounded corners’ radius (in layout px). 0 to disable.
        rounding_power = 3, -- (float) adjusts the curve used for rounding corners, larger is smoother, 2.0 is a circle, 4.0 is a squircle, 1.0 is a triangular corner. [1.0 - 10.0]

        active_opacity   = 1.0, -- (float) opacity of active windows. [0.0 - 1.0]
        inactive_opacity = 1.0, -- (float) opacity of inactive windows. [0.0 - 1.0]
        fullscreen_opacity = 1.0, -- (float) opacity of fullscreen windows. [0.0 - 1.0]

        dim_modal = true, -- (bool) enables dimming of parents of modal windows
        dim_inactive = false, -- (bool) enables dimming of inactive windows
        dim_strength = 0.5, -- (float) how much inactive windows should be dimmed [0.0 - 1.0]
        dim_special = 0.2, -- (float) how much to dim the rest of the screen by when a special workspace is open. [0.0 - 1.0]
        dim_around = 0.4, -- (float) how much the dim_around window rule should dim by. [0.0 - 1.0]

        screen_shader = "", -- (str) a path to a custom shader to be applied at the end of rendering. See examples/screenShader.frag for an example.
        border_part_of_window = true, -- (bool) whether the window border should be a part of the window

        shadow = {
            enabled      = true, -- (bool) enable drop shadows on windows
            range        = 4, -- (int) shadow range (“size”) in layout px
            render_power = 3, -- (int) in what power to render the falloff (more power, the faster the falloff) [1 - 4]
            sharp        = false, -- (bool) if enabled, will make the shadows sharp, akin to an infinite render power
            color        = 0xee1a1a1a, -- (color) shadow’s color. Alpha dictates shadow’s opacity.
            color_inactive = nil, -- (color) inactive shadow color. (if not set, will fall back to color)
            offset       = {0, 0}, -- (vec2) shadow’s rendering offset.
            scale        = 1.0, -- (float) shadow’s scale. [0.0 - 1.0]
        },

        blur = {
            enabled   = true, -- (bool) enable kawase window background blur
            size      = 3, -- (int) blur size (distance)
            passes    = 1, -- (int) the amount of passes to perform
            ignore_opacity = true, -- (bool) make the blur layer ignore the opacity of the window
            new_optimizations = true, -- (bool) whether to enable further optimizations to the blur. Recommended to leave on, as it will massively improve performance.
            xray = false, -- (bool) if enabled, floating windows will ignore tiled windows in their blur. Only available if new_optimizations is true. Will reduce overhead on floating blur significantly.
            noise = 0.0117, -- (float) how much noise to apply. [0.0 - 1.0]
            contrast = 0.8916, -- (float) contrast modulation for blur. [0.0 - 2.0]
            brightness = 0.8172, -- (float) brightness modulation for blur. [0.0 - 2.0]
            vibrancy  = 0.1696, -- (float) Increase saturation of blurred colors. [0.0 - 1.0]
            vibrancy_darkness = 0.0, -- (float) How strong the effect of vibrancy is on dark areas . [0.0 - 1.0]
            special = false, -- (bool) whether to blur behind the special workspace (note: expensive)
            popups = false, -- (bool) whether to blur popups (e.g. right-click menus)
            popups_ignorealpha = 0.2, -- (float) works like ignore_alpha in layer rules. If pixel opacity is below set value, will not blur. [0.0 - 1.0]
            input_methods = false, -- (bool) whether to blur input methods (e.g. fcitx5)
            input_methods_ignorealpha = 0.2, -- (float) works like ignore_alpha in layer rules. If pixel opacity is below set value, will not blur. [0.0 - 1.0]
        },

        glow = {
            enabled = false, -- (bool) enable inner glow on windows
            range = 10, -- (int) glow range (“size”) in layout px
            render_power = 3, -- (int) in what power to render the falloff (more power, the faster the falloff) [1 - 4]
            color = 0xee1a1a1a, -- (color) glow’s color. Alpha dictates glow’s opacity.
            color_inactive = nil, -- (color) inactive glow color. (if not set, will fall back to color)
        },
    },

    animations = {
        enabled = true, -- (bool) enable animations
        workspace_wraparound = false, -- (bool) enable workspace wraparound, causing directional workspace animations to animate as if the first and last workspaces were adjacent
    },
})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- Default springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })