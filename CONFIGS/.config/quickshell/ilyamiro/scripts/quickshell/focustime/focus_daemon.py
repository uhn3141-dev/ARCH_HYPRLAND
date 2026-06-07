# #!/usr/bin/env python3
# import subprocess
# import sqlite3
# import time
# import os
# import socket
# import json
# import threading
# import calendar
# import re
# import signal
# import sys
# from datetime import date, datetime, timedelta
# from collections import defaultdict

# current_app_class = "Desktop"
# current_app_title = "Desktop"

# DB_DIR = os.path.expanduser("~/.local/share/focustime")
# os.makedirs(DB_DIR, exist_ok=True)
# DB_PATH = os.path.join(DB_DIR, "focustime.db")

# # Cache fallback adheres to tmpfs priority but securely falls back
# XDG_RUNTIME = os.environ.get("XDG_RUNTIME_DIR")
# if not XDG_RUNTIME:
#     XDG_RUNTIME = os.path.expanduser("~/.cache/focustime")
#     os.makedirs(XDG_RUNTIME, exist_ok=True)
# STATE_FILE = os.path.join(XDG_RUNTIME, "focustime_state.json")

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

# def resolve_app_name(app_class, raw_title):
#     if not app_class or app_class in SYSTEM_STATES:
#         return app_class if app_class else "Unknown"
        
#     build_desktop_cache()
#     app_class_lower = app_class.lower()
#     base_class = re.sub(r'[-_ ]?updater$', '', app_class_lower)
#     base_class = base_class.replace('.exe', '')

#     if app_class_lower in DESKTOP_CACHE_NAME: return DESKTOP_CACHE_NAME[app_class_lower]
#     if base_class in DESKTOP_CACHE_NAME: return DESKTOP_CACHE_NAME[base_class]

#     clean_title = re.sub(r'^\(\d+\)\s*|^\[\d+\]\s*', '', raw_title)
#     clean_title = re.sub(r'\s*\(\d+\)$', '', clean_title)
#     parts = re.split(r'\s+[-—|]\s+', clean_title)
#     name = parts[-1].strip() if len(parts) > 1 else clean_title.strip()

#     if len(name) > 25: name = app_class.capitalize()

#     DESKTOP_CACHE_NAME[app_class_lower] = name
#     return name

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

# def init_db():
#     conn = sqlite3.connect(DB_PATH)
#     c = conn.cursor()
#     c.execute('''CREATE TABLE IF NOT EXISTS focus_log (log_date TEXT, app_class TEXT, seconds INTEGER, app_title TEXT, PRIMARY KEY (log_date, app_class))''')
#     c.execute('CREATE INDEX IF NOT EXISTS idx_log_date ON focus_log(log_date)')
#     c.execute('''CREATE TABLE IF NOT EXISTS focus_hourly (log_date TEXT, hour INTEGER, app_class TEXT, seconds INTEGER, PRIMARY KEY (log_date, hour, app_class))''')
#     c.execute('''CREATE TABLE IF NOT EXISTS focus_intervals (log_date TEXT, interval_idx INTEGER, app_class TEXT, seconds INTEGER, PRIMARY KEY (log_date, interval_idx, app_class))''')
#     c.execute('''CREATE TABLE IF NOT EXISTS focus_minutes (log_date TEXT, minute_idx INTEGER, app_class TEXT, seconds INTEGER, PRIMARY KEY (log_date, minute_idx, app_class))''')
    
#     c.execute("PRAGMA table_info(focus_log)")
#     if 'app_title' not in [row[1] for row in c.fetchall()]:
#         c.execute('ALTER TABLE focus_log ADD COLUMN app_title TEXT')
        
#     conn.commit()
#     return conn

# def get_active_window_hyprctl():
#     try:
#         output = subprocess.check_output(['hyprctl', 'activewindow', '-j'], text=True)
#         if output.strip() == "{}": return "Desktop", "Desktop"
#         data = json.loads(output)
        
#         app_cls = data.get('initialClass') or data.get('class') or ''
#         raw_title = data.get('initialTitle') or data.get('title') or ''

#         if "quickshell" in app_cls.lower() or "qs-master" in raw_title.lower() or "qs-master" in app_cls.lower():
#             return "Quickshell", "Quickshell"
            
#         app_cls = app_cls if app_cls else "Unknown"
#         raw_title = raw_title if raw_title else app_cls
#         clean_name = resolve_app_name(app_cls, raw_title)
#         return app_cls, clean_name
#     except Exception:
#         return "Unknown", "Unknown"

# def is_locked():
#     try:
#         subprocess.check_output(['pgrep', '-x', 'hyprlock'])
#         return True
#     except subprocess.CalledProcessError:
#         return False

# def listen_hyprland_ipc():
#     global current_app_class, current_app_title
#     hypr_sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
#     if not hypr_sig: return

#     sock_path = f"{XDG_RUNTIME}/hypr/{hypr_sig}/.socket2.sock"
#     if not os.path.exists(sock_path):
#         sock_path = f"/tmp/hypr/{hypr_sig}/.socket2.sock"

#     while True:
#         try:
#             client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
#             client.connect(sock_path)
#             buffer = ""
#             while True:
#                 data = client.recv(4096).decode('utf-8')
#                 if not data: break
#                 buffer += data
#                 while '\n' in buffer:
#                     line, buffer = buffer.split('\n', 1)
#                     if line.startswith('activewindow>>'):
#                         cls, clean_title = get_active_window_hyprctl()
#                         if is_locked() or cls == "hyprlock":
#                             current_app_class, current_app_title = "Locked", "Locked"
#                         else:
#                             current_app_class, current_app_title = cls, clean_title
#         except Exception:
#             time.sleep(2) 


# class DaemonTracker:
#     def __init__(self):
#         self.conn = init_db()
#         self.buffer = []
#         self.cached_json = None
#         self.last_sync = 0
#         self.last_date = date.today()
        
#     def full_sync(self, target_date):
#         c = self.conn.cursor()
        
#         yesterday = target_date - timedelta(days=1)
#         c.execute('SELECT SUM(seconds) FROM focus_log WHERE log_date = ?', (yesterday.isoformat(),))
#         yesterday_seconds = c.fetchone()[0] or 0

#         monday = target_date - timedelta(days=target_date.weekday())
#         sunday = monday + timedelta(days=6)
#         week_range_str = f"{monday.strftime('%b')} {monday.day} - {sunday.strftime('%b')} {sunday.day}"

#         c.execute('''SELECT COUNT(DISTINCT log_date), SUM(seconds) FROM focus_log 
#                      WHERE log_date >= ? AND log_date <= ? AND seconds > 0''', (monday.isoformat(), sunday.isoformat()))
#         row = c.fetchone()
#         days_count = row[0] or 0
#         total_week = row[1] or 0
#         average_seconds = total_week // days_count if days_count > 0 else 0
        
#         c.execute('SELECT SUM(seconds) FROM focus_log WHERE log_date = ?', (target_date.isoformat(),))
#         total_seconds = c.fetchone()[0] or 0

#         c.execute('''SELECT app_class, COALESCE(app_title, app_class), SUM(seconds) as secs 
#                      FROM focus_log WHERE log_date = ? GROUP BY app_class ORDER BY secs DESC''', (target_date.isoformat(),))
#         all_apps = []
#         for row in c.fetchall():
#             app_class, app_title, secs = row
#             all_apps.append({
#                 "class": app_class, "name": app_title, "icon": get_app_icon(app_class),
#                 "seconds": secs, "percent": round((secs / total_seconds) * 100, 1) if total_seconds > 0 else 0
#             })

