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
}