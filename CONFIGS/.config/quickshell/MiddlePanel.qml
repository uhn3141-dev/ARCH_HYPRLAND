// ============================================================
//  MIDDLE SECTION - CLOCK, SYSTEM INFO, POPUPS
// ============================================================

import QtQuick 2.15
import QtQuick.Layouts 2.15
import QtQuick.Controls 2.15
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland


import "./popups/Battery" as Battery
import "./popups/Brightness" as Brightness
import "./popups/Sound" as Sound
import "./popups/Clock" as Clock
import "./popups/Power" as Power
import "./popups/Network" as Network
import "./popups/Bluetooth" as Bluetooth



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
            width: config.middlePanelButtonWidth
            height: config.middlePanelButtonHeight
            
            property bool isHovered: batteryMouse.containsMouse

            color: isHovered ? theme.colTertiary : theme.colPrimary
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 500 } }

            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            
            Text {
                anchors.centerIn: parent
                text: {
                    if (batteryPopup.isCharging) return "󰂄"
                    if (batteryPopup.batteryPercent >= 90) return ""
                    if (batteryPopup.batteryPercent >= 70) return ""
                    if (batteryPopup.batteryPercent >= 40) return ""
                    if (batteryPopup.batteryPercent >= 15) return ""
                    return ""
                }
                color: theme.colOnPrimary
                font { pixelSize: config.fontSize+8; bold: true }
            }

            MouseArea {
                id: batteryMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "battery"])
            }
            
            // Hover animation
            scale: isHovered ? 1.1 : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            
            // Staggered startup animation
            property bool initAnimTriggerBattery: false
            opacity: initAnimTriggerBattery ? 1 : 0
            transform: Translate {
                y: batteryWidget.initAnimTriggerBattery ? 0 : 15
                Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
            }
            
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerBattery.interval = 1 * config.staggerDelay
                    animTimerBattery.start()
                } else {
                    initAnimTriggerBattery = true
                }
            }

            Timer {
                id: animTimerBattery
                running: false
                repeat: false
                onTriggered: batteryWidget.initAnimTriggerBattery = true
            }
        }

        Rectangle {
            id: brightnessWidget
            width: config.middlePanelButtonWidth
            height: config.middlePanelButtonHeight

            property bool isHovered: brightnessMouse.containsMouse

            color: isHovered ? theme.colTertiary : theme.colPrimary
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 500 } }

            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            
            Text {
                anchors.centerIn: parent
                text: {
                    if (brightnessPopup.autoBrightness) return "🔆"
                    if (brightnessPopup.currentBrightness >= 70) return "󰃠"
                    if (brightnessPopup.currentBrightness >= 30) return "󰃟"
                    if (brightnessPopup.currentBrightness >= 10) return "󰃝"
                    return "󰃞"
                }
                color: theme.colOnPrimary
                font { pixelSize: config.fontSize+4; bold: true }
            }

            MouseArea {
                id: brightnessMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "brightness"])
            }
            
            // Hover animation
            scale: isHovered ? 1.1 : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            
            // Staggered startup animation
            property bool initAnimTriggerBrightness: false
            opacity: initAnimTriggerBrightness ? 2 : 0
            transform: Translate {
                y: brightnessWidget.initAnimTriggerBrightness ? 0 : 15
                Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
            }
            
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerBrightness.interval = 1 * config.staggerDelay
                    animTimerBrightness.start()
                } else {
                    initAnimTriggerBrightness = true
                }
            }

            Timer {
                id: animTimerBrightness
                running: false
                repeat: false
                onTriggered: brightnessWidget.initAnimTriggerBrightness = true
            }
        }

        Rectangle {
            id: soundWidget
            width: config.middlePanelButtonWidth
            height: config.middlePanelButtonHeight

            property bool isHovered: soundMouse.containsMouse

            color: isHovered ? theme.colTertiary : theme.colPrimary
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 500 } }

            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            
            Text {
                anchors.centerIn: parent
                text: {
                    if (soundPopup.activeMute || soundPopup.activeVol === 0) return "󰖁"
                    if (soundPopup.activeVol >= 70) return "󰕾"
                    if (soundPopup.activeVol >= 30) return "󰖀"
                    return "󰕿"
                }
                color: theme.colOnPrimary
                font { pixelSize: config.fontSize+4; bold: true }
            }

            MouseArea {
                id: soundMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "sound"])
            }
            
            // Hover animation
            scale: isHovered ? 1.1 : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            
            // Staggered startup animation
            property bool initAnimTriggerSound: false
            opacity: initAnimTriggerSound ? 1 : 0
            transform: Translate {
                y: soundWidget.initAnimTriggerSound ? 0 : 15
                Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
            }
            
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerSound.interval = 3 * config.staggerDelay
                    animTimerSound.start()
                } else {
                    initAnimTriggerSound = true
                }
            }

            Timer {
                id: animTimerSound
                running: false
                repeat: false
                onTriggered: soundWidget.initAnimTriggerSound = true
            }
        }

        // Clock widget
        Rectangle {
            id: clockWidget
            width: config.clockButtonWidth
            height: config.clockButtonHeight

            property bool isHovered: clockMouse.containsMouse

            color: isHovered ? theme.colTertiary : theme.colPrimary
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 500 } }

            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder

            // anchors.verticalCenter: parent.verticalCenter

            Text {
                id: clockWidgetText
                anchors.centerIn: parent
                property var currentTime: new Date()
                text: currentTime.toLocaleTimeString(Qt.locale(), " hh:mm:ss ")
                //text: " 88:88:88 " // Dummy text test the prevention of resizing when numbers change
                color: theme.colOnPrimary
                font.family: config.fontFamilyClock
                font { pixelSize: config.fontSize+14; bold: true }

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
            
            // Hover animation
            scale: isHovered ? 1.03 : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            
            // Staggered startup animation
            property bool initAnimTriggerClock: false
            opacity: initAnimTriggerClock ? 1 : 0
            transform: Translate {
                y: clockWidget.initAnimTriggerClock ? 0 : 15
                Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
            }
            
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerClock.interval = 4 * config.staggerDelay
                    animTimerClock.start()
                } else {
                    initAnimTriggerClock = true
                }
            }

            Timer {
                id: animTimerClock
                running: false
                repeat: false
                onTriggered: clockWidget.initAnimTriggerClock = true
            }
        }

        Rectangle {
            id: powerWidget
            width: config.middlePanelButtonWidth
            height: config.middlePanelButtonHeight

            property bool isHovered: powerMouse.containsMouse

            color: isHovered ? theme.colTertiary : theme.colPrimary
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 500 } }

            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            
            Text {
                anchors.centerIn: parent
                text: "⏻"
                color: theme.colOnPrimary
                font { pixelSize: config.fontSize+4; bold: true }
            }

            MouseArea {
                id: powerMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "power"])
            }
            
            // Hover animation
            scale: isHovered ? 1.1 : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            
            // Staggered startup animation
            property bool initAnimTriggerPower: false
            opacity: initAnimTriggerPower ? 1 : 0
            transform: Translate {
                y: powerWidget.initAnimTriggerPower ? 0 : 15
                Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
            }
            
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerPower.interval = 3 * config.staggerDelay
                    animTimerPower.start()
                } else {
                    initAnimTriggerPower = true
                }
            }

            Timer {
                id: animTimerPower
                running: false
                repeat: false
                onTriggered: powerWidget.initAnimTriggerPower = true
            }
        }

        Rectangle {
            id: networkWidget
            width: config.middlePanelButtonWidth
            height: config.middlePanelButtonHeight

            property bool isHovered: networkMouse.containsMouse

            color: isHovered ? theme.colTertiary : theme.colPrimary
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 500 } }

            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder

            Text {
                anchors.centerIn: parent
                text: {
                    if (!networkPopup.wifiPowered && !networkPopup.ethernetPowered) return "󰤭"  // Both off
                    if (!networkPopup.wifiPowered && networkPopup.ethernetPowered) return "" // " 󰈀"  // WiFi off, Ethernet on
                    if (networkPopup.connectedNetwork) {
                        var sig = parseInt(networkPopup.connectedNetwork.signal) || 0
                        if (sig >= 80) return "󰤨"
                        if (sig >= 60) return "󰤥"
                        if (sig >= 40) return "󰤢"
                        if (sig >= 20) return "󰤟"
                        return "󰤯"
                    }
                    if (networkPopup.ethernetPowered) return "󰖪"  // WiFi on but Ethernet connected instead
                    return "󰤭"  // WiFi on, nothing connected
                }
                color: theme.colOnPrimary
                font { pixelSize: config.fontSize+3; bold: true }
            }

            MouseArea {
                id: networkMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "network"])
            }
            
            // Hover animation
            scale: isHovered ? 1.1 : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            
            // Staggered startup animation
            property bool initAnimTriggerNetwork: false
            opacity: initAnimTriggerNetwork ? 1 : 0
            transform: Translate {
                y: networkWidget.initAnimTriggerNetwork ? 0 : 15
                Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
            }
            
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerNetwork.interval = 2 * config.staggerDelay
                    animTimerNetwork.start()
                } else {
                    initAnimTriggerNetwork = true
                }
            }

            Timer {
                id: animTimerNetwork
                running: false
                repeat: false
                onTriggered: networkWidget.initAnimTriggerNetwork = true
            }
        }

        Rectangle {
            id: bluetoothWidget
            width: config.middlePanelButtonWidth
            height: config.middlePanelButtonHeight

            property bool isHovered: bluetoothMouse.containsMouse

            color: isHovered ? theme.colTertiary : theme.colPrimary
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 500 } }

            radius: config.elementRadius + 2
            border.width: 2
            border.color: config.widgetBorder
            
            Text {
                anchors.centerIn: parent
                text: {
                    if (!bluetoothPopup.bluetoothManager.bluetoothPresent) return "󰂲"
                    if (!bluetoothPopup.bluetoothManager.bluetoothPowered) return "󰂯"
                    if (bluetoothPopup.bluetoothManager.connectedDevices.length > 0) return "󰂱"
                    return "󰂯"
                }
                color: theme.colOnPrimary
                font { pixelSize: config.fontSize+4; bold: true }
            }

            MouseArea {
                id: bluetoothMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", _HOMEDIR + "/.config/quickshell/popup_manager.sh", "--toggle", "bluetooth"])
            }
            
            scale: isHovered ? 1.1 : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            
            property bool initAnimTriggerBluetooth: false
            opacity: initAnimTriggerBluetooth ? 1 : 0
            transform: Translate {
                y: bluetoothWidget.initAnimTriggerBluetooth ? 0 : 15
                Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
            }
            
            Component.onCompleted: {
                if (!root.isStartupReady) {
                    animTimerBluetooth.interval = 1 * config.staggerDelay
                    animTimerBluetooth.start()
                } else {
                    initAnimTriggerBluetooth = true
                }
            }

            Timer {
                id: animTimerBluetooth
                running: false
                repeat: false
                onTriggered: bluetoothWidget.initAnimTriggerBluetooth = true
            }
        }
    }
}