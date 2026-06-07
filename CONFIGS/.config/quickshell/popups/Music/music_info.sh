# #!/usr/bin/env bash

# TMP_DIR="/tmp/eww_covers"
# mkdir -p "$TMP_DIR"
# PLACEHOLDER="$TMP_DIR/placeholder_blank.png"
# STATE_FILE="$TMP_DIR/last_state.json"

# # --- 1. ENSURE PLACEHOLDER EXISTS ---
# if [ ! -f "$PLACEHOLDER" ]; then
#     convert -size 500x500 xc:"#313244" "$PLACEHOLDER"
# fi

# # --- 2. CHECK STATUS ---
# STATUS=$(playerctl status 2>/dev/null)

# if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then

#     # --- 3. GET INFO ---
#     rawUrl=$(playerctl metadata mpris:artUrl 2>/dev/null)
#     title=$(playerctl metadata xesam:title 2>/dev/null)
#     artist=$(playerctl metadata xesam:artist 2>/dev/null)
    
#     # Generate Hash based on the Image URL itself, not the track title.
#     # This prevents DBus sync lag from poisoning the cache with the wrong image.
#     if [ -n "$rawUrl" ]; then
#         trackHash=$(echo "$rawUrl" | md5sum | cut -d" " -f1)
#     else
#         idStr="${title:-unknown}-${artist:-unknown}"
#         trackHash=$(echo "$idStr" | md5sum | cut -d" " -f1)
#     fi
    
#     finalArt="$TMP_DIR/${trackHash}_art.jpg"
#     blurPath="$TMP_DIR/${trackHash}_blur.png"
#     colorPath="$TMP_DIR/${trackHash}_grad.txt"
#     textPath="$TMP_DIR/${trackHash}_text.txt"
#     lockFile="$TMP_DIR/${trackHash}.lock"

#     # Default display values (Placeholder)
#     displayArt="$PLACEHOLDER"
#     displayBlur="$PLACEHOLDER"
#     displayGrad="linear-gradient(45deg, #cba6f7, #89b4fa, #f38ba8, #cba6f7)"
#     displayText="#cdd6f4"

#     # --- 4. ASYNC BACKGROUND LOGIC ---
#     if [ -f "$finalArt" ] && [ -s "$finalArt" ]; then
#         displayArt="$finalArt"
#         if [ -f "$blurPath" ]; then displayBlur="$blurPath"; fi
#         if [ -f "$colorPath" ]; then displayGrad=$(cat "$colorPath"); fi
#         if [ -f "$textPath" ]; then displayText=$(cat "$textPath"); fi
#     else
#         if [ ! -f "$lockFile" ] && [ -n "$rawUrl" ]; then
#             touch "$lockFile"
#             (
#                 # Use temporary files to prevent QML from reading incomplete downloads
#                 tempArt="$TMP_DIR/${trackHash}_temp_art.jpg"
#                 tempBlur="$TMP_DIR/${trackHash}_temp_blur.png"

#                 if [[ "$rawUrl" == http* ]]; then
#                     curl -s -L --max-time 10 -o "$tempArt" "$rawUrl"
#                 else
#                     cleanPath=$(echo "$rawUrl" | sed 's/file:\/\///g')
#                     if [ -f "$cleanPath" ]; then
#                         cp "$cleanPath" "$tempArt"
#                     else
#                         cp "$PLACEHOLDER" "$tempArt"
#                     fi
#                 fi

#                 if [ ! -s "$tempArt" ]; then
#                     cp "$PLACEHOLDER" "$tempArt"
#                 fi

#                 isPlaceholder=$(convert "$tempArt" -format "%[hex:u.p{0,0}]" info: 2>/dev/null | cut -c1-6)
                
#                 if [[ "$isPlaceholder" == "313244" ]] || [[ -z "$isPlaceholder" ]]; then
#                     cp "$tempArt" "$tempBlur"
#                 else
#                     convert "$tempArt" -blur 0x20 -brightness-contrast -30x-10 "$tempBlur" 2>/dev/null
                    
#                     colors=$(convert "$tempArt" -resize 50x50 -alpha off +dither -quantize RGB -colors 3 -depth 8 -format "%c" histogram:info: 2>/dev/null | grep -E -o '#[0-9A-Fa-f]{6}' | head -n 3 | tr '\n' ' ')
#                     read -r -a color_array <<< "$colors"
                    
