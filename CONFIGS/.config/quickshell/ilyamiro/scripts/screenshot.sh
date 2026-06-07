#!/usr/bin/env bash
# ^ Specifies that this script should be run using the `bash` interpreter found in the user's PATH environment variable via `env`. This portable shebang locates bash dynamically rather than relying on a hardcoded absolute path.

# Ensure pactl can connect to PipeWire/PulseAudio regardless of launch context
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
# ^ Sets and exports the XDG_RUNTIME_DIR environment variable to the standard per-user runtime directory. The `$(id -u)` command substitution returns the current user's numeric UID, constructing a path like `/run/user/1000`. This is critical because PulseAudio/PipeWire store their communication sockets in this directory, and without it being properly set (e.g., when launched from a systemd service or different context), `pactl` would fail to connect to the audio server.

export PULSE_RUNTIME_PATH="$XDG_RUNTIME_DIR/pulse"
# ^ Sets and exports the PULSE_RUNTIME_PATH to point to the PulseAudio runtime directory within XDG_RUNTIME_DIR. This is where PulseAudio (or PipeWire's PulseAudio compatibility layer) stores its native protocol socket for client connections. Exporting this ensures all child processes of this script can communicate with the audio system correctly.

# ---------------------------------------------------------
# DEPENDENCY CHECK
# ---------------------------------------------------------
# First check for notify-send so we can display errors
if ! command -v notify-send &> /dev/null; then
    # ^ Checks if the `notify-send` command (used for desktop notifications) is available in the system PATH. The `command -v` builtin returns the path to the command if found, and `!` negates the result. Both stdout and stderr are redirected to /dev/null with `&>` to suppress output.

    echo "ERROR: notify-send is not installed. Cannot display missing dependencies."
    # ^ Prints an error message to the terminal (stdout) since desktop notifications are unavailable, informing the user that a critical dependency is missing.

    exit 1
    # ^ Exits the script immediately with a non-zero status code (1), indicating an error condition. Without notify-send, the script cannot provide user feedback for other missing dependencies.
fi

REQUIRED_CMDS=("gpu-screen-recorder" "grim" "satty" "wl-copy" "pactl" "quickshell" "zbarimg" "python3")
# ^ Defines an array called REQUIRED_CMDS containing the names of all executable commands that this script depends on. These include: gpu-screen-recorder (for video capture), grim (screenshot capture for Wayland), satty (screenshot annotation editor), wl-copy (Wayland clipboard utility), pactl (PulseAudio/PipeWire control), quickshell (QML shell for the UI overlay), zbarimg (QR/barcode scanner), and python3 (for XML parsing).

MISSING_CMDS=()
# ^ Initializes an empty array called MISSING_CMDS that will be populated with the names of any required commands that are not found on the system.

for cmd in "${REQUIRED_CMDS[@]}"; do
    # ^ Starts a for loop that iterates over each element in the REQUIRED_CMDS array. The `"${REQUIRED_CMDS[@]}"` expands to all array elements as separate words.

    if ! command -v "$cmd" &> /dev/null; then
        # ^ Checks if the current command (stored in `$cmd`) is NOT available in the system PATH. The `command -v` builtin returns the path if found, `!` negates the result, and output is suppressed.

        MISSING_CMDS+=("$cmd")
        # ^ Appends the missing command name to the MISSING_CMDS array using the `+=` operator, which adds a new element to the end of the array.
    fi
done

