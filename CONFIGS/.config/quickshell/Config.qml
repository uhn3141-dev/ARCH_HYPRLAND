import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    Theme { id: theme }

    // ============================================================
    //  VARIABLE GROUP - Customize these for your setup
    // ============================================================
    
    property int monitorWidth: 1360
    property int panelHeight: 32
    property string fontFamily: "Profont Nerd Font"
    property string fontFamilyClock: "Darknet" // "Darknet" "Gamecuben" "Race Sport" "Headshots"
    property int fontSize: 10

    property color widgetBorder: '#00000000'

    property int numberOfWorkspace: 9
    
    property int workspaceButtonWidth: 20
    property int workspaceButtonHeight: 20
    property int middlePanelButtonWidth: 22
    property int middlePanelButtonHeight: 22
    property int clockButtonWidth: 165
    property int clockButtonHeight: 26
    property int systemMonitorButtonWidth: 100
    property int systemMonitorButtonHeight: 22
    property int notificationCenterButtonWidth: 30
    property int notificationCenterButtonHeight: 22
    property int musicButtonWidth: 45
    property int musicButtonHeight: 22

    property int elementRadius: 5
    
    // ---- Animation Settings ----
    property int startupDelay: 150          // Delay before showing UI (ms)
    property int animationDuration: 600     // Duration for fade/slide animations (ms)
    property int staggerDelay: 60           // Delay between each workspace button animation (ms)
}