// import QtQuick
// import QtQuick.Window
// import QtQuick.Controls
// import QtQuick.Layouts
// import QtQuick.Effects
// import QtCore
// import Quickshell
// import Quickshell.Io
// import Quickshell.Wayland
// import Quickshell.Services.Pam
// import "../" // Assuming scaler.qml is available here

// ShellRoot {
//     id: root
//     MatugenColors { id: _theme }
//     readonly property color base: _theme.base
//     readonly property color crust: _theme.crust
//     readonly property color mantle: _theme.mantle
//     readonly property color text: _theme.text
//     readonly property color subtext0: _theme.subtext0
//     readonly property color overlay0: _theme.overlay0
//     readonly property color overlay2: _theme.overlay2
//     readonly property color surface0: _theme.surface0
//     readonly property color surface1: _theme.surface1
//     readonly property color surface2: _theme.surface2

//     readonly property color mauve: _theme.mauve
//     readonly property color red: _theme.red
//     readonly property color peach: _theme.peach
//     readonly property color blue: _theme.blue
//     readonly property color green: _theme.green

//     // Persistent Settings
//     Settings {
//         id: lockSettings
//         category: "QuickshellLockscreen"
//         property bool hidePassword: false
//         property int revealDuration: 300
//     }

//     // Shared state across all monitors
//     QtObject {
//         id: lockUI
//         property bool failed: false
//         property bool authenticating: false
//         property string statusText: "Locked"
//     }

//     // System Authentication hook
//     PamContext {
//         id: pam
        
//         Component.onCompleted: pam.start()

//         onCompleted: (result) => {
//             lockUI.authenticating = false;
//             if (result === PamResult.Success) {
//                 rootLock.locked = false;
//                 Qt.quit();
//             } else {
//                 lockUI.failed = true;
//                 lockUI.statusText = "Access Denied";
//                 pam.start();
//             }
//         }
//     }

//     Process {
//         id: suspendProcess
//         command: ["systemctl", "suspend"]
//     }

//     Process {
//         id: poweroffProcess
//         command: ["systemctl", "poweroff"]
//     }

//     Process {
//         id: reloadProcess
//         command: ["systemctl", "reboot"]
//     }

//     WlSessionLock {
//         id: rootLock
//         locked: true

//         WlSessionLockSurface {
//             id: surface

//             Item {
//                 id: screenRoot
//                 anchors.fill: parent

//                 // --- Responsive Scaling Logic ---
//                 // We use a property binding instead of a function to ensure 
//                 // continuous updates even if surface width starts at 0.
//                 Scaler {
//                     id: scaler
//                     currentWidth: screenRoot.width > 0 ? screenRoot.width : Screen.width
//                 }
//                 readonly property real sc: scaler.baseScale
//                 // --------------------------------

//                 property string staticWallpaperPath: "file:///tmp/lock_bg.png"

//                 property string batPct: "100"
//                 property string batStatus: "AC"
//                 property string currentUser: "User"
//                 property string faceIconPath: ""
//                 property string kbLayout: "US"
//                 property string weatherIcon: ""
//                 property string weatherTemp: "--°C"

//                 // UI States
//                 property real introState: 0.0
//                 property bool powerMenuOpen: false
//                 property bool inputActive: false 
//                 property bool isPlayingIntro: true
//                 property bool isDesktop: false
                
//                 Component.onCompleted: {
//                     introSequence.start();
//                 }

//                 property real globalOrbitAngle: 0
//                 NumberAnimation on globalOrbitAngle {
//                     from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
//                 }

//                 // Auto-hide input field if empty and idle for 15 seconds
//                 Timer {
//                     id: idleTimer
//                     interval: 15000
//                     running: screenRoot.inputActive && inputField.text.length === 0
//                     repeat: false
//                     onTriggered: screenRoot.inputActive = false
//                 }

//                 // ---------------------------------------------------------
//                 // BACKGROUND DATA POLLING 
//                 // ---------------------------------------------------------

//                 Process {
//                     id: chassisDetector
//                     running: true
//                     command: ["bash", "-c", "if ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then echo 'laptop'; else echo 'desktop'; fi"]
//                     stdout: StdioCollector {
//                         onStreamFinished: {
//                             screenRoot.isDesktop = (this.text.trim() === "desktop");
//                         }
//                     }
//                 }

//                 Process {
//                     id: userPoller
//                     command: [
//                         "bash", 
//                         "-c", 
//                         "USER_VAR=$(whoami); ICON_PATH=\"\"; if [ -f ~/.face.icon ]; then ICON_PATH=$(readlink -f ~/.face.icon); elif [ -f ~/.face ]; then ICON_PATH=$(readlink -f ~/.face); fi; echo -n \"$USER_VAR|$ICON_PATH\""
//                     ]
//                     stdout: StdioCollector {
//                         onStreamFinished: {
//                             let parts = this.text.trim().split("|");
//                             if (parts.length > 0 && parts[0] !== "") screenRoot.currentUser = parts[0];
//                             if (parts.length > 1 && parts[1].trim() !== "") {
//                                 let path = parts[1].trim();
//                                 screenRoot.faceIconPath = path.startsWith("file://") ? path : "file://" + path;
//                             }
//                         }
//                     }
//                     Component.onCompleted: running = true
//                 }
                
//                 Process {
//                     id: kbPoller
//                     command: ["bash", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n1 | cut -c1-2 | tr '[:lower:]' '[:upper:]'"]
//                     stdout: StdioCollector {
//                         onStreamFinished: {
//                             let layout = this.text.trim();
//                             if (layout !== "" && layout !== "null") {
//                                 screenRoot.kbLayout = layout;
//                             }
//                         }
//                     }
//                 }
//                 Timer { interval: 150; running: true; repeat: true; triggeredOnStart: true; onTriggered: kbPoller.running = true }

//                 Process {
//                     id: batPoller
//                     running: !screenRoot.isDesktop
//                     command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo '100'; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1 || echo 'AC'"]
//                     stdout: StdioCollector {
//                         onStreamFinished: {
//                             let lines = this.text.trim().split("\n");
//                             if (lines.length >= 2) {
//                                 screenRoot.batPct = lines[0] || "100";
//                                 screenRoot.batStatus = lines[1] || "Unknown";
//                             }
//                         }
//                     }
//                 }
//                 Timer { interval: 5000; running: !screenRoot.isDesktop; repeat: true; triggeredOnStart: true; onTriggered: batPoller.running = true }

//                 Process {
//                     id: weatherPoller
//                     property string scriptPath: Qt.resolvedUrl("calendar/weather.sh").toString().replace(/^file:\/\//, "")
//                     command: ["bash", "-c", '"' + scriptPath + '" --current-icon; "' + scriptPath + '" --current-temp']
//                     stdout: StdioCollector {
//                         onStreamFinished: {
//                             let lines = this.text.trim().split("\n");
//                             if (lines.length >= 2) {
//                                 screenRoot.weatherIcon = lines[0] || "";
//                                 screenRoot.weatherTemp = lines[1] || "--°C";
//                             }
//                         }
//                     }
//                 }
//                 Timer { interval: 900000; running: true; repeat: true; triggeredOnStart: true; onTriggered: weatherPoller.running = true }

//                 // ---------------------------------------------------------
//                 // 1. LIVING BACKGROUND
//                 // ---------------------------------------------------------
                
//                 Rectangle {
//                     anchors.fill: parent
//                     color: root.base
//                 }

//                 Image {
//                     id: bgWallpaper
//                     anchors.fill: parent
//                     source: screenRoot.staticWallpaperPath
//                     fillMode: Image.PreserveAspectCrop
//                     asynchronous: true
//                     visible: false 
//                     cache: false 
//                 }

//                 MultiEffect {
//                     source: bgWallpaper
//                     anchors.fill: bgWallpaper
//                     blurEnabled: true
//                     blurMax: 64 * screenRoot.sc
//                     blur: 1.0
//                 }
                
//                 Rectangle {
//                     id: dimmer
//                     anchors.fill: parent
//                     color: "black"
//                     opacity: 0.25 
//                 }

//                 Item {
//                     anchors.fill: parent

//                     Rectangle {
//                         width: parent.width * 0.8; height: width; radius: width / 2
//                         x: (parent.width / 2 - width / 2) + Math.cos(screenRoot.globalOrbitAngle * 2) * (200 * screenRoot.sc)
//                         y: (parent.height / 2 - height / 2) + Math.sin(screenRoot.globalOrbitAngle * 2) * (150 * screenRoot.sc)
//                         scale: 1.0 + Math.sin(screenRoot.globalOrbitAngle * 6) * 0.05
//                         opacity: screenRoot.inputActive ? 0.04 : 0.08
//                         color: root.mauve
//                         Behavior on color { ColorAnimation { duration: 1000 } }
//                         Behavior on opacity { NumberAnimation { duration: 600 } }
//                     }
                    
//                     Rectangle {
//                         width: parent.width * 0.9; height: width; radius: width / 2
//                         x: (parent.width / 2 - width / 2) + Math.sin(screenRoot.globalOrbitAngle * 1.5) * (-200 * screenRoot.sc)
//                         y: (parent.height / 2 - height / 2) + Math.cos(screenRoot.globalOrbitAngle * 1.5) * (-150 * screenRoot.sc)
//                         scale: 1.0 + Math.cos(screenRoot.globalOrbitAngle * 5) * 0.05
//                         opacity: screenRoot.inputActive ? 0.03 : 0.06
//                         color: root.blue
//                         Behavior on color { ColorAnimation { duration: 1000 } }
//                         Behavior on opacity { NumberAnimation { duration: 600 } }
//                     }

//                     Item {
//                         anchors.fill: parent
//                         opacity: screenRoot.introState
//                         scale: 1.1 - (0.1 * screenRoot.introState)
                        
//                         Repeater {
//                             model: 4
//                             Rectangle {
//                                 anchors.centerIn: parent
//                                 anchors.verticalCenterOffset: -40 * screenRoot.sc
//                                 width: (400 * screenRoot.sc) + (index * (220 * screenRoot.sc))
//                                 height: width
//                                 radius: width / 2
//                                 color: "transparent"
//                                 border.color: lockUI.failed ? root.red : root.text
//                                 border.width: Math.max(1, 1 * screenRoot.sc)
//                                 opacity: lockUI.failed ? (0.1 - (index * 0.02)) : (screenRoot.inputActive ? (0.02 - (index * 0.005)) : (0.04 - (index * 0.01)))
//                                 Behavior on border.color { ColorAnimation { duration: 600; easing.type: Easing.OutExpo } }
//                                 Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
//                             }
//                         }
//                     }
//                 }

//                 // ---------------------------------------------------------
//                 // 2. MAIN CONTENT LAYER
//                 // ---------------------------------------------------------
//                 MouseArea {
//                     anchors.fill: parent
//                     enabled: !screenRoot.isPlayingIntro
//                     onClicked: {
//                         if (screenRoot.powerMenuOpen) screenRoot.powerMenuOpen = false;
//                         if (!screenRoot.inputActive) screenRoot.inputActive = true;
//                         inputField.forceActiveFocus();
//                     }
//                 }

//                 Item {
//                     anchors.fill: parent
//                     opacity: screenRoot.introState
//                     transform: Translate { y: (30 * screenRoot.sc) * (1.0 - screenRoot.introState) }

//                     // --- CLOCK MODULE (Idle State) ---
//                     ColumnLayout {
//                         id: clockModule
//                         anchors.centerIn: parent
//                         anchors.verticalCenterOffset: screenRoot.inputActive ? (-120 * screenRoot.sc) : (-40 * screenRoot.sc)
//                         spacing: -10 * screenRoot.sc
                        
//                         opacity: screenRoot.inputActive ? 0.0 : 1.0
//                         scale: screenRoot.inputActive ? 0.9 : 1.0
//                         visible: opacity > 0.01

//                         Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
//                         Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
//                         Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

//                         RowLayout {
//                             Layout.alignment: Qt.AlignHCenter
//                             spacing: 0
                            
//                             Text {
//                                 id: clockHours
//                                 font.family: "JetBrains Mono"
//                                 font.pixelSize: 140 * screenRoot.sc
//                                 font.weight: Font.Bold
//                                 color: root.text
//                                 Behavior on color { ColorAnimation { duration: 300 } }
//                             }
//                             Text {
//                                 text: ":"
//                                 font.family: "JetBrains Mono"
//                                 font.pixelSize: 140 * screenRoot.sc
//                                 font.weight: Font.Bold
//                                 opacity: 0.5
//                                 color: root.text
//                                 Behavior on color { ColorAnimation { duration: 300 } }
//                             }
//                             Text {
//                                 id: clockMinutes
//                                 font.family: "JetBrains Mono"
//                                 font.pixelSize: 140 * screenRoot.sc
//                                 font.weight: Font.Bold
//                                 color: root.text
//                                 Behavior on color { ColorAnimation { duration: 300 } }
//                             }
//                         }

//                         Text {
//                             id: dateText
//                             Layout.alignment: Qt.AlignHCenter
//                             font.family: "JetBrains Mono"
//                             font.pixelSize: 22 * screenRoot.sc
//                             font.weight: Font.Bold
//                             color: root.text
//                         }

//                         Timer {
//                             interval: 1000; running: true; repeat: true; triggeredOnStart: true
//                             onTriggered: {
//                                 let d = new Date();
//                                 clockHours.text = Qt.formatDateTime(d, "hh");
//                                 clockMinutes.text = Qt.formatDateTime(d, "mm");
//                                 dateText.text = Qt.formatDateTime(d, "dddd, MMMM dd");
//                             }
//                         }
//                     }

//                     // --- AUTHENTICATION MODULE (Input State) ---
//                     RowLayout {
//                         id: authModule
//                         anchors.centerIn: parent
//                         anchors.verticalCenterOffset: screenRoot.inputActive ? (-40 * screenRoot.sc) : (40 * screenRoot.sc)
//                         spacing: 32 * screenRoot.sc 
                        
//                         opacity: screenRoot.inputActive ? 1.0 : 0.0
//                         scale: screenRoot.inputActive ? 1.0 : 0.9
//                         visible: opacity > 0.01

//                         Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
//                         Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
//                         Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

//                         // Left: Enlarged Avatar
//                         Item {
//                             Layout.alignment: Qt.AlignVCenter
//                             width: 170 * screenRoot.sc
//                             height: width // Force square aspect ratio

//                             Rectangle {
//                                 id: avatarMask
//                                 anchors.fill: parent
//                                 radius: height / 2 // Dynamic perfect radius
//                                 color: "black"
//                                 visible: false 
//                                 layer.enabled: true 
//                             }

//                             Rectangle {
//                                 anchors.fill: parent
//                                 radius: height / 2
//                                 color: Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.5)
//                                 visible: avatarImg.status !== Image.Ready
                                
//                                 Text {
//                                     anchors.centerIn: parent
//                                     text: "󰄽"
//                                     font.family: "Iosevka Nerd Font"
//                                     font.pixelSize: 64 * screenRoot.sc
//                                     color: root.subtext0
//                                 }
//                             }

//                             Image {
//                                 id: avatarImg
//                                 anchors.fill: parent
//                                 source: screenRoot.faceIconPath !== "" ? screenRoot.faceIconPath : ""
//                                 fillMode: Image.PreserveAspectCrop
//                                 visible: false 
//                                 cache: false
//                                 asynchronous: true
//                             }

//                             MultiEffect {
//                                 source: avatarImg
//                                 anchors.fill: avatarImg
//                                 maskEnabled: true
//                                 maskSource: avatarMask
//                                 visible: avatarImg.status === Image.Ready
//                             }

//                             Rectangle {
//                                 anchors.fill: parent
//                                 radius: height / 2
//                                 color: "transparent"
//                                 border.color: lockUI.failed ? root.red : (lockUI.authenticating ? root.peach : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.5))
//                                 border.width: Math.max(1, 3 * screenRoot.sc)
//                                 Behavior on border.color { ColorAnimation { duration: 300 } }
//                             }
//                         }

//                         // Right: Text Details & Input
//                         ColumnLayout {
//                             Layout.alignment: Qt.AlignVCenter
//                             spacing: 16 * screenRoot.sc

//                             Text {
//                                 Layout.alignment: Qt.AlignLeft
//                                 text: screenRoot.currentUser
//                                 font.family: "JetBrains Mono"
//                                 font.pixelSize: 28 * screenRoot.sc
//                                 font.weight: Font.Bold
//                                 color: root.text
//                             }

//                             RowLayout {
//                                 Layout.alignment: Qt.AlignLeft
//                                 spacing: 12 * screenRoot.sc

//                                 Rectangle {
//                                     width: 36 * screenRoot.sc
//                                     height: width // Force square
//                                     radius: height / 2 // Perfect circle
                                    
//                                     color: lockUI.failed
//                                         ? Qt.rgba(root.red.r,   root.red.g,   root.red.b,   0.2)
//                                         : (lockUI.authenticating
//                                             ? Qt.rgba(root.peach.r, root.peach.g, root.peach.b, 0.2)
//                                             : Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.15))
//                                     border.color: lockUI.failed
//                                         ? root.red
//                                         : (lockUI.authenticating ? root.peach : root.mauve)
//                                     border.width: Math.max(1, 1 * screenRoot.sc)
//                                     Behavior on color { ColorAnimation { duration: 300 } }
//                                     Behavior on border.color { ColorAnimation { duration: 300 } }

//                                     Text {
//                                         anchors.centerIn: parent
//                                         text: lockUI.failed ? "󰌾" : (lockUI.authenticating ? "󰌿" : "󰌾")
//                                         font.family: "Iosevka Nerd Font"
//                                         font.pixelSize: 18 * screenRoot.sc
//                                         color: lockUI.failed
//                                             ? root.red
//                                             : (lockUI.authenticating ? root.peach : root.mauve)
//                                         Behavior on color { ColorAnimation { duration: 300 } }
//                                     }
//                                 }

//                                 Text {
//                                     font.family: "JetBrains Mono"
//                                     font.pixelSize: 14 * screenRoot.sc
//                                     font.weight: Font.Medium
//                                     font.letterSpacing: 2.0
//                                     color: lockUI.failed
//                                         ? root.red
//                                         : (lockUI.authenticating ? root.peach : root.text)
//                                     text: lockUI.statusText.toUpperCase()
//                                     Behavior on color { ColorAnimation { duration: 300 } }
//                                 }
//                             }

//                             Rectangle {
//                                 id: pinPill
//                                 Layout.alignment: Qt.AlignLeft
//                                 width: 280 * screenRoot.sc
//                                 height: 60 * screenRoot.sc
//                                 radius: height / 2 // Perfect pill shape natively!
//                                 clip: true 
                                
//                                 color: lockUI.failed ? Qt.rgba(root.red.r, root.red.g, root.red.b, 0.1) : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.5)
//                                 border.width: Math.max(1, 2 * screenRoot.sc)
//                                 border.color: {
//                                     if (lockUI.failed) return root.red;
//                                     if (lockUI.authenticating) return root.peach;
//                                     if (inputField.text.length > 0) return root.text;
//                                     return Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08);
//                                 }

//                                 Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                                 Behavior on border.color { ColorAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                
//                                 scale: lockUI.failed ? 1.05 : (lockUI.authenticating ? 0.98 : 1.0)
//                                 Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

//                                 transform: Translate { id: shakeTranslate; x: 0 }
                                
//                                 SequentialAnimation {
//                                     id: shakeAnim
//                                     NumberAnimation { target: shakeTranslate; property: "x"; from: 0; to: -8 * screenRoot.sc; duration: 120; easing.type: Easing.InOutSine }
//                                     NumberAnimation { target: shakeTranslate; property: "x"; from: -8 * screenRoot.sc; to: 8 * screenRoot.sc; duration: 120; easing.type: Easing.InOutSine }
//                                     NumberAnimation { target: shakeTranslate; property: "x"; from: 8 * screenRoot.sc; to: 0; duration: 120; easing.type: Easing.InOutSine }
//                                 }

//                                 Connections {
//                                     target: lockUI
//                                     function onFailedChanged() {
//                                         if (lockUI.failed) shakeAnim.restart();
//                                     }
//                                 }

//                                 TextInput {
//                                     id: inputField
//                                     anchors.fill: parent
//                                     opacity: 0 
//                                     echoMode: TextInput.Password
//                                     enabled: !screenRoot.isPlayingIntro
                                    
//                                     property string oldText: ""
                                    
//                                     Component.onCompleted: forceActiveFocus()
                                    
//                                     onActiveFocusChanged: {
//                                         if (!activeFocus && !screenRoot.powerMenuOpen && !screenRoot.isPlayingIntro) {
//                                             forceActiveFocus();
//                                         }
//                                     }

