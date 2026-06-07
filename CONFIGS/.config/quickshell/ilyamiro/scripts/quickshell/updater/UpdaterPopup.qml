// import QtQuick
// import QtQuick.Window
// import QtQuick.Effects
// import QtQuick.Layouts
// import QtQuick.Controls
// import Quickshell
// import Quickshell.Io
// import "../"

// Item {
//     id: window
//     focus: true

//     // --- Responsive Scaling Logic ---
//     Scaler {
//         id: scaler
//         currentWidth: Screen.width
//     }
    
//     function s(val) { 
//         return scaler.s(val); 
//     }

//     // -------------------------------------------------------------------------
//     // COLORS (Dynamic Matugen Palette + Added Blob Colors)
//     // -------------------------------------------------------------------------
//     MatugenColors { id: _theme }
    
//     readonly property color base: _theme.base
//     readonly property color mantle: _theme.mantle || _theme.base
//     readonly property color crust: _theme.crust
//     readonly property color surface0: _theme.surface0
//     readonly property color surface1: _theme.surface1
//     readonly property color surface2: _theme.surface2
//     readonly property color text: _theme.text
//     readonly property color subtext0: _theme.subtext0
//     readonly property color green: _theme.green
    
//     // Added for background blobs
//     readonly property color mauve: _theme.mauve || "#cba6f7"
//     readonly property color blue: _theme.blue || "#89b4fa"

//     // -------------------------------------------------------------------------
//     // STATE & POLLING
//     // -------------------------------------------------------------------------
//     property string localVersion: "..."
//     property string remoteVersion: "..."
    
//     // Box animation properties
//     property var pendingCommits: []
//     property int typeIndex: 0

//     ListModel {
//         id: commitModel
//     }

//     // --- BACKGROUND ORBIT ANIMATION ---
//     property real globalOrbitAngle: 0
//     NumberAnimation on globalOrbitAngle {
//         from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
//     }

//     Keys.onEscapePressed: {
//         Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
//         event.accepted = true;
//     }

//     Process {
//         command: ["bash", "-c", "source ~/.local/state/imperative-dots-version 2>/dev/null && [ -n \"$LOCAL_VERSION\" ] && echo $LOCAL_VERSION || echo '0.0.0'"]
//         running: true
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 let out = this.text ? this.text.trim() : "";
//                 if (out !== "") window.localVersion = out;
//             }
//         }
//     }

//     Process {
//         command: ["bash", "-c", "curl -m 5 -s https://raw.githubusercontent.com/ilyamiro/imperative-dots/master/install.sh | grep '^DOTS_VERSION=' | cut -d'\"' -f2"]
//         running: true
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 let out = this.text ? this.text.trim() : "";
//                 if (out !== "") window.remoteVersion = out;
//             }
//         }
//     }

//     // Highly robust python script to trace the commit difference via install.sh history
//     property string fetchScript: `
// import urllib.request, json, subprocess

// repo = 'ilyamiro/imperative-dots'

// try:
//     local = subprocess.check_output("source ~/.local/state/imperative-dots-version 2>/dev/null && echo $LOCAL_VERSION", shell=True).decode('utf-8').strip()
// except:
//     local = ''

// if not local:
//     local = '0.0.0'

// def get_latest():
//     try:
//         req = urllib.request.Request('https://api.github.com/repos/' + repo + '/commits/master', headers={'User-Agent': 'updater'})
//         res = urllib.request.urlopen(req, timeout=5)
//         print(json.loads(res.read().decode())['commit']['message'])
//     except Exception: print('No changelog available')

// try:
//     if local in ['0.0.0', '...', '']: 
//         get_latest()
//     else:
//         # Step 1: Find the commit SHA where install.sh contained the local version
//         req_commits = urllib.request.Request('https://api.github.com/repos/' + repo + '/commits?path=install.sh&per_page=15', headers={'User-Agent': 'updater'})
//         res_commits = urllib.request.urlopen(req_commits, timeout=5)
//         file_commits = json.loads(res_commits.read().decode())
        
//         local_sha = None
//         for c in file_commits:
//             sha = c['sha']
//             try:
//                 raw_req = urllib.request.Request('https://raw.githubusercontent.com/' + repo + '/' + sha + '/install.sh', headers={'User-Agent': 'updater'})
//                 raw_res = urllib.request.urlopen(raw_req, timeout=5)
//                 content = raw_res.read().decode('utf-8')
                
//                 for line in content.splitlines():
//                     if line.startswith('DOTS_VERSION='):
//                         ver = line.split('=', 1)[1].strip().strip('"\\'')
//                         if ver == local:
//                             local_sha = sha
//                         break
//             except: pass
            
//             if local_sha:
//                 break
                
//         # Step 2: Use the exact SHA to get all commits in between
//         if local_sha:
//             compare_req = urllib.request.Request('https://api.github.com/repos/' + repo + '/compare/' + local_sha + '...master', headers={'User-Agent': 'updater'})
//             compare_res = urllib.request.urlopen(compare_req, timeout=5)
//             data = json.loads(compare_res.read().decode())
//             commits = data.get('commits', [])
            
//             if commits:
//                 for c in reversed(commits):
//                     print(c['commit']['message'])
//                     print('---SPLIT---')
//             else:
//                 get_latest()
//         else:
//             get_latest()
// except Exception as e:
//     get_latest()
// `

//     Process {
//         command: ["python3", "-c", window.fetchScript]
//         running: true
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 let out = this.text ? this.text.trim() : "";
//                 if (out !== "") {
//                     let blocks = out.split("---SPLIT---");
//                     let validLines = [];
                    
//                     for (let i = 0; i < blocks.length; i++) {
//                         let blockTrimmed = blocks[i].trim();
//                         if (blockTrimmed === "") continue;
                        
//                         // Parse literally every new line inside the commit into separate boxes
//                         let lines = blockTrimmed.split(/\r\n|\n/);
//                         for (let j = 0; j < lines.length; j++) {
//                             let trimmed = lines[j].trim();
//                             if (trimmed.length > 0) {
//                                 validLines.push(trimmed);
//                             }
//                         }
//                     }

//                     commitModel.clear();
                    
//                     if (validLines.length > 0) {
//                         window.pendingCommits = validLines;
//                         window.typeIndex = 0;
//                         commitBoxTimer.start();
//                     } else {
//                         commitModel.append({ "lineText": "No changelog available." });
//                     }
//                 } else {
//                     commitModel.clear();
//                     commitModel.append({ "lineText": "No changelog available." });
//                 }
//             }
//         }
//     }

