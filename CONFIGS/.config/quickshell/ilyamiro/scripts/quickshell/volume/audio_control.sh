# #!/usr/bin/env bash

# ACTION=$1
# TYPE=$2
# ID=$3
# VAL=$4

# case $ACTION in
#     set-volume)
#         # Type should be 'sink', 'source', or 'sink-input'
#         pactl set-$TYPE-volume "$ID" "$VAL%"
#         ;;
#     toggle-mute)
#         pactl set-$TYPE-mute "$ID" toggle
#         ;;
#     set-default)
#         # For setting defaults, we need to use the name rather than the index
#         pactl set-default-$TYPE "$ID"
#         ;;
# esac
#!/usr/bin/env bash                                                              # Shebang line: uses env to find bash interpreter for portability across systems

ACTION=$1                                                                        # Assigns first command-line argument to ACTION variable (e.g., set-volume, toggle-mute, set-default)
TYPE=$2                                                                          # Assigns second argument to TYPE variable (e.g., sink, source, sink-input for audio devices)
ID=$3                                                                            # Assigns third argument to ID variable (device identifier - can be index number or name)
VAL=$4                                                                           # Assigns fourth argument to VAL variable (volume percentage or other value)

case $ACTION in                                                                  # Case statement branching based on the ACTION argument value
    set-volume)                                                                  # Branch for volume adjustment action
        # Type should be 'sink', 'source', or 'sink-input'                        # Comment indicating valid TYPE values: sink (output), source (input), sink-input (application)
        pactl set-$TYPE-volume "$ID" "$VAL%"                                     # Executes pactl command: dynamically constructs type (e.g., set-sink-volume) and sets volume to VAL% (percentage with % sign)
        ;;                                                                        # End of set-volume branch
    toggle-mute)                                                                 # Branch for mute toggle action
        pactl set-$TYPE-mute "$ID" toggle                                        # Executes pactl command: dynamically constructs type (e.g., set-sink-mute) and toggles mute state for the device
        ;;                                                                        # End of toggle-mute branch
    set-default)                                                                 # Branch for setting default audio device
        # For setting defaults, we need to use the name rather than the index      # Comment noting that default device must be set by name (not numeric index)
        pactl set-default-$TYPE "$ID"                                            # Executes pactl command: dynamically constructs type (e.g., set-default-sink) using device name as ID
        ;;                                                                        # End of set-default branch
esac                                                                             # End of case statement - no default/wildcard branch, unrecognized actions are silently ignored