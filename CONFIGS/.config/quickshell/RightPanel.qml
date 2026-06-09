// ============================================================
//  RIGHT SECTION - SYSTEM MONITOR, NOTIFICATIONS
// ============================================================

import "./popups/Music" as Music
import "./popups/NotificationCenter" as NotificationCenter
import "./popups/SystemMonitor" as SystemMonitor
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

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

    ListModel {
        id: myNotifModel
    }

    Process {
        id: dunstHistoryFetcher

        command: ["bash", "-c", "dunstctl history 2>/dev/null"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let raw = text.trim();
                if (!raw)
                    return ;

                try {
                    let outer = JSON.parse(raw);
                    if (outer.type !== "aa{sv}")
                        return ;

                    let entries = outer.data[0] || [];
                    myNotifModel.clear();
                    for (let i = 0; i < entries.length; i++) {
                        let e = entries[i];
                        // Correctly extract Dunst's DBus-encoded fields
                        let getField = function getField(field) {
                            if (e[field] && e[field].data !== undefined)
                                return String(e[field].data);

                            return "";
                        };
                        let uid = getField('id') || String(i);
                        let appname = getField('appname') || "Dunst";
                        let summary = getField('summary') || "";
                        let body = getField('body') || "";
                        let message = getField('message') || summary; // fallback
                        myNotifModel.append({
                            "appName": appname,
                            "summary": message,
                            "body": body,
                            "uid": uid
                        });
                    }
                } catch (e) {
                    console.log("[Dunst] Parse error:", e);
                }
            }
        }

    }

    // Refresh every 2 seconds
    Timer {
        interval: 2000
        running: true
        repeat: true
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

            property bool isHovered: musicMouse.containsMouse
            // Staggered startup animation
            property bool initAnimTriggerMusic: false

            width: config.musicButtonWidth
            height: config.musicButtonHeight
            color: isHovered ? theme.colTertiary : theme.colPrimary
            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            // Hover animation
            scale: isHovered ? 1.06 : 1
            opacity: initAnimTriggerMusic ? 1 : 0
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerMusic.interval = 3 * config.staggerDelay;
                    animTimerMusic.start();
                } else {
                    initAnimTriggerMusic = true;
                }
            }

            Text {
                anchors.centerIn: parent
                text: "||"
                color: theme.colOnPrimary

                font {
                    pixelSize: config.fontSize
                    bold: true
                }

            }

            MouseArea {
                id: musicMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "music"])
            }

            Timer {
                id: animTimerMusic

                running: false
                repeat: false
                onTriggered: musicWidget.initAnimTriggerMusic = true
            }

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 500
                }

            }

            Behavior on scale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                }

            }

            transform: Translate {
                y: musicWidget.initAnimTriggerMusic ? 0 : 15

                Behavior on y {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutBack
                    }

                }

            }

        }

        Rectangle {
            id: notificationCenterWidget

            property bool isHovered: notificationCenterMouse.containsMouse
            // Staggered startup animation
            property bool initAnimTriggerNotificationCenter: false

            width: config.notificationCenterButtonWidth
            height: config.notificationCenterButtonHeight
            color: isHovered ? theme.colTertiary : theme.colPrimary
            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            // Hover animation
            scale: isHovered ? 1.06 : 1
            opacity: initAnimTriggerNotificationCenter ? 1 : 0
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerNotificationCenter.interval = 3 * config.staggerDelay;
                    animTimerNotificationCenter.start();
                } else {
                    initAnimTriggerNotificationCenter = true;
                }
            }

            Text {
                anchors.centerIn: parent
                text: "||"
                color: theme.colOnPrimary

                font {
                    pixelSize: config.fontSize
                    bold: true
                }

            }

            MouseArea {
                id: notificationCenterMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "notificationCenter"])
            }

            Timer {
                id: animTimerNotificationCenter

                running: false
                repeat: false
                onTriggered: notificationCenterWidget.initAnimTriggerNotificationCenter = true
            }

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 500
                }

            }

            Behavior on scale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                }

            }

            transform: Translate {
                y: notificationCenterWidget.initAnimTriggerNotificationCenter ? 0 : 15

                Behavior on y {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutBack
                    }

                }

            }

        }

        Rectangle {
            id: systemMonitorWidget

            property bool isHovered: systemMonitorMouse.containsMouse
            // Staggered startup animation
            property bool initAnimTriggerSystemMonitor: false

            width: config.systemMonitorButtonWidth
            height: config.systemMonitorButtonHeight
            color: isHovered ? theme.colTertiary : theme.colPrimary
            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            // Hover animation
            scale: isHovered ? 1.06 : 1
            opacity: initAnimTriggerSystemMonitor ? 1 : 0
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerSystemMonitor.interval = 3 * config.staggerDelay;
                    animTimerSystemMonitor.start();
                } else {
                    initAnimTriggerSystemMonitor = true;
                }
            }

            Text {
                anchors.centerIn: parent
                text: "||"
                color: theme.colOnPrimary

                font {
                    pixelSize: config.fontSize
                    bold: true
                }

            }

            MouseArea {
                id: systemMonitorMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "systemMonitor"])
            }

            Timer {
                id: animTimerSystemMonitor

                running: false
                repeat: false
                onTriggered: systemMonitorWidget.initAnimTriggerSystemMonitor = true
            }

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 500
                }

            }

            Behavior on scale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                }

            }

            transform: Translate {
                y: systemMonitorWidget.initAnimTriggerSystemMonitor ? 0 : 15

                Behavior on y {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutBack
                    }

                }

            }

        }

    }

}
