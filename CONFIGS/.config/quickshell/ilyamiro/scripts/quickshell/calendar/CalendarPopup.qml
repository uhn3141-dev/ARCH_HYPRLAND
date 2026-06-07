// import QtQuick
// import QtQuick.Layouts
// import QtQuick.Controls
// import QtCore
// import Quickshell
// import Quickshell.Io
// import QtQuick.Window
// import "../"

// Item {
//     id: window

//     // --- Responsive Scaling Logic ---
//     Scaler {
//         id: scaler
//         // Pass both width and height so the internal popup scale perfectly synchronizes
//         // with the master window's WindowRegistry.js calculations
//         currentWidth: Screen.width
//         currentHeight: Screen.height
//     }
    
//     // Expose reactive scale factor for all bindings
//     readonly property real sf: scaler.baseScale

//     // Keep helper function for backwards compatibility in pure JS blocks
//     function s(val) { 
//         return Math.round(val * window.sf); 
//     }

//     // -------------------------------------------------------------------------
//     // DYNAMIC MASTER WINDOW SCALING (Fixes Window Clipping)
//     // -------------------------------------------------------------------------
//     property real targetMasterHeight: window.scheduleModuleExists ? Math.round(750 * window.sf) : Math.round(510 * window.sf)
//     property real targetMasterWidth: Math.round(1450 * window.sf)
    
//     onTargetMasterHeightChanged: {
//         if (typeof masterWindow !== "undefined") {
//             masterWindow.animH = window.targetMasterHeight;
//             masterWindow.targetH = window.targetMasterHeight;
//         }
//     }

//     onTargetMasterWidthChanged: {
//         if (typeof masterWindow !== "undefined") {
//             masterWindow.animW = window.targetMasterWidth;
//             masterWindow.targetW = window.targetMasterWidth;
            
//             // Re-center horizontally to keep the popup perfectly in the middle when scaling changes
//             let newX = Math.floor((Screen.width / 2) - (window.targetMasterWidth / 2));
//             masterWindow.targetX = newX;
//             masterWindow.animX = newX;
//         }
//     }

//     // -------------------------------------------------------------------------
//     // KEYBOARD SHORTCUTS
//     // (Escape is handled by Main.qml now)
//     // -------------------------------------------------------------------------
//     Shortcut { 
//         sequence: "Left"
//         onActivated: {
//             if (calHover.hovered) {
//                 window.setMonthOffset(window.targetMonthOffset - 1);
//             } else {
//                 window.setWeatherView(window.targetWeatherView - 1);
//             }
//         }
//     }

//     Shortcut { 
//         sequence: "Right"
//         onActivated: {
//             if (calHover.hovered) {
//                 window.setMonthOffset(window.targetMonthOffset + 1);
//             } else {
//                 window.setWeatherView(window.targetWeatherView + 1);
//             }
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
//     readonly property color subtext1: _theme.subtext1
//     readonly property color subtext0: _theme.subtext0
//     readonly property color overlay2: _theme.overlay2
//     readonly property color overlay1: _theme.overlay1
//     readonly property color overlay0: _theme.overlay0
//     readonly property color surface2: _theme.surface2
//     readonly property color surface1: _theme.surface1
//     readonly property color surface0: _theme.surface0
    
//     readonly property color mauve: _theme.mauve
//     readonly property color pink: _theme.pink
//     readonly property color blue: _theme.blue
//     readonly property color sapphire: _theme.sapphire
//     readonly property color peach: _theme.peach
//     readonly property color yellow: _theme.yellow
//     readonly property color teal: _theme.teal
//     readonly property color green: _theme.green
//     readonly property color red: _theme.red

//     readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/calendar"

//     // -------------------------------------------------------------------------
//     // TIME OF DAY DYNAMIC COLORS
//     // -------------------------------------------------------------------------
//     readonly property color timeColor: {
//         let h = window.currentTime.getHours();
//         if (h >= 5 && h < 12) return window.peach;      // Morning
//         if (h >= 12 && h < 17) return window.sapphire;  // Afternoon
//         if (h >= 17 && h < 21) return window.mauve;     // Evening
//         return window.blue;                             // Night
//     }

//     readonly property color timeAccent: {
//         let h = window.currentTime.getHours();
//         if (h >= 5 && h < 12) return window.yellow;     // Morning Accent
//         if (h >= 12 && h < 17) return window.teal;      // Afternoon Accent
//         if (h >= 17 && h < 21) return window.pink;      // Evening Accent
//         return window.mauve;                            // Night Accent
//     }

//     readonly property color textAccent: Qt.tint(window.timeAccent, Qt.alpha(window.text, 0.35))

//     // -------------------------------------------------------------------------
//     // STARTUP ANIMATION STATES
//     // -------------------------------------------------------------------------
//     property bool startupComplete: false
//     property real introMain: 0
//     property real introAmbient: 0
//     property real introClock: 0
//     property real introCalendar: 0
//     property real introWeather: 0
//     property real introSchedule: 0

//     SequentialAnimation {
//         running: true
        
//         // 50ms buffer to allow the window manager to map the surface before animating
//         PauseAnimation { duration: 20 }

//         ParallelAnimation {
//             // Base window fades and scales slightly
//             NumberAnimation { target: window; property: "introMain"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutQuart }

//             // Ambient background glows and big parallax icon fade in
//             SequentialAnimation {
//                 PauseAnimation { duration: 150 }
//                 NumberAnimation { target: window; property: "introAmbient"; from: 0; to: 1.0; duration: 1000; easing.type: Easing.OutSine }
//             }

//             // Central clock and 3D orbital pop from the center
//             SequentialAnimation {
//                 PauseAnimation { duration: 250 }
//                 NumberAnimation { target: window; property: "introClock"; from: 0; to: 1.0; duration: 900; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
//             }

//             // Left wing (Calendar) slides in from the left
//             SequentialAnimation {
//                 PauseAnimation { duration: 350 }
//                 NumberAnimation { target: window; property: "introCalendar"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuint }
//             }

//             // Right wing (Weather) slides in from the right
//             SequentialAnimation {
//                 PauseAnimation { duration: 400 }
//                 NumberAnimation { target: window; property: "introWeather"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuint }
//             }

//             // Bottom section (Schedule) flows up smoothly
//             SequentialAnimation {
//                 PauseAnimation { duration: 500 }
//                 NumberAnimation { target: window; property: "introSchedule"; from: 0; to: 1.0; duration: 900; easing.type: Easing.OutExpo }
//             }
//         }
//         ScriptAction { script: window.startupComplete = true }
//     }

//     ParallelAnimation {
//         id: exitAnim
//         NumberAnimation { target: window; property: "introMain"; to: 0; duration: 400; easing.type: Easing.InQuart }
//         NumberAnimation { target: window; property: "introAmbient"; to: 0; duration: 250; easing.type: Easing.InQuart }
//         NumberAnimation { target: window; property: "introClock"; to: 0; duration: 300; easing.type: Easing.InQuart }
//         NumberAnimation { target: window; property: "introCalendar"; to: 0; duration: 350; easing.type: Easing.InQuart }
//         NumberAnimation { target: window; property: "introWeather"; to: 0; duration: 350; easing.type: Easing.InQuart }
//         NumberAnimation { target: window; property: "introSchedule"; to: 0; duration: 200; easing.type: Easing.InQuart }
//     }

//     property real globalOrbitAngle: 0
//     NumberAnimation on globalOrbitAngle {
//         from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
//     }

//     // -------------------------------------------------------------------------
//     // STATE & TIME (WITH SECOND PULSE)
//     // -------------------------------------------------------------------------
//     property var currentTime: new Date()
//     property real currentEpoch: currentTime.getTime() / 1000
    
//     property real secondPulse: 1.0
//     NumberAnimation on secondPulse { 
//         id: pulseReset 
//         to: 1.0; duration: 600; easing.type: Easing.OutQuint; running: false 
//     }

//     Timer {
//         interval: 1000; running: true; repeat: true
//         onTriggered: {
//             window.currentTime = new Date();
//             window.secondPulse = 1.06; // Gentle pulse
//             pulseReset.start();        
            
//             if (window.currentTime.getHours() === 0 && window.currentTime.getMinutes() === 0 && window.currentTime.getSeconds() === 0) {
//                 updateCalendarGrid();
//             }
//         }
//     }

//     // -------------------------------------------------------------------------
//     // WEATHER DATA & ELEGANT TRANSITIONS (3D ORBIT SPIN)
//     // -------------------------------------------------------------------------
//     property var weatherData: null
//     property int weatherView: 0
//     property color activeWeatherHex: weatherData && weatherData.forecast && weatherData.forecast[weatherView] ? weatherData.forecast[weatherView].hex : window.mauve

//     // Transition Properties
//     property int targetWeatherView: 0
//     property real weatherContentOpacity: 1.0
//     property real weatherContentOffset: 0.0
//     property int weatherAnimDirection: 1
    
//     // New 3D Spin Properties
//     property real transitionSpin: 0.0
//     property real transitionScale: 1.0

//     // -------------------------------------------------------------------------
//     // TEMPERATURE LOGIC 
//     // -------------------------------------------------------------------------
//     property real targetTemp: window.weatherData && window.weatherData.forecast[window.targetWeatherView] ? Number(window.weatherData.forecast[window.targetWeatherView].max) : 0
//     property real displayedTemp: targetTemp

//     Behavior on displayedTemp {
//         NumberAnimation {
//             id: tempAnim
//             duration: 800
//             easing.type: Easing.OutQuart
//         }
//     }

//     property bool isTempAnimating: tempAnim.running
//     property color tempGlowColor: {
//         if (!isTempAnimating || !window.startupComplete) return window.text;
        
//         // If the target is higher than the currently ticking number, we are counting up
//         if (window.targetTemp > window.displayedTemp) return window.red;
        
//         // If the target is lower than the currently ticking number, we are counting down
//         if (window.targetTemp < window.displayedTemp) return window.blue;
        
//         return window.text; 
//     }

//     SequentialAnimation {
//         id: weatherTransitionAnim
//         ParallelAnimation {
//             NumberAnimation { target: window; property: "weatherContentOpacity"; to: 0.0; duration: 250; easing.type: Easing.InSine }
//             NumberAnimation { target: window; property: "weatherContentOffset"; to: Math.round(-40 * window.sf) * weatherAnimDirection; duration: 250; easing.type: Easing.InSine }
            
//             // Spin the 3D orbit out and scale it down for depth
//             NumberAnimation { target: window; property: "transitionSpin"; to: 180 * weatherAnimDirection; duration: 300; easing.type: Easing.InBack }
//             NumberAnimation { target: window; property: "transitionScale"; to: 0.8; duration: 300; easing.type: Easing.InCubic }
//         }
//         ScriptAction { 
//             script: { 
//                 window.weatherView = window.targetWeatherView; 
//                 window.weatherContentOffset = Math.round(40 * window.sf) * weatherAnimDirection; // Move to opposite side while hidden
                
//                 // Reset the spin to the opposite side so it continues spinning into place seamlessly
//                 window.transitionSpin = -180 * weatherAnimDirection;
//             } 
//         }
//         ParallelAnimation {
//             NumberAnimation { target: window; property: "weatherContentOpacity"; to: 1.0; duration: 450; easing.type: Easing.OutQuart }
//             NumberAnimation { target: window; property: "weatherContentOffset"; to: 0.0; duration: 450; easing.type: Easing.OutQuart }
            
//             // Snap the 3D orbit back to 0 degrees and restore full scale
//             NumberAnimation { target: window; property: "transitionSpin"; to: 0.0; duration: 600; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
//             NumberAnimation { target: window; property: "transitionScale"; to: 1.0; duration: 500; easing.type: Easing.OutBack }
//         }
//     }

//     function setWeatherView(idx) {
//         if (idx < 0 || idx > 4 || !window.weatherData) return;
//         if (idx === window.targetWeatherView) return; // Ignore if we are already heading there

//         // If an animation is already running, gracefully interrupt it and apply the logical switch
//         // before starting the new animation so the data doesn't get desynced.
//         if (weatherTransitionAnim.running) {
//             weatherTransitionAnim.stop();
//             window.weatherView = window.targetWeatherView;
//         }

//         window.weatherAnimDirection = idx > window.weatherView ? 1 : -1;
//         window.targetWeatherView = idx;
//         weatherTransitionAnim.start();
//     }

//     property int activeHourIndex: {
//         if (window.weatherView !== 0 || !window.weatherData || !window.weatherData.forecast || !window.weatherData.forecast[0] || !window.weatherData.forecast[0].hourly) return -1;
        
//         let ch = window.currentTime.getHours();
//         let hrArr = window.weatherData.forecast[0].hourly.slice(0, 8);
//         let bestIdx = -1;
//         let minDiff = 999;
        
//         for (let i = 0; i < hrArr.length; i++) {
//             let timeStr = hrArr[i].time || "00:00";
//             let h = parseInt(timeStr.split(":")[0]);
//             let diff = Math.abs(h - ch);
//             if (diff < minDiff) {
//                 minDiff = diff;
//                 bestIdx = i;
//             }
//         }
//         return bestIdx !== -1 ? bestIdx : 0;
//     }

//     Process {
//         id: weatherPoller
//         command: ["bash", window.scriptsDir + "/weather.sh", "--json"]
//         running: true
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 let txt = this.text.trim();
//                 if (txt !== "") {
//                     try { window.weatherData = JSON.parse(txt); } catch(e) {}
//                 }
//             }
//         }
//     }

//     Timer {
//         interval: 150000 
//         running: true; repeat: true
//         onTriggered: weatherPoller.running = true
//     }

//     // -------------------------------------------------------------------------
//     // SCHEDULE DATA & CONDITIONAL RENDERING
//     // -------------------------------------------------------------------------
//     property bool scheduleModuleExists: false
//     property var scheduleData: { "header": "Loading Schedule...", "link": "", "lessons": [] }

//     // Dynamic offset based on whether the schedule module exists
//     property real centerOffset: window.scheduleModuleExists ? Math.round(-100 * window.sf) : 0
//     Behavior on centerOffset { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }

