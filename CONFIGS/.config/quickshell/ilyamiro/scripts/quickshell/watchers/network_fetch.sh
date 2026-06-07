# #!/usr/bin/env bash

# get_wifi_radio() {
#     LC_ALL=C nmcli radio wifi 2>/dev/null
# }

# get_wifi_ssid() {
#     local ssid=""
#     if command -v iw &>/dev/null; then
#         ssid=$(LC_ALL=C iw dev 2>/dev/null | awk '/\s+ssid/ { $1=""; sub(/^ /, ""); print; exit }')
#     fi
#     if [ -z "$ssid" ]; then
#         ssid=$(LC_ALL=C nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '/802-11-wireless/ {print $1; exit}')
#     fi
#     echo "${ssid:-}"
# }

# get_wifi_strength() {
#     local signal=$(LC_ALL=C awk 'NR==3 {gsub(/\./,"",$3); print int($3 * 100 / 70)}' /proc/net/wireless 2>/dev/null)
#     echo "${signal:-0}"
# }

# get_network_data() {
#     # Find the active interface routing internet traffic
#     local active_iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
#     local iface_type=""
    
#     if [ -n "$active_iface" ]; then
#         iface_type=$(LC_ALL=C nmcli -t -f DEVICE,TYPE d 2>/dev/null | awk -F: -v dev="$active_iface" '$1==dev {print $2; exit}')
#     fi

#     local status=""
#     local ssid=""
#     local icon=""
#     local eth_status="Disconnected"

#     # Scenario 1: Ethernet is actively providing internet
#     if [ "$iface_type" = "ethernet" ]; then
#         status="enabled"
#         ssid="Ethernet"
#         icon="󰈀"
#         eth_status="Connected"
        
#     # Scenario 2: Wi-Fi is actively providing internet
#     elif [ "$iface_type" = "wifi" ]; then
#         status="enabled"
#         ssid=$(get_wifi_ssid)
#         local signal=$(get_wifi_strength)
#         if [ "$signal" -ge 75 ]; then icon="󰤨"
#         elif [ "$signal" -ge 50 ]; then icon="󰤥"
#         elif [ "$signal" -ge 25 ]; then icon="󰤢"
#         else icon="󰤟"; fi
        
#         # Still check if an ethernet cable is plugged in silently in the background
#         local eth_dev=$(LC_ALL=C nmcli -t -f DEVICE,TYPE,STATE d 2>/dev/null | awk -F: '$2=="ethernet" && $3=="connected" && $1 != "lo" {print $1; exit}')
#         if [ -n "$eth_dev" ]; then eth_status="Connected"; fi
        
#     # Scenario 3: No active internet connection
#     else
#         local radio=$(get_wifi_radio)
#         local wifi_dev=$(LC_ALL=C nmcli -t -f DEVICE,TYPE d 2>/dev/null | awk -F: '$2=="wifi" {print $1; exit}')
        
#         if [ -z "$wifi_dev" ]; then
#             # No Wi-Fi hardware exists, and Ethernet is unplugged
#             status="disabled"
#             ssid=""
#             icon="󰈂"
#         elif [ "$radio" = "disabled" ]; then
#             # Wi-Fi hardware exists, but the radio is turned off
#             status="disabled"
#             ssid=""
#             icon="󰤮"
#         else
#             # Wi-Fi is turned on, but not connected to any network
#             status="enabled"
#             ssid=""
#             icon="󰤯"
#         fi
#     fi

#     echo "$status|$ssid|$icon|$eth_status"
# }

# toggle_wifi() {
#     if [ "$(get_wifi_radio)" = "enabled" ]; then
#         LC_ALL=C nmcli radio wifi off
#         notify-send -u low -i network-wireless-disabled "WiFi" "Disabled"
#     else
#         LC_ALL=C nmcli radio wifi on
#         notify-send -u low -i network-wireless-enabled "WiFi" "Enabled"
#     fi
# }

# case $1 in
#     --toggle) toggle_wifi ;;
#     *) 
#         IFS='|' read -r status ssid icon eth <<< "$(get_network_data)"
        
#         jq -n -c \
#             --arg status "$status" \
#             --arg ssid "$ssid" \
#             --arg icon "$icon" \
#             --arg eth "$eth" \
#             '{status: $status, ssid: $ssid, icon: $icon, eth_status: $eth}' ;;
# esac





