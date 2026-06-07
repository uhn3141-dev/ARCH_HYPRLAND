#!/usr/bin/env bash

# Zero-latency hardware presence check via sysfs (Instant, no nmcli hang)
if ! ls -1d /sys/class/net/*/wireless &>/dev/null; then
    echo '{ "present": false, "power": "off", "connected": null, "networks": [] }'
    exit 0
fi

POWER=$(LC_ALL=C nmcli radio wifi)

if [[ "$POWER" == "disabled" ]]; then
    echo '{ "present": true, "power": "off", "connected": null, "networks": [] }'
    exit 0
fi

get_icon() {
    local signal=$1
    if [[ $signal -ge 80 ]]; then echo "󰤨";
    elif [[ $signal -ge 60 ]]; then echo "󰤥";
    elif [[ $signal -ge 40 ]]; then echo "󰤢";
    elif [[ $signal -ge 20 ]]; then echo "󰤟";
    else echo "󰤯"; fi
}

CACHE_DIR="${XDG_RUNTIME_DIR:-$HOME/.cache}/quickshell_network_cache"
mkdir -p "$CACHE_DIR"

CURRENT_RAW=$(LC_ALL=C nmcli -t -f active,ssid,signal,security device wifi | awk -F: '$1=="yes"{print; exit}')

if [[ -n "$CURRENT_RAW" ]]; then
    IFS=':' read -r active ssid signal security <<< "$CURRENT_RAW"
    icon=$(get_icon "$signal")
    
    SAFE_SSID="${ssid//[^a-zA-Z0-9]/_}"
    CACHE_FILE="$CACHE_DIR/wifi_$SAFE_SSID"
    
    if [ -f "$CACHE_FILE" ]; then
        source "$CACHE_FILE"
    fi
    
    if [ -z "$IP" ] || [ "$IP" == "No IP" ] || [ -z "$FREQ" ]; then
        IFACE=$(LC_ALL=C nmcli -t -f DEVICE,TYPE d | awk -F: '$2=="wifi"{print $1;exit}')
        IP=$(ip -4 addr show dev "$IFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
        [ -z "$IP" ] && IP="No IP"
        
        FREQ=$(iw dev "$IFACE" link 2>/dev/null | awk '/freq:/ {print $2}')
        [ -n "$FREQ" ] && FREQ="${FREQ} MHz" || FREQ="Unknown"
        
        echo "IP=\"$IP\"" > "$CACHE_FILE"
        echo "FREQ=\"$FREQ\"" >> "$CACHE_FILE"
    fi

    # Native Bash JSON generation
    ssid_esc="${ssid//\"/\\\"}"
    sec_esc="${security//\"/\\\"}"
    icon_esc="${icon//\"/\\\"}"
    CONNECTED_JSON="{\"id\":\"$ssid_esc\",\"ssid\":\"$ssid_esc\",\"icon\":\"$icon_esc\",\"signal\":\"$signal\",\"security\":\"$sec_esc\",\"ip\":\"$IP\",\"freq\":\"$FREQ\"}"
else
    CONNECTED_JSON="null"
fi

# AWK processes the entire network list natively, zero sub-shells
NETWORKS_JSON=$(LC_ALL=C nmcli -t -f active,ssid,signal,security device wifi list --rescan no | awk -F: '
    !seen[$2]++ && $2 != "" && $1 != "yes" {
        ssid=$2; signal=$3; security=$4;
        
        # Escape quotes inside strings
        gsub(/"/, "\\\"", ssid);
        gsub(/"/, "\\\"", security);
        
        if (signal >= 80) icon="󰤨";
        else if (signal >= 60) icon="󰤥";
        else if (signal >= 40) icon="󰤢";
        else if (signal >= 20) icon="󰤟";
        else icon="󰤯";
        
        printf "{\"id\":\"%s\",\"ssid\":\"%s\",\"icon\":\"%s\",\"signal\":\"%s\",\"security\":\"%s\"}\n", ssid, ssid, icon, signal, security
    }
' | head -n 24 | paste -sd, -)

if [ -z "$NETWORKS_JSON" ]; then
    NETWORKS_JSON="[]"
else
    NETWORKS_JSON="[$NETWORKS_JSON]"
fi

# Final JSON output
echo "{\"present\":true,\"power\":\"on\",\"connected\":$CONNECTED_JSON,\"networks\":$NETWORKS_JSON}"


#!/usr/bin/env bash                                                                               # Shebang - specifies this script should be executed using the bash shell from the user's PATH environment

# Zero-latency hardware presence check via sysfs (Instant, no nmcli hang)                         # Comment explaining the fast hardware detection method
if ! ls -1d /sys/class/net/*/wireless &>/dev/null; then                                            # Check if ANY wireless interfaces exist - the 'wireless' subdirectory only exists inside WiFi interface directories, glob matches all net interfaces, suppress all output
    echo '{ "present": false, "power": "off", "connected": null, "networks": [] }'                  # No WiFi hardware found: output JSON with present=false, power off, null connected, empty networks array
    exit 0                                                                                           # Exit script successfully - no WiFi hardware to manage
