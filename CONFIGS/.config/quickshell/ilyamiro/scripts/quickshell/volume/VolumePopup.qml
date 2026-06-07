// import QtQuick
// import QtQuick.Layouts
// import QtQuick.Window
// import QtQuick.Effects
// import QtCore
// import Quickshell
// import Quickshell.Io
// import "../"

// Item {
//     id: window
//     focus: true

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
//     // SHORTCUTS & AUDIO
//     // -------------------------------------------------------------------------
//     Shortcut {
//         sequence: "Tab"
//         onActivated: {
//             if (window.activeTab === "outputs") window.activeTab = "inputs";
//             else if (window.activeTab === "inputs") window.activeTab = "apps";
//             else window.activeTab = "outputs";
//         }
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
//     // STATE & CONFIG
//     // -------------------------------------------------------------------------
//     readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/volume"
    
//     property string activeTab: "outputs" // outputs, inputs, apps
//     onActiveTabChanged: updateHeroData()

//     readonly property color tabColor: {
//         if (activeTab === "outputs") return window.blue;
//         if (activeTab === "inputs") return window.mauve;
//         return window.green;
//     }
    
//     property real globalOrbitAngle: 0
//     NumberAnimation on globalOrbitAngle {
//         from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
//     }

//     // Top Orb Active State Links
//     property string activeId: ""
//     property string activeName: "No Device"
//     property string activeDesc: ""
//     property int activeVol: 0
//     property bool activeMute: false
//     property string activeIcon: "󰓃"

//     // Models
//     ListModel { id: outputsModel }
//     ListModel { id: inputsModel }
//     ListModel { id: appsModel }

//     property var draggingNodes: ({})
//     property bool draggingMaster: false
//     Timer { id: syncDelay; interval: 600; onTriggered: { window.draggingNodes = ({}); window.draggingMaster = false; } }

//     // -------------------------------------------------------------------------
//     // CACHING & DATA LOGIC
//     // -------------------------------------------------------------------------
//     Settings {
//         id: cache
//         property string lastAudioJson: ""
//     }

//     Component.onCompleted: {
//         if (cache.lastAudioJson !== "") processAudioJson(cache.lastAudioJson);
//     }

//     function processAudioJson(textData) {
//         if (!textData) return;
//         try {
//             let data = JSON.parse(textData);
//             syncModel(outputsModel, data.outputs || []);
//             syncModel(inputsModel, data.inputs || []);
//             syncModel(appsModel, data.apps || []);
//             updateHeroData();
//         } catch(e) {}
//     }

//     function updateHeroData() {
//         let targetModel = (window.activeTab === "inputs") ? inputsModel : outputsModel;
        
//         let foundDefault = false;
//         for (let i = 0; i < targetModel.count; i++) {
//             let d = targetModel.get(i);
//             if (d.is_default) {
//                 window.activeId = d.id;
//                 window.activeName = d.description;
//                 window.activeDesc = d.name;
//                 window.activeIcon = d.icon;
//                 if (!window.draggingMaster) {
//                     window.activeVol = d.volume;
//                     window.activeMute = d.mute;
//                 }
//                 foundDefault = true;
//                 break;
//             }
//         }
        
//         // Fallback if no default is found
//         if (!foundDefault && targetModel.count > 0) {
//             let d = targetModel.get(0);
//             window.activeId = d.id;
//             window.activeName = d.description;
//             window.activeDesc = d.name;
//             window.activeIcon = d.icon;
//             if (!window.draggingMaster) {
//                 window.activeVol = d.volume;
//                 window.activeMute = d.mute;
//             }
//         }
//     }

//     function syncModel(listModel, dataArray) {
//         for (let i = listModel.count - 1; i >= 0; i--) {
//             let id = listModel.get(i).id;
//             let found = false;
//             for (let j = 0; j < dataArray.length; j++) {
//                 if (id === dataArray[j].id) { found = true; break; }
//             }
//             if (!found) listModel.remove(i);
//         }
        
//         for (let i = 0; i < dataArray.length; i++) {
//             let d = dataArray[i];
//             let foundIdx = -1;
//             for (let j = i; j < listModel.count; j++) {
//                 if (listModel.get(j).id === d.id) { foundIdx = j; break; }
//             }
            
//             let obj = {
//                 id: d.id, name: d.name, description: d.description,
//                 volume: d.volume, mute: d.mute, is_default: d.is_default, icon: d.icon
//             };

//             if (foundIdx === -1) {
//                 listModel.insert(i, obj);
//             } else {
//                 if (foundIdx !== i) listModel.move(foundIdx, i, 1);
//                 for (let key in obj) { 
//                     if (key === "volume" && window.draggingNodes[obj.id]) continue;
//                     if (listModel.get(i)[key] !== obj[key]) {
//                         listModel.setProperty(i, key, obj[key]); 
//                     }
//                 }
//             }
//         }
//     }

//     Process {
//         id: audioPoller
//         command: ["python3", window.scriptsDir + "/get_audio_state.py"]
//         running: true
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 cache.lastAudioJson = this.text.trim();
//                 processAudioJson(cache.lastAudioJson);
//             }
//         }
//     }

//     Timer {
//         interval: 1000; running: true; repeat: true; triggeredOnStart: true;
//         onTriggered: audioPoller.running = true
//     }

//     // -------------------------------------------------------------------------
//     // ANIMATIONS
//     // -------------------------------------------------------------------------
//     property real introMain: 0
//     property real introHeader: 0
//     property real introContent: 0

//     ParallelAnimation {
//         running: true
//         NumberAnimation { target: window; property: "introMain"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutExpo }
//         SequentialAnimation {
//             PauseAnimation { duration: 100 }
//             NumberAnimation { target: window; property: "introHeader"; from: 0; to: 1.0; duration: 700; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
//         }
//         SequentialAnimation {
//             PauseAnimation { duration: 200 }
//             NumberAnimation { target: window; property: "introContent"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutExpo }
//         }
//     }

//     // -------------------------------------------------------------------------
//     // UI LAYOUT
//     // -------------------------------------------------------------------------
//     Item {
//         anchors.fill: parent
//         scale: 0.95 + (0.05 * introMain)
//         opacity: introMain
//         transform: Translate { y: window.s(20) * (1 - introMain) }

//         Rectangle {
//             anchors.fill: parent
//             radius: window.s(20)
//             color: window.base
//             border.color: window.surface0
//             border.width: 1
//             clip: true

//             // Rotating Background Blobs
//             Rectangle {
//                 width: parent.width * 0.8; height: width; radius: width / 2
//                 x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)
//                 y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)
//                 opacity: 0.06
//                 color: window.tabColor
//                 Behavior on color { ColorAnimation { duration: 800 } }
//             }
//             Rectangle {
//                 width: parent.width * 0.9; height: width; radius: width / 2
//                 x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)
//                 y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)
//                 opacity: 0.04
//                 color: Qt.lighter(window.tabColor, 1.3)
//                 Behavior on color { ColorAnimation { duration: 800 } }
//             }

//             ColumnLayout {
//                 anchors.fill: parent
//                 anchors.margins: window.s(25)
//                 spacing: window.s(20)

//                 // ==========================================
//                 // HERO ORB & MASTER SLIDER (TOP SECTION)
//                 // ==========================================
//                 Item {
//                     Layout.fillWidth: true
//                     Layout.preferredHeight: window.s(150)
//                     opacity: introHeader
//                     transform: Translate { y: window.s(30) * (1.0 - introHeader) }

//                     RowLayout {
//                         anchors.fill: parent
//                         spacing: window.s(25)

//                         // 1. The Orb
//                         Item {
//                             Layout.preferredWidth: window.s(130)
//                             Layout.preferredHeight: window.s(130)
//                             scale: masterOrbMa.pressed ? 0.95 : (masterOrbMa.containsMouse ? 1.05 : 1.0)
//                             Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

//                             // Outermost border pulse ring
//                             Rectangle {
//                                 anchors.centerIn: parent
//                                 width: parent.width + window.s(15)
//                                 height: width
//                                 radius: width / 2
//                                 color: "transparent"
//                                 border.color: window.activeMute ? window.red : window.tabColor
//                                 border.width: window.s(3)
//                                 z: -2

//                                 property real pulseOp: 0.0
//                                 property real pulseSc: 1.0
//                                 opacity: window.activeMute ? 0.0 : pulseOp
//                                 scale: pulseSc

//                                 Timer {
//                                     interval: 45
//                                     running: parent.opacity > 0.01 || !window.activeMute
//                                     repeat: true
//                                     onTriggered: {
//                                         var time = Date.now() / 1000;
//                                         parent.pulseOp = 0.3 + Math.sin(time * 2.5) * 0.15;
//                                         parent.pulseSc = 1.02 + Math.cos(time * 3.0) * 0.02;
//                                     }
//                                 }
//                             }

//                             // Solid pulsing background ring
//                             Rectangle {
//                                 anchors.centerIn: parent
//                                 width: parent.width + window.s(40)
//                                 height: width
//                                 radius: width / 2
//                                 color: window.activeMute ? window.red : window.tabColor
//                                 opacity: window.activeMute ? 0.3 : 0.15
//                                 z: -1
//                                 Behavior on color { ColorAnimation { duration: 300 } }

//                                 SequentialAnimation on scale {
//                                     loops: Animation.Infinite; running: true
//                                     NumberAnimation { to: masterOrbMa.containsMouse ? 1.15 : 1.1; duration: masterOrbMa.containsMouse ? 800 : 2000; easing.type: Easing.InOutSine }
//                                     NumberAnimation { to: 1.0; duration: masterOrbMa.containsMouse ? 800 : 2000; easing.type: Easing.InOutSine }
//                                 }
//                             }

//                             // Core Shadow
//                             MultiEffect {
//                                 source: centralCore
//                                 anchors.fill: centralCore
//                                 shadowEnabled: true
//                                 shadowColor: "#000000"
//                                 shadowOpacity: 0.5
//                                 shadowBlur: 1.2
//                                 shadowVerticalOffset: window.s(6)
//                                 z: -1
//                             }

//                             // Core Rectangle
//                             Rectangle {
//                                 id: centralCore
//                                 anchors.fill: parent
//                                 radius: width / 2
//                                 color: window.base
//                                 border.color: window.activeMute ? window.red : Qt.lighter(window.tabColor, 1.1)
//                                 border.width: 2
//                                 clip: true
//                                 Behavior on border.color { ColorAnimation { duration: 300 } }

//                                 // Volume Wave Fill
//                                 Canvas {
//                                     id: orbWave
//                                     anchors.fill: parent
                                    
//                                     property real wavePhase: 0.0
//                                     NumberAnimation on wavePhase {
//                                         running: window.activeVol > 0 && window.activeVol < 100
//                                         loops: Animation.Infinite
//                                         from: 0; to: Math.PI * 2; duration: 1200
//                                     }
//                                     onWavePhaseChanged: requestPaint()

