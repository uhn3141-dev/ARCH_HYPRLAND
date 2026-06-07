require("modules.programs")
-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function () 
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("python3 ~/.config/quickshell/popups/Battery/battery_daemon.py")
  hl.exec_cmd("quickshell")
  hl.exec_cmd("dunst")
  hl.exec_cmd("hyprsunset")

  hl.exec_cmd("rfkill unblock all")
  hl.exec_cmd("dunstctl set-paused false")

  hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
  hl.exec_cmd("~/.config/hypr/scripts/xhost-fix.sh")

  hl.exec_cmd("hyprctl setcursor cursors/Night_Diamond_Blue 24") -- set cursor theme as env not working
end)