fi                                                                                                # End of hardware presence check

POWER=$(LC_ALL=C nmcli radio wifi)                                                                # Check WiFi radio state using nmcli with C locale (ensures English output) - returns "enabled" or "disabled"

if [[ "$POWER" == "disabled" ]]; then                                                              # Check if WiFi radio is disabled (turned off via hardware switch, airplane mode, or software kill)
    echo '{ "present": true, "power": "off", "connected": null, "networks": [] }'                   # WiFi hardware exists but radio is off: output JSON with present=true, power off, null connected, empty networks
    exit 0                                                                                           # Exit script - no need to scan networks when radio is off
fi                                                                                                # End of power check

get_icon() {                                                                                      # Define function get_icon - returns a WiFi signal strength icon based on percentage
    local signal=$1                                                                                 # Capture signal strength percentage from first argument
    if [[ $signal -ge 80 ]]; then echo "󰤨";                                                       # 80% or above: full signal icon (4 bars)
    elif [[ $signal -ge 60 ]]; then echo "󰤥";                                                     # 60-79%: 3 bars icon
    elif [[ $signal -ge 40 ]]; then echo "󰤢";                                                     # 40-59%: 2 bars icon
    elif [[ $signal -ge 20 ]]; then echo "󰤟";                                                     # 20-39%: 1 bar icon
    else echo "󰤯"; fi                                                                              # Below 20%: no signal/weak icon (0 bars with X)
}                                                                                                # End of get_icon function

CACHE_DIR="${XDG_RUNTIME_DIR:-$HOME/.cache}/quickshell_network_cache"                             # Define CACHE_DIR - uses XDG_RUNTIME_DIR if set (typically /run/user/UID), falls back to ~/.cache/quickshell_network_cache
mkdir -p "$CACHE_DIR"                                                                             # Create cache directory if it doesn't exist - -p creates parent directories and doesn't error if exists

CURRENT_RAW=$(LC_ALL=C nmcli -t -f active,ssid,signal,security device wifi | awk -F: '$1=="yes"{print; exit}')  # Get currently connected WiFi network: nmcli in terse mode filtering for active connection (field1="yes"), awk prints first match and exits