//     Timer {
//         id: commitBoxTimer
//         interval: 100 // Slightly faster cascade for multiple commits
//         repeat: true
//         onTriggered: {
//             if (window.typeIndex < window.pendingCommits.length) {
//                 commitModel.append({ "lineText": window.pendingCommits[window.typeIndex] });
//                 window.typeIndex++;
//             } else {
//                 stop();
//             }
//         }
//     }

//     // -------------------------------------------------------------------------
//     // UI LAYOUT
//     // -------------------------------------------------------------------------
//     Rectangle {
//         anchors.fill: parent
//         radius: window.s(16)
//         color: window.base
//         border.color: window.surface1
//         border.width: 1
//         clip: true

//         // --- AMBIENT BLOBS ---
//         Rectangle {
//             width: parent.width * 0.8; height: width; radius: width / 2
//             x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)
//             y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)
//             opacity: 0.08
//             color: window.mauve
//             Behavior on color { ColorAnimation { duration: 1000 } }
//         }
        
//         Rectangle {
//             width: parent.width * 0.9; height: width; radius: width / 2
//             x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)
//             y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)
//             opacity: 0.06
//             color: window.blue
//             Behavior on color { ColorAnimation { duration: 1000 } }
//         }

//         ColumnLayout {
//             anchors.fill: parent
//             anchors.margins: window.s(25)
//             spacing: window.s(20)

//             // --- ANIMATED CHOREOGRAPHED VERSIONS ---
//             Item {
//                 id: versionContainer
//                 Layout.fillWidth: true
//                 Layout.preferredHeight: window.s(60)

//                 Text { 
//                     id: oldVer
//                     text: window.localVersion
//                     font.family: "JetBrains Mono"
//                     font.pixelSize: window.s(22)
//                     color: window.subtext0 
//                     anchors.centerIn: parent
//                     anchors.horizontalCenterOffset: 0 // Starts exactly dead center
//                 }
                
//                 Text { 
//                     id: newVer
//                     text: window.remoteVersion
//                     font.family: "JetBrains Mono"
//                     font.weight: Font.Black
//                     font.pixelSize: window.s(48) 
//                     color: window.green 
//                     anchors.centerIn: parent
//                     anchors.horizontalCenterOffset: window.s(20) // Starts slightly right
//                     opacity: 0
//                     scale: 0.8 
//                 }

//                 MultiEffect {
//                     id: newVerEffect
//                     source: newVer
//                     anchors.fill: newVer
//                     shadowEnabled: true
//                     shadowColor: window.green
//                     shadowBlur: 0.0
//                     shadowHorizontalOffset: 0
//                     shadowVerticalOffset: 0
//                     opacity: newVer.opacity
//                 }

//                 // Smooth, fluid animation sequence
//                 SequentialAnimation {
//                     id: versionAnim

//                     PauseAnimation { duration: 150 }

//                     ParallelAnimation {
//                         // 1. Old version smoothly slides left and disappears completely (slower)
//                         NumberAnimation { 
//                             target: oldVer; property: "anchors.horizontalCenterOffset"; 
//                             to: window.s(-30) // Slide smoothly left
//                             duration: 1200; easing.type: Easing.OutExpo 
//                         }
//                         NumberAnimation {
//                             target: oldVer; property: "opacity";
//                             to: 0.0 // Fully disappear
//                             duration: 1000; easing.type: Easing.OutSine
//                         }

//                         // 2. New version slides into the EXACT center and scales up
//                         SequentialAnimation {
//                             PauseAnimation { duration: 400 } // Wait a bit more for old version to clear out
//                             ParallelAnimation {
//                                 NumberAnimation { target: newVer; property: "opacity"; to: 1; duration: 800; easing.type: Easing.OutSine }
//                                 NumberAnimation { 
//                                     target: newVer; property: "anchors.horizontalCenterOffset"; 
//                                     to: 0 // Ends exactly dead center
//                                     duration: 1200; easing.type: Easing.OutExpo 
//                                 }
//                                 NumberAnimation { 
//                                     target: newVer; property: "scale"; 
//                                     to: 1.0; 
//                                     duration: 1200; easing.type: Easing.OutBack; easing.overshoot: 1.4 
//                                 }
//                             }
//                             ScriptAction { script: glowAnim.start() }
//                         }
//                     }
//                 }

//                 SequentialAnimation {
//                     id: glowAnim
//                     loops: Animation.Infinite
//                     NumberAnimation { target: newVerEffect; property: "shadowBlur"; to: 0.8; duration: 1500; easing.type: Easing.InOutSine }
//                     NumberAnimation { target: newVerEffect; property: "shadowBlur"; to: 0.2; duration: 1500; easing.type: Easing.InOutSine }
//                 }

//                 Connections {
//                     target: window
//                     function onRemoteVersionChanged() {
//                         if (window.remoteVersion !== "..." && window.remoteVersion !== "") {
//                             versionAnim.start();
//                         }
//                     }
//                 }
//             }

//             // --- CLEAN COMMIT LIST ---
//             Item {
//                 Layout.fillWidth: true
//                 Layout.fillHeight: true
//                 clip: true

//                 ListView {
//                     id: changelogList
//                     anchors.fill: parent
//                     clip: true
//                     model: commitModel
//                     spacing: window.s(8) // Reduced spacing for a tighter look

//                     ScrollBar.vertical: ScrollBar {
//                         active: true
//                         policy: ScrollBar.AsNeeded
//                         contentItem: Rectangle { 
//                             implicitWidth: window.s(3); 
//                             radius: window.s(1.5); 
//                             color: window.surface2; 
//                             opacity: 0.5 
//                         }
//                     }

//                     // Elegant pop-in transition for the separate commit boxes
//                     add: Transition {
//                         ParallelAnimation {
//                             NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutExpo }
//                             NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: 450; easing.type: Easing.OutBack }
//                             NumberAnimation { property: "y"; from: y + window.s(15); duration: 450; easing.type: Easing.OutExpo }
//                         }
//                     }

//                     delegate: Rectangle {
//                         width: changelogList.width - window.s(12) 
//                         height: Math.max(window.s(40), commitText.implicitHeight + window.s(20))
                        
//                         color: window.surface0 
//                         radius: window.s(12)
                        
//                         Text {
//                             id: commitText
//                             anchors.fill: parent
//                             anchors.margins: window.s(10)
//                             anchors.leftMargin: window.s(16)
//                             anchors.rightMargin: window.s(16)
//                             text: model.lineText
//                             font.family: "JetBrains Mono"
//                             font.pixelSize: window.s(13)
//                             color: window.text
//                             wrapMode: Text.WordWrap
//                             verticalAlignment: Text.AlignVCenter
//                             lineHeight: 1.4
//                         }
//                     }
//                 }
//             }

