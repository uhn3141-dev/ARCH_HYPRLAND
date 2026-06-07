# #!/usr/bin/env python3
# import subprocess
# import json
# import os
# import sys
# import threading

# def cleanup_cache(all_lines, cache_dir):
#     valid_ids = set()
#     # Keep top 100 recent IDs to prevent infinite cache bloat
#     for line in all_lines[:100]:
#         if '\t' in line:
#             valid_ids.add(line.split('\t', 1)[0])
            
#     try:
#         for f in os.listdir(cache_dir):
#             if f.endswith('.png'):
#                 iid = f.replace('.png', '')
#                 if iid not in valid_ids:
#                     try:
#                         os.remove(os.path.join(cache_dir, f))
#                     except Exception:
#                         pass
#     except Exception:
#         pass

# def get_cliphist():
#     # Implement pagination arguments
#     offset = int(sys.argv[1]) if len(sys.argv) > 1 else 0
#     # Slightly smaller limit to make the initial UI pop open faster
#     limit = int(sys.argv[2]) if len(sys.argv) > 2 else 12 
    
#     cache_dir = "/tmp/qs_cliphist"
#     os.makedirs(cache_dir, exist_ok=True)
    
#     try:
#         # Fetch the entire list quickly
#         result = subprocess.run(["cliphist", "list"], capture_output=True, text=True)
#         all_lines = result.stdout.strip().split('\n')
        
#         # Slice only the requested chunk
#         lines = all_lines[offset:offset+limit]
        
#         # Move cleanup to a background thread so it doesn't block the UI from receiving data
#         if offset == 0:
#             threading.Thread(target=cleanup_cache, args=(all_lines, cache_dir), daemon=True).start()

#     except Exception as e:
#         print("[]")
#         return

#     items = []
#     for line in lines:
#         if not line: continue
#         parts = line.split('\t', 1)
#         if len(parts) != 2: continue
        
#         iid, content = parts[0], parts[1]
#         item_type = "text"
#         display_content = content.strip()

#         # Detect images in cliphist output
#         if "[[ binary data" in content:
#             item_type = "image"
#             img_path = os.path.join(cache_dir, f"{iid}.png")
            
#             # CACHING: Only decode the specific item if it doesn't already exist
#             if not os.path.exists(img_path):
#                 with open(img_path, "wb") as f:
#                     subprocess.run(["cliphist", "decode", iid], stdout=f)
#             display_content = img_path

#         items.append({
#             "id": iid,
#             "content": display_content,
#             "type": item_type
#         })

#     print(json.dumps(items))

# if __name__ == "__main__":
#     get_cliphist()



#!/usr/bin/env python3                                                                                      # Shebang line: tells the system to execute this script using the python3 interpreter from PATH
import subprocess                                                                                            # Imports subprocess module for spawning external processes (like cliphist) and capturing their output
import json                                                                                                  # Imports json module for serializing Python objects into JSON format for the QML frontend to consume
import os                                                                                                    # Imports os module for filesystem operations (directory creation, file existence checks, path manipulation)
import sys                                                                                                   # Imports sys module for accessing command-line arguments (argv) passed to the script
import threading                                                                                             # Imports threading module for running cleanup operations in background daemon threads

def cleanup_cache(all_lines, cache_dir):                                                                     # Defines a function to remove cached image files that are no longer in the recent clipboard history
    valid_ids = set()                                                                                        # Creates an empty set to store the IDs of clipboard items that should be kept (fast O(1) lookup)
    # Keep top 100 recent IDs to prevent infinite cache bloat                                                # Comment explaining the cache strategy: only the 100 most recent items are preserved
    for line in all_lines[:100]:                                                                             # Iterates through only the first 100 lines of clipboard history (most recent entries)
        if '\t' in line:                                                                                     # Checks if the line contains a tab character (cliphist format: ID\tcontent)
            valid_ids.add(line.split('\t', 1)[0])                                                            # Extracts the item ID (before the first tab) and adds it to the valid_ids set
            
    try:                                                                                                     # Begins a try block to catch any filesystem errors during cache cleanup
        for f in os.listdir(cache_dir):                                                                      # Iterates through all files in the cache directory
            if f.endswith('.png'):                                                                           # Checks if the filename ends with '.png' (cached image files)
                iid = f.replace('.png', '')                                                                  # Extracts the item ID by removing the '.png' extension from the filename
                if iid not in valid_ids:                                                                     # Checks if this ID is NOT in the set of valid IDs (i.e., it's an old/stale cache entry)
                    try:                                                                                     # Begins inner try block for individual file removal
                        os.remove(os.path.join(cache_dir, f))                                                # Deletes the stale cached image file from the cache directory
                    except Exception:                                                                        # Catches any exception during file deletion (e.g., permission error, file already deleted)
                        pass                                                                                 # Silently ignores individual file deletion failures
    except Exception:                                                                                        # Catches any exception during directory listing (e.g., directory doesn't exist, permission denied)
        pass                                                                                                 # Silently ignores cleanup failures - cleanup is non-critical

