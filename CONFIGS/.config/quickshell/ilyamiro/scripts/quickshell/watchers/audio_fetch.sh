# #!/usr/bin/env bash
# get_volume() {
#     local vol=""
#     if command -v wpctl &> /dev/null; then 
#         vol=$(LC_ALL=C wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}')
#     fi
#     if [[ -z "$vol" ]] && command -v pamixer &> /dev/null; then 
#         vol=$(LC_ALL=C pamixer --get-volume 2>/dev/null)
#     fi
#     echo "${vol:-0}"
# }

# is_muted() {
#     if command -v wpctl &> /dev/null; then
#         if LC_ALL=C wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q "MUTED"; then echo "true"; else echo "false"; fi
#     elif command -v pamixer &> /dev/null; then
#         if LC_ALL=C pamixer --get-mute 2>/dev/null | grep -q "true"; then echo "true"; else echo "false"; fi
#     else 
#         echo "false"
#     fi
# }

# get_volume_icon() {
#     local vol=$(get_volume)
#     local muted=$(is_muted)
#     if [ "$muted" = "true" ]; then echo "󰝟"
#     elif [ "$vol" -ge 70 ]; then echo "󰕾"
#     elif [ "$vol" -ge 30 ]; then echo "󰖀"
#     elif [ "$vol" -gt 0 ]; then echo "󰕿"
#     else echo "󰝟"; fi
# }

# toggle_mute() {
#     if command -v wpctl &> /dev/null; then
#         LC_ALL=C wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
#     elif command -v pamixer &> /dev/null; then
#         LC_ALL=C pamixer --toggle-mute 2>/dev/null
#     fi
#     if [ "$(is_muted)" = "true" ]; then notify-send -u low -i audio-volume-muted "Volume" "Muted"
#     else notify-send -u low -i audio-volume-high "Volume" "Unmuted ($(get_volume)%)"; fi
# }

# case $1 in
#     --toggle) toggle_mute ;;
#     *) jq -n -c --arg volume "$(get_volume)" --arg icon "$(get_volume_icon)" --arg is_muted "$(is_muted)" '{volume: $volume, icon: $icon, is_muted: $is_muted}' ;;
# esac




#!/usr/bin/env bash                                                              # Shebang line that tells the system to execute this script using the bash interpreter found in the user's PATH environment variable (more portable than hardcoding /bin/bash)
get_volume() {                                                                  # Defines a function named get_volume that retrieves the current system volume level as a percentage
    local vol=""                                                                # Declares a local variable 'vol' scoped only to this function and initializes it as an empty string
    if command -v wpctl &> /dev/null; then                                     # Checks if the 'wpctl' command (WirePlumber control tool for PipeWire) exists in the system PATH, redirecting both stdout and stderr to /dev/null to suppress any output
        vol=$(LC_ALL=C wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}')  # Sets the C locale temporarily to ensure consistent decimal formatting, gets the volume of the default audio sink, suppresses any stderr, pipes the output (like "Volume: 0.75") to awk which multiplies the second field (the decimal value) by 100 and converts it to an integer percentage
    fi                                                                           # Closes the if block for wpctl check
    if [[ -z "$vol" ]] && command -v pamixer &> /dev/null; then                # If 'vol' is still empty (wpctl failed or returned nothing) AND the 'pamixer' command (PulseAudio mixer) exists in PATH
        vol=$(LC_ALL=C pamixer --get-volume 2>/dev/null)                       # Uses pamixer to get the current volume level, setting C locale for consistency, and suppresses any error output
    fi                                                                           # Closes the second if block
    echo "${vol:-0}"                                                            # Prints the volume value, using bash parameter expansion to default to "0" if vol is unset or null (safe fallback)
}                                                                               # Closes the get_volume function definition

