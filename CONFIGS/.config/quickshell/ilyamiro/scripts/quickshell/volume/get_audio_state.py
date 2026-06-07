# #!/usr/bin/env python3
# import subprocess
# import json
# import sys

# def run_cmd(cmd):
#     try:
#         return subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL).decode('utf-8')
#     except:
#         return "[]"

# def parse_pactl(output):
#     try:
#         return json.loads(output)
#     except:
#         return []

# def get_valid_string(*args):
#     """Safely return the first valid string that isn't 'null' or empty."""
#     for arg in args:
#         if arg and str(arg).strip().lower() not in ["null", "none", ""]:
#             return str(arg)
#     return ""

# def get_data():
#     sinks = parse_pactl(run_cmd("pactl -f json list sinks"))
#     sources = parse_pactl(run_cmd("pactl -f json list sources"))
#     sink_inputs = parse_pactl(run_cmd("pactl -f json list sink-inputs"))
    
#     # Get defaults
#     try:
#         info = parse_pactl(run_cmd("pactl -f json info"))
#         default_sink = info.get("default_sink_name", "")
#         default_source = info.get("default_source_name", "")
#     except:
#         default_sink = ""
#         default_source = ""

#     def format_node(n, is_default=False, is_app=False):
#         # Extract volume gracefully
#         vol = 0
#         if "volume" in n and isinstance(n["volume"], dict):
#             if "front-left" in n["volume"]:
#                 vol = int(n["volume"]["front-left"].get("value_percent", "0%").strip("%"))
#             elif "mono" in n["volume"]:
#                 vol = int(n["volume"]["mono"].get("value_percent", "0%").strip("%"))

#         props = n.get("properties", {})
        
#         if is_app:
#             display_name = get_valid_string(props.get("application.name"), props.get("application.process.binary"), "Unknown App")
#             sub_desc = get_valid_string(props.get("media.name"), props.get("window.title"), props.get("media.role"), "Audio Stream")
#         else:
#             display_name = get_valid_string(props.get("device.description"), n.get("name"), "Unknown Device")
#             sub_desc = get_valid_string(n.get("name"), "Unknown")

#         icon = get_valid_string(props.get("application.icon_name"), props.get("device.icon_name"), "audio-card")
        
#         return {
#             "id": str(n.get("index")),
#             "name": sub_desc,
#             "description": display_name,
#             "volume": vol,
#             "mute": bool(n.get("mute", False)),
#             "is_default": bool(is_default),
#             "icon": icon
#         }

#     # Filter out empty apps/system sounds
#     apps = []
#     for s in sink_inputs:
#         props = s.get("properties", {})
#         if props.get("application.id") != "org.PulseAudio.pavucontrol":
#             apps.append(format_node(s, is_app=True))

#     out = {
#         "outputs": [format_node(s, s.get("name") == default_sink) for s in sinks],
#         "inputs": [format_node(s, s.get("name") == default_source) for s in sources],
#         "apps": apps
#     }
    
#     print(json.dumps(out))

# if __name__ == "__main__":
#     get_data()
#!/usr/bin/env python3                                                           # Shebang line: uses env to find python3 interpreter for portability across systems
import subprocess                                                                 # Imports subprocess module for executing shell commands and capturing their output
import json                                                                       # Imports json module for parsing and generating JSON data structures
import sys                                                                        # Imports sys module for system-specific parameters (though not directly used here)

def run_cmd(cmd):                                                                 # Defines helper function that executes a shell command and returns its output as string
    try:                                                                          # Try block to attempt command execution
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL).decode('utf-8') # Runs command via shell, suppresses stderr by sending to /dev/null, decodes bytes to UTF-8 string
    except:                                                                       # Catches any exception if command fails (non-zero exit, command not found, etc.)
        return "[]"                                                               # Returns empty JSON array string as fallback so parsing doesn't crash

def parse_pactl(output):                                                          # Defines helper function that parses JSON output from pactl commands
    try:                                                                          # Try block to attempt JSON parsing
        return json.loads(output)                                                 # Parses the JSON string into Python objects (list or dict)
    except:                                                                       # Catches JSON decode errors or any other parsing exceptions
        return []                                                                 # Returns empty list as safe fallback for malformed output

def get_valid_string(*args):                                                      # Defines helper function that returns the first valid non-empty string from arguments
    """Safely return the first valid string that isn't 'null' or empty."""        # Docstring explaining function purpose: filters out null/none/empty values
    for arg in args:                                                              # Iterates through all positional arguments passed to the function
        if arg and str(arg).strip().lower() not in ["null", "none", ""]:          # Checks if argument exists, is not "null"/"none"/empty after trimming and lowercasing
            return str(arg)                                                       # Returns the first valid string found
    return ""                                                                     # Returns empty string if no valid argument was found

