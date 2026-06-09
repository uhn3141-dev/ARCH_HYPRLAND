import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    property bool isStartupReady: false
    property bool showLayout: false
    readonly property string _HOMEDIR: Quickshell.env("HOME")

    anchors.top: true
    implicitHeight: config.panelHeight
    implicitWidth: config.monitorWidth - 2
    color: '#00ffffff'

    AppIcons {
        id: appIcons

        iconPath: _HOMEDIR + "/.config/quickshell/app_icons.json"
    }

    Theme {
        id: theme
    }

    Config {
        id: config
    }

    Timer {
        interval: 100
        running: true
        onTriggered: {
            root.isStartupReady = true;
        }
    }

    // Auto-reload every 5 minutes.
    Timer {
        interval: 300000
        running: true
        onTriggered: {
            Quickshell.reload("~/.config/quickshell/shell.qml");
        }
    }

    Timer {
        running: root.isStartupReady
        interval: config.startupDelay
        onTriggered: root.showLayout = true
    }

    PopupManager {
        id: popupManager
    }

    LeftPanel {
        id: leftPanel
    }

    MiddlePanel {
        id: middlePanel
    }

    RightPanel {
        id: rightPanel
    }

}