if [ ${#MISSING_CMDS[@]} -ne 0 ]; then
    # ^ Checks if the MISSING_CMDS array is not empty by comparing its length (`${#MISSING_CMDS[@]}` returns the number of elements) to zero using `-ne` (not equal). If there are missing dependencies, this condition is true.

    notify-send -u critical -a "Screenshot System" "Missing Dependencies" "Cannot start. Please install:\n${MISSING_CMDS[*]}"
    # ^ Sends a critical urgency (`-u critical`) desktop notification with the application name set to "Screenshot System" (`-a`). The notification title is "Missing Dependencies" and the body lists the missing commands. `${MISSING_CMDS[*]}` expands all array elements as a single string separated by spaces, and `\n` creates a newline for formatting.

    exit 1
    # ^ Exits the script with error code 1 since required dependencies are missing and the script cannot function properly.
fi
# ---------------------------------------------------------

# Directories
SAVE_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
# ^ Sets the directory where screenshots will be saved. Uses parameter expansion: if the XDG_PICTURES_DIR environment variable is set, use its value; otherwise fall back to `$HOME/Pictures`. The `/Screenshots` subdirectory is appended to organize screenshots separately from other pictures.

RECORD_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
# ^ Sets the directory where screen recordings will be saved. Uses the XDG_VIDEOS_DIR environment variable if set, otherwise defaults to `$HOME/Videos`. The `/Recordings` subdirectory keeps screen recordings organized separately from other videos.

CACHE_DIR="$HOME/.cache/qs_recording_state"
# ^ Sets the path to a cache directory used to store runtime state information for recordings, such as active process IDs, audio module IDs, and lock files. The `.cache` directory follows XDG conventions for non-essential temporary data.

mkdir -p "$SAVE_DIR" "$RECORD_DIR" "$CACHE_DIR"
# ^ Creates all three directories if they don't already exist. The `-p` flag creates parent directories as needed and suppresses errors for directories that already exist, ensuring the directory structure is ready before any files are saved.

# Parse arguments safely upfront
EDIT_MODE=false
# ^ Initializes the EDIT_MODE variable to `false`. When set to `true`, screenshots will be opened in the satty annotation editor after capture instead of being directly saved.

FULL_MODE=false
# ^ Initializes the FULL_MODE variable to `false`. When `true`, captures the entire screen/region immediately without showing the interactive overlay UI.

RECORD_MODE=false
# ^ Initializes the RECORD_MODE variable to `false`. When `true`, captures a video recording instead of a static screenshot.

SCAN_QR_MODE=false
# ^ Initializes the SCAN_QR_MODE variable to `false`. When `true`, captures a region and attempts to decode any QR codes found in it, exiting immediately with the decoded data.

GEOMETRY=""
# ^ Initializes the GEOMETRY variable to an empty string. When set, it contains the capture region in the format "x,y,width,height" (grim format), allowing captures of specific screen areas.

DESK_VOL="1.0"
# ^ Initializes the desktop audio volume to 1.0 (100%). This value is used when recording to set the desktop/system audio level, with the range from 0.0 (muted) to 1.0 (full volume).

DESK_MUTE="false"
# ^ Initializes the desktop audio mute flag to `false`. When set to `true`, desktop/system audio is excluded from screen recordings.

MIC_VOL="1.0"
# ^ Initializes the microphone volume to 1.0 (100%). This controls the microphone input level for screen recordings, ranging from 0.0 to 1.0.

MIC_MUTE="false"
# ^ Initializes the microphone mute flag to `false`. When `true`, microphone audio is excluded from recordings entirely.

MIC_DEVICE=""
# ^ Initializes the microphone device identifier to an empty string. When set, it specifies which audio input device to use for recordings (e.g., "alsa_input.pci-0000_00_1f.3.analog-stereo").

while [[ "$#" -gt 0 ]]; do
    # ^ Starts a while loop that continues as long as the number of positional parameters (`$#`) is greater than zero. This loop processes all command-line arguments passed to the script.

    case $1 in
        # ^ Opens a case statement that matches the first positional parameter (`$1`) against various patterns to determine which flag was passed.

        --edit) EDIT_MODE=true; shift ;;
        # ^ If `$1` is "--edit", sets EDIT_MODE to true and then shifts the positional parameters left by one (discarding the processed argument with `shift`). The `;;` terminates this case branch.

        --full) FULL_MODE=true; shift ;;
        # ^ If the "--full" flag is present, enables full mode (immediate capture without UI) and shifts past the argument.

        --record) RECORD_MODE=true; shift ;;
        # ^ If the "--record" flag is present, enables recording mode (video capture instead of screenshot) and shifts past the argument.

        --scan-qr) SCAN_QR_MODE=true; shift ;;
        # ^ If the "--scan-qr" flag is present, enables QR code scanning mode and shifts past the argument.

        --geometry) GEOMETRY="$2"; shift 2 ;;
        # ^ If the "--geometry" flag is found, captures the next argument (`$2`) as the geometry string (e.g., "0,0,1920,1080") and shifts by two positions to skip both the flag and its value.

        --desk-vol) DESK_VOL="$2"; shift 2 ;;
        # ^ Captures the desktop volume value from the argument following "--desk-vol" and shifts past both.

        --desk-mute) DESK_MUTE="$2"; shift 2 ;;
        # ^ Captures the desktop mute setting (expected to be "true" or "false") from the next argument and shifts past both.

        --mic-vol) MIC_VOL="$2"; shift 2 ;;
        # ^ Captures the microphone volume value from the argument following "--mic-vol" and shifts past both.

        --mic-mute) MIC_MUTE="$2"; shift 2 ;;
        # ^ Captures the microphone mute setting from the next argument and shifts past both.

        --mic-dev) MIC_DEVICE="$2"; shift 2 ;;
        # ^ Captures the microphone device identifier from the next argument and shifts past both the flag and its value.

        *) shift ;;
        # ^ The wildcard pattern `*` matches any unrecognized argument, simply shifting past it without taking any action. This allows graceful handling of unknown flags without errors.
    esac
    # ^ Closes the case statement.
done
# ^ Ends the while loop when all arguments have been processed.

