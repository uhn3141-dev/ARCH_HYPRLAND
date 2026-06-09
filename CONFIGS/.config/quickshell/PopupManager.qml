import QtQuick
import Quickshell.Io

Item {
    id: popupManager

    property var popups: ({
    })
    property string ipcDir: "/tmp/quickshell_ipc"

    function readIpcFile(filepath) {
        let cmd = "import Quickshell.Io; Process { command: [\"cat\", \"" + filepath + "\"]; stdout: StdioCollector { onStreamFinished: { popupManager.processIpc(text.trim()); } } }";
        let process = Qt.createQmlObject(cmd, popupManager);
        process.running = true;
        // Delete the file after reading
        let delCmd = "import Quickshell.Io; Process { command: [\"rm\", \"-f\", \"" + filepath + "\"] }";
        let delProcess = Qt.createQmlObject(delCmd, popupManager);
        delProcess.running = true;
    }

    function processIpc(line) {
        if (!line)
            return ;

        let parts = line.split(":");
        let action = parts[0];
        let target = parts[1];
        if (action === "close" && target === "all") {
            closeAll();
        } else if (action === "toggle") {
            if (popups[target]) {
                if (popups[target].visible)
                    hidePopup(target);
                else
                    showPopup(target);
            }
        }
    }

    function registerPopup(id, popupWindow) {
        popups[id] = popupWindow;
        popups = Object.assign({
        }, popups);
    }

    function showPopup(id) {
        if (!popups[id])
            return ;

        for (var otherId in popups) {
            if (otherId !== id && popups[otherId] && popups[otherId].visible)
                popups[otherId].visible = false;

        }
        popups[id].visible = true;
    }

    function hidePopup(id) {
        if (popups[id])
            popups[id].visible = false;

    }

    function closeAll() {
        for (var id in popups) {
            if (popups[id] && popups[id].visible)
                popups[id].visible = false;

        }
    }

    // Watch for new IPC files
    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: {
            let cmd = "import Quickshell.Io; Process { command: [\"bash\", \"-c\", \"ls -1tr " + ipcDir + "/msg_* 2>/dev/null\"]; stdout: StdioCollector { onStreamFinished: { var files = text.trim().split('\\n'); for (var i = 0; i < files.length; i++) { if (files[i]) popupManager.readIpcFile(files[i]); } } } }";
            let process = Qt.createQmlObject(cmd, popupManager);
            process.running = true;
        }
    }

}