//                                     Keys.onPressed: (event) => {
//                                         if (event.key === Qt.Key_Escape) {
//                                             screenRoot.inputActive = false;
//                                             text = "";
//                                             passModel.clear();
//                                             event.accepted = true;
//                                         } 
//                                         else if (!screenRoot.inputActive) {
//                                             screenRoot.inputActive = true;
//                                         }
//                                     }
                                    
//                                     onAccepted: {
//                                         if (text.length > 0 && pam.responseRequired && !lockUI.authenticating) {
//                                             lockUI.authenticating = true;
//                                             lockUI.statusText = "Authenticating...";
//                                             lockUI.failed = false;
//                                             pam.respond(text);
//                                             text = ""; 
//                                             oldText = "";
//                                             passModel.clear();
//                                         }
//                                     }
                                    
//                                     onTextChanged: {
//                                         if (lockUI.authenticating) return;

//                                         if (text.length > 0 && !screenRoot.inputActive) {
//                                             screenRoot.inputActive = true;
//                                         }
                                        
//                                         idleTimer.restart();
                                        
//                                         if (text !== oldText) {
//                                             if (text.length > oldText.length) {
//                                                 for (let i = oldText.length; i < text.length; i++) {
//                                                     passModel.append({ "charStr": text.charAt(i), "isDot": lockSettings.hidePassword });
//                                                 }
//                                             } else if (text.length < oldText.length) {
//                                                 let diff = oldText.length - text.length;
//                                                 for (let i = 0; i < diff; i++) {
//                                                     passModel.remove(passModel.count - 1);
//                                                 }
//                                             } else {
//                                                 passModel.clear();
//                                                 for (let i = 0; i < text.length; i++) {
//                                                     passModel.append({ "charStr": text.charAt(i), "isDot": lockSettings.hidePassword });
//                                                 }
//                                             }
//                                             oldText = text;
//                                         }

//                                         if (text.length > 0) {
//                                             lockUI.failed = false;
//                                             lockUI.statusText = "Enter PIN";
//                                         } else {
//                                             if (!lockUI.failed) lockUI.statusText = "Locked";
//                                         }
//                                     }
//                                 }

//                                 ListModel {
//                                     id: passModel
//                                 }

//                                 Item {
//                                     anchors.fill: parent
//                                     anchors.leftMargin: 20 * screenRoot.sc
//                                     anchors.rightMargin: 20 * screenRoot.sc
//                                     clip: true

//                                     Row {
//                                         id: dotRow
//                                         anchors.verticalCenter: parent.verticalCenter
//                                         x: width > parent.width ? parent.width - width : (parent.width - width) / 2
//                                         spacing: 4 * screenRoot.sc
                                        
//                                         Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

//                                         Repeater {
//                                             model: passModel
//                                             // Render text directly as the delegate to avoid circular layout loops
//                                             delegate: Text {
//                                                 text: model.isDot ? "•" : model.charStr
//                                                 font.family: "JetBrains Mono"
//                                                 font.pixelSize: model.isDot ? (32 * screenRoot.sc) : (24 * screenRoot.sc)
//                                                 font.weight: Font.Bold
//                                                 color: lockUI.failed ? root.red : (lockUI.authenticating ? root.peach : root.text)
//                                                 verticalAlignment: Text.AlignVCenter
//                                                 height: pinPill.height
                                                
//                                                 NumberAnimation on opacity { from: 0; to: 1; duration: 150 }
                                                
//                                                 Timer {
//                                                     interval: lockSettings.revealDuration
//                                                     running: !model.isDot && !lockSettings.hidePassword
//                                                     onTriggered: {
//                                                         if (index >= 0 && index < passModel.count) {
//                                                             passModel.setProperty(index, "isDot", true);
//                                                         }
//                                                     }
//                                                 }
//                                             }
//                                         }
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }

//                 // ---------------------------------------------------------
//                 // 3. BOTTOM SYSTEM INFO PILLS
//                 // ---------------------------------------------------------
//                 RowLayout {
//                     anchors.bottom: parent.bottom
//                     anchors.bottomMargin: 40 * screenRoot.sc
//                     anchors.horizontalCenter: parent.horizontalCenter
//                     spacing: 16 * screenRoot.sc

//                     opacity: screenRoot.introState
//                     transform: Translate { y: (20 * screenRoot.sc) * (1.0 - screenRoot.introState) }

//                     // KB Layout Pill
//                     Rectangle {
//                         property bool isHovered: kbMouse.containsMouse
//                         Layout.preferredHeight: 48 * screenRoot.sc
//                         Layout.preferredWidth: kbLayoutRow.implicitWidth + (36 * screenRoot.sc)
//                         radius: height / 2 // Dynamic pill shape
                        
//                         color: isHovered ? Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.6) : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.4)
//                         border.color: isHovered ? root.mauve : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08)
//                         border.width: Math.max(1, 1 * screenRoot.sc)
                        
//                         scale: isHovered ? 1.05 : 1.0
//                         Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                         Behavior on color { ColorAnimation { duration: 200 } }
//                         Behavior on border.color { ColorAnimation { duration: 200 } }

//                         RowLayout { 
//                             id: kbLayoutRow; anchors.centerIn: parent; spacing: 8 * screenRoot.sc
//                             Text { text: "󰌌"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18 * screenRoot.sc; color: parent.parent.isHovered ? root.mauve : root.overlay2; Behavior on color { ColorAnimation { duration: 200 } } }
//                             Text { text: screenRoot.kbLayout; font.family: "JetBrains Mono"; font.pixelSize: 14 * screenRoot.sc; font.weight: Font.Black; color: root.text }
//                         }
//                         MouseArea { id: kbMouse; anchors.fill: parent; hoverEnabled: true; enabled: !screenRoot.isPlayingIntro }
//                     }

//                     // Battery Pill
//                     Rectangle {
//                         property bool isHovered: batMouse.containsMouse
//                         visible: !screenRoot.isDesktop
//                         Layout.preferredHeight: 48 * screenRoot.sc
//                         Layout.preferredWidth: batLayoutRow.implicitWidth + (36 * screenRoot.sc)
//                         radius: height / 2
                        
//                         color: isHovered ? Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.6) : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.4)
//                         border.color: isHovered ? batLayoutRow.dynamicBatColor : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08)
//                         border.width: Math.max(1, 1 * screenRoot.sc)

//                         scale: isHovered ? 1.05 : 1.0
//                         Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                         Behavior on color { ColorAnimation { duration: 200 } }
//                         Behavior on border.color { ColorAnimation { duration: 200 } }

//                         RowLayout { 
//                             id: batLayoutRow; anchors.centerIn: parent; spacing: 8 * screenRoot.sc
                            
//                             property color dynamicBatColor: {
//                                 if (screenRoot.batStatus === "Charging") return root.green;
//                                 let pct = parseInt(screenRoot.batPct);
//                                 if (pct >= 60) return root.green;
//                                 if (pct >= 25) return root.peach;
//                                 return root.red;
//                             }

//                             Text { 
//                                 text: screenRoot.batStatus === "Charging" ? "󰂄" : (parseInt(screenRoot.batPct) < 20 ? "󰂃" : "󰁹")
//                                 font.family: "Iosevka Nerd Font"
//                                 font.pixelSize: 20 * screenRoot.sc
//                                 color: batLayoutRow.dynamicBatColor
//                                 Behavior on color { ColorAnimation { duration: 200 } }
//                             }
//                             Text { 
//                                 text: screenRoot.batPct + "%"
//                                 font.family: "JetBrains Mono"
//                                 font.pixelSize: 14 * screenRoot.sc
//                                 font.weight: Font.Black
//                                 color: batLayoutRow.dynamicBatColor
//                                 Behavior on color { ColorAnimation { duration: 200 } }
//                             }
//                         }
//                         MouseArea { id: batMouse; anchors.fill: parent; hoverEnabled: true; enabled: !screenRoot.isPlayingIntro }
//                     }

//                     // Weather Pill
//                     Rectangle {
//                         property bool isHovered: weatherMouse.containsMouse
//                         Layout.preferredHeight: 48 * screenRoot.sc
//                         Layout.preferredWidth: weatherLayoutRow.implicitWidth + (36 * screenRoot.sc)
//                         radius: height / 2
                        
//                         color: isHovered ? Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.6) : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.4)
//                         border.color: isHovered ? root.blue : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08)
//                         border.width: Math.max(1, 1 * screenRoot.sc)

//                         scale: isHovered ? 1.05 : 1.0
//                         Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                         Behavior on color { ColorAnimation { duration: 200 } }
//                         Behavior on border.color { ColorAnimation { duration: 200 } }

//                         RowLayout { 
//                             id: weatherLayoutRow; anchors.centerIn: parent; spacing: 8 * screenRoot.sc
//                             Text { 
//                                 text: screenRoot.weatherIcon
//                                 font.family: "Iosevka Nerd Font"
//                                 font.pixelSize: 20 * screenRoot.sc
//                                 color: parent.parent.isHovered ? root.blue : root.text
//                                 Behavior on color { ColorAnimation { duration: 200 } }
//                             }
//                             Text { 
//                                 text: screenRoot.weatherTemp
//                                 font.family: "JetBrains Mono"
//                                 font.pixelSize: 14 * screenRoot.sc
//                                 font.weight: Font.Black
//                                 color: root.text
//                                 Behavior on color { ColorAnimation { duration: 200 } }
//                             }
//                         }
//                         MouseArea { id: weatherMouse; anchors.fill: parent; hoverEnabled: true; enabled: !screenRoot.isPlayingIntro }
//                     }
//                 }

//                 // ---------------------------------------------------------
//                 // 4. POWER MENU
//                 // ---------------------------------------------------------
//                 Rectangle {
//                     id: powerMenu
//                     anchors.bottom: powerBtn.top
//                     anchors.right: parent.right
//                     anchors.bottomMargin: 15 * screenRoot.sc
//                     anchors.rightMargin: 40 * screenRoot.sc
//                     width: 280 * screenRoot.sc
//                     height: screenRoot.powerMenuOpen ? (menuLayout.implicitHeight + (20 * screenRoot.sc)) : 0
//                     radius: 18 * screenRoot.sc
//                     clip: true
//                     opacity: screenRoot.powerMenuOpen ? 1 : 0
                    
//                     color: Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.95)
//                     border.color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.25)
//                     border.width: Math.max(1, 1 * screenRoot.sc)

//                     Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
//                     Behavior on opacity { NumberAnimation { duration: 250 } }

//                     ColumnLayout {
//                         id: menuLayout
//                         anchors.top: parent.top
//                         anchors.topMargin: 10 * screenRoot.sc
//                         anchors.left: parent.left
//                         anchors.right: parent.right
//                         spacing: 6 * screenRoot.sc

//                         // --- SETTINGS SECTION ---
//                         Text { 
//                             text: "SETTINGS"
//                             font.family: "JetBrains Mono"
//                             font.weight: Font.Black
//                             font.pixelSize: 12 * screenRoot.sc
//                             font.letterSpacing: 1.5
//                             color: root.mauve
//                             Layout.leftMargin: 18 * screenRoot.sc; Layout.topMargin: 4 * screenRoot.sc; Layout.bottomMargin: 4 * screenRoot.sc 
//                         }

//                         // Hide Password Toggle
//                         RowLayout {
//                             Layout.fillWidth: true; Layout.leftMargin: 18 * screenRoot.sc; Layout.rightMargin: 18 * screenRoot.sc; Layout.topMargin: 4 * screenRoot.sc
//                             Text {
//                                 text: "Hide password"
//                                 font.family: "JetBrains Mono"
//                                 font.pixelSize: 14 * screenRoot.sc
//                                 font.weight: Font.Medium
//                                 color: root.text
//                                 Layout.fillWidth: true
//                             }
                            
//                             Rectangle {
//                                 width: 40 * screenRoot.sc; height: 22 * screenRoot.sc; radius: height / 2
//                                 color: lockSettings.hidePassword ? root.mauve : root.surface2
//                                 Behavior on color { ColorAnimation { duration: 250 } }
                                
//                                 Rectangle {
//                                     width: height; height: 18 * screenRoot.sc; radius: height / 2
//                                     x: lockSettings.hidePassword ? parent.width - width - (2 * screenRoot.sc) : (2 * screenRoot.sc)
//                                     y: (parent.height - height) / 2
//                                     color: root.base
//                                     Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
//                                 }
//                                 MouseArea { 
//                                     anchors.fill: parent; 
//                                     onClicked: {
//                                         lockSettings.hidePassword = !lockSettings.hidePassword;
//                                         if (lockSettings.hidePassword) {
//                                             for(let i = 0; i < passModel.count; i++) passModel.setProperty(i, "isDot", true);
//                                         }
//                                     }
//                                 }
//                             }
//                         }

//                         // Reveal Delay Slider
//                         ColumnLayout {
//                             Layout.fillWidth: true; Layout.leftMargin: 18 * screenRoot.sc; Layout.rightMargin: 18 * screenRoot.sc; Layout.topMargin: 8 * screenRoot.sc; Layout.bottomMargin: 8 * screenRoot.sc; spacing: 8 * screenRoot.sc
//                             opacity: lockSettings.hidePassword ? 0.3 : 1.0
//                             Behavior on opacity { NumberAnimation { duration: 200 } }
                            
//                             RowLayout {
//                                 Layout.fillWidth: true
//                                 Text {
//                                     text: "Reveal delay"
//                                     font.family: "JetBrains Mono"
//                                     font.pixelSize: 14 * screenRoot.sc
//                                     font.weight: Font.Medium
//                                     color: root.blue
//                                     Layout.fillWidth: true
//                                 }
//                                 Text { 
//                                     text: lockSettings.revealDuration >= 1000 ? (lockSettings.revealDuration / 1000).toFixed(1) + " s" : lockSettings.revealDuration + " ms"
//                                     font.family: "JetBrains Mono"
//                                     font.pixelSize: 13 * screenRoot.sc
//                                     font.weight: Font.Bold
//                                     color: root.peach
//                                 }
//                             }
                            
//                             Item {
//                                 Layout.fillWidth: true; Layout.preferredHeight: 28 * screenRoot.sc
                                
//                                 Rectangle {
//                                     anchors.verticalCenter: parent.verticalCenter
//                                     width: parent.width; height: 8 * screenRoot.sc; radius: height / 2; color: root.surface2
//                                     Rectangle {
//                                         width: ((lockSettings.revealDuration - 100) / 2900) * parent.width
//                                         height: parent.height; radius: height / 2; color: root.mauve
//                                     }
//                                 }
                                
//                                 Rectangle {
//                                     id: sliderThumb
//                                     width: 20 * screenRoot.sc
//                                     height: width
//                                     radius: height / 2
//                                     color: root.peach
//                                     border.color: root.crust; border.width: Math.max(1, 2 * screenRoot.sc)
//                                     anchors.verticalCenter: parent.verticalCenter
//                                     x: Math.max(0, Math.min(((lockSettings.revealDuration - 100) / 2900) * parent.width - (width / 2), parent.width - width))
                                    
//                                     scale: sliderMouse.pressed ? 1.3 : (sliderMouse.containsMouse ? 1.15 : 1.0)
//                                     Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
//                                 }
                                
//                                 MultiEffect {
//                                     source: sliderThumb
//                                     anchors.fill: sliderThumb
//                                     shadowEnabled: true
//                                     shadowBlur: 0.5
//                                     shadowColor: "#000000"
//                                     shadowOpacity: 0.4
//                                     shadowVerticalOffset: 2 * screenRoot.sc
//                                 }

//                                 MouseArea {
//                                     id: sliderMouse
//                                     anchors.fill: parent
//                                     hoverEnabled: true
//                                     enabled: !lockSettings.hidePassword
//                                     preventStealing: true
                                    
//                                     function updateVal(mouseX) {
//                                         let pct = Math.max(0, Math.min(1, mouseX / width));
//                                         let ms = Math.round(100 + (pct * 2900));
//                                         if (ms % 100 < 10) ms -= (ms % 100);
//                                         else if (ms % 100 > 90) ms += (100 - (ms % 100));
//                                         lockSettings.revealDuration = ms;
//                                     }

//                                     onPositionChanged: (mouse) => {
//                                         if (pressed) {
//                                             updateVal(mouse.x);
//                                         }
//                                     }
//                                     onPressed: (mouse) => updateVal(mouse.x)
//                                 }
//                             }
//                         }

//                         // Separator
//                         Rectangle {
//                             Layout.fillWidth: true; Layout.preferredHeight: Math.max(1, 1 * screenRoot.sc)
//                             color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.2)
//                             Layout.leftMargin: 18 * screenRoot.sc; Layout.rightMargin: 18 * screenRoot.sc; Layout.topMargin: 4 * screenRoot.sc; Layout.bottomMargin: 4 * screenRoot.sc
//                         }

//                         // --- SYSTEM ACTIONS SECTION ---
//                         Text {
//                             text: "SYSTEM"
//                             font.family: "JetBrains Mono"
//                             font.weight: Font.Black
//                             font.pixelSize: 12 * screenRoot.sc
//                             font.letterSpacing: 1.5
//                             color: root.mauve
//                             Layout.leftMargin: 18 * screenRoot.sc; Layout.bottomMargin: 4 * screenRoot.sc
//                         }

//                         Rectangle {
//                             Layout.fillWidth: true; Layout.preferredHeight: 48 * screenRoot.sc; Layout.leftMargin: 10 * screenRoot.sc; Layout.rightMargin: 10 * screenRoot.sc; radius: 12 * screenRoot.sc
//                             color: ma1.containsMouse ? Qt.rgba(root.blue.r, root.blue.g, root.blue.b, 0.1) : "transparent"
//                             scale: ma1.pressed ? 0.95 : (ma1.containsMouse ? 1.02 : 1.0)
//                             Behavior on color { ColorAnimation { duration: 200 } }
//                             Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            
//                             RowLayout {
//                                 anchors.fill: parent; anchors.leftMargin: 16 * screenRoot.sc; anchors.rightMargin: 16 * screenRoot.sc; spacing: 0
//                                 Text { text: "󰜉"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18 * screenRoot.sc; color: ma1.containsMouse ? root.blue : Qt.rgba(root.blue.r, root.blue.g, root.blue.b, 0.6); Behavior on color { ColorAnimation { duration: 200 } } }
//                                 Item { Layout.fillWidth: true }
//                                 Text { text: "Reboot"; font.family: "JetBrains Mono"; font.pixelSize: 15 * screenRoot.sc; font.weight: Font.Medium; color: ma1.containsMouse ? root.blue : Qt.rgba(root.blue.r, root.blue.g, root.blue.b, 0.6); Behavior on color { ColorAnimation { duration: 200 } } }
//                             }
//                             MouseArea { 
//                                 id: ma1; anchors.fill: parent; hoverEnabled: true;
//                                 onClicked: {
//                                     screenRoot.powerMenuOpen = false;
//                                     reloadProcess.running = true;
//                                 }
//                             }
//                         }

//                         Rectangle {
//                             Layout.fillWidth: true; Layout.preferredHeight: 48 * screenRoot.sc; Layout.leftMargin: 10 * screenRoot.sc; Layout.rightMargin: 10 * screenRoot.sc; radius: 12 * screenRoot.sc
//                             color: ma2.containsMouse ? Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.1) : "transparent"
//                             scale: ma2.pressed ? 0.95 : (ma2.containsMouse ? 1.02 : 1.0)
//                             Behavior on color { ColorAnimation { duration: 200 } }
//                             Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            
//                             RowLayout {
//                                 anchors.fill: parent; anchors.leftMargin: 16 * screenRoot.sc; anchors.rightMargin: 16 * screenRoot.sc; spacing: 0
//                                 Text { text: "󰒲"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18 * screenRoot.sc; color: ma2.containsMouse ? root.mauve : Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.6); Behavior on color { ColorAnimation { duration: 200 } } }
//                                 Item { Layout.fillWidth: true }
//                                 Text { text: "Suspend"; font.family: "JetBrains Mono"; font.pixelSize: 15 * screenRoot.sc; font.weight: Font.Medium; color: ma2.containsMouse ? root.mauve : Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.6); Behavior on color { ColorAnimation { duration: 200 } } }
//                             }
//                             MouseArea { 
//                                 id: ma2; anchors.fill: parent; hoverEnabled: true;
//                                 onClicked: {
//                                     screenRoot.powerMenuOpen = false;
//                                     suspendProcess.running = true;
//                                 }
//                             }
//                         }

