# #!/usr/bin/env bash
# PIPE="/tmp/qs_network_wait_$$.fifo"
# mkfifo "$PIPE" 2>/dev/null
# trap 'rm -f "$PIPE"; kill $(jobs -p) 2>/dev/null; exit 0' EXIT INT TERM

# LC_ALL=C nmcli monitor 2>/dev/null | grep --line-buffered -iwE "connected|disconnected|enabled|disabled|activated|deactivated|available|unavailable" > "$PIPE" &
# read -r _ < "$PIPE"



#!/usr/bin/env bash                                                              # Shebang line that tells the system to execute this script using the bash interpreter found in the user's PATH environment variable (more portable than hardcoding /bin/bash)
PIPE="/tmp/qs_network_wait_$$.fifo"                                             # Creates a variable PIPE containing a unique named pipe path using $$ (the current shell's process ID) to avoid conflicts with multiple script instances, prefixing with qs_network_wait_ to identify it belongs to the QuickShell network waiter component
mkfifo "$PIPE" 2>/dev/null                                                     # Creates the named pipe (FIFO special file) at the path specified by PIPE; 2>/dev/null suppresses error messages if the pipe already exists from a previous crashed instance of this script
trap 'rm -f "$PIPE"; kill $(jobs -p) 2>/dev/null; exit 0' EXIT INT TERM        # Sets up a trap that executes cleanup when the script exits normally (EXIT), receives an interrupt signal (INT, like Ctrl+C), or receives a termination signal (TERM); the cleanup commands forcefully remove the named pipe, kill all background jobs spawned by this script (suppressing errors if there are none), and exit with status code 0

LC_ALL=C nmcli monitor 2>/dev/null | grep --line-buffered -iwE "connected|disconnected|enabled|disabled|activated|deactivated|available|unavailable" > "$PIPE" &  # Sets C locale for consistent output, runs nmcli in monitor mode which watches for and prints NetworkManager state changes in real-time, suppresses any error output, pipes the stream through grep which uses: --line-buffered for immediate output (doesn't wait for buffer to fill), -i for case-insensitive matching, -w for whole-word matching (won't match substrings like "disable" inside "disabled"), -E for extended regex, and the alternation pattern matches any of the key network state words (connection events, radio state events, device availability events); all matched lines are redirected to the named pipe, and the entire pipeline runs in the background (&)
read -r _ < "$PIPE"                                                             # Reads one line from the named pipe into the throwaway variable _ (underscore convention), using -r to prevent backslash interpretation; this command blocks the script execution until data is written to the pipe by the nmcli monitor background process (meaning a network state change occurred), at which point the script unblocks and exits, signaling the caller to refresh network information