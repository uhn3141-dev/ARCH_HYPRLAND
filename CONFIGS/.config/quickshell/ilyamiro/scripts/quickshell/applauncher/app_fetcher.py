# #!/usr/bin/env python3
# import os
# import glob
# import json

# def fetch_apps():
#     apps = {}
#     home = os.path.expanduser('~')
    
#     # Expanded directories to catch Flatpaks, system apps, and Nix packages
#     dirs = [
#         '/usr/share/applications',
#         '/usr/local/share/applications',
#         f'{home}/.local/share/applications',
#         '/var/lib/flatpak/exports/share/applications',
#         f'{home}/.local/share/flatpak/exports/share/applications',
#         f'{home}/.nix-profile/share/applications',
#         '/run/current-system/sw/share/applications'
#     ]
    
#     for d in dirs:
#         if not os.path.exists(d):
#             continue
            
#         for f in glob.glob(os.path.join(d, '**/*.desktop'), recursive=True):
#             try:
#                 with open(f, 'r', encoding='utf-8') as file:
#                     app = {'name': '', 'exec': '', 'icon': ''}
#                     is_desktop = False
#                     no_display = False
                    
#                     for line in file:
#                         line = line.strip()
#                         if line == '[Desktop Entry]':
#                             is_desktop = True
#                         elif line.startswith('['):
#                             is_desktop = False
                            
#                         if is_desktop:
#                             if line.startswith('Name=') and not app['name']:
#                                 app['name'] = line[5:]
#                             elif line.startswith('Exec=') and not app['exec']:
#                                 # Strip %u, %f, and @@ placeholders
#                                 app['exec'] = line[5:].split(' %')[0].split(' @@')[0]
#                             elif line.startswith('Icon=') and not app['icon']:
#                                 app['icon'] = line[5:]
#                             elif line.startswith('NoDisplay=true') or line.startswith('NoDisplay=1'):
#                                 no_display = True
                                
#                     if app['name'] and app['exec'] and not no_display:
#                         apps[app['name']] = app
#             except Exception:
#                 pass
                
#     # Sort alphabetically and return as JSON
#     res = list(apps.values())
#     res.sort(key=lambda x: x['name'].lower())
#     print(json.dumps(res))

# if __name__ == "__main__":
#     fetch_apps()




#!/usr/bin/env python3                                                                                      # Shebang line that tells the system to execute this script using the python3 interpreter found in the user's PATH environment
import os                                                                                                   # Import the os module to interact with the operating system (file paths, existence checks, environment variables)
import glob                                                                                                 # Import the glob module to find file paths matching specified patterns (like *.desktop)
import json                                                                                                 # Import the json module to serialize Python objects into JSON format for output

