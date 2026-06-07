# #!/usr/bin/env bash

# # Zero-latency hardware presence check via sysfs (Instant, no nmcli latency)
# # Checks for any network interface starting with 'e' (eth0, enp4s0, eno1, etc.)
# if ! ls -1d /sys/class/net/e* &>/dev/null; then
#     jq -nc --arg power "off" '{ "present": false, "power": $power, "device": "", "connected": null }'
#     exit 0
# fi

# # Use LC_ALL=C to prevent nmcli from translating output
# # Find the first ethernet device regardless of state
# ETH_DEV=$(LC_ALL=C nmcli -t -f DEVICE,TYPE d 2>/dev/null | awk -F: '$2=="ethernet" {print $1; exit}')

# # Fallback check if nmcli disagrees with the sysfs check
# if [[ -z "$ETH_DEV" ]]; then
#     jq -nc --arg power "off" '{ "present": false, "power": $power, "device": "", "connected": null }'
#     exit 0
# fi

# # Fetch the specific state of that device
# STATE=$(LC_ALL=C nmcli -t -f DEVICE,STATE d 2>/dev/null | awk -F: -v dev="$ETH_DEV" '$1==dev {print $2; exit}')

# if [[ "$STATE" == "connected" || "$STATE" == "connecting" ]]; then
#     POWER="on"
    
#     # Fetch connection statistics
#     IP=$(ip -4 addr show dev "$ETH_DEV" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
#     [ -z "$IP" ] && IP="No IP"

#     SPEED=$(cat /sys/class/net/"$ETH_DEV"/speed 2>/dev/null)
#     [ -n "$SPEED" ] && SPEED="${SPEED} Mbps" || SPEED="Unknown"

#     MAC=$(cat /sys/class/net/"$ETH_DEV"/address 2>/dev/null)

#     # Apply LC_ALL=C here as well to ensure consistent parsing
#     PROFILE=$(LC_ALL=C nmcli -t -f NAME,DEVICE c show --active 2>/dev/null | grep ":$ETH_DEV$" | cut -d: -f1 | head -n1)
#     [ -z "$PROFILE" ] && PROFILE="Wired Connection"

#     CONNECTED_JSON=$(jq -nc \
#         --arg id "$ETH_DEV" \
#         --arg name "$PROFILE" \
#         --arg icon "󰈀" \
#         --arg ip "$IP" \
#         --arg speed "$SPEED" \
#         --arg mac "$MAC" \
#         '{id: $id, name: $name, icon: $icon, ip: $ip, speed: $speed, mac: $mac}')
# else
#     POWER="off"
#     CONNECTED_JSON="null"
# fi

# # Output JSON cleanly, including the device name even if offline
# jq -nc \
#     --arg power "$POWER" \
#     --arg device "$ETH_DEV" \
#     --argjson connected "$CONNECTED_JSON" \
#     '{present: true, power: $power, device: $device, connected: $connected}'



#!/usr/bin/env bash                                                                               # Shebang - specifies this script should be executed using the bash shell from the user's PATH environment

# Zero-latency hardware presence check via sysfs (Instant, no nmcli latency)                      # Comment explaining the fast hardware detection approach
# Checks for any network interface starting with 'e' (eth0, enp4s0, eno1, etc.)                   # Comment listing common ethernet interface naming patterns
if ! ls -1d /sys/class/net/e* &>/dev/null; then                                                    # Check if ANY ethernet interfaces exist in sysfs - glob pattern 'e*' matches eth0, enp*, eno*, etc., suppress all output and errors
    jq -nc --arg power "off" '{ "present": false, "power": $power, "device": "", "connected": null }'  # No ethernet hardware found: output JSON with present=false, power off, empty device, null connected
    exit 0                                                                                           # Exit script successfully - no ethernet hardware to query
fi                                                                                                # End of hardware presence check

# Use LC_ALL=C to prevent nmcli from translating output                                            # Comment explaining locale override - ensures consistent English output regardless of system language
# Find the first ethernet device regardless of state                                               # Comment describing the device detection strategy
ETH_DEV=$(LC_ALL=C nmcli -t -f DEVICE,TYPE d 2>/dev/null | awk -F: '$2=="ethernet" {print $1; exit}')  # Run nmcli in terse mode (-t), filter fields DEVICE and TYPE, pipe to awk: split on colon, if second field is "ethernet" print first field (device name) and exit (first match only)

