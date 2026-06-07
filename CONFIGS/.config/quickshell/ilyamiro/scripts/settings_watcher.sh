#!/usr/bin/env bash
# ^ Specifies that this script should be run using the `bash` interpreter found in the user's PATH environment variable via `env`. This portable shebang ensures the script works across different systems where bash might be installed at various paths.

# File paths
SETTINGS_FILE="$HOME/.config/hypr/settings.json"
# ^ Defines the path to the main settings JSON file that stores user configurations managed by the QuickShell settings UI. This JSON file is the central configuration source that gets modified by the user through the QML settings panel, and this watcher script synchronizes those changes to various Hyprland configuration files.

WEATHER_SCRIPT="$(dirname "$0")/weather.sh"
# ^ Constructs the path to the weather data fetching script relative to this script's location. `dirname "$0"` extracts the directory containing this script, then `/weather.sh` is appended. This script is called when the weather configuration file changes.

ENV_FILE="$(dirname "$0")/quickshell/calendar/.env"
# ^ Constructs the path to the weather/calendar environment configuration file located in the QuickShell calendar module directory. This `.env` file contains settings like API keys and location preferences for weather data, and its changes trigger a weather data refresh.

# Target configuration files based on the modular structure
CONF_DIR="$HOME/.config/hypr/config"
# ^ Defines the directory containing modular Hyprland configuration files. This watcher script updates these files when the corresponding settings change in the JSON configuration.

SETTINGS_CONF="$CONF_DIR/settings.conf"
# ^ Path to the Hyprland settings configuration file that contains general options like keyboard layout and keyboard options. This file is directly included in the main hyprland.conf.

AUTOSTART_CONF="$CONF_DIR/autostart.conf"
# ^ Path to the autostart configuration file that lists programs and commands to run when Hyprland starts. The watcher toggles entries here based on the guide startup preference.

ENV_CONF="$CONF_DIR/env.conf"
# ^ Path to the environment variables configuration file for Hyprland. The wallpaper directory environment variable is set here so it's available to the entire Hyprland session.

KEYBINDS_CONF="$CONF_DIR/keybindings.conf"
# ^ Path to the keybindings configuration file. This file is regenerated entirely from the JSON settings whenever keybinding preferences are modified by the user.

MONITORS_CONF="$CONF_DIR/monitors.conf"
# ^ Path to the monitor configuration file that defines display layouts, resolutions, refresh rates, and positions. This file is regenerated from the JSON settings when monitor arrangements change.

ZSH_RC="$HOME/.zshrc"
# ^ Path to the user's Zsh shell configuration file. The watcher updates environment variable exports here (like WALLPAPER_DIR) to ensure they persist across terminal sessions, not just within Hyprland.

# Ensure the required files and directories exist before watching
mkdir -p "$(dirname "$SETTINGS_FILE")"
# ^ Creates the parent directory for the settings JSON file if it doesn't exist. `dirname` extracts the directory portion (`$HOME/.config/hypr`), and `mkdir -p` creates it along with any necessary parent directories.

mkdir -p "$(dirname "$ENV_FILE")"
# ^ Creates the parent directory structure for the calendar .env file (inside the QuickShell scripts directory) if it doesn't already exist.

mkdir -p "$CONF_DIR"
# ^ Creates the modular Hyprland configuration directory if it doesn't exist, ensuring all target configuration files have a home.

[ ! -f "$SETTINGS_FILE" ] && echo "{}" > "$SETTINGS_FILE"
# ^ If the settings JSON file does not already exist, creates it with an empty JSON object `{}` as the initial content. This prevents errors from tools like `jq` trying to parse a non-existent file on first run.

# Define cache directory for state tracking
CACHE_DIR="$HOME/.cache/settings_watcher"
# ^ Defines the path to a cache directory where the watcher stores previous states of each settings section. By comparing current settings against cached versions, the script can detect which specific section changed and apply only the necessary updates.

mkdir -p "$CACHE_DIR"
# ^ Creates the cache directory if it doesn't exist, ensuring the watcher has a place to store its state tracking files.

echo "Started watching settings directories for changes..."
# ^ Prints a status message to the terminal indicating that the file watcher has started and is actively monitoring for configuration changes. This is useful for debugging or when running the script manually.