//                                     Connections {
//                                         target: window
//                                         function onActiveVolChanged() { orbWave.requestPaint() }
//                                         function onActiveMuteChanged() { orbWave.requestPaint() }
//                                         function onTabColorChanged() { orbWave.requestPaint() }
//                                     }

//                                     onPaint: {
//                                         var ctx = getContext("2d");
//                                         ctx.clearRect(0, 0, width, height);
//                                         if (window.activeVol <= 0) return;

//                                         var fillRatio = window.activeVol / 100.0;
//                                         var r = width / 2;
//                                         var fillY = height * (1.0 - fillRatio);

//                                         ctx.save();
                                        
//                                         // 1. Establish the circular clipping mask
//                                         ctx.beginPath();
//                                         ctx.arc(r, r, r, 0, 2 * Math.PI);
//                                         ctx.clip();
                                        
//                                         // 2. Draw the actual wave filling
//                                         ctx.beginPath();
//                                         ctx.moveTo(0, fillY);
                                        
//                                         if (fillRatio < 0.99) {
//                                             var waveAmp = window.s(8) * Math.sin(fillRatio * Math.PI); 
//                                             var cp1y = fillY + Math.sin(wavePhase) * waveAmp;
//                                             var cp2y = fillY + Math.cos(wavePhase + Math.PI) * waveAmp;
//                                             ctx.bezierCurveTo(width * 0.33, cp2y, width * 0.66, cp1y, width, fillY);
//                                             ctx.lineTo(width, height);
//                                             ctx.lineTo(0, height);
//                                         } else {
//                                             ctx.lineTo(width, 0);
//                                             ctx.lineTo(width, height);
//                                             ctx.lineTo(0, height);
//                                         }
//                                         ctx.closePath();
                                        
//                                         // Vibrant gradient matching the network orb
//                                         var grad = ctx.createLinearGradient(0, 0, 0, height);
//                                         if (window.activeMute) {
//                                             grad.addColorStop(0, Qt.lighter(window.red, 1.15).toString());
//                                             grad.addColorStop(1, window.red.toString());
//                                         } else {
//                                             grad.addColorStop(0, Qt.lighter(window.tabColor, 1.15).toString());
//                                             grad.addColorStop(1, window.tabColor.toString());
//                                         }
//                                         ctx.fillStyle = grad;
//                                         ctx.globalAlpha = 1.0;
//                                         ctx.fill();
//                                         ctx.restore();
//                                     }
//                                 }

//                                 // Dual-Layer Text for contrast clipping
//                                 // 1. Base Text (Visible when empty)
//                                 Text {
//                                     anchors.centerIn: parent
//                                     font.family: "JetBrains Mono"
//                                     font.weight: Font.Black
//                                     font.pixelSize: window.s(32)
//                                     color: window.activeMute ? window.red : window.text
//                                     text: window.activeMute ? "MUTE" : window.activeVol + "%"
//                                     Behavior on color { ColorAnimation { duration: 200 } }
//                                 }

//                                 // 2. Clipped Text (Dark text that reveals over the wave fill dynamically)
//                                 Item {
//                                     id: waveClipItem
//                                     anchors.bottom: parent.bottom
//                                     anchors.left: parent.left
//                                     anchors.right: parent.right

//                                     // Calculate the exact wave offset at the center of the orb using the Bezier formula
//                                     property real fillRatio: window.activeVol / 100.0
//                                     property real waveAmp: fillRatio < 0.99 ? window.s(8) * Math.sin(fillRatio * Math.PI) : 0
//                                     property real waveCenterOffset: 0.375 * waveAmp * (Math.sin(orbWave.wavePhase) - Math.cos(orbWave.wavePhase))
//                                     property real baseClipHeight: parent.height * fillRatio

//                                     height: Math.min(parent.height, Math.max(0, baseClipHeight - waveCenterOffset))
//                                     clip: true
//                                     visible: window.activeVol > 0

//                                     Text {
//                                         x: waveClipItem.width / 2 - width / 2
//                                         y: (centralCore.height / 2) - (height / 2) - (centralCore.height - waveClipItem.height)
//                                         font.family: "JetBrains Mono"
//                                         font.weight: Font.Black
//                                         font.pixelSize: window.s(32)
//                                         color: window.crust
//                                         text: window.activeMute ? "MUTE" : window.activeVol + "%"
//                                     }
//                                 }
//                             }

//                             MouseArea {
//                                 id: masterOrbMa
//                                 anchors.fill: parent
//                                 hoverEnabled: true
//                                 cursorShape: Qt.PointingHandCursor
//                                 onClicked: {
//                                     let type = window.activeTab === "inputs" ? "source" : "sink";
//                                     Quickshell.execDetached(["bash", window.scriptsDir + "/audio_control.sh", "toggle-mute", type, window.activeId]);
//                                     audioPoller.running = true;
//                                 }
//                             }
//                         }

//                         // 2. Details & Slider
//                         ColumnLayout {
//                             Layout.fillWidth: true
//                             Layout.fillHeight: true
//                             spacing: window.s(10)

//                             ColumnLayout {
//                                 spacing: window.s(2)
//                                 Text {
//                                     Layout.fillWidth: true; elide: Text.ElideRight
//                                     font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(20)
//                                     color: window.text
//                                     text: window.activeName
//                                 }
//                                 Text {
//                                     Layout.fillWidth: true; elide: Text.ElideRight
//                                     font.family: "JetBrains Mono"; font.pixelSize: window.s(13)
//                                     color: window.subtext0
//                                     text: window.activeTab === "apps" ? "Master Output Volume" : window.activeDesc
//                                 }
//                             }

//                             Item { Layout.fillHeight: true } // spacer

//                             RowLayout {
//                                 Layout.fillWidth: true
//                                 spacing: window.s(15)

//                                 // Slider
//                                 Item {
//                                     Layout.fillWidth: true
//                                     height: window.s(24)

//                                     Timer {
//                                         id: masterCmdThrottle
//                                         interval: 50
//                                         property int targetPct: -1
//                                         onTriggered: {
//                                             if (targetPct >= 0) {
//                                                 let type = window.activeTab === "inputs" ? "source" : "sink";
//                                                 if (targetPct > 0 && window.activeMute) {
//                                                     Quickshell.execDetached(["bash", window.scriptsDir + "/audio_control.sh", "toggle-mute", type, window.activeId]);
//                                                 }
//                                                 Quickshell.execDetached(["bash", window.scriptsDir + "/audio_control.sh", "set-volume", type, window.activeId, targetPct]);
//                                                 targetPct = -1;
//                                             }
//                                         }
//                                     }

//                                     Rectangle {
//                                         anchors.fill: parent; radius: window.s(12)
//                                         color: "#0dffffff"; border.color: "#1affffff"; border.width: 1
//                                         clip: true

//                                         Rectangle {
//                                             height: parent.height
//                                             width: parent.width * (Math.min(100, window.activeVol) / 100)
//                                             radius: window.s(12)
//                                             opacity: window.activeMute ? 0.3 : (masterSliderMa.containsMouse ? 1.0 : 0.85)
//                                             Behavior on opacity { NumberAnimation { duration: 200 } }
//                                             Behavior on width { enabled: !window.draggingMaster; NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

//                                             gradient: Gradient {
//                                                 orientation: Gradient.Horizontal
//                                                 GradientStop { position: 0.0; color: window.activeMute ? window.surface2 : window.tabColor; Behavior on color { ColorAnimation{duration: 300} } }
//                                                 GradientStop { position: 1.0; color: window.activeMute ? Qt.lighter(window.surface2, 1.15) : Qt.lighter(window.tabColor, 1.25); Behavior on color { ColorAnimation{duration: 300} } }
//                                             }
//                                         }
//                                     }
                                    
//                                     MouseArea {
//                                         id: masterSliderMa
//                                         anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                                         onPressed: (mouse) => { syncDelay.stop(); window.draggingMaster = true; updateVol(mouse.x); }
//                                         onPositionChanged: (mouse) => { if (pressed) updateVol(mouse.x); }
//                                         onReleased: { syncDelay.restart(); audioPoller.running = true; }
                                        
//                                         function updateVol(mx) {
//                                             let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100)));
//                                             window.activeVol = pct; // Instant visual feedback on orb

//                                             masterCmdThrottle.targetPct = pct;
//                                             if (!masterCmdThrottle.running) masterCmdThrottle.start();
//                                         }
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }

//                 // ==========================================
//                 // TABS
//                 // ==========================================
//                 Rectangle {
//                     Layout.fillWidth: true
//                     Layout.preferredHeight: window.s(54)
//                     radius: window.s(14)
//                     color: "#0dffffff" 
//                     border.color: "#1affffff"
//                     border.width: 1
//                     opacity: introHeader
//                     transform: Translate { y: window.s(20) * (1.0 - introHeader) }

//                     Rectangle {
//                         width: (parent.width - window.s(2)) / 3 
//                         height: parent.height - window.s(2)
//                         y: window.s(1)
//                         radius: window.s(10)
//                         x: {
//                             if (window.activeTab === "outputs") return window.s(1);
//                             if (window.activeTab === "inputs") return width + window.s(1);
//                             return (width * 2) + window.s(1);
//                         }
//                         Behavior on x { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                        
//                         gradient: Gradient {
//                             orientation: Gradient.Horizontal
//                             GradientStop { position: 0.0; color: window.tabColor; Behavior on color { ColorAnimation { duration: 400 } } }
//                             GradientStop { position: 1.0; color: Qt.lighter(window.tabColor, 1.15); Behavior on color { ColorAnimation { duration: 400 } } }
//                         }
//                     }

//                     RowLayout {
//                         anchors.fill: parent
//                         spacing: 0
                        
//                         Repeater {
//                             model: ListModel {
//                                 ListElement { tabId: "outputs"; icon: "󰓃"; label: "Outputs" } 
//                                 ListElement { tabId: "inputs"; icon: "󰍬"; label: "Inputs" }   
//                                 ListElement { tabId: "apps"; icon: "󰎆"; label: "Streams" } 
//                             }
                            
//                             delegate: Item {
//                                 Layout.fillWidth: true
//                                 Layout.fillHeight: true
                                
//                                 RowLayout {
//                                     anchors.centerIn: parent
//                                     spacing: window.s(8)
//                                     Text {
//                                         font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18)
//                                         color: window.activeTab === tabId ? window.crust : (tabMa.containsMouse ? window.text : window.subtext0)
//                                         text: icon
//                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                     }
//                                     Text {
//                                         font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(13)
//                                         color: window.activeTab === tabId ? window.crust : (tabMa.containsMouse ? window.text : window.subtext0)
//                                         text: label
//                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                     }
//                                 }
                                
//                                 MouseArea {
//                                     id: tabMa
//                                     anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                                     onClicked: {
//                                         window.activeTab = tabId;
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }

//                 // ==========================================
//                 // LIST VIEW CONTENT
//                 // ==========================================
//                 Item {
//                     Layout.fillWidth: true
//                     Layout.fillHeight: true
//                     opacity: introContent
//                     transform: Translate { y: window.s(20) * (1.0 - introContent) }