#                     c1=${color_array[0]:-#cba6f7}
#                     c2=${color_array[1]:-$c1}
#                     c3=${color_array[2]:-$c1}
                    
#                     echo "linear-gradient(45deg, $c1, $c2, $c3, $c1)" > "$colorPath"
                    
#                     opp_raw=$(convert xc:"$c1" -alpha off -negate -depth 8 -format "%[hex:u]" info: 2>/dev/null | grep -E -o '[0-9A-Fa-f]{6}' | head -n 1)
#                     if [ -n "$opp_raw" ]; then
#                         echo "#$opp_raw" > "$textPath"
#                     else
#                         echo "#cdd6f4" > "$textPath"
#                     fi
#                 fi

#                 # Atomic swap: Instantly move completed temp files to their final tracked paths
#                 mv "$tempBlur" "$blurPath"
#                 mv "$tempArt" "$finalArt"

#                 rm "$lockFile"
#                 (cd "$TMP_DIR" && ls -1t | tail -n +21 | xargs -r rm 2>/dev/null)
#             ) &
#         fi
#     fi

#     # --- 5. TIMING ---
#     len_micro=$(playerctl metadata mpris:length 2>/dev/null)
#     if [ -z "$len_micro" ] || [ "$len_micro" -eq 0 ]; then len_micro=1000000; fi
#     len_sec=$((len_micro / 1000000))
#     len_str=$(printf "%02d:%02d" $((len_sec/60)) $((len_sec%60)))

#     if [ "$STATUS" = "Playing" ]; then
#         # When playing, playerctl reports position correctly — save it
#         pos_micro=$(playerctl metadata --format '{{position}}' 2>/dev/null)
#         if [ -z "$pos_micro" ]; then pos_micro=0; fi
#         pos_sec=$((pos_micro / 1000000))

#         # Persist for use when paused/stopped (Firefox MPRIS reports 0 when paused)
#         jq -n -c \
#             --argjson pos_sec "$pos_sec" \
#             --argjson len_sec "$len_sec" \
#             '{pos_sec: $pos_sec, len_sec: $len_sec}' \
#             > "$STATE_FILE"
#     else
#         # Paused: Firefox (and some other players) report position=0 over D-Bus.
#         # Use last saved position from when it was playing instead.
#         pos_sec=0
#         if [ -f "$STATE_FILE" ]; then
#             saved_pos=$(jq -r '.pos_sec' "$STATE_FILE")
#             saved_len=$(jq -r '.len_sec' "$STATE_FILE")
#             # Only restore if it's the same track length (same song)
#             if [ "$saved_len" = "$len_sec" ] && [ -n "$saved_pos" ] && [ "$saved_pos" != "null" ]; then
#                 pos_sec=$saved_pos
#             fi
#         fi
#     fi

#     percent=$((pos_sec * 100 / len_sec))
#     pos_str=$(printf "%02d:%02d" $((pos_sec/60)) $((pos_sec%60)))
#     time_str="${pos_str} / ${len_str}"

#     # --- 6. DEVICE INFO ---
#     player_raw=$(playerctl status -f "{{playerName}}" 2>/dev/null | head -n 1)
#     player_nice="${player_raw^}"

#     sink_name=$(pactl get-default-sink 2>/dev/null)
#     dev_icon="󰓃"; dev_name="Speaker"
#     if [[ "$sink_name" == *"bluez"* ]]; then
#         dev_icon="󰂯"
#         readable_name=$(pactl list sinks | grep -A 20 "$sink_name" | grep -m 1 "Description:" | cut -d: -f2 | xargs)
#         if [ -n "$readable_name" ]; then dev_name="$readable_name"; else dev_name="Bluetooth"; fi
#     elif [[ "$sink_name" == *"usb"* ]]; then
#         dev_icon="󰓃"; dev_name="USB Audio"
#     elif [[ "$sink_name" == *"pci"* ]]; then
#         dev_icon="󰓃"; dev_name="System"
#     fi

