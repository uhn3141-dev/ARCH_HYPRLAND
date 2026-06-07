// ============================================================
//  RIGHT SECTION - SYSTEM MONITOR, NOTIFICATIONS
// ============================================================


import QtQuick 2.15
import QtQuick.Layouts 2.15
import QtQuick.Controls 2.15
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import "./popups/SystemMonitor" as SystemMonitor
import "./popups/NotificationCenter" as NotificationCenter
import "./popups/Music" as Music

RowLayout {
    id: rightPanel
    anchors.verticalCenter: parent.verticalCenter
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: 3

    SystemMonitor.SystemMonitorPanel { 
        id: systemMonitorPopup
        Component.onCompleted: popupManager.registerPopup("systemMonitor", systemMonitorPopup)
    }

    NotificationCenter.NotificationCenterPanel { 
        id: notificationCenterPopup
        notifModel: myNotifModel
        Component.onCompleted: popupManager.registerPopup("notificationCenter", notificationCenterPopup)
    }

    ListModel { id: myNotifModel }

    Process {
        id: dunstHistoryFetcher
        command: ["bash", "-c", "dunstctl history 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = text.trim()
                if (!raw) return
                try {
                    let outer = JSON.parse(raw)
                    if (outer.type !== "aa{sv}") return
                    let entries = outer.data[0] || []
                    
                    myNotifModel.clear()
                    for (let i = 0; i < entries.length; i++) {
                        let e = entries[i]
                        
                        // Correctly extract Dunst's DBus-encoded fields
                        let getField = function(field) {
                            if (e[field] && e[field].data !== undefined) return String(e[field].data)
                            return ""
                        }
                        
                        let uid      = getField('id')       || String(i)
                        let appname  = getField('appname')   || "Dunst"
                        let summary  = getField('summary')   || ""
                        let body     = getField('body')      || ""
                        let message  = getField('message')   || summary  // fallback
                        
                        myNotifModel.append({
                            appName: appname,
                            summary: message,
                            body:    body,
                            uid:     uid
                        })
                    }
                } catch(e) {
                    console.log("[Dunst] Parse error:", e)
                }
            }
        }
    }

    // Refresh every 2 seconds
    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: dunstHistoryFetcher.running = true
    }

    Music.MusicPanel { 
        id: musicPopup
        Component.onCompleted: popupManager.registerPopup("music", musicPopup)
    }

    Row {
        id: rightPanelContent
        spacing: 3

        Rectangle {
            id: musicWidget
            width: config.musicButtonWidth
            height: config.musicButtonHeight

            property bool isHovered: musicMouse.containsMouse

            color: isHovered ? theme.colTertiary : theme.colPrimary
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 500 } }

            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            
            Text {
                anchors.centerIn: parent
                text: "||"
                color: theme.colOnPrimary
                font { pixelSize: config.fontSize; bold: true }
            }

            MouseArea {
                id: musicMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "music"])
            }
            
            // Hover animation
            scale: isHovered ? 1.06 : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            
            // Staggered startup animation
            property bool initAnimTriggerMusic: false
            opacity: initAnimTriggerMusic ? 1 : 0
            transform: Translate {
                y: musicWidget.initAnimTriggerMusic ? 0 : 15
                Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
            }
            
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerMusic.interval = 3 * config.staggerDelay
                    animTimerMusic.start()
                } else {
                    initAnimTriggerMusic = true
                }
            }

            Timer {
                id: animTimerMusic
                running: false
                repeat: false
                onTriggered: musicWidget.initAnimTriggerMusic = true
            }
        }

        Rectangle {
            id: notificationCenterWidget
            width: config.notificationCenterButtonWidth
            height: config.notificationCenterButtonHeight

            property bool isHovered: notificationCenterMouse.containsMouse

            color: isHovered ? theme.colTertiary : theme.colPrimary
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 500 } }

            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            
            Text {
                anchors.centerIn: parent
                text: "||"
                color: theme.colOnPrimary
                font { pixelSize: config.fontSize; bold: true }
            }

            MouseArea {
                id: notificationCenterMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "notificationCenter"])
            }
            
            // Hover animation
            scale: isHovered ? 1.06 : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            
            // Staggered startup animation
            property bool initAnimTriggerNotificationCenter: false
            opacity: initAnimTriggerNotificationCenter ? 1 : 0
            transform: Translate {
                y: notificationCenterWidget.initAnimTriggerNotificationCenter ? 0 : 15
                Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
            }
            
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerNotificationCenter.interval = 3 * config.staggerDelay
                    animTimerNotificationCenter.start()
                } else {
                    initAnimTriggerNotificationCenter = true
                }
            }

            Timer {
                id: animTimerNotificationCenter
                running: false
                repeat: false
                onTriggered: notificationCenterWidget.initAnimTriggerNotificationCenter = true
            }
        }

        Rectangle {
            id: systemMonitorWidget
            width: config.systemMonitorButtonWidth
            height: config.systemMonitorButtonHeight

            property bool isHovered: systemMonitorMouse.containsMouse

            color: isHovered ? theme.colTertiary : theme.colPrimary
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 500 } }

            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            
            Text {
                anchors.centerIn: parent
                text: "||"
                color: theme.colOnPrimary
                font { pixelSize: config.fontSize; bold: true }
            }

            MouseArea {
                id: systemMonitorMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "systemMonitor"])
            }
            
            // Hover animation
            scale: isHovered ? 1.06 : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            
            // Staggered startup animation
            property bool initAnimTriggerSystemMonitor: false
            opacity: initAnimTriggerSystemMonitor ? 1 : 0
            transform: Translate {
                y: systemMonitorWidget.initAnimTriggerSystemMonitor ? 0 : 15
                Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
            }
            
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerSystemMonitor.interval = 3 * config.staggerDelay
                    animTimerSystemMonitor.start()
                } else {
                    initAnimTriggerSystemMonitor = true
                }
            }

            Timer {
                id: animTimerSystemMonitor
                running: false
                repeat: false
                onTriggered: systemMonitorWidget.initAnimTriggerSystemMonitor = true
            }
        }
    }
}