#!/usr/bin/env bash                                                              # Shebang line that tells the system to execute this script using the bash interpreter found in the user's PATH environment variable (more portable than hardcoding /bin/bash)

get_wifi_radio() {                                                              # Defines a function that checks whether the WiFi radio hardware is enabled or disabled
    LC_ALL=C nmcli radio wifi 2>/dev/null                                      # Sets C locale for consistent output, runs nmcli to query the WiFi radio status (returns "enabled" or "disabled"), suppresses any error output
}                                                                               # Closes the get_wifi_radio function definition

get_wifi_ssid() {                                                               # Defines a function that retrieves the SSID (network name) of the currently connected WiFi network
    local ssid=""                                                               # Declares a local variable 'ssid' scoped to this function and initializes it as an empty string
    if command -v iw &>/dev/null; then                                         # Checks if the 'iw' command (nl80211 wireless tool) is available in the system PATH, redirecting both stdout and stderr to /dev/null
        ssid=$(LC_ALL=C iw dev 2>/dev/null | awk '/\s+ssid/ { $1=""; sub(/^ /, ""); print; exit }')  # Sets C locale, runs 'iw dev' to list wireless interfaces, suppresses errors, pipes to awk which searches for lines containing whitespace followed by "ssid", then clears the first field ($1=""), removes the leading space with sub(), prints the cleaned SSID name, and exits after the first match
    fi                                                                           # Closes the iw if block
    if [ -z "$ssid" ]; then                                                    # If the ssid variable is still empty (iw didn't find it or iw is not available)
        ssid=$(LC_ALL=C nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '/802-11-wireless/ {print $1; exit}')  # Falls back to nmcli: uses terse mode (-t) and requests only the NAME and TYPE fields (-f), shows only active connections, suppresses errors, pipes through awk with colon as field separator which matches lines containing "802-11-wireless" (WiFi connection type) and prints the first field (connection name), then exits immediately
    fi                                                                           # Closes the fallback if block
    echo "${ssid:-}"                                                            # Prints the SSID value, using bash parameter expansion to default to an empty string if ssid is unset or null (safe fallback)
}                                                                               # Closes the get_wifi_ssid function definition

get_wifi_strength() {                                                           # Defines a function that calculates WiFi signal strength as a percentage from the kernel's wireless statistics
    local signal=$(LC_ALL=C awk 'NR==3 {gsub(/\./,"",$3); print int($3 * 100 / 70)}' /proc/net/wireless 2>/dev/null)  # Sets C locale, uses awk to process /proc/net/wireless: specifically reads the third line (NR==3 which contains the first wireless interface stats after the headers), removes any decimal point from the third field using gsub (e.g., converts "-45." to "-45"), calculates percentage by multiplying by 100 and dividing by 70 (where -70 dBm is considered a good signal floor, though this is a rough approximation), converts to integer with int(), suppresses errors if the file doesn't exist
    echo "${signal:-0}"                                                         # Prints the signal strength percentage, defaulting to 0 if the calculation returned empty or failed
}                                                                               # Closes the get_wifi_strength function definition

