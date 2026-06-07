# #!/usr/bin/env bash

# # ------------------------------------------------------------------------------
# # 1. Flatten Matugen v4.0 Nested JSON for Quickshell
# # ------------------------------------------------------------------------------
# # Updated to match your config.toml output path
# QS_JSON="~/.config/hypr/scripts/quickshell/qs_colors.json"

# python3 -c '
# import json
# import sys

# def flatten_colors(obj):
#     if isinstance(obj, dict):
#         if "color" in obj and isinstance(obj["color"], str):
#             return obj["color"]
#         return {k: flatten_colors(v) for k, v in obj.items()}
#     elif isinstance(obj, list):
#         return [flatten_colors(x) for x in obj]
#     return obj

# target_file = sys.argv[1]
# try:
#     with open(target_file, "r") as f:
#         data = json.load(f)
    
#     flat_data = flatten_colors(data)
    
#     with open(target_file, "w") as f:
#         json.dump(flat_data, f, indent=4)
        
# except FileNotFoundError:
#     pass
# except Exception as e:
#     print(f"Error flattening JSON: {e}")
# ' "$QS_JSON"

# # ------------------------------------------------------------------------------
# # 2. Flatten Matugen v4.0 Output in Standard Text Configs
# # ------------------------------------------------------------------------------
# # If Tera dumped {"color": "#hex"} into your text files, this strips it to #hex.
# TEXT_FILES=(
#     "$HOME/.config/hypr/scripts/quickshell/qs_colors.json"
#     "$HOME/.config/kitty/kitty-matugen-colors.conf"
#     "$HOME/.config/nvim/matugen_colors.lua"
#     "$HOME/.config/cava/colors"
#     "$HOME/.config/swayosd/style.css"
#     "$HOME/.config/rofi/theme.rasi"
#     "$HOME/.cache/matugen/colors-gtk.css"
#     "$HOME/.config/qt5ct/colors/matugen.conf"
#     "$HOME/.config/qt6ct/colors/matugen.conf"
#     "$HOME/.config/qt5ct/qss/matugen-style.qss"
#     "$HOME/.config/qt6ct/qss/matugen-style.qss"
#     "$HOME/.config/hypr/colors.conf"
# )

# for file in "${TEXT_FILES[@]}"; do
#     # Check if file exists and we have write permissions (avoids sudo password hangs on SDDM)
#     if [ -f "$file" ] && [ -w "$file" ]; then
#         # Looks for {"color": "#abcdef"} and replaces it with #abcdef
#         sed -i -E 's/\{[[:space:]]*"color":[[:space:]]*"([^"]+)"[[:space:]]*\}/\1/g' "$file"
#     elif [ -f "$file" ]; then
#         echo "Warning: No write permission for $file (Skipping text clean-up)"
#     fi
# done

# # ------------------------------------------------------------------------------
# # 3. Reload System Components
# # ------------------------------------------------------------------------------

# # Reload Kitty instances
# killall -USR1 kitty

# # Reload CAVA
# # ALWAYS rebuild the final config file from the base and newly generated colors
# cat ~/.config/cava/config_base ~/.config/cava/colors > ~/.config/cava/config 2>/dev/null

# # Tell CAVA to reload the config ONLY if it is currently running
# if pgrep -x "cava" > /dev/null; then
#     killall -USR1 cava
# fi

# # Restart swayosd-server in the background and disown it so the script doesn't hang
# killall swayosd-server 2>/dev/null
# swayosd-server --top-margin 0.9 --style "$HOME/.config/swayosd/style.css" > /dev/null 2>&1 &
# disown

# # GTK Live-Reload Hack
# # Rapidly toggles the global theme to force GTK3 and GTK4 apps to flush 
# # their caches and read the newly generated Matugen CSS.
# if command -v gsettings &> /dev/null; then
#     # GTK3 apps
#     gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
#     sleep 0.05
#     gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    
#     # GTK4 / Libadwaita apps
#     gsettings set org.gnome.desktop.interface color-scheme 'default'
#     sleep 0.05
#     gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
# fi




