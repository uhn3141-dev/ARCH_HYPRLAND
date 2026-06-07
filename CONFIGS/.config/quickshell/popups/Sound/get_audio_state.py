#!/usr/bin/env python3
"""
Audio State Fetcher for Quickshell Sound Panel
Fetches all PulseAudio/PipeWire sinks, sources, and sink-inputs
Outputs JSON with device info, volume, mute state, and default status
"""

import subprocess
import json


def run_cmd(cmd):
    """Run a shell command and return its stdout, or empty list on failure."""
    try:
        return subprocess.check_output(
            cmd, shell=True, stderr=subprocess.DEVNULL
        ).decode('utf-8')
    except subprocess.CalledProcessError:
        return "[]"


def parse_json(output):
    """Safely parse JSON output, returning empty list on failure."""
    try:
        return json.loads(output)
    except json.JSONDecodeError:
        return []


def get_valid_string(*args):
    """Return the first non-null, non-empty string from the given arguments."""
    for arg in args:
        if arg and str(arg).strip().lower() not in ("null", "none", ""):
            return str(arg)
    return ""


def get_data():
    """Main function: fetch audio state and output as JSON."""

    # --- Fetch all audio objects from PulseAudio/PipeWire ---
    sinks_raw = run_cmd("pactl -f json list sinks")
    sources_raw = run_cmd("pactl -f json list sources")
    sink_inputs_raw = run_cmd("pactl -f json list sink-inputs")

    sinks = parse_json(sinks_raw)
    sources = parse_json(sources_raw)
    sink_inputs = parse_json(sink_inputs_raw)

    # --- Get the default sink and source names ---
    try:
        info_raw = run_cmd("pactl -f json info")
        info = json.loads(info_raw)
        default_sink = info.get("default_sink_name", "")
        default_source = info.get("default_source_name", "")
    except (json.JSONDecodeError, KeyError):
        default_sink = ""
        default_source = ""


    def format_node(node, is_default=False, is_app=False):
        """
        Convert a raw PulseAudio node (sink/source/sink-input) into
        a standardized dictionary for the QML panel.
        """
        # --- Extract volume percentage ---
        vol = 0
        volume_data = node.get("volume", {})
        if isinstance(volume_data, dict):
            # Try stereo first, then mono
            if "front-left" in volume_data:
                vol_str = volume_data["front-left"].get("value_percent", "0%")
                vol = int(vol_str.strip("%"))
            elif "mono" in volume_data:
                vol_str = volume_data["mono"].get("value_percent", "0%")
                vol = int(vol_str.strip("%"))

        # --- Extract properties ---
        props = node.get("properties", {})

        # --- Determine display name and sub-description ---
        if is_app:
            # For application streams: use app name and media title
            display_name = get_valid_string(
                props.get("application.name"),
                props.get("application.process.binary"),
                "Unknown App"
            )
            sub_desc = get_valid_string(
                props.get("media.name"),
                props.get("window.title"),
                props.get("media.role"),
                "Audio Stream"
            )
        else:
            # For hardware devices: use device description and internal name
            display_name = get_valid_string(
                props.get("device.description"),
                node.get("name"),
                "Unknown Device"
            )
            sub_desc = get_valid_string(
                node.get("name"),
                "Unknown"
            )

        # --- Get icon name ---
        icon = get_valid_string(
            props.get("application.icon_name"),
            props.get("device.icon_name"),
            "audio-card"
        )

        # --- Build and return the standardized dictionary ---
        return {
            "id": str(node.get("index", "")),
            "name": sub_desc,
            "description": display_name,
            "volume": vol,
            "mute": bool(node.get("mute", False)),
            "is_default": bool(is_default),
            "icon": icon
        }


    # --- Process all application streams (filter out pavucontrol itself) ---
    apps = []
    for stream in sink_inputs:
        props = stream.get("properties", {})
        # Don't show pavucontrol's own stream
        if props.get("application.id") != "org.PulseAudio.pavucontrol":
            apps.append(format_node(stream, is_app=True))


    # --- Build final output ---
    output = {
        "outputs": [
            format_node(s, is_default=(s.get("name") == default_sink))
            for s in sinks
        ],
        "inputs": [
            format_node(s, is_default=(s.get("name") == default_source))
            for s in sources
        ],
        "apps": apps
    }

    print(json.dumps(output))


if __name__ == "__main__":
    get_data()