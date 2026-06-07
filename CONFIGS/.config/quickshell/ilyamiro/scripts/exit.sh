#!/usr/bin/env bash
# ^ Specifies that this script should be run using the `bash` interpreter found in the user's PATH environment variable via `env`. This ensures portability by locating bash dynamically rather than using a hardcoded path.

systemctl --user stop graphical-session.target
# ^ Uses `systemctl` with the `--user` flag to stop the user-level systemd target called `graphical-session.target`. This target represents the user's graphical session as a whole (including the compositor, X/Wayland services, and related user services). Stopping it gracefully terminates all services and processes that are part of this target in an orderly manner before the compositor itself exits.

systemctl --user stop graphical-session-pre.target
# ^ Stops the user-level `graphical-session-pre.target`, which is a systemd target that runs before the graphical session starts. This target typically includes pre-session services like XDG autostart, environment setup, and other dependencies that should be cleaned up before the session ends. Stopping it ensures proper teardown of these preparatory services.

sleep 0.5
# ^ Pauses script execution for 0.5 seconds (half a second). This brief delay gives the systemd user services time to actually stop and clean up their resources before the Hyprland compositor is terminated. Without this delay, the compositor might exit while services are still shutting down, potentially causing errors or leaving processes in an inconsistent state.

hyprctl dispatch exit
# ^ Sends the `exit` dispatch command to the Hyprland compositor via `hyprctl`. This tells Hyprland to gracefully terminate itself, closing all windows, killing child processes, and shutting down the Wayland display server. The `dispatch` subcommand is used to send dispatcher actions to the running compositor. This is the final step that actually ends the user's graphical session by stopping the window manager/compositor itself.