//             // --- HOLD TO UPDATE BUTTON ---
//             Rectangle {
//                 id: updateBtn
//                 Layout.alignment: Qt.AlignHCenter // Centered instead of stretched
//                 Layout.preferredWidth: window.s(240) // Fixed, elegant width
//                 Layout.preferredHeight: window.s(54)
//                 radius: window.s(12)
//                 color: window.surface0
//                 border.color: btnMa.containsMouse ? window.green : window.surface2
//                 border.width: btnMa.containsMouse ? window.s(2) : 1
//                 clip: true
                
//                 scale: btnMa.pressed ? 0.98 : (btnMa.containsMouse ? 1.01 : 1.0)
//                 Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
//                 Behavior on border.color { ColorAnimation { duration: 200 } }

//                 property real fillLevel: 0.0
//                 property bool triggered: false

//                 Canvas {
//                     id: waveCanvas
//                     anchors.fill: parent
                    
//                     property real wavePhase: 0.0
//                     NumberAnimation on wavePhase {
//                         running: updateBtn.fillLevel > 0.0 && updateBtn.fillLevel < 1.0
//                         loops: Animation.Infinite
//                         from: 0; to: Math.PI * 2
//                         duration: 1000
//                     }
                    
//                     onWavePhaseChanged: requestPaint()
//                     Connections { target: updateBtn; function onFillLevelChanged() { waveCanvas.requestPaint() } }
                    
//                     onPaint: {
//                         var ctx = getContext("2d");
//                         ctx.clearRect(0, 0, width, height);
//                         if (updateBtn.fillLevel <= 0.001) return;

//                         var currentW = width * updateBtn.fillLevel;
//                         var r = window.s(12);

//                         ctx.save();
//                         ctx.beginPath();
//                         ctx.moveTo(0, 0);
                        
//                         if (updateBtn.fillLevel < 0.99) {
//                             var waveAmp = window.s(8) * Math.sin(updateBtn.fillLevel * Math.PI); 
//                             var cp1x = currentW + Math.sin(wavePhase) * waveAmp;
//                             var cp2x = currentW + Math.cos(wavePhase + Math.PI) * waveAmp;

//                             ctx.lineTo(currentW, 0);
//                             ctx.bezierCurveTo(cp2x, height * 0.33, cp1x, height * 0.66, currentW, height);
//                             ctx.lineTo(0, height);
//                         } else {
//                             ctx.lineTo(width, 0);
//                             ctx.lineTo(width, height);
//                             ctx.lineTo(0, height);
//                         }
//                         ctx.closePath();
//                         ctx.clip(); 

//                         ctx.beginPath();
//                         ctx.roundedRect(0, 0, width, height, r, r);
//                         var grad = ctx.createLinearGradient(0, 0, width, 0);
//                         grad.addColorStop(0, Qt.darker(window.green, 1.1).toString());
//                         grad.addColorStop(1, window.green.toString());
//                         ctx.fillStyle = grad;
//                         ctx.fill();

//                         ctx.restore();
//                     }
//                 }

//                 RowLayout {
//                     anchors.centerIn: parent
//                     spacing: window.s(10)
                    
//                     Text { 
//                         text: "󰚰"
//                         font.family: "Iosevka Nerd Font"
//                         font.pixelSize: window.s(18)
//                         color: updateBtn.fillLevel > 0.5 ? window.crust : window.green 
//                         Behavior on color { ColorAnimation { duration: 150 } }
//                     }
                    
//                     Text { 
//                         text: updateBtn.fillLevel > 0 ? "HOLDING..." : "UPDATE"
//                         font.family: "JetBrains Mono"
//                         font.weight: Font.Black
//                         font.pixelSize: window.s(14)
//                         color: updateBtn.fillLevel > 0.5 ? window.crust : window.green 
//                         Behavior on color { ColorAnimation { duration: 150 } }
//                     }
//                 }

//                 MouseArea {
//                     id: btnMa
//                     anchors.fill: parent
//                     hoverEnabled: true
//                     cursorShape: updateBtn.triggered ? Qt.ArrowCursor : Qt.PointingHandCursor
                    
//                     onPressed: {
//                         if (!updateBtn.triggered) {
//                             drainAnim.stop();
//                             fillAnim.start();
//                         }
//                     }
                    
//                     onReleased: {
//                         if (!updateBtn.triggered && updateBtn.fillLevel < 1.0) {
//                             fillAnim.stop();
//                             drainAnim.start();
//                         }
//                     }
//                 }

//                 NumberAnimation {
//                     id: fillAnim
//                     target: updateBtn
//                     property: "fillLevel"
//                     to: 1.0
//                     duration: 1200 * (1.0 - updateBtn.fillLevel)
//                     easing.type: Easing.InSine
//                     onFinished: {
//                         updateBtn.triggered = true;
//                         let cmd = "if command -v kitty >/dev/null 2>&1; then kitty --hold bash -c 'eval \"$(curl -fsSL https://raw.githubusercontent.com/ilyamiro/imperative-dots/master/install.sh)\"'; else ${TERM:-xterm} -hold -e bash -c 'eval \"$(curl -fsSL https://raw.githubusercontent.com/ilyamiro/imperative-dots/master/install.sh)\"'; fi";
//                         Quickshell.execDetached(["bash", "-c", cmd]);
//                         Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
//                     }
//                 }

//                 NumberAnimation {
//                     id: drainAnim
//                     target: updateBtn
//                     property: "fillLevel"
//                     to: 0.0
//                     duration: 800 * updateBtn.fillLevel
//                     easing.type: Easing.OutCubic
//                 }
//             }
//         }
//     }
// }



import QtQuick                                                                  // Imports the QtQuick module for basic QML UI types and animation framework
import QtQuick.Window                                                           // Imports QtQuick.Window for accessing screen properties like dimensions
import QtQuick.Effects                                                          // Imports QtQuick.Effects module for graphical effects like shadows and blurs
import QtQuick.Layouts                                                          // Imports QtQuick.Layouts for layout management (RowLayout, ColumnLayout, etc.)
import QtQuick.Controls                                                         // Imports QtQuick.Controls for UI controls like ScrollBar
import Quickshell                                                               // Imports the Quickshell module for shell/window management integration with Hyprland
import Quickshell.Io                                                            // Imports Quickshell.Io for input/output operations like Process and StdioCollector
import "../"                                                                    // Imports parent directory to access shared components in the quickshell folder

