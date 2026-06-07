# #!/usr/bin/env bash

# # ============================================================================
# # 1. ZOMBIE PREVENTION
# # Kills any older instances of this script. When Quickshell reloads, 
# # it can leave the old listener pipelines running in the background infinitely.
# # ============================================================================
# for pid in $(pgrep -f "quickshell/workspaces.sh"); do
#     if [ "$pid" != "$$" ] && [ "$pid" != "$PPID" ]; then
#         kill -9 "$pid" 2>/dev/null
#     fi
# done

# # Cleanly kill immediate children (like socat) when the script exits normally
# cleanup() {
#     pkill -P $$ 2>/dev/null
# }
# trap cleanup EXIT SIGTERM SIGINT

# # --- Special Cleanup for Network/Bluetooth ---
# # The network toggle starts a background bluetooth scan that must be killed explicitly.
# BT_PID_FILE="$HOME/.cache/bt_scan_pid"

# if [ -f "$BT_PID_FILE" ]; then
#     kill $(cat "$BT_PID_FILE") 2>/dev/null
#     rm -f "$BT_PID_FILE"
# fi

# # Ensure bluetooth scan is explicitly turned off (timeout prevents deadlocks on fresh installs)
# (timeout 2 bluetoothctl scan off > /dev/null 2>&1) &
# # ---------------------------------------------

# # Configuration: Parse from settings.json dynamically, fallback to 8
# SETTINGS_FILE="$HOME/.config/hypr/settings.json"
# SEQ_END=$(jq -r '.workspaceCount // 8' "$SETTINGS_FILE" 2>/dev/null)
# # Double check it is a valid integer to prevent jq errors later
# if ! [[ "$SEQ_END" =~ ^[0-9]+$ ]]; then
#     SEQ_END=8
# fi

# print_workspaces() {
#     # Get raw data with a timeout fallback
#     spaces=$(timeout 2 hyprctl workspaces -j 2>/dev/null)
#     active=$(timeout 2 hyprctl activeworkspace -j 2>/dev/null | jq '.id')

#     # Failsafe if hyprctl crashes to prevent jq from outputting errors
#     if [ -z "$spaces" ] || [ -z "$active" ]; then return; fi

#     # Generate the JSON and write it atomically to prevent UI flickering
#     echo "$spaces" | jq --unbuffered --argjson a "$active" --arg end "$SEQ_END" -c '
#         # Create a map of workspace ID -> workspace data for easy lookup
#         (map( { (.id|tostring): . } ) | add) as $s
#         |
#         # Iterate from 1 to SEQ_END
#         [range(1; ($end|tonumber) + 1)] | map(
#             . as $i |
#             # Determine state: active -> occupied -> empty
#             (if $i == $a then "active"
#              elif ($s[$i|tostring] != null and $s[$i|tostring].windows > 0) then "occupied"
#              else "empty" end) as $state |

#             # Get window title for tooltip (if exists)
#             (if $s[$i|tostring] != null then $s[$i|tostring].lastwindowtitle else "Empty" end) as $win |

#             {
#                 id: $i,
#                 state: $state,
#                 tooltip: $win
#             }
#         )
#     ' > /tmp/qs_workspaces.tmp
    
#     mv /tmp/qs_workspaces.tmp /tmp/qs_workspaces.json
# }

# # Print initial state
# print_workspaces

# # ============================================================================
# # 2. THE EVENT DEBOUNCER
# # Listen to Hyprland socket wrapped in an infinite loop
# # ============================================================================
# while true; do
#     socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
#         case "$line" in
#             workspace*|focusedmon*|activewindow*|createwindow*|closewindow*|movewindow*|destroyworkspace*)
                
#                 # -> THE FIX <-
#                 # Hyprland emits HUNDREDS of events a second when you move/resize windows.
#                 # This reads and discards all subsequent events arriving within a 50ms window.
#                 # It bundles the storm into a single UI update, completely preventing CPU clogging!
#                 while read -t 0.05 -r extra_line; do
#                     continue
#                 done