get_network_data() {                                                            # Defines the main function that gathers all network information and returns a pipe-delimited string of status, SSID, icon, and ethernet status
    # Find the active interface routing internet traffic                         # Comment explaining that we need to identify which network interface is currently handling the default route (actual internet traffic)
    local active_iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')  # Declares a local variable, runs 'ip route show default' to display the default gateway route, suppresses errors, pipes through awk which finds the line containing "default" and prints the fifth field (the interface name, e.g., "wlan0" or "eth0"), then exits after the first match
    local iface_type=""                                                         # Declares a local variable to store the interface type (e.g., "ethernet" or "wifi") and initializes it as empty
    
    if [ -n "$active_iface" ]; then                                            # If the active interface variable is not empty (a default route exists, meaning there is an active internet connection)
        iface_type=$(LC_ALL=C nmcli -t -f DEVICE,TYPE d 2>/dev/null | awk -F: -v dev="$active_iface" '$1==dev {print $2; exit}')  # Sets C locale, uses nmcli in terse mode (-t) to list all devices with only DEVICE and TYPE fields (-f), suppresses errors, pipes to awk using colon as field separator, passes the active_iface as a variable (-v dev=...), matches the line where the first field equals that device name, prints the second field (the device type like "ethernet" or "wifi"), and exits immediately
    fi                                                                           # Closes the active_iface check

    local status=""                                                             # Declares a local variable to store the network status string ("enabled" or "disabled")
    local ssid=""                                                               # Declares a local variable to store the network name/SSID
    local icon=""                                                               # Declares a local variable to store the Nerd Font icon for the current network state
    local eth_status="Disconnected"                                             # Declares a local variable for ethernet status and defaults to "Disconnected"

    # Scenario 1: Ethernet is actively providing internet                        # Comment explaining the first network scenario: ethernet is the active connection carrying internet traffic
    if [ "$iface_type" = "ethernet" ]; then                                    # Checks if the active interface type is ethernet
        status="enabled"                                                        # Sets status to "enabled" since the network connection is active
        ssid="Ethernet"                                                         # Sets SSID to the literal string "Ethernet" since wired connections don't have SSIDs
        icon="󰈀"                                                               # Sets icon to the Nerd Font ethernet icon (󰈀 - network port/server icon)
        eth_status="Connected"                                                  # Updates ethernet status to "Connected" since we confirmed ethernet is the active connection
        
    # Scenario 2: Wi-Fi is actively providing internet                          # Comment explaining the second network scenario: WiFi is the active connection carrying internet traffic
    elif [ "$iface_type" = "wifi" ]; then                                      # Checks if the active interface type is wifi
        status="enabled"                                                        # Sets status to "enabled" since WiFi is connected and carrying traffic
        ssid=$(get_wifi_ssid)                                                   # Calls the get_wifi_ssid function to retrieve the actual WiFi network name (e.g., "MyHomeNetwork")
        local signal=$(get_wifi_strength)                                       # Declares a local variable and calls get_wifi_strength to get the signal strength percentage
        if [ "$signal" -ge 75 ]; then icon="󰤨"                                 # If signal strength is 75% or higher, uses the "full WiFi bars with connection" icon (󰤨 - four bars)
        elif [ "$signal" -ge 50 ]; then icon="󰤥"                              # If signal is between 50-74%, uses the "three WiFi bars" icon (󰤥)
        elif [ "$signal" -ge 25 ]; then icon="󰤢"                              # If signal is between 25-49%, uses the "two WiFi bars" icon (󰤢)
        else icon="󰤟"; fi                                                      # If signal is below 25%, uses the "one WiFi bar" icon (󰤟); fi closes the signal strength if-elif chain
        
        # Still check if an ethernet cable is plugged in silently in the background  # Comment explaining that even though WiFi is active, we should check if ethernet is also connected (cable plugged in but not the default route)
        local eth_dev=$(LC_ALL=C nmcli -t -f DEVICE,TYPE,STATE d 2>/dev/null | awk -F: '$2=="ethernet" && $3=="connected" && $1 != "lo" {print $1; exit}')  # Declares a local variable, uses nmcli in terse mode to list all devices with DEVICE, TYPE, and STATE fields, suppresses errors, pipes to awk with colon separator which matches lines where: the second field is "ethernet", the third field is "connected", and the first field is not "lo" (excludes loopback), then prints the device name and exits immediately
        if [ -n "$eth_dev" ]; then eth_status="Connected"; fi                  # If an ethernet device was found in connected state, updates eth_status to "Connected" (even though not the active route, the cable is plugged in)
        
    # Scenario 3: No active internet connection                                 # Comment explaining the third network scenario: there is no interface with a default route (no internet connectivity)
    else                                                                         # If the active interface type is neither ethernet nor wifi (or no default route exists)
        local radio=$(get_wifi_radio)                                           # Calls get_wifi_radio to check the WiFi radio state and stores it in a local variable
        local wifi_dev=$(LC_ALL=C nmcli -t -f DEVICE,TYPE d 2>/dev/null | awk -F: '$2=="wifi" {print $1; exit}')  # Declares a local variable, uses nmcli to find any WiFi device regardless of connection state, filters for device type "wifi", prints the device name, and exits after the first match
        
        if [ -z "$wifi_dev" ]; then                                            # If no WiFi device exists at all (no WiFi hardware in the system)
            # No Wi-Fi hardware exists, and Ethernet is unplugged               # Comment clarifying this sub-scenario: complete absence of wireless hardware
            status="disabled"                                                   # Sets status to "disabled" since there's no way to connect wirelessly
            ssid=""                                                             # Sets SSID to empty string (no network)
            icon="󰈂"                                                           # Uses the "disconnected/wireless unavailable" icon (󰈂)
        elif [ "$radio" = "disabled" ]; then                                    # Else if WiFi hardware exists but the radio transmitter is turned off (airplane mode or manually disabled)
            # Wi-Fi hardware exists, but the radio is turned off                # Comment clarifying this sub-scenario: hardware present but radio disabled
            status="disabled"                                                   # Sets status to "disabled" since WiFi cannot scan or connect
            ssid=""                                                             # Sets SSID to empty string
            icon="󰤮"                                                           # Uses the "WiFi off/disabled" icon (󰤮 - WiFi symbol with slash)
        else                                                                     # Else WiFi hardware exists and radio is on, but not connected to any network
            # Wi-Fi is turned on, but not connected to any network              # Comment clarifying this sub-scenario: WiFi is on and scanning but not associated with any access point
            status="enabled"                                                    # Sets status to "enabled" (WiFi is on and functional, just not connected)
            ssid=""                                                             # Sets SSID to empty string (no network joined)
            icon="󰤯"                                                           # Uses the "WiFi searching/disconnected" icon (󰤯 - WiFi symbol with question mark or no bars)
        fi                                                                       # Closes the inner if-elif-else chain for no-connection scenarios
    fi                                                                           # Closes the outer if-elif-else chain for all network scenarios

    echo "$status|$ssid|$icon|$eth_status"                                      # Outputs all four pieces of network data as a single pipe-delimited string that the caller can parse by splitting on the pipe character
}                                                                               # Closes the get_network_data function definition