is_muted() {                                                                    # Defines a function named is_muted that checks whether the default audio output is currently muted
    if command -v wpctl &> /dev/null; then                                     # Checks if wpctl command is available in the system
        if LC_ALL=C wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q "MUTED"; then echo "true"; else echo "false"; fi  # Gets the volume info from wpctl, suppresses stderr, pipes to grep which silently (-q) checks if the output contains the word "MUTED"; if yes prints "true", otherwise prints "false"
    elif command -v pamixer &> /dev/null; then                                  # If wpctl is not available but pamixer is
        if LC_ALL=C pamixer --get-mute 2>/dev/null | grep -q "true"; then echo "true"; else echo "false"; fi  # Uses pamixer to check mute status, suppresses errors, greps for "true" in the output, prints "true" if muted, "false" otherwise
    else                                                                         # If neither wpctl nor pamixer is available
        echo "false"                                                            # Defaults to returning "false" (not muted) when no audio control tool is found
    fi                                                                           # Closes the outer if-elif-else block
}                                                                               # Closes the is_muted function definition

get_volume_icon() {                                                             # Defines a function that returns an appropriate Nerd Font icon based on current volume level and mute state
    local vol=$(get_volume)                                                     # Calls the get_volume function and stores the returned volume percentage in a local variable
    local muted=$(is_muted)                                                     # Calls the is_muted function and stores its return value ("true" or "false") in a local variable
    if [ "$muted" = "true" ]; then echo "󰝟"                                    # If the audio is muted, prints the Nerd Font icon for "muted speaker" (󰝟)
    elif [ "$vol" -ge 70 ]; then echo "󰕾"                                      # If volume is greater than or equal to 70%, prints the icon for "high volume speaker" (󰕾)
    elif [ "$vol" -ge 30 ]; then echo "󰖀"                                      # If volume is between 30% and 69%, prints the icon for "medium volume speaker" (󰖀)
    elif [ "$vol" -gt 0 ]; then echo "󰕿"                                       # If volume is between 1% and 29%, prints the icon for "low volume speaker" (󰕿)
    else echo "󰝟"; fi                                                           # If volume is 0% (but not muted), prints the muted icon as fallback; fi closes the conditional chain
}                                                                               # Closes the get_volume_icon function definition

toggle_mute() {                                                                 # Defines a function that toggles the mute state of the default audio output and sends a notification
    if command -v wpctl &> /dev/null; then                                     # Checks if wpctl is available
        LC_ALL=C wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle                    # Uses wpctl to toggle the mute state on the default audio sink, with C locale for consistency
    elif command -v pamixer &> /dev/null; then                                  # If wpctl is not available but pamixer is
        LC_ALL=C pamixer --toggle-mute 2>/dev/null                             # Uses pamixer to toggle mute, suppressing any error output
    fi                                                                           # Closes the if-elif block
    if [ "$(is_muted)" = "true" ]; then notify-send -u low -i audio-volume-muted "Volume" "Muted"  # After toggling, if the state is now muted, sends a low-urgency desktop notification with the audio-volume-muted icon and the message "Muted"
    else notify-send -u low -i audio-volume-high "Volume" "Unmuted ($(get_volume)%)"; fi  # If unmuted, sends a low-urgency notification showing the current volume percentage using command substitution inside the message string
}                                                                               # Closes the toggle_mute function definition

case $1 in                                                                      # Begins a case statement that checks the first command-line argument passed to the script ($1)
    --toggle) toggle_mute ;;                                                    # If the argument is "--toggle", runs the toggle_mute function; ;; ends this case branch
    *) jq -n -c --arg volume "$(get_volume)" --arg icon "$(get_volume_icon)" --arg is_muted "$(is_muted)" '{volume: $volume, icon: $icon, is_muted: $is_muted}' ;;  # For any other argument (or no argument), creates a compact JSON object using jq: -n creates null input, -c outputs compact format, --arg sets JSON variables from the function results, and builds an object with volume, icon, and is_muted fields
esac                                                                             # Ends the case statement block