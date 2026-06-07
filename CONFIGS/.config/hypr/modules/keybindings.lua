---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(TERMINAL))
-- hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(DROPDOWN_TERMINAL))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(FILE_MANAGER))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(MENU))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(BROWSER))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd(EDITOR))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(SPOTIFY))

hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(WALLPAPER_CHANGER))

hl.bind("Escape", hl.dsp.exec_cmd(QS_KILL_POPUP))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(QS_RELOAD))
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.exec_cmd(QS_BATTERY))
hl.bind(mainMod .. " + SHIFT + Y", hl.dsp.exec_cmd(QS_BRIGHTNESS))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(QS_SOUND))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd(QS_CLOCK))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(QS_POWER))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd(QS_NETWORK))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(QS_BLUETOOTH))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(QS_MUSIC))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(QS_NOTIFICATION_CENTER))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd(QS_SYSTEM_MONITOR))

hl.bind(mainMod .. " + SHIFT + CTRL + L", hl.dsp.exec_cmd(QYLOCK))
hl.bind(mainMod .. " + SHIFT + CTRL + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

hl.bind(mainMod .. " + Q", hl.dsp.window.close())

hl.bind(mainMod .. " + CTRL + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + CTRL + SHIFT + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + CTRL + SHIFT + J", hl.dsp.layout("togglesplit"))    -- dwindle only
hl.bind(mainMod .. " + CTRL + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Move window with mainMod + CTRL + arrow keys
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.swap({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + CTRL + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + CTRL + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Scroll through existing workspaces with mainMod + ALT + arrow keys
hl.bind(mainMod .. " + ALT + right",  hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + ALT + left",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Resize windows with mainMod + SHIFT + arrow keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({x = -20, y = 0, relative = true}))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({x = 20, y = 0, relative = true}))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({x = 0, y = -20, relative = true}))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({x = 0, y = 20, relative = true}))


-- -- Laptop multimedia keys for volume and LCD brightness
-- hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
-- hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
-- hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
-- hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
-- hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
-- hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- -- Requires playerctl
-- hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
-- hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
-- hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
-- hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })