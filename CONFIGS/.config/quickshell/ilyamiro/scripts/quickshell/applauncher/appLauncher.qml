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
//     // COLORS (Expanded Dynamic Matugen Palette)
//     // -------------------------------------------------------------------------
//     MatugenColors { id: _theme }
    
//     readonly property color base: _theme.base
//     readonly property color mantle: _theme.mantle
//     readonly property color crust: _theme.crust
//     readonly property color text: _theme.text
//     readonly property color subtext0: _theme.subtext0
//     readonly property color overlay0: _theme.overlay0 || "#6c7086"
//     readonly property color overlay1: _theme.overlay1
//     readonly property color surface0: _theme.surface0
//     readonly property color surface1: _theme.surface1
//     readonly property color surface2: _theme.surface2
    
//     readonly property color mauve: _theme.mauve || "#cba6f7"
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
//     // STATE & LOGIC
//     // -------------------------------------------------------------------------
//     property var allApps: []

//     Process {
//         id: appFetcher
//         running: true
//         command: ["bash", "-c", "python3 " + Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/applauncher/app_fetcher.py"]
        
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 try {
//                     if (this.text && this.text.trim().length > 0) {
//                         window.allApps = JSON.parse(this.text);
//                         filterApps("");
//                     }
//                 } catch(e) {
//                     console.log("Error parsing apps list: ", e);
//                 }
//             }
//         }
//     }

//     ListModel {
//         id: appModel
//     }

//     // --- KEYBOARD NAV TRACKING (For Smart Highlight Morphing) ---
//     property bool isKeyboardNav: false
//     Timer {
//         id: keyboardNavTimer
//         interval: 500
//         repeat: false
//         onTriggered: window.isKeyboardNav = false
//     }

//     // --- SMART DIFFING FILTER ---
//     function filterApps(query) {
//         // Disable morphing behavior so the highlight box sticks to the flying item
//         window.isKeyboardNav = false;
//         if (keyboardNavTimer.running) keyboardNavTimer.stop();

//         appList.currentIndex = -1;
//         appList.positionViewAtBeginning();

//         let q = query.toLowerCase();
//         let filtered = [];
        
//         for (let i = 0; i < allApps.length; i++) {
//             if (allApps[i].name.toLowerCase().includes(q)) {
//                 filtered.push(allApps[i]);
//             }
//         }

//         for (let i = appModel.count - 1; i >= 0; i--) {
//             let currentName = appModel.get(i).name;
//             let keep = false;
//             for (let j = 0; j < filtered.length; j++) {
//                 if (filtered[j].name === currentName) {
//                     keep = true;
//                     break;
//                 }
//             }
//             if (!keep) {
//                 appModel.remove(i);
//             }
//         }

//         for (let i = 0; i < filtered.length; i++) {
//             let targetApp = filtered[i];
            
//             if (i < appModel.count) {
//                 if (appModel.get(i).name !== targetApp.name) {
//                     let foundIdx = -1;
//                     for (let j = i + 1; j < appModel.count; j++) {
//                         if (appModel.get(j).name === targetApp.name) {
//                             foundIdx = j;
//                             break;
//                         }
//                     }
//                     if (foundIdx !== -1) {
//                         appModel.move(foundIdx, i, 1);
//                     } else {
//                         appModel.insert(i, targetApp);
//                     }
//                 }
//             } else {
//                 appModel.append(targetApp);
//             }
//         }
        
//         if (appModel.count > 0) {
//             appList.currentIndex = 0;
//         }
//     }

//     function launchApp(execStr) {
//         Quickshell.execDetached(["hyprctl", "dispatch", "exec", "--", execStr]);
//         Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
//     }

//     // --- AGGRESSIVE FOCUS MANAGEMENT ---
//     Timer {
//         id: focusTimer
//         interval: 50
//         running: true
//         repeat: false
//         onTriggered: searchInput.forceActiveFocus()
//     }

//     Connections {
//         target: window
//         function onVisibleChanged() {
//             if (window.visible) {
//                 focusTimer.restart();
//                 introPhaseAnim.restart();
//             }
//         }
//     }

//     Keys.onEscapePressed: {
//         Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
//         event.accepted = true;
//     }

//     // --- BACKGROUND ORBIT ANIMATION ---
//     property real globalOrbitAngle: 0
//     NumberAnimation on globalOrbitAngle {
//         from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
//     }

//     // --- MAIN INTRO ANIMATION ---
//     property real introPhase: 0
//     NumberAnimation on introPhase {
//         id: introPhaseAnim
//         from: 0; to: 1; duration: 600; easing.type: Easing.OutExpo; running: true
//     }

//     // -------------------------------------------------------------------------
//     // UI LAYOUT
//     // -------------------------------------------------------------------------
//     Rectangle {
//         id: mainBg
//         width: parent.width
        
//         // --- DYNAMIC HEIGHT CALCULATION (Bottom-up Shrinking) ---
//         property real searchHeight: window.s(65)
//         property real separatorHeight: 1
//         property real itemHeight: window.s(60)
//         property real listSpacing: window.s(4)
//         property real maxListHeight: (8 * itemHeight) + (7 * listSpacing)
        
//         property real targetListHeight: appModel.count === 0 ? 0 : Math.min((appModel.count * itemHeight) + ((appModel.count - 1) * listSpacing), maxListHeight)
//         property real targetMargins: appModel.count > 0 ? window.s(20) : 0

//         // Smoothly animated properties for elegant container morphing
//         property real animatedListHeight: targetListHeight
//         property real animatedMargins: targetMargins

//         Behavior on animatedListHeight { 
//             NumberAnimation { duration: 500; easing.type: Easing.OutExpo } 
//         }
//         Behavior on animatedMargins { 
//             NumberAnimation { duration: 500; easing.type: Easing.OutExpo } 
//         }
        
//         height: searchHeight + separatorHeight + animatedMargins + animatedListHeight

//         anchors.top: parent.top
//         anchors.horizontalCenter: parent.horizontalCenter

//         radius: window.s(16)
//         color: Qt.rgba(window.base.r, window.base.g, window.base.b, 1.0)
//         border.color: window.surface1
//         border.width: 1
//         clip: true

//         transform: Translate { y: (window.introPhase - 1) * window.s(60) }
//         opacity: window.introPhase

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
//             spacing: 0

//             // --- SEARCH BAR ---
//             Rectangle {
//                 Layout.fillWidth: true
//                 Layout.preferredHeight: mainBg.searchHeight
//                 color: "transparent"
                
//                 RowLayout {
//                     anchors.fill: parent
//                     anchors.margins: window.s(15)
//                     anchors.leftMargin: window.s(20)
//                     anchors.rightMargin: window.s(20)
//                     spacing: window.s(15)

//                     Text {
//                         text: ""
//                         font.family: "Iosevka Nerd Font"
//                         font.pixelSize: window.s(18)
//                         color: searchInput.activeFocus ? window.mauve : window.subtext0
//                         Behavior on color { ColorAnimation { duration: 150 } }
//                     }

//                     TextField {
//                         id: searchInput
//                         Layout.fillWidth: true
//                         Layout.fillHeight: true
//                         background: Item {} 
//                         color: window.text
//                         font.family: "JetBrains Mono"
//                         font.pixelSize: window.s(16)
                        
//                         placeholderText: "Search..."
//                         placeholderTextColor: window.subtext0 
                        
//                         verticalAlignment: TextInput.AlignVCenter
//                         focus: true

//                         onTextChanged: filterApps(text)

//                         Keys.onDownPressed: {
//                             window.isKeyboardNav = true;
//                             keyboardNavTimer.restart();
//                             if (appList.currentIndex < appModel.count - 1) {
//                                 appList.currentIndex++;
//                             }
//                             event.accepted = true;
//                         }
//                         Keys.onUpPressed: {
//                             window.isKeyboardNav = true;
//                             keyboardNavTimer.restart();
//                             if (appList.currentIndex > 0) {
//                                 appList.currentIndex--;
//                             }
//                             event.accepted = true;
//                         }
//                         Keys.onReturnPressed: {
//                             if (appList.currentIndex >= 0 && appList.currentIndex < appModel.count) {
//                                 launchApp(appModel.get(appList.currentIndex).exec);
//                             }
//                             event.accepted = true;
//                         }
//                         Keys.onEscapePressed: {
//                             Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
//                             event.accepted = true;
//                         }
//                     }
//                 }
//             }

//             // --- SEPARATOR ---
//             Rectangle {
//                 Layout.fillWidth: true
//                 Layout.preferredHeight: mainBg.separatorHeight
//                 color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5)
//             }

//             // --- APPLICATION LIST ---
//             ListView {
//                 id: appList
//                 Layout.fillWidth: true
                
//                 Layout.preferredHeight: mainBg.animatedListHeight
//                 Layout.topMargin: mainBg.animatedMargins / 2
//                 Layout.bottomMargin: mainBg.animatedMargins / 2
//                 Layout.leftMargin: window.s(10)
//                 Layout.rightMargin: window.s(10)
                
//                 clip: true
//                 model: appModel
//                 spacing: mainBg.listSpacing
//                 currentIndex: 0
//                 boundsBehavior: Flickable.StopAtBounds

//                 highlightFollowsCurrentItem: false

//                 onCurrentIndexChanged: {
//                     if (currentIndex >= 0) {
//                         positionViewAtIndex(currentIndex, ListView.Contain);
//                     }
//                 }

//                 // --- ELEGANT LIST ITEM ANIMATIONS ---
//                 populate: Transition {
//                     ParallelAnimation {
//                         NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 550; easing.type: Easing.OutExpo }
//                         NumberAnimation { property: "scale"; from: 0.85; to: 1; duration: 600; easing.type: Easing.OutExpo }
//                         NumberAnimation { properties: "x,y"; duration: 600; easing.type: Easing.OutExpo }
//                     }
//                 }

//                 add: Transition {
//                     ParallelAnimation {
//                         NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 450; easing.type: Easing.OutExpo }
//                         NumberAnimation { property: "scale"; from: 0.85; to: 1; duration: 500; easing.type: Easing.OutExpo }
//                         NumberAnimation { properties: "x,y"; duration: 500; easing.type: Easing.OutExpo }
//                     }
//                 }
                
//                 remove: Transition {
//                     ParallelAnimation {
//                         NumberAnimation { property: "opacity"; to: 0; duration: 350; easing.type: Easing.OutExpo }
//                         NumberAnimation { property: "scale"; to: 0.85; duration: 400; easing.type: Easing.OutExpo }
//                     }
//                 }
                
//                 displaced: Transition {
//                     NumberAnimation { properties: "x,y"; duration: 500; easing.type: Easing.OutExpo }
//                 }

//                 ScrollBar.vertical: ScrollBar {
//                     active: true
//                     policy: ScrollBar.AsNeeded
//                     contentItem: Rectangle {
//                         implicitWidth: window.s(4)
//                         radius: window.s(2)
//                         color: window.surface2
//                         opacity: 0.5
//                     }
//                 }

//                 // --- MATTE MORPHING HIGHLIGHT ---
//                 highlight: Item {
//                     z: 0 
                    
//                     Rectangle {
//                         id: activeHighlight
//                         x: 0
//                         width: appList.width
//                         radius: window.s(8)
//                         color: window.mauve

//                         property int prevIdx: 0
//                         property int curIdx: appList.currentIndex

//                         onCurIdxChanged: {
//                             if (curIdx === -1) return; 
                            
//                             if (curIdx > prevIdx) {
//                                 bottomAnim.duration = 250; topAnim.duration = 450;
//                             } else if (curIdx < prevIdx) {
//                                 topAnim.duration = 250; bottomAnim.duration = 450;
//                             }
//                             prevIdx = curIdx;
//                         }

//                         // Track the current item's ACTUAL coordinates so it sticks mid-flight
//                         property real targetTop: appList.currentItem ? appList.currentItem.y : 0
//                         property real targetBottom: appList.currentItem ? (appList.currentItem.y + appList.currentItem.height) : 0

//                         property real actualTop: targetTop
//                         property real actualBottom: targetBottom

//                         // Only enable the morphed lagging behavior during keyboard navigation.
//                         // During search/diffing, it will instantly track the moving item.
//                         Behavior on actualTop { 
//                             enabled: window.isKeyboardNav
//                             NumberAnimation { id: topAnim; easing.type: Easing.OutExpo } 
//                         }
//                         Behavior on actualBottom { 
//                             enabled: window.isKeyboardNav
//                             NumberAnimation { id: bottomAnim; easing.type: Easing.OutExpo } 
//                         }

//                         y: actualTop
//                         height: actualBottom - actualTop
                        
//                         // Makes the highlight respect the item's pop-in scale animation
//                         scale: appList.currentItem ? appList.currentItem.scale : 1
                        
//                         opacity: appList.count > 0 && appList.currentIndex >= 0 ? 1 : 0
//                         Behavior on opacity { NumberAnimation { duration: 300 } }
//                     }
//                 }

//                 delegate: Item {
//                     width: ListView.view.width
//                     height: mainBg.itemHeight
//                     z: 1 
                    
//                     transformOrigin: Item.Center 

//                     Rectangle {
//                         anchors.fill: parent
//                         radius: window.s(8)
//                         color: "transparent"
                        
//                         Rectangle {
//                             anchors.fill: parent
//                             radius: window.s(8)
//                             color: window.surface0
//                             opacity: ma.containsMouse && index !== appList.currentIndex ? 0.4 : 0
//                             Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutSine } }
//                         }

//                         RowLayout {
//                             anchors.fill: parent
//                             anchors.margins: window.s(10)
//                             anchors.leftMargin: window.s(12)
//                             spacing: window.s(15)

//                             // --- TINTED ICON MATTE BOX ---
//                             Rectangle {
//                                 Layout.preferredWidth: window.s(40)
//                                 Layout.preferredHeight: window.s(40)
//                                 radius: window.s(12)
                                
//                                 color: index === appList.currentIndex ? window.crust : window.surface0
//                                 border.width: 0 
//                                 clip: true
                                
//                                 property real activeScale: index === appList.currentIndex ? 1.15 : 1
//                                 scale: activeScale
//                                 Behavior on activeScale { 
//                                     NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.5 } 
//                                 }
//                                 Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo } }

//                                 Image {
//                                     anchors.centerIn: parent
//                                     width: window.s(24)
//                                     height: window.s(24)
//                                     source: model.icon.startsWith("/") ? "file://" + model.icon : "image://icon/" + model.icon
//                                     sourceSize: Qt.size(64, 64)
//                                     fillMode: Image.PreserveAspectFit
//                                     asynchronous: true
//                                     smooth: true
//                                     mipmap: true
//                                 }
                                
//                                 // The Matugen Tint Overlay
//                                 Rectangle {
//                                     anchors.fill: parent
//                                     radius: window.s(12) 
                                    
//                                     color: window.mauve
//                                     opacity: index === appList.currentIndex ? 0.25 : 0.08 
                                    
//                                     Behavior on opacity { 
//                                         NumberAnimation { duration: 300; easing.type: Easing.OutExpo } 
//                                     }
//                                 }
//                             }

//                             Text {
//                                 Layout.fillWidth: true
//                                 text: model.name
//                                 font.family: "JetBrains Mono"
//                                 font.pixelSize: window.s(14)
//                                 font.weight: index === appList.currentIndex ? Font.Bold : Font.Medium
//                                 color: index === appList.currentIndex ? window.crust : window.text
//                                 elide: Text.ElideRight
//                                 verticalAlignment: Text.AlignVCenter
                                
//                                 property real textShift: index === appList.currentIndex ? window.s(6) : 0
//                                 transform: Translate { x: textShift }
                                
//                                 Behavior on textShift { 
//                                     NumberAnimation { duration: 500; easing.type: Easing.OutExpo } 
//                                 }
//                                 Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo } }
//                             }
//                         }

//                         MouseArea {
//                             id: ma
//                             anchors.fill: parent
//                             hoverEnabled: true
//                             onClicked: {
//                                 appList.currentIndex = index;
//                                 launchApp(model.exec);
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }




