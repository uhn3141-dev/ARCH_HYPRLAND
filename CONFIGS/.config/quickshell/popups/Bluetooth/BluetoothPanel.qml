import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PopupWindow {
    id: bluetoothPopup

    // Entry animations
    property real introTop: 0
    property real introList: 0
    readonly property bool isBusy: Object.keys(bluetoothManager.busyTasks).length > 0
    readonly property int pollInterval: isBusy ? 1000 : 3000
    property alias bluetoothManager: bluetoothManager

    anchor.window: root
    anchor.rect.x: root.width / 2 - width / 2
    anchor.rect.y: 31
    implicitWidth: 300
    implicitHeight: 300
    color: 'transparent'
    visible: false
    onVisibleChanged: {
        if (visible) {
            introTop = 0;
            introList = 0;
            entryAnim.restart();
            bluetoothManager.getStatus();
        }
    }

    ParallelAnimation {
        id: entryAnim

        NumberAnimation {
            target: bluetoothPopup
            property: "introTop"
            from: 0.2
            to: 1
            duration: 250
            easing.type: Easing.OutBack
        }

        SequentialAnimation {
            PauseAnimation {
                duration: 200
            }

            NumberAnimation {
                target: bluetoothPopup
                property: "introList"
                from: 0.2
                to: 1
                duration: 500
                easing.type: Easing.OutBack
            }

        }

    }

    Timer {
        id: statusTimer

        interval: bluetoothPopup.pollInterval
        running: bluetoothPopup.visible && !bluetoothManager.scanning
        repeat: true
        onTriggered: bluetoothManager.getStatus()
    }

    Timer {
        id: busyTimeout

        interval: 15000
        onTriggered: {
            bluetoothManager.busyTasks = ({
            });
            bluetoothManager.connectingDevice = "";
            bluetoothManager.pairingDevice = "";
            bluetoothManager.disconnectingDevice = "";
        }
    }

    QtObject {
        id: bluetoothManager

        property bool bluetoothPresent: false
        property bool bluetoothPowered: false
        property var connectedDevices: []
        property var discoveredDevices: []
        property bool loading: false
        property bool scanning: false
        property var busyTasks: ({
        })
        property string pairingDevice: ""
        property string connectingDevice: ""
        property string disconnectingDevice: ""
        property string failedId: ""
        property var autoConnectStates: ({
        })
        property string cachedJson: ""
        property string scriptPath: _HOMEDIR + "/.config/quickshell/popups/Bluetooth/bluetooth_panel_logic.sh"
        property Process statusProcess: null
        property Timer scanTimer

        scanTimer: Timer {
            interval: 2000
            repeat: true
            onTriggered: {
                if (bluetoothManager.scanning)
                    bluetoothManager.getStatus();
                else
                    stop();
            }
        }

        property var disconnectingDevices: ({
        })

        function getStatus() {
            if (statusProcess && statusProcess.running)
                return ;

            loading = true;
            statusProcess = Qt.createQmlObject('
                import Quickshell.Io
                Process {
                    command: ["bash", bluetoothManager.scriptPath, "--status"]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            try {
                                var cleanText = text.trim()
                                var startIdx = cleanText.indexOf("{")
                                var endIdx = cleanText.lastIndexOf("}")
                                if (startIdx >= 0 && endIdx > startIdx) {
                                    cleanText = cleanText.substring(startIdx, endIdx + 1)
                                }
                                if (cleanText) {
                                    bluetoothManager.cachedJson = cleanText
                                    var result = JSON.parse(cleanText)
                                    bluetoothManager.bluetoothPresent = result.present
                                    bluetoothManager.bluetoothPowered = result.power === "on"
                                    bluetoothManager.connectedDevices = result.connected || []
                                    bluetoothManager.discoveredDevices = result.devices || []

                                    var currentStates = bluetoothManager.autoConnectStates || {}
                                    var newStates = {}
                                    var allDevices = bluetoothManager.connectedDevices.concat(bluetoothManager.discoveredDevices)
                                    for (var i = 0; i < allDevices.length; i++) {
                                        var mac = allDevices[i].mac
                                        newStates[mac] = currentStates[mac] !== undefined ? currentStates[mac] : true
                                    }
                                    bluetoothManager.autoConnectStates = newStates

                                    var bt = bluetoothManager.busyTasks
                                    var dd = bluetoothManager.disconnectingDevices
                                    var changed = false

                                    for (var mac in bt) {
                                        var found = false
                                        for (var i = 0; i < bluetoothManager.connectedDevices.length; i++) {
                                            if (bluetoothManager.connectedDevices[i].mac === mac) {
                                                found = true
                                                break
                                            }
                                        }
                                        if (found) {
                                            delete bt[mac]
                                            changed = true
                                        }
                                    }

                                    for (var dMac in dd) {
                                        var stillConnected = false
                                        for (var j = 0; j < bluetoothManager.connectedDevices.length; j++) {
                                            if (bluetoothManager.connectedDevices[j].mac === dMac) {
                                                stillConnected = true
                                                break
                                            }
                                        }
                                        if (!stillConnected) {
                                            delete dd[dMac]
                                            changed = true
                                        }
                                    }

                                    if (changed) {
                                        bluetoothManager.busyTasks = Object.assign({}, bt)
                                        bluetoothManager.disconnectingDevices = Object.assign({}, dd)
                                        if (Object.keys(bt).length === 0 && Object.keys(dd).length === 0) {
                                            busyTimeout.stop()
                                        }
                                    }

                                    bluetoothManager.pairingDevice = ""
                                    bluetoothManager.connectingDevice = ""
                                    bluetoothManager.disconnectingDevice = ""
                                }
                            } catch(e) {
                                console.log("[BT] Error:", e)
                            }
                            bluetoothManager.loading = false
                            bluetoothManager.statusProcess = null
                        }
                    }
                }
            ', bluetoothManager);
            statusProcess.running = true;
        }

        function toggleScan() {
            if (scanning) {
                scanning = false;
                scanTimer.stop();
                let cmd = "import Quickshell.Io; Process { command: [\"bash\", \"-c\", \"bluetoothctl scan off 2>/dev/null\"] }";
                let stopProcess = Qt.createQmlObject(cmd, bluetoothManager);
                stopProcess.running = true;
                loading = false;
                Qt.callLater(getStatus, 500);
            } else {
                scanning = true;
                loading = true;
                let cmd = "import Quickshell.Io; Process { command: [\"bash\", \"-c\", \"rfkill unblock bluetooth; bluetoothctl scan on &\"] }";
                let startProcess = Qt.createQmlObject(cmd, bluetoothManager);
                startProcess.running = true;
                Qt.callLater(getStatus, 3000);
                scanTimer.interval = 3000;
                scanTimer.start();
            }
        }

        function togglePower() {
            let process = Qt.createQmlObject('
                import Quickshell.Io
                Process {
                    command: ["bash", bluetoothManager.scriptPath, "--toggle"]
                }
            ', bluetoothManager);
            process.running = true;
            Qt.callLater(getStatus, 1500);
        }

        function connectDevice(mac) {
            connectingDevice = mac;
            busyTasks[mac] = true;
            busyTasks = Object.assign({
            }, busyTasks);
            busyTimeout.restart();
            let cmd = "import Quickshell.Io; Process { command: [\"bash\", bluetoothManager.scriptPath, \"--connect\", \"" + mac + "\"] }";
            let process = Qt.createQmlObject(cmd, bluetoothManager);
            process.running = true;
            Qt.callLater(getStatus, 2000);
        }

        function disconnectDevice(mac) {
            disconnectingDevices[mac] = true;
            disconnectingDevices = Object.assign({
            }, disconnectingDevices);
            busyTimeout.restart();
            let cmd = "import Quickshell.Io; Process { command: [\"bash\", bluetoothManager.scriptPath, \"--disconnect\", \"" + mac + "\"] }";
            let process = Qt.createQmlObject(cmd, bluetoothManager);
            process.running = true;
            Qt.callLater(getStatus, 2000);
        }

        function pairDevice(mac) {
            pairingDevice = mac;
            busyTasks[mac] = true;
            busyTasks = Object.assign({
            }, busyTasks);
            busyTimeout.restart();
            let cmd = "import Quickshell.Io; Process { command: [\"bash\", \"-c\", \"bluetoothctl pair " + mac + " && bluetoothctl connect " + mac + "\"] }";
            let process = Qt.createQmlObject(cmd, bluetoothManager);
            process.running = true;
            Qt.callLater(getStatus, 2000);
        }

        Component.onCompleted: {
            if (cachedJson !== "") {
                try {
                    var result = JSON.parse(cachedJson);
                    bluetoothPresent = result.present;
                    bluetoothPowered = result.power === "on";
                    connectedDevices = result.connected || [];
                    discoveredDevices = result.devices || [];
                } catch (e) {
                }
            }
            getStatus();
        }
    }

    Rectangle {
        id: bluetoothPanel

        anchors.fill: parent
        color: theme.colSurface
        radius: 20
        border.width: 3
        border.color: theme.colSurface
        opacity: bluetoothPopup.visible ? 1 : 0
        scale: bluetoothPopup.visible ? 1 : 0.2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ============================================================
            // TOP ROW: Power + Scan Buttons
            // ============================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                opacity: bluetoothPopup.introTop

                Rectangle {
                    id: bluetoothPowerButton

                    property bool isHovered: bluetoothPowerButtonMouse.containsMouse

                    Layout.preferredWidth: 132
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignHCenter
                    color: isHovered ? (bluetoothManager.bluetoothPowered ? "#4CAF50" : theme.colTertiary) : (bluetoothManager.bluetoothPowered ? "#4CAF50" : theme.colPrimary)
                    radius: config.elementRadius + 2
                    border.width: 2
                    border.color: config.widgetBorder
                    scale: isHovered ? 1.1 : 1

                    Text {
                        anchors.centerIn: parent
                        text: bluetoothManager.bluetoothPowered ? "⏻" : "⏼"
                        color: theme.colOnPrimary

                        font {
                            pixelSize: config.fontSize * 2.8
                            bold: true
                        }

                    }

                    MouseArea {
                        id: bluetoothPowerButtonMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bluetoothManager.togglePower()
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }

                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutBack
                        }

                    }

                }

                Rectangle {
                    id: bluetoothScanButton

                    property bool isHovered: bluetoothScanButtonMouse.containsMouse

                    Layout.preferredWidth: 132
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignHCenter
                    color: isHovered ? (bluetoothManager.scanning ? "#FF9800" : theme.colTertiary) : (bluetoothManager.scanning ? "#FF9800" : theme.colPrimary)
                    radius: config.elementRadius + 2
                    border.width: 2
                    border.color: config.widgetBorder
                    scale: isHovered ? 1.1 : 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰐷"
                        color: theme.colOnPrimary

                        font {
                            pixelSize: config.fontSize * 2.8
                            bold: true
                        }

                        RotationAnimation on rotation {
                            running: bluetoothManager.scanning
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }

                    }

                    MouseArea {
                        id: bluetoothScanButtonMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bluetoothManager.toggleScan()
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }

                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutBack
                        }

                    }

                }

                transform: Translate {
                    y: 15 * (1 - bluetoothPopup.introTop)
                }

            }

            // ============================================================
            // DEVICE LIST
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: theme.colSecondary
                radius: 14
                clip: true
                opacity: bluetoothPopup.introList
                // Border glow on hover
                border.width: deviceListHover.containsMouse ? 2 : 0
                border.color: deviceListHover.containsMouse ? theme.colPrimary : "transparent"

                MouseArea {
                    id: deviceListHover

                    anchors.fill: parent
                    hoverEnabled: true
                }

                // Empty state
                Text {
                    anchors.centerIn: parent
                    text: !bluetoothManager.bluetoothPresent ? "Bluetooth adapter not found" : !bluetoothManager.bluetoothPowered ? "Bluetooth is turned off" : (bluetoothManager.connectedDevices.length === 0 && bluetoothManager.discoveredDevices.length === 0) ? (bluetoothManager.scanning ? "Scanning..." : "No devices found") : ""
                    color: theme.colOnSecondary
                    font.pixelSize: config.fontSize * 1.2
                    visible: !bluetoothManager.bluetoothPresent || !bluetoothManager.bluetoothPowered || (bluetoothManager.connectedDevices.length === 0 && bluetoothManager.discoveredDevices.length === 0)
                }

                // Device list
                Item {
                    visible: bluetoothManager.bluetoothPresent && bluetoothManager.bluetoothPowered && (bluetoothManager.connectedDevices.length > 0 || bluetoothManager.discoveredDevices.length > 0)

                    anchors {
                        fill: parent
                        margins: 10
                    }

                    Flickable {
                        id: deviceFlickable

                        anchors.fill: parent
                        contentHeight: deviceColumn.height
                        clip: true
                        interactive: deviceColumn.height > height
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: deviceColumn

                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: bluetoothManager.connectedDevices.concat(bluetoothManager.discoveredDevices)

                                delegate: Rectangle {
                                    id: btCard

                                    property bool expanded: false
                                    property bool isConnected: bluetoothManager.connectedDevices.some((d) => {
                                        return d.mac === modelData.mac;
                                    })
                                    property bool isPaired: modelData.action === "Connect" || isConnected
                                    property bool isMyBusy: !!bluetoothManager.busyTasks[modelData.mac]
                                    property bool isMyDisconnecting: !!bluetoothManager.disconnectingDevices[modelData.mac]
                                    property bool isPairing: bluetoothManager.pairingDevice === modelData.mac
                                    property bool isConnecting: bluetoothManager.connectingDevice === modelData.mac
                                    property real infoOpacity: 0

                                    width: parent.width
                                    height: expanded ? 90 : 55
                                    color: theme.colPrimary
                                    radius: 10
                                    clip: true
                                    opacity: isMyBusy ? 0.7 : 1

                                    // Main row
                                    Item {
                                        height: 40

                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            top: parent.top
                                            margins: 10
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 8

                                            Text {
                                                text: modelData.icon || ""
                                                font.pixelSize: config.fontSize * 1.8
                                                color: theme.colOnPrimary
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2

                                                Text {
                                                    text: modelData.name || "Unknown Device"
                                                    color: theme.colOnPrimary
                                                    font.pixelSize: config.fontSize * 1.1
                                                    font.weight: Font.DemiBold
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }

                                                Text {
                                                    text: modelData.mac || ""
                                                    color: theme.colOnPrimary
                                                    font.pixelSize: config.fontSize * 0.75
                                                    opacity: 0.6
                                                    font.family: "monospace"
                                                }

                                            }

                                            // Battery
                                            Row {
                                                spacing: 4
                                                visible: isConnected && modelData.battery && modelData.battery !== "0"
                                                Layout.alignment: Qt.AlignVCenter

                                                Text {
                                                    text: parseInt(modelData.battery) > 80 ? "" : parseInt(modelData.battery) > 60 ? "" : parseInt(modelData.battery) > 40 ? "" : parseInt(modelData.battery) > 20 ? "" : ""
                                                    color: parseInt(modelData.battery) > 20 ? theme.colOnPrimary : "#FF5252"
                                                    font.pixelSize: config.fontSize * 1.1
                                                }

                                                Text {
                                                    text: modelData.battery + "%"
                                                    color: parseInt(modelData.battery) > 20 ? theme.colOnPrimary : "#FF5252"
                                                    font.pixelSize: config.fontSize * 0.9
                                                    font.weight: Font.DemiBold
                                                }

                                            }

                                            // Status dot
                                            Rectangle {
                                                width: 8
                                                height: 8
                                                radius: 4
                                                color: isMyBusy ? "#FF9800" : isMyDisconnecting ? "#FF5252" : isConnected ? "#4CAF50" : isPaired ? "#FF9800" : "#FF5252"
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                        }

                                    }

                                    // Click area for expanding
                                    MouseArea {
                                        height: 40
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (btCard.expanded) {
                                                btCard.infoOpacity = 0;
                                                expanded = false;
                                            } else {
                                                expanded = true;
                                                Qt.callLater(function() {
                                                    btCard.infoOpacity = 1;
                                                }, 320);
                                            }
                                        }

                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            top: parent.top
                                        }

                                    }

                                    // Expanded buttons row
                                    RowLayout {
                                        spacing: 6
                                        opacity: btCard.infoOpacity
                                        visible: btCard.infoOpacity > 0.75

                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            bottom: parent.bottom
                                            margins: 8
                                        }

                                        // Pair button
                                        Rectangle {
                                            property bool pairBtnHover: false

                                            Layout.fillWidth: true
                                            height: 28
                                            radius: 8
                                            color: isPaired ? theme.colSurfaceVariant : (pairBtnHover ? theme.colSecondaryContainer : theme.colTertiaryContainer)
                                            opacity: isPairing ? 0.5 : (isPaired ? 0.5 : 1)

                                            Text {
                                                anchors.centerIn: parent
                                                text: isPairing ? "Pairing..." : isPaired ? "Paired" : "Pair"
                                                color: isPaired ? theme.colOnSurfaceVariant : theme.colOnTertiaryContainer
                                                font.pixelSize: config.fontSize * 0.75
                                                font.weight: Font.Medium
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                enabled: !isPairing && !isPaired
                                                onEntered: parent.pairBtnHover = true
                                                onExited: parent.pairBtnHover = false
                                                onClicked: bluetoothManager.pairDevice(modelData.mac)
                                            }

                                        }

                                        // Connect/Disconnect button
                                        Rectangle {
                                            property bool connectBtnHover: false

                                            Layout.fillWidth: true
                                            height: 28
                                            radius: 8
                                            color: connectBtnHover ? theme.colSecondaryContainer : theme.colTertiaryContainer
                                            opacity: isConnecting || isMyDisconnecting ? 0.5 : 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: isConnecting ? "Connecting..." : isMyDisconnecting ? "Disconnecting..." : isConnected ? "Disconnect" : "Connect"
                                                color: isConnected && !isMyDisconnecting ? "#FF5252" : "#4CAF50"
                                                font.pixelSize: config.fontSize * 0.75
                                                font.weight: Font.Medium
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                enabled: !isConnecting && !isMyDisconnecting
                                                onEntered: parent.connectBtnHover = true
                                                onExited: parent.connectBtnHover = false
                                                onClicked: {
                                                    if (isConnected)
                                                        bluetoothManager.disconnectDevice(modelData.mac);
                                                    else
                                                        bluetoothManager.connectDevice(modelData.mac);
                                                }
                                            }

                                        }

                                        // Auto-connect toggle
                                        Rectangle {
                                            property bool autoBtnHover: false
                                            property bool autoConnectEnabled: {
                                                if (!modelData || !modelData.mac)
                                                    return false;

                                                if (!bluetoothManager.autoConnectStates)
                                                    return true;

                                                return bluetoothManager.autoConnectStates[modelData.mac] !== undefined ? bluetoothManager.autoConnectStates[modelData.mac] : true;
                                            }

                                            Layout.fillWidth: true
                                            height: 28
                                            radius: 8
                                            color: autoBtnHover ? theme.colSecondaryContainer : theme.colTertiaryContainer

                                            Text {
                                                anchors.centerIn: parent
                                                text: parent.autoConnectEnabled ? "Auto: ON" : "Auto: OFF"
                                                color: parent.autoConnectEnabled ? "#4CAF50" : theme.colOnTertiaryContainer
                                                font.pixelSize: config.fontSize * 0.7
                                                font.weight: Font.Medium
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onEntered: parent.autoBtnHover = true
                                                onExited: parent.autoBtnHover = false
                                                onClicked: {
                                                    if (!modelData || !modelData.mac)
                                                        return ;

                                                    if (!bluetoothManager.autoConnectStates)
                                                        bluetoothManager.autoConnectStates = ({
                                                        });

                                                    let newState = !parent.autoConnectEnabled;
                                                    let states = bluetoothManager.autoConnectStates;
                                                    states[modelData.mac] = newState;
                                                    bluetoothManager.autoConnectStates = Object.assign({
                                                    }, states);
                                                    let cmd = "import Quickshell.Io; Process { command: [\"bash\", \"-c\", \"bluetoothctl " + (newState ? "trust " : "untrust ") + modelData.mac + "\"] }";
                                                    let process = Qt.createQmlObject(cmd, bluetoothManager);
                                                    process.running = true;
                                                }
                                            }

                                        }

                                    }

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: 300
                                            easing.type: Easing.OutCubic
                                        }

                                    }

                                    Behavior on infoOpacity {
                                        NumberAnimation {
                                            duration: 150
                                        }

                                    }

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 200
                                        }

                                    }

                                }

                            }

                        }

                    }

                }

                transform: Translate {
                    y: 15 * (1 - bluetoothPopup.introList)
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: 300
                    }

                }

                Behavior on border.width {
                    NumberAnimation {
                        duration: 200
                    }

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

}
