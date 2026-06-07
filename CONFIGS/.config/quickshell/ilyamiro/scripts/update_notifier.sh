#!/usr/bin/env bash
# ^ Specifies that this script should be run using the `bash` interpreter found in the user's PATH environment variable via `env`. This portable shebang ensures the script works across different systems where bash might be installed at various absolute paths.

# Check interval in seconds (600s = 10 minutes)
INTERVAL=600
# ^ Defines the time interval (in seconds) between update checks. 600 seconds equals 10 minutes, meaning this script checks for system updates every 10 minutes without overwhelming the network or CPU with constant polling.

# Cache file to prevent notification spam if the script is restarted
CACHE_FILE="$HOME/.cache/qs_update_notified_version"
# ^ Defines the path to a cache file that stores the last remote version number that the user was notified about. This prevents sending repeated desktop notifications for the same update every 10 minutes. If the script is restarted, this file persists the state so the user isn't re-notified about an update they've already been told about.

# State file to tell the topbar to show the update button
PENDING_FILE="$HOME/.cache/qs_update_pending"
# ^ Defines the path to a state file whose mere existence signals the QuickShell topbar to display an update icon/button. When this file exists, the topbar QML component knows an update is available and shows a clickable indicator. When the file is removed (after updating or when versions match), the button hides itself.

while true; do
    # ^ Starts an infinite loop that runs continuously until the script is terminated externally (e.g., killed by the system or user). This ensures the update checking runs perpetually at the defined interval.

    # Fetch local version
    LOCAL_VERSION=$(source ~/.local/state/imperative-dots-version 2>/dev/null && echo "$LOCAL_VERSION")
    # ^ Retrieves the currently installed version of the "Imperative Dots" system by sourcing a version file. The `source` command executes the file in the current shell context, which presumably sets a `LOCAL_VERSION` variable. After sourcing, `echo "$LOCAL_VERSION"` prints that value, and the entire command substitution captures it. Errors (e.g., file not found) are suppressed with `2>/dev/null`.

    LOCAL_VERSION=${LOCAL_VERSION:-"Unknown"}
    # ^ If the LOCAL_VERSION variable is empty or unset (which happens if the source file didn't exist or didn't set the variable), uses "Unknown" as the fallback value. The `${var:-default}` parameter expansion syntax provides this default behavior.

    # Fetch remote version
    REMOTE_VERSION=$(curl -m 5 -s https://raw.githubusercontent.com/ilyamiro/imperative-dots/master/install.sh | grep '^DOTS_VERSION=' | cut -d'"' -f2)
    # ^ Fetches the latest available version number from the project's GitHub repository. The pipeline: `curl -m 5 -s` downloads the raw install script with a 5-second timeout (`-m 5`) and in silent mode (`-s` to suppress progress output). The downloaded content is piped to `grep '^DOTS_VERSION='` which finds the line that defines the version variable. That line is piped to `cut -d'"' -f2` which extracts the text between double quotes (the actual version number, e.g., "2.4.0"). The result is stored in REMOTE_VERSION.

    # Check if we got valid responses and they don't match
    if [[ -n "$REMOTE_VERSION" && "$LOCAL_VERSION" != "Unknown" && "$LOCAL_VERSION" != "$REMOTE_VERSION" ]]; then
        # ^ Verifies three conditions are all true: (1) REMOTE_VERSION is not empty (meaning the curl fetch succeeded), (2) LOCAL_VERSION is not "Unknown" (meaning the local version file was read successfully), and (3) the local and remote versions differ (meaning an update is available). Only if all three are true does the script proceed to notify about an available update.

        # Determine the newest version using bash semantic sorting
        NEWEST=$(printf '%s\n' "$LOCAL_VERSION" "$REMOTE_VERSION" | sort -V | tail -n1)
        # ^ Compares the two version strings to determine which is newer using semantic version sorting. `printf '%s\n'` outputs both versions on separate lines, which are piped to `sort -V` (version sort, which correctly handles semantic versions like "2.10.0" being greater than "2.9.0"). `tail -n1` takes the last line, which is the highest/newest version. This prevents false update notifications if the local version is actually ahead of the remote (e.g., on a development branch).

        if [[ "$NEWEST" == "$REMOTE_VERSION" ]]; then
            # ^ Double-checks that the remote version is indeed the newest one. If the local version were somehow newer, this condition would be false and no notification would be sent, respecting that the user might be on a custom or development branch.

            # Signal the topbar to show the update icon
            touch "$PENDING_FILE"
            # ^ Creates (or updates the timestamp of) the pending update file. The QML topbar checks for this file's existence, and when present, displays an update button/icon that the user can click to initiate the update process.

            # Only send the notification if we haven't notified about this specific version yet
            if [[ ! -f "$CACHE_FILE" ]] || [[ "$(cat "$CACHE_FILE")" != "$REMOTE_VERSION" ]]; then
                # ^ Checks if either: (1) the cache file doesn't exist (this is the first time detecting any update), OR (2) the cached version differs from the current remote version (a new update is available that the user hasn't been notified about yet). This prevents notification spam for the same version every 10 minutes.

                # Cache the version so we don't spam the user every 10 minutes
                echo "$REMOTE_VERSION" > "$CACHE_FILE"
                # ^ Writes the current remote version number to the cache file. This ensures that on subsequent checks (10 minutes later), the script will see that it already notified about this version and won't send another notification.

                # Send standard notification without the action prompt
                notify-send -t 15000 -a 'Imperative Dots' -u normal 'Update Available' "A new version ($REMOTE_VERSION) is ready! Click the update icon in the topbar to install."
                # ^ Sends a desktop notification to inform the user about the available update. `-t 15000` sets the notification timeout to 15 seconds (15000 milliseconds). `-a 'Imperative Dots'` sets the application name shown in the notification. `-u normal` sets the urgency level to normal (as opposed to low or critical). The notification title is 'Update Available' and the body includes the new version number and instructions to use the topbar icon for installation.

            fi
            # ^ Closes the cache check if statement.
        fi
        # ^ Closes the newest version check if statement.
    else
        # ^ This branch executes if: the remote version couldn't be fetched (curl failed/offline), OR the local version is unknown (version file missing), OR the versions match (no update needed).

        # Self-healing: if versions match or we are offline, clear the pending flag 
        # so the topbar button disappears if you updated via terminal.
        rm -f "$PENDING_FILE"
        # ^ Removes the pending update file. This serves as a self-healing mechanism: if the user manually updates the system via terminal (rather than through the topbar button), the next check will detect that versions match and remove the pending flag, causing the topbar update button to disappear automatically. The `-f` flag suppresses errors if the file doesn't exist.
    fi

    # Wait 10 minutes before checking again
    sleep "$INTERVAL"
    # ^ Pauses the script execution for the defined interval (600 seconds / 10 minutes). After this sleep completes, the while loop continues to its next iteration, performing another update check. This creates a periodic polling pattern without consuming CPU resources during the wait period.
done
# ^ Closes the infinite while loop. The script will continue cycling through the update check logic every 10 minutes until it is externally terminated (e.g., the script process is killed, the system shuts down, or a systemd service managing it is stopped).