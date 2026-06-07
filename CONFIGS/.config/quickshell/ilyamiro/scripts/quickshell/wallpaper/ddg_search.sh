# #!/usr/bin/env bash

# QUERY="$1"
# SCRIPT_DIR="$(dirname "$(realpath "$0")")"
# CACHE_DIR="$HOME/.cache/wallpaper_picker"
# SEARCH_DIR="$CACHE_DIR/search_thumbs"
# MAP_FILE="$CACHE_DIR/search_map.txt"
# CONTROL_FILE="/tmp/ddg_search_control"
# LOG_FILE="/tmp/qs_ddg_downloader.log"

# echo "=== Starting search for: $QUERY ===" > "$LOG_FILE"

# # 1. Guarantee directory exists
# mkdir -p "$SEARCH_DIR"

# # 2. The Pipe: Python provides links, OS provides backpressure
# python3 -u "$SCRIPT_DIR/get_ddg_links.py" "$QUERY" | while IFS='|' read -r thumb_url full_url; do
    
#     # 3. Safely read control file
#     state=$(cat "$CONTROL_FILE" 2>/dev/null | tr -d '[:space:]')
    
#     if [[ "$state" == "stop" ]]; then 
#         echo "Stop signal received. Exiting." >> "$LOG_FILE"
#         exit 0 
#     fi
    
#     while [[ "$state" == "pause" ]]; do
#         sleep 1
#         state=$(cat "$CONTROL_FILE" 2>/dev/null | tr -d '[:space:]')
#     done

#     if [ -z "$thumb_url" ] || [ -z "$full_url" ]; then continue; fi

#     # =========================================================================
#     # PRE-FLIGHT CHECK ON THE FULL URL
#     # =========================================================================
#     target_headers=$(curl -s -I -L -m 3 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "$full_url")
#     target_type=$(echo "$target_headers" | grep -i "content-type:" | tail -n 1 | tr -d '\r')

#     if [[ ! "$target_type" =~ "image/" ]]; then
#         echo "Skip: Full URL is dead or HTML ($target_type) -> $full_url" >> "$LOG_FILE"
#         continue
#     fi
#     # =========================================================================

#     uuid=$(date +%s%N)
#     ext="${full_url##*.}"
#     ext="${ext%%\?*}"
#     ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
#     if [[ ! "$ext" =~ ^(jpg|jpeg|png|webp|gif)$ ]]; then ext="jpg"; fi

#     is_webp=0
#     if [[ "$ext" == "webp" ]]; then
#         is_webp=1
#         ext="jpg"
#     fi

#     filename="ddg_${uuid}.${ext}"
#     filepath="$SEARCH_DIR/$filename"
#     tmppath="${filepath}.tmp"

#     echo "Downloading Thumb: $thumb_url -> $filename" >> "$LOG_FILE"

#     # 4. TIMEOUT ADDED: -m 5 prevents permanent freezing on stalled connections
#     curl -s -L -m 5 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "$thumb_url" -o "$tmppath"

#     # 5. Check state again AFTER the curl block
#     state=$(cat "$CONTROL_FILE" 2>/dev/null | tr -d '[:space:]')
#     if [[ "$state" == "stop" ]]; then 
#         echo "Stop signal received during download. Discarding." >> "$LOG_FILE"
#         rm -f "$tmppath"
#         exit 0 
#     fi

#     # 6. Verify the thumbnail itself is valid and not corrupted
#     if [ -s "$tmppath" ]; then
#         actual_mime=$(file -b --mime-type "$tmppath")
        
#         if [[ ! "$actual_mime" =~ ^image/ ]]; then
#             echo "ERROR: Thumb is not an image ($actual_mime). Discarding." >> "$LOG_FILE"
#             rm -f "$tmppath"
#         else
#             if [[ "$actual_mime" == "image/webp" ]] || [ $is_webp -eq 1 ]; then
#                 magick "$tmppath" "$filepath" 2>/dev/null || mv "$tmppath" "$filepath"
#                 rm -f "$tmppath"
#             else
#                 mv "$tmppath" "$filepath"
#             fi
#             echo "$filename|$full_url" >> "$MAP_FILE"
#             echo "Success: $filename saved." >> "$LOG_FILE"
#         fi
#     else
#         echo "ERROR: Failed or empty download for $thumb_url" >> "$LOG_FILE"
#         rm -f "$tmppath"
#     fi
# done

