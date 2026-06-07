# #!/usr/bin/env bash

# # --- CONFIGURATION ---
# STRICT_SPAM_FILTER=true
# # ---------------------

# CACHE_DIR="${XDG_RUNTIME_DIR:-$HOME/.cache}/quickshell_network_cache"
# mkdir -p "$CACHE_DIR"
# PID_FILE="$CACHE_DIR/bt_scan_pid"

# get_icon() {
#     local type="${1,,}"
#     local name="${2,,}"
#     if [[ "$type" == *"headset"* || "$type" == *"headphone"* || "$name" == *"headphone"* || "$name" == *"buds"* || "$name" == *"pods"* ]]; then echo "🎧"
#     elif [[ "$type" == *"audio"* || "$type" == *"speaker"* || "$type" == *"card"* || "$name" == *"speaker"* ]]; then echo "蓼"
#     elif [[ "$type" == *"phone"* || "$name" == *"phone"* || "$name" == *"iphone"* || "$name" == *"android"* ]]; then echo ""
#     elif [[ "$type" == *"mouse"* || "$name" == *"mouse"* ]]; then echo ""
#     elif [[ "$type" == *"keyboard"* || "$name" == *"keyboard"* ]]; then echo ""
#     elif [[ "$type" == *"controller"* || "$name" == *"controller"* ]]; then echo ""
#     else echo ""
#     fi
# }

# get_audio_profile() {
#     local mac="$1"
#     local mac_us="${mac//:/_}"
    
#     local active=$(pactl list cards 2>/dev/null | awk -v mac="$mac_us" '
#         tolower($0) ~ "name:.*"tolower(mac) { found=1 }
#         found && tolower($0) ~ "active profile:" { 
#             sub(/.*Active Profile: /, ""); print; exit 
#         }
#         found && /^$/ { exit }
#     ')
    
#     if [[ -z "$active" || "$active" == "off" ]]; then echo "None"; return; fi
#     if [[ "$active" == *"a2dp"* ]]; then echo "Hi-Fi (A2DP)"; return; fi
#     if [[ "$active" == *"headset"* || "$active" == *"hfp"* ]]; then echo "Headset (HFP)"; return; fi
    
#     echo "Connected"
# }

# get_status() {
#     # 1. Zero-latency hardware presence check (Bypasses the 1-second timeout entirely)
#     if ! ls -1d /sys/class/bluetooth/hci* &>/dev/null; then
#         echo "{\"present\":false,\"power\":\"off\",\"connected\":[],\"devices\":[]}"
#         return
#     fi

#     # 2. Check if bluetoothctl is even installed to prevent command errors
#     if ! command -v bluetoothctl &> /dev/null; then
#         echo "{\"present\":false,\"power\":\"off\",\"connected\":[],\"devices\":[]}"
#         return
#     fi

#     # We keep the timeout here just in case the bluetoothd daemon is frozen, 
#     # but the sysfs check above prevents this from running at all on machines without BT.
#     controller=$(timeout 1 bluetoothctl list 2>/dev/null | head -n1)
#     if [[ -z "$controller" || "$controller" == *"Waiting"* ]]; then
#         echo "{\"present\":false,\"power\":\"off\",\"connected\":[],\"devices\":[]}"
#         return
#     fi

#     power="off"
#     if timeout 1 bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then power="on"; fi

#     connected_json="[]"
#     devices_json="[]"

#     if [ "$power" == "on" ]; then
#         paired_macs=$(bluetoothctl devices Paired)
#         mapfile -t devices < <(bluetoothctl devices)
#         mapfile -t connected_info_lines < <(bluetoothctl devices Connected)
        
#         connected_macs=""
#         connected_list_objs=()
#         devices_list_objs=()

#         # 1. PROCESS CONNECTED DEVICES
#         for c_line in "${connected_info_lines[@]}"; do
#             [ -z "$c_line" ] && continue
#             rest="${c_line#Device }"
#             mac="${rest%% *}"
#             name="${rest#* }"
#             connected_macs+="$mac "
            
#             CACHE_FILE="$CACHE_DIR/bt_stat_${mac//:/_}"

