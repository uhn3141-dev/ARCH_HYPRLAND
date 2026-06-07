import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import "./../../" as Icons

PopupWindow {
    id: batteryPopup

    Icons.AppIcons { 
        id: appIcons
        iconPath: _HOMEDIR + "/.config/quickshell/app_icons.json"
    }

    anchor.window: root
    anchor.rect.x: root.width / 2 - width / 2
    anchor.rect.y: 31

    implicitWidth: 300
    implicitHeight: 400

    color: 'transparent'
    visible: false

    onVisibleChanged: {
        if (visible) {
            introMain = 0
            introInfo = 0
            introTabs = 0
            entryAnim.restart()
            getBatteryStatus()
            getUptime()
            getStats()
            forceActiveFocus()
        }
    }

    // === State ===
    property int batteryPercent: 100
    property bool isCharging: false
    property string batteryStatus: "Discharging"
    property real introMain: 0
    property real introInfo: 0
    property real introTabs: 0
    property real chargeAnimProgress: 0
    property string uptimeStr: "00:00:00"
    property string activeTab: "uptime"

    // Stats
    property int daysHistory: 14
    property string selectedDate: ""  // ISO date string, empty = today
    property var todayStats: ({})
    property var appList: []
    property var appIconMap: ({})
    property var uptimeBars: []
    property string statsFile: _HOMEDIR + "/.config/quickshell/popups/Battery/qs_battery_stats.json"

    // === Entry Animations ===
    ParallelAnimation {
        id: entryAnim
        NumberAnimation {
            target: batteryPopup; property: "introMain"
            from: 0; to: 1; duration: 400; easing.type: Easing.OutBack
        }
        SequentialAnimation {
            PauseAnimation { duration: 80 }
            NumberAnimation {
                target: batteryPopup; property: "introInfo"
                from: 0; to: 1; duration: 450; easing.type: Easing.OutBack
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: 160 }
            NumberAnimation {
                target: batteryPopup; property: "introTabs"
                from: 0; to: 1; duration: 500; easing.type: Easing.OutBack
            }
        }
    }

    NumberAnimation on chargeAnimProgress {
        running: isCharging
        from: 0; to: 30
        duration: 60000
        loops: Animation.Infinite
        easing.type: Easing.Linear
    }

    // === Timer ===
    Timer {
        interval: 10000
        running: batteryPopup.visible
        repeat: true
        onTriggered: {
            getBatteryStatus()
            getUptime()
            getStats()
        }
    }

    // === Functions ===
    function getBatteryStatus() {
        let cmd = "import Quickshell.Io; Process {"
        cmd += "command: [\"bash\", \"-c\", \"cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo '0'; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1 || echo 'Unknown'\"]; "
        cmd += "stdout: StdioCollector { onStreamFinished: {"
        cmd += "var lines = text.trim().split('\\\\n');"
        cmd += "if (lines.length >= 2) {"
        cmd += "  batteryPercent = parseInt(lines[0]) || 50;"
        cmd += "  batteryStatus = lines[1];"
        cmd += "  isCharging = (batteryStatus === 'Charging' || batteryStatus === 'Full');"
        cmd += "}"
        cmd += "} } }"
        let process = Qt.createQmlObject(cmd, batteryPopup)
        process.running = true
    }

    function getUptime() {
        let cmd = "import Quickshell.Io; Process {"
        cmd += "command: [\"bash\", \"-c\", \"awk '{printf \\\"%d:%02d:%02d\\\", int($1/3600), int(($1%3600)/60), int($1%60)}' /proc/uptime\"]; "
        cmd += "stdout: StdioCollector { onStreamFinished: {"
        cmd += "uptimeStr = text.trim();"
        cmd += "} } }"
        let process = Qt.createQmlObject(cmd, batteryPopup)
        process.running = true
    }

    function getStats() {
        let cmd = "import Quickshell.Io; Process {"
        cmd += "command: [\"bash\", \"-c\", \"cat " + statsFile + " 2>/dev/null || echo '{\\\"days\\\":{}}'\"]; "
        cmd += "stdout: StdioCollector { onStreamFinished: {"
        cmd += "try {"
        cmd += "  todayStats = JSON.parse(text.trim());"
        cmd += "  updateUptimeBars();"
        cmd += "  updateAppList();"
        cmd += "} catch(e) {}"
        cmd += "} } }"
        let process = Qt.createQmlObject(cmd, batteryPopup)
        process.running = true
    }

    function updateUptimeBars() {
        let bars = []
        let today = new Date()
        let todayKey = today.getFullYear() + "-" +
                    String(today.getMonth() + 1).padStart(2, '0') + "-" +
                    String(today.getDate()).padStart(2, '0')

        for (let i = daysHistory - 1; i >= 0; i--) {
            let d = new Date(today)
            d.setDate(d.getDate() - i)
            let dayKey = d.getFullYear() + "-" +
                        String(d.getMonth() + 1).padStart(2, '0') + "-" +
                        String(d.getDate()).padStart(2, '0')
            let dayData = todayStats.days ? todayStats.days[dayKey] : null
            let uptimeSecs = dayData ? dayData.uptime : 0
            let hours = (uptimeSecs / 3600).toFixed(1)
            let pct = Math.min(1, uptimeSecs / (24 * 3600))
            bars.push({
                date: String(d.getDate()).padStart(2, '0') + "/" + String(d.getMonth() + 1).padStart(2, '0'),
                dateKey: dayKey,
                hours: hours + "h",
                pct: pct,
                isToday: dayKey === todayKey          // ✅ correct today flag
            })
        }
        uptimeBars = bars
    }

    function resolveAppName(appTitle) {
        let name = appTitle
        
        // Find the last " — " or " - " and take everything after it
        let emDashIdx = name.lastIndexOf(" — ")
        let enDashIdx = name.lastIndexOf(" – ")
        let hyphenIdx = name.lastIndexOf(" - ")
        
        let lastSeparator = Math.max(emDashIdx, enDashIdx, hyphenIdx)
        
        if (lastSeparator >= 0) {
            name = name.substring(lastSeparator + 3)  // Skip past " — " (3 chars)
        }
        
        // Remove "(1) " or "[1] " prefix
        name = name.replace(/^[\(\[]\d+[\)\]]\s*/, '')
        
        // Trim
        name = name.trim()
        
        return name || appTitle
    }

    function resolveAppIcon(appTitle) {
        return appIcons.getIcon(appTitle)
    }

    function updateAppList() {
        let targetDate = selectedDate
        if (!targetDate) {
            let today = new Date()
            targetDate = today.getFullYear() + "-" +
                        String(today.getMonth() + 1).padStart(2, '0') + "-" +
                        String(today.getDate()).padStart(2, '0')
        }
        
        let dayData = todayStats.days ? todayStats.days[targetDate] : null
        if (!dayData || !dayData.apps) { appList = []; return }

        let totalSeconds = 0
        for (let app in dayData.apps) { totalSeconds += dayData.apps[app] }

        let apps = []
        let colors = ["#2196F3", "#4CAF50", "#FF9800", "#9C27B0", "#607D8B", "#E91E63", "#00BCD4", "#FF5722"]
        let idx = 0

        for (let appName in dayData.apps) {
            let seconds = dayData.apps[appName]
            let h = Math.floor(seconds / 3600)
            let m = Math.floor((seconds % 3600) / 60)
            let timeStr = h > 0 ? h + "h " + m + "m" : m + "m"
            apps.push({
                name: resolveAppName(appName),
                icon: resolveAppIcon(appName),
                pct: totalSeconds > 0 ? Math.round((seconds / totalSeconds) * 100) : 0,
                time: timeStr,
                color: colors[idx % colors.length]
            })
            idx++
        }

        apps.sort((a, b) => b.pct - a.pct)
        appList = apps.slice(0, 10)
    }

    function navigateDay(delta) {
        if (!selectedDate) {
            // start from today
            let today = new Date()
            selectedDate = today.getFullYear() + "-" +
                        String(today.getMonth() + 1).padStart(2, '0') + "-" +
                        String(today.getDate()).padStart(2, '0')
        }
        let parts = selectedDate.split("-")
        let d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
        d.setDate(d.getDate() + delta)
        selectedDate = d.getFullYear() + "-" +
                    String(d.getMonth() + 1).padStart(2, '0') + "-" +
                    String(d.getDate()).padStart(2, '0')
        updateAppList()
        scrollToDate(selectedDate)
    }

    function scrollToDate(dateKey) {
        if (!uptimeBars.length) return
        let targetIndex = -1
        for (let i = 0; i < uptimeBars.length; i++) {
            if (uptimeBars[i].dateKey === dateKey || (!dateKey && uptimeBars[i].isToday)) {
                targetIndex = i
                break
            }
        }
        if (targetIndex === -1) targetIndex = uptimeBars.length - 1 // default to last (today)
        
        let barWidth = 44
        let spacing = 10
        let targetX = targetIndex * (barWidth + spacing) - uptimeFlickable.width / 2 + barWidth / 2
        targetX = Math.max(0, Math.min(targetX, uptimeRow.width - uptimeFlickable.width + 16))
        uptimeFlickable.contentX = targetX
    }

    // ============================================================
    // UI
    // ============================================================
    Rectangle {
        id: batteryPanel
        anchors.fill: parent
        color: theme.colSurface
        radius: 14
        border.width: 3
        border.color: theme.colSurface

        opacity: batteryPopup.visible ? 1 : 0
        scale: batteryPopup.visible ? 1 : 0.9
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            // ============================================================
            // ROW 1: Battery Icon + Slider
            // ============================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                opacity: batteryPopup.introMain
                transform: Translate { y: 10 * (1 - batteryPopup.introMain) }

                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 40
                    radius: 12
                    color: "transparent"
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: "#4CAF50"
                        opacity: isCharging ? 0.15 + (0.1 * Math.sin(chargeAnimProgress * Math.PI * 2)) : 0
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (batteryPercent >= 90) return ""
                            if (batteryPercent >= 70) return ""
                            if (batteryPercent >= 40) return ""
                            if (batteryPercent >= 15) return ""
                            return ""
                        }
                        font.pixelSize: config.fontSize * 2.5
                        color: {
                            if (isCharging) return "#4CAF50"
                            if (batteryPercent >= 70) return "#4CAF50"
                            if (batteryPercent >= 30) return "#FF9800"
                            return "#FF5252"
                        }
                        Behavior on color { ColorAnimation { duration: 300 } }
                        scale: isCharging ? 1.0 + (0.1 * Math.sin(chargeAnimProgress * Math.PI * 3)) : 1.0
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "⚡"
                        font.pixelSize: config.fontSize * 2
                        color: "#FFEB3B"
                        visible: isCharging
                        opacity: 0.5 + (0.5 * Math.abs(Math.sin(chargeAnimProgress * Math.PI * 2)))
                        y: -4 * Math.sin(chargeAnimProgress * Math.PI * 2)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 18
                    color: theme.colSecondary
                    clip: true

                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                            margins: 3
                        }
                        width: Math.max(22, (parent.width - 6) * (batteryPercent / 100))
                        radius: 16
                        clip: true

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0.0
                                color: isCharging ? "#4CAF50" : (batteryPercent < 15 ? "#FF5252" : (batteryPercent < 40 ? "#FF9800" : (batteryPercent < 70 ? "#FFCC00" : "#4CAF50")))
                            }
                            GradientStop {
                                position: 1.0
                                color: isCharging ? Qt.lighter("#4CAF50", 1.3) : (batteryPercent < 15 ? Qt.lighter("#FF5252", 1.2) : (batteryPercent < 40 ? Qt.lighter("#FF9800", 1.2) : (batteryPercent < 70 ? Qt.lighter("#FFCC00", 1.2) : Qt.lighter("#4CAF50", 1.3))))
                            }
                        }

                        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

                        Repeater {
                            model: 12
                            Rectangle {
                                id: particle
                                width: 4 + (index % 3) * 3
                                height: 4 + (index % 3) * 3
                                radius: width / 2
                                color: "white"
                                opacity: isCharging ? 0.6 : 0
                                visible: isCharging
                                y: 4 + (index * 4) % (parent.height - 8)
                                x: ((chargeAnimProgress * (parent.width + 20) * (0.8 + index * 0.15) + (index * 25)) % (parent.width + 20)) - 20

                                SequentialAnimation on opacity {
                                    running: isCharging; loops: Animation.Infinite
                                    NumberAnimation {
                                        from: 0.2
                                        to: 0.8
                                        duration: 600 + index * 100
                                        easing.type: Easing.InOutSine
                                    }
                                    NumberAnimation {
                                        from: 0.8
                                        to: 0.2
                                        duration: 600 + index * 100
                                        easing.type: Easing.InOutSine
                                    }
                                }

                                SequentialAnimation on y {
                                    running: isCharging; loops: Animation.Infinite
                                    NumberAnimation {
                                        to: y + (index % 3 - 1) * 5
                                        duration: 800 + index * 200
                                        easing.type: Easing.InOutSine
                                    }

                                    NumberAnimation {
                                        to: y - (index % 3 - 1) * 5
                                        duration: 800 + index * 200
                                        easing.type: Easing.InOutSine
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: batteryPercent + "%"
                        color: batteryPercent > 50 ? "#333" : theme.colOnSecondary
                        font.pixelSize: config.fontSize * 1
                        font.weight: Font.DemiBold
                        z: 1
                    }
                }
            }

            // ============================================================
            // ROW 2: Time Info (Until Full | Remaining)
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                height: 50
                color: theme.colSecondary
                radius: 10
                opacity: batteryPopup.introInfo
                transform: Translate { y: 10 * (1 - batteryPopup.introInfo) }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"
                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 4
                            Text {
                                text: "Until Full"
                                color: theme.colOnSecondary
                                font.pixelSize: config.fontSize * 0.65
                                font.weight: Font.Medium
                                opacity: 0.6
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "--:--:--"
                                color: theme.colOnSecondary
                                font.pixelSize: config.fontSize * 1.1
                                font.weight: Font.DemiBold
                                font.family: "monospace"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        color: theme.colOnSurfaceVariant
                        opacity: 0.15
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"
                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 4
                            Text {
                                text: "Remaining"
                                color: theme.colOnSecondary
                                font.pixelSize: config.fontSize * 0.65
                                font.weight: Font.Medium
                                opacity: 0.6
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "--:--:--"
                                color: theme.colOnSecondary
                                font.pixelSize: config.fontSize * 1.1
                                font.weight: Font.DemiBold
                                font.family: "monospace"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }

            // ============================================================
            // ROW 3: Uptime + App Usage Tabs
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: theme.colSecondary
                radius: 14
                clip: true
                opacity: batteryPopup.introTabs
                transform: Translate { y: 10 * (1 - batteryPopup.introTabs) }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Tab buttons
                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 3

                            Rectangle {
                                Layout.preferredWidth: 30
                                Layout.fillHeight: true
                                radius: 12
                                color: prevDayMa.containsMouse ? theme.colSurfaceVariant : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "◀"
                                    font.pixelSize: config.fontSize * 1.5
                                    color: theme.colOnSecondary
                                }

                                MouseArea {
                                    id: prevDayMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: navigateDay(-1)
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 7
                                color: activeTab === "uptime" ? theme.colPrimary : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "⏱ Uptime"
                                    color: activeTab === "uptime" ? theme.colOnPrimary : theme.colOnSecondary
                                    font.pixelSize: config.fontSize
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: activeTab = "uptime"
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 7
                                color: activeTab === "apps" ? theme.colPrimary : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "📊 Apps"
                                    color: activeTab === "apps" ? theme.colOnPrimary : theme.colOnSecondary
                                    font.pixelSize: config.fontSize
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: activeTab = "apps"
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 30
                                Layout.fillHeight: true
                                radius: 12
                                color: nextDayMa.containsMouse ? theme.colSurfaceVariant : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "▶"
                                    font.pixelSize: config.fontSize * 1.5
                                    color: theme.colOnSecondary
                                }

                                MouseArea {
                                    id: nextDayMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: navigateDay(1)
                                }
                            }
                        }
                    }

                    // Content
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"

                        // UPTIME TAB
                        Item {
                            anchors.fill: parent
                            visible: activeTab === "uptime"

                            Flickable {
                                id: uptimeFlickable
                                anchors.fill: parent
                                anchors.margins: 8
                                contentWidth: uptimeRow.width + 16
                                clip: true
                                interactive: true
                                flickableDirection: Flickable.HorizontalFlick
                                boundsBehavior: Flickable.StopAtBounds

                                Behavior on contentX {
                                    NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                                }

                                Row {
                                    id: uptimeRow
                                    height: parent.height
                                    spacing: 10

                                    Repeater {
                                        model: uptimeBars

                                        delegate: Item {
                                            width: 44
                                            height: parent.height + 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            property real barHeight: parent.height * modelData.pct * 0.85
                                            property string dateKey: modelData.dateKey     // Store the date key for external scrolling

                                            // Bar
                                            Rectangle {
                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                    bottom: parent.bottom
                                                    bottomMargin: 28
                                                }
                                                height: barHeight
                                                radius: 6
                                                gradient: Gradient {
                                                    GradientStop {
                                                        position: 0.0
                                                        color: (modelData.dateKey === selectedDate) ? "#2196F3" : ( (modelData.isToday) ? '#00a500' : theme.colSurfaceVariant )
                                                    }
                                                    GradientStop {
                                                        position: 1.0
                                                        color: (modelData.dateKey === selectedDate) ? "#2196F3" : ( (modelData.isToday) ? '#00a500' : theme.colSurfaceVariant )
                                                    }
                                                }
                                                Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                            }

                                            // Hours label above bar
                                            Text {
                                                anchors.bottom: parent.bottom
                                                anchors.bottomMargin: 28 + barHeight + 4
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: modelData.hours
                                                color: (modelData.dateKey === selectedDate) ? "#2196F3" : ( (modelData.isToday) ? '#00a500' : theme.colSurfaceVariant )
                                                font.pixelSize: config.fontSize
                                                font.weight: Font.DemiBold
                                                font.family: "monospace"
                                            }

                                            // Date label below bar
                                            Text {
                                                anchors.top: parent.bottom
                                                anchors.topMargin: -24
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: modelData.date
                                                color: (modelData.dateKey === selectedDate) ? "#2196F3" : ( (modelData.isToday) ? '#00a500' : theme.colSurfaceVariant )
                                                font.pixelSize: config.fontSize
                                                font.weight: (modelData.dateKey === selectedDate || (modelData.isToday && selectedDate === "")) ?
                                                            Font.DemiBold : Font.Normal
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData.isToday && selectedDate === modelData.dateKey) {
                                                        selectedDate = ""
                                                    } else {
                                                        selectedDate = modelData.dateKey
                                                    }
                                                    updateAppList()
                                                    scrollToDate(selectedDate)
                                                }
                                            }
                                        }
                                    }
                                }

                                Timer {
                                    id: scrollToToday
                                    interval: 100
                                    running: batteryPopup.visible && uptimeBars.length > 0
                                    repeat: false
                                    onTriggered: uptimeFlickable.contentX = uptimeRow.width - uptimeFlickable.width + 16
                                }
                            }

                            // "Today" reset button (visible only when a past date is selected)
                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 4
                                width: selectedDate !== "" ? 50 : 0
                                height: 20; radius: 10
                                color: "#2196F3"
                                visible: selectedDate !== ""
                                Behavior on width { NumberAnimation { duration: 200 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: "Today"
                                    color: "#fff"
                                    font.pixelSize: config.fontSize * 0.5
                                    font.weight: Font.DemiBold
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        selectedDate = ""
                                        updateAppList()
                                        scrollToDate("")
                                    }
                                }
                            }
                        }

                        // APPS TAB
                        Item {
                            anchors.fill: parent
                            visible: activeTab === "apps"

                            Flickable {
                                anchors.fill: parent
                                anchors.margins: 8
                                contentHeight: appsColumn.height
                                clip: true
                                interactive: appsColumn.height > height
                                boundsBehavior: Flickable.StopAtBounds

                                Column {
                                    id: appsColumn
                                    width: parent.width
                                    spacing: 5

                                    Repeater {
                                        model: appList

                                        delegate: Rectangle {
                                            width: parent.width
                                            height: 52
                                            color: theme.colPrimary
                                            radius: 8

                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: 8
                                                spacing: 4

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 8

                                                    Text {
                                                        text: modelData.icon
                                                        font.pixelSize: config.fontSize * 1.3
                                                        color: theme.colOnPrimary
                                                        Layout.alignment: Qt.AlignVCenter
                                                    }

                                                    Text {
                                                        text: modelData.name
                                                        color: theme.colOnPrimary
                                                        font.pixelSize: config.fontSize
                                                        font.weight: Font.DemiBold
                                                        Layout.fillWidth: true
                                                        elide: Text.ElideRight
                                                    }

                                                    Text {
                                                        text: modelData.pct + "%"
                                                        color: theme.colOnPrimary
                                                        font.pixelSize: config.fontSize
                                                        font.weight: Font.DemiBold
                                                        Layout.alignment: Qt.AlignVCenter
                                                    }

                                                    Text {
                                                        text: "|"
                                                        color: theme.colOnPrimary
                                                        font.pixelSize: config.fontSize * 0.65
                                                        opacity: 0.4
                                                        Layout.alignment: Qt.AlignVCenter
                                                    }

                                                    Text {
                                                        text: modelData.time
                                                        color: theme.colOnPrimary
                                                        font.pixelSize: config.fontSize
                                                        font.weight: Font.Medium
                                                        opacity: 0.7
                                                        Layout.alignment: Qt.AlignVCenter
                                                    }
                                                }

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    height: 8
                                                    radius: 4
                                                    color: theme.colSurfaceVariant
                                                    Rectangle {
                                                        height: parent.height
                                                        width: parent.width * (modelData.pct / 100)
                                                        radius: 4
                                                        color: modelData.color
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}