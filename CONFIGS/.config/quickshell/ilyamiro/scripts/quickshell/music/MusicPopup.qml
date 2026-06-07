// import QtQuick
// import QtQuick.Window
// import QtQuick.Controls
// import QtQuick.Layouts
// import QtQuick.Effects
// import QtQuick.Shapes
// import Quickshell
// import Quickshell.Io
// import "../"

// Item {
//     id: root

//     // --- Responsive Scaling Logic ---
//     Scaler {
//         id: scaler
//         // Uses the physical screen width so the popup scales synchronously
//         currentWidth: Screen.width
//     }
    
//     // Helper function scoped to the root Item for easy access
//     function s(val) { 
//         return scaler.s(val); 
//     }

//     // Theme Colors
//     MatugenColors { id: _theme }

//     // Theme Colors
//     readonly property color base: _theme.base
//     readonly property color surface0: _theme.surface0
//     readonly property color surface1: _theme.surface1
//     readonly property color surface2: _theme.surface2
//     readonly property color overlay0: _theme.overlay0
//     readonly property color overlay1: _theme.overlay1
//     readonly property color overlay2: _theme.overlay2
//     readonly property color text: _theme.text
//     readonly property color subtext0: _theme.subtext0
//     readonly property color subtext1: _theme.subtext1
//     readonly property color blue: _theme.blue
//     readonly property color sapphire: _theme.sapphire
//     readonly property color lavender: _theme.blue // Mapped to blue as Matugen template lacks lavender
//     readonly property color mauve: _theme.mauve
//     readonly property color pink: _theme.pink
//     readonly property color red: _theme.red
//     readonly property color yellow: _theme.yellow

//     // Data State Properties
//     property var musicData: {
//         "title": "Loading...", "artist": "", "status": "Stopped", "percent": 0,
//         "lengthStr": "00:00", "positionStr": "00:00", "timeStr": "--:-- / --:--",
//         "source": "Offline", "playerName": "", "blur": "", "grad": "",
//         "textColor": "#cdd6f4", "deviceIcon": "󰓃", "deviceName": "Speaker",
//         "artUrl": ""
//     }

//     property var eqData: {
//         "b1": 0, "b2": 0, "b3": 0, "b4": 0, "b5": 0,
//         "b6": 0, "b7": 0, "b8": 0, "b9": 0, "b10": 0,
//         "preset": "Flat", "pending": false
//     }

//     // Accumulators for Process standard output
//     property string accumulatedMusicOut: ""
//     property string accumulatedEqOut: ""

//     // UI State for debouncing the slider and play button
//     property bool userIsSeeking: false
//     property bool userToggledPlay: false
    
//     // ANTI-JITTER LOCK: Prevents background polling from reverting UI during processing
//     property real lastEqUpdate: 0

//     // Decoupled Global Animation States
//     property real catppuccinFlowOffset: 0
//     NumberAnimation on catppuccinFlowOffset {
//         from: 0; to: 1.0
//         duration: 8000 // Slowed down significantly for a graceful, constant flow
//         loops: Animation.Infinite
//         running: true
//     }

//     property real globalOrbitAngle: 0
//     NumberAnimation on globalOrbitAngle {
//         from: 0; to: Math.PI * 2
//         duration: 90000
//         loops: Animation.Infinite
//         running: true
//     }

//     // --- CANVAS LIGHTNING ANIMATION STATE ---
//     property real eqLightningProgress: 0.0
//     property real eqLightningFade: 1.0 // 1.0 = fully faded out

//     SequentialAnimation {
//         id: eqLightningAnim
//         running: false
//         ScriptAction { script: { root.eqLightningFade = 0.0; root.eqLightningProgress = 0.0; } }
//         NumberAnimation { 
//             target: root; property: "eqLightningProgress"; 
//             from: 0.0; to: 10.0; // 10 points = 9 segments
//             duration: 650; // Fast, snappy, energetic strike
//             easing.type: Easing.OutSine 
//         }
//         PauseAnimation { duration: 150 } // Hold the core flash at the end
//         NumberAnimation { 
//             target: root; property: "eqLightningFade"; 
//             from: 0.0; to: 1.0; 
//             duration: 800; // Smooth dissipation
//             easing.type: Easing.OutQuad 
//         }
//         ScriptAction { script: { root.eqLightningProgress = 0.0; } }
//     }

//     function triggerEqLightning() {
//         eqLightningAnim.restart();
//     }

//     // --- GLOBAL PLAY/PAUSE EVENT LISTENER ---
//     property string lastMusicStatus: "Stopped"
//     onMusicDataChanged: {
//         if (musicData && musicData.status && musicData.status !== lastMusicStatus) {
//             if (musicData.status === "Playing") {
//                 playPulse.trigger();
//             }
//             lastMusicStatus = musicData.status;
//         }
//     }

//     // --- ENHANCED STARTUP ANIMATION STATES ---
//     property real introMain: 0
//     property real introCover: 0
//     property real introText: 0
//     property real introControls: 0
//     property real introSeparator: 0
//     property real introEqHeader: 0
//     property real introEqSliders: 0
//     property real introPresets: 0

//     ParallelAnimation {
//         running: true

//         // 1. Base window fades, scales, and lifts smoothly (sped up by ~40ms)
//         NumberAnimation { target: root; property: "introMain"; from: 0; to: 1.0; duration: 760; easing.type: Easing.OutQuart }

//         // 2. Cover art snaps in with a premium elastic feel
//         SequentialAnimation {
//             PauseAnimation { duration: 70 }
//             NumberAnimation { target: root; property: "introCover"; from: 0; to: 1.0; duration: 810; easing.type: Easing.OutBack; easing.overshoot: 1.0 }
//         }

//         // 3. Text block glides in smoothly
//         SequentialAnimation {
//             PauseAnimation { duration: 150 }
//             NumberAnimation { target: root; property: "introText"; from: 0; to: 1.0; duration: 760; easing.type: Easing.OutQuart }
//         }

//         // 4. Progress bar and Media Controls bounce in
//         SequentialAnimation {
//             PauseAnimation { duration: 230 }
//             NumberAnimation { target: root; property: "introControls"; from: 0; to: 1.0; duration: 760; easing.type: Easing.OutBack; easing.overshoot: 0.8 }
//         }

//         // 5. Separator line drops and fades
//         SequentialAnimation {
//             PauseAnimation { duration: 310 }
//             NumberAnimation { target: root; property: "introSeparator"; from: 0; to: 1.0; duration: 660; easing.type: Easing.OutQuart }
//         }

//         // 6. EQ header follows down seamlessly
//         SequentialAnimation {
//             PauseAnimation { duration: 370 }
//             NumberAnimation { target: root; property: "introEqHeader"; from: 0; to: 1.0; duration: 710; easing.type: Easing.OutQuart }
//         }

//         // 7. EQ Sliders sweep up in a sequential waterfall wave
//         SequentialAnimation {
//             PauseAnimation { duration: 430 }
//             NumberAnimation { target: root; property: "introEqSliders"; from: 0; to: 1.0; duration: 860; easing.type: Easing.OutExpo }
//         }

//         // 8. Presets finish the orchestration with a final pop
//         SequentialAnimation {
//             PauseAnimation { duration: 550 }
//             NumberAnimation { target: root; property: "introPresets"; from: 0; to: 1.0; duration: 810; easing.type: Easing.OutBack; easing.overshoot: 0.8 }
//         }
//     }

//     // --- FIXED COLOR PARSING LOGIC ---
//     property var borderColors: {
//         var defaultColors = [root.mauve, root.blue, root.red, root.mauve];
//         if (!root.musicData || !root.musicData.grad) return defaultColors;
        
//         var hexRegex = /#[0-9a-fA-F]{6}/g;
//         var matches = root.musicData.grad.match(hexRegex);
        
//         if (matches && matches.length >= 3) {
//             return [matches[0], matches[1], matches[2], matches[0]]; // Wrap around for looping
//         }
//         return defaultColors;
//     }

//     // PROPER EXCEPTION-FREE FIX: Explicit bindings so GradientStop actually repaints
//     property color bc1: borderColors[0] || root.mauve
//     property color bc2: borderColors[1] || root.blue
//     property color bc3: borderColors[2] || root.red
//     property color bc4: borderColors[3] || root.mauve

//     property color dynamicTextColor: {
//         if (root.musicData && root.musicData.textColor) {
//             var c = String(root.musicData.textColor).trim();
//             // Securely extract exactly #RRGGBB, ignoring any alpha leak from the shell
//             var match = c.match(/^(#[0-9a-fA-F]{6})/);
//             if (match) return match[1];
//         }
//         return root.text;
//     }

//     // --- UTILITIES & OPTIMISTIC UPDATES ---
//     function execCmd(cmdStr) {
//         var safeCmd = cmdStr.replace(/`/g, "\\`");
//         var p = Qt.createQmlObject(`
//             import Quickshell.Io
//             Process {
//                 command: ["bash", "-c", \`${safeCmd}\`]
//                 running: true
//                 onExited: (exitCode) => destroy()
//             }
//         `, root);
//     }

//     function applyPresetOptimistically(presetName) {
//         var presets = {
//             "Flat": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
//             "Bass": [5, 7, 5, 2, 1, 0, 0, 0, 1, 2],
//             "Treble": [-2, -1, 0, 1, 2, 3, 4, 5, 6, 6],
//             "Vocal": [-2, -1, 1, 3, 5, 5, 4, 2, 1, 0],
//             "Pop": [2, 4, 2, 0, 1, 2, 4, 2, 1, 2],
//             "Rock": [5, 4, 2, -1, -2, -1, 2, 4, 5, 6],
//             "Jazz": [3, 3, 1, 1, 1, 1, 2, 1, 2, 3],
//             "Classic": [0, 1, 2, 2, 2, 2, 1, 2, 3, 4]
//         };
//         if (presets[presetName]) {
//             var temp = Object.assign({}, root.eqData);
//             for (var i = 0; i < 10; i++) {
//                 temp["b" + (i + 1)] = presets[presetName][i];
//             }
//             temp.preset = presetName;
//             temp.pending = false; 
//             root.eqData = temp; 
            
//             // Blind the polling process to stop it from fetching old data
//             root.lastEqUpdate = Date.now(); 
            
//             root.triggerEqLightning();
//             execCmd(`$HOME/.config/hypr/scripts/quickshell/music/equalizer.sh preset ${presetName}`);
//         }
//     }

//     // --- DATA POLLING ---
//     Timer {
//         id: seekDebounceTimer
//         interval: 2500 
//         onTriggered: root.userIsSeeking = false
//     }

//     Timer {
//         id: playDebounceTimer
//         interval: 1500
//         onTriggered: root.userToggledPlay = false
//     }

//     Timer {
//         interval: 500
//         running: true
//         repeat: true
//         triggeredOnStart: true
//         onTriggered: {
//             if (!musicProc.running) musicProc.running = true;
//             if (!eqProc.running) eqProc.running = true;
//         }
//     }

