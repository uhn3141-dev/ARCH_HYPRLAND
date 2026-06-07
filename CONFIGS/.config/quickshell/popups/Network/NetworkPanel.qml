import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

PopupWindow {
    id: networkPopup

    anchor.window: root
    anchor.rect.x: root.width / 2 - width / 2
    anchor.rect.y: 31

    implicitWidth: 300
    implicitHeight: 400

    color: 'transparent'
    visible: false

    onVisibleChanged: {
        if (visible) {
            introTop = 0
            introList = 0
            introTabs = 0
            entryAnim.restart()
        }
    }

    property string activeTab: "ethernet"
    property bool wifiPowered: false
    property bool ethernetPowered: false
    property bool wifiScanning: false
    property var connectedNetwork: null
    property var wifiNetworks: []
    property var ethernetInfo: null
    property string pendingSsid: ""
    property string pendingId: ""
    property string expandedNetwork: ""

    property real introTop: 0
    property real introList: 0
    property real introTabs: 0

    ParallelAnimation {
        id: entryAnim
        NumberAnimation {
            target: networkPopup
            property: "introTop"
            from: 0
            to: 1
            duration: 500
            easing.type: Easing.OutBack
        }
        SequentialAnimation {
            PauseAnimation { duration: 200 }
            NumberAnimation {
                target: networkPopup
                property: "introList"
                from: 0
                to: 1
                duration: 400
                easing.type: Easing.OutBack
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: 300 }
            NumberAnimation {
                target: networkPopup
                property: "introTabs"
                from: 0
                to: 1
                duration: 800
                easing.type: Easing.OutBack
            }
        }
    }

    Component.onCompleted: {}

    QtObject {
        id: networkManager
        
        property string wifiScript: _HOMEDIR + "/.config/quickshell/popups/Network/wifi_panel_logic.sh"
        property string ethernetScript: _HOMEDIR + "/.config/quickshell/popups/Network/ethernet_panel_logic.sh"
        
        function getWifiStatus() {
            let cmd = "import Quickshell.Io; Process { command: [\"bash\", networkManager.wifiScript]; stdout: StdioCollector { onStreamFinished: { try { var r = JSON.parse(text.trim()); networkPopup.wifiPowered = r.power === 'on'; networkPopup.connectedNetwork = r.connected; if (r.networks && r.networks.length > 0) networkPopup.wifiNetworks = r.networks; } catch(e) {} } } }"
            let process = Qt.createQmlObject(cmd, networkPopup)
            process.running = true
        }
        
        function getEthernetStatus() {
            let cmd = "import Quickshell.Io; Process { command: [\"bash\", networkManager.ethernetScript]; stdout: StdioCollector { onStreamFinished: { try { var r = JSON.parse(text.trim()); networkPopup.ethernetInfo = r; networkPopup.ethernetPowered = r.power === 'on'; } catch(e) {} } } }"
            let process = Qt.createQmlObject(cmd, networkPopup)
            process.running = true
        }
        
        function toggleWifi() {
            Quickshell.execDetached(["bash", "-c", "nmcli radio wifi " + (wifiPowered ? "off" : "on")])
            Qt.callLater(getWifiStatus, 1000)
        }

        function toggleEthernet() {
            let dev = ethernetInfo ? ethernetInfo.device : ""
            if (!dev) return
            if (ethernetPowered) {
                Quickshell.execDetached(["bash", "-c", "nmcli device disconnect " + dev])
            } else {
                Quickshell.execDetached(["bash", "-c", "nmcli device connect " + dev])
            }
            Qt.callLater(getEthernetStatus, 1000)
        }
        
        function connectWifi(ssid, password) {
            pendingId = ssid
            let cmd = "import Quickshell.Io; Process { command: [\"bash\", \"-c\", \"nmcli device wifi connect '" + ssid + "'" + (password ? " password '" + password + "'" : "") + "\"]; stdout: StdioCollector { onStreamFinished: { networkManager.getWifiStatus(); networkPopup.pendingId = ''; } } }"
            let process = Qt.createQmlObject(cmd, networkPopup)
            process.running = true
        }
        
        function disconnectWifi() {
            Quickshell.execDetached(["bash", "-c", "nmcli device disconnect $(nmcli -t -f DEVICE,TYPE d | grep wifi | cut -d: -f1)"])
            Qt.callLater(getWifiStatus, 1000)
        }
        
        Component.onCompleted: {
            getWifiStatus()
            getEthernetStatus()
        }
    }

    Timer {
        interval: 3000
        running: networkPopup.visible && !wifiScanning
        repeat: true
        onTriggered: {
            if (activeTab === "wifi") networkManager.getWifiStatus()
            else networkManager.getEthernetStatus()
        }
    }

    Rectangle {
        id: networkPanel
        anchors.fill: parent
        color: theme.colSurface
        radius: 20
        border.width: 3
        border.color: theme.colSurface

        opacity: networkPopup.visible ? 1 : 0
        scale: networkPopup.visible ? 1 : 0.2
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ============================================================
            // TOP ROW: Power + Scan + Quick Info
            // ============================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                opacity: networkPopup.introTop
                transform: Translate { y: 15 * (1 - networkPopup.introTop) }

                // Power Button
                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 34
                    radius: 17

                    property bool isHovered: networkPowerHover.containsMouse

                    color: isHovered ? theme.colTertiary : theme.colPrimary

                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    scale: isHovered ? 1.1 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (activeTab === "wifi") return wifiPowered ? "⏻" : "⏼"
                            if (activeTab === "ethernet") return ethernetPowered ? "⏻" : "⏼"
                            return "⏼"
                        }
                        color: {
                            if (activeTab === "wifi" && wifiPowered) return "#4CAF50"
                            if (activeTab === "ethernet" && ethernetPowered) return "#4CAF50"
                            return theme.colOnPrimary
                        }
                        font.pixelSize: config.fontSize * 1.6
                    }

                    MouseArea {
                        id: networkPowerHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (activeTab === "wifi") networkManager.toggleWifi()
                            else networkManager.toggleEthernet()
                        }
                    }
                }

                // Scan Button
                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 34
                    radius: 17
                    visible: activeTab === "wifi"

                    property bool isHovered: wifiScanHover.containsMouse

                    color: isHovered ? 
                        (wifiScanning ? "#FF9800" : theme.colTertiary) : 
                        (wifiScanning ? "#FF9800" : theme.colPrimary)

                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    scale: isHovered ? 1.1 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: "󰐷"
                        color: theme.colOnPrimary
                        font.pixelSize: config.fontSize * 1.6

                        RotationAnimation on rotation {
                            running: wifiScanning
                            from: 0; to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }
                    }

                    MouseArea {
                        id: wifiScanHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            wifiScanning = true
                            networkManager.getWifiStatus()
                            Qt.callLater(function() { wifiScanning = false }, 2000)
                        }
                    }
                }

                // Quick Info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (activeTab === "wifi" && connectedNetwork) return connectedNetwork.ssid
                            if (activeTab === "ethernet" && ethernetInfo && ethernetInfo.connected) return ethernetInfo.connected.name
                            return "Disconnected"
                        }
                        color: theme.colOnTertiaryContainer
                        font.pixelSize: config.fontSize * 1.1
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (activeTab === "wifi" && connectedNetwork) return connectedNetwork.ip || ""
                            if (activeTab === "ethernet" && ethernetInfo && ethernetInfo.connected) return ethernetInfo.connected.ip || ""
                            return ""
                        }
                        color: theme.colOnTertiaryContainer
                        font.pixelSize: config.fontSize * 0.8
                        opacity: 0.7
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }
            }

            // ============================================================
            // MIDDLE: Scrollable Network List
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: theme.colSecondary
                radius: 14
                clip: true
                opacity: networkPopup.introList
                transform: Translate { y: 15 * (1 - networkPopup.introList) }

                // ---- WiFi Tab ----
                // Nothing tested and worked in wifi just implemention as i have no wifi adapter
                Item {
                    anchors.fill: parent
                    visible: activeTab === "wifi"
                    opacity: activeTab === "wifi" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 8
                        contentHeight: wifiColumn.height
                        clip: true
                        interactive: wifiColumn.height > height
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: wifiColumn
                            width: parent.width
                            spacing: 6

                            // Connected network card
                            Rectangle {
                                width: parent.width
                                height: connectedNetwork ? 60 : 0
                                visible: connectedNetwork !== null
                                color: theme.colPrimary
                                radius: 10
                                clip: true

                                Behavior on height {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }

                                RowLayout {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: 10
                                    }
                                    height: 44
                                    spacing: 8

                                    Text {
                                        text: connectedNetwork ? (connectedNetwork.icon || "󰤨") : ""
                                        font.pixelSize: config.fontSize * 1.8
                                        color: theme.colOnPrimary
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: connectedNetwork ? connectedNetwork.ssid : ""
                                            color: theme.colOnPrimary
                                            font.pixelSize: config.fontSize * 1.2
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }

                                        Text {
                                            text: connectedNetwork ? (connectedNetwork.ip || "Connected") : ""
                                            color: "#4CAF50"
                                            font.pixelSize: config.fontSize * 0.8
                                        }
                                    }

                                    Rectangle {
                                        width: 65
                                        height: 28
                                        radius: 14
                                        color: "#FF5252"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Disconnect"
                                            color: "#fff"
                                            font.pixelSize: config.fontSize * 0.7
                                            font.weight: Font.Medium
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: networkManager.disconnectWifi()
                                        }
                                    }
                                }
                            }

                            // Available networks
                            Repeater {
                                model: wifiNetworks

                                delegate: Rectangle {
                                    id: wifiCard
                                    width: parent.width
                                    height: cardExpanded ? 130 : 55
                                    color: theme.colPrimary
                                    radius: 10
                                    clip: true

                                    property bool cardExpanded: networkPopup.expandedNetwork === modelData.id
                                    property bool isConnectedNet: connectedNetwork && connectedNetwork.ssid === modelData.ssid
                                    property bool isPending: modelData.id === pendingId
                                    property bool showPassword: false
                                    property real infoOpacity: 0
                                    property bool autoConnectEnabled: false

                                    property string downSpeed: "0 KB/s"
                                    property string upSpeed: "0 KB/s"
                                    property string currDown: ""
                                    property string currUp: ""
                                    property string prevDown: ""
                                    property string prevUp: ""

                                    function formatSpeedStr(bytes) {
                                        var b = parseInt(bytes)
                                        if (isNaN(b) || b <= 0) return "0 KB/s"
                                        if (b > 1048576) return (b / 1048576).toFixed(1) + " MB/s"
                                        if (b >= 1024) return Math.round(b / 1024) + " KB/s"
                                        return b + " B/s"
                                    }

                                    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                    Behavior on infoOpacity { NumberAnimation { duration: 150 } }
                                    opacity: isPending ? 0.6 : 1.0
                                    Behavior on opacity { NumberAnimation { duration: 200 } }

                                    // Main row
                                    RowLayout {
                                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                                        height: 40
                                        spacing: 8

                                        Text {
                                            text: modelData.icon || "󰤯"
                                            font.pixelSize: config.fontSize * 1.5
                                            color: theme.colOnPrimary
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text {
                                                text: modelData.ssid || "Unknown"
                                                color: theme.colOnPrimary; font.pixelSize: config.fontSize * 1.1
                                                font.weight: Font.DemiBold; elide: Text.ElideRight; width: parent.width
                                            }
                                            Text {
                                                text: modelData.security || "Open"
                                                color: modelData.security && modelData.security !== "Open" ? "#FF9800" : "#4CAF50"
                                                font.pixelSize: config.fontSize * 0.75
                                            }
                                        }

                                        // Speed rect (only visible when connected)
                                        Rectangle {
                                            Layout.preferredWidth: 60
                                            Layout.preferredHeight: 38
                                            radius: 10
                                            color: theme.colPrimaryContainer
                                            Layout.alignment: Qt.AlignVCenter
                                            visible: wifiCard.isConnectedNet

                                            ColumnLayout {
                                                anchors.fill: parent; spacing: 0

                                                Rectangle {
                                                    Layout.fillWidth: true; Layout.fillHeight: true; color: "transparent"
                                                    RowLayout {
                                                        anchors.centerIn: parent; spacing: 3
                                                        Text { text: "↑"; font.pixelSize: config.fontSize * 1.0; color: '#008cff' }
                                                        Text { text: wifiCard.upSpeed || "0 KB/s"; font.pixelSize: config.fontSize * 0.6; color: theme.colOnPrimaryContainer; font.weight: Font.Medium }
                                                    }
                                                }
                                                Rectangle { Layout.fillWidth: true; height: 1; color: theme.colOnSurfaceVariant; opacity: 0.15 }
                                                Rectangle {
                                                    Layout.fillWidth: true; Layout.fillHeight: true; color: "transparent"
                                                    RowLayout {
                                                        anchors.centerIn: parent; spacing: 3
                                                        Text { text: "↓"; font.pixelSize: config.fontSize * 1.0; color: "#4CAF50" }
                                                        Text { text: wifiCard.downSpeed || "0 KB/s"; font.pixelSize: config.fontSize * 0.6; color: theme.colOnPrimaryContainer; font.weight: Font.Medium }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Click area for expanding
                                    MouseArea {
                                        anchors { left: parent.left; right: parent.right; top: parent.top }
                                        height: 40
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (wifiCard.cardExpanded) {
                                                wifiCard.infoOpacity = 0
                                                showPassword = false
                                                expandedNetwork = ""
                                            } else {
                                                expandedNetwork = modelData.id
                                                if (!wifiCard.isConnectedNet) {
                                                    let sec = (modelData.security || "").toLowerCase()
                                                    if (sec !== "" && sec !== "open" && sec !== "--" && sec !== "none") {
                                                        showPassword = true
                                                        passwordField.text = ""
                                                        Qt.callLater(function() { 
                                                            wifiCard.infoOpacity = 1
                                                            Qt.callLater(function() {
                                                                passwordField.forceActiveFocus()
                                                            }, 100)
                                                        }, 400)
                                                    } else {
                                                        Qt.callLater(function() { wifiCard.infoOpacity = 1 }, 320)
                                                    }
                                                } else {
                                                    Qt.callLater(function() { wifiCard.infoOpacity = 1 }, 320)
                                                }
                                            }
                                        }
                                    }

                                    // Expanded section
                                    ColumnLayout {
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 8 }
                                        spacing: 6
                                        opacity: wifiCard.infoOpacity
                                        visible: wifiCard.infoOpacity > 0.7


                                        // Row 1: Password + Show/Hide
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 6

                                            Rectangle {
                                                Layout.fillWidth: true; height: 28; radius: 14; color: theme.colSurfaceVariant
                                                
                                                TextInput {
                                                    id: passwordField
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 10
                                                    anchors.rightMargin: 10
                                                    verticalAlignment: TextInput.AlignVCenter
                                                    color: theme.colOnSurfaceVariant
                                                    font.pixelSize: config.fontSize * 0.85
                                                    echoMode: passVisible ? TextInput.Normal : TextInput.Password
                                                    property bool passVisible: false
                                                }
                                            }

                                            Rectangle {
                                                width: 28; height: 28; radius: 14; color: theme.colSurfaceVariant
                                                Text { anchors.centerIn: parent; text: passwordField.passVisible ? "🙈" : "👁"; font.pixelSize: config.fontSize * 0.8 }
                                                MouseArea {
                                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: passwordField.passVisible = !passwordField.passVisible
                                                }
                                            }
                                        }

                                        // Row 2: Connect/Disconnect + Auto-connect + Forget
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 6

                                            // Connect/Disconnect
                                            Rectangle {
                                                Layout.fillWidth: true; height: 28; radius: 14
                                                color: wifiCard.isConnectedNet ? "#FF5252" : "#4CAF50"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: wifiCard.isConnectedNet ? "Disconnect" : (isPending ? "..." : "Connect")
                                                    color: "#fff"; font.pixelSize: config.fontSize * 0.7; font.weight: Font.DemiBold
                                                }
                                                MouseArea {
                                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (wifiCard.isConnectedNet) {
                                                            networkManager.disconnectWifi()
                                                        } else {
                                                            if (showPassword && pendingSsid === modelData.ssid) {
                                                                networkManager.connectWifi(pendingSsid, passwordField.text)
                                                                passwordField.text = ""; pendingSsid = ""; showPassword = false
                                                            } else {
                                                                networkManager.connectWifi(modelData.ssid, "")
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // Auto-connect toggle
                                            Rectangle {
                                                Layout.fillWidth: true; height: 28; radius: 14
                                                color: wifiCard.autoConnectEnabled ? "#4CAF50" : theme.colSurfaceVariant
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: wifiCard.autoConnectEnabled ? "Auto: ON" : "Auto: OFF"
                                                    color: wifiCard.autoConnectEnabled ? "#fff" : theme.colOnSurfaceVariant
                                                    font.pixelSize: config.fontSize * 0.65; font.weight: Font.Medium
                                                }
                                                MouseArea {
                                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: { wifiCard.autoConnectEnabled = !wifiCard.autoConnectEnabled }
                                                }
                                            }

                                            // Forget button
                                            Rectangle {
                                                Layout.fillWidth: true; height: 28; radius: 14
                                                color: theme.colSurfaceVariant
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Forget"
                                                    color: "#FF5252"
                                                    font.pixelSize: config.fontSize * 0.7; font.weight: Font.Medium
                                                }
                                                MouseArea {
                                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        networkManager.forgetNetwork(modelData.ssid)
                                                        expandedNetwork = ""
                                                        wifiCard.infoOpacity = 0
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Empty state
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: !wifiPowered ? "WiFi is off" : 
                                      (!connectedNetwork && wifiNetworks.length === 0 ? "No networks found" : "")
                                color: theme.colOnSecondary
                                font.pixelSize: config.fontSize * 1.1
                                visible: text !== ""
                            }
                        }
                    }
                }

                // ---- Ethernet Tab ----
                Item {
                    anchors.fill: parent
                    visible: activeTab === "ethernet"
                    opacity: activeTab === "ethernet" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 8
                        contentHeight: ethColumn.height
                        clip: true

                        Column {
                            id: ethColumn
                            width: parent.width
                            spacing: 6

                            // Ethernet card
                            Rectangle {
                                id: ethCard
                                width: parent.width
                                height: ethCard.ethExpanded ? 135 : 60
                                color: theme.colPrimary
                                radius: 10
                                clip: true

                                property bool ethExpanded: networkPopup.expandedNetwork === "ethernet"
                                property bool isConnected: ethernetInfo && ethernetInfo.connected
                                property real infoOpacity: 0

                                // Speed update timer
                                Timer {
                                    id: speedTimer
                                    interval: 1000
                                    running: false
                                    repeat: true
                                    onTriggered: {
                                        let dev = ethernetInfo && ethernetInfo.device ? ethernetInfo.device : "enp2s0"
                                        
                                        let cmd = 'import Quickshell.Io; Process {'
                                        cmd += 'command: ["bash", "-c", "cat /proc/net/dev | grep ' + dev + ' | awk \'{print $2,$10}\'"]; '
                                        cmd += 'stdout: StdioCollector { '
                                        cmd += 'onStreamFinished: { '
                                        cmd += 'var parts = text.trim().split(/\\s+/); '
                                        cmd += 'if (parts.length >= 2) { '
                                        cmd += 'ethCard.prevDown = ethCard.currDown || parts[0]; '
                                        cmd += 'ethCard.prevUp = ethCard.currUp || parts[1]; '
                                        cmd += 'ethCard.currDown = parts[0]; '
                                        cmd += 'ethCard.currUp = parts[1]; '
                                        cmd += 'var downDiff = parseInt(ethCard.currDown) - parseInt(ethCard.prevDown); '
                                        cmd += 'var upDiff = parseInt(ethCard.currUp) - parseInt(ethCard.prevUp); '
                                        cmd += 'ethCard.downSpeed = ethCard.formatSpeedStr(downDiff); '
                                        cmd += 'ethCard.upSpeed = ethCard.formatSpeedStr(upDiff); '
                                        cmd += '} else { console.log("[Speed] Not enough parts"); } '
                                        cmd += '} } }'
                                        
                                        let process = Qt.createQmlObject(cmd, networkPopup)
                                        process.running = true
                                    }
                                }

                                // Start speed updates when connected
                                onIsConnectedChanged: {
                                    if (isConnected) {
                                        speedTimer.running = true
                                    } else {
                                        speedTimer.running = false
                                    }
                                }

                                property string downSpeed: "0 KB/s"
                                property string upSpeed: "0 KB/s"
                                property string currDown: ""
                                property string currUp: ""
                                property string prevDown: ""
                                property string prevUp: ""

                                function formatSpeedStr(bytes) {
                                    var b = parseInt(bytes)
                                    if (isNaN(b) || b <= 0) return "0 KB/s"
                                    if (b > 1048576) return (b / 1048576).toFixed(1) + " MB/s"
                                    if (b >= 1024) return Math.round(b / 1024) + " KB/s"
                                    return b + " B/s"
                                }

                                Behavior on height {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }
                                Behavior on infoOpacity { NumberAnimation { duration: 150 } }

                                // Main row
                                Item {
                                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                                    height: 44

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 8

                                        Text {
                                            text: "󰈀"
                                            font.pixelSize: config.fontSize * 1.8
                                            color: ethCard.isConnected ? "#4CAF50" : theme.colOnPrimary
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                text: ethernetInfo && ethCard.isConnected ? ethernetInfo.connected.name : "Ethernet"
                                                color: theme.colOnPrimary
                                                font.pixelSize: config.fontSize * 1.2
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                                width: parent.width
                                            }

                                            Text {
                                                text: ethCard.isConnected ? "Connected" : "Disconnected"
                                                color: ethCard.isConnected ? "#4CAF50" : "#FF5252"
                                                font.pixelSize: config.fontSize * 0.8
                                            }
                                        }

                                        // Upload/Download speeds
                                        Rectangle {
                                            Layout.preferredWidth: 80
                                            Layout.preferredHeight: 38
                                            radius: 10
                                            color: theme.colPrimaryContainer
                                            Layout.alignment: Qt.AlignVCenter

                                            ColumnLayout {
                                                anchors.fill: parent
                                                spacing: 0

                                                // Upload (top half)
                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    color: "transparent"
                                                    radius: 10

                                                    RowLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 3

                                                        Text {
                                                            text: "↑"
                                                            font.pixelSize: config.fontSize *1.25
                                                            color: '#008cff'
                                                        }
                                                        Text {
                                                            text: ethCard.upSpeed || "0 KB/s"
                                                            font.pixelSize: config.fontSize
                                                            color: theme.colOnPrimaryContainer
                                                            font.weight: Font.Medium
                                                        }
                                                    }
                                                }

                                                // Divider
                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    height: 1
                                                    color: theme.colOnSurfaceVariant
                                                    opacity: 0.15
                                                }

                                                // Download (bottom half)
                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    color: "transparent"

                                                    RowLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 3

                                                        Text {
                                                            text: "↓"
                                                            font.pixelSize: config.fontSize * 1.25
                                                            color: "#4CAF50"
                                                        }
                                                        Text {
                                                            text: ethCard.downSpeed || "0 KB/s"
                                                            font.pixelSize: config.fontSize
                                                            color: theme.colOnPrimaryContainer
                                                            font.weight: Font.Medium
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (ethCard.ethExpanded) {
                                                ethCard.infoOpacity = 0
                                                expandedNetwork = ""
                                            } else {
                                                expandedNetwork = "ethernet"
                                                Qt.callLater(function() { ethCard.infoOpacity = 1 }, 320)
                                            }
                                        }
                                    }
                                }

                                // Expanded info
                                GridLayout {
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10 }
                                    columns: 2
                                    rowSpacing: 3
                                    columnSpacing: 10
                                    opacity: ethCard.infoOpacity
                                    visible: ethCard.infoOpacity > 0.75

                                    EthInfoRow { label: "Interface"; value: ethernetInfo ? ethernetInfo.device || "-" : "-" }
                                    EthInfoRow { label: "Driver"; value: ethernetInfo && ethCard.isConnected ? ethernetInfo.connected.driver || "-" : "-" }
                                    EthInfoRow { label: "IPv4"; value: ethernetInfo && ethCard.isConnected ? ethernetInfo.connected.ip || "-" : "-" }
                                    EthInfoRow { label: "Subnet"; value: ethernetInfo && ethCard.isConnected ? ethernetInfo.connected.subnet || "-" : "-" }
                                    EthInfoRow { label: "Gateway"; value: ethernetInfo && ethCard.isConnected ? ethernetInfo.connected.gateway || "-" : "-" }
                                    EthInfoRow { label: "DNS"; value: ethernetInfo && ethCard.isConnected ? ethernetInfo.connected.dns || "-" : "-" }
                                    EthInfoRow { label: "Speed"; value: ethernetInfo && ethCard.isConnected ? ethernetInfo.connected.speed || "-" : "-" }
                                    EthInfoRow { label: "Duplex"; value: ethernetInfo && ethCard.isConnected ? ethernetInfo.connected.duplex || "-" : "-" }
                                    EthInfoRow { label: "MAC"; value: ethernetInfo && ethCard.isConnected ? ethernetInfo.connected.mac || "-" : "-" }
                                    EthInfoRow { label: "MTU"; value: ethernetInfo && ethCard.isConnected ? ethernetInfo.connected.mtu || "-" : "-" }
                                }
                            }
                        }
                    }
                }
            }

            // ============================================================
            // BOTTOM: Tab Switcher
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: theme.colSecondary
                radius: 14
                opacity: networkPopup.introTabs
                transform: Translate { y: 15 * (1 - networkPopup.introTabs) }

                // Animated pill
                Rectangle {
                    width: (parent.width - 8) / 2
                    height: parent.height - 8
                    y: 4
                    radius: 10
                    color: theme.colPrimary
                    x: activeTab === "wifi" ? 4 : width + 4

                    Behavior on x {
                        NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰤨 WiFi"
                            color: activeTab === "wifi" ? theme.colOnPrimary : theme.colOnSecondary
                            font.pixelSize: config.fontSize * 1
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                activeTab = "wifi"
                                networkManager.getWifiStatus()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰈀 Ethernet"
                            color: activeTab === "ethernet" ? theme.colOnPrimary : theme.colOnSecondary
                            font.pixelSize: config.fontSize * 1
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                activeTab = "ethernet"
                                networkManager.getEthernetStatus()
                            }
                        }
                    }
                }
            }
        }
    }

    // ============================================================
    // COMPONENT: EthInfoRow
    // ============================================================
    component EthInfoRow: RowLayout {
        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        spacing: 8

        Text {
            text: label
            color: theme.colOnPrimary
            font.pixelSize: config.fontSize * 0.8
            font.weight: Font.Medium
            Layout.preferredWidth: 65
        }

        Text {
            Layout.fillWidth: true
            text: value
            color: theme.colOnPrimary
            font.pixelSize: config.fontSize * 0.8
            horizontalAlignment: Text.AlignRight
        }
    }
}