//                     ListView {
//                         id: contentList
//                         anchors.fill: parent
//                         spacing: window.s(12)
//                         clip: true
//                         boundsBehavior: Flickable.StopAtBounds

//                         // Elegant sliding transitions when models rearrange
//                         add: Transition {
//                             NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutQuint }
//                             NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: 400; easing.type: Easing.OutBack }
//                         }
//                         displaced: Transition {
//                             SpringAnimation { property: "y"; spring: 3; damping: 0.2; mass: 0.2 }
//                         }

//                         model: {
//                             if (window.activeTab === "outputs") return outputsModel;
//                             if (window.activeTab === "inputs") return inputsModel;
//                             return appsModel;
//                         }

//                         Item {
//                             width: contentList.width; height: contentList.height
//                             visible: contentList.count === 0
//                             ColumnLayout {
//                                 anchors.centerIn: parent
//                                 spacing: window.s(10)
//                                 Text { Layout.alignment: Qt.AlignHCenter; font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(32); color: window.surface2; text: "󰖁" }
//                                 Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.pixelSize: window.s(14); color: window.overlay0; text: "No active streams" }
//                             }
//                         }

//                         delegate: Rectangle {
//                             id: delegateRoot
//                             width: contentList.width
                            
//                             // Staggered Intro Animation Timer
//                             property bool isLoaded: false
//                             Timer {
//                                 running: true
//                                 interval: 40 + (index * 40)
//                                 onTriggered: delegateRoot.isLoaded = true
//                             }

//                             // Intro transforms
//                             opacity: isLoaded ? 1.0 : 0.0
//                             transform: Translate { y: isLoaded ? 0 : window.s(15) }
//                             Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
//                             Behavior on transform { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

//                             // Dynamic Height: The active hero element collapses its bottom slider row
//                             property bool isActiveNode: model.is_default && window.activeTab !== "apps"
//                             height: isActiveNode ? window.s(60) : window.s(100)
//                             Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

//                             radius: window.s(14)
                            
//                             property bool isHovered: cardMa.containsMouse && !isActiveNode

//                             color: isActiveNode ? window.tabColor : (isHovered ? "#0affffff" : "#05ffffff")
//                             border.color: isActiveNode ? window.tabColor : "#1affffff"
//                             border.width: isActiveNode ? 2 : 1
//                             Behavior on border.color { ColorAnimation { duration: 300 } }
//                             Behavior on color { ColorAnimation { duration: 300 } }

//                             // Full card selection listener
//                             MouseArea {
//                                 id: cardMa
//                                 anchors.fill: parent
//                                 hoverEnabled: window.activeTab !== "apps"
//                                 cursorShape: window.activeTab !== "apps" ? Qt.PointingHandCursor : Qt.ArrowCursor
//                                 onClicked: {
//                                     if (window.activeTab !== "apps" && !model.is_default) {
//                                         let type = window.activeTab === "outputs" ? "sink" : "source";
//                                         Quickshell.execDetached(["bash", window.scriptsDir + "/audio_control.sh", "set-default", type, model.name]);
//                                         audioPoller.running = true;
//                                     }
//                                 }
//                             }

//                             ColumnLayout {
//                                 anchors.fill: parent
//                                 anchors.leftMargin: window.s(16)
//                                 anchors.rightMargin: window.s(16)
//                                 anchors.topMargin: window.s(12)
//                                 anchors.bottomMargin: isActiveNode ? window.s(12) : window.s(16) // Prevent slider crowding bottom bounds
//                                 spacing: window.s(12)

//                                 // Top row: Text info and Icon
//                                 RowLayout {
//                                     Layout.fillWidth: true
//                                     spacing: window.s(12)

//                                     Text {
//                                         font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(22)
//                                         color: isActiveNode ? window.crust : window.text
//                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                         text: {
//                                             if (window.activeTab === "inputs") return "󰍬";
//                                             if (window.activeTab === "apps") return "󰎆";
//                                             if (model.description.toLowerCase().indexOf("headset") !== -1 || model.description.toLowerCase().indexOf("headphones") !== -1) return "󰋎";
//                                             return "󰓃";
//                                         }
//                                     }

//                                     ColumnLayout {
//                                         Layout.fillWidth: true
//                                         spacing: window.s(2)
//                                         Text {
//                                             Layout.fillWidth: true; elide: Text.ElideRight
//                                             font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(14)
//                                             color: isActiveNode ? window.crust : window.text
//                                             text: model.description
//                                         }
//                                         Text {
//                                             Layout.fillWidth: true; elide: Text.ElideRight
//                                             font.family: "JetBrains Mono"; font.pixelSize: window.s(11)
//                                             color: isActiveNode ? Qt.darker(window.crust, 1.5) : window.subtext0
//                                             text: isActiveNode ? "Active Default" : model.name
//                                         }
//                                     }
//                                 }

//                                 // Bottom row: Custom Slider & Mute (Hides if it's the active node)
//                                 RowLayout {
//                                     Layout.fillWidth: true
//                                     spacing: window.s(15)
//                                     visible: !isActiveNode
//                                     opacity: isActiveNode ? 0.0 : 1.0
//                                     Behavior on opacity { NumberAnimation { duration: 200 } }

//                                     Rectangle {
//                                         Layout.preferredWidth: window.s(32); Layout.preferredHeight: window.s(32); radius: window.s(16)
//                                         color: muteMa.containsMouse ? "#1affffff" : "transparent"
//                                         border.color: muteMa.containsMouse ? (model.mute ? window.overlay0 : window.tabColor) : "transparent"
//                                         Behavior on color { ColorAnimation { duration: 150 } }

//                                         Text {
//                                             anchors.centerIn: parent
//                                             font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18)
//                                             color: model.mute ? window.overlay0 : window.subtext0
//                                             text: model.mute || model.volume === 0 ? "󰖁" : (model.volume > 50 ? "󰕾" : "󰖀")
//                                             Behavior on color { ColorAnimation { duration: 200 } }
//                                         }
//                                         MouseArea {
//                                             id: muteMa
//                                             anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                                             onClicked: {
//                                                 let type = "sink";
//                                                 if (window.activeTab === "inputs") type = "source";
//                                                 if (window.activeTab === "apps") type = "sink-input";
//                                                 Quickshell.execDetached(["bash", window.scriptsDir + "/audio_control.sh", "toggle-mute", type, model.id]);
//                                                 audioPoller.running = true;
//                                             }
//                                         }
//                                     }

//                                     // Local Slider
//                                     Item {
//                                         Layout.fillWidth: true
//                                         height: window.s(14) // Slightly thinner than master slider for hierarchy
                                        
//                                         Timer {
//                                             id: volCmdThrottle
//                                             interval: 50
//                                             property int targetPct: -1
//                                             onTriggered: {
//                                                 if (targetPct >= 0) {
//                                                     let type = "sink";
//                                                     if (window.activeTab === "inputs") type = "source";
//                                                     if (window.activeTab === "apps") type = "sink-input";
                                                    
//                                                     if (targetPct > 0 && model.mute) {
//                                                         Quickshell.execDetached(["bash", window.scriptsDir + "/audio_control.sh", "toggle-mute", type, model.id]);
//                                                     }
//                                                     Quickshell.execDetached(["bash", window.scriptsDir + "/audio_control.sh", "set-volume", type, model.id, targetPct]);
//                                                     targetPct = -1;
//                                                 }
//                                             }
//                                         }

//                                         Rectangle {
//                                             anchors.fill: parent; radius: window.s(7)
//                                             color: "#0dffffff"; border.color: "#1affffff"; border.width: 1
//                                             clip: true

//                                             Rectangle {
//                                                 height: parent.height
//                                                 width: parent.width * (Math.min(100, model.volume) / 100)
//                                                 radius: window.s(7)
                                                
//                                                 // Heavily dimmed if muted, slightly dimmed if background node
//                                                 opacity: model.mute ? 0.3 : (volSliderMa.containsMouse ? 0.7 : 0.4)
//                                                 Behavior on opacity { NumberAnimation { duration: 200 } }
//                                                 Behavior on width { enabled: !window.draggingNodes[model.id]; NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

//                                                 gradient: Gradient {
//                                                     orientation: Gradient.Horizontal
//                                                     GradientStop { position: 0.0; color: model.mute ? window.surface2 : window.tabColor; Behavior on color { ColorAnimation { duration: 300 } } }
//                                                     GradientStop { position: 1.0; color: model.mute ? Qt.lighter(window.surface2, 1.15) : Qt.lighter(window.tabColor, 1.25); Behavior on color { ColorAnimation { duration: 300 } } }
//                                                 }
//                                             }
//                                         }
                                        
//                                         MouseArea {
//                                             id: volSliderMa
//                                             anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                                             onPressed: (mouse) => { syncDelay.stop(); window.draggingNodes[model.id] = true; updateVol(mouse.x); }
//                                             onPositionChanged: (mouse) => { if (pressed) updateVol(mouse.x); }
//                                             onReleased: { syncDelay.restart(); audioPoller.running = true; }
                                            
//                                             function updateVol(mx) {
//                                                 let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100)));
                                                
//                                                 let targetList = window.activeTab === "outputs" ? outputsModel : (window.activeTab === "inputs" ? inputsModel : appsModel);
//                                                 for (let i = 0; i < targetList.count; i++) {
//                                                     if (targetList.get(i).id === model.id) {
//                                                         targetList.setProperty(i, "volume", pct);
//                                                         break;
//                                                     }
//                                                 }

//                                                 volCmdThrottle.targetPct = pct;
//                                                 if (!volCmdThrottle.running) volCmdThrottle.start();
//                                             }
//                                         }
//                                     }

//                                     Text {
//                                         Layout.preferredWidth: window.s(35)
//                                         font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12)
//                                         color: window.subtext0
//                                         text: model.volume + "%"
//                                         horizontalAlignment: Text.AlignRight
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








import QtQuick                                                                  // Imports QtQuick module for basic QML UI types and animation framework
import QtQuick.Layouts                                                          // Imports QtQuick.Layouts for RowLayout, ColumnLayout, and other layout types
import QtQuick.Window                                                           // Imports QtQuick.Window for accessing Screen properties like width
import QtQuick.Effects                                                          // Imports QtQuick.Effects for graphical effects like MultiEffect shadows
import QtCore                                                                   // Imports QtCore for core Qt types and functionality (Settings, etc.)
import Quickshell                                                               // Imports Quickshell module for Hyprland shell/window management integration
import Quickshell.Io                                                            // Imports Quickshell.Io for Process and StdioCollector to run external commands
import "../"                                                                    // Imports parent directory to access shared components like Scaler and MatugenColors

