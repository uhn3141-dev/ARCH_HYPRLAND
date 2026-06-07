# #!/usr/bin/env bash
# get_battery_percent() { LC_ALL=C cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo "100"; }
# get_battery_status() { LC_ALL=C cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1 || echo "Full"; }
# get_battery_icon() {
#     local percent=$(get_battery_percent)
#     local status=$(get_battery_status)
#     if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
#         if [ "$percent" -ge 90 ]; then echo "󰂅"
#         elif [ "$percent" -ge 80 ]; then echo "󰂋"
#         elif [ "$percent" -ge 60 ]; then echo "󰂊"
#         elif [ "$percent" -ge 40 ]; then echo "󰢞"
#         elif [ "$percent" -ge 20 ]; then echo "󰂆"
#         else echo "󰢜"; fi
#     else
#         if [ "$percent" -ge 90 ]; then echo "󰁹"
#         elif [ "$percent" -ge 80 ]; then echo "󰂂"
#         elif [ "$percent" -ge 70 ]; then echo "󰂁"
#         elif [ "$percent" -ge 60 ]; then echo "󰂀"
#         elif [ "$percent" -ge 50 ]; then echo "󰁿"
#         elif [ "$percent" -ge 40 ]; then echo "󰁾"
#         elif [ "$percent" -ge 30 ]; then echo "󰁽"
#         elif [ "$percent" -ge 20 ]; then echo "󰁼"
#         elif [ "$percent" -ge 10 ]; then echo "󰁻"
#         else echo "󰁺"; fi
#     fi
# }
# jq -n -c --arg percent "$(get_battery_percent)" --arg status "$(get_battery_status)" --arg icon "$(get_battery_icon)" '{percent: $percent, status: $status, icon: $icon}'



#!/usr/bin/env bash                                                              # Shebang line that tells the system to execute this script using the bash interpreter found in the user's PATH environment variable (more portable than hardcoding /bin/bash)
get_battery_percent() { LC_ALL=C cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo "100"; }  # Defines a function to get battery percentage: sets C locale, reads the capacity file from any battery device (BAT* glob matches BAT0, BAT1, etc.), suppresses errors if no battery exists, takes only the first line via head, and if the whole command fails (no battery found) falls back to "100" as a safe default
get_battery_status() { LC_ALL=C cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1 || echo "Full"; }  # Defines a function to get battery status: reads the status file from the battery device, suppresses errors, takes first line, and defaults to "Full" if no battery is present (useful for desktop systems where the script might still be called)
get_battery_icon() {                                                            # Defines a function that returns an appropriate Nerd Font battery icon based on both charge percentage and charging status
    local percent=$(get_battery_percent)                                        # Calls get_battery_percent and stores the returned numeric value in a local variable named percent
    local status=$(get_battery_status)                                          # Calls get_battery_status and stores the returned status string (e.g., "Charging", "Discharging", "Full") in a local variable named status
    if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then              # Checks if the battery is either currently charging OR fully charged (no longer drawing power but still connected)
        if [ "$percent" -ge 90 ]; then echo "󰂅"                                # If battery is at 90% or higher while charging/full, returns the icon for "battery full charging" (󰂅 shows full battery with bolt)
        elif [ "$percent" -ge 80 ]; then echo "󰂋"                              # 80-89% charging icon (󰂋 - battery with bolt, one bar less than full)
        elif [ "$percent" -ge 60 ]; then echo "󰂊"                              # 60-79% charging icon (󰂊 - battery with bolt, ~75% indicator)
        elif [ "$percent" -ge 40 ]; then echo "󰢞"                              # 40-59% charging icon (󰢞 - battery with bolt, half charge indicator)
        elif [ "$percent" -ge 20 ]; then echo "󰂆"                              # 20-39% charging icon (󰂆 - battery with bolt, low but charging)
        else echo "󰢜"; fi                                                      # Below 20% charging icon (󰢜 - battery with bolt, very low but thankfully charging); fi closes the inner if-elif chain
    else                                                                         # Otherwise the battery is discharging (not plugged in and not full)
        if [ "$percent" -ge 90 ]; then echo "󰁹"                                # 90%+ discharging icon (󰁹 - full battery, no bolt)
        elif [ "$percent" -ge 80 ]; then echo "󰂂"                              # 80-89% discharging icon (󰂂 - mostly full battery)
        elif [ "$percent" -ge 70 ]; then echo "󰂁"                              # 70-79% discharging icon (󰂁 - slight drop visible)
        elif [ "$percent" -ge 60 ]; then echo "󰂀"                              # 60-69% discharging icon (󰂀 - about two-thirds full)
        elif [ "$percent" -ge 50 ]; then echo "󰁿"                              # 50-59% discharging icon (󰁿 - half battery)
        elif [ "$percent" -ge 40 ]; then echo "󰁾"                              # 40-49% discharging icon (󰁾 - less than half)
        elif [ "$percent" -ge 30 ]; then echo "󰁽"                              # 30-39% discharging icon (󰁽 - getting low)
        elif [ "$percent" -ge 20 ]; then echo "󰁼"                              # 20-29% discharging icon (󰁼 - low battery warning zone)
        elif [ "$percent" -ge 10 ]; then echo "󰁻"                              # 10-19% discharging icon (󰁻 - critically low)
        else echo "󰁺"; fi                                                      # Below 10% discharging icon (󰁺 - empty battery, immediate charging needed); fi closes the inner if-elif chain
    fi                                                                           # Closes the outer if-else block that distinguishes charging from discharging states
}                                                                               # Closes the get_battery_icon function definition
jq -n -c --arg percent "$(get_battery_percent)" --arg status "$(get_battery_status)" --arg icon "$(get_battery_icon)" '{percent: $percent, status: $status, icon: $icon}'  # Constructs a compact JSON object with three fields: percent (the battery percentage), status (Charging/Discharging/Full/etc.), and icon (the appropriate Nerd Font glyph); jq builds this with null input (-n), compact output (-c), and named arguments (--arg) populated by calling each function via command substitution