def get_data():                                                                   # Main function that collects and formats all audio device information
    sinks = parse_pactl(run_cmd("pactl -f json list sinks"))                      # Gets list of audio outputs (sinks) by running pactl with JSON output format, then parsing
    sources = parse_pactl(run_cmd("pactl -f json list sources"))                  # Gets list of audio inputs (sources/microphones) in JSON format from pactl
    sink_inputs = parse_pactl(run_cmd("pactl -f json list sink-inputs"))          # Gets list of applications playing audio (sink-inputs) in JSON format from pactl
    
    # Get defaults                                                                 # Comment indicating next section fetches default device names
    try:                                                                          # Try block for getting default device information
        info = parse_pactl(run_cmd("pactl -f json info"))                         # Gets general PulseAudio/PipeWire server info in JSON format
        default_sink = info.get("default_sink_name", "")                          # Extracts the default output device name from info dict, defaults to empty string
        default_source = info.get("default_source_name", "")                      # Extracts the default input device name from info dict, defaults to empty string
    except:                                                                       # Catches any exception if getting server info fails
        default_sink = ""                                                         # Sets default sink to empty string as fallback
        default_source = ""                                                       # Sets default source to empty string as fallback

    def format_node(n, is_default=False, is_app=False):                           # Defines nested helper function that formats a single audio device/application into a consistent dict
        # Extract volume gracefully                                                # Comment indicating careful volume extraction with fallbacks
        vol = 0                                                                   # Initializes volume to 0 as default
        if "volume" in n and isinstance(n["volume"], dict):                       # Checks if volume key exists and is a dictionary (not a simple type)
            if "front-left" in n["volume"]:                                       # Checks for front-left channel (stereo left)
                vol = int(n["volume"]["front-left"].get("value_percent", "0%").strip("%")) # Extracts percentage string, removes % sign, converts to integer
            elif "mono" in n["volume"]:                                           # Falls back to mono channel if no front-left
                vol = int(n["volume"]["mono"].get("value_percent", "0%").strip("%")) # Extracts mono volume percentage and converts to integer

        props = n.get("properties", {})                                           # Gets the properties dictionary from the device node, defaults to empty dict
        
        if is_app:                                                                # Branch for application audio streams (sink-inputs)
            display_name = get_valid_string(props.get("application.name"), props.get("application.process.binary"), "Unknown App") # Tries to get app name, then process binary name, falls back to "Unknown App"
            sub_desc = get_valid_string(props.get("media.name"), props.get("window.title"), props.get("media.role"), "Audio Stream") # Tries media name, window title, media role, falls back to "Audio Stream"
        else:                                                                     # Branch for physical/virtual audio devices (sinks/sources)
            display_name = get_valid_string(props.get("device.description"), n.get("name"), "Unknown Device") # Tries device description, then internal name, falls back to "Unknown Device"
            sub_desc = get_valid_string(n.get("name"), "Unknown")                 # Uses device name as sub description, falls back to "Unknown"

        icon = get_valid_string(props.get("application.icon_name"), props.get("device.icon_name"), "audio-card") # Extracts icon name from app or device properties, defaults to "audio-card"
        
        return {                                                                  # Returns a dictionary with standardized device information
            "id": str(n.get("index")),                                            # Device index converted to string (e.g., "0", "1")
            "name": sub_desc,                                                     # Sub description: media name for apps, device name for hardware
            "description": display_name,                                          # Human-readable display name
            "volume": vol,                                                        # Current volume level as integer (0-100)
            "mute": bool(n.get("mute", False)),                                   # Mute state converted to boolean, defaults to False if not present
            "is_default": bool(is_default),                                       # Whether this is the default device, converted to boolean
            "icon": icon                                                          # Icon name for UI display
        }

    # Filter out empty apps/system sounds                                         # Comment explaining filtering logic for application streams
    apps = []                                                                     # Initializes empty list for filtered application streams
    for s in sink_inputs:                                                         # Iterates through all sink-inputs (audio-producing applications)
        props = s.get("properties", {})                                           # Gets properties dict from each sink-input
        if props.get("application.id") != "org.PulseAudio.pavucontrol":           # Filters out pavucontrol's own audio stream (avoids showing volume control app itself)
            apps.append(format_node(s, is_app=True))                              # Formats the application and adds to apps list

    out = {                                                                       # Creates the final output dictionary
        "outputs": [format_node(s, s.get("name") == default_sink) for s in sinks], # List comprehension: formats each sink, marking it as default if name matches
        "inputs": [format_node(s, s.get("name") == default_source) for s in sources], # List comprehension: formats each source, marking as default if name matches
        "apps": apps                                                              # Assigns the filtered and formatted application list
    }
    
    print(json.dumps(out))                                                        # Converts the output dictionary to JSON string and prints to stdout for consumption by QML

if __name__ == "__main__":                                                        # Standard Python idiom: only executes if this script is run directly (not imported)
    get_data()                                                                    # Calls the main data collection function