def get_cliphist():                                                                                          # Defines the main function that retrieves clipboard history from cliphist and returns it as JSON
    # Implement pagination arguments                                                                         # Comment: the script supports pagination via command-line arguments
    offset = int(sys.argv[1]) if len(sys.argv) > 1 else 0                                                    # Reads the first command-line argument as the pagination offset (starting index), defaults to 0
    # Slightly smaller limit to make the initial UI pop open faster                                          # Comment explaining the default limit choice for responsive UI
    limit = int(sys.argv[2]) if len(sys.argv) > 2 else 12                                                    # Reads the second command-line argument as the page size, defaults to 12 items per page
    
    cache_dir = "/tmp/qs_cliphist"                                                                           # Defines the directory path where decoded clipboard images are cached as PNG files
    os.makedirs(cache_dir, exist_ok=True)                                                                    # Creates the cache directory (and any parent directories) if it doesn't exist; no error if it already exists
    
    try:                                                                                                     # Begins a try block to catch any errors during the cliphist command execution
        # Fetch the entire list quickly                                                                      # Comment: cliphist list is fast even with many entries
        result = subprocess.run(["cliphist", "list"], capture_output=True, text=True)                        # Runs 'cliphist list' command, captures its stdout and stderr as text strings
        all_lines = result.stdout.strip().split('\n')                                                        # Strips trailing whitespace from output and splits into a list of lines
        
        # Slice only the requested chunk                                                                     # Comment: we only process the page requested by offset/limit
        lines = all_lines[offset:offset+limit]                                                               # Extracts only the slice of lines for the current page (from offset to offset+limit)
        
        # Move cleanup to a background thread so it doesn't block the UI from receiving data                 # Comment: cleanup runs asynchronously to keep UI responsive
        if offset == 0:                                                                                      # Only triggers cleanup when requesting the first page (offset 0) to avoid redundant cleanups
            threading.Thread(target=cleanup_cache, args=(all_lines, cache_dir), daemon=True).start()         # Creates and starts a daemon thread that runs cleanup_cache; daemon=True means it won't block program exit

    except Exception as e:                                                                                   # Catches any exception from subprocess.run or the initial processing
        print("[]")                                                                                          # Outputs an empty JSON array to indicate no clipboard data is available
        return                                                                                               # Exits the function early since there's no data to process

    items = []                                                                                               # Initializes an empty list to store the processed clipboard item dictionaries
    for line in lines:                                                                                       # Iterates through each line in the current page of clipboard history
        if not line: continue                                                                                # Skips empty lines (blank lines in output)
        parts = line.split('\t', 1)                                                                          # Splits the line into at most 2 parts at the first tab character (ID and content)
        if len(parts) != 2: continue                                                                         # Skips lines that don't have exactly 2 parts after splitting (malformed entries)
        
        iid, content = parts[0], parts[1]                                                                    # Unpacks the first part as item ID and second part as the content/description
        item_type = "text"                                                                                   # Default item type is "text" for plain text clipboard entries
        display_content = content.strip()                                                                    # Strips leading/trailing whitespace from the content for display

        # Detect images in cliphist output                                                                   # Comment: cliphist marks binary data entries with a specific string
        if "[[ binary data" in content:                                                                      # Checks if the content contains the cliphist binary data indicator string
            item_type = "image"                                                                              # Changes the item type to "image" for binary/image clipboard entries
            img_path = os.path.join(cache_dir, f"{iid}.png")                                                 # Constructs the full path for the cached image file using the item ID
            
            # CACHING: Only decode the specific item if it doesn't already exist                             # Comment: avoids redundant image decoding for already-cached items
            if not os.path.exists(img_path):                                                                 # Checks if the PNG file for this item doesn't already exist in cache
                with open(img_path, "wb") as f:                                                              # Opens the image file for writing in binary mode
                    subprocess.run(["cliphist", "decode", iid], stdout=f)                                    # Decodes the clipboard image item and pipes the PNG output directly to the file
            display_content = img_path                                                                       # Sets the display content to the cached image file path (QML will use this as image source)

        items.append({                                                                                       # Appends a dictionary representing this clipboard item to the items list
            "id": iid,                                                                                       # Stores the clipboard item ID for reference
            "content": display_content,                                                                      # Stores either the text content or the path to the cached image
            "type": item_type                                                                                # Stores the type of clipboard entry ("text" or "image")
        })

    print(json.dumps(items))                                                                                 # Serializes the entire items list to a JSON string and prints to stdout for QML consumption

if __name__ == "__main__":                                                                                   # Python idiom: checks if this script is being executed directly (not imported as a module)
    get_cliphist()                                                                                           # Calls the main function to execute the clipboard history retrieval logic