//                         Rectangle {
//                             Layout.fillWidth: true; Layout.preferredHeight: 48 * screenRoot.sc; Layout.leftMargin: 10 * screenRoot.sc; Layout.rightMargin: 10 * screenRoot.sc; Layout.bottomMargin: 8 * screenRoot.sc; radius: 12 * screenRoot.sc
//                             color: ma3.containsMouse ? Qt.rgba(root.red.r, root.red.g, root.red.b, 0.1) : "transparent"
//                             scale: ma3.pressed ? 0.95 : (ma3.containsMouse ? 1.02 : 1.0)
//                             Behavior on color { ColorAnimation { duration: 200 } }
//                             Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            
//                             RowLayout {
//                                 anchors.fill: parent; anchors.leftMargin: 16 * screenRoot.sc; anchors.rightMargin: 16 * screenRoot.sc; spacing: 0
//                                 Text { text: "󰐥"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18 * screenRoot.sc; color: ma3.containsMouse ? root.red : Qt.rgba(root.red.r, root.red.g, root.red.b, 0.6); Behavior on color { ColorAnimation { duration: 200 } } }
//                                 Item { Layout.fillWidth: true }
//                                 Text { text: "Power Off"; font.family: "JetBrains Mono"; font.pixelSize: 15 * screenRoot.sc; font.weight: Font.Medium; color: ma3.containsMouse ? root.red : Qt.rgba(root.red.r, root.red.g, root.red.b, 0.6); Behavior on color { ColorAnimation { duration: 200 } } }
//                             }
//                             MouseArea { 
//                                 id: ma3; anchors.fill: parent; hoverEnabled: true;
//                                 onClicked: {
//                                     screenRoot.powerMenuOpen = false;
//                                     poweroffProcess.running = true;
//                                 }
//                             }
//                         }
//                     }
//                 }

//                 // Enlarged Power Button
//                 Rectangle {
//                     id: powerBtn
//                     anchors.bottom: parent.bottom
//                     anchors.right: parent.right
//                     anchors.margins: 40 * screenRoot.sc
//                     width: 52 * screenRoot.sc
//                     height: width
//                     radius: height / 2
                    
//                     color: screenRoot.powerMenuOpen 
//                             ? root.surface2 
//                             : (powerBtnMa.containsMouse ? Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.8) : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.4))
//                     border.color: screenRoot.powerMenuOpen ? root.text : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.15)
//                     border.width: Math.max(1, 1 * screenRoot.sc)

//                     opacity: screenRoot.introState
//                     transform: Translate { y: (20 * screenRoot.sc) * (1.0 - screenRoot.introState) }
                    
//                     scale: powerBtnMa.pressed ? 0.9 : (powerBtnMa.containsMouse ? 1.08 : 1.0)

//                     Behavior on color { ColorAnimation { duration: 200 } }
//                     Behavior on border.color { ColorAnimation { duration: 200 } }
//                     Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

//                     Text {
//                         anchors.centerIn: parent
//                         text: "󰐥"
//                         font.family: "Iosevka Nerd Font"
//                         font.pixelSize: 22 * screenRoot.sc
//                         color: screenRoot.powerMenuOpen ? root.red : (powerBtnMa.containsMouse ? root.text : root.subtext0)
//                         Behavior on color { ColorAnimation { duration: 200 } }
//                     }

//                     MouseArea {
//                         id: powerBtnMa
//                         anchors.fill: parent
//                         hoverEnabled: true
//                         enabled: !screenRoot.isPlayingIntro
//                         onClicked: {
//                             screenRoot.powerMenuOpen = !screenRoot.powerMenuOpen;
//                             if (!screenRoot.powerMenuOpen) inputField.forceActiveFocus();
//                         }
//                     }
//                 }

//                 // ---------------------------------------------------------
//                 // 5. INTRO ANIMATION OVERLAY
//                 // ---------------------------------------------------------
//                 Item {
//                     id: introOverlay
//                     anchors.fill: parent
//                     z: 999
//                     visible: screenRoot.isPlayingIntro || opacity > 0

//                     Rectangle {
//                         id: ring3
//                         width: 360 * screenRoot.sc
//                         height: width
//                         radius: height / 2 
//                         anchors.centerIn: parent
//                         color: "transparent"
//                         border.color: root.mauve
//                         border.width: Math.max(1, 1 * screenRoot.sc)
//                         scale: 0.5
//                         opacity: 0.0
//                     }
//                     Rectangle {
//                         id: ring2
//                         width: 300 * screenRoot.sc
//                         height: width
//                         radius: height / 2 
//                         anchors.centerIn: parent
//                         color: "transparent"
//                         border.color: root.text
//                         border.width: Math.max(1, 1 * screenRoot.sc)
//                         scale: 0.8
//                         opacity: 0.0
//                     }
//                     Rectangle {
//                         id: ring1
//                         width: 240 * screenRoot.sc
//                         height: width
//                         radius: height / 2 
//                         anchors.centerIn: parent
//                         color: "transparent"
//                         border.color: root.text
//                         border.width: Math.max(1, 2 * screenRoot.sc)
//                         scale: 0.8
//                         opacity: 0.0
//                     }

//                     Item {
//                         id: introLockOrb
//                         width: 170 * screenRoot.sc
//                         height: width
//                         anchors.centerIn: parent
//                         scale: 0.0
//                         opacity: 0.0
                        
//                         Rectangle {
//                             anchors.fill: parent
//                             radius: height / 2
//                             color: Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.9)
//                             border.color: root.text
//                             border.width: Math.max(1, 2 * screenRoot.sc)
//                         }

//                         Text {
//                             id: introIconUnlocked
//                             anchors.centerIn: parent
//                             text: "󰌿"
//                             font.family: "Iosevka Nerd Font"
//                             font.pixelSize: 64 * screenRoot.sc 
//                             color: root.text
//                             opacity: 1.0
//                             scale: 1.0
//                             transformOrigin: Item.Center
//                         }

//                         Text {
//                             id: introIconLocked
//                             anchors.centerIn: parent
//                             text: "󰌾"
//                             font.family: "Iosevka Nerd Font"
//                             font.pixelSize: 64 * screenRoot.sc 
//                             color: root.text
//                             opacity: 0.0
//                             scale: 1.6
//                             transformOrigin: Item.Center
//                         }
//                     }

//                     SequentialAnimation {
//                         id: introSequence
                        
//                         ParallelAnimation {
//                             NumberAnimation { target: introLockOrb; property: "scale"; from: 0.0; to: 1.0; duration: 300; easing.type: Easing.OutCubic }
//                             NumberAnimation { target: introLockOrb; property: "opacity"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
                            
//                             NumberAnimation { target: ring1; property: "scale"; from: 0.8; to: 1.25; duration: 250; easing.type: Easing.OutCubic }
//                             NumberAnimation { target: ring1; property: "opacity"; from: 0.6; to: 0.0; duration: 250; easing.type: Easing.OutCubic }
                            
//                             NumberAnimation { target: ring2; property: "scale"; from: 0.8; to: 1.4; duration: 300; easing.type: Easing.OutCubic }
//                             NumberAnimation { target: ring2; property: "opacity"; from: 0.4; to: 0.0; duration: 300; easing.type: Easing.OutCubic }

//                             NumberAnimation { target: ring3; property: "scale"; from: 0.5; to: 1.5; duration: 350; easing.type: Easing.OutCubic }
//                             NumberAnimation { target: ring3; property: "opacity"; from: 0.3; to: 0.0; duration: 350; easing.type: Easing.OutCubic }
                            
//                             SequentialAnimation {
//                                 PauseAnimation { duration: 300 } 
//                                 ParallelAnimation {
//                                     NumberAnimation { target: introIconUnlocked; property: "scale"; from: 1.0; to: 0.5; duration: 100; easing.type: Easing.InCubic }
//                                     NumberAnimation { target: introIconUnlocked; property: "opacity"; from: 1.0; to: 0.0; duration: 50 }
                                    
//                                     NumberAnimation { target: introIconLocked; property: "scale"; from: 1.6; to: 1.0; duration: 200; easing.type: Easing.OutBack }
//                                     NumberAnimation { target: introIconLocked; property: "opacity"; from: 0.0; to: 1.0; duration: 100 }
                                    
//                                     SequentialAnimation {
//                                         NumberAnimation { target: introLockOrb; property: "anchors.verticalCenterOffset"; from: 0; to: 3 * screenRoot.sc; duration: 40; easing.type: Easing.OutQuad }
//                                         NumberAnimation { target: introLockOrb; property: "anchors.verticalCenterOffset"; from: 3 * screenRoot.sc; to: 0; duration: 120; easing.type: Easing.OutBack }
//                                     }
//                                 }
//                             }
//                         }
                        
//                         PauseAnimation { duration: 50 }

//                         SequentialAnimation {
//                             ParallelAnimation {
//                                 NumberAnimation { target: introLockOrb; property: "scale"; to: 1.8; duration: 100; easing.type: Easing.InCubic }
//                                 NumberAnimation { target: introOverlay; property: "opacity"; to: 0.0; duration: 100; easing.type: Easing.InCubic }
//                             }
                            
//                             NumberAnimation { target: screenRoot; property: "introState"; from: 0.0; to: 1.0; duration: 100; easing.type: Easing.OutCubic }
//                         }

//                         PropertyAction { target: screenRoot; property: "isPlayingIntro"; value: false }
//                         ScriptAction { script: { inputField.text = ""; inputField.forceActiveFocus(); } }
//                     }
//                 }
//             }
//         }
//     }
// }









import QtQuick
// ^ Imports the QtQuick module, which provides all basic QML types (Item, Rectangle, Text, etc.), property bindings, animations, and the foundation for building user interfaces.

import QtQuick.Window
// ^ Imports the Window module, providing access to screen/window-related properties like Screen.width and Screen.height for responsive layout calculations.

import QtQuick.Controls
// ^ Imports the Qt Quick Controls module, providing reusable UI components. Though this lock screen uses mostly custom elements, the import makes standard controls available if needed.

import QtQuick.Layouts
// ^ Imports the Layouts module, providing RowLayout, ColumnLayout, and other layout types that automatically position and size their children with flexible spacing and alignment options.

import QtQuick.Effects
// ^ Imports the Qt Quick Effects module (Qt 6), which provides MultiEffect—a hardware-accelerated way to apply blur, shadow, colorization, and other visual effects to QML items efficiently on the GPU.

import QtCore
// ^ Imports the QtCore module, which provides core non-GUI functionality including Settings (for persistent storage), date/time formatting, and Qt object types like QtObject used for shared state management.

import Quickshell
// ^ Imports the Quickshell module, providing Wayland-specific shell functionality including Process management, ShellRoot (the top-level window container), and integration with the Wayland compositor.

import Quickshell.Io
// ^ Imports the Quickshell.Io module, providing StdioCollector for capturing process output asynchronously from shell commands run by Process objects.

import Quickshell.Wayland
// ^ Imports the Quickshell.Wayland module, providing Wayland protocol implementations including WlSessionLock and WlSessionLockSurface for creating a secure screen locker that integrates with the Wayland session lock protocol.

import Quickshell.Services.Pam
// ^ Imports the Quickshell.Services.Pam module, providing PamContext for Linux PAM (Pluggable Authentication Modules) integration. This allows secure password validation against the system's authentication backend.

import "../" // Assuming scaler.qml is available here
// ^ Imports QML files from the parent directory. This specifically allows access to Scaler.qml (a custom scaling component) which provides responsive sizing based on screen dimensions.