#         c.execute('''SELECT app_class, COALESCE(app_title, app_class), SUM(seconds) as secs FROM focus_log 
#                      WHERE log_date >= ? AND log_date <= ? GROUP BY app_class ORDER BY secs DESC LIMIT 50''', 
#                   (monday.isoformat(), sunday.isoformat()))
#         week_apps_rows = c.fetchall()
#         week_apps_total = sum([r[2] for r in week_apps_rows])
#         week_apps = []
#         for r in week_apps_rows:
#             cls, title, secs = r
#             week_apps.append({
#                 "class": cls, "name": title, "icon": get_app_icon(cls),
#                 "seconds": secs, "percent": round((secs / week_apps_total) * 100, 1) if week_apps_total > 0 else 0
#             })

#         c.execute('SELECT log_date, SUM(seconds) FROM focus_log WHERE log_date >= ? AND log_date <= ? GROUP BY log_date', 
#                  (monday.isoformat(), sunday.isoformat()))
#         week_map = {r[0]: r[1] for r in c.fetchall()}
#         days_str = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
#         week_data = []
#         for i in range(7):
#             d_str = (monday + timedelta(days=i)).isoformat()
#             week_data.append({"date": d_str, "day": days_str[i], "total": week_map.get(d_str, 0), "is_target": d_str == target_date.isoformat()})

#         first_day = target_date.replace(day=1)
#         _, num_days = calendar.monthrange(target_date.year, target_date.month)
#         last_day = target_date.replace(day=num_days)
#         c.execute('SELECT log_date, SUM(seconds) FROM focus_log WHERE log_date >= ? AND log_date <= ? GROUP BY log_date', 
#                  (first_day.isoformat(), last_day.isoformat()))
#         month_map = {r[0]: r[1] for r in c.fetchall()}
        
#         month_data = [{"date": "", "total": -1, "is_target": False} for _ in range(first_day.weekday())]
#         for i in range(1, num_days + 1):
#             d_str = target_date.replace(day=i).isoformat()
#             month_data.append({"date": d_str, "total": month_map.get(d_str, 0), "is_target": d_str == target_date.isoformat()})

#         hourly_data = [0] * 48
#         try:
#             c.execute('SELECT hour, SUM(seconds) FROM focus_hourly WHERE log_date = ? GROUP BY hour', (target_date.isoformat(),))
#             for hr, secs in c.fetchall():
#                 if 0 <= hr <= 23: hourly_data[hr * 2] += secs
#             c.execute('SELECT interval_idx, SUM(seconds) FROM focus_intervals WHERE log_date = ? GROUP BY interval_idx', (target_date.isoformat(),))
#             for idx, secs in c.fetchall():
#                 if 0 <= idx < 96: hourly_data[idx // 2] += secs
#         except sqlite3.OperationalError:
#             pass 

#         week_heatmap = [[0]*24 for _ in range(7)]
#         try:
#             c.execute('''SELECT log_date, hour, SUM(seconds) FROM focus_hourly WHERE log_date >= ? AND log_date <= ? GROUP BY log_date, hour''', 
#                       (monday.isoformat(), sunday.isoformat()))
#             for ldate, hr, secs in c.fetchall():
#                 day_idx = date.fromisoformat(ldate).weekday()
#                 if 0 <= hr <= 23: week_heatmap[day_idx][hr] += secs
#         except sqlite3.OperationalError:
#             pass

#         minute_data = [0] * 1440
#         try:
#             c.execute('''SELECT minute_idx, SUM(seconds) FROM focus_minutes WHERE log_date >= ? AND log_date <= ? GROUP BY minute_idx''', 
#                       (monday.isoformat(), sunday.isoformat()))
#             for idx, secs in c.fetchall():
#                 if 0 <= idx < 1440: minute_data[idx] += secs
#         except sqlite3.OperationalError:
#             pass

#         peak_str = "N/A"
#         max_sum = 0
#         best_window = None
#         for i in range(1440 - 60):
#             w_sum = sum(minute_data[i:i+60])
#             if w_sum > max_sum and w_sum > 0:
#                 max_sum = w_sum
#                 best_window = (i, i+60)

#         if best_window:
#             start_idx, end_idx = best_window
#             while start_idx < end_idx and minute_data[start_idx] == 0: start_idx += 1
#             actual_end = end_idx - 1
#             while actual_end > start_idx and minute_data[actual_end] == 0: actual_end -= 1
#             s_h, s_m = divmod(start_idx, 60)
#             e_h, e_m = divmod(actual_end, 60)
#             peak_str = f"{s_h:02d}:{s_m:02d} - {e_h:02d}:{e_m:02d}"

#         self.cached_json = {
#             "selected_date": target_date.isoformat(), "total": total_seconds, "average": average_seconds,
#             "week_range": week_range_str, "yesterday": yesterday_seconds, "current": current_app_title,
#             "apps": all_apps, "week_apps": week_apps, "week": week_data, "month": month_data,
#             "hourly": hourly_data, "week_heatmap": week_heatmap, "peak_usage_str": peak_str
#         }
#         self.last_sync = time.time()
#         self.last_date = target_date
        
#     def fast_tick(self, app_class, app_title, write_to_disk=True):
#         now = datetime.now()
#         target_date = now.date()
        
#         self.buffer.append((target_date.isoformat(), app_class, app_title, now))
        
#         if self.cached_json is None or target_date != self.last_date or (time.time() - self.last_sync > 60):
#             self.flush()
#             self.full_sync(target_date)
#         else:
#             d = self.cached_json
#             d["total"] += 1
#             d["current"] = app_title
            
#             found = False
#             for app in d["apps"]:
#                 if app["class"] == app_class:
#                     app["seconds"] += 1
#                     found = True
#                     break
#             if not found:
#                 d["apps"].append({
#                     "class": app_class, "name": app_title, 
#                     "icon": get_app_icon(app_class), "seconds": 1, "percent": 0
#                 })
                
#             for app in d["apps"]:
#                 app["percent"] = round((app["seconds"] / d["total"]) * 100, 1) if d["total"] > 0 else 0
#             d["apps"].sort(key=lambda x: x["seconds"], reverse=True)
            
#             for w in d["week"]:
#                 if w["is_target"]: w["total"] += 1
#             for m in d["month"]:
#                 if m["is_target"]: m["total"] += 1
                
#             hr = now.hour
#             idx = hr * 2 + (1 if now.minute >= 30 else 0)
#             if 0 <= idx < 48: d["hourly"][idx] += 1
                
#             day_idx = now.weekday()
#             if 0 <= hr < 24: d["week_heatmap"][day_idx][hr] += 1
                
#         # Conditionally write to tmpfs
#         if write_to_disk:
#             temp_file = STATE_FILE + ".tmp"
#             try:
#                 with open(temp_file, "w") as f:
#                     json.dump(self.cached_json, f)
#                 os.rename(temp_file, STATE_FILE)
#             except Exception:
#                 pass
            
#         if len(self.buffer) >= 15:
#             self.flush()
            
#     def flush(self):
#         if not self.buffer: return
#         c = self.conn.cursor()
        
#         logs = defaultdict(int)
#         titles = {}
#         hours = defaultdict(int)
#         intervals = defaultdict(int)
#         minutes = defaultdict(int)
        
#         for d_str, cls, title, dt in self.buffer:
#             logs[(d_str, cls)] += 1
#             titles[cls] = title
#             hr = dt.hour
#             hours[(d_str, hr, cls)] += 1
#             minute = hr * 60 + dt.minute
#             intervals[(d_str, minute // 15, cls)] += 1
#             minutes[(d_str, minute, cls)] += 1
            