//     // Check if the schedule manager script actually exists before doing anything
//     Process {
//         id: schedulePathChecker
//         command: ["bash", "-c", "[ -f '" + window.scriptsDir + "/schedule/schedule_manager.sh' ] && echo 1 || echo 0"]
//         running: true
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 if (this.text.trim() === "1") {
//                     window.scheduleModuleExists = true;
//                     schedulePoller.running = true; // Safe to start polling
//                 } else {
//                     window.scheduleModuleExists = false;
//                     // Shrinking is now automatically handled by the onTargetMasterHeightChanged watcher
//                 }
//             }
//         }
//     }

//     Process {
//         id: schedulePoller
//         command: ["bash", window.scriptsDir + "/schedule/schedule_manager.sh"]
//         running: false // Handled by schedulePathChecker
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 let txt = this.text.trim();
//                 if (txt !== "") {
//                     try { window.scheduleData = JSON.parse(txt); } catch(e) { console.log("Schedule Parse Error:", e); }
//                 }
//             }
//         }
//     }

//     Timer {
//         interval: 600000 
//         // Only run the timer if the module actually exists
//         running: window.scheduleModuleExists; repeat: true
//         onTriggered: schedulePoller.running = true
//     }

//     // -------------------------------------------------------------------------
//     // CALENDAR GRID LOGIC & TRANSITIONS
//     // -------------------------------------------------------------------------
//     property int monthOffset: 0
//     property int targetMonthOffset: 0
//     property string targetMonthName: ""
//     ListModel { id: calendarModel }

//     property real calendarContentOpacity: 1.0
//     property real calendarContentOffset: 0.0
//     property int calendarAnimDirection: 1

//     SequentialAnimation {
//         id: calendarTransitionAnim
//         ParallelAnimation {
//             NumberAnimation { target: window; property: "calendarContentOpacity"; to: 0.0; duration: 200; easing.type: Easing.InSine }
//             NumberAnimation { target: window; property: "calendarContentOffset"; to: Math.round(-20 * window.sf) * calendarAnimDirection; duration: 200; easing.type: Easing.InSine }
//         }
//         ScriptAction {
//             script: {
//                 window.monthOffset = window.targetMonthOffset;
//                 window.calendarContentOffset = Math.round(20 * window.sf) * calendarAnimDirection;
//             }
//         }
//         ParallelAnimation {
//             NumberAnimation { target: window; property: "calendarContentOpacity"; to: 1.0; duration: 350; easing.type: Easing.OutQuart }
//             NumberAnimation { target: window; property: "calendarContentOffset"; to: 0.0; duration: 350; easing.type: Easing.OutQuart }
//         }
//     }

//     function setMonthOffset(newOffset) {
//         if (newOffset === window.targetMonthOffset) return;

//         if (calendarTransitionAnim.running) {
//             calendarTransitionAnim.stop();
//             window.monthOffset = window.targetMonthOffset;
//         }

//         window.calendarAnimDirection = newOffset > window.targetMonthOffset ? 1 : -1;
//         window.targetMonthOffset = newOffset;
//         calendarTransitionAnim.start();
//     }

//     function updateCalendarGrid() {
//         let d = new Date(window.currentTime.getTime());
//         d.setDate(1); 
//         d.setMonth(d.getMonth() + window.monthOffset);

//         let targetMonth = d.getMonth();
//         let targetYear = d.getFullYear();
        
//         let actualToday = new Date();
//         let isRealCurrentMonth = (actualToday.getMonth() === targetMonth && actualToday.getFullYear() === targetYear);
//         let todayDate = actualToday.getDate();

//         window.targetMonthName = Qt.formatDateTime(d, "MMMM yyyy");

//         let firstDay = new Date(targetYear, targetMonth, 1).getDay();
//         firstDay = (firstDay === 0) ? 6 : firstDay - 1; 

//         let daysInMonth = new Date(targetYear, targetMonth + 1, 0).getDate();
//         let daysInPrevMonth = new Date(targetYear, targetMonth, 0).getDate();

//         calendarModel.clear();

//         for (let i = firstDay - 1; i >= 0; i--) {
//             calendarModel.append({ dayNum: (daysInPrevMonth - i).toString(), isCurrentMonth: false, isToday: false });
//         }
//         for (let i = 1; i <= daysInMonth; i++) {
//             calendarModel.append({ dayNum: i.toString(), isCurrentMonth: true, isToday: (isRealCurrentMonth && i === todayDate) });
//         }
//         let remaining = 42 - calendarModel.count;
//         for (let i = 1; i <= remaining; i++) {
//             calendarModel.append({ dayNum: i.toString(), isCurrentMonth: false, isToday: false });
//         }
//     }

//     onMonthOffsetChanged: updateCalendarGrid()

//     Component.onCompleted: {
//         updateCalendarGrid();
//     }

//     // -------------------------------------------------------------------------
//     // UI LAYOUT
//     // -------------------------------------------------------------------------
//     Item {
//         anchors.fill: parent
//         scale: 0.95 + (0.05 * introMain)
//         opacity: introMain

//         Rectangle {
//             anchors.fill: parent
//             radius: Math.round(20 * window.sf)
//             color: window.base
//             border.color: window.surface0
//             border.width: 1
//             clip: true

//             // =======================================================
//             // AMBIENT WIDGET COLOR BLOBS (Spread Out)
//             // =======================================================
//             Rectangle {
//                 width: parent.width * 0.5; height: width; radius: width / 2
//                 x: (parent.width * 0.75 - width / 2) + Math.cos(window.globalOrbitAngle * 1.5) * Math.round(350 * window.sf)
//                 y: (parent.height * 0.3 - height / 2) + Math.sin(window.globalOrbitAngle * 1.5) * Math.round(200 * window.sf)
//                 opacity: 0.025 * window.introAmbient
//                 color: window.activeWeatherHex
//                 Behavior on color { ColorAnimation { duration: 1000 } }
//             }

//             Rectangle {
//                 width: parent.width * 0.6; height: width; radius: width / 2
//                 x: (parent.width * 0.25 - width / 2) + Math.sin(window.globalOrbitAngle * 1.2) * Math.round(-300 * window.sf)
//                 y: (parent.height * 0.7 - height / 2) + Math.cos(window.globalOrbitAngle * 1.2) * Math.round(-250 * window.sf)
//                 opacity: 0.02 * window.introAmbient
//                 color: window.timeColor
//                 Behavior on color { ColorAnimation { duration: 1000 } }
//             }

//             Rectangle {
//                 width: parent.width * 0.45; height: width; radius: width / 2
//                 x: (parent.width * 0.5 - width / 2) + Math.cos(window.globalOrbitAngle * -1.8) * Math.round(400 * window.sf)
//                 y: (parent.height * 0.5 - height / 2) + Math.sin(window.globalOrbitAngle * -1.8) * Math.round(-350 * window.sf)
//                 opacity: 0.015 * window.introAmbient
//                 color: window.timeAccent
//                 Behavior on color { ColorAnimation { duration: 1000 } }
//             }

//             // Big Parallax Weather Icon (Tied to Weather Transition)
//             Text {
//                 anchors.centerIn: parent
//                 anchors.verticalCenterOffset: window.centerOffset
//                 text: window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].icon : ""
//                 font.family: "Iosevka Nerd Font"
//                 font.pixelSize: Math.round(800 * window.sf)
//                 color: window.activeWeatherHex
//                 opacity: (0.03 + (0.01 * Math.sin(window.globalOrbitAngle * 4))) * window.introAmbient * window.weatherContentOpacity
//                 z: 0
//                 Behavior on color { ColorAnimation { duration: 1500 } }
                
//                 property real drift: 0
//                 SequentialAnimation on drift {
//                     loops: Animation.Infinite
//                     NumberAnimation { to: Math.round(-20 * window.sf); duration: 6000; easing.type: Easing.InOutSine }
//                     NumberAnimation { to: 0; duration: 6000; easing.type: Easing.InOutSine }
//                 }
                
//                 transform: [
//                     Translate { y: parent.drift },
//                     Translate { x: window.weatherContentOffset * 2 } // Exaggerated shift for background depth
//                 ]
//             }

//             // =======================================================
//             // CENTRAL HERO: THE BREATHING TIME HUB & 3D HOURLY ORBIT
//             // =======================================================
//             Item {
//                 id: centralHub
//                 anchors.centerIn: parent
//                 anchors.verticalCenterOffset: window.centerOffset
//                 width: Math.round(1 * window.sf); height: Math.round(1 * window.sf) 
//                 z: 5

//                 opacity: introClock
//                 scale: 0.85 + (0.15 * introClock)

//                 property real levitation: 0
//                 SequentialAnimation on levitation {
//                     loops: Animation.Infinite
//                     NumberAnimation { to: Math.round(-15 * window.sf); duration: 4000; easing.type: Easing.InOutSine }
//                     NumberAnimation { to: 0; duration: 4000; easing.type: Easing.InOutSine }
//                 }

//                 property real orbitBreath: 1.0
//                 SequentialAnimation on orbitBreath {
//                     loops: Animation.Infinite
//                     running: true
//                     NumberAnimation { to: 1.035; duration: 3500; easing.type: Easing.InOutSine }
//                     NumberAnimation { to: 1.0; duration: 3500; easing.type: Easing.InOutSine }
//                 }

//                 // 3D Perspective Wobble (Pitch, Yaw, Roll)
//                 property real pitchBreath: 0
//                 SequentialAnimation on pitchBreath {
//                     loops: Animation.Infinite; running: true
//                     NumberAnimation { to: 3.5; duration: 4200; easing.type: Easing.InOutSine }
//                     NumberAnimation { to: -3.5; duration: 4200; easing.type: Easing.InOutSine }
//                 }

//                 property real yawBreath: 0
//                 SequentialAnimation on yawBreath {
//                     loops: Animation.Infinite; running: true
//                     NumberAnimation { to: 2.5; duration: 5100; easing.type: Easing.InOutSine }
//                     NumberAnimation { to: -2.5; duration: 5100; easing.type: Easing.InOutSine }
//                 }

//                 property real rollBreath: 0
//                 SequentialAnimation on rollBreath {
//                     loops: Animation.Infinite; running: true
//                     NumberAnimation { to: 1.5; duration: 5800; easing.type: Easing.InOutSine }
//                     NumberAnimation { to: -1.5; duration: 5800; easing.type: Easing.InOutSine }
//                 }
                
//                 transform: [
//                     Translate { y: Math.round(25 * window.sf) * (1.0 - introClock) },
//                     Translate { y: centralHub.levitation },
//                     Rotation { axis { x: 1; y: 0; z: 0 } angle: centralHub.pitchBreath },
//                     Rotation { axis { x: 0; y: 1; z: 0 } angle: centralHub.yawBreath },
//                     Rotation { axis { x: 0; y: 0; z: 1 } angle: centralHub.rollBreath }
//                 ]

//                 // OPTIMIZATION: Moved scale property out of the onPaint function to prevent redrawing every frame.
//                 // It now draws once, and scales using the GPU.
//                 Canvas {
//                     id: orbitCanvas
//                     z: -10
//                     x: Math.round(-400 * window.sf)   // Widened to prevent clipping when scaled
//                     y: Math.round(-200 * window.sf)   // Heightened to prevent clipping when scaled
//                     width: Math.round(800 * window.sf)
//                     height: Math.round(400 * window.sf)
//                     opacity: 0.25

//                     scale: centralHub.orbitBreath

//                     onWidthChanged: requestPaint()

//                     onPaint: {
//                         var ctx = getContext("2d");
//                         ctx.clearRect(0, 0, width, height);
//                         ctx.beginPath();
//                         var currentRx = Math.round(320 * window.sf);
//                         var currentRy = Math.round(140 * window.sf);
//                         for (var i = 0; i <= Math.PI * 2; i += 0.05) {
//                             var xx = width/2 + Math.cos(i) * currentRx;
//                             var yy = height/2 + Math.sin(i) * currentRy;
//                             if (i === 0) ctx.moveTo(xx, yy); else ctx.lineTo(xx, yy);
//                         }
//                         ctx.strokeStyle = window.textAccent;
//                         ctx.lineWidth = Math.max(1, Math.round(1.5 * window.sf));
//                         ctx.setLineDash([Math.round(4 * window.sf), Math.round(10 * window.sf)]);
//                         ctx.stroke();
//                     }
//                     Behavior on opacity { NumberAnimation { duration: 1500 } }
//                 }

//                 // Core Clock
//                 ColumnLayout {
//                     anchors.centerIn: parent
//                     spacing: 0
//                     z: 0 
//                     scale: 0.95 + (0.05 * window.secondPulse) 
                    
//                     RowLayout {
//                         Layout.alignment: Qt.AlignHCenter
//                         spacing: Math.round(2 * window.sf)
//                         Text {
//                             text: Qt.formatTime(window.currentTime, "HH:mm")
//                             font.family: "JetBrains Mono"
//                             font.weight: Font.Black
//                             font.pixelSize: Math.round(84 * window.sf)
//                             color: window.text
//                             style: Text.Outline; styleColor: Qt.alpha(window.crust, 0.4)
//                         }
//                         Text {
//                             text: Qt.formatTime(window.currentTime, ":ss")
//                             font.family: "JetBrains Mono"
//                             font.weight: Font.Bold
//                             font.pixelSize: Math.round(32 * window.sf)
//                             color: window.textAccent
//                             Layout.alignment: Qt.AlignBottom
//                             Layout.bottomMargin: Math.round(15 * window.sf)
//                             opacity: window.secondPulse > 1.02 ? 1.0 : 0.6 
//                             style: Text.Outline; styleColor: Qt.alpha(window.crust, 0.4)
//                             Behavior on color { ColorAnimation { duration: 1000 } }
//                         }
//                     }

//                     Text {
//                         Layout.alignment: Qt.AlignHCenter
//                         text: Qt.formatDateTime(window.currentTime, "dddd, MMMM dd")
//                         font.family: "JetBrains Mono"
//                         font.weight: Font.Bold
//                         font.pixelSize: Math.round(16 * window.sf)
//                         color: window.subtext0
//                         opacity: 0.9
//                     }
//                 }

//                 // TRUE 3D ORBITAL HOURLY FORECAST (Tied to Spin Transition)
//                 Item {
//                     anchors.fill: parent
//                     opacity: window.weatherContentOpacity
                    
//                     // Added Scale property to give a z-depth shrink effect when spinning
//                     scale: window.transitionScale 
//                     transform: Translate { x: window.weatherContentOffset * 1.5 }

//                     Repeater {
//                         id: hourRepeater
//                         model: window.weatherData && window.weatherData.forecast[window.weatherView] && window.weatherData.forecast[window.weatherView].hourly ? window.weatherData.forecast[window.weatherView].hourly.slice(0, 8) : []
                        
//                         delegate: Item {
//                             property int mCount: hourRepeater.count
//                             property bool isToday: window.weatherView === 0
//                             property bool isHighlighted: isToday && index === window.activeHourIndex
                            
//                             property real rx: Math.round(320 * window.sf) * centralHub.orbitBreath
//                             property real ry: Math.round(140 * window.sf) * centralHub.orbitBreath
                            
//                             property int relIdx: isToday ? (index - window.activeHourIndex) : index
                            
//                             property real targetAngleDeg: isToday ? (65 + (relIdx * 30)) : (index * (360 / Math.max(1, mCount)))
                            
//                             property real orbitOffset: isToday ? 0 : (window.globalOrbitAngle * (180 / Math.PI) * -1.5)
//                             property real osc: isToday ? (Math.sin(window.globalOrbitAngle * 10 + index) * 5) : 0 
                            
//                             // Integrated window.transitionSpin directly into the final angle calculation
//                             property real rad: (targetAngleDeg + orbitOffset + osc + window.transitionSpin) * (Math.PI / 180)

//                             x: Math.cos(rad) * rx - width/2
//                             y: Math.sin(rad) * ry - height/2
//                             z: Math.sin(rad) * Math.round(100 * window.sf) 
                            
//                             scale: isHighlighted ? 1.4 : (isToday ? (0.95 + 0.20 * Math.sin(rad)) : (0.90 + 0.25 * Math.sin(rad)))
//                             opacity: isHighlighted ? 1.0 : (isToday ? (0.7 + 0.3 * ((Math.sin(rad) + 1) / 2)) : (0.65 + 0.35 * ((Math.sin(rad) + 1) / 2)))

//                             width: Math.round(56 * window.sf); height: Math.round(95 * window.sf)
                            
//                             Rectangle {
//                                 anchors.fill: parent
//                                 radius: Math.round(28 * window.sf)
//                                 color: isHighlighted ? window.textAccent : (hrMa.containsMouse ? window.surface2 : window.surface0)
//                                 border.color: isHighlighted ? "transparent" : (hrMa.containsMouse ? window.textAccent : window.surface1)
//                                 border.width: 1
                                
//                                 Behavior on color { ColorAnimation { duration: 200 } }
                                
//                                 ColumnLayout {
//                                     anchors.centerIn: parent 
//                                     spacing: Math.round(4 * window.sf)
                                    
//                                     Text { 
//                                         Layout.alignment: Qt.AlignHCenter
//                                         text: modelData.time
//                                         font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: Math.round(12 * window.sf)
//                                         color: isHighlighted ? window.base : (hrMa.containsMouse ? window.text : window.overlay1)
//                                     }
                                    
//                                     Text { 
//                                         Layout.alignment: Qt.AlignHCenter
//                                         text: modelData.icon || (window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].icon : "")
//                                         font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(18 * window.sf)
//                                         color: isHighlighted ? window.base : (modelData.hex || window.text)
                                        
//                                         transform: Translate { y: hrMa.containsMouse ? Math.round(-3 * window.sf) : 0 }
//                                         Behavior on transform { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
//                                     }
                                    
//                                     Text { 
//                                         Layout.alignment: Qt.AlignHCenter; text: modelData.temp + "°"
//                                         font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: Math.round(14 * window.sf)
//                                         color: isHighlighted ? window.base : window.text 
//                                     }
//                                 }
//                             }
//                             MouseArea { id: hrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
//                         }
//                     }
//                 }
//             }

//             // =======================================================
//             // LEFT WING: FLOATING GLASS CALENDAR
//             // =======================================================
//             Rectangle {
//                 id: calendarRect
//                 anchors.left: parent.left
//                 anchors.top: parent.top
//                 anchors.margins: Math.round(40 * window.sf)
//                 width: Math.round(320 * window.sf)
//                 height: Math.round(420 * window.sf)
//                 color: Qt.alpha(window.surface0, 0.2) 
//                 radius: Math.round(14 * window.sf)
//                 border.color: Qt.alpha(window.surface1, 0.4)
//                 border.width: 1
//                 z: 10 

//                 opacity: introCalendar
//                 transform: Translate { x: Math.round(-40 * window.sf) * (1.0 - introCalendar) }

//                 HoverHandler { id: calHover }

//                 ColumnLayout {
//                     anchors.fill: parent
//                     anchors.margins: Math.round(25 * window.sf)
//                     spacing: Math.round(15 * window.sf)

//                     RowLayout {
//                         Layout.fillWidth: true
                        
//                         // "Return to Today" Home Button
//                         Rectangle {
//                             Layout.preferredWidth: Math.round(32 * window.sf); Layout.preferredHeight: Math.round(32 * window.sf); radius: Math.round(16 * window.sf)
//                             color: homeMa.containsMouse ? window.surface1 : "transparent"
//                             opacity: window.targetMonthOffset !== 0 ? 1.0 : 0.0
//                             visible: opacity > 0
//                             Behavior on opacity { NumberAnimation { duration: 200 } }
//                             Text { anchors.centerIn: parent; text: "󰃭"; font.family: "Iosevka Nerd Font"; color: window.text; font.pixelSize: Math.round(16 * window.sf) }
//                             MouseArea { 
//                                 id: homeMa; anchors.fill: parent; hoverEnabled: window.targetMonthOffset !== 0; 
//                                 onClicked: if (window.targetMonthOffset !== 0) window.setMonthOffset(0) 
//                             }
//                         }

//                         Rectangle {
//                             Layout.preferredWidth: Math.round(32 * window.sf); Layout.preferredHeight: Math.round(32 * window.sf); radius: Math.round(16 * window.sf)
//                             color: prevMa.containsMouse ? window.surface1 : "transparent"
//                             Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; color: window.text; font.pixelSize: Math.round(16 * window.sf) }
//                             MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; onClicked: window.setMonthOffset(window.targetMonthOffset - 1) }
//                         }
                        
//                         Text {
//                             Layout.fillWidth: true
//                             text: window.targetMonthName.toUpperCase()
//                             font.family: "JetBrains Mono"
//                             font.weight: Font.Black
//                             font.pixelSize: Math.round(16 * window.sf)
//                             fontSizeMode: Text.Fit
//                             minimumPixelSize: Math.round(8 * window.sf)
//                             color: window.text
//                             horizontalAlignment: Text.AlignHCenter
                            
//                             opacity: window.calendarContentOpacity
//                             transform: Translate { x: window.calendarContentOffset }
//                         }

//                         Rectangle {
//                             Layout.preferredWidth: Math.round(32 * window.sf); Layout.preferredHeight: Math.round(32 * window.sf); radius: Math.round(16 * window.sf)
//                             color: nextMa.containsMouse ? window.surface1 : "transparent"
//                             Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; color: window.text; font.pixelSize: Math.round(16 * window.sf) }
//                             MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; onClicked: window.setMonthOffset(window.targetMonthOffset + 1) }
//                         }

//                         Rectangle {
//                             Layout.preferredWidth: Math.round(32 * window.sf); Layout.preferredHeight: Math.round(32 * window.sf); radius: Math.round(16 * window.sf)
//                             color: diaryMa.containsMouse ? window.surface1 : "transparent"
//                             Text { anchors.centerIn: parent; text: "+"; font.family: "Iosevka Nerd Font"; color: diaryMa.containsMouse ? window.mauve : window.text; font.pixelSize: Math.round(32 * window.sf) }
//                             MouseArea { 
//                                 id: diaryMa; anchors.fill: parent; hoverEnabled: true; 
//                                 onClicked: Quickshell.execDetached(["bash", window.scriptsDir + "/diary_manager.sh"]) 
//                             }
//                             Behavior on color { ColorAnimation { duration: 150 } }
//                         }
//                     }

//                     RowLayout {
//                         Layout.fillWidth: true
//                         Repeater {
//                             model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
//                             Text {
//                                 Layout.fillWidth: true
//                                 text: modelData
//                                 font.family: "JetBrains Mono"
//                                 font.weight: Font.Black
//                                 font.pixelSize: Math.round(14 * window.sf)
//                                 color: window.overlay0
//                                 horizontalAlignment: Text.AlignHCenter
//                             }
//                         }
//                     }

//                     GridLayout {
//                         Layout.fillWidth: true
//                         Layout.fillHeight: true
//                         columns: 7
//                         rowSpacing: Math.round(6 * window.sf)
//                         columnSpacing: Math.round(6 * window.sf)

//                         opacity: window.calendarContentOpacity
//                         transform: Translate { x: window.calendarContentOffset }

//                         Repeater {
//                             model: calendarModel
//                             Rectangle {
//                                 Layout.fillWidth: true
//                                 Layout.fillHeight: true
                                
//                                 color: isToday ? window.textAccent : (dayMa.containsMouse ? Qt.alpha(window.surface2, 0.4) : "transparent")
//                                 radius: Math.round(10 * window.sf)
//                                 scale: dayMa.containsMouse ? 1.2 : 1.0
//                                 border.color: isToday ? window.surface0 : (dayMa.containsMouse ? window.overlay0 : "transparent")
//                                 border.width: isToday || dayMa.containsMouse ? 1 : 0
                                
//                                 Behavior on color { ColorAnimation { duration: 150 } }
//                                 Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

//                                 Text {
//                                     anchors.centerIn: parent
//                                     text: dayNum
//                                     font.family: "JetBrains Mono"
//                                     font.weight: isToday ? Font.Black : Font.Bold
//                                     font.pixelSize: Math.round(14 * window.sf)
//                                     color: isToday ? window.base : (isCurrentMonth ? window.text : window.surface0)
//                                     Behavior on color { ColorAnimation { duration: 200 } }
//                                 }

//                                 MouseArea { id: dayMa; anchors.fill: parent; hoverEnabled: true }
//                             }
//                         }
//                     }
//                 }
//             }

//             // =======================================================
//             // RIGHT WING: ORGANIC FLOATING WEATHER STATS
//             // =======================================================
//             Item {
//                 anchors.right: parent.right
//                 anchors.top: parent.top
//                 anchors.margins: Math.round(40 * window.sf)
//                 width: Math.round(320 * window.sf)
//                 height: Math.round(420 * window.sf)
//                 z: 10 

//                 opacity: introWeather
//                 transform: Translate { x: Math.round(40 * window.sf) * (1.0 - introWeather) }

//                 ColumnLayout {
//                     anchors.fill: parent
//                     spacing: Math.round(20 * window.sf)

//                     RowLayout {
//                         Layout.fillWidth: true
//                         Layout.alignment: Qt.AlignRight | Qt.AlignTop
//                         spacing: Math.round(20 * window.sf)
                        
//                         MouseArea { 
//                             id: wPrevMa; Layout.preferredWidth: Math.round(30 * window.sf); Layout.preferredHeight: Math.round(30 * window.sf); hoverEnabled: true
//                             onClicked: window.setWeatherView(window.targetWeatherView - 1) 
                            
//                             property real pulseOffset: 0
//                             SequentialAnimation on pulseOffset {
//                                 loops: Animation.Infinite; running: true
//                                 NumberAnimation { to: Math.round(-3 * window.sf); duration: 1000; easing.type: Easing.InOutSine }
//                                 NumberAnimation { to: 0; duration: 1000; easing.type: Easing.InOutSine }
//                             }
                            
//                             Text { 
//                                 anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(18 * window.sf)
//                                 color: parent.containsMouse ? window.textAccent : window.overlay1
//                                 transform: Translate { x: parent.containsMouse ? Math.round(-5 * window.sf) : wPrevMa.pulseOffset }
//                                 Behavior on transform { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
//                             }
//                         }
                        
//                         Text {
//                             Layout.fillWidth: true 
//                             horizontalAlignment: Text.AlignHCenter 
//                             text: window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].day_full.toUpperCase() : "LOADING..."
//                             font.family: "JetBrains Mono"
//                             font.weight: Font.Black
//                             font.pixelSize: Math.round(16 * window.sf)
//                             fontSizeMode: Text.Fit
//                             minimumPixelSize: Math.round(8 * window.sf)
//                             color: window.text
//                         }
                        
//                         MouseArea { 
//                             id: wNextMa; Layout.preferredWidth: Math.round(30 * window.sf); Layout.preferredHeight: Math.round(30 * window.sf); hoverEnabled: true
//                             onClicked: window.setWeatherView(window.targetWeatherView + 1)
                            
//                             property real pulseOffset: 0
//                             SequentialAnimation on pulseOffset {
//                                 loops: Animation.Infinite; running: true
//                                 NumberAnimation { to: Math.round(3 * window.sf); duration: 1000; easing.type: Easing.InOutSine }
//                                 NumberAnimation { to: 0; duration: 1000; easing.type: Easing.InOutSine }
//                             }
                            
//                             Text { 
//                                 anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(18 * window.sf)
//                                 color: parent.containsMouse ? window.textAccent : window.overlay1
//                                 transform: Translate { x: parent.containsMouse ? Math.round(5 * window.sf) : wNextMa.pulseOffset }
//                                 Behavior on transform { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
//                             }
//                         }
//                     }

//                     ColumnLayout {
//                         Layout.alignment: Qt.AlignRight 
//                         spacing: Math.round(-5 * window.sf)
                        
//                         // BIG TEMPERATURE TEXT - Anchored so it doesn't slide with the wrapper
//                         Text {
//                             Layout.alignment: Qt.AlignRight 
//                             text: Math.round(window.displayedTemp) + "°"
//                             font.family: "JetBrains Mono"
//                             font.weight: Font.Black
//                             font.pixelSize: Math.round(84 * window.sf)
//                             color: window.tempGlowColor
//                             style: Text.Outline; 
//                             styleColor: window.isTempAnimating ? Qt.alpha(window.tempGlowColor, 0.5) : Qt.alpha(window.crust, 0.4)
                            
//                             Behavior on color { ColorAnimation { duration: 300 } }
//                             Behavior on styleColor { ColorAnimation { duration: 300 } }
//                         }
                        
//                         Text {
//                             Layout.alignment: Qt.AlignRight
//                             Layout.maximumWidth: Math.round(320 * window.sf)
//                             horizontalAlignment: Text.AlignRight
//                             text: window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].desc : ""
//                             font.family: "JetBrains Mono"
//                             font.weight: Font.Bold
//                             font.pixelSize: Math.round(16 * window.sf)
//                             wrapMode: Text.WordWrap
//                             color: window.textAccent
//                             Behavior on color { ColorAnimation { duration: 1000 } }
                            
//                             opacity: window.weatherContentOpacity
//                             transform: Translate { x: window.weatherContentOffset }
//                         }
//                     }

//                     Item { Layout.fillHeight: true } 

//                     // FIX: Replaced explicit widths and manual vertical anchors with flexible ColumnLayout containers
//                     RowLayout {
//                         Layout.fillWidth: true
//                         Layout.alignment: Qt.AlignHCenter 
//                         spacing: Math.round(8 * window.sf)

//                         Repeater {
//                             model: 4

//                             Item {
//                                 id: gaugeWrapper
//                                 Layout.fillWidth: true
//                                 Layout.preferredHeight: Math.round(100 * window.sf) // Give wrapper bounds that can expand safely
                                
//                                 scale: gaugeMa.containsMouse ? 1.15 : 1.0
//                                 Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

//                                 property var forecast: window.weatherData && window.weatherData.forecast[window.targetWeatherView] ? window.weatherData.forecast[window.targetWeatherView] : null

//                                 property string gaugeIcon: index === 0 ? "" : index === 1 ? "" : index === 2 ? "" : ""
//                                 property string gaugeLbl: index === 0 ? "WIND" : index === 1 ? "HUMID" : index === 2 ? "RAIN" : "FEELS"

//                                 property string gaugeVal: forecast ? (
//                                     index === 0 ? forecast.wind + "m/s" :
//                                     index === 1 ? forecast.humidity + "%" :
//                                     index === 2 ? forecast.pop + "%" :
//                                     forecast.feels_like + "°"
//                                 ) : ""

//                                 property real gaugeFill: forecast ? (
//                                     index === 0 ? Math.min(1.0, forecast.wind / 25.0) :
//                                     index === 1 ? forecast.humidity / 100.0 :
//                                     index === 2 ? forecast.pop / 100.0 :
//                                     Math.max(0.0, Math.min(1.0, (forecast.feels_like + 15) / 55.0))
//                                 ) : 0.0
                                
//                                 // FIX: Use ColumnLayout to enforce perfect relative positioning instead of absolute anchors
//                                 ColumnLayout {
//                                     anchors.centerIn: parent
//                                     spacing: Math.round(6 * window.sf)
                                    
//                                     Item {
//                                         Layout.alignment: Qt.AlignHCenter
//                                         Layout.preferredWidth: Math.round(60 * window.sf)
//                                         Layout.preferredHeight: Math.round(60 * window.sf)
                                        
//                                         Rectangle {
//                                             anchors.fill: parent
//                                             radius: width / 2
//                                             color: window.textAccent
//                                             opacity: gaugeMa.containsMouse ? 0.3 : 0.0
//                                             Behavior on opacity { NumberAnimation { duration: 200 } }
//                                         }

//                                         Canvas {
//                                             id: gaugeCanvas
//                                             anchors.fill: parent
//                                             rotation: -90 
                                            
//                                             property real animProgress: gaugeWrapper.gaugeFill
                                            
//                                             Behavior on animProgress {
//                                                 NumberAnimation { duration: 1000; easing.type: Easing.OutExpo }
//                                             }
                                            
//                                             onAnimProgressChanged: requestPaint()
//                                             onWidthChanged: requestPaint()
//                                             Component.onCompleted: requestPaint()
                                            
//                                             onPaint: {
//                                                 var ctx = getContext("2d");
//                                                 ctx.clearRect(0, 0, width, height);
//                                                 var r = width / 2;
                                                
//                                                 ctx.beginPath();
//                                                 ctx.arc(r, r, r - Math.round(4 * window.sf), 0, 2 * Math.PI);
//                                                 ctx.strokeStyle = Qt.alpha(window.text, 0.1);
//                                                 ctx.lineWidth = Math.round(3 * window.sf);
//                                                 ctx.stroke();
                                                
//                                                 if (animProgress > 0) {
//                                                     ctx.beginPath();
//                                                     ctx.arc(r, r, r - Math.round(4 * window.sf), 0, animProgress * 2 * Math.PI);
//                                                     var grad = ctx.createLinearGradient(0, 0, width, height);
//                                                     grad.addColorStop(0, window.timeAccent);
//                                                     grad.addColorStop(1, window.sapphire);
//                                                     ctx.strokeStyle = grad;
//                                                     ctx.lineWidth = Math.round(4 * window.sf);
//                                                     ctx.lineCap = "round";
//                                                     ctx.stroke();
//                                                 }
//                                             }
//                                         }
                                        
//                                         Text {
//                                             anchors.centerIn: parent
//                                             text: gaugeWrapper.gaugeVal
//                                             font.family: "JetBrains Mono"
//                                             font.weight: Font.Black
//                                             font.pixelSize: Math.round(12 * window.sf) // Slightly reduced to guarantee fit inside circle
//                                             color: window.text
//                                         }
//                                     }
                                    
//                                     RowLayout {
//                                         Layout.alignment: Qt.AlignHCenter
//                                         Layout.fillWidth: true
//                                         spacing: Math.round(4 * window.sf)
                                        
//                                         Text { 
//                                             text: gaugeWrapper.gaugeIcon
//                                             font.family: "Iosevka Nerd Font"
//                                             font.pixelSize: Math.round(12 * window.sf)
//                                             color: gaugeMa.containsMouse ? window.textAccent : window.overlay0
//                                             Behavior on color { ColorAnimation { duration: 200 } }
//                                         }
//                                         Text { 
//                                             text: gaugeWrapper.gaugeLbl
//                                             Layout.fillWidth: true
//                                             font.family: "JetBrains Mono"
//                                             font.weight: Font.Bold
//                                             font.pixelSize: Math.round(11 * window.sf)
//                                             fontSizeMode: Text.Fit
//                                             minimumPixelSize: Math.round(6 * window.sf)
//                                             color: window.overlay0 
//                                         }
//                                     }
//                                 }
                                
//                                 MouseArea { id: gaugeMa; anchors.fill: parent; hoverEnabled: true }
//                             }
//                         }
//                     }
//                 }
//             }

//             // =======================================================
//             // BOTTOM SECTION: FRAMELESS FLUID DATA STREAM (SCHEDULE)
//             // =======================================================
//             Item {
//                 id: bottomSection
                
//                 // CONDITIONAL RENDERING BINDING
//                 visible: window.scheduleModuleExists
                
//                 anchors.left: parent.left
//                 anchors.right: parent.right
//                 anchors.bottom: parent.bottom
//                 height: Math.round(240 * window.sf)
//                 z: 20 

//                 opacity: introSchedule
//                 transform: Translate { y: Math.round(50 * window.sf) * (1.0 - introSchedule) }

//                 Rectangle {
//                     anchors.fill: parent
//                     gradient: Gradient {
//                         GradientStop { position: 0.0; color: "transparent" }
//                         GradientStop { position: 1.0; color: Qt.alpha(window.crust, 0.6) }
//                     }
//                 }

//                 Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: Qt.alpha(window.surface1, 0.5) }

//                 // OPTIMIZATION: Separated the massive continuous Canvas path-drawing loop into three pre-rendered hardware-accelerated static layers.
//                 Item {
//                     anchors.fill: parent
//                     z: -1
//                     opacity: 0.15
//                     clip: true

//                     // Wave 1 - Mauve
//                     Canvas {
//                         id: wave1
//                         property real wLen: Math.round(100 * window.sf) * 2 * Math.PI
//                         width: parent.width + wLen
//                         height: parent.height
                        
//                         NumberAnimation on x { from: 0; to: -wave1.wLen; duration: 4000; loops: Animation.Infinite; running: window.scheduleModuleExists }
                        
//                         onWidthChanged: requestPaint()
//                         onPaint: {
//                             var ctx = getContext("2d");
//                             ctx.clearRect(0, 0, width, height);
//                             var cy = height / 2;
//                             ctx.beginPath();
//                             ctx.moveTo(0, cy);
//                             for(var i = 0; i <= width + Math.round(20 * window.sf); i += Math.round(10 * window.sf)) {
//                                 ctx.lineTo(i, cy + Math.sin(i/Math.round(100 * window.sf)) * Math.round(30 * window.sf));
//                             }
//                             ctx.strokeStyle = window.mauve;
//                             ctx.lineWidth = Math.round(2 * window.sf);
//                             ctx.stroke();
//                         }
//                     }

//                     // Wave 2 - Sapphire
//                     Canvas {
//                         id: wave2
//                         property real wLen: Math.round(120 * window.sf) * 2 * Math.PI
//                         width: parent.width + wLen
//                         height: parent.height
                        
//                         NumberAnimation on x { from: -wave2.wLen; to: 0; duration: 5500; loops: Animation.Infinite; running: window.scheduleModuleExists }
                        
//                         onWidthChanged: requestPaint()
//                         onPaint: {
//                             var ctx = getContext("2d");
//                             ctx.clearRect(0, 0, width, height);
//                             var cy = height / 2;
//                             ctx.beginPath();
//                             ctx.moveTo(0, cy);
//                             for(var i = 0; i <= width + Math.round(20 * window.sf); i += Math.round(10 * window.sf)) {
//                                 ctx.lineTo(i, cy + Math.sin(i/Math.round(120 * window.sf)) * Math.round(40 * window.sf));
//                             }
//                             ctx.strokeStyle = window.sapphire;
//                             ctx.lineWidth = Math.round(2 * window.sf);
//                             ctx.stroke();
//                         }
//                     }

//                     // Wave 3 - Peach
//                     Canvas {
//                         id: wave3
//                         property real wLen: Math.round(80 * window.sf) * 2 * Math.PI
//                         width: parent.width + wLen
//                         height: parent.height
                        
//                         NumberAnimation on x { from: 0; to: -wave3.wLen; duration: 7000; loops: Animation.Infinite; running: window.scheduleModuleExists }
                        
//                         onWidthChanged: requestPaint()
//                         onPaint: {
//                             var ctx = getContext("2d");
//                             ctx.clearRect(0, 0, width, height);
//                             var cy = height / 2;
//                             ctx.beginPath();
//                             ctx.moveTo(0, cy);
//                             for(var i = 0; i <= width + Math.round(20 * window.sf); i += Math.round(10 * window.sf)) {
//                                 ctx.lineTo(i, cy + Math.sin(i/Math.round(80 * window.sf)) * Math.round(20 * window.sf));
//                             }
//                             ctx.strokeStyle = window.peach;
//                             ctx.lineWidth = Math.round(2 * window.sf);
//                             ctx.stroke();
//                         }
//                     }
//                 }

//                 ColumnLayout {
//                     anchors.fill: parent
//                     anchors.margins: Math.round(25 * window.sf)
//                     spacing: Math.round(15 * window.sf)

//                     RowLayout {
//                         Layout.fillWidth: true
//                         spacing: Math.round(15 * window.sf)
                        
//                         Rectangle {
//                             Layout.preferredWidth: Math.round(40 * window.sf); Layout.preferredHeight: Math.round(40 * window.sf); radius: Math.round(20 * window.sf); color: window.surface0
//                             Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(18 * window.sf); color: window.textAccent }
//                         }
                        
//                         Text { 
//                             Layout.fillWidth: true // FIX: Ensures text shrinks/elides instead of expanding layout infinitely
//                             text: window.scheduleData ? window.scheduleData.header : "Loading Schedule..."
//                             font.family: "JetBrains Mono"
//                             font.weight: Font.Bold
//                             font.pixelSize: Math.round(16 * window.sf)
//                             color: window.overlay0
//                             elide: Text.ElideRight
//                         }
                        
//                         Item { Layout.fillWidth: true }
                        
//                         Rectangle {
//                             Layout.preferredWidth: Math.round(120 * window.sf); Layout.preferredHeight: Math.round(36 * window.sf); radius: Math.round(10 * window.sf)
//                             color: schLinkMa.containsMouse ? window.mauve : Qt.alpha(window.surface1, 0.5)
//                             border.color: window.mauve; border.width: 1
//                             Behavior on color { ColorAnimation { duration: 150 } }
                            
//                             RowLayout {
//                                 anchors.centerIn: parent
//                                 spacing: Math.round(6 * window.sf)
//                                 Text { text: "Open Web"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: Math.round(14 * window.sf); color: schLinkMa.containsMouse ? window.base : window.text }
//                                 Text { text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(14 * window.sf); color: schLinkMa.containsMouse ? window.base : window.text }
//                             }
                            
//                             MouseArea {
//                                 id: schLinkMa; anchors.fill: parent; hoverEnabled: true
//                                 onClicked: if(window.scheduleData && window.scheduleData.link) Quickshell.execDetached(["xdg-open", window.scheduleData.link])
//                             }
//                         }
//                     }

//                     Item {
//                         Layout.fillWidth: true
//                         Layout.fillHeight: true

//                         Text {
//                             text: "Data stream offline. No scheduled events."
//                             font.family: "JetBrains Mono"
//                             font.italic: true
//                             font.pixelSize: Math.round(14 * window.sf)
//                             color: window.overlay0
//                             visible: window.scheduleData && window.scheduleData.lessons.length === 0
//                             anchors.centerIn: parent
//                         }

//                         Rectangle {
//                             anchors.verticalCenter: parent.verticalCenter
//                             anchors.left: parent.left
//                             anchors.right: parent.right
//                             height: Math.round(2 * window.sf)
//                             color: Qt.alpha(window.surface1, 0.4)
//                             visible: window.scheduleData && window.scheduleData.lessons.length > 0
//                         }

//                         ScrollView {
//                             id: schedScroll
//                             anchors.fill: parent
//                             clip: true
//                             ScrollBar.vertical.policy: ScrollBar.AlwaysOff
//                             ScrollBar.horizontal.policy: ScrollBar.AsNeeded
//                             visible: window.scheduleData && window.scheduleData.lessons.length > 0
//                             contentWidth: scheduleRow.width
//                             contentHeight: parent.height

//                             Row {
//                                 id: scheduleRow
//                                 height: parent.height
//                                 spacing: 0
                                
//                                 // Divide the actual rendered width of the scroll area by the 430 minutes in a standard school day 
//                                 // to get the dynamic Pixels Per Minute ratio that stretches perfectly across the entire space.
//                                 property real ppm: schedScroll.width / 430.0

//                                 Repeater {
//                                     model: window.scheduleData ? window.scheduleData.lessons : []

//                                     delegate: Item {
//                                         property bool isClass: modelData.type === "class"
                                        
//                                         // Calculate the exact duration in minutes directly from the start and end epochs 
//                                         property real durationMinutes: ((modelData.end || 0) - (modelData.start || 0)) / 60.0
                                        
//                                         // Multiply duration by PPM and round to the nearest whole pixel to avoid sub-pixel gaps entirely
//                                         width: Math.max(1, Math.round(durationMinutes * scheduleRow.ppm))
//                                         height: parent.height
                                        
//                                         Item {
//                                             id: classNode
//                                             anchors.fill: parent
//                                             anchors.topMargin: Math.round(10 * window.sf)
//                                             anchors.bottomMargin: Math.round(10 * window.sf)
//                                             visible: parent.isClass
                                            
//                                             property bool isActive: parent.isClass && window.currentEpoch >= (modelData.start || 0) && window.currentEpoch <= (modelData.end || 0)
//                                             property bool isPast: parent.isClass && window.currentEpoch > (modelData.end || 0)
                                            
//                                             Canvas {
//                                                 anchors.fill: parent
//                                                 visible: classMa.containsMouse || classNode.isActive
//                                                 opacity: classMa.containsMouse ? 0.2 : 0.08
//                                                 Behavior on opacity { NumberAnimation { duration: 200 } }
                                                
//                                                 property real wavePhase: 0
//                                                 NumberAnimation on wavePhase {
//                                                     from: 0; to: Math.PI * 2; duration: 2000; loops: Animation.Infinite; running: parent.visible
//                                                 }
//                                                 onWavePhaseChanged: requestPaint()
//                                                 onPaint: {
//                                                     var ctx = getContext("2d");
//                                                     ctx.clearRect(0, 0, width, height);
//                                                     ctx.beginPath();
//                                                     ctx.moveTo(0, height);
//                                                     for(var x = 0; x <= width; x += Math.round(10 * window.sf)) {
//                                                         ctx.lineTo(x, height/2 + Math.sin(x/Math.round(25 * window.sf) + wavePhase) * Math.round(20 * window.sf));
//                                                     }
//                                                     ctx.lineTo(width, height);
//                                                     ctx.lineTo(0, height);
//                                                     var grad = ctx.createLinearGradient(0, 0, width, 0);
//                                                     grad.addColorStop(0, window.mauve);
//                                                     grad.addColorStop(1, "transparent");
//                                                     ctx.fillStyle = grad;
//                                                     ctx.fill();
//                                                 }
//                                             }

//                                             Rectangle {
//                                                 id: accentLine
//                                                 width: classNode.isActive || classMa.containsMouse ? Math.round(4 * window.sf) : Math.round(2 * window.sf)
//                                                 anchors.left: parent.left
//                                                 anchors.top: parent.top
//                                                 anchors.bottom: parent.bottom
//                                                 radius: Math.round(2 * window.sf)
//                                                 color: classNode.isActive ? window.mauve : (classNode.isPast ? window.surface1 : window.surface2)
//                                                 Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
//                                                 Behavior on color { ColorAnimation { duration: 200 } }
//                                             }

//                                             ColumnLayout {
//                                                 anchors.left: accentLine.right
//                                                 anchors.right: parent.right
//                                                 anchors.verticalCenter: parent.verticalCenter
//                                                 anchors.leftMargin: classMa.containsMouse ? Math.round(25 * window.sf) : Math.round(15 * window.sf)
//                                                 Behavior on anchors.leftMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
//                                                 spacing: Math.round(6 * window.sf)

//                                                 Text {
//                                                     text: modelData.subject || ""
//                                                     font.family: "JetBrains Mono"
//                                                     font.weight: Font.Black
//                                                     font.pixelSize: Math.round(16 * window.sf)
//                                                     color: classNode.isActive ? window.mauve : (classNode.isPast ? window.overlay0 : window.text)
//                                                     elide: Text.ElideRight
//                                                     Layout.fillWidth: true
//                                                 }

//                                                 RowLayout {
//                                                     visible: !modelData.is_compact
//                                                     spacing: Math.round(8 * window.sf)
//                                                     Text { text: "󰅐"; font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(14 * window.sf); color: classNode.isActive ? window.mauve : window.overlay1 }
//                                                     Text { text: modelData.time || ""; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: Math.round(14 * window.sf); color: classNode.isActive ? window.text : window.overlay1 }
//                                                 }

//                                                 RowLayout {
//                                                     visible: !modelData.is_compact && (modelData.room || "") !== ""
//                                                     spacing: Math.round(8 * window.sf)
//                                                     Text { text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(14 * window.sf); color: classNode.isPast ? window.surface2 : window.peach }
//                                                     Text { text: modelData.room || ""; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: Math.round(14 * window.sf); color: window.subtext1; elide: Text.ElideRight; Layout.fillWidth: true }
//                                                 }
//                                             }

//                                             MouseArea { id: classMa; anchors.fill: parent; hoverEnabled: parent.visible }
//                                         }

//                                         Item {
//                                             anchors.fill: parent
//                                             visible: !parent.isClass
                                            
//                                             Rectangle {
//                                                 anchors.verticalCenter: parent.verticalCenter
//                                                 anchors.left: parent.left
//                                                 anchors.right: parent.right
//                                                 height: gapMa.containsMouse ? Math.round(4 * window.sf) : Math.round(2 * window.sf)
//                                                 color: gapMa.containsMouse ? window.mauve : "transparent"
//                                                 Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
//                                                 Behavior on color { ColorAnimation { duration: 150 } }
//                                             }

//                                             Rectangle {
//                                                 anchors.centerIn: parent
//                                                 width: breakText.width + Math.round(16 * window.sf)
//                                                 height: Math.round(24 * window.sf)
//                                                 radius: Math.round(6 * window.sf)
//                                                 color: window.mantle
//                                                 border.color: window.surface2
//                                                 border.width: 1
//                                                 opacity: gapMa.containsMouse ? 1.0 : 0.0
//                                                 scale: gapMa.containsMouse ? 1.0 : 0.8
//                                                 Behavior on opacity { NumberAnimation { duration: 150 } }
//                                                 Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

//                                                 Text {
//                                                     id: breakText
//                                                     anchors.centerIn: parent
//                                                     text: modelData.desc || ""
//                                                     font.family: "JetBrains Mono"
//                                                     font.weight: Font.Bold
//                                                     font.pixelSize: Math.round(14 * window.sf)
//                                                     color: window.mauve
//                                                 }
//                                             }

//                                             MouseArea { id: gapMa; anchors.fill: parent; hoverEnabled: parent.visible }
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


import QtQuick                                                                                               // Imports the core QtQuick module providing all basic QML types (Item, Rectangle, Text, animations, properties system, etc.)
import QtQuick.Layouts                                                                                       // Imports layout components (RowLayout, ColumnLayout, GridLayout) for arranging UI elements in structured patterns
import QtQuick.Controls                                                                                      // Imports interactive UI controls like ScrollView, ScrollBar, HoverHandler, and other standard widgets
import QtCore                                                                                                // Imports QtCore module which provides Settings (QSettings wrapper) for persistent local data storage
import Quickshell                                                                                            // Imports the Quickshell shell framework providing desktop-environment integration (Process, execDetached, environment variables)
import Quickshell.Io                                                                                         // Imports Quickshell I/O module specifically for StdioCollector which captures standard output from running processes
import QtQuick.Window                                                                                        // Imports window-related types giving access to Screen.width/Screen.height for responsive sizing and centering calculations
import "../"                                                                                                 // Imports from parent directory to access shared sibling components like Scaler.qml and MatugenColors.qml

Item {                                                                                                       // Defines the root Item container - the fundamental building block that holds all UI elements for this calendar component
    id: window                                                                                               // Assigns the identifier "window" so any element anywhere in this file can reference the root item's properties

    // --- Responsive Scaling Logic ---                                                                      // Marks the beginning of the scaling system that adapts UI sizes proportionally to screen resolution
    Scaler {                                                                                                 // Instantiates the Scaler component which calculates ratio-based scaling factors for consistent sizing across displays
        id: scaler                                                                                           // Gives this Scaler instance the id "scaler" allowing access to its scaling functions throughout the file
        // Pass both width and height so the internal popup scale perfectly synchronizes                     // Documents that both dimensions are needed for the master window synchronization system
        // with the master window's WindowRegistry.js calculations                                           // Explains integration with the JavaScript window registry for proper popup positioning
        currentWidth: Screen.width                                                                           // Passes the physical screen width in pixels for horizontal scaling calculations
        currentHeight: Screen.height                                                                         // Passes the physical screen height in pixels for vertical scaling calculations
    }
    
    // Expose reactive scale factor for all bindings                                                        // Documents that the base scale factor is made available as a property for use throughout the component
    readonly property real sf: scaler.baseScale                                                              // Read-only property exposing the Scaler's computed base scale factor for direct use in Math.round calculations

    // Keep helper function for backwards compatibility in pure JS blocks                                   // Explains this function exists for compatibility with JavaScript code blocks that need the old API
    function s(val) {                                                                                        // Defines a convenience function "s" that takes a design-pixel value and returns a scaled integer
        return Math.round(val * window.sf);                                                                  // Multiplies the value by the scale factor and rounds to nearest integer for crisp pixel alignment
    }

    // -------------------------------------------------------------------------                               // Visual separator line
    // DYNAMIC MASTER WINDOW SCALING (Fixes Window Clipping)                                                // Section: system that communicates size changes to the parent window to prevent content clipping
    // -------------------------------------------------------------------------                               // Visual separator line
    property real targetMasterHeight: window.scheduleModuleExists ? Math.round(750 * window.sf) : Math.round(510 * window.sf) // Calculates target master window height: 750dp with schedule, 510dp without, scaled and rounded
    property real targetMasterWidth: Math.round(1450 * window.sf)                                            // Calculates target master window width: always 1450dp, scaled and rounded for pixel-perfect sizing
    
    onTargetMasterHeightChanged: {                                                                           // Signal handler triggered whenever the target master window height changes (e.g., schedule appears/disappears)
        if (typeof masterWindow !== "undefined") {                                                           // Guard: checks if the masterWindow reference exists (set externally by the window manager code)
            masterWindow.animH = window.targetMasterHeight;                                                   // Updates the master window's animated height property to trigger smooth resizing transition
            masterWindow.targetH = window.targetMasterHeight;                                                 // Sets the master window's final target height for the animation to converge toward
        }
    }

    onTargetMasterWidthChanged: {                                                                            // Signal handler triggered whenever the target master window width changes
        if (typeof masterWindow !== "undefined") {                                                           // Guard: checks if masterWindow reference is available
            masterWindow.animW = window.targetMasterWidth;                                                    // Updates master window's animated width property
            masterWindow.targetW = window.targetMasterWidth;                                                  // Sets master window's final target width
            
            // Re-center horizontally to keep the popup perfectly in the middle when scaling changes         // Explains the centering logic that maintains popup position when size changes
            let newX = Math.floor((Screen.width / 2) - (window.targetMasterWidth / 2));                      // Calculates new X position: center of screen minus half the popup width, floored for integer positioning
            masterWindow.targetX = newX;                                                                      // Sets the master window's target X position
            masterWindow.animX = newX;                                                                        // Immediately sets the animated X position for instant repositioning
        }
    }

    // -------------------------------------------------------------------------                               // Visual separator line
    // KEYBOARD SHORTCUTS                                                                                   // Section: defines keyboard shortcuts for navigating calendar months and weather views
    // (Escape is handled by Main.qml now)                                                                  // Notes that Escape key closing is managed by the parent component, not here
    // -------------------------------------------------------------------------                               // Visual separator line
    Shortcut {                                                                                               // Creates a keyboard shortcut that triggers when the Left arrow key is pressed
        sequence: "Left"                                                                                     // Binds this shortcut to the physical Left arrow key
        onActivated: {                                                                                       // Handler executed when Left arrow is pressed
            if (calHover.hovered) {                                                                          // Checks if the mouse is currently hovering over the calendar section
                window.setMonthOffset(window.targetMonthOffset - 1);                                         // Decrements the target month offset to navigate to the previous month
            } else {                                                                                         // If not hovering over calendar
                window.setWeatherView(window.targetWeatherView - 1);                                         // Decrements the target weather view index to show previous day's forecast
            }
        }
    }

    Shortcut {                                                                                               // Creates a keyboard shortcut for the Right arrow key
        sequence: "Right"                                                                                    // Binds this shortcut to the physical Right arrow key
        onActivated: {                                                                                       // Handler executed when Right arrow is pressed
            if (calHover.hovered) {                                                                          // Checks if mouse is hovering over calendar section
                window.setMonthOffset(window.targetMonthOffset + 1);                                         // Increments target month offset to navigate to next month
            } else {                                                                                         // If not hovering over calendar
                window.setWeatherView(window.targetWeatherView + 1);                                         // Increments target weather view index for next day's forecast
            }
        }
    }

    // -------------------------------------------------------------------------                               // Visual separator line
    // COLORS (Dynamic Matugen Palette)                                                                     // Section header: declares all color properties populated from the Matugen material theme generator
    // -------------------------------------------------------------------------                               // Visual separator line
    MatugenColors { id: _theme }                                                                             // Creates MatugenColors component instance that reads current matugen color scheme; accessible via "_theme" id
    readonly property color base: _theme.base                                                                // Exposes the darkest background color from theme - used for main backgrounds
    readonly property color mantle: _theme.mantle                                                            // Exposes mantle color - slightly lighter than base for secondary backgrounds
    readonly property color crust: _theme.crust                                                              // Exposes crust color - darkest surface for highest contrast areas
    readonly property color text: _theme.text                                                                // Exposes primary text color for all important foreground text
    readonly property color subtext1: _theme.subtext1                                                        // Exposes subtext1 - tertiary text color between subtext0 and overlay for subtle hierarchy
    readonly property color subtext0: _theme.subtext0                                                        // Exposes subtext0 - secondary dimmer text for less prominent labels and descriptions
    readonly property color overlay2: _theme.overlay2                                                        // Exposes overlay2 - brightest overlay surface color
    readonly property color overlay1: _theme.overlay1                                                        // Exposes overlay1 - medium overlay surface color
    readonly property color overlay0: _theme.overlay0                                                        // Exposes overlay0 - dimmest overlay/muted surface color
    readonly property color surface2: _theme.surface2                                                        // Exposes surface2 - highest standard elevated surface for hover states
    readonly property color surface1: _theme.surface1                                                        // Exposes surface1 - medium elevated surface for interactive elements
    readonly property color surface0: _theme.surface0                                                        // Exposes surface0 - lowest elevated surface for card backgrounds
    
    readonly property color mauve: _theme.mauve                                                              // Exposes mauve accent - soft purple primary accent color
    readonly property color pink: _theme.pink                                                                // Exposes pink accent for decorative elements
    readonly property color blue: _theme.blue                                                                // Exposes blue accent for informational elements and night mode
    readonly property color sapphire: _theme.sapphire                                                        // Exposes sapphire accent - deep blue complementary color
    readonly property color peach: _theme.peach                                                              // Exposes peach accent - warm orange for morning indicators
    readonly property color yellow: _theme.yellow                                                            // Exposes yellow accent - bright warm color for morning accents
    readonly property color teal: _theme.teal                                                                // Exposes teal accent - blue-green for afternoon accents
    readonly property color green: _theme.green                                                              // Exposes green accent for success and positive indicators
    readonly property color red: _theme.red                                                                  // Exposes red accent for errors, warnings, and temperature increase indicators

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/calendar" // Resolves the full path to the calendar scripts directory using the HOME environment variable

    // -------------------------------------------------------------------------                               // Visual separator line
    // TIME OF DAY DYNAMIC COLORS                                                                           // Section: computes accent colors that shift throughout the day based on current hour
    // -------------------------------------------------------------------------                               // Visual separator line
    readonly property color timeColor: {                                                                     // Read-only property computing a primary time-of-day color
        let h = window.currentTime.getHours();                                                               // Gets the current hour (0-23) from the live clock
        if (h >= 5 && h < 12) return window.peach;      // Morning                                           // Returns warm peach for morning hours (5 AM to 11:59 AM)
        if (h >= 12 && h < 17) return window.sapphire;  // Afternoon                                          // Returns cool sapphire for afternoon (12 PM to 4:59 PM)
        if (h >= 17 && h < 21) return window.mauve;     // Evening                                           // Returns soft mauve for evening (5 PM to 8:59 PM)
        return window.blue;                             // Night                                             // Returns deep blue for night hours (9 PM to 4:59 AM)
    }

    readonly property color timeAccent: {                                                                    // Read-only property computing a secondary time-of-day accent color for highlights
        let h = window.currentTime.getHours();                                                               // Gets current hour
        if (h >= 5 && h < 12) return window.yellow;     // Morning Accent                                     // Bright yellow accent for morning
        if (h >= 12 && h < 17) return window.teal;      // Afternoon Accent                                   // Teal accent for afternoon
        if (h >= 17 && h < 21) return window.pink;      // Evening Accent                                     // Pink accent for evening
        return window.mauve;                            // Night Accent                                       // Mauve accent for night
    }

    readonly property color textAccent: Qt.tint(window.timeAccent, Qt.alpha(window.text, 0.35))              // Creates a subtle tinted text accent by blending timeAccent with 35% opacity text color

    // -------------------------------------------------------------------------                               // Visual separator line
    // STARTUP ANIMATION STATES                                                                              // Section: individual animation progress values for the staggered intro sequence
    // -------------------------------------------------------------------------                               // Visual separator line
    property bool startupComplete: false                                                                     // Flag set to true after all intro animations finish; used to control temperature glow behavior
    property real introMain: 0                                                                               // Animation progress (0 to 1) for the main container - controls overall scale and opacity
    property real introAmbient: 0                                                                            // Animation progress for ambient background blobs and the large parallax weather icon
    property real introClock: 0                                                                              // Animation progress for the central clock hub and 3D hourly orbit ring
    property real introCalendar: 0                                                                           // Animation progress for the left wing calendar panel entrance
    property real introWeather: 0                                                                            // Animation progress for the right wing weather panel entrance
    property real introSchedule: 0                                                                           // Animation progress for the bottom schedule section entrance

    SequentialAnimation {                                                                                    // Creates a sequential animation container - the outermost sequence with a pause then parallel animations
        running: true                                                                                        // Set to automatically start when the component loads
        
        // 50ms buffer to allow the window manager to map the surface before animating                      // Explains the initial pause gives the compositor time to create the window surface
        PauseAnimation { duration: 20 }                                                                      // Waits 20 milliseconds before starting any animations for window manager readiness

        ParallelAnimation {                                                                                  // All section animations run in parallel after the initial pause
            // Base window fades and scales slightly                                                         // Describes the main container entrance
            NumberAnimation { target: window; property: "introMain"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutQuart } // Fades and scales main container over 800ms with OutQuart deceleration

            // Ambient background glows and big parallax icon fade in                                       // Describes ambient layer entrance
            SequentialAnimation {                                                                            // Sequential with its own pause delay for staggered effect
                PauseAnimation { duration: 150 }                                                             // 150ms delay before ambient elements begin
                NumberAnimation { target: window; property: "introAmbient"; from: 0; to: 1.0; duration: 1000; easing.type: Easing.OutSine } // Gentle 1-second fade-in with sine easing for ambient elements
            }

            // Central clock and 3D orbital pop from the center                                             // Describes the clock hub's dramatic entrance
            SequentialAnimation {
                PauseAnimation { duration: 250 }                                                             // 250ms delay before clock appears
                NumberAnimation { target: window; property: "introClock"; from: 0; to: 1.0; duration: 900; easing.type: Easing.OutBack; easing.overshoot: 1.15 } // 900ms pop-in with 1.15x overshoot for bouncy effect
            }

            // Left wing (Calendar) slides in from the left                                                 // Describes calendar panel entrance
            SequentialAnimation {
                PauseAnimation { duration: 350 }                                                             // 350ms delay for cascade timing
                NumberAnimation { target: window; property: "introCalendar"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuint } // Smooth slide-in over 850ms
            }

            // Right wing (Weather) slides in from the right                                                // Describes weather panel entrance
            SequentialAnimation {
                PauseAnimation { duration: 400 }                                                             // 400ms delay - weather appears slightly after calendar
                NumberAnimation { target: window; property: "introWeather"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuint } // Matching 850ms slide-in
            }

            // Bottom section (Schedule) flows up smoothly                                                  // Describes schedule section entrance
            SequentialAnimation {
                PauseAnimation { duration: 500 }                                                             // 500ms delay - schedule is the last major element
                NumberAnimation { target: window; property: "introSchedule"; from: 0; to: 1.0; duration: 900; easing.type: Easing.OutExpo } // Snappy 900ms flow-up with Expo easing
            }
        }
        ScriptAction { script: window.startupComplete = true }                                               // After all animations finish, sets the startupComplete flag to true for runtime behavior changes
    }

    ParallelAnimation {                                                                                      // Exit animation that reverses all intro animations simultaneously for graceful closing
        id: exitAnim                                                                                         // Assigns id "exitAnim" so it can be started from external code
        NumberAnimation { target: window; property: "introMain"; to: 0; duration: 400; easing.type: Easing.InQuart } // Fades out main container over 400ms
        NumberAnimation { target: window; property: "introAmbient"; to: 0; duration: 250; easing.type: Easing.InQuart } // Fades ambient elements quickly in 250ms
        NumberAnimation { target: window; property: "introClock"; to: 0; duration: 300; easing.type: Easing.InQuart } // Shrinks clock out in 300ms
        NumberAnimation { target: window; property: "introCalendar"; to: 0; duration: 350; easing.type: Easing.InQuart } // Slides calendar out in 350ms
        NumberAnimation { target: window; property: "introWeather"; to: 0; duration: 350; easing.type: Easing.InQuart } // Slides weather out in 350ms
        NumberAnimation { target: window; property: "introSchedule"; to: 0; duration: 200; easing.type: Easing.InQuart } // Flows schedule out fastest in 200ms
    }

    property real globalOrbitAngle: 0                                                                        // Stores the current angle (in radians) for continuously rotating background blob animations
    NumberAnimation on globalOrbitAngle {                                                                    // Attaches a perpetual NumberAnimation directly to the globalOrbitAngle property
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true                  // Animates from 0 to 2π over 90 seconds, loops infinitely, starts immediately
    }

    // -------------------------------------------------------------------------                               // Visual separator line
    // STATE & TIME (WITH SECOND PULSE)                                                                     // Section: live clock management with per-second updates and pulse animation
    // -------------------------------------------------------------------------                               // Visual separator line
    property var currentTime: new Date()                                                                     // Stores the current date/time as a JavaScript Date object, initialized to now
    property real currentEpoch: currentTime.getTime() / 1000                                                 // Converts current time to Unix epoch seconds for schedule comparison calculations
    
    property real secondPulse: 1.0                                                                           // Pulse value that briefly spikes on each second change for clock animation
    NumberAnimation on secondPulse {                                                                         // Animation that smoothly returns the pulse back to normal after spiking
        id: pulseReset                                                                                       // Assigns id "pulseReset" so it can be restarted from code
        to: 1.0; duration: 600; easing.type: Easing.OutQuint; running: false                                 // Animates back to 1.0 over 600ms; doesn't auto-start, triggered by the timer
    }

    Timer {                                                                                                  // Creates a 1-second interval timer for live clock updates
        interval: 1000; running: true; repeat: true                                                          // Fires every 1000ms (1 second), starts immediately, repeats forever
        onTriggered: {                                                                                       // Handler executed every second
            window.currentTime = new Date();                                                                 // Updates the current time with a fresh Date object
            window.secondPulse = 1.06; // Gentle pulse                                                       // Spikes the pulse to 1.06 for visual feedback that a second has passed
            pulseReset.start();                                                                              // Starts the animation to smoothly return pulse from 1.06 back to 1.0
            
            if (window.currentTime.getHours() === 0 && window.currentTime.getMinutes() === 0 && window.currentTime.getSeconds() === 0) { // Checks if it's exactly midnight (00:00:00)
                updateCalendarGrid();                                                                        // Refreshes the calendar grid to handle month/year rollover at midnight
            }
        }
    }

    // -------------------------------------------------------------------------                               // Visual separator line
    // WEATHER DATA & ELEGANT TRANSITIONS (3D ORBIT SPIN)                                                   // Section: weather data management with 3D spin transitions between forecast days
    // -------------------------------------------------------------------------                               // Visual separator line
    property var weatherData: null                                                                           // Holds the parsed JSON weather data object; null when not yet loaded
    property int weatherView: 0                                                                              // Current weather view index (0=today, 1-4=next days) being displayed
    property color activeWeatherHex: weatherData && weatherData.forecast && weatherData.forecast[weatherView] ? weatherData.forecast[weatherView].hex : window.mauve // Resolves the current forecast's color hex; falls back to mauve

    // Transition Properties                                                                                 // Properties that drive the smooth crossfade animation between weather views
    property int targetWeatherView: 0                                                                        // The index we want to transition to (may differ from weatherView during animation)
    property real weatherContentOpacity: 1.0                                                                 // Current opacity of weather content; animated to 0 then back to 1 during transitions
    property real weatherContentOffset: 0.0                                                                  // Horizontal offset for slide animation; goes negative/positive then returns to 0
    property int weatherAnimDirection: 1                                                                     // Direction of animation: 1 for forward (next), -1 for backward (previous)
    
    // New 3D Spin Properties                                                                               // Properties for the 3D orbital spin effect during weather transitions
    property real transitionSpin: 0.0                                                                        // Current spin angle in degrees for the 3D rotation effect
    property real transitionScale: 1.0                                                                       // Current scale factor for the z-depth shrink effect during spin

    // -------------------------------------------------------------------------                               // Visual separator line
    // TEMPERATURE LOGIC                                                                                    // Section: smooth temperature counter animation with glow color feedback
    // -------------------------------------------------------------------------                               // Visual separator line
    property real targetTemp: window.weatherData && window.weatherData.forecast[window.targetWeatherView] ? Number(window.weatherData.forecast[window.targetWeatherView].max) : 0 // Extracts the target temperature (max temp) for the weather view we're heading to
    property real displayedTemp: targetTemp                                                                  // The smoothly animated temperature value that actually appears on screen

    Behavior on displayedTemp {                                                                              // Attaches an animation behavior to any changes in displayedTemp
        NumberAnimation {                                                                                    // Uses NumberAnimation for smooth counting effect
            id: tempAnim                                                                                     // Assigns id "tempAnim" so we can check if animation is running
            duration: 800                                                                                    // Counts up/down over 800ms for a smooth counter feel
            easing.type: Easing.OutQuart                                                                     // Decelerating count for natural feel
        }
    }

    property bool isTempAnimating: tempAnim.running                                                          // Boolean property: true while the temperature counter is actively animating
    property color tempGlowColor: {                                                                          // Dynamic color that changes based on temperature animation direction
        if (!isTempAnimating || !window.startupComplete) return window.text;                                 // Uses normal text color when not animating or during startup
        
        // If the target is higher than the currently ticking number, we are counting up                    // Comment explaining the temperature increasing logic
        if (window.targetTemp > window.displayedTemp) return window.red;                                     // Red glow when temperature is rising (counting up)
        
        // If the target is lower than the currently ticking number, we are counting down                   // Comment explaining temperature decreasing logic
        if (window.targetTemp < window.displayedTemp) return window.blue;                                    // Blue glow when temperature is falling (counting down)
        
        return window.text;                                                                                  // Normal text color when temperatures match
    }

    SequentialAnimation {                                                                                    // The main weather view transition animation sequence
        id: weatherTransitionAnim                                                                            // Assigns id so it can be controlled from setWeatherView function
        ParallelAnimation {                                                                                  // Phase 1: Fade out and slide out
            NumberAnimation { target: window; property: "weatherContentOpacity"; to: 0.0; duration: 250; easing.type: Easing.InSine } // Fades content to invisible over 250ms
            NumberAnimation { target: window; property: "weatherContentOffset"; to: Math.round(-40 * window.sf) * weatherAnimDirection; duration: 250; easing.type: Easing.InSine } // Slides content out 40dp in the animation direction
            
            // Spin the 3D orbit out and scale it down for depth                                           // Comment describing the 3D spin-out effect
            NumberAnimation { target: window; property: "transitionSpin"; to: 180 * weatherAnimDirection; duration: 300; easing.type: Easing.InBack } // Spins orbit 180° in animation direction over 300ms with Back easing
            NumberAnimation { target: window; property: "transitionScale"; to: 0.8; duration: 300; easing.type: Easing.InCubic } // Shrinks scale to 80% for depth effect
        }
        ScriptAction {                                                                                       // At the midpoint (when content is invisible), swap the data
            script: {                                                                                        // JavaScript block executed at the exact midpoint
                window.weatherView = window.targetWeatherView;                                                // Sets the actual weather view to the target, swapping the displayed forecast data
                window.weatherContentOffset = Math.round(40 * window.sf) * weatherAnimDirection; // Move to opposite side while hidden // Positions content on the opposite side, ready to slide in
                
                // Reset the spin to the opposite side so it continues spinning into place seamlessly      // Explains the spin continuity trick
                window.transitionSpin = -180 * weatherAnimDirection;                                         // Sets spin to opposite side so the incoming animation continues the rotation seamlessly
            } 
        }
        ParallelAnimation {                                                                                  // Phase 2: Fade in and slide in from opposite direction
            NumberAnimation { target: window; property: "weatherContentOpacity"; to: 1.0; duration: 450; easing.type: Easing.OutQuart } // Fades content back to fully visible over 450ms
            NumberAnimation { target: window; property: "weatherContentOffset"; to: 0.0; duration: 450; easing.type: Easing.OutQuart } // Slides content to center position
            
            // Snap the 3D orbit back to 0 degrees and restore full scale                                  // Describes the spin-in animation
            NumberAnimation { target: window; property: "transitionSpin"; to: 0.0; duration: 600; easing.type: Easing.OutBack; easing.overshoot: 1.2 } // Spins orbit back to 0° over 600ms with 1.2x overshoot for snap
            NumberAnimation { target: window; property: "transitionScale"; to: 1.0; duration: 500; easing.type: Easing.OutBack } // Restores scale to 100% over 500ms
        }
    }

    function setWeatherView(idx) {                                                                           // Public function to change the weather forecast view with smooth transition
        if (idx < 0 || idx > 4 || !window.weatherData) return;                                               // Guards: rejects invalid indices (<0 or >4) or if weather data isn't loaded yet
        if (idx === window.targetWeatherView) return; // Ignore if we are already heading there              // No-op if we're already transitioning to or showing this index

        // If an animation is already running, gracefully interrupt it and apply the logical switch         // Explains handling of rapid successive view changes
        // before starting the new animation so the data doesn't get desynced.                              // Prevents data corruption from overlapping animations
        if (weatherTransitionAnim.running) {                                                                 // Checks if a transition animation is currently in progress
            weatherTransitionAnim.stop();                                                                    // Stops the currently running animation immediately
            window.weatherView = window.targetWeatherView;                                                   // Forces the weather view to sync with whatever target was being animated to
        }

        window.weatherAnimDirection = idx > window.weatherView ? 1 : -1;                                     // Determines animation direction: 1 if new index is higher (forward), -1 if lower (backward)
        window.targetWeatherView = idx;                                                                      // Sets the new target view index
        weatherTransitionAnim.start();                                                                       // Starts the transition animation sequence
    }

    property int activeHourIndex: {                                                                          // Computes which hourly forecast slot best matches the current real-world hour
        if (window.weatherView !== 0 || !window.weatherData || !window.weatherData.forecast || !window.weatherData.forecast[0] || !window.weatherData.forecast[0].hourly) return -1; // Returns -1 if not on today's view or no hourly data
        
        let ch = window.currentTime.getHours();                                                              // Gets the current hour (0-23)
        let hrArr = window.weatherData.forecast[0].hourly.slice(0, 8);                                       // Takes only the first 8 hourly entries (typical forecast range)
        let bestIdx = -1;                                                                                    // Initializes best match index to -1 (none found)
        let minDiff = 999;                                                                                   // Initializes minimum time difference to a large number
        
        for (let i = 0; i < hrArr.length; i++) {                                                             // Loops through all available hourly forecasts
            let timeStr = hrArr[i].time || "00:00";                                                          // Gets the time string (e.g., "14:00") with fallback
            let h = parseInt(timeStr.split(":")[0]);                                                         // Extracts the hour number from the time string
            let diff = Math.abs(h - ch);                                                                     // Calculates absolute difference between forecast hour and current hour
            if (diff < minDiff) {                                                                            // If this forecast is closer than the previous best
                minDiff = diff;                                                                              // Updates the minimum difference
                bestIdx = i;                                                                                 // Records this index as the new best match
            }
        }
        return bestIdx !== -1 ? bestIdx : 0;                                                                 // Returns best match index, or index 0 if no good match found
    }

    Process {                                                                                                // Creates a Process to fetch weather data from the weather shell script
        id: weatherPoller                                                                                    // Assigns id "weatherPoller" for timer-based re-triggering
        command: ["bash", window.scriptsDir + "/weather.sh", "--json"]                                       // Runs the weather.sh script with --json flag for JSON output format
        running: true                                                                                        // Starts immediately on component load
        stdout: StdioCollector {                                                                             // Captures the standard output for JSON parsing
            onStreamFinished: {                                                                              // Triggered when the weather script completes
                let txt = this.text.trim();                                                                  // Gets the output text with whitespace removed
                if (txt !== "") {                                                                            // Checks if there is actual content (not empty)
                    try { window.weatherData = JSON.parse(txt); } catch(e) {}                                // Attempts to parse JSON; silently catches any parse errors
                }
            }
        }
    }

    Timer {                                                                                                  // Creates a periodic timer to refresh weather data
        interval: 150000                                                                                     // Fires every 150,000ms (2.5 minutes) for reasonable forecast freshness
        running: true; repeat: true                                                                          // Starts immediately, repeats forever
        onTriggered: weatherPoller.running = true                                                            // Re-triggers the weather fetch process on each timer fire
    }

    // -------------------------------------------------------------------------                               // Visual separator line
    // SCHEDULE DATA & CONDITIONAL RENDERING                                                                // Section: manages class schedule data and controls whether the schedule section is shown
    // -------------------------------------------------------------------------                               // Visual separator line
    property bool scheduleModuleExists: false                                                                // Flag indicating whether the schedule manager script was found on disk
    property var scheduleData: { "header": "Loading Schedule...", "link": "", "lessons": [] }                // Default schedule data with loading placeholder while real data is fetched

    // Dynamic offset based on whether the schedule module exists                                           // Explains that the clock hub shifts upward when schedule is present to make room
    property real centerOffset: window.scheduleModuleExists ? Math.round(-100 * window.sf) : 0               // Moves center hub up by 100dp when schedule exists; stays at 0 when absent
    Behavior on centerOffset { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }             // Smoothly animates the hub position shift over 600ms when schedule appears/disappears

    // Check if the schedule manager script actually exists before doing anything                           // Explains the existence check prevents errors from running non-existent scripts
    Process {                                                                                                // Creates a Process to test if the schedule manager script file exists
        id: schedulePathChecker                                                                              // Assigns id "schedulePathChecker"
        command: ["bash", "-c", "[ -f '" + window.scriptsDir + "/schedule/schedule_manager.sh' ] && echo 1 || echo 0"] // Shell test: checks if file exists; outputs "1" if yes, "0" if no
        running: true                                                                                        // Runs immediately on component load
        stdout: StdioCollector {                                                                             // Captures the output
            onStreamFinished: {                                                                              // When check completes
                if (this.text.trim() === "1") {                                                              // If the file exists (output was "1")
                    window.scheduleModuleExists = true;                                                      // Sets the flag to true enabling the schedule UI
                    schedulePoller.running = true; // Safe to start polling                                  // Triggers the schedule data fetcher now that we know the script exists
                } else {                                                                                     // If the file doesn't exist
                    window.scheduleModuleExists = false;                                                     // Keeps the flag false hiding the schedule section
                    // Shrinking is now automatically handled by the onTargetMasterHeightChanged watcher    // Notes that the master window will automatically resize since scheduleModuleExists affects targetMasterHeight
                }
            }
        }
    }

    Process {                                                                                                // Creates a Process to fetch the actual schedule data
        id: schedulePoller                                                                                   // Assigns id "schedulePoller"
        command: ["bash", window.scriptsDir + "/schedule/schedule_manager.sh"]                               // Runs the schedule manager script
        running: false // Handled by schedulePathChecker                                                     // Doesn't auto-start; only runs after schedulePathChecker confirms the script exists
        stdout: StdioCollector {                                                                             // Captures output for JSON parsing
            onStreamFinished: {                                                                              // When script completes
                let txt = this.text.trim();                                                                  // Gets trimmed output text
                if (txt !== "") {                                                                            // If there's content
                    try { window.scheduleData = JSON.parse(txt); } catch(e) { console.log("Schedule Parse Error:", e); } // Attempts JSON parse; logs any errors for debugging
                }
            }
        }
    }

    Timer {                                                                                                  // Creates a periodic timer for schedule data refresh
        interval: 600000                                                                                     // Fires every 600,000ms (10 minutes) - schedules don't change frequently
        // Only run the timer if the module actually exists                                                  // Comment explaining conditional timer operation
        running: window.scheduleModuleExists; repeat: true                                                   // Only runs when schedule module exists; repeats while active
        onTriggered: schedulePoller.running = true                                                           // Re-fetches schedule data on each timer fire
    }

    // -------------------------------------------------------------------------                               // Visual separator line
    // CALENDAR GRID LOGIC & TRANSITIONS                                                                    // Section: calendar month grid generation with smooth month-switching animations
    // -------------------------------------------------------------------------                               // Visual separator line
    property int monthOffset: 0                                                                              // Current actual month offset from today (0=current month, -1=previous, 1=next, etc.)
    property int targetMonthOffset: 0                                                                        // Target month offset for animation (may differ from monthOffset during transition)
    property string targetMonthName: ""                                                                      // Formatted month name string (e.g., "January 2025") for display
    ListModel { id: calendarModel }                                                                          // ListModel holding the 42 day entries for the 6-week calendar grid display

    property real calendarContentOpacity: 1.0                                                                // Opacity of calendar grid content; animated during month transitions
    property real calendarContentOffset: 0.0                                                                 // Horizontal offset for slide animation during month transitions
    property int calendarAnimDirection: 1                                                                    // Direction of calendar animation: 1 for next month, -1 for previous month

    SequentialAnimation {                                                                                    // Calendar month transition animation sequence
        id: calendarTransitionAnim                                                                           // Assigns id for control from setMonthOffset function
        ParallelAnimation {                                                                                  // Phase 1: Fade out and slide out
            NumberAnimation { target: window; property: "calendarContentOpacity"; to: 0.0; duration: 200; easing.type: Easing.InSine } // Fades calendar grid to invisible over 200ms
            NumberAnimation { target: window; property: "calendarContentOffset"; to: Math.round(-20 * window.sf) * calendarAnimDirection; duration: 200; easing.type: Easing.InSine } // Slides grid 20dp in animation direction
        }
        ScriptAction {                                                                                       // At midpoint, swap the calendar data
            script: {
                window.monthOffset = window.targetMonthOffset;                                                // Sets the actual month offset to the target, triggering calendar grid rebuild
                window.calendarContentOffset = Math.round(20 * window.sf) * calendarAnimDirection;           // Positions grid on opposite side ready to slide in
            }
        }
        ParallelAnimation {                                                                                  // Phase 2: Fade in and slide in
            NumberAnimation { target: window; property: "calendarContentOpacity"; to: 1.0; duration: 350; easing.type: Easing.OutQuart } // Fades grid back to visible over 350ms
            NumberAnimation { target: window; property: "calendarContentOffset"; to: 0.0; duration: 350; easing.type: Easing.OutQuart } // Slides grid back to center
        }
    }

    function setMonthOffset(newOffset) {                                                                     // Public function to change the displayed calendar month with animation
        if (newOffset === window.targetMonthOffset) return;                                                  // No-op if we're already targeting this month

        if (calendarTransitionAnim.running) {                                                                // If an animation is already running
            calendarTransitionAnim.stop();                                                                   // Stops the current animation
            window.monthOffset = window.targetMonthOffset;                                                    // Immediately syncs monthOffset to the target to prevent stale state
        }

        window.calendarAnimDirection = newOffset > window.targetMonthOffset ? 1 : -1;                        // Determines slide direction based on whether new offset is higher or lower
        window.targetMonthOffset = newOffset;                                                                // Sets the new target month offset
        calendarTransitionAnim.start();                                                                      // Starts the transition animation
    }

    function updateCalendarGrid() {                                                                          // Core function that rebuilds the calendar day model for the current month
        let d = new Date(window.currentTime.getTime());                                                      // Creates a date object cloned from current time
        d.setDate(1);                                                                                        // Sets the day to the 1st of whatever month we're in
        d.setMonth(d.getMonth() + window.monthOffset);                                                       // Applies the month offset (e.g., +1 moves to next month, -1 to previous)

        let targetMonth = d.getMonth();                                                                      // Gets the target month number (0-11) after offset
        let targetYear = d.getFullYear();                                                                    // Gets the target full year after offset
        
        let actualToday = new Date();                                                                        // Creates a fresh Date for the real current date (unaffected by offset)
        let isRealCurrentMonth = (actualToday.getMonth() === targetMonth && actualToday.getFullYear() === targetYear); // True only if viewing the actual current month
        let todayDate = actualToday.getDate();                                                               // Gets today's day number (1-31) for highlighting

        window.targetMonthName = Qt.formatDateTime(d, "MMMM yyyy");                                          // Formats the date as full month name and year (e.g., "January 2025")

        let firstDay = new Date(targetYear, targetMonth, 1).getDay();                                        // Gets the day-of-week (0=Sunday, 6=Saturday) of the 1st of target month
        firstDay = (firstDay === 0) ? 6 : firstDay - 1;                                                      // Converts to Monday-based index: Sunday becomes 6 (last), Monday=0, Tuesday=1...

        let daysInMonth = new Date(targetYear, targetMonth + 1, 0).getDate();                                // Gets the total number of days in target month by using day 0 of next month
        let daysInPrevMonth = new Date(targetYear, targetMonth, 0).getDate();                                // Gets the number of days in the previous month for filling leading cells

        calendarModel.clear();                                                                               // Empties the calendar model before rebuilding

        for (let i = firstDay - 1; i >= 0; i--) {                                                            // Fills the leading cells with days from the previous month
            calendarModel.append({ dayNum: (daysInPrevMonth - i).toString(), isCurrentMonth: false, isToday: false }); // Appends a day entry: previous month day number, not current month, not today
        }
        for (let i = 1; i <= daysInMonth; i++) {                                                             // Fills all days of the target month
            calendarModel.append({ dayNum: i.toString(), isCurrentMonth: true, isToday: (isRealCurrentMonth && i === todayDate) }); // Appends target month day; isToday true only for actual current month's day
        }
        let remaining = 42 - calendarModel.count;                                                            // Calculates how many trailing cells needed to fill a 6-week grid (42 total)
        for (let i = 1; i <= remaining; i++) {                                                               // Fills trailing cells with days from next month
            calendarModel.append({ dayNum: i.toString(), isCurrentMonth: false, isToday: false });           // Appends next month day, not current month, not today
        }
    }

    onMonthOffsetChanged: updateCalendarGrid()                                                               // Whenever monthOffset changes (after transition), automatically rebuilds the calendar grid

    Component.onCompleted: {                                                                                 // Lifecycle handler: runs once when the QML component finishes loading
        updateCalendarGrid();                                                                                // Generates the initial calendar grid on component startup
    }

    // -------------------------------------------------------------------------                               // Visual separator line
    // UI LAYOUT                                                                                             // Section header: marks the beginning of the actual visual user interface structure
    // -------------------------------------------------------------------------                               // Visual separator line
    Item {                                                                                                   // Creates a wrapper container Item that applies intro animation transforms to the entire widget
        anchors.fill: parent                                                                                 // Makes this container fill the entire root item
        scale: 0.95 + (0.05 * introMain)                                                                     // Scales from 95% to 100% as introMain goes 0→1 for subtle zoom-in entrance
        opacity: introMain                                                                                   // Fades from 0 to 1 as introMain animates

        Rectangle {                                                                                          // Creates the main background rectangle with rounded corners containing all widget content
            anchors.fill: parent                                                                             // Fills the wrapper container completely
            radius: Math.round(20 * window.sf)                                                               // Applies 20 scaled pixels border radius for rounded card appearance
            color: window.base                                                                               // Fills with the theme's base (darkest background) color
            border.color: window.surface0                                                                    // Adds a subtle 1px border using surface0 color for depth
            border.width: 1                                                                                  // Sets border thickness to exactly 1 pixel
            clip: true                                                                                       // Enables clipping so child content doesn't overflow rounded corners

            // =======================================================                                        // Visual section divider
            // AMBIENT WIDGET COLOR BLOBS (Spread Out)                                                       // Section: decorative color blobs that orbit across the entire widget background
            // =======================================================                                        // Visual section divider
            Rectangle {                                                                                      // First ambient blob - large semi-transparent circle with weather-derived color
                width: parent.width * 0.5; height: width; radius: width / 2                                  // Makes a circular shape: 50% of parent width, radius half for circle
                x: (parent.width * 0.75 - width / 2) + Math.cos(window.globalOrbitAngle * 1.5) * Math.round(350 * window.sf) // Orbits at 1.5x speed with cosine, 350dp amplitude, positioned in right 75% of widget
                y: (parent.height * 0.3 - height / 2) + Math.sin(window.globalOrbitAngle * 1.5) * Math.round(200 * window.sf) // Orbits at top 30% of widget with sine, 200dp amplitude
                opacity: 0.025 * window.introAmbient                                                         // Very subtle 2.5% max opacity scaled by intro animation progress
                color: window.activeWeatherHex                                                               // Color tracks the current weather forecast's accent color
                Behavior on color { ColorAnimation { duration: 1000 } }                                      // Smooth 1-second color transition when weather changes
            }

            Rectangle {                                                                                      // Second ambient blob - different size, orbit, and color for variety
                width: parent.width * 0.6; height: width; radius: width / 2                                  // Larger: 60% of parent width
                x: (parent.width * 0.25 - width / 2) + Math.sin(window.globalOrbitAngle * 1.2) * Math.round(-300 * window.sf) // Orbits at 1.2x speed with sine, -300dp amplitude (opposite direction), left 25% position
                y: (parent.height * 0.7 - height / 2) + Math.cos(window.globalOrbitAngle * 1.2) * Math.round(-250 * window.sf) // Orbits at bottom 70% with cosine, -250dp amplitude
                opacity: 0.02 * window.introAmbient                                                          // Slightly more subtle at 2% max opacity
                color: window.timeColor                                                                      // Color tracks the time-of-day dynamic color
                Behavior on color { ColorAnimation { duration: 1000 } }                                      // Smooth color transition
            }

            Rectangle {                                                                                      // Third ambient blob - smallest and most subtle
                width: parent.width * 0.45; height: width; radius: width / 2                                 // Smallest: 45% of parent width
                x: (parent.width * 0.5 - width / 2) + Math.cos(window.globalOrbitAngle * -1.8) * Math.round(400 * window.sf) // Orbits at -1.8x speed (reverse direction) with cosine, 400dp amplitude, center position
                y: (parent.height * 0.5 - height / 2) + Math.sin(window.globalOrbitAngle * -1.8) * Math.round(-350 * window.sf) // Orbits at center height with reverse sine, -350dp amplitude
                opacity: 0.015 * window.introAmbient                                                         // Most subtle at 1.5% max opacity
                color: window.timeAccent                                                                     // Color tracks the time-of-day accent color
                Behavior on color { ColorAnimation { duration: 1000 } }                                      // Smooth color transition
            }

            // Big Parallax Weather Icon (Tied to Weather Transition)                                       // Section: large background weather icon that moves with parallax effect
            Text {                                                                                           // Text element used to display a Nerd Font weather icon character
                anchors.centerIn: parent                                                                     // Centers the icon in the entire widget
                anchors.verticalCenterOffset: window.centerOffset                                            // Shifts vertically by centerOffset to track the clock hub position
                text: window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].icon : "" // Displays the weather icon from current forecast; empty string if no data
                font.family: "Iosevka Nerd Font"                                                             // Uses Nerd Font which includes weather icon glyphs
                font.pixelSize: Math.round(800 * window.sf)                                                  // Enormous 800dp font size for a giant background icon
                color: window.activeWeatherHex                                                               // Colored with the current weather's accent color
                opacity: (0.03 + (0.01 * Math.sin(window.globalOrbitAngle * 4))) * window.introAmbient * window.weatherContentOpacity // Very subtle 3-4% opacity that gently pulses, scaled by ambient intro and content opacity
                z: 0                                                                                         // Lowest z-index so it stays behind all interactive content
                Behavior on color { ColorAnimation { duration: 1500 } }                                      // Smooth 1.5-second color transition
                
                property real drift: 0                                                                       // Property for slow vertical drifting animation
                SequentialAnimation on drift {                                                               // Creates a gentle up-down floating animation
                    loops: Animation.Infinite                                                                 // Repeats forever
                    NumberAnimation { to: Math.round(-20 * window.sf); duration: 6000; easing.type: Easing.InOutSine } // Drifts up 20dp over 6 seconds
                    NumberAnimation { to: 0; duration: 6000; easing.type: Easing.InOutSine }                 // Drifts back down over 6 seconds
                }
                
                transform: [                                                                                 // Applies multiple transforms for parallax effect
                    Translate { y: parent.drift },                                                           // Applies the slow vertical drift
                    Translate { x: window.weatherContentOffset * 2 } // Exaggerated shift for background depth // Horizontal parallax: moves 2x the content offset for depth perception
                ]
            }

            // =======================================================                                        // Visual section divider
            // CENTRAL HERO: THE BREATHING TIME HUB & 3D HOURLY ORBIT                                       // Section: the central clock with orbiting hourly forecast items
            // =======================================================                                        // Visual section divider
            Item {                                                                                           // Container for the central clock hub and its animations
                id: centralHub                                                                               // Assigns id "centralHub" for referencing its levitation and rotation
                anchors.centerIn: parent                                                                     // Centers the hub in the widget
                anchors.verticalCenterOffset: window.centerOffset                                            // Shifts vertically by centerOffset to adapt to schedule presence
                width: Math.round(1 * window.sf); height: Math.round(1 * window.sf)                           // Nearly zero size (1dp) - serves only as an anchor point for positioned children
                z: 5                                                                                         // Mid-level z-index to sit above background but below panels

                opacity: introClock                                                                          // Fades with the clock intro animation
                scale: 0.85 + (0.15 * introClock)                                                            // Scales from 85% to 100% during intro for pop-in effect

                property real levitation: 0                                                                  // Property for the subtle floating animation
                SequentialAnimation on levitation {                                                          // Creates a gentle up-down floating motion
                    loops: Animation.Infinite                                                                 // Repeats forever
                    NumberAnimation { to: Math.round(-15 * window.sf); duration: 4000; easing.type: Easing.InOutSine } // Floats up 15dp over 4 seconds
                    NumberAnimation { to: 0; duration: 4000; easing.type: Easing.InOutSine }                 // Floats back down over 4 seconds
                }

                property real orbitBreath: 1.0                                                               // Property for orbital ring breathing (expansion/contraction)
                SequentialAnimation on orbitBreath {                                                         // Creates breathing animation for the orbital ellipse
                    loops: Animation.Infinite                                                                 // Loops forever
                    running: true                                                                            // Starts immediately
                    NumberAnimation { to: 1.035; duration: 3500; easing.type: Easing.InOutSine }             // Expands to 103.5% over 3.5 seconds
                    NumberAnimation { to: 1.0; duration: 3500; easing.type: Easing.InOutSine }               // Contracts back over 3.5 seconds
                }

                // 3D Perspective Wobble (Pitch, Yaw, Roll)                                                 // Section: subtle 3D rotation animations for the orbital plane
                property real pitchBreath: 0                                                                 // Pitch rotation (tilt forward/backward) property
                SequentialAnimation on pitchBreath {                                                         // Creates a slow pitch wobble
                    loops: Animation.Infinite; running: true
                    NumberAnimation { to: 3.5; duration: 4200; easing.type: Easing.InOutSine }               // Tilts to 3.5° over 4.2 seconds
                    NumberAnimation { to: -3.5; duration: 4200; easing.type: Easing.InOutSine }              // Tilts to -3.5° over 4.2 seconds
                }

                property real yawBreath: 0                                                                   // Yaw rotation (turn left/right) property
                SequentialAnimation on yawBreath {
                    loops: Animation.Infinite; running: true
                    NumberAnimation { to: 2.5; duration: 5100; easing.type: Easing.InOutSine }               // Turns 2.5° over 5.1 seconds
                    NumberAnimation { to: -2.5; duration: 5100; easing.type: Easing.InOutSine }              // Turns -2.5° over 5.1 seconds
                }

                property real rollBreath: 0                                                                  // Roll rotation (tilt sideways) property
                SequentialAnimation on rollBreath {
                    loops: Animation.Infinite; running: true
                    NumberAnimation { to: 1.5; duration: 5800; easing.type: Easing.InOutSine }               // Rolls 1.5° over 5.8 seconds
                    NumberAnimation { to: -1.5; duration: 5800; easing.type: Easing.InOutSine }              // Rolls -1.5° over 5.8 seconds
                }
                
                transform: [                                                                                 // Multiple transform layers applied in order
                    Translate { y: Math.round(25 * window.sf) * (1.0 - introClock) },                        // Slides down from 25dp above during clock intro
                    Translate { y: centralHub.levitation },                                                  // Applies the continuous floating levitation
                    Rotation { axis { x: 1; y: 0; z: 0 } angle: centralHub.pitchBreath },                   // 3D pitch rotation around X axis
                    Rotation { axis { x: 0; y: 1; z: 0 } angle: centralHub.yawBreath },                     // 3D yaw rotation around Y axis
                    Rotation { axis { x: 0; y: 0; z: 1 } angle: centralHub.rollBreath }                     // 3D roll rotation around Z axis
                ]

                // OPTIMIZATION: Moved scale property out of the onPaint function to prevent redrawing every frame. // Explains performance optimization: scale is GPU-accelerated instead of software redraw
                // It now draws once, and scales using the GPU.                                               // Canvas only redraws on size changes, scaling is handled by the GPU
                Canvas {                                                                                     // Canvas drawing the dashed elliptical orbit ring
                    id: orbitCanvas                                                                          // Assigns id "orbitCanvas"
                    z: -10                                                                                   // Renders behind the clock and hourly items
                    x: Math.round(-400 * window.sf)   // Widened to prevent clipping when scaled              // Negative x extends canvas left beyond the widget
                    y: Math.round(-200 * window.sf)   // Heightened to prevent clipping when scaled           // Negative y extends canvas up beyond the widget
                    width: Math.round(800 * window.sf)                                                        // Wide canvas to accommodate the full elliptical orbit
                    height: Math.round(400 * window.sf)                                                       // Tall canvas for the elliptical orbit
                    opacity: 0.25                                                                             // Subtle 25% opacity for the orbit ring

                    scale: centralHub.orbitBreath                                                             // GPU-accelerated scale driven by the breathing animation

                    onWidthChanged: requestPaint()                                                            // Redraws canvas only when width changes (responsive scaling)

                    onPaint: {                                                                               // Canvas paint handler - draws the dashed elliptical orbit once
                        var ctx = getContext("2d");                                                           // Gets 2D rendering context
                        ctx.clearRect(0, 0, width, height);                                                   // Clears the entire canvas
                        ctx.beginPath();                                                                      // Starts a new path
                        var currentRx = Math.round(320 * window.sf);                                          // Horizontal radius of the ellipse (320dp scaled)
                        var currentRy = Math.round(140 * window.sf);                                          // Vertical radius of the ellipse (140dp scaled - flatter)
                        for (var i = 0; i <= Math.PI * 2; i += 0.05) {                                        // Steps through a full circle in small increments
                            var xx = width/2 + Math.cos(i) * currentRx;                                      // Calculates x position on the ellipse
                            var yy = height/2 + Math.sin(i) * currentRy;                                    // Calculates y position on the ellipse
                            if (i === 0) ctx.moveTo(xx, yy); else ctx.lineTo(xx, yy);                       // Moves to first point, lines to subsequent points
                        }
                        ctx.strokeStyle = window.textAccent;                                                 // Colors the orbit with time-of-day text accent
                        ctx.lineWidth = Math.max(1, Math.round(1.5 * window.sf));                             // Sets line width to at least 1px
                        ctx.setLineDash([Math.round(4 * window.sf), Math.round(10 * window.sf)]);             // Creates dashed line: 4dp dash, 10dp gap
                        ctx.stroke();                                                                        // Renders the dashed ellipse
                    }
                    Behavior on opacity { NumberAnimation { duration: 1500 } }                               // Smooth opacity transitions for the orbit ring
                }

                // Core Clock                                                                                // The main digital clock display
                ColumnLayout {                                                                               // Vertical layout for time and date
                    anchors.centerIn: parent                                                                 // Centers on the hub anchor point
                    spacing: 0                                                                               // No spacing between time and date
                    z: 0                                                                                     // Renders above the orbit canvas
                    scale: 0.95 + (0.05 * window.secondPulse)                                                 // Subtly scales with the second pulse for a heartbeat effect
                    
                    RowLayout {                                                                              // Row for hours:minutes and seconds display
                        Layout.alignment: Qt.AlignHCenter                                                     // Centers the row horizontally
                        spacing: Math.round(2 * window.sf)                                                    // 2dp spacing between time and seconds
                        Text {                                                                               // Hours and minutes display (HH:MM)
                            text: Qt.formatTime(window.currentTime, "HH:mm")                                 // Formats current time as 24-hour hours:minutes string
                            font.family: "JetBrains Mono"                                                     // Monospace font for digital clock look
                            font.weight: Font.Black                                                           // Extra bold weight for prominence
                            font.pixelSize: Math.round(84 * window.sf)                                        // Very large 84dp font for the main time display
                            color: window.text                                                                // Primary text color
                            style: Text.Outline; styleColor: Qt.alpha(window.crust, 0.4)                      // Adds an outline using semi-transparent crust for depth
                        }
                        Text {                                                                               // Seconds display (:SS)
                            text: Qt.formatTime(window.currentTime, ":ss")                                   // Formats current time as colon + seconds string
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold                                                            // Bold weight (less than Black for hierarchy)
                            font.pixelSize: Math.round(32 * window.sf)                                        // Smaller 32dp font for seconds
                            color: window.textAccent                                                          // Uses the time-of-day accent color
                            Layout.alignment: Qt.AlignBottom                                                   // Aligns to bottom of row so seconds align with hours:minutes baseline
                            Layout.bottomMargin: Math.round(15 * window.sf)                                   // 15dp bottom margin for vertical alignment
                            opacity: window.secondPulse > 1.02 ? 1.0 : 0.6                                    // Briefly brightens to full opacity on each second pulse, otherwise 60%
                            style: Text.Outline; styleColor: Qt.alpha(window.crust, 0.4)                      // Outline matching the main time display
                            Behavior on color { ColorAnimation { duration: 1000 } }                           // Smooth color transition as time-of-day accent changes
                        }
                    }

                    Text {                                                                                   // Date display below the time
                        Layout.alignment: Qt.AlignHCenter                                                     // Centers horizontally
                        text: Qt.formatDateTime(window.currentTime, "dddd, MMMM dd")                         // Formats as full weekday name, full month name, day (e.g., "Monday, January 01")
                        font.family: "JetBrains Mono"
                        font.weight: Font.Bold
                        font.pixelSize: Math.round(16 * window.sf)                                            // 16dp font for the date
                        color: window.subtext0                                                                // Dimmer secondary text color for date
                        opacity: 0.9                                                                          // Slightly transparent for visual hierarchy
                    }
                }

                // TRUE 3D ORBITAL HOURLY FORECAST (Tied to Spin Transition)                                // Section: hourly forecast items orbiting the clock in 3D space
                Item {                                                                                       // Container for the orbiting hourly forecast items
                    anchors.fill: parent                                                                     // Fills the central hub area
                    opacity: window.weatherContentOpacity                                                     // Fades with weather content transitions
                    
                    // Added Scale property to give a z-depth shrink effect when spinning                   // Explains the scale property for 3D depth during transitions
                    scale: window.transitionScale                                                             // Scales down during weather spin transitions for depth effect
                    transform: Translate { x: window.weatherContentOffset * 1.5 }                            // Slides horizontally during transitions (1.5x for exaggerated orbital movement)

                    Repeater {                                                                               // Repeater to create hourly forecast items
                        id: hourRepeater                                                                     // Assigns id "hourRepeater" for model access
                        model: window.weatherData && window.weatherData.forecast[window.weatherView] && window.weatherData.forecast[window.weatherView].hourly ? window.weatherData.forecast[window.weatherView].hourly.slice(0, 8) : [] // Uses first 8 hourly entries from current forecast; empty array if no data
                        
                        delegate: Item {                                                                     // Delegate for each hourly forecast item
                            property int mCount: hourRepeater.count                                          // Exposes the total count of hourly items for angle calculations
                            property bool isToday: window.weatherView === 0                                  // True only when viewing today's forecast
                            property bool isHighlighted: isToday && index === window.activeHourIndex          // True when this item matches the current real-world hour
                            
                            property real rx: Math.round(320 * window.sf) * centralHub.orbitBreath            // Horizontal orbital radius (scaled and breathing)
                            property real ry: Math.round(140 * window.sf) * centralHub.orbitBreath            // Vertical orbital radius (scaled and breathing - flatter ellipse)
                            
                            property int relIdx: isToday ? (index - window.activeHourIndex) : index           // Relative index from active hour for today's view; absolute index for future days
                            
                            property real targetAngleDeg: isToday ? (65 + (relIdx * 30)) : (index * (360 / Math.max(1, mCount))) // Calculates angle in degrees: 65° base with 30° steps for today, evenly distributed for future days
                            
                            property real orbitOffset: isToday ? 0 : (window.globalOrbitAngle * (180 / Math.PI) * -1.5) // For future days, orbits slowly around; 0 offset for today (items stay near clock)
                            property real osc: isToday ? (Math.sin(window.globalOrbitAngle * 10 + index) * 5) : 0  // Small oscillation for today's items adding gentle wobble
                            
                            // Integrated window.transitionSpin directly into the final angle calculation   // Explains that spin angle is part of the final position calculation
                            property real rad: (targetAngleDeg + orbitOffset + osc + window.transitionSpin) * (Math.PI / 180) // Final angle in radians combining all rotation factors including weather spin
                            
                            x: Math.cos(rad) * rx - width/2                                                  // Calculates X position on the ellipse using cosine of the combined angle
                            y: Math.sin(rad) * ry - height/2                                                  // Calculates Y position on the ellipse using sine of the combined angle
                            z: Math.sin(rad) * Math.round(100 * window.sf)                                    // Z-index varies with position on ellipse for 3D depth sorting
                            
                            scale: isHighlighted ? 1.4 : (isToday ? (0.95 + 0.20 * Math.sin(rad)) : (0.90 + 0.25 * Math.sin(rad))) // Larger for highlighted hour; varies with sine for 3D depth illusion
                            opacity: isHighlighted ? 1.0 : (isToday ? (0.7 + 0.3 * ((Math.sin(rad) + 1) / 2)) : (0.65 + 0.35 * ((Math.sin(rad) + 1) / 2))) // Full opacity for highlighted; depth-based opacity variation for others

                            width: Math.round(56 * window.sf); height: Math.round(95 * window.sf)             // 56x95dp pill-shaped item size
                            
                            Rectangle {                                                                       // Background card for each hourly forecast item
                                anchors.fill: parent
                                radius: Math.round(28 * window.sf)                                            // Half of width for pill/capsule shape
                                color: isHighlighted ? window.textAccent : (hrMa.containsMouse ? window.surface2 : window.surface0) // Text accent highlight for current hour, surface2 on hover, surface0 normally
                                border.color: isHighlighted ? "transparent" : (hrMa.containsMouse ? window.textAccent : window.surface1) // Accent border on hover, surface1 normally, none when highlighted
                                border.width: 1
                                
                                Behavior on color { ColorAnimation { duration: 200 } }                         // Smooth color transition on hover/highlight changes
                                
                                ColumnLayout {                                                               // Vertical layout for time, icon, and temperature
                                    anchors.centerIn: parent
                                    spacing: Math.round(4 * window.sf)
                                    
                                    Text {                                                                    // Time label (e.g., "14:00")
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.time
                                        font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: Math.round(12 * window.sf)
                                        color: isHighlighted ? window.base : (hrMa.containsMouse ? window.text : window.overlay1) // Contrast color when highlighted, bright on hover, dim normally
                                    }
                                    
                                    Text {                                                                    // Weather icon for this hour
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.icon || (window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].icon : "") // Uses hourly icon, falls back to day icon, then generic cloud
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(18 * window.sf)
                                        color: isHighlighted ? window.base : (modelData.hex || window.text)   // Contrast when highlighted, custom hex color if available, otherwise text color
                                        
                                        transform: Translate { y: hrMa.containsMouse ? Math.round(-3 * window.sf) : 0 } // Lifts icon 3dp on hover for interactive feedback
                                        Behavior on transform { NumberAnimation { duration: 200; easing.type: Easing.OutBack } } // Bouncy lift animation
                                    }
                                    
                                    Text {                                                                    // Temperature for this hour
                                        Layout.alignment: Qt.AlignHCenter; text: modelData.temp + "°"
                                        font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: Math.round(14 * window.sf)
                                        color: isHighlighted ? window.base : window.text                      // Contrast when highlighted, normal text otherwise
                                    }
                                }
                            }
                            MouseArea { id: hrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor } // Hover area for the hourly forecast item
                        }
                    }
                }
            }

            // =======================================================                                        // Visual section divider
            // LEFT WING: FLOATING GLASS CALENDAR                                                            // Section: the left-side calendar panel with month navigation
            // =======================================================                                        // Visual section divider
            Rectangle {                                                                                      // Calendar panel background with glass-morphism effect
                id: calendarRect                                                                             // Assigns id for hover detection references
                anchors.left: parent.left                                                                    // Anchors to left edge of the widget
                anchors.top: parent.top                                                                      // Anchors to top edge
                anchors.margins: Math.round(40 * window.sf)                                                  // 40dp margin from edges
                width: Math.round(320 * window.sf)                                                            // Fixed 320dp width
                height: Math.round(420 * window.sf)                                                           // Fixed 420dp height
                color: Qt.alpha(window.surface0, 0.2)                                                        // Semi-transparent glass effect using 20% opacity surface0
                radius: Math.round(14 * window.sf)                                                            // 14dp corner rounding
                border.color: Qt.alpha(window.surface1, 0.4)                                                 // Semi-transparent border for glass effect
                border.width: 1
                z: 10                                                                                        // High z-index to render above background blobs

                opacity: introCalendar                                                                        // Fades with calendar intro animation
                transform: Translate { x: Math.round(-40 * window.sf) * (1.0 - introCalendar) }               // Slides in from 40dp to the left during intro

                HoverHandler { id: calHover }                                                                 // HoverHandler to detect if mouse is over the calendar (used by keyboard shortcuts)

                ColumnLayout {                                                                               // Vertical layout for calendar header and grid
                    anchors.fill: parent
                    anchors.margins: Math.round(25 * window.sf)                                               // 25dp internal padding
                    spacing: Math.round(15 * window.sf)                                                       // 15dp spacing between sections

                    RowLayout {                                                                              // Calendar header row: home button, prev month, month name, next month, diary button
                        Layout.fillWidth: true
                        
                        // "Return to Today" Home Button                                                     // Button to reset calendar to current month
                        Rectangle {                                                                          // Circular home button
                            Layout.preferredWidth: Math.round(32 * window.sf); Layout.preferredHeight: Math.round(32 * window.sf); radius: Math.round(16 * window.sf) // 32dp circle
                            color: homeMa.containsMouse ? window.surface1 : "transparent"                    // Highlights on hover
                            opacity: window.targetMonthOffset !== 0 ? 1.0 : 0.0                              // Only visible when NOT on current month
                            visible: opacity > 0                                                             // Hides when fully transparent for clean layout
                            Behavior on opacity { NumberAnimation { duration: 200 } }                         // Smooth fade in/out
                            Text { anchors.centerIn: parent; text: "󰃭"; font.family: "Iosevka Nerd Font"; color: window.text; font.pixelSize: Math.round(16 * window.sf) } // Calendar checkmark icon
                            MouseArea { 
                                id: homeMa; anchors.fill: parent; hoverEnabled: window.targetMonthOffset !== 0;  // Only enables hover when not on current month
                                onClicked: if (window.targetMonthOffset !== 0) window.setMonthOffset(0)       // Resets month to 0 (current month) on click
                            }
                        }

                        Rectangle {                                                                          // Previous month button
                            Layout.preferredWidth: Math.round(32 * window.sf); Layout.preferredHeight: Math.round(32 * window.sf); radius: Math.round(16 * window.sf)
                            color: prevMa.containsMouse ? window.surface1 : "transparent"
                            Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; color: window.text; font.pixelSize: Math.round(16 * window.sf) } // Left chevron icon
                            MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; onClicked: window.setMonthOffset(window.targetMonthOffset - 1) } // Decrements month on click
                        }
                        
                        Text {                                                                               // Month and year display (e.g., "JANUARY 2025")
                            Layout.fillWidth: true
                            text: window.targetMonthName.toUpperCase()                                       // Converts month name to uppercase
                            font.family: "JetBrains Mono"
                            font.weight: Font.Black
                            font.pixelSize: Math.round(16 * window.sf)
                            fontSizeMode: Text.Fit                                                           // Automatically shrinks font if text is too wide
                            minimumPixelSize: Math.round(8 * window.sf)                                      // Won't shrink below 8dp
                            color: window.text
                            horizontalAlignment: Text.AlignHCenter                                           // Centers the month name
                            
                            opacity: window.calendarContentOpacity                                           // Fades during month transitions
                            transform: Translate { x: window.calendarContentOffset }                          // Slides during month transitions
                        }

                        Rectangle {                                                                          // Next month button
                            Layout.preferredWidth: Math.round(32 * window.sf); Layout.preferredHeight: Math.round(32 * window.sf); radius: Math.round(16 * window.sf)
                            color: nextMa.containsMouse ? window.surface1 : "transparent"
                            Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; color: window.text; font.pixelSize: Math.round(16 * window.sf) } // Right chevron icon
                            MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; onClicked: window.setMonthOffset(window.targetMonthOffset + 1) } // Increments month on click
                        }

                        Rectangle {                                                                          // Diary button (opens diary manager script)
                            Layout.preferredWidth: Math.round(32 * window.sf); Layout.preferredHeight: Math.round(32 * window.sf); radius: Math.round(16 * window.sf)
                            color: diaryMa.containsMouse ? window.surface1 : "transparent"
                            Text { anchors.centerIn: parent; text: "+"; font.family: "Iosevka Nerd Font"; color: diaryMa.containsMouse ? window.mauve : window.text; font.pixelSize: Math.round(32 * window.sf) } // Plus icon, turns mauve on hover
                            MouseArea { 
                                id: diaryMa; anchors.fill: parent; hoverEnabled: true; 
                                onClicked: Quickshell.execDetached(["bash", window.scriptsDir + "/diary_manager.sh"]) // Runs the diary manager shell script on click
                            }
                            Behavior on color { ColorAnimation { duration: 150 } }                            // Smooth color transition on hover
                        }
                    }

                    RowLayout {                                                                              // Day-of-week header row (Mo, Tu, We, Th, Fr, Sa, Su)
                        Layout.fillWidth: true
                        Repeater {
                            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]                                // Array of 2-letter day abbreviations starting Monday
                            Text {
                                Layout.fillWidth: true                                                       // Each takes equal width
                                text: modelData                                                              // Displays the day abbreviation
                                font.family: "JetBrains Mono"
                                font.weight: Font.Black
                                font.pixelSize: Math.round(14 * window.sf)
                                color: window.overlay0                                                       // Dim overlay color for day headers
                                horizontalAlignment: Text.AlignHCenter                                       // Centers each day label
                            }
                        }
                    }

                    GridLayout {                                                                             // The actual calendar day grid (6 rows x 7 columns = 42 cells)
                        Layout.fillWidth: true
                        Layout.fillHeight: true                                                              // Takes remaining vertical space
                        columns: 7                                                                           // 7 columns for 7 days of the week
                        rowSpacing: Math.round(6 * window.sf)                                                // 6dp vertical spacing between rows
                        columnSpacing: Math.round(6 * window.sf)                                             // 6dp horizontal spacing between columns

                        opacity: window.calendarContentOpacity                                               // Fades during month transitions
                        transform: Translate { x: window.calendarContentOffset }                              // Slides during month transitions

                        Repeater {                                                                           // Repeater to create 42 day cells from the calendarModel
                            model: calendarModel
                            Rectangle {                                                                      // Individual day cell
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                
                                color: isToday ? window.textAccent : (dayMa.containsMouse ? Qt.alpha(window.surface2, 0.4) : "transparent") // Accent highlight for today, hover highlight otherwise
                                radius: Math.round(10 * window.sf)
                                scale: dayMa.containsMouse ? 1.2 : 1.0                                       // Pops up 20% on hover
                                border.color: isToday ? window.surface0 : (dayMa.containsMouse ? window.overlay0 : "transparent") // Border for today or hover
                                border.width: isToday || dayMa.containsMouse ? 1 : 0
                                
                                Behavior on color { ColorAnimation { duration: 150 } }                        // Smooth color transition
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } } // Bouncy scale animation on hover

                                Text {                                                                       // Day number text
                                    anchors.centerIn: parent
                                    text: dayNum                                                             // The day number (1-31, or previous/next month days)
                                    font.family: "JetBrains Mono"
                                    font.weight: isToday ? Font.Black : Font.Bold                            // Extra bold for today
                                    font.pixelSize: Math.round(14 * window.sf)
                                    color: isToday ? window.base : (isCurrentMonth ? window.text : window.surface0) // Contrast for today, normal for current month, faded for other months
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }

                                MouseArea { id: dayMa; anchors.fill: parent; hoverEnabled: true }            // Hover area for each day cell
                            }
                        }
                    }
                }
            }

            // =======================================================                                        // Visual section divider
            // RIGHT WING: ORGANIC FLOATING WEATHER STATS                                                   // Section: the right-side weather panel with forecasts and gauges
            // =======================================================                                        // Visual section divider
            Item {                                                                                           // Container for the weather panel
                anchors.right: parent.right                                                                  // Anchors to right edge
                anchors.top: parent.top                                                                      // Anchors to top
                anchors.margins: Math.round(40 * window.sf)                                                  // 40dp margin
                width: Math.round(320 * window.sf)                                                            // 320dp fixed width
                height: Math.round(420 * window.sf)                                                           // 420dp fixed height
                z: 10                                                                                        // High z-index

                opacity: introWeather                                                                         // Fades with weather intro animation
                transform: Translate { x: Math.round(40 * window.sf) * (1.0 - introWeather) }                 // Slides in from 40dp to the right during intro

                ColumnLayout {                                                                               // Vertical layout for weather content
                    anchors.fill: parent
                    spacing: Math.round(20 * window.sf)                                                       // 20dp spacing between sections

                    RowLayout {                                                                              // Weather day navigation row
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight | Qt.AlignTop                                         // Aligns to top-right of the weather panel
                        spacing: Math.round(20 * window.sf)
                        
                        MouseArea {                                                                           // Previous day button with animated arrow
                            id: wPrevMa; Layout.preferredWidth: Math.round(30 * window.sf); Layout.preferredHeight: Math.round(30 * window.sf); hoverEnabled: true
                            onClicked: window.setWeatherView(window.targetWeatherView - 1)                    // Goes to previous forecast day
                            
                            property real pulseOffset: 0                                                      // Property for subtle pulsing arrow animation
                            SequentialAnimation on pulseOffset {
                                loops: Animation.Infinite; running: true
                                NumberAnimation { to: Math.round(-3 * window.sf); duration: 1000; easing.type: Easing.InOutSine } // Pushes left 3dp
                                NumberAnimation { to: 0; duration: 1000; easing.type: Easing.InOutSine }     // Returns to center
                            }
                            
                            Text { 
                                anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(18 * window.sf) // Left arrow icon
                                color: parent.containsMouse ? window.textAccent : window.overlay1             // Accent color on hover
                                transform: Translate { x: parent.containsMouse ? Math.round(-5 * window.sf) : wPrevMa.pulseOffset } // Slides further left on hover, pulses normally
                                Behavior on transform { NumberAnimation { duration: 250; easing.type: Easing.OutBack } } // Bouncy arrow movement
                            }
                        }
                        
                        Text {                                                                               // Day name display (e.g., "MONDAY")
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].day_full.toUpperCase() : "LOADING..." // Full day name in uppercase, loading placeholder
                            font.family: "JetBrains Mono"
                            font.weight: Font.Black
                            font.pixelSize: Math.round(16 * window.sf)
                            fontSizeMode: Text.Fit                                                           // Auto-shrinks if needed
                            minimumPixelSize: Math.round(8 * window.sf)
                            color: window.text
                        }
                        
                        MouseArea {                                                                           // Next day button (mirrors previous)
                            id: wNextMa; Layout.preferredWidth: Math.round(30 * window.sf); Layout.preferredHeight: Math.round(30 * window.sf); hoverEnabled: true
                            onClicked: window.setWeatherView(window.targetWeatherView + 1)                    // Goes to next forecast day
                            
                            property real pulseOffset: 0
                            SequentialAnimation on pulseOffset {
                                loops: Animation.Infinite; running: true
                                NumberAnimation { to: Math.round(3 * window.sf); duration: 1000; easing.type: Easing.InOutSine } // Pushes right 3dp
                                NumberAnimation { to: 0; duration: 1000; easing.type: Easing.InOutSine }
                            }
                            
                            Text { 
                                anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(18 * window.sf) // Right arrow icon
                                color: parent.containsMouse ? window.textAccent : window.overlay1
                                transform: Translate { x: parent.containsMouse ? Math.round(5 * window.sf) : wNextMa.pulseOffset } // Slides further right on hover
                                Behavior on transform { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            }
                        }
                    }

                    ColumnLayout {                                                                           // Temperature and description section
                        Layout.alignment: Qt.AlignRight                                                       // Right-aligned
                        spacing: Math.round(-5 * window.sf)                                                   // Slightly negative spacing to tighten elements
                        
                        // BIG TEMPERATURE TEXT - Anchored so it doesn't slide with the wrapper              // Large temperature display that stays fixed during transitions
                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: Math.round(window.displayedTemp) + "°"                                     // Displays the smoothly animated temperature with degree symbol
                            font.family: "JetBrains Mono"
                            font.weight: Font.Black
                            font.pixelSize: Math.round(84 * window.sf)                                        // Very large 84dp font
                            color: window.tempGlowColor                                                       // Color changes based on whether temperature is rising (red) or falling (blue)
                            style: Text.Outline; 
                            styleColor: window.isTempAnimating ? Qt.alpha(window.tempGlowColor, 0.5) : Qt.alpha(window.crust, 0.4) // Glow outline when animating, subtle crust outline when stable
                            
                            Behavior on color { ColorAnimation { duration: 300 } }                            // Smooth color transitions
                            Behavior on styleColor { ColorAnimation { duration: 300 } }                       // Smooth outline color transitions
                        }
                        
                        Text {                                                                               // Weather description (e.g., "Partly Cloudy")
                            Layout.alignment: Qt.AlignRight
                            Layout.maximumWidth: Math.round(320 * window.sf)                                  // Max width equals panel width
                            horizontalAlignment: Text.AlignRight
                            text: window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].desc : "" // Shows weather description or empty
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: Math.round(16 * window.sf)
                            wrapMode: Text.WordWrap                                                          // Wraps to multiple lines if needed
                            color: window.textAccent                                                         // Time-of-day accent color
                            Behavior on color { ColorAnimation { duration: 1000 } }                           // Smooth color transition
                            
                            opacity: window.weatherContentOpacity                                            // Fades during weather transitions
                            transform: Translate { x: window.weatherContentOffset }                           // Slides during weather transitions
                        }
                    }

                    Item { Layout.fillHeight: true }                                                          // Flexible spacer that pushes gauges to the bottom

                    // FIX: Replaced explicit widths and manual vertical anchors with flexible ColumnLayout containers // Explains a layout fix using flexible containers
                    RowLayout {                                                                              // Row of 4 weather metric gauges
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Math.round(8 * window.sf)

                        Repeater {                                                                           // Repeater creating 4 gauge items
                            model: 4

                            Item {                                                                           // Container for each gauge
                                id: gaugeWrapper
                                Layout.fillWidth: true                                                       // Each takes equal width
                                Layout.preferredHeight: Math.round(100 * window.sf)                           // 100dp height for the gauge

                                scale: gaugeMa.containsMouse ? 1.15 : 1.0                                    // Pops up 15% on hover
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } } // Bouncy scale

                                property var forecast: window.weatherData && window.weatherData.forecast[window.targetWeatherView] ? window.weatherData.forecast[window.targetWeatherView] : null // Gets forecast data for current target view

                                property string gaugeIcon: index === 0 ? "" : index === 1 ? "" : index === 2 ? "" : "" // Wind, humidity, rain, feels-like icons
                                property string gaugeLbl: index === 0 ? "WIND" : index === 1 ? "HUMID" : index === 2 ? "RAIN" : "FEELS" // Label strings

                                property string gaugeVal: forecast ? (                                        // Resolves the display value for this gauge
                                    index === 0 ? forecast.wind + "m/s" :                                   // Wind speed in m/s
                                    index === 1 ? forecast.humidity + "%" :                                 // Humidity percentage
                                    index === 2 ? forecast.pop + "%" :                                     // Probability of precipitation
                                    forecast.feels_like + "°"                                              // Feels-like temperature
                                ) : ""

                                property real gaugeFill: forecast ? (                                         // Calculates the fill percentage (0.0 to 1.0) for the gauge arc
                                    index === 0 ? Math.min(1.0, forecast.wind / 25.0) :                     // Wind: max 25 m/s for full fill
                                    index === 1 ? forecast.humidity / 100.0 :                               // Humidity: direct percentage
                                    index === 2 ? forecast.pop / 100.0 :                                   // Rain probability: direct percentage
                                    Math.max(0.0, Math.min(1.0, (forecast.feels_like + 15) / 55.0))         // Feels-like: maps -15°C to 40°C range
                                ) : 0.0
                                
                                // FIX: Use ColumnLayout to enforce perfect relative positioning instead of absolute anchors // Layout fix for reliable positioning
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: Math.round(6 * window.sf)

                                    Item {                                                                   // Container for the circular gauge
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredWidth: Math.round(60 * window.sf)                     // 60dp diameter
                                        Layout.preferredHeight: Math.round(60 * window.sf)
                                        
                                        Rectangle {                                                          // Glow ring that appears on hover
                                            anchors.fill: parent
                                            radius: width / 2                                                // Perfect circle
                                            color: window.textAccent
                                            opacity: gaugeMa.containsMouse ? 0.3 : 0.0                       // Visible on hover
                                            Behavior on opacity { NumberAnimation { duration: 200 } }         // Smooth glow transition
                                        }

                                        Canvas {                                                             // Canvas for drawing the gauge arc
                                            id: gaugeCanvas
                                            anchors.fill: parent
                                            rotation: -90                                                    // Rotates -90° so arc starts from top (12 o'clock)
                                            
                                            property real animProgress: gaugeWrapper.gaugeFill               // Animated progress driven by the gauge fill value
                                            
                                            Behavior on animProgress {                                       // Smooth animation when fill value changes
                                                NumberAnimation { duration: 1000; easing.type: Easing.OutExpo }
                                            }
                                            
                                            onAnimProgressChanged: requestPaint()                            // Redraws on each animation frame
                                            onWidthChanged: requestPaint()                                   // Redraws on responsive size changes
                                            Component.onCompleted: requestPaint()                            // Initial draw on load
                                            
                                            onPaint: {                                                       // Canvas paint handler
                                                var ctx = getContext("2d");
                                                ctx.clearRect(0, 0, width, height);
                                                var r = width / 2;                                           // Radius is half the canvas width
                                                
                                                ctx.beginPath();
                                                ctx.arc(r, r, r - Math.round(4 * window.sf), 0, 2 * Math.PI); // Background track circle
                                                ctx.strokeStyle = Qt.alpha(window.text, 0.1);                // Very subtle 10% text color track
                                                ctx.lineWidth = Math.round(3 * window.sf);
                                                ctx.stroke();
                                                
                                                if (animProgress > 0) {                                      // Only draws fill arc if there's progress
                                                    ctx.beginPath();
                                                    ctx.arc(r, r, r - Math.round(4 * window.sf), 0, animProgress * 2 * Math.PI); // Fill arc proportional to progress
                                                    var grad = ctx.createLinearGradient(0, 0, width, height); // Diagonal gradient
                                                    grad.addColorStop(0, window.timeAccent);                 // Time-of-day accent start
                                                    grad.addColorStop(1, window.sapphire);                   // Sapphire end
                                                    ctx.strokeStyle = grad;
                                                    ctx.lineWidth = Math.round(4 * window.sf);
                                                    ctx.lineCap = "round";                                   // Rounded line ends
                                                    ctx.stroke();
                                                }
                                            }
                                        }
                                        
                                        Text {                                                               // Value text in center of gauge
                                            anchors.centerIn: parent
                                            text: gaugeWrapper.gaugeVal                                     // Shows the computed gauge value
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Black
                                            font.pixelSize: Math.round(12 * window.sf) // Slightly reduced to guarantee fit inside circle // Small font to fit inside the 60dp circle
                                            color: window.text
                                        }
                                    }
                                    
                                    RowLayout {                                                              // Row for icon and label below the gauge
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.fillWidth: true
                                        spacing: Math.round(4 * window.sf)
                                        
                                        Text {                                                               // Gauge icon
                                            text: gaugeWrapper.gaugeIcon
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: Math.round(12 * window.sf)
                                            color: gaugeMa.containsMouse ? window.textAccent : window.overlay0 // Brightens on hover
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                        }
                                        Text {                                                               // Gauge label
                                            text: gaugeWrapper.gaugeLbl
                                            Layout.fillWidth: true
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Bold
                                            font.pixelSize: Math.round(11 * window.sf)
                                            fontSizeMode: Text.Fit                                           // Auto-shrinks if needed
                                            minimumPixelSize: Math.round(6 * window.sf)
                                            color: window.overlay0
                                        }
                                    }
                                }
                                
                                MouseArea { id: gaugeMa; anchors.fill: parent; hoverEnabled: true }          // Hover area for the gauge
                            }
                        }
                    }
                }
            }

            // =======================================================                                        // Visual section divider
            // BOTTOM SECTION: FRAMELESS FLUID DATA STREAM (SCHEDULE)                                       // Section: bottom schedule area with animated wave backgrounds and timeline
            // =======================================================                                        // Visual section divider
            Item {                                                                                           // Container for the schedule section
                id: bottomSection
                
                // CONDITIONAL RENDERING BINDING                                                             // The entire schedule section only shows when the module exists
                visible: window.scheduleModuleExists
                
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.round(240 * window.sf)                                                           // 240dp fixed height
                z: 20                                                                                        // Highest z-index to overlay the bottom area

                opacity: introSchedule                                                                        // Fades with schedule intro animation
                transform: Translate { y: Math.round(50 * window.sf) * (1.0 - introSchedule) }                // Slides up from 50dp below during intro

                Rectangle {                                                                                  // Gradient overlay for the schedule area
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }                                 // Transparent at top for seamless blend
                        GradientStop { position: 1.0; color: Qt.alpha(window.crust, 0.6) }                   // 60% crust at bottom for depth
                    }
                }

                Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: Qt.alpha(window.surface1, 0.5) } // Thin separator line at top of schedule area

                // OPTIMIZATION: Separated the massive continuous Canvas path-drawing loop into three pre-rendered hardware-accelerated static layers. // Explains performance optimization: multiple static canvas layers instead of one complex one
                Item {                                                                                       // Container for the three animated sine wave canvases
                    anchors.fill: parent
                    z: -1                                                                                    // Behind schedule content
                    opacity: 0.15                                                                            // Very subtle 15% opacity
                    clip: true

                    // Wave 1 - Mauve                                                                        // First animated sine wave in mauve color
                    Canvas {
                        id: wave1
                        property real wLen: Math.round(100 * window.sf) * 2 * Math.PI                         // Wavelength calculated from 100dp period
                        width: parent.width + wLen                                                            // Canvas extends beyond parent to allow seamless scrolling
                        height: parent.height
                        
                        NumberAnimation on x { from: 0; to: -wave1.wLen; duration: 4000; loops: Animation.Infinite; running: window.scheduleModuleExists } // Scrolls leftward over 4 seconds
                        
                        onWidthChanged: requestPaint()                                                        // Redraws on size changes
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var cy = height / 2;                                                              // Vertical center
                            ctx.beginPath();
                            ctx.moveTo(0, cy);
                            for(var i = 0; i <= width + Math.round(20 * window.sf); i += Math.round(10 * window.sf)) { // Steps through x positions
                                ctx.lineTo(i, cy + Math.sin(i/Math.round(100 * window.sf)) * Math.round(30 * window.sf)); // Sine wave: 100dp period, 30dp amplitude
                            }
                            ctx.strokeStyle = window.mauve;
                            ctx.lineWidth = Math.round(2 * window.sf);
                            ctx.stroke();
                        }
                    }

                    // Wave 2 - Sapphire                                                                    // Second wave in sapphire, different speed and wavelength
                    Canvas {
                        id: wave2
                        property real wLen: Math.round(120 * window.sf) * 2 * Math.PI                         // 120dp period (longer wavelength)
                        width: parent.width + wLen
                        height: parent.height
                        
                        NumberAnimation on x { from: -wave2.wLen; to: 0; duration: 5500; loops: Animation.Infinite; running: window.scheduleModuleExists } // Scrolls rightward over 5.5 seconds (opposite direction)
                        
                        onWidthChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var cy = height / 2;
                            ctx.beginPath();
                            ctx.moveTo(0, cy);
                            for(var i = 0; i <= width + Math.round(20 * window.sf); i += Math.round(10 * window.sf)) {
                                ctx.lineTo(i, cy + Math.sin(i/Math.round(120 * window.sf)) * Math.round(40 * window.sf)); // 120dp period, 40dp amplitude
                            }
                            ctx.strokeStyle = window.sapphire;
                            ctx.lineWidth = Math.round(2 * window.sf);
                            ctx.stroke();
                        }
                    }

                    // Wave 3 - Peach                                                                        // Third wave in peach, different speed and wavelength
                    Canvas {
                        id: wave3
                        property real wLen: Math.round(80 * window.sf) * 2 * Math.PI                          // 80dp period (shortest wavelength)
                        width: parent.width + wLen
                        height: parent.height
                        
                        NumberAnimation on x { from: 0; to: -wave3.wLen; duration: 7000; loops: Animation.Infinite; running: window.scheduleModuleExists } // Scrolls leftward over 7 seconds
                        
                        onWidthChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var cy = height / 2;
                            ctx.beginPath();
                            ctx.moveTo(0, cy);
                            for(var i = 0; i <= width + Math.round(20 * window.sf); i += Math.round(10 * window.sf)) {
                                ctx.lineTo(i, cy + Math.sin(i/Math.round(80 * window.sf)) * Math.round(20 * window.sf)); // 80dp period, 20dp amplitude (smallest)
                            }
                            ctx.strokeStyle = window.peach;
                            ctx.lineWidth = Math.round(2 * window.sf);
                            ctx.stroke();
                        }
                    }
                }

                ColumnLayout {                                                                               // Main schedule content layout
                    anchors.fill: parent
                    anchors.margins: Math.round(25 * window.sf)                                               // 25dp padding
                    spacing: Math.round(15 * window.sf)

                    RowLayout {                                                                              // Schedule header row: icon, title, spacer, web link button
                        Layout.fillWidth: true
                        spacing: Math.round(15 * window.sf)
                        
                        Rectangle {                                                                          // Calendar icon circle
                            Layout.preferredWidth: Math.round(40 * window.sf); Layout.preferredHeight: Math.round(40 * window.sf); radius: Math.round(20 * window.sf); color: window.surface0
                            Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(18 * window.sf); color: window.textAccent } // Calendar icon
                        }
                        
                        Text {                                                                               // Schedule header text
                            Layout.fillWidth: true // FIX: Ensures text shrinks/elides instead of expanding layout infinitely // Takes available width with elision
                            text: window.scheduleData ? window.scheduleData.header : "Loading Schedule..."   // Shows schedule header or loading placeholder
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: Math.round(16 * window.sf)
                            color: window.overlay0
                            elide: Text.ElideRight                                                           // Shows ellipsis if text is too long
                        }
                        
                        Item { Layout.fillWidth: true }                                                       // Flexible spacer to push button right

                        Rectangle {                                                                          // "Open Web" button to open schedule link in browser
                            Layout.preferredWidth: Math.round(120 * window.sf); Layout.preferredHeight: Math.round(36 * window.sf); radius: Math.round(10 * window.sf)
                            color: schLinkMa.containsMouse ? window.mauve : Qt.alpha(window.surface1, 0.5)   // Mauve highlight on hover
                            border.color: window.mauve; border.width: 1                                       // Mauve border always visible
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Math.round(6 * window.sf)
                                Text { text: "Open Web"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: Math.round(14 * window.sf); color: schLinkMa.containsMouse ? window.base : window.text } // Contrast on hover
                                Text { text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(14 * window.sf); color: schLinkMa.containsMouse ? window.base : window.text } // External link icon
                            }
                            
                            MouseArea {
                                id: schLinkMa; anchors.fill: parent; hoverEnabled: true
                                onClicked: if(window.scheduleData && window.scheduleData.link) Quickshell.execDetached(["xdg-open", window.scheduleData.link]) // Opens the schedule URL in default browser
                            }
                        }
                    }

                    Item {                                                                                   // Schedule timeline area
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {                                                                               // Empty state text when no lessons exist
                            text: "Data stream offline. No scheduled events."
                            font.family: "JetBrains Mono"
                            font.italic: true
                            font.pixelSize: Math.round(14 * window.sf)
                            color: window.overlay0
                            visible: window.scheduleData && window.scheduleData.lessons.length === 0          // Only visible when lesson array is empty
                            anchors.centerIn: parent
                        }

                        Rectangle {                                                                          // Center timeline line (visible when lessons exist)
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: Math.round(2 * window.sf)                                                 // 2dp thin line
                            color: Qt.alpha(window.surface1, 0.4)                                            // Semi-transparent timeline
                            visible: window.scheduleData && window.scheduleData.lessons.length > 0            // Only visible when there are lessons
                        }

                        ScrollView {                                                                          // Horizontally scrollable container for the schedule timeline
                            id: schedScroll
                            anchors.fill: parent
                            clip: true
                            ScrollBar.vertical.policy: ScrollBar.AlwaysOff                                    // No vertical scrollbar needed
                            ScrollBar.horizontal.policy: ScrollBar.AsNeeded                                   // Horizontal scrollbar when content overflows
                            visible: window.scheduleData && window.scheduleData.lessons.length > 0
                            contentWidth: scheduleRow.width                                                   // Scroll content width matches the row of lessons
                            contentHeight: parent.height

                            Row {                                                                             // Single horizontal row containing all lesson/gap items
                                id: scheduleRow
                                height: parent.height
                                spacing: 0                                                                    // No spacing - items are positioned by their calculated widths
                                
                                // Divide the actual rendered width of the scroll area by the 430 minutes in a standard school day // Explains PPM (Pixels Per Minute) calculation
                                // to get the dynamic Pixels Per Minute ratio that stretches perfectly across the entire space.
                                property real ppm: schedScroll.width / 430.0                                  // Calculates pixels-per-minute based on 430-minute school day (7h10m) and current view width

                                Repeater {                                                                    // Repeater creating lesson/gap items from schedule data
                                    model: window.scheduleData ? window.scheduleData.lessons : []

                                    delegate: Item {                                                          // Delegate for each schedule item (class or break)
                                        property bool isClass: modelData.type === "class"                     // True if this item is a class, false if it's a break/gap
                                        
                                        // Calculate the exact duration in minutes directly from the start and end epochs // Uses Unix timestamps for precise duration
                                        property real durationMinutes: ((modelData.end || 0) - (modelData.start || 0)) / 60.0 // Converts epoch seconds difference to minutes
                                        
                                        // Multiply duration by PPM and round to the nearest whole pixel to avoid sub-pixel gaps entirely // Pixel-perfect width calculation
                                        width: Math.max(1, Math.round(durationMinutes * scheduleRow.ppm))     // Minimum 1px width; calculates exact pixel width from minutes and PPM
                                        height: parent.height

                                        Item {                                                               // CLASS ITEM: visual card for scheduled classes
                                            id: classNode
                                            anchors.fill: parent
                                            anchors.topMargin: Math.round(10 * window.sf)                      // 10dp top margin
                                            anchors.bottomMargin: Math.round(10 * window.sf)                   // 10dp bottom margin
                                            visible: parent.isClass                                           // Only visible for class-type items

                                            property bool isActive: parent.isClass && window.currentEpoch >= (modelData.start || 0) && window.currentEpoch <= (modelData.end || 0) // True if current time falls within this class period
                                            property bool isPast: parent.isClass && window.currentEpoch > (modelData.end || 0) // True if this class has already ended

                                            Canvas {                                                         // Animated wave fill behind active/hovered class items
                                                anchors.fill: parent
                                                visible: classMa.containsMouse || classNode.isActive          // Shows on hover or when class is active
                                                opacity: classMa.containsMouse ? 0.2 : 0.08                  // More visible on hover
                                                Behavior on opacity { NumberAnimation { duration: 200 } }

                                                property real wavePhase: 0                                   // Animation phase for the wavy fill
                                                NumberAnimation on wavePhase {
                                                    from: 0; to: Math.PI * 2; duration: 2000; loops: Animation.Infinite; running: parent.visible // Continuous wave animation
                                                }
                                                onWavePhaseChanged: requestPaint()
                                                onPaint: {
                                                    var ctx = getContext("2d");
                                                    ctx.clearRect(0, 0, width, height);
                                                    ctx.beginPath();
                                                    ctx.moveTo(0, height);                                   // Start at bottom-left
                                                    for(var x = 0; x <= width; x += Math.round(10 * window.sf)) {
                                                        ctx.lineTo(x, height/2 + Math.sin(x/Math.round(25 * window.sf) + wavePhase) * Math.round(20 * window.sf)); // Wavy top edge
                                                    }
                                                    ctx.lineTo(width, height);                               // Down to bottom-right
                                                    ctx.lineTo(0, height);                                    // Back to bottom-left
                                                    var grad = ctx.createLinearGradient(0, 0, width, 0);     // Horizontal gradient
                                                    grad.addColorStop(0, window.mauve);                      // Mauve on the left
                                                    grad.addColorStop(1, "transparent");                     // Fades to transparent on right
                                                    ctx.fillStyle = grad;
                                                    ctx.fill();
                                                }
                                            }

                                            Rectangle {                                                      // Left accent line for class items
                                                id: accentLine
                                                width: classNode.isActive || classMa.containsMouse ? Math.round(4 * window.sf) : Math.round(2 * window.sf) // Thicker when active/hovered
                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                anchors.bottom: parent.bottom
                                                radius: Math.round(2 * window.sf)
                                                color: classNode.isActive ? window.mauve : (classNode.isPast ? window.surface1 : window.surface2) // Mauve active, surface1 past, surface2 future
                                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutBack } } // Bouncy width animation
                                                Behavior on color { ColorAnimation { duration: 200 } }         // Smooth color transition
                                            }

                                            ColumnLayout {                                                   // Class info: subject, time, room
                                                anchors.left: accentLine.right
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.leftMargin: classMa.containsMouse ? Math.round(25 * window.sf) : Math.round(15 * window.sf) // Slides right on hover
                                                Behavior on anchors.leftMargin { NumberAnimation { duration: 300; easing.type: Easing.OutBack } } // Bouncy slide
                                                spacing: Math.round(6 * window.sf)

                                                Text {                                                       // Subject name
                                                    text: modelData.subject || ""
                                                    font.family: "JetBrains Mono"
                                                    font.weight: Font.Black
                                                    font.pixelSize: Math.round(16 * window.sf)
                                                    color: classNode.isActive ? window.mauve : (classNode.isPast ? window.overlay0 : window.text) // Mauve active, dim past, normal future
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }

                                                RowLayout {                                                  // Time row with clock icon
                                                    visible: !modelData.is_compact                           // Hidden in compact mode
                                                    spacing: Math.round(8 * window.sf)
                                                    Text { text: "󰅐"; font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(14 * window.sf); color: classNode.isActive ? window.mauve : window.overlay1 } // Clock icon
                                                    Text { text: modelData.time || ""; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: Math.round(14 * window.sf); color: classNode.isActive ? window.text : window.overlay1 } // Time string
                                                }

                                                RowLayout {                                                  // Room row with location icon
                                                    visible: !modelData.is_compact && (modelData.room || "") !== "" // Hidden in compact mode or when no room
                                                    spacing: Math.round(8 * window.sf)
                                                    Text { text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(14 * window.sf); color: classNode.isPast ? window.surface2 : window.peach } // Map marker icon
                                                    Text { text: modelData.room || ""; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: Math.round(14 * window.sf); color: window.subtext1; elide: Text.ElideRight; Layout.fillWidth: true } // Room name with elision
                                                }
                                            }

                                            MouseArea { id: classMa; anchors.fill: parent; hoverEnabled: parent.visible } // Hover area for class items
                                        }

                                        Item {                                                               // GAP/BREAK ITEM: spacer between classes
                                            anchors.fill: parent
                                            visible: !parent.isClass                                          // Only visible for non-class items

                                            Rectangle {                                                      // Center line for breaks
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                height: gapMa.containsMouse ? Math.round(4 * window.sf) : Math.round(2 * window.sf) // Thicker on hover
                                                color: gapMa.containsMouse ? window.mauve : "transparent"     // Mauve on hover, invisible normally
                                                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }

                                            Rectangle {                                                      // Break description popup card (appears on hover)
                                                anchors.centerIn: parent
                                                width: breakText.width + Math.round(16 * window.sf)            // Width matches text plus 16dp padding
                                                height: Math.round(24 * window.sf)
                                                radius: Math.round(6 * window.sf)
                                                color: window.mantle
                                                border.color: window.surface2
                                                border.width: 1
                                                opacity: gapMa.containsMouse ? 1.0 : 0.0                      // Only visible on hover
                                                scale: gapMa.containsMouse ? 1.0 : 0.8                        // Pops up from 80% scale on hover
                                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                                Text {                                                       // Break description text
                                                    id: breakText
                                                    anchors.centerIn: parent
                                                    text: modelData.desc || ""                                // Description from model (e.g., "Lunch Break")
                                                    font.family: "JetBrains Mono"
                                                    font.weight: Font.Bold
                                                    font.pixelSize: Math.round(14 * window.sf)
                                                    color: window.mauve
                                                }
                                            }

                                            MouseArea { id: gapMa; anchors.fill: parent; hoverEnabled: parent.visible } // Hover area for break items
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