# ---------------------------------------------------------
# INSTANT QR SCANNING EXECUTION
# ---------------------------------------------------------
if [ "$SCAN_QR_MODE" = true ]; then
    # ^ Checks if the QR code scanning mode was activated via command-line arguments. If true, the script immediately performs a QR scan and exits without showing any UI.

    RES_FILE="/tmp/qs_qr_result"
    # ^ Defines the path to a temporary file where the QR scan results will be stored. This file is read by other components (like the QML interface) to retrieve decoded QR data.

    export DEBUG_LOG="/tmp/qs_qr_debug.log"
    # ^ Sets and exports the path to a debug log file where detailed QR scanning diagnostic information will be written. The `export` makes it available to child processes like the Python script.

    rm -f "$RES_FILE" "$DEBUG_LOG"
    # ^ Removes any previous result and debug log files to ensure clean output for the current scan. The `-f` flag suppresses errors if the files don't exist.

    echo "=== QR SCAN INITIATED $(date) ===" > "$DEBUG_LOG"
    # ^ Writes a header line with a timestamp to the debug log file, marking the start of a new QR scanning session. The `$(date)` command substitution inserts the current date and time.

    if ! command -v zbarimg &> /dev/null; then
        # ^ Verifies that the `zbarimg` command (the QR/barcode scanning utility) is available. If not, scanning cannot proceed.

        echo -e "0,0,0,0|||ERROR: zbarimg is not installed. Please install it." > "$RES_FILE"
        # ^ Writes an error message in the expected result format to the result file. The `-e` flag enables interpretation of escape sequences. The format "0,0,0,0|||..." indicates no QR code bounds were found, and the text after "|||" is the error message.

        exit 1
        # ^ Exits with error code 1 because QR scanning is impossible without zbarimg.
    fi

    TMP_IMG="/dev/shm/qs_qr_temp_$$.png"
    # ^ Constructs a temporary file path for the screenshot used in QR detection. `/dev/shm` is a RAM-based filesystem (tmpfs) for fast I/O. `$$` is the current process ID, making the filename unique to prevent collisions with concurrent script executions.

    grim -g "$GEOMETRY" "$TMP_IMG"
    # ^ Captures a screenshot of the specified geometry region using `grim` (the Wayland screenshot utility). The `-g` flag passes the geometry string (format "x,y,width,height") to capture only a specific area of the screen, and the output is saved to the temporary file.

    export XML_OUT=$(zbarimg --xml -q "$TMP_IMG" 2>>"$DEBUG_LOG")
    # ^ Runs `zbarimg` on the captured screenshot to detect and decode any QR codes. The `--xml` flag requests XML-formatted output containing decoded data and position coordinates. The `-q` flag enables quiet mode. Standard error is appended to the debug log. The result is stored in the XML_OUT environment variable and exported for use by the Python parser. Using `export` with command substitution on the same line ensures the variable is available to child processes.

    if [ -n "$XML_OUT" ]; then
        # ^ Checks if the XML output is not empty (`-n` tests for non-zero length), meaning zbarimg detected at least one QR code or symbol in the image.

        python3 << 'EOF' > "$RES_FILE"
        # ^ Starts a heredoc that passes a Python script inline to the Python 3 interpreter. The single quotes around 'EOF' prevent shell variable expansion within the heredoc, allowing the Python code to contain shell-like syntax without interference. The output of the Python script is redirected to the result file. The script parses the XML output and extracts QR code data with bounding box coordinates.

import os, sys, logging, re
# ^ Imports necessary Python modules: `os` for environment access, `sys` for exit functionality, `logging` for debug output, and `re` for regular expression operations to clean XML.

import xml.etree.ElementTree as ET
# ^ Imports the ElementTree XML parsing library to parse the zbarimg XML output and navigate its element structure.

debug_log = os.environ.get("DEBUG_LOG", "/tmp/qs_qr_debug.log")
# ^ Retrieves the debug log file path from the DEBUG_LOG environment variable (which was exported by the shell script). If not set, defaults to the same path.

logging.basicConfig(filename=debug_log, level=logging.DEBUG, format="%(asctime)s - %(levelname)s - %(message)s")
# ^ Configures Python's logging module to write debug-level messages and above to the specified debug log file. The format includes timestamps, severity levels, and the message content.

raw_xml = os.environ.get("XML_OUT", "")
# ^ Reads the raw XML string from the XML_OUT environment variable that was exported by the shell script containing zbarimg's output.

if not raw_xml.strip():
    # ^ Checks if the XML output is empty or contains only whitespace after stripping. If true, zbarimg found nothing to report.

    print("0,0,0,0|||ERROR: Empty output from zbarimg. See log.")
    # ^ Prints an error message to stdout (which is redirected to the result file) in the expected format indicating no QR code was found.

    sys.exit(0)
    # ^ Exits the Python script successfully (status 0) since the error message has already been written to the result file.

