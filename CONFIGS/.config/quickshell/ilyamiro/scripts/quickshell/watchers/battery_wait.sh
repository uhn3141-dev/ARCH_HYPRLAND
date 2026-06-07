# #!/usr/bin/env bash
# PIPE="/tmp/qs_battery_wait_$$.fifo"
# mkfifo "$PIPE" 2>/dev/null
# trap 'rm -f "$PIPE"; kill $(jobs -p) 2>/dev/null; exit 0' EXIT INT TERM

# # Catch instant AC plug/unplug events
# LC_ALL=C udevadm monitor --subsystem-match=power_supply 2>/dev/null | grep --line-buffered "change" > "$PIPE" &

# # Failsafe: Force a refresh every 30 seconds because the kernel doesn't 
# # always broadcast a udev event when the battery drops by 1% naturally.
# (sleep 30 && echo "timeout" > "$PIPE") &

# read -r _ < "$PIPE"
# sleep 0.05

#!/usr/bin/env bash                                                              # Shebang line that tells the system to execute this script using the bash interpreter found in the user's PATH environment variable (more portable than hardcoding /bin/bash)
PIPE="/tmp/qs_battery_wait_$$.fifo"                                             # Creates a variable PIPE containing a unique named pipe path using $$ (the current shell's process ID) to avoid conflicts with multiple script instances, prefixing with qs_battery_wait_ to identify it belongs to the QuickShell battery waiter component
mkfifo "$PIPE" 2>/dev/null                                                     # Creates the named pipe (FIFO special file) at the path specified by PIPE; 2>/dev/null suppresses error messages if the pipe already exists from a previous crashed instance of this script
trap 'rm -f "$PIPE"; kill $(jobs -p) 2>/dev/null; exit 0' EXIT INT TERM        # Sets up a trap that executes cleanup when the script exits normally (EXIT), receives an interrupt signal (INT, like Ctrl+C), or receives a termination signal (TERM); the cleanup commands forcefully remove the named pipe, kill all background jobs spawned by this script (suppressing errors if there are none), and exit with status code 0

# Catch instant AC plug/unplug events                                           # Comment explaining that the following command captures immediate events when the power adapter is connected or disconnected
LC_ALL=C udevadm monitor --subsystem-match=power_supply 2>/dev/null | grep --line-buffered "change" > "$PIPE" &  # Sets C locale for consistent output, uses udevadm to monitor kernel uevents only from the power_supply subsystem (batteries, AC adapters, etc.), suppresses errors, pipes events through grep which filters for lines containing "change" (the event type for property changes) using line-buffered mode for immediate output, redirects the filtered stream to the named pipe, and runs this entire monitoring pipeline in the background (&)

# Failsafe: Force a refresh every 30 seconds because the kernel doesn't        # Comment explaining the purpose of the failsafe mechanism: the kernel does not emit udev events for gradual battery percentage changes (like dropping from 75% to 74% during normal discharge)
# always broadcast a udev event when the battery drops by 1% naturally.         # Continuation of the comment: clarifies that battery percentage decay during normal usage happens without triggering udev events, so a periodic refresh is needed
(sleep 30 && echo "timeout" > "$PIPE") &                                        # Runs a subshell in the background that sleeps for 30 seconds and then writes the string "timeout" to the named pipe; this acts as a periodic trigger to wake up the main script even if no udev events occurred, ensuring battery information gets refreshed at least every 30 seconds

read -r _ < "$PIPE"                                                             # Reads one line from the named pipe into the throwaway variable _ (underscore convention), using -r to prevent backslash interpretation; this command blocks the script execution until data is written to the pipe by either the udev monitor (on AC events) or the failsafe timer (every 30 seconds)
sleep 0.05                                                                      # Adds a tiny 50-millisecond delay after reading from the pipe before the script exits; this allows any rapid subsequent reads of battery files by the calling process to see the updated state without racing against kernel filesystem updates