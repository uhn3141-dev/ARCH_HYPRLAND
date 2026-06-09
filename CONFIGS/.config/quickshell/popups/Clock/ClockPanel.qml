import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

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
