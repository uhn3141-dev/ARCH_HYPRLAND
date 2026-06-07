import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

PopupWindow {
    id: powerPopup

    anchor.window: root
    anchor.rect.x: root.width / 2 - width / 2
    anchor.rect.y: 31

    implicitWidth: 250
    implicitHeight: 300

    color: 'transparent'
    visible: false

    onVisibleChanged: {
        if (visible) {
            // Reset and restart entry animation
            introRow1 = 0; introRow2 = 0; introRow3 = 0
            entryAnim.restart()
        }
    }

    // === State Properties ===
    property string powerMode: "balanced"
    property bool dndMode: false
    property bool screenSaver: false
    property bool screenOff: false
    property string hyprLayout: "master"
    property bool airplaneMode: false
    property bool autoBrightness: false
    property bool nightLight: false
    property bool wallpaperChanged: false

    // === Power Mode ===
    function setPowerMode(mode) {
        console.log("[Power] Mode:", mode)
        powerMode = mode
        modePulse.restart()
        
        // Save to cache
        Quickshell.execDetached(["bash", "-c", "mkdir -p ~/.cache && echo '" + mode + "' > ~/.cache/qs_power_mode"])
        
        // Apply the profile
        if (mode === "performance") {
            Quickshell.execDetached(["bash", "-c", "powerprofilesctl set performance 2>/dev/null || powerprofilesctl set balanced"])
        } else if (mode === "balanced") {
            Quickshell.execDetached(["bash", "-c", "powerprofilesctl set balanced"])
        } else {
            Quickshell.execDetached(["bash", "-c", "powerprofilesctl set power-saver"])
        }
    }
    
    // Timer to load saved power mode on startup
    Timer {
        interval: 60000
        running: true
        repeat: false
        onTriggered: {
            let cmd = "import Quickshell.Io; Process { command: [\"bash\", \"-c\", \"cat ~/.cache/qs_power_mode 2>/dev/null || echo 'balanced'\"]; stdout: StdioCollector { onStreamFinished: { var mode = text.trim(); if (mode === 'performance' || mode === 'balanced' || mode === 'power-saver') { powerMode = mode; } } } }"
            let process = Qt.createQmlObject(cmd, powerPopup)
            process.running = true
        }
    }

    // === Tool Toggles ===
    function toggleDND() {
        dndMode = !dndMode
        console.log("[Power] DND:", dndMode)
        Quickshell.execDetached(["bash", "-c", "dunstctl set-paused " + (dndMode ? "true" : "false")])
    }

    function toggleAirplaneMode() {
        airplaneMode = !airplaneMode
        console.log("[Power] Airplane:", airplaneMode)
        if (airplaneMode) {
            Quickshell.execDetached(["bash", "-c", "rfkill block all"])
        } else {
            Quickshell.execDetached(["bash", "-c", "rfkill unblock all"])
        }
    }

    function toggleScreenSaver() {
        screenSaver = !screenSaver
        console.log("[Power] ScreenSaver:", screenSaver)
        if (screenSaver) {
            Quickshell.execDetached(["bash", "-c", "hypridle &"])
        } else {
            Quickshell.execDetached(["bash", "-c", "pkill hypridle"])
        }
    }

    function toggleAutoBrightness() {
        autoBrightness = !autoBrightness
        console.log("[Power] AutoBrightness:", autoBrightness)
        if (autoBrightness) {
            Quickshell.execDetached(["bash", "-c", "clight &"])
        } else {
            Quickshell.execDetached(["bash", "-c", "pkill clight"])
        }
    }

    function toggleScreenOff() {
        screenOff = !screenOff
        console.log("[Power] ScreenOff:", screenOff)
        Quickshell.execDetached(["bash", "-c", "hyprctl dispatch dpms off"])
        screenOff = false
    }

    function toggleNightLight() {
        nightLight = !nightLight
        console.log("[Power] NightLight:", nightLight)
        if (nightLight) {
            Quickshell.execDetached(["bash", "-c", "sleep 0.2 && hyprctl hyprsunset temperature 3500"])
        } else {
            Quickshell.execDetached(["bash", "-c", "sleep 0.2 && hyprctl hyprsunset identity"])
        }
    }

    function toggleLayout() {
        if (hyprLayout === "dwindle") {
            hyprLayout = "master"
            Quickshell.execDetached(["bash", "-c", "hyprctl eval \"hl.config({ general = { layout = 'master' } })\""])
        } else if (hyprLayout === "master") {
            hyprLayout = "scrolling"
            Quickshell.execDetached(["bash", "-c", "hyprctl eval \"hl.config({ general = { layout = 'scrolling' } })\""])
        } else {
            hyprLayout = "dwindle"
            Quickshell.execDetached(["bash", "-c", "hyprctl eval \"hl.config({ general = { layout = 'dwindle' } })\""])
        }
        console.log("[Power] Layout:", hyprLayout)
    }

    function toggleWallpaper() {
        wallpaperChanged = !wallpaperChanged
        Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/walset.sh --auto-theme"])
    }

    // === Action Functions ===
    function reload() {
        Quickshell.execDetached(["bash", "-c", "hyprctl reload"])
        Quickshell.execDetached(["bash", "-c", "systemctl daemon-reload"])
        Quickshell.reload("~/.config/quickshell/shell.qml")
    }

    function lock() {
        Quickshell.execDetached(["bash", "-c", "~/.local/share/quickshell-lockscreen/lock.sh"]) // QYLOCK
    }

    function logout() {
        Quickshell.execDetached(["bash", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"])
    }

    function hibernate() {
        Quickshell.execDetached(["bash", "-c", "systemctl hibernate"])
    }

    function reboot() {
        Quickshell.execDetached(["bash", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || systemctl reboot"])
    }

    function shutdown() {
        Quickshell.execDetached(["bash", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || systemctl poweroff"])
    }

    // === Staggered Entry Animations ===
    property real introRow1: 0  // Uptime + Power Mode
    property real introRow2: 0  // Tools
    property real introRow3: 0  // Action Buttons

    ParallelAnimation {
        running: powerPopup.visible
        id: entryAnim
        
        // Row 1: Immediate
        NumberAnimation {
            target: powerPopup
            property: "introRow1"
            from: 0
            to: 1.0
            duration: 500
            easing.type: Easing.OutBack
        }
        
        // Row 2: 100ms delay
        SequentialAnimation {
            PauseAnimation { duration: 200 }
            NumberAnimation {
                target: powerPopup
                property: "introRow2"
                from: 0
                to: 1.0
                duration: 700
                easing.type: Easing.OutBack
            }
        }
        
        // Row 3: 200ms delay
        SequentialAnimation {
            PauseAnimation { duration: 300 }
            NumberAnimation {
                target: powerPopup
                property: "introRow3"
                from: 0
                to: 1.0
                duration: 800
                easing.type: Easing.OutBack
            }
        }
    }

    Rectangle {
        id: powerPanel
        anchors.fill: parent
        color: theme.colSurface
        radius: 20
        border.width: 3
        border.color: theme.colSurface

        // Opening animation
        opacity: powerPopup.visible ? 1 : 0
        scale: powerPopup.visible ? 1 : 0.2
        
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ============================================================
            // ROW 1: Uptime (1/3) + Power Mode (2/3)
            // ============================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                opacity: powerPopup.introRow1
                transform: Translate { y: 15 * (1 - powerPopup.introRow1) }

                // Uptime
                Rectangle {
                    Layout.preferredWidth: ((parent.width - 8) / 5 ) * 2
                    height: 36
                    radius: 10
                    color: theme.colSecondary
                    Layout.alignment: Qt.AlignVCenter

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "UPTIME"
                            color: theme.colOnSecondary
                            font.pixelSize: config.fontSize * 0.8
                            font.weight: Font.Bold
                            opacity: 0.6
                        }

                        Text {
                            id: uptimeText
                            anchors.horizontalCenter: parent.horizontalCenter
                            property var uptime: new Date(0, 0, 0, 0, 0, 0)
                            text: uptime.toLocaleTimeString(Qt.locale(), "hh:mm:ss")
                            color: theme.colOnSecondary
                            font.family: config.fontFamilyClock
                            font.pixelSize: config.fontSize * 1.1
                            font.bold: true

                            Timer {
                                interval: 1000
                                running: powerPopup.visible
                                repeat: true
                                onTriggered: {
                                    let cmd = "import Quickshell.Io; Process { command: [\"bash\", \"-c\", \"cat /proc/uptime | awk '{print int($1)}'\"]; stdout: StdioCollector { onStreamFinished: { uptimeText.uptime = new Date(0, 0, 0, 0, 0, parseInt(text.trim())); } } }"
                                    let process = Qt.createQmlObject(cmd, powerPopup)
                                    process.running = true
                                }
                            }
                        }
                    }
                }

                // Power Mode Pill with sliding background animation
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 15
                    color: theme.colSurfaceVariant
                    Layout.alignment: Qt.AlignVCenter

                    // Animated background indicator
                    Rectangle {
                        id: modeIndicator
                        height: parent.height
                        width: parent.width / 3
                        radius: 15
                        color: {
                            if (powerMode === "performance") return "#FF9800"
                            if (powerMode === "balanced") return "#4CAF50"
                            return "#2196F3"
                        }

                        // Slide to position
                        x: {
                            if (powerMode === "performance") return 0
                            if (powerMode === "balanced") return parent.width / 3
                            return (parent.width / 3) * 2
                        }

                        Behavior on x {
                            NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
                        }
                        Behavior on color {
                            ColorAnimation { duration: 300 }
                        }

                        // Pulse on change
                        scale: 1.0
                        
                        SequentialAnimation on scale {
                            id: modePulse
                            running: false
                            NumberAnimation { to: 1.15; duration: 150; easing.type: Easing.OutBack }
                            NumberAnimation { to: 1.0; duration: 200; easing.type: Easing.OutQuad }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Performance
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 15
                            color: "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "⚡"
                                font.pixelSize: config.fontSize * 1.1
                                color: powerMode === "performance" ? "#fff" : theme.colOnSurfaceVariant

                                Behavior on color {
                                    ColorAnimation { duration: 250 }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: setPowerMode("performance")
                            }
                        }

                        // Balanced
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "⚖"
                                font.pixelSize: config.fontSize * 1.1
                                color: powerMode === "balanced" ? "#fff" : theme.colOnSurfaceVariant

                                Behavior on color {
                                    ColorAnimation { duration: 250 }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: setPowerMode("balanced")
                            }
                        }

                        // Power Saver
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 15
                            color: "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "🌿"
                                font.pixelSize: config.fontSize * 1.1
                                color: powerMode === "powersaver" ? "#fff" : theme.colOnSurfaceVariant

                                Behavior on color {
                                    ColorAnimation { duration: 250 }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: setPowerMode("powersaver")
                            }
                        }
                    }
                }
            }

            // ============================================================
            // ROW 2: Tools (8 buttons - 2 rows x 4 cols)
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                height: 90
                color: theme.colSecondary
                radius: 14

                opacity: powerPopup.introRow2
                transform: Translate { y: 15 * (1 - powerPopup.introRow2) }

                // Border glow on hover
                border.width: toolsHover.containsMouse ? 3 : 0
                border.color: toolsHover.containsMouse ? theme.colError : "transparent"
                Behavior on border.color { ColorAnimation { duration: 300 } }
                Behavior on border.width { NumberAnimation { duration: 200 } }

                MouseArea {
                    id: toolsHover
                    anchors.fill: parent
                    hoverEnabled: true
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6

                    // Row 1: DND | Screen Saver | Screen Off | Layout
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // 1. DND
                        ToolButton {
                            icon: "🔇"
                            activeColor: "#E91E63"
                            active: dndMode
                            label: "DND"
                            animType: "spin"
                            onToggle: toggleDND
                        }

                        // 2. Screen Saver
                        ToolButton {
                            icon: "🖵"
                            activeColor: "#9C27B0"
                            active: screenSaver
                            label: "Screen Saver"
                            animType: "spin"
                            onToggle: toggleScreenSaver
                        }

                        // 3. Screen Off
                        ToolButton {
                            icon: "🖥"
                            activeColor: "#607D8B"
                            active: screenOff
                            label: "Screen Off"
                            animType: "spin"
                            onToggle: toggleScreenOff
                        }
                        
                        // 4. Layout
                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: 16

                            property bool isHovered: layHover.containsMouse
                            property color layoutColor: hyprLayout === "dwindle" ? "#4CAF50" : (hyprLayout === "master" ? "#2196F3" : "#FF9800")

                            color: layoutColor
                            border.width: isHovered ? 2 : 0
                            border.color: Qt.lighter(layoutColor, 1.5)

                            Behavior on color { ColorAnimation { duration: 300 } }
                            Behavior on border.color { ColorAnimation { duration: 200 } }
                            Behavior on border.width { NumberAnimation { duration: 200 } }
                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                            scale: isHovered ? 1.15 : 1.0

                            Text {
                                anchors.centerIn: parent
                                text: "📏"
                                font.pixelSize: config.fontSize * 1.3
                                color: "#fff"
                                rotation: hyprLayout === "dwindle" ? 0 : (hyprLayout === "master" ? 120 : 240)
                                Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                            }

                            // Layout label
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: hyprLayout === "dwindle" ? "D" : (hyprLayout === "master" ? "M" : "S")
                                font.pixelSize: config.fontSize * 0.65
                                color: "#fff"
                                font.weight: Font.Black
                                opacity: 0.8
                            }

                            MouseArea {
                                id: layHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: toggleLayout()
                            }
                        }
                    }

                    // Row 2: Airplane | Auto Brightness | Night Light | Wallpaper
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // 5. Airplane Mode
                        ToolButton {
                            icon: "✈"
                            activeColor: "#FF9800"
                            active: airplaneMode
                            label: "Airplane"
                            animType: "spin"
                            onToggle: toggleAirplaneMode
                        }

                        // 6. Auto Brightness
                        ToolButton {
                            icon: "🔆"
                            activeColor: "#FFEB3B"
                            active: autoBrightness
                            label: "Brightness"
                            animType: "scale"
                            onToggle: toggleAutoBrightness
                        }

                        // 7. Night Light
                        ToolButton {
                            icon: "🌙"
                            activeColor: "#FF5722"
                            active: nightLight
                            label: "Night Light"
                            animType: "spin"
                            onToggle: toggleNightLight
                        }

                        // 8. Wallpaper
                                                // 8. Wallpaper
                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: 16

                            property bool isHovered: wallpaperHover.containsMouse
                            property real clickRotation: 0

                            color: "#009688"

                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                            scale: isHovered ? 1.1 : 1.0

                            Text {
                                anchors.centerIn: parent
                                text: "🖼️"
                                font.pixelSize: config.fontSize * 1.2
                                color: "#fff"
                                rotation: parent.clickRotation
                                Behavior on rotation {
                                    NumberAnimation { duration: 600; easing.type: Easing.OutBack }
                                }
                            }

                            MouseArea {
                                id: wallpaperHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    parent.clickRotation += 360
                                    toggleWallpaper()
                                }
                            }
                        }
                    }
                }
            }

            // ============================================================
            // ROW 3: 6 Action Buttons
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: theme.colSecondary
                radius: 14

                opacity: powerPopup.introRow3
                transform: Translate { y: 25 * (1 - powerPopup.introRow3) }

                // Border glow on hover
                border.width: actionsHover.containsMouse ? 3 : 0
                border.color: actionsHover.containsMouse ? theme.colError : "transparent"
                Behavior on border.color { ColorAnimation { duration: 300 } }
                Behavior on border.width { NumberAnimation { duration: 200 } }

                MouseArea {
                    id: actionsHover
                    anchors.fill: parent
                    hoverEnabled: true
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    // Row 1
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Reload
                        AnimatedPowerButtons {
                            icon: "↻"
                            baseColor: "#2196F3"
                            weight: 2.0
                            onActivated: reload
                        }

                        // Lock
                        AnimatedPowerButtons {
                            icon: "🔒"
                            baseColor: "#4CAF50"
                            weight: 1.5
                            onActivated: lock
                        }

                        // Logout
                        AnimatedPowerButtons {
                            icon: "↩"
                            baseColor: "#FF9800"
                            weight: 3.0
                            onActivated: logout
                        }
                    }

                    // Row 2
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Hibernate
                        AnimatedPowerButtons {
                            icon: "🌙"
                            baseColor: "#9C27B0"
                            weight: 3.0
                            onActivated: hibernate
                        }

                        // Reboot
                        AnimatedPowerButtons {
                            icon: "↺"
                            baseColor: "#FF5722"
                            weight: 4.0
                            onActivated: reboot
                        }

                        // Shutdown
                        AnimatedPowerButtons {
                            icon: "⏻"
                            baseColor: "#F44336"
                            weight: 5.0
                            onActivated: shutdown
                        }
                    }
                }
            }
        }
    }

    // ============================================================
    // COMPONENT: AnimatedPowerButtons (Fluid wave fill - from example pattern)
    // ============================================================
    component AnimatedPowerButtons: Rectangle {
        property string icon: ""
        property color baseColor: "#2196F3"
        property real weight: 1.0  // Hold time multiplier
        property var onActivated: function() {}

        id: btn
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 25
        clip: true

        color: theme.colPrimaryContainer
        border.color: actionMa.containsMouse ? fillRect.color : theme.colSurfaceVariant
        border.width: actionMa.containsMouse ? 2 : 1
        
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        property real fillLevel: 0.0
        property bool triggered: false

        // Fluid wave fill canvas (from example)
        Canvas {
            id: waveCanvas
            anchors.fill: parent
            
            property real wavePhase: 0.0
            NumberAnimation on wavePhase {
                running: btn.fillLevel > 0.0 && btn.fillLevel < 1.0
                loops: Animation.Infinite
                from: 0; to: Math.PI * 2; duration: 800
            }
            onWavePhaseChanged: requestPaint()
            Connections { target: btn; function onFillLevelChanged() { waveCanvas.requestPaint() } }
            
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                if (btn.fillLevel <= 0.001) return
                
                var r = 25
                var fillY = height * (1.0 - btn.fillLevel)
                ctx.save()
                ctx.beginPath()
                ctx.moveTo(r, 0); ctx.lineTo(width - r, 0)
                ctx.arcTo(width, 0, width, r, r)
                ctx.lineTo(width, height - r)
                ctx.arcTo(width, height, width - r, height, r)
                ctx.lineTo(r, height)
                ctx.arcTo(0, height, 0, height - r, r)
                ctx.lineTo(0, r); ctx.arcTo(0, 0, r, 0, r)
                ctx.closePath()
                ctx.clip()
                
                ctx.beginPath()
                ctx.moveTo(0, fillY)
                if (btn.fillLevel < 0.99) {
                    var waveAmp = 8 * Math.sin(btn.fillLevel * Math.PI)
                    var cp1y = fillY + Math.sin(wavePhase) * waveAmp
                    var cp2y = fillY + Math.cos(wavePhase + Math.PI) * waveAmp
                    ctx.bezierCurveTo(width * 0.33, cp2y, width * 0.66, cp1y, width, fillY)
                    ctx.lineTo(width, height); ctx.lineTo(0, height)
                } else {
                    ctx.lineTo(width, 0); ctx.lineTo(width, height); ctx.lineTo(0, height)
                }
                ctx.closePath()
                
                var grad = ctx.createLinearGradient(0, 0, 0, height)
                grad.addColorStop(0, fillRect.color.toString())
                grad.addColorStop(1, Qt.lighter(fillRect.color, 1.2).toString())
                ctx.fillStyle = grad
                ctx.fill()
                ctx.restore()
            }
        }

        // Color reference for fill
        Rectangle {
            id: fillRect
            visible: false
            color: baseColor
        }

        // Icon (top layer)
        Text {
            anchors.centerIn: parent
            text: btn.icon
            font.pixelSize: config.fontSize * 2.0
            color: btn.fillLevel > 0.5 ? "white" : theme.colOnPrimaryContainer
            z: 1
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // Fill animation
        NumberAnimation {
            id: fillAnim
            target: btn; property: "fillLevel"
            to: 1.0
            duration: 550 * btn.weight
            easing.type: Easing.InSine
            onFinished: { btn.triggered = true; btn.onActivated() }
        }

        // Drain animation (on release)
        NumberAnimation {
            id: drainAnim
            target: btn; property: "fillLevel"
            to: 0.0
            duration: 800 * btn.fillLevel
            easing.type: Easing.OutQuad
        }

        MouseArea {
            id: actionMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: btn.triggered ? Qt.ArrowCursor : Qt.PointingHandCursor
            onPressed: { if (!btn.triggered) { drainAnim.stop(); fillAnim.start() } }
            onReleased: { if (!btn.triggered && btn.fillLevel < 1.0) { fillAnim.stop(); drainAnim.start() } }
        }
    }
    
    // ============================================================
    // COMPONENT: ToolButton
    // ============================================================
    component ToolButton: Rectangle {
        property string icon: ""
        property color activeColor: "#2196F3"
        property bool active: false
        property string label: ""
        property var onToggle: function() {}
        property string animType: "none"  // "spin", "scale", "layout", "none"

        Layout.fillWidth: true
        height: 32
        radius: 16

        property bool isHovered: toolHover.containsMouse

        color: active ? activeColor : theme.colSurfaceVariant

        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        scale: isHovered ? 1.1 : 1.0

        // // Tooltip -- ain't working
        // Rectangle {
        //     anchors.top: parent.bottom
        //     anchors.topMargin: 4
        //     anchors.horizontalCenter: parent.horizontalCenter
        //     width: tipText.implicitWidth + 12
        //     height: 18
        //     radius: 6
        //     color: theme.colSurface
        //     opacity: isHovered && !active ? 0.9 : 0
        //     Behavior on opacity { NumberAnimation { duration: 150 } }
        //     z: 100
            
        //     Text {
        //         id: tipText
        //         anchors.centerIn: parent
        //         text: label
        //         font.pixelSize: config.fontSize * 0.7
        //         color: theme.colOnSurface
        //         font.weight: Font.Medium
        //     }
        // }

        Text {
            id: iconText
            anchors.centerIn: parent
            text: icon
            font.pixelSize: config.fontSize * 1.2
            color: active ? "#fff" : theme.colOnSurfaceVariant

            // Rotation for spin and layout
            rotation: {
                if (animType === "spin" && active) return 360
                if (animType === "layout") {
                    if (activeColor === "#2196F3") return 0
                    if (activeColor === "#4CAF50") return 120
                    return 240
                }
                return 0
            }
            Behavior on rotation {
                NumberAnimation { duration: 500; easing.type: Easing.OutBack }
            }

            // Scale for scale animation
            scale: (animType === "scale" && active) ? 1.3 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 400; easing.type: Easing.OutBack }
            }
        }

        MouseArea {
            id: toolHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: onToggle()
        }
    }
}