try:
    # ^ Opens a try block to catch any exceptions that might occur during XML parsing or processing.

    xml_clean = re.sub(r'\sxmlns="[^"]+"', '', raw_xml)
    # ^ Removes XML namespace declarations (like `xmlns="http://..."`) from the raw XML string using a regular expression. The pattern matches whitespace followed by xmlns="..." and replaces it with an empty string. This simplifies parsing by removing namespace qualifiers.

    xml_clean = re.sub(r"\sxmlns='[^']+'", '', xml_clean)
    # ^ Performs the same namespace removal but for single-quoted namespace declarations (xmlns='...'), handling both quoting styles.

    tree = ET.fromstring(xml_clean)
    # ^ Parses the cleaned XML string into an ElementTree object, creating a traversable tree structure of XML elements.

    found_any = False
    # ^ Initializes a flag to track whether any valid symbols were found during iteration. Starts as False and will be set to True if at least one symbol with data is processed.

    for elem in tree.iter():
        # ^ Iterates over all elements in the XML tree recursively (including nested children). This allows finding symbol elements regardless of their depth in the tree structure.

        if elem.tag.endswith('symbol'):
            # ^ Checks if the current element's tag name ends with 'symbol' (zbarimg uses tags like 'symbol' for each detected code). Using `endswith` handles potential namespace prefixes.

            found_any = True
            # ^ Sets the flag to True since we've found at least one symbol element with possible QR data.

            data_text = ''
            # ^ Initializes an empty string to store the decoded data content of the QR code.

            min_x, min_y, max_x, max_y = float('inf'), float('inf'), -float('inf'), -float('inf')
            # ^ Initializes bounding box coordinates: min_x and min_y start at positive infinity (so any real coordinate will be smaller), while max_x and max_y start at negative infinity (so any real coordinate will be larger). This ensures the first encountered point sets all four boundaries.

            for child in elem:
                # ^ Iterates over the child elements of the current symbol element to find data content and position information.

                if child.tag.endswith('data'):
                    # ^ If the child element's tag ends with 'data', it contains the decoded QR code text content.

                    data_text = child.text if child.text else ''
                    # ^ Extracts the text content of the data element. If child.text is None (no text), uses an empty string instead to prevent errors.

                elif child.tag.endswith('polygon'):
                    # ^ If the child element's tag ends with 'polygon', it contains the corner points defining the QR code's location in the image.

                    pts_str = child.get('points', '')
                    # ^ Retrieves the 'points' attribute from the polygon element, which contains space-separated coordinate pairs. Defaults to empty string if the attribute doesn't exist.

                    if pts_str:
                        # ^ Checks if the points string is not empty, meaning there are coordinates to process.

                        pt_pairs = pts_str.replace('+', '').split(' ')
                        # ^ Removes any plus signs from the points string and splits it by spaces to get individual coordinate pairs (like ["x,y", "x,y", ...]).

                        for pair in pt_pairs:
                            # ^ Iterates over each coordinate pair string.

                            if ',' in pair:
                                # ^ Verifies the pair contains a comma, confirming it's in the expected "x,y" format.

                                try:
                                    # ^ Opens a try block to catch conversion errors if the coordinate values are not valid integers.

                                    x_str, y_str = pair.split(',')
                                    # ^ Splits the pair by comma to separate the x and y coordinate strings.

                                    x, y = int(x_str), int(y_str)
                                    # ^ Converts the coordinate strings to integers.

                                    min_x = min(min_x, x)
                                    # ^ Updates the minimum X coordinate if the current x is smaller than the stored minimum.

                                    max_x = max(max_x, x)
                                    # ^ Updates the maximum X coordinate if the current x is larger than the stored maximum.

                                    min_y = min(min_y, y)
                                    # ^ Updates the minimum Y coordinate.

                                    max_y = max(max_y, y)
                                    # ^ Updates the maximum Y coordinate.

                                except ValueError:
                                    # ^ Catches any ValueError exceptions if the coordinate strings cannot be converted to integers.

                                    pass
                                    # ^ Silently ignores malformed coordinate pairs and continues to the next one.

            if min_x == float('inf'): min_x, min_y, max_x, max_y = 0, 0, 0, 0
            # ^ If no valid coordinates were found (min_x is still infinity), sets all bounding box values to 0 to indicate no position data was available.

            w, h = max_x - min_x, max_y - min_y
            # ^ Calculates the width and height of the bounding box by subtracting minimum coordinates from maximum coordinates.

            encoded = data_text.replace('\\', '\\\\').replace('\n', '\\n').replace('\r', '')
            # ^ Escapes special characters in the decoded text: backslashes are doubled, newlines are converted to literal "\n" strings, and carriage returns are removed. This ensures the data fits on a single line without breaking the result format.

            print(f"{int(min_x)},{int(min_y)},{int(w)},{int(h)}|||{encoded}")
            # ^ Prints the result in the expected format: bounding box coordinates (x,y,width,height) separated by commas, followed by "|||" as a delimiter, then the decoded QR data. The QML interface parses this format to highlight the QR code position and display its contents.

    if not found_any: print("0,0,0,0|||NOT_FOUND")
    # ^ If no symbol elements were found after iterating the entire tree, prints a "NOT_FOUND" result with zero coordinates to indicate no QR code was detected in the image.

except Exception as e:
    # ^ Catches any exception that occurs during XML parsing or processing.

    print(f"0,0,0,0|||ERROR: XML Parse failure: {e}. Check log.")
    # ^ Prints an error result with the exception details, informing the user to check the debug log for more information.
EOF
        # ^ The 'EOF' delimiter marks the end of the Python heredoc. The Python script's stdout has been redirected to the result file throughout its execution.
    else
        echo -e "0,0,0,0|||NOT_FOUND" > "$RES_FILE"
        # ^ If zbarimg produced no XML output (no symbols detected at all), writes a "NOT_FOUND" result directly to the result file from the shell script.
    fi
    
    rm -f "$TMP_IMG"
    # ^ Removes the temporary screenshot image from the RAM disk, cleaning up after QR processing is complete.

    exit 0
    # ^ Exits the script successfully after completing the QR scan operation. The result file at RES_FILE is left for the calling process to read.
fi

