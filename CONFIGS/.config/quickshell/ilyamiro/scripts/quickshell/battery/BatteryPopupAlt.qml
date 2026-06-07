// import QtQuick
// import QtQuick.Layouts
// import QtQuick.Window
// import QtQuick.Controls
// import QtCore
// import Quickshell
// import Quickshell.Io
// import "../"

// Item {
//     id: window

//     // --- RECEIVE THE DBUS LIST FROM MAIN.QML ---
//     property var notifModel

//     // State object for collapsible notification groups
//     property var collapsedGroups: ({})

//     function toggleGroup(groupName) {
//         let temp = Object.assign({}, collapsedGroups);
//         temp[groupName] = !temp[groupName];
//         collapsedGroups = temp;
//     }

//     function isCollapsed(groupName) {
//         return collapsedGroups[groupName] === true;
//     }

//     // Helper: Safely clear an entire group of notifications by AppName
//     function clearGroup(appName) {
//         if (!notifModel) return;
//         for (let i = notifModel.count - 1; i >= 0; i--) {
//             if (notifModel.get(i).appName === appName) {
//                 notifModel.remove(i);
//             }
//         }
//     }

//     // --- Responsive Scaling Logic ---
//     Scaler {
//         id: scaler
//         // Uses the physical screen width so the popup scales synchronously with the TopBar
//         currentWidth: Screen.width
//     }
    
//     // Helper function scoped to the root Item for easy access in deeply nested elements and Canvases
//     function s(val) { 
//         return scaler.s(val); 
//     }

//     // -------------------------------------------------------------------------
//     // COLORS (Dynamic Matugen Palette)
//     // -------------------------------------------------------------------------
//     MatugenColors { id: _theme }
//     readonly property color base: _theme.base
//     readonly property color mantle: _theme.mantle
//     readonly property color crust: _theme.crust
//     readonly property color text: _theme.text
//     readonly property color subtext0: _theme.subtext0
//     readonly property color overlay0: _theme.overlay0
//     readonly property color overlay1: _theme.overlay1
//     readonly property color surface0: _theme.surface0
//     readonly property color surface1: _theme.surface1
//     readonly property color surface2: _theme.surface2
    
//     readonly property color mauve: _theme.mauve
//     readonly property color pink: _theme.pink
//     readonly property color red: _theme.red
//     readonly property color maroon: _theme.maroon
//     readonly property color peach: _theme.peach
//     readonly property color yellow: _theme.yellow
//     readonly property color green: _theme.green
//     readonly property color teal: _theme.teal
//     readonly property color sapphire: _theme.sapphire
//     readonly property color blue: _theme.blue

//     // -------------------------------------------------------------------------
//     // CACHE (Eliminates startup delay visually)
//     // -------------------------------------------------------------------------
//     Settings {
//         id: widgetCache
//         category: "SystemMonitorCache"
//         property int cpuUsage: 0
//         property int ramUsage: 0
//         property int diskUsage: 0
//         property int sysTemp: 0
//         property string powerProfile: "balanced"
//         property int upHours: 0
//         property int upMins: 0
//         property real sysVolume: 0
//         property bool sysMuted: false
//         property real sysBrightness: 0
//         property string currentUserName: "User"
//     }

//     // -------------------------------------------------------------------------
//     // STATE & POLLING
//     // -------------------------------------------------------------------------
//     property int cpuUsage: widgetCache.cpuUsage
//     property int ramUsage: widgetCache.ramUsage
//     property int diskUsage: widgetCache.diskUsage
//     property int sysTemp: widgetCache.sysTemp

//     property string powerProfile: widgetCache.powerProfile
    
//     property int upHours: widgetCache.upHours
//     property int upMins: widgetCache.upMins

//     property real sysVolume: widgetCache.sysVolume
//     property bool sysMuted: widgetCache.sysMuted
//     property real sysBrightness: widgetCache.sysBrightness
    
//     property string currentUserName: widgetCache.currentUserName

//     property bool dndEnabled: false

//     // Anti-Jitter Sync States
//     property bool isDraggingVol: false
//     property bool isDraggingBri: false

//     Timer { id: volSyncDelay; interval: 800; onTriggered: window.isDraggingVol = false; triggeredOnStart: true; }
//     Timer { id: briSyncDelay; interval: 800; onTriggered: window.isDraggingBri = false; triggeredOnStart: true; }

//     // Unified hue for Performance Profile
//     readonly property color profileStart: {
//         if (powerProfile === "performance") return window.red;
//         if (powerProfile === "power-saver") return window.green;
//         return window.blue;
//     }
//     readonly property color profileEnd: Qt.lighter(profileStart, 1.15)

//     // Ambient Blobs - Static for Desktop version
//     readonly property color ambientPrimary: window.mauve
//     readonly property color ambientSecondary: window.blue

//     // --- INIT DND STATE FROM CACHE ---
//     Process {
//         id: dndInit
//         running: true
//         command: ["bash", "-c", "mkdir -p ~/.cache && cat ~/.cache/qs_dnd 2>/dev/null || echo '0'"]
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 window.dndEnabled = (this.text.trim() === "1");
//             }
//         }
//     }

//     Process {
//         id: userPoller
//         command: ["bash", "-c", "echo $USER"]
//         running: true
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 window.currentUserName = this.text.trim();
//                 widgetCache.currentUserName = window.currentUserName;
//             }
//         }
//     }

//     Process {
//         id: sysPoller
//         // HIGHLY ROBUST BASH COMMANDS
//         command: ["bash", "-c", 
//             "vmstat 1 2 | tail -1 | awk '{print 100 - $15}' || echo '0'; " +
//             "free -m | awk '/Mem:/ {print int($3/$2 * 100)}' || echo '0'; " +
//             "df -h / | awk 'NR==2 {print $5}' | tr -d '%' || echo '0'; " +
//             "temp=$(sensors 2>/dev/null | grep -m 1 -E 'Package id 0|Tctl|Tdie|edge|temp1' | grep -oE '\\+[0-9]+\\.[0-9]+' | head -n 1 | tr -d '+' | cut -d. -f1); [ -z \"$temp\" ] && temp=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -n 1 | awk '{print int($1/1000)}'); echo \"${temp:-0}\"; " +
//             "powerprofilesctl get 2>/dev/null || echo 'balanced'; " +
//             "awk '{print int($1/3600)\"h \"int(($1%3600)/60)\"m\"}' /proc/uptime 2>/dev/null || echo '0h 0m'; " +
//             "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100), ($3==\"[MUTED]\"?\"off\":\"on\")}' || echo '0 on'; " +
//             "brightnessctl -m 2>/dev/null | awk -F, '{print substr($4, 1, length($4)-1)}' || echo '0'"
//         ]
//         running: true
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 let lines = this.text.trim().split("\n");
//                 if (lines.length >= 8) {
//                     window.cpuUsage = parseInt(lines[0]) || 0;
//                     widgetCache.cpuUsage = window.cpuUsage;

//                     window.ramUsage = parseInt(lines[1]) || 0;
//                     widgetCache.ramUsage = window.ramUsage;

//                     window.diskUsage = parseInt(lines[2]) || 0;
//                     widgetCache.diskUsage = window.diskUsage;

//                     window.sysTemp = parseInt(lines[3]) || 0;
//                     widgetCache.sysTemp = window.sysTemp;
                    
//                     window.powerProfile = lines[4];
//                     widgetCache.powerProfile = window.powerProfile;
                    
//                     let upParts = lines[5].split("h ");
//                     if (upParts.length === 2) {
//                         window.upHours = parseInt(upParts[0]) || 0;
//                         widgetCache.upHours = window.upHours;
//                         window.upMins = parseInt(upParts[1].replace("m", "")) || 0;
//                         widgetCache.upMins = window.upMins;
//                     }

//                     if (!window.isDraggingVol) {
//                         let volParts = (lines[6] || "0 on").trim().split(" ");
//                         window.sysVolume = parseInt(volParts[0]) || 0;
//                         widgetCache.sysVolume = window.sysVolume;
//                         window.sysMuted = (volParts[1] === "off");
//                         widgetCache.sysMuted = window.sysMuted;
//                     }
                    
//                     if (!window.isDraggingBri) {
//                         window.sysBrightness = parseInt(lines[7]) || 0;
//                         widgetCache.sysBrightness = window.sysBrightness;
//                     }
//                 }
//             }
//         }
//     }

//     Timer {
//         interval: 1500; running: true; repeat: true; triggeredOnStart: true;
//         onTriggered: sysPoller.running = true
//     }

//     property real globalOrbitAngle: 0
//     NumberAnimation on globalOrbitAngle {
//         from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
//     }

//     // --- ENHANCED STARTUP ANIMATION STATES ---
//     property real introMain: 0
//     property real introTop: 0
//     property real introNotifs: 0
//     property real introCore: 0
//     property real introSliders: 0
//     property real introActions: 0
//     property real introProfiles: 0

//     ParallelAnimation {
//         running: true

//         // Base window fades, scales, and lifts
//         NumberAnimation { target: window; property: "introMain"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutQuart }

//         // Top bar drops in
//         SequentialAnimation {
//             PauseAnimation { duration: 100 }
//             NumberAnimation { target: window; property: "introTop"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.0 }
//         }

//         // Notification List cascades in smoothly
//         SequentialAnimation {
//             PauseAnimation { duration: 150 }
//             NumberAnimation { target: window; property: "introNotifs"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuart }
//         }

//         // Central core pops out and breathes
//         SequentialAnimation {
//             PauseAnimation { duration: 250 }
//             NumberAnimation { target: window; property: "introCore"; from: 0; to: 1.0; duration: 900; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
//         }

//         // Hardware sliders slide up
//         SequentialAnimation {
//             PauseAnimation { duration: 350 }
//             NumberAnimation { target: window; property: "introSliders"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutQuart }
//         }

//         // Actions waterfall
//         SequentialAnimation {
//             PauseAnimation { duration: 450 }
//             NumberAnimation { target: window; property: "introActions"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutExpo }
//         }

//         // Power profiles finish the wave
//         SequentialAnimation {
//             PauseAnimation { duration: 550 }
//             NumberAnimation { target: window; property: "introProfiles"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutBack; easing.overshoot: 0.8 }
//         }
//     }

//     ParallelAnimation {
//         id: exitAnim
//         NumberAnimation { target: window; property: "introMain"; to: 0; duration: 400; easing.type: Easing.InQuart }
//         NumberAnimation { target: window; property: "introTop"; to: 0; duration: 300; easing.type: Easing.InQuart }
//         NumberAnimation { target: window; property: "introNotifs"; to: 0; duration: 300; easing.type: Easing.InQuart }
//         NumberAnimation { target: window; property: "introCore"; to: 0; duration: 350; easing.type: Easing.InQuart }
//         NumberAnimation { target: window; property: "introSliders"; to: 0; duration: 250; easing.type: Easing.InQuart }
//         NumberAnimation { target: window; property: "introActions"; to: 0; duration: 200; easing.type: Easing.InQuart }
//         NumberAnimation { target: window; property: "introProfiles"; to: 0; duration: 150; easing.type: Easing.InQuart }
//     }

//     // -------------------------------------------------------------------------
//     // UI LAYOUT
//     // -------------------------------------------------------------------------
//     Item {
//         anchors.fill: parent
//         scale: 0.92 + (0.08 * introMain)
//         opacity: introMain
//         transform: Translate { y: window.s(15) * (1 - introMain) }

//         // Unified Outer Background
//         Rectangle {
//             anchors.fill: parent
//             radius: window.s(20)
//             color: window.base
//             border.color: window.surface0 
//             border.width: 1
//             clip: true

//             // Rotating Background Blobs - Spanning across the whole widget natively
//             Rectangle {
//                 width: parent.width * 0.8; height: width; radius: width / 2
//                 x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)
//                 y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)
//                 opacity: 0.08
//                 color: window.ambientPrimary
//                 Behavior on color { ColorAnimation { duration: 1000 } }
//             }
            
//             Rectangle {
//                 width: parent.width * 0.9; height: width; radius: width / 2
//                 x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)
//                 y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)
//                 opacity: 0.06
//                 color: window.ambientSecondary
//                 Behavior on color { ColorAnimation { duration: 1000 } }
//             }

//             RowLayout {
//                 anchors.fill: parent
//                 spacing: window.s(15) // Seamless separation instead of a line

//                 // ==========================================
//                 // LEFT SIDE: NOTIFICATION CENTER
//                 // ==========================================
//                 Item {
//                     Layout.preferredWidth: window.s(320)
//                     Layout.fillHeight: true

//                     ColumnLayout {
//                         anchors.fill: parent
//                         anchors.margins: window.s(20)
//                         spacing: window.s(15)

//                         // --- Notification Header & DND Toggle ---
//                         RowLayout {
//                             Layout.fillWidth: true
//                             Layout.preferredHeight: window.s(38)
//                             spacing: window.s(12)
                            
//                             transform: Translate { y: window.s(-20) * (1.0 - introTop) }
//                             opacity: introTop

//                             Text {
//                                 text: "Notifications"
//                                 font.family: "JetBrains Mono"
//                                 font.weight: Font.Black
//                                 font.pixelSize: window.s(18)
//                                 color: window.text
//                             }

//                             Item { Layout.fillWidth: true } // Spacer

//                             // DND Toggle Button
//                             Rectangle {
//                                 Layout.preferredWidth: dndMa.containsMouse ? window.s(38) + dndText.implicitWidth + window.s(8) : window.s(38)
//                                 Layout.preferredHeight: window.s(38)
//                                 radius: window.s(12)
//                                 color: window.dndEnabled ? Qt.alpha(window.red, 0.15) : (dndMa.containsMouse ? window.surface1 : "transparent")
//                                 border.color: window.dndEnabled ? window.red : (dndMa.containsMouse ? window.surface2 : "transparent")
//                                 border.width: 1
//                                 clip: true

//                                 Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
//                                 Behavior on color { ColorAnimation { duration: 150 } }
//                                 Behavior on border.color { ColorAnimation { duration: 150 } }

//                                 Row {
//                                     anchors.right: parent.right
//                                     anchors.rightMargin: window.s(10)
//                                     anchors.verticalCenter: parent.verticalCenter
//                                     spacing: window.s(8)

//                                     Text {
//                                         id: dndText
//                                         text: window.dndEnabled ? "Silent" : "Mute"
//                                         font.family: "JetBrains Mono"
//                                         font.weight: Font.Bold
//                                         font.pixelSize: window.s(13)
//                                         color: window.dndEnabled ? window.red : window.text
//                                         anchors.verticalCenter: parent.verticalCenter
//                                         opacity: dndMa.containsMouse ? 1.0 : 0.0
//                                         Behavior on opacity { NumberAnimation { duration: 250 } }
//                                     }

//                                     Text {
//                                         font.family: "Iosevka Nerd Font"
//                                         font.pixelSize: window.s(18)
//                                         color: window.dndEnabled ? window.red : (dndMa.containsMouse ? window.text : window.overlay0)
//                                         text: window.dndEnabled ? "󰂛" : "󰂚"
//                                         anchors.verticalCenter: parent.verticalCenter
//                                         Behavior on color { ColorAnimation { duration: 150 } }
//                                     }
//                                 }

//                                 MouseArea {
//                                     id: dndMa
//                                     anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                                     onClicked: {
//                                         window.dndEnabled = !window.dndEnabled;
//                                         Quickshell.execDetached(["sh", "-c", "mkdir -p ~/.cache && echo '" + (window.dndEnabled ? "1" : "0") + "' > ~/.cache/qs_dnd"]);
//                                     }
//                                 }
//                             }
//                         }

//                         // --- Zero State ---
//                         Text {
//                             Layout.fillWidth: true
//                             Layout.fillHeight: true
//                             horizontalAlignment: Text.AlignHCenter
//                             verticalAlignment: Text.AlignVCenter
//                             font.family: "JetBrains Mono"
//                             font.weight: Font.Medium
//                             font.pixelSize: window.s(14)
//                             color: window.overlay0
//                             text: "You're all caught up."
//                             visible: !notifModel || notifModel.count === 0
//                             opacity: introNotifs
//                         }

//                         // --- Notification List ---
//                         ListView {
//                             id: notifList
//                             Layout.fillWidth: true
//                             Layout.fillHeight: true
//                             model: window.notifModel
//                             spacing: window.s(8)
//                             clip: true
                            
//                             opacity: introNotifs
//                             transform: Translate { y: window.s(20) * (1 - introNotifs) }

//                             ScrollBar.vertical: ScrollBar {
//                                 active: notifList.moving || notifList.movingVertically
//                                 width: window.s(4)
//                                 policy: ScrollBar.AsNeeded
//                                 contentItem: Rectangle { implicitWidth: window.s(4); radius: window.s(2); color: window.surface2 }
//                             }

//                             // Fluid Animations
//                             add: Transition {
//                                 ParallelAnimation {
//                                     NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 400; easing.type: Easing.OutQuint }
//                                     NumberAnimation { property: "x"; from: window.s(-40); to: 0; duration: 500; easing.type: Easing.OutExpo }
//                                     NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: 500; easing.type: Easing.OutBack }
//                                 }
//                             }
//                             remove: Transition {
//                                 ParallelAnimation {
//                                     NumberAnimation { property: "opacity"; to: 0.0; duration: 300; easing.type: Easing.OutQuint }
//                                     NumberAnimation { property: "scale"; to: 0.9; duration: 300; easing.type: Easing.OutQuint }
//                                 }
//                             }
//                             displaced: Transition {
//                                 NumberAnimation { properties: "y"; duration: 400; easing.type: Easing.OutExpo }
//                             }

//                             // --- Grouping Configuration ---
//                             section.property: "appName"
//                             section.criteria: ViewSection.FullString
//                             section.delegate: Item {
//                                 width: ListView.view.width
//                                 height: window.s(46)
                                
//                                 Rectangle {
//                                     anchors.fill: parent
//                                     anchors.topMargin: window.s(10)
//                                     anchors.bottomMargin: window.s(4)
//                                     color: headerMa.containsMouse ? window.surface1 : "transparent"
//                                     radius: window.s(8)
//                                     Behavior on color { ColorAnimation { duration: 150 } }

//                                     RowLayout {
//                                         anchors.fill: parent
//                                         anchors.leftMargin: window.s(6)
//                                         anchors.rightMargin: window.s(6)
//                                         spacing: window.s(8)

//                                         // Clickable Area for Collapse Toggle
//                                         MouseArea {
//                                             id: headerMa
//                                             Layout.fillWidth: true
//                                             Layout.fillHeight: true
//                                             hoverEnabled: true
//                                             cursorShape: Qt.PointingHandCursor
//                                             onClicked: window.toggleGroup(section)

//                                             RowLayout {
//                                                 anchors.fill: parent
//                                                 spacing: window.s(8)
                                                
//                                                 Text {
//                                                     font.family: "Iosevka Nerd Font"
//                                                     font.pixelSize: window.s(14)
//                                                     color: window.mauve
//                                                     text: window.isCollapsed(section) ? "󰅂" : "󰅀"
//                                                     Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
//                                                 }

//                                                 Text {
//                                                     text: section.toUpperCase()
//                                                     font.family: "JetBrains Mono"
//                                                     font.weight: Font.Black
//                                                     font.pixelSize: window.s(11)
//                                                     color: window.text
//                                                     Layout.fillWidth: true
//                                                     verticalAlignment: Text.AlignVCenter
//                                                 }
//                                             }
//                                         }

