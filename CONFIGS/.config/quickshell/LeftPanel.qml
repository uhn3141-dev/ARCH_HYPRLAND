// ============================================================
//  LEFT SECTION - WORKSPACE INDICATORS  (Scroll + Bounce + Fade)
// ============================================================

import QtQuick 2.15
import QtQuick.Layouts 2.15
import QtQuick.Controls 2.15
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

RowLayout {
    id: leftPanel
    
    anchors.verticalCenter: parent.verticalCenter
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.margins: 3

    // ----------------------------------------------------------
    //  AppIcons – same absolute path as the battery panel
    // ----------------------------------------------------------
    AppIcons {
        id: appIcons
        iconPath: _HOMEDIR + "/.config/quickshell/app_icons.json"
    }

    property var wsIconsMap: ({})
    property bool iconsLoaded: false

    Timer {
        interval: 500; running: true; repeat: true
        onTriggered: {
            if (appIcons.iconMap && Object.keys(appIcons.iconMap).length > 0) {
                iconsLoaded = true; stop()
            }
        }
    }

    Process {
        id: windowsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!iconsLoaded) return
                let raw = text.trim()
                if (!raw) return
                try {
                    let clients = JSON.parse(raw)
                    let newMap = {}
                    for (let i = 0; i < clients.length; i++) {
                        let c = clients[i]
                        let wsId = c.workspace ? c.workspace.id : -1
                        let cls = c["class"] || c.initialClass || ""
                        if (wsId > 0 && wsId <= 9 && cls) {
                            if (!newMap[wsId]) newMap[wsId] = []
                            let icon = appIcons.getIcon(cls)
                            if (icon && newMap[wsId].indexOf(icon) === -1)
                                newMap[wsId].push(icon)
                        }
                    }
                    for (let ws in newMap) newMap[ws] = newMap[ws].slice(0, 3)
                    wsIconsMap = newMap
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: { if (iconsLoaded) windowsProc.running = true }
    }

    // ----------------------------------------------------------
    //  Parent container with scroll‑wheel switching
    // ----------------------------------------------------------
    Rectangle {
        Layout.fillHeight: true
        Layout.preferredWidth: workspaceLayout.width + 8
        radius: config.elementRadius + 4
        color: theme.colSurfaceContainerLow
        border.color: theme.colSurfaceVariant
        border.width: 1

        // Scroll‑wheel workspace switching
        MouseArea {
            anchors.fill: parent
            onWheel: function(wheel) {
                let current = Hyprland.focusedWorkspace?.id ?? 1
                if (wheel.angleDelta.y > 0) {
                    let next = Math.max(1, current - 1)
                    Hyprland.dispatch("hl.dsp.focus({ workspace = '" + next + "' })")
                } else if (wheel.angleDelta.y < 0) {
                    let next = Math.min(config.numberOfWorkspace, current + 1)
                    Hyprland.dispatch("hl.dsp.focus({ workspace = '" + next + "' })")
                }
            }
        }

        Row {
            id: workspaceLayout
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                id: workspaceRepeater
                model: config.numberOfWorkspace

                Rectangle {
                    id: wsPill
                    width: isActive ? config.workspaceButtonWidth * 2.5 : config.workspaceButtonWidth
                    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    height: config.workspaceButtonHeight
                    radius: config.elementRadius

                    property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                    property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                    property bool isHovered: wsMouse.containsMouse

                    color: isHovered ? theme.colTertiary : 
                           (isActive ? theme.colPrimary : 
                           (ws ? theme.colSecondary : theme.colSurfaceVariant))
                    Behavior on color { ColorAnimation { duration: 200 } }

                    property bool initAnimTrigger: false
                    opacity: initAnimTrigger ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 500 } }

                    // --------------------------------------------------
                    //  Scale system: baseScale (bounce) + hoverScale
                    // --------------------------------------------------
                    property real baseScale: 1.0
                    property real hoverScale: isHovered && !isActive ? 1.05 : 1.0
                    Behavior on hoverScale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    scale: baseScale * hoverScale

                    // Bounce on active change
                    SequentialAnimation {
                        id: activeBounce
                        running: false
                        NumberAnimation { target: wsPill; property: "baseScale"; to: 1.12; duration: 150; easing.type: Easing.OutBack }
                        NumberAnimation { target: wsPill; property: "baseScale"; to: 1.0; duration: 200; easing.type: Easing.OutBack }
                    }
                    onIsActiveChanged: {
                        if (isActive) activeBounce.restart()
                    }

                    transform: Translate {
                        y: wsPill.initAnimTrigger ? 0 : 15
                        Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                    }

                    Component.onCompleted: {
                        if (!root.isStartupReady) {
                            animTimer.interval = index * config.staggerDelay
                            animTimer.start()
                        } else {
                            initAnimTrigger = true
                        }
                    }
                    Timer {
                        id: animTimer
                        running: false; repeat: false
                        onTriggered: wsPill.initAnimTrigger = true
                    }

                    // Content: Number + fading icons
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        

                        Text {
                            text: " " + (index + 1)
                            font.pixelSize: config.fontSize
                            font.family: config.fontFamily
                            font.bold: true
                            color: isActive ? theme.colOnPrimary : (isHovered ? theme.colTertiaryContainer : (ws ? theme.colOnSecondary : theme.colOnSurfaceVariant))
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        // Icons with smooth fade
                        Text {
                            property string currentText: {
                                let icons = wsIconsMap[index + 1]
                                return icons ? icons.join(" ") : ""
                            }
                            text: currentText
                            visible: isActive
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: config.fontSize * 1.4
                            color: theme.colOnPrimary
                            opacity: (isActive && currentText.length > 0) ? 0.9 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            Hyprland.dispatch("hl.dsp.focus({ workspace = '" + (index + 1) + "' })")
                        }
                    }
                }
            }
        }
    }
}