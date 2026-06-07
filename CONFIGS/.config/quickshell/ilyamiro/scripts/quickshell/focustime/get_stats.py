# #!/usr/bin/env python3
# import sqlite3
# import json
# import os
# import argparse
# import calendar
# import re
# from datetime import date, timedelta
# from collections import defaultdict

# DB_PATH = os.path.expanduser("~/.local/share/focustime/focustime.db")

# DESKTOP_CACHE_NAME = {}
# DESKTOP_CACHE_ICON = {}
# CACHE_BUILT = False
# SYSTEM_STATES = {"Desktop", "Locked", "Quickshell", "Unknown"}

# def get_xdg_search_dirs():
#     search_dirs = []
#     xdg_data_home = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
#     search_dirs.append(os.path.join(xdg_data_home, "applications"))
    
#     xdg_data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share")
#     for d in xdg_data_dirs.split(":"):
#         if d.strip():
#             search_dirs.append(os.path.join(d, "applications"))

#     fallback_dirs = [
#         "/var/lib/flatpak/exports/share/applications",
#         "/var/lib/snapd/desktop/applications"
#     ]
#     for d in fallback_dirs:
#         if d not in search_dirs:
#             search_dirs.append(d)
#     return search_dirs

# def build_desktop_cache():
#     global CACHE_BUILT
#     if CACHE_BUILT: return
    
#     for directory in get_xdg_search_dirs():
#         if not os.path.exists(directory): continue
#         try:
#             for f in os.listdir(directory):
#                 if f.endswith(".desktop"):
#                     path = os.path.join(directory, f)
#                     try:
#                         name, icon, wmclass = None, "", None
#                         with open(path, 'r', encoding='utf-8') as file:
#                             for line in file:
#                                 line = line.strip()
#                                 if line.startswith("Name=") and not name:
#                                     name = line.split("=", 1)[1].strip()
#                                 elif line.startswith("Icon=") and not icon:
#                                     icon = line.split("=", 1)[1].strip()
#                                 elif line.startswith("StartupWMClass="):
#                                     wmclass = line.split("=", 1)[1].strip().lower()
                        
#                         if name:
#                             base = f[:-8].lower()
#                             DESKTOP_CACHE_NAME[base] = name
#                             DESKTOP_CACHE_ICON[base] = icon
#                             if wmclass:
#                                 DESKTOP_CACHE_NAME[wmclass] = name
#                                 DESKTOP_CACHE_ICON[wmclass] = icon
#                     except Exception:
#                         pass
#         except Exception:
#             pass
#     CACHE_BUILT = True

# def get_app_icon(app_class):
#     if not app_class or app_class in SYSTEM_STATES:
#         return ""
        
#     build_desktop_cache()
    
#     app_class_lower = app_class.lower()
#     base_class = re.sub(r'[-_ ]?updater$', '', app_class_lower)
#     base_class = base_class.replace('.exe', '')

#     if app_class_lower in DESKTOP_CACHE_ICON: return DESKTOP_CACHE_ICON[app_class_lower]
#     if base_class in DESKTOP_CACHE_ICON: return DESKTOP_CACHE_ICON[base_class]
#     return ""

# def build_query(base_query, date_params, app_filter):
#     if app_filter: return base_query + " AND app_class = ?", date_params + (app_filter,)
#     return base_query, date_params

# def main():
#     parser = argparse.ArgumentParser()
#     parser.add_argument("date", nargs="?", default=date.today().isoformat())
#     parser.add_argument("--app", type=str, default=None, help="Filter stats by app_class")
#     args = parser.parse_args()

#     target_date_str = args.date
#     app_filter = args.app

#     try:
#         target_date = date.fromisoformat(target_date_str)
#     except ValueError:
#         target_date = date.today()

#     if not os.path.exists(DB_PATH):
#         print(json.dumps({
#             "total": 0, "average": 0, "week_range": "", "yesterday": 0, "current": "History", 
#             "apps": [], "week_apps": [], "week": [], "month": [], "hourly": [0]*48, "week_heatmap": [[0]*24 for _ in range(7)], "peak_usage_str": "N/A"
#         }))
#         return

#     conn = sqlite3.connect(DB_PATH)
#     c = conn.cursor()

#     yesterday = target_date - timedelta(days=1)
#     q, p = build_query('SELECT SUM(seconds) FROM focus_log WHERE log_date = ?', (yesterday.isoformat(),), app_filter)
#     c.execute(q, p)
#     yesterday_seconds = c.fetchone()[0] or 0