//                                         // Clear Group Button
//                                         Rectangle {
//                                             Layout.preferredWidth: window.s(26)
//                                             Layout.preferredHeight: window.s(26)
//                                             radius: window.s(13)
//                                             color: groupClearMa.containsMouse ? window.surface2 : "transparent"
//                                             Behavior on color { ColorAnimation { duration: 150 } }

//                                             Text {
//                                                 anchors.centerIn: parent
//                                                 font.family: "Iosevka Nerd Font"
//                                                 font.pixelSize: window.s(14)
//                                                 color: groupClearMa.containsMouse ? window.red : window.overlay0
//                                                 text: "󰅖"
//                                                 Behavior on color { ColorAnimation { duration: 150 } }
//                                             }

//                                             MouseArea {
//                                                 id: groupClearMa
//                                                 anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                                                 onClicked: window.clearGroup(section)
//                                             }
//                                         }
//                                     }
//                                 }
//                             }

//                             // --- Individual Notification Card ---
//                             delegate: Item {
//                                 id: delegateWrapper
//                                 width: ListView.view.width
//                                 property bool isHidden: window.isCollapsed(model.appName)
//                                 height: isHidden ? 0 : innerCard.height
//                                 visible: height > 0
//                                 opacity: isHidden ? 0 : 1
//                                 clip: true
                                
//                                 Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
//                                 Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }

//                                 Rectangle {
//                                     id: innerCard
//                                     width: parent.width
//                                     height: cardContent.height + window.s(24)
//                                     radius: window.s(14)
//                                     color: cardHover.containsMouse ? window.surface1 : window.surface0
//                                     border.color: cardHover.containsMouse ? window.surface2 : "transparent"
//                                     border.width: 1
//                                     clip: true
//                                     Behavior on color { ColorAnimation { duration: 200 } }
//                                     Behavior on border.color { ColorAnimation { duration: 200 } }

//                                     MouseArea {
//                                         id: cardHover
//                                         anchors.fill: parent
//                                         hoverEnabled: true
//                                     }

//                                     // Left side accent stripe
//                                     Rectangle {
//                                         width: window.s(4)
//                                         height: parent.height
//                                         anchors.left: parent.left
//                                         color: window.ambientPrimary
//                                     }

//                                     ColumnLayout {
//                                         id: cardContent
//                                         anchors.left: parent.left
//                                         anchors.right: parent.right
//                                         anchors.top: parent.top
//                                         anchors.margins: window.s(14)
//                                         anchors.leftMargin: window.s(18) // make room for the accent stripe
//                                         spacing: window.s(6)

//                                         RowLayout {
//                                             Layout.fillWidth: true
//                                             spacing: window.s(8)

//                                             Text {
//                                                 text: model.summary || "Notification"
//                                                 font.family: "JetBrains Mono"
//                                                 font.weight: Font.Bold
//                                                 font.pixelSize: window.s(13)
//                                                 color: window.text
//                                                 Layout.fillWidth: true
//                                                 wrapMode: Text.Wrap
//                                             }

//                                             // Individual Dismiss Button
//                                             Rectangle {
//                                                 Layout.preferredWidth: window.s(22)
//                                                 Layout.preferredHeight: window.s(22)
//                                                 radius: window.s(11)
//                                                 color: itemClearMa.containsMouse ? Qt.alpha(window.red, 0.15) : "transparent"
//                                                 Behavior on color { ColorAnimation { duration: 150 } }

//                                                 Text {
//                                                     anchors.centerIn: parent
//                                                     font.family: "Iosevka Nerd Font"
//                                                     font.pixelSize: window.s(12)
//                                                     color: itemClearMa.containsMouse ? window.red : window.overlay0
//                                                     text: "󰅖"
//                                                     Behavior on color { ColorAnimation { duration: 150 } }
//                                                 }

//                                                 MouseArea {
//                                                     id: itemClearMa
//                                                     anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                                                     onClicked: {
//                                                         if(window.notifModel) window.notifModel.remove(index);
//                                                     }
//                                                 }
//                                             }
//                                         }

//                                         Text {
//                                             text: model.body || ""
//                                             font.family: "JetBrains Mono"
//                                             font.weight: Font.Medium
//                                             font.pixelSize: window.s(11)
//                                             color: window.subtext0
//                                             Layout.fillWidth: true
//                                             wrapMode: Text.Wrap
//                                             visible: text !== ""
//                                             textFormat: Text.PlainText 
//                                         }
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }

//                 // ==========================================
//                 // RIGHT SIDE: SYSTEM RESOURCES CORE
//                 // ==========================================
//                 Item {
//                     Layout.preferredWidth: window.s(480)
//                     Layout.fillHeight: true

//                     // Radar Rings
//                     Item {
//                         id: radarItem
//                         anchors.fill: parent
                        
//                         Repeater {
//                             model: 3
//                             Rectangle {
//                                 anchors.centerIn: parent
//                                 anchors.verticalCenterOffset: window.s(-70)
//                                 width: window.s(320) + (index * window.s(170))
//                                 height: width
//                                 radius: width / 2
//                                 color: "transparent"
//                                 border.color: window.ambientSecondary
//                                 border.width: 1
//                                 Behavior on border.color { ColorAnimation { duration: 1000 } }
//                                 opacity: 0.06 - (index * 0.02)
//                             }
//                         }
//                     }

//                     // ==========================================
//                     // TOP: UPTIME COMPONENT
//                     // ==========================================
//                     Row {
//                         id: uptimeRow
//                         anchors.top: parent.top
//                         anchors.left: parent.left
//                         anchors.margins: window.s(25)
//                         spacing: window.s(6)
//                         z: 10
                        
//                         transform: Translate { y: window.s(-20) * (1.0 - introTop) }
//                         opacity: introTop
                        
//                         // Hours Box
//                         Rectangle {
//                             width: window.s(44); height: window.s(48); radius: window.s(10)
//                             color: window.surface0; border.color: window.surface1; border.width: 1
                            
//                             Rectangle { anchors.fill: parent; radius: window.s(10); color: window.ambientPrimary; opacity: 0.05; Behavior on color { ColorAnimation { duration: 1000 } } }
//                             Column {
//                                 anchors.centerIn: parent
//                                 Text { 
//                                     text: window.upHours.toString().padStart(2, '0')
//                                     font.pixelSize: window.s(18); font.family: "JetBrains Mono"; font.weight: Font.Black
//                                     color: window.ambientPrimary
//                                     Behavior on color { ColorAnimation { duration: 1000 } }
//                                     anchors.horizontalCenter: parent.horizontalCenter 
//                                 }
//                                 Text { 
//                                     text: "HR"; font.pixelSize: window.s(8); font.family: "JetBrains Mono"; font.weight: Font.Bold
//                                     color: window.subtext0; anchors.horizontalCenter: parent.horizontalCenter 
//                                 }
//                             }
//                         }

//                         // Pulsing Colon
//                         Text {
//                             anchors.verticalCenter: parent.verticalCenter
//                             text: ":"
//                             font.pixelSize: window.s(22); font.family: "JetBrains Mono"; font.weight: Font.Black
//                             color: window.ambientPrimary
//                             Behavior on color { ColorAnimation { duration: 1000 } }
                            
//                             opacity: uptimePulse
//                             property real uptimePulse: 1.0
//                             SequentialAnimation on uptimePulse {
//                                 loops: Animation.Infinite; running: true
//                                 NumberAnimation { to: 0.2; duration: 800; easing.type: Easing.InOutSine }
//                                 NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
//                             }
//                         }

//                         // Mins Box
//                         Rectangle {
//                             width: window.s(44); height: window.s(48); radius: window.s(10)
//                             color: window.surface0; border.color: window.surface1; border.width: 1
                            
//                             Rectangle { anchors.fill: parent; radius: window.s(10); color: window.ambientSecondary; opacity: 0.05; Behavior on color { ColorAnimation { duration: 1000 } } }
//                             Column {
//                                 anchors.centerIn: parent
//                                 Text { 
//                                     text: window.upMins.toString().padStart(2, '0')
//                                     font.pixelSize: window.s(18); font.family: "JetBrains Mono"; font.weight: Font.Black
//                                     color: window.ambientSecondary
//                                     Behavior on color { ColorAnimation { duration: 1000 } }
//                                     anchors.horizontalCenter: parent.horizontalCenter 
//                                 }
//                                 Text { 
//                                     text: "MIN"; font.pixelSize: window.s(8); font.family: "JetBrains Mono"; font.weight: Font.Bold
//                                     color: window.subtext0; anchors.horizontalCenter: parent.horizontalCenter 
//                                 }
//                             }
//                         }
//                     }

//                     // Expanding top-right logout icon
//                     Rectangle {
//                         id: logoutBtn
//                         anchors.top: parent.top; anchors.right: parent.right
//                         anchors.margins: window.s(25)
//                         z: 10
//                         width: logoutMa.containsMouse ? window.s(44) + usernameText.implicitWidth + window.s(12) : window.s(44)
//                         height: window.s(44); radius: window.s(14)
//                         color: logoutMa.containsMouse ? window.surface1 : "transparent"
//                         border.color: logoutMa.containsMouse ? window.surface2 : "transparent"
//                         clip: true
                        
//                         transform: Translate { y: window.s(-20) * (1.0 - introTop) }
//                         opacity: introTop

//                         Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
//                         Behavior on color { ColorAnimation { duration: 150 } }
//                         Behavior on border.color { ColorAnimation { duration: 150 } }

//                         Row {
//                             anchors.right: parent.right
//                             anchors.rightMargin: window.s(13)
//                             anchors.verticalCenter: parent.verticalCenter
//                             spacing: window.s(12)

//                             Text {
//                                 id: usernameText
//                                 text: window.currentUserName
//                                 font.family: "JetBrains Mono"
//                                 font.weight: Font.Bold
//                                 font.pixelSize: window.s(14)
//                                 color: window.text
//                                 anchors.verticalCenter: parent.verticalCenter
//                                 opacity: logoutMa.containsMouse ? 1.0 : 0.0
//                                 Behavior on opacity { NumberAnimation { duration: 250 } }
//                             }

//                             Text {
//                                 font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18)
//                                 color: logoutMa.containsMouse ? window.red : window.overlay0
//                                 text: "󰍃"
//                                 anchors.verticalCenter: parent.verticalCenter
//                                 Behavior on color { ColorAnimation { duration: 150 } }
//                             }
//                         }

//                         MouseArea {
//                             id: logoutMa
//                             anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                             onClicked: { 
//                                 exitAnim.start(); // Trigger graceful UI exit
//                                 Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/exit.sh"]); 
//                                 Quickshell.execDetached(["sh", "-c", "echo 'close' > /tmp/qs_widget_state"]); 
//                             }
//                         }
//                     }

//                     // ==========================================
//                     // BIG SYSTEM RESOURCES GRID (DESKTOP)
//                     // ==========================================
//                     Grid {
//                         id: sysGrid
//                         columns: 2
//                         spacing: window.s(25)
//                         anchors.centerIn: parent
//                         anchors.verticalCenterOffset: window.s(-85) 
//                         z: 1

//                         opacity: introCore
//                         transform: Translate { y: window.s(25) * (1 - introCore) }
//                         scale: 0.9 + (0.1 * introCore)

//                         // 1. CPU Orb
//                         Item {
//                             id: cpuOrb; width: window.s(145); height: window.s(145)
//                             property real animVal: window.cpuUsage
//                             Behavior on animVal { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }
//                             onAnimValChanged: cpuCanvas.requestPaint()
                            
//                             scale: cpuMa.containsMouse ? 1.05 : 1.0
//                             Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

//                             // Individual Aura - Fixed Overlap
//                             Rectangle {
//                                 anchors.centerIn: parent
//                                 width: parent.width + (cpuMa.containsMouse ? window.s(16) : window.s(4)) 
//                                 height: width; radius: width / 2
//                                 color: window.blue
//                                 opacity: cpuMa.containsMouse ? 0.25 : 0.08
//                                 Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
//                                 Behavior on opacity { NumberAnimation { duration: 300 } }
//                             }

//                             Canvas {
//                                 id: cpuCanvas; anchors.fill: parent; rotation: 180
//                                 Connections { target: window; function onBaseChanged() { cpuCanvas.requestPaint() } }
//                                 onPaint: {
//                                     var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
//                                     var cX = width/2; var cY = height/2; var rad = (width/2)-window.s(8);
//                                     var eA = (Math.min(100, Math.max(0, parent.animVal)) / 100) * 2 * Math.PI;
//                                     ctx.lineCap = "round"; ctx.lineWidth = window.s(8); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, 2*Math.PI); 
//                                     ctx.strokeStyle = window.surface0.toString(); ctx.stroke();
//                                     var grad = ctx.createLinearGradient(0, height, width, 0); grad.addColorStop(0, window.blue.toString()); grad.addColorStop(1, window.sapphire.toString());
//                                     ctx.lineWidth = window.s(14); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, eA); ctx.strokeStyle = grad; ctx.stroke();
//                                 }
//                             }
//                             ColumnLayout {
//                                 anchors.centerIn: parent; spacing: 0
//                                 RowLayout {
//                                     Layout.alignment: Qt.AlignHCenter; spacing: window.s(4)
//                                     Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18); color: window.blue; text: "" }
//                                     Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(28); color: window.text; text: Math.round(cpuOrb.animVal) + "%" }
//                                 }
//                                 Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12); color: window.subtext0; text: "CPU LOAD" }
//                             }
//                             MouseArea { id: cpuMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
//                         }

//                         // 2. RAM Orb
//                         Item {
//                             id: ramOrb; width: window.s(145); height: window.s(145)
//                             property real animVal: window.ramUsage
//                             Behavior on animVal { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }
//                             onAnimValChanged: ramCanvas.requestPaint()

//                             scale: ramMa.containsMouse ? 1.05 : 1.0
//                             Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

//                             // Individual Aura - Fixed Overlap
//                             Rectangle {
//                                 anchors.centerIn: parent
//                                 width: parent.width + (ramMa.containsMouse ? window.s(16) : window.s(4))
//                                 height: width; radius: width / 2
//                                 color: window.mauve
//                                 opacity: ramMa.containsMouse ? 0.25 : 0.08
//                                 Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
//                                 Behavior on opacity { NumberAnimation { duration: 300 } }
//                             }

//                             Canvas {
//                                 id: ramCanvas; anchors.fill: parent; rotation: 180
//                                 Connections { target: window; function onBaseChanged() { ramCanvas.requestPaint() } }
//                                 onPaint: {
//                                     var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
//                                     var cX = width/2; var cY = height/2; var rad = (width/2)-window.s(8);
//                                     var eA = (Math.min(100, Math.max(0, parent.animVal)) / 100) * 2 * Math.PI;
//                                     ctx.lineCap = "round"; ctx.lineWidth = window.s(8); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, 2*Math.PI); 
//                                     ctx.strokeStyle = window.surface0.toString(); ctx.stroke();
//                                     var grad = ctx.createLinearGradient(0, height, width, 0); grad.addColorStop(0, window.mauve.toString()); grad.addColorStop(1, window.pink.toString());
//                                     ctx.lineWidth = window.s(14); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, eA); ctx.strokeStyle = grad; ctx.stroke();
//                                 }
//                             }
//                             ColumnLayout {
//                                 anchors.centerIn: parent; spacing: 0
//                                 RowLayout {
//                                     Layout.alignment: Qt.AlignHCenter; spacing: window.s(4)
//                                     Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18); color: window.mauve; text: "󰍛" }
//                                     Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(28); color: window.text; text: Math.round(ramOrb.animVal) + "%" }
//                                 }
//                                 Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12); color: window.subtext0; text: "MEMORY" }
//                             }
//                             MouseArea { id: ramMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
//                         }

//                         // 3. DISK Orb
//                         Item {
//                             id: diskOrb; width: window.s(145); height: window.s(145)
//                             property real animVal: window.diskUsage
//                             Behavior on animVal { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }
//                             onAnimValChanged: diskCanvas.requestPaint()

//                             scale: diskMa.containsMouse ? 1.05 : 1.0
//                             Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

//                             // Individual Aura - Fixed Overlap
//                             Rectangle {
//                                 anchors.centerIn: parent
//                                 width: parent.width + (diskMa.containsMouse ? window.s(16) : window.s(4))
//                                 height: width; radius: width / 2
//                                 color: window.peach
//                                 opacity: diskMa.containsMouse ? 0.25 : 0.08
//                                 Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
//                                 Behavior on opacity { NumberAnimation { duration: 300 } }
//                             }

//                             Canvas {
//                                 id: diskCanvas; anchors.fill: parent; rotation: 180
//                                 Connections { target: window; function onBaseChanged() { diskCanvas.requestPaint() } }
//                                 onPaint: {
//                                     var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
//                                     var cX = width/2; var cY = height/2; var rad = (width/2)-window.s(8);
//                                     var eA = (Math.min(100, Math.max(0, parent.animVal)) / 100) * 2 * Math.PI;
//                                     ctx.lineCap = "round"; ctx.lineWidth = window.s(8); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, 2*Math.PI); 
//                                     ctx.strokeStyle = window.surface0.toString(); ctx.stroke();
//                                     var grad = ctx.createLinearGradient(0, height, width, 0); grad.addColorStop(0, window.peach.toString()); grad.addColorStop(1, window.yellow.toString());
//                                     ctx.lineWidth = window.s(14); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, eA); ctx.strokeStyle = grad; ctx.stroke();
//                                 }
//                             }
//                             ColumnLayout {
//                                 anchors.centerIn: parent; spacing: 0
//                                 RowLayout {
//                                     Layout.alignment: Qt.AlignHCenter; spacing: window.s(4)
//                                     Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18); color: window.peach; text: "󰋊" }
//                                     Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(28); color: window.text; text: Math.round(diskOrb.animVal) + "%" }
//                                 }
//                                 Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12); color: window.subtext0; text: "STORAGE" }
//                             }
//                             MouseArea { id: diskMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
//                         }

//                         // 4. TEMP Orb
//                         Item {
//                             id: tempOrb; width: window.s(145); height: window.s(145)
//                             property real animVal: window.sysTemp
//                             Behavior on animVal { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }
//                             onAnimValChanged: tempCanvas.requestPaint()

//                             scale: tempMa.containsMouse ? 1.05 : 1.0
//                             Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

//                             // Individual Aura - Fixed Overlap
//                             Rectangle {
//                                 anchors.centerIn: parent
//                                 width: parent.width + (tempMa.containsMouse ? window.s(16) : window.s(4))
//                                 height: width; radius: width / 2
//                                 color: window.red
//                                 opacity: tempMa.containsMouse ? 0.25 : 0.08
//                                 Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
//                                 Behavior on opacity { NumberAnimation { duration: 300 } }
//                             }

//                             Canvas {
//                                 id: tempCanvas; anchors.fill: parent; rotation: 180
//                                 Connections { target: window; function onBaseChanged() { tempCanvas.requestPaint() } }
//                                 onPaint: {
//                                     var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
//                                     var cX = width/2; var cY = height/2; var rad = (width/2)-window.s(8);
//                                     var eA = (Math.min(100, Math.max(0, parent.animVal)) / 100) * 2 * Math.PI;
//                                     ctx.lineCap = "round"; ctx.lineWidth = window.s(8); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, 2*Math.PI); 
//                                     ctx.strokeStyle = window.surface0.toString(); ctx.stroke();
//                                     var grad = ctx.createLinearGradient(0, height, width, 0); grad.addColorStop(0, window.red.toString()); grad.addColorStop(1, window.maroon.toString());
//                                     ctx.lineWidth = window.s(14); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, eA); ctx.strokeStyle = grad; ctx.stroke();
//                                 }
//                             }
//                             ColumnLayout {
//                                 anchors.centerIn: parent; spacing: 0
//                                 RowLayout {
//                                     Layout.alignment: Qt.AlignHCenter; spacing: window.s(4)
//                                     Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18); color: window.red; text: "" }
//                                     Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(28); color: window.text; text: Math.round(tempOrb.animVal) + "°" }
//                                 }
//                                 Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12); color: window.subtext0; text: "SYSTEM TEMP" }
//                             }
//                             MouseArea { id: tempMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
//                         }
//                     }

