#!/usr/bin/env bash
# ^ Specifies that this script should be run using the `bash` interpreter found in the user's PATH environment variable, ensuring consistent Bash behavior across different systems.

FLAG="$HOME/.cache/wallpaper_initialized"
# ^ Defines the path to a flag file used to track whether the wallpaper initialization has already been completed. The `$HOME` variable expands to the current user's home directory, and `.cache` is a standard directory for temporary/cache files.

RELOAD_SCRIPT_PATH="$HOME/.config/hypr/scripts/quickshell/wallpaper/matugen_reload.sh"
# ^ Defines the full path to a script that reloads or reapplies the matugen color scheme. This script is located within the QuickShell wallpaper module directory and is responsible for refreshing the system theme based on the current wallpaper colors.

# If the flag exists, just run matugen and the reload script, then exit
if [ -f "$FLAG" ]; then
    # ^ Checks if the flag file exists as a regular file (`-f` test). If it exists, it means wallpaper initialization has already been performed previously, so we only need to reapply the theme rather than setting up everything from scratch.

    # Use the cached wallpaper image for matugen
    if [ -f "/tmp/lock_bg.png" ]; then
        # ^ Checks if the cached lock screen background image exists at `/tmp/lock_bg.png`. This file was created during the first initialization and serves as a persistent reference to the selected wallpaper.

        matugen image "/tmp/lock_bg.png" --source-color-index 0
        # ^ Runs the `matugen` command (a Material You color scheme generator) using the cached wallpaper image as the source. The `image` subcommand tells matugen to extract colors from an image. The `--source-color-index 0` flag instructs matugen to use color index 0 (typically the dominant or primary color) from the generated palette as the source for generating the color scheme.
    fi
    
    if [ -f "$RELOAD_SCRIPT_PATH" ]; then
        # ^ Checks if the matugen reload script exists at the specified path before attempting to execute it, preventing errors if the script file is missing.

        chmod +x "$RELOAD_SCRIPT_PATH"
        # ^ Ensures the reload script has execute permissions by adding the executable bit (`+x`) to its file mode. This prevents permission denied errors when trying to run the script.

        bash "$RELOAD_SCRIPT_PATH"
        # ^ Executes the reload script using the `bash` interpreter explicitly, which sources and applies the matugen-generated color scheme to various system components (likely including Hyprland, waybar, GTK themes, etc.).
    fi
    
    exit 0
    # ^ Terminates the script with a success exit code (0) since the wallpaper was already initialized and only needed a theme refresh. No further initialization steps are required.
fi

# If no wallpaper dir is set, default to a common one to prevent find from failing
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
# ^ Sets the WALLPAPER_DIR variable using parameter expansion: if the WALLPAPER_DIR environment variable is already set, use its value; otherwise, fall back to the default path `$HOME/Pictures/Wallpapers`. This prevents the `find` command later from failing due to an empty or undefined directory.

sleep 0.5
# ^ Pauses the script execution for 0.5 seconds. This small delay allows the display server and window manager (Hyprland) to fully initialize before attempting to set the wallpaper, preventing potential race conditions where the wallpaper command runs before the compositor is ready to handle it.

# Find a random file
file=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | shuf -n 1)
# ^ Searches for image files in the wallpaper directory and selects one randomly. The `find` command looks for regular files (`-type f`) with case-insensitive names matching `.jpg`, `.jpeg`, or `.png` extensions (using `-iname` for case-insensitive matching). Errors are suppressed with `2>/dev/null`. The results are piped to `shuf -n 1` which randomly selects one line from the input. The selected file path is stored in the `file` variable using command substitution `$()`.

if [ -n "$file" ]; then
    # ^ Checks if the `file` variable is not empty (`-n` tests for a non-zero length string), meaning a wallpaper file was successfully found. This prevents errors if the wallpaper directory is empty or doesn't contain supported image types.

    cp "$file" /tmp/lock_bg.png
    # ^ Copies the selected wallpaper image to a fixed location at `/tmp/lock_bg.png`. This creates a persistent cached copy that can be referenced later (e.g., by the lock screen, the initialization flag check above, or other components that need access to the current wallpaper without knowing the original path).
    
    awww img "$file" --transition-type any --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 &
    # ^ Sets the desktop wallpaper using the `awww` wallpaper daemon (an alternative to swww). The `img` subcommand loads the specified image file. The flags configure the transition animation: `--transition-type any` uses any available transition effect, `--transition-pos 0.5,0.5` centers the transition origin, `--transition-fps 144` runs the animation at 144 frames per second for smoothness, and `--transition-duration 1` makes the transition last 1 second. The final `&` runs this command in the background so the script can continue without waiting for the wallpaper transition to complete.
    
    matugen image "$file" --source-color-index 0
    # ^ Generates a Material You color scheme using `matugen` with the selected wallpaper as the image source. The `--source-color-index 0` flag uses the primary/dominant color from the palette as the basis for generating the entire color scheme, which is then applied to system themes.
    
    # Execute reload script if it exists
    if [ -f "$RELOAD_SCRIPT_PATH" ]; then
        # ^ Checks if the matugen reload script exists before attempting to run it, preventing script failures if the file has been moved or deleted.

        chmod +x "$RELOAD_SCRIPT_PATH"
        # ^ Adds the executable permission to the reload script file to ensure it can be run without permission issues.

        bash "$RELOAD_SCRIPT_PATH"
        # ^ Executes the reload script using the bash interpreter, which applies the newly generated matugen color scheme to various system theme configurations (such as Hyprland colors, GTK themes, waybar styling, etc.).
    fi
fi

mkdir -p "$(dirname "$FLAG")"
# ^ Creates the parent directory for the flag file if it doesn't already exist. `dirname "$FLAG"` extracts the directory portion of the flag path (`$HOME/.cache`), and `mkdir -p` creates all necessary parent directories without error if they already exist. This ensures the flag file can be created in the next step without a "no such directory" error.

touch "$FLAG"
# ^ Creates the flag file (or updates its timestamp if it already exists) at the specified path. This marks wallpaper initialization as complete, preventing the full initialization process from running again on subsequent script executions. The file's mere existence signals that the first-time setup has been done, so future runs take the early exit path at the beginning of the script.