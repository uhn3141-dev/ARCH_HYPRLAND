import QtQuick
// ^ Imports the QtQuick module, providing basic QML types including Item, properties, and bindings.

import Quickshell
// ^ Imports the Quickshell module for Process management and shell integration in the Wayland environment.

import Quickshell.Io
// ^ Imports the Quickshell Io module, providing StdioCollector to asynchronously capture output from running processes.

import "WindowRegistry.js" as LayoutMath 
// ^ Imports the WindowRegistry.js JavaScript file under the namespace "LayoutMath". This file contains mathematical functions for calculating scale factors and UI element sizes based on screen dimensions.

Item {
    // ^ The root element is a generic Item—a non-visual container that serves purely as a logic provider. It has no visual representation of its own.

    id: root
    // ^ Assigns the identifier "root" for referencing this scaler instance from parent components.

    visible: false
    // ^ Hides this item from rendering since it performs only calculations and has no visual content to display.

    property real currentWidth: 1920.0
    // ^ Stores the current display width in pixels. Initialized to 1920 (Full HD) as a sensible default before the actual screen width is provided by the parent component. The `real` type allows floating-point values.

    property real currentHeight: 1080.0 // <-- ADDED
    // ^ Stores the current display height in pixels. Initialized to 1080 as a default matching Full HD resolution. The comment "ADDED" suggests this was a recent addition to support proper aspect ratio calculations (previously only width was considered).

    property real uiScale: 1.0
    // ^ Stores the user interface scale factor from settings.json. Defaults to 1.0 (100% scaling). Higher values (like 1.25, 1.5, 2.0) indicate high-DPI displays where UI elements need to be proportionally larger.

    // FIXED: Now passes both Width and Height to respect aspect ratio
    property real baseScale: LayoutMath.getScale(currentWidth, currentHeight, uiScale)
    // ^ Calculates the single master scale factor using the LayoutMath module. This property binding automatically recalculates whenever currentWidth, currentHeight, or uiScale changes. The function takes both dimensions to correctly handle ultrawide monitors or other non-standard aspect ratios, ensuring UI elements scale appropriately without distortion. The result is used throughout the UI by multiplying dimensions (e.g., `40 * scaler.baseScale`).
    
    function s(val) { 
        // ^ A convenience function that scales a numeric value by the baseScale factor. This provides a shorthand for the common operation of converting design-time pixel values to runtime scaled values.

        return LayoutMath.s(val, baseScale); 
        // ^ Delegates to the LayoutMath module's `s()` function, passing the value to scale and the current baseScale. The function performs the multiplication and returns the scaled result, handling any rounding or clamping logic.
    }

    Process {
        // ^ A Process that reads the uiScale setting from the settings JSON file on startup.

        id: scaleReader
        // ^ Assigns the identifier for referencing this process.

        command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null || echo '{}'"]
        // ^ Executes a bash command to read the settings file. If the file doesn't exist or can't be read (error suppressed with 2>/dev/null), outputs an empty JSON object as fallback.

        running: true
        // ^ Starts this process immediately when the component is created, reading the initial scale value.

        stdout: StdioCollector {
            // ^ Captures the standard output from the cat command.

            onStreamFinished: {
                // ^ Called when the file has been completely read.

                try {
                    // ^ Wraps parsing in a try block to handle corrupted or malformed JSON gracefully.

                    if (this.text && this.text.trim().length > 0 && this.text.trim() !== "{}") {
                        // ^ Checks if the output contains actual content beyond an empty JSON object.

                        let parsed = JSON.parse(this.text);
                        // ^ Parses the JSON text into a JavaScript object.

                        if (parsed.uiScale !== undefined && root.uiScale !== parsed.uiScale) {
                            // ^ If the uiScale setting exists in the file AND differs from the current scale value.

                            root.uiScale = parsed.uiScale;
                            // ^ Updates the uiScale property. Because baseScale is a property binding dependent on uiScale, this automatically triggers recalculation of all scaled dimensions throughout the UI.
                        }
                    }
                } catch (e) {}
                // ^ Catches and silently ignores any parsing errors—the UI continues with the default scale if the settings file is malformed.
            }
        }
    }

    // EVENT-DRIVEN WATCHER
    Process {
        // ^ A Process that continuously monitors the settings JSON file for changes, enabling live UI scale updates without restarting the application.

        id: scaleWatcher
        // ^ Assigns the identifier for this file watching process.

        // -qq keeps it completely silent. It waits for the file to exist, listens for a write, and then exits.
        command: ["bash", "-c", "while [ ! -f ~/.config/hypr/settings.json ]; do sleep 1; done; inotifywait -qq -e modify,close_write ~/.config/hypr/settings.json"]
        // ^ A multi-stage bash command: (1) `while` loop polls every second until the settings file exists (handles first-run where the file hasn't been created yet), (2) once the file exists, `inotifywait -qq` silently blocks until the file is modified (`modify` event) or closed after writing (`close_write` event). When triggered, the process exits, outputting the filename.

        running: true
        // ^ Starts the watcher immediately and keeps it running (it blocks until the file changes).

        stdout: StdioCollector {
            // ^ Captures output (though inotifywait -qq is silent on success, the fact that output finished tells us the file changed).

            onStreamFinished: {
                // ^ Called when inotifywait exits, indicating the settings file was modified.

                // 1. Read the new data
                scaleReader.running = false;
                // ^ Stops any still-running previous instance of the reader process.

                scaleReader.running = true;
                // ^ Restarts the reader to parse the updated settings file, which will update root.uiScale if the scale value changed.

                // 2. Restart the watcher for the next event
                scaleWatcher.running = false;
                // ^ Stops this watcher process.

                scaleWatcher.running = true;
                // ^ Restarts the watcher to begin monitoring for the next file change. This stop-start pattern ensures a clean process state without zombie processes or resource leaks. The loop continues indefinitely: wait for change → restart reader → restart watcher → wait for next change.
            }
        }
    }
}