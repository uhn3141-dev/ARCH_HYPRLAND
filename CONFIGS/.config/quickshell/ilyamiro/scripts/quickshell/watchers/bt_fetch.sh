# #!/usr/bin/env bash
# get_bt_status() {
#     if LC_ALL=C timeout 0.5 bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then echo "on"; else echo "off"; fi
# }
# get_bt_connected_device() {
#     if [ "$(get_bt_status)" = "on" ]; then
#         local device=$(LC_ALL=C timeout 0.5 bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f3-)
#         if [ -n "$device" ]; then echo "$device"; else echo "Disconnected"; fi
#     else echo "Off"; fi
# }
# get_bt_icon() {
#     if [ "$(get_bt_status)" = "on" ]; then
#         if LC_ALL=C timeout 0.5 bluetoothctl devices Connected 2>/dev/null | grep -q "^Device"; then echo "󰂱"; else echo "󰂯"; fi
#     else echo "󰂲"; fi
# }
# toggle_bt() {
#     if [ "$(get_bt_status)" = "on" ]; then
#         LC_ALL=C timeout 0.5 bluetoothctl power off 2>/dev/null
#         notify-send -u low -i bluetooth-disabled "Bluetooth" "Disabled"
#     else
#         LC_ALL=C timeout 0.5 bluetoothctl power on 2>/dev/null
#         notify-send -u low -i bluetooth-active "Bluetooth" "Enabled"
#     fi
# }
# case $1 in
#     --toggle) toggle_bt ;;
#     *) jq -n -c --arg status "$(get_bt_status)" --arg icon "$(get_bt_icon)" --arg connected "$(get_bt_connected_device)" '{status: $status, icon: $icon, connected: $connected}' ;;
# esac


#!/usr/bin/env bash                                                              # Shebang line that tells the system to execute this script using the bash interpreter found in the user's PATH environment variable (more portable than hardcoding /bin/bash)
get_bt_status() {                                                               # Defines a function that checks whether the Bluetooth adapter is powered on or off
    if LC_ALL=C timeout 0.5 bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then echo "on"; else echo "off"; fi  # Sets C locale, runs bluetoothctl show with a 0.5-second timeout to prevent hanging if the daemon is unresponsive, suppresses errors, pipes the output to grep which silently (-q) checks for the string "Powered: yes"; if found prints "on", otherwise prints "off"
}                                                                               # Closes the get_bt_status function definition

get_bt_connected_device() {                                                     # Defines a function that returns the name of the currently connected Bluetooth device, or a status string if none is connected
    if [ "$(get_bt_status)" = "on" ]; then                                     # First checks if Bluetooth is powered on by calling get_bt_status; if it's off, skip the check entirely
        local device=$(LC_ALL=C timeout 0.5 bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f3-)  # Declares a local variable, runs bluetoothctl to list only connected devices with a 0.5-second timeout, suppresses errors, takes only the first line (first connected device) with head, then uses cut with space delimiter to remove the first two fields (the "Device" keyword and the MAC address), keeping everything from field 3 onward which is the device name
        if [ -n "$device" ]; then echo "$device"; else echo "Disconnected"; fi  # If the device variable is not empty (a device name was extracted), prints the device name; otherwise prints "Disconnected" indicating Bluetooth is on but nothing is connected
    else echo "Off"; fi                                                         # If Bluetooth is powered off, simply prints "Off" instead of trying to look for devices
}                                                                               # Closes the get_bt_connected_device function definition

get_bt_icon() {                                                                 # Defines a function that returns the appropriate Nerd Font Bluetooth icon based on power state and connection status
    if [ "$(get_bt_status)" = "on" ]; then                                     # Checks if Bluetooth is powered on
        if LC_ALL=C timeout 0.5 bluetoothctl devices Connected 2>/dev/null | grep -q "^Device"; then echo "󰂱"; else echo "󰂯"; fi  # If Bluetooth is on, checks for connected devices: runs bluetoothctl with 0.5-second timeout to list connected devices, suppresses errors, greps silently for lines starting with "Device" (which indicates at least one connected device); if found prints the "Bluetooth connected" icon (󰂱), otherwise prints the "Bluetooth on but disconnected" icon (󰂯)
    else echo "󰂲"; fi                                                           # If Bluetooth is off, prints the "Bluetooth disabled" icon (󰂲)
}                                                                               # Closes the get_bt_icon function definition

toggle_bt() {                                                                   # Defines a function that toggles the Bluetooth adapter power state and sends a desktop notification
    if [ "$(get_bt_status)" = "on" ]; then                                     # Checks if Bluetooth is currently on
        LC_ALL=C timeout 0.5 bluetoothctl power off 2>/dev/null                # If on, powers off the Bluetooth adapter using bluetoothctl with a 0.5-second timeout and suppresses any error output
        notify-send -u low -i bluetooth-disabled "Bluetooth" "Disabled"        # Sends a low-urgency desktop notification with the bluetooth-disabled icon, title "Bluetooth", and message "Disabled"
    else                                                                         # If Bluetooth is currently off
        LC_ALL=C timeout 0.5 bluetoothctl power on 2>/dev/null                 # Powers on the Bluetooth adapter with a 0.5-second timeout, suppressing errors
        notify-send -u low -i bluetooth-active "Bluetooth" "Enabled"           # Sends a low-urgency desktop notification with the bluetooth-active icon, title "Bluetooth", and message "Enabled"
    fi                                                                           # Closes the if-else block
}                                                                               # Closes the toggle_bt function definition

case $1 in                                                                      # Begins a case statement that evaluates the first command-line argument ($1) passed to the script
    --toggle) toggle_bt ;;                                                      # If the argument is "--toggle", executes the toggle_bt function to flip the Bluetooth power state; ;; terminates this case branch
    *) jq -n -c --arg status "$(get_bt_status)" --arg icon "$(get_bt_icon)" --arg connected "$(get_bt_connected_device)" '{status: $status, icon: $icon, connected: $connected}' ;;  # Default case for any other argument (including no argument): constructs a compact JSON object using jq with three fields: status (on/off), icon (the Nerd Font icon), and connected (device name or "Disconnected"/"Off"); uses -n for null input, -c for compact single-line output, and --arg to bind each shell command substitution result to a JSON variable
esac                                                                             # Ends the case statement block