ShellRoot {
    // ^ Defines the top-level shell window using ShellRoot from Quickshell. This is the root element that represents a native Wayland shell surface, managed by the compositor. All lock screen content is contained within this root.

    id: root
    // ^ Assigns the identifier "root" to this ShellRoot, allowing it to be referenced from anywhere within this QML file (e.g., `root.base`, `root.mauve`).

    MatugenColors { id: _theme }
    // ^ Instantiates the MatugenColors component with the ID "_theme". This component reads the system's matugen-generated color scheme (Material You colors based on the wallpaper) and exposes them as properties. The underscore prefix by convention indicates it's primarily used internally.

    readonly property color base: _theme.base
    // ^ Exposes the matugen "base" color (the primary background color) as a read-only property for easy access throughout the lock screen. The `readonly` keyword prevents accidental modification. This color is the foundation of the theme palette.

    readonly property color crust: _theme.crust
    // ^ Exposes the "crust" color (the darkest shade in the palette, often used for deepest backgrounds or shadows). Read-only to maintain theme consistency.

    readonly property color mantle: _theme.mantle
    // ^ Exposes the "mantle" color (a very dark shade, slightly lighter than crust). Used for secondary dark backgrounds.

    readonly property color text: _theme.text
    // ^ Exposes the "text" color (the primary text/foreground color contrasting with base). This is the main readable color used for all important text throughout the lockscreen.

    readonly property color subtext0: _theme.subtext0
    // ^ Exposes the "subtext0" color (a subdued text variant, dimmer than primary text). Used for secondary or less important text elements.

    readonly property color overlay0: _theme.overlay0
    // ^ Exposes the "overlay0" color (a semi-transparent overlay shade). Used for hover states and subtle surface highlights.

    readonly property color overlay2: _theme.overlay2
    // ^ Exposes the "overlay2" color (a stronger overlay shade than overlay0). Used for more pronounced hover effects and active state indicators.

    readonly property color surface0: _theme.surface0
    // ^ Exposes the "surface0" color (a card/panel background color slightly elevated from base). Used for UI elements that need to visually separate from the main background.

    readonly property color surface1: _theme.surface1
    // ^ Exposes the "surface1" color (slightly lighter/more elevated than surface0). Used for layered panels and hover states on surface elements.

    readonly property color surface2: _theme.surface2
    // ^ Exposes the "surface2" color (the highest surface elevation). Used for the most prominent elevated elements like the active power menu.

    readonly property color mauve: _theme.mauve
    // ^ Exposes the "mauve" accent color. Used extensively for the lock icon, keyboard layout pill, settings section headers, and interactive element accents throughout the lockscreen.

    readonly property color red: _theme.red
    // ^ Exposes the "red" accent color. Used for error states (failed authentication, shake animation), low battery indicators, and the power off button.

    readonly property color peach: _theme.peach
    // ^ Exposes the "peach" accent color. Used for the authenticating state, medium battery levels, and the slider thumb control.

    readonly property color blue: _theme.blue
    // ^ Exposes the "blue" accent color. Used for the weather pill, reboot action button, and the reveal delay settings section.

    readonly property color green: _theme.green
    // ^ Exposes the "green" accent color. Used for the charging state and high battery level indicators, providing positive feedback.

    // Persistent Settings
    Settings {
        // ^ Creates a Settings object that provides persistent storage for user preferences. Settings are stored in the system's standard location (e.g., ~/.config) and survive application restarts.

        id: lockSettings
        // ^ Assigns the identifier "lockSettings" for referencing these persistent settings throughout the lock screen.

        category: "QuickshellLockscreen"
        // ^ Defines the settings category/group name. This organizes settings in the configuration file under "[QuickshellLockscreen]" or a similar namespace, preventing conflicts with other applications.

        property bool hidePassword: false
        // ^ Defines a persistent boolean property that controls whether password characters are hidden by default (shown as dots). Defaults to `false`, meaning characters are briefly visible as typed. This is a Settings-managed property that's automatically saved to disk when changed.

        property int revealDuration: 300
        // ^ Defines a persistent integer property that controls how long (in milliseconds) each typed character remains visible before being replaced with a dot. Defaults to 300ms for a brief reveal. Also managed automatically by the Settings object.
    }

    // Shared state across all monitors
    QtObject {
        // ^ Creates a QtObject, which is a non-visual QML element used purely for holding properties and signals. This object centralizes the lock screen's shared state.

        id: lockUI
        // ^ Assigns the identifier "lockUI" for referencing these state properties from anywhere in the lock screen.

        property bool failed: false
        // ^ Tracks whether the last authentication attempt failed. When `true`, the UI shows error indicators, red accent colors, and a shake animation. Defaults to `false`.

        property bool authenticating: false
        // ^ Tracks whether an authentication attempt is currently in progress. When `true`, the UI shows a loading state with peach accents and disables input. Starts as `false`.

        property string statusText: "Locked"
        // ^ The status message displayed near the input field. Changes to reflect current state: "Locked" when idle, "Enter PIN" when typing, "Authenticating..." during verification, and "Access Denied" on failure.
    }

    // System Authentication hook
    PamContext {
        // ^ Creates a PamContext object that interfaces with Linux PAM (Pluggable Authentication Modules) for system-level user authentication. This is the secure way to verify the user's password against the system.

        id: pam
        // ^ Assigns the identifier "pam" for referencing the authentication context.

        Component.onCompleted: pam.start()
        // ^ When the PamContext component finishes initializing, immediately starts a PAM conversation. This prepares the authentication system to receive the user's password input.

        onCompleted: (result) => {
            // ^ Signal handler called when a PAM authentication attempt completes. The `result` parameter contains the authentication outcome as a PamResult enum value.

            lockUI.authenticating = false;
            // ^ Sets the authenticating flag to false regardless of the outcome, re-enabling the UI for another attempt if needed.

            if (result === PamResult.Success) {
                // ^ Checks if the authentication was successful.

                rootLock.locked = false;
                // ^ Unlocks the session by setting the WlSessionLock's `locked` property to false. This tells the compositor to dismiss the lock screen and restore the user's session.

                Qt.quit();
                // ^ Terminates the QuickShell lock screen application. The compositor will handle the transition back to the user's desktop session.
            } else {
                // ^ If authentication failed (wrong password, etc.).

                lockUI.failed = true;
                // ^ Sets the failed flag to true, triggering error visuals (red accents, shake animation).

                lockUI.statusText = "Access Denied";
                // ^ Updates the status text to inform the user of the failed attempt.

                pam.start();
                // ^ Restarts the PAM conversation, preparing for the next authentication attempt. This resets the PAM state for a fresh password prompt.
            }
        }
    }

    Process {
        // ^ Creates a Process object (from Quickshell) representing the `systemctl suspend` command. This is defined here but not started automatically—it runs when the user clicks the Suspend button.

        id: suspendProcess
        // ^ Assigns the identifier for referencing this process.

        command: ["systemctl", "suspend"]
        // ^ The command array to execute: runs `systemctl suspend` which puts the system into sleep/suspend mode (S3 state), preserving session state in RAM.
    }

    Process {
        // ^ Creates a Process object for the `systemctl poweroff` command to shut down the system completely.

        id: poweroffProcess
        // ^ Assigns the identifier for the power off action.

        command: ["systemctl", "poweroff"]
        // ^ The command to power off the system entirely, terminating all processes and turning off the machine.
    }

    Process {
        // ^ Creates a Process object for the `systemctl reboot` command to restart the system.

        id: reloadProcess
        // ^ Assigns the identifier "reloadProcess" (though it performs a reboot, the name suggests a full system restart/reload).

        command: ["systemctl", "reboot"]
        // ^ The command to reboot/restart the system, shutting down all processes and starting the boot sequence again.
    }

    WlSessionLock {
        // ^ Creates a WlSessionLock object that implements the ext-session-lock-v1 Wayland protocol. This is the mechanism that securely locks the entire session, preventing other applications from capturing input or displaying content.

        id: rootLock
        // ^ Assigns the identifier "rootLock" for controlling the session lock state.

        locked: true
        // ^ Initiates the session in the locked state. The compositor will display this lock surface and prevent access to the desktop until this property is set to false upon successful authentication.

        WlSessionLockSurface {
            // ^ Creates a lock surface—the actual visual output displayed on each monitor. The session lock protocol creates one surface per display output.

            id: surface
            // ^ Assigns the identifier "surface" for this lock surface, though it's primarily used as a container.

            Item {
                // ^ Creates a generic Item that serves as the root container for all lock screen visual elements on this monitor.

                id: screenRoot
                // ^ Assigns the identifier "screenRoot" for referencing this monitor's lock screen root from nested components.

                anchors.fill: parent
                // ^ Makes this item fill its entire parent (the WlSessionLockSurface), ensuring the lock screen covers the entire monitor area.

                // --- Responsive Scaling Logic ---
                // We use a property binding instead of a function to ensure 
                // continuous updates even if surface width starts at 0.
                Scaler {
                    // ^ Instantiates the custom Scaler component (imported from parent directory). This component calculates a base scale factor based on the screen dimensions, enabling proportional UI sizing across different resolutions.

                    id: scaler
                    // ^ Assigns the identifier "scaler" for accessing the calculated scale factor.

                    currentWidth: screenRoot.width > 0 ? screenRoot.width : Screen.width
                    // ^ Sets the width used for scale calculation. Uses screenRoot.width if it's valid (>0, meaning the surface has been assigned a size), otherwise falls back to Screen.width (the overall screen width). This ensures scaling works even before the lock surface is fully initialized.
                }
                readonly property real sc: scaler.baseScale
                // ^ Defines a convenient read-only alias `sc` for the scaler's `baseScale` property. This is used throughout the lock screen by multiplying dimensions (e.g., `40 * screenRoot.sc`) to achieve resolution-independent sizes. All visual elements scale proportionally.
                // --------------------------------

                property string staticWallpaperPath: "file:///tmp/lock_bg.png"
                // ^ Defines the path to the lockscreen background image. Uses the `file://` URL scheme to load a local file. The image at `/tmp/lock_bg.png` is a cached copy of the user's wallpaper (created by the init script), ensuring the lock screen shows a blurred version of the desktop background.

                property string batPct: "100"
                // ^ Stores the current battery percentage as a string. Initialized to "100" as a default until the battery polling process provides an actual value. Updated every 5 seconds by the battery poller.

                property string batStatus: "AC"
                // ^ Stores the current battery status: "AC" (plugged in/charging), "Discharging", "Charging", or "Unknown". Initialized to "AC" as the default state.

                property string currentUser: "User"
                // ^ Stores the currently logged-in user's username. Initialized to "User" as a fallback until the user polling process retrieves the actual username via `whoami`.

                property string faceIconPath: ""
                // ^ Stores the file path to the user's face/avatar icon. Initialized as empty string. The user poller checks for `~/.face.icon` or `~/.face` files and sets this path if found, displaying the user's custom avatar.

                property string kbLayout: "US"
                // ^ Stores the current keyboard layout code (e.g., "US", "DE", "FR"). Initialized to "US" as default. Updated by the keyboard layout polling process which reads the active keymap from Hyprland.

                property string weatherIcon: ""
                // ^ Stores the current weather condition icon character (a Nerd Font glyph). Updated every 15 minutes by the weather polling process. Empty by default until weather data is fetched.

                property string weatherTemp: "--°C"
                // ^ Stores the current temperature string for display. Initialized to "--°C" as a placeholder until weather data is fetched. Updated by the weather polling process.

                // UI States
                property real introState: 0.0
                // ^ Tracks the progress of the intro animation (0.0 = intro playing, 1.0 = intro complete, main UI visible). This property drives the fade-in and slide-up transitions of the main lock screen content after the intro animation finishes.

                property bool powerMenuOpen: false
                // ^ Tracks whether the power menu (containing reboot, suspend, power off options) is currently expanded and visible. Toggled by clicking the power button.

                property bool inputActive: false 
                // ^ Tracks whether the password input mode is active. When `true`, the clock shrinks/moves up, the authentication module becomes visible, and the background effects subtly change. Toggled by clicking the background or pressing a key.

                property bool isPlayingIntro: true
                // ^ Tracks whether the intro animation sequence is currently playing. Set to `true` initially to prevent user interaction during the animation, and changed to `false` by the intro sequence when it completes.

                property bool isDesktop: false
                // ^ Tracks whether the system is a desktop (no battery) or a laptop (has battery). Determined by the chassis detector process. When `true`, the battery pill is hidden.
                
                Component.onCompleted: {
                    // ^ Signal handler called when the screenRoot component has finished initializing and all child elements are ready.

                    introSequence.start();
                    // ^ Starts the intro animation sequence, which plays the circular ring expansion and lock icon transition before revealing the main lock screen interface.
                }

                property real globalOrbitAngle: 0
                // ^ Defines a property that stores the current angle (in radians) for the orbiting background circles animation. Starts at 0 and increases continuously.

                NumberAnimation on globalOrbitAngle {
                    // ^ Creates a NumberAnimation that operates directly on the globalOrbitAngle property. This is a property animation that runs continuously without needing to be explicitly started/stopped.

                    from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
                    // ^ Animates from 0 to 2π (one full circle in radians) over 90,000 milliseconds (90 seconds). `loops: Animation.Infinite` makes it repeat forever. `running: true` starts it immediately. This creates slow, continuous orbital motion for the decorative background circles.
                }

                // Auto-hide input field if empty and idle for 15 seconds
                Timer {
                    // ^ Creates a Timer that auto-hides the password input mode after a period of inactivity, returning to the clock display.

                    id: idleTimer
                    // ^ Assigns the identifier "idleTimer" for reference.

                    interval: 15000
                    // ^ Sets the timer interval to 15,000 milliseconds (15 seconds). After this duration of inactivity, the timer triggers.

                    running: screenRoot.inputActive && inputField.text.length === 0
                    // ^ The timer runs only when input is active AND the input field is empty. This means if the user is actively typing (text length > 0), the timer won't fire. If the user enters input mode but doesn't type anything for 15 seconds, the timer triggers.

                    repeat: false
                    // ^ The timer fires only once per activation, not repeatedly. It will restart when conditions change (via `idleTimer.restart()` called in onTextChanged).

                    onTriggered: screenRoot.inputActive = false
                    // ^ When the timer fires (15 seconds of empty idle input), sets `inputActive` to false, transitioning the UI back to the clock display mode with the clock centered.
                }

                // ---------------------------------------------------------
                // BACKGROUND DATA POLLING 
                // ---------------------------------------------------------

                Process {
                    // ^ Creates a Process that detects whether the system is a laptop or desktop by checking for battery power supplies in sysfs.

                    id: chassisDetector
                    // ^ Assigns the identifier for this detection process.

                    running: true
                    // ^ Starts this process immediately and runs it once (it only needs to detect once at startup).

                    command: ["bash", "-c", "if ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then echo 'laptop'; else echo 'desktop'; fi"]
                    // ^ Runs a bash command that checks if any battery devices exist in the sysfs power supply directory. If BAT* files are found, outputs "laptop" (has battery); if the ls command fails (no batteries), outputs "desktop". Both stdout and stderr from `ls` are redirected to /dev/null.

                    stdout: StdioCollector {
                        // ^ Attaches a StdioCollector to capture the process output.

                        onStreamFinished: {
                            // ^ Called when the process completes.

                            screenRoot.isDesktop = (this.text.trim() === "desktop");
                            // ^ Sets the isDesktop flag by checking if the output text (trimmed of whitespace) exactly equals "desktop". If so, battery-related UI elements will be hidden.
                        }
                    }
                }

                Process {
                    // ^ Creates a Process that retrieves the current user's username and face icon path.

                    id: userPoller
                    // ^ Assigns the identifier for the user information process.

                    command: [
                        "bash", 
                        "-c", 
                        "USER_VAR=$(whoami); ICON_PATH=\"\"; if [ -f ~/.face.icon ]; then ICON_PATH=$(readlink -f ~/.face.icon); elif [ -f ~/.face ]; then ICON_PATH=$(readlink -f ~/.face); fi; echo -n \"$USER_VAR|$ICON_PATH\""
                    ]
                    // ^ Runs a bash script that: (1) gets the username with `whoami`, (2) checks for a face icon file at `~/.face.icon` first, then `~/.face`, (3) if found, resolves it to an absolute path with `readlink -f`, (4) outputs the username and icon path separated by a pipe character. The `-n` flag on echo suppresses the trailing newline.

                    stdout: StdioCollector {
                        // ^ Captures the process output.

                        onStreamFinished: {
                            // ^ Called when the user info has been retrieved.

                            let parts = this.text.trim().split("|");
                            // ^ Splits the output by the pipe character to separate username and icon path.

                            if (parts.length > 0 && parts[0] !== "") screenRoot.currentUser = parts[0];
                            // ^ If the username part exists and is not empty, updates the currentUser property, replacing the "User" default.

                            if (parts.length > 1 && parts[1].trim() !== "") {
                                // ^ If there's a second part (icon path) and it's not empty.

                                let path = parts[1].trim();
                                // ^ Trims whitespace from the icon path.

                                screenRoot.faceIconPath = path.startsWith("file://") ? path : "file://" + path;
                                // ^ Ensures the path uses the `file://` URL scheme required by QML's Image source. If the path already starts with "file://", use it as-is; otherwise, prefix it.
                            }
                        }
                    }

                    Component.onCompleted: running = true
                    // ^ Starts the user polling process when this component completes initialization, ensuring user info is displayed immediately.
                }
                
                Process {
                    // ^ Creates a Process that retrieves the current keyboard layout from Hyprland's device information.

                    id: kbPoller
                    // ^ Assigns the identifier for the keyboard layout process.

                    command: ["bash", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n1 | cut -c1-2 | tr '[:lower:]' '[:upper:]'"]
                    // ^ A pipeline command: (1) `hyprctl devices -j` gets all input devices as JSON, (2) `jq` filters for the main keyboard's active keymap name, (3) `head -n1` takes the first result, (4) `cut -c1-2` extracts only the first two characters (e.g., "us" from "us(intl)"), (5) `tr` converts to uppercase. This gives the keyboard layout code like "US", "DE", "FR".

                    stdout: StdioCollector {
                        // ^ Captures the output.

                        onStreamFinished: {
                            // ^ Called when the keyboard layout is retrieved.

                            let layout = this.text.trim();
                            // ^ Gets the trimmed output.

                            if (layout !== "" && layout !== "null") {
                                // ^ Validates the output isn't empty or the literal string "null" (which jq outputs for null values).

                                screenRoot.kbLayout = layout;
                                // ^ Updates the kbLayout display property with the current layout code.
                            }
                        }
                    }
                }

                Timer { interval: 150; running: true; repeat: true; triggeredOnStart: true; onTriggered: kbPoller.running = true }
                // ^ Creates a Timer that polls the keyboard layout every 150 milliseconds. `interval: 150` sets a fast polling rate to detect layout switches quickly. `running: true` starts it immediately. `repeat: true` makes it loop. `triggeredOnStart: true` fires immediately on start rather than waiting for the first interval. When triggered, it sets `kbPoller.running = true` which re-runs the keyboard layout detection process. This provides near real-time keyboard layout display.

                Process {
                    // ^ Creates a Process that reads battery status from Linux sysfs.

                    id: batPoller
                    // ^ Assigns the identifier for the battery information process.

                    running: !screenRoot.isDesktop
                    // ^ Only runs this process when the system is NOT a desktop (i.e., when it's a laptop with a battery). The `!` operator inverts the isDesktop boolean, so the process runs on laptops. The binding means it will automatically start/stop if the chassis type changes.

                    command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo '100'; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1 || echo 'AC'"]
                    // ^ Reads battery information: (1) reads the capacity file from any BAT* device (battery percentage), (2) if that fails, defaults to "100", (3) reads the status file for charging state, (4) if that fails, defaults to "AC". Both values are output on separate lines.

                    stdout: StdioCollector {
                        // ^ Captures the two-line output.

                        onStreamFinished: {
                            // ^ Called when battery data is retrieved.

                            let lines = this.text.trim().split("\n");
                            // ^ Splits the output into lines (first line = percentage, second line = status).

                            if (lines.length >= 2) {
                                // ^ Ensures both values are present.

                                screenRoot.batPct = lines[0] || "100";
                                // ^ Sets the battery percentage (first line), falling back to "100" if somehow empty.

                                screenRoot.batStatus = lines[1] || "Unknown";
                                // ^ Sets the battery status (second line), falling back to "Unknown".
                            }
                        }
                    }
                }

                Timer { interval: 5000; running: !screenRoot.isDesktop; repeat: true; triggeredOnStart: true; onTriggered: batPoller.running = true }
                // ^ Creates a Timer that polls battery status every 5,000 milliseconds (5 seconds). Only runs when NOT on a desktop (`!screenRoot.isDesktop`). Fires immediately on start (`triggeredOnStart: true`) for instant battery display, then repeats every 5 seconds for regular updates.

                Process {
                    // ^ Creates a Process that retrieves weather information using the weather shell script.

                    id: weatherPoller
                    // ^ Assigns the identifier for the weather process.

                    property string scriptPath: Qt.resolvedUrl("calendar/weather.sh").toString().replace(/^file:\/\//, "")
                    // ^ Resolves the relative path to the weather script to an absolute file path. `Qt.resolvedUrl()` converts the relative path to a full `file://` URL. `.toString()` converts it to a string, and `.replace(/^file:\/\//, "")` strips the `file://` prefix, leaving just the absolute filesystem path that can be passed to bash.

                    command: ["bash", "-c", '"' + scriptPath + '" --current-icon; "' + scriptPath + '" --current-temp']
                    // ^ Constructs a bash command that runs the weather script twice: first with `--current-icon` to get the weather condition icon character, then with `--current-temp` to get the temperature string. The semicolon separates the two commands, and both outputs appear on separate lines.

                    stdout: StdioCollector {
                        // ^ Captures the two-line output (icon on line 1, temperature on line 2).

                        onStreamFinished: {
                            // ^ Called when weather data is retrieved.

                            let lines = this.text.trim().split("\n");
                            // ^ Splits the output into lines.

                            if (lines.length >= 2) {
                                // ^ Ensures both icon and temperature are present.

                                screenRoot.weatherIcon = lines[0] || "";
                                // ^ Sets the weather icon (first line), defaulting to empty string if missing.

                                screenRoot.weatherTemp = lines[1] || "--°C";
                                // ^ Sets the temperature display string (second line), defaulting to the placeholder if missing.
                            }
                        }
                    }
                }

                Timer { interval: 900000; running: true; repeat: true; triggeredOnStart: true; onTriggered: weatherPoller.running = true }
                // ^ Creates a Timer that polls weather data every 900,000 milliseconds (15 minutes). Always runs regardless of system type. Fires immediately on start for instant weather display, then repeats every 15 minutes to keep data reasonably current without excessive API calls.

                // ---------------------------------------------------------
                // 1. LIVING BACKGROUND
                // ---------------------------------------------------------
                
                Rectangle {
                    // ^ The bottom-most background layer: a solid color rectangle filling the entire screen.

                    anchors.fill: parent
                    // ^ Makes this rectangle cover the entire lock screen surface.

                    color: root.base
                    // ^ Fills with the matugen "base" color, providing the theme's primary background color. This ensures no transparent gaps show through.
                }

                Image {
                    // ^ An Image element that loads and displays the user's wallpaper as the background behind the blur effect.

                    id: bgWallpaper
                    // ^ Assigns the identifier "bgWallpaper" for referencing this image layer.

                    anchors.fill: parent
                    // ^ Scales the image to fill the entire screen.

                    source: screenRoot.staticWallpaperPath
                    // ^ Sets the image source to the cached wallpaper at `/tmp/lock_bg.png` using the file:// URL.

                    fillMode: Image.PreserveAspectCrop
                    // ^ Scales the image proportionally to fill the entire area, cropping excess portions rather than distorting the aspect ratio. Maintains the wallpaper's visual integrity.

                    asynchronous: true
                    // ^ Loads the image asynchronously in a background thread, preventing UI freezes if the image file is large or on slow storage.

                    visible: false 
                    // ^ Hides this base image since we don't want to see the sharp original—only its blurred version via the MultiEffect. The image data is still loaded and available as a source for the effect.

                    cache: false 
                    // ^ Disables Qt's internal image caching. Each time the lock screen appears, it reloads the image fresh, ensuring any wallpaper changes are reflected immediately when the screen is locked.
                }

                MultiEffect {
                    // ^ Applies a GPU-accelerated visual effect to the wallpaper image. MultiEffect can combine multiple effects (blur, shadow, colorize, etc.) efficiently.

                    source: bgWallpaper
                    // ^ Uses the wallpaper image as the input source for the effect pipeline.

                    anchors.fill: bgWallpaper
                    // ^ Makes the effect output cover the same area as the source image (full screen).

                    blurEnabled: true
                    // ^ Enables the blur effect, which will soften the wallpaper into an abstract background.

                    blurMax: 64 * screenRoot.sc
                    // ^ Sets the maximum blur radius to 64 pixels, scaled by the screen factor. This determines how much blurring is possible when `blur` is set to 1.0 (maximum). Higher values create a smoother, more abstract background.

                    blur: 1.0
                    // ^ Sets the blur amount to maximum (1.0 or 100%), creating a heavily blurred, dreamy version of the wallpaper. This provides visual depth while keeping the lock screen content readable.
                }
                
                Rectangle {
                    // ^ A semi-transparent black overlay that dims the blurred background further.

                    id: dimmer
                    // ^ Assigns the identifier "dimmer" (though it's not referenced elsewhere by ID).

                    anchors.fill: parent
                    // ^ Covers the entire screen.

                    color: "black"
                    // ^ Uses pure black as the base color.

                    opacity: 0.25 
                    // ^ Sets opacity to 25%, creating a darkening effect over the blurred wallpaper. This ensures text and UI elements have sufficient contrast against any wallpaper, whether light or dark.
                }

                Item {
                    // ^ A container for the animated background circles that create visual interest.

                    anchors.fill: parent
                    // ^ Contains circles within the full screen area.

                    Rectangle {
                        // ^ The first orbiting circle—a large, slow-moving decorative element using mauve color.

                        width: parent.width * 0.8; height: width; radius: width / 2
                        // ^ Makes this rectangle a circle by setting width to 80% of parent width, height equal to width (making it square), and radius to width/2 (making it perfectly circular).

                        x: (parent.width / 2 - width / 2) + Math.cos(screenRoot.globalOrbitAngle * 2) * (200 * screenRoot.sc)
                        // ^ Calculates the X position using cosine: starts centered, then offsets by cos(angle*2) multiplied by a scaled amplitude. The `* 2` makes this circle orbit at double the base speed.

                        y: (parent.height / 2 - height / 2) + Math.sin(screenRoot.globalOrbitAngle * 2) * (150 * screenRoot.sc)
                        // ^ Calculates the Y position using sine with the same frequency, creating circular motion. The amplitude is slightly smaller (150 vs 200) for an elliptical orbit.

                        scale: 1.0 + Math.sin(screenRoot.globalOrbitAngle * 6) * 0.05
                        // ^ Adds subtle breathing/pulsing effect: scale oscillates between 0.95 and 1.05 (5% variation) at 6x the orbital frequency. This gives the circle a gentle living quality.

                        opacity: screenRoot.inputActive ? 0.04 : 0.08
                        // ^ Adjusts opacity based on input state: dimmer (4%) when input is active to reduce distraction, brighter (8%) when showing the clock for more visual warmth.

                        color: root.mauve
                        // ^ Uses the mauve accent color, tying the decorative element to the theme.

                        Behavior on color { ColorAnimation { duration: 1000 } }
                        // ^ Animates color changes smoothly over 1 second (1000ms), ensuring transitions between theme colors are gradual and pleasant.

                        Behavior on opacity { NumberAnimation { duration: 600 } }
                        // ^ Animates opacity changes over 600ms, making the transition between input-active and idle states smooth.
                    }
                    
                    Rectangle {
                        // ^ The second orbiting circle—complementary to the first, using blue color and different orbital parameters.

                        width: parent.width * 0.9; height: width; radius: width / 2
                        // ^ Slightly larger at 90% of parent width, maintaining a perfect circle shape.

                        x: (parent.width / 2 - width / 2) + Math.sin(screenRoot.globalOrbitAngle * 1.5) * (-200 * screenRoot.sc)
                        // ^ Uses sine instead of cosine for X position, creating a 90-degree phase offset from the first circle. The `* 1.5` makes it orbit at a different speed. Negative amplitude (-200) makes it orbit in the opposite horizontal direction.

                        y: (parent.height / 2 - height / 2) + Math.cos(screenRoot.globalOrbitAngle * 1.5) * (-150 * screenRoot.sc)
                        // ^ Uses cosine for Y position, maintaining the phase relationship. Negative amplitude for vertical movement as well, creating a counter-rotating feel.

                        scale: 1.0 + Math.cos(screenRoot.globalOrbitAngle * 5) * 0.05
                        // ^ Pulsing effect at 5x frequency using cosine, slightly offset in phase from the first circle's sine-based pulse.

                        opacity: screenRoot.inputActive ? 0.03 : 0.06
                        // ^ Slightly dimmer than the first circle overall (3%/6% vs 4%/8%), creating depth through varying opacity.

                        color: root.blue
                        // ^ Uses the blue accent color, complementing the mauve circle with a cooler tone.

                        Behavior on color { ColorAnimation { duration: 1000 } }
                        // ^ Smooth color transitions over 1 second.

                        Behavior on opacity { NumberAnimation { duration: 600 } }
                        // ^ Smooth opacity transitions matching the first circle.
                    }

                    Item {
                        // ^ A container for concentric ring circles that appear around the clock area, pulsing subtly.

                        anchors.fill: parent
                        // ^ Fills the screen.

                        opacity: screenRoot.introState
                        // ^ Fades in as the intro animation completes (introState goes from 0 to 1), so these rings appear with the main UI.

                        scale: 1.1 - (0.1 * screenRoot.introState)
                        // ^ Subtle scale animation: starts at 1.1 (slightly larger) and settles to 1.0 as intro completes. This creates a gentle settling effect.

                        Repeater {
                            // ^ Creates multiple copies of a templated item—in this case, four concentric circles.

                            model: 4
                            // ^ Generates exactly 4 copies, indexed 0 through 3.

                            Rectangle {
                                // ^ Each repeated item is a rectangular circle (radius = half width) rendered as a ring.

                                anchors.centerIn: parent
                                // ^ All circles share the same center point (the middle of the screen).

                                anchors.verticalCenterOffset: -40 * screenRoot.sc
                                // ^ Offsets all circles slightly upward (negative Y) from center, positioning them near the clock display area.

                                width: (400 * screenRoot.sc) + (index * (220 * screenRoot.sc))
                                // ^ Each circle gets progressively larger: index 0 = 400, index 1 = 620, index 2 = 840, index 3 = 1060 (all scaled). This creates evenly spaced concentric rings.

                                height: width
                                // ^ Maintains square dimensions for a perfect circle.

                                radius: width / 2
                                // ^ Half the width/height makes the rectangle perfectly circular.

                                color: "transparent"
                                // ^ The interior is fully transparent—only the border is visible, creating ring shapes.

                                border.color: lockUI.failed ? root.red : root.text
                                // ^ Changes border color based on authentication state: red on failure, normal text color otherwise. This provides instant visual feedback for failed attempts.

                                border.width: Math.max(1, 1 * screenRoot.sc)
                                // ^ Sets a thin border (1 pixel minimum, scales with display), ensuring the rings are visible without being overwhelming.

                                opacity: lockUI.failed ? (0.1 - (index * 0.02)) : (screenRoot.inputActive ? (0.02 - (index * 0.005)) : (0.04 - (index * 0.01)))
                                // ^ Complex opacity logic: on failure, outer rings are more visible (0.1 decreasing to 0.04) for emphasis. In normal state, rings are dimmer when input is active (less distraction), and each successive ring (higher index) is slightly more transparent, creating a fading outward effect.

                                Behavior on border.color { ColorAnimation { duration: 600; easing.type: Easing.OutExpo } }
                                // ^ Smoothly animates border color changes over 600ms using an exponential out easing curve, which starts fast and decelerates, feeling responsive yet polished.

                                Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                                // ^ Smooth opacity transitions matching the border color animation timing and easing.
                            }
                        }
                    }
                }

                // ---------------------------------------------------------
                // 2. MAIN CONTENT LAYER
                // ---------------------------------------------------------
                MouseArea {
                    // ^ A full-screen invisible mouse area that captures clicks to activate the password input mode or dismiss the power menu.

                    anchors.fill: parent
                    // ^ Covers the entire lock screen, intercepting all mouse clicks.

                    enabled: !screenRoot.isPlayingIntro
                    // ^ Disables interaction while the intro animation is playing, preventing accidental clicks during the transition.

                    onClicked: {
                        // ^ Handles mouse click events anywhere on the lock screen.

                        if (screenRoot.powerMenuOpen) screenRoot.powerMenuOpen = false;
                        // ^ If the power menu is open, clicking anywhere closes it first (dismiss behavior).

                        if (!screenRoot.inputActive) screenRoot.inputActive = true;
                        // ^ If input mode isn't already active, activate it—showing the password field and transitioning the clock.

                        inputField.forceActiveFocus();
                        // ^ Forces keyboard focus to the hidden password input field, ready to receive typed characters immediately.
                    }
                }

                Item {
                    // ^ Container for both the clock module (idle state) and authentication module (input state), handling the transition between them.

                    anchors.fill: parent
                    // ^ Fills the screen area.

                    opacity: screenRoot.introState
                    // ^ Fades in as the intro completes, revealing the main content.

                    transform: Translate { y: (30 * screenRoot.sc) * (1.0 - screenRoot.introState) }
                    // ^ Slides the content upward during intro: starts 30px down (when introState=0) and settles at 0 (when introState=1). This creates a gentle rise-from-below entrance effect.

                    // --- CLOCK MODULE (Idle State) ---
                    ColumnLayout {
                        // ^ Vertically stacks the clock hours:minutes and date text, centered on screen.

                        id: clockModule
                        // ^ Assigns the identifier "clockModule" for referencing.

                        anchors.centerIn: parent
                        // ^ Centers the clock module in the screen when in idle state.

                        anchors.verticalCenterOffset: screenRoot.inputActive ? (-120 * screenRoot.sc) : (-40 * screenRoot.sc)
                        // ^ Moves the clock upward when input becomes active: from -40px (slightly above center) to -120px (well above center), making room for the authentication module. This property binding automatically animates when inputActive changes.

                        spacing: -10 * screenRoot.sc
                        // ^ Uses negative spacing to tighten the gap between the time and date text (bringing them closer together vertically). The negative value reduces normal layout spacing.

                        opacity: screenRoot.inputActive ? 0.0 : 1.0
                        // ^ Fades out the clock completely when input is active (opacity 0), and shows it fully when idle (opacity 1). The visibility check below prevents it from consuming interaction when invisible.

                        scale: screenRoot.inputActive ? 0.9 : 1.0
                        // ^ Slightly shrinks the clock when transitioning away (90% scale) and returns to normal when idle. Combined with opacity, this creates a smooth dismiss effect.

                        visible: opacity > 0.01
                        // ^ Hides the clock module entirely when it's nearly invisible (opacity < 1%), preventing it from intercepting mouse events or affecting layout calculations. The 0.01 threshold avoids flickering at the exact 0 boundary.

                        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                        // ^ Animates the vertical position changes smoothly over 600ms with exponential easing out. This creates an elegant slide-up/slide-down when transitioning between clock and input modes.

                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        // ^ Animates opacity changes over 400ms with cubic easing out, creating a smooth fade.

                        Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                        // ^ Animates scale changes over 500ms with back easing, which slightly overshoots the target before settling. This gives the scale animation a subtle bouncy, lively feel.

                        RowLayout {
                            // ^ Horizontally arranges the hours, colon separator, and minutes in a single line.

                            Layout.alignment: Qt.AlignHCenter
                            // ^ Centers this row horizontally within the parent ColumnLayout.

                            spacing: 0
                            // ^ No extra spacing between the time elements—they're positioned exactly as laid out by the font.

                            Text {
                                // ^ Displays the current hour digits (e.g., "09" or "14").

                                id: clockHours
                                // ^ Assigns the identifier for updating from the clock timer.

                                font.family: "JetBrains Mono"
                                // ^ Uses the JetBrains Mono monospace font for clean, uniform digit rendering and modern aesthetics.

                                font.pixelSize: 140 * screenRoot.sc
                                // ^ Sets a very large font size (140px base, scaled) for prominent time display that's readable from across the room.

                                font.weight: Font.Bold
                                // ^ Uses bold weight for maximum visibility and impact.

                                color: root.text
                                // ^ Colors the clock with the theme's primary text color.

                                Behavior on color { ColorAnimation { duration: 300 } }
                                // ^ Smooth color transitions for theme changes.
                            }

                            Text {
                                // ^ The colon separator between hours and minutes.

                                text: ":"
                                // ^ Hard-coded colon character (the clock timer doesn't update this—it's static).

                                font.family: "JetBrains Mono"
                                // ^ Same font family for consistency.

                                font.pixelSize: 140 * screenRoot.sc
                                // ^ Same large size as the digits.

                                font.weight: Font.Bold
                                // ^ Bold for consistency.

                                opacity: 0.5
                                // ^ Rendered at half opacity to subtly de-emphasize the separator compared to the digits themselves, creating a refined visual hierarchy.

                                color: root.text
                                // ^ Theme text color.

                                Behavior on color { ColorAnimation { duration: 300 } }
                                // ^ Smooth color transitions.
                            }

                            Text {
                                // ^ Displays the current minute digits (e.g., "05" or "42").

                                id: clockMinutes
                                // ^ Assigns the identifier for updating from the clock timer.

                                font.family: "JetBrains Mono"
                                // ^ Consistent font family.

                                font.pixelSize: 140 * screenRoot.sc
                                // ^ Same large size as hours.

                                font.weight: Font.Bold
                                // ^ Bold for visibility.

                                color: root.text
                                // ^ Theme text color.

                                Behavior on color { ColorAnimation { duration: 300 } }
                                // ^ Smooth color transitions.
                            }
                        }

                        Text {
                            // ^ Displays the current date below the time (e.g., "Monday, January 15").

                            id: dateText
                            // ^ Assigns the identifier for updating from the clock timer.

                            Layout.alignment: Qt.AlignHCenter
                            // ^ Centers the date text horizontally within the column.

                            font.family: "JetBrains Mono"
                            // ^ Consistent monospace font throughout.

                            font.pixelSize: 22 * screenRoot.sc
                            // ^ Much smaller than the time (22px vs 140px), creating clear visual hierarchy with the time dominant.

                            font.weight: Font.Bold
                            // ^ Bold for readability at smaller size.

                            color: root.text
                            // ^ Theme text color for the date.
                        }

                        Timer {
                            // ^ A timer that updates the clock display every second.

                            interval: 1000; running: true; repeat: true; triggeredOnStart: true
                            // ^ Fires every 1,000ms (1 second), starts immediately, repeats indefinitely, and fires immediately on creation (so the clock shows the correct time instantly, not after a 1-second delay).

                            onTriggered: {
                                // ^ Called every second and immediately on start.

                                let d = new Date();
                                // ^ Creates a new JavaScript Date object with the current date and time.

                                clockHours.text = Qt.formatDateTime(d, "hh");
                                // ^ Formats the hours in 12-hour format with leading zero (e.g., "09" or "02").

                                clockMinutes.text = Qt.formatDateTime(d, "mm");
                                // ^ Formats the minutes with leading zero (e.g., "05" or "42").

                                dateText.text = Qt.formatDateTime(d, "dddd, MMMM dd");
                                // ^ Formats the date as full weekday name, full month name, and day number (e.g., "Monday, January 15").
                            }
                        }
                    }

                    // --- AUTHENTICATION MODULE (Input State) ---
                    RowLayout {
                        // ^ Horizontally arranges the user avatar (left) and the password input + status (right) in a row.

                        id: authModule
                        // ^ Assigns the identifier "authModule".

                        anchors.centerIn: parent
                        // ^ Centers the authentication module in the screen when input is active.

                        anchors.verticalCenterOffset: screenRoot.inputActive ? (-40 * screenRoot.sc) : (40 * screenRoot.sc)
                        // ^ When input is active, positions slightly above center (-40px). When inactive, starts lower (40px below center) for the slide-up transition effect.

                        spacing: 32 * screenRoot.sc 
                        // ^ Adds substantial spacing (32px scaled) between the avatar circle and the text/input column, giving each element breathing room.

                        opacity: screenRoot.inputActive ? 1.0 : 0.0
                        // ^ Fully visible when input is active, completely transparent when idle. This is the inverse of the clock module's opacity.

                        scale: screenRoot.inputActive ? 1.0 : 0.9
                        // ^ Full scale when active, slightly shrunk when inactive (matching the clock's opposite behavior).

                        visible: opacity > 0.01
                        // ^ Hidden when nearly invisible to prevent interaction interference.

                        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                        // ^ Smooth slide-up animation matching the clock's slide-up, creating a cohesive transition.

                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        // ^ Smooth fade animation matching the clock.

                        Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                        // ^ Bouncy scale animation for lively feel.

                        // Left: Enlarged Avatar
                        Item {
                            // ^ Container for the circular user avatar, using a fixed size.

                            Layout.alignment: Qt.AlignVCenter
                            // ^ Vertically centers the avatar within the row.

                            width: 170 * screenRoot.sc
                            // ^ Sets a large width (170px scaled) for the avatar, making it prominent.

                            height: width // Force square aspect ratio
                            // ^ Forces height equal to width, maintaining a perfect square container for the circular avatar mask.

                            Rectangle {
                                // ^ A hidden rectangle used as a mask source for clipping the avatar image into a circle.

                                id: avatarMask
                                // ^ Assigns the identifier for use as the maskSource in MultiEffect.

                                anchors.fill: parent
                                // ^ Same size as the parent container.

                                radius: height / 2 // Dynamic perfect radius
                                // ^ Half the height creates a perfect circle mask when used with MultiEffect's maskEnabled.

                                color: "black"
                                // ^ The color inside the mask determines opacity—anything under black areas of the mask source will be visible.

                                visible: false 
                                // ^ The mask itself is invisible; only used as a data source for the MultiEffect below.

                                layer.enabled: true 
                                // ^ Enables layer rendering for this item, which allows it to be used as a mask texture by MultiEffect.
                            }

                            Rectangle {
                                // ^ A fallback placeholder circle shown when the user's avatar image hasn't loaded yet.

                                anchors.fill: parent
                                // ^ Same size as the avatar container.

                                radius: height / 2
                                // ^ Perfect circle shape matching the mask.

                                color: Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.5)
                                // ^ Semi-transparent version of the surface0 color, creating a subtle visible circle even without an image.

                                visible: avatarImg.status !== Image.Ready
                                // ^ Only shown when the avatar image is NOT ready (loading, error, or no image set). Hidden once the image loads successfully.

                                Text {
                                    // ^ A fallback icon inside the placeholder circle.

                                    anchors.centerIn: parent
                                    // ^ Centers the icon in the placeholder.

                                    text: "󰄽"
                                    // ^ A Nerd Font icon representing a user silhouette.

                                    font.family: "Iosevka Nerd Font"
                                    // ^ Uses Iosevka Nerd Font for the icon. This font includes thousands of glyphs and icons.

                                    font.pixelSize: 64 * screenRoot.sc
                                    // ^ Large icon size relative to the circle.

                                    color: root.subtext0
                                    // ^ Uses the subdued text color so the placeholder is visible but not prominent.
                                }
                            }

                            Image {
                                // ^ The actual user avatar image, loaded from disk.

                                id: avatarImg
                                // ^ Assigns the identifier for status checking.

                                anchors.fill: parent
                                // ^ Fills the circular container.

                                source: screenRoot.faceIconPath !== "" ? screenRoot.faceIconPath : ""
                                // ^ Loads the face icon path if it was found by the user poller. If no path is set, the source is empty and the placeholder shows instead.

                                fillMode: Image.PreserveAspectCrop
                                // ^ Crops the image to fill the square area while maintaining aspect ratio, ensuring the face is centered and fills the circle nicely.

                                visible: false 
                                // ^ The raw image is hidden—only the masked version via MultiEffect is shown. This prevents the square image from being visible.

                                cache: false
                                // ^ Disables caching to ensure the avatar reloads fresh each time the lock screen appears.

                                asynchronous: true
                                // ^ Loads the image in a background thread to prevent UI lag if the image file is large.
                            }

                            MultiEffect {
                                // ^ Applies a mask to the avatar image, clipping it into a perfect circle.

                                source: avatarImg
                                // ^ Uses the avatar image as the input.

                                anchors.fill: avatarImg
                                // ^ Same dimensions as the image.

                                maskEnabled: true
                                // ^ Enables the masking feature, which uses maskSource to determine which parts of the source are visible.

                                maskSource: avatarMask
                                // ^ Uses the circular rectangle as the mask—everything outside the circle is clipped away.

                                visible: avatarImg.status === Image.Ready
                                // ^ Only shows the masked avatar when the image has loaded successfully, revealing it as a replacement for the placeholder.
                            }

                            Rectangle {
                                // ^ A subtle border ring around the avatar circle.

                                anchors.fill: parent
                                // ^ Same size as the avatar.

                                radius: height / 2
                                // ^ Perfectly circular border.

                                color: "transparent"
                                // ^ Transparent fill—only the border is visible.

                                border.color: lockUI.failed ? root.red : (lockUI.authenticating ? root.peach : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.5))
                                // ^ Dynamic border color based on state: red on authentication failure, peach while authenticating, and semi-transparent text color (50% opacity) when idle. This provides subtle state feedback around the user's avatar.

                                border.width: Math.max(1, 3 * screenRoot.sc)
                                // ^ Thicker border (3px scaled, minimum 1px) for emphasis, making the avatar ring a noticeable UI element.

                                Behavior on border.color { ColorAnimation { duration: 300 } }
                                // ^ Smooth border color transitions over 300ms for responsive state feedback.
                            }
                        }

                        // Right: Text Details & Input
                        ColumnLayout {
                            // ^ Vertically stacks the username, status row, and password input pill.

                            Layout.alignment: Qt.AlignVCenter
                            // ^ Vertically centers this column within the row.

                            spacing: 16 * screenRoot.sc
                            // ^ Comfortable spacing between the username, status row, and input pill.

                            Text {
                                // ^ Displays the current user's username above the input field.

                                Layout.alignment: Qt.AlignLeft
                                // ^ Left-aligns the username within the column.

                                text: screenRoot.currentUser
                                // ^ Shows the username retrieved by the userPoller (e.g., "john").

                                font.family: "JetBrains Mono"
                                // ^ Consistent monospace font.

                                font.pixelSize: 28 * screenRoot.sc
                                // ^ Large text (28px scaled) for the username, making it clearly visible.

                                font.weight: Font.Bold
                                // ^ Bold for emphasis on the user identity.

                                color: root.text
                                // ^ Primary text color.
                            }

                            RowLayout {
                                // ^ Horizontally arranges the status icon and status text (e.g., lock icon + "ENTER PIN").

                                Layout.alignment: Qt.AlignLeft
                                // ^ Left-aligns the status row.

                                spacing: 12 * screenRoot.sc
                                // ^ Comfortable spacing between icon and text.

                                Rectangle {
                                    // ^ A small circular indicator containing the status icon.

                                    width: 36 * screenRoot.sc
                                    // ^ Small fixed width for the indicator circle.

                                    height: width // Force square
                                    // ^ Equal height for a perfect square base.

                                    radius: height / 2 // Perfect circle
                                    // ^ Half the height creates a perfect circle.

                                    color: lockUI.failed
                                        ? Qt.rgba(root.red.r,   root.red.g,   root.red.b,   0.2)
                                        : (lockUI.authenticating
                                            ? Qt.rgba(root.peach.r, root.peach.g, root.peach.b, 0.2)
                                            : Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.15))
                                    // ^ Dynamic background color: red tint (20% opacity) on failure, peach tint on authenticating, mauve tint (15% opacity) when idle. This provides subtle color-coded state feedback.

                                    border.color: lockUI.failed
                                        ? root.red
                                        : (lockUI.authenticating ? root.peach : root.mauve)
                                    // ^ Matching border color at full opacity for the same states.

                                    border.width: Math.max(1, 1 * screenRoot.sc)
                                    // ^ Thin border (1px scaled, minimum 1px).

                                    Behavior on color { ColorAnimation { duration: 300 } }
                                    // ^ Smooth background color transitions.

                                    Behavior on border.color { ColorAnimation { duration: 300 } }
                                    // ^ Smooth border color transitions.

                                    Text {
                                        // ^ The status icon inside the circle (lock/unlock symbol).

                                        anchors.centerIn: parent
                                        // ^ Centers the icon in the circle.

                                        text: lockUI.failed ? "󰌾" : (lockUI.authenticating ? "󰌿" : "󰌾")
                                        // ^ Shows a closed lock (󰌾) when idle or failed, and an open lock (󰌿) while authenticating. The open lock during authentication suggests the password is being checked.

                                        font.family: "Iosevka Nerd Font"
                                        // ^ Icon font for the lock symbols.

                                        font.pixelSize: 18 * screenRoot.sc
                                        // ^ Appropriately sized for the 36px circle.

                                        color: lockUI.failed
                                            ? root.red
                                            : (lockUI.authenticating ? root.peach : root.mauve)
                                        // ^ Icon color matches the circle's accent for each state.

                                        Behavior on color { ColorAnimation { duration: 300 } }
                                        // ^ Smooth icon color transitions.
                                    }
                                }

                                Text {
                                    // ^ The status message text (e.g., "LOCKED", "ENTER PIN", "AUTHENTICATING...").

                                    font.family: "JetBrains Mono"
                                    // ^ Consistent monospace font.

                                    font.pixelSize: 14 * screenRoot.sc
                                    // ^ Smaller text size for the status label.

                                    font.weight: Font.Medium
                                    // ^ Medium weight for readability.

                                    font.letterSpacing: 2.0
                                    // ^ Increased letter spacing (2px) for a more modern, spaced-out uppercase look.

                                    color: lockUI.failed
                                        ? root.red
                                        : (lockUI.authenticating ? root.peach : root.text)
                                    // ^ Red on failure, peach while authenticating, normal text color when idle.

                                    text: lockUI.statusText.toUpperCase()
                                    // ^ Displays the status text in uppercase using JavaScript's `toUpperCase()` method, reinforcing the modern design.

                                    Behavior on color { ColorAnimation { duration: 300 } }
                                    // ^ Smooth color transitions.
                                }
                            }

                            Rectangle {
                                // ^ The password input pill—a rounded rectangle containing the password dots/characters and hidden input field.

                                id: pinPill
                                // ^ Assigns the identifier "pinPill" for referencing elsewhere (e.g., dotRow references pinPill.height).

                                Layout.alignment: Qt.AlignLeft
                                // ^ Left-aligns the input pill within the column.

                                width: 280 * screenRoot.sc
                                // ^ Wide input field (280px scaled) providing ample space for the password.

                                height: 60 * screenRoot.sc
                                // ^ Comfortable height (60px) for a prominent, easy-to-click input area.

                                radius: height / 2 // Perfect pill shape natively!
                                // ^ Half the height (30px) creates a perfect pill/capsule shape with fully rounded ends.

                                clip: true 
                                // ^ Clips child content to the pill's rounded boundaries. Essential for the dotRow which may scroll horizontally—this prevents text from visually bleeding outside the pill shape.

                                color: lockUI.failed ? Qt.rgba(root.red.r, root.red.g, root.red.b, 0.1) : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.5)
                                // ^ Dynamic background: subtle red tint (10% opacity) on failure, normal surface0 color at 50% opacity otherwise. This provides immediate visual feedback for incorrect passwords.

                                border.width: Math.max(1, 2 * screenRoot.sc)
                                // ^ Slightly thicker border (2px scaled) for emphasis on the primary interactive element.

                                border.color: {
                                    if (lockUI.failed) return root.red;
                                    if (lockUI.authenticating) return root.peach;
                                    if (inputField.text.length > 0) return root.text;
                                    return Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08);
                                }
                                // ^ Multi-state border color: full red on failure, peach while authenticating, full text color when user has started typing (text length > 0), and very subtle (8% opacity) text color when empty/idle. This makes the pill visually respond to all states.

                                Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                // ^ Quick background color transitions (250ms) with exponential easing for snappy feedback.

                                Behavior on border.color { ColorAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                // ^ Matching border color animation speed for cohesive transitions.

                                scale: lockUI.failed ? 1.05 : (lockUI.authenticating ? 0.98 : 1.0)
                                // ^ Subtle scale animation for feedback: slightly expands (5%) on failure (emphasizing the error), slightly shrinks (2%) during authentication (showing it's processing), and normal (100%) when idle. This adds physicality to the UI.

                                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                                // ^ Animates scale changes with back easing (slight overshoot), making the pill feel springy and responsive.

                                transform: Translate { id: shakeTranslate; x: 0 }
                                // ^ Applies a Translate transform to enable horizontal shaking. Initially at x=0 (no offset). The ID "shakeTranslate" allows the shake animation to target this specific transform.

                                SequentialAnimation {
                                    // ^ Defines a shake animation sequence that plays when authentication fails.

                                    id: shakeAnim
                                    // ^ Assigns the identifier so it can be restarted from the Connections handler below.

                                    NumberAnimation { target: shakeTranslate; property: "x"; from: 0; to: -8 * screenRoot.sc; duration: 120; easing.type: Easing.InOutSine }
                                    // ^ First movement: shakes left by 8px (scaled) over 120ms with sine easing for a natural oscillation feel.

                                    NumberAnimation { target: shakeTranslate; property: "x"; from: -8 * screenRoot.sc; to: 8 * screenRoot.sc; duration: 120; easing.type: Easing.InOutSine }
                                    // ^ Second movement: shakes right by 16px total (from -8 to +8) over 120ms, continuing the oscillation.

                                    NumberAnimation { target: shakeTranslate; property: "x"; from: 8 * screenRoot.sc; to: 0; duration: 120; easing.type: Easing.InOutSine }
                                    // ^ Third movement: returns to center from the right position over 120ms, completing the shake and settling. Total animation duration is 360ms for a quick, noticeable shake.
                                }

                                Connections {
                                    // ^ Creates a connection to the lockUI object's signals.

                                    target: lockUI
                                    // ^ Watches the lockUI shared state object for changes.

                                    function onFailedChanged() {
                                        // ^ Called when the `failed` property on lockUI changes.

                                        if (lockUI.failed) shakeAnim.restart();
                                        // ^ If failure just became true (new failed attempt), restarts the shake animation from the beginning. This ensures the shake plays even if a previous failure animation was still in progress.
                                    }
                                }

                                TextInput {
                                    // ^ An invisible text input field that captures all keyboard input for password entry.

                                    id: inputField
                                    // ^ Assigns the identifier for referencing from mouse areas and timers.

                                    anchors.fill: parent
                                    // ^ Fills the entire pill, making the whole area clickable for input.

                                    opacity: 0 
                                    // ^ Completely invisible—the user sees the dotRow visual feedback instead. The TextInput captures keystrokes but doesn't display its own text.

                                    echoMode: TextInput.Password
                                    // ^ Prevents the password from being displayed by the TextInput itself. Combined with opacity:0, this ensures the raw password is never visible on screen.

                                    enabled: !screenRoot.isPlayingIntro
                                    // ^ Disables input during the intro animation, preventing premature password entry.

                                    property string oldText: ""
                                    // ^ Custom property that tracks the previous text content. Used to efficiently detect additions vs deletions for updating the password dots model.

                                    Component.onCompleted: forceActiveFocus()
                                    // ^ When the TextInput initializes, immediately forces keyboard focus. This ensures the lock screen is ready to receive input instantly (though it's overridden by the intro disable).

                                    onActiveFocusChanged: {
                                        // ^ Called when this TextInput gains or loses keyboard focus.

                                        if (!activeFocus && !screenRoot.powerMenuOpen && !screenRoot.isPlayingIntro) {
                                            // ^ If focus is lost AND the power menu isn't open AND the intro isn't playing.
                                            forceActiveFocus();
                                            // ^ Re-claims focus immediately. This prevents the user from accidentally losing the ability to type their password (e.g., by clicking elsewhere).
                                        }
                                    }

                                    Keys.onPressed: (event) => {
                                        // ^ Low-level key press handler that fires for ANY key, before the TextInput processes it.

                                        if (event.key === Qt.Key_Escape) {
                                            // ^ If the Escape key is pressed.

                                            screenRoot.inputActive = false;
                                            // ^ Deactivates input mode, transitioning back to the clock display.

                                            text = "";
                                            // ^ Clears the password field.

                                            passModel.clear();
                                            // ^ Clears all password dots from the visual model.

                                            event.accepted = true;
                                            // ^ Marks the event as handled, preventing it from propagating further.
                                        } 
                                        else if (!screenRoot.inputActive) {
                                            // ^ If any other key is pressed while input mode isn't active (user starts typing from the clock view).

                                            screenRoot.inputActive = true;
                                            // ^ Activates input mode, showing the authentication module.
                                        }
                                    }
                                    
                                    onAccepted: {
                                        // ^ Called when the Enter/Return key is pressed, submitting the password for authentication.

                                        if (text.length > 0 && pam.responseRequired && !lockUI.authenticating) {
                                            // ^ Only proceeds if: (1) there's actual text entered, (2) PAM is ready to receive a response, (3) we're not already in the middle of authenticating.

                                            lockUI.authenticating = true;
                                            // ^ Sets the authenticating flag, which changes the UI to show the processing state.

                                            lockUI.statusText = "Authenticating...";
                                            // ^ Updates status text to inform the user.

                                            lockUI.failed = false;
                                            // ^ Resets the failed flag (in case of a previous failure).

                                            pam.respond(text);
                                            // ^ Sends the entered password to PAM for authentication. The result will come back through the `onCompleted` handler.

                                            text = ""; 
                                            // ^ Clears the password field after submission.

                                            oldText = "";
                                            // ^ Resets the old text tracker.

                                            passModel.clear();
                                            // ^ Clears the visual dots immediately.
                                        }
                                    }
                                    
                                    onTextChanged: {
                                        // ^ Called every time the text content changes (character added or removed).

                                        if (lockUI.authenticating) return;
                                        // ^ If currently authenticating, ignores text changes to prevent UI updates during the processing state.

                                        if (text.length > 0 && !screenRoot.inputActive) {
                                            // ^ If there's text but input mode isn't active (first character typed).
                                            screenRoot.inputActive = true;
                                            // ^ Activates input mode, revealing the authentication UI.
                                        }
                                        
                                        idleTimer.restart();
                                        // ^ Restarts the 15-second idle timer every time the user types or deletes a character, resetting the auto-hide countdown.

                                        if (text !== oldText) {
                                            // ^ Only processes if the text actually changed (guard against redundant updates).

                                            if (text.length > oldText.length) {
                                                // ^ A character was ADDED (new length > old length).
                                                for (let i = oldText.length; i < text.length; i++) {
                                                    // ^ Iterates from the last unchanged position to the end.
                                                    passModel.append({ "charStr": text.charAt(i), "isDot": lockSettings.hidePassword });
                                                    // ^ Appends a new entry to the visual dots model with the actual character and whether it should be shown as a dot (based on the hidePassword setting).
                                                }
                                            } else if (text.length < oldText.length) {
                                                // ^ A character was REMOVED (backspace/delete).
                                                let diff = oldText.length - text.length;
                                                // ^ Calculates how many characters were removed.
                                                for (let i = 0; i < diff; i++) {
                                                    passModel.remove(passModel.count - 1);
                                                    // ^ Removes the last entries from the model, matching the number of deleted characters.
                                                }
                                            } else {
                                                // ^ Same length but text changed (e.g., paste replacing selection).
                                                passModel.clear();
                                                // ^ Clears the model completely.
                                                for (let i = 0; i < text.length; i++) {
                                                    passModel.append({ "charStr": text.charAt(i), "isDot": lockSettings.hidePassword });
                                                    // ^ Rebuilds the entire model from the current text.
                                                }
                                            }
                                            oldText = text;
                                            // ^ Updates the old text tracker to the current content for the next comparison.
                                        }

                                        if (text.length > 0) {
                                            // ^ If there's text in the field (user has started typing).
                                            lockUI.failed = false;
                                            // ^ Clears any previous failure state, returning the UI to normal.
                                            lockUI.statusText = "Enter PIN";
                                            // ^ Updates status to prompt the user to submit.
                                        } else {
                                            // ^ If the field is empty.
                                            if (!lockUI.failed) lockUI.statusText = "Locked";
                                            // ^ If not in a failed state, reverts to "Locked". If in a failed state, keeps the "Access Denied" message visible.
                                        }
                                    }
                                }

                                ListModel {
                                    // ^ A dynamic list model that holds the password characters for display as dots/text.

                                    id: passModel
                                    // ^ Assigns the identifier for the Repeater to use as its model.
                                }

                                Item {
                                    // ^ A container that clips the password dots to the pill boundaries, enabling horizontal scrolling for long passwords.

                                    anchors.fill: parent
                                    // ^ Fills the pinPill.

                                    anchors.leftMargin: 20 * screenRoot.sc
                                    // ^ Left padding inside the pill to prevent the first dot from touching the edge.

                                    anchors.rightMargin: 20 * screenRoot.sc
                                    // ^ Right padding to prevent the last dot from touching the edge.

                                    clip: true
                                    // ^ Clips child content to this container's boundaries. Combined with the margins, this creates an inset area where dots can scroll without overlapping the pill's borders.

                                    Row {
                                        // ^ Horizontally arranges the password dot/character delegates.

                                        id: dotRow
                                        // ^ Assigns the identifier for the scroll behavior.

                                        anchors.verticalCenter: parent.verticalCenter
                                        // ^ Vertically centers the row within the pill.

                                        x: width > parent.width ? parent.width - width : (parent.width - width) / 2
                                        // ^ Smart horizontal positioning: if the row is wider than the container (many characters), right-aligns it so the newest characters are visible (scrolls left). Otherwise, centers the row. This creates an auto-scrolling password display.

                                        spacing: 4 * screenRoot.sc
                                        // ^ Small spacing between dots/characters.
                                        
                                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                        // ^ Animates horizontal position changes (when dots are added/removed and the row repositions), creating smooth scrolling.

                                        Repeater {
                                            // ^ Generates one visual element for each entry in the passModel.

                                            model: passModel
                                            // ^ Uses the password characters model as its data source.

                                            // Render text directly as the delegate to avoid circular layout loops
                                            delegate: Text {
                                                // ^ Each password character is rendered as a Text element.

                                                text: model.isDot ? "•" : model.charStr
                                                // ^ Shows a bullet character (•) if isDot is true, otherwise shows the actual character (briefly visible before the reveal timer fires).

                                                font.family: "JetBrains Mono"
                                                // ^ Consistent monospace font for uniform character widths.

                                                font.pixelSize: model.isDot ? (32 * screenRoot.sc) : (24 * screenRoot.sc)
                                                // ^ Dots are displayed larger (32px) for prominence, while actual characters are slightly smaller (24px). This difference isn't visually jarring because dots are always shown.

                                                font.weight: Font.Bold
                                                // ^ Bold for visibility.

                                                color: lockUI.failed ? root.red : (lockUI.authenticating ? root.peach : root.text)
                                                // ^ Color-coded by state: red on failure, peach during authentication, normal text color otherwise.

                                                verticalAlignment: Text.AlignVCenter
                                                // ^ Vertically centers the text within the pill height.

                                                height: pinPill.height
                                                // ^ Matches the pill height for proper vertical alignment.

                                                NumberAnimation on opacity { from: 0; to: 1; duration: 150 }
                                                // ^ Each new character/dot fades in over 150ms when first added, creating a smooth appearance animation.

                                                Timer {
                                                    // ^ A timer that auto-converts a visible character back to a dot after the reveal duration.

                                                    interval: lockSettings.revealDuration
                                                    // ^ Uses the user-configurable reveal duration (default 300ms) as the timer interval.

                                                    running: !model.isDot && !lockSettings.hidePassword
                                                    // ^ Only runs when: (1) the character is currently visible (not a dot), AND (2) the hidePassword setting is false (user wants characters to be briefly revealed). If hidePassword is true, characters start as dots and stay as dots.

                                                    onTriggered: {
                                                        // ^ Fires after the reveal duration elapses.
                                                        if (index >= 0 && index < passModel.count) {
                                                            // ^ Safely checks that the index is still valid (model hasn't been cleared).
                                                            passModel.setProperty(index, "isDot", true);
                                                            // ^ Changes the `isDot` property to true, which causes the delegate to switch from showing the character to showing a bullet.
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

                // ---------------------------------------------------------
                // 3. BOTTOM SYSTEM INFO PILLS
                // ---------------------------------------------------------
                RowLayout {
                    // ^ Horizontally arranges the information pills (keyboard layout, battery, weather) along the bottom of the screen.

                    anchors.bottom: parent.bottom
                    // ^ Positions at the bottom edge.

                    anchors.bottomMargin: 40 * screenRoot.sc
                    // ^ Adds 40px (scaled) of space from the bottom edge, preventing the pills from touching the screen edge.

                    anchors.horizontalCenter: parent.horizontalCenter
                    // ^ Centers the entire row of pills horizontally.

                    spacing: 16 * screenRoot.sc
                    // ^ Comfortable spacing between adjacent pills.

                    opacity: screenRoot.introState
                    // ^ Fades in as the intro completes, appearing with the rest of the UI.

                    transform: Translate { y: (20 * screenRoot.sc) * (1.0 - screenRoot.introState) }
                    // ^ Slides up from below: starts 20px lower and rises to its final position as introState approaches 1.0.

                    // KB Layout Pill
                    Rectangle {
                        // ^ A pill-shaped container showing the current keyboard layout.

                        property bool isHovered: kbMouse.containsMouse
                        // ^ Custom property that tracks hover state from the mouse area. Used for hover effects like color changes and scaling.

                        Layout.preferredHeight: 48 * screenRoot.sc
                        // ^ Fixed height for the pill (48px scaled), establishing a consistent size for all info pills.

                        Layout.preferredWidth: kbLayoutRow.implicitWidth + (36 * screenRoot.sc)
                        // ^ Dynamic width: measures the content row's natural width and adds padding (36px). This ensures the pill fits its content without being oversized.

                        radius: height / 2 // Dynamic pill shape
                        // ^ Half the height creates perfectly rounded ends, giving the classic pill shape.

                        color: isHovered ? Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.6) : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.4)
                        // ^ Hover effect: lighter background (surface1 at 60% opacity) when hovered, normal surface0 at 40% opacity when idle. This provides subtle interactive feedback.

                        border.color: isHovered ? root.mauve : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08)
                        // ^ Border appears in mauve accent when hovered, nearly invisible text color (8% opacity) when idle. The accent border draws attention to the hovered pill.

                        border.width: Math.max(1, 1 * screenRoot.sc)
                        // ^ Thin border (1px scaled) that becomes visible primarily on hover.

                        scale: isHovered ? 1.05 : 1.0
                        // ^ Slightly enlarges (5%) on hover for a satisfying interactive feel, returning to normal on exit.

                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        // ^ Smooth, snappy scale animation for hover transitions.

                        Behavior on color { ColorAnimation { duration: 200 } }
                        // ^ Quick color transitions for the hover effect.

                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        // ^ Matching border color animation speed.

                        RowLayout { 
                            // ^ Horizontally arranges the keyboard icon and layout text.

                            id: kbLayoutRow; anchors.centerIn: parent; spacing: 8 * screenRoot.sc
                            // ^ Centers the row inside the pill with small spacing between icon and text.

                            Text { text: "󰌌"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18 * screenRoot.sc; color: parent.parent.isHovered ? root.mauve : root.overlay2; Behavior on color { ColorAnimation { duration: 200 } } }
                            // ^ Keyboard icon (󰌌) using Nerd Font. Changes color to mauve when hovered (via parent.parent referencing the pill Rectangle), or stays as overlay2 when idle. Smooth color animation for the transition.

                            Text { text: screenRoot.kbLayout; font.family: "JetBrains Mono"; font.pixelSize: 14 * screenRoot.sc; font.weight: Font.Black; color: root.text }
                            // ^ Displays the keyboard layout code (e.g., "US") in bold monospace. Uses Font.Black (heaviest weight) for maximum contrast at small size.
                        }

                        MouseArea { id: kbMouse; anchors.fill: parent; hoverEnabled: true; enabled: !screenRoot.isPlayingIntro }
                        // ^ Makes the entire pill interactive for hover detection. `hoverEnabled: true` is required for the `containsMouse` property to work. Disabled during intro animation.
                    }

                    // Battery Pill
                    Rectangle {
                        // ^ A pill showing battery percentage and status. Only visible on laptops.

                        property bool isHovered: batMouse.containsMouse
                        // ^ Tracks hover state for interactive effects.

                        visible: !screenRoot.isDesktop
                        // ^ Hidden on desktop systems (no battery). Visible on laptops.

                        Layout.preferredHeight: 48 * screenRoot.sc
                        // ^ Consistent height with other pills.

                        Layout.preferredWidth: batLayoutRow.implicitWidth + (36 * screenRoot.sc)
                        // ^ Dynamic width based on content plus padding.

                        radius: height / 2
                        // ^ Pill shape with fully rounded ends.

                        color: isHovered ? Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.6) : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.4)
                        // ^ Hover and idle background colors matching the keyboard pill style.

                        border.color: isHovered ? batLayoutRow.dynamicBatColor : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08)
                        // ^ Border color: uses the dynamic battery color (green/peach/red) on hover for extra emphasis, subtle text color when idle.

                        border.width: Math.max(1, 1 * screenRoot.sc)
                        // ^ Thin border.

                        scale: isHovered ? 1.05 : 1.0
                        // ^ Hover scale effect.

                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        // ^ Smooth scale animation.

                        Behavior on color { ColorAnimation { duration: 200 } }
                        // ^ Quick background color transitions.

                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        // ^ Quick border color transitions.

                        RowLayout { 
                            // ^ Arranges battery icon and percentage text.

                            id: batLayoutRow; anchors.centerIn: parent; spacing: 8 * screenRoot.sc
                            // ^ Centered row with spacing.

                            property color dynamicBatColor: {
                                if (screenRoot.batStatus === "Charging") return root.green;
                                let pct = parseInt(screenRoot.batPct);
                                if (pct >= 60) return root.green;
                                if (pct >= 25) return root.peach;
                                return root.red;
                            }
                            // ^ Computes the battery color dynamically: green when charging OR above 60%, peach between 25-59%, red below 25%. This property binding automatically updates whenever batStatus or batPct changes, providing real-time color feedback.

                            Text { 
                                text: screenRoot.batStatus === "Charging" ? "󰂄" : (parseInt(screenRoot.batPct) < 20 ? "󰂃" : "󰁹")
                                // ^ Selects the appropriate battery icon: charging icon (󰂄), low battery icon (󰂃) when below 20%, and normal battery icon (󰁹) otherwise.

                                font.family: "Iosevka Nerd Font"
                                // ^ Icon font.

                                font.pixelSize: 20 * screenRoot.sc
                                // ^ Slightly larger icon than the keyboard pill for emphasis.

                                color: batLayoutRow.dynamicBatColor
                                // ^ Uses the dynamic color matching the battery level.

                                Behavior on color { ColorAnimation { duration: 200 } }
                                // ^ Smooth color transitions when battery level changes.
                            }

                            Text { 
                                text: screenRoot.batPct + "%"
                                // ^ Displays the battery percentage with a percent sign.

                                font.family: "JetBrains Mono"
                                // ^ Monospace font for clean number display.

                                font.pixelSize: 14 * screenRoot.sc
                                // ^ Matching text size with other pills.

                                font.weight: Font.Black
                                // ^ Heaviest weight for readability.

                                color: batLayoutRow.dynamicBatColor
                                // ^ Color matches the icon.

                                Behavior on color { ColorAnimation { duration: 200 } }
                                // ^ Smooth color transitions.
                            }
                        }

                        MouseArea { id: batMouse; anchors.fill: parent; hoverEnabled: true; enabled: !screenRoot.isPlayingIntro }
                        // ^ Hover detection for the battery pill, disabled during intro.
                    }

                    // Weather Pill
                    Rectangle {
                        // ^ A pill displaying current weather icon and temperature.

                        property bool isHovered: weatherMouse.containsMouse
                        // ^ Hover state tracker.

                        Layout.preferredHeight: 48 * screenRoot.sc
                        // ^ Consistent height.

                        Layout.preferredWidth: weatherLayoutRow.implicitWidth + (36 * screenRoot.sc)
                        // ^ Dynamic width with padding.

                        radius: height / 2
                        // ^ Pill shape.

                        color: isHovered ? Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.6) : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.4)
                        // ^ Standard hover/idle backgrounds.

                        border.color: isHovered ? root.blue : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08)
                        // ^ Uses blue accent on hover (weather-related), subtle otherwise.

                        border.width: Math.max(1, 1 * screenRoot.sc)
                        // ^ Thin border.

                        scale: isHovered ? 1.05 : 1.0
                        // ^ Hover enlargement.

                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        // ^ Smooth scale animation.

                        Behavior on color { ColorAnimation { duration: 200 } }
                        // ^ Quick color transitions.

                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        // ^ Quick border color transitions.

                        RowLayout { 
                            // ^ Arranges weather icon and temperature.

                            id: weatherLayoutRow; anchors.centerIn: parent; spacing: 8 * screenRoot.sc
                            // ^ Centered with spacing.

                            Text { 
                                text: screenRoot.weatherIcon
                                // ^ Displays the weather condition icon (Nerd Font glyph like  for sun,  for cloud, etc.).

                                font.family: "Iosevka Nerd Font"
                                // ^ Icon font.

                                font.pixelSize: 20 * screenRoot.sc
                                // ^ Larger icon for visibility.

                                color: parent.parent.isHovered ? root.blue : root.text
                                // ^ Blue on hover (matching the pill border), normal text color when idle.

                                Behavior on color { ColorAnimation { duration: 200 } }
                                // ^ Smooth color transitions.
                            }

                            Text { 
                                text: screenRoot.weatherTemp
                                // ^ Displays the temperature (e.g., "22°C" or "72°F").

                                font.family: "JetBrains Mono"
                                // ^ Monospace font.

                                font.pixelSize: 14 * screenRoot.sc
                                // ^ Standard text size.

                                font.weight: Font.Black
                                // ^ Boldest weight.

                                color: root.text
                                // ^ Always uses normal text color for readability.

                                Behavior on color { ColorAnimation { duration: 200 } }
                                // ^ Smooth transitions.
                            }
                        }

                        MouseArea { id: weatherMouse; anchors.fill: parent; hoverEnabled: true; enabled: !screenRoot.isPlayingIntro }
                        // ^ Hover detection, disabled during intro.
                    }
                }

                // ---------------------------------------------------------
                // 4. POWER MENU
                // ---------------------------------------------------------
                Rectangle {
                    // ^ The popup power menu that expands upward from the power button, containing settings toggles and system actions.

                    id: powerMenu
                    // ^ Assigns the identifier for visibility and animation control.

                    anchors.bottom: powerBtn.top
                    // ^ Positions the menu directly above the power button, expanding upward.

                    anchors.right: parent.right
                    // ^ Aligns with the right edge of the screen.

                    anchors.bottomMargin: 15 * screenRoot.sc
                    // ^ Small gap between the power button and the menu.

                    anchors.rightMargin: 40 * screenRoot.sc
                    // ^ Matches the power button's right margin for alignment.

                    width: 280 * screenRoot.sc
                    // ^ Fixed width for the menu panel.

                    height: screenRoot.powerMenuOpen ? (menuLayout.implicitHeight + (20 * screenRoot.sc)) : 0
                    // ^ Dynamic height: when open, measures the content's natural height plus padding. When closed, height is 0 (completely collapsed).

                    radius: 18 * screenRoot.sc
                    // ^ Large corner radius for a modern, card-like appearance.

                    clip: true
                    // ^ Clips content to the rounded boundaries and hides content when height collapses to 0.

                    opacity: screenRoot.powerMenuOpen ? 1 : 0
                    // ^ Fully visible when open, transparent when closed.

                    color: Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.95)
                    // ^ Nearly opaque (95%) surface0 color for the menu background, providing a solid card over the blurred background.

                    border.color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.25)
                    // ^ Subtle mauve border (25% opacity) for a refined edge.

                    border.width: Math.max(1, 1 * screenRoot.sc)
                    // ^ Thin border.

                    Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
                    // ^ Animates height changes over 350ms for smooth expand/collapse. Exponential easing out gives a satisfying deceleration as it reaches full size.

                    Behavior on opacity { NumberAnimation { duration: 250 } }
                    // ^ Quick fade animation for the menu appearance.

                    ColumnLayout {
                        // ^ Vertically stacks the settings section, separator, and system actions.

                        id: menuLayout
                        // ^ Assigns the identifier for measuring implicitHeight.

                        anchors.top: parent.top
                        // ^ Anchored to the top of the menu.

                        anchors.topMargin: 10 * screenRoot.sc
                        // ^ Top padding inside the menu.

                        anchors.left: parent.left
                        // ^ Fills from the left edge.

                        anchors.right: parent.right
                        // ^ Fills to the right edge (with margins handled by individual items).

                        spacing: 6 * screenRoot.sc
                        // ^ Small spacing between menu items.

                        // --- SETTINGS SECTION ---
                        Text { 
                            // ^ Section header for the settings toggles.

                            text: "SETTINGS"
                            // ^ Uppercase for modern, button-like labeling.

                            font.family: "JetBrains Mono"
                            // ^ Monospace font.

                            font.weight: Font.Black
                            // ^ Heaviest weight for the header.

                            font.pixelSize: 12 * screenRoot.sc
                            // ^ Small text for the section label.

                            font.letterSpacing: 1.5
                            // ^ Increased letter spacing for the uppercase aesthetic.

                            color: root.mauve
                            // ^ Mauve accent color for the section header.

                            Layout.leftMargin: 18 * screenRoot.sc; Layout.topMargin: 4 * screenRoot.sc; Layout.bottomMargin: 4 * screenRoot.sc 
                            // ^ Indentation and vertical spacing for the header.
                        }

                        // Hide Password Toggle
                        RowLayout {
                            // ^ A row containing the toggle label and the toggle switch.

                            Layout.fillWidth: true; Layout.leftMargin: 18 * screenRoot.sc; Layout.rightMargin: 18 * screenRoot.sc; Layout.topMargin: 4 * screenRoot.sc
                            // ^ Full width with horizontal padding.

                            Text {
                                // ^ Label for the password visibility toggle.

                                text: "Hide password"
                                // ^ Descriptive label.

                                font.family: "JetBrains Mono"
                                // ^ Monospace font.

                                font.pixelSize: 14 * screenRoot.sc
                                // ^ Readable text size.

                                font.weight: Font.Medium
                                // ^ Medium weight for body text.

                                color: root.text
                                // ^ Primary text color.

                                Layout.fillWidth: true
                                // ^ Expands to fill available space, pushing the toggle switch to the right.
                            }
                            
                            Rectangle {
                                // ^ A custom toggle switch (iOS-style).

                                width: 40 * screenRoot.sc; height: 22 * screenRoot.sc; radius: height / 2
                                // ^ Pill-shaped toggle with rounded ends.

                                color: lockSettings.hidePassword ? root.mauve : root.surface2
                                // ^ Mauve background when active (hiding password), surface2 gray when inactive (showing password).

                                Behavior on color { ColorAnimation { duration: 250 } }
                                // ^ Smooth background color transition when toggling.

                                Rectangle {
                                    // ^ The sliding toggle knob.

                                    width: height; height: 18 * screenRoot.sc; radius: height / 2
                                    // ^ Perfectly circular knob, slightly smaller than the track height.

                                    x: lockSettings.hidePassword ? parent.width - width - (2 * screenRoot.sc) : (2 * screenRoot.sc)
                                    // ^ Position: right side when active (hidePassword=true), left side when inactive. The 2px margin prevents the knob from touching the edges.

                                    y: (parent.height - height) / 2
                                    // ^ Vertically centers the knob within the track.

                                    color: root.base
                                    // ^ Base color for the knob, providing contrast against the colored track.

                                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                    // ^ Animated sliding with back easing for a springy toggle feel.
                                }

                                MouseArea { 
                                    // ^ Makes the toggle switch clickable.

                                    anchors.fill: parent; 
                                    // ^ Fills the entire switch.

                                    onClicked: {
                                        // ^ Handles click to toggle the setting.

                                        lockSettings.hidePassword = !lockSettings.hidePassword;
                                        // ^ Flips the boolean value (true ↔ false).

                                        if (lockSettings.hidePassword) {
                                            // ^ If now hiding passwords (just switched to ON).
                                            for(let i = 0; i < passModel.count; i++) passModel.setProperty(i, "isDot", true);
                                            // ^ Immediately converts all currently visible characters in the password model to dots, ensuring privacy is instantly applied to any already-typed password.
                                        }
                                    }
                                }
                            }
                        }

                        // Reveal Delay Slider
                        ColumnLayout {
                            // ^ Contains the reveal delay label, value display, and custom slider.

                            Layout.fillWidth: true; Layout.leftMargin: 18 * screenRoot.sc; Layout.rightMargin: 18 * screenRoot.sc; Layout.topMargin: 8 * screenRoot.sc; Layout.bottomMargin: 8 * screenRoot.sc; spacing: 8 * screenRoot.sc
                            // ^ Full width with padding.

                            opacity: lockSettings.hidePassword ? 0.3 : 1.0
                            // ^ Dimmed (30% opacity) when password hiding is active, as the reveal delay is irrelevant when characters are never shown. Full opacity when characters can be revealed.

                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            // ^ Smooth opacity transition when the hidePassword setting changes.

                            RowLayout {
                                // ^ Row for the delay label and current value.

                                Layout.fillWidth: true
                                // ^ Full width.

                                Text {
                                    // ^ Label for the reveal delay setting.

                                    text: "Reveal delay"
                                    // ^ Descriptive label.

                                    font.family: "JetBrains Mono"
                                    // ^ Monospace font.

                                    font.pixelSize: 14 * screenRoot.sc
                                    // ^ Standard text size.

                                    font.weight: Font.Medium
                                    // ^ Medium weight.

                                    color: root.blue
                                    // ^ Blue accent to match the weather/settings color theme.

                                    Layout.fillWidth: true
                                    // ^ Expands to push the value text right.
                                }

                                Text { 
                                    // ^ Displays the current delay value.

                                    text: lockSettings.revealDuration >= 1000 ? (lockSettings.revealDuration / 1000).toFixed(1) + " s" : lockSettings.revealDuration + " ms"
                                    // ^ Formats the value: if 1000ms or more, shows in seconds with one decimal (e.g., "1.5 s"), otherwise shows in milliseconds (e.g., "300 ms").

                                    font.family: "JetBrains Mono"
                                    // ^ Monospace font.

                                    font.pixelSize: 13 * screenRoot.sc
                                    // ^ Slightly smaller than the label.

                                    font.weight: Font.Bold
                                    // ^ Bold for emphasis.

                                    color: root.peach
                                    // ^ Peach accent for the value display.
                                }
                            }
                            
                            Item {
                                // ^ Container for the custom slider track and thumb.

                                Layout.fillWidth: true; Layout.preferredHeight: 28 * screenRoot.sc
                                // ^ Full width with fixed height for the slider.

                                Rectangle {
                                    // ^ The slider track (background line).

                                    anchors.verticalCenter: parent.verticalCenter
                                    // ^ Vertically centered in the container.

                                    width: parent.width; height: 8 * screenRoot.sc; radius: height / 2; color: root.surface2
                                    // ^ Full-width track, 8px tall, with rounded ends, using surface2 color.

                                    Rectangle {
                                        // ^ The filled portion of the track (progress bar).

                                        width: ((lockSettings.revealDuration - 100) / 2900) * parent.width
                                        // ^ Width proportional to the current value within the range: (current - min) / range * trackWidth. The range is 100ms to 3000ms, so (value - 100) / 2900 determines the fill percentage.

                                        height: parent.height; radius: height / 2; color: root.mauve
                                        // ^ Same height as the track, rounded, colored with mauve accent.
                                    }
                                }
                                
                                Rectangle {
                                    // ^ The slider thumb (draggable circle).

                                    id: sliderThumb
                                    // ^ Assigns the identifier for the position calculation.

                                    width: 20 * screenRoot.sc
                                    // ^ 20px diameter circle.

                                    height: width
                                    // ^ Perfectly circular.

                                    radius: height / 2
                                    // ^ Half height = perfect circle.

                                    color: root.peach
                                    // ^ Peach accent for the thumb.

                                    border.color: root.crust; border.width: Math.max(1, 2 * screenRoot.sc)
                                    // ^ Dark border (crust color) for contrast, 2px thick.

                                    anchors.verticalCenter: parent.verticalCenter
                                    // ^ Vertically centered on the track.

                                    x: Math.max(0, Math.min(((lockSettings.revealDuration - 100) / 2900) * parent.width - (width / 2), parent.width - width))
                                    // ^ Position calculation: maps the value (100-3000 range) to the track width, centers the thumb on that position (subtracts half thumb width), and clamps between 0 and (trackWidth - thumbWidth) using Math.max/Min to prevent overflow.

                                    scale: sliderMouse.pressed ? 1.3 : (sliderMouse.containsMouse ? 1.15 : 1.0)
                                    // ^ Interactive scaling: expands to 130% when actively dragging (pressed), 115% on hover, normal otherwise. Provides satisfying tactile feedback.

                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                    // ^ Bouncy scale animation for the thumb.
                                }
                                
                                MultiEffect {
                                    // ^ Adds a drop shadow to the slider thumb for depth.

                                    source: sliderThumb
                                    // ^ Uses the thumb as the shadow source.

                                    anchors.fill: sliderThumb
                                    // ^ Same dimensions as the thumb.

                                    shadowEnabled: true
                                    // ^ Enables the shadow effect.

                                    shadowBlur: 0.5
                                    // ^ Tight, sharp shadow (low blur radius).

                                    shadowColor: "#000000"
                                    // ^ Pure black shadow.

                                    shadowOpacity: 0.4
                                    // ^ 40% opacity for a subtle but noticeable shadow.

                                    shadowVerticalOffset: 2 * screenRoot.sc
                                    // ^ Shadow drops 2px (scaled) below the thumb.
                                }

                                MouseArea {
                                    // ^ Interactive area for dragging the slider.

                                    id: sliderMouse
                                    // ^ Assigns the identifier for the thumb scale binding.

                                    anchors.fill: parent
                                    // ^ Covers the entire slider area (full width of the track).

                                    hoverEnabled: true
                                    // ^ Enables hover detection for the thumb scale effect.

                                    enabled: !lockSettings.hidePassword
                                    // ^ Disabled when password hiding is on (since reveal delay is irrelevant), preventing interaction.

                                    preventStealing: true
                                    // ^ Prevents other mouse areas from stealing events when the user starts dragging from this area, ensuring smooth drag interaction.

                                    function updateVal(mouseX) {
                                        // ^ Helper function to update the duration value based on the mouse X position.

                                        let pct = Math.max(0, Math.min(1, mouseX / width));
                                        // ^ Calculates the percentage (0.0 to 1.0) based on where the mouse is horizontally within the slider, clamped between 0 and 1.

                                        let ms = Math.round(100 + (pct * 2900));
                                        // ^ Converts percentage to milliseconds in the range 100-3000ms: 100ms base + (percentage * 2900ms range). Rounds to nearest integer.

                                        if (ms % 100 < 10) ms -= (ms % 100);
                                        // ^ Snaps to nearest 100ms when close to a hundred boundary (within 10ms). If the value is 247, the remainder is 47 (not <10), no change. If 305, remainder 5 (<10), snaps down to 300.

                                        else if (ms % 100 > 90) ms += (100 - (ms % 100));
                                        // ^ Snaps up to the next hundred when within 10ms above. If 395, remainder 95 (>90), snaps to 400. This creates a subtle magnetic snap near round numbers.

                                        lockSettings.revealDuration = ms;
                                        // ^ Updates the persistent setting with the calculated value, which triggers the visual update and saves to disk.
                                    }

                                    onPositionChanged: (mouse) => {
                                        // ^ Called when the mouse moves over the slider area.

                                        if (pressed) {
                                            // ^ Only updates the value if the mouse button is held down (dragging), not on simple hover.

                                            updateVal(mouse.x);
                                            // ^ Calls the update function with the current mouse X position.
                                        }
                                    }

                                    onPressed: (mouse) => updateVal(mouse.x)
                                    // ^ Called on initial press: immediately updates the value to where the user clicked, allowing instant jumping to any position on the track.
                                }
                            }
                        }

                        // Separator
                        Rectangle {
                            // ^ A thin horizontal line separating the settings section from the system actions.

                            Layout.fillWidth: true; Layout.preferredHeight: Math.max(1, 1 * screenRoot.sc)
                            // ^ Full width, minimum 1px height (scaled).

                            color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.2)
                            // ^ Mauve color at 20% opacity for a subtle, themed divider.

                            Layout.leftMargin: 18 * screenRoot.sc; Layout.rightMargin: 18 * screenRoot.sc; Layout.topMargin: 4 * screenRoot.sc; Layout.bottomMargin: 4 * screenRoot.sc
                            // ^ Horizontal padding and vertical spacing around the divider.
                        }

                        // --- SYSTEM ACTIONS SECTION ---
                        Text {
                            // ^ Section header for the system action buttons.

                            text: "SYSTEM"
                            // ^ Uppercase label.

                            font.family: "JetBrains Mono"
                            // ^ Monospace font.

                            font.weight: Font.Black
                            // ^ Boldest weight.

                            font.pixelSize: 12 * screenRoot.sc
                            // ^ Small header text.

                            font.letterSpacing: 1.5
                            // ^ Letter spacing for the uppercase look.

                            color: root.mauve
                            // ^ Mauve accent.

                            Layout.leftMargin: 18 * screenRoot.sc; Layout.bottomMargin: 4 * screenRoot.sc
                            // ^ Indentation and bottom spacing.
                        }

                        Rectangle {
                            // ^ The reboot button row.

                            Layout.fillWidth: true; Layout.preferredHeight: 48 * screenRoot.sc; Layout.leftMargin: 10 * screenRoot.sc; Layout.rightMargin: 10 * screenRoot.sc; radius: 12 * screenRoot.sc
                            // ^ Full width with smaller horizontal padding, fixed height, rounded corners.

                            color: ma1.containsMouse ? Qt.rgba(root.blue.r, root.blue.g, root.blue.b, 0.1) : "transparent"
                            // ^ Blue tint (10% opacity) on hover, transparent otherwise.

                            scale: ma1.pressed ? 0.95 : (ma1.containsMouse ? 1.02 : 1.0)
                            // ^ Shrinks slightly when pressed (95%), grows slightly on hover (102%), normal otherwise. Provides tactile button feedback.

                            Behavior on color { ColorAnimation { duration: 200 } }
                            // ^ Quick color transitions.

                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            // ^ Bouncy scale transitions.

                            RowLayout {
                                // ^ Arranges the icon, spacer, and text.

                                anchors.fill: parent; anchors.leftMargin: 16 * screenRoot.sc; anchors.rightMargin: 16 * screenRoot.sc; spacing: 0
                                // ^ Fills the parent with horizontal padding, no spacing (spacer handles distribution).

                                Text { text: "󰜉"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18 * screenRoot.sc; color: ma1.containsMouse ? root.blue : Qt.rgba(root.blue.r, root.blue.g, root.blue.b, 0.6); Behavior on color { ColorAnimation { duration: 200 } } }
                                // ^ Reboot icon. Full blue on hover, 60% opacity blue otherwise.

                                Item { Layout.fillWidth: true }
                                // ^ Spacer that fills the remaining space between icon and text, pushing text to the right.

                                Text { text: "Reboot"; font.family: "JetBrains Mono"; font.pixelSize: 15 * screenRoot.sc; font.weight: Font.Medium; color: ma1.containsMouse ? root.blue : Qt.rgba(root.blue.r, root.blue.g, root.blue.b, 0.6); Behavior on color { ColorAnimation { duration: 200 } } }
                                // ^ "Reboot" label with hover color effect matching the icon.
                            }

                            MouseArea { 
                                // ^ Interactive area for the reboot button.

                                id: ma1; anchors.fill: parent; hoverEnabled: true;
                                // ^ Fills the button, hover enabled for visual feedback.

                                onClicked: {
                                    // ^ Handles click on the reboot button.

                                    screenRoot.powerMenuOpen = false;
                                    // ^ Closes the power menu.

                                    reloadProcess.running = true;
                                    // ^ Starts the reboot process (systemctl reboot).
                                }
                            }
                        }

                        Rectangle {
                            // ^ The suspend button row, identical structure to reboot.

                            Layout.fillWidth: true; Layout.preferredHeight: 48 * screenRoot.sc; Layout.leftMargin: 10 * screenRoot.sc; Layout.rightMargin: 10 * screenRoot.sc; radius: 12 * screenRoot.sc
                            // ^ Same dimensions and padding.

                            color: ma2.containsMouse ? Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.1) : "transparent"
                            // ^ Mauve tint on hover instead of blue.

                            scale: ma2.pressed ? 0.95 : (ma2.containsMouse ? 1.02 : 1.0)
                            // ^ Same press/hover scale behavior.

                            Behavior on color { ColorAnimation { duration: 200 } }
                            // ^ Quick color transitions.

                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            // ^ Bouncy scale transitions.

                            RowLayout {
                                // ^ Icon, spacer, and text.

                                anchors.fill: parent; anchors.leftMargin: 16 * screenRoot.sc; anchors.rightMargin: 16 * screenRoot.sc; spacing: 0
                                // ^ Fills with padding.

                                Text { text: "󰒲"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18 * screenRoot.sc; color: ma2.containsMouse ? root.mauve : Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.6); Behavior on color { ColorAnimation { duration: 200 } } }
                                // ^ Suspend/sleep icon (󰒲). Mauve on hover, 60% opacity otherwise.

                                Item { Layout.fillWidth: true }
                                // ^ Spacer.

                                Text { text: "Suspend"; font.family: "JetBrains Mono"; font.pixelSize: 15 * screenRoot.sc; font.weight: Font.Medium; color: ma2.containsMouse ? root.mauve : Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.6); Behavior on color { ColorAnimation { duration: 200 } } }
                                // ^ "Suspend" label.
                            }

                            MouseArea { 
                                // ^ Interactive area for suspend.

                                id: ma2; anchors.fill: parent; hoverEnabled: true;
                                // ^ Fills the button with hover.

                                onClicked: {
                                    // ^ Click handler.

                                    screenRoot.powerMenuOpen = false;
                                    // ^ Closes menu.

                                    suspendProcess.running = true;
                                    // ^ Triggers systemctl suspend to put the machine to sleep.
                                }
                            }
                        }

                        Rectangle {
                            // ^ The power off button row, using red for the destructive action.

                            Layout.fillWidth: true; Layout.preferredHeight: 48 * screenRoot.sc; Layout.leftMargin: 10 * screenRoot.sc; Layout.rightMargin: 10 * screenRoot.sc; Layout.bottomMargin: 8 * screenRoot.sc; radius: 12 * screenRoot.sc
                            // ^ Same structure with extra bottom margin for padding before the menu edge.

                            color: ma3.containsMouse ? Qt.rgba(root.red.r, root.red.g, root.red.b, 0.1) : "transparent"
                            // ^ Red tint on hover to indicate the destructive nature of this action.

                            scale: ma3.pressed ? 0.95 : (ma3.containsMouse ? 1.02 : 1.0)
                            // ^ Same interactive scaling.

                            Behavior on color { ColorAnimation { duration: 200 } }
                            // ^ Quick color transitions.

                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            // ^ Bouncy scale.

                            RowLayout {
                                // ^ Icon, spacer, and text.

                                anchors.fill: parent; anchors.leftMargin: 16 * screenRoot.sc; anchors.rightMargin: 16 * screenRoot.sc; spacing: 0
                                // ^ Fills with padding.

                                Text { text: "󰐥"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18 * screenRoot.sc; color: ma3.containsMouse ? root.red : Qt.rgba(root.red.r, root.red.g, root.red.b, 0.6); Behavior on color { ColorAnimation { duration: 200 } } }
                                // ^ Power off icon (󰐥). Full red on hover, 60% opacity red otherwise.

                                Item { Layout.fillWidth: true }
                                // ^ Spacer.

                                Text { text: "Power Off"; font.family: "JetBrains Mono"; font.pixelSize: 15 * screenRoot.sc; font.weight: Font.Medium; color: ma3.containsMouse ? root.red : Qt.rgba(root.red.r, root.red.g, root.red.b, 0.6); Behavior on color { ColorAnimation { duration: 200 } } }
                                // ^ "Power Off" label in red.
                            }

                            MouseArea { 
                                // ^ Interactive area for power off.

                                id: ma3; anchors.fill: parent; hoverEnabled: true;
                                // ^ Fills button with hover.

                                onClicked: {
                                    // ^ Click handler.

                                    screenRoot.powerMenuOpen = false;
                                    // ^ Closes menu.

                                    poweroffProcess.running = true;
                                    // ^ Triggers systemctl poweroff to shut down the machine completely.
                                }
                            }
                        }
                    }
                }

                // Enlarged Power Button
                Rectangle {
                    // ^ A large circular button in the bottom-right corner that toggles the power menu.

                    id: powerBtn
                    // ^ Assigns the identifier for positioning the power menu above it.

                    anchors.bottom: parent.bottom
                    // ^ Bottom edge alignment.

                    anchors.right: parent.right
                    // ^ Right edge alignment.

                    anchors.margins: 40 * screenRoot.sc
                    // ^ 40px (scaled) margin from both the bottom and right edges.

                    width: 52 * screenRoot.sc
                    // ^ Larger than the info pills (52px vs 48px) for emphasis as a primary action.

                    height: width
                    // ^ Perfectly square for a circular button.

                    radius: height / 2
                    // ^ Half the height creates a perfect circle.

                    color: screenRoot.powerMenuOpen 
                            ? root.surface2 
                            : (powerBtnMa.containsMouse ? Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.8) : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.4))
                    // ^ Triple-state background: highest elevation (surface2) when menu is open, lighter surface1 (80% opacity) on hover, normal surface0 (40% opacity) when idle.

                    border.color: screenRoot.powerMenuOpen ? root.text : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.15)
                    // ^ Full text color border when menu is open, nearly invisible (15% opacity) otherwise.

                    border.width: Math.max(1, 1 * screenRoot.sc)
                    // ^ Thin border.

                    opacity: screenRoot.introState
                    // ^ Fades in with the intro animation.

                    transform: Translate { y: (20 * screenRoot.sc) * (1.0 - screenRoot.introState) }
                    // ^ Slides up from below during intro.

                    scale: powerBtnMa.pressed ? 0.9 : (powerBtnMa.containsMouse ? 1.08 : 1.0)
                    // ^ Shrinks to 90% when pressed, expands to 108% on hover, normal size otherwise. The larger hover scale (8% vs 5% for info pills) emphasizes this as the primary interactive element.

                    Behavior on color { ColorAnimation { duration: 200 } }
                    // ^ Quick background transitions.

                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    // ^ Quick border transitions.

                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                    // ^ Bouncy scale animation for satisfying button feedback.

                    Text {
                        // ^ The power icon inside the button.

                        anchors.centerIn: parent
                        // ^ Perfectly centered.

                        text: "󰐥"
                        // ^ Power symbol icon.

                        font.family: "Iosevka Nerd Font"
                        // ^ Icon font.

                        font.pixelSize: 22 * screenRoot.sc
                        // ^ Slightly larger than the info pill icons for emphasis.

                        color: screenRoot.powerMenuOpen ? root.red : (powerBtnMa.containsMouse ? root.text : root.subtext0)
                        // ^ Red when menu is open (highlighting the active state), full text color on hover, subdued subtext0 when idle.
                        
                        Behavior on color { ColorAnimation { duration: 200 } }
                        // ^ Smooth icon color transitions.
                    }

                    MouseArea {
                        // ^ Interactive area for the power button.

                        id: powerBtnMa
                        // ^ Assigns the identifier for the containsMouse binding above.

                        anchors.fill: parent
                        // ^ Covers the entire circular button.

                        hoverEnabled: true
                        // ^ Enables hover detection for the visual effects.

                        enabled: !screenRoot.isPlayingIntro
                        // ^ Disabled during intro animation to prevent accidental clicks.

                        onClicked: {
                            // ^ Toggles the power menu on click.

                            screenRoot.powerMenuOpen = !screenRoot.powerMenuOpen;
                            // ^ Flips the boolean: opens if closed, closes if open.

                            if (!screenRoot.powerMenuOpen) inputField.forceActiveFocus();
                            // ^ If closing the menu, returns keyboard focus to the password input field immediately so the user can continue typing.
                        }
                    }
                }

                // ---------------------------------------------------------
                // 5. INTRO ANIMATION OVERLAY
                // ---------------------------------------------------------
                Item {
                    // ^ An overlay container that displays the intro animation (expanding rings and lock icon transition). This sits on top of all other content.

                    id: introOverlay
                    // ^ Assigns the identifier for controlling visibility and opacity during the animation.

                    anchors.fill: parent
                    // ^ Covers the entire screen.

                    z: 999
                    // ^ Rendered on top of everything else, ensuring the intro animation isn't obscured by any other UI elements.

                    visible: screenRoot.isPlayingIntro || opacity > 0
                    // ^ Visible while the intro is playing, AND remains visible while opacity fades out (prevents it from disappearing mid-fade). Once opacity reaches 0, it becomes invisible.

                    Rectangle {
                        // ^ The outermost expanding ring of the intro animation (ring 3).

                        id: ring3
                        // ^ Assigns the identifier for the intro sequence to animate.

                        width: 360 * screenRoot.sc
                        // ^ Largest ring at 360px diameter.

                        height: width
                        // ^ Perfect circle dimensions.

                        radius: height / 2 
                        // ^ Circular shape.

                        anchors.centerIn: parent
                        // ^ Centered on screen.

                        color: "transparent"
                        // ^ Only the border is visible.

                        border.color: root.mauve
                        // ^ Mauve border color.

                        border.width: Math.max(1, 1 * screenRoot.sc)
                        // ^ Thin border.

                        scale: 0.5
                        // ^ Starts at half size, will expand during animation.

                        opacity: 0.0
                        // ^ Starts invisible, will briefly appear during the animation.
                    }

                    Rectangle {
                        // ^ The middle ring (ring 2).

                        id: ring2
                        // ^ Assigns the identifier for animation.

                        width: 300 * screenRoot.sc
                        // ^ Medium ring at 300px.

                        height: width
                        // ^ Perfect circle.

                        radius: height / 2 
                        // ^ Circular.

                        anchors.centerIn: parent
                        // ^ Centered.

                        color: "transparent"
                        // ^ Only border visible.

                        border.color: root.text
                        // ^ Text color border.

                        border.width: Math.max(1, 1 * screenRoot.sc)
                        // ^ Thin border.

                        scale: 0.8
                        // ^ Starts at 80% size.

                        opacity: 0.0
                        // ^ Starts invisible.
                    }

                    Rectangle {
                        // ^ The innermost ring (ring 1), closest to the lock orb.

                        id: ring1
                        // ^ Assigns the identifier for animation.

                        width: 240 * screenRoot.sc
                        // ^ Smallest ring at 240px.

                        height: width
                        // ^ Perfect circle.

                        radius: height / 2 
                        // ^ Circular.

                        anchors.centerIn: parent
                        // ^ Centered.

                        color: "transparent"
                        // ^ Only border visible.

                        border.color: root.text
                        // ^ Text color border.

                        border.width: Math.max(1, 2 * screenRoot.sc)
                        // ^ Slightly thicker border (2px) than the outer rings for emphasis.

                        scale: 0.8
                        // ^ Starts at 80% size.

                        opacity: 0.0
                        // ^ Starts invisible.
                    }

                    Item {
                        // ^ Container for the central lock icon orb.

                        id: introLockOrb
                        // ^ Assigns the identifier for position animation (shake during intro).

                        width: 170 * screenRoot.sc
                        // ^ 170px diameter circle.

                        height: width
                        // ^ Perfect circle.

                        anchors.centerIn: parent
                        // ^ Centered on screen.

                        scale: 0.0
                        // ^ Starts scaled to nothing (0%), will scale up to 100%.

                        opacity: 0.0
                        // ^ Starts invisible, will fade in.

                        Rectangle {
                            // ^ The circular background of the lock orb.

                            anchors.fill: parent
                            // ^ Fills the orb container.

                            radius: height / 2
                            // ^ Perfect circle.

                            color: Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.9)
                            // ^ Nearly opaque (90%) surface0 color for the orb background.

                            border.color: root.text
                            // ^ Text color border.

                            border.width: Math.max(1, 2 * screenRoot.sc)
                            // ^ 2px border for definition.
                        }

                        Text {
                            // ^ The unlocked icon (initially shown).

                            id: introIconUnlocked
                            // ^ Assigns the identifier for the icon swap animation.

                            anchors.centerIn: parent
                            // ^ Centered in the orb.

                            text: "󰌿"
                            // ^ Unlocked lock icon.

                            font.family: "Iosevka Nerd Font"
                            // ^ Icon font.

                            font.pixelSize: 64 * screenRoot.sc 
                            // ^ Large icon filling most of the orb.

                            color: root.text
                            // ^ Text color.

                            opacity: 1.0
                            // ^ Fully visible initially.

                            scale: 1.0
                            // ^ Normal size.

                            transformOrigin: Item.Center
                            // ^ Scale transform originates from the center of the element.
                        }

                        Text {
                            // ^ The locked icon (shown after the swap).

                            id: introIconLocked
                            // ^ Assigns the identifier for the icon swap animation.

                            anchors.centerIn: parent
                            // ^ Centered.

                            text: "󰌾"
                            // ^ Locked lock icon.

                            font.family: "Iosevka Nerd Font"
                            // ^ Icon font.

                            font.pixelSize: 64 * screenRoot.sc 
                            // ^ Same size as unlocked.

                            color: root.text
                            // ^ Text color.

                            opacity: 0.0
                            // ^ Starts invisible, will fade in as unlocked fades out.

                            scale: 1.6
                            // ^ Starts larger (160%), will shrink to normal during the swap animation, creating a zoom-in effect for the locked icon.

                            transformOrigin: Item.Center
                            // ^ Center-originating scale.
                        }
                    }

                    SequentialAnimation {
                        // ^ The complete intro animation sequence, running multiple sub-animations in order.

                        id: introSequence
                        // ^ Assigns the identifier for starting from Component.onCompleted.
                        
                        ParallelAnimation {
                            // ^ First phase: all elements animate simultaneously (in parallel).

                            NumberAnimation { target: introLockOrb; property: "scale"; from: 0.0; to: 1.0; duration: 300; easing.type: Easing.OutCubic }
                            // ^ The lock orb scales from nothing to full size over 300ms, with a smooth cubic ease out (starts fast, decelerates).

                            NumberAnimation { target: introLockOrb; property: "opacity"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
                            // ^ The orb fades in slightly faster than it scales (200ms vs 300ms), ensuring it's visible during most of the scale animation.

                            NumberAnimation { target: ring1; property: "scale"; from: 0.8; to: 1.25; duration: 250; easing.type: Easing.OutCubic }
                            // ^ Ring 1 expands from 80% to 125% and...

                            NumberAnimation { target: ring1; property: "opacity"; from: 0.6; to: 0.0; duration: 250; easing.type: Easing.OutCubic }
                            // ^ ...simultaneously fades from 60% opacity to invisible, creating a ripple that expands and disappears.

                            NumberAnimation { target: ring2; property: "scale"; from: 0.8; to: 1.4; duration: 300; easing.type: Easing.OutCubic }
                            // ^ Ring 2 expands further (to 140%) over a longer duration (300ms).

                            NumberAnimation { target: ring2; property: "opacity"; from: 0.4; to: 0.0; duration: 300; easing.type: Easing.OutCubic }
                            // ^ Ring 2 fades out starting from lower opacity (40%), creating a layered ripple effect.

                            NumberAnimation { target: ring3; property: "scale"; from: 0.5; to: 1.5; duration: 350; easing.type: Easing.OutCubic }
                            // ^ Ring 3 expands the most (from 50% to 150%) over the longest duration (350ms).

                            NumberAnimation { target: ring3; property: "opacity"; from: 0.3; to: 0.0; duration: 350; easing.type: Easing.OutCubic }
                            // ^ Ring 3 fades out from 30% opacity, completing the ripple wave outward.

                            SequentialAnimation {
                                // ^ Nested within the parallel animation: after a pause, performs the lock icon swap.

                                PauseAnimation { duration: 300 } 
                                // ^ Waits 300ms before starting the icon swap, letting the orb finish scaling in first.

                                ParallelAnimation {
                                    // ^ Both icons animate simultaneously.

                                    NumberAnimation { target: introIconUnlocked; property: "scale"; from: 1.0; to: 0.5; duration: 100; easing.type: Easing.InCubic }
                                    // ^ Unlocked icon shrinks from normal to 50% over 100ms (fast shrink).

                                    NumberAnimation { target: introIconUnlocked; property: "opacity"; from: 1.0; to: 0.0; duration: 50 }
                                    // ^ Unlocked icon quickly fades out over 50ms.

                                    NumberAnimation { target: introIconLocked; property: "scale"; from: 1.6; to: 1.0; duration: 200; easing.type: Easing.OutBack }
                                    // ^ Locked icon shrinks from 160% to normal over 200ms with back easing (overshoots slightly), creating a satisfying "lock" impression.

                                    NumberAnimation { target: introIconLocked; property: "opacity"; from: 0.0; to: 1.0; duration: 100 }
                                    // ^ Locked icon fades in over 100ms, overlapping with the unlocked icon's fade out.

                                    SequentialAnimation {
                                        // ^ A subtle shake/vibration of the orb mimicking a lock mechanism engaging.

                                        NumberAnimation { target: introLockOrb; property: "anchors.verticalCenterOffset"; from: 0; to: 3 * screenRoot.sc; duration: 40; easing.type: Easing.OutQuad }
                                        // ^ Quick downward nudge (3px) over 40ms.

                                        NumberAnimation { target: introLockOrb; property: "anchors.verticalCenterOffset"; from: 3 * screenRoot.sc; to: 0; duration: 120; easing.type: Easing.OutBack }
                                        // ^ Bounces back to center over 120ms with back easing, creating a vibration feel.
                                    }
                                }
                            }
                        }
                        
                        PauseAnimation { duration: 50 }
                        // ^ Brief 50ms pause after the lock animation completes, letting the user see the locked icon briefly.

                        SequentialAnimation {
                            // ^ Final phase: the lock orb scales up and fades out, revealing the main UI.

                            ParallelAnimation {
                                // ^ Orb scale and overlay fade happen together.

                                NumberAnimation { target: introLockOrb; property: "scale"; to: 1.8; duration: 100; easing.type: Easing.InCubic }
                                // ^ The orb quickly scales up to 180% (expanding dramatically).

                                NumberAnimation { target: introOverlay; property: "opacity"; to: 0.0; duration: 100; easing.type: Easing.InCubic }
                                // ^ The entire overlay fades to transparent simultaneously, revealing the main lock screen UI.
                            }
                            
                            NumberAnimation { target: screenRoot; property: "introState"; from: 0.0; to: 1.0; duration: 100; easing.type: Easing.OutCubic }
                            // ^ The introState property animates from 0 to 1 over 100ms, triggering the main UI's fade-in and slide-up transitions.
                        }

                        PropertyAction { target: screenRoot; property: "isPlayingIntro"; value: false }
                        // ^ Immediately sets isPlayingIntro to false (no animation) after the sequence completes. This re-enables all mouse areas and interactions.
                        
                        ScriptAction { script: { inputField.text = ""; inputField.forceActiveFocus(); } }
                        // ^ Executes JavaScript: clears any text that might have been typed during the intro and forces keyboard focus to the password input field, ready for the user to unlock.
                    }
                }
            }
        }
    }
}