#     monday = target_date - timedelta(days=target_date.weekday())
#     sunday = monday + timedelta(days=6)
#     week_range_str = f"{monday.strftime('%b')} {monday.day} - {sunday.strftime('%b')} {sunday.day}"

#     q, p = build_query('''SELECT COUNT(DISTINCT log_date), SUM(seconds) FROM focus_log 
#                           WHERE log_date >= ? AND log_date <= ? AND seconds > 0''', (monday.isoformat(), sunday.isoformat()), app_filter)
#     c.execute(q, p)
#     row = c.fetchone()
#     days_count = row[0] or 0
#     total_week = row[1] or 0
#     average_seconds = total_week // days_count if days_count > 0 else 0

#     q, p = build_query('SELECT SUM(seconds) FROM focus_log WHERE log_date = ?', (target_date.isoformat(),), app_filter)
#     c.execute(q, p)
#     total_seconds = c.fetchone()[0] or 0

#     q, p = build_query('''SELECT app_class, COALESCE(app_title, app_class), SUM(seconds) as secs 
#                           FROM focus_log WHERE log_date = ?''', (target_date.isoformat(),), app_filter)
#     c.execute(q + " GROUP BY app_class ORDER BY secs DESC", p)
    
#     all_apps = []
#     for row in c.fetchall():
#         app_class, app_title, secs = row
#         all_apps.append({
#             "class": app_class, "name": app_title, "icon": get_app_icon(app_class),
#             "seconds": secs, "percent": round((secs / total_seconds) * 100, 1) if total_seconds > 0 else 0
#         })

#     q, p = build_query('''SELECT app_class, COALESCE(app_title, app_class), SUM(seconds) as secs 
#                           FROM focus_log WHERE log_date >= ? AND log_date <= ?''', (monday.isoformat(), sunday.isoformat()), app_filter)
#     c.execute(q + " GROUP BY app_class ORDER BY secs DESC LIMIT 50", p)
#     week_apps_rows = c.fetchall()
#     week_apps_total = sum([r[2] for r in week_apps_rows])
#     week_apps = []
#     for r in week_apps_rows:
#         cls, title, secs = r
#         week_apps.append({
#             "class": cls, "name": title, "icon": get_app_icon(cls),
#             "seconds": secs, "percent": round((secs / week_apps_total) * 100, 1) if week_apps_total > 0 else 0
#         })

#     # BULK QUERY FOR WEEK
#     q, p = build_query('SELECT log_date, SUM(seconds) FROM focus_log WHERE log_date >= ? AND log_date <= ?', 
#                        (monday.isoformat(), sunday.isoformat()), app_filter)
#     c.execute(q + " GROUP BY log_date", p)
#     week_map = {r[0]: r[1] for r in c.fetchall()}
    
#     week_data = []
#     days_str = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
#     for i in range(7):
#         d_str = (monday + timedelta(days=i)).isoformat()
#         week_data.append({"date": d_str, "day": days_str[i], "total": week_map.get(d_str, 0), "is_target": d_str == target_date_str})

#     # BULK QUERY FOR MONTH
#     first_day = target_date.replace(day=1)
#     _, num_days = calendar.monthrange(target_date.year, target_date.month)
#     last_day = target_date.replace(day=num_days)

#     q, p = build_query('SELECT log_date, SUM(seconds) FROM focus_log WHERE log_date >= ? AND log_date <= ?', 
#                        (first_day.isoformat(), last_day.isoformat()), app_filter)
#     c.execute(q + " GROUP BY log_date", p)
#     month_map = {r[0]: r[1] for r in c.fetchall()}
    
#     month_data = [{"date": "", "total": -1, "is_target": False} for _ in range(first_day.weekday())]
#     for i in range(1, num_days + 1):
#         d_str = target_date.replace(day=i).isoformat()
#         month_data.append({"date": d_str, "total": month_map.get(d_str, 0), "is_target": d_str == target_date_str})

#     hourly_data = [0] * 48
#     try:
#         q, p = build_query('SELECT hour, SUM(seconds) FROM focus_hourly WHERE log_date = ?', (target_date.isoformat(),), app_filter)
#         c.execute(q + " GROUP BY hour", p)
#         for hr, secs in c.fetchall():
#             if 0 <= hr <= 23: hourly_data[hr * 2] += secs
            
#         q, p = build_query('SELECT interval_idx, SUM(seconds) FROM focus_intervals WHERE log_date = ?', (target_date.isoformat(),), app_filter)
#         c.execute(q + " GROUP BY interval_idx", p)
#         for idx, secs in c.fetchall():
#             if 0 <= idx < 96: hourly_data[idx // 2] += secs
#     except sqlite3.OperationalError:
#         pass

