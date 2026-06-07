pragma Singleton
// ^ Declares this QML file as a singleton, meaning only one instance of this component will ever be created. All other QML files that import this will share the same instance, making it perfect for global configuration and state management. The `pragma` keyword is a compiler directive for the QML engine.

import QtQuick
// ^ Imports the QtQuick module, which provides all the basic QML types and functionality including Item, properties, signals, and basic animations. This is the foundation module required for any QML application.

import Quickshell
// ^ Imports the Quickshell module, which provides Wayland-specific shell functionality including the `Quickshell` object for environment variables, process management (Process type), and desktop shell integration. This is the core framework for building the desktop interface.

import Quickshell.Io
// ^ Imports the Quickshell.Io module, which provides input/output utilities including the `StdioCollector` type used to capture and process the standard output from spawned processes. This enables reading command results asynchronously.

Item {
    // ^ Defines the root element as a generic `Item`, which is the most basic visual QML type. As a singleton, it doesn't need visual properties—it serves purely as a container for global properties, functions, and initialization logic.

    id: config
    // ^ Assigns the identifier "config" to this Item. This ID is how other QML files reference this singleton instance (e.g., `Config.uiScale` or `Config.getSetting(...)`, assuming the singleton is imported under the name "Config").

    // =========================================================================
    // Core Paths & Environment
    // =========================================================================
    readonly property string homeDir: Quickshell.env("HOME")
    // ^ Defines a read-only string property containing the user's home directory path. `Quickshell.env("HOME")` reads the HOME environment variable from the system. Being `readonly`, this property cannot be modified after initialization, ensuring consistent path references throughout the application.

    readonly property string hyprDir: homeDir + "/.config/hypr"
    // ^ Constructs the path to the Hyprland configuration directory by concatenating the home directory with "/.config/hypr". This is where all Hyprland-related configuration files, scripts, and the settings JSON are stored. Readonly prevents accidental modification.

    readonly property string qsScriptsDir: hyprDir + "/scripts/quickshell"
    // ^ Constructs the path to the QuickShell scripts directory within the Hyprland configuration. This directory contains all the QML files, shell scripts, and subdirectories for various widgets (calendar, network, volume, etc.). Readonly ensures consistent reference.

    readonly property string cacheDir: homeDir + "/.cache/quickshell"
    // ^ Constructs the path to the QuickShell cache directory where temporary data, thumbnails, and runtime state files are stored. Following XDG conventions, caches go in ~/.cache rather than ~/.config since they can be regenerated.
    
    readonly property string settingsJsonPath: hyprDir + "/settings.json"
    // ^ Constructs the full path to the main settings JSON file. This file is the single source of truth for user configurations, managed by the settings UI and synchronized to Hyprland config files by the settings watcher daemon.

    readonly property string weatherEnvPath: qsScriptsDir + "/calendar/.env"
    // ^ Constructs the full path to the weather configuration environment file. This .env file stores API keys and location settings for the weather widget, in a format compatible with shell scripts and Python fetchers.

    // State Tracking
    property bool dataReady: false
    // ^ Defines a boolean property that tracks whether the initial data loading is complete. Starts as `false` and is set to `true` after all configuration files have been read and processed. Other components can bind to this property to delay rendering until configuration is fully loaded, preventing flicker or incorrect initial states.

    property var rawSettings: ({})
    // ^ Defines a variable-type property that holds the parsed JSON settings object. Initialized as an empty JavaScript object `{}`. This stores all settings loaded from settings.json and is updated in real-time when settings are changed via `setSetting()` or `updateJsonBulk()`. Using `var` allows it to hold any JavaScript type (object, array, etc.).

    property var rawEnvs: ({})
    // ^ Defines a variable-type property that holds the parsed environment variables from the weather .env file. Initialized as an empty object. This serves as an in-memory cache of the env file contents, updated when env values are set through `setEnv()` or `updateEnvBulk()`.

    // =========================================================================
    // Generic Utilities (Use these in ANY widget!)
    // =========================================================================

    // Execute a background bash command easily
    function sh(cmd) {
        // ^ Defines a convenience function called `sh` that takes a command string as its argument. This function provides a simple way to run shell commands from anywhere in the QML application without needing to create a Process object each time.

        Quickshell.execDetached(["bash", "-c", cmd]);
        // ^ Executes the command string in a detached background process. `Quickshell.execDetached` spawns a new process that runs independently of the QML application (won't be killed if the QML app exits). The array format `["bash", "-c", cmd]` passes "bash" as the executable, "-c" to indicate the next argument is a command string, and the actual command. This is equivalent to running `bash -c "command"` in the terminal.
    }

    // --- JSON Operations ---
    function getSetting(key, fallbackValue) {
        // ^ Defines a generic function to retrieve a setting value from the cached settings object. Takes two parameters: `key` (the setting name to look up) and `fallbackValue` (the default value to return if the key doesn't exist).

        return rawSettings.hasOwnProperty(key) ? rawSettings[key] : fallbackValue;
        // ^ Uses the JavaScript ternary operator: if the `rawSettings` object has an own property matching the key (checked via `hasOwnProperty`), returns its value; otherwise returns the provided fallback value. This provides safe setting access with sensible defaults.
    }

    function setSetting(key, value) {
        // ^ Defines a generic function to update a setting value both in memory and on disk. Takes two parameters: `key` (the setting name to update) and `value` (the new value to assign).

        // 1. Update local cache instantly
        rawSettings[key] = value;
        // ^ Immediately updates the in-memory `rawSettings` object with the new value. This ensures the UI reflects changes instantly without waiting for the disk write to complete, providing a responsive user experience.

        // 2. Format for bash (escape quotes safely)
        let safeValue = typeof value === "string" ? `"${value}"` : value;
        // ^ Prepares the value for safe insertion into a bash command. If the value is a string type, wraps it in double quotes to prevent word splitting and special character interpretation in the shell. If it's not a string (e.g., number, boolean), uses the value directly without quoting.

        if (typeof value === "object") safeValue = JSON.stringify(value).replace(/'/g, "'\\''");
        // ^ If the value is an object (like an array for keybinds), converts it to a JSON string using `JSON.stringify()`. Then escapes any single quotes in the JSON by replacing `'` with `'\''` (which in bash means: end current single-quoted string, append an escaped single quote, start a new single-quoted string). This prevents the JSON from breaking the bash command's quoting.

        // 3. Patch JSON using jq
        let cmd = `mkdir -p "$(dirname '${settingsJsonPath}')" && ` +
                  `[ ! -f '${settingsJsonPath}' ] && echo '{}' > '${settingsJsonPath}'; ` +
                  `jq '. + {"${key}": ${safeValue}}' '${settingsJsonPath}' > '${settingsJsonPath}.tmp' && ` +
                  `mv '${settingsJsonPath}.tmp' '${settingsJsonPath}'`;
        // ^ Constructs a bash command string using a template literal (backticks for multi-line strings): (1) `mkdir -p` ensures the settings file's parent directory exists, (2) if the settings file doesn't exist, creates it with an empty JSON object `{}`, (3) uses `jq` to merge the new key-value pair into the existing JSON (the `. + {...}` expression adds/updates the key), writing to a temporary file, (4) atomically renames the temp file to the actual settings file. This approach prevents file corruption if the write is interrupted.

        sh(cmd);
        // ^ Executes the constructed bash command using the convenience `sh()` function, which runs it in a detached background process.
    }

    function updateJsonBulk(dataObj) {
        // ^ Defines a function to update multiple JSON settings at once, which is more efficient than calling `setSetting()` multiple times since it only writes to disk once. Takes a `dataObj` parameter containing multiple key-value pairs to update.

        let jsonStr = JSON.stringify(dataObj).replace(/'/g, "'\\''");
        // ^ Converts the entire data object to a JSON string using `JSON.stringify()`, then escapes any single quotes for safe bash command insertion using the same `'\''` technique.

        let cmd = `mkdir -p "$(dirname '${settingsJsonPath}')" && ` +
                  `[ ! -f '${settingsJsonPath}' ] && echo '{}' > '${settingsJsonPath}'; ` +
                  `jq '. + ${jsonStr}' '${settingsJsonPath}' > '${settingsJsonPath}.tmp' && ` +
                  `mv '${settingsJsonPath}.tmp' '${settingsJsonPath}'`;
        // ^ Constructs a similar bash command as `setSetting()`, but merges the entire `jsonStr` object at once using `jq '. + {...}'`. This performs a single JSON merge operation and a single file write, which is faster and safer than multiple sequential writes.

        sh(cmd);
        // ^ Executes the bulk update command in a detached background process.

        // Update local cache
        for (let key in dataObj) rawSettings[key] = dataObj[key];
        // ^ Iterates over all keys in the data object and updates the in-memory `rawSettings` cache for each one. This ensures the local state matches the written JSON without needing to re-read the file. The `let` keyword declares a block-scoped loop variable.
    }

    // --- Env Operations ---
    function getEnv(key, fallbackValue) {
        // ^ Defines a function to retrieve an environment variable value from the cached envs object. Mirrors `getSetting()` but operates on `rawEnvs` instead of `rawSettings`. Takes a key and an optional fallback value.

        return rawEnvs.hasOwnProperty(key) ? rawEnvs[key] : fallbackValue;
        // ^ Returns the value from `rawEnvs` if the key exists, otherwise returns the fallback value. This provides safe access to environment configuration like weather API settings.
    }

    function setEnv(filePath, key, value) {
        // ^ Defines a function to update a single environment variable in a .env file. Takes three parameters: `filePath` (the env file to modify), `key` (the variable name), and `value` (the new value).

        rawEnvs[key] = value;
        // ^ Immediately updates the in-memory cache with the new value.

        let safeVal = value.toString().replace(/'/g, "'\\''");
        // ^ Converts the value to a string (in case it's a number or boolean) and escapes single quotes for safe bash insertion.

        let cmd = `mkdir -p "$(dirname '${filePath}')" && touch '${filePath}'; ` +
                  `if grep -q "^${key}=" '${filePath}'; then ` +
                  `sed -i "s|^${key}=.*|${key}='${safeVal}'|" '${filePath}'; ` +
                  `else echo "${key}='${safeVal}'" >> '${filePath}'; fi`;
        // ^ Constructs a bash command that: (1) ensures the file's parent directory exists, (2) creates the file if it doesn't exist, (3) checks if the key already exists in the file using `grep -q`, (4) if it exists, uses `sed -i` to replace the entire line with the new key-value pair (using `|` as delimiter since values may contain `/`), (5) if it doesn't exist, appends a new line with the key-value pair to the end of the file. This ensures idempotent env file updates.

        sh(cmd);
        // ^ Executes the env update command in a detached background process.
    }

    function updateEnvBulk(filePath, envDict) {
        // ^ Defines a function to update multiple environment variables at once in a .env file. Takes the file path and a dictionary object of key-value pairs.

        let cmds = [`mkdir -p "$(dirname '${filePath}')"`, `touch '${filePath}'`];
        // ^ Initializes an array of bash commands, starting with directory creation and file creation/touch. Using an array allows joining all commands with `&&` later for sequential execution.

        for (let key in envDict) {
            // ^ Iterates over each key in the environment dictionary object.

            rawEnvs[key] = envDict[key];
            // ^ Updates the in-memory cache for each environment variable.

            let safeVal = envDict[key].toString().replace(/'/g, "'\\''");
            // ^ Escapes the value for safe bash insertion.

            cmds.push(`if grep -q "^${key}=" '${filePath}'; then ` +
                      `sed -i "s|^${key}=.*|${key}='${safeVal}'|" '${filePath}'; ` +
                      `else echo "${key}='${safeVal}'" >> '${filePath}'; fi`);
            // ^ Pushes the same grep/sed/echo logic from `setEnv()` onto the commands array for each key-value pair.
        }

        sh(cmds.join(" && "));
        // ^ Joins all commands in the array with ` && ` (logical AND), meaning each command runs only if the previous one succeeded. Executes the combined command string in a detached process. This is more efficient than calling `setEnv()` multiple times since it only spawns one process.
    }


    // =========================================================================
    // Legacy Specific Properties (Bound to Settings.qml)
    // =========================================================================
    property real uiScale: 1.0
    // ^ Defines a property for the UI scale factor, defaulting to 1.0 (100% scaling). This controls the size of all QuickShell interface elements. The `real` type is a floating-point number, allowing fractional scaling values like 1.25 or 1.5 for high-DPI displays. This property is bound to the settings UI slider/input.

    property bool openGuideAtStartup: true
    // ^ Defines a boolean property controlling whether the welcome/guide overlay opens automatically when Hyprland starts. Defaults to `true`, meaning the guide will be shown on first launch. This gets persisted to settings.json and toggles the autostart config line.

    property bool topbarHelpIcon: true
    // ^ Defines a boolean property that controls the visibility of the help/question mark icon in the topbar. When `true`, an icon is displayed that users can click to access help or the guide. Defaults to `true`.

    property int workspaceCount: 8
    // ^ Defines an integer property for the number of workspaces displayed in the topbar. Defaults to 8 workspaces. This value can be changed through the settings UI and, when modified, triggers a reload of the topbar to reflect the new workspace count.

    property int initialWorkspaceCount: 8
    // ^ Defines an integer property that stores the workspace count at the time of loading/saving. This is used to detect whether the count has actually changed (by comparing `workspaceCount` against `initialWorkspaceCount`) to determine if a topbar reload is necessary. Defaults to 8 matching the initial workspace count.

    property string wallpaperDir: Quickshell.env("WALLPAPER_DIR") || (homeDir + "/Pictures/Wallpapers")
    // ^ Defines the wallpaper directory path. Uses the JavaScript logical OR operator `||` to provide a fallback: first attempts to read the WALLPAPER_DIR environment variable (set in Hyprland's env config), and if that's empty or unset, falls back to the default `~/Pictures/Wallpapers` directory.

    property string language: ""
    // ^ Defines a string property for the keyboard language/layout code (e.g., "us", "de", "fr"). Initialized as empty string, it will be populated either from the Hyprland config file or from settings.json during initialization.

    property string kbOptions: "grp:alt_shift_toggle"
    // ^ Defines a string property for XKB keyboard options. Defaults to "grp:alt_shift_toggle", which configures Alt+Shift to toggle between keyboard layouts when multiple layouts are configured. This is a common shortcut for multilingual users.

    property string weatherUnit: "metric"
    // ^ Defines a string property for the weather temperature unit. Defaults to "metric" (Celsius). Can be changed to "imperial" (Fahrenheit) through the weather configuration UI. This gets persisted in the weather .env file.

    property string weatherApiKey: ""
    // ^ Defines a string property for the OpenWeatherMap API key. Initialized as empty, it must be filled by the user through the settings UI for weather functionality to work. The key is stored in the weather .env file.

    property string weatherCityId: ""
    // ^ Defines a string property for the OpenWeatherMap city ID, which identifies the location for weather forecasts. Initialized as empty, it's set by the user through the weather configuration UI and stored in the .env file.

    property var keybindsData: []
    // ^ Defines a variable-type property that holds an array of keybinding objects. Each object contains properties like `type`, `mods`, `key`, `dispatcher`, `command`, and `isEditing` (for the settings UI). Initialized as an empty array, it's populated from settings.json during boot.

    signal keybindsLoaded()
    // ^ Declares a custom signal called `keybindsLoaded`. This signal is emitted after all keybindings have been fully loaded and parsed from disk. Other QML components (like the settings UI) can connect to this signal to delay their initialization until keybind data is available, preventing empty or incomplete displays.


    // =========================================================================
    // Legacy Specific Functions (Bound to Settings.qml)
    // =========================================================================
    function saveAppSettings() {
        // ^ Defines a function that saves all application-level settings to disk. This is called when the user clicks "Save" in the settings UI. It collects current property values, writes them to settings.json via bulk update, and handles special cases like workspace count changes.

        let configObj = {
            "uiScale": config.uiScale,
            "openGuideAtStartup": config.openGuideAtStartup,
            "topbarHelpIcon": config.topbarHelpIcon,
            "wallpaperDir": config.wallpaperDir,
            "language": config.language,
            "kbOptions": config.kbOptions,
            "workspaceCount": config.workspaceCount
        };
        // ^ Creates a JavaScript object containing all the current application setting values. This object will be serialized to JSON and merged into the settings file. Using `config.propertyName` accesses properties of this singleton (redundant but explicit since we're inside the config object).

        config.updateJsonBulk(configObj);
        // ^ Calls the bulk JSON update function to write all application settings to disk in a single operation, along with updating the in-memory cache.

        sh("notify-send 'Quickshell' 'Settings Applied Successfully!'");
        // ^ Sends a desktop notification confirming that settings were saved successfully. The notification appears with the application name "Quickshell" and the message "Settings Applied Successfully!".

        if (config.workspaceCount !== config.initialWorkspaceCount) {
            // ^ Checks if the workspace count has been changed by the user (comparing current against the initial value captured at load time). This detects whether a topbar reload is needed.

            sh(`qs -p "${qsScriptsDir}/TopBar.qml" ipc call topbar queueReload`);
            // ^ If the workspace count changed, sends an IPC command to the TopBar QuickShell instance telling it to reload. The `queueReload` method likely schedules a reload after the current event processing completes, preventing UI glitches. The QS command uses the path to the TopBar QML file to target the correct running instance.

            config.initialWorkspaceCount = config.workspaceCount; 
            // ^ Updates the initial workspace count to match the new value. This prevents the reload from being triggered again on subsequent saves unless the count changes again.
        }
    }

    function saveWeatherConfig() {
        // ^ Defines a function that saves weather-related configuration (API key, city, unit) to the weather .env file and clears the weather cache to force fresh data fetching.

        let envs = {
            "OPENWEATHER_KEY": config.weatherApiKey,
            "OPENWEATHER_CITY_ID": config.weatherCityId,
            "OPENWEATHER_UNIT": config.weatherUnit
        };
        // ^ Creates an object containing the three weather configuration values, keyed by their environment variable names as expected by the weather fetching scripts.

        config.updateEnvBulk(config.weatherEnvPath, envs);
        // ^ Calls the bulk env update function to write all three weather variables to the .env file in a single operation.

        sh(`rm -rf "${cacheDir}/weather"`);
        // ^ Deletes the cached weather data directory. This forces the weather widget to fetch fresh data on the next update using the new API configuration, rather than showing stale data based on old settings or old locations.

        sh("notify-send 'Weather' 'API configuration saved successfully!'");
        // ^ Sends a desktop notification confirming that the weather API configuration was saved successfully.
    }

    function saveAllKeybinds(bindsArray) {
        // ^ Defines a function to save the complete keybindings configuration. Takes a `bindsArray` parameter containing the array of keybinding objects from the settings UI.

        config.keybindsData = bindsArray;
        // ^ Updates the in-memory keybinds data array with the new bindings. This keeps the local state synchronized.

        config.setSetting("keybinds", bindsArray);
        // ^ Writes the keybinds array to the settings JSON file under the "keybinds" key. This persists the keybinding configuration to disk, which the settings watcher will then pick up and regenerate the Hyprland keybindings config file.

        sh("notify-send 'Quickshell' 'Keybinds Saved Successfully!'");
        // ^ Sends a desktop notification confirming that the keybindings were saved successfully.
    }

    // =========================================================================
    // Boot Initialization (Runs once on start)
    // =========================================================================
    Component.onCompleted: {
        // ^ This signal handler runs once when the Config singleton component has finished initializing. This is the boot sequence that kicks off reading all configuration files from disk. It runs asynchronously to avoid blocking the UI.

        settingsReader.running = true;
        // ^ Starts the settingsReader Process by setting its `running` property to `true`. This begins reading and parsing the settings.json file in the background.

        envReader.running = true;
        // ^ Starts the envReader Process to read the weather .env file in the background.

        hyprLangReader.running = true;
        // ^ Starts the hyprLangReader Process to extract the keyboard language from the Hyprland configuration in the background.
    }

    Process {
        // ^ Defines a Process object (from the Quickshell module) that can execute external commands and capture their output. This process reads and parses the weather .env file.

        id: envReader
        // ^ Assigns the identifier "envReader" so it can be referenced elsewhere (e.g., to start it via `envReader.running = true`).

        command: ["bash", "-c", `cat "${config.weatherEnvPath}" 2>/dev/null || echo ''`]
        // ^ Defines the command to execute: uses bash to `cat` the weather .env file, suppressing errors if it doesn't exist (`2>/dev/null`), and outputs an empty string as a fallback (`|| echo ''`). The template literal `${config.weatherEnvPath}` inserts the full path to the env file.

        running: false
        // ^ Sets the initial running state to `false`, meaning this process doesn't start automatically. It will be started when `Component.onCompleted` sets `running = true`.

        stdout: StdioCollector {
            // ^ Attaches a StdioCollector to the process's standard output. This object collects all output text and emits a `streamFinished` signal when the process completes and all output has been received.

            onStreamFinished: {
                // ^ This signal handler runs when the env file has been fully read and the process exits. It parses the collected text into individual environment variables.

                let lines = this.text ? this.text.trim().split('\n') : [];
                // ^ Checks if any text was collected. If so, trims whitespace and splits the text into an array of lines. If no text (empty file or error), creates an empty array. `this.text` refers to the accumulated stdout text collected by the StdioCollector.

                for (let line of lines) {
                    // ^ Iterates over each line from the env file using a `for...of` loop for clean iteration over array elements.

                    line = line.trim();
                    // ^ Trims leading and trailing whitespace from the current line.

                    let parts = line.split("=");
                    // ^ Splits the line at the first equals sign, creating an array where the first element is the key and the rest are the value. Note: this simple split can break if the value contains `=` signs.

                    if (parts.length >= 2) {
                        // ^ Only processes lines that have at least two parts (contain an equals sign). This skips empty lines and comments.

                        let key = parts[0].trim();
                        // ^ Extracts the key as the first part, trimmed of whitespace.

                        let val = parts.slice(1).join("=").replace(/^['"]|['"]$/g, '').trim();
                        // ^ Extracts the value by joining all remaining parts with "=" (preserving equals signs in the value), then removes any surrounding single or double quotes using a regex replacement (`/^['"]|['"]$/g` removes quotes at start or end), and finally trims whitespace.

                        config.rawEnvs[key] = val;
                        // ^ Stores the parsed key-value pair in the in-memory envs cache.

                        if (key === "OPENWEATHER_KEY") config.weatherApiKey = val;
                        // ^ If the key is specifically "OPENWEATHER_KEY", also updates the corresponding QML property so the weather settings UI reflects the stored value.

                        else if (key === "OPENWEATHER_CITY_ID") config.weatherCityId = val;
                        // ^ Maps the OPENWEATHER_CITY_ID env value to the weatherCityId property for UI binding.

                        else if (key === "OPENWEATHER_UNIT") config.weatherUnit = val;
                        // ^ Maps the OPENWEATHER_UNIT env value to the weatherUnit property for UI binding.
                    }
                }
            }
        }
    }

    Process {
        // ^ Defines a Process object that reads the current keyboard layout from the Hyprland configuration file. This is used to pre-populate the language setting on first run.

        id: hyprLangReader
        // ^ Assigns the identifier "hyprLangReader" for referencing this process.

        command: ["bash", "-c", `grep -m1 '^ *kb_layout *=' "${config.hyprDir}/hyprland.conf" | cut -d'=' -f2 | tr -d ' '`]
        // ^ The command pipeline: (1) `grep -m1 '^ *kb_layout *='` searches for lines starting with optional spaces followed by `kb_layout =` in the main hyprland.conf file, limiting to the first match (`-m1`), (2) `cut -d'=' -f2` splits on `=` and takes the second field (the value after the equals sign), (3) `tr -d ' '` removes all spaces from the result. This extracts the keyboard layout code like "us" or "de".

        running: false
        // ^ Initially not running; started during component completion.

        stdout: StdioCollector {
            // ^ Collects the standard output from the grep pipeline.

            onStreamFinished: {
                // ^ Called when the process finishes and all output is collected.

                let out = this.text ? this.text.trim() : "";
                // ^ Gets the trimmed output text, or empty string if no output (e.g., layout not set).

                if (out.length > 0 && config.language === "") config.language = out;
                // ^ If output was captured AND the config.language property is still empty (meaning it wasn't already set from settings.json), sets the language property to the extracted value. This prioritizes settings.json over hyprland.conf—if the user has saved a language preference, it won't be overwritten by the config file reading.
            }
        }
    }

    Process {
        // ^ Defines a Process object that reads and parses the main settings.json file. This is the primary configuration source that loads all persisted user settings.

        id: settingsReader
        // ^ Assigns the identifier "settingsReader" for referencing this process.

        command: ["bash", "-c", `cat "${config.settingsJsonPath}" 2>/dev/null || echo '{}'`]
        // ^ Reads the settings JSON file, suppressing errors if it doesn't exist, and falls back to an empty JSON object `{}`. This ensures the parser always receives valid JSON.

        running: false
        // ^ Initially not running; started during component completion.

        stdout: StdioCollector {
            // ^ Collects the JSON text from the cat command.

            onStreamFinished: {
                // ^ Called when the JSON file has been read. This is the main initialization handler that populates all QML properties from the saved settings.

                try {
                    // ^ Opens a try block to catch any JSON parsing errors or other exceptions during initialization, preventing a crash from corrupting settings.

                    if (this.text && this.text.trim().length > 0 && this.text.trim() !== "{}") {
                        // ^ Checks if there is meaningful content: text exists, it's not empty after trimming, and it's not just an empty JSON object. If any condition fails, settings are effectively empty.

                        config.rawSettings = JSON.parse(this.text);
                        // ^ Parses the JSON text into a JavaScript object and stores it in `rawSettings`. This is the core in-memory cache that all settings access functions use.

                        // Map explicitly defined properties
                        if (config.rawSettings.uiScale !== undefined) config.uiScale = config.rawSettings.uiScale;
                        // ^ If the uiScale setting exists in the parsed JSON, applies it to the QML property, scaling the entire interface.

                        if (config.rawSettings.openGuideAtStartup !== undefined) config.openGuideAtStartup = config.rawSettings.openGuideAtStartup;
                        // ^ Loads the guide startup preference from settings.

                        if (config.rawSettings.topbarHelpIcon !== undefined) config.topbarHelpIcon = config.rawSettings.topbarHelpIcon;
                        // ^ Loads the help icon visibility preference.

                        if (config.rawSettings.wallpaperDir !== undefined) config.wallpaperDir = config.rawSettings.wallpaperDir;
                        // ^ Loads the wallpaper directory path from settings, overriding the environment variable default.

                        if (config.rawSettings.language !== undefined && config.rawSettings.language !== "") config.language = config.rawSettings.language;
                        // ^ Loads the keyboard language, but only if it's defined AND not empty (preserving any value already loaded from hyprland.conf or environment).

                        if (config.rawSettings.kbOptions !== undefined) config.kbOptions = config.rawSettings.kbOptions;
                        // ^ Loads the keyboard options string (like XKB options for layout switching).

                        if (config.rawSettings.workspaceCount !== undefined) {
                            // ^ Checks if workspace count is defined in settings.

                            config.workspaceCount = config.rawSettings.workspaceCount;
                            // ^ Applies the workspace count to the live property.

                            config.initialWorkspaceCount = config.rawSettings.workspaceCount; 
                            // ^ Also sets the initial count tracker to match, so changes are detected relative to the loaded value.
                        }
                        
                        // Map Keybinds
                        if (config.rawSettings.keybinds !== undefined && Array.isArray(config.rawSettings.keybinds)) {
                            // ^ Checks if keybinds exist AND are actually an array (the expected format). The `Array.isArray()` check prevents errors if keybinds were stored in an unexpected format.

                            let tempBinds = [];
                            // ^ Creates a temporary array to hold the formatted keybinding objects.

                            for (let k of config.rawSettings.keybinds) {
                                // ^ Iterates over each raw keybinding object from the JSON.

                                tempBinds.push({
                                    type: k.type || "bind",
                                    mods: k.mods || "",
                                    key: k.key || "",
                                    dispatcher: k.dispatcher || "exec",
                                    command: k.command || "",
                                    isEditing: false
                                });
                                // ^ Creates a normalized keybinding object with defaults for any missing fields: type defaults to "bind", modifiers/keys default to empty string, dispatcher defaults to "exec", command defaults to empty string, and `isEditing` is always initialized to false (for the settings UI's edit mode). This ensures all expected properties exist.
                            }
                            config.keybindsData = tempBinds;
                            // ^ Sets the keybindsData property to the normalized array for use by the settings UI and keybinding display.
                        } else {
                            config.keybindsData = [];
                            // ^ If keybinds are missing or malformed, initializes an empty array.

                            config.saveAllKeybinds([]);
                            // ^ Saves the empty array to the settings file, which will create the keybinds structure if it was missing or fix it if it was corrupted.
                        }
                    } else {
                        // ^ This branch runs if settings file is empty or contains only `{}`.

                        config.saveAppSettings();
                        // ^ Saves the current default application settings to create an initial settings file with default values.

                        config.keybindsData = [];
                        // ^ Initializes empty keybinds array.

                        config.saveAllKeybinds([]);
                        // ^ Writes the empty keybinds array to create the structure in the new settings file.
                    }
                } catch (e) {
                    // ^ Catches any exception during JSON parsing or property mapping.

                    console.log("Error parsing global settings:", e);
                    // ^ Logs the error to the console for debugging purposes.

                    config.keybindsData = [];
                    // ^ Falls back to an empty keybinds array to prevent the UI from crashing due to undefined data.
                }

                config.keybindsLoaded();
                // ^ Emits the `keybindsLoaded` signal to notify any connected components (like the settings UI) that keybinding data is now available and they can complete their initialization.

                config.dataReady = true;
                // ^ Sets the `dataReady` flag to true, signaling that all configuration has been loaded and the UI can now render fully. Components bound to `dataReady` will reactively update when this changes.
            }
        }
    }
}