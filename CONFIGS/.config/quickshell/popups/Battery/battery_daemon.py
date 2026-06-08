#!/usr/bin/env python3
"""Battery stats daemon - tracks uptime and active window usage"""

import json
import os
import time
import subprocess
import socket
from datetime import date
from threading import Thread

# STATS_FILE = os.path.expanduser("~/.config/quickshell/popups/Battery/qs_battery_stats.json")
STATS_FILE = os.path.join(os.path.dirname(__file__), "qs_battery_stats.json")
HYPR_SIG = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
XDG_RUNTIME = os.environ.get("XDG_RUNTIME_DIR", "/tmp")

last_uptime = 0
current_app = "Desktop"

def get_uptime():
    try:
        with open('/proc/uptime', 'r') as f:
            return int(float(f.read().split()[0]))
    except:
        return 0

def get_active_window():
    try:
        result = subprocess.check_output(
            ['hyprctl', 'activewindow', '-j'],
            stderr=subprocess.DEVNULL, timeout=2
        ).decode('utf-8', errors='replace').strip()
        if result == "{}" or not result:
            return "Desktop"
        data = json.loads(result)
        return data.get('initialTitle', data.get('title', 'Desktop'))[:40]
    except:
        return "Desktop"

def load_stats():
    try:
        with open(STATS_FILE, 'r') as f:
            content = f.read().strip()
            return json.loads(content) if content else {"days": {}}
    except:
        return {"days": {}}

def save_stats(data):
    os.makedirs(os.path.dirname(STATS_FILE), exist_ok=True)
    with open(STATS_FILE, 'w') as f:
        json.dump(data, f, indent=2)

def listen_hyprland():
    global current_app
    if not HYPR_SIG:
        return
    sock_path = f"{XDG_RUNTIME}/hypr/{HYPR_SIG}/.socket2.sock"
    if not os.path.exists(sock_path):
        sock_path = f"/tmp/hypr/{HYPR_SIG}/.socket2.sock"
    
    while True:
        try:
            client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            client.connect(sock_path)
            buffer = ""
            while True:
                data = client.recv(4096).decode('utf-8')
                if not data:
                    break
                buffer += data
                while '\n' in buffer:
                    line, buffer = buffer.split('\n', 1)
                    if line.startswith('activewindow>>'):
                        current_app = get_active_window()
        except:
            time.sleep(2)

# Start Hyprland listener in background
Thread(target=listen_hyprland, daemon=True).start()

# Main loop
while True:
    time.sleep(10)
    
    today = date.today().isoformat()
    current_uptime = get_uptime()
    
    if last_uptime == 0:
        last_uptime = current_uptime
        continue
    
    elapsed = current_uptime - last_uptime
    if elapsed < 0:
        elapsed = 10
    elapsed = min(elapsed, 15)
    
    last_uptime = current_uptime
    
    data = load_stats()
    
    if today not in data['days']:
        data['days'][today] = {'uptime': 0, 'apps': {}}
    
    data['days'][today]['uptime'] += elapsed
    
    if current_app and current_app != "Desktop":
        apps = data['days'][today]['apps']
        apps[current_app] = apps.get(current_app, 0) + elapsed
    
    save_stats(data)
    