#                 print_workspaces
#                 ;;
#         esac
#     done
#     sleep 1
# done




#!/usr/bin/env bash
# ^ Specifies that this script should be run using the `bash` interpreter found in the user's PATH environment variable via `env`. This portable shebang ensures the script works across different systems.

# ============================================================================
# 1. ZOMBIE PREVENTION
# Kills any older instances of this script. When Quickshell reloads, 
# it can leave the old listener pipelines running in the background infinitely.
# ============================================================================
for pid in $(pgrep -f "quickshell/workspaces.sh"); do
    # ^ Uses pgrep with the `-f` flag to search the full command line of all running processes for "quickshell/workspaces.sh". This returns the Process IDs of all instances of this script that are currently running. The $(...) command substitution captures the list of PIDs.

    if [ "$pid" != "$$" ] && [ "$pid" != "$PPID" ]; then
        # ^ Checks two conditions: (1) the found PID is NOT the current script's own PID (`$$` expands to the current shell's process ID), AND (2) the found PID is NOT the parent process ID (`$PPID` is the PID of the process that launched this script). This ensures we only kill OTHER instances, not ourselves or our immediate parent.

        kill -9 "$pid" 2>/dev/null
        # ^ Sends the SIGKILL signal (-9) to forcefully terminate the old script instance. SIGKILL cannot be caught or ignored by the target process, ensuring it dies immediately. Errors (e.g., process already gone) are suppressed with `2>/dev/null`.
    fi
    # ^ Closes the if statement.
done
# ^ Closes the for loop.

# Cleanly kill immediate children (like socat) when the script exits normally
cleanup() {
    # ^ Defines a cleanup function that will be called when the script exits, is terminated, or is interrupted.

    pkill -P $$ 2>/dev/null
    # ^ Uses pkill with the `-P` flag to kill all child processes whose parent PID matches the current script's PID (`$$`). This ensures any spawned subprocesses (like the socat listener) are cleaned up. Errors are suppressed in case children have already exited.
}

trap cleanup EXIT SIGTERM SIGINT
# ^ Sets up signal traps using the `trap` builtin. The cleanup function will be automatically called when the script: (1) exits normally (EXIT), (2) receives a SIGTERM signal (termination request), or (3) receives a SIGINT signal (Ctrl+C interrupt). This guarantees cleanup even on unexpected termination.

# --- Special Cleanup for Network/Bluetooth ---
# The network toggle starts a background bluetooth scan that must be killed explicitly.
BT_PID_FILE="$HOME/.cache/bt_scan_pid"
# ^ Defines the path to the file that stores the Process ID of any running Bluetooth scan process (managed by the network widget scripts).

if [ -f "$BT_PID_FILE" ]; then
    # ^ Checks if the Bluetooth PID file exists, indicating a scan process was started.

    kill $(cat "$BT_PID_FILE") 2>/dev/null
    # ^ Reads the stored PID from the file using `cat` and sends a termination signal to that process. Errors are suppressed if the process no longer exists.

    rm -f "$BT_PID_FILE"
    # ^ Removes the PID file to clean up, using `-f` to avoid errors if the file was already deleted.
fi
# ^ Closes the if statement.

# Ensure bluetooth scan is explicitly turned off (timeout prevents deadlocks on fresh installs)
(timeout 2 bluetoothctl scan off > /dev/null 2>&1) &
# ^ Runs `bluetoothctl scan off` in a background subshell with a 2-second timeout. The `timeout` command ensures this doesn't hang indefinitely if bluetoothctl is unresponsive (common on systems without Bluetooth or fresh installs). All output is redirected to /dev/null. The final `&` runs it in the background so it doesn't block the script. This is a safety net to ensure Bluetooth scanning is disabled.

# ---------------------------------------------

# Configuration: Parse from settings.json dynamically, fallback to 8
SETTINGS_FILE="$HOME/.config/hypr/settings.json"
# ^ Defines the path to the main settings JSON file where the workspace count configuration is stored.

