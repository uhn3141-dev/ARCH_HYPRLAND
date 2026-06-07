#!/usr/bin/env bash
# ^ Specifies that this script should be run using the `bash` interpreter found in the user's PATH environment variable, ensuring consistent Bash behavior.

# -----------------------------------------------------------------------------
# CONSTANTS & ARGUMENTS
# -----------------------------------------------------------------------------
QS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ^ Determines the directory where this script (qs_manager.sh) is located. It changes to that directory using `cd`, then prints the absolute path with `pwd`, storing it in QS_DIR. The `${BASH_SOURCE[0]}` variable holds the path of the currently executing script.

BT_PID_FILE="$HOME/.cache/bt_scan_pid"
# ^ Defines the path to a file that will store the Process ID (PID) of the background Bluetooth scanning process. The `$HOME` variable expands to the current user's home directory.

BT_SCAN_LOG="$HOME/.cache/bt_scan.log"
# ^ Defines the path to a log file where the output of the Bluetooth scanning process will be written. This allows the QML interface to read scan results.

SRC_DIR="${WALLPAPER_DIR:-${srcdir:-$HOME/Pictures/Wallpapers}}"
# ^ Sets the source directory for wallpaper files. It uses parameter expansion with fallbacks: first checks if the WALLPAPER_DIR environment variable is set, then checks srcdir, and finally defaults to `$HOME/Pictures/Wallpapers` if neither is set.

THUMB_DIR="$HOME/.cache/wallpaper_picker/thumbs"
# ^ Sets the directory where thumbnail images for the wallpaper picker will be stored. These are cached, resized versions of the original wallpapers.

# User-specific cache directory matching the QML logic
QS_NETWORK_CACHE="${XDG_RUNTIME_DIR:-$HOME/.cache}/qs_network"
# ^ Defines a cache directory for network-related QuickShell data. It uses the XDG_RUNTIME_DIR environment variable if set (common on systemd systems), otherwise falls back to `$HOME/.cache`. This directory will store the current network mode.

mkdir -p "$QS_NETWORK_CACHE"
# ^ Creates the network cache directory and any necessary parent directories. The `-p` flag prevents errors if the directory already exists and creates intermediate directories as needed.

IPC_FILE="/tmp/qs_widget_state"
# ^ Defines the path to an Inter-Process Communication (IPC) file. This is a temporary file used to send commands and state information between the shell scripts and the QuickShell QML application.

NETWORK_MODE_FILE="$QS_NETWORK_CACHE/mode"
# ^ Defines the path to a file that stores the currently selected network mode (e.g., "wifi", "ethernet", "bluetooth") within the network cache directory.

ACTION="$1"
# ^ Captures the first command-line argument passed to the script and assigns it to the ACTION variable. This determines what operation to perform (e.g., "open", "close", "toggle", or a workspace number).

TARGET="$2"
# ^ Captures the second command-line argument and assigns it to the TARGET variable. This specifies which widget or component the action should apply to (e.g., "network", "wallpaper", "calendar").

SUBTARGET="$3"
# ^ Captures the third command-line argument and assigns it to the SUBTARGET variable. This provides additional context for the action (e.g., the specific network mode like "wifi" when opening the network panel).

# -----------------------------------------------------------------------------
# FAST PATH: WORKSPACE SWITCHING
# -----------------------------------------------------------------------------
if [[ "$ACTION" =~ ^[0-9]+$ ]]; then
    # ^ Checks if the ACTION variable consists entirely of one or more digits (a workspace number). The `=~` operator performs a regular expression match where `^[0-9]+$` matches strings containing only numbers.

    WORKSPACE_NUM="$ACTION"
    # ^ Assigns the numeric ACTION to a more descriptive variable name WORKSPACE_NUM, representing the target workspace number to switch to.

    echo "close" > "$IPC_FILE"
    # ^ Writes the string "close" to the IPC file, overwriting any previous content. This signals the QuickShell interface to close any open popups or overlays before switching workspaces.

    CMD="workspace $WORKSPACE_NUM"
    # ^ Constructs a Hyprland dispatch command to switch to the specified workspace number, storing it in the CMD variable.

    [[ "$2" == "move" ]] && CMD="movetoworkspace $WORKSPACE_NUM"
    # ^ If the second argument ($2) equals "move", overrides the CMD variable to use the `movetoworkspace` dispatcher instead, which moves the currently active window to the specified workspace along with switching to it.

    hyprctl --batch "dispatch $CMD" >/dev/null 2>&1
    # ^ Executes the Hyprland command using `hyprctl` in batch mode, which allows running a single dispatch command. The `dispatch` keyword tells Hyprland to execute the workspace/movetoworkspace command. Both standard output and standard error are redirected to /dev/null to suppress any output.

    exit 0
    # ^ Terminates the script immediately with a success exit code (0) since the workspace switch has been handled and no further processing is needed.