//                     // ==========================================
//                     // BOTTOM DOCKS
//                     // ==========================================
//                     ColumnLayout {
//                         id: bottomDocks
//                         anchors.bottom: parent.bottom
//                         anchors.left: parent.left
//                         anchors.right: parent.right
//                         anchors.margins: window.s(25)
//                         spacing: window.s(15)

//                         // 1. HARDWARE CONTROLS DOCK (Sliders)
//                         Rectangle {
//                             Layout.fillWidth: true
//                             Layout.preferredHeight: window.s(96)
//                             radius: window.s(14)
//                             color: window.surface0
//                             border.color: window.surface1
//                             border.width: 1

//                             opacity: introSliders
//                             transform: Translate { y: window.s(20) * (1.0 - introSliders) }

//                             ColumnLayout {
//                                 anchors.fill: parent
//                                 anchors.margins: window.s(14)
//                                 spacing: window.s(12)

//                                 // Brightness Slider
//                                 RowLayout {
//                                     Layout.fillWidth: true
//                                     spacing: window.s(15)

//                                     Item {
//                                         Layout.preferredWidth: window.s(32)
//                                         Layout.preferredHeight: window.s(32)
//                                         Text {
//                                             anchors.centerIn: parent
//                                             text: window.sysBrightness > 66 ? "󰃠" : (window.sysBrightness > 33 ? "󰃟" : "󰃞")
//                                             font.family: "Iosevka Nerd Font"
//                                             font.pixelSize: window.s(22)
//                                             color: window.blue
//                                             Behavior on color { ColorAnimation { duration: 200 } }
//                                         }
//                                     }

//                                     Item {
//                                         Layout.fillWidth: true
//                                         height: window.s(18)
                                        
//                                         Timer {
//                                             id: briCmdThrottle
//                                             interval: 50
//                                             property int targetPct: -1
//                                             onTriggered: {
//                                                 if (targetPct >= 0) {
//                                                     Quickshell.execDetached(["brightnessctl", "set", targetPct + "%"]);
//                                                     targetPct = -1;
//                                                 }
//                                             }
//                                         }

//                                         Rectangle {
//                                             anchors.fill: parent
//                                             radius: window.s(9)
//                                             color: window.surface1
//                                             border.color: window.surface2
//                                             border.width: 1
//                                             clip: true

//                                             Rectangle {
//                                                 height: parent.height
//                                                 width: parent.width * (window.sysBrightness / 100)
//                                                 radius: window.s(9)
//                                                 opacity: briMa.containsMouse ? 1.0 : 0.85
//                                                 Behavior on opacity { NumberAnimation { duration: 200 } }
//                                                 Behavior on width { enabled: !window.isDraggingBri; NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }

//                                                 gradient: Gradient {
//                                                     orientation: Gradient.Horizontal
//                                                     GradientStop { position: 0.0; color: window.blue; Behavior on color { ColorAnimation { duration: 300 } } }
//                                                     GradientStop { position: 1.0; color: window.sapphire; Behavior on color { ColorAnimation { duration: 300 } } }
//                                                 }
//                                             }
//                                         }
//                                         MouseArea {
//                                             id: briMa
//                                             anchors.fill: parent
//                                             hoverEnabled: true
//                                             cursorShape: Qt.PointingHandCursor
//                                             onPressed: (mouse) => { briSyncDelay.stop(); window.isDraggingBri = true; updateBri(mouse.x); }
//                                             onPositionChanged: (mouse) => { if (pressed) updateBri(mouse.x); }
//                                             onReleased: { briSyncDelay.restart(); }
                                            
//                                             function updateBri(mx) {
//                                                 let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100)));
//                                                 window.sysBrightness = pct; 
//                                                 briCmdThrottle.targetPct = pct;
//                                                 if (!briCmdThrottle.running) briCmdThrottle.start();
//                                             }
//                                         }
//                                     }
//                                 }

//                                 // Volume Slider
//                                 RowLayout {
//                                     Layout.fillWidth: true
//                                     spacing: window.s(15)

//                                     Rectangle {
//                                         Layout.preferredWidth: window.s(32)
//                                         Layout.preferredHeight: window.s(32)
//                                         radius: window.s(16)
//                                         color: volIconMa.containsMouse ? window.surface1 : "transparent"
//                                         border.color: volIconMa.containsMouse ? window.profileStart : "transparent"
//                                         Behavior on color { ColorAnimation { duration: 150 } }
//                                         Behavior on border.color { ColorAnimation { duration: 150 } }

//                                         Text {
//                                             anchors.centerIn: parent
//                                             text: window.sysMuted || window.sysVolume === 0 ? "󰖁" : (window.sysVolume > 50 ? "󰕾" : "󰖀")
//                                             font.family: "Iosevka Nerd Font"
//                                             font.pixelSize: window.s(22)
//                                             color: window.sysMuted ? window.overlay0 : window.profileStart
//                                             Behavior on color { ColorAnimation { duration: 200 } }
//                                         }
//                                         MouseArea {
//                                             id: volIconMa
//                                             anchors.fill: parent
//                                             hoverEnabled: true
//                                             cursorShape: Qt.PointingHandCursor
//                                             onClicked: {
//                                                 volSyncDelay.stop();
//                                                 window.isDraggingVol = true; 
//                                                 window.sysMuted = !window.sysMuted;
//                                                 Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
//                                                 volSyncDelay.restart();
//                                             }
//                                         }
//                                     }

//                                     Item {
//                                         Layout.fillWidth: true
//                                         height: window.s(18)
                                        
//                                         Timer {
//                                             id: volCmdThrottle
//                                             interval: 50
//                                             property int targetPct: -1
//                                             onTriggered: {
//                                                 if (targetPct >= 0) {
//                                                     if (targetPct > 0 && window.sysMuted) {
//                                                         window.sysMuted = false;
//                                                         Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"]);
//                                                     }
//                                                     Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", targetPct + "%"]);
//                                                     targetPct = -1;
//                                                 }
//                                             }
//                                         }

//                                         Rectangle {
//                                             anchors.fill: parent
//                                             radius: window.s(9)
//                                             color: window.surface1
//                                             border.color: window.surface2
//                                             border.width: 1
//                                             clip: true

//                                             Rectangle {
//                                                 height: parent.height
//                                                 width: parent.width * (window.sysVolume / 100)
//                                                 radius: window.s(9)
//                                                 opacity: window.sysMuted ? 0.5 : (volMa.containsMouse ? 1.0 : 0.85)
//                                                 Behavior on opacity { NumberAnimation { duration: 200 } }
//                                                 Behavior on width { enabled: !window.isDraggingVol; NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }

//                                                 gradient: Gradient {
//                                                     orientation: Gradient.Horizontal
//                                                     GradientStop { position: 0.0; color: window.sysMuted ? window.surface2 : window.profileStart; Behavior on color { ColorAnimation { duration: 300 } } }
//                                                     GradientStop { position: 1.0; color: window.sysMuted ? Qt.lighter(window.surface2, 1.15) : window.profileEnd; Behavior on color { ColorAnimation { duration: 300 } } }
//                                                 }
//                                             }
//                                         }
//                                         MouseArea {
//                                             id: volMa
//                                             anchors.fill: parent
//                                             hoverEnabled: true
//                                             cursorShape: Qt.PointingHandCursor
//                                             onPressed: (mouse) => { volSyncDelay.stop(); window.isDraggingVol = true; updateVol(mouse.x); }
//                                             onPositionChanged: (mouse) => { if (pressed) updateVol(mouse.x); }
//                                             onReleased: { volSyncDelay.restart(); }
                                            
//                                             function updateVol(mx) {
//                                                 let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100)));
//                                                 window.sysVolume = pct;
//                                                 volCmdThrottle.targetPct = pct;
//                                                 if (!volCmdThrottle.running) volCmdThrottle.start();
//                                             }
//                                         }
//                                     }
//                                 }
//                             }
//                         }

//                         // 2. SYSTEM ACTIONS DOCK
//                         RowLayout {
//                             Layout.fillWidth: true
//                             Layout.preferredHeight: window.s(75)
//                             spacing: window.s(12)
                            
//                             Repeater {
//                                 model: ListModel {
//                                     ListElement { cmd: "bash ~/.config/hypr/scripts/lock.sh"; icon: ""; baseColor: "mauve"; weight: 1.0 }
//                                     ListElement { cmd: "bash ~/.config/hypr/scripts/lock.sh & systemctl suspend"; icon: "ᶻ 𝗓 𝗓"; baseColor: "blue"; weight: 1.0 }
//                                     ListElement { cmd: "systemctl reboot"; icon: "󰑓"; baseColor: "yellow"; weight: 2.5 }
//                                     ListElement { cmd: "systemctl poweroff -i"; icon: ""; baseColor: "red"; weight: 3.5 }
//                                 }
                                
//                                 delegate: Rectangle {
//                                     id: actionCapsule
//                                     Layout.fillWidth: true
//                                     Layout.fillHeight: true
//                                     radius: window.s(14)

//                                     opacity: introActions
//                                     transform: Translate { y: window.s(30) * (1.0 - introActions) + (index * window.s(12) * (1.0 - introActions)) }
                                    
//                                     property color c1: window[baseColor] || window.surface1
//                                     property color c2: Qt.lighter(c1, 1.2)

//                                     color: actionMa.containsMouse ? window.surface1 : window.surface0
//                                     border.color: actionMa.containsMouse ? c1 : window.surface2
//                                     border.width: actionMa.containsMouse ? 2 : 1
//                                     Behavior on color { ColorAnimation { duration: 200 } }
//                                     Behavior on border.color { ColorAnimation { duration: 200 } }
                                    
//                                     scale: actionMa.pressed ? (0.98 - (0.01 * weight)) : (actionMa.containsMouse ? 1.08 : 1.0)
//                                     Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }

//                                     property real fillLevel: 0.0
//                                     property bool triggered: false
//                                     property real flashOpacity: 0.0
                                    
//                                     Canvas {
//                                         id: actionWaveCanvas
//                                         anchors.fill: parent
                                        
//                                         property real wavePhase: 0.0
//                                         NumberAnimation on wavePhase {
//                                             running: actionCapsule.fillLevel > 0.0 && actionCapsule.fillLevel < 1.0
//                                             loops: Animation.Infinite
//                                             from: 0; to: Math.PI * 2; duration: 800
//                                         }
//                                         onWavePhaseChanged: requestPaint()
//                                         Connections { target: actionCapsule; function onFillLevelChanged() { actionWaveCanvas.requestPaint() } }
//                                         Connections { target: window; function onBaseChanged() { actionWaveCanvas.requestPaint() } }
                                        
//                                         onPaint: {
//                                             var ctx = getContext("2d");
//                                             ctx.clearRect(0, 0, width, height);
//                                             if (actionCapsule.fillLevel <= 0.001) return;
                                            
//                                             var r = window.s(14); 
//                                             var fillY = height * (1.0 - actionCapsule.fillLevel);
//                                             ctx.save();
//                                             ctx.beginPath();
//                                             ctx.moveTo(r, 0); ctx.lineTo(width - r, 0); ctx.arcTo(width, 0, width, r, r);
//                                             ctx.lineTo(width, height - r); ctx.arcTo(width, height, width - r, height, r);
//                                             ctx.lineTo(r, height); ctx.arcTo(0, height, 0, height - r, r);
//                                             ctx.lineTo(0, r); ctx.arcTo(0, 0, r, 0, r); ctx.closePath(); ctx.clip(); 
                                            
//                                             ctx.beginPath();
//                                             ctx.moveTo(0, fillY);
//                                             if (actionCapsule.fillLevel < 0.99) {
//                                                 var waveAmp = window.s(10) * Math.sin(actionCapsule.fillLevel * Math.PI); 
//                                                 var cp1y = fillY + Math.sin(wavePhase) * waveAmp;
//                                                 var cp2y = fillY + Math.cos(wavePhase + Math.PI) * waveAmp;
//                                                 ctx.bezierCurveTo(width * 0.33, cp2y, width * 0.66, cp1y, width, fillY);
//                                                 ctx.lineTo(width, height); ctx.lineTo(0, height);
//                                             } else {
//                                                 ctx.lineTo(width, 0); ctx.lineTo(width, height); ctx.lineTo(0, height);
//                                             }
//                                             ctx.closePath();
                                            
//                                             var grad = ctx.createLinearGradient(0, 0, 0, height);
//                                             grad.addColorStop(0, actionCapsule.c1.toString()); grad.addColorStop(1, actionCapsule.c2.toString());
//                                             ctx.fillStyle = grad; ctx.fill(); ctx.restore();
//                                         }
//                                     }

//                                     Rectangle {
//                                         anchors.fill: parent; radius: window.s(14); color: "#ffffff"
//                                         opacity: actionCapsule.flashOpacity
//                                         PropertyAnimation on opacity { id: cardFlashAnim; to: 0; duration: 500; easing.type: Easing.OutExpo }
//                                     }

//                                     Text { 
//                                         anchors.centerIn: parent
//                                         font.family: "Iosevka Nerd Font"
//                                         font.pixelSize: window.s(24)
//                                         color: actionMa.containsMouse ? window.text : window.subtext0
//                                         text: icon
//                                         Behavior on color { ColorAnimation { duration: 150 } }
//                                     }

//                                     Item {
//                                         anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
//                                         height: actionCapsule.height * actionCapsule.fillLevel
//                                         clip: true
                                        
//                                         Text { 
//                                             anchors.horizontalCenter: parent.horizontalCenter
//                                             y: (actionCapsule.height / 2) - (height / 2) - (actionCapsule.height - parent.height)
//                                             font.family: "Iosevka Nerd Font"
//                                             font.pixelSize: window.s(24)
//                                             color: window.crust
//                                             text: icon 
//                                         }
//                                     }

//                                     MouseArea {
//                                         id: actionMa
//                                         anchors.fill: parent
//                                         hoverEnabled: true
//                                         cursorShape: actionCapsule.triggered ? Qt.ArrowCursor : Qt.PointingHandCursor
                                        
//                                         onPressed: { 
//                                             if (!actionCapsule.triggered) { 
//                                                 drainAnim.stop(); 
//                                                 fillAnim.start(); 
//                                             }
//                                         }
//                                         onReleased: {
//                                             if (!actionCapsule.triggered && actionCapsule.fillLevel < 1.0) { 
//                                                 fillAnim.stop(); 
//                                                 drainAnim.start(); 
//                                             }
//                                         }
//                                     }

//                                     NumberAnimation {
//                                         id: fillAnim; target: actionCapsule; property: "fillLevel"; to: 1.0
//                                         duration: (550 * weight) * (1.0 - actionCapsule.fillLevel); easing.type: Easing.InSine
//                                         onFinished: {
//                                             actionCapsule.triggered = true; actionCapsule.flashOpacity = 0.6; cardFlashAnim.start();
//                                             exitAnim.start(); exitTimer.start();
//                                         }
//                                     }
                                    
//                                     NumberAnimation {
//                                         id: drainAnim; target: actionCapsule; property: "fillLevel"; to: 0.0
//                                         duration: 1500 * actionCapsule.fillLevel; easing.type: Easing.OutQuad
//                                     }

//                                     Timer {
//                                         id: exitTimer; interval: 500 
//                                         onTriggered: { Quickshell.execDetached(["sh", "-c", cmd]); Quickshell.execDetached(["sh", "-c", "echo 'close' > /tmp/qs_widget_state"]); }
//                                     }
//                                 }
//                             }
//                         }

//                         // 3. POWER PROFILES DOCK
//                         Rectangle {
//                             Layout.fillWidth: true
//                             Layout.preferredHeight: window.s(54)
//                             radius: window.s(14)
//                             color: window.surface0 
//                             border.color: window.surface1
//                             border.width: 1

//                             opacity: introProfiles
//                             transform: Translate { y: window.s(20) * (1.0 - introProfiles) }
                            
//                             Rectangle {
//                                 id: sliderPill
//                                 width: (parent.width - window.s(2)) / 3 
//                                 height: parent.height - window.s(2)
//                                 y: window.s(1)
//                                 radius: window.s(10)
//                                 x: {
//                                     if (window.powerProfile === "performance") return window.s(1);
//                                     if (window.powerProfile === "balanced") return width + window.s(1);
//                                     return (width * 2) + window.s(1);
//                                 }
                                
//                                 Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                                
//                                 gradient: Gradient {
//                                     orientation: Gradient.Horizontal
//                                     GradientStop { position: 0.0; color: window.profileStart; Behavior on color { ColorAnimation{duration:400} } }
//                                     GradientStop { position: 1.0; color: window.profileEnd; Behavior on color { ColorAnimation{duration:400} } }
//                                 }
//                             }

//                             RowLayout {
//                                 anchors.fill: parent
//                                 spacing: 0
                                
//                                 Repeater {
//                                     model: ListModel {
//                                         ListElement { name: "performance"; icon: "󰓅"; label: "Perform" } 
//                                         ListElement { name: "balanced"; icon: "󰗑"; label: "Balance" }   
//                                         ListElement { name: "power-saver"; icon: "󰌪"; label: "Saver" } 
//                                     }
                                    
//                                     delegate: Item {
//                                         Layout.fillWidth: true
//                                         Layout.fillHeight: true
                                        
//                                         RowLayout {
//                                             anchors.centerIn: parent
//                                             spacing: window.s(8)
//                                             Text {
//                                                 font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18)
//                                                 color: window.powerProfile === name ? window.crust : (profileMa.containsMouse ? window.text : window.subtext0)
//                                                 text: icon
//                                                 Behavior on color { ColorAnimation { duration: 200 } }
//                                             }
//                                             Text {
//                                                 font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(13)
//                                                 color: window.powerProfile === name ? window.crust : (profileMa.containsMouse ? window.text : window.subtext0)
//                                                 text: label
//                                                 Behavior on color { ColorAnimation { duration: 200 } }
//                                             }
//                                         }
                                        
//                                         MouseArea {
//                                             id: profileMa
//                                             anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                                             onClicked: { Quickshell.execDetached(["powerprofilesctl", "set", name]); sysPoller.running = true; }
//                                         }
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }
import QtQuick                                                                                               // Imports the core QtQuick module providing all basic QML types (Item, Rectangle, Text, animations, properties, etc.)
import QtQuick.Layouts                                                                                       // Imports layout components (RowLayout, ColumnLayout, Grid) for arranging UI elements in structured patterns
import QtQuick.Window                                                                                        // Imports window-related types giving access to Screen.width/Screen.height for responsive sizing based on physical display
import QtQuick.Controls                                                                                      // Imports interactive UI controls like ScrollBar, TextField, and other standard user input widgets
import QtCore                                                                                                // Imports QtCore module which provides Settings (QSettings wrapper) for persistent local data storage
import Quickshell                                                                                            // Imports the Quickshell shell framework providing desktop-environment integration (Process, execDetached, environment)
import Quickshell.Io                                                                                         // Imports Quickshell I/O module specifically for StdioCollector which captures standard output from running processes
import "../"                                                                                                 // Imports from parent directory to access shared sibling components like Scaler.qml and MatugenColors.qml

Item {                                                                                                       // Defines the root Item container - the fundamental building block that holds all other UI elements for this component
    id: window                                                                                               // Assigns the identifier "window" so any element anywhere in this file can reference the root item and its properties

    // --- RECEIVE THE DBUS LIST FROM MAIN.QML ---                                                            // Descriptive comment indicating this property receives notification data passed from the parent Main.qml
    property var notifModel                                                                                  // Declares a variant property that will hold a ListModel reference containing all active desktop notifications

    // State object for collapsible notification groups                                                       // Documents that collapsedGroups tracks which notification app groups the user has collapsed or expanded
    property var collapsedGroups: ({})                                                                       // Initializes an empty JavaScript object where keys are app name strings and values are boolean collapsed states

    function toggleGroup(groupName) {                                                                        // Defines a function to flip the collapsed/expanded state of notifications from a specific application group
        let temp = Object.assign({}, collapsedGroups);                                                       // Creates a shallow copy of the collapsedGroups object to trigger QML property change detection on reassignment
        temp[groupName] = !temp[groupName];                                                                  // Toggles the boolean value for the given group: if collapsed becomes expanded, if expanded becomes collapsed
        collapsedGroups = temp;                                                                              // Reassigns the entire object to the property, notifying QML bindings to update the UI accordingly
    }

    function isCollapsed(groupName) {                                                                        // Defines a function to check whether a specific application's notification group is currently collapsed
        return collapsedGroups[groupName] === true;                                                          // Returns true only if the group's value is strictly equal to true; undefined or false both return false
    }

    // Helper: Safely clear an entire group of notifications by AppName                                      // Documents this utility function for removing all notifications belonging to a specific application
    function clearGroup(appName) {                                                                           // Defines the clearGroup function taking an application name string as its parameter
        if (!notifModel) return;                                                                             // Guard clause: exits immediately if the notification model doesn't exist (null or undefined)
        for (let i = notifModel.count - 1; i >= 0; i--) {                                                    // Iterates backwards through the model to safely remove items while index positions are shifting
            if (notifModel.get(i).appName === appName) {                                                     // Checks if the notification at current index belongs to the specified application name
                notifModel.remove(i);                                                                        // Removes the matching notification from the model at the current index position
            }
        }
    }

    // --- Responsive Scaling Logic ---                                                                      // Marks the beginning of the scaling system that adapts UI sizes proportionally to screen resolution
    Scaler {                                                                                                 // Instantiates the Scaler component which calculates ratio-based scaling factors for consistent sizing across displays
        id: scaler                                                                                           // Gives this Scaler instance the id "scaler" allowing access to its scaling functions throughout the file
        // Uses the physical screen width so the popup scales synchronously with the TopBar                 // Documents that scaling is driven by actual screen width ensuring visual consistency with the top bar
        currentWidth: Screen.width                                                                           // Passes the physical screen width in pixels to the Scaler so it can compute appropriate size multipliers
    }
    
    // Helper function scoped to the root Item for easy access in deeply nested elements and Canvases        // Explains that this convenience wrapper function is available to all nested elements including Canvas handlers
    function s(val) {                                                                                        // Defines a JavaScript function named "s" that takes a design-pixel value as its input parameter
        return scaler.s(val);                                                                                // Calls the Scaler's internal scaling method and returns the properly scaled pixel value for the current screen
    }

    // -------------------------------------------------------------------------                               // Visual separator line for code organization and readability
    // COLORS (Dynamic Matugen Palette)                                                                     // Section header: declares all color properties populated from the Matugen material theme generator output
    // -------------------------------------------------------------------------                               // Visual separator line
    MatugenColors { id: _theme }                                                                             // Creates MatugenColors component instance that reads current matugen color scheme; accessible via "_theme" id
    readonly property color base: _theme.base                                                                // Exposes the darkest background color from theme as read-only property "base" - used for main backgrounds
    readonly property color mantle: _theme.mantle                                                            // Exposes mantle color - slightly lighter than base, used as secondary background surface in the palette
    readonly property color crust: _theme.crust                                                              // Exposes crust color - the darkest surface in the theme hierarchy, often used for highest contrast backgrounds
    readonly property color text: _theme.text                                                                // Exposes primary text color - main foreground color for all important text content throughout the interface
    readonly property color subtext0: _theme.subtext0                                                        // Exposes subtext0 - secondary dimmer text color for less prominent labels, descriptions, and supplementary text
    readonly property color overlay0: _theme.overlay0                                                        // Exposes overlay0 - an overlay/muted surface color often used for subtle UI element backgrounds
    readonly property color overlay1: _theme.overlay1                                                        // Exposes overlay1 - slightly lighter overlay color one step above overlay0 in the theme hierarchy
    readonly property color surface0: _theme.surface0                                                        // Exposes surface0 - the lowest elevated surface color, used for card backgrounds slightly above base
    readonly property color surface1: _theme.surface1                                                        // Exposes surface1 - medium elevated surface, commonly used for interactive element backgrounds and borders
    readonly property color surface2: _theme.surface2                                                        // Exposes surface2 - highest standard elevated surface, used for hover states and prominent container backgrounds
    
    readonly property color mauve: _theme.mauve                                                              // Exposes mauve accent color - soft purple tone used aesthetically throughout the interface as primary accent
    readonly property color pink: _theme.pink                                                                // Exposes pink accent color from the theme palette for decorative elements and visual variety
    readonly property color red: _theme.red                                                                  // Exposes red accent - used for errors, destructive actions, danger states, and critical warnings
    readonly property color maroon: _theme.maroon                                                            // Exposes maroon accent - deeper red variant for warning backgrounds and danger zone visual indicators
    readonly property color peach: _theme.peach                                                              // Exposes peach accent - warm orange tone for medium-level indicators and warm visual elements
    readonly property color yellow: _theme.yellow                                                            // Exposes yellow accent - warning color for attention-grabbing elements and caution states
    readonly property color green: _theme.green                                                              // Exposes green accent - success color used for positive states and safe conditions
    readonly property color teal: _theme.teal                                                                // Exposes teal accent - blue-green variant for additional visual variety in the interface palette
    readonly property color sapphire: _theme.sapphire                                                        // Exposes sapphire accent - deep blue variant for complementary accent colors alongside mauve
    readonly property color blue: _theme.blue                                                                // Exposes blue accent - standard blue from palette used for informational elements and balanced states

    // -------------------------------------------------------------------------                               // Visual separator line
    // CACHE (Eliminates startup delay visually)                                                             // Section header: Settings-based cache that provides instant initial values while system polling starts up
    // -------------------------------------------------------------------------                               // Visual separator line
    Settings {                                                                                               // Creates a Settings object that persists data to disk using QSettings, surviving application restarts
        id: widgetCache                                                                                      // Assigns id "widgetCache" so the cache can be read from and written to throughout the component
        category: "SystemMonitorCache"                                                                       // Groups all cached values under the "SystemMonitorCache" category in the settings file for organization
        property int cpuUsage: 0                                                                             // Cached CPU usage percentage - loaded from disk on startup for instant display before first poll
        property int ramUsage: 0                                                                             // Cached RAM usage percentage for immediate display of memory state from previous session
        property int diskUsage: 0                                                                            // Cached disk usage percentage for immediate display of storage state from previous session
        property int sysTemp: 0                                                                              // Cached system temperature in Celsius for instant temperature display before first sensor poll
        property string powerProfile: "balanced"                                                             // Cached power profile string with "balanced" as default if no previous value exists
        property int upHours: 0                                                                              // Cached uptime hours component for instant uptime display from previous session
        property int upMins: 0                                                                               // Cached uptime minutes component for instant uptime display from previous session
        property real sysVolume: 0                                                                           // Cached system volume percentage for instant volume slider display
        property bool sysMuted: false                                                                        // Cached mute state for instant mute indicator display
        property real sysBrightness: 0                                                                       // Cached screen brightness percentage for instant brightness slider display
        property string currentUserName: "User"                                                              // Cached username with "User" as default fallback if no previous value was stored
    }

    // -------------------------------------------------------------------------                               // Visual separator line
    // STATE & POLLING                                                                                       // Section header: contains all dynamic state variables initialized from cache and updated by system polling
    // -------------------------------------------------------------------------                               // Visual separator line
    property int cpuUsage: widgetCache.cpuUsage                                                              // CPU usage percentage property initialized from cached value for instant UI population
    property int ramUsage: widgetCache.ramUsage                                                              // RAM usage percentage property initialized from cached value
    property int diskUsage: widgetCache.diskUsage                                                            // Disk usage percentage property initialized from cached value
    property int sysTemp: widgetCache.sysTemp                                                                // System temperature property initialized from cached value for immediate display

    property string powerProfile: widgetCache.powerProfile                                                   // Power profile string initialized from cached value ("performance", "balanced", or "power-saver")
    
    property int upHours: widgetCache.upHours                                                                // Uptime hours initialized from cache for instant uptime display
    property int upMins: widgetCache.upMins                                                                  // Uptime minutes initialized from cache for instant uptime display

    property real sysVolume: widgetCache.sysVolume                                                           // System volume initialized from cached value for instant slider position
    property bool sysMuted: widgetCache.sysMuted                                                             // Mute state initialized from cached value
    property real sysBrightness: widgetCache.sysBrightness                                                   // Brightness initialized from cached value for instant slider position
    
    property string currentUserName: widgetCache.currentUserName                                             // Username initialized from cache with "User" fallback for instant display

    property bool dndEnabled: false                                                                          // Do Not Disturb mode toggle: when true notifications are suppressed, when false they display normally

    // Anti-Jitter Sync States                                                                               // Documents that these flags prevent external polling from overriding user's active slider manipulation
    property bool isDraggingVol: false                                                                       // Flag set to true when user is currently dragging the volume slider to prevent polling from overriding
    property bool isDraggingBri: false                                                                       // Flag set to true when user is currently dragging the brightness slider to prevent polling interference

    Timer { id: volSyncDelay; interval: 800; onTriggered: window.isDraggingVol = false; triggeredOnStart: true; } // Creates a timer: after 800ms of no volume dragging, clears the dragging flag to re-enable external sync
    Timer { id: briSyncDelay; interval: 800; onTriggered: window.isDraggingBri = false; triggeredOnStart: true; } // Creates a timer: after 800ms of no brightness dragging, clears the flag to resume normal polling updates

    // Unified hue for Performance Profile                                                                   // Documents that profile color changes based on active power management mode
    readonly property color profileStart: {                                                                  // Read-only property computing the power profile indicator gradient start color
        if (powerProfile === "performance") return window.red;                                               // Returns red for performance mode indicating high power consumption
        if (powerProfile === "power-saver") return window.green;                                             // Returns green for power-saver mode indicating energy efficient operation
        return window.blue;                                                                                  // Returns blue as default for balanced mode indicating normal power usage
    }
    readonly property color profileEnd: Qt.lighter(profileStart, 1.15)                                       // Creates lighter variant (15% lighter) of profileStart for gradient end stops and visual depth

    // Ambient Blobs - Static for Desktop version                                                            // Documents that for the desktop variant, blob colors are fixed aesthetic choices rather than battery-derived
    readonly property color ambientPrimary: window.mauve                                                     // Primary ambient blob color set to mauve for consistent purple aesthetic
    readonly property color ambientSecondary: window.blue                                                    // Secondary ambient blob color set to blue for complementary color harmony

    // --- INIT DND STATE FROM CACHE ---                                                                     // Section comment: reads previously saved Do Not Disturb preference from disk cache on startup
    Process {                                                                                                // Creates a Process object to execute a shell command and capture its output
        id: dndInit                                                                                          // Assigns id "dndInit" for potential reference to this initialization process
        running: true                                                                                        // Sets the process to start executing immediately when the QML component finishes loading
        command: ["bash", "-c", "mkdir -p ~/.cache && cat ~/.cache/qs_dnd 2>/dev/null || echo '0'"]          // Shell pipeline: creates .cache dir if missing, reads qs_dnd file, outputs "0" if file doesn't exist
        stdout: StdioCollector {                                                                             // Attaches a StdioCollector to capture everything the process writes to its standard output stream
            onStreamFinished: {                                                                              // Signal handler triggered when the process exits and all stdout data has been fully collected
                window.dndEnabled = (this.text.trim() === "1");                                              // Sets dndEnabled to true if the file contained exactly "1", false for any other value after trimming whitespace
            }
        }
    }

    Process {                                                                                                // Creates a second Process to retrieve the current user's login name
        id: userPoller                                                                                       // Assigns id "userPoller" for identification of this username-fetching process
        command: ["bash", "-c", "echo $USER"]                                                                // Simple shell command that prints the value of the USER environment variable to standard output
        running: true                                                                                        // Starts execution immediately on component load to populate the username display
        stdout: StdioCollector {                                                                             // Captures the process standard output for processing
            onStreamFinished: {                                                                              // Called when the echo command completes and output is fully received
                window.currentUserName = this.text.trim();                                                   // Sets the currentUserName property to the output text with leading/trailing whitespace removed
                widgetCache.currentUserName = window.currentUserName;                                        // Persists the username to the Settings cache so it survives application restarts
            }
        }
    }

    Process {                                                                                                // Creates the main system polling Process that gathers CPU, RAM, disk, temp, and other system state
        id: sysPoller                                                                                        // Assigns id "sysPoller" so the periodic timer can trigger re-execution of this process
        // HIGHLY ROBUST BASH COMMANDS                                                                       // Comment emphasizing the resilient shell commands with fallbacks for different hardware configurations
        command: ["bash", "-c",                                                                              // Executes a bash shell with a multi-command script string for gathering various system metrics
            "vmstat 1 2 | tail -1 | awk '{print 100 - $15}' || echo '0'; " +                                 // Samples CPU usage: runs vmstat twice (1sec interval), takes second sample, calculates 100-idle%, defaults to 0
            "free -m | awk '/Mem:/ {print int($3/$2 * 100)}' || echo '0'; " +                                // Calculates RAM usage: parses free output, divides used(Mem: col3) by total(Mem: col2), multiplies by 100
            "df -h / | awk 'NR==2 {print $5}' | tr -d '%' || echo '0'; " +                                   // Gets root disk usage: runs df, takes second line, extracts percentage field, strips % symbol, defaults to 0
            "temp=$(sensors 2>/dev/null | grep -m 1 -E 'Package id 0|Tctl|Tdie|edge|temp1' | grep -oE '\\+[0-9]+\\.[0-9]+' | head -n 1 | tr -d '+' | cut -d. -f1); [ -z \"$temp\" ] && temp=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -n 1 | awk '{print int($1/1000)}'); echo \"${temp:-0}\"; " + // Robust temp: tries lm-sensors with multiple CPU temp patterns, falls back to sysfs thermal zones, defaults to 0
            "powerprofilesctl get 2>/dev/null || echo 'balanced'; " +                                        // Queries power-profiles-daemon for current mode, defaults to 'balanced' if daemon unavailable
            "awk '{print int($1/3600)\"h \"int(($1%3600)/60)\"m\"}' /proc/uptime 2>/dev/null || echo '0h 0m'; " + // Parses /proc/uptime seconds into formatted "Xh Ym" string, defaults to "0h 0m" if unavailable
            "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100), ($3==\"[MUTED]\"?\"off\":\"on\")}' || echo '0 on'; " + // Queries PipeWire/WirePlumber for volume and mute state, defaults to "0 on"
            "brightnessctl -m 2>/dev/null | awk -F, '{print substr($4, 1, length($4)-1)}' || echo '0'"       // Gets brightness percentage from brightnessctl machine-readable output, strips trailing %, defaults to "0"
        ]
        running: true                                                                                        // Starts the polling process immediately when the component loads for initial data population
        stdout: StdioCollector {                                                                             // Captures all 8 lines of system state output for parsing
            onStreamFinished: {                                                                              // Triggered when the polling command completes and all output lines are available
                let lines = this.text.trim().split("\n");                                                    // Splits the multi-line output into an array of individual strings using newline as delimiter
                if (lines.length >= 8) {                                                                     // Validates that we received all 8 expected lines before attempting to process the data
                    window.cpuUsage = parseInt(lines[0]) || 0;                                               // Parses CPU usage from first line as integer, defaults to 0 on parse failure
                    widgetCache.cpuUsage = window.cpuUsage;                                                  // Persists CPU usage to Settings cache for next startup

                    window.ramUsage = parseInt(lines[1]) || 0;                                               // Parses RAM usage from second line
                    widgetCache.ramUsage = window.ramUsage;                                                  // Persists RAM usage to cache

                    window.diskUsage = parseInt(lines[2]) || 0;                                              // Parses disk usage from third line
                    widgetCache.diskUsage = window.diskUsage;                                                // Persists disk usage to cache

                    window.sysTemp = parseInt(lines[3]) || 0;                                                // Parses system temperature from fourth line
                    widgetCache.sysTemp = window.sysTemp;                                                    // Persists temperature to cache
                    
                    window.powerProfile = lines[4];                                                          // Sets power profile from fifth output line
                    widgetCache.powerProfile = window.powerProfile;                                          // Persists power profile to cache
                    
                    let upParts = lines[5].split("h ");                                                      // Splits the uptime string "Xh Ym" by "h " to separate hours from minutes
                    if (upParts.length === 2) {                                                              // Confirms the split produced exactly two parts (hours and minutes with trailing 'm')
                        window.upHours = parseInt(upParts[0]) || 0;                                          // Parses hours portion as integer, defaults to 0 if parsing fails
                        widgetCache.upHours = window.upHours;                                                // Persists uptime hours to cache
                        window.upMins = parseInt(upParts[1].replace("m", "")) || 0;                          // Removes trailing 'm' from minutes, parses as integer, defaults to 0
                        widgetCache.upMins = window.upMins;                                                  // Persists uptime minutes to cache
                    }

                    if (!window.isDraggingVol) {                                                             // Only updates volume from system if user is NOT currently dragging the volume slider
                        let volParts = (lines[6] || "0 on").trim().split(" ");                               // Splits volume line into two parts: percentage number and "on"/"off" mute state
                        window.sysVolume = parseInt(volParts[0]) || 0;                                       // Parses volume percentage from first part, defaults to 0
                        widgetCache.sysVolume = window.sysVolume;                                            // Persists volume to cache
                        window.sysMuted = (volParts[1] === "off");                                           // Sets mute flag to true if second part is "off" (muted), false if "on"
                        widgetCache.sysMuted = window.sysMuted;                                              // Persists mute state to cache
                    }
                    
                    if (!window.isDraggingBri) {                                                             // Only updates brightness from system if user is NOT currently dragging the brightness slider
                        window.sysBrightness = parseInt(lines[7]) || 0;                                      // Parses brightness percentage from eighth line, defaults to 0
                        widgetCache.sysBrightness = window.sysBrightness;                                    // Persists brightness to cache
                    }
                }
            }
        }
    }

    Timer {                                                                                                  // Creates a periodic Timer to refresh system state at regular intervals
        interval: 1500; running: true; repeat: true; triggeredOnStart: true;                                 // Fires every 1500ms (1.5 seconds), starts immediately, repeats forever, also triggers on start
        onTriggered: sysPoller.running = true                                                                // When timer fires, sets sysPoller to running=true which re-executes the polling command
    }

    property real globalOrbitAngle: 0                                                                        // Stores the current angle (in radians) for the continuously rotating background decorative blob animations
    NumberAnimation on globalOrbitAngle {                                                                    // Attaches a perpetual NumberAnimation directly to the globalOrbitAngle property
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true                  // Animates from 0 to 2π (full circle) over 90 seconds, loops infinitely, starts immediately on load
    }

    // --- ENHANCED STARTUP ANIMATION STATES ---                                                              // Section documents the staggered intro animation system using individual progress values per UI section
    property real introMain: 0                                                                               // Animation progress (0 to 1) for the main container - controls overall scale, opacity, and lift effect
    property real introTop: 0                                                                                // Animation progress for the top bar elements (notification header, uptime, logout button)
    property real introNotifs: 0                                                                             // Animation progress for the notification list section entrance
    property real introCore: 0                                                                               // Animation progress for the central system resource orbs grid entrance
    property real introSliders: 0                                                                            // Animation progress for the brightness and volume slider controls
    property real introActions: 0                                                                            // Animation progress for the system action buttons (lock, suspend, reboot, poweroff)
    property real introProfiles: 0                                                                           // Animation progress for the power profile selector at the very bottom

    ParallelAnimation {                                                                                      // Creates a ParallelAnimation that runs all intro animations simultaneously (but with staggered start delays)
        running: true                                                                                        // Set to automatically start playing the animation sequence when the component loads

        // Base window fades, scales, and lifts                                                              // Describes the main container's entrance animation behavior
        NumberAnimation { target: window; property: "introMain"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutQuart } // Animates introMain from 0 to 1 over 800ms with OutQuart deceleration - drives fade and scale

        // Top bar drops in                                                                                  // Describes the top section's staggered drop-in animation
        SequentialAnimation {                                                                                // Creates a sequential animation: first pause, then animate (creates the stagger delay)
            PauseAnimation { duration: 100 }                                                                 // Waits 100 milliseconds before starting the top bar animation for cascading effect
            NumberAnimation { target: window; property: "introTop"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.0 } // Animates with OutBack easing and 1.0 overshoot for bouncy landing
        }

        // Notification List cascades in smoothly                                                            // Describes notification section entrance
        SequentialAnimation {
            PauseAnimation { duration: 150 }                                                                 // 150ms delay from animation start before notifications begin their entrance
            NumberAnimation { target: window; property: "introNotifs"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuart } // Smooth 850ms fade-slide with OutQuart deceleration
        }

        // Central core pops out and breathes                                                                // Describes the system resource orbs entrance with dramatic pop effect
        SequentialAnimation {
            PauseAnimation { duration: 250 }                                                                 // 250ms delay before the central resource grid begins its animation
            NumberAnimation { target: window; property: "introCore"; from: 0; to: 1.0; duration: 900; easing.type: Easing.OutBack; easing.overshoot: 1.2 } // 900ms with 1.2 overshoot for dramatic pop-out effect
        }

        // Hardware sliders slide up                                                                         // Describes the volume/brightness slider entrance
        SequentialAnimation {
            PauseAnimation { duration: 350 }                                                                 // 350ms delay creating further stagger in the cascading entrance sequence
            NumberAnimation { target: window; property: "introSliders"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutQuart } // Smooth slide-up with OutQuart deceleration
        }

        // Actions waterfall                                                                                  // Describes the action buttons entrance cascading down like a waterfall
        SequentialAnimation {
            PauseAnimation { duration: 450 }                                                                 // 450ms delay before action buttons start their animation
            NumberAnimation { target: window; property: "introActions"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutExpo } // Expo easing for a snappy, responsive feel on button entrance
        }

        // Power profiles finish the wave                                                                    // Describes the final profile selector entrance completing the wave
        SequentialAnimation {
            PauseAnimation { duration: 550 }                                                                 // Longest delay of 550ms - profiles are the last element to appear in the cascade
            NumberAnimation { target: window; property: "introProfiles"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutBack; easing.overshoot: 0.8 } // Gentle bouncy entrance with 0.8 overshoot for polished finish
        }
    }

    ParallelAnimation {                                                                                      // Creates the exit animation that reverses all intro animations simultaneously for graceful closing
        id: exitAnim                                                                                         // Assigns id "exitAnim" so it can be started by calling exitAnim.start() from click handlers
        NumberAnimation { target: window; property: "introMain"; to: 0; duration: 400; easing.type: Easing.InQuart } // Fades/scales out the main container to 0 over 400ms with InQuart acceleration (reverse of intro)
        NumberAnimation { target: window; property: "introTop"; to: 0; duration: 300; easing.type: Easing.InQuart } // Animates top section out in 300ms
        NumberAnimation { target: window; property: "introNotifs"; to: 0; duration: 300; easing.type: Easing.InQuart } // Fades out notification list in 300ms
        NumberAnimation { target: window; property: "introCore"; to: 0; duration: 350; easing.type: Easing.InQuart } // Shrinks resource orbs out in 350ms
        NumberAnimation { target: window; property: "introSliders"; to: 0; duration: 250; easing.type: Easing.InQuart } // Slides sliders away in 250ms
        NumberAnimation { target: window; property: "introActions"; to: 0; duration: 200; easing.type: Easing.InQuart } // Fades action buttons out quickly in 200ms
        NumberAnimation { target: window; property: "introProfiles"; to: 0; duration: 150; easing.type: Easing.InQuart } // Fastest exit at 150ms for profile selector - items exit in reverse cascade speed
    }

    // -------------------------------------------------------------------------                               // Visual separator line
    // UI LAYOUT                                                                                             // Section header: marks the beginning of the actual visual user interface structure
    // -------------------------------------------------------------------------                               // Visual separator line
    Item {                                                                                                   // Creates a wrapper container Item that applies the intro animation transforms to the entire widget
        anchors.fill: parent                                                                                 // Makes this container fill the entire root item completely
        scale: 0.92 + (0.08 * introMain)                                                                     // Animates scale from 92% to 100% as introMain goes 0→1 - creates subtle zoom-in entrance effect
        opacity: introMain                                                                                   // Animates opacity from 0 (invisible) to 1 (fully visible) as introMain animates
        transform: Translate { y: window.s(15) * (1 - introMain) }                                           // Slides the widget upward from 15dp below to final position during intro - creates lift effect

        // Unified Outer Background                                                                           // Comment identifying the main background card of the entire popup widget
        Rectangle {                                                                                          // Creates the main background rectangle with rounded corners that contains all widget content
            anchors.fill: parent                                                                             // Fills the wrapper container completely edge to edge
            radius: window.s(20)                                                                             // Applies 20 scaled pixels border radius for rounded modern card appearance
            color: window.base                                                                               // Fills with the theme's base (darkest background) color
            border.color: window.surface0                                                                    // Adds a subtle 1px border using surface0 color for depth definition
            border.width: 1                                                                                  // Sets border thickness to exactly 1 pixel
            clip: true                                                                                       // Enables clipping so that child content cannot overflow outside the rounded rectangle boundaries

            // Rotating Background Blobs - Spanning across the whole widget natively                         // Documents these decorative circles that orbit continuously for visual ambiance
            Rectangle {                                                                                      // Creates the first ambient decorative blob - a large semi-transparent colored circle
                width: parent.width * 0.8; height: width; radius: width / 2                                  // Makes a circular shape: width is 80% of parent, height matches for square, radius half for circle
                x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)     // Calculates X position: centered horizontally plus cosine-based orbital offset at double speed, 150dp amplitude
                y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)  // Calculates Y position: centered vertically plus sine-based orbital offset at double speed, 100dp amplitude
                opacity: 0.08                                                                                // Sets very low opacity (8%) so the blob is subtle and doesn't distract from content
                color: window.ambientPrimary                                                                 // Colors the blob using the mauve ambient primary color for consistent aesthetics
                Behavior on color { ColorAnimation { duration: 1000 } }                                      // Smoothly transitions color over 1 second when theme changes cause color shifts
            }
            
            Rectangle {                                                                                      // Creates the second ambient blob with different size, speed, and color for visual variety
                width: parent.width * 0.9; height: width; radius: width / 2                                  // Slightly larger: 90% of parent width for variety in blob sizes
                x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150) // Orbits at 1.5x speed using sine (phase-shifted from first blob), negative amplitude for opposite movement
                y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100) // Complementary vertical orbit using cosine with negative amplitude for opposing trajectory
                opacity: 0.06                                                                                // Even more subtle at 6% opacity for depth layering effect
                color: window.ambientSecondary                                                               // Uses blue secondary ambient color for visual contrast with the first blob
                Behavior on color { ColorAnimation { duration: 1000 } }                                      // Smooth 1-second color transition matching the primary blob animation timing
            }

            RowLayout {                                                                                      // Creates the main horizontal layout dividing the widget into left (notifications) and right (system resources) panels
                anchors.fill: parent                                                                         // Stretches the row layout to fill the entire background rectangle
                spacing: window.s(15) // Seamless separation instead of a line                              // Sets 15dp spacing between left and right panels for clean visual separation without a divider line

                // ==========================================                                                 // Visual section divider for code organization
                // LEFT SIDE: NOTIFICATION CENTER                                                             // Section label: this is the notifications panel on the left half
                // ==========================================                                                 // Visual section divider
                Item {                                                                                       // Creates a container Item for the entire left panel (fixed width, full height)
                    Layout.preferredWidth: window.s(320)                                                     // Sets the left panel to a fixed width of 320 scaled pixels regardless of content
                    Layout.fillHeight: true                                                                  // Makes the left panel stretch vertically to fill the full available height

                    ColumnLayout {                                                                           // Creates a vertical column layout inside the left panel for header and notification list
                        anchors.fill: parent                                                                 // Fills the left panel container completely
                        anchors.margins: window.s(20)                                                        // Applies 20dp uniform margin padding around all sides of the content
                        spacing: window.s(15)                                                                // Sets 15dp vertical spacing between the header row and the notification list

                        // --- Notification Header & DND Toggle ---                                          // Identifies this as the notification title bar with Do Not Disturb toggle button
                        RowLayout {                                                                          // Creates a horizontal row layout for the "Notifications" title and DND toggle
                            Layout.fillWidth: true                                                           // Makes the header row stretch to fill the full available width
                            Layout.preferredHeight: window.s(38)                                             // Sets a fixed height of 38dp for the header row
                            spacing: window.s(12)                                                            // Sets 12dp horizontal spacing between the title text and the DND button
                            
                            transform: Translate { y: window.s(-20) * (1.0 - introTop) }                     // Slides the header down from 20dp above during intro animation creating drop-in effect
                            opacity: introTop                                                                // Fades the header opacity from 0 to 1 using the introTop animation progress

                            Text {                                                                           // Creates the "Notifications" title text element
                                text: "Notifications"                                                        // Sets the display text string
                                font.family: "JetBrains Mono"                                                // Uses JetBrains Mono monospace font for clean, modern developer-oriented typography
                                font.weight: Font.Black                                                      // Sets the heaviest font weight (Black=900) for maximum visual emphasis on the title
                                font.pixelSize: window.s(18)                                                 // Sets font size to 18 scaled pixels for clear readable header size
                                color: window.text                                                           // Colors the title with the theme's primary text color
                            }

                            Item { Layout.fillWidth: true } // Spacer                                        // Creates an empty flexible spacer item that pushes the DND button to the right edge

                            // DND Toggle Button                                                             // Identifies the Do Not Disturb toggle button component
                            Rectangle {                                                                      // Creates the DND button background rectangle with expandable width behavior
                                Layout.preferredWidth: dndMa.containsMouse ? window.s(38) + dndText.implicitWidth + window.s(8) : window.s(38) // Expands width on hover to reveal text label, collapses to icon-only square when not hovered
                                Layout.preferredHeight: window.s(38)                                         // Fixed height of 38dp matching the header row height
                                radius: window.s(12)                                                         // Applies 12dp corner radius for soft rounded pill/capsule appearance
                                color: window.dndEnabled ? Qt.alpha(window.red, 0.15) : (dndMa.containsMouse ? window.surface1 : "transparent") // Red tinted background when DND active, surface1 highlight on hover, transparent otherwise
                                border.color: window.dndEnabled ? window.red : (dndMa.containsMouse ? window.surface2 : "transparent") // Red border when active, surface2 on hover for definition, transparent normally
                                border.width: 1                                                              // 1 pixel border width
                                clip: true                                                                   // Clips the expanding text content so it doesn't show outside the rounded rectangle during width animation

                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } } // Smoothly animates width expansion/contraction over 300ms with OutQuint easing curve
                                Behavior on color { ColorAnimation { duration: 150 } }                        // Smooth 150ms background color transitions for hover and state changes
                                Behavior on border.color { ColorAnimation { duration: 150 } }                 // Smooth 150ms border color transitions matching background animation timing

                                Row {                                                                        // Creates a row inside the button to hold the text label (visible on hover) and icon
                                    anchors.right: parent.right                                              // Anchors the row to the right edge of the button so it expands leftward
                                    anchors.rightMargin: window.s(10)                                        // Adds 10dp margin from the right edge for internal padding
                                    anchors.verticalCenter: parent.verticalCenter                            // Vertically centers the row content within the button height
                                    spacing: window.s(8)                                                     // Sets 8dp spacing between the text label and the icon

                                    Text {                                                                   // Creates the DND status text label ("Silent" or "Mute")
                                        id: dndText                                                          // Assigns id "dndText" so the button width calculation can reference its implicitWidth
                                        text: window.dndEnabled ? "Silent" : "Mute"                           // Displays "Silent" when DND is enabled (notifications suppressed), "Mute" when disabled
                                        font.family: "JetBrains Mono"                                        // Uses JetBrains Mono monospace font for consistency
                                        font.weight: Font.Bold                                               // Bold weight for emphasis on the action label
                                        font.pixelSize: window.s(13)                                         // Sets font size to 13 scaled pixels
                                        color: window.dndEnabled ? window.red : window.text                   // Red text when DND active (warning color), normal text color otherwise
                                        anchors.verticalCenter: parent.verticalCenter                        // Vertically centers the text within the row
                                        opacity: dndMa.containsMouse ? 1.0 : 0.0                             // Text is only visible (opacity 1) when mouse hovers over the button, fully transparent otherwise
                                        Behavior on opacity { NumberAnimation { duration: 250 } }             // Smooth 250ms fade in/out transition for text appearance/disappearance
                                    }

                                    Text {                                                                   // Creates the bell icon using Nerd Font glyphs
                                        font.family: "Iosevka Nerd Font"                                     // Uses Iosevka Nerd Font which includes patched icon glyphs
                                        font.pixelSize: window.s(18)                                         // Sets icon size to 18 scaled pixels
                                        color: window.dndEnabled ? window.red : (dndMa.containsMouse ? window.text : window.overlay0) // Red when DND active, text color on hover, dim overlay0 when idle
                                        text: window.dndEnabled ? "󰂛" : "󰂚"                               // Shows bell-off icon when DND enabled, bell-on icon when disabled
                                        anchors.verticalCenter: parent.verticalCenter                        // Vertically centers the icon within the row
                                        Behavior on color { ColorAnimation { duration: 150 } }                // Smooth 150ms color transition for icon color changes
                                    }
                                }

                                MouseArea {                                                                  // Creates the interactive click area covering the entire DND button
                                    id: dndMa                                                                // Assigns id "dndMa" so other elements can reference its hover state (containsMouse)
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor // Fills the button, enables hover detection, changes cursor to pointing hand on hover
                                    onClicked: {                                                             // Defines what happens when the user clicks the DND button
                                        window.dndEnabled = !window.dndEnabled;                              // Toggles the DND state: switches between enabled and disabled
                                        Quickshell.execDetached(["sh", "-c", "mkdir -p ~/.cache && echo '" + (window.dndEnabled ? "1" : "0") + "' > ~/.cache/qs_dnd"]); // Persists the new DND state to disk cache file; writes "1" or "0"
                                    }
                                }
                            }
                        }

                        // --- Zero State ---                                                                 // Identifies the empty state display shown when no notifications exist
                        Text {                                                                               // Creates a centered placeholder text element for the empty notification list state
                            Layout.fillWidth: true                                                           // Allows the text to take full available width for horizontal centering
                            Layout.fillHeight: true                                                          // Allows the text to take full available height for vertical centering
                            horizontalAlignment: Text.AlignHCenter                                           // Centers the text horizontally within its layout area
                            verticalAlignment: Text.AlignVCenter                                             // Centers the text vertically within its layout area
                            font.family: "JetBrains Mono"                                                    // Uses JetBrains Mono monospace font family
                            font.weight: Font.Medium                                                         // Medium font weight (500) - less heavy than title, appropriate for placeholder text
                            font.pixelSize: window.s(14)                                                     // Sets font size to 14 scaled pixels
                            color: window.overlay0                                                           // Uses dim overlay0 color for subtle placeholder appearance
                            text: "You're all caught up."                                                     // Friendly message displayed when no notifications are present
                            visible: !notifModel || notifModel.count === 0                                   // Only visible when no notification model exists or the model has zero items
                            opacity: introNotifs                                                             // Fades in/out with the notification section intro animation progress
                        }

                        // --- Notification List ---                                                          // Identifies the scrollable list view containing individual notification cards
                        ListView {                                                                           // Creates a ListView for efficiently displaying potentially large numbers of notifications
                            id: notifList                                                                    // Assigns id "notifList" for referencing scroll behavior and other properties
                            Layout.fillWidth: true                                                           // Makes the list fill the full available width in the layout
                            Layout.fillHeight: true                                                          // Makes the list fill all remaining vertical space in the column
                            model: window.notifModel                                                         // Binds the ListView's data source to the notifModel passed from Main.qml
                            spacing: window.s(8)                                                             // Sets 8dp vertical spacing between individual notification cards
                            clip: true                                                                       // Enables clipping so scrolled-out notifications don't render outside the list bounds
                            
                            opacity: introNotifs                                                             // Fades the entire notification list opacity with the intro animation
                            transform: Translate { y: window.s(20) * (1 - introNotifs) }                      // Slides the list up from 20dp below during intro, creating smooth entrance motion

                            ScrollBar.vertical: ScrollBar {                                                  // Attaches a custom-styled vertical scrollbar to the notification list
                                active: notifList.moving || notifList.movingVertically                        // Shows scrollbar when the list is actively being scrolled by user interaction
                                width: window.s(4)                                                           // Makes a very thin 4dp wide scrollbar for minimal visual footprint
                                policy: ScrollBar.AsNeeded                                                   // Only displays the scrollbar when the notification content overflows the visible area
                                contentItem: Rectangle { implicitWidth: window.s(4); radius: window.s(2); color: window.surface2 } // Styles the scrollbar thumb as a thin rounded rectangle using surface2 color
                            }

                            // Fluid Animations                                                              // Identifies the smooth transition animations for notification items
                            add: Transition {                                                                // Defines the animation played when new notifications are added to the list
                                ParallelAnimation {                                                          // Groups multiple animations to run simultaneously for a cohesive entrance
                                    NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 400; easing.type: Easing.OutQuint } // Fades in from transparent to opaque over 400ms
                                    NumberAnimation { property: "x"; from: window.s(-40); to: 0; duration: 500; easing.type: Easing.OutExpo } // Slides in from 40dp to the left to final position over 500ms
                                    NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: 500; easing.type: Easing.OutBack } // Scales up slightly from 95% to 100% with OutBack overshoot for pop effect
                                }
                            }
                            remove: Transition {                                                             // Defines the animation when notifications are removed/dismissed
                                ParallelAnimation {                                                          // Groups fade and scale animations for smooth exit
                                    NumberAnimation { property: "opacity"; to: 0.0; duration: 300; easing.type: Easing.OutQuint } // Fades out to invisible over 300ms
                                    NumberAnimation { property: "scale"; to: 0.9; duration: 300; easing.type: Easing.OutQuint } // Shrinks to 90% size over 300ms for subtle collapse effect
                                }
                            }
                            displaced: Transition {                                                          // Defines animation for items that shift position due to additions/removals above them
                                NumberAnimation { properties: "y"; duration: 400; easing.type: Easing.OutExpo } // Smoothly slides items vertically to their new positions over 400ms
                            }

                            // --- Grouping Configuration ---                                                 // Section for notification grouping: notifications grouped by source application
                            section.property: "appName"                                                      // Tells the ListView to group notification items by their "appName" data property
                            section.criteria: ViewSection.FullString                                         // Uses exact full string matching for grouping (not just first character or prefix)
                            section.delegate: Item {                                                         // Defines the visual delegate for each group section header
                                width: ListView.view.width                                                   // Makes the section header full width of the list view
                                height: window.s(46)                                                         // Sets section header height to 46dp
                                
                                Rectangle {                                                                  // Background rectangle for the section header
                                    anchors.fill: parent                                                     // Fills the entire header area
                                    anchors.topMargin: window.s(10)                                           // Adds 10dp top margin for spacing from the list edge or previous group
                                    anchors.bottomMargin: window.s(4)                                         // Adds 4dp bottom margin for spacing before group items
                                    color: headerMa.containsMouse ? window.surface1 : "transparent"           // Highlights with surface1 color on hover, transparent otherwise
                                    radius: window.s(8)                                                      // Applies 8dp corner rounding
                                    Behavior on color { ColorAnimation { duration: 150 } }                    // Smooth 150ms hover highlight transition

                                    RowLayout {                                                              // Horizontal layout for collapse chevron, app name, and clear button
                                        anchors.fill: parent                                                 // Fills the header rectangle
                                        anchors.leftMargin: window.s(6)                                       // 6dp left padding
                                        anchors.rightMargin: window.s(6)                                      // 6dp right padding
                                        spacing: window.s(8)                                                 // 8dp spacing between elements

                                        // Clickable Area for Collapse Toggle                               // The collapsible group header is clickable to expand/collapse
                                        MouseArea {                                                          // Creates the clickable area for toggling group collapse state
                                            id: headerMa                                                     // Assigns id "headerMa" for hover state detection
                                            Layout.fillWidth: true                                           // Takes all available width in the row
                                            Layout.fillHeight: true                                          // Full height of the header
                                            hoverEnabled: true                                               // Enables hover detection for the highlight effect
                                            cursorShape: Qt.PointingHandCursor                                // Shows pointing hand cursor to indicate clickability
                                            onClicked: window.toggleGroup(section)                            // Toggles the collapse state for this section's app group on click

                                            RowLayout {                                                      // Inner row for the chevron icon and app name text
                                                anchors.fill: parent                                         // Fills the mouse area
                                                spacing: window.s(8)                                         // 8dp between chevron and app name
                                                
                                                Text {                                                       // Collapse/expand direction chevron icon
                                                    font.family: "Iosevka Nerd Font"                         // Uses Nerd Font for icon glyphs
                                                    font.pixelSize: window.s(14)                             // 14dp icon size
                                                    color: window.mauve                                      // Mauve accent color for the chevron to stand out
                                                    text: window.isCollapsed(section) ? "󰅂" : "󰅀"         // Shows right-pointing chevron when collapsed, down-pointing when expanded
                                                    Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutBack } } // Smooth rotation animation if chevron direction is controlled by rotation
                                                }

                                                Text {                                                       // Application group name displayed in uppercase
                                                    text: section.toUpperCase()                              // Converts the app name string to UPPERCASE for section header display
                                                    font.family: "JetBrains Mono"                            // Monospace font for app name
                                                    font.weight: Font.Black                                  // Extra bold weight for emphasis
                                                    font.pixelSize: window.s(11)                             // 11dp font size - smaller than notification content
                                                    color: window.text                                       // Primary text color
                                                    Layout.fillWidth: true                                   // Takes remaining width in the row
                                                    verticalAlignment: Text.AlignVCenter                     // Vertically centers the text
                                                }
                                            }
                                        }

                                        // Clear Group Button                                              // Button to dismiss all notifications from this application group
                                        Rectangle {                                                          // Circular button background for the clear action
                                            Layout.preferredWidth: window.s(26)                               // Fixed 26dp width
                                            Layout.preferredHeight: window.s(26)                              // Fixed 26dp height (square)
                                            radius: window.s(13)                                             // Half of 26 = 13dp radius for perfect circular shape
                                            color: groupClearMa.containsMouse ? window.surface2 : "transparent" // Highlights with surface2 on hover, transparent normally
                                            Behavior on color { ColorAnimation { duration: 150 } }            // Smooth hover highlight transition

                                            Text {                                                           // Trash/clear icon
                                                anchors.centerIn: parent                                     // Centers the icon in the circular button
                                                font.family: "Iosevka Nerd Font"                             // Nerd Font for icon glyph
                                                font.pixelSize: window.s(14)                                 // 14dp icon size
                                                color: groupClearMa.containsMouse ? window.red : window.overlay0 // Turns red on hover for destructive action warning, dim otherwise
                                                text: "󰅖"                                                   // Trash/delete icon glyph
                                                Behavior on color { ColorAnimation { duration: 150 } }        // Smooth color transition on hover
                                            }

                                            MouseArea {                                                      // Clickable area for clear button
                                                id: groupClearMa                                             // Assigns id for hover detection
                                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor // Fills circle, enables hover, hand cursor
                                                onClicked: window.clearGroup(section)                        // Calls the clearGroup function to remove all notifications for this app
                                            }
                                        }
                                    }
                                }
                            }

                            // --- Individual Notification Card ---                                         // Delegate defining the visual appearance of each notification item
                            delegate: Item {                                                                 // Wrapper item for individual notification cards
                                id: delegateWrapper                                                          // Assigns id for internal property references
                                width: ListView.view.width                                                   // Full width of the list view
                                property bool isHidden: window.isCollapsed(model.appName)                     // Custom property: true if this notification's app group is collapsed
                                height: isHidden ? 0 : innerCard.height                                      // Height is 0 when collapsed (hidden), otherwise matches the card content height
                                visible: height > 0                                                          // Only visible when height is greater than 0 (prevents 0-height items from rendering)
                                opacity: isHidden ? 0 : 1                                                    // Fully transparent when hidden in collapsed group
                                clip: true                                                                   // Clips the card content so it doesn't show during collapse animation
                                
                                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } } // Smoothly animates height changes during collapse/expand over 300ms
                                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } } // Smoothly fades opacity for polished visibility transition

                                Rectangle {                                                                  // The actual visual notification card rectangle
                                    id: innerCard                                                            // Assigns id so delegateWrapper can reference its height
                                    width: parent.width                                                      // Full width of the wrapper
                                    height: cardContent.height + window.s(24)                                // Card height is content height plus 24dp padding (12dp top + 12dp bottom)
                                    radius: window.s(14)                                                     // 14dp corner radius for modern rounded card appearance
                                    color: cardHover.containsMouse ? window.surface1 : window.surface0        // Elevates from surface0 to surface1 on mouse hover for depth perception
                                    border.color: cardHover.containsMouse ? window.surface2 : "transparent"  // Adds visible border only on hover for subtle focus indication
                                    border.width: 1                                                          // 1px border width
                                    clip: true                                                               // Clips content (like the accent stripe) to card rounded corners
                                    Behavior on color { ColorAnimation { duration: 200 } }                    // Smooth 200ms card background color transition on hover
                                    Behavior on border.color { ColorAnimation { duration: 200 } }             // Smooth 200ms border color transition matching background timing

                                    MouseArea {                                                              // Hover detection area for the notification card
                                        id: cardHover                                                        // Assigns id for containsMouse reference by card background
                                        anchors.fill: parent                                                 // Covers the entire card area
                                        hoverEnabled: true                                                   // Enables hover detection for card highlight effect
                                    }

                                    // Left side accent stripe                                              // Decorative colored vertical stripe on the left edge of each notification
                                    Rectangle {                                                              // Creates the accent stripe rectangle
                                        width: window.s(4)                                                    // Very thin 4dp wide stripe
                                        height: parent.height                                                // Full height of the card
                                        anchors.left: parent.left                                            // Anchored to the left edge of the card
                                        color: window.ambientPrimary                                         // Colored using mauve ambient primary color for consistent aesthetics
                                    }

                                    ColumnLayout {                                                           // Vertical layout for notification title/body text content
                                        id: cardContent                                                      // Assigns id so innerCard can measure this item's height
                                        anchors.left: parent.left                                            // Anchored to card left edge
                                        anchors.right: parent.right                                          // Anchored to card right edge
                                        anchors.top: parent.top                                              // Anchored to card top edge
                                        anchors.margins: window.s(14)                                        // 14dp uniform margin padding
                                        anchors.leftMargin: window.s(18) // make room for the accent stripe   // Extra 4dp left margin (18 vs 14) to clear the 4dp accent stripe
                                        spacing: window.s(6)                                                 // 6dp vertical spacing between title and body text

                                        RowLayout {                                                          // Horizontal row for notification summary title and dismiss button
                                            Layout.fillWidth: true                                           // Full width of the content area
                                            spacing: window.s(8)                                             // 8dp horizontal spacing between title and dismiss button

                                            Text {                                                           // Notification summary/title text
                                                text: model.summary || "Notification"                        // Displays the summary from notification model, fallback "Notification" if empty
                                                font.family: "JetBrains Mono"                                // Monospace font for the title
                                                font.weight: Font.Bold                                       // Bold weight for title emphasis
                                                font.pixelSize: window.s(13)                                 // 13dp font size
                                                color: window.text                                           // Primary text color
                                                Layout.fillWidth: true                                       // Takes all available width, pushing dismiss button to right
                                                wrapMode: Text.Wrap                                          // Wraps long titles to multiple lines if needed
                                            }

                                            // Individual Dismiss Button                                    // Button to dismiss this specific notification
                                            Rectangle {                                                      // Circular dismiss button background
                                                Layout.preferredWidth: window.s(22)                           // 22dp width
                                                Layout.preferredHeight: window.s(22)                          // 22dp height (square)
                                                radius: window.s(11)                                         // 11dp radius for perfect circle
                                                color: itemClearMa.containsMouse ? Qt.alpha(window.red, 0.15) : "transparent" // Subtle red tint (15% opacity) on hover, transparent normally
                                                Behavior on color { ColorAnimation { duration: 150 } }        // Smooth hover color transition

                                                Text {                                                       // Dismiss X/close icon
                                                    anchors.centerIn: parent                                 // Centers the icon in the circular button
                                                    font.family: "Iosevka Nerd Font"                         // Nerd Font for icon
                                                    font.pixelSize: window.s(12)                             // 12dp icon size
                                                    color: itemClearMa.containsMouse ? window.red : window.overlay0 // Red on hover for destructive action indication, dim normally
                                                    text: "󰅖"                                               // Trash/delete icon glyph
                                                    Behavior on color { ColorAnimation { duration: 150 } }    // Smooth color transition on hover
                                                }

                                                MouseArea {                                                  // Click area to dismiss the notification
                                                    id: itemClearMa                                          // Assigns id for hover detection
                                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor // Fills circle, hover enabled, hand cursor
                                                    onClicked: {                                             // Click handler
                                                        if(window.notifModel) window.notifModel.remove(index); // Removes this specific notification from the model by its index
                                                    }
                                                }
                                            }
                                        }

                                        Text {                                                               // Notification body/description text
                                            text: model.body || ""                                           // Displays body text from notification model, empty string if no body
                                            font.family: "JetBrains Mono"                                    // Monospace font for body
                                            font.weight: Font.Medium                                         // Medium weight (500) - lighter than bold title
                                            font.pixelSize: window.s(11)                                     // 11dp font size - smaller than title for visual hierarchy
                                            color: window.subtext0                                           // Secondary dimmer text color for body content
                                            Layout.fillWidth: true                                           // Full width
                                            wrapMode: Text.Wrap                                              // Wraps long body text to multiple lines
                                            visible: text !== ""                                             // Only visible when there is actual body text content
                                            textFormat: Text.PlainText                                       // Treats text as plain text only (no HTML/markdown parsing for security)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ==========================================                                                 // Visual section divider
                // RIGHT SIDE: SYSTEM RESOURCES CORE                                                            // Section label: right panel containing CPU/RAM/Disk/Temp orbs, sliders, actions, and profiles
                // ==========================================                                                 // Visual section divider
                Item {                                                                                       // Creates container for the entire right panel (fixed width, full height)
                    Layout.preferredWidth: window.s(480)                                                     // Sets right panel to fixed width of 480 scaled pixels
                    Layout.fillHeight: true                                                                  // Stretches vertically to fill available height

                    // Radar Rings                                                                           // Documents these concentric decorative circles behind the resource orbs
                    Item {                                                                                   // Container for the radar ring decorations
                        id: radarItem                                                                        // Assigns id "radarItem" for potential reference
                        anchors.fill: parent                                                                 // Fills the right panel
                        
                        Repeater {                                                                           // Repeater creates multiple copies of its delegate based on model count
                            model: 3                                                                         // Creates 3 instances (rings) with index values 0, 1, 2
                            Rectangle {                                                                      // Each ring is a large circular border-only rectangle
                                anchors.centerIn: parent                                                     // Centers each ring in the parent panel
                                anchors.verticalCenterOffset: window.s(-70)                                  // Shifts rings upward by 70dp to align with the resource grid position
                                width: window.s(320) + (index * window.s(170))                               // Progressive sizing: 320dp, 490dp, 660dp using the index to create concentric rings
                                height: width                                                                // Matches height to width for perfect circular shape
                                radius: width / 2                                                            // Half width equals radius for complete circle
                                color: "transparent"                                                         // No fill - only the border is visible
                                border.color: window.ambientSecondary                                        // Border color uses the blue ambient secondary color for aesthetics
                                border.width: 1                                                              // Thin 1px border for subtle radar-line appearance
                                Behavior on border.color { ColorAnimation { duration: 1000 } }                // Smooth 1-second border color transitions when theme changes
                                opacity: 0.06 - (index * 0.02)                                              // Decreasing opacity per ring: 0.06, 0.04, 0.02 - outer rings are more subtle
                            }
                        }
                    }

                    // ==========================================                                             // Section divider
                    // TOP: UPTIME COMPONENT                                                                 // Section: system uptime display showing hours and minutes
                    // ==========================================                                             // Section divider
                    Row {                                                                                    // Horizontal row layout for hours box, colon, and minutes box
                        id: uptimeRow                                                                        // Assigns id "uptimeRow" for potential reference
                        anchors.top: parent.top                                                              // Anchored to top of the right panel
                        anchors.left: parent.left                                                            // Anchored to left of the right panel
                        anchors.margins: window.s(25)                                                        // 25dp margin from top and left edges
                        spacing: window.s(6)                                                                 // 6dp spacing between elements in the row
                        z: 10                                                                                // High z-index to ensure uptime renders above radar rings and other elements
                        
                        transform: Translate { y: window.s(-20) * (1.0 - introTop) }                         // Slides down from 20dp above during intro animation
                        opacity: introTop                                                                    // Fades with top section intro animation
                        
                        // Hours Box                                                                         // Card displaying the uptime hours value
                        Rectangle {                                                                          // Hours card background
                            width: window.s(44); height: window.s(48); radius: window.s(10)                   // 44x48dp rectangle with 10dp corner radius
                            color: window.surface0; border.color: window.surface1; border.width: 1            // Surface0 fill with surface1 border for depth
                            
                            Rectangle { anchors.fill: parent; radius: window.s(10); color: window.ambientPrimary; opacity: 0.05; Behavior on color { ColorAnimation { duration: 1000 } } } // Subtle 5% opacity mauve tint overlay
                            Column {                                                                         // Vertical column for number and "HR" label
                                anchors.centerIn: parent                                                     // Centers the column in the card
                                Text {                                                                       // Hours number display
                                    text: window.upHours.toString().padStart(2, '0')                         // Converts hours to string and pads with leading zero (e.g., "05" for 5 hours)
                                    font.pixelSize: window.s(18); font.family: "JetBrains Mono"; font.weight: Font.Black // Large bold monospace number
                                    color: window.ambientPrimary                                             // Colored with mauve ambient primary
                                    Behavior on color { ColorAnimation { duration: 1000 } }                   // Smooth color transition on theme changes
                                    anchors.horizontalCenter: parent.horizontalCenter                        // Centers horizontally in the column
                                }
                                Text {                                                                       // "HR" unit label below the number
                                    text: "HR"; font.pixelSize: window.s(8); font.family: "JetBrains Mono"; font.weight: Font.Bold // Small bold label
                                    color: window.subtext0; anchors.horizontalCenter: parent.horizontalCenter // Dim secondary color, centered horizontally
                                }
                            }
                        }

                        // Pulsing Colon                                                                     // Animated colon separator between hours and minutes
                        Text {                                                                               // Colon character text
                            anchors.verticalCenter: parent.verticalCenter                                    // Vertically centered in the row
                            text: ":"                                                                        // Displays the colon character
                            font.pixelSize: window.s(22); font.family: "JetBrains Mono"; font.weight: Font.Black // Large bold colon
                            color: window.ambientPrimary                                                     // Colored with mauve
                            Behavior on color { ColorAnimation { duration: 1000 } }                           // Smooth color transition
                            
                            opacity: uptimePulse                                                             // Opacity driven by the pulsing animation value
                            property real uptimePulse: 1.0                                                   // Custom property holding the current pulse opacity value
                            SequentialAnimation on uptimePulse {                                             // Creates a continuous breathing/pulsing animation on uptimePulse
                                loops: Animation.Infinite; running: true                                     // Loops forever, starts immediately
                                NumberAnimation { to: 0.2; duration: 800; easing.type: Easing.InOutSine }    // Fades colon to 20% opacity over 800ms using sine easing for smooth breathing
                                NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }    // Fades back to 100% opacity over 800ms completing the pulse cycle
                            }
                        }

                        // Mins Box                                                                         // Card displaying the uptime minutes value (mirrors hours box structure)
                        Rectangle {                                                                          // Minutes card background
                            width: window.s(44); height: window.s(48); radius: window.s(10)                   // Same dimensions as hours box for visual consistency
                            color: window.surface0; border.color: window.surface1; border.width: 1            // Same surface styling
                            
                            Rectangle { anchors.fill: parent; radius: window.s(10); color: window.ambientSecondary; opacity: 0.05; Behavior on color { ColorAnimation { duration: 1000 } } } // Secondary blue color tint for visual distinction
                            Column {                                                                         // Vertical column for number and "MIN" label
                                anchors.centerIn: parent
                                Text {                                                                       // Minutes number display
                                    text: window.upMins.toString().padStart(2, '0')                           // Zero-padded minutes string (e.g., "03" for 3 minutes)
                                    font.pixelSize: window.s(18); font.family: "JetBrains Mono"; font.weight: Font.Black
                                    color: window.ambientSecondary                                           // Uses blue ambient secondary for contrast with hours
                                    Behavior on color { ColorAnimation { duration: 1000 } }
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {                                                                       // "MIN" unit label
                                    text: "MIN"; font.pixelSize: window.s(8); font.family: "JetBrains Mono"; font.weight: Font.Bold
                                    color: window.subtext0; anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }

                    // Expanding top-right logout icon                                                       // Logout/power button that expands on hover to show username
                    Rectangle {                                                                              // Logout button container rectangle
                        id: logoutBtn                                                                        // Assigns id for property width animation reference
                        anchors.top: parent.top; anchors.right: parent.right                                  // Positions in top-right corner of the right panel
                        anchors.margins: window.s(25)                                                        // 25dp margin from top and right edges
                        z: 10                                                                                // High z-index to ensure it renders above other elements
                        width: logoutMa.containsMouse ? window.s(44) + usernameText.implicitWidth + window.s(12) : window.s(44) // Expands to show username on hover: base 44dp + text width + 12dp padding
                        height: window.s(44); radius: window.s(14)                                           // 44dp height with 14dp corner radius
                        color: logoutMa.containsMouse ? window.surface1 : "transparent"                      // Surface1 highlight on hover, transparent normally
                        border.color: logoutMa.containsMouse ? window.surface2 : "transparent"               // Surface2 border on hover for definition
                        clip: true                                                                           // Clips content so username doesn't show outside during width animation
                        
                        transform: Translate { y: window.s(-20) * (1.0 - introTop) }                         // Slides down from above during intro
                        opacity: introTop                                                                    // Fades with top section intro

                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } } // Smooth 300ms width expansion/contraction
                        Behavior on color { ColorAnimation { duration: 150 } }                                // Smooth background color transition
                        Behavior on border.color { ColorAnimation { duration: 150 } }                         // Smooth border color transition

                        Row {                                                                                // Horizontal row for username text and power icon
                            anchors.right: parent.right                                                      // Anchored to right edge of button
                            anchors.rightMargin: window.s(13)                                                // 13dp right margin padding
                            anchors.verticalCenter: parent.verticalCenter                                    // Vertically centered in button
                            spacing: window.s(12)                                                            // 12dp between username and icon

                            Text {                                                                           // Username text (only visible on hover)
                                id: usernameText                                                             // Assigns id for width measurement
                                text: window.currentUserName                                                 // Displays the logged-in username from cache/poller
                                font.family: "JetBrains Mono"                                                // Monospace font
                                font.weight: Font.Bold                                                       // Bold weight
                                font.pixelSize: window.s(14)                                                 // 14dp font size
                                color: window.text                                                           // Primary text color
                                anchors.verticalCenter: parent.verticalCenter                                // Vertically centered
                                opacity: logoutMa.containsMouse ? 1.0 : 0.0                                 // Only visible when mouse hovers
                                Behavior on opacity { NumberAnimation { duration: 250 } }                     // Smooth 250ms fade in/out
                            }

                            Text {                                                                           // Power/logout icon
                                font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18)               // Nerd Font icon, 18dp size
                                color: logoutMa.containsMouse ? window.red : window.overlay0                 // Red on hover (destructive action warning), dim normally
                                text: "󰍃"                                                                   // Exit/logout icon glyph
                                anchors.verticalCenter: parent.verticalCenter                                // Vertically centered
                                Behavior on color { ColorAnimation { duration: 150 } }                        // Smooth color transition
                            }
                        }

                        MouseArea {                                                                          // Click area for logout action
                            id: logoutMa                                                                     // Assigns id for hover detection
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor      // Fills button, hover enabled, hand cursor
                            onClicked: {                                                                     // Click handler
                                exitAnim.start(); // Trigger graceful UI exit                                // Starts the exit animation sequence for visual feedback before closing
                                Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/exit.sh"]);    // Executes the exit/logout shell script
                                Quickshell.execDetached(["sh", "-c", "echo 'close' > /tmp/qs_widget_state"]); // Signals the Quickshell widget manager to close this popup
                            }
                        }
                    }

                    // ==========================================                                             // Section divider
                    // BIG SYSTEM RESOURCES GRID (DESKTOP)                                                   // Section: 2x2 grid of system resource monitor orbs for desktop variant
                    // ==========================================                                             // Section divider
                    Grid {                                                                                   // Creates a Grid layout that arranges its children in rows and columns
                        id: sysGrid                                                                          // Assigns id "sysGrid" for potential reference
                        columns: 2                                                                           // Sets the grid to have 2 columns (2x2 layout for 4 orbs)
                        spacing: window.s(25)                                                                // 25dp spacing between grid cells both horizontally and vertically
                        anchors.centerIn: parent                                                             // Centers the entire grid within the right panel
                        anchors.verticalCenterOffset: window.s(-85)                                          // Shifts the grid upward by 85dp to leave room for bottom docks
                        z: 1                                                                                 // Z-index of 1 to render above radar rings

                        opacity: introCore                                                                   // Fades with the core intro animation
                        transform: Translate { y: window.s(25) * (1 - introCore) }                            // Slides up from 25dp below during intro
                        scale: 0.9 + (0.1 * introCore)                                                       // Scales from 90% to 100% during intro for pop-in effect

                        // 1. CPU Orb                                                                        // First grid cell: CPU usage circular gauge
                        Item {                                                                               // Container item for the CPU orb
                            id: cpuOrb; width: window.s(145); height: window.s(145)                           // 145x145dp square container for the orb
                            property real animVal: window.cpuUsage                                           // Animated value property bound to the current CPU usage percentage
                            Behavior on animVal { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } } // Smoothly animates the orb value over 1.2 seconds when CPU usage changes
                            onAnimValChanged: cpuCanvas.requestPaint()                                       // Triggers canvas repaint whenever the animated value updates
                            
                            scale: cpuMa.containsMouse ? 1.05 : 1.0                                         // Scales up slightly to 105% on mouse hover for interactive feedback
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } } // Smooth 400ms scale transition on hover

                            // Individual Aura - Fixed Overlap                                               // Glow aura around the orb that expands on hover
                            Rectangle {                                                                      // Aura glow circle
                                anchors.centerIn: parent                                                     // Centers on the orb
                                width: parent.width + (cpuMa.containsMouse ? window.s(16) : window.s(4))      // Expands from 4dp to 16dp larger than orb on hover
                                height: width; radius: width / 2                                             // Perfect circle
                                color: window.blue                                                           // Blue color for CPU indicator
                                opacity: cpuMa.containsMouse ? 0.25 : 0.08                                   // More visible (25%) on hover, subtle (8%) normally
                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } } // Smooth aura expansion
                                Behavior on opacity { NumberAnimation { duration: 300 } }                    // Smooth opacity transition
                            }

                            Canvas {                                                                         // Canvas for drawing the CPU percentage arc gauge
                                id: cpuCanvas; anchors.fill: parent; rotation: 180                           // Fills orb, rotated 180° so arc starts from top
                                Connections { target: window; function onBaseChanged() { cpuCanvas.requestPaint() } } // Repaints when theme base color changes
                                onPaint: {                                                                   // Canvas paint handler
                                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);          // Gets context and clears canvas
                                    var cX = width/2; var cY = height/2; var rad = (width/2)-window.s(8);    // Calculates center point and radius (minus 8dp padding)
                                    var eA = (Math.min(100, Math.max(0, parent.animVal)) / 100) * 2 * Math.PI; // Calculates end angle from animated value, clamped 0-100%
                                    ctx.lineCap = "round"; ctx.lineWidth = window.s(8); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, 2*Math.PI); // Draws background track circle
                                    ctx.strokeStyle = window.surface0.toString(); ctx.stroke();               // Fills track with surface0 color
                                    var grad = ctx.createLinearGradient(0, height, width, 0); grad.addColorStop(0, window.blue.toString()); grad.addColorStop(1, window.sapphire.toString()); // Blue-to-sapphire gradient
                                    ctx.lineWidth = window.s(14); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, eA); ctx.strokeStyle = grad; ctx.stroke(); // Draws fill arc with gradient
                                }
                            }
                            ColumnLayout {                                                                   // Text overlay inside the orb showing icon, percentage, and label
                                anchors.centerIn: parent; spacing: 0
                                RowLayout {                                                                  // Row for CPU icon and percentage
                                    Layout.alignment: Qt.AlignHCenter; spacing: window.s(4)
                                    Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18); color: window.blue; text: "" } // CPU chip icon in blue
                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(28); color: window.text; text: Math.round(cpuOrb.animVal) + "%" } // Animated percentage with % sign
                                }
                                Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12); color: window.subtext0; text: "CPU LOAD" } // "CPU LOAD" label
                            }
                            MouseArea { id: cpuMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor } // Hover area for CPU orb
                        }

                        // 2. RAM Orb                                                                        // Second grid cell: RAM usage circular gauge
                        Item {                                                                               // Container for RAM orb (mirrors CPU orb structure)
                            id: ramOrb; width: window.s(145); height: window.s(145)
                            property real animVal: window.ramUsage                                           // Animated value bound to RAM usage
                            Behavior on animVal { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }
                            onAnimValChanged: ramCanvas.requestPaint()

                            scale: ramMa.containsMouse ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

                            // Individual Aura - Fixed Overlap
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + (ramMa.containsMouse ? window.s(16) : window.s(4))
                                height: width; radius: width / 2
                                color: window.mauve                                                          // Mauve color for RAM indicator
                                opacity: ramMa.containsMouse ? 0.25 : 0.08
                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                            }

                            Canvas {
                                id: ramCanvas; anchors.fill: parent; rotation: 180
                                Connections { target: window; function onBaseChanged() { ramCanvas.requestPaint() } }
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                    var cX = width/2; var cY = height/2; var rad = (width/2)-window.s(8);
                                    var eA = (Math.min(100, Math.max(0, parent.animVal)) / 100) * 2 * Math.PI;
                                    ctx.lineCap = "round"; ctx.lineWidth = window.s(8); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, 2*Math.PI); 
                                    ctx.strokeStyle = window.surface0.toString(); ctx.stroke();
                                    var grad = ctx.createLinearGradient(0, height, width, 0); grad.addColorStop(0, window.mauve.toString()); grad.addColorStop(1, window.pink.toString()); // Mauve-to-pink gradient
                                    ctx.lineWidth = window.s(14); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, eA); ctx.strokeStyle = grad; ctx.stroke();
                                }
                            }
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 0
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter; spacing: window.s(4)
                                    Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18); color: window.mauve; text: "󰍛" } // RAM memory icon in mauve
                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(28); color: window.text; text: Math.round(ramOrb.animVal) + "%" }
                                }
                                Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12); color: window.subtext0; text: "MEMORY" } // "MEMORY" label
                            }
                            MouseArea { id: ramMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                        }

                        // 3. DISK Orb                                                                       // Third grid cell: Disk usage circular gauge
                        Item {                                                                               // Container for Disk orb
                            id: diskOrb; width: window.s(145); height: window.s(145)
                            property real animVal: window.diskUsage                                          // Animated value bound to disk usage
                            Behavior on animVal { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }
                            onAnimValChanged: diskCanvas.requestPaint()

                            scale: diskMa.containsMouse ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

                            // Individual Aura - Fixed Overlap
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + (diskMa.containsMouse ? window.s(16) : window.s(4))
                                height: width; radius: width / 2
                                color: window.peach                                                          // Peach color for disk indicator
                                opacity: diskMa.containsMouse ? 0.25 : 0.08
                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                            }

                            Canvas {
                                id: diskCanvas; anchors.fill: parent; rotation: 180
                                Connections { target: window; function onBaseChanged() { diskCanvas.requestPaint() } }
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                    var cX = width/2; var cY = height/2; var rad = (width/2)-window.s(8);
                                    var eA = (Math.min(100, Math.max(0, parent.animVal)) / 100) * 2 * Math.PI;
                                    ctx.lineCap = "round"; ctx.lineWidth = window.s(8); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, 2*Math.PI); 
                                    ctx.strokeStyle = window.surface0.toString(); ctx.stroke();
                                    var grad = ctx.createLinearGradient(0, height, width, 0); grad.addColorStop(0, window.peach.toString()); grad.addColorStop(1, window.yellow.toString()); // Peach-to-yellow gradient
                                    ctx.lineWidth = window.s(14); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, eA); ctx.strokeStyle = grad; ctx.stroke();
                                }
                            }
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 0
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter; spacing: window.s(4)
                                    Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18); color: window.peach; text: "󰋊" } // Disk/storage icon in peach
                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(28); color: window.text; text: Math.round(diskOrb.animVal) + "%" }
                                }
                                Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12); color: window.subtext0; text: "STORAGE" } // "STORAGE" label
                            }
                            MouseArea { id: diskMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                        }

                        // 4. TEMP Orb                                                                       // Fourth grid cell: System temperature circular gauge
                        Item {                                                                               // Container for Temp orb
                            id: tempOrb; width: window.s(145); height: window.s(145)
                            property real animVal: window.sysTemp                                            // Animated value bound to system temperature (displays as percentage of 100°C for arc)
                            Behavior on animVal { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }
                            onAnimValChanged: tempCanvas.requestPaint()

                            scale: tempMa.containsMouse ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

                            // Individual Aura - Fixed Overlap
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + (tempMa.containsMouse ? window.s(16) : window.s(4))
                                height: width; radius: width / 2
                                color: window.red                                                            // Red color for temperature indicator
                                opacity: tempMa.containsMouse ? 0.25 : 0.08
                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                            }

                            Canvas {
                                id: tempCanvas; anchors.fill: parent; rotation: 180
                                Connections { target: window; function onBaseChanged() { tempCanvas.requestPaint() } }
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                    var cX = width/2; var cY = height/2; var rad = (width/2)-window.s(8);
                                    var eA = (Math.min(100, Math.max(0, parent.animVal)) / 100) * 2 * Math.PI; // Temperature treated as percentage of 100 for arc visualization
                                    ctx.lineCap = "round"; ctx.lineWidth = window.s(8); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, 2*Math.PI); 
                                    ctx.strokeStyle = window.surface0.toString(); ctx.stroke();
                                    var grad = ctx.createLinearGradient(0, height, width, 0); grad.addColorStop(0, window.red.toString()); grad.addColorStop(1, window.maroon.toString()); // Red-to-maroon gradient
                                    ctx.lineWidth = window.s(14); ctx.beginPath(); ctx.arc(cX, cY, rad, 0, eA); ctx.strokeStyle = grad; ctx.stroke();
                                }
                            }
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 0
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter; spacing: window.s(4)
                                    Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18); color: window.red; text: "" } // Thermometer icon in red
                                    Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(28); color: window.text; text: Math.round(tempOrb.animVal) + "°" } // Temperature with degree symbol
                                }
                                Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12); color: window.subtext0; text: "SYSTEM TEMP" } // "SYSTEM TEMP" label
                            }
                            MouseArea { id: tempMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                        }
                    }

                    // ==========================================                                             // Section divider
                    // BOTTOM DOCKS                                                                          // Section containing the lower control panels stacked vertically
                    // ==========================================                                             // Section divider
                    ColumnLayout {                                                                           // Vertical column layout for bottom controls
                        id: bottomDocks                                                                      // Assigns id "bottomDocks" for potential reference
                        anchors.bottom: parent.bottom                                                        // Anchored to bottom of right panel
                        anchors.left: parent.left                                                            // Anchored to left
                        anchors.right: parent.right                                                          // Anchored to right
                        anchors.margins: window.s(25)                                                        // 25dp margin around entire dock area
                        spacing: window.s(15)                                                                // 15dp vertical spacing between control sections

                        // 1. HARDWARE CONTROLS DOCK (Sliders)                                              // First dock: brightness and volume sliders
                        Rectangle {                                                                          // Slider dock background card
                            Layout.fillWidth: true                                                           // Full width
                            Layout.preferredHeight: window.s(96)                                             // Fixed height to fit two sliders comfortably
                            radius: window.s(14)                                                             // 14dp corner rounding
                            color: window.surface0                                                           // Surface0 background
                            border.color: window.surface1                                                    // Surface1 border for depth
                            border.width: 1

                            opacity: introSliders                                                            // Fades with sliders intro animation
                            transform: Translate { y: window.s(20) * (1.0 - introSliders) }                   // Slides up from below during intro

                            ColumnLayout {                                                                   // Vertical layout for the two slider rows
                                anchors.fill: parent
                                anchors.margins: window.s(14)                                                // 14dp internal padding
                                spacing: window.s(12)                                                        // 12dp between brightness and volume sliders

                                // Brightness Slider                                                         // First slider row: screen brightness control
                                RowLayout {                                                                  // Horizontal row for brightness icon and slider
                                    Layout.fillWidth: true
                                    spacing: window.s(15)

                                    Item {                                                                    // Container for brightness icon
                                        Layout.preferredWidth: window.s(32)                                   // 32dp square area for icon
                                        Layout.preferredHeight: window.s(32)
                                        Text {                                                                // Brightness level indicator icon
                                            anchors.centerIn: parent
                                            text: window.sysBrightness > 66 ? "󰃠" : (window.sysBrightness > 33 ? "󰃟" : "󰃞") // High/medium/low brightness icon based on level
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: window.s(22)
                                            color: window.blue                                                // Blue color for brightness (static desktop style)
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                        }
                                    }

                                    Item {                                                                    // Container for the slider track and thumb
                                        Layout.fillWidth: true                                                // Takes remaining width
                                        height: window.s(18)

                                        Timer {                                                               // Command throttle timer to prevent overwhelming system with rapid brightness changes
                                            id: briCmdThrottle                                                // Assigns id
                                            interval: 50                                                      // 50ms throttle interval (20 commands per second max)
                                            property int targetPct: -1                                        // Pending brightness percentage to set
                                            onTriggered: {                                                    // When timer fires
                                                if (targetPct >= 0) {                                         // If there's a valid pending target
                                                    Quickshell.execDetached(["brightnessctl", "set", targetPct + "%"]); // Executes brightnessctl to set screen brightness
                                                    targetPct = -1;                                           // Resets target after execution
                                                }
                                            }
                                        }

                                        Rectangle {                                                          // Slider track background (the full bar)
                                            anchors.fill: parent
                                            radius: window.s(9)                                              // 9dp rounded for pill shape
                                            color: window.surface1                                           // Track background color
                                            border.color: window.surface2                                    // Track border
                                            border.width: 1
                                            clip: true                                                       // Clips fill bar to rounded track

                                            Rectangle {                                                      // Filled portion of the slider (shows current brightness level)
                                                height: parent.height
                                                width: parent.width * (window.sysBrightness / 100)            // Width proportional to brightness percentage
                                                radius: window.s(9)
                                                opacity: briMa.containsMouse ? 1.0 : 0.85                     // Brighter when hovering for visual feedback
                                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                                Behavior on width { enabled: !window.isDraggingBri; NumberAnimation { duration: 200; easing.type: Easing.OutQuint } } // Smooth width animation only when not dragging

                                                gradient: Gradient {                                         // Horizontal gradient fill for the filled portion
                                                    orientation: Gradient.Horizontal
                                                    GradientStop { position: 0.0; color: window.blue; Behavior on color { ColorAnimation { duration: 300 } } } // Blue start color
                                                    GradientStop { position: 1.0; color: window.sapphire; Behavior on color { ColorAnimation { duration: 300 } } } // Sapphire end color
                                                }
                                            }
                                        }
                                        MouseArea {                                                          // Interactive drag area for brightness slider
                                            id: briMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onPressed: (mouse) => { briSyncDelay.stop(); window.isDraggingBri = true; updateBri(mouse.x); } // On press: stops anti-jitter timer, sets dragging flag, updates brightness
                                            onPositionChanged: (mouse) => { if (pressed) updateBri(mouse.x); } // While dragging: continuously updates brightness
                                            onReleased: { briSyncDelay.restart(); }                           // On release: restarts anti-jitter timer to re-enable polling after 800ms

                                            function updateBri(mx) {                                         // Helper function to convert mouse x position to brightness percentage
                                                let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100))); // Calculates percentage from mouse position, clamps between 0-100
                                                window.sysBrightness = pct;                                  // Updates local brightness property immediately for responsive UI
                                                briCmdThrottle.targetPct = pct;                              // Sets the throttled command target
                                                if (!briCmdThrottle.running) briCmdThrottle.start();         // Starts throttle timer if not already running
                                            }
                                        }
                                    }
                                }

                                // Volume Slider                                                            // Second slider row: audio volume control
                                RowLayout {                                                                  // Horizontal row for volume icon and slider
                                    Layout.fillWidth: true
                                    spacing: window.s(15)

                                    Rectangle {                                                              // Volume icon container with click-to-mute behavior
                                        Layout.preferredWidth: window.s(32)                                   // 32dp square
                                        Layout.preferredHeight: window.s(32)
                                        radius: window.s(16)                                                  // Full radius for circular appearance
                                        color: volIconMa.containsMouse ? window.surface1 : "transparent"      // Highlights on hover
                                        border.color: volIconMa.containsMouse ? window.profileStart : "transparent" // Profile-derived border on hover
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Behavior on border.color { ColorAnimation { duration: 150 } }

                                        Text {                                                                // Volume level/mute icon
                                            anchors.centerIn: parent
                                            text: window.sysMuted || window.sysVolume === 0 ? "󰖁" : (window.sysVolume > 50 ? "󰕾" : "󰖀") // Muted/zero, high, or low volume icon
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: window.s(22)
                                            color: window.sysMuted ? window.overlay0 : window.profileStart    // Dim when muted, profile color when active
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                        }
                                        MouseArea {                                                          // Click area to toggle mute/unmute
                                            id: volIconMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {                                                      // Toggle mute on click
                                                volSyncDelay.stop();                                          // Stops anti-jitter timer
                                                window.isDraggingVol = true;                                  // Sets dragging flag to prevent polling override
                                                window.sysMuted = !window.sysMuted;                           // Toggles mute state locally
                                                Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]); // Sends toggle command to PipeWire
                                                volSyncDelay.restart();                                       // Restarts anti-jitter timer
                                            }
                                        }
                                    }

                                    Item {                                                                    // Volume slider track container
                                        Layout.fillWidth: true
                                        height: window.s(18)

                                        Timer {                                                               // Command throttle for volume changes
                                            id: volCmdThrottle
                                            interval: 50                                                      // 50ms throttle
                                            property int targetPct: -1
                                            onTriggered: {
                                                if (targetPct >= 0) {
                                                    if (targetPct > 0 && window.sysMuted) {                   // If setting volume above 0 while muted
                                                        window.sysMuted = false;                              // Unmute locally
                                                        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"]); // Send unmute command
                                                    }
                                                    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", targetPct + "%"]); // Sets volume to target percentage
                                                    targetPct = -1;
                                                }
                                            }
                                        }

                                        Rectangle {                                                          // Volume slider track
                                            anchors.fill: parent
                                            radius: window.s(9)
                                            color: window.surface1
                                            border.color: window.surface2
                                            border.width: 1
                                            clip: true

                                            Rectangle {                                                      // Filled portion of volume slider
                                                height: parent.height
                                                width: parent.width * (window.sysVolume / 100)
                                                radius: window.s(9)
                                                opacity: window.sysMuted ? 0.5 : (volMa.containsMouse ? 1.0 : 0.85) // Dimmer when muted, brighter on hover
                                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                                Behavior on width { enabled: !window.isDraggingVol; NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }

                                                gradient: Gradient {                                         // Gradient fill uses muted colors when muted
                                                    orientation: Gradient.Horizontal
                                                    GradientStop { position: 0.0; color: window.sysMuted ? window.surface2 : window.profileStart; Behavior on color { ColorAnimation { duration: 300 } } } // Gray when muted, profile color otherwise
                                                    GradientStop { position: 1.0; color: window.sysMuted ? Qt.lighter(window.surface2, 1.15) : window.profileEnd; Behavior on color { ColorAnimation { duration: 300 } } }
                                                }
                                            }
                                        }
                                        MouseArea {                                                          // Interactive drag area for volume
                                            id: volMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onPressed: (mouse) => { volSyncDelay.stop(); window.isDraggingVol = true; updateVol(mouse.x); }
                                            onPositionChanged: (mouse) => { if (pressed) updateVol(mouse.x); }
                                            onReleased: { volSyncDelay.restart(); }

                                            function updateVol(mx) {
                                                let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100))); // Converts mouse x to percentage 0-100
                                                window.sysVolume = pct;                                      // Updates local volume for responsive UI
                                                volCmdThrottle.targetPct = pct;                              // Sets throttled command target
                                                if (!volCmdThrottle.running) volCmdThrottle.start();         // Starts throttle timer
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 2. SYSTEM ACTIONS DOCK                                                        // Second dock: system action buttons (lock, suspend, reboot, poweroff)
                        RowLayout {                                                                          // Horizontal row layout stretching across full width
                            Layout.fillWidth: true
                            Layout.preferredHeight: window.s(75)                                             // 75dp fixed height for action buttons
                            spacing: window.s(12)                                                            // 12dp spacing between buttons
                            
                            Repeater {                                                                       // Repeater to generate buttons from a model definition
                                model: ListModel {                                                           // Inline ListModel defining the 4 system action buttons
                                    ListElement { cmd: "bash ~/.config/hypr/scripts/lock.sh"; icon: ""; baseColor: "mauve"; weight: 1.0 } // Lock screen: mauve, weight 1.0 (fastest fill)
                                    ListElement { cmd: "bash ~/.config/hypr/scripts/lock.sh & systemctl suspend"; icon: "ᶻ 𝗓 𝗓"; baseColor: "blue"; weight: 1.0 } // Suspend: blue, weight 1.0
                                    ListElement { cmd: "systemctl reboot"; icon: "󰑓"; baseColor: "yellow"; weight: 2.5 } // Reboot: yellow, weight 2.5 (medium fill speed)
                                    ListElement { cmd: "systemctl poweroff -i"; icon: ""; baseColor: "red"; weight: 3.5 } // Power off: red, weight 3.5 (slowest fill - needs longest hold)
                                }
                                
                                delegate: Rectangle {                                                        // Delegate defining each action button's appearance and behavior
                                    id: actionCapsule                                                        // Assigns id for property references
                                    Layout.fillWidth: true                                                   // Each button stretches equally to fill row width
                                    Layout.fillHeight: true                                                  // Full row height
                                    radius: window.s(14)                                                     // 14dp corner rounding

                                    opacity: introActions                                                    // Fades with actions intro animation
                                    transform: Translate { y: window.s(30) * (1.0 - introActions) + (index * window.s(12) * (1.0 - introActions)) } // Slides up from below with staggered offset per button index
                                    
                                    property color c1: window[baseColor] || window.surface1                   // Dynamically resolves color from theme using baseColor string (e.g., window["mauve"]), fallback to surface1
                                    property color c2: Qt.lighter(c1, 1.2)                                   // Creates lighter variant (20% lighter) of c1 for gradient effects

                                    color: actionMa.containsMouse ? window.surface1 : window.surface0        // Elevates background on hover
                                    border.color: actionMa.containsMouse ? c1 : window.surface2              // Accent-colored border on hover, neutral border normally
                                    border.width: actionMa.containsMouse ? 2 : 1                            // Thicker 2px border on hover for emphasis
                                    Behavior on color { ColorAnimation { duration: 200 } }                    // Smooth background transition
                                    Behavior on border.color { ColorAnimation { duration: 200 } }             // Smooth border transition
                                    
                                    scale: actionMa.pressed ? (0.98 - (0.01 * weight)) : (actionMa.containsMouse ? 1.08 : 1.0) // Presses down (0.97-0.98 based on weight), pops up on hover (1.08)
                                    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } } // Smooth scale transitions

                                    property real fillLevel: 0.0                                             // Fill level for the hold-to-activate animation (0 = empty, 1 = full/triggered)
                                    property bool triggered: false                                           // Flag set to true once the fill completes and action is about to execute
                                    property real flashOpacity: 0.0                                          // White flash overlay opacity for visual feedback at trigger moment
                                    
                                    Canvas {                                                                 // Canvas for drawing the liquid fill wave animation inside the button
                                        id: actionWaveCanvas
                                        anchors.fill: parent
                                        
                                        property real wavePhase: 0.0                                         // Wave animation phase for the wavy top surface of the fill liquid
                                        NumberAnimation on wavePhase {                                       // Animates wavePhase continuously while filling
                                            running: actionCapsule.fillLevel > 0.0 && actionCapsule.fillLevel < 1.0 // Only runs while actively filling (not empty or complete)
                                            loops: Animation.Infinite                                         // Continuous loop
                                            from: 0; to: Math.PI * 2; duration: 800                         // Full sine wave cycle over 800ms
                                        }
                                        onWavePhaseChanged: requestPaint()                                   // Repaints canvas whenever wave phase changes
                                        Connections { target: actionCapsule; function onFillLevelChanged() { actionWaveCanvas.requestPaint() } } // Repaints when fill level changes
                                        Connections { target: window; function onBaseChanged() { actionWaveCanvas.requestPaint() } } // Repaints when theme base color changes
                                        
                                        onPaint: {                                                           // Canvas paint handler for the liquid fill
                                            var ctx = getContext("2d");
                                            ctx.clearRect(0, 0, width, height);
                                            if (actionCapsule.fillLevel <= 0.001) return;                     // Don't draw anything if fill is essentially empty
                                            
                                            var r = window.s(14);                                            // Corner radius matching the button
                                            var fillY = height * (1.0 - actionCapsule.fillLevel);            // Y position of the fill surface: higher fill = lower Y (fills from bottom)
                                            ctx.save();
                                            ctx.beginPath();
                                            ctx.moveTo(r, 0); ctx.lineTo(width - r, 0); ctx.arcTo(width, 0, width, r, r); // Creates rounded rectangle clipping path
                                            ctx.lineTo(width, height - r); ctx.arcTo(width, height, width - r, height, r);
                                            ctx.lineTo(r, height); ctx.arcTo(0, height, 0, height - r, r);
                                            ctx.lineTo(0, r); ctx.arcTo(0, 0, r, 0, r); ctx.closePath(); ctx.clip(); // Clips drawing to rounded rect
                                            
                                            ctx.beginPath();
                                            ctx.moveTo(0, fillY);
                                            if (actionCapsule.fillLevel < 0.99) {                             // Draw wavy surface while filling is in progress
                                                var waveAmp = window.s(10) * Math.sin(actionCapsule.fillLevel * Math.PI); // Wave amplitude decreases as fill approaches 100%
                                                var cp1y = fillY + Math.sin(wavePhase) * waveAmp;            // First bezier control point Y
                                                var cp2y = fillY + Math.cos(wavePhase + Math.PI) * waveAmp;  // Second bezier control point Y
                                                ctx.bezierCurveTo(width * 0.33, cp2y, width * 0.66, cp1y, width, fillY); // Wavy fill surface curve
                                                ctx.lineTo(width, height); ctx.lineTo(0, height);             // Bottom fill
                                            } else {                                                         // When fill is essentially complete (>99%), draw flat surface
                                                ctx.lineTo(width, 0); ctx.lineTo(width, height); ctx.lineTo(0, height);
                                            }
                                            ctx.closePath();                                                 // Closes the fill shape
                                            
                                            var grad = ctx.createLinearGradient(0, 0, 0, height);            // Vertical gradient for the fill liquid
                                            grad.addColorStop(0, actionCapsule.c1.toString()); grad.addColorStop(1, actionCapsule.c2.toString()); // Action color gradient
                                            ctx.fillStyle = grad; ctx.fill(); ctx.restore();                 // Renders the fill
                                        }
                                    }

                                    Rectangle {                                                              // White flash overlay for trigger moment
                                        anchors.fill: parent; radius: window.s(14); color: "#ffffff"          // White rectangle matching button shape
                                        opacity: actionCapsule.flashOpacity                                  // Opacity controlled by flashOpacity property
                                        PropertyAnimation on opacity { id: cardFlashAnim; to: 0; duration: 500; easing.type: Easing.OutExpo } // Auto-fades flash to 0 over 500ms
                                    }

                                    Text {                                                                   // Action icon (center of button)
                                        anchors.centerIn: parent
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: window.s(24)                                         // 24dp icon size
                                        color: actionMa.containsMouse ? window.text : window.subtext0        // Brightens icon on hover
                                        text: icon                                                           // Displays the icon from model
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    Item {                                                                    // Container for the inverted-color icon visible inside the fill
                                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                        height: actionCapsule.height * actionCapsule.fillLevel               // Height matches the fill level (0 when empty, full button when complete)
                                        clip: true                                                           // Clips the inverted icon so it only shows within fill area
                                        
                                        Text {                                                                // Inverted color icon (visible inside liquid fill)
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            y: (actionCapsule.height / 2) - (height / 2) - (actionCapsule.height - parent.height) // Positions icon so it appears stationary while fill rises
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: window.s(24)
                                            color: window.crust                                              // Dark crust color for contrast against bright fill
                                            text: icon                                                       // Same icon as the main one
                                        }
                                    }

                                    MouseArea {                                                              // Press-and-hold interaction area for the action button
                                        id: actionMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: actionCapsule.triggered ? Qt.ArrowCursor : Qt.PointingHandCursor // Changes cursor to arrow once triggered (can't interact further)
                                        
                                        onPressed: {                                                         // On mouse press
                                            if (!actionCapsule.triggered) {                                  // Only respond if action hasn't already been triggered
                                                drainAnim.stop();                                            // Stop any ongoing drain animation
                                                fillAnim.start();                                            // Start the fill animation (hold to activate)
                                            }
                                        }
                                        onReleased: {                                                        // On mouse release (before fill completes)
                                            if (!actionCapsule.triggered && actionCapsule.fillLevel < 1.0) {  // If not yet triggered and fill isn't complete
                                                fillAnim.stop();                                             // Stop filling
                                                drainAnim.start();                                           // Start draining back to empty
                                            }
                                        }
                                    }

                                    NumberAnimation {                                                        // Animation that fills the button from current level to 100%
                                        id: fillAnim; target: actionCapsule; property: "fillLevel"; to: 1.0
                                        duration: (550 * weight) * (1.0 - actionCapsule.fillLevel); easing.type: Easing.InSine // Duration proportional to weight and remaining distance
                                        onFinished: {                                                        // When fill completes (hold long enough)
                                            actionCapsule.triggered = true; actionCapsule.flashOpacity = 0.6; cardFlashAnim.start(); // Mark as triggered, start white flash
                                            exitAnim.start(); exitTimer.start();                             // Begin UI exit animation and execution timer
                                        }
                                    }
                                    
                                    NumberAnimation {                                                        // Animation that drains the fill back to empty
                                        id: drainAnim; target: actionCapsule; property: "fillLevel"; to: 0.0
                                        duration: 1500 * actionCapsule.fillLevel; easing.type: Easing.OutQuad // Drain takes up to 1.5 seconds depending on current fill level
                                    }

                                    Timer {                                                                  // Short delay timer before executing the system command
                                        id: exitTimer; interval: 500                                         // 500ms delay to allow exit animation to play visually
                                        onTriggered: { Quickshell.execDetached(["sh", "-c", cmd]); Quickshell.execDetached(["sh", "-c", "echo 'close' > /tmp/qs_widget_state"]); } // Executes the system command, then signals widget to close
                                    }
                                }
                            }
                        }

                        // 3. POWER PROFILES DOCK                                                        // Third dock: power profile selector (performance, balanced, power-saver)
                        Rectangle {                                                                          // Profile selector background card
                            Layout.fillWidth: true
                            Layout.preferredHeight: window.s(54)                                             // 54dp fixed height
                            radius: window.s(14)
                            color: window.surface0
                            border.color: window.surface1
                            border.width: 1

                            opacity: introProfiles                                                           // Fades with profiles intro animation
                            transform: Translate { y: window.s(20) * (1.0 - introProfiles) }                  // Slides up from below during intro
                            
                            Rectangle {                                                                      // Animated sliding pill indicator showing active profile
                                id: sliderPill
                                width: (parent.width - window.s(2)) / 3                                      // Width equals 1/3 of parent (minus small margin), one for each profile
                                height: parent.height - window.s(2)                                          // Almost full height (2dp smaller than parent)
                                y: window.s(1)                                                               // 1dp vertical offset for centering
                                radius: window.s(10)                                                         // Rounded pill shape
                                x: {                                                                         // X position depends on which profile is active
                                    if (window.powerProfile === "performance") return window.s(1);           // Far left position for performance
                                    if (window.powerProfile === "balanced") return width + window.s(1);      // Middle position for balanced (offset by one pill width)
                                    return (width * 2) + window.s(1);                                        // Far right position for power-saver (offset by two pill widths)
                                }
                                
                                Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } } // Smooth bouncing slide between profile positions
                                
                                gradient: Gradient {                                                         // Horizontal gradient for the pill
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: window.profileStart; Behavior on color { ColorAnimation{duration:400} } } // Profile-derived start color
                                    GradientStop { position: 1.0; color: window.profileEnd; Behavior on color { ColorAnimation{duration:400} } } // Profile-derived end color
                                }
                            }

                            RowLayout {                                                                      // Row layout with three equal sections for each profile
                                anchors.fill: parent
                                spacing: 0                                                                   // No spacing so sections touch edge-to-edge
                                
                                Repeater {                                                                   // Repeater to create the three profile options
                                    model: ListModel {                                                       // Inline model with the three power profiles
                                        ListElement { name: "performance"; icon: "󰓅"; label: "Perform" }     // Performance mode: bolt icon, "Perform" label
                                        ListElement { name: "balanced"; icon: "󰗑"; label: "Balance" }        // Balanced mode: scale icon, "Balance" label
                                        ListElement { name: "power-saver"; icon: "󰌪"; label: "Saver" }       // Power saver mode: leaf icon, "Saver" label
                                    }
                                    
                                    delegate: Item {                                                         // Delegate for each profile option
                                        Layout.fillWidth: true                                               // Each takes equal width (1/3 of row)
                                        Layout.fillHeight: true                                              // Full height
                                        
                                        RowLayout {                                                          // Row for icon and label text
                                            anchors.centerIn: parent                                         // Centered in the section
                                            spacing: window.s(8)
                                            Text {                                                           // Profile icon
                                                font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18)
                                                color: window.powerProfile === name ? window.crust : (profileMa.containsMouse ? window.text : window.subtext0) // Dark crust when active, text on hover, dim otherwise
                                                text: icon
                                                Behavior on color { ColorAnimation { duration: 200 } }
                                            }
                                            Text {                                                           // Profile label text
                                                font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(13)
                                                color: window.powerProfile === name ? window.crust : (profileMa.containsMouse ? window.text : window.subtext0) // Same color logic as icon
                                                text: label
                                                Behavior on color { ColorAnimation { duration: 200 } }
                                            }
                                        }
                                        
                                        MouseArea {                                                          // Click area to select this profile
                                            id: profileMa
                                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { Quickshell.execDetached(["powerprofilesctl", "set", name]); sysPoller.running = true; } // Sets the power profile via powerprofilesctl, then triggers immediate state refresh
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}