#     week_heatmap = [[0]*24 for _ in range(7)]
#     try:
#         q, p = build_query('''SELECT log_date, hour, SUM(seconds) FROM focus_hourly 
#                               WHERE log_date >= ? AND log_date <= ?''', (monday.isoformat(), sunday.isoformat()), app_filter)
#         c.execute(q + " GROUP BY log_date, hour", p)
#         for ldate, hr, secs in c.fetchall():
#             day_idx = date.fromisoformat(ldate).weekday()
#             if 0 <= hr <= 23: week_heatmap[day_idx][hr] += secs
#     except sqlite3.OperationalError:
#         pass

#     minute_data = [0] * 1440
#     try:
#         q, p = build_query('''SELECT minute_idx, SUM(seconds) FROM focus_minutes 
#                               WHERE log_date >= ? AND log_date <= ?''', (monday.isoformat(), sunday.isoformat()), app_filter)
#         c.execute(q + " GROUP BY minute_idx", p)
#         for idx, secs in c.fetchall():
#             if 0 <= idx < 1440: minute_data[idx] += secs
#     except sqlite3.OperationalError:
#         pass

#     peak_str = "N/A"
#     max_sum = 0
#     best_window = None
#     for i in range(1440 - 60):
#         w_sum = sum(minute_data[i:i+60])
#         if w_sum > max_sum and w_sum > 0:
#             max_sum = w_sum
#             best_window = (i, i+60)

#     if best_window:
#         start_idx, end_idx = best_window
#         while start_idx < end_idx and minute_data[start_idx] == 0: start_idx += 1
#         actual_end = end_idx - 1
#         while actual_end > start_idx and minute_data[actual_end] == 0: actual_end -= 1
#         s_h, s_m = divmod(start_idx, 60)
#         e_h, e_m = divmod(actual_end, 60)
#         peak_str = f"{s_h:02d}:{s_m:02d} - {e_h:02d}:{e_m:02d}"

#     result = {
#         "selected_date": target_date.isoformat(), "total": total_seconds, "average": average_seconds,
#         "week_range": week_range_str, "yesterday": yesterday_seconds, "current": app_filter if app_filter else "History",
#         "apps": all_apps, "week_apps": week_apps, "week": week_data, "month": month_data,
#         "hourly": hourly_data, "week_heatmap": week_heatmap, "peak_usage_str": peak_str
#     }
    
#     print(json.dumps(result))

# if __name__ == "__main__":
#     main()
#!/usr/bin/env python3                                                           # Shebang line that tells the system to execute this script using the python3 interpreter found in the user's PATH environment variable
import sqlite3                                                                   # Imports the sqlite3 module for connecting to and querying the focus time tracking SQLite database
import json                                                                      # Imports the json module for serializing the query results into JSON format to be consumed by the QML frontend
import os                                                                        # Imports the os module for file path operations, directory existence checks, and reading environment variables for XDG paths
import argparse                                                                  # Imports the argparse module for parsing command-line arguments (target date and optional app filter)
import calendar                                                                  # Imports the calendar module for getting month ranges and weekday information used in monthly calendar data generation
import re                                                                        # Imports the re module for regular expression operations used in parsing application class names and desktop file processing
from datetime import date, timedelta                                             # Imports date for calendar date handling and timedelta for date arithmetic (calculating yesterday, week boundaries, etc.)
from collections import defaultdict                                              # Imports defaultdict which provides dictionaries with default values (used in the daemon but defined here for standalone compatibility)

DB_PATH = os.path.expanduser("~/.local/share/focustime/focustime.db")           # Constructs the full path to the SQLite database file by expanding the home directory and appending the focustime subdirectory path

DESKTOP_CACHE_NAME = {}                                                          # Initializes an empty dictionary that caches mappings from application class identifiers to human-readable display names (from .desktop files)
DESKTOP_CACHE_ICON = {}                                                          # Initializes an empty dictionary that caches mappings from application class identifiers to icon names (from .desktop files)
CACHE_BUILT = False                                                              # Boolean flag tracking whether the desktop file cache has been built; starts False and set to True after first build to avoid redundant scans
SYSTEM_STATES = {"Desktop", "Locked", "Quickshell", "Unknown"}                  # A set of special state names representing system-level states rather than actual applications; used to skip icon lookups for these states