Item {                                                                          // Root container item for the entire volume control popup
    id: window                                                                  // Unique identifier "window" for referencing this root item throughout the file
    focus: true                                                                 // Enables keyboard focus so the popup can receive key events (like Tab)

    // --- Responsive Scaling Logic ---                                          // Comment divider for the UI scaling system
    Scaler {                                                                    // Instantiates Scaler component for consistent responsive sizing
        id: scaler                                                              // Unique identifier "scaler" for this instance
        // Uses the physical screen width so the popup scales synchronously with the TopBar // Comment explaining that scaling matches the top bar
        currentWidth: Screen.width                                              // Binds the scaler to the actual physical screen width for calculation
    }
    
    // Helper function scoped to the root Item for easy access in deeply nested elements and Canvases // Comment describing the s() helper function
    function s(val) {                                                           // Helper function that scales a value according to screen dimensions
        return scaler.s(val);                                                   // Delegates to the scaler instance's s() method and returns scaled result
    }

    // ------------------------------------------------------------------------- // Visual divider for shortcuts and audio section
    // SHORTCUTS & AUDIO                                                          // Section header: keyboard shortcuts and audio control setup
    // ------------------------------------------------------------------------- // Visual divider closing the section header
    Shortcut {                                                                  // Keyboard shortcut handler definition
        sequence: "Tab"                                                         // Binds to the Tab key press
        onActivated: {                                                          // Code executed when Tab key is pressed
            if (window.activeTab === "outputs") window.activeTab = "inputs";    // If on outputs tab, switch to inputs tab
            else if (window.activeTab === "inputs") window.activeTab = "apps";  // If on inputs tab, switch to apps/streams tab
            else window.activeTab = "outputs";                                  // Otherwise (on apps), switch back to outputs tab (cyclic rotation)
        }
    }
    // ------------------------------------------------------------------------- // Visual divider for color palette section
    // COLORS (Dynamic Matugen Palette)                                           // Section header: color properties from the matugen theme
    // ------------------------------------------------------------------------- // Visual divider closing the section header
    MatugenColors { id: _theme }                                                // Instantiates MatugenColors component to get the dynamic theme color palette
    readonly property color base: _theme.base                                   // Base background color (darkest shade) from matugen theme
    readonly property color mantle: _theme.mantle                               // Mantle color (slightly lighter than base) from theme
    readonly property color crust: _theme.crust                                 // Crust color (lightest background shade) from theme
    readonly property color text: _theme.text                                   // Primary text/foreground color from matugen theme
    readonly property color subtext0: _theme.subtext0                           // Secondary/muted text color from theme
    readonly property color overlay0: _theme.overlay0                           // Overlay0 color (very subtle overlay) from theme
    readonly property color overlay1: _theme.overlay1                           // Overlay1 color (slightly stronger overlay) from theme
    readonly property color surface0: _theme.surface0                           // Surface0 color (darkest UI surface) from theme
    readonly property color surface1: _theme.surface1                           // Surface1 color (medium UI surface) from theme
    readonly property color surface2: _theme.surface2                           // Surface2 color (lightest UI surface) from theme
    
    readonly property color mauve: _theme.mauve                                 // Mauve accent color from matugen palette
    readonly property color pink: _theme.pink                                   // Pink accent color from matugen palette
    readonly property color red: _theme.red                                     // Red accent color from matugen palette (used for mute state)
    readonly property color maroon: _theme.maroon                               // Maroon accent color from matugen palette
    readonly property color peach: _theme.peach                                 // Peach accent color from matugen palette
    readonly property color yellow: _theme.yellow                               // Yellow accent color from matugen palette
    readonly property color green: _theme.green                                 // Green accent color from matugen palette (used for apps/streams)
    readonly property color teal: _theme.teal                                   // Teal accent color from matugen palette
    readonly property color sapphire: _theme.sapphire                           // Sapphire accent color from matugen palette
    readonly property color blue: _theme.blue                                   // Blue accent color from matugen palette (used for outputs tab)

    // ------------------------------------------------------------------------- // Visual divider for state and config section
    // STATE & CONFIG                                                              // Section header: application state and configuration properties
    // ------------------------------------------------------------------------- // Visual divider closing the section header
    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/volume" // Full path to volume control scripts directory, built from HOME env var
    
    property string activeTab: "outputs"                                        // Currently selected tab: "outputs", "inputs", or "apps" (default outputs)
    onActiveTabChanged: updateHeroData()                                        // When tab changes, immediately refresh the hero/master display data

    readonly property color tabColor: {                                         // Computed color that changes based on active tab
        if (activeTab === "outputs") return window.blue;                        // Blue for outputs/speakers tab
        if (activeTab === "inputs") return window.mauve;                        // Mauve for inputs/microphones tab
        return window.green;                                                    // Green for apps/streams tab (default/fallback)
    }
    
    property real globalOrbitAngle: 0                                           // Property for background blob orbital rotation angle (0 to 2π)
    NumberAnimation on globalOrbitAngle {                                       // Continuous animation for the orbital angle
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true // Full 360° rotation over 90 seconds, looping infinitely
    }

    // Top Orb Active State Links                                                // Comment describing hero/master orb state properties
    property string activeId: ""                                                // ID of the currently active/default device (string, e.g., "0")
    property string activeName: "No Device"                                     // Display name of the active device, default "No Device"
    property string activeDesc: ""                                              // Description/subtitle for the active device
    property int activeVol: 0                                                   // Volume level of the active device (0-100)
    property bool activeMute: false                                             // Mute state of the active device
    property string activeIcon: "󰓃"                                             // Nerd Font icon for the active device, default speaker icon

    // Models                                                                     // Comment indicating data models section
    ListModel { id: outputsModel }                                              // ListModel for storing audio output devices (speakers, headphones, etc.)
    ListModel { id: inputsModel }                                               // ListModel for storing audio input devices (microphones)
    ListModel { id: appsModel }                                                 // ListModel for storing audio-producing applications (streams)

    property var draggingNodes: ({})                                            // Object/dictionary tracking which device nodes are currently being dragged by user
    property bool draggingMaster: false                                         // Boolean tracking whether the master/hero slider is being dragged
    Timer { id: syncDelay; interval: 600; onTriggered: { window.draggingNodes = ({}); window.draggingMaster = false; } } // Timer: 600ms after drag ends, clears all dragging flags to resume live updates

    // ------------------------------------------------------------------------- // Visual divider for caching and data logic section
    // CACHING & DATA LOGIC                                                       // Section header: caching system and data processing functions
    // ------------------------------------------------------------------------- // Visual divider closing the section header
    Settings {                                                                  // Persistent settings storage component (saves to disk automatically)
        id: cache                                                               // Unique identifier "cache"
        property string lastAudioJson: ""                                       // Stores the last known audio state JSON for instant display on next open
    }

    Component.onCompleted: {                                                    // Code that runs when this component finishes loading
        if (cache.lastAudioJson !== "") processAudioJson(cache.lastAudioJson);  // If cached audio data exists, immediately process it for instant UI population
    }

    function processAudioJson(textData) {                                       // Function that parses JSON audio data and updates all device models
        if (!textData) return;                                                  // If no data provided, exit early
        try {                                                                   // Try block for JSON parsing
            let data = JSON.parse(textData);                                    // Parse the JSON string into a JavaScript object
            syncModel(outputsModel, data.outputs || []);                        // Synchronize outputs model with parsed output devices (or empty array)
            syncModel(inputsModel, data.inputs || []);                          // Synchronize inputs model with parsed input devices (or empty array)
            syncModel(appsModel, data.apps || []);                              // Synchronize apps model with parsed application streams (or empty array)
            updateHeroData();                                                   // Update the hero/master display with current default device info
        } catch(e) {}                                                           // Silently ignore any parsing errors (empty catch block)
    }

    function updateHeroData() {                                                 // Function that updates the master/hero orb display with current default device
        let targetModel = (window.activeTab === "inputs") ? inputsModel : outputsModel; // Select model based on active tab (inputs uses inputsModel, others use outputsModel)
        
        let foundDefault = false;                                               // Flag to track if a default device was found
        for (let i = 0; i < targetModel.count; i++) {                           // Iterate through all devices in the selected model
            let d = targetModel.get(i);                                         // Get device data at current index
            if (d.is_default) {                                                 // If this device is marked as the system default
                window.activeId = d.id;                                         // Set the active device ID
                window.activeName = d.description;                              // Set the display name (human-readable)
                window.activeDesc = d.name;                                     // Set the description/technical name
                window.activeIcon = d.icon;                                     // Set the icon name
                if (!window.draggingMaster) {                                   // Only update volume/mute from data if user is NOT currently dragging the slider
                    window.activeVol = d.volume;                                // Update master volume display
                    window.activeMute = d.mute;                                 // Update master mute state
                }
                foundDefault = true;                                            // Mark that a default was found
                break;                                                          // Exit loop (first default found wins)
            }
        }
        
        // Fallback if no default is found                                        // Comment explaining fallback logic
        if (!foundDefault && targetModel.count > 0) {                           // If no default device found but there are devices in the list
            let d = targetModel.get(0);                                         // Use the first device as fallback
            window.activeId = d.id;                                             // Set ID from first device
            window.activeName = d.description;                                  // Set display name
            window.activeDesc = d.name;                                         // Set description
            window.activeIcon = d.icon;                                         // Set icon
            if (!window.draggingMaster) {                                       // Only update if not dragging
                window.activeVol = d.volume;                                    // Set volume
                window.activeMute = d.mute;                                     // Set mute state
            }
        }
    }

    function syncModel(listModel, dataArray) {                                  // Function that efficiently synchronizes a ListModel with incoming JSON data
        for (let i = listModel.count - 1; i >= 0; i--) {                        // Iterate backwards through existing model items
            let id = listModel.get(i).id;                                       // Get the ID of the current model item
            let found = false;                                                  // Flag to check if this ID exists in new data
            for (let j = 0; j < dataArray.length; j++) {                        // Loop through new data array
                if (id === dataArray[j].id) { found = true; break; }            // If ID matches, mark as found and exit inner loop
            }
            if (!found) listModel.remove(i);                                    // If ID not in new data, remove this item from the model (device was disconnected)
        }
        
        for (let i = 0; i < dataArray.length; i++) {                            // Iterate through new data array to add/update items
            let d = dataArray[i];                                               // Get device data at current index
            let foundIdx = -1;                                                  // Initialize found index as -1 (not found)
            for (let j = i; j < listModel.count; j++) {                         // Search for matching ID in model starting from current position
                if (listModel.get(j).id === d.id) { foundIdx = j; break; }      // If ID matches, store the index and exit loop
            }
            
            let obj = {                                                         // Create a normalized object with all device properties
                id: d.id, name: d.name, description: d.description,             // Core identity fields
                volume: d.volume, mute: d.mute, is_default: d.is_default, icon: d.icon // State and display fields
            };

            if (foundIdx === -1) {                                              // If device not found in existing model
                listModel.insert(i, obj);                                       // Insert new device at the correct position in the model
            } else {                                                            // If device already exists in model
                if (foundIdx !== i) listModel.move(foundIdx, i, 1);             // Move it to the correct position if it's in the wrong spot
                for (let key in obj) {                                          // Iterate through all properties of the new data object
                    if (key === "volume" && window.draggingNodes[obj.id]) continue; // Skip volume update if user is currently dragging this device's slider
                    if (listModel.get(i)[key] !== obj[key]) {                   // If the model value differs from new data
                        listModel.setProperty(i, key, obj[key]);                // Update the property in the model
                    }
                }
            }
        }
    }

    Process {                                                                   // Process component that polls for current audio state
        id: audioPoller                                                         // Unique identifier "audioPoller"
        command: ["python3", window.scriptsDir + "/get_audio_state.py"]          // Runs the Python script that fetches all audio device states
        running: true                                                           // Starts the process immediately on load
        stdout: StdioCollector {                                                // Collects standard output from the Python script
            onStreamFinished: {                                                 // Callback when the process completes and output is available
                cache.lastAudioJson = this.text.trim();                         // Save the raw JSON output to persistent cache for next launch
                processAudioJson(cache.lastAudioJson);                          // Process the new audio data to update UI models
            }
        }
    }

    Timer {                                                                     // Timer that triggers periodic audio state polling
        interval: 1000; running: true; repeat: true; triggeredOnStart: true;    // Runs every 1000ms (1 second), starts immediately, repeats, also triggers on start
        onTriggered: audioPoller.running = true                                 // Restarts the audioPoller process each time the timer fires
    }

    // ------------------------------------------------------------------------- // Visual divider for animations section
    // ANIMATIONS                                                                 // Section header: intro entrance animation properties
    // ------------------------------------------------------------------------- // Visual divider closing the section header
    property real introMain: 0                                                  // Progress of main container intro animation (0.0 to 1.0)
    property real introHeader: 0                                                // Progress of header/orb intro animation (0.0 to 1.0)
    property real introContent: 0                                               // Progress of content list intro animation (0.0 to 1.0)

    ParallelAnimation {                                                         // Parallel animation that runs multiple intro animations simultaneously
        running: true                                                           // Starts automatically when component loads
        NumberAnimation { target: window; property: "introMain"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutExpo } // Main container fades/scales in over 800ms with exponential ease-out
        SequentialAnimation {                                                   // Sequential animation for header (starts after slight delay)
            PauseAnimation { duration: 100 }                                    // 100ms delay before header animation begins
            NumberAnimation { target: window; property: "introHeader"; from: 0; to: 1.0; duration: 700; easing.type: Easing.OutBack; easing.overshoot: 1.2 } // Header bounces in over 700ms with back easing (overshoots to 120%)
        }
        SequentialAnimation {                                                   // Sequential animation for content list (starts after longer delay)
            PauseAnimation { duration: 200 }                                    // 200ms delay before content begins
            NumberAnimation { target: window; property: "introContent"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutExpo } // Content fades in over 800ms
        }
    }

    // ------------------------------------------------------------------------- // Visual divider for main UI layout section
    // UI LAYOUT                                                                  // Section header: the visual layout of the volume popup
    // ------------------------------------------------------------------------- // Visual divider closing the section header
    Item {                                                                      // Container item for the animated intro entrance effects
        anchors.fill: parent                                                    // Fills the entire parent/window area
        scale: 0.95 + (0.05 * introMain)                                        // Scales from 95% to 100% as introMain progresses
        opacity: introMain                                                      // Fades from 0 to full opacity as introMain progresses
        transform: Translate { y: window.s(20) * (1 - introMain) }              // Slides up from 20 units below as intro progresses

        Rectangle {                                                             // Main background rectangle for the popup
            anchors.fill: parent                                                // Fills the animated container
            radius: window.s(20)                                                // Rounded corners with 20 scaled units radius
            color: window.base                                                  // Base theme background color (darkest)
            border.color: window.surface0                                       // Subtle border using surface0 color
            border.width: 1                                                     // 1-pixel border width
            clip: true                                                          // Clips child content to the rounded rectangle bounds

            // Rotating Background Blobs                                          // Comment describing decorative background blob elements
            Rectangle {                                                         // First background blob (larger, tab-colored)
                width: parent.width * 0.8; height: width; radius: width / 2     // 80% of parent width, circular shape
                x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150) // X: centered + cosine orbital movement with 150-unit amplitude
                y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100) // Y: centered + sine orbital movement with 100-unit amplitude
                opacity: 0.06                                                   // 6% opacity for subtle ambient effect
                color: window.tabColor                                          // Uses the current tab's accent color (blue/mauve/green)
                Behavior on color { ColorAnimation { duration: 800 } }          // Smooth 800ms color transition when tab changes
            }
            Rectangle {                                                         // Second background blob (larger, lighter, opposite orbit)
                width: parent.width * 0.9; height: width; radius: width / 2     // 90% of parent width, larger than first blob
                x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150) // X: uses sine with 1.5x frequency and negative direction
                y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100) // Y: uses cosine with negative direction for opposite orbit
                opacity: 0.04                                                   // 4% opacity, more subtle than first blob
                color: Qt.lighter(window.tabColor, 1.3)                         // 30% lighter version of the tab color for visual variety
                Behavior on color { ColorAnimation { duration: 800 } }          // Smooth color transition
            }

            ColumnLayout {                                                      // Main vertical layout for all UI elements
                anchors.fill: parent                                            // Fills the background rectangle
                anchors.margins: window.s(25)                                   // 25-unit scaled margin on all sides
                spacing: window.s(20)                                           // 20-unit vertical spacing between major sections

                // ==========================================                    // Visual divider for hero section
                // HERO ORB & MASTER SLIDER (TOP SECTION)                         // Section header: the large orb and master volume slider at the top
                // ==========================================                    // Visual divider closing the section header
                Item {                                                          // Container for the hero orb and master controls
                    Layout.fillWidth: true                                      // Fills full width of the column
                    Layout.preferredHeight: window.s(150)                       // Fixed height of 150 scaled units
                    opacity: introHeader                                        // Fades in with the header intro animation progress
                    transform: Translate { y: window.s(30) * (1.0 - introHeader) } // Slides up from 30 units below as header intro progresses

                    RowLayout {                                                 // Horizontal layout for orb and details/slider side by side
                        anchors.fill: parent                                    // Fills the parent item
                        spacing: window.s(25)                                   // 25-unit spacing between orb and details

                        // 1. The Orb                                                // Comment for the orb section
                        Item {                                                  // Container for the master volume orb
                            Layout.preferredWidth: window.s(130)                // Fixed width of 130 scaled units
                            Layout.preferredHeight: window.s(130)               // Fixed height of 130 scaled units (square)
                            scale: masterOrbMa.pressed ? 0.95 : (masterOrbMa.containsMouse ? 1.05 : 1.0) // Shrinks to 95% on press, grows to 105% on hover
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } } // Bouncy scale animation over 400ms

                            // Outermost border pulse ring                          // Comment describing the pulsing border ring effect
                            Rectangle {                                         // Outer pulsing ring around the orb
                                anchors.centerIn: parent                        // Centered on the orb container
                                width: parent.width + window.s(15)              // 15 units larger than the orb
                                height: width                                   // Maintains circular shape
                                radius: width / 2                               // Full circle radius
                                color: "transparent"                            // Transparent fill, only border is visible
                                border.color: window.activeMute ? window.red : window.tabColor // Red border when muted, tab color otherwise
                                border.width: window.s(3)                       // 3-unit thick border
                                z: -2                                           // Placed behind the main orb (z-index -2)

                                property real pulseOp: 0.0                      // Property for pulsing opacity animation
                                property real pulseSc: 1.0                      // Property for pulsing scale animation
                                opacity: window.activeMute ? 0.0 : pulseOp      // Hidden when muted, otherwise follows pulse opacity
                                scale: pulseSc                                  // Applies the pulsing scale

                                Timer {                                         // Timer that drives the pulsing animation
                                    interval: 45                                // 45ms interval for smooth animation (~22fps)
                                    running: parent.opacity > 0.01 || !window.activeMute // Runs when visible or not muted
                                    repeat: true                                // Repeats continuously
                                    onTriggered: {                              // Called each timer tick
                                        var time = Date.now() / 1000;           // Gets current time in seconds
                                        parent.pulseOp = 0.3 + Math.sin(time * 2.5) * 0.15; // Pulsing opacity between 0.15 and 0.45
                                        parent.pulseSc = 1.02 + Math.cos(time * 3.0) * 0.02; // Pulsing scale between 1.00 and 1.04
                                    }
                                }
                            }

                            // Solid pulsing background ring                         // Comment describing the larger solid background ring
                            Rectangle {                                         // Larger solid ring behind the orb
                                anchors.centerIn: parent                        // Centered on the orb
                                width: parent.width + window.s(40)              // 40 units larger than orb
                                height: width                                   // Circular shape
                                radius: width / 2                               // Full circle
                                color: window.activeMute ? window.red : window.tabColor // Red when muted, tab color otherwise
                                opacity: window.activeMute ? 0.3 : 0.15         // 30% opacity when muted, 15% otherwise
                                z: -1                                           // Behind the main orb but in front of the pulse ring
                                Behavior on color { ColorAnimation { duration: 300 } } // Smooth color transition on mute/tab change

                                SequentialAnimation on scale {                  // Breathing scale animation for the background ring
                                    loops: Animation.Infinite; running: true    // Loops infinitely, starts immediately
                                    NumberAnimation { to: masterOrbMa.containsMouse ? 1.15 : 1.1; duration: masterOrbMa.containsMouse ? 800 : 2000; easing.type: Easing.InOutSine } // Expands to 1.15 on hover (800ms) or 1.1 normally (2000ms)
                                    NumberAnimation { to: 1.0; duration: masterOrbMa.containsMouse ? 800 : 2000; easing.type: Easing.InOutSine } // Contracts back to 1.0
                                }
                            }

                            // Core Shadow                                          // Comment for the drop shadow effect on the orb
                            MultiEffect {                                       // MultiEffect for rendering a shadow beneath the orb
                                source: centralCore                             // Applies shadow to the centralCore rectangle
                                anchors.fill: centralCore                       // Covers the same area as centralCore
                                shadowEnabled: true                             // Enables shadow rendering
                                shadowColor: "#000000"                          // Black shadow color
                                shadowOpacity: 0.5                              // 50% opacity shadow
                                shadowBlur: 1.2                                 // Soft blur on the shadow (1.2 blur factor)
                                shadowVerticalOffset: window.s(6)               // Shadow offset 6 units downward
                                z: -1                                           // Placed behind the core
                            }

                            // Core Rectangle                                       // Comment for the main orb body
                            Rectangle {                                         // The main central orb circle
                                id: centralCore                                 // Unique identifier "centralCore"
                                anchors.fill: parent                            // Fills the orb container
                                radius: width / 2                               // Perfect circle
                                color: window.base                              // Base background color
                                border.color: window.activeMute ? window.red : Qt.lighter(window.tabColor, 1.1) // Red border when muted, lighter tab color otherwise
                                border.width: 2                                 // 2-pixel border
                                clip: true                                      // Clips the wave fill animation to circular bounds
                                Behavior on border.color { ColorAnimation { duration: 300 } } // Smooth border color transition

                                // Volume Wave Fill                                  // Comment for the animated wave fill inside the orb
                                Canvas {                                        // Canvas for drawing the dynamic wave fill effect
                                    id: orbWave                                 // Unique identifier "orbWave"
                                    anchors.fill: parent                        // Fills the central core
                                    
                                    property real wavePhase: 0.0                // Phase angle for wave animation
                                    NumberAnimation on wavePhase {              // Continuous animation for wave movement
                                        running: window.activeVol > 0 && window.activeVol < 100 // Only runs when volume is between 1 and 99
                                        loops: Animation.Infinite               // Loops infinitely while running
                                        from: 0; to: Math.PI * 2; duration: 1200 // Full phase cycle over 1.2 seconds
                                    }
                                    onWavePhaseChanged: requestPaint()          // Requests repaint when wave phase changes

                                    Connections {                               // Connections to trigger repaints on state changes
                                        target: window                          // Connects to the root window
                                        function onActiveVolChanged() { orbWave.requestPaint() } // Repaint when volume changes
                                        function onActiveMuteChanged() { orbWave.requestPaint() } // Repaint when mute state changes
                                        function onTabColorChanged() { orbWave.requestPaint() } // Repaint when tab color changes
                                    }

                                    onPaint: {                                  // Custom paint function that draws the wave fill
                                        var ctx = getContext("2d");             // Gets 2D canvas rendering context
                                        ctx.clearRect(0, 0, width, height);     // Clears the canvas
                                        if (window.activeVol <= 0) return;      // Don't draw anything if volume is 0

                                        var fillRatio = window.activeVol / 100.0; // Converts volume to fill ratio (0.0 to 1.0)
                                        var r = width / 2;                      // Radius of the circle
                                        var fillY = height * (1.0 - fillRatio); // Y position where fill starts (bottom-up fill)

                                        ctx.save();                             // Saves current drawing state
                                        
                                        // 1. Establish the circular clipping mask // Comment: clip to circle shape
                                        ctx.beginPath();                        // Begins new path
                                        ctx.arc(r, r, r, 0, 2 * Math.PI);      // Draws a circle path centered at (r,r) with radius r
                                        ctx.clip();                             // Clips all subsequent drawing to this circle
                                        
                                        // 2. Draw the actual wave filling         // Comment: draw the wavy fill
                                        ctx.beginPath();                        // Begins new path for the fill
                                        ctx.moveTo(0, fillY);                   // Starts at left edge at the fill height
                                        
                                        if (fillRatio < 0.99) {                 // If not fully filled, draw wavy top edge
                                            var waveAmp = window.s(8) * Math.sin(fillRatio * Math.PI); // Wave amplitude decreases near full (sine of fill * π)
                                            var cp1y = fillY + Math.sin(wavePhase) * waveAmp; // Control point 1 Y: varies with wave phase
                                            var cp2y = fillY + Math.cos(wavePhase + Math.PI) * waveAmp; // Control point 2 Y: offset by π for opposite curve
                                            ctx.bezierCurveTo(width * 0.33, cp2y, width * 0.66, cp1y, width, fillY); // Cubic bezier creating wavy top edge
                                            ctx.lineTo(width, height);          // Line down right edge
                                            ctx.lineTo(0, height);              // Line across bottom edge
                                        } else {                                // If fully filled (100%)
                                            ctx.lineTo(width, 0);               // Line to top-right
                                            ctx.lineTo(width, height);          // Line down right edge
                                            ctx.lineTo(0, height);              // Line across bottom
                                        }
                                        ctx.closePath();                        // Closes the fill path
                                        
                                        // Vibrant gradient matching the network orb // Comment: gradient coloring
                                        var grad = ctx.createLinearGradient(0, 0, 0, height); // Vertical linear gradient
                                        if (window.activeMute) {                // If muted, use red gradient
                                            grad.addColorStop(0, Qt.lighter(window.red, 1.15).toString()); // Lighter red at top
                                            grad.addColorStop(1, window.red.toString()); // Normal red at bottom
                                        } else {                                // If not muted, use tab color
                                            grad.addColorStop(0, Qt.lighter(window.tabColor, 1.15).toString()); // Lighter tab color at top
                                            grad.addColorStop(1, window.tabColor.toString()); // Normal tab color at bottom
                                        }
                                        ctx.fillStyle = grad;                   // Sets fill to the gradient
                                        ctx.globalAlpha = 1.0;                  // Full opacity
                                        ctx.fill();                             // Fills the wave area
                                        ctx.restore();                          // Restores previous drawing state (removes clip)
                                    }
                                }

                                // Dual-Layer Text for contrast clipping          // Comment describing the two-layer text system for contrast
                                // 1. Base Text (Visible when empty)              // Comment: base text layer always visible
                                Text {                                          // Base text layer showing volume/mute
                                    anchors.centerIn: parent                    // Centered in the orb
                                    font.family: "JetBrains Mono"               // Monospace font
                                    font.weight: Font.Black                     // Heaviest font weight
                                    font.pixelSize: window.s(32)                // Large 32-unit font size
                                    color: window.activeMute ? window.red : window.text // Red when muted, normal text color otherwise
                                    text: window.activeMute ? "MUTE" : window.activeVol + "%" // Shows "MUTE" or volume percentage
                                    Behavior on color { ColorAnimation { duration: 200 } } // Smooth color transition
                                }

                                // 2. Clipped Text (Dark text that reveals over the wave fill dynamically) // Comment: clipped text that shows dark over the wave fill
                                Item {                                          // Container item that clips the dark text to wave fill area
                                    id: waveClipItem                            // Unique identifier "waveClipItem"
                                    anchors.bottom: parent.bottom               // Anchored to bottom of orb
                                    anchors.left: parent.left                   // Anchored to left
                                    anchors.right: parent.right                 // Anchored to right

                                    // Calculate the exact wave offset at the center of the orb using the Bezier formula // Comment: calculates wave edge position
                                    property real fillRatio: window.activeVol / 100.0 // Current fill ratio
                                    property real waveAmp: fillRatio < 0.99 ? window.s(8) * Math.sin(fillRatio * Math.PI) : 0 // Wave amplitude (0 when full)
                                    property real waveCenterOffset: 0.375 * waveAmp * (Math.sin(orbWave.wavePhase) - Math.cos(orbWave.wavePhase)) // Calculates wave offset at center using bezier midpoint formula
                                    property real baseClipHeight: parent.height * fillRatio // Base height proportional to fill ratio

                                    height: Math.min(parent.height, Math.max(0, baseClipHeight - waveCenterOffset)) // Clips height: dynamic wave edge, clamped to valid range
                                    clip: true                                  // Clips child text to this item's height
                                    visible: window.activeVol > 0               // Only visible when volume is greater than 0

                                    Text {                                      // Dark text that appears over the wave fill
                                        x: waveClipItem.width / 2 - width / 2   // Horizontally centered
                                        y: (centralCore.height / 2) - (height / 2) - (centralCore.height - waveClipItem.height) // Vertically positioned so text stays fixed while clip reveals it
                                        font.family: "JetBrains Mono"           // Monospace font
                                        font.weight: Font.Black                 // Heaviest weight
                                        font.pixelSize: window.s(32)            // Large font matching base text
                                        color: window.crust                     // Light crust color for contrast against wave fill
                                        text: window.activeMute ? "MUTE" : window.activeVol + "%" // Same text as base layer
                                    }
                                }
                            }

                            MouseArea {                                         // Interactive area for the master orb (click to toggle mute)
                                id: masterOrbMa                                 // Unique identifier "masterOrbMa"
                                anchors.fill: parent                            // Covers entire orb
                                hoverEnabled: true                              // Enables hover detection
                                cursorShape: Qt.PointingHandCursor              // Hand cursor on hover
                                onClicked: {                                    // Click handler
                                    let type = window.activeTab === "inputs" ? "source" : "sink"; // Determine type: "source" for inputs tab, "sink" otherwise
                                    Quickshell.execDetached(["bash", window.scriptsDir + "/audio_control.sh", "toggle-mute", type, window.activeId]); // Run audio_control.sh to toggle mute for the active device
                                    audioPoller.running = true;                 // Trigger immediate audio state refresh
                                }
                            }
                        }

                        // 2. Details & Slider                                      // Comment for the details and master slider section
                        ColumnLayout {                                          // Vertical layout for device name and master slider
                            Layout.fillWidth: true                              // Fills remaining horizontal space
                            Layout.fillHeight: true                             // Fills full height
                            spacing: window.s(10)                               // 10-unit spacing between elements

                            ColumnLayout {                                      // Nested vertical layout for text labels
                                spacing: window.s(2)                            // 2-unit tight spacing between name and description
                                Text {                                          // Active device display name
                                    Layout.fillWidth: true; elide: Text.ElideRight // Fills width, elides text with "..." if too long
                                    font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(20) // Bold monospace at 20 units
                                    color: window.text                          // Primary text color
                                    text: window.activeName                     // Shows the active device description
                                }
                                Text {                                          // Active device subtitle/description
                                    Layout.fillWidth: true; elide: Text.ElideRight // Fills width, elides if needed
                                    font.family: "JetBrains Mono"; font.pixelSize: window.s(13) // Monospace at 13 units
                                    color: window.subtext0                      // Muted subtext color
                                    text: window.activeTab === "apps" ? "Master Output Volume" : window.activeDesc // Shows "Master Output Volume" for apps tab, device name otherwise
                                }
                            }

                            Item { Layout.fillHeight: true }                    // Spacer that pushes the slider to the bottom

                            RowLayout {                                         // Horizontal layout for the master slider
                                Layout.fillWidth: true                          // Fills full width
                                spacing: window.s(15)                           // 15-unit spacing (for potential future elements)

                                // Slider                                            // Comment for the master volume slider
                                Item {                                          // Container for the slider bar
                                    Layout.fillWidth: true                      // Fills remaining width
                                    height: window.s(24)                        // 24-unit height for the slider track

                                    Timer {                                     // Throttle timer to batch volume change commands
                                        id: masterCmdThrottle                   // Unique identifier "masterCmdThrottle"
                                        interval: 50                            // 50ms debounce interval
                                        property int targetPct: -1               // Target volume percentage, -1 means no pending command
                                        onTriggered: {                          // Called when timer fires
                                            if (targetPct >= 0) {               // If there's a pending volume change
                                                let type = window.activeTab === "inputs" ? "source" : "sink"; // Determine device type
                                                if (targetPct > 0 && window.activeMute) { // If setting volume above 0 while muted
                                                    Quickshell.execDetached(["bash", window.scriptsDir + "/audio_control.sh", "toggle-mute", type, window.activeId]); // Unmute first
                                                }
                                                Quickshell.execDetached(["bash", window.scriptsDir + "/audio_control.sh", "set-volume", type, window.activeId, targetPct]); // Set the volume
                                                targetPct = -1;                 // Clear the pending command
                                            }
                                        }
                                    }

                                    Rectangle {                                 // Slider track background
                                        anchors.fill: parent; radius: window.s(12) // Fills parent, rounded corners
                                        color: "#0dffffff"; border.color: "#1affffff"; border.width: 1 // Semi-transparent white with subtle border
                                        clip: true                              // Clips the fill bar to rounded bounds

                                        Rectangle {                             // Slider fill bar (shows current volume)
                                            height: parent.height               // Full height of track
                                            width: parent.width * (Math.min(100, window.activeVol) / 100) // Width proportional to volume (capped at 100%)
                                            radius: window.s(12)                // Rounded corners matching track
                                            opacity: window.activeMute ? 0.3 : (masterSliderMa.containsMouse ? 1.0 : 0.85) // Dimmed when muted, full on hover, 85% normally
                                            Behavior on opacity { NumberAnimation { duration: 200 } } // Smooth opacity transition
                                            Behavior on width { enabled: !window.draggingMaster; NumberAnimation { duration: 300; easing.type: Easing.OutQuint } } // Animated width when not dragging

                                            gradient: Gradient {                // Gradient fill for the slider bar
                                                orientation: Gradient.Horizontal // Left-to-right gradient
                                                GradientStop { position: 0.0; color: window.activeMute ? window.surface2 : window.tabColor; Behavior on color { ColorAnimation{duration: 300} } } // Left: surface2 when muted, tab color normally
                                                GradientStop { position: 1.0; color: window.activeMute ? Qt.lighter(window.surface2, 1.15) : Qt.lighter(window.tabColor, 1.25); Behavior on color { ColorAnimation{duration: 300} } } // Right: lighter shade
                                            }
                                        }
                                    }
                                    
                                    MouseArea {                                 // Interactive area for the master slider
                                        id: masterSliderMa                      // Unique identifier "masterSliderMa"
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor // Full coverage; hover enabled; hand cursor
                                        onPressed: (mouse) => { syncDelay.stop(); window.draggingMaster = true; updateVol(mouse.x); } // On press: stop sync delay, set dragging flag, update volume from click position
                                        onPositionChanged: (mouse) => { if (pressed) updateVol(mouse.x); } // While dragging, continuously update volume
                                        onReleased: { syncDelay.restart(); audioPoller.running = true; } // On release: restart sync delay timer, trigger audio refresh
                                        
                                        function updateVol(mx) {                // Function to calculate and apply volume from mouse X position
                                            let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100))); // Calculate percentage from mouse position, clamped 0-100
                                            window.activeVol = pct;              // Update the displayed volume immediately for visual feedback

                                            masterCmdThrottle.targetPct = pct;  // Set the throttled command target
                                            if (!masterCmdThrottle.running) masterCmdThrottle.start(); // Start throttle timer if not already running
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ==========================================                    // Visual divider for tabs section
                // TABS                                                                  // Section header: the tab bar for switching between outputs/inputs/apps
                // ==========================================                    // Visual divider closing the section header
                Rectangle {                                                     // Tab bar background container
                    Layout.fillWidth: true                                      // Full width
                    Layout.preferredHeight: window.s(54)                        // 54-unit height
                    radius: window.s(14)                                        // 14-unit rounded corners
                    color: "#0dffffff"                                          // Very subtle semi-transparent white background
                    border.color: "#1affffff"                                   // Subtle white border
                    border.width: 1                                             // 1-pixel border
                    opacity: introHeader                                        // Fades in with header intro animation
                    transform: Translate { y: window.s(20) * (1.0 - introHeader) } // Slides up from 20 units below

                    Rectangle {                                                 // Animated pill indicator that slides between tabs
                        width: (parent.width - window.s(2)) / 3                  // Width is one-third of available space (minus 2-unit gap)
                        height: parent.height - window.s(2)                     // Height matches parent minus 2-unit gap
                        y: window.s(1)                                          // 1 unit from top
                        radius: window.s(10)                                    // 10-unit rounded corners
                        x: {                                                    // Computed X position based on active tab
                            if (window.activeTab === "outputs") return window.s(1); // First position for outputs
                            if (window.activeTab === "inputs") return width + window.s(1); // Second position for inputs
                            return (width * 2) + window.s(1);                   // Third position for apps
                        }
                        Behavior on x { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.1 } } // Animated sliding with back easing (slight overshoot)
                        
                        gradient: Gradient {                                    // Gradient fill for the pill
                            orientation: Gradient.Horizontal                    // Left-to-right gradient
                            GradientStop { position: 0.0; color: window.tabColor; Behavior on color { ColorAnimation { duration: 400 } } } // Left: tab color with animated transition
                            GradientStop { position: 1.0; color: Qt.lighter(window.tabColor, 1.15); Behavior on color { ColorAnimation { duration: 400 } } } // Right: lighter shade with animated transition
                        }
                    }

                    RowLayout {                                                 // Row layout for the three tab buttons
                        anchors.fill: parent                                    // Fills the tab bar
                        spacing: 0                                              // No spacing (tabs touch each other)
                        
                        Repeater {                                              // Repeater creating three tab buttons from model
                            model: ListModel {                                  // Inline ListModel defining the three tabs
                                ListElement { tabId: "outputs"; icon: "󰓃"; label: "Outputs" } // Outputs tab: speaker icon
                                ListElement { tabId: "inputs"; icon: "󰍬"; label: "Inputs" }    // Inputs tab: microphone icon
                                ListElement { tabId: "apps"; icon: "󰎆"; label: "Streams" }    // Apps tab: application icon
                            }
                            
                            delegate: Item {                                    // Delegate for each tab button
                                Layout.fillWidth: true                          // Each tab gets equal width
                                Layout.fillHeight: true                         // Full height
                                
                                RowLayout {                                     // Horizontal layout for icon and label
                                    anchors.centerIn: parent                    // Centered in the tab
                                    spacing: window.s(8)                        // 8-unit spacing between icon and text
                                    Text {                                      // Tab icon (Nerd Font)
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18) // Nerd Font at 18 units
                                        color: window.activeTab === tabId ? window.crust : (tabMa.containsMouse ? window.text : window.subtext0) // Crust when active, text on hover, subtext0 normally
                                        text: icon                              // The icon character from model
                                        Behavior on color { ColorAnimation { duration: 200 } } // Smooth color transition
                                    }
                                    Text {                                      // Tab label
                                        font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(13) // Bold monospace at 13 units
                                        color: window.activeTab === tabId ? window.crust : (tabMa.containsMouse ? window.text : window.subtext0) // Same color logic as icon
                                        text: label                             // The label text from model
                                        Behavior on color { ColorAnimation { duration: 200 } } // Smooth color transition
                                    }
                                }
                                
                                MouseArea {                                     // Clickable area for tab switching
                                    id: tabMa                                   // Unique identifier "tabMa"
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor // Full coverage; hover; hand cursor
                                    onClicked: {                                // Click handler
                                        window.activeTab = tabId;               // Switch to this tab
                                    }
                                }
                            }
                        }
                    }
                }

                // ==========================================                    // Visual divider for content list section
                // LIST VIEW CONTENT                                                    // Section header: the scrollable list of audio devices
                // ==========================================                    // Visual divider closing the section header
                Item {                                                          // Container for the device list view
                    Layout.fillWidth: true                                      // Full width
                    Layout.fillHeight: true                                     // Fills remaining vertical space
                    opacity: introContent                                       // Fades in with content intro animation
                    transform: Translate { y: window.s(20) * (1.0 - introContent) } // Slides up from 20 units below

                    ListView {                                                  // Scrollable list view for devices
                        id: contentList                                         // Unique identifier "contentList"
                        anchors.fill: parent                                    // Fills the parent item
                        spacing: window.s(12)                                   // 12-unit spacing between device cards
                        clip: true                                              // Clips content to bounds
                        boundsBehavior: Flickable.StopAtBounds                  // Stops scrolling at edges (no overshoot bounce)

                        // Elegant sliding transitions when models rearrange       // Comment describing add/displaced animations
                        add: Transition {                                       // Animation when new items are added
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutQuint } // Fades in over 400ms
                            NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: 400; easing.type: Easing.OutBack } // Scales from 90% with overshoot over 400ms
                        }
                        displaced: Transition {                                 // Animation when items are displaced/reordered
                            SpringAnimation { property: "y"; spring: 3; damping: 0.2; mass: 0.2 } // Spring animation for vertical movement (bouncy)
                        }

                        model: {                                                // Dynamic model selection based on active tab
                            if (window.activeTab === "outputs") return outputsModel; // Use outputs model
                            if (window.activeTab === "inputs") return inputsModel;  // Use inputs model
                            return appsModel;                                   // Default to apps model
                        }

                        Item {                                                  // Empty state placeholder (shown when no devices)
                            width: contentList.width; height: contentList.height // Matches list size
                            visible: contentList.count === 0                     // Only visible when the model is empty
                            ColumnLayout {                                      // Centered vertical layout for empty state
                                anchors.centerIn: parent                        // Centered in the list area
                                spacing: window.s(10)                           // 10-unit spacing
                                Text { Layout.alignment: Qt.AlignHCenter; font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(32); color: window.surface2; text: "󰖁" } // Large muted speaker icon centered
                                Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.pixelSize: window.s(14); color: window.overlay0; text: "No active streams" } // "No active streams" message
                            }
                        }

                        delegate: Rectangle {                                   // Delegate defining each device card
                            id: delegateRoot                                    // Unique identifier "delegateRoot"
                            width: contentList.width                            // Full list width
                            
                            // Staggered Intro Animation Timer                     // Comment describing staggered entrance animation
                            property bool isLoaded: false                        // Tracks if this card's intro animation has triggered
                            Timer {                                             // Timer for staggered animation delay
                                running: true                                   // Starts immediately
                                interval: 40 + (index * 40)                     // Base 40ms + 40ms per index for stagger effect
                                onTriggered: delegateRoot.isLoaded = true        // When timer fires, mark as loaded to trigger animation
                            }

                            // Intro transforms                                     // Comment for intro animation properties
                            opacity: isLoaded ? 1.0 : 0.0                        // Fades in when loaded
                            transform: Translate { y: isLoaded ? 0 : window.s(15) } // Slides up from 15 units when loaded
                            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } } // Smooth fade over 500ms
                            Behavior on transform { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } } // Smooth slide over 500ms

                            // Dynamic Height: The active hero element collapses its bottom slider row // Comment explaining height difference for active device
                            property bool isActiveNode: model.is_default && window.activeTab !== "apps" // True when this is the default device and NOT on apps tab
                            height: isActiveNode ? window.s(60) : window.s(100)  // 60 units when active (collapsed slider), 100 units normally
                            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } } // Animated height transition

                            radius: window.s(14)                                // 14-unit rounded corners
                            
                            property bool isHovered: cardMa.containsMouse && !isActiveNode // True when hovered and not the active node

                            color: isActiveNode ? window.tabColor : (isHovered ? "#0affffff" : "#05ffffff") // Tab color when active, brighter on hover, subtle default
                            border.color: isActiveNode ? window.tabColor : "#1affffff" // Tab color border when active, subtle white otherwise
                            border.width: isActiveNode ? 2 : 1                  // 2px border when active, 1px normally
                            Behavior on border.color { ColorAnimation { duration: 300 } } // Smooth border color
                            Behavior on color { ColorAnimation { duration: 300 } } // Smooth background color

                            // Full card selection listener                         // Comment for click-to-select-default functionality
                            MouseArea {                                         // Clickable area covering the entire card
                                id: cardMa                                      // Unique identifier "cardMa"
                                anchors.fill: parent                            // Full card coverage
                                hoverEnabled: window.activeTab !== "apps"       // Hover enabled except on apps tab (apps are not selectable)
                                cursorShape: window.activeTab !== "apps" ? Qt.PointingHandCursor : Qt.ArrowCursor // Hand cursor for devices, arrow for apps
                                onClicked: {                                    // Click handler to set device as default
                                    if (window.activeTab !== "apps" && !model.is_default) { // Only for non-apps tabs and if not already default
                                        let type = window.activeTab === "outputs" ? "sink" : "source"; // Determine type: sink for outputs, source for inputs
                                        Quickshell.execDetached(["bash", window.scriptsDir + "/audio_control.sh", "set-default", type, model.name]); // Run script to set this device as default
                                        audioPoller.running = true;             // Trigger audio state refresh
                                    }
                                }
                            }

                            ColumnLayout {                                      // Vertical layout for card content
                                anchors.fill: parent                            // Fills the card
                                anchors.leftMargin: window.s(16)                // 16-unit left padding
                                anchors.rightMargin: window.s(16)               // 16-unit right padding
                                anchors.topMargin: window.s(12)                 // 12-unit top padding
                                anchors.bottomMargin: isActiveNode ? window.s(12) : window.s(16) // Bottom padding: 12 when active, 16 normally
                                spacing: window.s(12)                           // 12-unit spacing between rows

                                // Top row: Text info and Icon                      // Comment for the top row of the card
                                RowLayout {                                     // Horizontal layout for icon and text
                                    Layout.fillWidth: true                      // Full width
                                    spacing: window.s(12)                       // 12-unit spacing

                                    Text {                                      // Device type icon
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(22) // Nerd Font at 22 units
                                        color: isActiveNode ? window.crust : window.text // Crust when active, normal text otherwise
                                        Behavior on color { ColorAnimation { duration: 200 } } // Smooth color
                                        text: {                                 // Icon selection logic
                                            if (window.activeTab === "inputs") return "󰍬"; // Microphone icon for inputs
                                            if (window.activeTab === "apps") return "󰎆"; // Application icon for apps
                                            if (model.description.toLowerCase().indexOf("headset") !== -1 || model.description.toLowerCase().indexOf("headphones") !== -1) return "󰋎"; // Headset icon if name contains headset/headphones
                                            return "󰓃";                         // Default speaker icon for outputs
                                        }
                                    }

                                    ColumnLayout {                              // Vertical layout for device name and subtitle
                                        Layout.fillWidth: true                  // Fills remaining width
                                        spacing: window.s(2)                    // 2-unit tight spacing
                                        Text {                                  // Device description/name
                                            Layout.fillWidth: true; elide: Text.ElideRight // Fills width, elides if too long
                                            font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(14) // Bold monospace at 14 units
                                            color: isActiveNode ? window.crust : window.text // Crust when active
                                            text: model.description             // Device description from model
                                        }
                                        Text {                                  // Device subtitle (technical name or status)
                                            Layout.fillWidth: true; elide: Text.ElideRight // Fills width, elides
                                            font.family: "JetBrains Mono"; font.pixelSize: window.s(11) // Monospace at 11 units
                                            color: isActiveNode ? Qt.darker(window.crust, 1.5) : window.subtext0 // Darker crust when active, subtext0 normally
                                            text: isActiveNode ? "Active Default" : model.name // Shows "Active Default" for active, technical name otherwise
                                        }
                                    }
                                }

                                // Bottom row: Custom Slider & Mute (Hides if it's the active node) // Comment for slider row (hidden on active/hero device)
                                RowLayout {                                     // Horizontal layout for mute button and volume slider
                                    Layout.fillWidth: true                      // Full width
                                    spacing: window.s(15)                       // 15-unit spacing
                                    visible: !isActiveNode                       // Hidden when this is the active/default device (uses master slider instead)
                                    opacity: isActiveNode ? 0.0 : 1.0            // Fades out when hidden
                                    Behavior on opacity { NumberAnimation { duration: 200 } } // Smooth opacity transition

                                    Rectangle {                                 // Mute button background
                                        Layout.preferredWidth: window.s(32); Layout.preferredHeight: window.s(32); radius: window.s(16) // 32x32 circular button
                                        color: muteMa.containsMouse ? "#1affffff" : "transparent" // White tint on hover, transparent normally
                                        border.color: muteMa.containsMouse ? (model.mute ? window.overlay0 : window.tabColor) : "transparent" // Colored border on hover, transparent normally
                                        Behavior on color { ColorAnimation { duration: 150 } } // Quick color transition

                                        Text {                                  // Mute/unmute icon
                                            anchors.centerIn: parent            // Centered in button
                                            font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18) // Nerd Font at 18 units
                                            color: model.mute ? window.overlay0 : window.subtext0 // Overlay0 when muted, subtext0 normally
                                            text: model.mute || model.volume === 0 ? "󰖁" : (model.volume > 50 ? "󰕾" : "󰖀") // Muted speaker icon when muted/0, high volume icon when >50%, low volume otherwise
                                            Behavior on color { ColorAnimation { duration: 200 } } // Smooth color
                                        }
                                        MouseArea {                             // Clickable area for mute toggle
                                            id: muteMa                          // Unique identifier "muteMa"
                                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor // Full coverage; hover; hand cursor
                                            onClicked: {                        // Click handler
                                                let type = "sink";              // Default to sink (output)
                                                if (window.activeTab === "inputs") type = "source"; // Source for inputs tab
                                                if (window.activeTab === "apps") type = "sink-input"; // Sink-input for apps tab
                                                Quickshell.execDetached(["bash", window.scriptsDir + "/audio_control.sh", "toggle-mute", type, model.id]); // Run audio_control.sh to toggle mute
                                                audioPoller.running = true;     // Trigger audio refresh
                                            }
                                        }
                                    }

                                    // Local Slider                                     // Comment for the per-device volume slider
                                    Item {                                      // Container for the slider
                                        Layout.fillWidth: true                  // Fills remaining width
                                        height: window.s(14)                    // 14-unit height (thinner than master slider for visual hierarchy)
                                        
                                        Timer {                                 // Throttle timer for volume commands
                                            id: volCmdThrottle                  // Unique identifier "volCmdThrottle"
                                            interval: 50                        // 50ms debounce
                                            property int targetPct: -1           // Pending volume target
                                            onTriggered: {                      // When timer fires
                                                if (targetPct >= 0) {           // If there's a pending command
                                                    let type = "sink";          // Default to sink
                                                    if (window.activeTab === "inputs") type = "source"; // Source for inputs
                                                    if (window.activeTab === "apps") type = "sink-input"; // Sink-input for apps
                                                    
                                                    if (targetPct > 0 && model.mute) { // If setting non-zero volume while muted
                                                        Quickshell.execDetached(["bash", window.scriptsDir + "/audio_control.sh", "toggle-mute", type, model.id]); // Unmute first
                                                    }
                                                    Quickshell.execDetached(["bash", window.scriptsDir + "/audio_control.sh", "set-volume", type, model.id, targetPct]); // Set volume
                                                    targetPct = -1;             // Clear pending
                                                }
                                            }
                                        }

                                        Rectangle {                             // Slider track background
                                            anchors.fill: parent; radius: window.s(7) // Fills; smaller radius for thinner slider
                                            color: "#0dffffff"; border.color: "#1affffff"; border.width: 1 // Semi-transparent white
                                            clip: true                          // Clips fill bar

                                            Rectangle {                         // Slider fill bar
                                                height: parent.height           // Full track height
                                                width: parent.width * (Math.min(100, model.volume) / 100) // Width proportional to device volume
                                                radius: window.s(7)             // Rounded corners
                                                
                                                // Heavily dimmed if muted, slightly dimmed if background node // Comment for opacity logic
                                                opacity: model.mute ? 0.3 : (volSliderMa.containsMouse ? 0.7 : 0.4) // 30% when muted, 70% on hover, 40% normally
                                                Behavior on opacity { NumberAnimation { duration: 200 } } // Smooth opacity
                                                Behavior on width { enabled: !window.draggingNodes[model.id]; NumberAnimation { duration: 300; easing.type: Easing.OutQuint } } // Animated width when not dragging

                                                gradient: Gradient {            // Gradient fill
                                                    orientation: Gradient.Horizontal // Left-to-right
                                                    GradientStop { position: 0.0; color: model.mute ? window.surface2 : window.tabColor; Behavior on color { ColorAnimation { duration: 300 } } } // Surface2 when muted
                                                    GradientStop { position: 1.0; color: model.mute ? Qt.lighter(window.surface2, 1.15) : Qt.lighter(window.tabColor, 1.25); Behavior on color { ColorAnimation { duration: 300 } } } // Lighter shade
                                                }
                                            }
                                        }
                                        
                                        MouseArea {                             // Interactive slider area
                                            id: volSliderMa                     // Unique identifier "volSliderMa"
                                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor // Full coverage; hover; hand cursor
                                            onPressed: (mouse) => { syncDelay.stop(); window.draggingNodes[model.id] = true; updateVol(mouse.x); } // On press: stop sync, mark as dragging, update volume
                                            onPositionChanged: (mouse) => { if (pressed) updateVol(mouse.x); } // While dragging, update
                                            onReleased: { syncDelay.restart(); audioPoller.running = true; } // On release: restart sync, refresh
                                            
                                            function updateVol(mx) {            // Calculate volume from mouse position
                                                let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100))); // Clamped percentage
                                                
                                                let targetList = window.activeTab === "outputs" ? outputsModel : (window.activeTab === "inputs" ? inputsModel : appsModel); // Get the correct model
                                                for (let i = 0; i < targetList.count; i++) { // Find this device in model
                                                    if (targetList.get(i).id === model.id) { // Match by ID
                                                        targetList.setProperty(i, "volume", pct); // Update volume in model for instant UI feedback
                                                        break;
                                                    }
                                                }

                                                volCmdThrottle.targetPct = pct; // Set throttle target
                                                if (!volCmdThrottle.running) volCmdThrottle.start(); // Start throttle timer
                                            }
                                        }
                                    }

                                    Text {                                      // Volume percentage label
                                        Layout.preferredWidth: window.s(35)     // Fixed 35-unit width
                                        font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12) // Bold monospace at 12 units
                                        color: window.subtext0                  // Muted color
                                        text: model.volume + "%"                // Shows volume percentage
                                        horizontalAlignment: Text.AlignRight    // Right-aligned
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