fi

MANIFEST="$THUMB_DIR/.manifest"
# ^ Defines the path to a manifest file that lists all cached thumbnail filenames. This hidden file helps track which wallpapers have already been processed into thumbnails.

build_manifest() {
    # ^ Defines a function called `build_manifest` that generates or regenerates the manifest file by listing all thumbnail files currently in the thumbnails directory.

    find "$THUMB_DIR" -maxdepth 1 -type f ! -name '.source_dir' ! -name '.manifest' \
        -printf "%f\n" | sort > "$MANIFEST"
    # ^ Uses the `find` command to list all regular files (`-type f`) in the THUMB_DIR without descending into subdirectories (`-maxdepth 1`). It excludes the hidden metadata files `.source_dir` and `.manifest` using the `! -name` negation pattern. The `-printf "%f\n"` prints only the filename (without path) followed by a newline. The output is piped through `sort` for alphabetical ordering and redirected to the MANIFEST file, overwriting its previous contents.
}

handle_wallpaper_prep() {
    # ^ Defines a function called `handle_wallpaper_prep` that prepares wallpaper thumbnails. It processes source images, creates thumbnails for new files, removes thumbnails for deleted files, and detects the currently active wallpaper.

    mkdir -p "$THUMB_DIR"
    # ^ Creates the thumbnail directory and any necessary parent directories, ensuring the directory structure exists before attempting to write files.

    (
        # ^ Opens a subshell (enclosed in parentheses). This groups all the following commands to run in a background process while keeping variable exports contained. The background execution is triggered by the `&` at the end of the subshell.

        export THUMB_DIR SRC_DIR MANIFEST
        # ^ Exports the THUMB_DIR, SRC_DIR, and MANIFEST variables so they are available to child processes and subshells spawned within this subshell (like the xargs-invoked bash processes).

        process_one() {
            # ^ Defines a nested function called `process_one` inside the subshell. This function handles the thumbnail generation for a single image or video file passed as the first argument.

            img="$1"
            # ^ Assigns the first argument (the full path to the source file) to the local variable `img`.

            filename=$(basename "$img")
            # ^ Extracts just the filename (with extension) from the full path using the `basename` command and stores it in the `filename` variable.

            extension="${filename##*.}"
            # ^ Extracts the file extension by removing everything up to and including the last dot in the filename. The `##` operator performs greedy suffix removal, stripping the longest match of the pattern `*.` from the beginning.

            if [[ "${extension,,}" == "webp" ]]; then
                # ^ Checks if the file extension, converted to lowercase using the `,,` parameter expansion operator, equals "webp". WebP images need conversion to JPG for compatibility.

                new_img="${img%.*}.jpg"
                # ^ Constructs a new filename by removing the original extension (using `%.*` which removes the shortest match of `.*` from the end) and appending ".jpg".

                magick "$img" "$new_img" && rm -f "$img"
                # ^ Uses ImageMagick's `magick` command to convert the WebP image to JPG format. The `&&` ensures the original file is only removed (`rm -f`) if the conversion succeeds, preventing data loss.

                img="$new_img"; filename=$(basename "$img"); extension="jpg"
                # ^ Updates the `img` variable to point to the new JPG file, re-extracts the `filename` from the new path, and sets `extension` to "jpg". The semicolons separate multiple commands on one line.
            fi

            if [[ "${extension,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
                # ^ Checks if the lowercase file extension matches any of the common video formats (mp4, mkv, mov, webm) using a regular expression match.

                thumb="$THUMB_DIR/000_$filename"
                # ^ Constructs the thumbnail path for video files by prefixing the filename with "000_" in the THUMB_DIR. This naming convention distinguishes video thumbnails from image thumbnails.

                [ -f "$THUMB_DIR/$filename" ] && rm -f "$THUMB_DIR/$filename"
                # ^ If a thumbnail exists with just the original filename (without the "000_" prefix), it is removed. This handles cleanup when a file changes from image to video type.

                if [ ! -f "$thumb" ]; then
                    # ^ Checks if the video thumbnail does not already exist, avoiding redundant processing of already cached thumbnails.

                    ffmpeg -y -ss 00:00:05 -i "$img" -vframes 1 \
                        -f image2 -q:v 2 "$thumb" >/dev/null 2>&1
                    # ^ Uses `ffmpeg` to extract a single frame from the video at the 5-second mark (`-ss 00:00:05`). The `-y` flag overwrites existing output files. `-vframes 1` captures only one frame. `-f image2` forces image output format. `-q:v 2` sets the JPEG quality (2 is high quality, range 2-31). Output is suppressed by redirecting to /dev/null.

                    echo "000_$filename" >> "$MANIFEST"
                    # ^ Appends the thumbnail filename (with "000_" prefix) to the manifest file, recording that this thumbnail has been successfully created.
                fi
            else
                # ^ If the file is not a video (i.e., it's a regular image), this branch handles image thumbnail creation.

                thumb="$THUMB_DIR/$filename"
                # ^ Constructs the thumbnail path for image files using just the original filename (no "000_" prefix) in the THUMB_DIR.

                if [ ! -f "$thumb" ]; then
                    # ^ Checks if the image thumbnail does not already exist to avoid reprocessing.

                    magick "$img" -resize x420 -quality 70 "$thumb"
                    # ^ Uses ImageMagick's `magick` command to resize the image to a height of 420 pixels (width is automatically scaled proportionally with `x420`) and sets JPEG compression quality to 70, saving the result to the thumbnail path.

                    echo "$filename" >> "$MANIFEST"
                    # ^ Appends the original filename to the manifest file, recording that this thumbnail has been successfully created.
                fi
            fi
        }
        # ^ Closes the `process_one` function definition.

        export -f process_one
        # ^ Exports the `process_one` function so it can be called by child processes like those spawned by `xargs`. The `-f` flag specifically exports the function.

        # Source dir change — nuke everything and rebuild
        THUMB_SOURCE_FILE="$THUMB_DIR/.source_dir"
        # ^ Defines the path to a metadata file that stores the source directory path that was used for the current thumbnail cache.

        if [ -f "$THUMB_SOURCE_FILE" ]; then
            # ^ Checks if the source directory metadata file exists (meaning thumbnails have been cached before).

            read -r CACHED_SRC < "$THUMB_SOURCE_FILE"
            # ^ Reads the first line from the source directory file and stores it in the CACHED_SRC variable. The `-r` flag prevents backslash interpretation.

            if [ "$CACHED_SRC" != "$SRC_DIR" ]; then
                # ^ Compares the cached source directory with the current SRC_DIR. If they differ, the user has changed wallpaper directories.

                find "$THUMB_DIR" -maxdepth 1 -type f \
                    ! -name '.source_dir' ! -name '.manifest' -delete
                # ^ Deletes all regular files in the THUMB_DIR (all cached thumbnails) except for the `.source_dir` and `.manifest` metadata files, clearing the stale cache.

                echo "$SRC_DIR" > "$THUMB_SOURCE_FILE"
                # ^ Updates the `.source_dir` file with the new source directory path, overwriting the previous value.

                > "$MANIFEST"  # reset manifest
                # ^ Truncates the manifest file (clears its contents) since all thumbnails have been deleted. The `>` redirect without a command creates an empty file or truncates an existing one.
            fi
        else
            # ^ If the source directory metadata file does not exist (first run or cleared cache).

            echo "$SRC_DIR" > "$THUMB_SOURCE_FILE"
            # ^ Creates the `.source_dir` file and writes the current source directory path to it.

            > "$MANIFEST"
            # ^ Creates or truncates the manifest file to start fresh.
        fi

        # Build manifest if missing
        [ ! -f "$MANIFEST" ] && build_manifest
        # ^ If the manifest file doesn't exist (perhaps it was deleted), calls the `build_manifest` function to regenerate it by scanning existing thumbnails.

        # Get current src files (one find, sorted)
        SRC_LIST=$(mktemp)
        # ^ Creates a temporary file using `mktemp` and stores its path in the SRC_LIST variable. This file will hold a sorted list of source files currently in the wallpaper directory.

        find "$SRC_DIR" -maxdepth 1 -type f \
            \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
               -o -iname "*.gif" -o -iname "*.mp4" -o -iname "*.mkv" \
               -o -iname "*.mov" -o -iname "*.webm" \) \
            -printf "%f\n" | sort > "$SRC_LIST"
        # ^ Uses `find` to list all supported image and video files in the source directory (case-insensitive with `-iname`). The file types include JPEG, PNG, GIF images and MP4, MKV, MOV, WebM videos. Only filenames are printed with `-printf "%f\n"`, sorted alphabetically, and written to the temporary SRC_LIST file.

        # Orphans: in manifest but not in src anymore
        comm -23 \
            <(sed 's/^000_//' "$MANIFEST" | sort) \
            "$SRC_LIST" \
        | while read -r orphan; do
            # ^ Uses `comm -23` to find lines unique to the first input (files in manifest but not in source directory - these are orphaned thumbnails). The first input is the manifest with "000_" prefixes stripped and sorted. The second input is the current source file list. The `<(command)` syntax uses process substitution to treat command output as a file. Results are piped to a while loop that reads each orphan filename.

            rm -f "$THUMB_DIR/$orphan" "$THUMB_DIR/000_$orphan"
            # ^ Removes both the regular thumbnail and any video thumbnail variant ("000_" prefixed) for each orphaned file. The `-f` flag suppresses errors if files don't exist.

            # Remove from manifest
            sed -i "/^${orphan}$/d;/^000_${orphan}$/d" "$MANIFEST"
            # ^ Edits the manifest file in-place (`-i`) to delete lines matching exactly the orphan filename (with `^` and `$` anchors) or the "000_" prefixed version. Semicolon separates two deletion patterns.
        done

        # New files: in src but not in manifest
        comm -23 \
            "$SRC_LIST" \
            <(sed 's/^000_//' "$MANIFEST" | sort) \
        | xargs -P 8 -I{} bash -c 'process_one "$SRC_DIR/$@"' _ {}
        # ^ Uses `comm -23` again but with inputs reversed: finds files in source directory that are not in the manifest (new files). Process substitution strips "000_" prefixes from manifest entries. The resulting list is piped to `xargs` which runs the `process_one` function in parallel (`-P 8` allows up to 8 concurrent processes). `-I{}` uses `{}` as a replacement string. Each file path is substituted for `{}` and the `process_one` function is called with the full path `$SRC_DIR/{}`. The underscore `_` is a placeholder for `$0` in the bash command.

        rm -f "$SRC_LIST"
        # ^ Removes the temporary source list file to clean up.

    ) </dev/null >/dev/null 2>&1 &
    # ^ Closes the subshell, redirects its standard input from /dev/null (preventing any interactive input), redirects both standard output and standard error to /dev/null (suppressing all output), and runs the entire subshell in the background with `&`. This allows the wallpaper preparation to happen asynchronously without blocking the script.

    # swww/mpvpaper detection (unchanged, fast)
    TARGET_THUMB=""
    # ^ Initializes the TARGET_THUMB variable to an empty string. This will eventually hold the filename of the thumbnail corresponding to the currently active wallpaper.

    CURRENT_SRC=""
    # ^ Initializes the CURRENT_SRC variable to an empty string. This will hold the filename of the currently set wallpaper.

    if pgrep -a "mpvpaper" > /dev/null; then
        # ^ Checks if the `mpvpaper` process is running by searching for it with `pgrep`. The `-a` flag shows the full command line, and output is redirected to /dev/null since we only care about the exit status.

        CURRENT_SRC=$(pgrep -a mpvpaper | grep -o "$SRC_DIR/[^' ]*" | head -n1)
        # ^ If mpvpaper is running, extracts the wallpaper path from its command line. `pgrep -a` lists all mpvpaper processes with arguments. `grep -o` extracts only the matching part that looks like a path in the source directory. The pattern `[^' ]*` matches characters that are not spaces or single quotes. `head -n1` takes only the first match.

        CURRENT_SRC=$(basename "$CURRENT_SRC")
        # ^ Extracts just the filename from the full path using `basename`.
    fi

    if [ -z "$CURRENT_SRC" ] && command -v swww >/dev/null; then
        # ^ If CURRENT_SRC is still empty (no mpvpaper wallpaper found) AND the `swww` command is available, attempt to get the wallpaper from swww. `command -v` checks if the program exists, and `-z` tests if the string is empty.

        CURRENT_SRC=$(swww query 2>/dev/null | grep -o "$SRC_DIR/[^ ]*" | head -n1)
        # ^ Runs `swww query` to get the current wallpaper information, suppressing any error output. Extracts the image path that starts with the source directory path using `grep -o`, and takes the first match.

        CURRENT_SRC=$(basename "$CURRENT_SRC")
        # ^ Extracts just the filename from the path.
    fi

    if [ -n "$CURRENT_SRC" ]; then
        # ^ If a current wallpaper source was found (`-n` tests if the string is non-empty).

        EXT="${CURRENT_SRC##*.}"
        # ^ Extracts the file extension from the current wallpaper filename using the greedy suffix removal operator `##*.` which removes everything up to the last dot.

        [[ "${EXT,,}" =~ ^(mp4|mkv|mov|webm)$ ]] \
            && TARGET_THUMB="000_$CURRENT_SRC" \
            || TARGET_THUMB="$CURRENT_SRC"
        # ^ Checks if the lowercase extension matches video formats. If it's a video, sets TARGET_THUMB with the "000_" prefix (matching the video thumbnail naming convention). Otherwise, uses the regular filename. The backslashes continue the conditional across lines.
    fi

    export WALLPAPER_THUMB="$TARGET_THUMB"
    # ^ Exports the TARGET_THUMB value as the WALLPAPER_THUMB environment variable so the QML interface can know which wallpaper is currently active and highlight it accordingly.
}


handle_network_prep() {
    # ^ Defines a function called `handle_network_prep` that prepares network scanning functionality. It starts Bluetooth device scanning and WiFi network scanning in the background.

    echo "" > "$BT_SCAN_LOG"
    # ^ Clears (or creates if not existing) the Bluetooth scan log file by writing an empty string to it. This ensures fresh scan results.

    { echo "scan on"; sleep infinity; } | stdbuf -oL bluetoothctl > "$BT_SCAN_LOG" 2>&1 &
    # ^ Starts a background process that enables Bluetooth scanning. The `{ echo "scan on"; sleep infinity; }` sends the "scan on" command to bluetoothctl and then sleeps indefinitely (keeping the pipe open). `stdbuf -oL` sets line-buffered output for bluetoothctl to ensure real-time logging. The output (both stdout and stderr) is redirected to the BT_SCAN_LOG file. The final `&` runs this pipeline in the background.

    echo $! > "$BT_PID_FILE"
    # ^ Writes the Process ID ($!) of the most recently started background process (the Bluetooth scanning pipeline) to the BT_PID_FILE for later cleanup/termination.

    (nmcli device wifi rescan) >/dev/null 2>&1 &
    # ^ Starts a background WiFi network scan using NetworkManager's `nmcli` command. The `device wifi rescan` requests a fresh scan of available WiFi networks. Output is suppressed, and the process runs in the background.
}

# -----------------------------------------------------------------------------
# ZOMBIE WATCHDOG
# -----------------------------------------------------------------------------
MAIN_QML_PATH="$HOME/.config/hypr/scripts/quickshell/Main.qml"
# ^ Defines the full path to the main QuickShell QML file that controls popup widgets and overlays.

BAR_QML_PATH="$HOME/.config/hypr/scripts/quickshell/TopBar.qml"
# ^ Defines the full path to the top bar QuickShell QML file that renders the status bar/panel.

if ! pgrep -f "quickshell.*Main\.qml" >/dev/null; then
    # ^ Checks if there is NO running process matching the pattern "quickshell" followed by "Main.qml". The `-f` flag searches the full command line, and the `!` negates the result. Output is suppressed. The `\.` escapes the dot in the regex.

    quickshell -p "$MAIN_QML_PATH" >/dev/null 2>&1 &
    # ^ If the Main.qml quickshell process is not running, launches it in the background. The `-p` flag likely specifies the QML file to load. Output is redirected to /dev/null and the process runs asynchronously with `&`.

    disown
    # ^ Removes the background process from the shell's job table, preventing it from being terminated if the shell exits. This ensures the quickshell process persists independently.
fi

if ! pgrep -f "quickshell.*TopBar\.qml" >/dev/null; then
    # ^ Checks if the TopBar quickshell process is not running using the same pattern matching approach.

    quickshell -p "$BAR_QML_PATH" >/dev/null 2>&1 &
    # ^ Launches the TopBar quickshell process in the background if it's not already running.

    disown
    # ^ Disowns the TopBar process so it will not be killed when this script terminates.
fi

# -----------------------------------------------------------------------------
# IPC ROUTING
# -----------------------------------------------------------------------------
if [[ "$ACTION" == "close" ]]; then
    # ^ Checks if the ACTION argument is "close", indicating that a widget should be closed/hidden.

    echo "close" > "$IPC_FILE"
    # ^ Writes the "close" command to the IPC file, signaling the QML interface to close any open popup or overlay.

    if [[ "$TARGET" == "network" || "$TARGET" == "all" || -z "$TARGET" ]]; then
        # ^ Checks if the TARGET is specifically "network", "all", or empty (no target specified). These conditions indicate that network-related background processes should be cleaned up.

        if [ -f "$BT_PID_FILE" ]; then
            # ^ Verifies that the Bluetooth PID file exists, meaning a Bluetooth scan process was started.

            kill $(cat "$BT_PID_FILE") 2>/dev/null
            # ^ Reads the stored PID from the file and sends a termination signal to that process. Errors (e.g., process already dead) are suppressed.

            rm -f "$BT_PID_FILE"
            # ^ Removes the PID file to clean up, using `-f` to avoid errors if the file was already deleted.
        fi

        (bluetoothctl scan off > /dev/null 2>&1) &
        # ^ Sends a command to disable Bluetooth scanning in the background, suppressing any output. This ensures Bluetooth scanning stops when the network panel is closed.
    fi

    exit 0
    # ^ Exits the script successfully after handling the close action.
fi

if [[ "$ACTION" == "open" || "$ACTION" == "toggle" ]]; then
    # ^ Checks if the ACTION is either "open" (show a widget) or "toggle" (switch between open/closed states).

    CURRENT_MODE=$(cat "$NETWORK_MODE_FILE" 2>/dev/null)
    # ^ Reads the current network mode from the mode file, storing it in CURRENT_MODE. If the file doesn't exist, error is suppressed and CURRENT_MODE will be empty.

    if [[ "$TARGET" == "network" ]]; then
        # ^ If the target widget is the network panel, special preparation is needed.

        handle_network_prep
        # ^ Calls the network preparation function to start Bluetooth and WiFi scanning.

        [[ -n "$SUBTARGET" ]] && echo "$SUBTARGET" > "$NETWORK_MODE_FILE"
        # ^ If a SUBTARGET was provided (e.g., "wifi", "bluetooth", "ethernet"), writes it to the network mode file to set the initial view mode. The `-n` test ensures SUBTARGET is not empty.

        echo "$ACTION:$TARGET:$SUBTARGET" > "$IPC_FILE"
        # ^ Writes a colon-separated message to the IPC file containing the action, target widget ("network"), and subtarget (specific network mode). The QML interface reads this to determine what to display.

        exit 0
        # ^ Exits after handling the network panel open/toggle action.
    fi

    if [[ "$TARGET" == "wallpaper" ]]; then
        # ^ If the target widget is the wallpaper picker.

        handle_wallpaper_prep
        # ^ Calls the wallpaper preparation function to generate thumbnails and detect the current wallpaper.

        echo "$ACTION:$TARGET:$WALLPAPER_THUMB" > "$IPC_FILE"
        # ^ Writes the IPC message with the action, "wallpaper" target, and the current wallpaper thumbnail filename. This tells the QML interface which thumbnail to highlight as active.
    else
        # ^ For any other target widget (calendar, volume, clipboard, etc.).

        echo "$ACTION:$TARGET:$SUBTARGET" > "$IPC_FILE"
        # ^ Writes the generic IPC message with action, target, and subtarget for the QML interface to process.
    fi

    exit 0
    # ^ Exits successfully after handling the open/toggle action for any widget.
fi