# echo "=== Pipeline finished ===" >> "$LOG_FILE"


#!/usr/bin/env bash                                                              # Shebang line: uses env to find bash interpreter for maximum portability

QUERY="$1"                                                                       # Assigns the first command-line argument to QUERY variable (the search term for wallpapers)
SCRIPT_DIR="$(dirname "$(realpath "$0")")"                                       # Gets the absolute directory path where this script is located by resolving symlinks and extracting dirname
CACHE_DIR="$HOME/.cache/wallpaper_picker"                                        # Defines the base cache directory path for the wallpaper picker under user's home
SEARCH_DIR="$CACHE_DIR/search_thumbs"                                            # Defines the subdirectory where downloaded thumbnail images will be stored
MAP_FILE="$CACHE_DIR/search_map.txt"                                             # Defines the path to the mapping file that stores thumbnail-filename to full-URL pairs
CONTROL_FILE="/tmp/ddg_search_control"                                           # Defines the path to a control file used for pause/stop signals between processes
LOG_FILE="/tmp/qs_ddg_downloader.log"                                            # Defines the path to a log file for debugging and status tracking

echo "=== Starting search for: $QUERY ===" > "$LOG_FILE"                         # Writes a header to the log file indicating search start with the query term (overwrites existing log)

# 1. Guarantee directory exists                                                 # Comment explaining the purpose of the next line
mkdir -p "$SEARCH_DIR"                                                           # Creates the search thumbnails directory if it doesn't exist (creates parent dirs too)

