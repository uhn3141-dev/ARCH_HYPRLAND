---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us", -- (str) Appropriate XKB keymap parameter
        sensitivity = 0.3,
        -- kb_model = "", -- (str) Appropriate XKB keymap parameter.
        -- kb_variant = "", -- (str) Appropriate XKB keymap parameter.
        -- kb_options = "", -- (str) Appropriate XKB keymap parameter.
        -- kb_rules = "", -- (str) Appropriate XKB keymap parameter.
        -- kb_file = "", -- (str) If you prefer, you can use a path to your custom .xkb file.
        numlock_by_default = true, -- (bool) Engage numlock by default.
        -- resolve_binds_by_sym = false, -- (bool) Determines how keybinds act when multiple layouts are used. If false, keybinds will always act as if the first specified layout is active. If true, keybinds specified by symbols are activated when you type the respective symbol with the current layout.
        -- repeat_rate = 25, -- (int) The repeat rate for held-down keys, in repeats per second.
        -- repeat_delay = 600, -- (int) Delay before a held-down key is repeated, in milliseconds.
        -- accel_profile = "", -- (str) Sets the cursor acceleration profile. Can be one of adaptive, flat. Can also be custom, see below. Leave empty to use libinput’s default mode for your input device. libinput#pointer-acceleration [adaptive/flat/custom]
        -- force_no_accel = false, -- (bool) Force no cursor acceleration. This bypasses most of your pointer settings to get as raw of a signal as possible. Enabling this is not recommended due to potential cursor desynchronization.
        -- rotation = 0, -- (int) Sets the rotation of a device in degrees clockwise off the logical neutral position. Value is clamped to the range 0 to 359.
        -- left_handed = false, -- (bool) Switches RMB and LMB
        -- scroll_points = "", -- (str) Sets the scroll acceleration profile, when accel_profile is set to custom. Has to be in the form <step> <points>. Leave empty to have a flat scroll curve.
        -- scroll_method = "", -- (str) Sets the scroll method. Can be one of 2fg (2 fingers), edge, on_button_down, no_scroll. libinput#scrolling [2fg/edge/on_button_down/no_scroll]
        -- scroll_button = 0, -- (int) Sets the scroll button. Has to be an int, cannot be a string. Check wev if you have any doubts regarding the ID. 0 means default.
        -- scroll_button_lock = false, -- (bool) If the scroll button lock is enabled, the button does not need to be held down. Pressing and releasing the button toggles the button lock, which logically holds the button down or releases it. While the button is logically held down, motion events are converted to scroll events.
        -- scroll_factor = 1.0, -- (float) Multiplier added to scroll movement for external mice. Note that there is a separate setting for touchpad scroll_factor.
        -- natural_scroll = false, -- (bool) Inverts scrolling direction. When enabled, scrolling moves content directly, rather than manipulating a scrollbar.
        follow_mouse = 1, -- (int) Specify if and how cursor movement should affect window focus. See the note below. [0/1/2/3]
        -- follow_mouse_shrink = 0, -- (int) Shrinks the inactive window hitboxes used for focus detection by the specified number of pixels. This creates a dead zone in gaps between windows where moving the cursor will not change focus. Works only with follow_mouse = 1.
        -- follow_mouse_threshold = 0.0, -- (float) The smallest distance in logical pixels the mouse needs to travel for the window under it to get focused. Works only with follow_mouse = 1.
        -- focus_on_close = 0, -- (int) Controls the window focus behavior when a window is closed. When set to 0, focus will shift to the next window candidate. When set to 1, focus will shift to the window under the cursor. When set to 2, focus will shift to the most recently used/active window. [0/1/2]
        -- mouse_refocus = true, -- (bool) If disabled, mouse focus won’t switch to the hovered window unless the mouse crosses a window boundary when follow_mouse=1.
        -- float_switch_override_focus = 1, -- (int) If enabled (1 or 2), focus will change to the window under the cursor when changing from tiled-to-floating and vice versa. If 2, focus will also follow mouse on float-to-float switches.
        -- special_fallthrough = false, -- (bool) if enabled, having only floating windows in the special workspace will not block focusing windows in the regular workspace.
        -- off_window_axis_events = 1, -- (int) Handles axis events around (gaps/border for tiled, dragarea/border for floated) a focused window. 0 ignores axis events 1 sends out-of-bound coordinates 2 fakes pointer coordinates to the closest point inside the window 3 warps the cursor to the closest point inside the window
        -- emulate_discrete_scroll = 1, -- (int) Emulates discrete scrolling from high resolution scrolling events. 0 disables it, 1 enables handling of non-standard events only, and 2 force enables all scroll wheel events to be handled

        -- touchpad = {
        --     natural_scroll = false, -- (bool) Inverts scrolling direction. When enabled, scrolling moves content directly, rather than manipulating a scrollbar.
        --     disable_while_typing = true, -- (bool) Disable the touchpad while typing.
        --     scroll_factor = 1.0, -- (float) Multiplier applied to the amount of scroll movement.
        --     middle_button_emulation = false, -- (bool) Sending LMB and RMB simultaneously will be interpreted as a middle click. This disables any touchpad area that would normally send a middle click based on location. libinput#middle-button-emulation
        --     tap_button_map = "", -- (str) Sets the tap button mapping for touchpad button emulation. Can be one of lrm (default) or lmr (Left, Middle, Right Buttons). [lrm/lmr]
        --     clickfinger_behavior = false, -- (bool) Button presses with 1, 2, or 3 fingers will be mapped to LMB, RMB, and MMB respectively. This disables interpretation of clicks based on location on the touchpad. libinput#clickfinger-behavior
        --     tap_to_click = true, -- (bool) Tapping on the touchpad with 1, 2, or 3 fingers will send LMB, RMB, and MMB respectively.
        --     drag_lock = 0, -- (int) When enabled, lifting the finger off while dragging will not drop the dragged item. 0 -> disabled, 1 -> enabled with timeout, 2 -> enabled sticky. libinput#tap-and-drag
        --     tap_and_drag = true, -- (bool) Sets the tap and drag mode for the touchpad
        --     flip_x = false, -- (bool) inverts the horizontal movement of the touchpad
        --     flip_y = false, -- (bool) inverts the vertical movement of the touchpad
        --     drag_3fg = 0, -- (int) enables three finger drag, 0 -> disabled, 1 -> 3 fingers, 2 -> 4 fingers libinput#drag-3fg
        -- },

        -- touchdevice = {
        --     transform = -1, -- (int) Transform the input from touchdevices. The possible transformations are the same as those of the monitors. -1 means it’s unset.
        --     output = "[[Auto]]", -- (str) The monitor to bind touch devices. The default is auto-detection. To stop auto-detection, use an empty string or the “[[Empty]]” value.
        --     enabled = true, -- (bool) Whether input is enabled for touch devices.
        -- },

        -- virtualkeyboard = {
        --     share_states = 2, -- (int) Unify key down states and modifier states with other keyboards. 0 -> no, 1 -> yes, 2 -> yes unless IME client
        --     release_pressed_on_close = true, -- (bool) Release all pressed keys by virtual keyboard on close.
        -- },

        -- tablet = {
        --     transform = -1, -- (int) Transform the input from tablets. The possible transformations are the same as those of the monitors. -1 means it’s unset.
        --     output = "[[Empty]]", -- (str) The monitor to bind tablets. Can be current or a monitor name. Leave empty to map across all monitors.
        --     region_position = {0, 0}, -- (vec2) position of the mapped region in monitor layout relative to the top left corner of the bound monitor or all monitors.
        --     absolute_region_position = false, -- (bool) whether to treat the region_position as an absolute position in monitor layout. Only applies when output is empty.
        --     region_size = {0, 0}, -- (vec2) size of the mapped region. When this variable is set, tablet input will be mapped to the region. [0, 0] or invalid size means unset.
        --     relative_input = false, -- (bool) whether the input should be relative
        --     left_handed = false, -- (bool) if enabled, the tablet will be rotated 180 degrees
        --     active_area_size = {0, 0}, -- (vec2) size of tablet’s active area in mm
        --     active_area_position = {0, 0}, -- (vec2) position of the active area in mm
        -- },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
    -- workspace_swipe_distance = 300, -- (int) in px, the distance of the touchpad gesture
    -- workspace_swipe_touch = false, -- (bool) enable workspace swiping from the edge of a touchscreen
    -- workspace_swipe_invert = true, -- (bool) invert the direction (touchpad only)
    -- workspace_swipe_touch_invert = false, -- (bool) invert the direction (touchscreen only)
    -- workspace_swipe_min_speed_to_force = 30, -- (int) minimum speed in px per timepoint to force the change ignoring cancel_ratio. Setting to 0 will disable this mechanic.
    -- workspace_swipe_cancel_ratio = 0.5, -- (float) how much the swipe has to proceed in order to commence it. (0.7 -> if > 0.7 * distance, switch, if less, revert) [0.0 - 1.0]
    -- workspace_swipe_create_new = true, -- (bool) whether a swipe right on the last workspace should create a new one.
    -- workspace_swipe_direction_lock = true, -- (bool) if enabled, switching direction will be locked when you swipe past the direction_lock_threshold (touchpad only).
    -- workspace_swipe_direction_lock_threshold = 10, -- (int) in px, the distance to swipe before direction lock activates (touchpad only).
    -- workspace_swipe_forever = false, -- (bool) if enabled, swiping will not clamp at the neighboring workspaces but continue to the further ones.
    -- workspace_swipe_use_r = false, -- (bool) if enabled, swiping will use the r prefix instead of the m prefix for finding workspaces.
    -- close_max_timeout = 1000, -- (int) the timeout for a window to close when using a 1:1 gesture, in ms
})