import QtQuick                                                                                               // Import the QtQuick module, which provides core QML types for building user interfaces (Item, Rectangle, animations, etc.)
import QtQuick.Window                                                                                        // Import QtQuick.Window for access to the Screen object and window-level properties
import QtQuick.Effects                                                                                       // Import QtQuick.Effects for visual effect components (MultiEffect, etc.) — though not directly used in this file, available for potential future effects
import QtQuick.Layouts                                                                                       // Import QtQuick.Layouts for layout management components like RowLayout and ColumnLayout
import QtQuick.Controls                                                                                      // Import QtQuick.Controls for interactive UI controls such as TextField, ScrollBar, and other standard widgets
import Quickshell                                                                                            // Import Quickshell, the shell platform providing desktop shell-specific functionality (Process, environment access, etc.)
import Quickshell.Io                                                                                         // Import Quickshell.Io for input/output utilities like StdioCollector that captures process output streams
import "../"                                                                                                 // Import parent directory to access sibling QML components like Scaler and MatugenColors

Item {                                                                                                       // Define the root Item element, serving as the main container for the entire app launcher interface
    id: window                                                                                               // Assign the identifier 'window' to this root item for referencing throughout the component
    focus: true                                                                                              // Ensure this item has keyboard focus so it can receive key events like Escape presses

    // --- Responsive Scaling Logic ---                                                                      // Section comment indicating the scaling system that adapts the UI based on screen resolution
    Scaler {                                                                                                 // Instantiate the Scaler component, which calculates scaling factors based on current screen dimensions
        id: scaler                                                                                           // Give this Scaler instance the id 'scaler' for referencing its scaling functions
        currentWidth: Screen.width                                                                           // Pass the current screen width in pixels to the Scaler so it can compute appropriate scaling ratios
    }
    
    function s(val) {                                                                                        // Define a convenience function 's' that takes a raw pixel value and returns a scaled value
        return scaler.s(val);                                                                                // Call the Scaler's internal 's' function to convert the given value to properly scaled pixels for current display
    }

    // -------------------------------------------------------------------------                               // Visual separator comment
    // COLORS (Expanded Dynamic Matugen Palette)                                                             // Section indicating that these are dynamic colors generated by Matugen (material color generator)
    // -------------------------------------------------------------------------                               // Visual separator comment
    MatugenColors { id: _theme }                                                                             // Instantiate MatugenColors component which reads the current Matugen-generated color scheme, accessible via '_theme'
    
    readonly property color base: _theme.base                                                                // Define a read-only property 'base' that exposes the background/base color from the Matugen theme
    readonly property color mantle: _theme.mantle                                                            // Define a read-only property 'mantle' — a slightly elevated surface color from the theme
    readonly property color crust: _theme.crust                                                              // Define a read-only property 'crust' — the darkest background color in the surface hierarchy
    readonly property color text: _theme.text                                                                // Define a read-only property 'text' for the primary text color from the theme
    readonly property color subtext0: _theme.subtext0                                                        // Define a read-only property 'subtext0' — secondary/dimmer text color for less prominent text
    readonly property color overlay0: _theme.overlay0 || "#6c7086"                                           // Define 'overlay0' with a fallback to a hex color "#6c7086" if the Matugen theme doesn't provide this color
    readonly property color overlay1: _theme.overlay1                                                        // Define 'overlay1' — an overlay/surface color one level lighter than overlay0
    readonly property color surface0: _theme.surface0                                                        // Define 'surface0' — the lowest elevated surface color (slightly lighter than base)
    readonly property color surface1: _theme.surface1                                                        // Define 'surface1' — a slightly elevated surface color, often used for cards and borders
    readonly property color surface2: _theme.surface2                                                        // Define 'surface2' — the highest elevated surface color in the standard surface hierarchy
    
    readonly property color mauve: _theme.mauve || "#cba6f7"                                                 // Define accent color 'mauve' with a fallback to soft purple "#cba6f7" if theme missing
    readonly property color pink: _theme.pink                                                                // Define accent color 'pink' from the Matugen theme palette
    readonly property color red: _theme.red                                                                  // Define accent color 'red' for error states or destructive actions
    readonly property color maroon: _theme.maroon                                                            // Define accent color 'maroon' — a deeper red variant from the theme
    readonly property color peach: _theme.peach                                                              // Define accent color 'peach' — warm orange tone from the theme
    readonly property color yellow: _theme.yellow                                                            // Define accent color 'yellow' for warnings or highlights
    readonly property color green: _theme.green                                                              // Define accent color 'green' for success states or positive indicators
    readonly property color teal: _theme.teal                                                                // Define accent color 'teal' — blue-green accent from the theme
    readonly property color sapphire: _theme.sapphire                                                        // Define accent color 'sapphire' — deep blue accent color
    readonly property color blue: _theme.blue                                                                // Define accent color 'blue' — standard blue from the Matugen palette

    // -------------------------------------------------------------------------                               // Visual separator comment
    // STATE & LOGIC                                                                                         // Section comment indicating application state management and core logic
    // -------------------------------------------------------------------------                               // Visual separator comment
    property var allApps: []                                                                                 // Define a property to hold an array of all fetched application objects (name, exec, icon) from the Python script

    Process {                                                                                                // Create a Process object to run the Python app fetcher as a child process
        id: appFetcher                                                                                       // Assign id 'appFetcher' to reference this process instance
        running: true                                                                                        // Set the process to start running immediately when the component is loaded
        command: ["bash", "-c", "python3 " + Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/applauncher/app_fetcher.py"] // Define the command: invoke bash to run python3 on the app_fetcher.py script located in the user's hypr config directory
        
        stdout: StdioCollector {                                                                             // Attach a StdioCollector to capture the standard output stream of the running process
            onStreamFinished: {                                                                              // Signal handler triggered when the process finishes writing to its stdout and the stream is complete
                try {                                                                                        // Begin try block to safely attempt JSON parsing of the collected output text
                    if (this.text && this.text.trim().length > 0) {                                          // Check if the captured text exists AND after trimming whitespace it has content (not empty)
                        window.allApps = JSON.parse(this.text);                                              // Parse the JSON text output from the Python script and store the resulting array in allApps property
                        filterApps("");                                                                      // Immediately call filterApps with empty query to populate the app list model with all discovered apps
                    }
                } catch(e) {                                                                                 // Catch any error that occurs during JSON parsing (malformed JSON, unexpected data, etc.)
                    console.log("Error parsing apps list: ", e);                                             // Log the error message to the console for debugging purposes, including the exception object
                }
            }
        }
    }

    ListModel {                                                                                              // Define a ListModel to hold the currently filtered/displayed application entries
        id: appModel                                                                                         // Assign id 'appModel' for referencing this data model from the ListView and filtering functions
    }

    // --- KEYBOARD NAV TRACKING (For Smart Highlight Morphing) ---                                           // Comment explaining that this section manages keyboard navigation state for highlight animation behavior
    property bool isKeyboardNav: false                                                                       // Boolean flag to track whether the user is currently navigating via keyboard (arrows) vs mouse
    Timer {                                                                                                  // Create a Timer to automatically reset the keyboard navigation flag after keyboard activity stops
        id: keyboardNavTimer                                                                                 // Assign id 'keyboardNavTimer' for controlling this timer
        interval: 500                                                                                        // Set the timer interval to 500 milliseconds (half a second) before auto-resetting
        repeat: false                                                                                        // Configure as a single-shot timer — it fires once and stops
        onTriggered: window.isKeyboardNav = false                                                            // When the timer triggers, set isKeyboardNav back to false to disable the morphing animation behavior
    }

    // --- SMART DIFFING FILTER ---                                                                           // Comment indicating this function intelligently updates the model with minimal changes (add/remove/move)
    function filterApps(query) {                                                                             // Define the filterApps function that takes a search query string to filter displayed applications
        // Disable morphing behavior so the highlight box sticks to the flying item                            // Comment explaining that keyboard nav morphing is disabled during search filtering
        window.isKeyboardNav = false;                                                                        // Set isKeyboardNav to false so the highlight follows items instantly without lagging during filtering
        if (keyboardNavTimer.running) keyboardNavTimer.stop();                                               // If the keyboard nav timer is currently running, stop it immediately to prevent stale state

        appList.currentIndex = -1;                                                                           // Reset the ListView's current index to -1 (no selection) before repopulating the filtered list
        appList.positionViewAtBeginning();                                                                   // Scroll the list view back to the very beginning (top) of the content

        let q = query.toLowerCase();                                                                         // Convert the search query string to lowercase for case-insensitive matching
        let filtered = [];                                                                                   // Initialize an empty array to hold the application objects that match the current filter
        
        for (let i = 0; i < allApps.length; i++) {                                                           // Iterate through all cached application objects in the allApps array
            if (allApps[i].name.toLowerCase().includes(q)) {                                                 // Check if the lowercase version of the app's name contains the lowercase query string anywhere
                filtered.push(allApps[i]);                                                                   // If the app name matches the query, add it to the filtered results array
            }
        }

        for (let i = appModel.count - 1; i >= 0; i--) {                                                      // Iterate backwards through the current model (backwards to safely remove items without index shifting)
            let currentName = appModel.get(i).name;                                                          // Get the name of the application at index i from the current model
            let keep = false;                                                                                // Initialize a flag 'keep' to false — assume this item should be removed unless found in filtered results
            for (let j = 0; j < filtered.length; j++) {                                                      // Loop through all apps in the new filtered results array
                if (filtered[j].name === currentName) {                                                      // Check if the filtered app's name matches the current model item's name exactly
                    keep = true;                                                                             // If a match is found, set keep to true — this item should remain in the model
                    break;                                                                                   // Exit the inner loop early since we found a match
                }
            }
            if (!keep) {                                                                                     // If the current model item was NOT found in the filtered results
                appModel.remove(i);                                                                          // Remove it from the model at index i (safe because we iterate backwards)
            }
        }

        for (let i = 0; i < filtered.length; i++) {                                                          // Iterate through the filtered results array to ensure model matches the filtered order
            let targetApp = filtered[i];                                                                     // Get the application object that should be at position i in the model
             
            if (i < appModel.count) {                                                                        // Check if index i exists within the current model bounds (there's already an item at this position)
                if (appModel.get(i).name !== targetApp.name) {                                               // If the app at position i doesn't match what should be there, we need to rearrange
                    let foundIdx = -1;                                                                       // Initialize foundIdx to -1 indicating the target app hasn't been found yet in the model
                    for (let j = i + 1; j < appModel.count; j++) {                                           // Search through the remaining model items (from i+1 onwards) trying to find the target app
                        if (appModel.get(j).name === targetApp.name) {                                       // Check if the app at index j has the same name as the target app we want at position i
                            foundIdx = j;                                                                    // If found, record its current index j in foundIdx
                            break;                                                                           // Exit the search loop since we found the target app
                        }
                    }
                    if (foundIdx !== -1) {                                                                   // If we found the target app elsewhere in the model (foundIdx is valid)
                        appModel.move(foundIdx, i, 1);                                                       // Move the item from foundIdx to index i (the desired position), moving exactly 1 item
                    } else {                                                                                 // If the target app wasn't found anywhere in the existing model
                        appModel.insert(i, targetApp);                                                       // Insert the targetApp at position i as a completely new entry in the model
                    }
                }
            } else {                                                                                         // If index i is beyond the current model size (i >= count), we need to append new items
                appModel.append(targetApp);                                                                  // Append the targetApp to the end of the model
            }
        }
        
        if (appModel.count > 0) {                                                                            // After filtering is complete, check if there are any items remaining in the model
            appList.currentIndex = 0;                                                                        // If items exist, select the first item (index 0) automatically for keyboard navigation readiness
        }
    }

    function launchApp(execStr) {                                                                            // Define a function to launch an application given its executable command string
        Quickshell.execDetached(["hyprctl", "dispatch", "exec", "--", execStr]);                             // Use hyprctl to dispatch an exec command in Hyprland, passing the app's exec string after '--' to separate arguments
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]); // Execute the qs_manager.sh script with "close" argument to hide/dismiss the Quickshell overlay after launching
    }

    // --- AGGRESSIVE FOCUS MANAGEMENT ---                                                                   // Comment indicating this section ensures the search input field keeps focus reliably
    Timer {                                                                                                  // Create a Timer dedicated to enforcing focus on the search input field
        id: focusTimer                                                                                       // Assign id 'focusTimer' for referencing this focus-enforcing timer
        interval: 50                                                                                         // Set a very short interval of 50 milliseconds for near-instant focus reclamation
        running: true                                                                                        // Set the timer to start running immediately when the component loads
        repeat: false                                                                                        // Configure as single-shot — fires once after 50ms, though it will be restarted by signal handlers
        onTriggered: searchInput.forceActiveFocus()                                                          // When the timer fires, programmatically force active keyboard focus onto the searchInput TextField
    }

    Connections {                                                                                            // Define a Connections object to wire up signal handlers for the window's visibility changes
        target: window                                                                                       // Specify that we are connecting to signals emitted by the root item (id: window)
        function onVisibleChanged() {                                                                        // Signal handler triggered whenever the window's 'visible' property changes value
            if (window.visible) {                                                                            // Check if the window just became visible (shown to the user)
                focusTimer.restart();                                                                        // Restart the focus timer to ensure the search input gets focus after the window appears
                introPhaseAnim.restart();                                                                    // Restart the intro animation so it plays from the beginning each time the panel opens
            }
        }
    }

    Keys.onEscapePressed: {                                                                                  // Handle the Escape key press event at the root item level
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]); // Execute the close script to dismiss the Quickshell overlay when Escape is pressed
        event.accepted = true;                                                                               // Mark the key event as accepted (handled) so it doesn't propagate further up the item hierarchy
    }

    // --- BACKGROUND ORBIT ANIMATION ---                                                                    // Comment indicating an orbital animation that drives moving decorative background elements
    property real globalOrbitAngle: 0                                                                        // Define a real number property to store the current angle (in radians) of the orbital animation cycle
    NumberAnimation on globalOrbitAngle {                                                                    // Apply a NumberAnimation directly to the globalOrbitAngle property
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true                  // Animate from 0 to 2π (full circle) over 90 seconds, looping infinitely, starting immediately
    }

    // --- MAIN INTRO ANIMATION ---                                                                           // Comment indicating the intro animation property that controls the panel's entrance effect
    property real introPhase: 0                                                                              // Define a property to track the progress of the intro animation (0 = start, 1 = end)
    NumberAnimation on introPhase {                                                                          // Apply a NumberAnimation to the introPhase property for smooth entrance transition
        id: introPhaseAnim                                                                                   // Assign id 'introPhaseAnim' so we can restart this animation from code when the panel becomes visible
        from: 0; to: 1; duration: 600; easing.type: Easing.OutExpo; running: true                            // Animate from 0 to 1 over 600ms with an exponential ease-out curve for a smooth deceleration, starts automatically
    }

    // -------------------------------------------------------------------------                               // Visual separator comment
    // UI LAYOUT                                                                                             // Section indicating the actual visual user interface components begin here
    // -------------------------------------------------------------------------                               // Visual separator comment
    Rectangle {                                                                                              // Create the main background container Rectangle for the app launcher panel
        id: mainBg                                                                                           // Assign id 'mainBg' for referencing this container throughout the UI
        width: parent.width                                                                                  // Set the width to fill the full width of the parent (root) item
        
        // --- DYNAMIC HEIGHT CALCULATION (Bottom-up Shrinking) ---                                           // Comment explaining the height calculation logic that adapts to the number of visible items
        property real searchHeight: window.s(65)                                                             // Define the scaled height of the search bar section (65dp scaled by screen factor)
        property real separatorHeight: 1                                                                     // Define the separator line height as a thin 1-pixel line
        property real itemHeight: window.s(60)                                                               // Define the scaled height for each individual app list item (60dp scaled)
        property real listSpacing: window.s(4)                                                               // Define the scaled spacing gap between list items (4dp scaled)
        property real maxListHeight: (8 * itemHeight) + (7 * listSpacing)                                    // Calculate the maximum list height for 8 visible items (8 items + 7 gaps between them)
        
        property real targetListHeight: appModel.count === 0 ? 0 : Math.min((appModel.count * itemHeight) + ((appModel.count - 1) * listSpacing), maxListHeight) // Calculate desired list height: 0 if empty, otherwise the height needed for all items or capped at maxListHeight
        property real targetMargins: appModel.count > 0 ? window.s(20) : 0                                   // Set target margins to scaled 20dp if there are items, or 0 if list is empty (no margin needed)
 
        // Smoothly animated properties for elegant container morphing                                        // Comment indicating these properties drive the animated/responsive container behavior
        property real animatedListHeight: targetListHeight                                                   // Define the actual animatable list height property, initialized to the target height
        property real animatedMargins: targetMargins                                                         // Define the actual animatable margins property, initialized to the target margins

        Behavior on animatedListHeight {                                                                     // Attach a default animation behavior to changes in animatedListHeight property
            NumberAnimation { duration: 500; easing.type: Easing.OutExpo }                                   // Animate height changes over 500ms with an exponential ease-out curve for smooth expansion/contraction
        }
        Behavior on animatedMargins {                                                                        // Attach a default animation behavior to changes in animatedMargins property
            NumberAnimation { duration: 500; easing.type: Easing.OutExpo }                                   // Animate margin changes also over 500ms with exponential ease-out for cohesive visual transition
        }
        
        height: searchHeight + separatorHeight + animatedMargins + animatedListHeight                        // Calculate total container height: search + separator + top margin + list height (margins applied once as total)

        anchors.top: parent.top                                                                              // Anchor the top edge of the panel to the top of the parent (root item)
        anchors.horizontalCenter: parent.horizontalCenter                                                    // Center the panel horizontally within the parent

        radius: window.s(16)                                                                                 // Apply rounded corners with a scaled radius of 16dp to the panel
        color: Qt.rgba(window.base.r, window.base.g, window.base.b, 1.0)                                     // Set the background color to the theme's base color with full opacity by extracting RGB components and using 1.0 alpha
        border.color: window.surface1                                                                        // Set the border color to the surface1 theme color for a subtle elevated border effect
        border.width: 1                                                                                      // Set the border width to 1 pixel for a thin, elegant outline
        clip: true                                                                                           // Enable clipping so that child items (like rounded highlight) don't draw outside the rounded rectangle bounds

        transform: Translate { y: (window.introPhase - 1) * window.s(60) }                                   // Apply a vertical translate transform: when introPhase is 0, panel is offset up by 60dp; when 1, offset is 0 (panel slides in from above)
        opacity: window.introPhase                                                                           // Bind the panel's opacity directly to introPhase, so it fades from 0 to 1 during the intro animation

        // --- AMBIENT BLOBS ---                                                                              // Comment indicating decorative animated blob elements that drift in the background for visual interest
        Rectangle {                                                                                          // Create the first ambient blob — a large semi-transparent rounded rectangle
            width: parent.width * 0.8; height: width; radius: width / 2                                      // Make it a circle/square shape: width is 80% of parent, height equals width (square), radius half makes it circular
            x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)         // Calculate x position: centered horizontally then offset by cosine of double orbit angle, scaled by 150dp for orbital movement
            y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)      // Calculate y position: centered vertically then offset by sine of double orbit angle, scaled by 100dp for orbital movement
            opacity: 0.08                                                                                    // Set very low opacity (8%) so the blob is subtle and not distracting
            color: window.mauve                                                                              // Color the blob with the mauve accent color from the theme
            Behavior on color { ColorAnimation { duration: 1000 } }                                          // When the color property changes (theme switch), animate the transition smoothly over 1 second
        }
        
        Rectangle {                                                                                          // Create the second ambient blob — slightly different size and orbital parameters for variety
            width: parent.width * 0.9; height: width; radius: width / 2                                      // Make a slightly larger circle: width 90% of parent, height equals width, radius makes it circular
            x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)     // Calculate x: centered then offset by sine of 1.5x orbit angle, negated scaled 150dp (moves opposite direction)
            y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)   // Calculate y: centered then offset by cosine of 1.5x orbit angle, negated scaled 100dp (opposite movement pattern)
            opacity: 0.06                                                                                    // Even lower opacity (6%) for this blob to create depth through varying transparency
            color: window.blue                                                                               // Color this blob with the blue accent color for contrast with the mauve blob
            Behavior on color { ColorAnimation { duration: 1000 } }                                          // Smooth color transition over 1 second when the theme changes
        }

        ColumnLayout {                                                                                       // Create a vertical column layout to arrange the search bar, separator, and app list sequentially
            anchors.fill: parent                                                                             // Make the column layout fill the entire mainBg rectangle
            spacing: 0                                                                                       // Set zero spacing between layout children — we'll manually control positioning

            // --- SEARCH BAR ---                                                                             // Comment indicating the search bar section at the top of the panel
            Rectangle {                                                                                      // Container rectangle for the search bar row
                Layout.fillWidth: true                                                                       // Make this rectangle fill the full width of the column layout
                Layout.preferredHeight: mainBg.searchHeight                                                  // Set its height to the predefined searchHeight property of the mainBg
                color: "transparent"                                                                         // Make the rectangle itself transparent (it's just a container)

                RowLayout {                                                                                  // Create a horizontal row layout for the search icon and text input field
                    anchors.fill: parent                                                                     // Make the row layout fill the entire search bar rectangle
                    anchors.margins: window.s(15)                                                            // Set uniform margins of 15dp around all sides of the row layout
                    anchors.leftMargin: window.s(20)                                                         // Override just the left margin to 20dp for extra padding on the left
                    anchors.rightMargin: window.s(20)                                                        // Override just the right margin to 20dp for symmetrical padding
                    spacing: window.s(15)                                                                    // Set 15dp spacing between the search icon and the text input field

                    Text {                                                                                   // Text element to display the search magnifying glass icon
                        text: ""                                                                            // Set the text to the Font Awesome magnifying glass unicode character (U+F002)
                        font.family: "Iosevka Nerd Font"                                                     // Use Iosevka Nerd Font which includes the icon glyphs (Nerd Font variant)
                        font.pixelSize: window.s(18)                                                         // Set the font size to 18 scaled device-independent pixels
                        color: searchInput.activeFocus ? window.mauve : window.subtext0                       // Dynamic color: mauve accent when search field is focused, subtext0 (dim) when unfocused
                        Behavior on color { ColorAnimation { duration: 150 } }                               // Animate the color transition over 150ms for a smooth visual feedback when focus changes
                    }

                    TextField {                                                                              // Create the search text input field where users type to filter applications
                        id: searchInput                                                                      // Assign id 'searchInput' for referencing this field (focus management, key handlers)
                        Layout.fillWidth: true                                                               // Allow the text field to expand and fill all remaining horizontal space in the row
                        Layout.fillHeight: true                                                              // Allow the text field to fill the full height of the search bar row
                        background: Item {}                                                                  // Set an empty Item as background to remove the default TextField styling (no border/background)
                        color: window.text                                                                   // Set the text color to the theme's primary text color
                        font.family: "JetBrains Mono"                                                        // Use JetBrains Mono font for the search input text
                        font.pixelSize: window.s(16)                                                         // Set font size to 16 scaled pixels for comfortable readability
                        
                        placeholderText: "Search..."                                                         // Display "Search..." as placeholder text when the field is empty
                        placeholderTextColor: window.subtext0                                                 // Set the placeholder text color to subtext0 (dim secondary text color)
                        
                        verticalAlignment: TextInput.AlignVCenter                                            // Vertically center the text content within the input field's height
                        focus: true                                                                          // Request keyboard focus on this field by default (though managed by focus timer)

                        onTextChanged: filterApps(text)                                                      // Whenever the user types/deletes text, call filterApps with the current text to update results

                        Keys.onDownPressed: {                                                                // Handle the Down arrow key press within the search field
                            window.isKeyboardNav = true;                                                     // Set the keyboard navigation flag to true — user is now navigating via keyboard
                            keyboardNavTimer.restart();                                                      // Restart the keyboard nav timer to keep it alive while the user keeps pressing keys
                            if (appList.currentIndex < appModel.count - 1) {                                 // Check if the currently selected item is not the last item in the list
                                appList.currentIndex++;                                                      // Move the selection down by incrementing the current index
                            }
                            event.accepted = true;                                                           // Mark the event as handled so it doesn't propagate to other handlers
                        }
                        Keys.onUpPressed: {                                                                  // Handle the Up arrow key press within the search field
                            window.isKeyboardNav = true;                                                     // Set keyboard nav flag to true
                            keyboardNavTimer.restart();                                                      // Restart the keyboard nav timer
                            if (appList.currentIndex > 0) {                                                  // Check if the selected item is not the very first item
                                appList.currentIndex--;                                                      // Move the selection up by decrementing the current index
                            }
                            event.accepted = true;                                                           // Mark event as handled
                        }
                        Keys.onReturnPressed: {                                                              // Handle the Return/Enter key press
                            if (appList.currentIndex >= 0 && appList.currentIndex < appModel.count) {         // Verify that a valid item is currently selected (index within bounds)
                                launchApp(appModel.get(appList.currentIndex).exec);                           // Launch the selected application by calling launchApp with its exec command string
                            }
                            event.accepted = true;                                                           // Mark event as handled
                        }
                        Keys.onEscapePressed: {                                                              // Handle the Escape key press within the search field
                            Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]); // Close the entire Quickshell panel via the manager script
                            event.accepted = true;                                                           // Mark event as handled
                        }
                    }
                }
            }

            // --- SEPARATOR ---                                                                               // Comment indicating the thin horizontal separator line between search and results
            Rectangle {                                                                                      // Rectangle acting as a visual separator/horizontal line
                Layout.fillWidth: true                                                                       // Stretch to the full width of the layout
                Layout.preferredHeight: mainBg.separatorHeight                                               // Set height to the predefined 1-pixel separator height
                color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5)                 // Color the separator with surface1 at 50% opacity for a subtle, semi-transparent line
            }

            // --- APPLICATION LIST ---                                                                        // Comment indicating the scrollable list view of filtered application entries
            ListView {                                                                                       // Create a ListView to display the filtered application model items
                id: appList                                                                                  // Assign id 'appList' for referencing this view (currentIndex, positioning, etc.)
                Layout.fillWidth: true                                                                       // Fill the available width in the column layout
                
                Layout.preferredHeight: mainBg.animatedListHeight                                            // Bind the list height to the animated property that smoothly adjusts to content changes
                Layout.topMargin: mainBg.animatedMargins / 2                                                 // Apply half of the animated margins as top margin inside the layout
                Layout.bottomMargin: mainBg.animatedMargins / 2                                              // Apply half of the animated margins as bottom margin for symmetric spacing
                Layout.leftMargin: window.s(10)                                                              // Set 10dp left margin for inner padding
                Layout.rightMargin: window.s(10)                                                             // Set 10dp right margin for inner padding
                
                clip: true                                                                                   // Enable clipping so items don't show outside the list's rounded bounds
                model: appModel                                                                              // Bind the ListView's data model to our appModel ListModel defined earlier
                spacing: mainBg.listSpacing                                                                  // Set the spacing between list items to the predefined scaled spacing value
                currentIndex: 0                                                                              // Set the initial current/selected index to 0 (first item)
                boundsBehavior: Flickable.StopAtBounds                                                        // Prevent the list from scrolling past its content boundaries (no bouncing/overscroll)

                highlightFollowsCurrentItem: false                                                           // Disable the default highlight follow behavior; we will implement a custom morphing highlight

                onCurrentIndexChanged: {                                                                     // Signal handler triggered whenever the currentIndex property changes value
                    if (currentIndex >= 0) {                                                                 // Check if the new index is valid (non-negative, meaning an item is selected)
                        positionViewAtIndex(currentIndex, ListView.Contain);                                 // Scroll the view to ensure the currently selected item is visible within the viewport
                    }
                }

                // --- ELEGANT LIST ITEM ANIMATIONS ---                                                       // Comment indicating transition animations for items appearing, changing, and leaving the list
                populate: Transition {                                                                       // Define the transition for items when the view is first populated (initial fill)
                    ParallelAnimation {                                                                      // Group multiple animations to run simultaneously
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 550; easing.type: Easing.OutExpo } // Fade items in from transparent to opaque over 550ms with exponential ease-out
                        NumberAnimation { property: "scale"; from: 0.85; to: 1; duration: 600; easing.type: Easing.OutExpo } // Scale items up from 85% to full size over 600ms for a pop-in effect
                        NumberAnimation { properties: "x,y"; duration: 600; easing.type: Easing.OutExpo }    // Animate position changes over 600ms so items slide smoothly into place
                    }
                }

                add: Transition {                                                                            // Define the transition animation for newly added items entering the list
                    ParallelAnimation {                                                                      // Run fade, scale, and position animations together for a cohesive entrance
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 450; easing.type: Easing.OutExpo } // Fade in new items over 450ms (slightly faster than populate)
                        NumberAnimation { property: "scale"; from: 0.85; to: 1; duration: 500; easing.type: Easing.OutExpo } // Scale up from 85% to 100% over 500ms
                        NumberAnimation { properties: "x,y"; duration: 500; easing.type: Easing.OutExpo }    // Animate position for 500ms so new items fly into their correct spot
                    }
                }
                
                remove: Transition {                                                                         // Define the transition animation for items being removed from the list
                    ParallelAnimation {                                                                      // Run fade and scale animations in parallel for a smooth exit
                        NumberAnimation { property: "opacity"; to: 0; duration: 350; easing.type: Easing.OutExpo } // Fade out removed items to fully transparent over 350ms
                        NumberAnimation { property: "scale"; to: 0.85; duration: 400; easing.type: Easing.OutExpo } // Shrink items down to 85% scale over 400ms as they leave
                    }
                }
                
                displaced: Transition {                                                                      // Define the transition for items that need to move to make room (displaced by adds/removes)
                    NumberAnimation { properties: "x,y"; duration: 500; easing.type: Easing.OutExpo }        // Smoothly animate displaced items sliding to their new positions over 500ms
                }

                ScrollBar.vertical: ScrollBar {                                                              // Attach a custom vertical scrollbar to the ListView
                    active: true                                                                             // Keep the scrollbar always active (visible) rather than auto-hiding
                    policy: ScrollBar.AsNeeded                                                               // Show the scrollbar only when the content exceeds the viewport height (as needed)
                    contentItem: Rectangle {                                                                 // Customize the visual appearance of the scrollbar thumb
                        implicitWidth: window.s(4)                                                           // Set the scrollbar thumb width to 4 scaled pixels (very thin)
                        radius: window.s(2)                                                                  // Apply a 2dp radius for slightly rounded thumb edges
                        color: window.surface2                                                               // Color the thumb with surface2 color from the theme
                        opacity: 0.5                                                                         // Make the scrollbar semi-transparent (50% opacity) so it's subtle
                    }
                }

                // --- MATTE MORPHING HIGHLIGHT ---                                                           // Comment indicating the custom animated highlight that smoothly morphs between selected items
                highlight: Item {                                                                            // Define the highlight component as an Item (container for the actual highlight rectangle)
                    z: 0                                                                                     // Set z-index to 0 so the highlight renders behind the delegate items (which have z:1)
                    
                    Rectangle {                                                                              // Create the actual colored highlight rectangle
                        id: activeHighlight                                                                  // Assign id 'activeHighlight' for internal property references
                        x: 0                                                                                 // Position the highlight at the left edge of the ListView
                        width: appList.width                                                                 // Stretch the highlight to the full width of the ListView
                        radius: window.s(8)                                                                  // Apply 8dp rounded corners to the highlight bar
                        color: window.mauve                                                                  // Color the highlight with the mauve accent color for strong visual emphasis

                        property int prevIdx: 0                                                              // Internal property to store the previously selected index for animation direction detection
                        property int curIdx: appList.currentIndex                                            // Internal property bound to the current selected index of the ListView

                        onCurIdxChanged: {                                                                   // Signal handler triggered when the curIdx property (bound to currentIndex) changes
                            if (curIdx === -1) return;                                                       // If nothing is selected (index -1), exit early without adjusting animations
                            
                            if (curIdx > prevIdx) {                                                          // If navigating DOWN (new index is greater than previous)
                                bottomAnim.duration = 250; topAnim.duration = 450;                           // Set bottom edge to animate faster (250ms) and top edge slower (450ms) for a fluid downward stretch
                            } else if (curIdx < prevIdx) {                                                   // If navigating UP (new index is less than previous)
                                topAnim.duration = 250; bottomAnim.duration = 450;                            // Set top edge faster (250ms) and bottom edge slower (450ms) for a fluid upward stretch
                            }
                            prevIdx = curIdx;                                                                // Update prevIdx to the current index for the next comparison
                        }

                        // Track the current item's ACTUAL coordinates so it sticks mid-flight                  // Comment explaining that these properties track the dynamic position of the current delegate item
                        property real targetTop: appList.currentItem ? appList.currentItem.y : 0              // Get the Y coordinate of the currently selected item's top edge, or 0 if no item selected
                        property real targetBottom: appList.currentItem ? (appList.currentItem.y + appList.currentItem.height) : 0 // Calculate the bottom edge Y coordinate of the selected item, or 0 if none

                        property real actualTop: targetTop                                                   // The actual used top coordinate, initialized to targetTop; can lag behind during animations
                        property real actualBottom: targetBottom                                             // The actual used bottom coordinate, initialized to targetBottom; can lag behind during animations

                        // Only enable the morphed lagging behavior during keyboard navigation.                // Comment explaining the conditional morphing: lagging only active when user uses keyboard arrows
                        // During search/diffing, it will instantly track the moving item.                    // Comment: during search filtering, the highlight snaps instantly to follow the first item
                        Behavior on actualTop {                                                              // Attach an animation behavior to changes in the actualTop property
                            enabled: window.isKeyboardNav                                                    // Only enable this animated behavior when the user is navigating using the keyboard
                            NumberAnimation { id: topAnim; easing.type: Easing.OutExpo }                     // Define the animation for top edge movement using OutExpo easing (no hardcoded duration; set dynamically)
                        }
                        Behavior on actualBottom {                                                           // Attach an animation behavior to changes in the actualBottom property
                            enabled: window.isKeyboardNav                                                    // Enable only during keyboard navigation
                            NumberAnimation { id: bottomAnim; easing.type: Easing.OutExpo }                  // Define the animation for bottom edge movement with OutExpo easing
                        }

                        y: actualTop                                                                         // Set the highlight's Y position to the animated actualTop value (top edge of selection)
                        height: actualBottom - actualTop                                                     // Calculate the highlight's height as the difference between animated bottom and top edges
                        
                        // Makes the highlight respect the item's pop-in scale animation                      // Comment: the highlight scales with the delegate item so it matches the pop-in/out effects
                        scale: appList.currentItem ? appList.currentItem.scale : 1                           // Mirror the scale of the currently selected delegate item, or 1 (full size) if no item
                        
                        opacity: appList.count > 0 && appList.currentIndex >= 0 ? 1 : 0                      // Show highlight (opacity 1) only when there are items and a valid index is selected; otherwise hide it
                        Behavior on opacity { NumberAnimation { duration: 300 } }                            // Smoothly animate opacity changes over 300ms for a gentle fade in/out of the highlight
                    }
                }

                delegate: Item {                                                                             // Define the delegate component that renders each individual application item in the ListView
                    width: ListView.view.width                                                               // Set the delegate item width to the full width of the ListView
                    height: mainBg.itemHeight                                                                // Set each delegate's height to the predefined item height from mainBg
                    z: 1                                                                                     // Set z-index to 1 so delegate items render above the highlight (z:0) for proper layering
                    
                    transformOrigin: Item.Center                                                             // Set the transform origin to the center of the item (scale animations will originate from center)

                    Rectangle {                                                                              // Transparent container rectangle for each list entry
                        anchors.fill: parent                                                                 // Make this rectangle fill the entire delegate item area
                        radius: window.s(8)                                                                  // Apply 8dp rounded corners to match the highlight style
                        color: "transparent"                                                                 // Set the background to completely transparent (the highlight provides the selection indicator)
                        
                        Rectangle {                                                                          // Inner rectangle for the hover effect (shows on mouse over when item is not selected)
                            anchors.fill: parent                                                             // Fill the parent rectangle completely
                            radius: window.s(8)                                                              // Apply matching 8dp radius
                            color: window.surface0                                                           // Color this hover overlay with surface0 from the theme
                            opacity: ma.containsMouse && index !== appList.currentIndex ? 0.4 : 0            // Show at 40% opacity on hover only if the mouse is over this item AND it's not the currently selected item; otherwise fully transparent
                            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutSine } } // Animate hover opacity with sine ease-out for a smooth, subtle glow effect
                        }

                        RowLayout {                                                                          // Horizontal row layout to arrange the app icon and name text side by side
                            anchors.fill: parent                                                             // Fill the entire delegate area
                            anchors.margins: window.s(10)                                                    // Set uniform 10dp margins around the row content
                            anchors.leftMargin: window.s(12)                                                 // Override left margin to 12dp for slightly more padding on the left
                            spacing: window.s(15)                                                            // Set 15dp spacing between the icon box and the app name text

                            // --- TINTED ICON MATTE BOX ---                                                 // Comment describing the decorative icon container with tinted overlay effect
                            Rectangle {                                                                      // Container rectangle for the application icon with tinting
                                Layout.preferredWidth: window.s(40)                                          // Set fixed width of 40dp for the icon container
                                Layout.preferredHeight: window.s(40)                                         // Set fixed height of 40dp (square container)
                                radius: window.s(12)                                                         // Apply 12dp corner radius for a soft-rounded square look
                                
                                color: index === appList.currentIndex ? window.crust : window.surface0        // Dynamic background: darkest crust color when selected, surface0 when unselected
                                border.width: 0                                                              // No visible border on the icon container
                                clip: true                                                                   // Enable clipping so the tint overlay doesn't spill outside the rounded corners
                                
                                property real activeScale: index === appList.currentIndex ? 1.15 : 1          // Property that scales up to 115% when this item is selected, stays at 100% otherwise
                                scale: activeScale                                                           // Apply the activeScale to the icon container's scale transform
                                Behavior on activeScale {                                                    // Attach animation to the activeScale property changes
                                    NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.5 } // Animate scale over 500ms with OutBack easing (overshoots for a bouncy pop effect, 1.5x overshoot)
                                }
                                Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo } } // Smoothly animate background color changes over 300ms when selection state toggles

                                Image {                                                                      // Image element to display the application's icon
                                    anchors.centerIn: parent                                                 // Center the icon image within the container rectangle
                                    width: window.s(24)                                                      // Set icon width to 24dp
                                    height: window.s(24)                                                     // Set icon height to 24dp
                                    source: model.icon.startsWith("/") ? "file://" + model.icon : "image://icon/" + model.icon // Determine icon source: if it begins with '/', it's a file path prefixed with "file://"; otherwise use Qt's icon theme system with "image://icon/"
                                    sourceSize: Qt.size(64, 64)                                              // Request the icon to be loaded at 64x64 resolution for crisp rendering at any display scale
                                    fillMode: Image.PreserveAspectFit                                        // Scale the icon to fit within the bounds while maintaining its original aspect ratio
                                    asynchronous: true                                                       // Load the icon image asynchronously to prevent UI stuttering during scrolling
                                    smooth: true                                                             // Enable smooth filtering for higher quality scaling results
                                    mipmap: true                                                             // Enable mipmapping for better rendering quality when the icon is scaled down
                                }
                                
                                // The Matugen Tint Overlay                                                   // Comment: a semi-transparent colored overlay that tints all icons toward the mauve accent color
                                Rectangle {                                                                  // Overlay rectangle for applying the mauve tint effect
                                    anchors.fill: parent                                                     // Cover the entire icon container
                                    radius: window.s(12)                                                     // Match the parent's 12dp border radius
                                    
                                    color: window.mauve                                                      // Use the mauve accent color for the tint
                                    opacity: index === appList.currentIndex ? 0.25 : 0.08                    // Stronger tint (25%) on the selected item for emphasis, subtle tint (8%) on all other items
                                    
                                    Behavior on opacity {                                                    // Animate opacity changes on this overlay
                                        NumberAnimation { duration: 300; easing.type: Easing.OutExpo }       // Smooth 300ms exponential ease-out transition when selection changes
                                    }
                                }
                            }

                            Text {                                                                           // Text element displaying the application's display name
                                Layout.fillWidth: true                                                       // Allow the text to expand and fill remaining horizontal space
                                text: model.name                                                             // Bind the displayed text to the 'name' property from the ListModel
                                font.family: "JetBrains Mono"                                                // Use JetBrains Mono font for consistent monospace typography
                                font.pixelSize: window.s(14)                                                 // Set font size to 14 scaled pixels
                                font.weight: index === appList.currentIndex ? Font.Bold : Font.Medium         // Use Bold weight for the selected item, Medium weight for unselected items
                                color: index === appList.currentIndex ? window.crust : window.text            // Darkest crust color for selected text (contrast against mauve highlight), normal text color for unselected
                                elide: Text.ElideRight                                                       // If the text is too long to fit, show an ellipsis (...) on the right side
                                verticalAlignment: Text.AlignVCenter                                         // Vertically center the text within the row layout
                                
                                property real textShift: index === appList.currentIndex ? window.s(6) : 0     // Property that shifts text right by 6dp when selected (subtle indent effect on selection)
                                transform: Translate { x: textShift }                                        // Apply a horizontal translate transform using the textShift value
                                
                                Behavior on textShift {                                                      // Animate the textShift property changes
                                    NumberAnimation { duration: 500; easing.type: Easing.OutExpo }           // Smooth 500ms exponential ease-out transition for the text slide effect
                                }
                                Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo } } // Animate text color transitions over 300ms when selection state changes
                            }
                        }

                        MouseArea {                                                                          // MouseArea to detect clicks and hover on the entire delegate item
                            id: ma                                                                           // Assign id 'ma' for referencing this MouseArea (used for hover detection above)
                            anchors.fill: parent                                                             // Fill the entire delegate item to make the whole row clickable
                            hoverEnabled: true                                                               // Enable hover detection so we can show the hover highlight effect
                            onClicked: {                                                                     // Handler for mouse click events on this delegate
                                appList.currentIndex = index;                                                // Set the ListView's current index to this item's index (selects it)
                                launchApp(model.exec);                                                       // Launch the application immediately using the 'exec' property from the model
                            }
                        }
                    }
                }
            }
        }
    }
}