#!/usr/bin/env bash                                                              # Shebang line: uses env to find bash interpreter for maximum portability across systems

# ------------------------------------------------------------------------------ # Visual divider for section 1
# 1. Flatten Matugen v4.0 Nested JSON for Quickshell                              # Section header: converts nested matugen JSON structure to flat key-value pairs
# ------------------------------------------------------------------------------ # Visual divider closing the section header
# Updated to match your config.toml output path                                    # Comment noting the path matches the matugen configuration
QS_JSON="~/.config/hypr/scripts/quickshell/qs_colors.json"                        # Defines the path to the Quickshell colors JSON file (tilde will be expanded later)

python3 -c '                                                                      # Runs Python inline script with the following code passed as a string argument
import json                                                                       # Python: imports json module for parsing and writing JSON data
import sys                                                                        # Python: imports sys module for accessing command-line arguments

def flatten_colors(obj):                                                          # Python: defines recursive function that flattens nested color objects
    if isinstance(obj, dict):                                                     # If the current object is a dictionary
        if "color" in obj and isinstance(obj["color"], str):                      # If dict has a "color" key whose value is a string (like {"color": "#hex"})
            return obj["color"]                                                   # Return just the color hex string, discarding the wrapper object
        return {k: flatten_colors(v) for k, v in obj.items()}                     # Otherwise recursively process each key-value pair in the dictionary
    elif isinstance(obj, list):                                                   # If the current object is a list
        return [flatten_colors(x) for x in obj]                                   # Recursively process each element in the list
    return obj                                                                    # Return the object unchanged if it is neither dict nor list (base case)

target_file = sys.argv[1]                                                         # Gets the target file path from the first command-line argument
try:                                                                              # Python try block for file operations
    with open(target_file, "r") as f:                                             # Opens the target file in read mode
        data = json.load(f)                                                       # Loads and parses the JSON content into Python objects
    
    flat_data = flatten_colors(data)                                              # Calls the flatten function to convert nested structure to flat key-value pairs
    
    with open(target_file, "w") as f:                                             # Opens the same file in write mode (overwrites original)
        json.dump(flat_data, f, indent=4)                                         # Writes the flattened data back as formatted JSON with 4-space indentation
        
except FileNotFoundError:                                                         # Catches if the target file does not exist
    pass                                                                          # Silently ignore missing file (no colors to flatten)
except Exception as e:                                                            # Catches any other error during processing
    print(f"Error flattening JSON: {e}")                                          # Prints error message to stderr for debugging
' "$QS_JSON"                                                                      # Passes the QS_JSON file path as argument to the Python script (bash expands the tilde)

# ------------------------------------------------------------------------------ # Visual divider for section 2
# 2. Flatten Matugen v4.0 Output in Standard Text Configs                          # Section header: removes JSON wrapper from color values in various config files
# ------------------------------------------------------------------------------ # Visual divider closing the section header
# If Tera dumped {"color": "#hex"} into your text files, this strips it to #hex.  # Comment explaining that matugen's Tera templates may have left JSON fragments
TEXT_FILES=(                                                                      # Begins a bash array containing paths to all config files that need cleaning
    "$HOME/.config/hypr/scripts/quickshell/qs_colors.json"                        # Quickshell colors JSON file
    "$HOME/.config/kitty/kitty-matugen-colors.conf"                               # Kitty terminal emulator color configuration
    "$HOME/.config/nvim/matugen_colors.lua"                                       # Neovim editor color configuration (Lua format)
    "$HOME/.config/cava/colors"                                                   # CAVA audio visualizer color configuration
    "$HOME/.config/swayosd/style.css"                                             # SwayOSD on-screen display style CSS
    "$HOME/.config/rofi/theme.rasi"                                               # Rofi application launcher theme file
    "$HOME/.cache/matugen/colors-gtk.css"                                         # GTK color CSS generated by matugen in cache
    "$HOME/.config/qt5ct/colors/matugen.conf"                                     # Qt5 Configuration Tool color settings
    "$HOME/.config/qt6ct/colors/matugen.conf"                                     # Qt6 Configuration Tool color settings
    "$HOME/.config/qt5ct/qss/matugen-style.qss"                                   # Qt5 Style Sheet with matugen colors
    "$HOME/.config/qt6ct/qss/matugen-style.qss"                                   # Qt6 Style Sheet with matugen colors
    "$HOME/.config/hypr/colors.conf"                                              # Hyprland compositor color configuration
)

