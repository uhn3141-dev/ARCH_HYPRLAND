#!/usr/bin/env bash
# ^ Specifies that this script should be run using the `bash` interpreter found in the user's PATH environment variable via `env`. This portable shebang locates bash dynamically rather than relying on a hardcoded absolute path.

# Helper functions to get current state
get_sink() { pactl get-default-sink; }
# ^ Defines a helper function called `get_sink` that returns the name of the currently active/default audio output sink (device). It uses `pactl get-default-sink` to query PulseAudio/PipeWire for the default output device (e.g., "alsa_output.pci-0000_00_1f.3.analog-stereo" for built-in speakers or a Bluetooth headphone sink). This function allows consistent state queries throughout the script.

get_vol() { pamixer --get-volume; }
# ^ Defines a helper function called `get_vol` that returns the current volume level as an integer percentage. It uses `pamixer --get-volume` which queries the current default sink's volume directly. `pamixer` is a PulseAudio command-line mixer that provides simpler volume queries than pactl.

get_mute() { pamixer --get-mute; }
# ^ Defines a helper function called `get_mute` that returns the current mute state of the default sink. `pamixer --get-mute` outputs either "true" (muted) or "false" (not muted). This function provides a consistent interface for checking mute status.

# 1. Initialize state
last_sink=$(get_sink)
# ^ Captures the initial default sink name before the event loop starts. This stored value will be used for comparison with subsequent states to detect when the audio output device itself has changed (e.g., plugging in headphones or switching to a Bluetooth speaker).

last_vol=$(get_vol)
# ^ Captures the initial volume level as a baseline. This stored value allows the script to detect when the volume has actually changed (as opposed to other sink events that don't affect volume).

last_mute=$(get_mute)
# ^ Captures the initial mute state as a baseline. This stored value enables detection of mute toggles, which would change the mute state without necessarily changing the volume percentage.

# 2. Loop through events
pactl subscribe | grep --line-buffered "Event 'change' on sink" | while read -r line; do
    # ^ Creates a continuous audio event monitoring pipeline. `pactl subscribe` outputs events from the PulseAudio/PipeWire server whenever something changes (new sinks, volume changes, device connections, etc.). This output is piped to `grep --line-buffered "Event 'change' on sink"` which filters for only events related to sink changes (output devices). The `--line-buffered` flag ensures grep outputs matching lines immediately rather than buffering them, enabling real-time responsiveness. The filtered events are piped to a `while read -r line` loop that processes each event as it occurs. The `-r` flag prevents backslash interpretation in the input.

    current_sink=$(get_sink)
    # ^ Queries the current default sink at the moment the event was received. This captures the potentially changed state of the audio output device.

    current_vol=$(get_vol)
    # ^ Queries the current volume level at the moment of the event, capturing any volume changes that may have triggered this event.

    current_mute=$(get_mute)
    # ^ Queries the current mute state at the moment of the event, capturing any mute toggles that may have triggered this event.

    # CHECK 1: Did the Output Device change? (e.g. Headphones connected)
    if [[ "$current_sink" != "$last_sink" ]]; then
        # ^ Compares the current default sink against the previously stored sink. If they differ, it means the audio output device itself has changed (e.g., the user plugged in headphones, connected a Bluetooth speaker, or switched output devices manually). This is important because device changes also trigger sink change events, but the script wants to ignore these for the purpose of showing volume overlays.

        # The device changed. We do NOT want a popup for this.
        # Just update our tracking variables to the new device's levels.
        last_sink="$current_sink"
        # ^ Updates the stored sink to the new device name. This prevents the device change from being detected again on subsequent events (until the device changes again).

        last_vol="$current_vol"
        # ^ Updates the stored volume to the new device's volume level. When switching devices, the volume level may be different (headphones might have their own volume setting), so the baseline must be reset to the new device's current state.

        last_mute="$current_mute"
        # ^ Updates the stored mute state to the new device's mute state. Like volume, mute state can be per-device, so the baseline is reset to prevent false detection of a mute change.

        continue
        # ^ Skips the rest of the loop body (CHECK 2) and jumps to the next iteration. This ensures that device changes alone do not trigger the on-screen display (OSD) volume popup, since the user didn't intentionally change the volume—they just changed output devices.
    fi

    # CHECK 2: Did the Volume/Mute actually change on the SAME device?
    if [[ "$current_vol" != "$last_vol" ]] || [[ "$current_mute" != "$last_mute" ]]; then
        # ^ Checks if either the volume level OR the mute state has changed from the last recorded values. Since CHECK 1 already confirmed the device hasn't changed, any difference here means the user intentionally adjusted the volume or toggled mute on the current output device. The `||` (OR) operator means if either condition is true, the OSD should be triggered.

        # Trigger OSD (without changing volume)
        swayosd-client --output-volume 0
        # ^ Triggers the on-screen display (OSD) to show the current volume level. The `--output-volume 0` flag tells swayosd-client to display the output device's volume overlay with a volume change of 0 (meaning it just shows the current state without modifying the volume further). The `0` value effectively says "display the current volume without adjusting it." This causes a visual volume indicator to appear on screen, showing the new volume level and mute status.

        # Update tracking
        last_vol="$current_vol"
        # ^ Updates the stored volume level to the new value. This prevents the OSD from being triggered again on the same volume level when the next event arrives (only actual future changes will trigger it).

        last_mute="$current_mute"
        # ^ Updates the stored mute state to the new value. This completes the state tracking update, ensuring the script accurately knows the current audio state for future event comparisons.
    fi
    # ^ Closes the volume/mute change check if statement.
done
# ^ Closes the while loop. The script will continue monitoring for sink change events indefinitely. Each time pactl outputs a matching event, the loop body processes it, checks what actually changed, and conditionally displays the volume OSD. The script runs until it is externally terminated (e.g., by killing the process or stopping a systemd service that manages it).