#         for (d_str, cls), secs in logs.items():
#             c.execute('''INSERT INTO focus_log (log_date, app_class, seconds, app_title) VALUES (?, ?, ?, ?)
#                          ON CONFLICT(log_date, app_class) DO UPDATE SET seconds = seconds + ?, app_title = ?''',
#                       (d_str, cls, secs, titles[cls], secs, titles[cls]))
                      
#         for (d_str, hr, cls), secs in hours.items():
#             c.execute('''INSERT INTO focus_hourly (log_date, hour, app_class, seconds) VALUES (?, ?, ?, ?)
#                          ON CONFLICT(log_date, hour, app_class) DO UPDATE SET seconds = seconds + ?''',
#                       (d_str, hr, cls, secs, secs))
                      
#         for (d_str, itv, cls), secs in intervals.items():
#             c.execute('''INSERT INTO focus_intervals (log_date, interval_idx, app_class, seconds) VALUES (?, ?, ?, ?)
#                          ON CONFLICT(log_date, interval_idx, app_class) DO UPDATE SET seconds = seconds + ?''',
#                       (d_str, itv, cls, secs, secs))
                      
#         for (d_str, min_idx, cls), secs in minutes.items():
#             c.execute('''INSERT INTO focus_minutes (log_date, minute_idx, app_class, seconds) VALUES (?, ?, ?, ?)
#                          ON CONFLICT(log_date, minute_idx, app_class) DO UPDATE SET seconds = seconds + ?''',
#                       (d_str, min_idx, cls, secs, secs))
                      
#         self.conn.commit()
#         self.buffer.clear()

# tracker = DaemonTracker()

# def exit_handler(sig, frame):
#     tracker.flush()
#     sys.exit(0)

# def main():
#     global current_app_class, current_app_title
#     signal.signal(signal.SIGINT, exit_handler)
#     signal.signal(signal.SIGTERM, exit_handler)

#     current_app_class, current_app_title = get_active_window_hyprctl()
    
#     ipc_thread = threading.Thread(target=listen_hyprland_ipc, daemon=True)
#     ipc_thread.start()

#     tick_counter = 0
#     while True:
#         time.sleep(1)
#         tick_counter += 1
#         if current_app_class and current_app_class not in [""]:
#             # Only dump JSON to memory/disk every 5 seconds
#             tracker.fast_tick(current_app_class, current_app_title, write_to_disk=(tick_counter % 5 == 0))

# if __name__ == "__main__":
#     main()

#!/usr/bin/env python3                                                           # Shebang line that tells the system to execute this script using the python3 interpreter found in the user's PATH environment variable
import subprocess                                                                # Imports the subprocess module for spawning external processes (like hyprctl), connecting to their pipes, and capturing their output
import sqlite3                                                                   # Imports the sqlite3 module for creating and managing the SQLite database that stores focus time tracking data persistently
import time                                                                      # Imports the time module for time-related functions like sleep(), and for tracking sync intervals with time.time()
import os                                                                        # Imports the os module for operating system interactions: file paths, directory creation, environment variables, and file operations
import socket                                                                    # Imports the socket module for creating Unix domain socket connections to communicate with Hyprland's IPC socket for real-time window events
import json                                                                      # Imports the json module for serializing and deserializing JSON data, used for parsing hyprctl output and writing the state cache file
import threading                                                                 # Imports the threading module to run the Hyprland IPC listener in a separate daemon thread concurrently with the main tracking loop
import calendar                                                                  # Imports the calendar module for getting month ranges and weekday calculations used in the monthly view data generation
import re                                                                        # Imports the re module for regular expression operations: parsing application names, cleaning titles, and matching patterns in desktop file processing
import signal                                                                    # Imports the signal module to handle Unix signals (SIGINT, SIGTERM) for graceful shutdown, ensuring buffered data is flushed to disk before exit
import sys                                                                       # Imports the sys module for system-specific parameters and functions, including sys.exit() for clean program termination
from datetime import date, datetime, timedelta                                   # Imports date for calendar date handling, datetime for timestamps, and timedelta for date arithmetic (calculating yesterday, week ranges, etc.)
from collections import defaultdict                                              # Imports defaultdict which provides dictionaries with default values, used to efficiently accumulate tracking data without checking for key existence

current_app_class = "Desktop"                                                    # Global variable that tracks the class/identifier of the currently focused application window; initialized to "Desktop" as the default state
current_app_title = "Desktop"                                                    # Global variable that tracks the human-readable display name of the currently focused application; initialized to "Desktop" matching the default state

DB_DIR = os.path.expanduser("~/.local/share/focustime")                         # Constructs the full path to the database directory by expanding the tilde to the user's home directory and appending the focustime subdirectory under .local/share
os.makedirs(DB_DIR, exist_ok=True)                                              # Creates the database directory if it doesn't exist; exist_ok=True prevents errors if the directory already exists (idempotent operation)
DB_PATH = os.path.join(DB_DIR, "focustime.db")                                  # Joins the database directory path with the filename "focustime.db" to create the complete path to the SQLite database file

# Cache fallback adheres to tmpfs priority but securely falls back              # Comment explaining the state file location strategy: prefers tmpfs (XDG_RUNTIME_DIR) for speed, but falls back to a cache directory for durability
XDG_RUNTIME = os.environ.get("XDG_RUNTIME_DIR")                                 # Attempts to get the XDG_RUNTIME_DIR environment variable which points to a tmpfs (RAM-based) directory for runtime files; returns None if not set
if not XDG_RUNTIME:                                                              # If XDG_RUNTIME_DIR is not available (shouldn't happen on modern Linux but added as a safety check)
    XDG_RUNTIME = os.path.expanduser("~/.cache/focustime")                      # Falls back to a focustime subdirectory under ~/.cache as the runtime directory for storing temporary state
    os.makedirs(XDG_RUNTIME, exist_ok=True)                                     # Creates the fallback cache directory if it doesn't already exist
STATE_FILE = os.path.join(XDG_RUNTIME, "focustime_state.json")                  # Constructs the full path to the JSON state file that caches the current tracking statistics for quick access by the QML frontend

DESKTOP_CACHE_NAME = {}                                                          # Initializes an empty dictionary that will cache the mapping from application identifiers (class names, WM classes) to human-readable application names
DESKTOP_CACHE_ICON = {}                                                          # Initializes an empty dictionary that will cache the mapping from application identifiers to their icon names (from .desktop files)
CACHE_BUILT = False                                                              # Boolean flag indicating whether the desktop file cache has been built; starts as False and is set to True after the first build to avoid repeated filesystem scans
SYSTEM_STATES = {"Desktop", "Locked", "Quickshell", "Unknown"}                  # A set of special state names that represent system-level states rather than actual applications; used to avoid unnecessary lookups for these states

def get_xdg_search_dirs():                                                       # Defines a function that returns a list of directories where .desktop files are located, following the XDG specification for application entries
    search_dirs = []                                                             # Initializes an empty list that will collect all directories to search for .desktop files
    xdg_data_home = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))  # Gets the XDG_DATA_HOME environment variable, defaulting to ~/.local/share if not set (standard location for user-specific data files)
    search_dirs.append(os.path.join(xdg_data_home, "applications"))              # Adds the user's applications directory (e.g., ~/.local/share/applications) as the first search location
    
    xdg_data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share")  # Gets the XDG_DATA_DIRS environment variable (colon-separated list of system data directories), defaulting to the standard system paths
    for d in xdg_data_dirs.split(":"):                                           # Iterates through each colon-separated directory in the XDG_DATA_DIRS string
        if d.strip():                                                             # Checks if the directory string is not empty after stripping whitespace (skips empty entries that might result from trailing colons)
            search_dirs.append(os.path.join(d, "applications"))                   # Appends the "applications" subdirectory for each system data directory (e.g., /usr/local/share/applications, /usr/share/applications)

    fallback_dirs = [                                                            # Defines a list of fallback directories where .desktop files might exist outside the standard XDG paths
        "/var/lib/flatpak/exports/share/applications",                            # Flatpak applications store their .desktop files in this exports directory
        "/var/lib/snapd/desktop/applications"                                    # Snap packages store their .desktop files in this snap-specific directory
    ]
    for d in fallback_dirs:                                                      # Iterates through each fallback directory
        if d not in search_dirs:                                                  # Checks if the directory is already in the search list (avoids duplicates)
            search_dirs.append(d)                                                 # Adds the fallback directory to the search list if it wasn't already included
    return search_dirs                                                            # Returns the complete list of directories to search for .desktop files