# ---------------------------------------------------------
# SMART TOGGLE: STOP RECORDING & CLEANUP VIRTUAL AUDIO
# ---------------------------------------------------------
if [ -f "$CACHE_DIR/rec_pid" ]; then
    # ^ Checks if a recording PID file exists in the cache directory. This file's presence indicates that a screen recording is currently in progress, so this script invocation should stop that recording rather than start a new one.

    # PREVENT OVERLAPPING EXECUTIONS
    if [ -f "$CACHE_DIR/processing.lock" ]; then exit 0; fi
    # ^ Checks if a processing lock file exists, which would indicate that another instance of this script is already in the process of stopping the recording. If so, exits immediately with success to prevent multiple simultaneous stop attempts that could corrupt the video file or cause race conditions.

    touch "$CACHE_DIR/processing.lock"
    # ^ Creates (or updates the timestamp of) the processing lock file to prevent other script instances from interfering with this recording stop operation. This acts as a mutex.

    REC_PID=$(cat "$CACHE_DIR/rec_pid")
    # ^ Reads the process ID of the running gpu-screen-recorder process from the cache file and stores it in the REC_PID variable.

    FINAL_FILE=$(cat "$CACHE_DIR/final_file")
    # ^ Reads the path to the expected final video file from the cache file and stores it in the FINAL_FILE variable for later verification.

    # 1. SEND STOP SIGNAL TO GPU-SCREEN-RECORDER
    [ "$REC_PID" != "0" ] && kill -SIGINT $REC_PID 2>/dev/null
    # ^ If the recorded PID is not "0" (meaning it's a valid PID), sends the SIGINT signal (equivalent to Ctrl+C) to the gpu-screen-recorder process. This is the graceful way to tell gpu-screen-recorder to finalize and close the video file. Errors are suppressed with `2>/dev/null` in case the process has already terminated.

    # 2. WAIT FOR GSR TO CLOSE GRACEFULLY AND FINALIZE MP4
    timeout=30
    # ^ Initializes a timeout counter to 30 iterations. Combined with the 0.1 second sleep, this provides a maximum wait time of 3 seconds for the recorder to exit gracefully.

    while kill -0 $REC_PID 2>/dev/null && [ $timeout -gt 0 ]; do
        # ^ Loops as long as: (1) the process with the stored PID still exists (`kill -0` sends no signal but checks if the process is alive, with errors suppressed), AND (2) the timeout counter hasn't reached zero. This waits for gpu-screen-recorder to finalize the video file.

        sleep 0.1
        # ^ Pauses for 0.1 seconds (100 milliseconds) between checks to avoid busy-waiting and consuming CPU unnecessarily.

        timeout=$((timeout - 1))
        # ^ Decrements the timeout counter by 1 each iteration. After 30 iterations (approximately 3 seconds), the loop will exit even if the process is still running.
    done

    # FORCE KILL IF STUCK
    [ "$REC_PID" != "0" ] && kill -9 $REC_PID 2>/dev/null
    # ^ If the process still exists after the timeout period (or if it's stuck), sends the SIGKILL signal (-9) to forcefully terminate it. SIGKILL cannot be caught or ignored by the process, ensuring it stops. Errors are suppressed if the process already exited.

    # 3. DESTROY PIPEWIRE VIRTUAL AUDIO CABLES
    if [ -f "$CACHE_DIR/pw_modules" ]; then
        # ^ Checks if a file listing PipeWire module IDs exists. This file was created when audio routing was set up for the recording.

        while read -r mod_id; do
            # ^ Reads the module IDs file line by line, storing each line in the `mod_id` variable. The `-r` flag prevents backslash interpretation.

            [ -n "$mod_id" ] && pactl unload-module "$mod_id" 2>/dev/null
            # ^ If the module ID is not empty, uses `pactl unload-module` to remove the PipeWire virtual audio module. This cleans up the virtual sinks and loopbacks that were created for mixing desktop and microphone audio. Errors are suppressed if the module was already removed.
        done < "$CACHE_DIR/pw_modules"
        # ^ Redirects the contents of the pw_modules file as input to the while loop.

        rm -f "$CACHE_DIR/pw_modules"
        # ^ Removes the module IDs file after all modules have been unloaded, completing the audio cleanup.
    fi

    # 4. SEND FINAL NOTIFICATION
    if [ -f "$FINAL_FILE" ]; then
        # ^ Checks if the final video file exists at the expected path, confirming that gpu-screen-recorder successfully saved the recording.

        notify-send -a "Screen Recorder" -i "$FINAL_FILE" "⏺ Recording Saved" "File: $(basename "$FINAL_FILE")\nFolder: $RECORD_DIR"
        # ^ Sends a desktop notification with the application name "Screen Recorder", using the video file as the notification icon (`-i`). The title shows a recording symbol and "Recording Saved". The body shows the filename (extracted with `basename`) and the folder path where it was saved.

    else
        notify-send -a "Screen Recorder" "❌ Error" "Failed to save the video file."
        # ^ If the final video file doesn't exist, sends an error notification indicating the recording failed to save.
    fi

    # 5. INSTANT UI CLEANUP
    rm -f "$CACHE_DIR/processing.lock"
    # ^ Removes the processing lock file, allowing future script invocations to start new recordings.

    rm -f "$CACHE_DIR/rec_pid" "$CACHE_DIR/final_file"
    # ^ Removes both the PID file and the final file path cache, fully cleaning up the recording state.

    exit 0
    # ^ Exits the script successfully after stopping the recording and cleaning up.
fi

time=$(date +'%Y-%m-%d-%H%M%S')
# ^ Generates a timestamp string in the format "YYYY-MM-DD-HHMMSS" (e.g., "2026-05-12-143025"). This is used to create unique filenames for screenshots and recordings, ensuring no files are overwritten.

FILENAME="$SAVE_DIR/Screenshot_$time.png"
# ^ Constructs the full path for screenshot files by combining the save directory, the prefix "Screenshot_", the timestamp, and the ".png" extension.

VID_FILENAME="$RECORD_DIR/Recording_$time.mp4"
# ^ Constructs the full path for recording files using the recordings directory, the prefix "Recording_", the timestamp, and the ".mp4" video extension.

CACHE_FILE="$HOME/.cache/qs_screenshot_geom"
# ^ Defines the path to a cache file that stores the last used capture geometry (region coordinates). This allows the UI overlay to remember and restore the user's previous selection.

MODE_CACHE_FILE="$HOME/.cache/qs_screenshot_mode"
# ^ Defines the path to a cache file that stores the last used capture mode ("true" for full screen, "false" for region selection). This persists the user's preference between uses.

rm -f "$CACHE_DIR/processing.lock"
# ^ Removes any stale processing lock file that might exist from a previous interrupted operation, ensuring the script can proceed without blocking.