Item {                                                                          // Root item serving as the main container for the updater popup window
    id: window                                                                  // Unique identifier "window" for referencing this root item throughout the file
    focus: true                                                                 // Enables keyboard focus on this item so it can receive key events

    // --- Responsive Scaling Logic ---                                          // Comment divider for the responsive UI scaling system
    Scaler {                                                                    // Instantiates the Scaler component for consistent UI scaling across screen sizes
        id: scaler                                                              // Unique identifier "scaler" for this scaler instance
        currentWidth: Screen.width                                              // Binds the scaler to the actual screen width for calculating scale factors
    }
    
    function s(val) {                                                           // Helper function that applies the current scale factor to a value
        return scaler.s(val);                                                   // Delegates to the scaler's s() method to return the scaled value
    }

    // ------------------------------------------------------------------------- // Visual divider for the color palette section
    // COLORS (Dynamic Matugen Palette + Added Blob Colors)                      // Section header: colors from matugen theme plus extra colors for background blobs
    // ------------------------------------------------------------------------- // Visual divider closing the section header
    MatugenColors { id: _theme }                                                // Instantiates MatugenColors component to get the dynamic color palette from matugen
    
    readonly property color base: _theme.base                                   // Read-only property: base background color from matugen theme (darkest shade)
    readonly property color mantle: _theme.mantle || _theme.base                // Mantle color with fallback to base if mantle is undefined in the theme
    readonly property color crust: _theme.crust                                 // Crust color from matugen theme (lightest background shade)
    readonly property color surface0: _theme.surface0                           // Surface0 color from theme (darkest UI surface)
    readonly property color surface1: _theme.surface1                           // Surface1 color from theme (medium UI surface)
    readonly property color surface2: _theme.surface2                           // Surface2 color from theme (lightest UI surface)
    readonly property color text: _theme.text                                   // Primary text/foreground color from matugen theme
    readonly property color subtext0: _theme.subtext0                           // Secondary/subdued text color from theme
    readonly property color green: _theme.green                                 // Green accent color from matugen theme (used for update button and new version)
    
    // Added for background blobs                                                // Comment indicating these are specifically for decorative background elements
    readonly property color mauve: _theme.mauve || "#cba6f7"                    // Mauve accent color with hardcoded fallback to Catppuccin mauve hex if theme doesn't provide it
    readonly property color blue: _theme.blue || "#89b4fa"                      // Blue accent color with hardcoded fallback to Catppuccin blue hex if theme doesn't provide it

    // ------------------------------------------------------------------------- // Visual divider for state and polling section
    // STATE & POLLING                                                           // Section header: state variables and data fetching processes
    // ------------------------------------------------------------------------- // Visual divider closing the section header
    property string localVersion: "..."                                         // Property storing the locally installed version string, initialized with placeholder "..."
    property string remoteVersion: "..."                                        // Property storing the latest remote version string from GitHub, initialized with placeholder "..."
    
    // Box animation properties                                                  // Comment for animation-related properties
    property var pendingCommits: []                                             // Array to temporarily hold parsed commit messages before animated reveal
    property int typeIndex: 0                                                   // Counter tracking which commit is currently being revealed in the animation

    ListModel {                                                                 // ListModel data structure for displaying commit messages in the ListView
        id: commitModel                                                         // Unique identifier "commitModel" for the commit list data model
    }

    // --- BACKGROUND ORBIT ANIMATION ---                                        // Comment divider for the orbiting background blob animation
    property real globalOrbitAngle: 0                                           // Property tracking the orbital angle for background blob movement (0 to 2π)
    NumberAnimation on globalOrbitAngle {                                       // Continuous number animation on the orbit angle
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true // Full 360° rotation over 90 seconds, looping infinitely for slow ambient movement
    }

    Keys.onEscapePressed: {                                                     // Keyboard handler for the Escape key press
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]); // Runs the qs_manager.sh script with "close" argument to close this popup
        event.accepted = true;                                                  // Marks the key event as handled to prevent further processing
    }

    Process {                                                                   // Process component that runs a shell command to get the local version
        command: ["bash", "-c", "source ~/.local/state/imperative-dots-version 2>/dev/null && [ -n \"$LOCAL_VERSION\" ] && echo $LOCAL_VERSION || echo '0.0.0'"] // Sources the version file, echoes the version if found, otherwise outputs '0.0.0'
        running: true                                                           // Starts the process immediately when the component loads
        stdout: StdioCollector {                                                // Collects the standard output of the process
            onStreamFinished: {                                                 // Callback triggered when the process completes and output is available
                let out = this.text ? this.text.trim() : "";                    // Gets the trimmed output text, or empty string if null
                if (out !== "") window.localVersion = out;                      // If output is not empty, update the localVersion property
            }
        }
    }

    Process {                                                                   // Process component that fetches the latest remote version from GitHub
        command: ["bash", "-c", "curl -m 5 -s https://raw.githubusercontent.com/ilyamiro/imperative-dots/master/install.sh | grep '^DOTS_VERSION=' | cut -d'\"' -f2"] // Curls the install.sh from GitHub (5 second timeout), extracts DOTS_VERSION value
        running: true                                                           // Starts immediately
        stdout: StdioCollector {                                                // Collects standard output
            onStreamFinished: {                                                 // Callback when curl completes
                let out = this.text ? this.text.trim() : "";                    // Gets trimmed output
                if (out !== "") window.remoteVersion = out;                     // Updates remoteVersion if version string was found
            }
        }
    }

    // Highly robust python script to trace the commit difference via install.sh history // Comment describing the Python script that fetches commit history
    property string fetchScript: `                                              // Multi-line string property containing the entire Python script
import urllib.request, json, subprocess                                         // Python imports: urllib for HTTP requests, json for parsing, subprocess for shell commands

repo = 'ilyamiro/imperative-dots'                                               // GitHub repository string for API requests

try:                                                                            // Try block to attempt getting local version
    local = subprocess.check_output("source ~/.local/state/imperative-dots-version 2>/dev/null && echo $LOCAL_VERSION", shell=True).decode('utf-8').strip() // Runs shell command to get local version, decodes output
except:                                                                         // If the shell command fails
    local = ''                                                                  // Set local to empty string

if not local:                                                                   // If local version is empty or falsy
    local = '0.0.0'                                                             // Default to '0.0.0' as fallback version

def get_latest():                                                               // Function to fetch just the latest commit message
    try:                                                                        // Try block for the API request
        req = urllib.request.Request('https://api.github.com/repos/' + repo + '/commits/master', headers={'User-Agent': 'updater'}) // Creates request for latest master commit with custom User-Agent
        res = urllib.request.urlopen(req, timeout=5)                            // Opens the URL with 5 second timeout
        print(json.loads(res.read().decode())['commit']['message'])             // Parses JSON response and prints the commit message
    except Exception: print('No changelog available')                           // On any error, prints fallback message

try:                                                                            // Main try block for the commit comparison logic
    if local in ['0.0.0', '...', '']:                                           // If local version is default/placeholder/empty
        get_latest()                                                            // Just fetch the latest commit message
    else:                                                                       // If we have a valid local version
        # Step 1: Find the commit SHA where install.sh contained the local version // Comment: find the exact commit matching local version
        req_commits = urllib.request.Request('https://api.github.com/repos/' + repo + '/commits?path=install.sh&per_page=15', headers={'User-Agent': 'updater'}) // Request last 15 commits that modified install.sh
        res_commits = urllib.request.urlopen(req_commits, timeout=5)            // Opens the commits API URL
        file_commits = json.loads(res_commits.read().decode())                  // Parses the JSON array of commits
        
        local_sha = None                                                        // Initialize the local commit SHA as None
        for c in file_commits:                                                  // Iterate through each commit that touched install.sh
            sha = c['sha']                                                      // Get the commit SHA hash
            try:                                                                // Try to fetch the raw install.sh at this commit
                raw_req = urllib.request.Request('https://raw.githubusercontent.com/' + repo + '/' + sha + '/install.sh', headers={'User-Agent': 'updater'}) // Request raw file content at specific commit
                raw_res = urllib.request.urlopen(raw_req, timeout=5)            // Opens the raw file URL
                content = raw_res.read().decode('utf-8')                        // Reads and decodes the file content
                
                for line in content.splitlines():                               // Iterate through each line of install.sh
                    if line.startswith('DOTS_VERSION='):                        // Find the line defining DOTS_VERSION
                        ver = line.split('=', 1)[1].strip().strip('"\\'')       // Extract version value, strip quotes and whitespace
                        if ver == local:                                        // If this version matches local version
                            local_sha = sha                                    // Store this commit SHA as the local version's commit
                        break                                                   // Exit the line loop
            except: pass                                                        // Ignore any errors fetching individual commits
            
            if local_sha:                                                       // If we found the local version's SHA
                break                                                           // Exit the commit loop
                
        # Step 2: Use the exact SHA to get all commits in between               // Comment: compare local SHA to master to get all intermediate commits
        if local_sha:                                                           // If we successfully found the local commit SHA
            compare_req = urllib.request.Request('https://api.github.com/repos/' + repo + '/compare/' + local_sha + '...master', headers={'User-Agent': 'updater'}) // GitHub compare API: all commits between local and master
            compare_res = urllib.request.urlopen(compare_req, timeout=5)        // Opens the compare URL
            data = json.loads(compare_res.read().decode())                      // Parses the comparison JSON response
            commits = data.get('commits', [])                                   // Gets the array of commits from the response
            
            if commits:                                                         // If there are commits between local and master
                for c in reversed(commits):                                     // Iterate in reverse (oldest first) for chronological order
                    print(c['commit']['message'])                               // Print each commit message
                    print('---SPLIT---')                                        // Print delimiter string between commits for parsing
            else:                                                               // If no commits between (up to date)
                get_latest()                                                    // Fetch just the latest commit message
        else:                                                                   // If local SHA wasn't found
            get_latest()                                                        // Fallback to latest commit
except Exception as e:                                                          // Catch any exceptions in the main logic
    get_latest()                                                                // Fallback to latest commit on error
`

    Process {                                                                   // Process component that runs the Python commit-fetching script
        command: ["python3", "-c", window.fetchScript]                          // Runs python3 with the fetchScript as inline code (-c flag)
        running: true                                                           // Starts immediately
        stdout: StdioCollector {                                                // Collects standard output from the Python script
            onStreamFinished: {                                                 // Callback when Python script completes
                let out = this.text ? this.text.trim() : "";                    // Gets trimmed output text
                if (out !== "") {                                               // If there is output
                    let blocks = out.split("---SPLIT---");                      // Splits the output by the delimiter into individual commit message blocks
                    let validLines = [];                                        // Array to store parsed commit message lines
                    
                    for (let i = 0; i < blocks.length; i++) {                   // Iterate through each block
                        let blockTrimmed = blocks[i].trim();                    // Trim whitespace from the block
                        if (blockTrimmed === "") continue;                      // Skip empty blocks
                        
                        // Parse literally every new line inside the commit into separate boxes // Comment: split multi-line commits into individual display lines
                        let lines = blockTrimmed.split(/\r\n|\n/);              // Split block by newlines (handles both Windows and Unix line endings)
                        for (let j = 0; j < lines.length; j++) {                // Iterate through each line in the block
                            let trimmed = lines[j].trim();                      // Trim the line
                            if (trimmed.length > 0) {                           // If line is not empty
                                validLines.push(trimmed);                       // Add to valid lines array
                            }
                        }
                    }

                    commitModel.clear();                                        // Clear any existing items in the commit display model
                    
                    if (validLines.length > 0) {                                // If there are valid commit lines to display
                        window.pendingCommits = validLines;                     // Store lines in pendingCommits for animated reveal
                        window.typeIndex = 0;                                   // Reset the type index to start from beginning
                        commitBoxTimer.start();                                 // Start the timer that reveals commits one by one
                    } else {                                                    // If no valid lines were parsed
                        commitModel.append({ "lineText": "No changelog available." }); // Add a single fallback message to the model
                    }
                } else {                                                        // If Python script produced no output
                    commitModel.clear();                                        // Clear the model
                    commitModel.append({ "lineText": "No changelog available." }); // Add fallback message
                }
            }
        }
    }

    Timer {                                                                     // Timer component for cascading reveal animation of commit messages
        id: commitBoxTimer                                                      // Unique identifier "commitBoxTimer"
        interval: 100                                                           // 100 millisecond interval between each commit reveal
        repeat: true                                                            // Repeats until stopped
        onTriggered: {                                                          // Function called each time the timer fires
            if (window.typeIndex < window.pendingCommits.length) {              // If there are still commits to reveal
                commitModel.append({ "lineText": window.pendingCommits[window.typeIndex] }); // Add the next commit line to the display model
                window.typeIndex++;                                             // Increment the index for the next reveal
            } else {                                                            // If all commits have been revealed
                stop();                                                         // Stop the timer
            }
        }
    }

    // ------------------------------------------------------------------------- // Visual divider for the UI layout section
    // UI LAYOUT                                                                  // Section header: main user interface layout
    // ------------------------------------------------------------------------- // Visual divider closing the section header
    Rectangle {                                                                 // Main container rectangle for the entire updater popup UI
        anchors.fill: parent                                                    // Fills the entire parent Item
        radius: window.s(16)                                                    // Rounded corners with 16 scaled units radius
        color: window.base                                                      // Background color uses the base theme color (darkest)
        border.color: window.surface1                                           // Border color uses surface1 for subtle outline
        border.width: 1                                                         // 1-pixel border width
        clip: true                                                              // Clips child content to the rounded rectangle bounds

        // --- AMBIENT BLOBS ---                                                 // Comment divider for decorative background blob elements
        Rectangle {                                                             // First ambient background blob (mauve colored)
            width: parent.width * 0.8; height: width; radius: width / 2         // 80% of parent width, circular shape
            x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150) // X position: centered + cosine orbital movement with 150-unit amplitude
            y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100) // Y position: centered + sine orbital movement with 100-unit amplitude
            opacity: 0.08                                                       // Very subtle 8% opacity for ambient effect
            color: window.mauve                                                 // Mauve color for this blob
            Behavior on color { ColorAnimation { duration: 1000 } }             // Smooth 1-second color transition when theme changes
        }
        
        Rectangle {                                                             // Second ambient background blob (blue colored)
            width: parent.width * 0.9; height: width; radius: width / 2         // 90% of parent width, circular, slightly larger than first blob
            x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150) // X position: uses sine with 1.5x frequency and negative 150-unit amplitude (opposite direction)
            y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100) // Y position: uses cosine with negative 100-unit amplitude
            opacity: 0.06                                                       // 6% opacity, slightly more subtle than first blob
            color: window.blue                                                  // Blue color for contrast with mauve blob
            Behavior on color { ColorAnimation { duration: 1000 } }             // Smooth color transition
        }

        ColumnLayout {                                                          // Main vertical layout for all UI elements
            anchors.fill: parent                                                // Fills the parent rectangle
            anchors.margins: window.s(25)                                       // 25-unit scaled margin on all sides
            spacing: window.s(20)                                               // 20-unit spacing between child elements

            // --- ANIMATED CHOREOGRAPHED VERSIONS ---                           // Comment divider for the version display animation section
            Item {                                                              // Container item for the version number display and animation
                id: versionContainer                                            // Unique identifier "versionContainer"
                Layout.fillWidth: true                                          // Fills the full width of the column
                Layout.preferredHeight: window.s(60)                            // Fixed height of 60 scaled units

                Text {                                                          // Text element displaying the old/local version
                    id: oldVer                                                  // Unique identifier "oldVer"
                    text: window.localVersion                                   // Displays the local version string
                    font.family: "JetBrains Mono"                               // Monospace font for version numbers
                    font.pixelSize: window.s(22)                                // 22-unit scaled font size
                    color: window.subtext0                                      // Subdued text color (muted, representing old version)
                    anchors.centerIn: parent                                    // Centered in the versionContainer
                    anchors.horizontalCenterOffset: 0                           // Starts exactly at center (will animate left)
                }
                
                Text {                                                          // Text element displaying the new/remote version
                    id: newVer                                                  // Unique identifier "newVer"
                    text: window.remoteVersion                                  // Displays the remote version string
                    font.family: "JetBrains Mono"                               // Monospace font
                    font.weight: Font.Black                                     // Heaviest font weight for emphasis
                    font.pixelSize: window.s(48)                                // Large 48-unit font size for prominence
                    color: window.green                                         // Green color indicating new/updated version
                    anchors.centerIn: parent                                    // Centered in the versionContainer
                    anchors.horizontalCenterOffset: window.s(20)                // Starts offset 20 units to the right (will slide to center)
                    opacity: 0                                                  // Starts fully transparent (will fade in)
                    scale: 0.8                                                  // Starts at 80% scale (will grow to 100%)
                }

                MultiEffect {                                                   // Graphical effect applied to the new version text
                    id: newVerEffect                                            // Unique identifier "newVerEffect"
                    source: newVer                                              // Applies effect to the newVer text element
                    anchors.fill: newVer                                        // Covers the same area as newVer
                    shadowEnabled: true                                         // Enables shadow/glow effect
                    shadowColor: window.green                                   // Green shadow color matching the text
                    shadowBlur: 0.0                                             // Initial blur amount of 0 (animated later)
                    shadowHorizontalOffset: 0                                   // No horizontal shadow offset
                    shadowVerticalOffset: 0                                     // No vertical shadow offset
                    opacity: newVer.opacity                                     // Matches the opacity of the newVer text
                }

                // Smooth, fluid animation sequence                              // Comment describing the version transition animation
                SequentialAnimation {                                           // Sequential animation for the version number swap
                    id: versionAnim                                             // Unique identifier "versionAnim"

                    PauseAnimation { duration: 150 }                            // Initial 150ms pause before starting

                    ParallelAnimation {                                         // Parallel animation: old fades out while new fades in
                        // 1. Old version smoothly slides left and disappears completely (slower) // Comment for old version exit
                        NumberAnimation {                                       // Animation for old version sliding left
                            target: oldVer; property: "anchors.horizontalCenterOffset"; // Animates the horizontal center offset
                            to: window.s(-30)                                   // Slides 30 units to the left
                            duration: 1200; easing.type: Easing.OutExpo         // Over 1.2 seconds with exponential ease-out
                        }
                        NumberAnimation {                                       // Animation for old version fading out
                            target: oldVer; property: "opacity";                // Animates opacity
                            to: 0.0                                             // Fades to fully transparent
                            duration: 1000; easing.type: Easing.OutSine         // Over 1 second with sine ease-out
                        }

                        // 2. New version slides into the EXACT center and scales up // Comment for new version entrance
                        SequentialAnimation {                                   // Nested sequential: waits then animates new version in
                            PauseAnimation { duration: 400 }                    // 400ms delay before new version appears (old version partially cleared)
                            ParallelAnimation {                                 // Parallel entrance animations for new version
                                NumberAnimation { target: newVer; property: "opacity"; to: 1; duration: 800; easing.type: Easing.OutSine } // Fades in over 800ms
                                NumberAnimation {                               // Slides new version to center
                                    target: newVer; property: "anchors.horizontalCenterOffset"; // Animates horizontal offset
                                    to: 0                                       // Slides to exact center (offset 0)
                                    duration: 1200; easing.type: Easing.OutExpo // Over 1.2 seconds with exponential ease-out
                                }
                                NumberAnimation {                               // Scales new version to full size
                                    target: newVer; property: "scale";          // Animates scale property
                                    to: 1.0;                                    // Grows to 100% size
                                    duration: 1200; easing.type: Easing.OutBack; easing.overshoot: 1.4 // Over 1.2 seconds with back easing, overshoots to 140% before settling
                                }
                            }
                            ScriptAction { script: glowAnim.start() }           // After entrance animation completes, starts the glow pulsing animation
                        }
                    }
                }

                SequentialAnimation {                                           // Continuous pulsing glow animation for the new version
                    id: glowAnim                                                // Unique identifier "glowAnim"
                    loops: Animation.Infinite                                   // Loops infinitely for continuous pulsing
                    NumberAnimation { target: newVerEffect; property: "shadowBlur"; to: 0.8; duration: 1500; easing.type: Easing.InOutSine } // Glow increases to 0.8 blur over 1.5 seconds
                    NumberAnimation { target: newVerEffect; property: "shadowBlur"; to: 0.2; duration: 1500; easing.type: Easing.InOutSine } // Glow decreases to 0.2 blur over 1.5 seconds
                }

                Connections {                                                   // Connection to detect when remote version data arrives
                    target: window                                              // Connects to the root window item
                    function onRemoteVersionChanged() {                         // Signal handler for remoteVersion property changes
                        if (window.remoteVersion !== "..." && window.remoteVersion !== "") { // Only trigger if we have a valid version (not placeholder)
                            versionAnim.start();                                // Start the version transition animation
                        }
                    }
                }
            }

            // --- CLEAN COMMIT LIST ---                                          // Comment divider for the commit changelog list section
            Item {                                                              // Container item for the scrollable commit list
                Layout.fillWidth: true                                          // Fills full width
                Layout.fillHeight: true                                         // Fills remaining vertical space
                clip: true                                                      // Clips content to bounds (for scrolling)

                ListView {                                                      // Scrollable list view for commit messages
                    id: changelogList                                           // Unique identifier "changelogList"
                    anchors.fill: parent                                        // Fills the parent Item
                    clip: true                                                  // Clips content for scrolling
                    model: commitModel                                          // Uses commitModel as the data source
                    spacing: window.s(8)                                        // 8-unit scaled spacing between commit boxes

                    ScrollBar.vertical: ScrollBar {                             // Vertical scrollbar for the list
                        active: true                                            // Scrollbar is always active (visible when needed)
                        policy: ScrollBar.AsNeeded                              // Only shows when content exceeds view height
                        contentItem: Rectangle {                                // Custom styling for the scrollbar thumb
                            implicitWidth: window.s(3);                         // 3-unit wide scrollbar
                            radius: window.s(1.5);                              // Rounded scrollbar thumb
                            color: window.surface2;                             // Surface2 color for the thumb
                            opacity: 0.5                                        // 50% opacity for subtle appearance
                        }
                    }

                    // Elegant pop-in transition for the separate commit boxes    // Comment describing the add transition animation
                    add: Transition {                                           // Transition applied when items are added to the list
                        ParallelAnimation {                                     // Parallel animation for pop-in effect
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutExpo } // Fades in from transparent over 400ms
                            NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: 450; easing.type: Easing.OutBack } // Scales from 95% to 100% with back easing (slight overshoot) over 450ms
                            NumberAnimation { property: "y"; from: y + window.s(15); duration: 450; easing.type: Easing.OutExpo } // Slides up from 15 units below final position over 450ms
                        }
                    }

                    delegate: Rectangle {                                       // Delegate defining the appearance of each commit box
                        width: changelogList.width - window.s(12)               // Width is list width minus 12-unit padding
                        height: Math.max(window.s(40), commitText.implicitHeight + window.s(20)) // Height is max of 40 units or content height plus 20-unit padding
                        
                        color: window.surface0                                  // Surface0 background for each commit box
                        radius: window.s(12)                                    // 12-unit rounded corners
                        
                        Text {                                                  // Text element displaying the commit message
                            id: commitText                                      // Unique identifier "commitText"
                            anchors.fill: parent                                // Fills the delegate rectangle
                            anchors.margins: window.s(10)                       // 10-unit margin on all sides
                            anchors.leftMargin: window.s(16)                    // 16-unit left margin for extra padding
                            anchors.rightMargin: window.s(16)                   // 16-unit right margin
                            text: model.lineText                                // Displays the commit message text from model
                            font.family: "JetBrains Mono"                       // Monospace font for code-like appearance
                            font.pixelSize: window.s(13)                        // 13-unit font size
                            color: window.text                                  // Primary text color
                            wrapMode: Text.WordWrap                             // Wraps text at word boundaries
                            verticalAlignment: Text.AlignVCenter                // Vertically centers text in the box
                            lineHeight: 1.4                                     // 1.4 line height for readability
                        }
                    }
                }
            }

            // --- HOLD TO UPDATE BUTTON ---                                      // Comment divider for the hold-to-confirm update button
            Rectangle {                                                         // Update button container rectangle
                id: updateBtn                                                   // Unique identifier "updateBtn"
                Layout.alignment: Qt.AlignHCenter                               // Horizontally centered in the layout
                Layout.preferredWidth: window.s(240)                            // Fixed width of 240 scaled units
                Layout.preferredHeight: window.s(54)                            // Fixed height of 54 scaled units
                radius: window.s(12)                                            // 12-unit rounded corners
                color: window.surface0                                          // Surface0 background
                border.color: btnMa.containsMouse ? window.green : window.surface2 // Green border on hover, surface2 otherwise
                border.width: btnMa.containsMouse ? window.s(2) : 1            // 2-pixel border on hover, 1-pixel normally
                clip: true                                                      // Clips the wave fill animation to rounded bounds
                
                scale: btnMa.pressed ? 0.98 : (btnMa.containsMouse ? 1.01 : 1.0) // 98% when pressed, 101% on hover, 100% normally
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } } // Smooth scale transition over 250ms
                Behavior on border.color { ColorAnimation { duration: 200 } }   // Smooth border color transition

                property real fillLevel: 0.0                                    // Property tracking fill progress (0.0 to 1.0) for hold-to-activate
                property bool triggered: false                                  // Boolean to prevent re-triggering once activated

                Canvas {                                                        // Canvas element for drawing the wave fill animation
                    id: waveCanvas                                              // Unique identifier "waveCanvas"
                    anchors.fill: parent                                        // Fills the button rectangle
                    
                    property real wavePhase: 0.0                                // Phase angle for the wave animation
                    NumberAnimation on wavePhase {                              // Continuous animation for wave phase
                        running: updateBtn.fillLevel > 0.0 && updateBtn.fillLevel < 1.0 // Only runs while filling (between 0 and 1)
                        loops: Animation.Infinite                               // Loops infinitely while running
                        from: 0; to: Math.PI * 2                               // Full circle phase cycle
                        duration: 1000                                          // 1 second per cycle
                    }
                    
                    onWavePhaseChanged: requestPaint()                          // Requests repaint when wave phase changes
                    Connections { target: updateBtn; function onFillLevelChanged() { waveCanvas.requestPaint() } } // Repaints when fill level changes
                    
                    onPaint: {                                                  // Paint function that draws the wave fill
                        var ctx = getContext("2d");                             // Gets 2D drawing context
                        ctx.clearRect(0, 0, width, height);                     // Clears the canvas
                        if (updateBtn.fillLevel <= 0.001) return;               // Don't draw if fill is negligible

                        var currentW = width * updateBtn.fillLevel;             // Current fill width based on fill level
                        var r = window.s(12);                                   // Corner radius matching button

                        ctx.save();                                             // Saves current drawing state
                        ctx.beginPath();                                        // Begins new path
                        ctx.moveTo(0, 0);                                       // Starts at top-left
                        
                        if (updateBtn.fillLevel < 0.99) {                       // If not fully filled, draw wavy edge
                            var waveAmp = window.s(8) * Math.sin(updateBtn.fillLevel * Math.PI); // Wave amplitude decreases near full (sine of fill * π)
                            var cp1x = currentW + Math.sin(wavePhase) * waveAmp; // Control point 1 X: varies with wave phase
                            var cp2x = currentW + Math.cos(wavePhase + Math.PI) * waveAmp; // Control point 2 X: offset by π for opposite curve

                            ctx.lineTo(currentW, 0);                            // Line to top of wave edge
                            ctx.bezierCurveTo(cp2x, height * 0.33, cp1x, height * 0.66, currentW, height); // Cubic bezier curve creating wavy edge
                            ctx.lineTo(0, height);                              // Line to bottom-left
                        } else {                                                // If fully filled, draw solid rectangle
                            ctx.lineTo(width, 0);                               // Line to top-right
                            ctx.lineTo(width, height);                          // Line to bottom-right
                            ctx.lineTo(0, height);                              // Line to bottom-left
                        }
                        ctx.closePath();                                        // Closes the path
                        ctx.clip();                                             // Clips drawing to this path

                        ctx.beginPath();                                        // Begins new path for rounded rectangle
                        ctx.roundedRect(0, 0, width, height, r, r);            // Draws rounded rectangle matching button shape
                        var grad = ctx.createLinearGradient(0, 0, width, 0);    // Creates horizontal gradient
                        grad.addColorStop(0, Qt.darker(window.green, 1.1).toString()); // Darker green at left side
                        grad.addColorStop(1, window.green.toString());          // Normal green at right side
                        ctx.fillStyle = grad;                                   // Sets fill to gradient
                        ctx.fill();                                             // Fills the rectangle

                        ctx.restore();                                          // Restores previous drawing state
                    }
                }

                RowLayout {                                                     // Horizontal layout for button icon and text
                    anchors.centerIn: parent                                    // Centered in the button
                    spacing: window.s(10)                                       // 10-unit spacing between icon and text
                    
                    Text {                                                      // Update/download icon
                        text: "󰚰"                                              // Nerd Font download icon
                        font.family: "Iosevka Nerd Font"                        // Nerd Font for icon rendering
                        font.pixelSize: window.s(18)                            // 18-unit icon size
                        color: updateBtn.fillLevel > 0.5 ? window.crust : window.green // Crust (light) color when fill > 50%, green otherwise (inverts for visibility)
                        Behavior on color { ColorAnimation { duration: 150 } }  // Quick color transition
                    }
                    
                    Text {                                                      // Button label text
                        text: updateBtn.fillLevel > 0 ? "HOLDING..." : "UPDATE" // Shows "HOLDING..." while pressed, "UPDATE" normally
                        font.family: "JetBrains Mono"                           // Monospace font
                        font.weight: Font.Black                                 // Heaviest font weight
                        font.pixelSize: window.s(14)                            // 14-unit font size
                        color: updateBtn.fillLevel > 0.5 ? window.crust : window.green // Inverts color when mostly filled
                        Behavior on color { ColorAnimation { duration: 150 } }  // Quick color transition
                    }
                }

                MouseArea {                                                     // Interactive area for the hold gesture
                    id: btnMa                                                   // Unique identifier "btnMa"
                    anchors.fill: parent                                        // Fills the entire button
                    hoverEnabled: true                                          // Enables hover detection
                    cursorShape: updateBtn.triggered ? Qt.ArrowCursor : Qt.PointingHandCursor // Arrow cursor when triggered, hand cursor otherwise
                    
                    onPressed: {                                                // When mouse/touch is pressed down
                        if (!updateBtn.triggered) {                             // Only if not already triggered
                            drainAnim.stop();                                   // Stop any draining animation
                            fillAnim.start();                                   // Start filling animation
                        }
                    }
                    
                    onReleased: {                                               // When mouse/touch is released
                        if (!updateBtn.triggered && updateBtn.fillLevel < 1.0) { // If not triggered and not fully filled
                            fillAnim.stop();                                    // Stop filling
                            drainAnim.start();                                  // Start draining back to 0
                        }
                    }
                }

                NumberAnimation {                                               // Animation that fills the button when held
                    id: fillAnim                                                // Unique identifier "fillAnim"
                    target: updateBtn                                           // Targets the updateBtn
                    property: "fillLevel"                                       // Animates fillLevel property
                    to: 1.0                                                     // Fills to 100%
                    duration: 1200 * (1.0 - updateBtn.fillLevel)                // Duration scales with remaining fill: longer when starting from 0, shorter near full
                    easing.type: Easing.InSine                                  // Accelerating sine easing
                    onFinished: {                                               // When fill completes
                        updateBtn.triggered = true;                             // Mark as triggered
                        let cmd = "if command -v kitty >/dev/null 2>&1; then kitty --hold bash -c 'eval \"$(curl -fsSL https://raw.githubusercontent.com/ilyamiro/imperative-dots/master/install.sh)\"'; else ${TERM:-xterm} -hold -e bash -c 'eval \"$(curl -fsSL https://raw.githubusercontent.com/ilyamiro/imperative-dots/master/install.sh)\"'; fi"; // Command: opens terminal and runs the install script, preferring kitty then falling back to xterm
                        Quickshell.execDetached(["bash", "-c", cmd]);           // Executes the install command in a detached shell
                        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]); // Closes the updater popup after triggering
                    }
                }

                NumberAnimation {                                               // Animation that drains the button when released early
                    id: drainAnim                                               // Unique identifier "drainAnim"
                    target: updateBtn                                           // Targets updateBtn
                    property: "fillLevel"                                       // Animates fillLevel
                    to: 0.0                                                     // Drains to 0%
                    duration: 800 * updateBtn.fillLevel                         // Duration proportional to current fill: faster when nearly empty
                    easing.type: Easing.OutCubic                                // Decelerating cubic easing
                }
            }
        }
    }
}