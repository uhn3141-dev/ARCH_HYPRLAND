# #!/usr/bin/env bash

# STATE_FILE="/tmp/eq_state.json"
# PRESET_DIR="$HOME/.config/easyeffects/output"
# PRESET_NAME="live_eq"
# PRESET_FILE="$PRESET_DIR/${PRESET_NAME}.json"

# mkdir -p "$PRESET_DIR"

# # Default state (Now includes "pending": false)
# if [ ! -f "$STATE_FILE" ]; then
#     echo '{"b1": 0, "b2": 0, "b3": 0, "b4": 0, "b5": 0, "b6": 0, "b7": 0, "b8": 0, "b9": 0, "b10": 0, "preset": "Flat", "pending": false}' > "$STATE_FILE"
# fi

# apply_eq() {
#     vals=$(cat "$STATE_FILE")
#     python3 -c "
# import sys, json
# try:
#     data = json.loads(sys.argv[1])
#     slider_map = { 0:0, 1:3, 2:6, 3:9, 4:12, 5:15, 6:18, 7:21, 8:24, 9:27 }
#     freqs = [32, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000, 20000, 22000, 24000, 24000]
#     gains = [float(data['b1']), float(data['b2']), float(data['b3']), float(data['b4']), float(data['b5']), float(data['b6']), float(data['b7']), float(data['b8']), float(data['b9']), float(data['b10'])]
#     bands = {}
#     for i in range(32):
#         freq = freqs[i] if i < len(freqs) else 20000.0
#         gain = 0.0
#         for s_idx, b_idx in slider_map.items():
#             if i == b_idx:
#                 gain = gains[s_idx]
#                 break
#         bands[f\"band{i}\"] = { \"frequency\": freq, \"gain\": gain, \"mode\": \"Bell\", \"mute\": False, \"q\": 1.0, \"solo\": False, \"width\": 1.0, \"slope\": \"x1\" }
#     preset = { \"output\": { \"blocklist\": [], \"plugins_order\": [ \"equalizer\" ], \"equalizer\": { \"bypass\": False, \"input-gain\": 0.0, \"output-gain\": 0.0, \"left\": bands, \"right\": bands, \"mode\": \"IIR\", \"num-bands\": 32, \"split-channels\": False } } }
#     print(json.dumps(preset, indent=4))
# except:
#     sys.exit(1)
# " "$vals" > "$PRESET_FILE"

#     easyeffects -l "$PRESET_NAME" >/dev/null 2>&1 &
# }

# # Save state helper (Always sets pending to false because Presets apply instantly)
# save_preset() {
#     jq -n -c --arg b1 "$1" --arg b2 "$2" --arg b3 "$3" --arg b4 "$4" --arg b5 "$5" \
#           --arg b6 "$6" --arg b7 "$7" --arg b8 "$8" --arg b9 "$9" --arg b10 "${10}" --arg p "${11}" \
#        '{"b1": $b1, "b2": $b2, "b3": $b3, "b4": $b4, "b5": $b5, "b6": $b6, "b7": $b7, "b8": $b8, "b9": $b9, "b10": $b10, "preset": $p, "pending": false}' > "$STATE_FILE"
# }

# cmd=$1
# arg1=$2
# arg2=$3