#             if [ -f "$CACHE_FILE" ]; then
#                 source "$CACHE_FILE"
#             else
#                 info=$(bluetoothctl info "$mac")
#                 icon_type=$(echo "$info" | awk -F': ' '/Icon:/ {print $2}')
#                 icon=$(get_icon "$icon_type" "$name")
#                 profile=$(get_audio_profile "$mac")
                
#                 echo "CACHE_NAME=\"${name//\"/\\\"}\"" > "$CACHE_FILE"
#                 echo "CACHE_ICON=\"${icon//\"/\\\"}\"" >> "$CACHE_FILE"
#                 echo "CACHE_PROFILE=\"${profile//\"/\\\"}\"" >> "$CACHE_FILE"
                
#                 CACHE_NAME="${name//\"/\\\"}"
#                 CACHE_ICON="${icon//\"/\\\"}"
#                 CACHE_PROFILE="${profile//\"/\\\"}"
#             fi
            
#             bat=$(bluetoothctl info "$mac" | awk -F'[(|)]' '/Battery Percentage:/ {print $2}')
#             [ -z "$bat" ] && bat="0"

#             connected_list_objs+=("{\"id\":\"$mac\",\"name\":\"$CACHE_NAME\",\"mac\":\"$mac\",\"icon\":\"$CACHE_ICON\",\"battery\":\"$bat\",\"profile\":\"$CACHE_PROFILE\"}")
#         done

#         if [ ${#connected_list_objs[@]} -gt 0 ]; then
#             connected_json="[$(IFS=,; echo "${connected_list_objs[*]}")]"
#         fi

#         # 2. PROCESS DISCOVERED & PAIRED DEVICES
#         for line in "${devices[@]}"; do
#             [ -z "$line" ] && continue
#             rest="${line#Device }"
#             mac="${rest%% *}"
            
#             if [[ "$connected_macs" == *"$mac"* ]]; then continue; fi

#             name="${rest#* }"
#             name_esc="${name//\"/\\\"}"

#             if [[ "$paired_macs" == *"$mac"* ]]; then
#                 action="Connect"
#             else
#                 action="Pair"
#                 if [[ "$STRICT_SPAM_FILTER" == true ]]; then
#                     mac_hyphens="${mac//:/-}"
#                     if [[ "$name" == "$mac" || "$name" == "$mac_hyphens" || -z "$name" ]]; then
#                         continue
#                     fi
#                 fi
#             fi

#             icon=$(get_icon "unknown" "$name")
#             icon_esc="${icon//\"/\\\"}"

#             devices_list_objs+=("{\"id\":\"$mac\",\"name\":\"$name_esc\",\"mac\":\"$mac\",\"icon\":\"$icon_esc\",\"action\":\"$action\"}")
#         done

#         if [ ${#devices_list_objs[@]} -gt 0 ]; then
#             devices_json="[$(IFS=,; echo "${devices_list_objs[*]}")]"
#         fi
#     fi

#     echo "{\"present\":true,\"power\":\"$power\",\"connected\":$connected_json,\"devices\":$devices_json}"
# }


# toggle_power() {
#     if bluetoothctl show | grep -q "Powered: yes"; then
#         bluetoothctl power off
#     else
#         bluetoothctl power on
#     fi
#     sleep 0.5
# }

# connect_dev() {
#     local mac="$1"
#     if [ -f "$PID_FILE" ]; then kill -STOP $(cat "$PID_FILE") 2>/dev/null; fi
#     bluetoothctl trust "$mac" > /dev/null 2>&1
#     bluetoothctl connect "$mac"
#     if [ -f "$PID_FILE" ]; then kill -CONT $(cat "$PID_FILE") 2>/dev/null; fi
# }

# disconnect_dev() {
#     local mac="$1"
#     rm -f "$CACHE_DIR/bt_stat_${mac//:/_}" 2>/dev/null
#     bluetoothctl disconnect "$mac"
# }

# cmd="$1"
# case $cmd in
#     --status) get_status ;;
#     --toggle) toggle_power ;;
#     --connect) connect_dev "$2" ;;
#     --disconnect) disconnect_dev "$2" ;;
# esac