def get_xdg_search_dirs():                                                       # Defines a function that returns a list of directories where .desktop files are located, following the XDG Base Directory specification
    search_dirs = []                                                             # Initializes an empty list that will collect all directories to search for .desktop application launcher files
    xdg_data_home = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))  # Gets the XDG_DATA_HOME environment variable with a fallback to ~/.local/share (the standard user data directory)
    search_dirs.append(os.path.join(xdg_data_home, "applications"))              # Adds the user's applications directory (e.g., ~/.local/share/applications) as the first and highest priority search location
    
    xdg_data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share")  # Gets the XDG_DATA_DIRS environment variable (colon-separated system data directories) with standard fallback paths
    for d in xdg_data_dirs.split(":"):                                           # Iterates through each colon-separated directory path in the XDG_DATA_DIRS string
        if d.strip():                                                             # Checks if the directory string is not empty after removing whitespace (filters out empty entries from trailing/multiple colons)
            search_dirs.append(os.path.join(d, "applications"))                   # Appends the "applications" subdirectory for each system data directory (e.g., /usr/local/share/applications)

    fallback_dirs = [                                                            # Defines a list of additional fallback directories where .desktop files may exist outside standard XDG locations
        "/var/lib/flatpak/exports/share/applications",                            # Flatpak applications export their .desktop files to this directory for integration with desktop environments
        "/var/lib/snapd/desktop/applications"                                    # Snap packages store their .desktop files in this snap-specific applications directory
    ]
    for d in fallback_dirs:                                                      # Iterates through each fallback directory
        if d not in search_dirs:                                                  # Checks if this directory is already in the search list (prevents duplicate entries)
            search_dirs.append(d)                                                 # Adds the fallback directory to the search list if it wasn't already included
    return search_dirs                                                            # Returns the complete list of directories to search for .desktop files

def build_desktop_cache():                                                       # Defines a function that scans all .desktop files across the system and builds lookup dictionaries for application names and icons
    global CACHE_BUILT                                                            # Declares that we're modifying the global CACHE_BUILT flag variable
    if CACHE_BUILT: return                                                       # If the cache has already been built, exit immediately to avoid redundant filesystem scanning operations
    
    for directory in get_xdg_search_dirs():                                      # Iterates through every directory returned by the XDG search directories function
        if not os.path.exists(directory): continue                               # If the directory doesn't exist on this system, skip it and move to the next one
        try:                                                                      # Opens a try block to handle potential permission errors or other filesystem access exceptions gracefully
            for f in os.listdir(directory):                                       # Lists all files and subdirectories in the current directory
                if f.endswith(".desktop"):                                        # Only processes files that have the .desktop extension (Linux application launcher files)
                    path = os.path.join(directory, f)                             # Constructs the absolute path to the .desktop file by joining directory and filename
                    try:                                                          # Nested try block for handling parsing errors on individual .desktop files
                        name, icon, wmclass = None, "", None                     # Initializes variables: name=None (not found), icon="" (empty string default), wmclass=None (not found)
                        with open(path, 'r', encoding='utf-8') as file:          # Opens the .desktop file for reading with UTF-8 encoding to properly handle international characters
                            for line in file:                                     # Reads the file line by line to parse key-value pairs
                                line = line.strip()                                # Removes leading and trailing whitespace from the current line
                                if line.startswith("Name=") and not name:         # If the line starts with "Name=" AND we haven't found a name yet (first Name= entry is primary)
                                    name = line.split("=", 1)[1].strip()          # Splits on the first equals sign and takes the value portion, then strips whitespace to get the application name
                                elif line.startswith("Icon=") and not icon:       # If the line starts with "Icon=" AND we haven't found an icon yet
                                    icon = line.split("=", 1)[1].strip()          # Extracts the icon name/value from after "Icon=" by splitting on the first equals sign
                                elif line.startswith("StartupWMClass="):          # If the line defines the StartupWMClass (used by X11/Wayland window managers to identify application windows)
                                    wmclass = line.split("=", 1)[1].strip().lower()  # Extracts the WM class value and converts it to lowercase for case-insensitive matching in lookups
                        
                        if name:                                                  # If we successfully extracted an application name from the .desktop file
                            base = f[:-8].lower()                                 # Creates a base identifier from the filename by removing the ".desktop" suffix (last 8 characters) and converting to lowercase
                            DESKTOP_CACHE_NAME[base] = name                       # Maps the base filename (without .desktop extension) to the human-readable application name
                            DESKTOP_CACHE_ICON[base] = icon                       # Maps the base filename to the icon name for icon lookups
                            if wmclass:                                           # If a StartupWMClass was found in this .desktop file
                                DESKTOP_CACHE_NAME[wmclass] = name                 # Also maps the WM class string to the application name for window class-based lookups
                                DESKTOP_CACHE_ICON[wmclass] = icon                 # Also maps the WM class to the icon name for icon retrieval by window class
                    except Exception:                                              # Catches any exception that occurs while parsing an individual .desktop file
                        pass                                                       # Silently ignores parsing errors for individual files (corrupted, unreadable, or malformed files)
        except Exception:                                                          # Catches any exception that occurs while listing or accessing a directory
            pass                                                                   # Silently ignores directories that can't be read (permission errors, etc.)
    CACHE_BUILT = True                                                             # Marks the cache as successfully built so subsequent calls to this function return immediately

