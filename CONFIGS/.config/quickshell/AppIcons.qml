import QtQuick
import Quickshell.Io

Item {
    id: root

    // Path to the JSON icon file (set this from the outside)
    property string iconPath: ""
    // Holds the loaded icons: key = lowercase app name, value = icon string
    property var iconMap: ({
    })

    function loadIcons() {
        // Resolve relative paths to absolute
        let resolvedPath = iconPath;
        if (iconPath.startsWith("./") || iconPath.startsWith("../")) {
            let base = Qt.resolvedUrl(".").replace("file://", "");
            resolvedPath = base + "/" + iconPath;
        }
        // Read the file with a Process
        let cmd = `import Quickshell.Io; Process {
            command: ["cat", "${resolvedPath}"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        let data = JSON.parse(text.trim())
                        let map = {}
                        let apps = data.apps || []
                        for (let i = 0; i < apps.length; i++) {
                            let app = apps[i]
                            if (app.icon) {
                                map[app.name.toLowerCase()] = app.icon
                            }
                            let aliases = app.aliases || []
                            for (let j = 0; j < aliases.length; j++) {
                                if (app.icon) {
                                    map[aliases[j].toLowerCase()] = app.icon
                                }
                            }
                        }
                        root.iconMap = map
                    } catch(e) {
                        console.log("AppIcons: failed to parse", resolvedPath, e)
                    }
                }
            }
            stderr: StdioCollector {
                onStreamFinished: {
                    if (text.trim()) console.log("AppIcons error:", text.trim())
                }
            }
        }`;
        let process = Qt.createQmlObject(cmd, root);
        process.running = true;
    }

    function getIcon(appName) {
        let lower = appName.toLowerCase();
        // direct match
        if (iconMap[lower])
            return iconMap[lower];

        // substring match
        for (let key in iconMap) {
            if (lower.indexOf(key) !== -1 || key.indexOf(lower) !== -1)
                return iconMap[key];

        }
        return "󰎆"; // fallback icon
    }

    // Reload when the path changes
    onIconPathChanged: {
        if (iconPath)
            loadIcons();

    }
    // Also load once when the component is ready (in case iconPath is already set)
    Component.onCompleted: {
        if (iconPath)
            loadIcons();

    }
}