inotifywait -m -q -e close_write,moved_to --format '%w%f' "$(dirname "$SETTINGS_FILE")" "$(dirname "$ENV_FILE")" | while read -r filepath; do
    # ^ This is the core of the script: a continuous file monitoring pipeline. `inotifywait` watches directories for file system events: `-m` enables monitor mode (run indefinitely), `-q` enables quiet mode (suppresses startup messages), `-e close_write,moved_to` listens for files being closed after writing (indicating a complete edit) or files moved into the watched directory. `--format '%w%f'` outputs the full path of the affected file. The two watched directories are the settings JSON parent and the calendar .env parent. The output is piped to a `while read` loop that processes each file change event, storing the affected file's path in the `filepath` variable. The `-r` flag prevents backslash interpretation in filenames.

    # ---------------------------------------------------------
    # SETTINGS JSON TRIGGER
    # ---------------------------------------------------------
    if [[ "$filepath" == "$SETTINGS_FILE" ]]; then
        # ^ Checks if the file that triggered the event is the main settings JSON file. If so, the script needs to parse it and potentially update multiple Hyprland configuration files.

        echo "Settings file modified. Checking for specific changes..."
        # ^ Prints a status message indicating that the settings file was modified and the script is about to analyze what changed.

        # 1. Capture current states as compact JSON strings
        NEW_GENERAL=$(jq -c '{language, kbOptions, openGuideAtStartup, wallpaperDir}' "$SETTINGS_FILE" 2>/dev/null)
        # ^ Extracts the general settings section from the JSON file using `jq`. The `-c` flag outputs in compact format (single line). The filter `{language, kbOptions, openGuideAtStartup, wallpaperDir}` creates a new JSON object containing only these four fields from the settings file. Errors are suppressed with `2>/dev/null` in case the file is malformed. This compact representation is perfect for comparison with the cached version.

        NEW_KEYBINDS=$(jq -c '.keybinds' "$SETTINGS_FILE" 2>/dev/null)
        # ^ Extracts the entire keybinds array/section from the settings JSON in compact format. This captures all keybinding configurations for comparison with the cached version.

        NEW_MONITORS=$(jq -c '.monitors' "$SETTINGS_FILE" 2>/dev/null)
        # ^ Extracts the entire monitors array/section from the settings JSON in compact format. This captures all monitor display configurations for comparison.

        # 2. Update General Settings if changed
        if [[ "$NEW_GENERAL" != "$(cat "$CACHE_DIR/general" 2>/dev/null)" ]]; then
            # ^ Compares the newly extracted general settings with the previously cached version. If they differ (or if no cache exists yet, the `cat` returns empty string), general settings have been modified and need to be applied to configuration files.

            echo "General settings changed. Applying..."
            # ^ Status message indicating general settings are being synchronized to Hyprland config files.

            LANG=$(jq -r '.language // empty' "$SETTINGS_FILE")
            # ^ Extracts the keyboard language/layout setting from the JSON file. The `-r` flag outputs raw text (without JSON quotes). The `// empty` operator returns an empty string if the field doesn't exist, rather than the literal string "null".

            KB_OPT=$(jq -r '.kbOptions // empty' "$SETTINGS_FILE")
            # ^ Extracts the keyboard options setting (e.g., custom XKB options like "ctrl:nocaps") from the JSON file, defaulting to empty string if not set.

            GUIDE_STARTUP=$(jq -r '.openGuideAtStartup' "$SETTINGS_FILE")
            # ^ Extracts the guide startup preference (a boolean "true" or "false") from the JSON file. This determines whether the guide overlay appears automatically when Hyprland starts.

            WP_DIR=$(jq -r '.wallpaperDir // empty' "$SETTINGS_FILE")
            # ^ Extracts the wallpaper directory path setting from the JSON file, defaulting to empty string if the field is not configured.

            [ -n "$LANG" ] && [ "$LANG" != "null" ] && sed -i "s/^ *kb_layout =.*/    kb_layout = $LANG/" "$SETTINGS_CONF"
            # ^ If the language setting is not empty AND is not the literal string "null" (which jq outputs for JSON null values), updates the keyboard layout line in the Hyprland settings config file using `sed -i` (in-place editing). The pattern `^ *kb_layout =.*` matches any line starting with optional spaces followed by "kb_layout =", and replaces it with the properly indented new value.

            if [ -n "$KB_OPT" ] && [ "$KB_OPT" != "null" ]; then
                # ^ Checks if a keyboard options value is provided and is valid. If so, it will be applied to the config.

                sed -i "s/^ *kb_options =.*/    kb_options = $KB_OPT/" "$SETTINGS_CONF"
                # ^ Updates the keyboard options line in the settings config file with the new value, maintaining proper indentation.

            else
                sed -i "s/^ *kb_options =.*/    kb_options = /" "$SETTINGS_CONF"
                # ^ If no keyboard options are set, clears the line by setting it to an empty value after the equals sign. This effectively disables any custom keyboard options.
            fi

            if [ "$GUIDE_STARTUP" == "true" ]; then
                # ^ If the guide startup preference is enabled (true).

                sed -i 's|^#*[[:space:]]*exec-once = ~/.config/hypr/scripts/qs_manager.sh toggle guide.*|exec-once = ~/.config/hypr/scripts/qs_manager.sh toggle guide \&|' "$AUTOSTART_CONF"
                # ^ Uncomments and ensures the guide toggle line is active in the autostart config. The `sed` pattern `^#*[[:space:]]*` matches any number of comment characters and whitespace at the beginning of the line, replacing it with the uncommented exec-once command. The `|` is used as a delimiter instead of `/` since file paths contain slashes. The `\&` appends a literal `&` to run the command in the background.

            elif [ "$GUIDE_STARTUP" == "false" ]; then
                # ^ If the guide startup preference is disabled (false).

                sed -i 's|^exec-once = ~/.config/hypr/scripts/qs_manager.sh toggle guide.*|# exec-once = ~/.config/hypr/scripts/qs_manager.sh toggle guide \&|' "$AUTOSTART_CONF"
                # ^ Comments out the guide toggle line in the autostart config by adding a `# ` prefix to it. This prevents the guide from opening automatically on startup while preserving the line for easy re-enabling.
            fi

            if [ -n "$WP_DIR" ] && [ "$WP_DIR" != "null" ]; then
                # ^ If a wallpaper directory is set and is a valid path (not null).

                sed -i "s|^env = WALLPAPER_DIR,.*|env = WALLPAPER_DIR,$WP_DIR|" "$ENV_CONF"
                # ^ Updates the WALLPAPER_DIR environment variable line in the Hyprland environment config file with the new directory path. Using `|` as delimiter since paths contain forward slashes.

                [ -f "$ZSH_RC" ] && sed -i "s|^export WALLPAPER_DIR=.*|export WALLPAPER_DIR=\"$WP_DIR\"|" "$ZSH_RC"
                # ^ If the .zshrc file exists, also updates the WALLPAPER_DIR export there. This ensures the wallpaper directory is set both for the Hyprland session and for terminal/shell sessions. The path is wrapped in double quotes to handle spaces.
            fi
            
            echo "$NEW_GENERAL" > "$CACHE_DIR/general"
            # ^ Updates the general settings cache file with the new settings. This prevents the same changes from being reapplied on the next detection event.
        fi

        # 3. Update Keybindings if changed
        if [[ "$NEW_KEYBINDS" != "$(cat "$CACHE_DIR/keybinds" 2>/dev/null)" ]]; then
            # ^ Compares the newly extracted keybinds with the cached version. If they differ, the keybindings configuration file needs to be regenerated.

            echo "Keybinds changed. Regenerating..."
            # ^ Status message indicating keybinding regeneration is starting.

            cat << 'EOF' > "$KEYBINDS_CONF"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  ◈ KEYBINDINGS (Auto-generated by Quickshell Settings Watcher)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ───────── Mouse & Gestures ─────────