# 2. The Pipe: Python provides links, OS provides backpressure                    # Comment explaining the pipeline architecture
python3 -u "$SCRIPT_DIR/get_ddg_links.py" "$QUERY" | while IFS='|' read -r thumb_url full_url; do # Runs Python script with unbuffered output (-u), pipes results; reads each line split by '|' into thumb_url and full_url variables
    
    # 3. Safely read control file                                                 # Comment explaining the control file check
    state=$(cat "$CONTROL_FILE" 2>/dev/null | tr -d '[:space:]')                 # Reads the control file silently (ignoring errors if not found), removes all whitespace characters
    
    if [[ "$state" == "stop" ]]; then                                             # Checks if the control file contains "stop"
        echo "Stop signal received. Exiting." >> "$LOG_FILE"                     # Logs the stop signal to the log file
        exit 0                                                                   # Exits the script immediately with success code (0)
    fi
    
    while [[ "$state" == "pause" ]]; do                                           # Loops while the control file contains "pause" (blocks processing)
        sleep 1                                                                  # Waits for 1 second before checking again to avoid CPU spinning
        state=$(cat "$CONTROL_FILE" 2>/dev/null | tr -d '[:space:]')             # Re-reads the control file to check if pause state has changed
    done

    if [ -z "$thumb_url" ] || [ -z "$full_url" ]; then continue; fi              # If either thumbnail URL or full URL is empty, skip this iteration and continue with next line

    # =========================================================================  # Visual divider for the pre-flight URL check section
    # PRE-FLIGHT CHECK ON THE FULL URL                                            # Comment explaining the URL validation step
    # =========================================================================  # Visual divider closing the section header
    target_headers=$(curl -s -I -L -m 3 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "$full_url") # Fetches only HTTP headers (-I) from the full URL, following redirects (-L), with 3-second timeout (-m 3), using a browser User-Agent
    target_type=$(echo "$target_headers" | grep -i "content-type:" | tail -n 1 | tr -d '\r') # Extracts the Content-Type header (case-insensitive grep), takes the last occurrence (after redirects), removes carriage returns

    if [[ ! "$target_type" =~ "image/" ]]; then                                   # Checks if the Content-Type does NOT contain "image/" (not a valid image)
        echo "Skip: Full URL is dead or HTML ($target_type) -> $full_url" >> "$LOG_FILE" # Logs the skip with the invalid content type and URL
        continue                                                                 # Skips to the next iteration (doesn't download this thumbnail)
    fi
    # =========================================================================  # End of pre-flight check section

    uuid=$(date +%s%N)                                                           # Generates a unique identifier using seconds and nanoseconds since epoch
    ext="${full_url##*.}"                                                        # Extracts the file extension by removing everything before the last dot in the URL
    ext="${ext%%\?*}"                                                            # Removes any query parameters from the extension (everything after '?')
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')                              # Converts the extension to lowercase for consistency
    if [[ ! "$ext" =~ ^(jpg|jpeg|png|webp|gif)$ ]]; then ext="jpg"; fi           # If the extension isn't a supported image format, defaults to "jpg"

    is_webp=0                                                                     # Initializes a flag to track if the original was webp format (0 = no, 1 = yes)
    if [[ "$ext" == "webp" ]]; then                                               # If the extension is webp
        is_webp=1                                                                # Sets the webp flag to 1
        ext="jpg"                                                                # Changes extension to jpg (will be converted from webp)
    fi

    filename="ddg_${uuid}.${ext}"                                                # Constructs the filename using "ddg_" prefix, unique uuid, and extension
    filepath="$SEARCH_DIR/$filename"                                             # Constructs the full file path in the search thumbs directory
    tmppath="${filepath}.tmp"                                                    # Creates a temporary file path by appending ".tmp" (used during download)

    echo "Downloading Thumb: $thumb_url -> $filename" >> "$LOG_FILE"              # Logs the download attempt with thumbnail URL and target filename

    # 4. TIMEOUT ADDED: -m 5 prevents permanent freezing on stalled connections    # Comment explaining the curl timeout parameter
    curl -s -L -m 5 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "$thumb_url" -o "$tmppath" # Downloads thumbnail silently, following redirects, 5-second timeout, browser User-Agent, saves to temp file

    # 5. Check state again AFTER the curl block                                   # Comment explaining post-download control check
    state=$(cat "$CONTROL_FILE" 2>/dev/null | tr -d '[:space:]')                 # Reads control file again after download completes
    if [[ "$state" == "stop" ]]; then                                             # If stop signal was set during download
        echo "Stop signal received during download. Discarding." >> "$LOG_FILE"   # Logs the discard message
        rm -f "$tmppath"                                                         # Removes the partially downloaded temporary file
        exit 0                                                                   # Exits the script
    fi

    # 6. Verify the thumbnail itself is valid and not corrupted                    # Comment explaining thumbnail validation
    if [ -s "$tmppath" ]; then                                                    # Checks if the temp file exists and has non-zero size (-s means "size > 0")
        actual_mime=$(file -b --mime-type "$tmppath")                             # Uses the 'file' command to detect the actual MIME type of the downloaded file
        
        if [[ ! "$actual_mime" =~ ^image/ ]]; then                                # If the actual MIME type is not an image format
            echo "ERROR: Thumb is not an image ($actual_mime). Discarding." >> "$LOG_FILE" # Logs the error with the detected MIME type
            rm -f "$tmppath"                                                     # Removes the invalid temporary file
        else                                                                      # If the file is a valid image
            if [[ "$actual_mime" == "image/webp" ]] || [ $is_webp -eq 1 ]; then   # If the file is webp or was originally webp
                magick "$tmppath" "$filepath" 2>/dev/null || mv "$tmppath" "$filepath" # Converts webp to jpg using ImageMagick, falls back to just renaming if conversion fails
                rm -f "$tmppath"                                                 # Removes the temporary file after conversion
            else                                                                  # If not webp
                mv "$tmppath" "$filepath"                                        # Simply renames/moves the temp file to the final filename
            fi
            echo "$filename|$full_url" >> "$MAP_FILE"                             # Appends the mapping entry (filename and full URL separated by '|') to the map file
            echo "Success: $filename saved." >> "$LOG_FILE"                       # Logs successful save
        fi
    else                                                                          # If the temp file is empty or doesn't exist
        echo "ERROR: Failed or empty download for $thumb_url" >> "$LOG_FILE"      # Logs the download failure
        rm -f "$tmppath"                                                         # Removes any empty/corrupted temp file
    fi
done

echo "=== Pipeline finished ===" >> "$LOG_FILE"                                   # Logs pipeline completion marker to the log file