def build_desktop_cache():                                                       # Defines a function that scans all .desktop files and builds lookup dictionaries for application names and icons
    global CACHE_BUILT                                                            # Declares that we're modifying the global CACHE_BUILT flag
    if CACHE_BUILT: return                                                       # If the cache has already been built, exit the function immediately to avoid redundant filesystem scanning
    
    for directory in get_xdg_search_dirs():                                      # Iterates through every directory returned by the XDG search dirs function
        if not os.path.exists(directory): continue                               # If the directory doesn't exist on this system, skip to the next one
        try:                                                                      # Opens a try block to handle permission errors or other filesystem exceptions gracefully
            for f in os.listdir(directory):                                       # Lists all files in the current directory
                if f.endswith(".desktop"):                                        # Only processes files that have the .desktop extension (application launcher files)
                    path = os.path.join(directory, f)                             # Constructs the full path to the .desktop file
                    try:                                                          # Nested try block for handling individual file parsing errors
                        name, icon, wmclass = None, "", None                     # Initializes variables: name=None (not found yet), icon="" (empty default), wmclass=None (not found yet)
                        with open(path, 'r', encoding='utf-8') as file:          # Opens the .desktop file for reading with UTF-8 encoding to handle international characters
                            for line in file:                                     # Reads the file line by line
                                line = line.strip()                                # Removes leading/trailing whitespace from the current line
                                if line.startswith("Name=") and not name:         # If the line defines the application name and we haven't found a name yet (first Name= entry is usually the primary)
                                    name = line.split("=", 1)[1].strip()          # Splits the line on the first equals sign and takes the value part (everything after "Name="), then strips whitespace
                                elif line.startswith("Icon=") and not icon:       # If the line defines the icon and we haven't found one yet
                                    icon = line.split("=", 1)[1].strip()          # Extracts the icon name/value from after "Icon="
                                elif line.startswith("StartupWMClass="):          # If the line defines the WM_CLASS property (used by X11/Wayland to identify windows)
                                    wmclass = line.split("=", 1)[1].strip().lower()  # Extracts the WM class and converts it to lowercase for case-insensitive matching
                        
                        if name:                                                  # If we successfully extracted an application name from the file
                            base = f[:-8].lower()                                 # Creates a base identifier from the filename by removing the ".desktop" suffix (last 8 characters) and converting to lowercase
                            DESKTOP_CACHE_NAME[base] = name                       # Maps the base filename (without .desktop) to the human-readable application name
                            DESKTOP_CACHE_ICON[base] = icon                       # Maps the base filename to the icon name
                            if wmclass:                                           # If a StartupWMClass was found in the file
                                DESKTOP_CACHE_NAME[wmclass] = name                 # Also maps the WM class to the application name (allows lookup by window class)
                                DESKTOP_CACHE_ICON[wmclass] = icon                 # Also maps the WM class to the icon name
                    except Exception:                                              # Catches any exception during parsing of an individual .desktop file
                        pass                                                       # Silently ignores parsing errors for individual files (corrupted or unreadable files)
        except Exception:                                                          # Catches any exception during directory listing (permission errors, etc.)
            pass                                                                   # Silently ignores directories that can't be read
    CACHE_BUILT = True                                                             # Marks the cache as successfully built so subsequent calls skip the scanning process

def resolve_app_name(app_class, raw_title):                                      # Defines a function that converts a raw application class to a clean, human-readable name using the desktop cache and title cleaning
    if not app_class or app_class in SYSTEM_STATES:                              # If the app_class is empty/None OR it's one of the predefined system states (Desktop, Locked, etc.)
        return app_class if app_class else "Unknown"                             # Return the system state name itself, or "Unknown" if app_class is empty
        
    build_desktop_cache()                                                         # Ensures the desktop cache is built before attempting lookups
    app_class_lower = app_class.lower()                                           # Converts the application class to lowercase for case-insensitive matching
    base_class = re.sub(r'[-_ ]?updater$', '', app_class_lower)                  # Removes optional "updater" suffix (with or without dash/underscore/space prefix) from the class name, as apps often have separate updater processes
    base_class = base_class.replace('.exe', '')                                  # Removes ".exe" suffix that might appear in Windows applications running through Wine/Proton

    if app_class_lower in DESKTOP_CACHE_NAME: return DESKTOP_CACHE_NAME[app_class_lower]  # If the exact lowercase class is in the cache, return the corresponding human-readable name immediately
    if base_class in DESKTOP_CACHE_NAME: return DESKTOP_CACHE_NAME[base_class]    # If the base class (without updater suffix) is in the cache, return that name

    clean_title = re.sub(r'^\(\d+\)\s*|^\[\d+\]\s*', '', raw_title)             # Cleans the window title by removing leading parenthesized or bracketed numbers (like "(5) Firefox" or "[12] Terminal") that some apps prepend
    clean_title = re.sub(r'\s*\(\d+\)$', '', clean_title)                        # Also removes trailing parenthesized numbers (like "App (2)") from the end of the title
    parts = re.split(r'\s+[-—|]\s+', clean_title)                                # Splits the title on common separators (dash, em-dash, or pipe surrounded by spaces) to handle apps that include document names
    name = parts[-1].strip() if len(parts) > 1 else clean_title.strip()         # Takes the last part after splitting (usually the app name, not the document), or the whole title if no separator was found

    if len(name) > 25: name = app_class.capitalize()                            # If the resolved name is longer than 25 characters, fall back to using the capitalized class name to avoid overly long display names

    DESKTOP_CACHE_NAME[app_class_lower] = name                                   # Caches the newly resolved name for this class so future lookups are instant
    return name                                                                   # Returns the resolved application name

def get_app_icon(app_class):                                                     # Defines a function that returns the icon name for a given application class by looking up the desktop cache
    if not app_class or app_class in SYSTEM_STATES:                              # If the class is empty or a system state (Desktop, Locked, etc.)
        return ""                                                                 # Return empty string since system states don't have application icons
        
    build_desktop_cache()                                                         # Ensures the desktop cache is built before lookups
    app_class_lower = app_class.lower()                                           # Converts to lowercase for case-insensitive matching
    base_class = re.sub(r'[-_ ]?updater$', '', app_class_lower)                  # Removes the updater suffix variant, same as in resolve_app_name
    base_class = base_class.replace('.exe', '')                                  # Removes .exe suffix for Wine/Proton applications

    if app_class_lower in DESKTOP_CACHE_ICON: return DESKTOP_CACHE_ICON[app_class_lower]  # If the exact class exists in the icon cache, return its icon name
    if base_class in DESKTOP_CACHE_ICON: return DESKTOP_CACHE_ICON[base_class]    # If the base class (sans updater) exists, return that icon name

    return ""                                                                     # Returns empty string if no icon was found for this application class

