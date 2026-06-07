#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Parse arguments
for arg in "$@"; do
    if [ "$arg" = "--auto-theme" ]; then
        AUTO_THEME=true
    else
        WALLPAPER="$arg"
    fi
done

# If no image specified, pick random
if [ -z "$WALLPAPER" ]; then
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | shuf -n 1)
fi

if [ ! -f "$WALLPAPER" ]; then
    echo "Error: Image not found: $WALLPAPER"
    exit 1
fi

echo "Setting wallpaper: $WALLPAPER"

awww img "$WALLPAPER" --transition-type any --transition-fps 60

# Generate colors with auto-preference
if [ "$AUTO_THEME" = true ]; then
    matugen image "$WALLPAPER" --mode dark --prefer lightness
else
    matugen image "$WALLPAPER"
fi

# #!/usr/bin/env bash

# WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# # If argument provided, use that image; otherwise pick random
# if [ -n "$1" ]; then
#     WALLPAPER="$1"
# else
#     WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | shuf -n 1)
# fi

# if [ ! -f "$WALLPAPER" ]; then
#     echo "Error: Image not found: $WALLPAPER"
#     exit 1
# fi

# echo "Setting wallpaper: $WALLPAPER"

# awww img "$WALLPAPER" --transition-type any --transition-fps 60

# matugen image "$WALLPAPER"

# echo "Done!"