SEQ_END=$(jq -r '.workspaceCount // 8' "$SETTINGS_FILE" 2>/dev/null)
# ^ Uses `jq` to extract the workspaceCount value from settings.json. The `-r` flag outputs raw text without JSON quotes. The `// 8` operator returns 8 as a fallback if the field doesn't exist or is null. Errors (e.g., file not found, invalid JSON) are suppressed with `2>/dev/null`.

# Double check it is a valid integer to prevent jq errors later
if ! [[ "$SEQ_END" =~ ^[0-9]+$ ]]; then
    # ^ Validates that SEQ_END consists only of digits (a positive integer). The `=~` operator performs a regular expression match against the pattern `^[0-9]+$` which matches strings containing only one or more digits. The `!` negates the result.

    SEQ_END=8
    # ^ If the validation fails (not a valid integer), falls back to the default of 8 workspaces. This prevents errors in downstream jq commands that expect a numeric value.
fi
# ^ Closes the if statement.

print_workspaces() {
    # ^ Defines a function that queries Hyprland for workspace information and writes a JSON array to a temporary file. This function is called initially and whenever workspace-related events occur.

    # Get raw data with a timeout fallback
    spaces=$(timeout 2 hyprctl workspaces -j 2>/dev/null)
    # ^ Queries Hyprland for all workspaces using `hyprctl workspaces -j` to get JSON output. The `timeout 2` prevents hanging for more than 2 seconds if hyprctl is unresponsive. Stderr is suppressed. The result is stored in the `spaces` variable.

    active=$(timeout 2 hyprctl activeworkspace -j 2>/dev/null | jq '.id')
    # ^ Queries the currently active workspace ID with a 2-second timeout. The JSON output is piped to `jq '.id'` to extract just the workspace ID number. Stored in the `active` variable.

    # Failsafe if hyprctl crashes to prevent jq from outputting errors
    if [ -z "$spaces" ] || [ -z "$active" ]; then return; fi
    # ^ Checks if either variable is empty (`-z` test). If hyprctl failed or timed out, returns from the function early without producing output. This prevents jq from receiving empty input and generating error messages.

    # Generate the JSON and write it atomically to prevent UI flickering
    echo "$spaces" | jq --unbuffered --argjson a "$active" --arg end "$SEQ_END" -c '
        # ^ Pipes the raw workspaces JSON to jq for processing. The flags: `--unbuffered` ensures immediate output (important for pipes), `--argjson a "$active"` passes the active workspace ID as a JSON number variable named `$a`, `--arg end "$SEQ_END"` passes the workspace count as a string variable named `$end`, `-c` outputs compact (single-line) JSON. The single-quoted string is the jq filter program.

        # Create a map of workspace ID -> workspace data for easy lookup
        (map( { (.id|tostring): . } ) | add) as $s
        # ^ Transforms the array of workspace objects into a lookup dictionary. `map( { (.id|tostring): . } )` creates an array of single-key objects where the key is the stringified workspace ID and the value is the full workspace object. The `| add` merges all these objects into one combined object. For example, workspaces with IDs 1 and 3 become `{"1": {...}, "3": {...}}`. This is stored in the `$s` variable.

        # Iterate from 1 to SEQ_END
        [range(1; ($end|tonumber) + 1)] | map(
            # ^ Creates an array of numbers from 1 to SEQ_END inclusive. `range(1; n+1)` generates numbers 1 through n, and wrapping in `[]` converts them to an array. The array is piped to `map()` which processes each workspace index.

            . as $i |
            # ^ Stores the current workspace index in the `$i` variable for use in subsequent expressions.

            # Determine state: active -> occupied -> empty
            (if $i == $a then "active"
             elif ($s[$i|tostring] != null and $s[$i|tostring].windows > 0) then "occupied"
             else "empty" end) as $state |
            # ^ Determines the state of this workspace: if the index matches the active workspace ID (`$i == $a`), state is "active". Otherwise, if the workspace exists in the lookup map AND has windows (`.windows > 0`), state is "occupied". Otherwise, state is "empty". The result is stored in `$state`.

            # Get window title for tooltip (if exists)
            (if $s[$i|tostring] != null then $s[$i|tostring].lastwindowtitle else "Empty" end) as $win |
            # ^ Retrieves the title of the last focused window on this workspace for tooltip display. If the workspace exists in the lookup map, uses its `lastwindowtitle` field. Otherwise, defaults to "Empty". Stored in `$win`.

            {
                id: $i,
                state: $state,
                tooltip: $win
            }
            # ^ Constructs the output object for this workspace: the numeric ID, the determined state string, and the tooltip window title.
        )
    ' > /tmp/qs_workspaces.tmp
    # ^ Redirects the jq output (the complete workspace array) to a temporary file. Using a temp file and then renaming ensures atomic writes—the reader won't see a partially written file.

    mv /tmp/qs_workspaces.tmp /tmp/qs_workspaces.json
    # ^ Atomically moves (renames) the temporary file to the final JSON file path. Because `mv` on the same filesystem is an atomic operation, the reader process will never see an incomplete file, preventing UI flickering or JSON parse errors.
}