toggle_wifi() {                                                                 # Defines a function that toggles the WiFi radio state and sends a desktop notification
    if [ "$(get_wifi_radio)" = "enabled" ]; then                               # Calls get_wifi_radio and checks if the current WiFi radio state is "enabled"
        LC_ALL=C nmcli radio wifi off                                          # If WiFi is on, turns it off using nmcli with C locale for consistent output
        notify-send -u low -i network-wireless-disabled "WiFi" "Disabled"      # Sends a low-urgency desktop notification with the wireless-disabled icon, title "WiFi", and message "Disabled"
    else                                                                         # If WiFi radio is not enabled (it's disabled)
        LC_ALL=C nmcli radio wifi on                                           # Turns the WiFi radio on using nmcli
        notify-send -u low -i network-wireless-enabled "WiFi" "Enabled"        # Sends a low-urgency desktop notification with the wireless-enabled icon, title "WiFi", and message "Enabled"
    fi                                                                           # Closes the if-else block
}                                                                               # Closes the toggle_wifi function definition

case $1 in                                                                      # Begins a case statement that evaluates the first command-line argument ($1) passed to the script
    --toggle) toggle_wifi ;;                                                    # If the argument is "--toggle", executes the toggle_wifi function to flip the WiFi radio state; ;; terminates this case branch
    *)                                                                           # Default case for any other argument (including no argument at all)
        IFS='|' read -r status ssid icon eth <<< "$(get_network_data)"         # Temporarily sets the Internal Field Separator to the pipe character, reads the output of get_network_data (which returns a pipe-delimited string), and splits it into four separate variables: status, ssid, icon, and eth; the -r flag prevents backslash interpretation, and <<< is a here-string that feeds the command substitution result as stdin to read
        
        jq -n -c \                                                              # Begins a jq command to construct JSON: -n uses null input since we'll provide all data via --arg, -c outputs compact single-line format; the backslash continues the command to the next line
            --arg status "$status" \                                            # Passes the status variable as a JSON argument named $status
            --arg ssid "$ssid" \                                                # Passes the ssid (network name) variable as a JSON argument named $ssid
            --arg icon "$icon" \                                                # Passes the icon (Nerd Font glyph) variable as a JSON argument named $icon
            --arg eth "$eth" \                                                  # Passes the eth (ethernet status) variable as a JSON argument named $eth
            '{status: $status, ssid: $ssid, icon: $icon, eth_status: $eth}' ;;# Constructs a JSON object with four fields: status (enabled/disabled), ssid (network name or empty), icon (Nerd Font icon), and eth_status (Connected/Disconnected); ;; terminates the default case branch
esac                                                                             # Ends the case statement block