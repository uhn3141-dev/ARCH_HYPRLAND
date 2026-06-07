# #!/usr/bin/env bash

# # File to store the latest seek request
# SEEK_FILE="/tmp/quickshell_music_seek_data"

# # Arg mapping
# command=$1
# arg=$2
# len_sec=$3
# player_name=$4

# # Fallback for player name
# if [ -z "$player_name" ]; then
#     player_name=$(playerctl status -f "{{playerName}}" 2>/dev/null | head -n 1)
# fi
# if [ -z "$player_name" ]; then exit 0; fi

# case $command in
#     "seek")
#         # 1. WRITE: Save the latest target data to a file immediately.
#         #    This overwrites any previous pending request.
#         echo "$arg $len_sec $player_name" > "$SEEK_FILE"

#         # 2. CHECK: Is a worker already running?
#         #    We check for a specific marker we create below.
#         lock_file="/tmp/quickshell_music_seek_lock"
        
#         # If the lock file exists, a worker is already waiting to execute.
#         # We just exit and let that worker pick up our new value from step 1.
#         if [ -f "$lock_file" ]; then
#             exit 0
#         fi

#         # 3. WORKER: Create the lock and run in background
#         touch "$lock_file"
        
#         (
#             # Wait a tiny bit to gather rapid updates (Debounce)
#             sleep 0.05
            
#             # Read the LATEST value from the file (Step 1)
#             read -r final_arg final_len final_player < "$SEEK_FILE"
            
#             # Perform the Seek Logic
#             if [ -n "$final_len" ] && [ "$final_len" != "0" ]; then
#                 # Use AWK for math
#                 target_sec=$(awk -v len="$final_len" -v perc="$final_arg" 'BEGIN { printf "%.2f", (len * perc) / 100 }')
#                 # Execute
#                 playerctl -p "$final_player" position "$target_sec"
#             fi
            
#             # Remove lock so a new batch can start
#             rm "$lock_file"
#         ) & 
        
#         # Exit main script immediately to free up the UI
#         exit 0
#         ;;
    
#     "next")
#         playerctl -p "$player_name" next ;;
        
#     "prev")
#         playerctl -p "$player_name" previous ;;
        
#     "play-pause")
#         playerctl -p "$player_name" play-pause ;;
        
# esac

#!/usr/bin/env bash                                                                               # Shebang - specifies this script should be executed using the bash shell from the user's PATH environment

# File to store the latest seek request                                                            # Comment describing the purpose of SEEK_FILE
SEEK_FILE="/tmp/quickshell_music_seek_data"                                                       # Define SEEK_FILE variable - temporary file that stores the most recent seek request parameters (percentage, length, player name)

# Arg mapping                                                                                      # Comment - documents the argument positions from the calling program
command=$1                                                                                        # Capture first argument as the command to execute (seek, next, prev, or play-pause)
arg=$2                                                                                            # Capture second argument - for seek command this is the target percentage (0-100), unused for other commands
len_sec=$3                                                                                        # Capture third argument - for seek command this is the track length in seconds, unused for other commands
player_name=$4                                                                                    # Capture fourth argument - the player name to control (e.g., "firefox", "spotify"), may be empty

# Fallback for player name                                                                         # Comment - auto-detect player if not explicitly provided
if [ -z "$player_name" ]; then                                                                    # Check if player_name is empty or not provided
    player_name=$(playerctl status -f "{{playerName}}" 2>/dev/null | head -n 1)                  # Auto-detect active player: get status with template outputting player name, suppress errors, take only first player if multiple
fi                                                                                                # End of fallback check
if [ -z "$player_name" ]; then exit 0; fi                                                         # If still no player found after fallback, exit silently with success code (nothing to control)