def init_db():                                                                   # Defines a function that initializes the SQLite database, creating all necessary tables and indexes, and handles schema migration
    conn = sqlite3.connect(DB_PATH)                                              # Opens a connection to the SQLite database file; creates it if it doesn't exist
    c = conn.cursor()                                                             # Creates a cursor object to execute SQL commands on the database
    c.execute('''CREATE TABLE IF NOT EXISTS focus_log (log_date TEXT, app_class TEXT, seconds INTEGER, app_title TEXT, PRIMARY KEY (log_date, app_class))''')  # Creates the main focus log table with columns for date, application class, accumulated seconds, and display title; the primary key is the combination of date and app class (one row per app per day)
    c.execute('CREATE INDEX IF NOT EXISTS idx_log_date ON focus_log(log_date)')  # Creates an index on the log_date column for faster date-range queries when generating weekly/monthly reports
    c.execute('''CREATE TABLE IF NOT EXISTS focus_hourly (log_date TEXT, hour INTEGER, app_class TEXT, seconds INTEGER, PRIMARY KEY (log_date, hour, app_class))''')  # Creates the hourly aggregation table storing seconds spent per hour per app per day for granular time distribution analysis
    c.execute('''CREATE TABLE IF NOT EXISTS focus_intervals (log_date TEXT, interval_idx INTEGER, app_class TEXT, seconds INTEGER, PRIMARY KEY (log_date, interval_idx, app_class))''')  # Creates the 15-minute interval table for finer-grained tracking; interval_idx ranges from 0-95 (24 hours * 4 intervals)
    c.execute('''CREATE TABLE IF NOT EXISTS focus_minutes (log_date TEXT, minute_idx INTEGER, app_class TEXT, seconds INTEGER, PRIMARY KEY (log_date, minute_idx, app_class))''')  # Creates the per-minute table for high-resolution tracking; minute_idx ranges from 0-1439 (24 hours * 60 minutes)
    
    c.execute("PRAGMA table_info(focus_log)")                                    # Queries the schema of the focus_log table to get column information for migration checks
    if 'app_title' not in [row[1] for row in c.fetchall()]:                     # Extracts column names (index 1) from the pragma result; checks if 'app_title' column exists (for databases created before this feature was added)
        c.execute('ALTER TABLE focus_log ADD COLUMN app_title TEXT')             # If app_title column doesn't exist, adds it to the table (schema migration without data loss)
        
    conn.commit()                                                                 # Commits all table creation and migration changes to the database
    return conn                                                                   # Returns the database connection object for use by the tracker

def get_active_window_hyprctl():                                                 # Defines a function that queries Hyprland for the currently active/focused window and returns its class and cleaned name
    try:                                                                          # Opens a try block to handle cases where hyprctl is unavailable or returns errors
        output = subprocess.check_output(['hyprctl', 'activewindow', '-j'], text=True)  # Runs 'hyprctl activewindow -j' to get the active window info in JSON format, capturing the output as a string
        if output.strip() == "{}": return "Desktop", "Desktop"                  # If the output is an empty JSON object (no window is focused, meaning the desktop is showing), return the Desktop state
        data = json.loads(output)                                                 # Parses the JSON output into a Python dictionary
        
        app_cls = data.get('initialClass') or data.get('class') or ''           # Gets the window class: prefers 'initialClass' (set at launch) over 'class' (which may change), defaults to empty string if neither exists
        raw_title = data.get('initialTitle') or data.get('title') or ''         # Gets the window title: prefers 'initialTitle' over 'title', defaults to empty string

        if "quickshell" in app_cls.lower() or "qs-master" in raw_title.lower() or "qs-master" in app_cls.lower():  # Checks multiple fields for the Quickshell identifier to detect when the Quickshell overlay is focused
            return "Quickshell", "Quickshell"                                    # Returns the special Quickshell state if detected, so time spent in the launcher is categorized separately
            
        app_cls = app_cls if app_cls else "Unknown"                             # If app_cls is empty after the check, assigns "Unknown" as the fallback class
        raw_title = raw_title if raw_title else app_cls                          # If raw_title is empty, uses the app class as the title fallback
        clean_name = resolve_app_name(app_cls, raw_title)                        # Resolves the raw class to a human-readable name using the desktop cache and title cleaning logic
        return app_cls, clean_name                                                # Returns both the raw class (for internal tracking) and the cleaned display name
    except Exception:                                                             # Catches any exception (hyprctl not found, JSON parse error, etc.)
        return "Unknown", "Unknown"                                               # Returns "Unknown" state when the active window cannot be determined

def is_locked():                                                                 # Defines a function that checks if the session is currently locked (hyprlock is running)
    try:                                                                          # Opens a try block since pgrep will raise CalledProcessError if the process is not found
        subprocess.check_output(['pgrep', '-x', 'hyprlock'])                    # Runs pgrep with exact match (-x) to check if a process named exactly "hyprlock" is running
        return True                                                               # If pgrep succeeds (hyprlock is running), return True indicating the session is locked
    except subprocess.CalledProcessError:                                        # Catches the exception raised when pgrep doesn't find the process
        return False                                                              # Returns False indicating the session is not locked

def listen_hyprland_ipc():                                                       # Defines a function that connects to Hyprland's socket2 IPC to receive real-time window focus change events; runs in a daemon thread
    global current_app_class, current_app_title                                  # Declares these as global variables so changes in this thread are visible to the main thread
    hypr_sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")                    # Gets Hyprland's instance signature from the environment variable; this unique identifier is set by Hyprland itself
    if not hypr_sig: return                                                      # If the signature is not set (not running under Hyprland), exit the function immediately

    sock_path = f"{XDG_RUNTIME}/hypr/{hypr_sig}/.socket2.sock"                  # Constructs the primary path to Hyprland's socket2 event socket using the XDG runtime directory and instance signature
    if not os.path.exists(sock_path):                                             # If the primary socket path doesn't exist (some configurations use a different location)
        sock_path = f"/tmp/hypr/{hypr_sig}/.socket2.sock"                        # Tries the alternative location under /tmp/hypr as a fallback

    while True:                                                                   # Starts an infinite loop to continuously monitor the socket (reconnects if connection is lost)
        try:                                                                      # Opens a try block for socket connection and reading
            client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)           # Creates a new Unix domain socket for stream-based communication
            client.connect(sock_path)                                             # Connects the socket to Hyprland's IPC socket path
            buffer = ""                                                           # Initializes an empty string buffer to accumulate data received from the socket
            while True:                                                           # Inner loop for continuously reading events from the connected socket
                data = client.recv(4096).decode('utf-8')                         # Receives up to 4096 bytes of data from the socket and decodes it from UTF-8 to a string
                if not data: break                                                # If no data was received (connection closed by the server), break out of the inner loop to reconnect
                buffer += data                                                    # Appends the received data to the buffer
                while '\n' in buffer:                                             # While there are complete lines (separated by newline) in the buffer
                    line, buffer = buffer.split('\n', 1)                          # Splits the buffer at the first newline, extracting the first complete line and keeping the rest in the buffer
                    if line.startswith('activewindow>>'):                         # Checks if the line is an activewindow change event (the prefix used by Hyprland for window focus changes)
                        cls, clean_title = get_active_window_hyprctl()            # Gets the current active window class and cleaned title from hyprctl
                        if is_locked() or cls == "hyprlock":                      # Checks if the session is locked or if the focused window is hyprlock itself
                            current_app_class, current_app_title = "Locked", "Locked"  # If locked, sets both global variables to "Locked"
                        else:                                                      # If not locked
                            current_app_class, current_app_title = cls, clean_title  # Updates the global variables with the newly focused application's class and display name
        except Exception:                                                          # Catches any exception (socket errors, connection failures, etc.)
            time.sleep(2)                                                          # Waits 2 seconds before attempting to reconnect, preventing tight error loops