//     Process {
//         id: musicProc
//         running: true
//         command: ["bash", "-c", "$HOME/.config/hypr/scripts/quickshell/music/music_info.sh"]
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 if (this.text) {
//                     var outStr = this.text.trim();
//                     if (outStr.length > 0) {
//                         try { 
//                             var newData = JSON.parse(outStr); 
//                             if (root.userToggledPlay) {
//                                 newData.status = root.musicData.status; 
//                             }
//                             root.musicData = newData; 
//                         } catch(e) {}
//                     }
//                 }
//             }
//         }
//     }

//     Process {
//         id: eqProc
//         running: true
//         command: ["bash", "-c", "$HOME/.config/hypr/scripts/quickshell/music/equalizer.sh get"]
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 if (this.text) {
//                     // Ignore background data entirely if we recently pushed an optimistic update
//                     if (Date.now() - root.lastEqUpdate < 2000) return;

//                     var outStr = this.text.trim();
//                     if (outStr.length > 0) {
//                         try { root.eqData = JSON.parse(outStr); } catch(e) {}
//                     }
//                 }
//             }
//         }
//     }

//     // --- UI LAYOUT ---
//     Item {
//         id: mainWrapper
//         anchors.fill: parent
        
//         // Deepened scale effect and introduced a gentle Y-axis translation for the main container
//         scale: 0.92 + (0.08 * root.introMain)
//         opacity: root.introMain
//         transform: Translate { y: root.s(15) * (1 - root.introMain) }

//         // OUTER ANIMATED BORDER WITH PROPER CLIPPING
//         Item {
//             anchors.fill: parent

//             Shape {
//                 id: maskRectOuter
//                 anchors.fill: parent
//                 visible: false // Hidden because MultiEffect will render it as a mask
//                 layer.enabled: true
//                 preferredRendererType: Shape.GeometryRenderer // Fixes lag by hardware accelerating the stroke

//                 property real sw: root.s(6)
//                 property real inset: (sw / 2) + root.s(0.5) 
//                 property real w: width
//                 property real h: height
//                 property real r: root.s(14) - inset
                
//                 // Mathematical perimeter
//                 property real straightLines: 2 * (w - 2 * inset - 2 * r) + 2 * (h - 2 * inset - 2 * r)
//                 property real arcLines: 2 * Math.PI * r
//                 property real perimeter: straightLines + arcLines

//                 property real drawProgress: 0

//                 NumberAnimation on drawProgress {
//                     id: chargeAnim
//                     from: 0
//                     to: maskRectOuter.perimeter
//                     duration: 1200 // The time it takes to "charge" the whole wick
//                     easing.type: Easing.OutCubic
//                     running: true // Ensure it starts reliably
//                 }

//                 ShapePath {
//                     strokeWidth: maskRectOuter.sw
//                     strokeColor: "black" 
//                     fillColor: "transparent"
//                     capStyle: ShapePath.FlatCap 

//                     // QML Shape dash patterns are measured in units of strokeWidth! 
//                     dashPattern: [maskRectOuter.perimeter / maskRectOuter.sw, maskRectOuter.perimeter / maskRectOuter.sw]
//                     dashOffset: (maskRectOuter.perimeter - maskRectOuter.drawProgress) / maskRectOuter.sw

//                     // Start exactly at Bottom-Left corner, going UP clockwise
//                     startX: maskRectOuter.inset
//                     startY: maskRectOuter.h - maskRectOuter.inset - maskRectOuter.r

//                     // 1. Up to top-left corner
//                     PathLine { x: maskRectOuter.inset; y: maskRectOuter.inset + maskRectOuter.r }
//                     // 2. Arc top-left
//                     PathArc { 
//                         x: maskRectOuter.inset + maskRectOuter.r; y: maskRectOuter.inset 
//                         radiusX: maskRectOuter.r; radiusY: maskRectOuter.r; direction: PathArc.Clockwise 
//                     }
//                     // 3. Right to top-right corner
//                     PathLine { x: maskRectOuter.w - maskRectOuter.inset - maskRectOuter.r; y: maskRectOuter.inset }
//                     // 4. Arc top-right
//                     PathArc { 
//                         x: maskRectOuter.w - maskRectOuter.inset; y: maskRectOuter.inset + maskRectOuter.r 
//                         radiusX: maskRectOuter.r; radiusY: maskRectOuter.r; direction: PathArc.Clockwise 
//                     }
//                     // 5. Down to bottom-right corner
//                     PathLine { x: maskRectOuter.w - maskRectOuter.inset; y: maskRectOuter.h - maskRectOuter.inset - maskRectOuter.r }
//                     // 6. Arc bottom-right
//                     PathArc { 
//                         x: maskRectOuter.w - maskRectOuter.inset - maskRectOuter.r; y: maskRectOuter.h - maskRectOuter.inset 
//                         radiusX: maskRectOuter.r; radiusY: maskRectOuter.r; direction: PathArc.Clockwise 
//                     }
//                     // 7. Left to bottom-left corner
//                     PathLine { x: maskRectOuter.inset + maskRectOuter.r; y: maskRectOuter.h - maskRectOuter.inset }
//                     // 8. Arc bottom-left to finish
//                     PathArc { 
//                         x: maskRectOuter.inset; y: maskRectOuter.h - maskRectOuter.inset - maskRectOuter.r 
//                         radiusX: maskRectOuter.r; radiusY: maskRectOuter.r; direction: PathArc.Clockwise 
//                     }
//                 }
//             }

//             Item {
//                 id: gradContainer
//                 anchors.fill: parent
//                 visible: false // Hidden for MultiEffect mapping
//                 clip: true // Prevents the rotated gradient bounding box from bulging out the sides!

//                 Rectangle {
//                     width: Math.max(parent.width, parent.height) * 2
//                     height: width
//                     anchors.centerIn: parent
                    
//                     NumberAnimation on rotation {
//                         from: 0; to: 360; duration: 5000
//                         loops: Animation.Infinite
//                         running: true
//                     }

//                     gradient: Gradient {
//                         // FIXED: Using securely unpacked color bindings
//                         GradientStop { position: 0.0; color: root.bc1; Behavior on color { ColorAnimation { duration: 800; easing.type: Easing.InOutQuad } } }
//                         GradientStop { position: 0.33; color: root.bc2; Behavior on color { ColorAnimation { duration: 800; easing.type: Easing.InOutQuad } } }
//                         GradientStop { position: 0.66; color: root.bc3; Behavior on color { ColorAnimation { duration: 800; easing.type: Easing.InOutQuad } } }
//                         GradientStop { position: 1.0; color: root.bc4; Behavior on color { ColorAnimation { duration: 800; easing.type: Easing.InOutQuad } } }
//                     }
//                 }
//             }

//             MultiEffect {
//                 source: gradContainer
//                 anchors.fill: parent
//                 maskEnabled: true
//                 maskSource: maskRectOuter
//             }
//         }

//         // INNER WINDOW BOX
//         Rectangle {
//             id: innerBg
//             anchors.fill: parent
//             anchors.margins: root.s(3)
//             color: root.base
//             radius: root.s(10)

//             // FIX: This forces the entire background to render as a single hardware texture,
//             // preventing the UI from dragging and causing "shadow boxes" during the StackView transition!
//             layer.enabled: true

//             // Provide a perfectly rounded mask for the inner content
//             Rectangle {
//                 id: innerBgMask
//                 anchors.fill: parent
//                 radius: root.s(10)
//                 visible: false
                
//                 // FIX: Masks in MultiEffect strictly require layer.enabled to correctly capture the radius during scaling!
//                 layer.enabled: true 
//             }

//             Item {
//                 id: bgEffectsLayer
//                 anchors.fill: parent
                
//                 // This correctly clamps the blur and orbit circles to the 10px radius corners
//                 layer.enabled: true
//                 layer.effect: MultiEffect {
//                     maskEnabled: true
//                     maskSource: innerBgMask
//                 }

//                 // LAYER 1: Background Blur (Smooth fade-in)
//                 Image {
//                     anchors.fill: parent
//                     source: root.musicData.blur ? "file://" + root.musicData.blur : ""
//                     fillMode: Image.PreserveAspectCrop
                    
//                     // Fixed: Ensures blur is completely hidden when stopped so the pure base color matches the calendar
//                     opacity: (status === Image.Ready && root.musicData.status !== "Stopped" && root.musicData.status !== "Offline") ? 0.9 : 0.0
//                     Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.InOutQuad } }
//                 }

//                 // LAYER 1.5: Flowing Orbits
//                 Rectangle {
//                     width: parent.width * 0.8; height: width; radius: width / 2
//                     x: (parent.width / 2 - width / 2) + Math.cos(root.globalOrbitAngle * 2) * root.s(150)
//                     y: (parent.height / 2 - height / 2) + Math.sin(root.globalOrbitAngle * 2) * root.s(100)
                    
//                     // Fixed: Hides orbits when stopped
//                     opacity: root.musicData.status === "Playing" ? 0.08 : (root.musicData.status === "Paused" ? 0.04 : 0.0)
//                     color: root.musicData.status === "Playing" ? root.mauve : root.surface2
//                     Behavior on color { ColorAnimation { duration: 1000 } }
//                     Behavior on opacity { NumberAnimation { duration: 1000 } }
//                 }
                
//                 Rectangle {
//                     width: parent.width * 0.9; height: width; radius: width / 2
//                     x: (parent.width / 2 - width / 2) + Math.sin(root.globalOrbitAngle * 1.5) * root.s(-150)
//                     y: (parent.height / 2 - height / 2) + Math.cos(root.globalOrbitAngle * 1.5) * root.s(-100)
                    
//                     // Fixed: Hides orbits when stopped
//                     opacity: root.musicData.status === "Playing" ? 0.08 : (root.musicData.status === "Paused" ? 0.02 : 0.0)
//                     color: root.musicData.status === "Playing" ? root.blue : root.surface1
//                     Behavior on color { ColorAnimation { duration: 1000 } }
//                     Behavior on opacity { NumberAnimation { duration: 1000 } }
//                 }
//             }

//             // LAYER 2: UI Content
//             ColumnLayout {
//                 anchors.fill: parent
//                 anchors.margins: root.s(20)
//                 spacing: 0

//                 // ==========================================
//                 // TOP INFO SECTION
//                 // ==========================================
//                 RowLayout {
//                     Layout.fillWidth: true
//                     Layout.preferredHeight: root.s(220)
//                     spacing: root.s(25)

//                     // Cover Art Wrapper
//                     Item {
//                         Layout.preferredWidth: root.s(220)
//                         Layout.preferredHeight: root.s(220)
//                         Layout.alignment: Qt.AlignVCenter

//                         opacity: root.introCover
//                         // Enhanced 2D drift animation
//                         transform: Translate { x: root.s(-40) * (1 - root.introCover); y: root.s(10) * (1 - root.introCover) }

//                         // Elastic response to play/pause state
//                         scale: root.musicData.status === "Playing" ? 1.0 : 0.90
//                         Behavior on scale { NumberAnimation { duration: 800; easing.type: Easing.OutElastic; easing.overshoot: 1.2 } }

//                         Rectangle {
//                             anchors.fill: parent
//                             radius: root.s(110)
//                             color: root.surface1
//                             border.width: root.s(4)
//                             border.color: root.musicData.status === "Playing" ? root.mauve : root.overlay0
//                             Behavior on border.color { ColorAnimation { duration: 500 } }

//                             // Glow Effect surrounding the thumbnail
//                             Rectangle {
//                                 z: -1
//                                 anchors.centerIn: parent
//                                 width: parent.width + root.s(20)
//                                 height: parent.height + root.s(20)
//                                 radius: width / 2
//                                 color: root.mauve
//                                 opacity: root.musicData.status === "Playing" ? 0.5 : 0.0
//                                 Behavior on opacity { NumberAnimation { duration: 500 } }
//                                 layer.enabled: true
//                                 layer.effect: MultiEffect {
//                                     blurEnabled: true
//                                     blurMax: 32
//                                     blur: 1.0
//                                 }
//                             }

//                             Item {
//                                 anchors.fill: parent
//                                 anchors.margins: root.s(4)
//                                 Image {
//                                     id: artImg
//                                     anchors.fill: parent
//                                     source: root.musicData.artUrl ? "file://" + root.musicData.artUrl : ""
//                                     fillMode: Image.PreserveAspectCrop
//                                     visible: false 
//                                 }
//                                 Rectangle {
//                                     id: maskRect
//                                     anchors.fill: parent
//                                     radius: width / 2
//                                     visible: false
//                                     layer.enabled: true 
//                                 }
//                                 MultiEffect {
//                                     anchors.fill: parent
//                                     source: artImg
//                                     maskEnabled: true
//                                     maskSource: maskRect
//                                     opacity: artImg.status === Image.Ready ? 1.0 : 0.0
//                                     Behavior on opacity { NumberAnimation { duration: 800 } }
//                                 }
                                
//                                 // NEW: Dimmed slightly by tinting with the primary mauve accent, as requested
//                                 Rectangle {
//                                     anchors.fill: parent
//                                     radius: width / 2
//                                     color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.2)
//                                     opacity: artImg.status === Image.Ready ? 1.0 : 0.0
//                                     Behavior on opacity { NumberAnimation { duration: 800 } }
//                                 }

//                                 Rectangle {
//                                     width: root.s(40); height: root.s(40)
//                                     radius: root.s(20); color: "#000000"
//                                     opacity: 0.8; anchors.centerIn: parent
//                                 }
//                             }
                            
//                             NumberAnimation on rotation {
//                                 from: 0; to: 360; duration: 8000
//                                 loops: Animation.Infinite
//                                 running: true
//                                 paused: root.musicData.status !== "Playing"
//                             }
//                         }
//                     }

//                     ColumnLayout {
//                         Layout.fillWidth: true
//                         Layout.alignment: Qt.AlignVCenter
//                         spacing: root.s(15)

//                         // TEXT INFO CHUNK
//                         ColumnLayout {
//                             spacing: root.s(6)
//                             opacity: root.introText
//                             transform: Translate { x: root.s(30) * (1 - root.introText) }
                            
//                             // HARD-LOCKED SEAMLESS INFINITE MARQUEE
//                             Item {
//                                 id: titleClipRect
//                                 Layout.fillWidth: true
//                                 Layout.preferredHeight: root.s(28) 
//                                 clip: true

//                                 // This is the distance between the end of the text and the clone
//                                 property int marqueeSpacing: root.s(60)

//                                 Item {
//                                     id: marqueeContainer
//                                     height: parent.height

//                                     Row {
//                                         spacing: titleClipRect.marqueeSpacing
//                                         Text {
//                                             id: titleTextMain
//                                             text: root.musicData.title
//                                             color: root.dynamicTextColor
//                                             font.family: "JetBrains Mono"
//                                             font.pixelSize: root.s(20)
//                                             font.bold: true
//                                             Behavior on color { ColorAnimation { duration: 600 } }

//                                             // Only animate if the text is physically wider than our container
//                                             onTextChanged: {
//                                                 marqueeContainer.x = 0;
//                                                 if (implicitWidth > titleClipRect.width) {
//                                                     titleAnim.restart();
//                                                 } else {
//                                                     titleAnim.stop();
//                                                 }
//                                             }
//                                         }
//                                         // The clone that creates the seamless endless loop
//                                         Text {
//                                             id: titleTextClone
//                                             text: root.musicData.title
//                                             color: root.dynamicTextColor
//                                             font.family: "JetBrains Mono"
//                                             font.pixelSize: root.s(20)
//                                             font.bold: true
//                                             visible: titleTextMain.implicitWidth > titleClipRect.width
//                                         }
//                                     }

//                                     SequentialAnimation on x {
//                                         id: titleAnim
//                                         loops: Animation.Infinite
//                                         running: titleTextMain.implicitWidth > titleClipRect.width

//                                         // 1. Stop for a few seconds in the initial position
//                                         PauseAnimation { duration: 3000 }
                                        
//                                         // 2. Smoothly run left until the clone is exactly where the original started
//                                         NumberAnimation {
//                                             from: 0
//                                             to: -(titleTextMain.implicitWidth + titleClipRect.marqueeSpacing)
//                                             // The duration calculates dynamically to maintain a constant scroll speed
//                                             duration: (titleTextMain.implicitWidth + titleClipRect.marqueeSpacing) * 25
//                                         }
                                        
//                                         // 3. Instantly snap back to 0 without stopping (creating the seamless loop)
//                                         PropertyAction { target: marqueeContainer; property: "x"; value: 0 }
//                                     }
//                                 }
//                             }

//                             Text {
//                                 text: root.musicData.artist ? "BY " + root.musicData.artist : ""
//                                 color: root.subtext0 // Better matugen match
//                                 font.family: "JetBrains Mono"
//                                 font.pixelSize: root.s(14)
//                                 font.bold: true
//                                 elide: Text.ElideRight
//                                 maximumLineCount: 1 // Strict 1 line
//                                 Layout.fillWidth: true
//                                 Layout.preferredHeight: root.s(20)
//                             }
//                             RowLayout {
//                                 spacing: root.s(10)
//                                 Rectangle {
//                                     color: "#1AFFFFFF"
//                                     radius: root.s(4)
//                                     Layout.preferredHeight: root.s(24)
//                                     Layout.preferredWidth: pillContent.width + root.s(20)
//                                     RowLayout {
//                                         id: pillContent
//                                         anchors.centerIn: parent
//                                         spacing: root.s(6)
//                                         Text { text: root.musicData.deviceIcon || "󰓃"; color: root.mauve; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(14) }
//                                         Text { text: root.musicData.deviceName || "Speaker"; color: root.overlay2; font.family: "JetBrains Mono"; font.pixelSize: root.s(12); font.bold: true }
//                                     }
//                                 }
//                                 Text {
//                                     text: "VIA " + (root.musicData.source || "Offline")
//                                     color: root.overlay2 // Better matugen match
//                                     font.family: "JetBrains Mono"
//                                     font.pixelSize: root.s(12)
//                                     font.bold: true
//                                     font.italic: true
//                                 }
//                             }
//                         }

//                         // PROGRESS AREA CHUNK
//                         ColumnLayout {
//                             Layout.fillWidth: true
//                             spacing: root.s(5)
//                             opacity: root.introControls
//                             transform: Translate { x: root.s(20) * (1 - root.introControls); y: root.s(10) * (1 - root.introControls) }

//                             Slider {
//                                 id: progBar
//                                 Layout.fillWidth: true
//                                 Layout.preferredHeight: root.s(20) 
//                                 from: 0; to: 100

//                                 Connections {
//                                     target: root
//                                     function onMusicDataChanged() {
//                                         if (!progBar.pressed && !root.userIsSeeking) {
//                                             if (root.musicData && root.musicData.percent !== undefined) {
//                                                 var p = Number(root.musicData.percent);
//                                                 if (!isNaN(p)) progBar.value = p;
//                                             }
//                                         }
//                                     }
//                                 }

//                                 Behavior on value {
//                                     enabled: !progBar.pressed && !root.userIsSeeking
//                                     NumberAnimation { duration: 400; easing.type: Easing.OutSine }
//                                 }

//                                 onPressedChanged: {
//                                     if (pressed) {
//                                         root.userIsSeeking = true;
//                                         seekDebounceTimer.stop();
//                                     } else {
//                                         var temp = Object.assign({}, root.musicData);
//                                         temp.percent = value;
//                                         root.musicData = temp;

//                                         var safePlayer = root.musicData.playerName ? root.musicData.playerName : "";
//                                         root.execCmd(`$HOME/.config/hypr/scripts/quickshell/music/player_control.sh seek ${value.toFixed(2)} ${root.musicData.length} "${safePlayer}"`);
                                        
//                                         seekDebounceTimer.restart();
//                                     }
//                                 }

//                                 background: Item {
//                                     x: progBar.leftPadding
//                                     y: progBar.topPadding + (progBar.availableHeight - root.s(12)) / 2
//                                     width: progBar.availableWidth
//                                     height: root.s(12)

//                                     // Shadows mimicking the EQ slider background
//                                     Rectangle {
//                                         anchors.fill: parent
//                                         radius: root.s(6)
//                                         // Dynamic tint: surface0 with 70% opacity for a softer dark look
//                                         color: Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.7)

//                                         layer.enabled: true
//                                         layer.effect: MultiEffect {
//                                             shadowEnabled: true
//                                             shadowColor: "#000000"
//                                             shadowOpacity: 0.9
//                                             shadowBlur: 0.5
//                                             shadowVerticalOffset: 1
//                                         }
//                                     }

//                                     // Masked Gradient Fill (Completely redesigned for smooth, light, synergistic palette)
//                                     Item {
//                                         width: progBar.handle.x - progBar.leftPadding + (progBar.handle.width / 2)
//                                         height: parent.height
                                        
//                                         layer.enabled: true
//                                         layer.effect: MultiEffect {
//                                             maskEnabled: true
//                                             maskSource: sliderFillMask
//                                         }

//                                         Rectangle {
//                                             id: sliderFillMask
//                                             width: parent.width
//                                             height: parent.height
//                                             radius: root.s(6)
//                                             visible: false
//                                             layer.enabled: true 
//                                         }

//                                         Rectangle {
//                                             width: root.s(2000)
//                                             height: parent.height
//                                             // Sliding the gradient perfectly by exactly half its width (1000px)
//                                             x: -(root.catppuccinFlowOffset * root.s(1000)) 
//                                             gradient: Gradient {
//                                                 orientation: Gradient.Horizontal
//                                                 // Mathematically precise loops with lighter, cooler colors & theme change support
//                                                 GradientStop { position: 0.0000; color: Qt.lighter(root.blue, 1.2); Behavior on color { ColorAnimation { duration: 800 } } }
//                                                 GradientStop { position: 0.1666; color: Qt.lighter(root.sapphire, 1.15); Behavior on color { ColorAnimation { duration: 800 } } }
//                                                 GradientStop { position: 0.3333; color: Qt.lighter(root.mauve, 1.15); Behavior on color { ColorAnimation { duration: 800 } } }
//                                                 GradientStop { position: 0.5000; color: Qt.lighter(root.blue, 1.2); Behavior on color { ColorAnimation { duration: 800 } } }
//                                                 GradientStop { position: 0.6666; color: Qt.lighter(root.sapphire, 1.15); Behavior on color { ColorAnimation { duration: 800 } } }
//                                                 GradientStop { position: 0.8333; color: Qt.lighter(root.mauve, 1.15); Behavior on color { ColorAnimation { duration: 800 } } }
//                                                 GradientStop { position: 1.0000; color: Qt.lighter(root.blue, 1.2); Behavior on color { ColorAnimation { duration: 800 } } }
//                                             }
//                                         }
//                                     }
//                                 }

//                                 handle: Rectangle {
//                                     x: progBar.leftPadding + progBar.visualPosition * (progBar.availableWidth - width)
//                                     y: progBar.topPadding + (progBar.availableHeight - height) / 2
//                                     implicitWidth: root.s(18) 
//                                     implicitHeight: root.s(18)
//                                     width: root.s(18); height: root.s(18)
//                                     radius: root.s(9); color: root.text
//                                     scale: progBar.pressed ? 1.3 : 1.0
//                                     Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
//                                 }
//                             }

//                             RowLayout {
//                                 Layout.fillWidth: true
//                                 Text { text: root.musicData.positionStr || "00:00"; color: root.overlay2; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: root.s(13) }
//                                 Item { Layout.fillWidth: true }
//                                 Text { text: root.musicData.lengthStr || "00:00"; color: root.overlay2; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: root.s(13) }
//                             }
//                         }

//                         // MEDIA CONTROLS CHUNK
//                         RowLayout {
//                             Layout.alignment: Qt.AlignHCenter
//                             spacing: root.s(30)
//                             opacity: root.introControls
//                             transform: Translate { y: root.s(20) * (1 - root.introControls) }

//                             MouseArea {
//                                 width: root.s(30); height: root.s(30)
//                                 cursorShape: Qt.PointingHandCursor
//                                 onClicked: root.execCmd("playerctl previous")
//                                 Text { anchors.centerIn: parent; text: ""; color: parent.pressed ? root.text : root.overlay2; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(24) }
//                             }
//                             MouseArea {
//                                 id: playPauseBtn
//                                 width: root.s(50); height: root.s(50)
//                                 cursorShape: Qt.PointingHandCursor
//                                 onClicked: {
//                                     root.userToggledPlay = true;
//                                     playDebounceTimer.restart();
//                                     var temp = Object.assign({}, root.musicData);
//                                     temp.status = (temp.status === "Playing" ? "Paused" : "Playing");
//                                     root.musicData = temp;
//                                     root.execCmd("playerctl play-pause");
//                                 }

//                                 // Fluid Ripple Animation Element
//                                 Rectangle {
//                                     id: playPulse
//                                     anchors.centerIn: parent
//                                     width: parent.width
//                                     height: parent.height
//                                     radius: width / 2
//                                     color: root.mauve
//                                     opacity: 0
//                                     scale: 1

//                                     NumberAnimation {
//                                         id: playPulseScaleAnim
//                                         target: playPulse
//                                         property: "scale"
//                                         from: 1.0; to: 1.8
//                                         duration: 500
//                                         easing.type: Easing.OutQuart
//                                     }
//                                     NumberAnimation {
//                                         id: playPulseFadeAnim
//                                         target: playPulse
//                                         property: "opacity"
//                                         from: 0.5; to: 0.0
//                                         duration: 500
//                                         easing.type: Easing.OutQuart
//                                     }

//                                     function trigger() {
//                                         playPulseScaleAnim.restart();
//                                         playPulseFadeAnim.restart();
//                                     }
//                                 }

//                                 Text { 
//                                     anchors.centerIn: parent
//                                     text: root.musicData.status === "Playing" ? "" : ""
//                                     color: parent.pressed ? root.pink : root.mauve
//                                     font.family: "Iosevka Nerd Font"
//                                     font.pixelSize: root.s(42) 
//                                     scale: parent.pressed ? 0.8 : 1.0
//                                     Behavior on color { ColorAnimation { duration: 150 } }
//                                     Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
//                                 }
//                             }
//                             MouseArea {
//                                 width: root.s(30); height: root.s(30)
//                                 cursorShape: Qt.PointingHandCursor
//                                 onClicked: root.execCmd("playerctl next")
//                                 Text { anchors.centerIn: parent; text: ""; color: parent.pressed ? root.text : root.overlay2; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(24) }
//                             }
//                         }
//                     }
//                 }

//                 // ==========================================
//                 // SEPARATOR
//                 // ==========================================
//                 Rectangle {
//                     Layout.fillWidth: true
//                     Layout.preferredHeight: root.s(2)
//                     Layout.topMargin: root.s(20)
//                     Layout.bottomMargin: root.s(20)
//                     color: "#1AFFFFFF"
//                     radius: root.s(1)

//                     opacity: root.introSeparator
//                     transform: Translate { y: root.s(15) * (1 - root.introSeparator) }
//                 }

//                 // ==========================================
//                 // EQUALIZER
//                 // ==========================================
//                 ColumnLayout {
//                     Layout.fillWidth: true
//                     spacing: root.s(15)

//                     // Header Row
//                     RowLayout {
//                         Layout.fillWidth: true
//                         opacity: root.introEqHeader
//                         transform: Translate { y: root.s(15) * (1 - root.introEqHeader) }

//                         Text { text: "Equalizer"; color: root.mauve; font.family: "JetBrains Mono"; font.pixelSize: root.s(16); font.bold: true; Layout.fillWidth: true }
                        
//                         // Redesigned Apply Button
//                         Rectangle {
//                             Layout.preferredHeight: root.s(28)
//                             Layout.preferredWidth: applyTxt.width + root.s(30)
//                             radius: root.s(10)
//                             color: root.eqData.pending ? root.mauve : root.surface1
//                             border.color: root.eqData.pending ? root.mauve : root.surface2
//                             border.width: 1
                            
//                             Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutCubic } }
//                             Behavior on border.color { ColorAnimation { duration: 300; easing.type: Easing.OutCubic } }

//                             layer.enabled: root.eqData.pending
//                             layer.effect: MultiEffect {
//                                 shadowEnabled: true; shadowColor: root.mauve; shadowOpacity: 0.4; shadowBlur: 0.6
//                             }

//                             Text {
//                                 id: applyTxt
//                                 anchors.centerIn: parent
//                                 text: root.eqData.pending ? "Apply" : "Saved"
//                                 color: root.eqData.pending ? root.base : root.subtext0
//                                 font.family: "JetBrains Mono"
//                                 font.pixelSize: root.s(12)
//                                 font.bold: true
//                                 Behavior on color { ColorAnimation { duration: 300 } }
//                             }
//                             MouseArea {
//                                 anchors.fill: parent
//                                 cursorShape: root.eqData.pending ? Qt.PointingHandCursor : Qt.ArrowCursor
//                                 onClicked: {
//                                     if (root.eqData.pending) {
//                                         var temp = Object.assign({}, root.eqData);
//                                         temp.pending = false;
//                                         root.eqData = temp;
                                        
//                                         // Blind the polling process to stop it from fetching old data
//                                         root.lastEqUpdate = Date.now(); 
                                        
//                                         root.triggerEqLightning();
//                                         root.execCmd("$HOME/.config/hypr/scripts/quickshell/music/equalizer.sh apply");
//                                     }
//                                 }
//                             }
//                         }
//                         Text { text: root.eqData.preset || "Flat"; color: root.subtext0; font.family: "JetBrains Mono"; font.pixelSize: root.s(14); font.bold: true; Layout.leftMargin: root.s(15) }
//                     }

//                     // Eq Sliders Container with Canvas Lightning Overlay
//                     Item {
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: root.s(180)

//                         Row {
//                             id: eqSliderRow
//                             anchors.fill: parent
//                             z: 1 // Ensures sliders (and their handles) render over the lightning

//                             Repeater {
//                                 model: [
//                                     {"idx": 1, "lbl": "31"}, {"idx": 2, "lbl": "63"}, {"idx": 3, "lbl": "125"},
//                                     {"idx": 4, "lbl": "250"}, {"idx": 5, "lbl": "500"}, {"idx": 6, "lbl": "1k"},
//                                     {"idx": 7, "lbl": "2k"}, {"idx": 8, "lbl": "4k"}, {"idx": 9, "lbl": "8k"},
//                                     {"idx": 10, "lbl": "16k"}
//                                 ]
//                                 delegate: Item {
//                                     id: sliderDelegate
//                                     width: eqSliderRow.width / 10 
//                                     height: eqSliderRow.height

//                                     // --- ENHANCED SLIDER CASCADING ANIMATION ---
//                                     opacity: root.introEqSliders
//                                     transform: Translate {
//                                         y: root.s(30) * (1 - root.introEqSliders) + (index * root.s(8) * (1 - root.introEqSliders))
//                                     }

//                                     // Mathematical evaluation mapping to the exact timeline of the strike
//                                     property real dist: root.eqLightningProgress - (modelData.idx - 1)
//                                     property real hitPulse: dist >= 0 && dist < 1.0 ? Math.sin((dist) * Math.PI) : 0.0
                                    
//                                     // Massive Energy Pulses
//                                     property real trackPulse: 0.0
//                                     property real ringPulse: 0.0
//                                     property real flashFade: 0.0
//                                     property bool hasFired: false

//                                     onDistChanged: {
//                                         // Reset the fire lock when the animation sweeps past or starts over
//                                         if (dist <= 0.05) {
//                                             hasFired = false;
//                                         } else if (dist > 0.4 && !hasFired) {
//                                             // Trigger strictly once per bolt passing over
//                                             hasFired = true;
//                                             trackPulseAnim.restart();
//                                             ringPulseAnim.restart();
//                                             flashFadeAnim.restart();
//                                         }
//                                     }

//                                     SequentialAnimation {
//                                         id: trackPulseAnim
//                                         // Animates the bolt perfectly down the track
//                                         NumberAnimation { target: sliderDelegate; property: "trackPulse"; from: 0.0; to: 1.0; duration: 1000; easing.type: Easing.OutQuart }
//                                     }
//                                     SequentialAnimation {
//                                         id: ringPulseAnim
//                                         // Explodes outward creating a physical shockwave
//                                         NumberAnimation { target: sliderDelegate; property: "ringPulse"; from: 1.0; to: 0.0; duration: 1500; easing.type: Easing.OutExpo }
//                                     }
//                                     SequentialAnimation {
//                                         id: flashFadeAnim
//                                         // Slowly cools the inner track gradient back to normal
//                                         NumberAnimation { target: sliderDelegate; property: "flashFade"; from: 1.0; to: 0.0; duration: 1500; easing.type: Easing.OutSine }
//                                     }

//                                     ColumnLayout {
//                                         anchors.fill: parent
//                                         spacing: root.s(5)
//                                         Slider {
//                                             id: eqSlider
//                                             Layout.fillHeight: true
//                                             Layout.alignment: Qt.AlignHCenter
//                                             orientation: Qt.Vertical
//                                             from: -12; to: 12
//                                             stepSize: 1

//                                             Connections {
//                                                 target: root
//                                                 function onEqDataChanged() {
//                                                     if (!eqSlider.pressed) {
//                                                         if (root.eqData && root.eqData["b" + modelData.idx] !== undefined) {
//                                                             var p = Number(root.eqData["b" + modelData.idx]);
//                                                             if (!isNaN(p)) eqSlider.value = p;
//                                                         }
//                                                     }
//                                                 }
//                                             }

//                                             Behavior on value {
//                                                 enabled: !eqSlider.pressed
//                                                 NumberAnimation {
//                                                     duration: 350
//                                                     easing.type: Easing.OutQuart
//                                                 }
//                                             }

//                                             onPressedChanged: {
//                                                 if (!pressed) {
//                                                     var temp = Object.assign({}, root.eqData);
//                                                     temp["b" + modelData.idx] = Math.round(value);
//                                                     temp.preset = "Custom";
//                                                     temp.pending = true;
//                                                     root.eqData = temp;
                                                    
//                                                     // Set lock here too to protect individual slider tweaks
//                                                     root.lastEqUpdate = Date.now();
                                                    
//                                                     root.execCmd(`$HOME/.config/hypr/scripts/quickshell/music/equalizer.sh set_band ${modelData.idx} ${Math.round(value)}`);
//                                                 }
//                                             }

//                                             background: Rectangle {
//                                                 id: trackBg
//                                                 x: eqSlider.leftPadding + (eqSlider.availableWidth - width) / 2
//                                                 y: eqSlider.topPadding
//                                                 implicitWidth: root.s(10) 
//                                                 implicitHeight: root.s(150)
//                                                 width: root.s(10); height: eqSlider.availableHeight
//                                                 radius: root.s(4); 
                                                
//                                                 // Dynamic tint: surface0 with 70% opacity for a softer dark look
//                                                 color: Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.7)

//                                                 layer.enabled: true
//                                                 layer.effect: MultiEffect {
//                                                     id: trackEffect
//                                                     shadowEnabled: true
//                                                     shadowColor: "#000000"
//                                                     shadowOpacity: 0.9
//                                                     shadowBlur: 0.5
//                                                     shadowVerticalOffset: 1
//                                                 }

//                                                 // MASSIVE Outer Energy Shockwave Ring 
//                                                 Rectangle {
//                                                     z: -1
//                                                     anchors.centerIn: parent
//                                                     width: parent.width + root.s(20) + sliderDelegate.ringPulse * root.s(40)
//                                                     height: parent.height + root.s(20) + sliderDelegate.ringPulse * root.s(60)
//                                                     radius: parent.radius + root.s(10) + sliderDelegate.ringPulse * root.s(20)
//                                                     color: "transparent"
//                                                     border.color: root.mauve
//                                                     border.width: root.s(2) + sliderDelegate.ringPulse * root.s(4)
//                                                     opacity: sliderDelegate.ringPulse * 0.8 * (1.0 - root.eqLightningFade)
                                                    
//                                                     layer.enabled: true
//                                                     layer.effect: MultiEffect { blurEnabled: true; blurMax: 32; blur: 1.0 }
//                                                 }

//                                                 // The Track Fill Base (FIXED THE SQUARE CORNERS ISSUE)
//                                                 Item {
//                                                     width: parent.width
//                                                     height: (1 - eqSlider.visualPosition) * parent.height
//                                                     y: eqSlider.visualPosition * parent.height
                                                    
//                                                     layer.enabled: true
//                                                     layer.effect: MultiEffect {
//                                                         maskEnabled: true
//                                                         maskSource: eqFillMask
//                                                     }

//                                                     Rectangle {
//                                                         id: eqFillMask
//                                                         anchors.fill: parent
//                                                         radius: root.s(4)
//                                                         visible: false
//                                                         layer.enabled: true 
//                                                     }

//                                                     Rectangle {
//                                                         anchors.fill: parent
//                                                         color: root.blue

//                                                         // Track Override: Changes entire gradient of track
//                                                         Rectangle {
//                                                             anchors.fill: parent
//                                                             opacity: sliderDelegate.flashFade
//                                                             gradient: Gradient {
//                                                                 orientation: Gradient.Vertical
//                                                                 GradientStop { position: 0.0; color: root.mauve }
//                                                                 GradientStop { position: 0.5; color: root.blue }
//                                                                 GradientStop { position: 1.0; color: "transparent" }
//                                                             }
//                                                         }

//                                                         // The Internal Charging Surge Bolt 
//                                                         Rectangle {
//                                                             width: parent.width
//                                                             height: root.s(80) // Massive physical bolt
//                                                             y: (sliderDelegate.trackPulse * (parent.height + height)) - height
//                                                             opacity: Math.sin(sliderDelegate.trackPulse * Math.PI) * 2.0 * (1.0 - root.eqLightningFade)
                                                            
//                                                             gradient: Gradient {
//                                                                 orientation: Gradient.Vertical
//                                                                 GradientStop { position: 0.0; color: "transparent" }
//                                                                 GradientStop { position: 0.2; color: root.blue }
//                                                                 GradientStop { position: 0.5; color: root.text } // Theme integrated bright center
//                                                                 GradientStop { position: 0.8; color: root.mauve }
//                                                                 GradientStop { position: 1.0; color: "transparent" }
//                                                             }
                                                            
//                                                             layer.enabled: true
//                                                             layer.effect: MultiEffect {
//                                                                 shadowEnabled: true; shadowColor: root.blue; shadowBlur: 1.0; shadowOpacity: 1.0
//                                                             }
//                                                         }
//                                                     }
//                                                 }
//                                             }

//                                             handle: Rectangle {
//                                                 x: eqSlider.leftPadding + (eqSlider.availableWidth - width) / 2
//                                                 y: eqSlider.topPadding + eqSlider.visualPosition * (eqSlider.availableHeight - height)
//                                                 implicitWidth: root.s(18)
//                                                 implicitHeight: root.s(18)
//                                                 width: root.s(18); height: root.s(18)
//                                                 radius: root.s(9); color: root.text

//                                                 property var catColors: [root.mauve, root.pink, root.lavender, root.mauve, root.blue]

//                                                 // Core glow flare that cleanly fades out matching the canvas
//                                                 Rectangle {
//                                                     anchors.centerIn: parent
//                                                     width: parent.width + root.s(36) * sliderDelegate.hitPulse // Bigger bloom
//                                                     height: width
//                                                     radius: width / 2
//                                                     color: parent.catColors[index % parent.catColors.length]
//                                                     opacity: sliderDelegate.hitPulse * (1.0 - root.eqLightningFade)
//                                                     layer.enabled: true
//                                                     layer.effect: MultiEffect { blurEnabled: true; blurMax: 32; blur: 1.0 }
//                                                 }

//                                                 // Pop the handle itself slightly as the beam passes
//                                                 scale: 1.0 + (sliderDelegate.hitPulse * 0.4 * (1.0 - root.eqLightningFade))
//                                             }
//                                         }
//                                         Text {
//                                             text: modelData.lbl
//                                             color: root.overlay1
//                                             font.family: "JetBrains Mono"
//                                             font.pixelSize: root.s(10)
//                                             font.bold: true
//                                             Layout.alignment: Qt.AlignHCenter
//                                         }
//                                     }
//                                 }
//                             }
//                         }

//                         // --- THE FLUID CANVAS LIGHTNING (Optimized for Realism and multiple waves) ---
//                         Canvas {
//                             id: lightningCanvas
//                             anchors.fill: parent
//                             opacity: 1.0 - root.eqLightningFade
//                             z: 0 // Draw securely behind the sliders

//                             // Force hardware FBO backend instead of slow software rendering
//                             renderTarget: Canvas.FramebufferObject 

//                             // GPU Layer effect to provide bloom WITHOUT locking up the CPU via ctx.shadowBlur
//                             layer.enabled: true
//                             layer.effect: MultiEffect {
//                                 shadowEnabled: true
//                                 shadowColor: root.mauve
//                                 shadowBlur: 1.0 // 1.0 is max blur in MultiEffect
//                                 shadowOpacity: 0.6
//                                 shadowVerticalOffset: 0
//                                 shadowHorizontalOffset: 0
//                             }

//                             Timer {
//                                 interval: 16 // ~60fps for silky smooth arcs
//                                 running: root.eqLightningFade < 1.0 && root.eqLightningProgress > 0.0
//                                 repeat: true
//                                 onTriggered: lightningCanvas.requestPaint()
//                             }

//                             onPaint: {
//                                 var ctx = getContext("2d");
//                                 ctx.clearRect(0, 0, width, height);

//                                 if (root.eqLightningProgress <= 0.0 || root.eqLightningFade >= 1.0) return;

//                                 var time = Date.now() / 1000;
//                                 var maxIdx = root.eqLightningProgress; // 0 to 9

//                                 ctx.lineJoin = "round";
//                                 ctx.lineCap = "round";

//                                 // Step 1: Map the spatial coordinates of the 10 handles
//                                 var pts = [];
//                                 for (var i = 1; i <= 10; i++) {
//                                     var val = root.eqData["b" + i] !== undefined ? Number(root.eqData["b" + i]) : 0;
//                                     var norm = 1.0 - ((val + 12) / 24);
                                    
//                                     // Py uses margins rough mapping to the handles visible track
//                                     var py = root.s(10) + norm * (height - root.s(35)); 
//                                     var px = (i - 0.5) * (width / 10);
//                                     pts.push({ x: px, y: py });
//                                 }

//                                 // Step 2: Draw the multi-wave arcing structure
//                                 // Strand 0: Slow erratic mauve glow/wave
//                                 // Strand 1: Complex pink glow
//                                 // Strand 2: Crackling secondary core
//                                 // Strand 3: Hot white center core
//                                 for (var s = 0; s < 4; s++) { 
//                                     ctx.beginPath();
//                                     ctx.moveTo(pts[0].x, pts[0].y);

//                                     for (var i = 0; i < pts.length - 1; i++) {
//                                         if (i > maxIdx) break; // Stop drawing ahead of current progress

//                                         var p1 = pts[i];
//                                         var p2 = pts[i+1];

//                                         var fraction = 1.0;
//                                         if (maxIdx < i + 1) {
//                                             fraction = maxIdx - i;
//                                         }

//                                         // Subdivision steps create the crackle noise
//                                         var steps = s === 3 ? 6 : 8; // Ultra smooth subdivision, s=3 core has less subdiv for straighter look
//                                         for (var j = 1; j <= steps; j++) {
//                                             var t = j / steps;
//                                             if (t > fraction) t = fraction;

//                                             var cx = p1.x + (p2.x - p1.x) * t;
//                                             var cy = p1.y + (p2.y - p1.y) * t;

//                                             // Wave calculations: create distinct arcs and noise branching
//                                             var envelope = Math.sin(t * Math.PI);

//                                             // s=3 core noise (straightest) to s=0 outer glow noise (most waves)
//                                             var noiseAmpX = s === 3 ? 1.0 : (4 - s) * 4; 
//                                             var noiseAmpY = s === 3 ? 1.0 : (4 - s) * 5; 
                                            
//                                             // Combine multiple frequencies for complex branching/crackle appearance
//                                             // Glow strands (0, 1) also get a sweeping sine wave applied to create distinct separating waves
//                                             var sepWaveX = (s < 2) ? Math.sin(time * 3 + i + j + s) * root.s(10) * envelope : 0;
//                                             var sepWaveY = (s < 2) ? Math.cos(time * 2.5 + i - j - s) * root.s(15) * envelope : 0;

//                                             // Primary erratic crackle noise using high frequency combined sine/cos
//                                             var noiseX = Math.sin(time * (10+s) + i + j) * Math.cos(time * 8 - i + j) * noiseAmpX * envelope * (1 - root.eqLightningFade);
//                                             var noiseY = Math.cos(time * (9-s) + i - j) * Math.sin(time * 7 + i - j) * noiseAmpY * envelope * (1 - root.eqLightningFade);

//                                             ctx.lineTo(cx + sepWaveX + noiseX, cy + sepWaveY + noiseY);

//                                             if (t === fraction) break;
//                                         }
//                                     }

//                                     // Step 3: Theme and render each distinct strand
//                                     if (s === 0) { // Massive Sweeping Outer Glow (Mauve)
//                                         ctx.lineWidth = root.s(20);
//                                         ctx.strokeStyle = root.mauve;
//                                         ctx.globalAlpha = 0.2;
//                                     } else if (s === 1) { // Medium Sweeping Wave (Pink)
//                                         ctx.lineWidth = root.s(8);
//                                         ctx.strokeStyle = root.pink;
//                                         ctx.globalAlpha = 0.45;
//                                     } else if (s === 2) { // Tight erratic core (Lavender)
//                                         ctx.lineWidth = root.s(3.5);
//                                         ctx.strokeStyle = root.lavender;
//                                         ctx.globalAlpha = 0.85;
//                                     } else if (s === 3) { // Pure white straight hot core - heavily transparent
//                                         ctx.lineWidth = root.s(1.0);
//                                         ctx.strokeStyle = "#ffffff";
//                                         ctx.globalAlpha = 0.1;
//                                     }

//                                     ctx.stroke();
//                                 }
//                             }
//                         }
//                     }

//                     // Presets Grid
//                     ColumnLayout {
//                         Layout.fillWidth: true
//                         spacing: root.s(8)
                        
//                         opacity: root.introPresets
//                         transform: Translate { y: root.s(20) * (1 - root.introPresets) }

//                         RowLayout {
//                             Layout.fillWidth: true
//                             spacing: root.s(10)
//                             Repeater {
//                                 model: ["Flat", "Bass", "Treble", "Vocal"]
//                                 delegate: PresetButton { name: modelData }
//                             }
//                         }
//                         RowLayout {
//                             Layout.fillWidth: true
//                             spacing: root.s(10)
//                             Repeater {
//                                 model: ["Pop", "Rock", "Jazz", "Classic"]
//                                 delegate: PresetButton { name: modelData }
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }

//     // --- HELPER COMPONENT FOR PRESETS ---
//     component PresetButton : Rectangle {
//         property string name: ""
//         Layout.fillWidth: true
//         Layout.preferredHeight: root.s(32)
//         radius: root.s(8)
        
//         property bool isActivePreset: root.eqData && root.eqData.preset === name
//         property bool isHovered: hoverMa.containsMouse

//         color: isActivePreset ? root.mauve : (isHovered ? root.surface1 : "#BF1E1E2E")
//         scale: isHovered && !isActivePreset ? 1.05 : 1.0

//         Behavior on color { ColorAnimation { duration: 200 } }
//         Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

//         Text {
//             anchors.centerIn: parent
//             text: parent.name
//             color: parent.isActivePreset ? root.base : (parent.isHovered ? root.text : root.subtext0)
//             font.family: "JetBrains Mono"
//             font.pixelSize: root.s(12)
//             font.bold: true
//             Behavior on color { ColorAnimation { duration: 200 } }
//         }

//         MouseArea {
//             id: hoverMa
//             anchors.fill: parent
//             hoverEnabled: true
//             cursorShape: Qt.PointingHandCursor
//             onClicked: root.applyPresetOptimistically(parent.name)
//         }
//     }
// }



import QtQuick                                                                                  // Import QtQuick module - core QML types for building user interfaces (Item, Rectangle, Text, etc.)
import QtQuick.Window                                                                            // Import QtQuick.Window - provides Screen and Window types for display information
import QtQuick.Controls                                                                          // Import QtQuick.Controls - provides interactive UI controls like Slider
import QtQuick.Layouts                                                                           // Import QtQuick.Layouts - provides layout types (RowLayout, ColumnLayout) for arranging items
import QtQuick.Effects                                                                            // Import QtQuick.Effects - provides visual effects like MultiEffect for shadows and blurs
import QtQuick.Shapes                                                                             // Import QtQuick.Shapes - provides Shape, ShapePath, PathArc for drawing vector graphics
import Quickshell                                                                                 // Import Quickshell - the shell framework for creating desktop widgets/windows
import Quickshell.Io                                                                              // Import Quickshell.Io - provides I/O types like Process, StdioCollector for running commands
import "../"                                                                                      // Import parent directory - allows access to shared QML components in the parent folder

Item {                                                                                           // Root Item - top-level container for the entire music widget
    id: root                                                                                      // Assign id "root" - used to reference this item from anywhere within the component

    // --- Responsive Scaling Logic ---                                                            // Comment header - marks the scaling system section
    Scaler {                                                                                      // Create Scaler instance - custom component for responsive scaling
        id: scaler                                                                                 // Assign id "scaler" for reference
        // Uses the physical screen width so the popup scales synchronously                       // Comment explaining the scaling approach
        currentWidth: Screen.width                                                                  // Set currentWidth to the physical screen width in pixels - ensures consistent scaling
    }                                                                                             // End of Scaler
    
    // Helper function scoped to the root Item for easy access                                    // Comment describing the helper function
    function s(val) {                                                                              // Define function s(val) - scales a value proportionally based on screen width
        return scaler.s(val);                                                                       // Call scaler's s() method with val and return the scaled result
    }                                                                                             // End of s() function

    // Theme Colors                                                                                // Comment - marks theme color property definitions
    MatugenColors { id: _theme }                                                                   // Create MatugenColors instance - loads material you color scheme from system theme

    // Theme Colors                                                                                // Comment header for theme color bindings
    readonly property color base: _theme.base                                                      // Define readonly color "base" - binds to Matugen's base/background color
    readonly property color surface0: _theme.surface0                                              // Define readonly color "surface0" - lowest elevated surface color
    readonly property color surface1: _theme.surface1                                              // Define readonly color "surface1" - slightly elevated surface color
    readonly property color surface2: _theme.surface2                                              // Define readonly color "surface2" - more elevated surface color
    readonly property color overlay0: _theme.overlay0                                              // Define readonly color "overlay0" - lowest overlay/text color
    readonly property color overlay1: _theme.overlay1                                              // Define readonly color "overlay1" - medium overlay/text color
    readonly property color overlay2: _theme.overlay2                                              // Define readonly color "overlay2" - highest overlay/text color
    readonly property color text: _theme.text                                                      // Define readonly color "text" - main text color
    readonly property color subtext0: _theme.subtext0                                              // Define readonly color "subtext0" - secondary text color
    readonly property color subtext1: _theme.subtext1                                              // Define readonly color "subtext1" - tertiary text color
    readonly property color blue: _theme.blue                                                      // Define readonly color "blue" - theme blue accent
    readonly property color sapphire: _theme.sapphire                                              // Define readonly color "sapphire" - theme sapphire accent
    readonly property color lavender: _theme.blue // Mapped to blue as Matugen template lacks lavender  // Define lavender as blue fallback - Matugen may not have lavender in all templates
    readonly property color mauve: _theme.mauve                                                    // Define readonly color "mauve" - theme mauve accent
    readonly property color pink: _theme.pink                                                      // Define readonly color "pink" - theme pink accent
    readonly property color red: _theme.red                                                        // Define readonly color "red" - theme red accent
    readonly property color yellow: _theme.yellow                                                  // Define readonly color "yellow" - theme yellow accent

    // Data State Properties                                                                       // Comment header - marks data state property definitions
    property var musicData: {                                                                      // Define musicData property - object holding all current track/playback information
        "title": "Loading...", "artist": "", "status": "Stopped", "percent": 0,                    // Default values: title, empty artist, stopped status, 0% progress
        "lengthStr": "00:00", "positionStr": "00:00", "timeStr": "--:-- / --:--",                  // Default time strings for display
        "source": "Offline", "playerName": "", "blur": "", "grad": "",                             // Default source info and empty image paths
        "textColor": "#cdd6f4", "deviceIcon": "󰓃", "deviceName": "Speaker",                     // Default text color (Catppuccin text), speaker icon, device name
        "artUrl": ""                                                                               // Empty album art URL by default
    }                                                                                             // End of musicData object

    property var eqData: {                                                                         // Define eqData property - object holding equalizer state
        "b1": 0, "b2": 0, "b3": 0, "b4": 0, "b5": 0,                                             // Band 1-5 gain values in dB (all 0 = flat)
        "b6": 0, "b7": 0, "b8": 0, "b9": 0, "b10": 0,                                            // Band 6-10 gain values in dB
        "preset": "Flat", "pending": false                                                          // Current preset name, pending flag (false = saved, true = unsaved changes)
    }                                                                                             // End of eqData object

    // Accumulators for Process standard output                                                    // Comment describing accumulators
    property string accumulatedMusicOut: ""                                                       // Define property to accumulate music info shell script stdout (though StdioCollector is used instead)
    property string accumulatedEqOut: ""                                                          // Define property to accumulate equalizer shell script stdout

    // UI State for debouncing the slider and play button                                         // Comment describing UI state properties
    property bool userIsSeeking: false                                                             // Define userIsSeeking flag - true when user is actively dragging the progress slider
    property bool userToggledPlay: false                                                           // Define userToggledPlay flag - true when user clicked play/pause (prevents polling from overriding)
    
    // ANTI-JITTER LOCK: Prevents background polling from reverting UI during processing          // Comment explaining the anti-jitter mechanism
    property real lastEqUpdate: 0                                                                  // Define lastEqUpdate timestamp - stores Date.now() when optimistic EQ update was pushed, blocks polling for 2 seconds

    // Decoupled Global Animation States                                                           // Comment header for global animation properties
    property real catppuccinFlowOffset: 0                                                          // Define catppuccinFlowOffset - controls the flowing gradient animation position (0 to 1)
    NumberAnimation on catppuccinFlowOffset {                                                       // NumberAnimation on the flow offset property
        from: 0; to: 1.0                                                                             // Animate from 0 to 1
        duration: 8000 // Slowed down significantly for a graceful, constant flow                    // 8 seconds per cycle - slow and smooth gradient flow
        loops: Animation.Infinite                                                                     // Loop forever
        running: true                                                                                 // Start immediately
    }                                                                                              // End of NumberAnimation

    property real globalOrbitAngle: 0                                                              // Define globalOrbitAngle - controls orbiting background circle positions (0 to 2π)
    NumberAnimation on globalOrbitAngle {                                                            // NumberAnimation on the orbit angle
        from: 0; to: Math.PI * 2                                                                      // Animate from 0 to 2π radians (full circle)
        duration: 90000                                                                                // 90 seconds per orbit - very slow, graceful movement
        loops: Animation.Infinite                                                                      // Loop forever
        running: true                                                                                  // Start immediately
    }                                                                                              // End of NumberAnimation

    // --- CANVAS LIGHTNING ANIMATION STATE ---                                                    // Comment header - marks lightning effect animation state
    property real eqLightningProgress: 0.0                                                          // Define eqLightningProgress - controls how far the lightning bolt has traveled (0 to 10)
    property real eqLightningFade: 1.0 // 1.0 = fully faded out                                     // Define eqLightningFade - controls overall visibility (1.0 = invisible, 0.0 = fully visible)

    SequentialAnimation {                                                                            // Define SequentialAnimation for the lightning strike effect
        id: eqLightningAnim                                                                           // Assign id "eqLightningAnim" for triggering
        running: false                                                                                 // Don't run automatically - triggered manually
        ScriptAction { script: { root.eqLightningFade = 0.0; root.eqLightningProgress = 0.0; } }      // Step 1: Reset - make lightning fully visible, start at beginning
        NumberAnimation {                                                                              // Step 2: Animate the progress
            target: root; property: "eqLightningProgress";                                               // Target root's eqLightningProgress property
            from: 0.0; to: 10.0; // 10 points = 9 segments                                                // Animate across all 10 bands (9 segments between them)
            duration: 650; // Fast, snappy, energetic strike                                              // 650ms - quick energetic lightning bolt
            easing.type: Easing.OutSine                                                                    // OutSine easing - starts fast, decelerates at end
        }                                                                                              // End of NumberAnimation
        PauseAnimation { duration: 150 } // Hold the core flash at the end                             // Step 3: Pause 150ms - holds the bright flash at the endpoint
        NumberAnimation {                                                                              // Step 4: Fade out the lightning
            target: root; property: "eqLightningFade";                                                    // Target root's eqLightningFade property
            from: 0.0; to: 1.0;                                                                            // Fade from fully visible to invisible
            duration: 800; // Smooth dissipation                                                          // 800ms smooth fade out
            easing.type: Easing.OutQuad                                                                    // OutQuad easing for natural dissipation
        }                                                                                              // End of NumberAnimation
        ScriptAction { script: { root.eqLightningProgress = 0.0; } }                                   // Step 5: Reset progress to 0 for next trigger
    }                                                                                              // End of SequentialAnimation

    function triggerEqLightning() {                                                                  // Define function to trigger the lightning effect
        eqLightningAnim.restart();                                                                    // Restart the lightning animation sequence from beginning
    }                                                                                              // End of triggerEqLightning function

    // --- GLOBAL PLAY/PAUSE EVENT LISTENER ---                                                     // Comment header - marks play/pause detection logic
    property string lastMusicStatus: "Stopped"                                                       // Define lastMusicStatus - tracks previous status to detect changes
    onMusicDataChanged: {                                                                            // Handler for when musicData property changes
        if (musicData && musicData.status && musicData.status !== lastMusicStatus) {                   // Check if status exists and has changed from previous value
            if (musicData.status === "Playing") {                                                       // If new status is Playing (transitioned to playing)
                playPulse.trigger();                                                                      // Trigger the play pulse ripple animation
            }                                                                                           // End of if
            lastMusicStatus = musicData.status;                                                          // Update lastMusicStatus to current status for next comparison
        }                                                                                             // End of if
    }                                                                                              // End of onMusicDataChanged

    // --- ENHANCED STARTUP ANIMATION STATES ---                                                     // Comment header - marks staggered intro animation properties
    property real introMain: 0                                                                       // Define introMain - controls main container fade/scale (0 to 1)
    property real introCover: 0                                                                      // Define introCover - controls cover art animation progress
    property real introText: 0                                                                       // Define introText - controls text info animation progress
    property real introControls: 0                                                                   // Define introControls - controls progress bar and media buttons animation
    property real introSeparator: 0                                                                  // Define introSeparator - controls separator line animation
    property real introEqHeader: 0                                                                   // Define introEqHeader - controls EQ header animation
    property real introEqSliders: 0                                                                  // Define introEqSliders - controls EQ sliders animation
    property real introPresets: 0                                                                    // Define introPresets - controls preset buttons animation

    ParallelAnimation {                                                                              // Define ParallelAnimation - runs all intro animations simultaneously (with staggered delays)
        running: true                                                                                  // Start automatically when component loads

        // 1. Base window fades, scales, and lifts smoothly (sped up by ~40ms)                      // Comment describing first animation group
        NumberAnimation { target: root; property: "introMain"; from: 0; to: 1.0; duration: 760; easing.type: Easing.OutQuart }  // Main container: fade and scale in over 760ms with OutQuart easing

        // 2. Cover art snaps in with a premium elastic feel                                        // Comment describing cover art animation
        SequentialAnimation {                                                                          // SequentialAnimation for cover art delay + animation
            PauseAnimation { duration: 70 }                                                              // Wait 70ms before starting cover animation
            NumberAnimation { target: root; property: "introCover"; from: 0; to: 1.0; duration: 810; easing.type: Easing.OutBack; easing.overshoot: 1.0 }  // Cover art: elastic snap-in over 810ms with OutBack overshoot
        }                                                                                              // End of SequentialAnimation

        // 3. Text block glides in smoothly                                                         // Comment describing text animation
        SequentialAnimation {                                                                          // SequentialAnimation for text delay + animation
            PauseAnimation { duration: 150 }                                                             // Wait 150ms
            NumberAnimation { target: root; property: "introText"; from: 0; to: 1.0; duration: 760; easing.type: Easing.OutQuart }  // Text: glide in over 760ms
        }                                                                                              // End of SequentialAnimation

        // 4. Progress bar and Media Controls bounce in                                              // Comment describing controls animation
        SequentialAnimation {                                                                          // SequentialAnimation for controls delay + animation
            PauseAnimation { duration: 230 }                                                             // Wait 230ms
            NumberAnimation { target: root; property: "introControls"; from: 0; to: 1.0; duration: 760; easing.type: Easing.OutBack; easing.overshoot: 0.8 }  // Controls: bounce in with OutBack overshoot
        }                                                                                              // End of SequentialAnimation

        // 5. Separator line drops and fades                                                        // Comment describing separator animation
        SequentialAnimation {                                                                          // SequentialAnimation for separator delay + animation
            PauseAnimation { duration: 310 }                                                             // Wait 310ms
            NumberAnimation { target: root; property: "introSeparator"; from: 0; to: 1.0; duration: 660; easing.type: Easing.OutQuart }  // Separator: drop and fade over 660ms
        }                                                                                              // End of SequentialAnimation

        // 6. EQ header follows down seamlessly                                                    // Comment describing EQ header animation
        SequentialAnimation {                                                                          // SequentialAnimation for EQ header delay + animation
            PauseAnimation { duration: 370 }                                                             // Wait 370ms
            NumberAnimation { target: root; property: "introEqHeader"; from: 0; to: 1.0; duration: 710; easing.type: Easing.OutQuart }  // EQ header: slide down over 710ms
        }                                                                                              // End of SequentialAnimation

        // 7. EQ Sliders sweep up in a sequential waterfall wave                                    // Comment describing sliders animation
        SequentialAnimation {                                                                          // SequentialAnimation for sliders delay + animation
            PauseAnimation { duration: 430 }                                                             // Wait 430ms
            NumberAnimation { target: root; property: "introEqSliders"; from: 0; to: 1.0; duration: 860; easing.type: Easing.OutExpo }  // Sliders: sweep up with OutExpo easing over 860ms
        }                                                                                              // End of SequentialAnimation

        // 8. Presets finish the orchestration with a final pop                                     // Comment describing presets animation
        SequentialAnimation {                                                                          // SequentialAnimation for presets delay + animation
            PauseAnimation { duration: 550 }                                                             // Wait 550ms
            NumberAnimation { target: root; property: "introPresets"; from: 0; to: 1.0; duration: 810; easing.type: Easing.OutBack; easing.overshoot: 0.8 }  // Presets: pop in with OutBack overshoot over 810ms
        }                                                                                              // End of SequentialAnimation
    }                                                                                              // End of ParallelAnimation

    // --- FIXED COLOR PARSING LOGIC ---                                                            // Comment header - marks border color extraction logic
    property var borderColors: {                                                                     // Define borderColors property - extracts hex colors from the gradient string
        var defaultColors = [root.mauve, root.blue, root.red, root.mauve];                             // Default fallback colors: mauve, blue, red, mauve (looping)
        if (!root.musicData || !root.musicData.grad) return defaultColors;                              // If no music data or no gradient string, return defaults
        
        var hexRegex = /#[0-9a-fA-F]{6}/g;                                                             // Regular expression to match 6-digit hex color codes (#RRGGBB)
        var matches = root.musicData.grad.match(hexRegex);                                              // Find all hex color matches in the gradient string
        
        if (matches && matches.length >= 3) {                                                           // If at least 3 colors were found
            return [matches[0], matches[1], matches[2], matches[0]]; // Wrap around for looping          // Return [color1, color2, color3, color1] for seamless gradient looping
        }                                                                                              // End of if
        return defaultColors;                                                                          // Fallback to default colors if extraction failed
    }                                                                                              // End of borderColors

    // PROPER EXCEPTION-FREE FIX: Explicit bindings so GradientStop actually repaints               // Comment explaining the explicit color property workaround
    property color bc1: borderColors[0] || root.mauve                                                 // Define bc1 - first border color, fallback to mauve if array is empty
    property color bc2: borderColors[1] || root.blue                                                  // Define bc2 - second border color, fallback to blue
    property color bc3: borderColors[2] || root.red                                                   // Define bc3 - third border color, fallback to red
    property color bc4: borderColors[3] || root.mauve                                                 // Define bc4 - fourth border color (loops back), fallback to mauve

    property color dynamicTextColor: {                                                               // Define dynamicTextColor - calculated text color based on album art
        if (root.musicData && root.musicData.textColor) {                                               // If music data and textColor exist
            var c = String(root.musicData.textColor).trim();                                              // Convert to string and trim whitespace
            // Securely extract exactly #RRGGBB, ignoring any alpha leak from the shell               // Comment explaining security/safety measure
            var match = c.match(/^(#[0-9a-fA-F]{6})/);                                                   // Extract exactly 6-digit hex color, ignoring any extra characters (like alpha channel)
            if (match) return match[1];                                                                   // If match found, return the clean hex color
        }                                                                                              // End of if
        return root.text;                                                                              // Fallback to theme text color if extraction fails
    }                                                                                              // End of dynamicTextColor

    // --- UTILITIES & OPTIMISTIC UPDATES ---                                                        // Comment header - marks utility functions section
    function execCmd(cmdStr) {                                                                       // Define execCmd function - safely executes a shell command asynchronously
        var safeCmd = cmdStr.replace(/`/g, "\\`");                                                     // Escape backticks in command string to prevent shell injection
        var p = Qt.createQmlObject(`                                                                   // Dynamically create a QML Process object from string
            import Quickshell.Io                                                                        // Import needed for Process
            Process {                                                                                   // Define Process inline
                command: ["bash", "-c", \`${safeCmd}\`]                                                  // Command array: run bash with -c and the escaped command string
                running: true                                                                             // Start immediately
                onExited: (exitCode) => destroy()                                                          // When process exits, destroy this QML object to free memory
            }                                                                                            // End of Process
        `, root);                                                                                      // Create as child of root item
    }                                                                                              // End of execCmd function

    function applyPresetOptimistically(presetName) {                                                  // Define function to apply EQ preset with instant UI update
        var presets = {                                                                                // Define preset gain values for each named preset
            "Flat": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],                                                    // Flat: all bands at 0dB
            "Bass": [5, 7, 5, 2, 1, 0, 0, 0, 1, 2],                                                    // Bass: boosted lows, slight cut at mids, slight boost highs
            "Treble": [-2, -1, 0, 1, 2, 3, 4, 5, 6, 6],                                               // Treble: cut lows, progressively boost highs
            "Vocal": [-2, -1, 1, 3, 5, 5, 4, 2, 1, 0],                                                // Vocal: cut sub-bass, boost midrange vocals, cut highest
            "Pop": [2, 4, 2, 0, 1, 2, 4, 2, 1, 2],                                                    // Pop: moderate boost lows and highs, slight mid cut
            "Rock": [5, 4, 2, -1, -2, -1, 2, 4, 5, 6],                                                // Rock: strong bass, mid cut, strong treble
            "Jazz": [3, 3, 1, 1, 1, 1, 2, 1, 2, 3],                                                   // Jazz: gentle bass, flat mids, slight treble
            "Classic": [0, 1, 2, 2, 2, 2, 1, 2, 3, 4]                                                 // Classic: subtle low cut, gradual treble boost
        };                                                                                           // End of presets object
        if (presets[presetName]) {                                                                     // If the preset name exists in our map
            var temp = Object.assign({}, root.eqData);                                                   // Create shallow copy of current eqData
            for (var i = 0; i < 10; i++) {                                                                // Loop through 10 bands
                temp["b" + (i + 1)] = presets[presetName][i];                                               // Set each band to the preset value (b1 through b10)
            }                                                                                            // End of for loop
            temp.preset = presetName;                                                                     // Set preset name
            temp.pending = false;                                                                          // Mark as saved (not pending)
            root.eqData = temp;                                                                            // Assign updated object to trigger UI refresh
            
            // Blind the polling process to stop it from fetching old data                             // Comment explaining anti-jitter lock
            root.lastEqUpdate = Date.now();                                                                // Set timestamp to now - blocks background polling for 2 seconds
            
            root.triggerEqLightning();                                                                     // Trigger the lightning bolt animation
            execCmd(`$HOME/.config/hypr/scripts/quickshell/music/equalizer.sh preset ${presetName}`);     // Execute the equalizer script asynchronously to apply preset
        }                                                                                              // End of if
    }                                                                                              // End of applyPresetOptimistically function

    // --- DATA POLLING ---                                                                          // Comment header - marks data polling timers section
    Timer {                                                                                          // Define Timer for seek debouncing
        id: seekDebounceTimer                                                                         // Assign id "seekDebounceTimer"
        interval: 2500                                                                                 // 2.5 seconds - prevents sending seek commands too rapidly
        onTriggered: root.userIsSeeking = false                                                         // When timer fires, clear the seeking flag (allows polling to resume)
    }                                                                                              // End of seekDebounceTimer

    Timer {                                                                                          // Define Timer for play/pause debouncing
        id: playDebounceTimer                                                                         // Assign id "playDebounceTimer"
        interval: 1500                                                                                 // 1.5 seconds - prevents polling from overriding user's play/pause toggle
        onTriggered: root.userToggledPlay = false                                                       // When timer fires, clear the toggle flag
    }                                                                                              // End of playDebounceTimer

    Timer {                                                                                          // Define Timer for periodic data polling
        interval: 500                                                                                  // Poll every 500ms (2 times per second)
        running: true                                                                                  // Start immediately
        repeat: true                                                                                   // Repeat forever
        triggeredOnStart: true                                                                         // Also trigger immediately on start (don't wait first 500ms)
        onTriggered: {                                                                                 // Handler when timer fires
            if (!musicProc.running) musicProc.running = true;                                             // If music process isn't running, start it
            if (!eqProc.running) eqProc.running = true;                                                   // If EQ process isn't running, start it
        }                                                                                              // End of onTriggered
    }                                                                                              // End of polling Timer

    Process {                                                                                        // Define Process for fetching music info
        id: musicProc                                                                                  // Assign id "musicProc"
        running: true                                                                                  // Start immediately
        command: ["bash", "-c", "$HOME/.config/hypr/scripts/quickshell/music/music_info.sh"]           // Run the music_info.sh script to get current track info as JSON
        stdout: StdioCollector {                                                                       // Use StdioCollector to capture all stdout output
            onStreamFinished: {                                                                          // Handler when the process finishes and all output is collected
                if (this.text) {                                                                           // If there is output text
                    var outStr = this.text.trim();                                                           // Trim whitespace from output
                    if (outStr.length > 0) {                                                                 // If output is not empty
                        try {                                                                                // Try block for JSON parsing
                            var newData = JSON.parse(outStr);                                                  // Parse the JSON output into an object
                            if (root.userToggledPlay) {                                                         // If user recently toggled play/pause
                                newData.status = root.musicData.status;                                            // Preserve the status that the user set (prevent polling override)
                            }                                                                                  // End of if
                            root.musicData = newData;                                                            // Update musicData with parsed data (triggers UI updates)
                        } catch(e) {}                                                                          // Silently catch JSON parse errors
                    }                                                                                      // End of if
                }                                                                                          // End of if
            }                                                                                            // End of onStreamFinished
        }                                                                                              // End of StdioCollector
    }                                                                                              // End of musicProc

    Process {                                                                                        // Define Process for fetching equalizer state
        id: eqProc                                                                                    // Assign id "eqProc"
        running: true                                                                                  // Start immediately
        command: ["bash", "-c", "$HOME/.config/hypr/scripts/quickshell/music/equalizer.sh get"]        // Run equalizer.sh with "get" command to retrieve current EQ state as JSON
        stdout: StdioCollector {                                                                       // Use StdioCollector for output
            onStreamFinished: {                                                                          // Handler when process finishes
                if (this.text) {                                                                           // If output exists
                    // Ignore background data entirely if we recently pushed an optimistic update        // Comment explaining anti-jitter protection
                    if (Date.now() - root.lastEqUpdate < 2000) return;                                      // If less than 2 seconds since last optimistic update, ignore this polling result

                    var outStr = this.text.trim();                                                           // Trim output
                    if (outStr.length > 0) {                                                                 // If non-empty
                        try { root.eqData = JSON.parse(outStr); } catch(e) {}                                  // Parse JSON and update eqData, silently catch errors
                    }                                                                                      // End of if
                }                                                                                          // End of if
            }                                                                                            // End of onStreamFinished
        }                                                                                              // End of StdioCollector
    }                                                                                              // End of eqProc

    // --- UI LAYOUT ---                                                                             // Comment header - marks the main UI layout section
    Item {                                                                                           // Main wrapper item - provides scale and opacity animation container
        id: mainWrapper                                                                               // Assign id "mainWrapper"
        anchors.fill: parent                                                                           // Fill the entire root item
        
        // Deepened scale effect and introduced a gentle Y-axis translation for the main container   // Comment describing animation effect
        scale: 0.92 + (0.08 * root.introMain)                                                          // Scale from 0.92 to 1.0 as introMain goes 0→1 (subtle zoom in)
        opacity: root.introMain                                                                         // Fade from 0 to 1 with introMain
        transform: Translate { y: root.s(15) * (1 - root.introMain) }                                   // Slide up from 15px down to final position

        // OUTER ANIMATED BORDER WITH PROPER CLIPPING                                                 // Comment header - marks the animated gradient border section
        Item {                                                                                         // Container for the border effect
            anchors.fill: parent                                                                         // Fill the main wrapper

            Shape {                                                                                      // Shape for the animated border mask
                id: maskRectOuter                                                                          // Assign id "maskRectOuter"
                anchors.fill: parent                                                                       // Fill parent
                visible: false // Hidden because MultiEffect will render it as a mask                       // Hidden - used only as mask source for MultiEffect
                layer.enabled: true                                                                        // Enable layer rendering (needed for MultiEffect masking)
                preferredRendererType: Shape.GeometryRenderer // Fixes lag by hardware accelerating the stroke  // Use GeometryRenderer for GPU-accelerated rendering

                property real sw: root.s(6)                                                                // Define stroke width property (scaled 6px)
                property real inset: (sw / 2) + root.s(0.5)                                                // Define inset from edge = half stroke width + 0.5px (prevents clipping)
                property real w: width                                                                     // Property tracking current width
                property real h: height                                                                    // Property tracking current height
                property real r: root.s(14) - inset                                                         // Corner radius = 14px scaled minus inset
                
                // Mathematical perimeter                                                                // Comment - calculates total perimeter for dash animation
                property real straightLines: 2 * (w - 2 * inset - 2 * r) + 2 * (h - 2 * inset - 2 * r)    // Calculate total straight line length: 2 horizontal + 2 vertical sections
                property real arcLines: 2 * Math.PI * r                                                    // Calculate total arc length: circumference of 4 quarter-circles (full circle)
                property real perimeter: straightLines + arcLines                                           // Total perimeter = straight lines + arcs

                property real drawProgress: 0                                                              // Property for animation progress along the perimeter

                NumberAnimation on drawProgress {                                                           // Animate the draw progress
                    id: chargeAnim                                                                           // Assign id "chargeAnim"
                    from: 0                                                                                  // Start at 0
                    to: maskRectOuter.perimeter                                                               // Animate to full perimeter length
                    duration: 1200 // The time it takes to "charge" the whole wick                            // 1.2 seconds for full border draw
                    easing.type: Easing.OutCubic                                                              // OutCubic easing - smooth deceleration
                    running: true // Ensure it starts reliably                                                // Start immediately
                }                                                                                          // End of NumberAnimation

                ShapePath {                                                                                // Define the path that draws the border
                    strokeWidth: maskRectOuter.sw                                                            // Set stroke width from outer mask property
                    strokeColor: "black"                                                                      // Black stroke (used as mask, color doesn't matter)
                    fillColor: "transparent"                                                                  // No fill - only stroke
                    capStyle: ShapePath.FlatCap                                                               // Flat line caps (no protruding ends)

                    // QML Shape dash patterns are measured in units of strokeWidth!                        // Comment explaining dash pattern units
                    dashPattern: [maskRectOuter.perimeter / maskRectOuter.sw, maskRectOuter.perimeter / maskRectOuter.sw]  // Dash pattern: one dash of full perimeter length, one gap of full perimeter length
                    dashOffset: (maskRectOuter.perimeter - maskRectOuter.drawProgress) / maskRectOuter.sw     // Offset dash to reveal only the drawn portion (animates from full perimeter to 0)

                    // Start exactly at Bottom-Left corner, going UP clockwise                            // Comment describing path start point
                    startX: maskRectOuter.inset                                                              // Start X at left inset
                    startY: maskRectOuter.h - maskRectOuter.inset - maskRectOuter.r                          // Start Y at bottom minus inset minus radius (bottom-left corner start)

                    // 1. Up to top-left corner                                                            // Path segment 1: vertical line up
                    PathLine { x: maskRectOuter.inset; y: maskRectOuter.inset + maskRectOuter.r }            // Draw line up to just before top-left corner arc
                    // 2. Arc top-left                                                                      // Path segment 2: top-left rounded corner
                    PathArc {                                                                                // Draw arc for rounded corner
                        x: maskRectOuter.inset + maskRectOuter.r; y: maskRectOuter.inset                      // End point of arc (moved right and up)
                        radiusX: maskRectOuter.r; radiusY: maskRectOuter.r; direction: PathArc.Clockwise      // Use corner radius, clockwise direction
                    }                                                                                       // End of PathArc
                    // 3. Right to top-right corner                                                        // Path segment 3: horizontal line right
                    PathLine { x: maskRectOuter.w - maskRectOuter.inset - maskRectOuter.r; y: maskRectOuter.inset }  // Draw line right to just before top-right corner
                    // 4. Arc top-right                                                                    // Path segment 4: top-right rounded corner
                    PathArc {                                                                                // Draw arc
                        x: maskRectOuter.w - maskRectOuter.inset; y: maskRectOuter.inset + maskRectOuter.r    // End point (moved down)
                        radiusX: maskRectOuter.r; radiusY: maskRectOuter.r; direction: PathArc.Clockwise      // Same radius, clockwise
                    }                                                                                       // End of PathArc
                    // 5. Down to bottom-right corner                                                     // Path segment 5: vertical line down
                    PathLine { x: maskRectOuter.w - maskRectOuter.inset; y: maskRectOuter.h - maskRectOuter.inset - maskRectOuter.r }  // Draw line down to just before bottom-right corner
                    // 6. Arc bottom-right                                                                // Path segment 6: bottom-right rounded corner
                    PathArc {                                                                                // Draw arc
                        x: maskRectOuter.w - maskRectOuter.inset - maskRectOuter.r; y: maskRectOuter.h - maskRectOuter.inset  // End point (moved left)
                        radiusX: maskRectOuter.r; radiusY: maskRectOuter.r; direction: PathArc.Clockwise      // Same radius, clockwise
                    }                                                                                       // End of PathArc
                    // 7. Left to bottom-left corner                                                      // Path segment 7: horizontal line left
                    PathLine { x: maskRectOuter.inset + maskRectOuter.r; y: maskRectOuter.h - maskRectOuter.inset }  // Draw line left to just before bottom-left corner
                    // 8. Arc bottom-left to finish                                                       // Path segment 8: bottom-left rounded corner
                    PathArc {                                                                                // Draw arc
                        x: maskRectOuter.inset; y: maskRectOuter.h - maskRectOuter.inset - maskRectOuter.r    // End point back at start
                        radiusX: maskRectOuter.r; radiusY: maskRectOuter.r; direction: PathArc.Clockwise      // Same radius, clockwise
                    }                                                                                       // End of PathArc
                }                                                                                         // End of ShapePath
            }                                                                                           // End of Shape

            Item {                                                                                       // Container for the rotating gradient (source for border)
                id: gradContainer                                                                          // Assign id "gradContainer"
                anchors.fill: parent                                                                       // Fill parent
                visible: false // Hidden for MultiEffect mapping                                             // Hidden - used as source for MultiEffect
                clip: true // Prevents the rotated gradient bounding box from bulging out the sides!       // Clip to prevent oversized rotated rectangle from overflowing

                Rectangle {                                                                                // Rotating gradient rectangle
                    width: Math.max(parent.width, parent.height) * 2                                          // Width = 2x the larger dimension (ensures coverage when rotated)
                    height: width                                                                              // Square shape for consistent rotation
                    anchors.centerIn: parent                                                                   // Center in the container
                    
                    NumberAnimation on rotation {                                                               // Continuous rotation animation
                        from: 0; to: 360; duration: 5000                                                          // Full rotation every 5 seconds
                        loops: Animation.Infinite                                                                  // Loop forever
                        running: true                                                                              // Start immediately
                    }                                                                                           // End of NumberAnimation

                    gradient: Gradient {                                                                        // Define gradient for the border colors
                        // FIXED: Using securely unpacked color bindings                                       // Comment explaining the fixed color approach
                        GradientStop { position: 0.0; color: root.bc1; Behavior on color { ColorAnimation { duration: 800; easing.type: Easing.InOutQuad } } }  // Color 1 at 0% position with smooth transition
                        GradientStop { position: 0.33; color: root.bc2; Behavior on color { ColorAnimation { duration: 800; easing.type: Easing.InOutQuad } } }  // Color 2 at 33% position
                        GradientStop { position: 0.66; color: root.bc3; Behavior on color { ColorAnimation { duration: 800; easing.type: Easing.InOutQuad } } }  // Color 3 at 66% position
                        GradientStop { position: 1.0; color: root.bc4; Behavior on color { ColorAnimation { duration: 800; easing.type: Easing.InOutQuad } } }  // Color 4 at 100% position
                    }                                                                                         // End of Gradient
                }                                                                                           // End of Rectangle
            }                                                                                            // End of gradContainer

            MultiEffect {                                                                                 // Apply mask effect to show gradient only where the border path is
                source: gradContainer                                                                       // Use the rotating gradient as source
                anchors.fill: parent                                                                         // Fill parent
                maskEnabled: true                                                                            // Enable masking
                maskSource: maskRectOuter                                                                    // Use the Shape path as mask (only shows gradient through the drawn border)
            }                                                                                            // End of MultiEffect
        }                                                                                              // End of border Item

        // INNER WINDOW BOX                                                                           // Comment header - marks the inner content area
        Rectangle {                                                                                    // Inner background rectangle
            id: innerBg                                                                                  // Assign id "innerBg"
            anchors.fill: parent                                                                          // Fill parent
            anchors.margins: root.s(3)                                                                     // 3px margin from border
            color: root.base                                                                               // Use theme base color as background
            radius: root.s(10)                                                                             // Rounded corners (10px scaled)

            // FIX: This forces the entire background to render as a single hardware texture,            // Comment explaining performance fix
            // preventing the UI from dragging and causing "shadow boxes" during the StackView transition!  // More explanation
            layer.enabled: true                                                                            // Enable layer rendering - forces GPU texture for smooth animations

            // Provide a perfectly rounded mask for the inner content                                    // Comment describing mask purpose
            Rectangle {                                                                                  // Invisible mask rectangle for content clipping
                id: innerBgMask                                                                            // Assign id "innerBgMask"
                anchors.fill: parent                                                                       // Fill inner background
                radius: root.s(10)                                                                          // Same radius as inner background
                visible: false                                                                              // Hidden - used only as mask source
                
                // FIX: Masks in MultiEffect strictly require layer.enabled to correctly capture the radius during scaling!  // Comment explaining mask requirement
                layer.enabled: true                                                                         // Enable layer for correct mask capture during animations
            }                                                                                            // End of innerBgMask

            Item {                                                                                       // Container for background effects layer
                id: bgEffectsLayer                                                                        // Assign id "bgEffectsLayer"
                anchors.fill: parent                                                                       // Fill inner background
                
                // This correctly clamps the blur and orbit circles to the 10px radius corners           // Comment explaining clipping
                layer.enabled: true                                                                        // Enable layer rendering
                layer.effect: MultiEffect {                                                                 // Apply MultiEffect as layer effect
                    maskEnabled: true                                                                         // Enable masking
                    maskSource: innerBgMask                                                                   // Use innerBgMask to clip effects to rounded corners
                }                                                                                          // End of layer.effect

                // LAYER 1: Background Blur (Smooth fade-in)                                             // Comment - blurred album art background layer
                Image {                                                                                    // Blurred background image
                    anchors.fill: parent                                                                     // Fill the effects layer
                    source: root.musicData.blur ? "file://" + root.musicData.blur : ""                         // Load blur image if path exists, prepend "file://" for local files
                    fillMode: Image.PreserveAspectCrop                                                         // Crop to fill while maintaining aspect ratio
                    
                    // Fixed: Ensures blur is completely hidden when stopped so the pure base color matches the calendar  // Comment explaining visibility logic
                    opacity: (status === Image.Ready && root.musicData.status !== "Stopped" && root.musicData.status !== "Offline") ? 0.9 : 0.0  // Show at 90% opacity when playing/paused, hide when stopped
                    Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.InOutQuad } }    // Smooth opacity transition over 800ms
                }                                                                                          // End of Image

                // LAYER 1.5: Flowing Orbits                                                             // Comment - decorative orbiting circles layer
                Rectangle {                                                                                // First orbiting circle
                    width: parent.width * 0.8; height: width; radius: width / 2                               // Circle with diameter 80% of parent width
                    x: (parent.width / 2 - width / 2) + Math.cos(root.globalOrbitAngle * 2) * root.s(150)      // X position: center + cos(2*angle) * 150px - orbits horizontally
                    y: (parent.height / 2 - height / 2) + Math.sin(root.globalOrbitAngle * 2) * root.s(100)    // Y position: center + sin(2*angle) * 100px - orbits vertically
                    
                    // Fixed: Hides orbits when stopped                                                   // Comment explaining visibility
                    opacity: root.musicData.status === "Playing" ? 0.08 : (root.musicData.status === "Paused" ? 0.04 : 0.0)  // 8% opacity when playing, 4% when paused, hidden when stopped
                    color: root.musicData.status === "Playing" ? root.mauve : root.surface2                  // Mauve when playing, surface2 when paused
                    Behavior on color { ColorAnimation { duration: 1000 } }                                  // Smooth color transition over 1 second
                    Behavior on opacity { NumberAnimation { duration: 1000 } }                               // Smooth opacity transition
                }                                                                                          // End of Rectangle (orbit 1)
                
                Rectangle {                                                                                // Second orbiting circle
                    width: parent.width * 0.9; height: width; radius: width / 2                               // Larger circle - 90% of parent width
                    x: (parent.width / 2 - width / 2) + Math.sin(root.globalOrbitAngle * 1.5) * root.s(-150)   // X position: center + sin(1.5*angle) * -150px - opposite direction
                    y: (parent.height / 2 - height / 2) + Math.cos(root.globalOrbitAngle * 1.5) * root.s(-100)   // Y position: center + cos(1.5*angle) * -100px
                    
                    // Fixed: Hides orbits when stopped                                                   // Comment explaining visibility
                    opacity: root.musicData.status === "Playing" ? 0.08 : (root.musicData.status === "Paused" ? 0.02 : 0.0)  // 8% playing, 2% paused, hidden stopped
                    color: root.musicData.status === "Playing" ? root.blue : root.surface1                   // Blue when playing, surface1 when paused
                    Behavior on color { ColorAnimation { duration: 1000 } }                                  // Smooth color transition
                    Behavior on opacity { NumberAnimation { duration: 1000 } }                               // Smooth opacity transition
                }                                                                                          // End of Rectangle (orbit 2)
            }                                                                                            // End of bgEffectsLayer

            // LAYER 2: UI Content                                                                     // Comment - main UI content layer
            ColumnLayout {                                                                               // Main vertical column layout
                anchors.fill: parent                                                                       // Fill inner background
                anchors.margins: root.s(20)                                                                 // 20px margins on all sides
                spacing: 0                                                                                  // No spacing between sections (handled internally)

                // ==========================================                                            // Decorative separator
                // TOP INFO SECTION                                                                        // Section header
                // ==========================================                                            // Decorative separator
                RowLayout {                                                                                // Horizontal row for cover art and track info
                    Layout.fillWidth: true                                                                   // Fill available width
                    Layout.preferredHeight: root.s(220)                                                       // Fixed height of 220px (scaled)
                    spacing: root.s(25)                                                                       // 25px spacing between cover art and text

                    // Cover Art Wrapper                                                                     // Subsection comment
                    Item {                                                                                   // Container for cover art
                        Layout.preferredWidth: root.s(220)                                                      // Fixed width 220px
                        Layout.preferredHeight: root.s(220)                                                     // Fixed height 220px (square)
                        Layout.alignment: Qt.AlignVCenter                                                       // Center vertically in the row

                        opacity: root.introCover                                                                // Fade in with introCover animation
                        // Enhanced 2D drift animation                                                         // Comment describing entrance animation
                        transform: Translate { x: root.s(-40) * (1 - root.introCover); y: root.s(10) * (1 - root.introCover) }  // Slide in from left (-40px) and slightly up (10px) as introCover goes 0→1

                        // Elastic response to play/pause state                                               // Comment describing play/pause effect
                        scale: root.musicData.status === "Playing" ? 1.0 : 0.90                                 // Full size when playing, 90% when paused/stopped
                        Behavior on scale { NumberAnimation { duration: 800; easing.type: Easing.OutElastic; easing.overshoot: 1.2 } }  // Elastic bounce animation over 800ms

                        Rectangle {                                                                             // Circular cover art frame
                            anchors.fill: parent                                                                  // Fill container
                            radius: root.s(110)                                                                    // Circular (radius = half of 220)
                            color: root.surface1                                                                    // Surface1 background color
                            border.width: root.s(4)                                                                 // 4px border
                            border.color: root.musicData.status === "Playing" ? root.mauve : root.overlay0           // Mauve border when playing, overlay0 otherwise
                            Behavior on border.color { ColorAnimation { duration: 500 } }                             // Smooth border color transition

                            // Glow Effect surrounding the thumbnail                                             // Comment describing glow
                            Rectangle {                                                                            // Glow ring behind thumbnail
                                z: -1                                                                                // Render behind the thumbnail
                                anchors.centerIn: parent                                                               // Center on the thumbnail
                                width: parent.width + root.s(20)                                                       // 20px larger than thumbnail
                                height: parent.height + root.s(20)                                                     // 20px taller
                                radius: width / 2                                                                      // Circular
                                color: root.mauve                                                                      // Mauve glow color
                                opacity: root.musicData.status === "Playing" ? 0.5 : 0.0                                // 50% opacity when playing, hidden otherwise
                                Behavior on opacity { NumberAnimation { duration: 500 } }                                // Smooth opacity transition
                                layer.enabled: true                                                                    // Enable layer for blur effect
                                layer.effect: MultiEffect {                                                             // Apply blur to create glow
                                    blurEnabled: true                                                                    // Enable blur
                                    blurMax: 32                                                                          // Maximum blur radius
                                    blur: 1.0                                                                            // Full blur amount
                                }                                                                                      // End of layer.effect
                            }                                                                                        // End of glow Rectangle

                            Item {                                                                                   // Container for album art image
                                anchors.fill: parent                                                                   // Fill frame
                                anchors.margins: root.s(4)                                                              // 4px margin (inside border)
                                Image {                                                                                // Album art image
                                    id: artImg                                                                           // Assign id "artImg"
                                    anchors.fill: parent                                                                 // Fill container
                                    source: root.musicData.artUrl ? "file://" + root.musicData.artUrl : ""                // Load art if URL exists
                                    fillMode: Image.PreserveAspectCrop                                                    // Crop to fill
                                    visible: false                                                                        // Hidden - rendered through MultiEffect mask
                                }                                                                                      // End of Image
                                Rectangle {                                                                            // Circular mask for album art
                                    id: maskRect                                                                         // Assign id "maskRect"
                                    anchors.fill: parent                                                                  // Fill container
                                    radius: width / 2                                                                     // Circular mask
                                    visible: false                                                                        // Hidden - used as mask source
                                    layer.enabled: true                                                                    // Enable layer for masking
                                }                                                                                      // End of maskRect
                                MultiEffect {                                                                          // Apply circular mask to album art
                                    anchors.fill: parent                                                                 // Fill container
                                    source: artImg                                                                        // Use album art as source
                                    maskEnabled: true                                                                     // Enable masking
                                    maskSource: maskRect                                                                  // Use circular mask
                                    opacity: artImg.status === Image.Ready ? 1.0 : 0.0                                     // Show when image is loaded
                                    Behavior on opacity { NumberAnimation { duration: 800 } }                               // Smooth opacity transition
                                }                                                                                      // End of MultiEffect
                                
                                // NEW: Dimmed slightly by tinting with the primary mauve accent, as requested         // Comment describing tint overlay
                                Rectangle {                                                                            // Tint overlay rectangle
                                    anchors.fill: parent                                                                 // Fill container
                                    radius: width / 2                                                                     // Circular
                                    color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.2)                          // Mauve tint at 20% opacity
                                    opacity: artImg.status === Image.Ready ? 1.0 : 0.0                                     // Show when image is loaded
                                    Behavior on opacity { NumberAnimation { duration: 800 } }                               // Smooth opacity transition
                                }                                                                                      // End of tint Rectangle

                                Rectangle {                                                                            // Dark center dot (decorative)
                                    width: root.s(40); height: root.s(40)                                                // 40px size
                                    radius: root.s(20); color: "#000000"                                                  // Black circle
                                    opacity: 0.8; anchors.centerIn: parent                                                 // 80% opacity, centered
                                }                                                                                      // End of center dot
                            }                                                                                         // End of art container Item
                            
                            NumberAnimation on rotation {                                                               // Continuous rotation of the frame
                                from: 0; to: 360; duration: 8000                                                          // Full rotation every 8 seconds
                                loops: Animation.Infinite                                                                  // Loop forever
                                running: true                                                                              // Start immediately
                                paused: root.musicData.status !== "Playing"                                                 // Pause rotation when not playing
                            }                                                                                          // End of rotation animation
                        }                                                                                            // End of cover frame Rectangle
                    }                                                                                              // End of cover art Item

                    ColumnLayout {                                                                                 // Right column: text info and controls
                        Layout.fillWidth: true                                                                       // Fill remaining width
                        Layout.alignment: Qt.AlignVCenter                                                             // Center vertically
                        spacing: root.s(15)                                                                           // 15px spacing between sections

                        // TEXT INFO CHUNK                                                                           // Subsection comment
                        ColumnLayout {                                                                               // Column for track title, artist, device info
                            spacing: root.s(6)                                                                         // 6px spacing between text elements
                            opacity: root.introText                                                                     // Fade in with introText
                            transform: Translate { x: root.s(30) * (1 - root.introText) }                                // Slide in from right (30px) as introText goes 0→1
                            
                            // HARD-LOCKED SEAMLESS INFINITE MARQUEE                                                  // Comment - scrolling title marquee
                            Item {                                                                                     // Container for marquee
                                id: titleClipRect                                                                        // Assign id "titleClipRect"
                                Layout.fillWidth: true                                                                   // Fill width
                                Layout.preferredHeight: root.s(28)                                                        // Fixed height 28px
                                clip: true                                                                                // Clip content (hides overflow for scrolling effect)

                                // This is the distance between the end of the text and the clone                       // Comment explaining spacing
                                property int marqueeSpacing: root.s(60)                                                    // 60px gap between original text and its clone

                                Item {                                                                                   // Marquee animation container
                                    id: marqueeContainer                                                                   // Assign id "marqueeContainer"
                                    height: parent.height                                                                   // Match parent height

                                    Row {                                                                                  // Horizontal row of text + clone
                                        spacing: titleClipRect.marqueeSpacing                                                 // Gap between original and clone
                                        Text {                                                                               // Original title text
                                            id: titleTextMain                                                                  // Assign id "titleTextMain"
                                            text: root.musicData.title                                                          // Display track title
                                            color: root.dynamicTextColor                                                       // Use dynamic text color from album art
                                            font.family: "JetBrains Mono"                                                       // JetBrains Mono font
                                            font.pixelSize: root.s(20)                                                          // Scaled 20px font
                                            font.bold: true                                                                     // Bold text
                                            Behavior on color { ColorAnimation { duration: 600 } }                                // Smooth color transition

                                            // Only animate if the text is physically wider than our container                // Comment explaining animation trigger
                                            onTextChanged: {                                                                   // When text changes (new track)
                                                marqueeContainer.x = 0;                                                          // Reset marquee position to start
                                                if (implicitWidth > titleClipRect.width) {                                         // If text is wider than container
                                                    titleAnim.restart();                                                            // Start/restart scrolling animation
                                                } else {                                                                          // If text fits
                                                    titleAnim.stop();                                                               // Stop animation
                                                }                                                                                // End of if-else
                                            }                                                                                  // End of onTextChanged
                                        }                                                                                    // End of titleTextMain
                                        // The clone that creates the seamless endless loop                                // Comment explaining clone purpose
                                        Text {                                                                               // Clone title text for seamless loop
                                            id: titleTextClone                                                                   // Assign id "titleTextClone"
                                            text: root.musicData.title                                                           // Same text as original
                                            color: root.dynamicTextColor                                                        // Same dynamic color
                                            font.family: "JetBrains Mono"                                                       // Same font
                                            font.pixelSize: root.s(20)                                                           // Same size
                                            font.bold: true                                                                      // Same bold
                                            visible: titleTextMain.implicitWidth > titleClipRect.width                             // Only visible when scrolling is needed
                                        }                                                                                    // End of titleTextClone
                                    }                                                                                      // End of Row

                                    SequentialAnimation on x {                                                              // Sequential animation for marquee X position
                                        id: titleAnim                                                                         // Assign id "titleAnim"
                                        loops: Animation.Infinite                                                               // Loop forever
                                        running: titleTextMain.implicitWidth > titleClipRect.width                               // Only run when text is wider than container

                                        // 1. Stop for a few seconds in the initial position                               // Comment explaining pause
                                        PauseAnimation { duration: 3000 }                                                      // Pause 3 seconds at start before scrolling

                                        // 2. Smoothly run left until the clone is exactly where the original started      // Comment explaining scroll
                                        NumberAnimation {                                                                      // Scroll animation
                                            from: 0                                                                              // Start at position 0
                                            to: -(titleTextMain.implicitWidth + titleClipRect.marqueeSpacing)                     // Scroll left by text width + gap
                                            // The duration calculates dynamically to maintain a constant scroll speed         // Comment explaining dynamic duration
                                            duration: (titleTextMain.implicitWidth + titleClipRect.marqueeSpacing) * 25           // Duration = (width + gap) * 25ms per pixel = constant speed
                                        }                                                                                     // End of NumberAnimation
                                        
                                        // 3. Instantly snap back to 0 without stopping (creating the seamless loop)        // Comment explaining snap-back
                                        PropertyAction { target: marqueeContainer; property: "x"; value: 0 }                   // Instant reset to 0 - creates illusion of infinite loop
                                    }                                                                                       // End of SequentialAnimation
                                }                                                                                          // End of marqueeContainer
                            }                                                                                            // End of titleClipRect

                            Text {                                                                                       // Artist text
                                text: root.musicData.artist ? "BY " + root.musicData.artist : ""                            // "BY ArtistName" or empty if no artist
                                color: root.subtext0 // Better matugen match                                                // Subtext0 color (secondary text)
                                font.family: "JetBrains Mono"                                                               // JetBrains Mono font
                                font.pixelSize: root.s(14)                                                                   // Scaled 14px
                                font.bold: true                                                                              // Bold text
                                elide: Text.ElideRight                                                                       // Elide with ... if too long
                                maximumLineCount: 1 // Strict 1 line                                                          // Single line only
                                Layout.fillWidth: true                                                                       // Fill width
                                Layout.preferredHeight: root.s(20)                                                           // Fixed height 20px
                            }                                                                                            // End of artist Text
                            RowLayout {                                                                                  // Row for device and source info
                                spacing: root.s(10)                                                                        // 10px between elements
                                Rectangle {                                                                              // Device info pill
                                    color: "#1AFFFFFF"                                                                     // Semi-transparent white (10% opacity)
                                    radius: root.s(4)                                                                      // Slightly rounded corners
                                    Layout.preferredHeight: root.s(24)                                                     // Fixed height 24px
                                    Layout.preferredWidth: pillContent.width + root.s(20)                                   // Width = content + 20px padding
                                    RowLayout {                                                                           // Content inside pill
                                        id: pillContent                                                                     // Assign id for width calculation
                                        anchors.centerIn: parent                                                            // Center in pill
                                        spacing: root.s(6)                                                                  // 6px between icon and text
                                        Text { text: root.musicData.deviceIcon || "󰓃"; color: root.mauve; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(14) }  // Device icon (Nerd Font), mauve color
                                        Text { text: root.musicData.deviceName || "Speaker"; color: root.overlay2; font.family: "JetBrains Mono"; font.pixelSize: root.s(12); font.bold: true }  // Device name, overlay2 color, bold
                                    }                                                                                  // End of RowLayout
                                }                                                                                      // End of device pill Rectangle
                                Text {                                                                                 // Source text
                                    text: "VIA " + (root.musicData.source || "Offline")                                   // "VIA Firefox" or "VIA Offline"
                                    color: root.overlay2 // Better matugen match                                          // Overlay2 color
                                    font.family: "JetBrains Mono"                                                         // JetBrains Mono font
                                    font.pixelSize: root.s(12)                                                             // Scaled 12px
                                    font.bold: true                                                                        // Bold
                                    font.italic: true                                                                      // Italic
                                }                                                                                      // End of source Text
                            }                                                                                         // End of RowLayout
                        }                                                                                            // End of text info ColumnLayout

                        // PROGRESS AREA CHUNK                                                                       // Subsection comment
                        ColumnLayout {                                                                               // Column for progress bar and time labels
                            Layout.fillWidth: true                                                                     // Fill width
                            spacing: root.s(5)                                                                          // 5px spacing
                            opacity: root.introControls                                                                  // Fade in with introControls
                            transform: Translate { x: root.s(20) * (1 - root.introControls); y: root.s(10) * (1 - root.introControls) }  // Slide in from right and slightly down

                            Slider {                                                                                   // Progress bar slider
                                id: progBar                                                                              // Assign id "progBar"
                                Layout.fillWidth: true                                                                    // Fill width
                                Layout.preferredHeight: root.s(20)                                                         // Fixed height 20px
                                from: 0; to: 100                                                                           // Range 0 to 100 (percentage)

                                Connections {                                                                              // Connections to root signals
                                    target: root                                                                             // Listen to root
                                    function onMusicDataChanged() {                                                           // When music data changes
                                        if (!progBar.pressed && !root.userIsSeeking) {                                           // Only update if user is NOT dragging the slider
                                            if (root.musicData && root.musicData.percent !== undefined) {                         // If percent data exists
                                                var p = Number(root.musicData.percent);                                             // Convert to number
                                                if (!isNaN(p)) progBar.value = p;                                                    // Set slider value if valid number
                                            }                                                                                    // End of if
                                        }                                                                                      // End of if
                                    }                                                                                        // End of onMusicDataChanged
                                }                                                                                          // End of Connections

                                Behavior on value {                                                                        // Animate value changes
                                    enabled: !progBar.pressed && !root.userIsSeeking                                          // Only animate when not being dragged by user
                                    NumberAnimation { duration: 400; easing.type: Easing.OutSine }                              // Smooth 400ms animation
                                }                                                                                          // End of Behavior

                                onPressedChanged: {                                                                        // When press state changes
                                    if (pressed) {                                                                           // Slider is being pressed (user started dragging)
                                        root.userIsSeeking = true;                                                             // Set seeking flag (blocks polling)
                                        seekDebounceTimer.stop();                                                              // Stop debounce timer
                                    } else {                                                                                 // Slider released (user finished dragging)
                                        var temp = Object.assign({}, root.musicData);                                           // Copy current music data
                                        temp.percent = value;                                                                   // Set percent to slider value
                                        root.musicData = temp;                                                                  // Update musicData (triggers UI)

                                        var safePlayer = root.musicData.playerName ? root.musicData.playerName : "";              // Get player name safely
                                        root.execCmd(`$HOME/.config/hypr/scripts/quickshell/music/player_control.sh seek ${value.toFixed(2)} ${root.musicData.length} "${safePlayer}"`);  // Execute seek command with percentage and length
                                        
                                        seekDebounceTimer.restart();                                                            // Restart debounce timer (blocks polling for 2.5 seconds)
                                    }                                                                                        // End of if-else
                                }                                                                                          // End of onPressedChanged

                                background: Item {                                                                         // Custom background for slider
                                    x: progBar.leftPadding                                                                    // X position with padding
                                    y: progBar.topPadding + (progBar.availableHeight - root.s(12)) / 2                         // Center vertically
                                    width: progBar.availableWidth                                                              // Full available width
                                    height: root.s(12)                                                                         // Height 12px

                                    // Shadows mimicking the EQ slider background                                            // Comment describing shadow effect
                                    Rectangle {                                                                               // Background track shadow
                                        anchors.fill: parent                                                                     // Fill parent
                                        radius: root.s(6)                                                                        // Rounded corners
                                        // Dynamic tint: surface0 with 70% opacity for a softer dark look                       // Comment explaining color
                                        color: Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.7)                    // Surface0 at 70% opacity

                                        layer.enabled: true                                                                      // Enable layer for shadow
                                        layer.effect: MultiEffect {                                                               // Shadow effect
                                            shadowEnabled: true                                                                     // Enable shadow
                                            shadowColor: "#000000"                                                                  // Black shadow
                                            shadowOpacity: 0.9                                                                     // 90% shadow opacity
                                            shadowBlur: 0.5                                                                        // Small blur
                                            shadowVerticalOffset: 1                                                                // 1px down offset
                                        }                                                                                        // End of layer.effect
                                    }                                                                                          // End of shadow Rectangle

                                    // Masked Gradient Fill (Completely redesigned for smooth, light, synergistic palette)    // Comment for gradient fill
                                    Item {                                                                                     // Container for gradient fill with mask
                                        width: progBar.handle.x - progBar.leftPadding + (progBar.handle.width / 2)                 // Width from left edge to handle center
                                        height: parent.height                                                                     // Full height
                                        
                                        layer.enabled: true                                                                       // Enable layer
                                        layer.effect: MultiEffect {                                                                // Mask effect
                                            maskEnabled: true                                                                       // Enable masking
                                            maskSource: sliderFillMask                                                              // Use fill mask to clip gradient
                                        }                                                                                        // End of layer.effect

                                        Rectangle {                                                                              // Mask rectangle (invisible)
                                            id: sliderFillMask                                                                     // Assign id
                                            width: parent.width                                                                    // Match container width
                                            height: parent.height                                                                  // Match height
                                            radius: root.s(6)                                                                      // Rounded corners
                                            visible: false                                                                         // Hidden - mask only
                                            layer.enabled: true                                                                    // Enable for masking
                                        }                                                                                       // End of sliderFillMask

                                        Rectangle {                                                                              // Flowing gradient fill
                                            width: root.s(2000)                                                                    // Very wide (2000px) to allow sliding
                                            height: parent.height                                                                  // Match height
                                            // Sliding the gradient perfectly by exactly half its width (1000px)                  // Comment explaining slide
                                            x: -(root.catppuccinFlowOffset * root.s(1000))                                           // Slide left by flow offset * 1000px (animates continuously)
                                            gradient: Gradient {                                                                   // Horizontal gradient
                                                orientation: Gradient.Horizontal                                                      // Left to right
                                                // Mathematically precise loops with lighter, cooler colors & theme change support  // Comment
                                                GradientStop { position: 0.0000; color: Qt.lighter(root.blue, 1.2); Behavior on color { ColorAnimation { duration: 800 } } }  // Lightened blue at 0%
                                                GradientStop { position: 0.1666; color: Qt.lighter(root.sapphire, 1.15); Behavior on color { ColorAnimation { duration: 800 } } }  // Lightened sapphire at 16.66%
                                                GradientStop { position: 0.3333; color: Qt.lighter(root.mauve, 1.15); Behavior on color { ColorAnimation { duration: 800 } } }  // Lightened mauve at 33.33%
                                                GradientStop { position: 0.5000; color: Qt.lighter(root.blue, 1.2); Behavior on color { ColorAnimation { duration: 800 } } }  // Lightened blue at 50%
                                                GradientStop { position: 0.6666; color: Qt.lighter(root.sapphire, 1.15); Behavior on color { ColorAnimation { duration: 800 } } }  // Lightened sapphire at 66.66%
                                                GradientStop { position: 0.8333; color: Qt.lighter(root.mauve, 1.15); Behavior on color { ColorAnimation { duration: 800 } } }  // Lightened mauve at 83.33%
                                                GradientStop { position: 1.0000; color: Qt.lighter(root.blue, 1.2); Behavior on color { ColorAnimation { duration: 800 } } }  // Lightened blue at 100%
                                            }                                                                                    // End of Gradient
                                        }                                                                                      // End of flowing gradient Rectangle
                                    }                                                                                         // End of gradient container Item
                                }                                                                                             // End of background

                                handle: Rectangle {                                                                            // Slider handle (thumb)
                                    x: progBar.leftPadding + progBar.visualPosition * (progBar.availableWidth - width)            // X position follows slider value
                                    y: progBar.topPadding + (progBar.availableHeight - height) / 2                                 // Center vertically
                                    implicitWidth: root.s(18)                                                                     // Default width 18px
                                    implicitHeight: root.s(18)                                                                    // Default height 18px
                                    width: root.s(18); height: root.s(18)                                                          // Explicit size 18px
                                    radius: root.s(9); color: root.text                                                             // Circular (radius=half), text color
                                    scale: progBar.pressed ? 1.3 : 1.0                                                              // Scale up 30% when pressed
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }             // Bouncy scale animation
                                }                                                                                              // End of handle
                            }                                                                                               // End of Slider

                            RowLayout {                                                                                    // Time labels row
                                Layout.fillWidth: true                                                                       // Fill width
                                Text { text: root.musicData.positionStr || "00:00"; color: root.overlay2; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: root.s(13) }  // Current position (left)
                                Item { Layout.fillWidth: true }                                                               // Spacer between times
                                Text { text: root.musicData.lengthStr || "00:00"; color: root.overlay2; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: root.s(13) }  // Total length (right)
                            }                                                                                            // End of RowLayout
                        }                                                                                              // End of progress ColumnLayout

                        // MEDIA CONTROLS CHUNK                                                                         // Subsection comment
                        RowLayout {                                                                                    // Row for media control buttons
                            Layout.alignment: Qt.AlignHCenter                                                            // Center horizontally
                            spacing: root.s(30)                                                                           // 30px between buttons
                            opacity: root.introControls                                                                    // Fade in with introControls
                            transform: Translate { y: root.s(20) * (1 - root.introControls) }                               // Slide up from below (20px) as introControls goes 0→1

                            MouseArea {                                                                                  // Previous track button
                                width: root.s(30); height: root.s(30)                                                       // 30x30px clickable area
                                cursorShape: Qt.PointingHandCursor                                                           // Hand cursor on hover
                                onClicked: root.execCmd("playerctl previous")                                                  // Execute "playerctl previous" on click
                                Text { anchors.centerIn: parent; text: ""; color: parent.pressed ? root.text : root.overlay2; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(24) }  // Previous icon (Nerd Font), color changes on press
                            }                                                                                            // End of previous MouseArea
                            MouseArea {                                                                                  // Play/Pause button
                                id: playPauseBtn                                                                           // Assign id "playPauseBtn"
                                width: root.s(50); height: root.s(50)                                                       // Larger button 50x50px
                                cursorShape: Qt.PointingHandCursor                                                           // Hand cursor
                                onClicked: {                                                                                // On click:
                                    root.userToggledPlay = true;                                                              // Set toggle flag (blocks polling override)
                                    playDebounceTimer.restart();                                                               // Restart debounce timer (1.5 seconds)
                                    var temp = Object.assign({}, root.musicData);                                               // Copy music data
                                    temp.status = (temp.status === "Playing" ? "Paused" : "Playing");                            // Toggle status
                                    root.musicData = temp;                                                                      // Update musicData (immediate UI feedback)
                                    root.execCmd("playerctl play-pause");                                                       // Execute play-pause toggle
                                }                                                                                           // End of onClicked

                                // Fluid Ripple Animation Element                                                          // Comment describing ripple effect
                                Rectangle {                                                                                // Ripple circle
                                    id: playPulse                                                                             // Assign id "playPulse"
                                    anchors.centerIn: parent                                                                   // Center on button
                                    width: parent.width                                                                        // Same size as button
                                    height: parent.height                                                                      // Same size
                                    radius: width / 2                                                                          // Circular
                                    color: root.mauve                                                                          // Mauve ripple color
                                    opacity: 0                                                                                 // Start invisible
                                    scale: 1                                                                                   // Start at normal size

                                    NumberAnimation {                                                                         // Scale animation
                                        id: playPulseScaleAnim                                                                   // Assign id for triggering
                                        target: playPulse                                                                        // Target the ripple
                                        property: "scale"                                                                        // Animate scale
                                        from: 1.0; to: 1.8                                                                       // Grow from 1x to 1.8x
                                        duration: 500                                                                            // Over 500ms
                                        easing.type: Easing.OutQuart                                                             // OutQuart easing
                                    }                                                                                         // End of NumberAnimation
                                    NumberAnimation {                                                                         // Fade animation
                                        id: playPulseFadeAnim                                                                    // Assign id
                                        target: playPulse                                                                        // Target the ripple
                                        property: "opacity"                                                                      // Animate opacity
                                        from: 0.5; to: 0.0                                                                       // Fade from 50% to 0%
                                        duration: 500                                                                            // Over 500ms
                                        easing.type: Easing.OutQuart                                                             // OutQuart easing
                                    }                                                                                         // End of NumberAnimation

                                    function trigger() {                                                                      // Function to trigger both animations
                                        playPulseScaleAnim.restart();                                                           // Restart scale animation
                                        playPulseFadeAnim.restart();                                                            // Restart fade animation
                                    }                                                                                         // End of trigger function
                                }                                                                                          // End of playPulse Rectangle

                                Text {                                                                                     // Play/Pause icon
                                    anchors.centerIn: parent                                                                  // Center on button
                                    text: root.musicData.status === "Playing" ? "" : ""                                      // Pause icon when playing, play icon otherwise
                                    color: parent.pressed ? root.pink : root.mauve                                               // Pink when pressed, mauve normally
                                    font.family: "Iosevka Nerd Font"                                                             // Nerd Font for icons
                                    font.pixelSize: root.s(42)                                                                    // Large 42px icon
                                    scale: parent.pressed ? 0.8 : 1.0                                                              // Shrink slightly when pressed
                                    Behavior on color { ColorAnimation { duration: 150 } }                                          // Smooth color transition
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }            // Bouncy scale transition
                                }                                                                                          // End of play/pause icon Text
                            }                                                                                            // End of play/pause MouseArea
                            MouseArea {                                                                                  // Next track button
                                width: root.s(30); height: root.s(30)                                                       // 30x30px
                                cursorShape: Qt.PointingHandCursor                                                           // Hand cursor
                                onClicked: root.execCmd("playerctl next")                                                      // Execute "playerctl next"
                                Text { anchors.centerIn: parent; text: ""; color: parent.pressed ? root.text : root.overlay2; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(24) }  // Next icon, color changes on press
                            }                                                                                            // End of next MouseArea
                        }                                                                                              // End of media controls RowLayout
                    }                                                                                                // End of right ColumnLayout
                }                                                                                                  // End of top RowLayout

                // ==========================================                                                          // Decorative separator
                // SEPARATOR                                                                                            // Section header
                // ==========================================                                                          // Decorative separator
                Rectangle {                                                                                          // Horizontal separator line
                    Layout.fillWidth: true                                                                             // Full width
                    Layout.preferredHeight: root.s(2)                                                                    // 2px height
                    Layout.topMargin: root.s(20)                                                                         // 20px margin above
                    Layout.bottomMargin: root.s(20)                                                                      // 20px margin below
                    color: "#1AFFFFFF"                                                                                   // Semi-transparent white (10% opacity)
                    radius: root.s(1)                                                                                    // Slightly rounded

                    opacity: root.introSeparator                                                                         // Fade in with introSeparator
                    transform: Translate { y: root.s(15) * (1 - root.introSeparator) }                                    // Slide up from below as introSeparator goes 0→1
                }                                                                                                  // End of separator Rectangle

                // ==========================================                                                          // Decorative separator
                // EQUALIZER                                                                                             // Section header
                // ==========================================                                                          // Decorative separator
                ColumnLayout {                                                                                       // Column for equalizer section
                    Layout.fillWidth: true                                                                            // Full width
                    spacing: root.s(15)                                                                                // 15px spacing

                    // Header Row                                                                                      // Subsection comment
                    RowLayout {                                                                                      // Row for EQ header (label, apply button, preset name)
                        Layout.fillWidth: true                                                                         // Full width
                        opacity: root.introEqHeader                                                                     // Fade in with introEqHeader
                        transform: Translate { y: root.s(15) * (1 - root.introEqHeader) }                                // Slide up from below

                        Text { text: "Equalizer"; color: root.mauve; font.family: "JetBrains Mono"; font.pixelSize: root.s(16); font.bold: true; Layout.fillWidth: true }  // "Equalizer" label in mauve, bold
                        
                        // Redesigned Apply Button                                                                     // Comment for apply button
                        Rectangle {                                                                                  // Apply/Saved button
                            Layout.preferredHeight: root.s(28)                                                         // Height 28px
                            Layout.preferredWidth: applyTxt.width + root.s(30)                                           // Width = text width + 30px padding
                            radius: root.s(10)                                                                          // Rounded corners
                            color: root.eqData.pending ? root.mauve : root.surface1                                       // Mauve when pending (unsaved), surface1 when saved
                            border.color: root.eqData.pending ? root.mauve : root.surface2                                 // Mauve border when pending, surface2 when saved
                            border.width: 1                                                                              // 1px border
                            
                            Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutCubic } }           // Smooth color transition
                            Behavior on border.color { ColorAnimation { duration: 300; easing.type: Easing.OutCubic } }    // Smooth border color transition

                            layer.enabled: root.eqData.pending                                                           // Enable layer when pending (for shadow effect)
                            layer.effect: MultiEffect {                                                                   // Shadow when pending
                                shadowEnabled: true; shadowColor: root.mauve; shadowOpacity: 0.4; shadowBlur: 0.6            // Mauve shadow at 40% opacity
                            }                                                                                            // End of layer.effect

                            Text {                                                                                     // Button label
                                id: applyTxt                                                                             // Assign id for width calculation
                                anchors.centerIn: parent                                                                  // Center in button
                                text: root.eqData.pending ? "Apply" : "Saved"                                              // "Apply" when pending, "Saved" otherwise
                                color: root.eqData.pending ? root.base : root.subtext0                                      // Base color text on mauve, subtext0 on surface1
                                font.family: "JetBrains Mono"                                                              // JetBrains Mono font
                                font.pixelSize: root.s(12)                                                                 // 12px font
                                font.bold: true                                                                            // Bold
                                Behavior on color { ColorAnimation { duration: 300 } }                                      // Smooth color transition
                            }                                                                                           // End of Text
                            MouseArea {                                                                                // Click area for apply
                                anchors.fill: parent                                                                      // Fill button
                                cursorShape: root.eqData.pending ? Qt.PointingHandCursor : Qt.ArrowCursor                   // Hand cursor when clickable, arrow otherwise
                                onClicked: {                                                                              // On click:
                                    if (root.eqData.pending) {                                                              // Only if there are unsaved changes
                                        var temp = Object.assign({}, root.eqData);                                             // Copy eqData
                                        temp.pending = false;                                                                  // Clear pending flag
                                        root.eqData = temp;                                                                    // Update eqData (UI feedback)
                                        
                                        // Blind the polling process to stop it from fetching old data                      // Comment explaining anti-jitter
                                        root.lastEqUpdate = Date.now();                                                       // Set timestamp to block polling for 2 seconds
                                        
                                        root.triggerEqLightning();                                                            // Trigger lightning animation
                                        root.execCmd("$HOME/.config/hypr/scripts/quickshell/music/equalizer.sh apply");       // Execute apply command
                                    }                                                                                      // End of if
                                }                                                                                        // End of onClicked
                            }                                                                                          // End of MouseArea
                        }                                                                                            // End of apply button Rectangle
                        Text { text: root.eqData.preset || "Flat"; color: root.subtext0; font.family: "JetBrains Mono"; font.pixelSize: root.s(14); font.bold: true; Layout.leftMargin: root.s(15) }  // Current preset name display
                    }                                                                                             // End of header RowLayout

                    // Eq Sliders Container with Canvas Lightning Overlay                                          // Comment for sliders section
                    Item {                                                                                        // Container for EQ sliders and lightning canvas
                        Layout.fillWidth: true                                                                     // Full width
                        Layout.preferredHeight: root.s(180)                                                         // Fixed height 180px

                        Row {                                                                                      // Horizontal row of sliders
                            id: eqSliderRow                                                                          // Assign id "eqSliderRow"
                            anchors.fill: parent                                                                      // Fill container
                            z: 1 // Ensures sliders (and their handles) render over the lightning                       // Higher z-index than canvas (renders on top)

                            Repeater {                                                                               // Repeater creates 10 slider delegates
                                model: [                                                                              // Model array of 10 objects with index and label
                                    {"idx": 1, "lbl": "31"}, {"idx": 2, "lbl": "63"}, {"idx": 3, "lbl": "125"},        // Band 1-3: 31Hz, 63Hz, 125Hz
                                    {"idx": 4, "lbl": "250"}, {"idx": 5, "lbl": "500"}, {"idx": 6, "lbl": "1k"},       // Band 4-6: 250Hz, 500Hz, 1kHz
                                    {"idx": 7, "lbl": "2k"}, {"idx": 8, "lbl": "4k"}, {"idx": 9, "lbl": "8k"},         // Band 7-9: 2kHz, 4kHz, 8kHz
                                    {"idx": 10, "lbl": "16k"}                                                           // Band 10: 16kHz
                                ]                                                                                    // End of model
                                delegate: Item {                                                                     // Delegate for each slider
                                    id: sliderDelegate                                                                // Assign id "sliderDelegate"
                                    width: eqSliderRow.width / 10                                                      // Each takes 1/10 of row width
                                    height: eqSliderRow.height                                                         // Full row height

                                    // --- ENHANCED SLIDER CASCADING ANIMATION ---                                   // Comment for cascade animation
                                    opacity: root.introEqSliders                                                       // Fade in with introEqSliders
                                    transform: Translate {                                                              // Slide up with cascade delay based on index
                                        y: root.s(30) * (1 - root.introEqSliders) + (index * root.s(8) * (1 - root.introEqSliders))  // More delay for higher indices = waterfall effect
                                    }                                                                                // End of transform

                                    // Mathematical evaluation mapping to the exact timeline of the strike            // Comment for lightning interaction
                                    property real dist: root.eqLightningProgress - (modelData.idx - 1)                  // Distance of lightning from this band (0 to 1 range when passing)
                                    property real hitPulse: dist >= 0 && dist < 1.0 ? Math.sin((dist) * Math.PI) : 0.0  // Pulse intensity: sine curve peaking at dist=0.5, 0 when not passing
                                    
                                    // Massive Energy Pulses                                                         // Comment for animation properties
                                    property real trackPulse: 0.0                                                     // Track pulse animation value (bolt passing through track)
                                    property real ringPulse: 0.0                                                      // Ring pulse animation value (outer shockwave)
                                    property real flashFade: 0.0                                                      // Flash fade animation value (track gradient intensity)
                                    property bool hasFired: false                                                     // Flag to ensure animations only fire once per bolt pass

                                    onDistChanged: {                                                                  // When distance property changes
                                        // Reset the fire lock when the animation sweeps past or starts over           // Comment explaining reset logic
                                        if (dist <= 0.05) {                                                             // If bolt is at/near start of this band
                                            hasFired = false;                                                              // Reset the fired flag
                                        } else if (dist > 0.4 && !hasFired) {                                            // If bolt is past 40% through and hasn't fired yet
                                            // Trigger strictly once per bolt passing over                               // Comment explaining single-trigger
                                            hasFired = true;                                                               // Set flag to prevent re-triggering
                                            trackPulseAnim.restart();                                                      // Restart track pulse animation
                                            ringPulseAnim.restart();                                                       // Restart ring shockwave animation
                                            flashFadeAnim.restart();                                                       // Restart flash fade animation
                                        }                                                                              // End of if-else
                                    }                                                                                // End of onDistChanged

                                    SequentialAnimation {                                                            // Track pulse animation sequence
                                        id: trackPulseAnim                                                              // Assign id
                                        // Animates the bolt perfectly down the track                                  // Comment
                                        NumberAnimation { target: sliderDelegate; property: "trackPulse"; from: 0.0; to: 1.0; duration: 1000; easing.type: Easing.OutQuart }  // Pulse from 0 to 1 over 1 second
                                    }                                                                                // End of trackPulseAnim
                                    SequentialAnimation {                                                            // Ring shockwave animation
                                        id: ringPulseAnim                                                              // Assign id
                                        // Explodes outward creating a physical shockwave                             // Comment
                                        NumberAnimation { target: sliderDelegate; property: "ringPulse"; from: 1.0; to: 0.0; duration: 1500; easing.type: Easing.OutExpo }  // Ring from 1 to 0 over 1.5 seconds
                                    }                                                                                // End of ringPulseAnim
                                    SequentialAnimation {                                                            // Flash fade animation
                                        id: flashFadeAnim                                                              // Assign id
                                        // Slowly cools the inner track gradient back to normal                      // Comment
                                        NumberAnimation { target: sliderDelegate; property: "flashFade"; from: 1.0; to: 0.0; duration: 1500; easing.type: Easing.OutSine }  // Flash from 1 to 0 over 1.5 seconds
                                    }                                                                                // End of flashFadeAnim

                                    ColumnLayout {                                                                   // Column for slider + label
                                        anchors.fill: parent                                                           // Fill delegate
                                        spacing: root.s(5)                                                              // 5px spacing
                                        Slider {                                                                        // Vertical EQ slider
                                            id: eqSlider                                                                  // Assign id "eqSlider"
                                            Layout.fillHeight: true                                                        // Fill available height
                                            Layout.alignment: Qt.AlignHCenter                                               // Center horizontally
                                            orientation: Qt.Vertical                                                        // Vertical orientation
                                            from: -12; to: 12                                                               // Range -12dB to +12dB
                                            stepSize: 1                                                                     // 1dB steps

                                            Connections {                                                                  // Connect to eqData changes
                                                target: root                                                                 // Listen to root
                                                function onEqDataChanged() {                                                  // When eqData updates
                                                    if (!eqSlider.pressed) {                                                    // Only update if not being dragged
                                                        if (root.eqData && root.eqData["b" + modelData.idx] !== undefined) {     // If band data exists
                                                            var p = Number(root.eqData["b" + modelData.idx]);                     // Get band value as number
                                                            if (!isNaN(p)) eqSlider.value = p;                                     // Set slider if valid number
                                                        }                                                                      // End of if
                                                    }                                                                         // End of if
                                                }                                                                            // End of onEqDataChanged
                                            }                                                                              // End of Connections

                                            Behavior on value {                                                            // Animate value changes
                                                enabled: !eqSlider.pressed                                                    // Only when not being dragged
                                                NumberAnimation {                                                              // Smooth animation
                                                    duration: 350                                                               // 350ms
                                                    easing.type: Easing.OutQuart                                                 // OutQuart easing
                                                }                                                                             // End of NumberAnimation
                                            }                                                                              // End of Behavior

                                            onPressedChanged: {                                                            // When press state changes
                                                if (!pressed) {                                                               // When released
                                                    var temp = Object.assign({}, root.eqData);                                   // Copy eqData
                                                    temp["b" + modelData.idx] = Math.round(value);                                // Update this band with rounded value
                                                    temp.preset = "Custom";                                                      // Set preset to "Custom"
                                                    temp.pending = true;                                                         // Mark as pending (unsaved)
                                                    root.eqData = temp;                                                          // Update eqData
                                                    
                                                    // Set lock here too to protect individual slider tweaks                   // Comment
                                                    root.lastEqUpdate = Date.now();                                              // Block polling for 2 seconds
                                                    
                                                    root.execCmd(`$HOME/.config/hypr/scripts/quickshell/music/equalizer.sh set_band ${modelData.idx} ${Math.round(value)}`);  // Execute set_band command
                                                }                                                                            // End of if
                                            }                                                                              // End of onPressedChanged

                                            background: Rectangle {                                                        // Slider track background
                                                id: trackBg                                                                   // Assign id
                                                x: eqSlider.leftPadding + (eqSlider.availableWidth - width) / 2                 // Center horizontally
                                                y: eqSlider.topPadding                                                          // Start at top
                                                implicitWidth: root.s(10)                                                       // Default width 10px
                                                implicitHeight: root.s(150)                                                     // Default height 150px
                                                width: root.s(10); height: eqSlider.availableHeight                              // Explicit size 10px wide, full height
                                                radius: root.s(4);                                                               // Rounded corners
                                                
                                                // Dynamic tint: surface0 with 70% opacity for a softer dark look              // Comment
                                                color: Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.7)            // Surface0 at 70% opacity

                                                layer.enabled: true                                                              // Enable layer for shadow
                                                layer.effect: MultiEffect {                                                       // Shadow effect
                                                    id: trackEffect                                                               // Assign id
                                                    shadowEnabled: true                                                            // Enable shadow
                                                    shadowColor: "#000000"                                                         // Black shadow
                                                    shadowOpacity: 0.9                                                            // 90% opacity
                                                    shadowBlur: 0.5                                                               // Small blur
                                                    shadowVerticalOffset: 1                                                       // 1px down
                                                }                                                                              // End of layer.effect

                                                // MASSIVE Outer Energy Shockwave Ring                                       // Comment for shockwave
                                                Rectangle {                                                                   // Outer ring
                                                    z: -1                                                                       // Behind track
                                                    anchors.centerIn: parent                                                      // Centered on track
                                                    width: parent.width + root.s(20) + sliderDelegate.ringPulse * root.s(40)       // Width expands with ringPulse (up to +40px)
                                                    height: parent.height + root.s(20) + sliderDelegate.ringPulse * root.s(60)     // Height expands (up to +60px)
                                                    radius: parent.radius + root.s(10) + sliderDelegate.ringPulse * root.s(20)     // Radius expands
                                                    color: "transparent"                                                          // Transparent fill
                                                    border.color: root.mauve                                                       // Mauve border
                                                    border.width: root.s(2) + sliderDelegate.ringPulse * root.s(4)                 // Border width expands with pulse
                                                    opacity: sliderDelegate.ringPulse * 0.8 * (1.0 - root.eqLightningFade)         // Opacity follows ringPulse and overall lightning fade
                                                    
                                                    layer.enabled: true                                                            // Enable layer for blur
                                                    layer.effect: MultiEffect { blurEnabled: true; blurMax: 32; blur: 1.0 }        // Blur to create glow effect
                                                }                                                                             // End of ring Rectangle

                                                // The Track Fill Base (FIXED THE SQUARE CORNERS ISSUE)                      // Comment for fill
                                                Item {                                                                         // Container for track fill with mask
                                                    width: parent.width                                                          // Full track width
                                                    height: (1 - eqSlider.visualPosition) * parent.height                          // Height from slider position to bottom
                                                    y: eqSlider.visualPosition * parent.height                                      // Start at slider position
                                                    
                                                    layer.enabled: true                                                            // Enable layer for masking
                                                    layer.effect: MultiEffect {                                                     // Mask effect
                                                        maskEnabled: true                                                            // Enable masking
                                                        maskSource: eqFillMask                                                       // Use fill mask for rounded corners
                                                    }                                                                            // End of layer.effect

                                                    Rectangle {                                                                  // Mask rectangle (invisible)
                                                        id: eqFillMask                                                            // Assign id
                                                        anchors.fill: parent                                                       // Fill container
                                                        radius: root.s(4)                                                          // Same radius as track
                                                        visible: false                                                             // Hidden
                                                        layer.enabled: true                                                        // Enable for masking
                                                    }                                                                           // End of eqFillMask

                                                    Rectangle {                                                                  // Track fill color
                                                        anchors.fill: parent                                                       // Fill container
                                                        color: root.blue                                                            // Blue fill

                                                        // Track Override: Changes entire gradient of track                      // Comment for flash effect
                                                        Rectangle {                                                               // Flash gradient overlay
                                                            anchors.fill: parent                                                     // Fill
                                                            opacity: sliderDelegate.flashFade                                         // Opacity follows flashFade animation
                                                            gradient: Gradient {                                                      // Vertical gradient for flash
                                                                orientation: Gradient.Vertical                                          // Top to bottom
                                                                GradientStop { position: 0.0; color: root.mauve }                      // Mauve at top
                                                                GradientStop { position: 0.5; color: root.blue }                       // Blue in middle
                                                                GradientStop { position: 1.0; color: "transparent" }                   // Transparent at bottom
                                                            }                                                                       // End of Gradient
                                                        }                                                                        // End of flash overlay

                                                        // The Internal Charging Surge Bolt                                       // Comment for bolt
                                                        Rectangle {                                                               // Surge bolt rectangle
                                                            width: parent.width                                                      // Full track width
                                                            height: root.s(80) // Massive physical bolt                              // 80px tall bolt
                                                            y: (sliderDelegate.trackPulse * (parent.height + height)) - height        // Moves from top to bottom with trackPulse
                                                            opacity: Math.sin(sliderDelegate.trackPulse * Math.PI) * 2.0 * (1.0 - root.eqLightningFade)  // Sine curve opacity, fades with lightning
                                                            
                                                            gradient: Gradient {                                                      // Vertical gradient for bolt
                                                                orientation: Gradient.Vertical                                          // Top to bottom
                                                                GradientStop { position: 0.0; color: "transparent" }                    // Transparent at top
                                                                GradientStop { position: 0.2; color: root.blue }                        // Blue at 20%
                                                                GradientStop { position: 0.5; color: root.text } // Theme integrated bright center  // Text color (bright) at center
                                                                GradientStop { position: 0.8; color: root.mauve }                       // Mauve at 80%
                                                                GradientStop { position: 1.0; color: "transparent" }                    // Transparent at bottom
                                                            }                                                                       // End of Gradient
                                                            
                                                            layer.enabled: true                                                       // Enable layer for shadow
                                                            layer.effect: MultiEffect {                                                // Glow effect on bolt
                                                                shadowEnabled: true; shadowColor: root.blue; shadowBlur: 1.0; shadowOpacity: 1.0  // Blue glow
                                                            }                                                                       // End of layer.effect
                                                        }                                                                        // End of bolt Rectangle
                                                    }                                                                          // End of fill Rectangle
                                                }                                                                            // End of fill container Item
                                            }                                                                              // End of background

                                            handle: Rectangle {                                                             // Slider handle (thumb)
                                                x: eqSlider.leftPadding + (eqSlider.availableWidth - width) / 2                // Center horizontally
                                                y: eqSlider.topPadding + eqSlider.visualPosition * (eqSlider.availableHeight - height)  // Position follows slider value
                                                implicitWidth: root.s(18)                                                     // Default 18px
                                                implicitHeight: root.s(18)                                                    // Default 18px
                                                width: root.s(18); height: root.s(18)                                          // Explicit size
                                                radius: root.s(9); color: root.text                                             // Circular, text color

                                                property var catColors: [root.mauve, root.pink, root.lavender, root.mauve, root.blue]  // Array of colors for handle glow

                                                // Core glow flare that cleanly fades out matching the canvas                  // Comment for glow
                                                Rectangle {                                                                   // Glow flare
                                                    anchors.centerIn: parent                                                    // Center on handle
                                                    width: parent.width + root.s(36) * sliderDelegate.hitPulse // Bigger bloom    // Width expands with hitPulse (up to +36px)
                                                    height: width                                                               // Keep circular
                                                    radius: width / 2                                                           // Circular
                                                    color: parent.catColors[index % parent.catColors.length]                     // Color from array based on index
                                                    opacity: sliderDelegate.hitPulse * (1.0 - root.eqLightningFade)              // Opacity follows hitPulse and fade
                                                    layer.enabled: true                                                          // Enable layer for blur
                                                    layer.effect: MultiEffect { blurEnabled: true; blurMax: 32; blur: 1.0 }       // Blur for glow effect
                                                }                                                                            // End of glow Rectangle

                                                // Pop the handle itself slightly as the beam passes                          // Comment for handle pop
                                                scale: 1.0 + (sliderDelegate.hitPulse * 0.4 * (1.0 - root.eqLightningFade))     // Scale up to 1.4x when bolt passes
                                            }                                                                              // End of handle
                                        }                                                                               // End of Slider
                                        Text {                                                                           // Frequency label below slider
                                            text: modelData.lbl                                                             // Display frequency label (e.g., "1k")
                                            color: root.overlay1                                                             // Overlay1 color
                                            font.family: "JetBrains Mono"                                                    // JetBrains Mono font
                                            font.pixelSize: root.s(10)                                                        // 10px font
                                            font.bold: true                                                                  // Bold
                                            Layout.alignment: Qt.AlignHCenter                                                 // Center horizontally
                                        }                                                                                // End of label Text
                                    }                                                                                  // End of ColumnLayout
                                }                                                                                    // End of delegate Item
                            }                                                                                      // End of Repeater
                        }                                                                                         // End of Row (sliders)

                        // --- THE FLUID CANVAS LIGHTNING (Optimized for Realism and multiple waves) ---           // Comment for lightning canvas
                        Canvas {                                                                                  // Canvas for drawing lightning bolts
                            id: lightningCanvas                                                                      // Assign id "lightningCanvas"
                            anchors.fill: parent                                                                      // Fill container
                            opacity: 1.0 - root.eqLightningFade                                                        // Fade out with lightningFade (inverted: 1=invisible)
                            z: 0 // Draw securely behind the sliders                                                    // Behind sliders (lower z-index)

                            // Force hardware FBO backend instead of slow software rendering                          // Comment for performance
                            renderTarget: Canvas.FramebufferObject                                                       // Use FramebufferObject for GPU-accelerated rendering

                            // GPU Layer effect to provide bloom WITHOUT locking up the CPU via ctx.shadowBlur         // Comment for bloom
                            layer.enabled: true                                                                          // Enable layer
                            layer.effect: MultiEffect {                                                                   // Bloom/glow effect
                                shadowEnabled: true                                                                         // Enable shadow (used as bloom)
                                shadowColor: root.mauve                                                                     // Mauve glow color
                                shadowBlur: 1.0 // 1.0 is max blur in MultiEffect                                            // Maximum blur
                                shadowOpacity: 0.6                                                                          // 60% opacity
                                shadowVerticalOffset: 0                                                                     // No offset
                                shadowHorizontalOffset: 0                                                                   // No offset
                            }                                                                                            // End of layer.effect

                            Timer {                                                                                      // Timer for canvas redraw (~60fps)
                                interval: 16 // ~60fps for silky smooth arcs                                               // 16ms = ~60 frames per second
                                running: root.eqLightningFade < 1.0 && root.eqLightningProgress > 0.0                       // Only run when lightning is visible
                                repeat: true                                                                               // Repeat while running
                                onTriggered: lightningCanvas.requestPaint()                                                  // Request repaint on each tick
                            }                                                                                            // End of Timer

                            onPaint: {                                                                                   // Paint handler - draws the lightning
                                var ctx = getContext("2d");                                                                // Get 2D drawing context
                                ctx.clearRect(0, 0, width, height);                                                         // Clear the canvas

                                if (root.eqLightningProgress <= 0.0 || root.eqLightningFade >= 1.0) return;                  // Exit if lightning shouldn't be visible

                                var time = Date.now() / 1000;                                                               // Current time in seconds (for noise animation)
                                var maxIdx = root.eqLightningProgress; // 0 to 9                                              // How far the bolt has progressed (0 to 10)

                                ctx.lineJoin = "round";                                                                     // Round line joins for smooth corners
                                ctx.lineCap = "round";                                                                      // Round line caps

                                // Step 1: Map the spatial coordinates of the 10 handles                                   // Comment for handle mapping
                                var pts = [];                                                                                // Array to store handle positions
                                for (var i = 1; i <= 10; i++) {                                                               // Loop through 10 bands
                                    var val = root.eqData["b" + i] !== undefined ? Number(root.eqData["b" + i]) : 0;            // Get band value, default 0
                                    var norm = 1.0 - ((val + 12) / 24);                                                         // Normalize value to 0-1 range (inverted: +12dB=0, -12dB=1)
                                    
                                    // Py uses margins rough mapping to the handles visible track                            // Comment for position calculation
                                    var py = root.s(10) + norm * (height - root.s(35));                                        // Y position: top margin + normalized * available height
                                    var px = (i - 0.5) * (width / 10);                                                         // X position: center of each band column
                                    pts.push({ x: px, y: py });                                                                // Add point to array
                                }                                                                                            // End of for loop

                                // Step 2: Draw the multi-wave arcing structure                                              // Comment for wave drawing
                                // Strand 0: Slow erratic mauve glow/wave                                                    // Strand descriptions
                                // Strand 1: Complex pink glow
                                // Strand 2: Crackling secondary core
                                // Strand 3: Hot white center core
                                for (var s = 0; s < 4; s++) {                                                                 // Draw 4 strands (from outer glow to inner core)
                                    ctx.beginPath();                                                                           // Begin new path
                                    ctx.moveTo(pts[0].x, pts[0].y);                                                            // Start at first handle position

                                    for (var i = 0; i < pts.length - 1; i++) {                                                  // Loop through handle pairs (segments)
                                        if (i > maxIdx) break; // Stop drawing ahead of current progress                         // Stop if past lightning progress

                                        var p1 = pts[i];                                                                         // Start point
                                        var p2 = pts[i+1];                                                                       // End point

                                        var fraction = 1.0;                                                                      // How much of this segment to draw
                                        if (maxIdx < i + 1) {                                                                    // If progress ends within this segment
                                            fraction = maxIdx - i;                                                                // Calculate partial segment fraction
                                        }                                                                                       // End of if

                                        // Subdivision steps create the crackle noise                                          // Comment for subdivision
                                        var steps = s === 3 ? 6 : 8; // Ultra smooth subdivision, s=3 core has less subdiv for straighter look  // 8 steps for glow, 6 for core
                                        for (var j = 1; j <= steps; j++) {                                                       // Subdivide each segment
                                            var t = j / steps;                                                                    // Progress within segment (0 to 1)
                                            if (t > fraction) t = fraction;                                                        // Clamp to fraction

                                            var cx = p1.x + (p2.x - p1.x) * t;                                                    // Interpolated X position
                                            var cy = p1.y + (p2.y - p1.y) * t;                                                    // Interpolated Y position

                                            // Wave calculations: create distinct arcs and noise branching                       // Comment for wave math
                                            var envelope = Math.sin(t * Math.PI);                                                  // Envelope: sine curve peaks at midpoint

                                            // s=3 core noise (straightest) to s=0 outer glow noise (most waves)                // Noise amplitude varies by strand
                                            var noiseAmpX = s === 3 ? 1.0 : (4 - s) * 4;                                           // X noise: 1 for core, up to 16 for outer glow
                                            var noiseAmpY = s === 3 ? 1.0 : (4 - s) * 5;                                           // Y noise: 1 for core, up to 20 for outer glow
                                            
                                            // Combine multiple frequencies for complex branching/crackle appearance              // Comment for wave separation
                                            // Glow strands (0, 1) also get a sweeping sine wave applied to create distinct separating waves  // Only glow strands have separation
                                            var sepWaveX = (s < 2) ? Math.sin(time * 3 + i + j + s) * root.s(10) * envelope : 0;    // Separation X wave for strands 0,1
                                            var sepWaveY = (s < 2) ? Math.cos(time * 2.5 + i - j - s) * root.s(15) * envelope : 0;   // Separation Y wave

                                            // Primary erratic crackle noise using high frequency combined sine/cos              // Comment for noise generation
                                            var noiseX = Math.sin(time * (10+s) + i + j) * Math.cos(time * 8 - i + j) * noiseAmpX * envelope * (1 - root.eqLightningFade);  // Complex X noise with time-based variation
                                            var noiseY = Math.cos(time * (9-s) + i - j) * Math.sin(time * 7 + i - j) * noiseAmpY * envelope * (1 - root.eqLightningFade);  // Complex Y noise

                                            ctx.lineTo(cx + sepWaveX + noiseX, cy + sepWaveY + noiseY);                            // Draw line to offset position

                                            if (t === fraction) break;                                                            // Stop if reached fraction limit
                                        }                                                                                       // End of subdivision loop
                                    }                                                                                          // End of segment loop

                                    // Step 3: Theme and render each distinct strand                                           // Comment for rendering
                                    if (s === 0) { // Massive Sweeping Outer Glow (Mauve)                                        // Strand 0 styling
                                        ctx.lineWidth = root.s(20);                                                               // Thick line 20px
                                        ctx.strokeStyle = root.mauve;                                                             // Mauve color
                                        ctx.globalAlpha = 0.2;                                                                    // 20% opacity
                                    } else if (s === 1) { // Medium Sweeping Wave (Pink)                                          // Strand 1 styling
                                        ctx.lineWidth = root.s(8);                                                                // Medium line 8px
                                        ctx.strokeStyle = root.pink;                                                              // Pink color
                                        ctx.globalAlpha = 0.45;                                                                   // 45% opacity
                                    } else if (s === 2) { // Tight erratic core (Lavender)                                        // Strand 2 styling
                                        ctx.lineWidth = root.s(3.5);                                                              // Thin line 3.5px
                                        ctx.strokeStyle = root.lavender;                                                          // Lavender color
                                        ctx.globalAlpha = 0.85;                                                                   // 85% opacity
                                    } else if (s === 3) { // Pure white straight hot core - heavily transparent                   // Strand 3 styling (core)
                                        ctx.lineWidth = root.s(1.0);                                                              // Very thin 1px
                                        ctx.strokeStyle = "#ffffff";                                                              // Pure white
                                        ctx.globalAlpha = 0.1;                                                                    // 10% opacity (subtle)
                                    }                                                                                            // End of if-else

                                    ctx.stroke();                                                                                // Render the stroke
                                }                                                                                              // End of strand loop
                            }                                                                                              // End of onPaint
                        }                                                                                              // End of Canvas
                    }                                                                                               // End of sliders container Item

                    // Presets Grid                                                                                     // Subsection comment
                    ColumnLayout {                                                                                    // Column for preset buttons
                        Layout.fillWidth: true                                                                          // Full width
                        spacing: root.s(8)                                                                               // 8px between rows
                        
                        opacity: root.introPresets                                                                       // Fade in with introPresets
                        transform: Translate { y: root.s(20) * (1 - root.introPresets) }                                  // Slide up from below

                        RowLayout {                                                                                    // First row of presets
                            Layout.fillWidth: true                                                                       // Full width
                            spacing: root.s(10)                                                                           // 10px between buttons
                            Repeater {                                                                                   // Repeater for 4 buttons
                                model: ["Flat", "Bass", "Treble", "Vocal"]                                                  // Preset names for first row
                                delegate: PresetButton { name: modelData }                                                  // Use PresetButton component
                            }                                                                                           // End of Repeater
                        }                                                                                             // End of first RowLayout
                        RowLayout {                                                                                    // Second row of presets
                            Layout.fillWidth: true                                                                       // Full width
                            spacing: root.s(10)                                                                           // 10px between buttons
                            Repeater {                                                                                   // Repeater for 4 buttons
                                model: ["Pop", "Rock", "Jazz", "Classic"]                                                   // Preset names for second row
                                delegate: PresetButton { name: modelData }                                                  // Use PresetButton component
                            }                                                                                           // End of Repeater
                        }                                                                                             // End of second RowLayout
                    }                                                                                               // End of presets ColumnLayout
                }                                                                                                 // End of equalizer ColumnLayout
            }                                                                                                   // End of main ColumnLayout
        }                                                                                                     // End of innerBg Rectangle
    }                                                                                                       // End of mainWrapper Item

    // --- HELPER COMPONENT FOR PRESETS ---                                                                   // Comment header - marks preset button component definition
    component PresetButton : Rectangle {                                                                      // Define reusable PresetButton component (extends Rectangle)
        property string name: ""                                                                               // Property for preset name
        Layout.fillWidth: true                                                                                  // Fill available width in layout
        Layout.preferredHeight: root.s(32)                                                                      // Fixed height 32px
        radius: root.s(8)                                                                                       // Rounded corners
        
        property bool isActivePreset: root.eqData && root.eqData.preset === name                                 // True if this button's preset is currently active
        property bool isHovered: hoverMa.containsMouse                                                            // True if mouse is hovering

        color: isActivePreset ? root.mauve : (isHovered ? root.surface1 : "#BF1E1E2E")                           // Mauve when active, surface1 on hover, dark color default
        scale: isHovered && !isActivePreset ? 1.05 : 1.0                                                          // Scale up 5% on hover (if not active)

        Behavior on color { ColorAnimation { duration: 200 } }                                                    // Smooth color transition
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }                      // Bouncy scale transition

        Text {                                                                                                 // Button label
            anchors.centerIn: parent                                                                             // Center in button
            text: parent.name                                                                                    // Display preset name
            color: parent.isActivePreset ? root.base : (parent.isHovered ? root.text : root.subtext0)              // Base color when active, text on hover, subtext0 default
            font.family: "JetBrains Mono"                                                                         // JetBrains Mono font
            font.pixelSize: root.s(12)                                                                             // 12px font
            font.bold: true                                                                                       // Bold
            Behavior on color { ColorAnimation { duration: 200 } }                                                 // Smooth color transition
        }                                                                                                    // End of Text

        MouseArea {                                                                                            // Click area
            id: hoverMa                                                                                          // Assign id for hover detection
            anchors.fill: parent                                                                                  // Fill button
            hoverEnabled: true                                                                                    // Enable hover tracking
            cursorShape: Qt.PointingHandCursor                                                                     // Hand cursor
            onClicked: root.applyPresetOptimistically(parent.name)                                                   // On click: apply this preset optimistically
        }                                                                                                    // End of MouseArea
    }                                                                                                      // End of PresetButton component
}                                                                                                        // End of root Item