# case $cmd in
#     "get") cat "$STATE_FILE" ;;
#     "set_band")
#         # SLIDER MOVE: Set pending = true, Preset = Custom. DO NOT APPLY.
#         tmp=$(cat "$STATE_FILE")
#         updated=$(echo "$tmp" | jq -c --arg val "$arg2" ".b$arg1 = \$val | .preset = \"Custom\" | .pending = true")
#         echo "$updated" > "$STATE_FILE"
#         ;;
#     "apply")
#         # APPLY BUTTON: Set pending = false, then Apply.
#         tmp=$(cat "$STATE_FILE")
#         updated=$(echo "$tmp" | jq -c ".pending = false")
#         echo "$updated" > "$STATE_FILE"
#         apply_eq
#         ;;
#     "preset")
#         # PRESET CLICK: Save values (pending=false) and Apply Instantly.
#         case $arg1 in
#             "Flat")    save_preset 0 0 0 0 0 0 0 0 0 0 "Flat" ;;
#             "Bass")    save_preset 5 7 5 2 1 0 0 0 1 2 "Bass" ;;
#             "Treble")  save_preset -2 -1 0 1 2 3 4 5 6 6 "Treble" ;;
#             "Vocal")   save_preset -2 -1 1 3 5 5 4 2 1 0 "Vocal" ;;
#             "Pop")     save_preset 2 4 2 0 1 2 4 2 1 2 "Pop" ;;
#             "Rock")    save_preset 5 4 2 -1 -2 -1 2 4 5 6 "Rock" ;;
#             "Jazz")    save_preset 3 3 1 1 1 1 2 1 2 3 "Jazz" ;;
#             "Classic") save_preset 0 1 2 2 2 2 1 2 3 4 "Classic" ;;
#         esac
#         apply_eq
#         ;;
# esac



#!/usr/bin/env bash                                                                               # Shebang - specifies this script should be executed using the bash shell from the user's PATH environment

STATE_FILE="/tmp/eq_state.json"                                                                   # Define STATE_FILE variable - stores equalizer band values and state in /tmp (temporary filesystem, cleared on reboot)
PRESET_DIR="$HOME/.config/easyeffects/output"                                                     # Define PRESET_DIR variable - directory where EasyEffects output presets are stored in user's config
PRESET_NAME="live_eq"                                                                             # Define PRESET_NAME variable - name of the EasyEffects preset that will be loaded/applied
PRESET_FILE="$PRESET_DIR/${PRESET_NAME}.json"                                                     # Define PRESET_FILE variable - full path to the EasyEffects preset JSON file by combining directory and name

mkdir -p "$PRESET_DIR"                                                                            # Create the preset directory if it doesn't exist - -p flag creates parent directories as needed and doesn't error if already exists

# Default state (Now includes "pending": false)                                                   # Comment explaining the default state structure includes a pending flag set to false
if [ ! -f "$STATE_FILE" ]; then                                                                   # Check if the state file does NOT exist - this runs only on first execution or after /tmp is cleared
    echo '{"b1": 0, "b2": 0, "b3": 0, "b4": 0, "b5": 0, "b6": 0, "b7": 0, "b8": 0, "b9": 0, "b10": 0, "preset": "Flat", "pending": false}' > "$STATE_FILE"  # Write default JSON to state file - all 10 bands set to 0, preset named "Flat", pending flag false (no unsaved changes)
fi                                                                                                # End of if statement - state file initialization block

