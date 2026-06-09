import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PopupWindow {
    id: sysPopup

    // === State ===
    property string activeTab: "cpu"
    property var cpuData: ({
    })
    property var gpuData: ({
    })
    property var memData: ({
    })
    property var diskData: []
    property var appsData: []
    property real introOrbs: 0
    property real introTabs: 0
    property real introContent: 0
    readonly property color cpuColor: "#FF5722"
    readonly property color gpuColor: "#9C27B0"
    readonly property color memColor: "#2196F3"
    readonly property color diskColor: "#4CAF50"
    readonly property color tabColor: {
        if (activeTab === "cpu")
            return cpuColor;

        if (activeTab === "gpu")
            return gpuColor;

        if (activeTab === "memory")
            return memColor;

        if (activeTab === "disk")
            return diskColor;

        return "#FF9800";
    }
    property string scriptPath: _HOMEDIR + "/.config/quickshell/popups/SystemMonitor/system_info.sh"
    property string jsonFilePath: _HOMEDIR + "/.config/quickshell/popups/SystemMonitor/system_info.json"
    // Expand states
    property bool cpuExpanded: false
    property bool gpuExpanded: false
    property bool memExpanded: false
    property bool diskExpanded: true

    function readSystemData() {
        let cmd = "import Quickshell.Io; Process { command: [\"cat\", sysPopup.jsonFilePath]; stdout: StdioCollector { onStreamFinished: {";
        cmd += "try {";
        cmd += "  var all = JSON.parse(text.trim());";
        cmd += "  cpuData = all.cpu || {};";
        cmd += "  gpuData = all.gpu || {};";
        cmd += "  memData = all.memory || {};";
        cmd += "  diskData = all.disk || [];";
        cmd += "  appsData = all.apps || [];";
        cmd += "} catch(e) {}";
        cmd += "} } }";
        let process = Qt.createQmlObject(cmd, sysPopup);
        // Force canvas repaint on every orb (optional but explicit)
        cpuOrb.canvas.requestPaint();
        gpuOrb.canvas.requestPaint();
        memOrb.canvas.requestPaint();
        diskOrb.canvas.requestPaint();
        process.running = true;
    }

    // Right‑anchored
    anchor.window: root
    anchor.rect.x: root.width - width - 20
    anchor.rect.y: 31
    implicitWidth: 380
    implicitHeight: 500
    color: 'transparent'
    visible: false
    onVisibleChanged: {
        if (visible) {
            introOrbs = 0;
            introTabs = 0;
            introContent = 0;
            entryAnim.restart();
            // Start daemon and reading
            Quickshell.execDetached(["bash", scriptPath, "--daemon", jsonFilePath]);
            readTimer.start();
        } else {
            Quickshell.execDetached(["bash", "-c", "pkill -f 'system_info.sh --daemon'"]);
            readTimer.stop();
        }
    }

    // === Entry Animations ===
    ParallelAnimation {
        id: entryAnim

        NumberAnimation {
            target: sysPopup
            property: "introOrbs"
            from: 0
            to: 1
            duration: 400
            easing.type: Easing.OutBack
        }

        SequentialAnimation {
            PauseAnimation {
                duration: 100
            }

            NumberAnimation {
                target: sysPopup
                property: "introTabs"
                from: 0
                to: 1
                duration: 400
                easing.type: Easing.OutBack
            }

        }

        SequentialAnimation {
            PauseAnimation {
                duration: 200
            }

            NumberAnimation {
                target: sysPopup
                property: "introContent"
                from: 0
                to: 1
                duration: 450
                easing.type: Easing.OutBack
            }

        }

    }

    // === Data Reader (1 second interval) ===
    Timer {
        id: readTimer

        interval: 1000
        repeat: true
        onTriggered: readSystemData()
    }

    // === Main Panel ===
    Rectangle {
        id: sysPanel

        anchors.fill: parent
        color: theme.colSurface
        radius: 20
        border.width: 3
        border.color: theme.colSurface
        opacity: sysPopup.visible ? 1 : 0
        scale: sysPopup.visible ? 1 : 0.2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ─── ORBS ──────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                opacity: sysPopup.introOrbs

                UsageOrb {
                    id: cpuOrb

                    label: "CPU"
                    usage: cpuData.usage || 0
                    temp: cpuData.temp || 0
                    orbColor: cpuColor
                    onUpdateRequested: readSystemData()
                }

                UsageOrb {
                    id: gpuOrb

                    label: "GPU"
                    usage: gpuData.usage || 0
                    temp: gpuData.temp || 0
                    orbColor: gpuColor
                    onUpdateRequested: readSystemData()
                }

                UsageOrb {
                    id: memOrb

                    label: "MEM"
                    usage: memData.usage || 0
                    temp: 0
                    orbColor: memColor
                    showTemp: false
                    onUpdateRequested: readSystemData()
                }

                UsageOrb {
                    id: diskOrb

                    label: "DISK"
                    usage: diskData.usage || 0
                    temp: 0
                    orbColor: diskColor
                    showTemp: false
                    onUpdateRequested: readSystemData()
                }

                transform: Translate {
                    y: 15 * (1 - sysPopup.introOrbs)
                }

            }

            // ─── TABS ──────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: theme.colSecondary
                radius: 10
                opacity: sysPopup.introTabs

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 3

                    SysTab {
                        text: "CPU"
                        tabId: "cpu"
                    }

                    SysTab {
                        text: "GPU"
                        tabId: "gpu"
                    }

                    SysTab {
                        text: "Memory"
                        tabId: "memory"
                    }

                    SysTab {
                        text: "Disk"
                        tabId: "disk"
                    }

                    SysTab {
                        text: "Apps"
                        tabId: "apps"
                    }

                }

                transform: Translate {
                    y: 15 * (1 - sysPopup.introTabs)
                }

            }

            // ─── CONTENT (fixed height, top‑aligned) ────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 280
                color: theme.colSecondary
                radius: 14
                clip: true
                opacity: sysPopup.introContent

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 8
                    contentHeight: contentColumn.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        // ─── DISK TAB ───────────────────
                        // ─── APPS TAB ───────────────────

                        id: contentColumn

                        width: parent.width
                        spacing: 6

                        // ─── CPU TAB ────────────────────
                        Item {
                            width: parent.width
                            height: cpuCard.height
                            visible: activeTab === "cpu"

                            Rectangle {
                                id: cpuCard

                                width: parent.width
                                height: cpuColumn.implicitHeight
                                color: theme.colPrimary
                                radius: 10

                                Column {
                                    id: cpuColumn

                                    width: parent.width

                                    // --- Header (always visible, clickable) ---
                                    Rectangle {
                                        width: parent.width
                                        height: 36
                                        color: "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "CPU: " + (cpuData.model || "Unknown")
                                            color: theme.colOnPrimary
                                            font.pixelSize: config.fontSize
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: cpuExpanded = !cpuExpanded
                                        }

                                    }

                                    // --- Expanded content (with margins) ---
                                    Column {
                                        width: parent.width
                                        visible: cpuExpanded
                                        opacity: cpuExpanded ? 1 : 0

                                        // Add top margin, horizontal margins, and bottom margin
                                        Item {
                                            width: parent.width
                                            height: childrenRect.height + 4

                                            RowLayout {
                                                spacing: 8

                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                    top: parent.top
                                                    margins: 8 // 10px left, right, top
                                                }

                                                Column {
                                                    Layout.fillWidth: true
                                                    spacing: 6

                                                    InfoRow {
                                                        label: "Usage"
                                                        value: (cpuData.usage || 0) + "%"
                                                    }

                                                    InfoRow {
                                                        label: "Cores"
                                                        value: cpuData.cores ? cpuData.cores : "-"
                                                    }

                                                    InfoRow {
                                                        label: "Frequency"
                                                        value: cpuData.freq ? cpuData.freq + " GHz" : "-"
                                                    }

                                                    InfoRow {
                                                        label: "Temperature"
                                                        value: cpuData.temp ? cpuData.temp + "°C" : "-"
                                                    }

                                                }

                                                Column {
                                                    Layout.fillWidth: true
                                                    spacing: 6

                                                    InfoRow {
                                                        label: "L2 Cache"
                                                        value: cpuData.l2 || "-"
                                                    }

                                                    InfoRow {
                                                        label: "L3 Cache"
                                                        value: cpuData.l3 || "-"
                                                    }

                                                    InfoRow {
                                                        label: "Governor"
                                                        value: cpuData.governor || "-"
                                                    }

                                                    InfoRow {
                                                        label: "Processes"
                                                        value: cpuData.processes || "-"
                                                    }

                                                }

                                            }

                                        }

                                        // Optional bottom margin – can be added as an extra spacer
                                        Rectangle {
                                            width: parent.width
                                            height: 10
                                            color: "transparent"
                                        }

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 150
                                            }

                                        }

                                    }

                                }

                                Behavior on height {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                        }

                        // ─── GPU TAB ────────────────────
                        Item {
                            width: parent.width
                            height: gpuCard.height
                            visible: activeTab === "gpu"

                            Rectangle {
                                id: gpuCard

                                width: parent.width
                                height: gpuColumn.implicitHeight
                                color: theme.colPrimary
                                radius: 10

                                Column {
                                    id: gpuColumn

                                    width: parent.width

                                    Rectangle {
                                        width: parent.width
                                        height: 36
                                        color: "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "GPU: " + (gpuData.model || "Unknown")
                                            color: theme.colOnPrimary
                                            font.pixelSize: config.fontSize
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: gpuExpanded = !gpuExpanded
                                        }

                                    }

                                    Column {
                                        width: parent.width
                                        visible: gpuExpanded
                                        opacity: gpuExpanded ? 1 : 0

                                        Item {
                                            width: parent.width
                                            height: childrenRect.height + 4

                                            RowLayout {
                                                spacing: 8

                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                    top: parent.top
                                                    margins: 8
                                                }

                                                Column {
                                                    Layout.fillWidth: true
                                                    spacing: 6

                                                    InfoRow {
                                                        label: "Usage"
                                                        value: (gpuData.usage || 0) + "%"
                                                    }

                                                    InfoRow {
                                                        label: "Frequency"
                                                        value: gpuData.freq ? gpuData.freq + " MHz" : "-"
                                                    }

                                                    InfoRow {
                                                        label: "Temperature"
                                                        value: gpuData.temp ? gpuData.temp + "°C" : "-"
                                                    }

                                                    InfoRow {
                                                        label: "VRAM Used"
                                                        value: gpuData.vram ? gpuData.vram + "M" : "-"
                                                    }

                                                }

                                                Column {
                                                    Layout.fillWidth: true
                                                    spacing: 6

                                                    InfoRow {
                                                        label: "VRAM Total"
                                                        value: gpuData.vram_total ? gpuData.vram_total + "M" : "-"
                                                    }

                                                    InfoRow {
                                                        label: "Driver"
                                                        value: gpuData.driver || "-"
                                                    }

                                                    InfoRow {
                                                        label: "PCIe"
                                                        value: gpuData.pcie || "-"
                                                    }

                                                }

                                            }

                                        }

                                        Rectangle {
                                            width: parent.width
                                            height: 10
                                            color: "transparent"
                                        }

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 150
                                            }

                                        }

                                    }

                                }

                                Behavior on height {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                        }

                        // ─── MEMORY TAB ─────────────────
                        Item {
                            width: parent.width
                            height: memCard.height
                            visible: activeTab === "memory"

                            Rectangle {
                                id: memCard

                                width: parent.width
                                height: memColumn.implicitHeight
                                color: theme.colPrimary
                                radius: 10

                                Column {
                                    id: memColumn

                                    width: parent.width

                                    Rectangle {
                                        width: parent.width
                                        height: 36
                                        color: "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Memory"
                                            color: theme.colOnPrimary
                                            font.pixelSize: config.fontSize
                                            font.weight: Font.DemiBold
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: memExpanded = !memExpanded
                                        }

                                    }

                                    Column {
                                        width: parent.width
                                        visible: memExpanded
                                        opacity: memExpanded ? 1 : 0

                                        Item {
                                            width: parent.width
                                            height: childrenRect.height + 4

                                            RowLayout {
                                                spacing: 8

                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                    top: parent.top
                                                    margins: 8
                                                }

                                                Column {
                                                    Layout.fillWidth: true
                                                    spacing: 6

                                                    InfoRow {
                                                        label: "Usage"
                                                        value: (memData.usage || 0) + "%"
                                                    }

                                                    InfoRow {
                                                        label: "Total"
                                                        value: memData.total || "-"
                                                    }

                                                    InfoRow {
                                                        label: "Used"
                                                        value: memData.used || "-"
                                                    }

                                                    InfoRow {
                                                        label: "Available"
                                                        value: memData.available || "-"
                                                    }

                                                    InfoRow {
                                                        label: "Cached"
                                                        value: memData.cached || "-"
                                                    }

                                                }

                                                Column {
                                                    Layout.fillWidth: true
                                                    spacing: 6

                                                    InfoRow {
                                                        label: "Buffers"
                                                        value: memData.buffers || "-"
                                                    }

                                                    InfoRow {
                                                        label: "Swap Total"
                                                        value: memData.swap_total || "-"
                                                    }

                                                    InfoRow {
                                                        label: "Swap Used"
                                                        value: memData.swap_used || "-"
                                                    }

                                                    InfoRow {
                                                        label: "Swap %"
                                                        value: memData.swap_pct ? memData.swap_pct + "%" : "0%"
                                                    }

                                                }

                                            }

                                        }

                                        Rectangle {
                                            width: parent.width
                                            height: 10
                                            color: "transparent"
                                        }

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 150
                                            }

                                        }

                                    }

                                }

                                Behavior on height {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                        }

                    }

                }

                transform: Translate {
                    y: 15 * (1 - sysPopup.introContent)
                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutBack
            }

        }

    }

    // ────────────────────────────────────────────
    // COMPONENTS
    // ────────────────────────────────────────────
    component UsageOrb: Rectangle {
        property string label: ""
        property real usage: 0
        property real temp: 0
        property color orbColor: "#2196F3"
        property bool showTemp: true
        // Smoothly animated usage for the progress ring
        property real animUsage: 0
        property alias canvas: orbCanvas

        // Signal emitted every 2 seconds – parent can react to refresh data
        signal updateRequested(string orbLabel)

        width: 80
        height: 80
        radius: 50
        color: theme.colSecondary
        onUsageChanged: animUsage = usage

        Canvas {
            id: orbCanvas

            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var r = width / 2 - 6;
                var cx = width / 2, cy = height / 2;
                // Background ring
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, Math.PI * 2);
                ctx.strokeStyle = theme.colSurfaceVariant;
                ctx.lineWidth = 8;
                ctx.stroke();
                if (animUsage > 0) {
                    // Progress arc
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + (animUsage / 100) * Math.PI * 2);
                    ctx.strokeStyle = animUsage > 80 ? "#FF5252" : (animUsage > 50 ? "#FF9800" : orbColor);
                    ctx.lineWidth = 9;
                    ctx.lineCap = "round";
                    ctx.stroke();
                }
            }

            // Repaint when animUsage changes
            Connections {
                function onAnimUsageChanged() {
                    orbCanvas.requestPaint();
                }

                target: parent
            }

        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 1

            Text {
                text: usage + "%"
                color: usage > 80 ? "#FF5252" : (usage > 50 ? "#FF9800" : orbColor)
                font.pixelSize: config.fontSize * 1.3
                font.weight: Font.Black
                font.family: "monospace"
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: label
                color: theme.colOnSecondary
                font.pixelSize: config.fontSize * 0.65
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: showTemp ? temp + "°C" : ""
                color: temp > 70 ? "#FF5252" : (temp > 50 ? "#FF9800" : theme.colOnSecondary)
                font.pixelSize: config.fontSize * 0.55
                visible: showTemp
                Layout.alignment: Qt.AlignHCenter
            }

        }

        Behavior on animUsage {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }

        }

    }

    component SysTab: Rectangle {
        property string text: ""
        property string tabId: ""

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 7
        color: activeTab === tabId ? theme.colPrimary : "transparent"

        Text {
            anchors.centerIn: parent
            text: parent.text
            color: activeTab === tabId ? theme.colOnPrimary : theme.colOnSecondary
            font.pixelSize: config.fontSize * 0.7
            font.weight: Font.Medium
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                activeTab = tabId;
            }
        }

    }

    component InfoRow: RowLayout {
        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        spacing: 6

        Text {
            text: label
            color: theme.colOnPrimary
            font.pixelSize: config.fontSize * 0.9
            font.weight: Font.Medium
            opacity: 0.7
            Layout.preferredWidth: 90
        }

        Text {
            Layout.fillWidth: true
            text: value
            color: theme.colOnPrimary
            font.pixelSize: config.fontSize * 0.9
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }

    }

}
