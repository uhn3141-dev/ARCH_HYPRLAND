import QtQuick 2.15
import QtQuick.Layouts 2.15
import QtQuick.Controls 2.15
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    AppIcons { 
        id: appIcons
        iconPath: _HOMEDIR + "/.config/quickshell/app_icons.json"
    }

    anchors.top: true
    implicitHeight: config.panelHeight
    implicitWidth: config.monitorWidth - 2
    color: '#00ffffff'

    Theme { id: theme }
    Config { id: config }

    property bool isStartupReady: false
    Timer {
        interval: 100
        running: true
        onTriggered: {
            root.isStartupReady = true
        }
    }

    // Auto-reload every 5 minutes.
    Timer {
        interval: 300000
        running: true
        onTriggered: {
            Quickshell.reload("~/.config/quickshell/shell.qml")
        }
    }
    
    property bool showLayout: false
    Timer { 
        running: root.isStartupReady
        interval: config.startupDelay
        onTriggered: root.showLayout = true
    }

    readonly property string _HOMEDIR: Quickshell.env("HOME")

    PopupManager { id: popupManager }

    LeftPanel { id: leftPanel }
    MiddlePanel { id: middlePanel }
    RightPanel { id: rightPanel }
}