apply_eq() {                                                                                      # Define function apply_eq - generates an EasyEffects preset from the state file and applies it
    vals=$(cat "$STATE_FILE")                                                                     # Read the entire contents of the state file into the 'vals' variable - captures current band values and state
    python3 -c "                                                                                  # Execute inline Python script using python3 interpreter - -c flag runs the code passed as string argument
import sys, json                                                                                  # Import sys (system functions/argv) and json (JSON parsing/generation) modules
try:                                                                                              # Begin try block - catch any errors in Python script execution
    data = json.loads(sys.argv[1])                                                                # Parse the JSON string passed as first command-line argument into 'data' dictionary
    slider_map = { 0:0, 1:3, 2:6, 3:9, 4:12, 5:15, 6:18, 7:21, 8:24, 9:27 }                    # Define mapping from 10 slider indices to 32 band indices - sliders control every 3rd band (bands 0,3,6,9,12,15,18,21,24,27)
    freqs = [32, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000, 20000, 22000, 24000, 24000]  # Define frequency values for all 32 bands - these are standard ISO 1/3 octave center frequencies from 32Hz to 24kHz
    gains = [float(data['b1']), float(data['b2']), float(data['b3']), float(data['b4']), float(data['b5']), float(data['b6']), float(data['b7']), float(data['b8']), float(data['b9']), float(data['b10'])]  # Extract gain values from state data for all 10 sliders and convert to float numbers
    bands = {}                                                                                    # Initialize empty dictionary to hold all 32 band configurations
    for i in range(32):                                                                           # Loop through all 32 bands (0 to 31)
        freq = freqs[i] if i < len(freqs) else 20000.0                                            # Set frequency for this band - use frequency array value, fallback to 20000Hz if index out of range
        gain = 0.0                                                                                # Default gain is 0.0 dB (flat) for bands not controlled by sliders
        for s_idx, b_idx in slider_map.items():                                                   # Loop through slider-to-band mapping - s_idx is slider number (0-9), b_idx is band index (0-31)
            if i == b_idx:                                                                        # Check if current band index matches a slider-controlled band
                gain = gains[s_idx]                                                                # Set gain to the corresponding slider value if this band is controlled by a slider
                break                                                                              # Exit the inner loop once the matching slider is found - no need to check remaining sliders
        bands[f\"band{i}\"] = { \"frequency\": freq, \"gain\": gain, \"mode\": \"Bell\", \"mute\": False, \"q\": 1.0, \"solo\": False, \"width\": 1.0, \"slope\": \"x1\" }  # Create band dictionary with all EasyEffects parameters - Bell mode filter at specified frequency/gain, Q=1.0 for moderate bandwidth
    preset = { \"output\": { \"blocklist\": [], \"plugins_order\": [ \"equalizer\" ], \"equalizer\": { \"bypass\": False, \"input-gain\": 0.0, \"output-gain\": 0.0, \"left\": bands, \"right\": bands, \"mode\": \"IIR\", \"num-bands\": 32, \"split-channels\": False } } }  # Build complete EasyEffects preset structure - output chain with equalizer plugin, 32-band IIR equalizer, same settings for left/right channels
    print(json.dumps(preset, indent=4))                                                           # Output the complete preset as formatted JSON with 4-space indentation - this gets redirected to the preset file
except:                                                                                           # Catch any exception in the Python script (JSON parse errors, key errors, etc.)
    sys.exit(1)                                                                                   # Exit with error code 1 to signal failure to the bash script
" "$vals" > "$PRESET_FILE"                                                                        # Pass $vals as argument to Python script and redirect Python's stdout output to the EasyEffects preset file

    easyeffects -l "$PRESET_NAME" >/dev/null 2>&1 &                                               # Load the preset in EasyEffects by name - runs in background (&), suppresses stdout and stderr (> /dev/null 2>&1)
}                                                                                                 # End of apply_eq function definition

# Save state helper (Always sets pending to false because Presets apply instantly)                 # Comment explaining the save_preset function always clears pending flag since EasyEffects presets take effect immediately
save_preset() {                                                                                   # Define function save_preset - writes band values and preset name to state file, always sets pending=false
    jq -n -c --arg b1 "$1" --arg b2 "$2" --arg b3 "$3" --arg b4 "$4" --arg b5 "$5" \             # Use jq (JSON processor) to create new JSON - -n means no input, -c means compact output, --arg sets variables from function arguments
          --arg b6 "$6" --arg b7 "$7" --arg b8 "$8" --arg b9 "$9" --arg b10 "${10}" --arg p "${11}" \  # Continue jq arguments - set b6-b10 and preset name from function arguments 6-11 (${10} and ${11} need braces for multi-digit)
       '{"b1": $b1, "b2": $b2, "b3": $b3, "b4": $b4, "b5": $b5, "b6": $b6, "b7": $b7, "b8": $b8, "b9": $b9, "b10": $b10, "preset": $p, "pending": false}' > "$STATE_FILE"  # Build JSON object with all band values, preset name, and pending=false, write to state file
}                                                                                                 # End of save_preset function definition

cmd=$1                                                                                            # Capture first command-line argument into 'cmd' variable - determines which action to perform (get, set_band, apply, preset)
arg1=$2                                                                                           # Capture second command-line argument into 'arg1' variable - used for band number or preset name
arg2=$3                                                                                           # Capture third command-line argument into 'arg2' variable - used for band gain value

case $cmd in                                                                                      # Begin case statement - evaluate the command ($cmd) and execute matching block
    "get") cat "$STATE_FILE" ;;                                                                   # If command is "get": output the entire state file contents to stdout (used by QML to read current state)
    "set_band")                                                                                   # If command is "set_band": update a specific band value without applying - stores slider position
        # SLIDER MOVE: Set pending = true, Preset = Custom. DO NOT APPLY.                         # Comment explaining this only updates state, marks as pending, and names preset "Custom" but doesn't apply changes
        tmp=$(cat "$STATE_FILE")                                                                  # Read current state file contents into 'tmp' variable
        updated=$(echo "$tmp" | jq -c --arg val "$arg2" ".b$arg1 = \$val | .preset = \"Custom\" | .pending = true")  # Use jq to update the specified band (b$arg1) with new value ($arg2), change preset name to "Custom", set pending=true, output compact JSON
        echo "$updated" > "$STATE_FILE"                                                           # Write the updated JSON back to the state file - overwrites previous state
        ;;                                                                                        # End of "set_band" case block
    "apply")                                                                                      # If command is "apply": apply the current equalizer settings to EasyEffects
        # APPLY BUTTON: Set pending = false, then Apply.                                          # Comment explaining this clears pending flag and applies the EQ
        tmp=$(cat "$STATE_FILE")                                                                  # Read current state file into 'tmp' variable
        updated=$(echo "$tmp" | jq -c ".pending = false")                                         # Use jq to set pending flag to false - keeps all other values unchanged
        echo "$updated" > "$STATE_FILE"                                                           # Write updated JSON back to state file
        apply_eq                                                                                  # Call apply_eq function to generate EasyEffects preset and load it
        ;;                                                                                        # End of "apply" case block
    "preset")                                                                                     # If command is "preset": apply a predefined equalizer preset
        # PRESET CLICK: Save values (pending=false) and Apply Instantly.                          # Comment explaining this saves preset values and applies immediately
        case $arg1 in                                                                             # Nested case statement - evaluate the preset name ($arg1) and select corresponding values
            "Flat")    save_preset 0 0 0 0 0 0 0 0 0 0 "Flat" ;;                                # Flat preset: all bands at 0dB - neutral/no equalization
            "Bass")    save_preset 5 7 5 2 1 0 0 0 1 2 "Bass" ;;                                # Bass preset: boosts low frequencies (bands 1-3), slight cut at mids (band 6-8), slight boost at highs
            "Treble")  save_preset -2 -1 0 1 2 3 4 5 6 6 "Treble" ;;                            # Treble preset: cuts low frequencies (bands 1-2), progressively boosts higher frequencies (bands 4-10)
            "Vocal")   save_preset -2 -1 1 3 5 5 4 2 1 0 "Vocal" ;;                             # Vocal preset: cuts sub-bass, boosts midrange where vocals sit (bands 3-7), cuts highest frequencies
            "Pop")     save_preset 2 4 2 0 1 2 4 2 1 2 "Pop" ;;                                 # Pop preset: moderate boost across lows and highs, slight mid cut - classic "smile" curve
            "Rock")    save_preset 5 4 2 -1 -2 -1 2 4 5 6 "Rock" ;;                             # Rock preset: strong bass boost, mid cut (bands 4-6), strong treble boost - emphasizes rhythm and lead
            "Jazz")    save_preset 3 3 1 1 1 1 2 1 2 3 "Jazz" ;;                                # Jazz preset: gentle bass boost, flat mids, slight treble presence - natural sound with warmth
            "Classic") save_preset 0 1 2 2 2 2 1 2 3 4 "Classic" ;;                             # Classic preset: subtle low cut, gradual treble boost - bright and clear for classical music
        esac                                                                                      # End of nested case statement for preset selection
        apply_eq                                                                                  # Call apply_eq function to immediately apply the selected preset to EasyEffects
        ;;                                                                                        # End of "preset" case block
esac                                                                                              # End of main case statement - script execution complete