gesture = 3, horizontal, workspace

# ───────── Dynamic Keybinds ─────────
EOF
            # ^ Writes a header block to the keybindings config file using a heredoc. The single quotes around 'EOF' prevent variable expansion. The header includes a warning that the file is auto-generated, a fixed mouse gesture configuration (3-finger horizontal swipe changes workspaces), and a section header for the dynamically generated keybinds that follow.

            jq -r '.keybinds[]? | "\(.type // "bind") = \(.mods // ""), \(.key // ""), \(.dispatcher // "exec")\(if .command and .command != "" then ", \(.command)" else "" end)"' "$SETTINGS_FILE" >> "$KEYBINDS_CONF"
            # ^ Appends all keybinding configurations to the keybindings config file using a powerful `jq` expression. `jq -r` outputs raw text. `.keybinds[]?` iterates over each keybinding entry (the `?` suppresses errors if the array is empty). For each binding, it constructs a Hyprland bind line using string interpolation: the type defaults to "bind" if not specified, the mods (modifier keys like "SUPER"), the key, and the dispatcher (defaults to "exec"). If a command exists and is non-empty, it's appended after a comma. This creates lines like `bind = SUPER, E, exec, thunar` from the JSON configuration.

            echo "$NEW_KEYBINDS" > "$CACHE_DIR/keybinds"
            # ^ Updates the keybindings cache with the new configuration to prevent redundant regeneration.
        fi

        # 4. Update Monitors if changed
        if [[ "$NEW_MONITORS" != "$(cat "$CACHE_DIR/monitors" 2>/dev/null)" ]]; then
            # ^ Compares the newly extracted monitor configuration with the cached version. If they differ, the monitors config file must be regenerated.

            echo "Monitors changed. Regenerating..."
            # ^ Status message indicating monitor configuration regeneration.

            cat << 'EOF' > "$MONITORS_CONF"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  ◈ MONITORS (Auto-generated by Quickshell Settings Watcher)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
            # ^ Writes the header block to the monitors config file, indicating it is auto-generated by the settings watcher. The trailing empty line separates the header from the monitor entries.

            MONITOR_COUNT=$(jq '.monitors | length' "$SETTINGS_FILE" 2>/dev/null)
            # ^ Counts the number of monitor entries in the JSON settings using `jq '.monitors | length'`. This determines whether there are any configured monitors or if defaults should be used.

            if [[ "$MONITOR_COUNT" -gt 0 ]]; then
                # ^ If there is at least one monitor configured in the settings.

                jq -r '.monitors[]? | "monitor = \(.name), \(.resW)x\(.resH)@\(.rate), \(.x)x\(.y), \(.scale)\(if .transform and .transform != 0 then ", transform, \(.transform)" else "" end)"' "$SETTINGS_FILE" >> "$MONITORS_CONF"
                # ^ Generates Hyprland monitor configuration lines for each monitor entry and appends them to the config file. For each monitor, it constructs a line like `monitor = eDP-1, 1920x1080@60, 0x0, 1`. The format includes: monitor name, resolution (resW x resH) @ refresh rate, position (x x y), and scale. If a transform (rotation) is specified and is not 0, it appends ", transform, " followed by the transform value (e.g., ", transform, 1" for 90-degree rotation).
            else
                echo "monitor = , preferred, auto, 1" >> "$MONITORS_CONF"
                # ^ If no monitors are configured, writes a default auto-detection line that tells Hyprland to use the preferred resolution, automatic positioning, and a scale of 1 for all detected displays.
            fi

            echo "$NEW_MONITORS" > "$CACHE_DIR/monitors"
            # ^ Updates the monitors cache with the new configuration to prevent redundant regeneration on future events.
        fi

    # ---------------------------------------------------------
    # .ENV WEATHER TRIGGER
    # ---------------------------------------------------------
    elif [[ "$filepath" == "$ENV_FILE" ]]; then
        # ^ If the modified file is the calendar .env file (containing weather API settings like location and API keys), triggers a weather data refresh.

        echo ".env updated! Forcing weather cache refresh..."
        # ^ Status message indicating that weather data will be refreshed due to configuration changes.

        if [ -x "$WEATHER_SCRIPT" ]; then
            # ^ Checks if the weather script exists and is executable (`-x` test). If so, it can be run directly.

            "$WEATHER_SCRIPT" --getdata &
            # ^ Runs the weather script with the `--getdata` flag to fetch fresh weather data based on the new configuration. The `&` runs it in the background so it doesn't block the file watcher loop.

        else
            bash "$WEATHER_SCRIPT" --getdata &
            # ^ If the weather script is not executable (permission issue), runs it explicitly with `bash`. Still runs in the background to avoid blocking.
        fi
    fi
done
# ^ Closes the while loop. The script continues running indefinitely because `inotifywait` runs in monitor mode (`-m`), continuously outputting file change events as they occur. Each event is processed through the loop, and the script only terminates when killed externally or when inotifywait itself fails.