#     # --- 7. JSON OUTPUT ---
#     jq -n -c \
#         --arg title "$title" \
#         --arg artist "$artist" \
#         --arg status "$STATUS" \
#         --arg len "$len_sec" \
#         --arg pos "$pos_sec" \
#         --arg len_str "$len_str" \
#         --arg pos_str "$pos_str" \
#         --arg time_str "$time_str" \
#         --arg percent "$percent" \
#         --arg source "$player_nice" \
#         --arg pname "$player_raw" \
#         --arg blur "$displayBlur" \
#         --arg grad "$displayGrad" \
#         --arg txtColor "$displayText" \
#         --arg devIcon "$dev_icon" \
#         --arg devName "$dev_name" \
#         --arg finalArt "$displayArt" \
#         '{
#             title: $title,
#             artist: $artist,
#             status: $status,
#             length: $len,
#             position: $pos,
#             lengthStr: $len_str,
#             positionStr: $pos_str,
#             timeStr: $time_str,
#             percent: $percent,
#             source: $source,
#             playerName: $pname,
#             blur: $blur,
#             grad: $grad,
#             textColor: $txtColor,
#             deviceIcon: $devIcon,
#             deviceName: $devName,
#             artUrl: $finalArt
#         }'

# else
#     # --- FALLBACK (Stopped) ---
#     # Restore last known position so the widget does not snap to 00:00
#     if [ -f "$STATE_FILE" ]; then
#         last_pos_sec=$(jq -r '.pos_sec' "$STATE_FILE")
#         last_len_sec=$(jq -r '.len_sec' "$STATE_FILE")
#     else
#         last_pos_sec=0; last_len_sec=0
#     fi

#     if [ -z "$last_pos_sec" ] || [ "$last_pos_sec" = "null" ]; then last_pos_sec=0; fi
#     if [ -z "$last_len_sec" ] || [ "$last_len_sec" = "null" ] || [ "$last_len_sec" -eq 0 ]; then last_len_sec=1; fi

#     last_percent=$((last_pos_sec * 100 / last_len_sec))
#     last_pos_str=$(printf "%02d:%02d" $((last_pos_sec/60)) $((last_pos_sec%60)))
#     last_len_str=$(printf "%02d:%02d" $((last_len_sec/60)) $((last_len_sec%60)))
#     last_time_str="${last_pos_str} / ${last_len_str}"

#     jq -n -c \
#     --arg placeholder "$PLACEHOLDER" \
#     --arg pos_str "$last_pos_str" \
#     --arg len_str "$last_len_str" \
#     --arg time_str "$last_time_str" \
#     --arg percent "$last_percent" \
#     '{
#         title: "Not Playing",
#         artist: "",
#         status: "Stopped",
#         percent: $percent,
#         lengthStr: $len_str,
#         positionStr: $pos_str,
#         timeStr: $time_str,
#         source: "Offline",
#         playerName: "",
#         blur: $placeholder,
#         grad: "linear-gradient(45deg, #cba6f7, #89b4fa, #f38ba8, #cba6f7)",
#         textColor: "#cdd6f4",
#         deviceIcon: "󰓃",
#         deviceName: "Speaker",
#         artUrl: $placeholder
#     }'
# fi

#!/usr/bin/env bash                                                                               # Shebang - specifies this script should be executed using the bash shell from the user's PATH environment

TMP_DIR="/tmp/eww_covers"                                                                         # Define TMP_DIR variable - directory for storing cached album art and derived assets in /tmp (temporary filesystem)
mkdir -p "$TMP_DIR"                                                                               # Create the temporary directory if it doesn't exist - -p flag creates parent directories and doesn't error if already exists
PLACEHOLDER="$TMP_DIR/placeholder_blank.png"                                                      # Define PLACEHOLDER variable - path to a blank placeholder image used when no album art is available
STATE_FILE="$TMP_DIR/last_state.json"                                                             # Define STATE_FILE variable - stores last known playback position to preserve it when player reports 0 during pause

# --- 1. ENSURE PLACEHOLDER EXISTS ---                                                             # Section comment - Step 1: Create the placeholder image if missing
if [ ! -f "$PLACEHOLDER" ]; then                                                                   # Check if the placeholder image file does NOT exist
    convert -size 500x500 xc:"#313244" "$PLACEHOLDER"                                             # Use ImageMagick convert to create a 500x500 pixel solid color image - color #313244 is Catppuccin Mocha's surface0/base color (dark gray-purple)
fi                                                                                                # End of placeholder creation check