class DaemonTracker:                                                              # Defines the main tracker class that manages data collection, buffering, synchronization, and statistics generation
    def __init__(self):                                                           # Constructor method called when creating a DaemonTracker instance
        self.conn = init_db()                                                     # Initializes the database connection and ensures all tables exist; stores the connection for later use
        self.buffer = []                                                          # Initializes an empty list that acts as a write buffer: accumulates tracking data before batch-inserting into the database
        self.cached_json = None                                                   # Stores the current computed statistics as a JSON-serializable dictionary; None means no cache exists yet
        self.last_sync = 0                                                        # Timestamp of the last full synchronization (database query to rebuild statistics); initialized to epoch 0
        self.last_date = date.today()                                             # Stores the date of the last full sync; initialized to today's date to trigger an immediate sync on first tick
        
    def full_sync(self, target_date):                                             # Method that performs a complete database query to rebuild all statistics for a given target date
        c = self.conn.cursor()                                                    # Gets a database cursor for executing queries
        
        yesterday = target_date - timedelta(days=1)                               # Calculates yesterday's date by subtracting one day from the target date
        c.execute('SELECT SUM(seconds) FROM focus_log WHERE log_date = ?', (yesterday.isoformat(),))  # Queries the total seconds tracked for yesterday
        yesterday_seconds = c.fetchone()[0] or 0                                  # Fetches the result; if NULL (no data), defaults to 0

        monday = target_date - timedelta(days=target_date.weekday())             # Calculates the Monday of the current week by subtracting the weekday number (0=Monday, 6=Sunday)
        sunday = monday + timedelta(days=6)                                       # Calculates the Sunday of the current week by adding 6 days to Monday
        week_range_str = f"{monday.strftime('%b')} {monday.day} - {sunday.strftime('%b')} {sunday.day}"  # Formats a human-readable week range string like "Mar 10 - Mar 16"

        c.execute('''SELECT COUNT(DISTINCT log_date), SUM(seconds) FROM focus_log 
                     WHERE log_date >= ? AND log_date <= ? AND seconds > 0''', (monday.isoformat(), sunday.isoformat()))  # Counts distinct days with activity and sums total seconds for the current week
        row = c.fetchone()                                                        # Fetches the single result row
        days_count = row[0] or 0                                                  # Extracts the count of distinct days with tracking data; defaults to 0
        total_week = row[1] or 0                                                  # Extracts the total seconds for the week; defaults to 0
        average_seconds = total_week // days_count if days_count > 0 else 0      # Calculates the daily average for the week using integer division; avoids division by zero
        
        c.execute('SELECT SUM(seconds) FROM focus_log WHERE log_date = ?', (target_date.isoformat(),))  # Queries the total seconds tracked for the target date
        total_seconds = c.fetchone()[0] or 0                                      # Fetches the total; defaults to 0 if no data exists for that date

        c.execute('''SELECT app_class, COALESCE(app_title, app_class), SUM(seconds) as secs 
                     FROM focus_log WHERE log_date = ? GROUP BY app_class ORDER BY secs DESC''', (target_date.isoformat(),))  # Queries all applications tracked on the target date, grouped by app class, ordered by most time spent; uses COALESCE to fall back to app_class if app_title is null
        all_apps = []                                                              # Initializes an empty list to store application data dictionaries
        for row in c.fetchall():                                                   # Iterates through each row from the query result
            app_class, app_title, secs = row                                       # Unpacks the row into app class, display title, and total seconds
            all_apps.append({                                                      # Appends a dictionary with all computed application statistics
                "class": app_class, "name": app_title, "icon": get_app_icon(app_class),  # Stores the class, display name, and icon path/name
                "seconds": secs, "percent": round((secs / total_seconds) * 100, 1) if total_seconds > 0 else 0  # Calculates the percentage of total time spent on this app, rounded to 1 decimal; avoids division by zero
            })

        c.execute('''SELECT app_class, COALESCE(app_title, app_class), SUM(seconds) as secs FROM focus_log 
                     WHERE log_date >= ? AND log_date <= ? GROUP BY app_class ORDER BY secs DESC LIMIT 50''', 
                  (monday.isoformat(), sunday.isoformat()))                        # Queries the top 50 applications for the entire week, ordered by total time
        week_apps_rows = c.fetchall()                                              # Fetches all weekly application rows
        week_apps_total = sum([r[2] for r in week_apps_rows])                     # Sums the seconds from all week apps to calculate total weekly tracked time
        week_apps = []                                                             # Initializes empty list for weekly app statistics
        for r in week_apps_rows:                                                   # Iterates through each weekly application row
            cls, title, secs = r                                                    # Unpacks class, title, and seconds
            week_apps.append({                                                      # Appends a dictionary for each weekly app
                "class": cls, "name": title, "icon": get_app_icon(cls),            # Stores class, name, and icon
                "seconds": secs, "percent": round((secs / week_apps_total) * 100, 1) if week_apps_total > 0 else 0  # Calculates percentage of weekly total
            })

        c.execute('SELECT log_date, SUM(seconds) FROM focus_log WHERE log_date >= ? AND log_date <= ? GROUP BY log_date', 
                 (monday.isoformat(), sunday.isoformat()))                          # Queries daily totals for each day of the current week
        week_map = {r[0]: r[1] for r in c.fetchall()}                              # Creates a dictionary mapping date strings to total seconds for quick lookup
        days_str = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]              # List of abbreviated day names for display
        week_data = []                                                              # Initializes list for weekly day data
        for i in range(7):                                                          # Iterates through each day of the week (0=Monday, 6=Sunday)
            d_str = (monday + timedelta(days=i)).isoformat()                        # Calculates the ISO date string for each day
            week_data.append({"date": d_str, "day": days_str[i], "total": week_map.get(d_str, 0), "is_target": d_str == target_date.isoformat()})  # Creates a day entry with date, abbreviated name, total seconds (0 if no data), and whether this is the target/selected day

        first_day = target_date.replace(day=1)                                     # Gets the first day of the target month by replacing the day component with 1
        _, num_days = calendar.monthrange(target_date.year, target_date.month)    # Returns a tuple of (weekday of first day, number of days in month); we only need the number of days
        last_day = target_date.replace(day=num_days)                               # Creates a date object for the last day of the month
        c.execute('SELECT log_date, SUM(seconds) FROM focus_log WHERE log_date >= ? AND log_date <= ? GROUP BY log_date', 
                 (first_day.isoformat(), last_day.isoformat()))                    # Queries daily totals for all days in the target month
        month_map = {r[0]: r[1] for r in c.fetchall()}                             # Creates a dictionary mapping month dates to total seconds
        
        month_data = [{"date": "", "total": -1, "is_target": False} for _ in range(first_day.weekday())]  # Creates padding entries for days before the 1st of the month (empty slots to align the calendar grid); total=-1 indicates no data cell
        for i in range(1, num_days + 1):                                            # Iterates through each day of the month (1 to total days)
            d_str = target_date.replace(day=i).isoformat()                           # Creates ISO date string for the current day
            month_data.append({"date": d_str, "total": month_map.get(d_str, 0), "is_target": d_str == target_date.isoformat()})  # Adds the month day entry with date, total seconds, and target flag

        hourly_data = [0] * 48                                                      # Initializes a list of 48 zeros (one slot per half-hour in a day: 24 * 2 = 48)
        try:                                                                         # Opens a try block in case the hourly table doesn't exist yet
            c.execute('SELECT hour, SUM(seconds) FROM focus_hourly WHERE log_date = ? GROUP BY hour', (target_date.isoformat(),))  # Queries hourly totals for the target date
            for hr, secs in c.fetchall():                                            # Iterates through each hour's data
                if 0 <= hr <= 23: hourly_data[hr * 2] += secs                       # Maps each hour to its corresponding half-hour slot (hour 0 -> index 0, hour 1 -> index 2, etc.)
            c.execute('SELECT interval_idx, SUM(seconds) FROM focus_intervals WHERE log_date = ? GROUP BY interval_idx', (target_date.isoformat(),))  # Queries 15-minute interval data
            for idx, secs in c.fetchall():                                           # Iterates through interval data
                if 0 <= idx < 96: hourly_data[idx // 2] += secs                     # Maps 15-minute intervals to half-hour slots (intervals 0-1 -> slot 0, intervals 2-3 -> slot 1, etc.)
        except sqlite3.OperationalError:                                             # Catches database operational errors (e.g., table doesn't exist on first run)
            pass                                                                      # Silently passes if tables aren't ready yet

        week_heatmap = [[0]*24 for _ in range(7)]                                    # Creates a 7x24 grid (7 days, 24 hours) for the weekly heatmap visualization; initializes all cells to 0
        try:                                                                         # Opens try block for the heatmap query
            c.execute('''SELECT log_date, hour, SUM(seconds) FROM focus_hourly WHERE log_date >= ? AND log_date <= ? GROUP BY log_date, hour''', 
                      (monday.isoformat(), sunday.isoformat()))                      # Queries hourly data for the entire week
            for ldate, hr, secs in c.fetchall():                                     # Iterates through each day-hour combination
                day_idx = date.fromisoformat(ldate).weekday()                        # Gets the weekday number (0=Monday) from the date string
                if 0 <= hr <= 23: week_heatmap[day_idx][hr] += secs                  # Accumulates seconds into the appropriate day/hour cell
        except sqlite3.OperationalError:                                             # Catches table-not-found errors
            pass                                                                      # Silently continues with empty heatmap

        minute_data = [0] * 1440                                                     # Creates a list of 1440 zeros (one slot per minute in a day: 24 * 60 = 1440)
        try:                                                                         # Opens try block for minute-level data
            c.execute('''SELECT minute_idx, SUM(seconds) FROM focus_minutes WHERE log_date >= ? AND log_date <= ? GROUP BY minute_idx''', 
                      (monday.isoformat(), sunday.isoformat()))                      # Queries minute-level data for the entire week
            for idx, secs in c.fetchall():                                           # Iterates through each minute index
                if 0 <= idx < 1440: minute_data[idx] += secs                        # Accumulates seconds into the minute array
        except sqlite3.OperationalError:                                             # Catches table-not-found errors
            pass                                                                      # Silently continues with empty minute data        peak_str = "N/A"                                                             # Default peak usage string when no data is available
        max_sum = 0                                                                   # Tracks the maximum total seconds found in any 60-minute window
        best_window = None                                                            # Stores the (start_index, end_index) of the best 60-minute window found
        for i in range(1440 - 60):                                                   # Slides a 60-minute window across all 1440 minutes (stops at 1380 so window doesn't exceed bounds)
            w_sum = sum(minute_data[i:i+60])                                          # Sums the seconds in the current 60-minute window
            if w_sum > max_sum and w_sum > 0:                                        # If this window has more activity than the previous best AND has at least some activity
                max_sum = w_sum                                                        # Updates the maximum sum
                best_window = (i, i+60)                                               # Stores this window's boundaries

        if best_window:                                                               # If a peak window was found with activity
            start_idx, end_idx = best_window                                           # Unpacks the start and end indices
            while start_idx < end_idx and minute_data[start_idx] == 0: start_idx += 1  # Trims leading zeros from the window to find when activity actually starts
            actual_end = end_idx - 1                                                    # Sets the end index to the last minute of the window
            while actual_end > start_idx and minute_data[actual_end] == 0: actual_end -= 1  # Trims trailing zeros to find when activity ends
            s_h, s_m = divmod(start_idx, 60)                                           # Converts the start minute index to hours and minutes using divmod
            e_h, e_m = divmod(actual_end, 60)                                          # Converts the end minute index to hours and minutes
            peak_str = f"{s_h:02d}:{s_m:02d} - {e_h:02d}:{e_m:02d}"                  # Formats the peak time range as "HH:MM - HH:MM" with zero-padded numbers

        self.cached_json = {                                                          # Builds the complete statistics dictionary that will be cached and served to the frontend
            "selected_date": target_date.isoformat(), "total": total_seconds, "average": average_seconds,  # Stores the target date, daily total, and daily average
            "week_range": week_range_str, "yesterday": yesterday_seconds, "current": current_app_title,  # Stores week range string, yesterday's total, and the currently focused app name
            "apps": all_apps, "week_apps": week_apps, "week": week_data, "month": month_data,  # Stores application breakdowns for today and the week, plus week and month day arrays
            "hourly": hourly_data, "week_heatmap": week_heatmap, "peak_usage_str": peak_str  # Stores hourly distribution, weekly heatmap grid, and the formatted peak usage time string
        }
        self.last_sync = time.time()                                                  # Records the current timestamp as the last sync time for throttle calculations
        self.last_date = target_date                                                  # Updates the last sync date to the current target date
        
    def fast_tick(self, app_class, app_title, write_to_disk=True):                   # Method called every second by the main loop to increment tracking counters for the current app
        now = datetime.now()                                                          # Gets the current datetime including both date and time components
        target_date = now.date()                                                      # Extracts just the date portion for database operations
        
        self.buffer.append((target_date.isoformat(), app_class, app_title, now))     # Adds a new tracking entry to the write buffer as a tuple: (date string, app class, app title, datetime object)
        
        if self.cached_json is None or target_date != self.last_date or (time.time() - self.last_sync > 60):  # Checks if we need a full sync: no cache exists, date changed (midnight rollover), or more than 60 seconds since last sync
            self.flush()                                                               # Flushes all buffered data to the database before rebuilding the cache
            self.full_sync(target_date)                                                # Performs a complete database query to rebuild all statistics for the new date
        else:                                                                          # If we can do a fast incremental update (same date, recent sync)
            d = self.cached_json                                                       # Gets a reference to the current cached statistics dictionary
            d["total"] += 1                                                            # Increments the total seconds counter by 1 (one second has passed)
            d["current"] = app_title                                                   # Updates the current application name display
            
            found = False                                                               # Flag to track whether the current app already exists in the apps list
            for app in d["apps"]:                                                       # Iterates through the daily applications list
                if app["class"] == app_class:                                           # If this app is already in the list
                    app["seconds"] += 1                                                  # Increments its seconds counter by 1
                    found = True                                                         # Marks as found
                    break                                                                # Exits the loop since we found the app
            if not found:                                                                # If the app wasn't in the list (new app for today)
                d["apps"].append({                                                       # Adds a new entry to the apps list
                    "class": app_class, "name": app_title,                              # Stores the app class and display name
                    "icon": get_app_icon(app_class), "seconds": 1, "percent": 0         # Adds icon, initializes seconds to 1, percent starts at 0
                })
                
            for app in d["apps"]:                                                        # Iterates through all apps to recalculate percentages
                app["percent"] = round((app["seconds"] / d["total"]) * 100, 1) if d["total"] > 0 else 0  # Recalculates each app's percentage of total time, rounded to 1 decimal place
            d["apps"].sort(key=lambda x: x["seconds"], reverse=True)                    # Sorts the apps list by seconds descending so the frontend shows the most used apps first
            
            for w in d["week"]:                                                          # Iterates through the week day data
                if w["is_target"]: w["total"] += 1                                      # If this day entry is the target/current day, increments its total by 1
            for m in d["month"]:                                                         # Iterates through the month day data
                if m["is_target"]: m["total"] += 1                                      # If this month entry is the current day, increments its total
                
            hr = now.hour                                                                # Gets the current hour (0-23)
            idx = hr * 2 + (1 if now.minute >= 30 else 0)                              # Calculates the half-hour index: hour*2 gives the base, add 1 if we're in the second half of the hour
            if 0 <= idx < 48: d["hourly"][idx] += 1                                    # If the index is within bounds, increments that half-hour slot by 1
                
            day_idx = now.weekday()                                                      # Gets the current day of the week (0=Monday)
            if 0 <= hr < 24: d["week_heatmap"][day_idx][hr] += 1                       # If the hour is valid, increments the heatmap cell for the current day and hour
            
        # Conditionally write to tmpfs                                                  # Comment indicating the state file writing logic
        if write_to_disk:                                                                # If the write_to_disk flag is True (every 5th tick)
            temp_file = STATE_FILE + ".tmp"                                              # Creates a temporary filename by appending .tmp to avoid corruption during writing
            try:                                                                         # Opens try block for file writing
                with open(temp_file, "w") as f:                                          # Opens the temp file for writing
                    json.dump(self.cached_json, f)                                       # Serializes the cached statistics dictionary to JSON and writes it to the temp file
                os.rename(temp_file, STATE_FILE)                                         # Atomically renames the temp file to the actual state file (prevents partial reads if the frontend reads during writing)
            except Exception:                                                             # Catches any file writing errors
                pass                                                                      # Silently ignores write failures (state file is a cache, database is the authoritative source)
            
        if len(self.buffer) >= 15:                                                       # If the write buffer has accumulated 15 or more entries
            self.flush()                                                                  # Flush all buffered entries to the database for persistence
            
    def flush(self):                                                                    # Method that writes all buffered tracking data to the SQLite database in batch inserts
        if not self.buffer: return                                                       # If the buffer is empty, there's nothing to flush; return immediately
        c = self.conn.cursor()                                                           # Gets a database cursor
        
        logs = defaultdict(int)                                                           # Creates a defaultdict for main log entries (date+class -> total seconds)
        titles = {}                                                                       # Dictionary to store the most recent title for each app class
        hours = defaultdict(int)                                                          # defaultdict for hourly aggregations (date+hour+class -> seconds)
        intervals = defaultdict(int)                                                      # defaultdict for 15-minute interval aggregations
        minutes = defaultdict(int)                                                        # defaultdict for per-minute aggregations
        
        for d_str, cls, title, dt in self.buffer:                                        # Iterates through each buffered tracking entry
            logs[(d_str, cls)] += 1                                                        # Increments the daily total for this app class
            titles[cls] = title                                                            # Updates the title for this class (last one wins, which is fine for display)
            hr = dt.hour                                                                   # Extracts the hour from the datetime object
            hours[(d_str, hr, cls)] += 1                                                  # Increments the hourly counter
            minute = hr * 60 + dt.minute                                                   # Calculates the absolute minute of the day (0-1439)
            intervals[(d_str, minute // 15, cls)] += 1                                   # Increments the 15-minute interval counter (0-95)
            minutes[(d_str, minute, cls)] += 1                                           # Increments the per-minute counter
            
        for (d_str, cls), secs in logs.items():                                           # Iterates through the aggregated daily log entries
            c.execute('''INSERT INTO focus_log (log_date, app_class, seconds, app_title) VALUES (?, ?, ?, ?)
                         ON CONFLICT(log_date, app_class) DO UPDATE SET seconds = seconds + ?, app_title = ?''',
                      (d_str, cls, secs, titles[cls], secs, titles[cls]))                  # Performs an UPSERT: inserts a new row or updates the existing row by adding seconds and updating the title
                      
        for (d_str, hr, cls), secs in hours.items():                                      # Iterates through hourly aggregations
            c.execute('''INSERT INTO focus_hourly (log_date, hour, app_class, seconds) VALUES (?, ?, ?, ?)
                         ON CONFLICT(log_date, hour, app_class) DO UPDATE SET seconds = seconds + ?''',
                      (d_str, hr, cls, secs, secs))                                        # UPSERTs into the hourly table, adding to existing seconds if the row already exists
                      
        for (d_str, itv, cls), secs in intervals.items():                                 # Iterates through 15-minute interval aggregations
            c.execute('''INSERT INTO focus_intervals (log_date, interval_idx, app_class, seconds) VALUES (?, ?, ?, ?)
                         ON CONFLICT(log_date, interval_idx, app_class) DO UPDATE SET seconds = seconds + ?''',
                      (d_str, itv, cls, secs, secs))                                      # UPSERTs into the intervals table
                      
        for (d_str, min_idx, cls), secs in minutes.items():                               # Iterates through per-minute aggregations
            c.execute('''INSERT INTO focus_minutes (log_date, minute_idx, app_class, seconds) VALUES (?, ?, ?, ?)
                         ON CONFLICT(log_date, minute_idx, app_class) DO UPDATE SET seconds = seconds + ?''',
                      (d_str, min_idx, cls, secs, secs))                                  # UPSERTs into the minutes table
                      
        self.conn.commit()                                                                # Commits all the batched database changes in a single transaction for performance
        self.buffer.clear()                                                               # Clears the buffer after successful database write

tracker = DaemonTracker()                                                               # Creates the global singleton instance of the DaemonTracker class that manages all tracking operations

def exit_handler(sig, frame):                                                           # Signal handler function called when the process receives SIGINT (Ctrl+C) or SIGTERM
    tracker.flush()                                                                      # Flushes any remaining buffered tracking data to the database before exiting
    sys.exit(0)                                                                          # Exits the program cleanly with status code 0

def main():                                                                              # Main function that sets up signal handlers and runs the primary tracking loop
    global current_app_class, current_app_title                                          # Declares global variables to be modified within this function
    signal.signal(signal.SIGINT, exit_handler)                                           # Registers the exit_handler to be called when SIGINT is received (Ctrl+C)
    signal.signal(signal.SIGTERM, exit_handler)                                          # Registers the exit_handler for SIGTERM (system shutdown or kill command)

    current_app_class, current_app_title = get_active_window_hyprctl()                  # Gets the initial active window information to set the starting state
    
    ipc_thread = threading.Thread(target=listen_hyprland_ipc, daemon=True)              # Creates a daemon thread that will run the Hyprland IPC listener; daemon=True means it will be terminated when the main thread exits
    ipc_thread.start()                                                                   # Starts the IPC listener thread so it begins monitoring window focus changes

    tick_counter = 0                                                                     # Initializes a counter to track the number of seconds that have passed
    while True:                                                                          # Starts the infinite main loop
        time.sleep(1)                                                                     # Sleeps for 1 second (the tracking granularity is 1 second)
        tick_counter += 1                                                                 # Increments the tick counter
        if current_app_class and current_app_class not in [""]:                          # If there is a valid current application class (not empty string)
            # Only dump JSON to memory/disk every 5 seconds                              # Comment explaining the write throttling strategy
            tracker.fast_tick(current_app_class, current_app_title, write_to_disk=(tick_counter % 5 == 0))  # Calls fast_tick with the current app info; write_to_disk is True only every 5th tick (modulo 5 equals 0) to reduce disk I/O

if __name__ == "__main__":                                                              # Standard Python idiom: only run main() if this script is executed directly (not imported as a module)
    main()                                                                               # Calls the main function to start the focus time tracking daemon