# Fallback check if nmcli disagrees with the sysfs check                                           # Comment explaining the fallback - handles cases where sysfs shows interfaces but nmcli doesn't list them
if [[ -z "$ETH_DEV" ]]; then                                                                       # Check if ETH_DEV is empty (nmcli didn't find any ethernet devices)
    jq -nc --arg power "off" '{ "present": false, "power": $power, "device": "", "connected": null }'  # Output no-ethernet JSON
    exit 0                                                                                           # Exit script
fi                                                                                                # End of fallback check

# Fetch the specific state of that device                                                          # Comment - query the connection state of the detected ethernet device
STATE=$(LC_ALL=C nmcli -t -f DEVICE,STATE d 2>/dev/null | awk -F: -v dev="$ETH_DEV" '$1==dev {print $2; exit}')  # Run nmcli to get device states, pipe to awk with device variable: if first field matches ETH_DEV, print second field (state) and exit

if [[ "$STATE" == "connected" || "$STATE" == "connecting" ]]; then                                 # Check if ethernet is connected or in the process of connecting
    POWER="on"                                                                                       # Set POWER to "on" - ethernet link is active
    
    # Fetch connection statistics                                                                    # Comment - gather detailed connection information
    IP=$(ip -4 addr show dev "$ETH_DEV" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)  # Get IPv4 address: show addresses for the device, use Perl regex to extract IP after "inet ", take first match only
    [ -z "$IP" ] && IP="No IP"                                                                       # If IP address is empty (no DHCP lease or static IP), set to "No IP" placeholder

    SPEED=$(cat /sys/class/net/"$ETH_DEV"/speed 2>/dev/null)                                        # Read link speed from sysfs speed file (in Mbps), suppress errors if file doesn't exist
    [ -n "$SPEED" ] && SPEED="${SPEED} Mbps" || SPEED="Unknown"                                     # If speed value exists, append " Mbps" unit; otherwise set to "Unknown"

    MAC=$(cat /sys/class/net/"$ETH_DEV"/address 2>/dev/null)                                        # Read MAC address from sysfs address file, suppress errors

    # Apply LC_ALL=C here as well to ensure consistent parsing                                      # Comment explaining locale override for profile name parsing
    PROFILE=$(LC_ALL=C nmcli -t -f NAME,DEVICE c show --active 2>/dev/null | grep ":$ETH_DEV$" | cut -d: -f1 | head -n1)  # Get active connection profiles: filter for lines ending with ":$ETH_DEV", cut first field (profile name), take first match
    [ -z "$PROFILE" ] && PROFILE="Wired Connection"                                                  # If no profile name found, use generic "Wired Connection" as fallback

    CONNECTED_JSON=$(jq -nc \                                                                       # Build JSON object for connected state using jq: -n for no input, -c for compact output
        --arg id "$ETH_DEV" \                                                                        # Pass device name as 'id' argument
        --arg name "$PROFILE" \                                                                      # Pass connection profile name as 'name'
        --arg icon "󰈀" \                                                                            # Pass ethernet icon (Nerd Font network symbol) as 'icon'
        --arg ip "$IP" \                                                                             # Pass IP address as 'ip'
        --arg speed "$SPEED" \                                                                       # Pass link speed as 'speed'
        --arg mac "$MAC" \                                                                           # Pass MAC address as 'mac'
        '{id: $id, name: $name, icon: $icon, ip: $ip, speed: $speed, mac: $mac}')                   # Build JSON object with all connection details
else                                                                                               # Ethernet is not connected or connecting (disconnected/unmanaged/unavailable)
    POWER="off"                                                                                      # Set POWER to "off" - no active ethernet connection
    CONNECTED_JSON="null"                                                                            # Set connected JSON to literal null (no active connection data)
fi                                                                                                # End of state check

# Output JSON cleanly, including the device name even if offline                                   # Comment explaining the final output format
jq -nc \                                                                                           # Build final JSON output with jq: -n no input, -c compact
    --arg power "$POWER" \                                                                          # Pass power state as 'power' argument
    --arg device "$ETH_DEV" \                                                                       # Pass device name as 'device' (always included, even when offline)
    --argjson connected "$CONNECTED_JSON" \                                                         # Pass connected JSON object as raw JSON (--argjson prevents double-quoting)
    '{present: true, power: $power, device: $device, connected: $connected}'                        # Build final JSON: always present=true (hardware exists), power state, device name, connected details (null or object)