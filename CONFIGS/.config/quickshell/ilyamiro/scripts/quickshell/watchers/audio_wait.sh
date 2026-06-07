# #!/usr/bin/env bash
# PIPE="/tmp/qs_audio_wait_$$.fifo"
# mkfifo "$PIPE" 2>/dev/null
# trap 'rm -f "$PIPE"; kill $(jobs -p) 2>/dev/null; exit 0' EXIT INT TERM
# LC_ALL=C pactl subscribe 2>/dev/null | grep --line-buffered -E "sink|server" > "$PIPE" &
# read -r _ < "$PIPE"




#!/usr/bin/env bash                                                              # Shebang line that tells the system to execute this script using the bash interpreter found in the user's PATH environment variable (more portable than hardcoding /bin/bash)
PIPE="/tmp/qs_audio_wait_$$.fifo"                                               # Creates a variable PIPE containing a unique named pipe path using $$ (the current shell's process ID) to avoid conflicts with multiple script instances, prefixing with qs_audio_wait_ to identify it belongs to the QuickShell audio waiter component
mkfifo "$PIPE" 2>/dev/null                                                     # Creates the named pipe (FIFO special file) at the path specified by PIPE; 2>/dev/null suppresses error messages if the pipe already exists from a previous crashed instance
trap 'rm -f "$PIPE"; kill $(jobs -p) 2>/dev/null; exit 0' EXIT INT TERM        # Sets up a trap that executes when the script exits normally (EXIT), receives an interrupt signal (INT like Ctrl+C), or receives a termination signal (TERM); the commands remove the named pipe forcefully, kill all background jobs spawned by this script while suppressing errors, and exit with code 0
LC_ALL=C pactl subscribe 2>/dev/null | grep --line-buffered -E "sink|server" > "$PIPE" &  # Sets C locale for consistent parsing, subscribes to PulseAudio/PipeWire events using pactl, suppresses any errors, pipes the event stream through grep which uses line-buffered mode (prints matches immediately without waiting for buffer to fill) and filters for events containing "sink" or "server" (audio device changes), redirects this filtered output to the named pipe, and runs the entire pipeline in the background (&)
read -r _ < "$PIPE"                                                             # Reads one line from the named pipe into the dummy variable _ (underscore is convention for throwaway variable), -r prevents backslash interpretation; this command blocks until data is written to the pipe by the background pipeline, effectively waiting for the next audio-related event before the script proceeds or exits