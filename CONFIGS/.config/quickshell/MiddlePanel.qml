// ============================================================
//  MIDDLE SECTION - CLOCK, SYSTEM INFO, POPUPS
// ============================================================

import "./popups/Battery" as Battery
import "./popups/Bluetooth" as Bluetooth
import "./popups/Brightness" as Brightness
import "./popups/Clock" as Clock
import "./popups/Network" as Network
import "./popups/Power" as Power
import "./popups/Sound" as Sound
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

RowLayout {
    id: middlePanel

    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.centerIn: parent
    anchors.top: parent.top
    anchors.margins: 3

    Battery.BatteryPanel {
        id: batteryPopup

        Component.onCompleted: popupManager.registerPopup("battery", batteryPopup)
    }

    Brightness.BrightnessPanel {
        id: brightnessPopup

        Component.onCompleted: popupManager.registerPopup("brightness", brightnessPopup)
    }

    Sound.SoundPanel {
        id: soundPopup

        Component.onCompleted: popupManager.registerPopup("sound", soundPopup)
    }

    Clock.ClockPanel {
        id: clockPopup

        Component.onCompleted: popupManager.registerPopup("clock", clockPopup)
    }

    Bluetooth.BluetoothPanel {
        id: bluetoothPopup

        Component.onCompleted: popupManager.registerPopup("bluetooth", bluetoothPopup)
    }

    Network.NetworkPanel {
        id: networkPopup

        Component.onCompleted: popupManager.registerPopup("network", networkPopup)
    }

    Power.PowerPanel {
        id: powerPopup

        Component.onCompleted: popupManager.registerPopup("power", powerPopup)
    }

    Row {
        id: centerPanelContent

        spacing: 3

        Rectangle {
            id: batteryWidget

            property bool isHovered: batteryMouse.containsMouse
            // Staggered startup animation
            property bool initAnimTriggerBattery: false

            width: config.middlePanelButtonWidth
            height: config.middlePanelButtonHeight
            color: isHovered ? theme.colTertiary : theme.colPrimary
            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            // Hover animation
            scale: isHovered ? 1.1 : 1
            opacity: initAnimTriggerBattery ? 1 : 0
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerBattery.interval = 1 * config.staggerDelay;
                    animTimerBattery.start();
                } else {
                    initAnimTriggerBattery = true;
                }
            }

            Text {
                anchors.centerIn: parent
                text: {
                    if (batteryPopup.isCharging)
                        return "󰂄";

                    if (batteryPopup.batteryPercent >= 90)
                        return "";

                    if (batteryPopup.batteryPercent >= 70)
                        return "";

                    if (batteryPopup.batteryPercent >= 40)
                        return "";

                    if (batteryPopup.batteryPercent >= 15)
                        return "";

                    return "";
                }
                color: theme.colOnPrimary

                font {
                    pixelSize: config.fontSize + 8
                    bold: true
                }

            }

            MouseArea {
                id: batteryMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "battery"])
            }

            Timer {
                id: animTimerBattery

                running: false
                repeat: false
                onTriggered: batteryWidget.initAnimTriggerBattery = true
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
                y: batteryWidget.initAnimTriggerBattery ? 0 : 15

                Behavior on y {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutBack
                    }

                }

            }

        }

        Rectangle {
            id: brightnessWidget

            property bool isHovered: brightnessMouse.containsMouse
            // Staggered startup animation
            property bool initAnimTriggerBrightness: false

            width: config.middlePanelButtonWidth
            height: config.middlePanelButtonHeight
            color: isHovered ? theme.colTertiary : theme.colPrimary
            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            // Hover animation
            scale: isHovered ? 1.1 : 1
            opacity: initAnimTriggerBrightness ? 2 : 0
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerBrightness.interval = 1 * config.staggerDelay;
                    animTimerBrightness.start();
                } else {
                    initAnimTriggerBrightness = true;
                }
            }

            Text {
                anchors.centerIn: parent
                text: {
                    if (brightnessPopup.autoBrightness)
                        return "🔆";

                    if (brightnessPopup.currentBrightness >= 70)
                        return "󰃠";

                    if (brightnessPopup.currentBrightness >= 30)
                        return "󰃟";

                    if (brightnessPopup.currentBrightness >= 10)
                        return "󰃝";

                    return "󰃞";
                }
                color: theme.colOnPrimary

                font {
                    pixelSize: config.fontSize + 4
                    bold: true
                }

            }

            MouseArea {
                id: brightnessMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "brightness"])
            }

            Timer {
                id: animTimerBrightness

                running: false
                repeat: false
                onTriggered: brightnessWidget.initAnimTriggerBrightness = true
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
                y: brightnessWidget.initAnimTriggerBrightness ? 0 : 15

                Behavior on y {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutBack
                    }

                }

            }

        }

        Rectangle {
            id: soundWidget

            property bool isHovered: soundMouse.containsMouse
            // Staggered startup animation
            property bool initAnimTriggerSound: false

            width: config.middlePanelButtonWidth
            height: config.middlePanelButtonHeight
            color: isHovered ? theme.colTertiary : theme.colPrimary
            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            // Hover animation
            scale: isHovered ? 1.1 : 1
            opacity: initAnimTriggerSound ? 1 : 0
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerSound.interval = 3 * config.staggerDelay;
                    animTimerSound.start();
                } else {
                    initAnimTriggerSound = true;
                }
            }

            Text {
                anchors.centerIn: parent
                text: {
                    if (soundPopup.activeMute || soundPopup.activeVol === 0)
                        return "󰖁";

                    if (soundPopup.activeVol >= 70)
                        return "󰕾";

                    if (soundPopup.activeVol >= 30)
                        return "󰖀";

                    return "󰕿";
                }
                color: theme.colOnPrimary

                font {
                    pixelSize: config.fontSize + 4
                    bold: true
                }

            }

            MouseArea {
                id: soundMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "sound"])
            }

            Timer {
                id: animTimerSound

                running: false
                repeat: false
                onTriggered: soundWidget.initAnimTriggerSound = true
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
                y: soundWidget.initAnimTriggerSound ? 0 : 15

                Behavior on y {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutBack
                    }

                }

            }

        }

        // Clock widget
        Rectangle {
            // anchors.verticalCenter: parent.verticalCenter

            id: clockWidget

            property bool isHovered: clockMouse.containsMouse
            // Staggered startup animation
            property bool initAnimTriggerClock: false

            width: config.clockButtonWidth
            height: config.clockButtonHeight
            color: isHovered ? theme.colTertiary : theme.colPrimary
            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            // Hover animation
            scale: isHovered ? 1.03 : 1
            opacity: initAnimTriggerClock ? 1 : 0
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerClock.interval = 4 * config.staggerDelay;
                    animTimerClock.start();
                } else {
                    initAnimTriggerClock = true;
                }
            }

            Text {
                id: clockWidgetText

                property var currentTime: new Date()

                anchors.centerIn: parent
                text: currentTime.toLocaleTimeString(Qt.locale(), " hh:mm:ss ")
                //text: " 88:88:88 " // Dummy text test the prevention of resizing when numbers change
                color: theme.colOnPrimary
                font.family: config.fontFamilyClock

                font {
                    pixelSize: config.fontSize + 14
                    bold: true
                }

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clockWidgetText.currentTime = new Date()
                }

            }

            MouseArea {
                id: clockMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "clock"])
            }

            Timer {
                id: animTimerClock

                running: false
                repeat: false
                onTriggered: clockWidget.initAnimTriggerClock = true
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
                y: clockWidget.initAnimTriggerClock ? 0 : 15

                Behavior on y {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutBack
                    }

                }

            }

        }

        Rectangle {
            id: powerWidget

            property bool isHovered: powerMouse.containsMouse
            // Staggered startup animation
            property bool initAnimTriggerPower: false

            width: config.middlePanelButtonWidth
            height: config.middlePanelButtonHeight
            color: isHovered ? theme.colTertiary : theme.colPrimary
            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            // Hover animation
            scale: isHovered ? 1.1 : 1
            opacity: initAnimTriggerPower ? 1 : 0
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerPower.interval = 3 * config.staggerDelay;
                    animTimerPower.start();
                } else {
                    initAnimTriggerPower = true;
                }
            }

            Text {
                anchors.centerIn: parent
                text: "⏻"
                color: theme.colOnPrimary

                font {
                    pixelSize: config.fontSize + 4
                    bold: true
                }

            }

            MouseArea {
                id: powerMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "power"])
            }

            Timer {
                id: animTimerPower

                running: false
                repeat: false
                onTriggered: powerWidget.initAnimTriggerPower = true
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
                y: powerWidget.initAnimTriggerPower ? 0 : 15

                Behavior on y {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutBack
                    }

                }

            }

        }

        Rectangle {
            id: networkWidget

            property bool isHovered: networkMouse.containsMouse
            // Staggered startup animation
            property bool initAnimTriggerNetwork: false

            width: config.middlePanelButtonWidth
            height: config.middlePanelButtonHeight
            color: isHovered ? theme.colTertiary : theme.colPrimary
            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            // Hover animation
            scale: isHovered ? 1.1 : 1
            opacity: initAnimTriggerNetwork ? 1 : 0
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerNetwork.interval = 2 * config.staggerDelay;
                    animTimerNetwork.start();
                } else {
                    initAnimTriggerNetwork = true;
                }
            }

            Text {
                anchors.centerIn: parent
                text: {
                    if (!networkPopup.wifiPowered && !networkPopup.ethernetPowered)
                        return "󰤭";
 // Both off
                    if (!networkPopup.wifiPowered && networkPopup.ethernetPowered)
                        return "";
 // " 󰈀"  // WiFi off, Ethernet on
                    if (networkPopup.connectedNetwork) {
                        var sig = parseInt(networkPopup.connectedNetwork.signal) || 0;
                        if (sig >= 80)
                            return "󰤨";

                        if (sig >= 60)
                            return "󰤥";

                        if (sig >= 40)
                            return "󰤢";

                        if (sig >= 20)
                            return "󰤟";

                        return "󰤯";
                    }
                    if (networkPopup.ethernetPowered)
                        return "󰖪";
 // WiFi on but Ethernet connected instead
                    return "󰤭"; // WiFi on, nothing connected
                }
                color: theme.colOnPrimary

                font {
                    pixelSize: config.fontSize + 3
                    bold: true
                }

            }

            MouseArea {
                id: networkMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "network"])
            }

            Timer {
                id: animTimerNetwork

                running: false
                repeat: false
                onTriggered: networkWidget.initAnimTriggerNetwork = true
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
                y: networkWidget.initAnimTriggerNetwork ? 0 : 15

                Behavior on y {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutBack
                    }

                }

            }

        }

        Rectangle {
            id: bluetoothWidget

            property bool isHovered: bluetoothMouse.containsMouse
            property bool initAnimTriggerBluetooth: false

            width: config.middlePanelButtonWidth
            height: config.middlePanelButtonHeight
            color: isHovered ? theme.colTertiary : theme.colPrimary
            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            scale: isHovered ? 1.1 : 1
            opacity: initAnimTriggerBluetooth ? 1 : 0
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerBluetooth.interval = 1 * config.staggerDelay;
                    animTimerBluetooth.start();
                } else {
                    initAnimTriggerBluetooth = true;
                }
            }

            Text {
                anchors.centerIn: parent
                text: {
                    if (!bluetoothPopup.bluetoothManager.bluetoothPresent)
                        return "󰂲";

                    if (!bluetoothPopup.bluetoothManager.bluetoothPowered)
                        return "󰂯";

                    if (bluetoothPopup.bluetoothManager.connectedDevices.length > 0)
                        return "󰂱";

                    return "󰂯";
                }
                color: theme.colOnPrimary

                font {
                    pixelSize: config.fontSize + 4
                    bold: true
                }

            }

            MouseArea {
                id: bluetoothMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "bluetooth"])
            }

            Timer {
                id: animTimerBluetooth

                running: false
                repeat: false
                onTriggered: bluetoothWidget.initAnimTriggerBluetooth = true
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
                y: bluetoothWidget.initAnimTriggerBluetooth ? 0 : 15

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