# ---------------------------------------------------------
# PHASE 1: Capture Execution (GPU-Screen-Recorder + Virtual Audio)
# ---------------------------------------------------------
if [ "$FULL_MODE" = true ] || [ -n "$GEOMETRY" ]; then
    # ^ Checks if either full mode is enabled (capture entire screen immediately) OR a specific geometry was provided (capture a predefined region). If either is true, the script proceeds with direct capture rather than showing the interactive UI overlay.

    if [ "$RECORD_MODE" = true ]; then
        # ^ Checks if recording mode is enabled. If true, captures a video recording instead of a static screenshot.

        # Clear out any old module IDs
        echo -n "" > "$CACHE_DIR/pw_modules"
        # ^ Creates or truncates the PipeWire module IDs file, clearing any stale module IDs from previous recordings. The `-n` flag prevents adding a trailing newline.

        DESK_SINK=$(pactl get-default-sink 2>/dev/null)
        # ^ Retrieves the name of the default audio sink (output device) using `pactl`. Errors are suppressed in case pactl cannot connect. This will be used to capture system/desktop audio.

        [ -n "$DESK_SINK" ] && DESK_DEV="${DESK_SINK}.monitor" || DESK_DEV=""
        # ^ If a default sink was found, constructs the monitor source name by appending ".monitor" to the sink name. The monitor source captures the audio being played through that sink. If no sink was found, sets DESK_DEV to empty, disabling desktop audio capture.

        [ -n "$MIC_DEVICE" ] && [ "$MIC_DEVICE" != "null" ] && MIC_DEV="$MIC_DEVICE" || MIC_DEV=$(pactl get-default-source 2>/dev/null)
        # ^ Determines the microphone device to use with a three-part logic: if MIC_DEVICE was provided and is not "null", use it; otherwise, fall back to the system's default audio source (typically the built-in microphone). Stores the result in MIC_DEV.

        MIC_DEV="${MIC_DEV:-default}"
        # ^ If MIC_DEV is still empty or unset after the previous assignment, defaults to the string "default", which tells PulseAudio/PipeWire to use the system default input device.

        # Reverted back to the portal method for reliable security clearance
        GSR_ARGS=(-w "portal" -c "mp4" -f "60" -ac "aac")
        # ^ Initializes an array of arguments for gpu-screen-recorder: `-w "portal"` uses the XDG Desktop Portal for screen capture (providing secure, compositor-approved access without needing special permissions), `-c "mp4"` sets the container format to MP4, `-f "60"` sets the framerate to 60 FPS, and `-ac "aac"` uses AAC audio codec for encoding audio tracks.

        AUDIO_MIX=""
        # ^ Initializes an empty string that will accumulate PipeWire audio sources separated by the pipe character "|", forming a mixed audio track for the recording.

        # --- DESKTOP AUDIO VIRTUAL ROUTING ---
        if [ "$DESK_MUTE" != "true" ] && [ -n "$DESK_DEV" ]; then
            # ^ Checks if desktop audio is NOT muted AND a valid desktop audio device exists. If both conditions are met, desktop audio will be included in the recording.

            # Create a virtual sink
            D_SINK_ID=$(pactl load-module module-null-sink sink_name=qs_virt_desk sink_properties=device.description="QS_Virtual_Desk")
            # ^ Creates a virtual null sink (a dummy audio device) named "qs_virt_desk" with a human-readable description using PipeWire's module-null-sink. The `pactl load-module` command returns the module ID, which is stored for later cleanup. This virtual sink acts as a mixing point for desktop audio.

            # Loop the real desktop audio into the virtual sink
            D_LOOP_ID=$(pactl load-module module-loopback source="$DESK_DEV" sink=qs_virt_desk)
            # ^ Creates a loopback module that routes audio from the desktop monitor source (capturing system output) to the virtual sink "qs_virt_desk". The module ID is stored for cleanup. This effectively copies desktop audio into the virtual sink where it can be captured by the recorder.

            # Linearize volume calculation (0 - 65536) to prevent PulseAudio's steep cubic drop-off at 25%
            D_VOL_INT=$(awk "BEGIN {print int(${DESK_VOL//,/.} * 65536)}")
            # ^ Converts the decimal volume (0.0 to 1.0) to PulseAudio's internal integer representation (0 to 65536). The `${DESK_VOL//,/.}` replaces any commas with periods for proper float parsing. `awk` performs the multiplication and `int()` truncates to an integer. The comment notes this avoids PulseAudio's non-linear cubic volume curve that causes steep drops at low percentages.

            pactl set-sink-volume qs_virt_desk "$D_VOL_INT"
            # ^ Sets the volume of the virtual desktop sink to the calculated integer value, applying the user's desired desktop audio level to the recording.

            # Save IDs for teardown
            echo "$D_SINK_ID" >> "$CACHE_DIR/pw_modules"
            # ^ Appends the virtual sink module ID to the modules file for cleanup when recording stops.

            echo "$D_LOOP_ID" >> "$CACHE_DIR/pw_modules"
            # ^ Appends the loopback module ID to the modules file for cleanup.

            # Append to mixing string
            AUDIO_MIX="${AUDIO_MIX}qs_virt_desk.monitor|"
            # ^ Appends the monitor source of the virtual desktop sink to the audio mix string, followed by a pipe separator. The ".monitor" suffix captures the audio flowing through the sink. This tells gpu-screen-recorder to include this audio source in the recording.
        fi

        # --- MICROPHONE VIRTUAL ROUTING ---
        if [ "$MIC_MUTE" != "true" ] && [ -n "$MIC_DEV" ]; then
            # ^ Checks if the microphone is NOT muted AND a valid microphone device exists. If both conditions are met, microphone audio will be included.

            # Create a virtual sink for the mic
            M_SINK_ID=$(pactl load-module module-null-sink sink_name=qs_virt_mic sink_properties=device.description="QS_Virtual_Mic")
            # ^ Creates a virtual null sink named "qs_virt_mic" with a description of "QS_Virtual_Mic", and stores the returned module ID for cleanup.

            # Loop the real mic into the virtual sink
            M_LOOP_ID=$(pactl load-module module-loopback source="$MIC_DEV" sink=qs_virt_mic)
            # ^ Creates a loopback from the selected microphone device to the virtual microphone sink. This routes the user's microphone input through the virtual sink for capture. The module ID is stored for cleanup.

            # Linearize volume calculation (0 - 65536) to prevent PulseAudio's steep cubic drop-off
            M_VOL_INT=$(awk "BEGIN {print int(${MIC_VOL//,/.} * 65536)}")
            # ^ Converts the microphone volume from decimal to PulseAudio's integer format, applying the same linearization as desktop audio to avoid non-linear volume behavior.

            pactl set-sink-volume qs_virt_mic "$M_VOL_INT"
            # ^ Applies the calculated microphone volume to the virtual microphone sink.

            # Save IDs for teardown
            echo "$M_SINK_ID" >> "$CACHE_DIR/pw_modules"
            # ^ Records the microphone virtual sink module ID for later cleanup.

            echo "$M_LOOP_ID" >> "$CACHE_DIR/pw_modules"
            # ^ Records the microphone loopback module ID for later cleanup.

            # Append to mixing string
            AUDIO_MIX="${AUDIO_MIX}qs_virt_mic.monitor|"
            # ^ Appends the monitor source of the virtual microphone sink to the audio mix string. This includes microphone audio in the recording.
        fi

        # Remove trailing pipe and add the single mix string to the recorder so everything stays on one track
        AUDIO_MIX=${AUDIO_MIX%|}
        # ^ Removes the trailing pipe character from the audio mix string using the `%` suffix removal operator. This ensures the string format is correct (no dangling separator) before passing it to gpu-screen-recorder.

        if [ -n "$AUDIO_MIX" ]; then
            # ^ Checks if the audio mix string is not empty, meaning at least one audio source was configured for recording.

            GSR_ARGS+=(-a "$AUDIO_MIX")
            # ^ Appends the audio mix argument to the gpu-screen-recorder arguments array. The `-a` flag specifies which PipeWire audio sources to record. The `+=` operator appends to the existing array.
        fi

        # Execute gpu-screen-recorder
        gpu-screen-recorder "${GSR_ARGS[@]}" -o "$VID_FILENAME" > /dev/null 2>&1 &
        # ^ Launches gpu-screen-recorder with all accumulated arguments (`${GSR_ARGS[@]}` expands the array to individual arguments), specifying the output file with `-o`. Both stdout and stderr are redirected to /dev/null. The `&` at the end runs the recorder in the background, allowing the script to continue.

        REC_PID=$!
        # ^ Captures the process ID of the just-launched background gpu-screen-recorder process using the special `$!` variable.

        echo "$REC_PID" > "$CACHE_DIR/rec_pid"
        # ^ Writes the recorder's PID to the cache file so the script can later identify and stop the recording process.

        echo "$VID_FILENAME" > "$CACHE_DIR/final_file"
        # ^ Writes the expected output video file path to the cache file, used later to verify the recording was saved successfully.

        notify-send -a "Screen Recorder" "⏺ Recording Started" "Press your screenshot shortcut again to stop."
        # ^ Sends a desktop notification informing the user that screen recording has begun and instructing them to press the same shortcut again to stop recording.

        exit 0
        # ^ Exits the script successfully after launching the recording. The recording continues in the background, and a second invocation of this script will detect the PID file and stop it.
    fi

    # Mode: Screenshot
    GRIM_CMD="grim -"
    # ^ Initializes the grim command with just `-` as the output argument, which tells grim to write the screenshot to stdout (enabling piping to other commands). No geometry is specified yet, so this would capture the full screen by default.

    [ -n "$GEOMETRY" ] && GRIM_CMD="grim -g \"$GEOMETRY\" -"
    # ^ If a specific geometry was provided, overrides the grim command to include the `-g` flag with the geometry string (e.g., "0,0,1920,1080") for region-specific capture, still outputting to stdout with `-`.

    if [ "$EDIT_MODE" = true ]; then
        # ^ Checks if edit mode is enabled, meaning the screenshot should be opened in the satty annotation editor before being saved.

        eval $GRIM_CMD | GSK_RENDERER=gl satty --filename - --output-filename "$FILENAME" --init-tool brush --copy-command wl-copy
        # ^ This pipeline: `eval` expands the grim command (including the geometry string if present), executes it to capture the screenshot to stdout. The output is piped to `satty`, an image annotation tool. The environment variable `GSK_RENDERER=gl` sets the GTK scene graph renderer to OpenGL for hardware acceleration. Satty arguments: `--filename -` reads from stdin, `--output-filename "$FILENAME"` saves the edited result to the timestamped file, `--init-tool brush` starts with the brush/drawing tool selected, and `--copy-command wl-copy` copies the final image to the Wayland clipboard after editing.
    else
        eval $GRIM_CMD | tee "$FILENAME" | wl-copy
        # ^ If edit mode is off, captures the screenshot, pipes it through `tee` which saves a copy to the timestamped file while also passing the data through to `wl-copy`, which copies the screenshot directly to the Wayland clipboard. This provides both a saved file and clipboard access without requiring the annotation editor.
    fi

    [ -s "$FILENAME" ] && notify-send -a "Screenshot" -i "$FILENAME" "Screenshot Saved" "File: Screenshot_$time.png\nFolder: $SAVE_DIR"
    # ^ If the screenshot file exists and has a non-zero size (`-s` test), sends a desktop notification confirming the save. The notification uses the screenshot itself as the icon (`-i`), with the title "Screenshot Saved" and the filename and folder location in the body.

    exit 0
    # ^ Exits successfully after completing the screenshot capture and notification.
