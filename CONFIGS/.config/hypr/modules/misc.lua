----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 0, -- (int) Enforce any of the 3 default wallpapers. Setting this to 0 or 1 disables the anime background. -1 means “random”.
        disable_hyprland_logo   = true, -- (bool) disables the random Hyprland logo / anime girl background. :(
        font_family = "Profont Nerd", -- (string) Set the global default font to render the text including debug fps/notification, config error messages and etc., selected from system fonts.

        -- disable_splash_rendering = true, -- (bool) disables the Hyprland splash rendering. (requires a monitor reload to take effect)
        -- disable_scale_notification = true, -- (bool) disables notification popup when a monitor fails to set a suitable scale
        -- col.splash = 0xffffffff, -- (color) Changes the color of the splash text (requires a monitor reload to take effect).
        -- splash_font_family = "Profont Nerd", -- (string) Changes the font used to render the splash text, selected from system fonts (requires a monitor reload to take effect).
        -- vrr = 0, -- (int) controls the VRR (Adaptive Sync) of your monitors. 0 - off, 1 - on, 2 - fullscreen only, 3 - fullscreen with video or game content type [0/1/2/3]
        -- mouse_move_enables_dpms = false, -- (bool) If DPMS is set to off, wake up the monitors if the mouse moves.
        -- key_press_enables_dpms = false, -- (bool) If DPMS is set to off, wake up the monitors if a key is pressed.
        -- name_vk_after_proc = true, -- (bool) Name virtual keyboards after the processes that create them. E.g. /usr/bin/fcitx5 will have hl-virtual-keyboard-fcitx5.
        -- always_follow_on_dnd = true, -- (bool) Will make mouse focus follow the mouse when drag and dropping. Recommended to leave it enabled, especially for people using focus follows mouse at 0.
        -- layers_hog_keyboard_focus = true, -- (bool) If true, will make keyboard-interactive layers keep their focus on mouse move (e.g. wofi, bemenu)
        -- animate_manual_resizes = false, -- (bool) If true, will animate manual window resizes/moves
        -- animate_mouse_windowdragging = false, -- (bool) If true, will animate windows being dragged by mouse, note that this can cause weird behavior on some curves
        -- disable_autoreload = false, -- (bool) If true, the config will not reload automatically on save, and instead needs to be reloaded with hyprctl reload. Might save on battery.
        -- enable_swallow = false, -- (bool) Enable window swallowing
        -- swallow_regex = "", -- (str) The class regex to be used for windows that should be swallowed (usually, a terminal). To know more about the list of regex which can be used use this cheatsheet.
        -- swallow_exception_regex = "", -- (str) The title regex to be used for windows that should not be swallowed by the windows specified in swallow_regex (e.g. wev). The regex is matched against the parent (e.g. Kitty) window’s title on the assumption that it changes to whatever process it’s running.
        -- focus_on_activate = false, -- (bool) Whether Hyprland should focus an app that requests to be focused (an activate request)
        -- mouse_move_focuses_monitor = true, -- (bool) Whether mouse moving into a different monitor should focus it
        -- allow_session_lock_restore = false, -- (bool) if true, will allow you to restart a lockscreen app in case it crashes
        -- session_lock_xray = false, -- (bool) if true, keep rendering workspaces below your lockscreen
        -- background_color = 0x111111, -- (color) change the background color. (requires enabled disable_hyprland_logo)
        -- close_special_on_empty = true, -- (bool) close the special workspace if the last window is removed
        -- on_focus_under_fullscreen = 2, -- (int) if there is a fullscreen or maximized window, decide whether a tiled window requested to focus should replace it, stay behind or disable the fullscreen/maximized state. 0 - ignore focus request (keep focus on fullscreen window), 1 - takes over, 2 - unfullscreen/unmaximize [0/1/2]
        -- exit_window_retains_fullscreen = false, -- (bool) if true, closing a fullscreen window makes the next focused window fullscreen
        -- initial_workspace_tracking = 1, -- (int) if enabled, windows will open on the workspace they were invoked on. 0 - disabled, 1 - single-shot, 2 - persistent (all children too)
        -- middle_click_paste = true, -- (bool) whether to enable middle-click-paste (aka primary selection)
        -- render_unfocused_fps = 15, -- (int) the maximum limit for render_unfocused windows’ fps in the background (see also Window-Rules - render_unfocused)
        -- disable_xdg_env_checks = false, -- (bool) disable the warning if XDG environment is externally managed
        -- disable_hyprland_qtutils_check = false, -- (bool) disable the warning if hyprland-qtutils is not installed
        -- lockdead_screen_delay = 1000, -- (int) delay after which the “lockdead” screen will appear in case a lockscreen app fails to cover all the outputs (5 seconds max)
        -- enable_anr_dialog = true, -- (bool) whether to enable the ANR (app not responding) dialog when your apps hang
        -- anr_missed_pings = 5, -- (int) number of missed pings before showing the ANR dialog
        -- size_limits_tiled = false, -- (bool) whether to apply min_size and max_size rules to tiled windows
        -- disable_watchdog_warning = false, -- (bool) whether to disable the warning about not using start-hyprland, which can cause performance issues and instability
    },
})