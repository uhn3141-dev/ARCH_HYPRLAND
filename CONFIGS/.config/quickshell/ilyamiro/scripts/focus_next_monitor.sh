#!/bin/bash
# ^ Specifies that this script should be run using the Bash interpreter located at `/bin/bash`. This is an absolute path variant of the shebang, ensuring it works even if `/usr/bin/env` is not available or preferred.

# Cycle focus to the next monitor
hyprctl dispatch focusmonitor +1
# ^ Executes a Hyprland command using `hyprctl` to shift the keyboard/mouse focus to the next monitor in the configuration. The `dispatch` keyword sends a dispatcher command, and `focusmonitor +1` cycles focus forward by one monitor. The `+1` means move to the next monitor in the list (wrapping around to the first after the last). This is typically used for keyboard-driven navigation between multiple displays.

# Get the newly focused monitor's geometry
monitor=$(hyprctl monitors -j | jq '.[] | select(.focused == true)')
# ^ Retrieves detailed information about the currently focused monitor using a pipeline of commands. First, `hyprctl monitors -j` outputs information about all connected monitors in JSON format (`-j` flag). This JSON is piped to `jq`, a command-line JSON processor. The `jq` filter `.[]` iterates over all objects in the JSON array (one per monitor), and `select(.focused == true)` picks only the monitor object where the `focused` field is `true`. The result (the full JSON object of the focused monitor including x, y, width, height, scale, etc.) is stored in the `monitor` variable using command substitution `$()`.

x=$(echo "$monitor" | jq '.x + (.width / 2 / .scale)' | bc)
# ^ Calculates the X coordinate for the center point of the focused monitor. First, `echo "$monitor"` passes the monitor JSON object to `jq`, which computes the expression `.x + (.width / 2 / .scale)`. This takes the monitor's X position (left edge offset), adds half its width (to get the horizontal center), and divides by the monitor's scale factor (to convert from scaled coordinates to actual pixel coordinates for high-DPI displays). The result is piped to `bc`, a command-line calculator, which evaluates the arithmetic expression and outputs the final integer or float value. The result is stored in the `x` variable.

y=$(echo "$monitor" | jq '.y + (.height / 2 / .scale)' | bc)
# ^ Calculates the Y coordinate for the center point of the focused monitor using the same approach as the X calculation. It takes the monitor's Y position (top edge offset), adds half its height (to get the vertical center), and divides by the monitor's scale factor. The arithmetic expression is evaluated by `bc`, and the result is stored in the `y` variable. Together with `x`, this gives the exact pixel coordinates of the center of the focused monitor.

# Move cursor to the center of that monitor
hyprctl dispatch movecursor "$x" "$y"
# ^ Moves the mouse cursor to the calculated center coordinates of the newly focused monitor. The `hyprctl dispatch movecursor` command takes two arguments: the X and Y pixel coordinates. This ensures that after switching focus to a different monitor, the cursor is repositioned to the center of that monitor rather than staying at its previous location (which might now be on a different display). The variables `$x` and `$y` are expanded to their calculated values.