def get_app_icon(app_class):                                                     # Defines a function that returns the icon name for a given application class by looking it up in the desktop file cache
    if not app_class or app_class in SYSTEM_STATES:                              # If the app_class is empty/None or it's one of the special system states (Desktop, Locked, etc.)
        return ""                                                                 # Returns an empty string since system states don't have associated application icons
        
    build_desktop_cache()                                                         # Ensures the desktop file cache is built before attempting any lookups
    
    app_class_lower = app_class.lower()                                           # Converts the application class to lowercase for case-insensitive matching against cache keys
    base_class = re.sub(r'[-_ ]?updater$', '', app_class_lower)                  # Removes an optional "updater" suffix (with possible dash/underscore/space separator) from the class name since updater processes are separate from main apps
    base_class = base_class.replace('.exe', '')                                  # Removes ".exe" extension that may appear in Windows applications running through Wine/Proton compatibility layers

    if app_class_lower in DESKTOP_CACHE_ICON: return DESKTOP_CACHE_ICON[app_class_lower]  # If the exact lowercase class exists as a key in the icon cache, return its icon immediately
    if base_class in DESKTOP_CACHE_ICON: return DESKTOP_CACHE_ICON[base_class]    # If the base class (after removing updater suffix) exists in the cache, return that icon
    return ""                                                                     # Returns empty string if no icon was found for this application class in the desktop file cache

def build_query(base_query, date_params, app_filter):                            # Defines a helper function that dynamically extends SQL queries with an optional app_class filter for per-app statistics
    if app_filter: return base_query + " AND app_class = ?", date_params + (app_filter,)  # If an app filter is provided, appends "AND app_class = ?" to the query and adds the filter to the parameters tuple
    return base_query, date_params                                                # If no app filter, returns the base query and parameters unchanged