# --- 2. CHECK STATUS ---                                                                          # Section comment - Step 2: Query the current playback status via MPRIS
STATUS=$(playerctl status 2>/dev/null)                                                            # Get player status (Playing/Paused/Stopped) using playerctl - suppress error output if no players found (2>/dev/null)

if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then                                    # Check if a player is actively playing or paused - only process metadata when there's active media

    # --- 3. GET INFO ---                                                                          # Section comment - Step 3: Extract track metadata from the player
    rawUrl=$(playerctl metadata mpris:artUrl 2>/dev/null)                                         # Get the album art URL from MPRIS metadata - may be a web URL (http://) or local file path (file://)
    title=$(playerctl metadata xesam:title 2>/dev/null)                                           # Get the track title from metadata using xesam:title field (standard MPRIS spec)
    artist=$(playerctl metadata xesam:artist 2>/dev/null)                                         # Get the artist name from metadata using xesam:artist field
    
    # Generate Hash based on the Image URL itself, not the track title.                           # Comment explaining the hashing strategy
    # This prevents DBus sync lag from poisoning the cache with the wrong image.                  # Comment noting that hashing by URL prevents showing previous track's art during rapid track changes
    if [ -n "$rawUrl" ]; then                                                                      # Check if an art URL exists (non-empty string)
        trackHash=$(echo "$rawUrl" | md5sum | cut -d" " -f1)                                      # Generate MD5 hash of the art URL - pipe URL to md5sum, then cut to extract only the hash (remove filename)
    else                                                                                           # If no art URL available
        idStr="${title:-unknown}-${artist:-unknown}"                                               # Create identifier string by combining title and artist with hyphen - use "unknown" as fallback if either is empty
        trackHash=$(echo "$idStr" | md5sum | cut -d" " -f1)                                      # Generate MD5 hash of the fallback identifier string
    fi                                                                                             # End of art URL check
    
    finalArt="$TMP_DIR/${trackHash}_art.jpg"                                                       # Define finalArt path - cached album art file named with track hash + "_art.jpg"
    blurPath="$TMP_DIR/${trackHash}_blur.png"                                                      # Define blurPath - cached blurred version of album art for background effects
    colorPath="$TMP_DIR/${trackHash}_grad.txt"                                                     # Define colorPath - file storing extracted gradient colors from album art
    textPath="$TMP_DIR/${trackHash}_text.txt"                                                      # Define textPath - file storing calculated text color (contrasting color for overlay text)
    lockFile="$TMP_DIR/${trackHash}.lock"                                                          # Define lockFile - prevents multiple simultaneous processing of the same track's artwork

    # Default display values (Placeholder)                                                         # Comment - set initial fallback values before checking cache
    displayArt="$PLACEHOLDER"                                                                      # Default album art to placeholder image - will be replaced if cached art exists
    displayBlur="$PLACEHOLDER"                                                                     # Default blurred background to placeholder
    displayGrad="linear-gradient(45deg, #cba6f7, #89b4fa, #f38ba8, #cba6f7)"                     # Default gradient - Catppuccin colors: mauve→blue→red→mauve at 45 degree angle
    displayText="#cdd6f4"                                                                          # Default text color - Catppuccin Mocha's text color (light lavender white)

    # --- 4. ASYNC BACKGROUND LOGIC ---                                                            # Section comment - Step 4: Check cache or process artwork asynchronously
    if [ -f "$finalArt" ] && [ -s "$finalArt" ]; then                                              # Check if cached final art exists AND has non-zero size (-s flag)
        displayArt="$finalArt"                                                                     # Use cached album art for display
        if [ -f "$blurPath" ]; then displayBlur="$blurPath"; fi                                    # If blurred version exists, use it for display blur
        if [ -f "$colorPath" ]; then displayGrad=$(cat "$colorPath"); fi                           # If gradient colors file exists, read and use its contents
        if [ -f "$textPath" ]; then displayText=$(cat "$textPath"); fi                             # If text color file exists, read and use its contents
    else                                                                                           # No valid cache exists - need to download/process artwork
        if [ ! -f "$lockFile" ] && [ -n "$rawUrl" ]; then                                         # Only process if lock file doesn't exist (prevents duplicate processing) AND art URL is non-empty
            touch "$lockFile"                                                                      # Create lock file to prevent concurrent processing of the same track
            (                                                                                      # Begin subshell (parentheses) - all commands inside run asynchronously in background
                # Use temporary files to prevent QML from reading incomplete downloads              # Comment explaining why temp files are used - prevents UI from displaying partially downloaded/broken images
                tempArt="$TMP_DIR/${trackHash}_temp_art.jpg"                                       # Define tempArt path - temporary file for downloading artwork
                tempBlur="$TMP_DIR/${trackHash}_temp_blur.png"                                     # Define tempBlur path - temporary file for processing blur effect

                if [[ "$rawUrl" == http* ]]; then                                                  # Check if art URL starts with "http" (remote web URL)
                    curl -s -L --max-time 10 -o "$tempArt" "$rawUrl"                              # Download the image using curl: -s silent, -L follow redirects, --max-time 10 second timeout, -o output to temp file
                else                                                                                # URL is not HTTP - likely a local file:// path
                    cleanPath=$(echo "$rawUrl" | sed 's/file:\/\///g')                             # Strip "file://" prefix from the URL using sed substitution - leaves clean filesystem path
                    if [ -f "$cleanPath" ]; then                                                    # Check if the cleaned path points to an existing file
                        cp "$cleanPath" "$tempArt"                                                  # Copy the local file to temp location
                    else                                                                             # Local file doesn't exist
                        cp "$PLACEHOLDER" "$tempArt"                                                 # Copy placeholder image to temp as fallback
                    fi                                                                               # End of local file check
                fi                                                                                 # End of URL type check

                if [ ! -s "$tempArt" ]; then                                                        # Check if downloaded/copied temp file is empty or missing
                    cp "$PLACEHOLDER" "$tempArt"                                                     # Replace with placeholder to ensure valid image exists
                fi                                                                                  # End of empty file check

                isPlaceholder=$(convert "$tempArt" -format "%[hex:u.p{0,0}]" info: 2>/dev/null | cut -c1-6)  # Use ImageMagick to get the hex color of the top-left pixel (p{0,0}) - captures first 6 hex characters, suppresses errors
                
                if [[ "$isPlaceholder" == "313244" ]] || [[ -z "$isPlaceholder" ]]; then           # Check if top-left pixel color matches placeholder (#313244) or is empty (processing failed)
                    cp "$tempArt" "$tempBlur"                                                       # If it's placeholder/error, just copy art as blur without processing (no heavy effects needed)
                else                                                                                 # Real artwork exists - process it
                    convert "$tempArt" -blur 0x20 -brightness-contrast -30x-10 "$tempBlur" 2>/dev/null  # Generate blur: radius 0x20 (strong blur), darken with -brightness-contrast -30x-10, suppress errors
                    
                    colors=$(convert "$tempArt" -resize 50x50 -alpha off +dither -quantize RGB -colors 3 -depth 8 -format "%c" histogram:info: 2>/dev/null | grep -E -o '#[0-9A-Fa-f]{6}' | head -n 3 | tr '\n' ' ')  # Extract dominant colors: resize to 50x50 for speed, remove alpha, quantize to 3 colors, get histogram, extract hex colors, take top 3, join with spaces
                    read -r -a color_array <<< "$colors"                                             # Read the space-separated colors string into a bash array variable color_array
                    
                    c1=${color_array[0]:-#cba6f7}                                                   # Set first color to extracted color 0, fallback to Catppuccin mauve (#cba6f7) if empty
                    c2=${color_array[1]:-$c1}                                                       # Set second color to extracted color 1, fallback to c1 if only one color extracted
                    c3=${color_array[2]:-$c1}                                                       # Set third color to extracted color 2, fallback to c1 if only two colors extracted
                    
                    echo "linear-gradient(45deg, $c1, $c2, $c3, $c1)" > "$colorPath"              # Write CSS linear-gradient string to color file - 45 degree angle cycling through extracted colors back to first
                    
                    opp_raw=$(convert xc:"$c1" -alpha off -negate -depth 8 -format "%[hex:u]" info: 2>/dev/null | grep -E -o '[0-9A-Fa-f]{6}' | head -n 1)  # Generate contrasting text color: create 1px solid color of c1, negate (invert), get hex value, extract first 6 hex chars
                    if [ -n "$opp_raw" ]; then                                                       # Check if contrast color was successfully generated
                        echo "#$opp_raw" > "$textPath"                                               # Write contrasting text color to file with # prefix
                    else                                                                              # Contrast generation failed
                        echo "#cdd6f4" > "$textPath"                                                 # Write default Catppuccin text color as fallback
                    fi                                                                               # End of contrast color check
                fi                                                                                  # End of artwork processing block

                # Atomic swap: Instantly move completed temp files to their final tracked paths     # Comment explaining atomic move - prevents QML from reading partially written files
                mv "$tempBlur" "$blurPath"                                                           # Move temporary blur to final blur path atomically (mv is atomic on same filesystem)
                mv "$tempArt" "$finalArt"                                                            # Move temporary art to final art path atomically

                rm "$lockFile"                                                                       # Remove lock file to allow reprocessing if track changes
                (cd "$TMP_DIR" && ls -1t | tail -n +21 | xargs -r rm 2>/dev/null)                   # Cleanup old cached files: list files by time (newest first), skip first 20, remove the rest - keeps only 20 most recent tracks' artwork
            ) &                                                                                     # End subshell and run it in background (&) - this doesn't block the script, processing happens asynchronously
        fi                                                                                          # End of lock file check
    fi                                                                                             # End of cache check

    # --- 5. TIMING ---                                                                             # Section comment - Step 5: Calculate track timing and progress
    len_micro=$(playerctl metadata mpris:length 2>/dev/null)                                       # Get track length in microseconds from MPRIS metadata
    if [ -z "$len_micro" ] || [ "$len_micro" -eq 0 ]; then len_micro=1000000; fi                  # If length is empty or zero, set default to 1,000,000 microseconds (1 second) to avoid division by zero
    len_sec=$((len_micro / 1000000))                                                               # Convert microseconds to seconds by dividing by 1,000,000 (bash integer arithmetic)
    len_str=$(printf "%02d:%02d" $((len_sec/60)) $((len_sec%60)))                                # Format length as MM:SS - minutes = len_sec/60, seconds = len_sec%60, padded to 2 digits with leading zeros

    if [ "$STATUS" = "Playing" ]; then                                                              # If player is actively playing
        # When playing, playerctl reports position correctly — save it                            # Comment explaining that position is reliable during playback
        pos_micro=$(playerctl metadata --format '{{position}}' 2>/dev/null)                       # Get current playback position in microseconds using template format
        if [ -z "$pos_micro" ]; then pos_micro=0; fi                                                # If position is empty, default to 0
        pos_sec=$((pos_micro / 1000000))                                                           # Convert microseconds to seconds

        # Persist for use when paused/stopped (Firefox MPRIS reports 0 when paused)               # Comment explaining why position is saved - Firefox and some players report 0 position when paused
        jq -n -c \                                                                                 # Create new JSON using jq: -n no input, -c compact output
            --argjson pos_sec "$pos_sec" \                                                         # Pass pos_sec as JSON number (not string) using --argjson
            --argjson len_sec "$len_sec" \                                                         # Pass len_sec as JSON number
            '{pos_sec: $pos_sec, len_sec: $len_sec}' \                                            # Create JSON object with position and length in seconds
            > "$STATE_FILE"                                                                        # Write JSON to state file for later retrieval when paused
    else                                                                                           # Player is Paused (not Playing)
        # Paused: Firefox (and some other players) report position=0 over D-Bus.                  # Comment noting the problem - paused state often reports position as 0
        # Use last saved position from when it was playing instead.                               # Comment explaining the solution - restore position from saved state
        pos_sec=0                                                                                  # Default position to 0
        if [ -f "$STATE_FILE" ]; then                                                               # Check if state file exists (was previously saved during playback)
            saved_pos=$(jq -r '.pos_sec' "$STATE_FILE")                                            # Extract saved position from state file using jq -r for raw output
            saved_len=$(jq -r '.len_sec' "$STATE_FILE")                                            # Extract saved length from state file
            # Only restore if it's the same track length (same song)                              # Comment explaining validation - prevents showing wrong position for different track
            if [ "$saved_len" = "$len_sec" ] && [ -n "$saved_pos" ] && [ "$saved_pos" != "null" ]; then  # Only restore position if: lengths match (same track), position is non-empty, and not JSON null
                pos_sec=$saved_pos                                                                   # Set position to the saved value from when it was playing
            fi                                                                                       # End of validation check
        fi                                                                                         # End of state file check
    fi                                                                                             # End of playing/paused check

    percent=$((pos_sec * 100 / len_sec))                                                            # Calculate progress percentage - multiply by 100 first to avoid floating point, bash integer division
    pos_str=$(printf "%02d:%02d" $((pos_sec/60)) $((pos_sec%60)))                                # Format position as MM:SS string with leading zeros
    time_str="${pos_str} / ${len_str}"                                                             # Create full time string like "01:23 / 04:56" by combining position and length

    # --- 6. DEVICE INFO ---                                                                       # Section comment - Step 6: Get audio output device information
    player_raw=$(playerctl status -f "{{playerName}}" 2>/dev/null | head -n 1)                     # Get the player name from MPRIS (e.g., "firefox", "spotify") - head -n 1 takes first if multiple
    player_nice="${player_raw^}"                                                                   # Capitalize first letter of player name using bash parameter expansion (^ operator) - makes "firefox" → "Firefox"

    sink_name=$(pactl get-default-sink 2>/dev/null)                                                # Get the default audio sink name from PulseAudio/PipeWire using pactl
    dev_icon="󰓃"; dev_name="Speaker"                                                              # Set default device icon (Nerd Font speaker symbol) and name
    if [[ "$sink_name" == *"bluez"* ]]; then                                                       # Check if sink name contains "bluez" (Bluetooth audio via BlueZ stack)
        dev_icon="󰂯"                                                                               # Set icon to Bluetooth symbol (Nerd Font)
        readable_name=$(pactl list sinks | grep -A 20 "$sink_name" | grep -m 1 "Description:" | cut -d: -f2 | xargs)  # Parse pactl output: list all sinks, find 20 lines after sink name, get first "Description:" line, cut field 2 after colon, trim whitespace with xargs
        if [ -n "$readable_name" ]; then dev_name="$readable_name"; else dev_name="Bluetooth"; fi  # Use readable device name if found, otherwise generic "Bluetooth"
    elif [[ "$sink_name" == *"usb"* ]]; then                                                        # Check if sink name contains "usb" (USB audio device)
        dev_icon="󰓃"; dev_name="USB Audio"                                                        # Keep speaker icon, set name to "USB Audio"
    elif [[ "$sink_name" == *"pci"* ]]; then                                                        # Check if sink name contains "pci" (internal PCI sound card)
        dev_icon="󰓃"; dev_name="System"                                                           # Keep speaker icon, set name to "System"
    fi                                                                                             # End of device type detection

    # --- 7. JSON OUTPUT ---                                                                       # Section comment - Step 7: Output all collected data as JSON
    jq -n -c \                                                                                     # Create new JSON with jq: -n for no input, -c for compact single-line output
        --arg title "$title" \                                                                     # Pass title as string argument to jq
        --arg artist "$artist" \                                                                   # Pass artist as string
        --arg status "$STATUS" \                                                                   # Pass playback status
        --arg len "$len_sec" \                                                                     # Pass length in seconds
        --arg pos "$pos_sec" \                                                                     # Pass position in seconds
        --arg len_str "$len_str" \                                                                 # Pass formatted length string (MM:SS)
        --arg pos_str "$pos_str" \                                                                 # Pass formatted position string
        --arg time_str "$time_str" \                                                               # Pass combined time string
        --arg percent "$percent" \                                                                 # Pass progress percentage
        --arg source "$player_nice" \                                                              # Pass capitalized player name
        --arg pname "$player_raw" \                                                                # Pass raw player name
        --arg blur "$displayBlur" \                                                                # Pass path to blurred background image
        --arg grad "$displayGrad" \                                                                # Pass CSS gradient string
        --arg txtColor "$displayText" \                                                            # Pass text color hex
        --arg devIcon "$dev_icon" \                                                                # Pass device icon character
        --arg devName "$dev_name" \                                                                # Pass device name
        --arg finalArt "$displayArt" \                                                             # Pass path to album art image
        '{                                                                                         # Begin jq JSON template
            title: $title,                                                                          # Track title
            artist: $artist,                                                                        # Artist name
            status: $status,                                                                        # Playback status (Playing/Paused)
            length: $len,                                                                           # Track length in seconds
            position: $pos,                                                                         # Current position in seconds
            lengthStr: $len_str,                                                                     # Formatted length MM:SS
            positionStr: $pos_str,                                                                   # Formatted position MM:SS
            timeStr: $time_str,                                                                      # Combined time string "MM:SS / MM:SS"
            percent: $percent,                                                                       # Progress percentage (0-100)
            source: $source,                                                                         # Capitalized player name
            playerName: $pname,                                                                      # Raw player name
            blur: $blur,                                                                             # Path to blurred background
            grad: $grad,                                                                             # CSS gradient string
            textColor: $txtColor,                                                                     # Text color hex
            deviceIcon: $devIcon,                                                                     # Device icon character
            deviceName: $devName,                                                                     # Device name
            artUrl: $finalArt                                                                         # Path to album art
        }'                                                                                           # End of jq JSON template - this JSON is printed to stdout and read by QML