for file in "${TEXT_FILES[@]}"; do                                                # Iterates through each file path in the TEXT_FILES array
    # Check if file exists and we have write permissions (avoids sudo password hangs on SDDM) # Comment explaining the permission check prevents display manager issues
    if [ -f "$file" ] && [ -w "$file" ]; then                                     # Checks if file exists (-f) AND is writable (-w) by current user
        # Looks for {"color": "#abcdef"} and replaces it with #abcdef              # Comment describing the sed replacement pattern
        sed -i -E 's/\{[[:space:]]*"color":[[:space:]]*"([^"]+)"[[:space:]]*\}/\1/g' "$file" # Uses sed with extended regex (-E) to find JSON color objects and replace with just the hex value; \1 is the captured hex string
    elif [ -f "$file" ]; then                                                     # If file exists but is NOT writable
        echo "Warning: No write permission for $file (Skipping text clean-up)"    # Prints warning message indicating the file was skipped
    fi
done

# ------------------------------------------------------------------------------ # Visual divider for section 3
# 3. Reload System Components                                                     # Section header: restarts/refreshes applications to pick up new color scheme
# ------------------------------------------------------------------------------ # Visual divider closing the section header

# Reload Kitty instances                                                          # Comment for kitty terminal reload
killall -USR1 kitty                                                               # Sends USR1 signal to all kitty processes, which tells kitty to reload its configuration

# Reload CAVA                                                                     # Comment for CAVA audio visualizer reload
# ALWAYS rebuild the final config file from the base and newly generated colors    # Comment explaining config rebuilding strategy
cat ~/.config/cava/config_base ~/.config/cava/colors > ~/.config/cava/config 2>/dev/null # Concatenates the base CAVA config with the new colors file, writes to final config; suppresses errors

# Tell CAVA to reload the config ONLY if it is currently running                   # Comment explaining conditional reload
if pgrep -x "cava" > /dev/null; then                                              # Checks if a process named exactly "cava" is running (pgrep -x for exact match)
    killall -USR1 cava                                                            # Sends USR1 signal to CAVA to reload its configuration without restarting
fi

# Restart swayosd-server in the background and disown it so the script does not hang # Comment explaining the background restart approach
killall swayosd-server 2>/dev/null                                                # Kills any existing swayosd-server process, suppressing error if not running
swayosd-server --top-margin 0.9 --style "$HOME/.config/swayosd/style.css" > /dev/null 2>&1 & # Starts swayosd-server with 90% top margin and new style, redirecting output to null, running in background (&)
disown                                                                            # Removes the background swayosd-server process from the shell's job table so it won't be killed when the script exits

# GTK Live-Reload Hack                                                            # Comment for GTK theme live reload workaround
# Rapidly toggles the global theme to force GTK3 and GTK4 apps to flush            # Comment explaining the toggle trick forces GTK to re-read CSS
# their caches and read the newly generated Matugen CSS.                           # Continuation of explanation
if command -v gsettings &> /dev/null; then                                        # Checks if gsettings command is available (GNOME/GTK settings tool)
    # GTK3 apps                                                                   # Comment for GTK3 applications
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'                  # Temporarily switches GTK theme to default Adwaita
    sleep 0.05                                                                    # Waits 50 milliseconds for the change to propagate
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'           # Switches back to the desired dark GTK3 theme (forces cache flush)
    
    # GTK4 / Libadwaita apps                                                      # Comment for GTK4/Libadwaita applications
    gsettings set org.gnome.desktop.interface color-scheme 'default'               # Temporarily sets color scheme to default (light)
    sleep 0.05                                                                    # Brief 50ms pause for setting to take effect
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'           # Switches back to dark preference (forces GTK4 to re-read CSS)
fi                                                                                # End of gsettings conditional block