#!/usr/bin/env bash                                                                               # Shebang - specifies this script should be executed using the bash shell from the user's PATH environment

# --- CONFIGURATION ---                                                                           # Comment header - marks configuration section
STRICT_SPAM_FILTER=true                                                                           # Set STRICT_SPAM_FILTER to true - when enabled, filters out unnamed/anonymous Bluetooth devices from the device list (shows only named devices)
# ---------------------                                                                           # Configuration section end separator

CACHE_DIR="${XDG_RUNTIME_DIR:-$HOME/.cache}/quickshell_network_cache"                             # Define CACHE_DIR - uses XDG_RUNTIME_DIR if set (typically /run/user/UID), falls back to ~/.cache/quickshell_network_cache for Bluetooth status cache files
mkdir -p "$CACHE_DIR"                                                                             # Create the cache directory if it doesn't exist - -p creates parent directories as needed
PID_FILE="$CACHE_DIR/bt_scan_pid"                                                                 # Define PID_FILE - stores the process ID of any running Bluetooth scan to allow pausing/resuming during connect/disconnect operations

get_icon() {                                                                                      # Define function get_icon - returns an emoji icon based on device type and name
    local type="${1,,}"                                                                             # Convert first argument (device type) to lowercase using bash parameter expansion ,, operator
    local name="${2,,}"                                                                             # Convert second argument (device name) to lowercase
    if [[ "$type" == *"headset"* || "$type" == *"headphone"* || "$name" == *"headphone"* || "$name" == *"buds"* || "$name" == *"pods"* ]]; then echo "🎧"  # If type or name contains headset/headphone/buds/pods keywords, return headphones emoji
    elif [[ "$type" == *"audio"* || "$type" == *"speaker"* || "$type" == *"card"* || "$name" == *"speaker"* ]]; then echo "蓼"  # If audio/speaker/card keywords found, return speaker emoji (Chinese character for speaker)
    elif [[ "$type" == *"phone"* || "$name" == *"phone"* || "$name" == *"iphone"* || "$name" == *"android"* ]]; then echo ""  # If phone-related keywords, return smartphone icon (Nerd Font)
    elif [[ "$type" == *"mouse"* || "$name" == *"mouse"* ]]; then echo ""                           # If mouse keyword, return mouse icon (Nerd Font)
    elif [[ "$type" == *"keyboard"* || "$name" == *"keyboard"* ]]; then echo ""                     # If keyboard keyword, return keyboard icon (Nerd Font)
    elif [[ "$type" == *"controller"* || "$name" == *"controller"* ]]; then echo ""                 # If controller/gamepad keyword, return gamepad icon (Nerd Font)
    else echo ""                                                                                    # Default: return generic Bluetooth icon (Nerd Font)
    fi                                                                                             # End of icon selection if-elif-else
}                                                                                                # End of get_icon function

