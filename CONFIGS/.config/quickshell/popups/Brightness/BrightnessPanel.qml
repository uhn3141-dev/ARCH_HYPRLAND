import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

PopupWindow {
    id: brightnessPopup

    anchor.window: root
    anchor.rect.x: root.width / 2 - width / 2
    anchor.rect.y: 31

    implicitWidth: 300
    implicitHeight: 60

    color: 'transparent'
    visible: false

    onVisibleChanged: {
        if (visible) {
            introMain = 0
            entryAnim.restart()
            getBrightness()
        }
    }

    property int currentBrightness: 100
    property bool autoBrightness: false
    property real introMain: 0

    ParallelAnimation {
        id: entryAnim
        NumberAnimation {
            target: brightnessPopup
            property: "introMain"
            from: 0; to: 1
            duration: 350
            easing.type: Easing.OutBack
        }
    }

    function getBrightness() {
        let cmd = "import Quickshell.Io; Process { command: [\"bash\", \"-c\", \"brightnessctl -m | awk -F, '{print substr($4, 1, length($4)-1)}'\"]; stdout: StdioCollector { onStreamFinished: { var val = parseInt(text.trim()); if (!isNaN(val)) currentBrightness = val; } } }"
        let process = Qt.createQmlObject(cmd, brightnessPopup)
        process.running = true
    }

    function setBrightness(val) {
        currentBrightness = Math.max(1, Math.min(100, val))
        Quickshell.execDetached(["bash", "-c", "brightnessctl set " + currentBrightness + "%"])
    }

    function toggleAutoBrightness() {
        autoBrightness = !autoBrightness
        if (autoBrightness) {
            Quickshell.execDetached(["bash", "-c", "clight &"])
        } else {
            Quickshell.execDetached(["bash", "-c", "pkill clight"])
            getBrightness()
        }
    }

    Rectangle {
        id: brightnessPanel
        anchors.fill: parent
        color: theme.colSurface
        radius: 14
        border.width: 3
        border.color: theme.colSurface

        opacity: brightnessPopup.visible ? 1 : 0
        scale: brightnessPopup.visible ? 1 : 0.9
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            opacity: brightnessPopup.introMain
            transform: Translate { y: 10 * (1 - brightnessPopup.introMain) }

            // Slider with brightness-based gradient
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 18
                color: theme.colSecondary
                opacity: autoBrightness ? 0.4 : 1.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                // Gradient fill - color changes based on brightness level
                Rectangle {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                        margins: 3
                    }
                    width: Math.max(22, (parent.width - 6) * (currentBrightness / 100))
                    radius: 16
                    
                    // Color shifts from cool/dim to warm/bright based on brightness
                    color: {
                        var pct = currentBrightness / 100
                        if (pct < 0.15) return "#8B0000"      // Red (0-15%)
                        if (pct < 0.30) return "#FF6600"      // Orange (15-30%)
                        if (pct < 0.45) return "#FFCC00"      // Yellow (30-45%)
                        if (pct < 0.60) return "#33CC33"      // Green (45-60%)
                        if (pct < 0.75) return "#33CCFF"      // Sky Blue (60-75%)
                        if (pct < 0.90) return "#3366FF"      // Blue (75-90%)
                        return "#9933FF"                       // Purple (90-100%)
                    }
                    
                    Behavior on width { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: currentBrightness + "%"
                    color: currentBrightness > 50 ? "#333" : theme.colOnSecondary
                    font.pixelSize: config.fontSize * 1
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: autoBrightness ? Qt.ArrowCursor : Qt.PointingHandCursor
                    enabled: !autoBrightness
                    onPressed: (mouse) => setBrightness(Math.round((mouse.x / width) * 100))
                    onPositionChanged: (mouse) => {
                        if (pressed && !autoBrightness) setBrightness(Math.round((mouse.x / width) * 100))
                    }
                }
            }

            // Right button - shows % or auto icon
            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 36
                radius: 12
                color: autoBrightness ? "#2196F3" : theme.colSecondary

                property bool isHovered: rightBtnHover.containsMouse

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                scale: isHovered ? 1.1 : 1.0

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (autoBrightness) return "🔆"
                        if (currentBrightness >= 70) return "󰃠"
                        if (currentBrightness >= 30) return "󰃟"
                        if (currentBrightness >= 10) return "󰃝"
                        return "󰃞"
                    }
                    font.pixelSize: config.fontSize * 2.4
                    color: {
                        if (autoBrightness) return "#fff"
                        if (currentBrightness >= 70) return "#FFEB3B"
                        if (currentBrightness >= 30) return theme.colOnSecondary
                        return "#FF9800"
                    }
                    rotation: autoBrightness ? 360 : 0
                    Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                }

                MouseArea {
                    id: rightBtnHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toggleAutoBrightness()
                }
            }
        }
    }
}