import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

PopupWindow {
    id: notifPopup

    anchor.window: root
    anchor.rect.x: root.width - width - 20
    anchor.rect.y: 31

    implicitWidth: 340
    implicitHeight: 460

    color: 'transparent'
    visible: false

    property bool dndEnabled: false
    property var notifModel: []        // provided by MiddlePanel

    property var collapsedGroups: ({})

    function toggleGroup(groupName) {
        let temp = Object.assign({}, collapsedGroups)
        temp[groupName] = !temp[groupName]
        collapsedGroups = temp
    }
    function isCollapsed(groupName) {
        return collapsedGroups[groupName] === true
    }
    function clearGroup(appName) {
        if (!notifModel) return
        for (let i = notifModel.count - 1; i >= 0; i--) {
            if (notifModel.get(i).appName === appName)
                notifModel.remove(i)
        }
    }

    // ── DND sync on open ──
    Process {
        id: dndReader
        command: ["bash", "-c", "dunstctl is-paused"]
        stdout: StdioCollector {
            onStreamFinished: {
                notifPopup.dndEnabled = (text.trim() === 'true')
            }
        }
    }
    onVisibleChanged: {
        if (visible) {
            introHeader = 0; introList = 0
            entryAnim.restart()
            dndReader.running = true
        }
    }

    property real introHeader: 0
    property real introList: 0

    ParallelAnimation {
        id: entryAnim
        NumberAnimation { target: notifPopup; property: "introHeader"; from: 0; to: 1; duration: 400; easing.type: Easing.OutBack }
        SequentialAnimation {
            PauseAnimation { duration: 150 }
            NumberAnimation { target: notifPopup; property: "introList"; from: 0; to: 1; duration: 500; easing.type: Easing.OutBack }
        }
    }

    Rectangle {
        id: notifPanel
        anchors.fill: parent
        color: theme.colSurface
        radius: 20
        border.width: 3
        border.color: theme.colSurface

        opacity: notifPopup.visible ? 1 : 0
        scale: notifPopup.visible ? 1 : 0.2
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ── Header + DND + Clear All ────────
            RowLayout {
                Layout.fillWidth: true
                height: 36
                spacing: 8
                opacity: notifPopup.introHeader
                transform: Translate { y: 15 * (1 - notifPopup.introHeader) }

                Text {
                    text: "Notifications"
                    color: theme.colOnSurface
                    font.pixelSize: config.fontSize * 1.2
                    font.weight: Font.Bold
                }

                Item { Layout.fillWidth: true }

                // DND Toggle
                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: notifPopup.dndEnabled ? "#FF5252" : theme.colSecondary
                    Text {
                        anchors.centerIn: parent
                        text: notifPopup.dndEnabled ? "󰂛" : "󰂚"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: config.fontSize * 1.2
                        color: notifPopup.dndEnabled ? "#fff" : theme.colOnSecondary
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            notifPopup.dndEnabled = !notifPopup.dndEnabled
                            Quickshell.execDetached(["bash", "-c", "dunstctl set-paused " + (notifPopup.dndEnabled ? "true" : "false")])
                        }
                    }
                }

                // Clear All button
                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: "#FF5252"
                    visible: notifModel && notifModel.count > 0
                    Text {
                        anchors.centerIn: parent
                        text: "󰆴"   // trash icon
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: config.fontSize * 1.2
                        color: "#fff"
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["bash", "-c", "dunstctl close-all"])
                            if (notifModel) notifModel.clear()
                        }
                    }
                }
            }

            // ── Notification List ──────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: theme.colSecondary
                radius: 14
                clip: true
                opacity: notifPopup.introList
                transform: Translate { y: 15 * (1 - notifPopup.introList) }

                Text {
                    anchors.centerIn: parent
                    text: "You're all caught up."
                    color: theme.colOnSecondary
                    font.pixelSize: config.fontSize * 1
                    visible: !notifModel || notifModel.count === 0
                }

                ListView {
                    id: notifList
                    anchors.fill: parent
                    anchors.margins: 6
                    model: notifModel
                    spacing: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    // Group by appName
                    section.property: "appName"
                    section.criteria: ViewSection.FullString
                    section.delegate: Item {
                        width: ListView.view.width
                        height: 30

                        Rectangle {
                            anchors.fill: parent
                            anchors.topMargin: 4; anchors.bottomMargin: 2
                            color: headerMa.containsMouse ? theme.colPrimary : "transparent"
                            radius: 6

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6; anchors.rightMargin: 6
                                spacing: 6

                                MouseArea {
                                    id: headerMa
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: notifPopup.toggleGroup(section)

                                    RowLayout {
                                        anchors.fill: parent; spacing: 6
                                        Text {
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: config.fontSize * 0.8
                                            color: theme.colPrimary
                                            text: notifPopup.isCollapsed(section) ? "󰅂" : "󰅀"
                                        }
                                        Text {
                                            text: section.toUpperCase()
                                            font.family: config.fontFamily || "JetBrains Mono"
                                            font.weight: Font.Bold
                                            font.pixelSize: config.fontSize * 0.65
                                            color: theme.colOnPrimary
                                            Layout.fillWidth: true
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 22; Layout.preferredHeight: 22; radius: 11
                                    color: groupClearMa.containsMouse ? "#FF5252" : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: config.fontSize * 0.7
                                        color: groupClearMa.containsMouse ? "#fff" : theme.colOnSurfaceVariant
                                    }
                                    MouseArea {
                                        id: groupClearMa
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: notifPopup.clearGroup(section)
                                    }
                                }
                            }
                        }
                    }

                    // Individual notification
                    delegate: Item {
                        id: wrapper
                        width: ListView.view.width
                        property bool hidden: notifPopup.isCollapsed(model.appName)
                        height: hidden ? 0 : card.height + 6
                        visible: height > 0
                        clip: true
                        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

                        Rectangle {
                            id: card
                            width: parent.width
                            height: contentCol.height + 20
                            radius: 10
                            color: cardHover.containsMouse ? theme.colPrimary : theme.colSecondary
                            border.color: cardHover.containsMouse ? theme.colSurfaceVariant : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }

                            MouseArea {
                                id: cardHover
                                anchors.fill: parent
                                hoverEnabled: true
                            }

                            Rectangle {
                                width: 4; height: parent.height
                                anchors.left: parent.left
                                color: theme.colPrimary
                            }

                            ColumnLayout {
                                id: contentCol
                                anchors.left: parent.left; anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 10; anchors.leftMargin: 16
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true; spacing: 6
                                    Text {
                                        text: model.summary || "Notification"
                                        font.family: config.fontFamily || "JetBrains Mono"
                                        font.weight: Font.Bold
                                        font.pixelSize: config.fontSize * 0.85
                                        color: theme.colOnPrimary
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                    }
                                    // Dismiss button – red trash icon
                                    Rectangle {
                                        Layout.preferredWidth: 24
                                        Layout.preferredHeight: 24
                                        radius: 12
                                        color: dismissMa.containsMouse ? "#D32F2F" : "#FF5252"
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰆴"   // trash icon
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: config.fontSize * 0.75
                                            color: "#fff"
                                        }

                                        MouseArea {
                                            id: dismissMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Quickshell.execDetached(["bash", "-c", "dunstctl close " + model.uid])
                                                notifModel.remove(index)
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: model.body || ""
                                    font.family: config.fontFamily || "JetBrains Mono"
                                    font.weight: Font.Medium
                                    font.pixelSize: config.fontSize * 0.7
                                    color: theme.colOnSecondary
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                    visible: text !== ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}