fi

# ---------------------------------------------------------
# PHASE 2: UI Trigger (Launch Standalone Quickshell Overlay)
# ---------------------------------------------------------
QML_PATH="$HOME/.config/hypr/scripts/quickshell/ScreenshotOverlay.qml"
# ^ Defines the full path to the QuickShell QML file that provides the interactive screenshot/recording overlay UI. This overlay allows the user to select capture regions, toggle modes, and adjust audio settings.

if pgrep -f "quickshell -p $QML_PATH" > /dev/null; then
    # ^ Checks if the ScreenshotOverlay quickshell process is already running by searching for its full command line using `pgrep -f`. Output is suppressed since we only care about the exit status.

    pkill -f "quickshell -p $QML_PATH"
    # ^ If the overlay is already running, kills it with `pkill -f` using the same pattern match. This effectively toggles the overlay: if it's visible, hide it; if it's hidden, the next lines will launch it.

    exit 0
    # ^ Exits after killing the existing overlay since toggling it off was the intended action.
fi

if command -v pactl &> /dev/null; then
    # ^ Checks if the `pactl` command is available for audio device enumeration. This is only needed for the recording mode UI to populate microphone options.

    export QS_MIC_LIST=$(pactl list sources short 2>/dev/null | awk '{print $2}' | grep -v '\.monitor$' | while IFS= read -r name; do
        # ^ Constructs a list of available microphones and exports it as the QS_MIC_LIST environment variable for the QML overlay. The pipeline: `pactl list sources short` lists all audio sources, `awk '{print $2}'` extracts only the device name column, `grep -v '\.monitor$'` filters out monitor sources (which capture output, not input), and the while loop processes each remaining input device.

        desc=$(pactl list sources 2>/dev/null | awk -v n="$name" '/Name:/ { found = ($2 == n) } found && /Description:/ { sub(/^[[:space:]]*Description:[[:space:]]*/, ""); print; exit }')
        # ^ For each microphone, retrieves its human-readable description using a multi-step awk script. `-v n="$name"` passes the device name to awk. The pattern `/Name:/` checks each "Name:" line, setting `found = ($2 == n)` to true when the device name matches. When `found` is true AND the line contains "Description:", it strips the label prefix with `sub()` and prints the description, then exits.

        echo "$name|${desc:-$name}"
        # ^ Outputs a formatted string with the device name and description separated by a pipe character. If no description was found, falls back to using the device name as the description. This format allows the QML interface to parse and display the microphone list.
    done)
    # ^ Closes the command substitution and export. The QS_MIC_LIST variable now contains newline-separated entries of "device_name|description" pairs.