get_audio_profile() {                                                                            # Define function get_audio_profile - determines the active Bluetooth audio codec/profile for a device
    local mac="$1"                                                                                 # Capture the device MAC address from first argument
    local mac_us="${mac//:/_}"                                                                     # Replace all colons with underscores in MAC address (pactl uses underscore format for card names)
    
    local active=$(pactl list cards 2>/dev/null | awk -v mac="$mac_us" '                           # Run pactl to list audio cards, pipe to awk with mac_us variable, suppress stderr
        tolower($0) ~ "name:.*"tolower(mac) { found=1 }                                            # If line contains card name matching our MAC (case-insensitive), set found flag
        found && tolower($0) ~ "active profile:" {                                                  # If we've found our card and this line contains "active profile:"
            sub(/.*Active Profile: /, ""); print; exit                                               # Remove everything before the profile name, print it, and exit awk
        }                                                                                           # End of active profile block
        found && /^$/ { exit }                                                                       # If we found our card but hit an empty line (card block ended without profile), exit
    ')                                                                                             # End of awk command
    
    if [[ -z "$active" || "$active" == "off" ]]; then echo "None"; return; fi                      # If no active profile or profile is "off", output "None" and return
    if [[ "$active" == *"a2dp"* ]]; then echo "Hi-Fi (A2DP)"; return; fi                          # If profile contains "a2dp" (high-quality audio), output "Hi-Fi (A2DP)"
    if [[ "$active" == *"headset"* || "$active" == *"hfp"* ]]; then echo "Headset (HFP)"; return; fi  # If profile contains "headset" or "hfp" (hands-free profile), output "Headset (HFP)"
    
    echo "Connected"                                                                                # Fallback: if profile exists but isn't recognized, output generic "Connected"
}                                                                                                # End of get_audio_profile function

get_status() {                                                                                   # Define function get_status - generates a JSON object with full Bluetooth adapter and device information
    # 1. Zero-latency hardware presence check (Bypasses the 1-second timeout entirely)           # Comment explaining fast hardware check
    if ! ls -1d /sys/class/bluetooth/hci* &>/dev/null; then                                       # Check if ANY Bluetooth hardware interfaces exist in sysfs (hci0, hci1, etc.) - suppress all output
        echo "{\"present\":false,\"power\":\"off\",\"connected\":[],\"devices\":[]}"               # No Bluetooth hardware: output JSON with present=false, power off, empty device arrays
        return                                                                                      # Exit function early - no Bluetooth hardware to query
    fi                                                                                             # End of hardware check

    # 2. Check if bluetoothctl is even installed to prevent command errors                        # Comment explaining bluetoothctl check
    if ! command -v bluetoothctl &> /dev/null; then                                                # Check if bluetoothctl command exists in PATH
        echo "{\"present\":false,\"power\":\"off\",\"connected\":[],\"devices\":[]}"               # bluetoothctl not installed: output no-Bluetooth JSON
        return                                                                                      # Exit function
    fi                                                                                             # End of bluetoothctl check

    # We keep the timeout here just in case the bluetoothd daemon is frozen,                      # Comment explaining timeout purpose
    # but the sysfs check above prevents this from running at all on machines without BT.          # Additional context
    controller=$(timeout 1 bluetoothctl list 2>/dev/null | head -n1)                              # List Bluetooth controllers with 1-second timeout (prevents hanging if daemon is frozen), take first line, suppress errors
    if [[ -z "$controller" || "$controller" == *"Waiting"* ]]; then                               # Check if no controller found OR bluetoothctl is still waiting for daemon
        echo "{\"present\":false,\"power\":\"off\",\"connected\":[],\"devices\":[]}"               # No controller available: output no-Bluetooth JSON
        return                                                                                      # Exit function
    fi                                                                                             # End of controller check

    power="off"                                                                                    # Default power state to "off"
    if timeout 1 bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then power="on"; fi      # Check if adapter is powered on with 1-second timeout, grep for "Powered: yes", set power="on" if found

    connected_json="[]"                                                                            # Initialize connected devices JSON array as empty
    devices_json="[]"                                                                              # Initialize discovered/paired devices JSON array as empty

    if [ "$power" == "on" ]; then                                                                  # Only query devices if Bluetooth is powered on
        paired_macs=$(bluetoothctl devices Paired)                                                  # Get list of paired devices (MAC and name)
        mapfile -t devices < <(bluetoothctl devices)                                                 # Read all known devices into 'devices' array using process substitution and mapfile
        mapfile -t connected_info_lines < <(bluetoothctl devices Connected)                          # Read all connected devices into 'connected_info_lines' array
        
        connected_macs=""                                                                           # Initialize string to track MACs of connected devices (for filtering duplicates)
        connected_list_objs=()                                                                      # Initialize array for connected device JSON objects
        devices_list_objs=()                                                                        # Initialize array for discovered device JSON objects

        # 1. PROCESS CONNECTED DEVICES                                                              # Section comment - process actively connected devices first
        for c_line in "${connected_info_lines[@]}"; do                                                # Loop through each connected device line
            [ -z "$c_line" ] && continue                                                               # Skip empty lines (safety check)
            rest="${c_line#Device }"                                                                     # Remove "Device " prefix from the line to get "MAC Name"
            mac="${rest%% *}"                                                                            # Extract MAC address: everything before first space
            name="${rest#* }"                                                                            # Extract device name: everything after first space
            connected_macs+="$mac "                                                                      # Append this MAC to connected list (space-separated, used for filtering below)
            
            CACHE_FILE="$CACHE_DIR/bt_stat_${mac//:/_}"                                                   # Define cache file path for this device - replace colons with underscores in MAC for filename safety

            if [ -f "$CACHE_FILE" ]; then                                                                  # Check if cache file exists for this device
                source "$CACHE_FILE"                                                                         # Source the cache file to load CACHE_NAME, CACHE_ICON, CACHE_PROFILE variables
            else                                                                                             # Cache miss - need to query device info
                info=$(bluetoothctl info "$mac")                                                               # Get detailed device info from bluetoothctl
                icon_type=$(echo "$info" | awk -F': ' '/Icon:/ {print $2}')                                     # Extract the Icon field (device type category) from bluetoothctl info output
                icon=$(get_icon "$icon_type" "$name")                                                           # Call get_icon function with device type and name to get appropriate emoji
                profile=$(get_audio_profile "$mac")                                                              # Get active audio profile (A2DP, HFP, etc.) for this device
                
                echo "CACHE_NAME=\"${name//\"/\\\"}\"" > "$CACHE_FILE"                                           # Write escaped device name to cache file (escape double quotes for safe sourcing)
                echo "CACHE_ICON=\"${icon//\"/\\\"}\"" >> "$CACHE_FILE"                                           # Append escaped icon to cache file
                echo "CACHE_PROFILE=\"${profile//\"/\\\"}\"" >> "$CACHE_FILE"                                     # Append escaped profile to cache file
                
                CACHE_NAME="${name//\"/\\\"}"                                                                    # Set CACHE_NAME variable for immediate use
                CACHE_ICON="${icon//\"/\\\"}"                                                                    # Set CACHE_ICON variable for immediate use
                CACHE_PROFILE="${profile//\"/\\\"}"                                                              # Set CACHE_PROFILE variable for immediate use
            fi                                                                                               # End of cache check
            
            bat=$(bluetoothctl info "$mac" | awk -F'[(|)]' '/Battery Percentage:/ {print $2}')                 # Extract battery percentage from bluetoothctl info - uses parentheses or pipe as field separators
            [ -z "$bat" ] && bat="0"                                                                           # If battery info not available, default to "0"

            connected_list_objs+=("{\"id\":\"$mac\",\"name\":\"$CACHE_NAME\",\"mac\":\"$mac\",\"icon\":\"$CACHE_ICON\",\"battery\":\"$bat\",\"profile\":\"$CACHE_PROFILE\"}")  # Build JSON object for this connected device and add to array
        done                                                                                              # End of connected devices loop

        if [ ${#connected_list_objs[@]} -gt 0 ]; then                                                      # If we have any connected devices
            connected_json="[$(IFS=,; echo "${connected_list_objs[*]}")]"                                   # Join all connected device JSON objects with commas and wrap in brackets to form JSON array
        fi                                                                                                 # End of connected JSON check

        # 2. PROCESS DISCOVERED & PAIRED DEVICES                                                       # Section comment - process all known but not connected devices
        for line in "${devices[@]}"; do                                                                    # Loop through all known devices
            [ -z "$line" ] && continue                                                                      # Skip empty lines
            rest="${line#Device }"                                                                           # Remove "Device " prefix
            mac="${rest%% *}"                                                                                # Extract MAC address
            
            if [[ "$connected_macs" == *"$mac"* ]]; then continue; fi                                        # Skip this device if it's already in the connected list (avoids duplicates)

            name="${rest#* }"                                                                                # Extract device name
            name_esc="${name//\"/\\\"}"                                                                       # Escape double quotes in name for JSON safety

            if [[ "$paired_macs" == *"$mac"* ]]; then                                                         # Check if this device is already paired
                action="Connect"                                                                               # If paired: action is "Connect" (ready to connect)
            else                                                                                               # Device is not paired
                action="Pair"                                                                                   # If not paired: action is "Pair" (needs pairing first)
                if [[ "$STRICT_SPAM_FILTER" == true ]]; then                                                      # Check if strict spam filter is enabled
                    mac_hyphens="${mac//:/-}"                                                                       # Create hyphenated version of MAC address (AA:BB:CC -> AA-BB-CC)
                    if [[ "$name" == "$mac" || "$name" == "$mac_hyphens" || -z "$name" ]]; then                      # Check if device name is just its MAC address (no real name) or empty
                        continue                                                                                      # Skip this device - it's an unnamed/anonymous device (likely spam)
                    fi                                                                                             # End of name check
                fi                                                                                                # End of spam filter check
            fi                                                                                                # End of paired check

            icon=$(get_icon "unknown" "$name")                                                               # Get icon based on device name (type is unknown for non-connected devices)
            icon_esc="${icon//\"/\\\"}"                                                                       # Escape quotes in icon for JSON

            devices_list_objs+=("{\"id\":\"$mac\",\"name\":\"$name_esc\",\"mac\":\"$mac\",\"icon\":\"$icon_esc\",\"action\":\"$action\"}")  # Build JSON object for this device with id, name, mac, icon, and action (Connect/Pair)
        done                                                                                               # End of discovered devices loop

        if [ ${#devices_list_objs[@]} -gt 0 ]; then                                                         # If we have any discovered devices
            devices_json="[$(IFS=,; echo "${devices_list_objs[*]}")]"                                       # Join all device JSON objects with commas and wrap in brackets
        fi                                                                                                  # End of devices JSON check
    fi                                                                                                   # End of power-on check

    echo "{\"present\":true,\"power\":\"$power\",\"connected\":$connected_json,\"devices\":$devices_json}"  # Output final JSON: Bluetooth is present, power state, connected devices array, discovered devices array
}                                                                                                     # End of get_status function


toggle_power() {                                                                                      # Define function toggle_power - toggles Bluetooth adapter power on/off
    if bluetoothctl show | grep -q "Powered: yes"; then                                                  # Check if adapter is currently powered on
        bluetoothctl power off                                                                            # Power off the adapter
    else                                                                                                 # Adapter is powered off
        bluetoothctl power on                                                                             # Power on the adapter
    fi                                                                                                  # End of if-else
    sleep 0.5                                                                                           # Sleep 500ms to allow the adapter state change to take effect before next query
}                                                                                                     # End of toggle_power function

connect_dev() {                                                                                        # Define function connect_dev - connects to a specific Bluetooth device by MAC address
    local mac="$1"                                                                                       # Capture MAC address from first argument
    if [ -f "$PID_FILE" ]; then kill -STOP $(cat "$PID_FILE") 2>/dev/null; fi                            # If a scan process PID file exists, send SIGSTOP to pause it (prevents interference during connection)
    bluetoothctl trust "$mac" > /dev/null 2>&1                                                            # Trust the device (auto-connect in future), suppress all output
    bluetoothctl connect "$mac"                                                                            # Initiate connection to the device
    if [ -f "$PID_FILE" ]; then kill -CONT $(cat "$PID_FILE") 2>/dev/null; fi                              # If scan was paused, send SIGCONT to resume it after connection attempt
}                                                                                                     # End of connect_dev function

disconnect_dev() {                                                                                     # Define function disconnect_dev - disconnects from a specific Bluetooth device
    local mac="$1"                                                                                       # Capture MAC address from first argument
    rm -f "$CACHE_DIR/bt_stat_${mac//:/_}" 2>/dev/null                                                    # Remove the cached info file for this device to force fresh query on reconnect (clears stale data)
    bluetoothctl disconnect "$mac"                                                                         # Disconnect the device
}                                                                                                     # End of disconnect_dev function

cmd="$1"                                                                                               # Capture first command-line argument as the command to execute
case $cmd in                                                                                           # Begin case statement to route commands
    --status) get_status ;;                                                                             # If --status flag: call get_status function to output Bluetooth state JSON
    --toggle) toggle_power ;;                                                                           # If --toggle flag: call toggle_power to switch adapter on/off
    --connect) connect_dev "$2" ;;                                                                      # If --connect flag: call connect_dev with second argument as MAC address
    --disconnect) disconnect_dev "$2" ;;                                                                # If --disconnect flag: call disconnect_dev with second argument as MAC address
esac                                                                                                   # End of case statement