def main():                                                                       # Main function that handles command-line argument parsing, database querying, and JSON output generation
    parser = argparse.ArgumentParser()                                            # Creates an ArgumentParser object to define and parse command-line arguments
    parser.add_argument("date", nargs="?", default=date.today().isoformat())     # Adds an optional positional argument "date" that accepts an ISO format date string (YYYY-MM-DD); defaults to today's date if not provided
    parser.add_argument("--app", type=str, default=None, help="Filter stats by app_class")  # Adds an optional --app argument that accepts an application class string for filtering statistics to a specific app
    args = parser.parse_args()                                                    # Parses the command-line arguments and stores the results in the args namespace

    target_date_str = args.date                                                   # Extracts the target date string from the parsed arguments (either user-provided or defaulting to today)
    app_filter = args.app                                                         # Extracts the optional app filter string from the parsed arguments (None if not provided)

    try:                                                                          # Opens a try block to handle invalid date strings gracefully
        target_date = date.fromisoformat(target_date_str)                        # Attempts to parse the date string into a Python date object using the ISO format parser
    except ValueError:                                                            # Catches ValueError if the date string is not in valid ISO format
        target_date = date.today()                                               # Falls back to using today's date if the provided date string was invalid

    if not os.path.exists(DB_PATH):                                              # Checks if the focus time database file exists at the expected path
        print(json.dumps({                                                        # If the database doesn't exist, prints a JSON object with empty/default values so the frontend can render without errors
            "total": 0, "average": 0, "week_range": "", "yesterday": 0, "current": "History",  # Sets all statistics to zero/empty and current to "History" indicating no tracking data available
            "apps": [], "week_apps": [], "week": [], "month": [], "hourly": [0]*48, "week_heatmap": [[0]*24 for _ in range(7)], "peak_usage_str": "N/A"  # Provides empty arrays, zero-filled hourly data, empty heatmap, and "N/A" peak time
        }))
        return                                                                    # Exits the function early since there's no database to query

    conn = sqlite3.connect(DB_PATH)                                              # Opens a connection to the SQLite database file
    c = conn.cursor()                                                             # Creates a cursor object to execute SQL queries against the database

    yesterday = target_date - timedelta(days=1)                                  # Calculates yesterday's date by subtracting one day from the target date
    q, p = build_query('SELECT SUM(seconds) FROM focus_log WHERE log_date = ?', (yesterday.isoformat(),), app_filter)  # Builds the query and parameters for getting yesterday's total seconds, with optional app filter
    c.execute(q, p)                                                               # Executes the built SQL query with its parameters
    yesterday_seconds = c.fetchone()[0] or 0                                     # Fetches the result; if NULL (no data for yesterday), defaults to 0 seconds

    monday = target_date - timedelta(days=target_date.weekday())                 # Calculates the Monday of the target date's week by subtracting the weekday number (0=Monday, 6=Sunday)
    sunday = monday + timedelta(days=6)                                           # Calculates the Sunday of that week by adding 6 days to Monday
    week_range_str = f"{monday.strftime('%b')} {monday.day} - {sunday.strftime('%b')} {sunday.day}"  # Formats a human-readable week range string like "Mar 10 - Mar 16" using abbreviated month names

    q, p = build_query('''SELECT COUNT(DISTINCT log_date), SUM(seconds) FROM focus_log 
                          WHERE log_date >= ? AND log_date <= ? AND seconds > 0''', (monday.isoformat(), sunday.isoformat()), app_filter)  # Builds query to count distinct active days and sum total seconds for the week
    c.execute(q, p)                                                               # Executes the weekly statistics query
    row = c.fetchone()                                                            # Fetches the single result row containing count and sum
    days_count = row[0] or 0                                                      # Extracts the count of distinct days with activity; defaults to 0 if NULL
    total_week = row[1] or 0                                                      # Extracts the total seconds for the week; defaults to 0 if NULL
    average_seconds = total_week // days_count if days_count > 0 else 0          # Calculates the daily average for the week using integer division; returns 0 if no active days to avoid division by zero

    q, p = build_query('SELECT SUM(seconds) FROM focus_log WHERE log_date = ?', (target_date.isoformat(),), app_filter)  # Builds query for total seconds on the target date
    c.execute(q, p)                                                               # Executes the daily total query
    total_seconds = c.fetchone()[0] or 0                                          # Fetches the total seconds; defaults to 0 if no data exists for the target date

    q, p = build_query('''SELECT app_class, COALESCE(app_title, app_class), SUM(seconds) as secs 
                          FROM focus_log WHERE log_date = ?''', (target_date.isoformat(),), app_filter)  # Builds query for daily app breakdown; COALESCE falls back to app_class if app_title is null
    c.execute(q + " GROUP BY app_class ORDER BY secs DESC", p)                   # Appends GROUP BY and ORDER BY to the query (not included in build_query to keep that function generic), then executes
    all_apps = []                                                                  # Initializes an empty list to store application statistics dictionaries for the day
    for row in c.fetchall():                                                       # Iterates through each row returned by the daily apps query
        app_class, app_title, secs = row                                           # Unpacks the row into application class, display title, and total seconds
        all_apps.append({                                                          # Appends a dictionary with complete statistics for this application
            "class": app_class, "name": app_title, "icon": get_app_icon(app_class),  # Stores the application class, display name, and icon name (from desktop cache)
            "seconds": secs, "percent": round((secs / total_seconds) * 100, 1) if total_seconds > 0 else 0  # Calculates percentage of total daily time, rounded to 1 decimal; avoids division by zero
        })

    q, p = build_query('''SELECT app_class, COALESCE(app_title, app_class), SUM(seconds) as secs 
                          FROM focus_log WHERE log_date >= ? AND log_date <= ?''', (monday.isoformat(), sunday.isoformat()), app_filter)  # Builds query for weekly app breakdown
    c.execute(q + " GROUP BY app_class ORDER BY secs DESC LIMIT 50", p)          # Adds GROUP BY, ORDER BY descending, and LIMIT 50 to get top 50 apps for the week
    week_apps_rows = c.fetchall()                                                 # Fetches all rows for the weekly application statistics
    week_apps_total = sum([r[2] for r in week_apps_rows])                        # Sums the seconds column (index 2) across all weekly app rows to get total weekly tracked time
    week_apps = []                                                                 # Initializes an empty list for weekly application data
    for r in week_apps_rows:                                                       # Iterates through each weekly application row
        cls, title, secs = r                                                        # Unpacks class, title, and seconds from the row
        week_apps.append({                                                          # Appends a dictionary with weekly statistics for this app
            "class": cls, "name": title, "icon": get_app_icon(cls),                # Stores class, display name, and icon
            "seconds": secs, "percent": round((secs / week_apps_total) * 100, 1) if week_apps_total > 0 else 0  # Calculates percentage of weekly total, rounded to 1 decimal
        })

    # BULK QUERY FOR WEEK                                                        # Comment indicating the following section queries and processes weekly day-by-day data
    q, p = build_query('SELECT log_date, SUM(seconds) FROM focus_log WHERE log_date >= ? AND log_date <= ?', 
                       (monday.isoformat(), sunday.isoformat()), app_filter)      # Builds query for daily totals across the week date range
    c.execute(q + " GROUP BY log_date", p)                                       # Adds GROUP BY to aggregate by date, then executes the query
    week_map = {r[0]: r[1] for r in c.fetchall()}                                # Creates a dictionary mapping date strings to total seconds for efficient lookup when building week data
    
    week_data = []                                                                 # Initializes an empty list to store day-by-day data for the week
    days_str = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]                 # List of abbreviated three-letter day names for display in the weekly view
    for i in range(7):                                                             # Iterates through each day of the week (0=Monday through 6=Sunday)
        d_str = (monday + timedelta(days=i)).isoformat()                           # Calculates the ISO date string for the current day by adding i days to Monday
        week_data.append({"date": d_str, "day": days_str[i], "total": week_map.get(d_str, 0), "is_target": d_str == target_date_str})  # Creates a day entry with date, day name, total seconds (0 if no data), and whether this is the selected day

    # BULK QUERY FOR MONTH                                                       # Comment indicating the following section processes monthly calendar data
    first_day = target_date.replace(day=1)                                        # Gets the first day of the target month by replacing the day component with 1
    _, num_days = calendar.monthrange(target_date.year, target_date.month)       # Returns a tuple (weekday of first day, number of days in month); we only need num_days
    last_day = target_date.replace(day=num_days)                                  # Creates a date object for the last day of the month using the number of days

    q, p = build_query('SELECT log_date, SUM(seconds) FROM focus_log WHERE log_date >= ? AND log_date <= ?', 
                       (first_day.isoformat(), last_day.isoformat()), app_filter)  # Builds query for daily totals across the entire month
    c.execute(q + " GROUP BY log_date", p)                                       # Groups results by date and executes the monthly query
    month_map = {r[0]: r[1] for r in c.fetchall()}                               # Creates a dictionary mapping month dates to total seconds for efficient lookup
    
    month_data = [{"date": "", "total": -1, "is_target": False} for _ in range(first_day.weekday())]  # Creates padding entries for days before the 1st of the month (empty cells to align the calendar grid); total=-1 signals "no data" vs total=0 meaning "no activity"
    for i in range(1, num_days + 1):                                               # Iterates through each day of the month (1 to total number of days)
        d_str = target_date.replace(day=i).isoformat()                             # Creates the ISO date string for the current day of the month
        month_data.append({"date": d_str, "total": month_map.get(d_str, 0), "is_target": d_str == target_date_str})  # Adds a month day entry with date, total seconds (0 if no data), and whether this is the selected/target day

    hourly_data = [0] * 48                                                         # Initializes a list of 48 zeros representing half-hour slots in a day (24 hours * 2 half-hours)
    try:                                                                            # Opens a try block in case the hourly tables don't exist yet (first run before daemon creates them)
        q, p = build_query('SELECT hour, SUM(seconds) FROM focus_hourly WHERE log_date = ?', (target_date.isoformat(),), app_filter)  # Builds query for hourly aggregation on the target date
        c.execute(q + " GROUP BY hour", p)                                         # Groups by hour and executes the query
        for hr, secs in c.fetchall():                                              # Iterates through each hour's data
            if 0 <= hr <= 23: hourly_data[hr * 2] += secs                         # Maps each hour to its corresponding half-hour index (hour 0->index 0, hour 1->index 2, etc.) and adds seconds
            
        q, p = build_query('SELECT interval_idx, SUM(seconds) FROM focus_intervals WHERE log_date = ?', (target_date.isoformat(),), app_filter)  # Builds query for 15-minute interval data
        c.execute(q + " GROUP BY interval_idx", p)                                # Groups by interval index and executes
        for idx, secs in c.fetchall():                                             # Iterates through interval data
            if 0 <= idx < 96: hourly_data[idx // 2] += secs                       # Maps 15-minute intervals to half-hour slots (intervals 0-1->slot 0, 2-3->slot 1) and adds seconds
    except sqlite3.OperationalError:                                               # Catches database operational errors (typically table doesn't exist yet)
        pass                                                                        # Silently passes and keeps the zero-filled hourly_data array

    week_heatmap = [[0]*24 for _ in range(7)]                                      # Creates a 7x24 grid (7 days of week, 24 hours per day) for the weekly activity heatmap; initializes all cells to 0
    try:                                                                            # Opens try block for heatmap data queries
        q, p = build_query('''SELECT log_date, hour, SUM(seconds) FROM focus_hourly 
                              WHERE log_date >= ? AND log_date <= ?''', (monday.isoformat(), sunday.isoformat()), app_filter)  # Builds query for hourly data across the entire week
        c.execute(q + " GROUP BY log_date, hour", p)                              # Groups by date and hour, then executes
        for ldate, hr, secs in c.fetchall():                                       # Iterates through each date-hour-seconds combination
            day_idx = date.fromisoformat(ldate).weekday()                          # Converts the date string to a date object and gets the weekday number (0=Monday)
            if 0 <= hr <= 23: week_heatmap[day_idx][hr] += secs                   # If the hour is valid, adds the seconds to the appropriate cell in the heatmap grid
    except sqlite3.OperationalError:                                               # Catches errors if the hourly table doesn't exist yet
        pass                                                                        # Silently passes with the zero-filled heatmap

    minute_data = [0] * 1440                                                       # Creates a list of 1440 zeros representing each minute in a day (24 hours * 60 minutes)
    try:                                                                            # Opens try block for minute-level data
        q, p = build_query('''SELECT minute_idx, SUM(seconds) FROM focus_minutes 
                              WHERE log_date >= ? AND log_date <= ?''', (monday.isoformat(), sunday.isoformat()), app_filter)  # Builds query for per-minute data across the week
        c.execute(q + " GROUP BY minute_idx", p)                                  # Groups by minute index and executes
        for idx, secs in c.fetchall():                                             # Iterates through each minute index and its accumulated seconds
            if 0 <= idx < 1440: minute_data[idx] += secs                          # Adds the seconds to the appropriate minute slot in the array
    except sqlite3.OperationalError:                                               # Catches errors if the minutes table doesn't exist yet
        pass                                                                        # Silently passes with the zero-filled minute_data

    peak_str = "N/A"                                                               # Default peak usage time string when no activity data is available
    max_sum = 0                                                                     # Tracks the maximum total seconds found in any 60-minute sliding window
    best_window = None                                                              # Stores the (start_index, end_index) tuple of the best 60-minute window found
    for i in range(1440 - 60):                                                      # Slides a 60-minute window across all 1440 minutes; stops at 1380 so the window stays within bounds
        w_sum = sum(minute_data[i:i+60])                                            # Calculates the sum of seconds in the current 60-minute window
        if w_sum > max_sum and w_sum > 0:                                          # If this window has more total activity than the previous best AND has at least some non-zero activity
            max_sum = w_sum                                                          # Updates the maximum sum to this window's total
            best_window = (i, i+60)                                                  # Stores this window's start and end minute indices as the current best

    if best_window:                                                                 # If a peak activity window was found with non-zero activity
        start_idx, end_idx = best_window                                             # Unpacks the start and end indices of the best window
        while start_idx < end_idx and minute_data[start_idx] == 0: start_idx += 1  # Trims leading zeros from the beginning of the window to find when activity actually starts
        actual_end = end_idx - 1                                                     # Sets the end index to the last minute of the 60-minute window
        while actual_end > start_idx and minute_data[actual_end] == 0: actual_end -= 1  # Trims trailing zeros to find when activity actually ends within the window
        s_h, s_m = divmod(start_idx, 60)                                            # Converts the start minute index to hours and minutes using divmod (returns quotient and remainder)
        e_h, e_m = divmod(actual_end, 60)                                           # Converts the end minute index to hours and minutes
        peak_str = f"{s_h:02d}:{s_m:02d} - {e_h:02d}:{e_m:02d}"                    # Formats the peak usage time range as "HH:MM - HH:MM" with zero-padded two-digit numbers

    result = {                                                                      # Builds the final result dictionary containing all computed statistics
        "selected_date": target_date.isoformat(), "total": total_seconds, "average": average_seconds,  # Target date, daily total seconds, and daily average seconds
        "week_range": week_range_str, "yesterday": yesterday_seconds, "current": app_filter if app_filter else "History",  # Week range string, yesterday's total, and current display name (app filter or "History")
        "apps": all_apps, "week_apps": week_apps, "week": week_data, "month": month_data,  # Application breakdowns for today and this week, plus week and month day arrays
        "hourly": hourly_data, "week_heatmap": week_heatmap, "peak_usage_str": peak_str  # Hourly distribution data, weekly heatmap grid, and the formatted peak usage time string
    }
    
    print(json.dumps(result))                                                       # Serializes the entire result dictionary to a JSON string and prints to stdout for consumption by the QML frontend

if __name__ == "__main__":                                                          # Standard Python idiom: only execute main() if this script is run directly (not imported as a module)
    main()                                                                           # Calls the main function to start the statistics retrieval process