if [[ -n "$CURRENT_RAW" ]]; then                                                                   # Check if a connected WiFi network was found (CURRENT_RAW is non-empty)
    IFS=':' read -r active ssid signal security <<< "$CURRENT_RAW"                                   # Parse the colon-separated line into variables: active flag, SSID name, signal strength, security type
    icon=$(get_icon "$signal")                                                                       # Call get_icon function with signal strength to get appropriate WiFi icon
    
    SAFE_SSID="${ssid//[^a-zA-Z0-9]/_}"                                                              # Create filesystem-safe SSID by replacing all non-alphanumeric characters with underscores (used for cache filename)
    CACHE_FILE="$CACHE_DIR/wifi_$SAFE_SSID"                                                           # Define cache file path using the sanitized SSID
    
    if [ -f "$CACHE_FILE" ]; then                                                                      # Check if cache file exists for this network
        source "$CACHE_FILE"                                                                            # Source the cache file to load IP and FREQ variables from previous query
    fi                                                                                                # End of cache check
    
    if [ -z "$IP" ] || [ "$IP" == "No IP" ] || [ -z "$FREQ" ]; then                                   # Check if IP is missing/invalid or frequency hasn't been cached yet
        IFACE=$(LC_ALL=C nmcli -t -f DEVICE,TYPE d | awk -F: '$2=="wifi"{print $1;exit}')               # Get the WiFi interface name (e.g., wlan0, wlp3s0) using nmcli with awk to find type "wifi"
        IP=$(ip -4 addr show dev "$IFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)  # Extract IPv4 address from interface: use Perl regex lookbehind for "inet " followed by IP pattern, take first match
        [ -z "$IP" ] && IP="No IP"                                                                       # If no IP found (no DHCP lease), set placeholder "No IP"
        
        FREQ=$(iw dev "$IFACE" link 2>/dev/null | awk '/freq:/ {print $2}')                              # Get WiFi frequency from 'iw' command: search for "freq:" line, print second field (frequency in MHz)
        [ -n "$FREQ" ] && FREQ="${FREQ} MHz" || FREQ="Unknown"                                           # If frequency exists, append " MHz" unit; otherwise set "Unknown"
        
        echo "IP=\"$IP\"" > "$CACHE_FILE"                                                               # Write IP address to cache file (overwrites any existing)
        echo "FREQ=\"$FREQ\"" >> "$CACHE_FILE"                                                          # Append frequency to cache file
    fi                                                                                                # End of cache update check

    # Native Bash JSON generation                                                                     # Comment - build JSON manually without calling jq (faster, avoids external dependency)
    ssid_esc="${ssid//\"/\\\"}"                                                                        # Escape double quotes in SSID for JSON safety (replace " with \")
    sec_esc="${security//\"/\\\"}"                                                                      # Escape double quotes in security type
    icon_esc="${icon//\"/\\\"}"                                                                         # Escape double quotes in icon (though unlikely to contain any)
    CONNECTED_JSON="{\"id\":\"$ssid_esc\",\"ssid\":\"$ssid_esc\",\"icon\":\"$icon_esc\",\"signal\":\"$signal\",\"security\":\"$sec_esc\",\"ip\":\"$IP\",\"freq\":\"$FREQ\"}"  # Build JSON object string with all connection details: id, SSID, icon, signal strength, security, IP, frequency
else                                                                                                # No connected WiFi network found
    CONNECTED_JSON="null"                                                                             # Set connected to JSON null literal
fi                                                                                                # End of connected network check

# AWK processes the entire network list natively, zero sub-shells                                  # Comment explaining the performance optimization - single awk process instead of multiple subshells
NETWORKS_JSON=$(LC_ALL=C nmcli -t -f active,ssid,signal,security device wifi list --rescan no | awk -F: '  # Get list of available WiFi networks: nmcli with --rescan no (use cached scan), pipe to awk with colon field separator
    !seen[$2]++ && $2 != "" && $1 != "yes" {                                                           # Process each network: skip if SSID already seen (deduplication), skip empty SSIDs, skip active/connected network ($1="yes")
        ssid=$2; signal=$3; security=$4;                                                                 # Assign fields to readable variable names
        
        # Escape quotes inside strings                                                                    # Comment - ensure JSON validity
        gsub(/"/, "\\\"", ssid);                                                                          # Escape double quotes in SSID using global substitution
        gsub(/"/, "\\\"", security);                                                                       # Escape double quotes in security type
        
        if (signal >= 80) icon="󰤨";                                                                      # Signal >= 80%: full bars icon
        else if (signal >= 60) icon="󰤥";                                                                 # 60-79%: 3 bars
        else if (signal >= 40) icon="󰤢";                                                                 # 40-59%: 2 bars
        else if (signal >= 20) icon="󰤟";                                                                 # 20-39%: 1 bar
        else icon="󰤯";                                                                                   # Below 20%: weak/no signal icon
        
        printf "{\"id\":\"%s\",\"ssid\":\"%s\",\"icon\":\"%s\",\"signal\":\"%s\",\"security\":\"%s\"}\n", ssid, ssid, icon, signal, security  # Print JSON object for this network on a separate line
    }                                                                                                  # End of awk pattern-action block
' | head -n 24 | paste -sd, -)                                                                        # Take first 24 networks (limits output size), then join all lines with commas using paste

if [ -z "$NETWORKS_JSON" ]; then                                                                     # Check if networks JSON is empty (no networks found)
    NETWORKS_JSON="[]"                                                                                 # Set to empty JSON array
else                                                                                                 # Networks exist
    NETWORKS_JSON="[$NETWORKS_JSON]"                                                                   # Wrap the comma-separated network objects in square brackets to form valid JSON array
fi                                                                                                  # End of networks JSON construction

# Final JSON output                                                                                  # Comment - output the complete WiFi status JSON
echo "{\"present\":true,\"power\":\"on\",\"connected\":$CONNECTED_JSON,\"networks\":$NETWORKS_JSON}"  # Output JSON: WiFi is present, power is on, connected network (object or null), available networks array