def fetch_apps():                                                                                           # Define the main function 'fetch_apps' that will discover and collect all installed application entries
    apps = {}                                                                                               # Initialize an empty dictionary 'apps' to store discovered applications, keyed by their display name
    home = os.path.expanduser('~')                                                                          # Resolve the tilde '~' character to the absolute path of the current user's home directory
    
    # Expanded directories to catch Flatpaks, system apps, and Nix packages                                 # Comment indicating that the following directories cover multiple installation sources (standard, Flatpak, Nix)
    dirs = [                                                                                                # Start defining a list 'dirs' containing all directory paths where .desktop files may be located
        '/usr/share/applications',                                                                          # Standard system-wide directory for application .desktop entries installed by the package manager (e.g., pacman)
        '/usr/local/share/applications',                                                                    # Directory for locally compiled or manually installed applications available system-wide
        f'{home}/.local/share/applications',                                                                # User-specific application entries directory, typically for apps installed only for the current user
        '/var/lib/flatpak/exports/share/applications',                                                      # System-wide Flatpak application entries directory (exports from system-installed Flatpaks)
        f'{home}/.local/share/flatpak/exports/share/applications',                                          # User-specific Flatpak application entries directory (exports from user-installed Flatpaks)
        f'{home}/.nix-profile/share/applications',                                                          # Nix package manager user profile applications directory (for apps installed via nix-env or home-manager)
        '/run/current-system/sw/share/applications'                                                         # NixOS current system generation applications directory (system-wide Nix-installed apps from configuration.nix)
    ]                                                                                                       # End of the directories list definition
    
    for d in dirs:                                                                                          # Iterate over each directory path stored in the 'dirs' list
        if not os.path.exists(d):                                                                           # Check if the current directory 'd' does NOT exist on the filesystem
            continue                                                                                        # If the directory doesn't exist, skip to the next directory iteration without attempting to scan it
            
        for f in glob.glob(os.path.join(d, '**/*.desktop'), recursive=True):                                # Use glob to recursively find all files ending with '.desktop' inside the current directory 'd' and its subdirectories
            try:                                                                                            # Begin a try block to catch any exceptions that might occur while parsing individual .desktop files
                with open(f, 'r', encoding='utf-8') as file:                                                # Open the current .desktop file 'f' in read mode with UTF-8 encoding to ensure proper character handling
                    app = {'name': '', 'exec': '', 'icon': ''}                                              # Initialize a dictionary for the current application with empty strings for name, exec command, and icon
                    is_desktop = False                                                                      # Flag variable to track whether we are currently inside the [Desktop Entry] section of the file
                    no_display = False                                                                      # Flag variable to track if this application entry explicitly requests not being shown in menus/launchers
                    
                    for line in file:                                                                       # Iterate over each line of text read from the opened .desktop file
                        line = line.strip()                                                                 # Remove leading and trailing whitespace (spaces, tabs, newlines) from the current line
                        if line == '[Desktop Entry]':                                                       # Check if the stripped line exactly matches the [Desktop Entry] section header
                            is_desktop = True                                                               # Set the is_desktop flag to True, indicating we are now parsing the desktop entry section
                        elif line.startswith('['):                                                          # Check if the line starts with a '[' bracket, indicating it's a new section header (but not [Desktop Entry])
                            is_desktop = False                                                              # Set is_desktop flag to False since we've entered a different section (like [Desktop Action ...])
                            
                        if is_desktop:                                                                      # Only process key-value pairs if we are currently inside the [Desktop Entry] section
                            if line.startswith('Name=') and not app['name']:                                # Check if the line starts with 'Name=' AND the app's name hasn't been set yet (captures first Name entry only)
                                app['name'] = line[5:]                                                      # Extract the application's display name by taking the substring starting from index 5 (skipping 'Name=')
                            elif line.startswith('Exec=') and not app['exec']:                              # Check if the line starts with 'Exec=' AND the app's executable command hasn't been set yet
                                # Strip %u, %f, and @@ placeholders                                         # Comment explaining that the following operations remove URI and file argument placeholders from the exec command
                                app['exec'] = line[5:].split(' %')[0].split(' @@')[0]                       # Extract the exec command (index 5), split at ' %' to remove field codes like %f %u %U, then split at ' @@' to remove Nix-style @@ wrappers, taking only the clean command
                            elif line.startswith('Icon=') and not app['icon']:                              # Check if the line starts with 'Icon=' AND the app's icon name/path hasn't been set yet
                                app['icon'] = line[5:]                                                      # Extract the icon identifier or path by taking the substring starting from index 5 (skipping 'Icon=')
                            elif line.startswith('NoDisplay=true') or line.startswith('NoDisplay=1'):        # Check if the line starts with 'NoDisplay=true' OR 'NoDisplay=1', indicating this app should be hidden from launchers
                                no_display = True                                                           # Set the no_display flag to True to mark this application as hidden
                                
                    if app['name'] and app['exec'] and not no_display:                                      # After processing all lines, check if we have a valid name AND exec command AND the app is not hidden
                        apps[app['name']] = app                                                             # Add the valid application dictionary to the 'apps' dictionary, using its display name as the key
            except Exception:                                                                               # Catch any exception that might have occurred during file processing (open errors, permission issues, etc.)
                pass                                                                                        # Silently ignore the exception and continue to the next .desktop file without crashing the script
                
    # Sort alphabetically and return as JSON                                                                # Comment indicating the next steps: sort the collected apps alphabetically and output as JSON format
    res = list(apps.values())                                                                               # Convert the values (app dictionaries) from the 'apps' dictionary into a list for sorting and output
    res.sort(key=lambda x: x['name'].lower())                                                               # Sort the list of app dictionaries in-place alphabetically by the lowercase version of each app's name
    print(json.dumps(res))                                                                                  # Serialize the sorted list of app dictionaries to a JSON string and print it to standard output (for consumption by the QML frontend)

if __name__ == "__main__":                                                                                  # Python idiom: check if this script is being run directly (not imported as a module in another script)
    fetch_apps()                                                                                            # Call the main fetch_apps() function to execute the application discovery and JSON output logic