else                                                                                               # Player status is not Playing or Paused (i.e., Stopped or no player)
    # --- FALLBACK (Stopped) ---                                                                   # Section comment - Handle stopped/no player state
    # Restore last known position so the widget does not snap to 00:00                            # Comment explaining why position is preserved - smooth UX transition
    if [ -f "$STATE_FILE" ]; then                                                                   # Check if state file exists from previous playback
        last_pos_sec=$(jq -r '.pos_sec' "$STATE_FILE")                                             # Extract saved position from state file
        last_len_sec=$(jq -r '.len_sec' "$STATE_FILE")                                             # Extract saved length from state file
    else                                                                                           # No state file exists (first run or cleared)
        last_pos_sec=0; last_len_sec=0                                                              # Set both to 0 as defaults
    fi                                                                                             # End of state file check

    if [ -z "$last_pos_sec" ] || [ "$last_pos_sec" = "null" ]; then last_pos_sec=0; fi            # If position is empty or JSON null, set to 0
    if [ -z "$last_len_sec" ] || [ "$last_len_sec" = "null" ] || [ "$last_len_sec" -eq 0 ]; then last_len_sec=1; fi  # If length is empty, null, or zero, set to 1 (avoids division by zero in percentage calculation)

    last_percent=$((last_pos_sec * 100 / last_len_sec))                                            # Calculate percentage from saved position and length
    last_pos_str=$(printf "%02d:%02d" $((last_pos_sec/60)) $((last_pos_sec%60)))                 # Format saved position as MM:SS
    last_len_str=$(printf "%02d:%02d" $((last_len_sec/60)) $((last_len_sec%60)))                 # Format saved length as MM:SS
    last_time_str="${last_pos_str} / ${last_len_str}"                                              # Create combined time string

    jq -n -c \                                                                                     # Create JSON with jq: -n no input, -c compact
    --arg placeholder "$PLACEHOLDER" \                                                             # Pass placeholder image path
    --arg pos_str "$last_pos_str" \                                                                # Pass formatted position
    --arg len_str "$last_len_str" \                                                                # Pass formatted length
    --arg time_str "$last_time_str" \                                                              # Pass combined time string
    --arg percent "$last_percent" \                                                                # Pass progress percentage
    '{                                                                                             # Begin JSON template for stopped state
        title: "Not Playing",                                                                       # Display "Not Playing" as title
        artist: "",                                                                                  # Empty artist
        status: "Stopped",                                                                           # Status is Stopped
        percent: $percent,                                                                           # Last known progress percentage
        lengthStr: $len_str,                                                                          # Last known formatted length
        positionStr: $pos_str,                                                                        # Last known formatted position
        timeStr: $time_str,                                                                           # Last known combined time string
        source: "Offline",                                                                           # Source is "Offline" (no player)
        playerName: "",                                                                              # Empty player name
        blur: $placeholder,                                                                          # Use placeholder for blur
        grad: "linear-gradient(45deg, #cba6f7, #89b4fa, #f38ba8, #cba6f7)",                        # Default gradient (mauve→blue→red→mauve)
        textColor: "#cdd6f4",                                                                        # Default text color (Catppuccin text)
        deviceIcon: "󰓃",                                                                            # Default speaker icon
        deviceName: "Speaker",                                                                       # Default device name
        artUrl: $placeholder                                                                         # Use placeholder for art
    }'                                                                                               # End of JSON template - outputs stopped state info to stdout
fi                                                                                                # End of the main if-else block (Playing/Paused vs Stopped)