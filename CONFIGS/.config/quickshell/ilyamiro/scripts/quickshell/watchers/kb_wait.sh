# #!/usr/bin/env bash
# PIPE="/tmp/qs_kb_wait_$$.fifo"
# mkfifo "$PIPE" 2>/dev/null
# trap 'rm -f "$PIPE"; kill $(jobs -p) 2>/dev/null; exit 0' EXIT INT TERM

# if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
#     LC_ALL=C socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock 2>/dev/null | grep --line-buffered "activelayout>>" > "$PIPE" &
# else
#     sleep 10 > "$PIPE" &
# fi

# read -r _ < "$PIPE"
# sleep 0.05


#!/usr/bin/env bash                                                              # Shebang line that tells the system to execute this script using the bash interpreter found in the user's PATH environment variable (more portable than hardcoding /bin/bash)
PIPE="/tmp/qs_kb_wait_$$.fifo"                                                  # Creates a variable PIPE containing a unique named pipe path using $$ (the current shell's process ID) to avoid conflicts with multiple script instances, prefixing with qs_kb_wait_ to identify it belongs to the QuickShell keyboard layout waiter component
mkfifo "$PIPE" 2>/dev/null                                                     # Creates the named pipe (FIFO special file) at the path specified by PIPE; 2>/dev/null suppresses error messages if the pipe already exists from a previous crashed instance of this script
trap 'rm -f "$PIPE"; kill $(jobs -p) 2>/dev/null; exit 0' EXIT INT TERM        # Sets up a trap that executes cleanup when the script exits normally (EXIT), receives an interrupt signal (INT, like Ctrl+C), or receives a termination signal (TERM); the cleanup commands forcefully remove the named pipe, kill all background jobs spawned by this script (suppressing errors if there are none), and exit with status code 0

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then                                 # Checks if the HYPRLAND_INSTANCE_SIGNATURE environment variable is not empty (-n test); this variable is set by Hyprland when running inside a Hyprland session and uniquely identifies the compositor instance
    LC_ALL=C socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock 2>/dev/null | grep --line-buffered "activelayout>>" > "$PIPE" &  # Sets C locale, uses socat in unidirectional mode (-U reads from the socket and outputs to stdout, does not send any input) to connect to Hyprland's socket2 (event socket) located in the XDG runtime directory under the Hyprland instance signature subdirectory, suppresses socat errors, pipes the Hyprland event stream through grep which filters for lines containing "activelayout>>" (the event emitted when keyboard layout changes) using line-buffered mode for immediate delivery, redirects matches to the named pipe, and runs everything in the background (&)
else                                                                             # If HYPRLAND_INSTANCE_SIGNATURE is not set (we are not running inside a Hyprland session)
    sleep 10 > "$PIPE" &                                                        # Fallback: runs a background subshell that sleeps for 10 seconds and then writes nothing to the named pipe (redirecting stdout from sleep, which produces no output, effectively just signaling the pipe to wake up the reader after 10 seconds); this provides a periodic refresh interval when Hyprland's socket is unavailable
fi                                                                               # Closes the if-else block

read -r _ < "$PIPE"                                                             # Reads one line from the named pipe into the throwaway variable _ (underscore convention), using -r to prevent backslash interpretation; this command blocks the script execution until data is written to the pipe by either the Hyprland socket monitor (on keyboard layout change) or the fallback sleep timer (every 10 seconds)
sleep 0.05                                                                      # Adds a tiny 50-millisecond delay after reading from the pipe before the script exits; this allows any rapid subsequent reads of the keyboard layout by the calling process to see the updated state without racing against Hyprland's internal event processing