else
    export QS_MIC_LIST=""
    # ^ If pactl is not available, exports an empty microphone list. The QML overlay will show no microphone options in this case.
fi

PREFS="$HOME/.cache/qs_audio_prefs"
# ^ Defines the path to a cache file that stores the user's persistent audio preferences (volumes, mute states, device selection) between sessions.

if [ -f "$PREFS" ]; then
    # ^ Checks if the audio preferences file exists, meaning the user has previously configured and saved audio settings.

    IFS=',' read -r QS_DESK_VOL QS_DESK_MUTE QS_MIC_VOL QS_MIC_MUTE QS_MIC_DEV < "$PREFS"
    # ^ Reads the preferences file and splits the comma-separated values into five variables using `IFS=','` to set the field separator. The variables are: desktop volume, desktop mute state, microphone volume, microphone mute state, and the preferred microphone device name. The `-r` flag prevents backslash interpretation.

    export QS_DESK_VOL QS_DESK_MUTE QS_MIC_VOL QS_MIC_MUTE QS_MIC_DEV
    # ^ Exports all five audio preference variables so they are available as environment variables to the QML overlay process.
fi

[ "$EDIT_MODE" = true ] && export QS_SCREENSHOT_EDIT="true" || export QS_SCREENSHOT_EDIT="false"
# ^ Sets and exports the QS_SCREENSHOT_EDIT environment variable based on the EDIT_MODE flag. If true, the QML overlay will configure itself to send screenshots to the editor; if false, it will use direct save mode.

[ -f "$CACHE_FILE" ] && export QS_CACHED_GEOM=$(cat "$CACHE_FILE") || export QS_CACHED_GEOM=""
# ^ If the geometry cache file exists, reads its content and exports it as QS_CACHED_GEOM. This restores the user's previously selected capture region in the overlay. If the cache file doesn't exist, exports an empty string.

[ -f "$MODE_CACHE_FILE" ] && export QS_CACHED_MODE=$(cat "$MODE_CACHE_FILE") || export QS_CACHED_MODE="false"
# ^ If the mode cache file exists, reads its content (expected to be "true" or "false") and exports it as QS_CACHED_MODE. This restores whether the user last used full-screen or region capture mode. Defaults to "false" (region mode) if no cache exists.

quickshell -p "$QML_PATH"
# ^ Launches the QuickShell application with the ScreenshotOverlay QML file. This displays the interactive screenshot/recording overlay UI to the user. The command runs in the foreground (no `&`), meaning the script blocks until the user closes the overlay, at which point the overlay will have written geometry and mode selections back to the cache files for the next invocation.