case $command in                                                                                  # Begin case statement - evaluate the command and execute matching block
    "seek")                                                                                       # If command is "seek": handle position seeking with debouncing
        # 1. WRITE: Save the latest target data to a file immediately.                           # Comment - Step 1: Store the seek parameters
        #    This overwrites any previous pending request.                                       # Comment explaining that writing overwrites - only the latest request matters
        echo "$arg $len_sec $player_name" > "$SEEK_FILE"                                          # Write the seek parameters (percentage, length in seconds, player name) to the seek data file, overwriting any previous pending request

        # 2. CHECK: Is a worker already running?                                                  # Comment - Step 2: Check if a background worker is already processing
        #    We check for a specific marker we create below.                                      # Comment explaining the lock file mechanism
        lock_file="/tmp/quickshell_music_seek_lock"                                                # Define lock_file variable - marker file whose existence indicates a worker is running
        
        # If the lock file exists, a worker is already waiting to execute.                        # Comment explaining the logic
        # We just exit and let that worker pick up our new value from step 1.                     # Comment explaining that existing worker will read the updated SEEK_FILE
        if [ -f "$lock_file" ]; then                                                               # Check if the lock file exists (a worker is currently debouncing)
            exit 0                                                                                  # Exit immediately - the running worker will pick up our newly written seek parameters
        fi                                                                                         # End of lock file check

        # 3. WORKER: Create the lock and run in background                                        # Comment - Step 3: Start a new worker process
        touch "$lock_file"                                                                         # Create the lock file to signal that a worker is now running (prevents other rapid seeks from creating workers)
        
        (                                                                                          # Begin subshell (parentheses) - everything inside runs asynchronously in background
            # Wait a tiny bit to gather rapid updates (Debounce)                                  # Comment explaining the sleep - collects multiple rapid seek requests
            sleep 0.05                                                                              # Sleep for 50 milliseconds - allows rapid successive seek commands to accumulate, only the last one will be used
            
            # Read the LATEST value from the file (Step 1)                                        # Comment - reads the most recently written seek parameters
            read -r final_arg final_len final_player < "$SEEK_FILE"                                # Read three space-separated values from SEEK_FILE into variables: final_arg (percentage), final_len (length), final_player (player name)
            
            # Perform the Seek Logic                                                               # Comment - calculate and execute the actual seek
            if [ -n "$final_len" ] && [ "$final_len" != "0" ]; then                                # Check if length is non-empty AND not zero (prevents division by zero in awk)
                # Use AWK for math                                                                 # Comment - awk provides floating point precision that bash lacks
                target_sec=$(awk -v len="$final_len" -v perc="$final_arg" 'BEGIN { printf "%.2f", (len * perc) / 100 }')  # Calculate target position in seconds using awk: multiply length by percentage divided by 100, format to 2 decimal places
                # Execute                                                                          # Comment - issue the actual seek command
                playerctl -p "$final_player" position "$target_sec"                                # Set the player position to the calculated number of seconds using playerctl with the specific player
            fi                                                                                     # End of length validation
            
            # Remove lock so a new batch can start                                                # Comment - cleanup lock to allow future seek operations
            rm "$lock_file"                                                                         # Delete the lock file - signals that this worker is done and a new worker can be spawned for subsequent seeks
        ) &                                                                                        # End subshell and run it in background (&) - this allows the main script to exit immediately
        
        # Exit main script immediately to free up the UI                                          # Comment - the UI doesn't wait for the seek to complete
        exit 0                                                                                     # Exit immediately with success - the background worker continues independently
        ;;                                                                                         # End of "seek" case block
    
    "next")                                                                                        # If command is "next": skip to next track
        playerctl -p "$player_name" next ;;                                                        # Send "next" command to the specified media player via playerctl
    
    "prev")                                                                                        # If command is "prev": skip to previous track
        playerctl -p "$player_name" previous ;;                                                    # Send "previous" command to the specified media player
    
    "play-pause")                                                                                  # If command is "play-pause": toggle between play and pause
        playerctl -p "$player_name" play-pause ;;                                                  # Send "play-pause" toggle command to the specified media player
        
esac                                                                                              # End of case statement - script execution complete