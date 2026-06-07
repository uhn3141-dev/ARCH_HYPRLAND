#!/usr/bin/env bash
# =============================================================================
# Audio Control Script for Quickshell Sound Panel
# Usage: audio_control.sh <action> <type> <id> [value]
#
# Actions:
#   set-volume   - Set volume percentage for a device/stream
#   toggle-mute  - Toggle mute state for a device/stream
#   set-default  - Set the default sink or source
#
# Types:
#   sink         - Output device
#   source       - Input device
#   sink-input   - Application audio stream
#
# Examples:
#   audio_control.sh set-volume sink 0 75        (set speaker to 75%)
#   audio_control.sh toggle-mute source 1         (toggle mic mute)
#   audio_control.sh set-default sink "alsa_output.pci-0000_00_1f.3.analog-stereo"
# =============================================================================

ACTION="$1"   # set-volume | toggle-mute | set-default
TYPE="$2"     # sink | source | sink-input
ID="$3"       # device index or stream index
VAL="$4"      # volume percentage (only for set-volume)

case "$ACTION" in
    set-volume)
        # Set the volume of a specific device or stream
        # Example: pactl set-sink-volume 0 75%
        pactl "set-${TYPE}-volume" "$ID" "${VAL}%"
        ;;
    toggle-mute)
        # Toggle mute on/off for a specific device or stream
        # Example: pactl set-sink-mute 0 toggle
        pactl "set-${TYPE}-mute" "$ID" toggle
        ;;
    set-default)
        # Set the default sink or source by its internal name
        # This affects where new audio streams are routed
        # Example: pactl set-default-sink "alsa_output.pci-0000_00_1f.3.analog-stereo"
        pactl "set-default-${TYPE}" "$ID"
        ;;
    *)
        echo "Usage: $0 {set-volume|toggle-mute|set-default} <type> <id> [value]"
        exit 1
        ;;
esac