# Print initial state
print_workspaces
# ^ Calls the function immediately to generate the initial workspace state file, so the TopBar has data to display right away without waiting for an event.

# ============================================================================
# 2. THE EVENT DEBOUNCER
# Listen to Hyprland socket wrapped in an infinite loop
# ============================================================================
while true; do
    # ^ Starts an infinite outer loop that ensures the event listener is restarted if it ever exits (e.g., if Hyprland restarts or the socket connection drops).

    socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
        # ^ Uses `socat` to connect to Hyprland's event socket (socket2). The socket path is constructed from environment variables: `$XDG_RUNTIME_DIR` (typically /run/user/1000), `$HYPRLAND_INSTANCE_SIGNATURE` (unique per Hyprland instance), and the socket filename `.socket2.sock`. The `-u` flag means unidirectional (only read from socket). The `-` argument connects stdout to the pipe. The output is piped to a `while read -r line` loop that reads each event line. The `-r` flag prevents backslash interpretation.

        case "$line" in
            # ^ Opens a case statement to match the event line against relevant Hyprland event types.

            workspace*|focusedmon*|activewindow*|createwindow*|closewindow*|movewindow*|destroyworkspace*)
                # ^ Matches any event line starting with these prefixes. These are all the Hyprland events that could change workspace state: workspace changes, monitor focus changes, active window changes, window creation/closing/moving, and workspace destruction. All other events (like mouse movements, layer changes, etc.) are ignored.
                
                # -> THE FIX <-
                # Hyprland emits HUNDREDS of events a second when you move/resize windows.
                # This reads and discards all subsequent events arriving within a 50ms window.
                # It bundles the storm into a single UI update, completely preventing CPU clogging!
                while read -t 0.05 -r extra_line; do
                    # ^ This inner while loop reads and DISCARDS any additional events that arrive within 50 milliseconds. The `read -t 0.05` sets a timeout of 0.05 seconds (50ms)—it will read a line if available within that time, and exit if the timeout is reached with no input. The `extra_line` variable is read but never used (events are consumed and ignored).
                    continue
                    # ^ Explicitly continues to the next iteration of the inner while loop (though `continue` here is technically redundant since the loop body ends after this line anyway).
                done
                # ^ When the inner while loop exits (no more events within 50ms), the script proceeds.

                print_workspaces
                # ^ Now calls the workspace printing function. Because the 50ms debounce window has absorbed the burst of rapid events, this only executes once per event storm instead of hundreds of times, dramatically reducing CPU usage and JSON file writes.
                ;;
                # ^ Ends this case branch.
        esac
        # ^ Closes the case statement.
    done
    # ^ Closes the inner while loop (the socat event reader).

    sleep 1
    # ^ If the inner loop exits (e.g., socat connection drops, Hyprland restarts), waits 1 second before the outer while loop restarts the socat connection, preventing rapid reconnection attempts that could flood the system.
done
# ^ Closes the outer while true loop. The script runs indefinitely, monitoring Hyprland events and updating the workspace state file until it's killed externally.