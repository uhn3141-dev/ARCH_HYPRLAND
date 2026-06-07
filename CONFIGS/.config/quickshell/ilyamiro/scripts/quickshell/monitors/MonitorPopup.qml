// import QtQuick
// import QtQuick.Layouts
// import QtQuick.Effects
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
    
//     // Helper function scoped to the root Item
//     function s(val) { 
//         return scaler.s(val); 
//     }

//     // Custom File Logger
//     function debugLog(msg) {
//         let safeMsg = msg.replace(/'/g, "'\\''");
//         Quickshell.execDetached(["sh", "-c", "echo '" + safeMsg + "' >> /tmp/monitor_popup.log"]);
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
//     readonly property color surface0: _theme.surface0
//     readonly property color surface1: _theme.surface1
//     readonly property color surface2: _theme.surface2
    
//     readonly property color mauve: _theme.mauve
//     readonly property color blue: _theme.blue
//     readonly property color pink: _theme.pink
//     readonly property color teal: _theme.teal
//     readonly property color yellow: _theme.yellow
//     readonly property color peach: _theme.peach
//     readonly property color green: _theme.green
//     readonly property color red: _theme.red
//     readonly property color sapphire: _theme.sapphire

//     // -------------------------------------------------------------------------
//     // STATE & MATH
//     // -------------------------------------------------------------------------
//     property int activeEditIndex: 0
//     property int activeFocusIndex: 0 // 0: Res, 1: Clock, 2: Frame, 3: Apply
//     property real uiScale: 0.10 
    
//     // Wayland Absolute Anchor tracking
//     property int originalLayoutOriginX: 0
//     property int originalLayoutOriginY: 0

//     ListModel {
//         id: monitorsModel
//     }
    
//     property var resList: [
//         {w: 3840, h: 2160, l: "4K",   accent: window.pink}, 
//         {w: 2560, h: 1440, l: "QHD",  accent: window.mauve},
//         {w: 1920, h: 1080, l: "FHD",  accent: window.blue},
//         {w: 1600, h: 900,  l: "HD+",  accent: window.teal}, 
//         {w: 1366, h: 768,  l: "WXGA", accent: window.yellow}, 
//         {w: 1280, h: 720,  l: "HD",   accent: window.peach}, 
//         {w: 1024, h: 768,  l: "XGA",  accent: window.green}, 
//         {w: 800,  h: 600,  l: "SVGA", accent: window.red} 
//     ]

//     property color selectedResAccent: window.mauve
//     property color selectedRateAccent: window.blue

//     property int currentTransform: monitorsModel.count > 0 ? monitorsModel.get(window.activeEditIndex).transform : 0
//     property bool currentIsPortrait: currentTransform === 1 || currentTransform === 3

//     property real currentSimW: {
//         if (monitorsModel.count === 0) return 1920;
//         let mon = monitorsModel.get(window.activeEditIndex);
//         return currentIsPortrait ? mon.resH : mon.resW;
//     }
//     property real currentSimH: {
//         if (monitorsModel.count === 0) return 1080;
//         let mon = monitorsModel.get(window.activeEditIndex);
//         return currentIsPortrait ? mon.resW : mon.resH;
//     }

//     property real globalOrbitAngle: 0
//     NumberAnimation on globalOrbitAngle {
//         from: 0
//         to: Math.PI * 2
//         duration: 90000
//         loops: Animation.Infinite
//         running: true
//     }
    
//     // -------------------------------------------------------------------------
//     // KEYBOARD NAVIGATION LOGIC
//     // -------------------------------------------------------------------------
//     Keys.onPressed: (event) => {
//         if (event.key === Qt.Key_Tab) {
//             if (event.modifiers & Qt.ControlModifier) {
//                 if (monitorsModel.count > 1) {
//                     window.activeEditIndex = (window.activeEditIndex + 1) % monitorsModel.count;
//                 }
//             } else {
//                 window.activeFocusIndex = (window.activeFocusIndex + 1) % 4;
//             }
//             event.accepted = true;
//         } else if (event.key === Qt.Key_Backtab) {
//             if (event.modifiers & Qt.ControlModifier) {
//                 if (monitorsModel.count > 1) {
//                     window.activeEditIndex = (window.activeEditIndex - 1 + monitorsModel.count) % monitorsModel.count;
//                 }
//             } else {
//                 window.activeFocusIndex = (window.activeFocusIndex - 1 + 4) % 4;
//             }
//             event.accepted = true;
//         } else if (event.key === Qt.Key_Left) {
//             handleArrowKey("Left"); event.accepted = true;
//         } else if (event.key === Qt.Key_Right) {
//             handleArrowKey("Right"); event.accepted = true;
//         } else if (event.key === Qt.Key_Up) {
//             handleArrowKey("Up"); event.accepted = true;
//         } else if (event.key === Qt.Key_Down) {
//             handleArrowKey("Down"); event.accepted = true;
//         } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
//             if (activeFocusIndex === 3) {
//                 window.applyPressed = true;
//                 window.triggerApply();
//             }
//             event.accepted = true;
//         }
//     }
    
//     Keys.onReleased: (event) => {
//         if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
//             window.applyPressed = false;
//         }
//     }

//     function handleArrowKey(dir) {
//         if (monitorsModel.count === 0) return;
        
//         if (activeFocusIndex === 0) {
//             let activeMon = monitorsModel.get(window.activeEditIndex);
//             let idx = 2; // Default FHD
//             for (let i = 0; i < window.resList.length; i++) {
//                 if (window.resList[i].w === activeMon.resW && window.resList[i].h === activeMon.resH) {
//                     idx = i; break;
//                 }
//             }
            
//             if (dir === "Left" && idx % 2 !== 0) idx--;
//             else if (dir === "Right" && idx % 2 === 0 && idx < 7) idx++;
//             else if (dir === "Up" && idx >= 2) idx -= 2;
//             else if (dir === "Down" && idx <= 5) idx += 2;

//             window.selectedResAccent = window.resList[idx].accent;
//             monitorsModel.setProperty(window.activeEditIndex, "resW", window.resList[idx].w);
//             monitorsModel.setProperty(window.activeEditIndex, "resH", window.resList[idx].h);
//             delayedLayoutUpdate.restart();
            
//         } else if (activeFocusIndex === 1) {
//             let t = monitorsModel.get(window.activeEditIndex).transform;
//             if (dir === "Up") t = 0;
//             else if (dir === "Right") t = 1;
//             else if (dir === "Down") t = 2;
//             else if (dir === "Left") t = 3;
//             monitorsModel.setProperty(window.activeEditIndex, "transform", t);
//             delayedLayoutUpdate.restart();
            
//         } else if (activeFocusIndex === 2) {
//             let cIdx = sliderContainer.currentIndex;
//             if (dir === "Left" && cIdx > 0) cIdx--;
//             else if (dir === "Right" && cIdx < sliderContainer.rates.length - 1) cIdx++;
//             sliderContainer.updateSelectionVisual(cIdx);
//         }
//     }

//     // -------------------------------------------------------------------------
//     // FLUID STARTUP ANIMATIONS 
//     // -------------------------------------------------------------------------
//     property real introProgress: 0.0
//     property real monitorScale: 0.85
//     property real uiYOffset: window.s(25)
//     property real screenLight: 0.0

//     Component.onCompleted: startupAnim.start()

//     ParallelAnimation {
//         id: startupAnim
//         NumberAnimation { target: window; property: "introProgress"; from: 0.0; to: 1.0; duration: 900; easing.type: Easing.OutQuint }
//         NumberAnimation { target: window; property: "monitorScale"; from: 0.85; to: 1.0; duration: 1200; easing.type: Easing.OutQuint }
//         NumberAnimation { target: window; property: "uiYOffset"; from: window.s(25); to: 0; duration: 1800; easing.type: Easing.OutQuint }
//         NumberAnimation { target: window; property: "screenLight"; from: 0.0; to: 1.0; duration: 1500; easing.type: Easing.InOutQuad }
//     }
//     property bool applyHovered: false
//     property bool applyPressed: false

//     onActiveEditIndexChanged: {
//         menuTransitionAnim.restart();
//     }

//     // -------------------------------------------------------------------------
//     // MATHEMATICAL PERIMETER GLUE (Virtual Coordinates - Do not scale)
//     // -------------------------------------------------------------------------
//     function isOverlapping(ax, ay, aw, ah, bx, by, bw, bh) {
//         return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by;
//     }

//     function isOverlappingAny(x, y, w, h, skipIdx) {
//         for (let i = 0; i < monitorsModel.count; i++) {
//             if (i === skipIdx) continue;
//             let m = monitorsModel.get(i);
//             let isP = m.transform === 1 || m.transform === 3;
//             let mW = ((isP ? m.resH : m.resW) / m.sysScale) * window.uiScale;
//             let mH = ((isP ? m.resW : m.resH) / m.sysScale) * window.uiScale;
//             if (isOverlapping(x, y, w, h, m.uiX, m.uiY, mW, mH)) return true;
//         }
//         return false;
//     }

//     function getPerimeterSnap(pX, pY, sX, sY, sW, sH, mW, mH, snapT) {
//         let edges = [
//             { x1: sX - mW, x2: sX + sW, y1: sY - mH, y2: sY - mH }, // Top Edge
//             { x1: sX - mW, x2: sX + sW, y1: sY + sH, y2: sY + sH }, // Bottom Edge
//             { x1: sX - mW, x2: sX - mW, y1: sY - mH, y2: sY + sH }, // Left Edge
//             { x1: sX + sW, x2: sX + sW, y1: sY - mH, y2: sY + sH }  // Right Edge
//         ];

//         let bestX = pX;
//         let bestY = pY;
//         let minDist = 999999;

//         for (let i = 0; i < 4; i++) {
//             let e = edges[i];
            
//             let cx = Math.max(e.x1, Math.min(pX, e.x2));
//             let cy = Math.max(e.y1, Math.min(pY, e.y2));

//             if (Math.abs(cx - sX) < snapT) cx = sX;
//             if (Math.abs(cx - (sX + sW - mW)) < snapT) cx = sX + sW - mW;
//             if (Math.abs(cx - (sX + sW/2 - mW/2)) < snapT) cx = sX + sW/2 - mW/2;
            
//             if (Math.abs(cy - sY) < snapT) cy = sY;
//             if (Math.abs(cy - (sY + sH - mH)) < snapT) cy = sY + sH - mH;
//             if (Math.abs(cy - (sY + sH/2 - mH/2)) < snapT) cy = sY + sH/2 - mH/2;

//             let dist = Math.hypot(pX - cx, pY - cy);
//             if (dist < minDist) {
//                 minDist = dist;
//                 bestX = cx;
//                 bestY = cy;
//             }
//         }
//         return { x: bestX, y: bestY };
//     }

//     function forceLayoutUpdate() {
//         if (monitorsModel.count < 2) return;
        
//         let mIdx = window.activeEditIndex;
//         let mModel = monitorsModel.get(mIdx);
//         let isP = mModel.transform === 1 || mModel.transform === 3;
//         let mW = ((isP ? mModel.resH : mModel.resW) / mModel.sysScale) * window.uiScale;
//         let mH = ((isP ? mModel.resW : mModel.resH) / mModel.sysScale) * window.uiScale;

//         let bestX = mModel.uiX;
//         let bestY = mModel.uiY;
//         let bestDist = 999999;

//         for (let i = 0; i < monitorsModel.count; i++) {
//             if (i === mIdx) continue;
//             let sModel = monitorsModel.get(i);
//             let sIsP = sModel.transform === 1 || sModel.transform === 3;
//             let sW = ((sIsP ? sModel.resH : sModel.resW) / sModel.sysScale) * window.uiScale;
//             let sH = ((sIsP ? sModel.resW : sModel.resH) / sModel.sysScale) * window.uiScale;
            
//             let snapped = window.getPerimeterSnap(
//                 mModel.uiX, mModel.uiY,
//                 sModel.uiX, sModel.uiY,
//                 sW, sH, mW, mH, 20
//             );
            
//             let dist = Math.hypot(snapped.x - mModel.uiX, snapped.y - mModel.uiY);
//             if (dist < bestDist) {
//                 bestDist = dist;
//                 bestX = snapped.x;
//                 bestY = snapped.y;
//             }
//         }

//         monitorsModel.setProperty(mIdx, "uiX", bestX);
//         monitorsModel.setProperty(mIdx, "uiY", bestY);
//     }

//     Timer {
//         id: delayedLayoutUpdate
//         interval: 10
//         running: false
//         repeat: false
//         onTriggered: window.forceLayoutUpdate()
//     }

//     // -------------------------------------------------------------------------
//     // NATIVE SYSTEM PROCESSES 
//     // -------------------------------------------------------------------------
//     Process {
//         id: displayPoller
//         command: ["hyprctl", "monitors", "-j"]
//         running: true
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 try {
//                     let data = JSON.parse(this.text.trim());
//                     monitorsModel.clear();
                    
//                     let minX = 999999, minY = 999999;

//                     for (let i = 0; i < data.length; i++) {
//                         if (data[i].x < minX) minX = data[i].x;
//                         if (data[i].y < minY) minY = data[i].y;
//                     }

//                     window.originalLayoutOriginX = minX !== 999999 ? minX : 0;
//                     window.originalLayoutOriginY = minY !== 999999 ? minY : 0;

//                     for (let i = 0; i < data.length; i++) {
//                         let scl = data[i].scale !== undefined ? data[i].scale : 1.0;
//                         let tf = data[i].transform !== undefined ? data[i].transform : 0;
//                         let normalizedX = (data[i].x - minX) * window.uiScale;
//                         let normalizedY = (data[i].y - minY) * window.uiScale;

//                         monitorsModel.append({
//                             name: data[i].name,
//                             resW: data[i].width,
//                             resH: data[i].height,
//                             sysScale: scl,
//                             rate: Math.round(data[i].refreshRate).toString(),
//                             uiX: normalizedX,
//                             uiY: normalizedY,
//                             transform: tf
//                         });

//                         if (data[i].focused) window.activeEditIndex = i;
//                     }
                    
//                     window.forceLayoutUpdate();
//                 } catch(e) {}
//             }
//         }
//     }

//     // -------------------------------------------------------------------------
//     // SYSTEM APPLY FUNCTION & DEBUG LOGGING
//     // -------------------------------------------------------------------------
//     function triggerApply() {
//         flashRect.opacity = 0.8; 
//         applyFlashAnim.start();

//         if (monitorsModel.count === 0) return;

//         window.debugLog("================= NEW APPLY RUN =================");

//         if (monitorsModel.count === 1) {
//             let m = monitorsModel.get(0);
//             let monitorStr = m.name + "," + m.resW + "x" + m.resH + "@" + m.rate + ",0x0," + m.sysScale;
//             if (m.transform !== 0) {
//                 monitorStr += ",transform," + m.transform;
//             }

//             let jsonMonitorsArray = [{
//                 name: m.name, resW: m.resW, resH: m.resH, rate: parseInt(m.rate),
//                 x: 0, y: 0, scale: m.sysScale, transform: m.transform
//             }];
//             let safeJson = JSON.stringify(jsonMonitorsArray).replace(/'/g, "'\\''");
//             let jsonCmd = "jq '.monitors = " + safeJson + "' ~/.config/hypr/settings.json > ~/.config/hypr/settings.json.tmp && mv ~/.config/hypr/settings.json.tmp ~/.config/hypr/settings.json";
//             let postReloadCmd = "swww kill ; sleep 0.2 ; swww-daemon &";

//             Quickshell.execDetached(["notify-send", "Display Update", "Applied & Saved: " + m.resW + "x" + m.resH + " @ " + m.rate + "Hz"]);
//             Quickshell.execDetached(["sh", "-c", "hyprctl keyword monitor " + monitorStr + " ; " + jsonCmd + " ; " + postReloadCmd]);
            
//             window.debugLog("Executed single monitor apply.");
//         } else {
//             let rects = [];
//             let finalMinX = 999999;
//             let finalMinY = 999999;

//             for (let i = 0; i < monitorsModel.count; i++) {
//                 let m = monitorsModel.get(i);
//                 let isP = m.transform === 1 || m.transform === 3;
//                 let physW = Math.round((isP ? m.resH : m.resW) / m.sysScale);
//                 let physH = Math.round((isP ? m.resW : m.resH) / m.sysScale);
                
//                 let rawX = m.uiX / window.uiScale;
//                 let rawY = m.uiY / window.uiScale;
                
//                 rects.push({
//                     x: rawX, y: rawY, w: physW, h: physH, 
//                     resW: m.resW, resH: m.resH, name: m.name, 
//                     rate: m.rate, sysScale: m.sysScale, transform: m.transform
//                 });
//             }

//             function getTightSnap(pX, pY, sX, sY, sW, sH, mW, mH, t) {
//                 let cx = pX; let cy = pY;
//                 if (Math.abs(cx - (sX - mW)) < t) cx = sX - mW;
//                 else if (Math.abs(cx - (sX + sW)) < t) cx = sX + sW;
//                 else if (Math.abs(cx - sX) < t) cx = sX;
//                 else if (Math.abs(cx - (sX + sW - mW)) < t) cx = sX + sW - mW;
//                 else if (Math.abs(cx - (sX + sW/2 - mW/2)) < t) cx = sX + sW/2 - mW/2;
                
//                 if (Math.abs(cy - (sY - mH)) < t) cy = sY - mH;
//                 else if (Math.abs(cy - (sY + sH)) < t) cy = sY + sH;
//                 else if (Math.abs(cy - sY) < t) cy = sY;
//                 else if (Math.abs(cy - (sY + sH - mH)) < t) cy = sY + sH - mH;
//                 else if (Math.abs(cy - (sY + sH/2 - mH/2)) < t) cy = sY + sH/2 - mH/2;
                
//                 return {x: cx, y: cy};
//             }

//             for (let i = 1; i < rects.length; i++) {
//                 let bestX = rects[i].x;
//                 let bestY = rects[i].y;
//                 let bestDist = 999999;
//                 for (let j = 0; j < i; j++) {
//                     let r0 = rects[j];
//                     let snapped = getTightSnap(
//                         rects[i].x, rects[i].y,
//                         r0.x, r0.y,
//                         r0.w, r0.h, rects[i].w, rects[i].h, 25
//                     );
//                     let dist = Math.hypot(rects[i].x - snapped.x, rects[i].y - snapped.y);
//                     if (dist < bestDist) {
//                         bestDist = dist;
//                         bestX = Math.round(snapped.x);
//                         bestY = Math.round(snapped.y);
//                     }
//                 }
//                 rects[i].x = bestX;
//                 rects[i].y = bestY;
//             }

//             for (let i = 0; i < rects.length; i++) {
//                 if (rects[i].x < finalMinX) finalMinX = rects[i].x;
//                 if (rects[i].y < finalMinY) finalMinY = rects[i].y;
//             }
            
//             let batchCmds = [];
//             let summaryString = "";
//             let jsonMonitorsArray = [];

//             for (let i = 0; i < rects.length; i++) {
//                 let r = rects[i];
                
//                 r.x = Math.round(r.x - finalMinX);
//                 r.y = Math.round(r.y - finalMinY);
                
//                 let monitorStr = r.name + "," + r.resW + "x" + r.resH + "@" + r.rate + "," + r.x + "x" + r.y + "," + r.sysScale;
//                 if (r.transform !== 0) {
//                     monitorStr += ",transform," + r.transform;
//                 }
                
//                 batchCmds.push("keyword monitor " + monitorStr);
//                 summaryString += r.name + " ";

//                 jsonMonitorsArray.push({
//                     name: r.name, resW: r.resW, resH: r.resH, rate: parseInt(r.rate),
//                     x: r.x, y: r.y, scale: r.sysScale, transform: r.transform
//                 });
//             }
            
//             let fullHyprCmd = "hyprctl --batch '" + batchCmds.join(" ; ") + "'";
//             let safeJson = JSON.stringify(jsonMonitorsArray).replace(/'/g, "'\\''");
//             let jsonCmd = "jq '.monitors = " + safeJson + "' ~/.config/hypr/settings.json > ~/.config/hypr/settings.json.tmp && mv ~/.config/hypr/settings.json.tmp ~/.config/hypr/settings.json";
//             let postReloadCmd = "swww kill ; sleep 0.2 ; swww-daemon &";

//             Quickshell.execDetached(["sh", "-c", fullHyprCmd + " ; " + jsonCmd + " ; " + postReloadCmd]);
//             Quickshell.execDetached(["notify-send", "Display Update", "Applied & Saved layout for: " + summaryString]);
            
//             window.debugLog("Executed multi monitor apply: " + fullHyprCmd);
//         }
//     }


//     // -------------------------------------------------------------------------
//     // UI LAYOUT
//     // -------------------------------------------------------------------------
//     Item {
//         anchors.fill: parent
//         scale: 0.95 + (0.05 * window.introProgress)
//         opacity: window.introProgress

//         Rectangle {
//             anchors.fill: parent
//             radius: window.s(30)
//             color: window.base
//             border.color: window.surface0
//             border.width: 1
//             clip: true

//             Rectangle {
//                 width: parent.width * 0.8
//                 height: width
//                 radius: width / 2
//                 x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)
//                 y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)
//                 opacity: 0.04
//                 color: window.selectedResAccent
//                 Behavior on color { ColorAnimation { duration: 1000 } }
//             }
//             Rectangle {
//                 width: parent.width * 0.9
//                 height: width
//                 radius: width / 2
//                 x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)
//                 y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)
//                 opacity: 0.04
//                 color: window.selectedRateAccent
//                 Behavior on color { ColorAnimation { duration: 1000 } }
//             }

//             // ==========================================
//             // LEFT SIDE VISUAL AREA
//             // ==========================================
//             Item {
//                 id: leftVisualArea
//                 width: window.s(380)
//                 height: window.s(300)
//                 anchors.left: parent.left
//                 anchors.verticalCenter: parent.verticalCenter
//                 anchors.leftMargin: window.s(20)

//                 // --------------------------------------------------
//                 // MODE 1: SINGLE MONITOR
//                 // --------------------------------------------------
//                 Item {
//                     anchors.fill: parent
//                     visible: monitorsModel.count === 1

//                     Item {
//                         id: singleMonitorZoom
//                         anchors.centerIn: parent
//                         width: window.s(380)
//                         height: window.s(280)
                        
//                         property real baseScale: Math.min(1.0, Math.min(2200 / window.currentSimW, 1400 / Math.max(1, window.currentSimH)))
//                         scale: baseScale * window.monitorScale
//                         opacity: window.introProgress
//                         Behavior on baseScale { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

//                         Rectangle {
//                             id: deskSurface
//                             width: window.s(1000)
//                             height: window.s(14)
//                             radius: window.s(6)
//                             anchors.top: standBase.bottom
//                             anchors.horizontalCenter: parent.horizontalCenter
//                             color: window.mantle
//                             border.color: window.surface0
//                             border.width: 1

//                             Rectangle { 
//                                 width: window.s(24)
//                                 height: window.s(350)
//                                 radius: window.s(4)
//                                 color: window.crust
//                                 anchors.top: parent.bottom
//                                 anchors.topMargin: window.s(-5)
//                                 anchors.left: parent.left
//                                 anchors.leftMargin: window.s(100)
//                                 z: -1 
//                             }
//                             Rectangle { 
//                                 width: window.s(24)
//                                 height: window.s(350)
//                                 radius: window.s(4)
//                                 color: window.crust
//                                 anchors.top: parent.bottom
//                                 anchors.topMargin: window.s(-5)
//                                 anchors.right: parent.right
//                                 anchors.rightMargin: window.s(100)
//                                 z: -1 
//                             }
//                         }

//                         Rectangle {
//                             id: standBase
//                             width: window.s(130)
//                             height: window.s(8)
//                             radius: window.s(4)
//                             anchors.bottom: parent.bottom
//                             anchors.bottomMargin: window.s(20)
//                             anchors.horizontalCenter: parent.horizontalCenter
//                             color: window.surface1
//                         }
                        
//                         Rectangle {
//                             id: standNeck
//                             width: window.s(34)
//                             height: window.s(70)
//                             anchors.bottom: standBase.top
//                             anchors.horizontalCenter: parent.horizontalCenter
//                             color: window.surface0
//                             Rectangle { 
//                                 width: window.s(10)
//                                 height: window.s(30)
//                                 radius: window.s(5)
//                                 anchors.centerIn: parent
//                                 color: window.base 
//                             }
//                         }

//                         Rectangle {
//                             id: screenBezel
                            
//                             // Perfect aspect ratio AND scales up physically on the desk at higher resolutions
//                             width: window.s(320) * (window.currentSimW / 1920.0)
//                             height: window.s(320) * (window.currentSimH / 1920.0)

//                             anchors.bottom: standNeck.top
//                             anchors.bottomMargin: window.s(-10)
//                             anchors.horizontalCenter: parent.horizontalCenter
//                             radius: window.s(12)
//                             color: window.crust
//                             border.color: window.surface2
//                             border.width: window.s(2)
                            
//                             Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
//                             Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

//                             Rectangle {
//                                 anchors.fill: parent
//                                 anchors.margins: window.s(10)
//                                 radius: window.s(6)
//                                 color: window.surface0
//                                 clip: true

//                                 Rectangle {
//                                     anchors.fill: parent
//                                     color: "transparent"
//                                     opacity: window.screenLight
                                    
//                                     gradient: Gradient {
//                                         orientation: Gradient.Vertical
//                                         GradientStop { 
//                                             position: 0.0
//                                             color: Qt.tint(window.surface0, Qt.alpha(window.selectedResAccent, 0.15))
//                                             Behavior on color { ColorAnimation { duration: 400 } } 
//                                         }
//                                         GradientStop { 
//                                             position: 1.0
//                                             color: Qt.tint(window.surface0, Qt.alpha(window.selectedRateAccent, 0.1))
//                                             Behavior on color { ColorAnimation { duration: 400 } } 
//                                         }
//                                     }
                                    
//                                     Grid { 
//                                         anchors.centerIn: parent
//                                         rows: 10
//                                         columns: 15
//                                         spacing: window.s(20)
//                                         Repeater { 
//                                             model: 150
//                                             Rectangle { width: window.s(2); height: window.s(2); radius: window.s(1); color: Qt.alpha(window.text, 0.1) } 
//                                         } 
//                                     }
//                                 }

//                                 Item {
//                                     anchors.centerIn: parent
//                                     width: window.s(160)
//                                     height: window.s(100)
                                    
//                                     // 1. Counteract the environmental zoom factor
//                                     property real counterScale: 1.0 / singleMonitorZoom.scale
                                    
//                                     // 2. Compute a safe physical boundary based on current visual rotation
//                                     // If rotated (portrait), we compare the wrapper's height to the screen's width, etc.
//                                     property real maxPhysicalScale: window.currentIsPortrait 
//                                         ? Math.min((parent.width * 0.9) / height, (parent.height * 0.9) / width)
//                                         : Math.min((parent.width * 0.9) / width, (parent.height * 0.9) / height)
                                    
//                                     scale: Math.min(counterScale, maxPhysicalScale)
                                    
//                                     ColumnLayout {
//                                         anchors.centerIn: parent
//                                         spacing: window.s(4)

//                                         // Restored Rotation: Acts as a pointer to the monitor's physical bottom
//                                         rotation: window.currentTransform * 90
//                                         Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

//                                         Text { 
//                                             Layout.alignment: Qt.AlignHCenter
//                                             font.family: "Iosevka Nerd Font"
//                                             font.pixelSize: window.s(38)
//                                             color: window.selectedResAccent
//                                             text: "󰍹"
//                                             Behavior on color { ColorAnimation { duration: 400 } } 
//                                         }
//                                         Text { 
//                                             Layout.alignment: Qt.AlignHCenter
//                                             font.family: "JetBrains Mono"
//                                             font.weight: Font.Bold
//                                             font.pixelSize: window.s(16)
//                                             color: window.text
//                                             text: monitorsModel.count > 0 ? monitorsModel.get(0).name : "Unknown" 
//                                         }
//                                         Text { 
//                                             Layout.alignment: Qt.AlignHCenter
//                                             font.family: "JetBrains Mono"
//                                             font.pixelSize: window.s(12)
//                                             color: window.subtext0
//                                             text: window.currentSimW + "x" + window.currentSimH + " @ " + (monitorsModel.count > 0 ? monitorsModel.get(0).rate : "60") + "Hz" 
//                                         }
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }

//                 // --------------------------------------------------
//                 // MODE 2: MULTI-MONITOR (3+ Supported)
//                 // --------------------------------------------------
//                 Item {
//                     anchors.fill: parent
//                     visible: monitorsModel.count > 1

//                     Item {
//                         id: multiMonitorView
//                         width: window.s(380)
//                         height: window.s(280)
//                         anchors.centerIn: parent
//                         clip: true 

//                         Grid {
//                             anchors.centerIn: parent
//                             rows: 25
//                             columns: 34
//                             spacing: window.s(18)
//                             Repeater { 
//                                 model: 850
//                                 Rectangle { width: window.s(2); height: window.s(2); radius: window.s(1); color: Qt.alpha(window.text, 0.1) } 
//                             }
//                         }

//                         property real targetScale: {
//                             if (monitorsModel.count < 2) return 1.0;
//                             let minX = 999999, minY = 999999, maxX = -999999, maxY = -999999;
                            
//                             for (let i = 0; i < monitorsModel.count; i++) {
//                                 let m = monitorsModel.get(i);
//                                 let isP = m.transform === 1 || m.transform === 3;
//                                 let w = ((isP ? m.resH : m.resW) / m.sysScale) * window.uiScale;
//                                 let h = ((isP ? m.resW : m.resH) / m.sysScale) * window.uiScale;
                                
//                                 minX = Math.min(minX, m.uiX);
//                                 minY = Math.min(minY, m.uiY);
//                                 maxX = Math.max(maxX, m.uiX + w);
//                                 maxY = Math.max(maxY, m.uiY + h);
//                             }
                            
//                             let requiredW = (maxX - minX) + 80;
//                             let requiredH = (maxY - minY) + 80;
                            
//                             return Math.min(1.8 * scaler.baseScale, Math.min(window.s(340) / requiredW, window.s(240) / requiredH));
//                         }

//                         property real offsetX: {
//                             if (monitorsModel.count < 2) return 0;
//                             let minX = 999999, maxX = -999999;
                            
//                             for (let i = 0; i < monitorsModel.count; i++) {
//                                 let m = monitorsModel.get(i);
//                                 let isP = m.transform === 1 || m.transform === 3;
//                                 let w = ((isP ? m.resH : m.resW) / m.sysScale) * window.uiScale;
                                
//                                 minX = Math.min(minX, m.uiX);
//                                 maxX = Math.max(maxX, m.uiX + w);
//                             }
                            
//                             let centerX = minX + (maxX - minX) / 2;
//                             return window.s(190) - (centerX * targetScale);
//                         }

//                         property real offsetY: {
//                             if (monitorsModel.count < 2) return 0;
//                             let minY = 999999, maxY = -999999;
                            
//                             for (let i = 0; i < monitorsModel.count; i++) {
//                                 let m = monitorsModel.get(i);
//                                 let isP = m.transform === 1 || m.transform === 3;
//                                 let h = ((isP ? m.resW : m.resH) / m.sysScale) * window.uiScale;
                                
//                                 minY = Math.min(minY, m.uiY);
//                                 maxY = Math.max(maxY, m.uiY + h);
//                             }
                            
//                             let centerY = minY + (maxY - minY) / 2;
//                             return window.s(140) - (centerY * targetScale);
//                         }

//                         Item {
//                             id: transformNode
//                             x: multiMonitorView.offsetX
//                             y: multiMonitorView.offsetY
//                             scale: multiMonitorView.targetScale
//                             transformOrigin: Item.TopLeft

//                             Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
//                             Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
//                             Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

//                             Repeater {
//                                 id: monitorRepeater
//                                 model: monitorsModel

//                                 Item {
//                                     property bool isActive: window.activeEditIndex === index
//                                     property bool isPortrait: model.transform === 1 || model.transform === 3

//                                     // THE VISIBLE SNAPPED MONITOR CARD
//                                     Rectangle {
//                                         id: monitorCard
//                                         x: model.uiX
//                                         y: model.uiY
                                        
//                                         width: (isPortrait ? model.resH : model.resW) / model.sysScale * window.uiScale
//                                         height: (isPortrait ? model.resW : model.resH) / model.sysScale * window.uiScale
                                        
//                                         radius: 8
//                                         color: isActive ? window.surface1 : window.crust
//                                         border.color: isActive ? window.selectedResAccent : window.surface2
//                                         border.width: isActive ? 2 : 1
//                                         z: isActive ? 5 : 0

//                                         Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
//                                         Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                                        
//                                         Behavior on border.color { ColorAnimation { duration: 300 } }
//                                         Behavior on color { ColorAnimation { duration: 300 } }
//                                         Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
//                                         Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

//                                         Item {
//                                             anchors.centerIn: parent
//                                             width: 110
//                                             height: 80
                                            
//                                             property real idealScale: 1.2 / transformNode.scale
//                                             // Ensure the bounded box checks against the correct axis when visually rotated
//                                             property real maxPhysicalScale: isPortrait 
//                                                 ? Math.min((parent.width * 0.9) / height, (parent.height * 0.9) / width) 
//                                                 : Math.min((parent.width * 0.9) / width, (parent.height * 0.9) / height)
                                                
//                                             scale: Math.min(idealScale, maxPhysicalScale)
                                            
//                                             ColumnLayout {
//                                                 anchors.centerIn: parent
//                                                 spacing: 2
                                                
//                                                 // Restored Rotation for Multi-Monitor cards
//                                                 rotation: model.transform * 90
//                                                 Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

//                                                 Text { 
//                                                     Layout.alignment: Qt.AlignHCenter
//                                                     font.family: "Iosevka Nerd Font"
//                                                     font.pixelSize: 32
//                                                     color: isActive ? window.selectedResAccent : window.text
//                                                     text: "󰍹"
//                                                     Behavior on color { ColorAnimation { duration: 300 } } 
//                                                 }
//                                                 Text { 
//                                                     Layout.alignment: Qt.AlignHCenter
//                                                     font.family: "JetBrains Mono"
//                                                     font.weight: Font.Black
//                                                     font.pixelSize: 13
//                                                     color: window.text
//                                                     text: model.name 
//                                                 }
//                                                 Text { 
//                                                     Layout.alignment: Qt.AlignHCenter
//                                                     font.family: "JetBrains Mono"
//                                                     font.pixelSize: 10
//                                                     color: window.subtext0
//                                                     text: model.resW + "x" + model.resH + " @ " + model.rate + "Hz" 
//                                                 }
//                                             }
//                                         }
//                                     }

//                                     // THE INVISIBLE GHOST DRAGGER
//                                     Item {
//                                         id: ghostDrag
//                                         x: model.uiX
//                                         y: model.uiY
//                                         width: monitorCard.width
//                                         height: monitorCard.height
//                                         z: isActive ? 10 : 1

//                                         MouseArea {
//                                             id: ghostMa
//                                             anchors.fill: parent
//                                             drag.target: ghostDrag
//                                             drag.axis: Drag.XAndYAxis
                                            
//                                             onPressed: {
//                                                 window.activeEditIndex = index;
//                                                 ghostDrag.x = model.uiX;
//                                                 ghostDrag.y = model.uiY;
//                                             }

//                                             onPositionChanged: {
//                                                 if (drag.active && monitorsModel.count >= 2) {
//                                                     let mW = monitorCard.width;
//                                                     let mH = monitorCard.height;

//                                                     let padding = 40;
//                                                     let boundMinX = 999999, boundMinY = 999999;
//                                                     let boundMaxX = -999999, boundMaxY = -999999;
                                                    
//                                                     for (let j = 0; j < monitorsModel.count; j++) {
//                                                         if (j === index) continue;
//                                                         let sModel = monitorsModel.get(j);
//                                                         let sIsP = sModel.transform === 1 || sModel.transform === 3;
//                                                         let sW = ((sIsP ? sModel.resH : sModel.resW) / sModel.sysScale) * window.uiScale;
//                                                         let sH = ((sIsP ? sModel.resW : sModel.resH) / sModel.sysScale) * window.uiScale;
                                                        
//                                                         boundMinX = Math.min(boundMinX, sModel.uiX - mW - padding);
//                                                         boundMinY = Math.min(boundMinY, sModel.uiY - mH - padding);
//                                                         boundMaxX = Math.max(boundMaxX, sModel.uiX + sW + padding);
//                                                         boundMaxY = Math.max(boundMaxY, sModel.uiY + sH + padding);
//                                                     }

//                                                     ghostDrag.x = Math.max(boundMinX, Math.min(ghostDrag.x, boundMaxX));
//                                                     ghostDrag.y = Math.max(boundMinY, Math.min(ghostDrag.y, boundMaxY));

//                                                     let bestX = ghostDrag.x;
//                                                     let bestY = ghostDrag.y;
//                                                     let bestDist = 999999;
                                                    
//                                                     for (let j = 0; j < monitorsModel.count; j++) {
//                                                         if (j === index) continue;
//                                                         let sModel = monitorsModel.get(j);
//                                                         let sIsP = sModel.transform === 1 || sModel.transform === 3;
//                                                         let sW = ((sIsP ? sModel.resH : sModel.resW) / sModel.sysScale) * window.uiScale;
//                                                         let sH = ((sIsP ? sModel.resW : sModel.resH) / sModel.sysScale) * window.uiScale;
                                                        
//                                                         let snapped = window.getPerimeterSnap(
//                                                             ghostDrag.x, ghostDrag.y,
//                                                             sModel.uiX, sModel.uiY,
//                                                             sW, sH, mW, mH, 20
//                                                         );
                                                        
//                                                         let dist = Math.hypot(ghostDrag.x - snapped.x, ghostDrag.y - snapped.y);
//                                                         if (dist < bestDist) {
//                                                             bestDist = dist;
//                                                             bestX = snapped.x;
//                                                             bestY = snapped.y;
//                                                         }
//                                                     }

//                                                     if (!window.isOverlappingAny(bestX, bestY, mW, mH, index)) {
//                                                         monitorsModel.setProperty(index, "uiX", bestX);
//                                                         monitorsModel.setProperty(index, "uiY", bestY);
//                                                     }
//                                                 }
//                                             }

//                                             onReleased: {
//                                                 ghostDrag.x = model.uiX;
//                                                 ghostDrag.y = model.uiY;
//                                             }
//                                         }
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }

//             // ==========================================
//             // INTERACTIVE SELECTION GRIDS
//             // ==========================================
//             Item {
//                 anchors.left: leftVisualArea.right
//                 anchors.right: parent.right
//                 anchors.verticalCenter: parent.verticalCenter
//                 anchors.verticalCenterOffset: window.s(-10) // Tweak layout slightly downwards 
//                 anchors.leftMargin: window.s(10)
//                 anchors.rightMargin: window.s(30)
//                 height: rightSideContainer.implicitHeight 

//                 opacity: window.introProgress
//                 transform: Translate { y: window.uiYOffset }

//                 SequentialAnimation {
//                     id: menuTransitionAnim
//                     ParallelAnimation {
//                         ScaleAnimator { 
//                             target: rightSideContainer
//                             from: 0.99
//                             to: 1.0
//                             duration: 200
//                             easing.type: Easing.OutSine 
//                         }
//                         NumberAnimation { 
//                             target: highlightFlash
//                             property: "opacity"
//                             from: 0.05
//                             to: 0.0
//                             duration: 250
//                             easing.type: Easing.OutQuad 
//                         }
//                     }
//                 }

//                 Rectangle {
//                     id: highlightFlash
//                     anchors.fill: rightSideContainer
//                     anchors.margins: window.s(-10)
//                     color: window.selectedResAccent
//                     opacity: 0.0
//                     radius: window.s(12)
//                 }

//                 ColumnLayout {
//                     id: rightSideContainer
//                     anchors.fill: parent
//                     spacing: window.s(10)

//                     // --- RESOLUTION CARDS SECTION ---
//                     GridLayout {
//                         id: resGrid
//                         Layout.fillWidth: true
//                         columns: 2
//                         columnSpacing: window.s(10)
//                         rowSpacing: window.s(10)

//                         Repeater {
//                             model: window.resList

//                             delegate: Rectangle {
//                                 property var modelData: window.resList[index]
//                                 Layout.fillWidth: true
//                                 Layout.preferredHeight: window.s(45)
//                                 radius: window.s(12)
                                
//                                 property bool isSel: {
//                                     if (monitorsModel.count === 0) return false;
//                                     let activeMon = monitorsModel.get(window.activeEditIndex);
//                                     return activeMon.resW === modelData.w && activeMon.resH === modelData.h;
//                                 }
//                                 property color accentColor: modelData.accent
                                
//                                 color: isSel ? Qt.alpha(accentColor, 0.15) : (resMa.containsMouse ? window.surface0 : window.mantle)
//                                 border.color: isSel ? accentColor : (resMa.containsMouse ? window.surface1 : "transparent")
//                                 border.width: isSel ? 2 : 1
                                
//                                 Behavior on color { ColorAnimation { duration: 200 } }
//                                 Behavior on border.color { ColorAnimation { duration: 200 } }

//                                 RowLayout {
//                                     anchors.fill: parent
//                                     anchors.margins: window.s(12)
//                                     spacing: window.s(8)
                                    
//                                     Text { 
//                                         font.family: "JetBrains Mono"
//                                         font.weight: isSel ? Font.Black : Font.Bold
//                                         font.pixelSize: window.s(15)
//                                         color: isSel ? accentColor : window.text
//                                         text: modelData.l
//                                         Behavior on color { ColorAnimation { duration: 200 } } 
//                                     }
                                    
//                                     Item { Layout.fillWidth: true } 
                                    
//                                     Text { 
//                                         font.family: "JetBrains Mono"
//                                         font.pixelSize: window.s(11)
//                                         color: isSel ? window.text : window.overlay0
//                                         text: modelData.w + "x" + modelData.h
//                                         Behavior on color { ColorAnimation { duration: 200 } } 
//                                     }
//                                 }

//                                 scale: resMa.pressed ? 0.96 : 1.0
//                                 Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }

//                                 MouseArea {
//                                     id: resMa
//                                     anchors.fill: parent
//                                     hoverEnabled: true
//                                     cursorShape: Qt.PointingHandCursor
//                                     onClicked: {
//                                         window.activeFocusIndex = 0;
//                                         if (monitorsModel.count > 0) {
//                                             window.selectedResAccent = accentColor;
//                                             monitorsModel.setProperty(window.activeEditIndex, "resW", modelData.w);
//                                             monitorsModel.setProperty(window.activeEditIndex, "resH", modelData.h);
//                                             delayedLayoutUpdate.restart();
//                                         }
//                                     }
//                                 }
//                             }
//                         }
//                     }

//                     Item { Layout.preferredHeight: window.s(2) } 

//                     // --- ROTATION DIAL (CLOCK-STYLE) SECTION ---
//                     RowLayout {
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: window.s(120)
                        
//                         Item { Layout.fillWidth: true }

//                         Rectangle {
//                             id: clockDial
//                             // Use Layout properties instead of standard width/height to prevent 
//                             // the layout engine from breaking your dimensions during resize
//                             Layout.preferredWidth: window.s(120)
//                             Layout.preferredHeight: window.s(120)
//                             Layout.alignment: Qt.AlignCenter
                            
//                             radius: width / 2
//                             color: window.surface0 
                            
//                             border.color: window.activeFocusIndex === 1 ? window.selectedResAccent : window.surface1 
//                             border.width: window.activeFocusIndex === 1 ? window.s(3) : window.s(2)
//                             Behavior on border.color { ColorAnimation { duration: 200 } }
//                             Behavior on border.width { NumberAnimation { duration: 200 } }

//                             // 12-Hour Clock Tick Marks
//                             Repeater {
//                                 model: 12
//                                 Item {
//                                     anchors.fill: parent
//                                     rotation: index * 30
//                                     Rectangle {
//                                         width: index % 3 === 0 ? window.s(4) : window.s(2)
//                                         height: index % 3 === 0 ? window.s(8) : window.s(4)
//                                         radius: width / 2
//                                         color: index % 3 === 0 ? window.subtext0 : window.surface2 
//                                         anchors.top: parent.top
//                                         anchors.topMargin: window.s(4)
//                                         anchors.horizontalCenter: parent.horizontalCenter
//                                     }
//                                 }
//                             }

//                             // The Interactive Pointer
//                             Item {
//                                 id: dialPointer
//                                 anchors.fill: parent
//                                 property int activeTransform: monitorsModel.count > 0 ? monitorsModel.get(window.activeEditIndex).transform : 0
//                                 rotation: activeTransform * 90
//                                 Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutBack;} }

//                                 // Pointer Line
//                                 Rectangle {
//                                     width: window.s(5)
//                                     height: parent.height / 2 - window.s(20)
//                                     radius: window.s(2.5)
//                                     color: window.selectedResAccent
//                                     anchors.bottom: parent.verticalCenter
//                                     anchors.horizontalCenter: parent.horizontalCenter
//                                     Behavior on color { ColorAnimation { duration: 300 } }
//                                 }
                                
//                                 // Center Dot
//                                 Rectangle {
//                                     width: window.s(18)
//                                     height: window.s(18) // Replaced height: width binding
//                                     radius: width / 2
//                                     color: window.base
//                                     border.color: window.selectedResAccent
//                                     border.width: window.s(4)
//                                     anchors.centerIn: parent
//                                     Behavior on border.color { ColorAnimation { duration: 300 } }
//                                 }
//                             }

//                             MouseArea {
//                                 id: dialMa
//                                 anchors.fill: parent
//                                 hoverEnabled: true
//                                 cursorShape: Qt.PointingHandCursor

//                                 function updateAngle(mouse) {
//                                     if (monitorsModel.count === 0) return;
//                                     window.activeFocusIndex = 1;
                                    
//                                     let dx = mouse.x - width / 2;
//                                     let dy = mouse.y - height / 2;

//                                     if (Math.hypot(dx, dy) < window.s(20)) return;

//                                     let snap = 0;
//                                     if (Math.abs(dx) > Math.abs(dy)) {
//                                         snap = dx > 0 ? 1 : 3;
//                                     } else {
//                                         snap = dy > 0 ? 2 : 0;
//                                     }
                                    
//                                     monitorsModel.setProperty(window.activeEditIndex, "transform", snap);
//                                     delayedLayoutUpdate.restart();
//                                 }

//                                 onPressed: (mouse) => updateAngle(mouse)
//                                 onPositionChanged: (mouse) => { if (pressed) updateAngle(mouse) }
//                             }
//                         }

//                         Item { Layout.fillWidth: true }
//                     }                    Item { Layout.preferredHeight: window.s(2) }

//                     // --- REFRESH RATE SLIDER SECTION ---
//                     Item {
//                         id: sliderContainer
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: window.s(45)
//                         Layout.leftMargin: window.s(6)
//                         Layout.rightMargin: window.s(6)
                        
//                         property var rates: [60, 75, 100, 120, 144, 165, 180, 240, 360]
//                         property var rateColors: [window.red, window.mauve, window.blue, window.sapphire, window.teal, window.pink, window.yellow, window.green, window.peach]
                        
//                         property int currentIndex: {
//                             if (monitorsModel.count === 0) return 0;
//                             let currentVal = parseInt(monitorsModel.get(window.activeEditIndex).rate) || 60;
//                             let closestIdx = 0;
//                             let minDiff = 9999;
//                             for (let i = 0; i < rates.length; i++) {
//                                 let diff = Math.abs(rates[i] - currentVal);
//                                 if (diff < minDiff) { 
//                                     minDiff = diff; 
//                                     closestIdx = i; 
//                                 }
//                             }
//                             return closestIdx;
//                         }

//                         property real visualPct: currentIndex / (rates.length - 1)

//                         onCurrentIndexChanged: { 
//                             if (!sliderMa.pressed) visualPct = currentIndex / (rates.length - 1); 
//                         }
                        
//                         function updateSelectionVisual(idx) {
//                             if (monitorsModel.count === 0) return;
//                             visualPct = idx / (rates.length - 1);
//                             monitorsModel.setProperty(window.activeEditIndex, "rate", rates[idx].toString());
//                             window.selectedRateAccent = rateColors[idx];
//                         }

//                         Rectangle {
//                             id: track
//                             anchors.left: parent.left
//                             anchors.right: parent.right
//                             anchors.leftMargin: window.s(15)
//                             anchors.rightMargin: window.s(15)
//                             anchors.verticalCenter: parent.verticalCenter
//                             anchors.verticalCenterOffset: window.s(-10)
//                             height: window.s(12)
//                             radius: window.s(6)
//                             color: window.mantle
//                             border.color: window.crust
//                             border.width: 1
                            
//                             Rectangle { 
//                                 id: trackFill
//                                 width: Math.max(0, knob.x + knob.width / 2)
//                                 height: parent.height
//                                 radius: parent.radius
//                                 color: window.selectedRateAccent
//                                 Behavior on color { ColorAnimation { duration: 200 } } 
//                             }

//                             Rectangle {
//                                 id: knob
//                                 width: window.s(24)
//                                 height: window.s(24)
//                                 radius: window.s(12)
//                                 color: sliderMa.containsPress ? window.selectedRateAccent : window.text
//                                 anchors.verticalCenter: parent.verticalCenter
//                                 x: (sliderContainer.visualPct * parent.width) - width / 2
                                
//                                 Behavior on x { 
//                                     enabled: !sliderMa.pressed
//                                     NumberAnimation { duration: 250; easing.type: Easing.OutCubic } 
//                                 }
//                                 Behavior on color { ColorAnimation { duration: 150 } }
                                
//                                 border.width: (sliderMa.containsMouse || window.activeFocusIndex === 2) ? window.s(4) : 0
//                                 border.color: Qt.alpha(window.selectedRateAccent, 0.4)
//                                 Behavior on border.width { NumberAnimation { duration: 150 } }
//                             }
//                         }

//                         Repeater {
//                             model: sliderContainer.rates.length
//                             Item {
//                                 x: track.x + (index / (sliderContainer.rates.length - 1)) * track.width
//                                 y: track.y + window.s(20)
                                
//                                 Text { 
//                                     anchors.horizontalCenter: parent.horizontalCenter
//                                     text: sliderContainer.rates[index]
//                                     font.family: "JetBrains Mono"
//                                     font.pixelSize: window.s(13)
//                                     font.weight: sliderContainer.currentIndex === index ? Font.Bold : Font.Normal
//                                     color: sliderContainer.currentIndex === index ? window.selectedRateAccent : window.overlay0
//                                     Behavior on color { ColorAnimation { duration: 200 } } 
//                                 }
//                             }
//                         }

//                         MouseArea {
//                             id: sliderMa
//                             anchors.fill: parent
//                             hoverEnabled: true
//                             cursorShape: Qt.PointingHandCursor

//                             function updateSelection(mouseX, snapToGrid) {
//                                 if (monitorsModel.count === 0) return;
//                                 window.activeFocusIndex = 2;
                                
//                                 let pct = (mouseX - track.x) / track.width;
//                                 pct = Math.max(0, Math.min(1, pct));
//                                 let idx = Math.round(pct * (sliderContainer.rates.length - 1));
                                
//                                 if (snapToGrid) {
//                                     sliderContainer.visualPct = idx / (sliderContainer.rates.length - 1);
//                                 } else {
//                                     sliderContainer.visualPct = pct;
//                                 }

//                                 monitorsModel.setProperty(window.activeEditIndex, "rate", sliderContainer.rates[idx].toString());
//                                 window.selectedRateAccent = sliderContainer.rateColors[idx];
//                             }

//                             onPressed: (mouse) => updateSelection(mouse.x, false)
//                             onPositionChanged: (mouse) => { if (pressed) updateSelection(mouse.x, false) }
//                             onReleased: (mouse) => updateSelection(mouse.x, true)
//                             onCanceled: () => sliderContainer.visualPct = sliderContainer.currentIndex / (sliderContainer.rates.length - 1)
//                         }
//                     }

//                     Item { Layout.preferredHeight: window.s(15) } 

//                     // ==========================================
//                     // FLOATING APPLY BUTTON 
//                     // ==========================================
//                     Item {
//                         id: applyButtonContainer
//                         Layout.alignment: Qt.AlignRight
//                         Layout.preferredWidth: window.s(170)
//                         Layout.preferredHeight: window.s(50)

//                         MultiEffect {
//                             source: applyBtn
//                             anchors.fill: applyBtn
//                             shadowEnabled: true
//                             shadowColor: window.selectedRateAccent
//                             shadowBlur: window.applyHovered || window.activeFocusIndex === 3 ? 1.2 : 0.6
//                             shadowOpacity: window.applyHovered || window.activeFocusIndex === 3 ? 0.6 : 0.2
//                             shadowVerticalOffset: window.s(4)
//                             z: -1
//                             Behavior on shadowBlur { NumberAnimation { duration: 300 } } 
//                             Behavior on shadowOpacity { NumberAnimation { duration: 300 } } 
//                             Behavior on shadowColor { ColorAnimation { duration: 400 } }
//                         }

//                         Rectangle {
//                             id: applyBtn
//                             anchors.fill: parent
//                             radius: window.s(25)
                            
//                             gradient: Gradient { 
//                                 orientation: Gradient.Horizontal
//                                 GradientStop { 
//                                     position: 0.0
//                                     color: window.selectedResAccent
//                                     Behavior on color { ColorAnimation { duration: 400 } } 
//                                 } 
//                                 GradientStop { 
//                                     position: 1.0
//                                     color: window.selectedRateAccent
//                                     Behavior on color { ColorAnimation { duration: 400 } } 
//                                 } 
//                             }
                            
//                             border.color: window.activeFocusIndex === 3 ? window.crust : "transparent"
//                             border.width: window.activeFocusIndex === 3 ? window.s(2) : 0
                            
//                             scale: window.applyPressed ? 0.94 : (window.applyHovered || window.activeFocusIndex === 3 ? 1.04 : 1.0)
//                             Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

//                             Rectangle {
//                                 id: flashRect
//                                 anchors.fill: parent
//                                 radius: window.s(25)
//                                 color: window.text
//                                 opacity: 0.0
//                                 PropertyAnimation on opacity { 
//                                     id: applyFlashAnim
//                                     to: 0.0
//                                     duration: 400
//                                     easing.type: Easing.OutExpo 
//                                 }
//                             }

//                             RowLayout {
//                                 anchors.centerIn: parent
//                                 spacing: window.s(8)
                                
//                                 Text { 
//                                     font.family: "Iosevka Nerd Font"
//                                     font.pixelSize: window.s(20)
//                                     color: window.crust
//                                     text: "󰸵" 
//                                 }
                                
//                                 Text { 
//                                     font.family: "JetBrains Mono"
//                                     font.weight: Font.Black
//                                     font.pixelSize: window.s(14)
//                                     color: window.crust
//                                     text: monitorsModel.count > 1 ? "Apply All" : "Apply" 
//                                 }
//                             }
//                         }

//                         MouseArea {
//                             id: applyMa
//                             anchors.fill: parent
//                             z: 10
//                             hoverEnabled: true
//                             cursorShape: Qt.PointingHandCursor
                            
//                             onEntered: { window.applyHovered = true; window.activeFocusIndex = 3; }
//                             onExited: window.applyHovered = false
//                             onPressed: window.applyPressed = true
//                             onReleased: window.applyPressed = false
//                             onCanceled: window.applyPressed = false

//                             onClicked: window.triggerApply()
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }

import QtQuick                                                                    // Imports the QtQuick module which provides basic QML types for creating user interfaces (Item, Rectangle, Text, etc.)
import QtQuick.Layouts                                                            // Imports QtQuick.Layouts module providing RowLayout, ColumnLayout, GridLayout for automatic positioning of child items
import QtQuick.Effects                                                            // Imports QtQuick.Effects module for graphical effects, specifically used here for the MultiEffect shadow on the apply button
import Quickshell                                                                 // Imports the Quickshell module - the core shell framework that provides Process, execDetached, env, and shell integration features
import Quickshell.Io                                                              // Imports Quickshell's I/O module providing StdioCollector for capturing process standard output streams
import "../"                                                                      // Imports the parent directory's QML components, giving access to Scaler.qml and MatugenColors.qml

Item {                                                                            // Root item of this Monitor configuration popup component
    id: window                                                                    // Assigns the id "window" to this root Item for referencing by child elements
    focus: true                                                                   // Ensures this Item receives keyboard focus when visible, enabling keyboard navigation

    // --- Responsive Scaling Logic ---                                            // Comment block indicating the following code handles resolution-independent sizing
    Scaler {                                                                      // Creates an instance of the Scaler component (defined in Scaler.qml) for converting design units to pixels based on screen resolution
        id: scaler                                                                // Assigns id "scaler" for calling its methods
        currentWidth: Screen.width                                                // Passes the current screen width in pixels so the Scaler can calculate appropriate scaling factors
    }
    
    // Helper function scoped to the root Item                                     // Comment: convenience function for scaled values
    function s(val) {                                                            // Defines function s() that converts design-unit values to actual pixel values
        return scaler.s(val);                                                     // Delegates to the Scaler component's s() method
    }

    // Custom File Logger                                                          // Comment: debugging utility function
    function debugLog(msg) {                                                     // JavaScript function that appends a debug message to a log file
        let safeMsg = msg.replace(/'/g, "'\\''");                                // Escapes single quotes in the message by replacing them with the shell-safe sequence '\'' to prevent command injection
        Quickshell.execDetached(["sh", "-c", "echo '" + safeMsg + "' >> /tmp/monitor_popup.log"]);  // Runs a detached shell command that echoes the safe message and appends it to the debug log file
    }
    
    // -------------------------------------------------------------------------
    // COLORS (Dynamic Matugen Palette)                                           // Comment block: exposes the dynamic color scheme from matugen
    // -------------------------------------------------------------------------
    MatugenColors { id: _theme }                                                  // Creates an instance of MatugenColors (from MatugenColors.qml) that reads the current system color scheme
    readonly property color base: _theme.base                                     // Read-only property for the base background color
    readonly property color mantle: _theme.mantle                                 // Read-only property for the mantle color - slightly darker than base
    readonly property color crust: _theme.crust                                   // Read-only property for the crust color - darkest surface color
    readonly property color text: _theme.text                                     // Read-only property for primary text color
    readonly property color subtext0: _theme.subtext0                            // Read-only property for secondary/subdued text
    readonly property color overlay0: _theme.overlay0                            // Read-only property for dimmest overlay text
    readonly property color surface0: _theme.surface0                            // Read-only property for lowest elevated surface color
    readonly property color surface1: _theme.surface1                            // Read-only property for medium surface color
    readonly property color surface2: _theme.surface2                            // Read-only property for highest surface color
    
    readonly property color mauve: _theme.mauve                                    // Read-only accent color: mauve (purple-pink)
    readonly property color blue: _theme.blue                                      // Read-only accent color: blue
    readonly property color pink: _theme.pink                                      // Read-only accent color: pink
    readonly property color teal: _theme.teal                                      // Read-only accent color: teal
    readonly property color yellow: _theme.yellow                                  // Read-only accent color: yellow
    readonly property color peach: _theme.peach                                    // Read-only accent color: peach (warm orange)
    readonly property color green: _theme.green                                    // Read-only accent color: green
    readonly property color red: _theme.red                                        // Read-only accent color: red
    readonly property color sapphire: _theme.sapphire                              // Read-only accent color: sapphire

    // -------------------------------------------------------------------------
    // STATE & MATH                                                                // Comment block: properties for UI state management
    // -------------------------------------------------------------------------
    property int activeEditIndex: 0                                                // Index of the currently selected/active monitor in the monitorsModel for editing
    property int activeFocusIndex: 0 // 0: Res, 1: Clock, 2: Frame, 3: Apply     // Tracks which UI section has keyboard focus: 0=Resolution grid, 1=Rotation dial, 2=Refresh rate slider, 3=Apply button
    property real uiScale: 0.10                                                    // Scale factor for converting real monitor coordinates to the virtual canvas representation; 0.10 means 10% of real size
    
    // Wayland Absolute Anchor tracking                                             // Comment: stores the original layout origin for coordinate normalization
    property int originalLayoutOriginX: 0                                          // X-coordinate of the top-left-most monitor in the original layout, used to normalize coordinates
    property int originalLayoutOriginY: 0                                          // Y-coordinate of the top-left-most monitor in the original layout

    ListModel {                                                                     // Creates a ListModel to hold the data for each connected monitor
        id: monitorsModel                                                           // Assigns id "monitorsModel" for referencing throughout the component
    }
    
    property var resList: [                                                         // Array of predefined resolution options, each with width, height, a short label, and an associated accent color
        {w: 3840, h: 2160, l: "4K",   accent: window.pink},                        // 4K UHD resolution option
        {w: 2560, h: 1440, l: "QHD",  accent: window.mauve},                       // QHD (1440p) resolution option
        {w: 1920, h: 1080, l: "FHD",  accent: window.blue},                        // Full HD (1080p) resolution option - default
        {w: 1600, h: 900,  l: "HD+",  accent: window.teal},                        // HD+ (900p) resolution option
        {w: 1366, h: 768,  l: "WXGA", accent: window.yellow},                      // WXGA (768p laptop) resolution option
        {w: 1280, h: 720,  l: "HD",   accent: window.peach},                       // HD (720p) resolution option
        {w: 1024, h: 768,  l: "XGA",  accent: window.green},                       // XGA (1024x768) resolution option
        {w: 800,  h: 600,  l: "SVGA", accent: window.red}                          // SVGA (800x600) resolution option
    ]

    property color selectedResAccent: window.mauve                                  // Accent color reflecting the currently selected resolution; defaults to mauve
    property color selectedRateAccent: window.blue                                  // Accent color reflecting the currently selected refresh rate; defaults to blue

    property int currentTransform: monitorsModel.count > 0 ? monitorsModel.get(window.activeEditIndex).transform : 0  // Gets the transform (rotation) value of the active monitor; 0=normal, 1=90°, 2=180°, 3=270°
    property bool currentIsPortrait: currentTransform === 1 || currentTransform === 3  // Boolean: true if the monitor is in portrait orientation (90° or 270° rotation)

    property real currentSimW: {                                                     // Calculates the simulated width based on resolution and rotation state
        if (monitorsModel.count === 0) return 1920;                                  // Default width if no monitors are loaded
        let mon = monitorsModel.get(window.activeEditIndex);                          // Gets the active monitor's data
        return currentIsPortrait ? mon.resH : mon.resW;                              // If portrait, width becomes the vertical resolution; otherwise uses horizontal resolution
    }
    property real currentSimH: {                                                     // Calculates the simulated height based on resolution and rotation state
        if (monitorsModel.count === 0) return 1080;                                  // Default height if no monitors
        let mon = monitorsModel.get(window.activeEditIndex);                          // Gets active monitor data
        return currentIsPortrait ? mon.resW : mon.resH;                              // If portrait, height becomes the horizontal resolution; otherwise uses vertical resolution
    }

    property real globalOrbitAngle: 0                                                // Tracks the animation angle for decorative floating background orbs
    NumberAnimation on globalOrbitAngle {                                            // Attaches a continuous animation to the orbit angle
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true  // Rotates from 0 to 2π over 90 seconds, looping infinitely
    }
    
    // -------------------------------------------------------------------------
    // KEYBOARD NAVIGATION LOGIC                                                   // Comment block: keyboard event handling for full keyboard accessibility
    // -------------------------------------------------------------------------
    Keys.onPressed: (event) => {                                                     // Handler for when any key is pressed while this Item has focus
        if (event.key === Qt.Key_Tab) {                                              // If the Tab key is pressed
            if (event.modifiers & Qt.ControlModifier) {                               // AND the Ctrl modifier is held down
                if (monitorsModel.count > 1) {                                        // AND there are multiple monitors
                    window.activeEditIndex = (window.activeEditIndex + 1) % monitorsModel.count;  // Cycles to the next monitor (wraps around using modulo)
                }
            } else {                                                                   // If Tab is pressed without Ctrl
                window.activeFocusIndex = (window.activeFocusIndex + 1) % 4;          // Cycles focus through the 4 UI sections (Res, Clock, Frame, Apply)
            }
            event.accepted = true;                                                     // Marks the event as handled to prevent default behavior
        } else if (event.key === Qt.Key_Backtab) {                                   // If Shift+Tab is pressed (Backtab)
            if (event.modifiers & Qt.ControlModifier) {                               // With Ctrl held
                if (monitorsModel.count > 1) {                                        // Multiple monitors
                    window.activeEditIndex = (window.activeEditIndex - 1 + monitorsModel.count) % monitorsModel.count;  // Cycles to the previous monitor (wraps around)
                }
            } else {                                                                   // Without Ctrl
                window.activeFocusIndex = (window.activeFocusIndex - 1 + 4) % 4;     // Cycles focus backward through the 4 UI sections
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {                                      // Left arrow key
            handleArrowKey("Left"); event.accepted = true;                             // Calls the arrow key handler with "Left" direction
        } else if (event.key === Qt.Key_Right) {                                     // Right arrow key
            handleArrowKey("Right"); event.accepted = true;                            // Calls handler with "Right"
        } else if (event.key === Qt.Key_Up) {                                        // Up arrow key
            handleArrowKey("Up"); event.accepted = true;                               // Calls handler with "Up"
        } else if (event.key === Qt.Key_Down) {                                      // Down arrow key
            handleArrowKey("Down"); event.accepted = true;                             // Calls handler with "Down"
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {     // Enter/Return key
            if (activeFocusIndex === 3) {                                             // If the Apply button has focus
                window.applyPressed = true;                                            // Sets pressed state to true for visual feedback
                window.triggerApply();                                                 // Triggers the apply function to save and execute the new monitor configuration
            }
            event.accepted = true;
        }
    }
    
    Keys.onReleased: (event) => {                                                    // Handler for when a key is released
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {           // If Enter/Return is released
            window.applyPressed = false;                                              // Resets the apply button pressed state
        }
    }

    function handleArrowKey(dir) {                                                   // Function that processes arrow key navigation based on current focus
        if (monitorsModel.count === 0) return;                                        // Exits if no monitors are loaded
        
        if (activeFocusIndex === 0) {                                                 // If resolution grid has focus
            let activeMon = monitorsModel.get(window.activeEditIndex);                 // Gets the active monitor's data
            let idx = 2; // Default FHD                                                // Default resolution index (FHD/1080p)
            for (let i = 0; i < window.resList.length; i++) {                          // Searches for the current resolution in the resList
                if (window.resList[i].w === activeMon.resW && window.resList[i].h === activeMon.resH) {  // If this entry matches the current resolution
                    idx = i; break;                                                      // Sets idx to the found index and stops searching
                }
            }
            
            if (dir === "Left" && idx % 2 !== 0) idx--;                              // Left arrow on an odd column (right column): moves left in the same row
            else if (dir === "Right" && idx % 2 === 0 && idx < 7) idx++;             // Right arrow on an even column (left column) and not at the end: moves right
            else if (dir === "Up" && idx >= 2) idx -= 2;                              // Up arrow: moves up one row (2 columns per row)
            else if (dir === "Down" && idx <= 5) idx += 2;                            // Down arrow: moves down one row

            window.selectedResAccent = window.resList[idx].accent;                    // Updates the accent color to match the newly selected resolution
            monitorsModel.setProperty(window.activeEditIndex, "resW", window.resList[idx].w);  // Updates the monitor's width in the model
            monitorsModel.setProperty(window.activeEditIndex, "resH", window.resList[idx].h);  // Updates the monitor's height
            delayedLayoutUpdate.restart();                                            // Triggers a delayed recalculation of the multi-monitor layout
            
        } else if (activeFocusIndex === 1) {                                          // If rotation dial has focus
            let t = monitorsModel.get(window.activeEditIndex).transform;               // Gets the current transform/rotation value
            if (dir === "Up") t = 0;                                                   // Up arrow: normal orientation (0°)
            else if (dir === "Right") t = 1;                                          // Right arrow: 90° clockwise
            else if (dir === "Down") t = 2;                                            // Down arrow: 180° (inverted)
            else if (dir === "Left") t = 3;                                           // Left arrow: 270° (90° counter-clockwise)
            monitorsModel.setProperty(window.activeEditIndex, "transform", t);        // Updates the monitor's transform value in the model
            delayedLayoutUpdate.restart();                                            // Triggers layout recalculation
            
        } else if (activeFocusIndex === 2) {                                          // If refresh rate slider has focus
            let cIdx = sliderContainer.currentIndex;                                  // Gets the current slider index
            if (dir === "Left" && cIdx > 0) cIdx--;                                   // Left: decreases rate if not at minimum
            else if (dir === "Right" && cIdx < sliderContainer.rates.length - 1) cIdx++;  // Right: increases rate if not at maximum
            sliderContainer.updateSelectionVisual(cIdx);                              // Updates the slider visual and applies the new rate
        }
    }

    // -------------------------------------------------------------------------
    // FLUID STARTUP ANIMATIONS                                                    // Comment block: entrance animation properties
    // -------------------------------------------------------------------------
    property real introProgress: 0.0                                                 // Overall intro animation progress from 0 (start) to 1 (complete)
    property real monitorScale: 0.85                                                 // Starting scale of the monitor visual (85% to 100%)
    property real uiYOffset: window.s(25)                                            // Starting vertical offset for the UI controls (slides up into place)
    property real screenLight: 0.0                                                   // Opacity of the screen light overlay effect on the monitor visual

    Component.onCompleted: startupAnim.start()                                      // When the component finishes loading, starts the entrance animation

    ParallelAnimation {                                                              // ParallelAnimation runs multiple animations simultaneously
        id: startupAnim                                                              // Assigns id "startupAnim" for starting from onCompleted
        NumberAnimation { target: window; property: "introProgress"; from: 0.0; to: 1.0; duration: 900; easing.type: Easing.OutQuint }  // Fades/scales main content in over 900ms
        NumberAnimation { target: window; property: "monitorScale"; from: 0.85; to: 1.0; duration: 1200; easing.type: Easing.OutQuint }  // Monitor visual scales from 85% to 100% over 1.2 seconds
        NumberAnimation { target: window; property: "uiYOffset"; from: window.s(25); to: 0; duration: 1800; easing.type: Easing.OutQuint }  // UI controls slide up from 25 units offset over 1.8 seconds
        NumberAnimation { target: window; property: "screenLight"; from: 0.0; to: 1.0; duration: 1500; easing.type: Easing.InOutQuad }  // Screen light overlay fades in over 1.5 seconds
    }
    property bool applyHovered: false                                                // Boolean tracking whether the mouse is hovering over the Apply button
    property bool applyPressed: false                                                // Boolean tracking whether the Apply button is being pressed

    onActiveEditIndexChanged: {                                                      // Signal handler triggered when the active monitor being edited changes
        menuTransitionAnim.restart();                                                // Restarts the subtle scale/flash animation on the settings panel
    }

    // -------------------------------------------------------------------------
    // MATHEMATICAL PERIMETER GLUE (Virtual Coordinates - Do not scale)             // Comment block: collision detection and snap-to-edge logic for multi-monitor layout
    // -------------------------------------------------------------------------
    function isOverlapping(ax, ay, aw, ah, bx, by, bw, bh) {                        // Checks if two rectangles (a and b) overlap/collide
        return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by;        // Standard axis-aligned bounding box (AABB) overlap test: returns true if rectangles intersect
    }

    function isOverlappingAny(x, y, w, h, skipIdx) {                                // Checks if a rectangle overlaps any monitor except the one at skipIdx
        for (let i = 0; i < monitorsModel.count; i++) {                             // Iterates through all monitors
            if (i === skipIdx) continue;                                              // Skips the monitor being checked against itself
            let m = monitorsModel.get(i);                                             // Gets the monitor data
            let isP = m.transform === 1 || m.transform === 3;                         // Checks if this monitor is in portrait
            let mW = ((isP ? m.resH : m.resW) / m.sysScale) * window.uiScale;        // Calculates the virtual width considering portrait swap and scaling
            let mH = ((isP ? m.resW : m.resH) / m.sysScale) * window.uiScale;        // Calculates virtual height
            if (isOverlapping(x, y, w, h, m.uiX, m.uiY, mW, mH)) return true;       // If they overlap, return true immediately
        }
        return false;                                                                  // No overlaps found
    }

    function getPerimeterSnap(pX, pY, sX, sY, sW, sH, mW, mH, snapT) {             // Calculates the closest perimeter snap position for a monitor (m) against a source monitor (s)
        let edges = [                                                                // Defines the four perimeter edges of the source monitor where snapping can occur
            { x1: sX - mW, x2: sX + sW, y1: sY - mH, y2: sY - mH }, // Top Edge    // Top edge: positioned so the moving monitor sits above the source
            { x1: sX - mW, x2: sX + sW, y1: sY + sH, y2: sY + sH }, // Bottom Edge // Bottom edge: positioned below the source
            { x1: sX - mW, x2: sX - mW, y1: sY - mH, y2: sY + sH }, // Left Edge   // Left edge: positioned to the left of the source
            { x1: sX + sW, x2: sX + sW, y1: sY - mH, y2: sY + sH }  // Right Edge  // Right edge: positioned to the right of the source
        ];

        let bestX = pX;                                                              // Initializes best position with the current position
        let bestY = pY;
        let minDist = 999999;                                                        // Initializes minimum distance to a very large number

        for (let i = 0; i < 4; i++) {                                               // Iterates through the 4 edges
            let e = edges[i];                                                         // Gets the current edge definition
            
            let cx = Math.max(e.x1, Math.min(pX, e.x2));                              // Clamps the x-coordinate to the edge's x-range (closest point on edge segment)
            let cy = Math.max(e.y1, Math.min(pY, e.y2));                              // Clamps the y-coordinate to the edge's y-range

            if (Math.abs(cx - sX) < snapT) cx = sX;                                  // Snaps to left-align with the source monitor if within threshold
            if (Math.abs(cx - (sX + sW - mW)) < snapT) cx = sX + sW - mW;           // Snaps to right-align with the source
            if (Math.abs(cx - (sX + sW/2 - mW/2)) < snapT) cx = sX + sW/2 - mW/2;  // Snaps to center-align with the source
            
            if (Math.abs(cy - sY) < snapT) cy = sY;                                  // Snaps to top-align with the source
            if (Math.abs(cy - (sY + sH - mH)) < snapT) cy = sY + sH - mH;           // Snaps to bottom-align with the source
            if (Math.abs(cy - (sY + sH/2 - mH/2)) < snapT) cy = sY + sH/2 - mH/2;  // Snaps to middle-align with the source

            let dist = Math.hypot(pX - cx, pY - cy);                                  // Calculates Euclidean distance from original position to this snap point
            if (dist < minDist) {                                                      // If this is closer than any previously found point
                minDist = dist;                                                        // Updates minimum distance
                bestX = cx;                                                            // Updates best X coordinate
                bestY = cy;                                                            // Updates best Y coordinate
            }
        }
        return { x: bestX, y: bestY };                                                // Returns the best snap position found
    }

    function forceLayoutUpdate() {                                                    // Forces the active monitor to snap to the nearest perimeter of any other monitor
        if (monitorsModel.count < 2) return;                                          // Only relevant when there are 2+ monitors
        
        let mIdx = window.activeEditIndex;                                            // Gets the index of the monitor being edited
        let mModel = monitorsModel.get(mIdx);                                         // Gets its data
        let isP = mModel.transform === 1 || mModel.transform === 3;                   // Checks portrait orientation
        let mW = ((isP ? mModel.resH : mModel.resW) / mModel.sysScale) * window.uiScale;  // Calculates virtual width
        let mH = ((isP ? mModel.resW : mModel.resH) / mModel.sysScale) * window.uiScale;  // Calculates virtual height

        let bestX = mModel.uiX;                                                        // Initializes best position to current position
        let bestY = mModel.uiY;
        let bestDist = 999999;                                                         // Large initial distance

        for (let i = 0; i < monitorsModel.count; i++) {                               // Iterates through all other monitors
            if (i === mIdx) continue;                                                   // Skips the monitor being moved
            let sModel = monitorsModel.get(i);                                          // Gets the source monitor data
            let sIsP = sModel.transform === 1 || sModel.transform === 3;                // Checks its portrait orientation
            let sW = ((sIsP ? sModel.resH : sModel.resW) / sModel.sysScale) * window.uiScale;  // Source virtual width
            let sH = ((sIsP ? sModel.resW : sModel.resH) / sModel.sysScale) * window.uiScale;  // Source virtual height
            
            let snapped = window.getPerimeterSnap(                                      // Calculates the best snap position against this source
                mModel.uiX, mModel.uiY,
                sModel.uiX, sModel.uiY,
                sW, sH, mW, mH, 20                                                     // Snap threshold of 20 virtual units
            );
            
            let dist = Math.hypot(snapped.x - mModel.uiX, snapped.y - mModel.uiY);    // Calculates distance from original position to this snap point
            if (dist < bestDist) {                                                       // If this is the closest source so far
                bestDist = dist;                                                         // Updates best distance
                bestX = snapped.x;                                                       // Updates best X
                bestY = snapped.y;                                                       // Updates best Y
            }
        }

        monitorsModel.setProperty(mIdx, "uiX", bestX);                                 // Applies the best snap X coordinate to the model
        monitorsModel.setProperty(mIdx, "uiY", bestY);                                 // Applies the best snap Y coordinate to the model
    }

    Timer {                                                                           // Timer for debouncing layout updates
        id: delayedLayoutUpdate                                                       // Assigns id "delayedLayoutUpdate"
        interval: 10                                                                  // 10 millisecond delay
        running: false                                                                // Not running initially
        repeat: false                                                                 // Single-shot
        onTriggered: window.forceLayoutUpdate()                                       // When triggered, calls the layout update function
    }

    // -------------------------------------------------------------------------
    // NATIVE SYSTEM PROCESSES                                                     // Comment block: process for fetching monitor data from Hyprland
    // -------------------------------------------------------------------------
    Process {                                                                        // Creates a Quickshell Process to query Hyprland for monitor information
        id: displayPoller                                                            // Assigns id "displayPoller"
        command: ["hyprctl", "monitors", "-j"]                                       // Runs 'hyprctl monitors -j' to get all monitor info in JSON format
        running: true                                                                // Starts the process immediately on component load
        stdout: StdioCollector {                                                     // Captures the process standard output
            onStreamFinished: {                                                       // Triggered when the process completes and output is collected
                try {                                                                  // Try block for JSON parsing
                    let data = JSON.parse(this.text.trim());                             // Parses the JSON output into a JavaScript array of monitor objects
                    monitorsModel.clear();                                              // Clears the existing model before repopulating
                    
                    let minX = 999999, minY = 999999;                                   // Initializes to find the top-left-most monitor coordinate

                    for (let i = 0; i < data.length; i++) {                            // First pass: find the minimum x and y coordinates
                        if (data[i].x < minX) minX = data[i].x;                         // Updates minX if this monitor's x is smaller
                        if (data[i].y < minY) minY = data[i].y;                         // Updates minY if this monitor's y is smaller
                    }

                    window.originalLayoutOriginX = minX !== 999999 ? minX : 0;        // Stores the origin X (0 if no monitors found)
                    window.originalLayoutOriginY = minY !== 999999 ? minY : 0;        // Stores the origin Y

                    for (let i = 0; i < data.length; i++) {                            // Second pass: populate the model with normalized coordinates
                        let scl = data[i].scale !== undefined ? data[i].scale : 1.0;    // Gets the monitor scale factor, defaults to 1.0
                        let tf = data[i].transform !== undefined ? data[i].transform : 0;  // Gets the rotation transform, defaults to 0 (normal)
                        let normalizedX = (data[i].x - minX) * window.uiScale;         // Normalizes x coordinate relative to origin, then applies virtual scale
                        let normalizedY = (data[i].y - minY) * window.uiScale;         // Normalizes y coordinate

                        monitorsModel.append({                                          // Appends a new entry to the monitors model
                            name: data[i].name,                                          // Monitor name (e.g., "DP-1", "HDMI-A-1")
                            resW: data[i].width,                                         // Native width resolution
                            resH: data[i].height,                                        // Native height resolution
                            sysScale: scl,                                                // System scale factor (e.g., 1.0, 1.5, 2.0)
                            rate: Math.round(data[i].refreshRate).toString(),            // Refresh rate rounded and converted to string
                            uiX: normalizedX,                                             // Virtual X position for the canvas
                            uiY: normalizedY,                                             // Virtual Y position
                            transform: tf                                                 // Rotation transform value
                        });

                        if (data[i].focused) window.activeEditIndex = i;                // If this monitor is currently focused, set it as the active editing target
                    }
                    
                    window.forceLayoutUpdate();                                          // After loading all monitors, snaps them to perimeters
                } catch(e) {}                                                            // Silently catches and ignores JSON parsing errors
            }
        }
    }

    // -------------------------------------------------------------------------
    // SYSTEM APPLY FUNCTION & DEBUG LOGGING                                       // Comment block: function that builds and executes hyprctl commands
    // -------------------------------------------------------------------------
    function triggerApply() {                                                         // Main function to apply the configured monitor settings to the system
        flashRect.opacity = 0.8;                                                       // Triggers a white flash on the apply button for visual feedback
        applyFlashAnim.start();                                                        // Starts the flash fade-out animation

        if (monitorsModel.count === 0) return;                                         // Exits if no monitors are loaded

        window.debugLog("================= NEW APPLY RUN =================");          // Logs the start of an apply operation

        if (monitorsModel.count === 1) {                                               // SINGLE MONITOR CONFIGURATION
            let m = monitorsModel.get(0);                                                // Gets the single monitor's data
            let monitorStr = m.name + "," + m.resW + "x" + m.resH + "@" + m.rate + ",0x0," + m.sysScale;  // Builds the hyprctl monitor string: name,resolution@rate,position,scale
            if (m.transform !== 0) {                                                     // If the monitor has a rotation
                monitorStr += ",transform," + m.transform;                               // Appends the transform parameter
            }

            let jsonMonitorsArray = [{                                                   // Creates a JSON array entry for saving to settings file
                name: m.name, resW: m.resW, resH: m.resH, rate: parseInt(m.rate),       // Monitor identification and settings
                x: 0, y: 0, scale: m.sysScale, transform: m.transform                   // Position at origin for single monitor
            }];
            let safeJson = JSON.stringify(jsonMonitorsArray).replace(/'/g, "'\\''");    // Converts to JSON string and escapes single quotes for shell safety
            let jsonCmd = "jq '.monitors = " + safeJson + "' ~/.config/hypr/settings.json > ~/.config/hypr/settings.json.tmp && mv ~/.config/hypr/settings.json.tmp ~/.config/hypr/settings.json";  // Shell command to update the monitors array in settings.json using jq
            let postReloadCmd = "swww kill ; sleep 0.2 ; swww-daemon &";              // Command to restart the wallpaper daemon after resolution change

            Quickshell.execDetached(["notify-send", "Display Update", "Applied & Saved: " + m.resW + "x" + m.resH + " @ " + m.rate + "Hz"]);  // Sends a desktop notification
            Quickshell.execDetached(["sh", "-c", "hyprctl keyword monitor " + monitorStr + " ; " + jsonCmd + " ; " + postReloadCmd]);  // Executes the full chain: apply monitor, save settings, restart wallpaper
            
            window.debugLog("Executed single monitor apply.");                         // Logs the completion
        } else {                                                                        // MULTI-MONITOR CONFIGURATION
            let rects = [];                                                              // Array to hold monitor rectangle data for layout calculation
            let finalMinX = 999999;                                                      // Will store the minimum x coordinate for normalization
            let finalMinY = 999999;                                                      // Will store the minimum y coordinate

            for (let i = 0; i < monitorsModel.count; i++) {                             // Builds the initial rectangle array from model data
                let m = monitorsModel.get(i);                                             // Gets monitor data
                let isP = m.transform === 1 || m.transform === 3;                        // Checks portrait orientation
                let physW = Math.round((isP ? m.resH : m.resW) / m.sysScale);           // Calculates physical width (resolution / scale), swapping for portrait
                let physH = Math.round((isP ? m.resW : m.resH) / m.sysScale);           // Calculates physical height
                
                let rawX = m.uiX / window.uiScale;                                       // Converts virtual X back to raw coordinate
                let rawY = m.uiY / window.uiScale;                                       // Converts virtual Y back to raw coordinate
                
                rects.push({                                                              // Pushes a rectangle object
                    x: rawX, y: rawY, w: physW, h: physH,                                // Position and dimensions
                    resW: m.resW, resH: m.resH, name: m.name,                            // Resolution and name
                    rate: m.rate, sysScale: m.sysScale, transform: m.transform           // Rate, scale, and transform
                });
            }

            function getTightSnap(pX, pY, sX, sY, sW, sH, mW, mH, t) {                 // Inner function for tighter snapping during final apply (larger threshold)
                let cx = pX; let cy = pY;                                                  // Starts with current position
                if (Math.abs(cx - (sX - mW)) < t) cx = sX - mW;                          // Snap left edge of moving monitor to left of source (moving monitor on left)
                else if (Math.abs(cx - (sX + sW)) < t) cx = sX + sW;                     // Snap left edge of moving monitor to right of source (moving monitor on right)
                else if (Math.abs(cx - sX) < t) cx = sX;                                  // Snap left-align with source
                else if (Math.abs(cx - (sX + sW - mW)) < t) cx = sX + sW - mW;          // Snap right-align with source
                else if (Math.abs(cx - (sX + sW/2 - mW/2)) < t) cx = sX + sW/2 - mW/2; // Snap center-align with source
                
                if (Math.abs(cy - (sY - mH)) < t) cy = sY - mH;                          // Snap top edge above source
                else if (Math.abs(cy - (sY + sH)) < t) cy = sY + sH;                     // Snap top edge below source
                else if (Math.abs(cy - sY) < t) cy = sY;                                  // Snap top-align
                else if (Math.abs(cy - (sY + sH - mH)) < t) cy = sY + sH - mH;          // Snap bottom-align
                else if (Math.abs(cy - (sY + sH/2 - mH/2)) < t) cy = sY + sH/2 - mH/2; // Snap middle-align
                
                return {x: cx, y: cy};                                                     // Returns the snapped position
            }

            for (let i = 1; i < rects.length; i++) {                                     // Processes monitors starting from the second one
                let bestX = rects[i].x;                                                    // Initializes best position
                let bestY = rects[i].y;
                let bestDist = 999999;                                                     // Large initial distance
                for (let j = 0; j < i; j++) {                                             // Checks against all previously processed monitors
                    let r0 = rects[j];                                                      // Gets the reference monitor
                    let snapped = getTightSnap(                                             // Calculates snap position
                        rects[i].x, rects[i].y,
                        r0.x, r0.y,
                        r0.w, r0.h, rects[i].w, rects[i].h, 25                             // Larger 25-unit snap threshold for final positioning
                    );
                    let dist = Math.hypot(rects[i].x - snapped.x, rects[i].y - snapped.y); // Calculates distance to snap point
                    if (dist < bestDist) {                                                    // If closer than previous best
                        bestDist = dist;                                                      // Updates best distance
                        bestX = Math.round(snapped.x);                                        // Rounds and stores best X
                        bestY = Math.round(snapped.y);                                        // Rounds and stores best Y
                    }
                }
                rects[i].x = bestX;                                                          // Applies best snapped X
                rects[i].y = bestY;                                                          // Applies best snapped Y
            }

            for (let i = 0; i < rects.length; i++) {                                       // Finds the minimum coordinates for normalization
                if (rects[i].x < finalMinX) finalMinX = rects[i].x;
                if (rects[i].y < finalMinY) finalMinY = rects[i].y;
            }
            
            let batchCmds = [];                                                              // Array to hold hyprctl batch commands
            let summaryString = "";                                                          // String for notification summary
            let jsonMonitorsArray = [];                                                      // Array for saving to JSON settings file

            for (let i = 0; i < rects.length; i++) {                                        // Builds the final commands and JSON data
                let r = rects[i];                                                             // Gets the rectangle data
                
                r.x = Math.round(r.x - finalMinX);                                            // Normalizes x so the leftmost monitor is at 0
                r.y = Math.round(r.y - finalMinY);                                            // Normalizes y so the topmost monitor is at 0
                
                let monitorStr = r.name + "," + r.resW + "x" + r.resH + "@" + r.rate + "," + r.x + "x" + r.y + "," + r.sysScale;  // Builds hyprctl monitor string
                if (r.transform !== 0) {                                                      // If rotated
                    monitorStr += ",transform," + r.transform;                                 // Appends transform
                }
                
                batchCmds.push("keyword monitor " + monitorStr);                              // Adds to batch commands array
                summaryString += r.name + " ";                                                // Appends monitor name to summary

                jsonMonitorsArray.push({                                                       // Adds to JSON array for settings file
                    name: r.name, resW: r.resW, resH: r.resH, rate: parseInt(r.rate),
                    x: r.x, y: r.y, scale: r.sysScale, transform: r.transform
                });
            }
            
            let fullHyprCmd = "hyprctl --batch '" + batchCmds.join(" ; ") + "'";            // Joins all commands with semicolons into a single batch command
            let safeJson = JSON.stringify(jsonMonitorsArray).replace(/'/g, "'\\''");        // Escapes the JSON for shell safety
            let jsonCmd = "jq '.monitors = " + safeJson + "' ~/.config/hypr/settings.json > ~/.config/hypr/settings.json.tmp && mv ~/.config/hypr/settings.json.tmp ~/.config/hypr/settings.json";  // Shell command to save settings
            let postReloadCmd = "swww kill ; sleep 0.2 ; swww-daemon &";                  // Wallpaper daemon restart command

            Quickshell.execDetached(["sh", "-c", fullHyprCmd + " ; " + jsonCmd + " ; " + postReloadCmd]);  // Executes the full chain
            Quickshell.execDetached(["notify-send", "Display Update", "Applied & Saved layout for: " + summaryString]);  // Sends notification with monitor names
            
            window.debugLog("Executed multi monitor apply: " + fullHyprCmd);               // Logs the complete command
        }
    }


    // -------------------------------------------------------------------------
    // UI LAYOUT                                                                     // Comment block marking the start of the visual layout
    // -------------------------------------------------------------------------
    Item {                                                                            // Main content container
        anchors.fill: parent                                                           // Fills the entire parent (window root Item)
        scale: 0.95 + (0.05 * window.introProgress)                                     // Scales from 95% to 100% during intro animation
        opacity: window.introProgress                                                    // Fades in during intro animation

        Rectangle {                                                                     // Main background card
            anchors.fill: parent                                                          // Fills the container
            radius: window.s(30)                                                           // Large rounded corners (30 design units)
            color: window.base                                                              // Base background color
            border.color: window.surface0                                                   // Subtle border using surface0
            border.width: 1                                                                  // 1px border
            clip: true                                                                       // Clips child content to rounded corners

            Rectangle {                                                                      // First decorative floating orb
                width: parent.width * 0.8; height: width; radius: width / 2                    // Circle: 80% parent width, radius makes it circular
                x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)  // X position oscillates with cosine at 2x frequency
                y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)  // Y position oscillates with sine at 2x frequency
                opacity: 0.04                                                                  // Very subtle 4% opacity
                color: window.selectedResAccent                                                 // Color follows the selected resolution accent
                Behavior on color { ColorAnimation { duration: 1000 } }                        // Smooth 1-second color transition
            }
            Rectangle {                                                                      // Second decorative floating orb
                width: parent.width * 0.9; height: width; radius: width / 2                    // Slightly larger circle: 90% parent width
                x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)  // Uses sine for X at 1.5x frequency, negative amplitude
                y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)  // Uses cosine for Y, negative amplitude for counter-orbit
                opacity: 0.04                                                                  // 4% opacity
                color: window.selectedRateAccent                                                // Color follows the selected refresh rate accent
                Behavior on color { ColorAnimation { duration: 1000 } }                        // Smooth 1-second transition
            }

            // ==========================================
            // LEFT SIDE VISUAL AREA                                                      // Comment: left half shows the monitor visualization
            // ==========================================
            Item {                                                                           // Container for the left visual area
                id: leftVisualArea
                width: window.s(380)                                                           // Fixed width of 380 design units
                height: window.s(300)                                                          // Fixed height of 300 units
                anchors.left: parent.left                                                       // Anchored to left edge
                anchors.verticalCenter: parent.verticalCenter                                   // Vertically centered
                anchors.leftMargin: window.s(20)                                                // 20 units from left edge

                // --------------------------------------------------
                // MODE 1: SINGLE MONITOR                                                    // Comment: visualization shown when only one monitor is connected
                // --------------------------------------------------
                Item {                                                                         // Container for single monitor view
                    anchors.fill: parent                                                         // Fills the left visual area
                    visible: monitorsModel.count === 1                                            // Only visible when exactly 1 monitor exists

                    Item {                                                                       // Container that handles zoom/scale of the monitor graphic
                        id: singleMonitorZoom
                        anchors.centerIn: parent                                                  // Centered in the visual area
                        width: window.s(380); height: window.s(280)                               // Base dimensions
                        
                        property real baseScale: Math.min(1.0, Math.min(2200 / window.currentSimW, 1400 / Math.max(1, window.currentSimH)))  // Calculates scale to fit the monitor within bounds; higher resolution = smaller scale; maxes at 1.0
                        scale: baseScale * window.monitorScale                                    // Combines base scale with animated startup scale
                        opacity: window.introProgress                                             // Fades in with intro animation
                        Behavior on baseScale { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }  // Smooth 600ms scale transitions when resolution changes

                        Rectangle {                                                              // Desk surface/platform the monitor sits on
                            id: deskSurface
                            width: window.s(1000); height: window.s(14); radius: window.s(6)      // Wide thin rectangle with rounded corners
                            anchors.top: standBase.bottom                                         // Sits below the stand base
                            anchors.horizontalCenter: parent.horizontalCenter                      // Centered horizontally
                            color: window.mantle                                                   // Mantle color
                            border.color: window.surface0; border.width: 1                         // Subtle border

                            Rectangle {                                                           // Left desk leg
                                width: window.s(24); height: window.s(350); radius: window.s(4); color: window.crust  // Tall thin leg
                                anchors.top: parent.bottom; anchors.topMargin: window.s(-5); anchors.left: parent.left; anchors.leftMargin: window.s(100); z: -1  // Positioned below desk, offset from left
                            }
                            Rectangle {                                                           // Right desk leg
                                width: window.s(24); height: window.s(350); radius: window.s(4); color: window.crust
                                anchors.top: parent.bottom; anchors.topMargin: window.s(-5); anchors.right: parent.right; anchors.rightMargin: window.s(100); z: -1  // Mirrored on right side
                            }
                        }

                        Rectangle {                                                              // Stand base (bottom of monitor stand)
                            id: standBase
                            width: window.s(130); height: window.s(8); radius: window.s(4)        // Wide thin rectangle
                            anchors.bottom: parent.bottom; anchors.bottomMargin: window.s(20); anchors.horizontalCenter: parent.horizontalCenter  // Near bottom, centered
                            color: window.surface1
                        }
                        
                        Rectangle {                                                              // Stand neck (vertical part connecting base to screen)
                            id: standNeck
                            width: window.s(34); height: window.s(70)                             // Taller than wide
                            anchors.bottom: standBase.top; anchors.horizontalCenter: parent.horizontalCenter  // Sits on base, centered
                            color: window.surface0
                            Rectangle { width: window.s(10); height: window.s(30); radius: window.s(5); anchors.centerIn: parent; color: window.base }  // Inner cutout detail on the neck
                        }

                        Rectangle {                                                              // Monitor screen bezel
                            id: screenBezel
                            
                            // Perfect aspect ratio AND scales up physically on the desk at higher resolutions  // Comment: width and height scale proportionally to the simulated resolution
                            width: window.s(320) * (window.currentSimW / 1920.0)                  // Scales width relative to 1920 base; higher width = wider bezel
                            height: window.s(320) * (window.currentSimH / 1920.0)                 // Scales height relative to 1920 base

                            anchors.bottom: standNeck.top; anchors.bottomMargin: window.s(-10); anchors.horizontalCenter: parent.horizontalCenter  // Sits on neck, slightly overlapping
                            radius: window.s(12)                                                   // Rounded corners
                            color: window.crust                                                    // Dark crust color for bezel
                            border.color: window.surface2; border.width: window.s(2)               // Thicker border for bezel edge
                            
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }   // Smooth width animation
                            Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }  // Smooth height animation

                            Rectangle {                                                            // Inner screen area
                                anchors.fill: parent; anchors.margins: window.s(10); radius: window.s(6); color: window.surface0; clip: true  // Inset from bezel, clips content

                                Rectangle {                                                        // Screen lighting gradient overlay
                                    anchors.fill: parent; color: "transparent"; opacity: window.screenLight  // Fades in during startup
                                    
                                    gradient: Gradient {                                            // Vertical gradient for screen reflection effect
                                        orientation: Gradient.Vertical
                                        GradientStop { position: 0.0; color: Qt.tint(window.surface0, Qt.alpha(window.selectedResAccent, 0.15)); Behavior on color { ColorAnimation { duration: 400 } } }  // Tints with resolution accent at top
                                        GradientStop { position: 1.0; color: Qt.tint(window.surface0, Qt.alpha(window.selectedRateAccent, 0.1)); Behavior on color { ColorAnimation { duration: 400 } } }  // Tints with rate accent at bottom
                                    }
                                    
                                    Grid {                                                         // Decorative grid of dots (pixel-like texture)
                                        anchors.centerIn: parent; rows: 10; columns: 15; spacing: window.s(20)  // 10x15 grid
                                        Repeater { model: 150; Rectangle { width: window.s(2); height: window.s(2); radius: window.s(1); color: Qt.alpha(window.text, 0.1) } }  // 150 tiny dots at 10% text opacity
                                    }
                                }

                                Item {                                                             // Monitor info overlay container
                                    anchors.centerIn: parent; width: window.s(160); height: window.s(100)  // Centered content area
                                    
                                    // 1. Counteract the environmental zoom factor                   // Comment: compensates for the parent's zoom so text stays readable
                                    property real counterScale: 1.0 / singleMonitorZoom.scale       // Inverse of the zoom scale
                                    
                                    // 2. Compute a safe physical boundary based on current visual rotation  // Comment: prevents text from overflowing when rotated
                                    property real maxPhysicalScale: window.currentIsPortrait 
                                        ? Math.min((parent.width * 0.9) / height, (parent.height * 0.9) / width)  // If portrait, compare against swapped dimensions
                                        : Math.min((parent.width * 0.9) / width, (parent.height * 0.9) / height)  // Landscape: compare directly
                                    
                                    scale: Math.min(counterScale, maxPhysicalScale)                 // Uses the smaller of the two scales to ensure content fits
                                    
                                    ColumnLayout {                                                  // Vertical column for monitor icon, name, and specs
                                        anchors.centerIn: parent; spacing: window.s(4)

                                        // Restored Rotation: Acts as a pointer to the monitor's physical bottom  // Comment: rotates the icon/text group to match monitor orientation
                                        rotation: window.currentTransform * 90                      // Rotates by transform*90 degrees (0, 90, 180, 270)
                                        Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }  // Smooth rotation animation

                                        Text { Layout.alignment: Qt.AlignHCenter; font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(38); color: window.selectedResAccent; text: "󰍹"; Behavior on color { ColorAnimation { duration: 400 } } }  // Monitor icon, color follows resolution accent
                                        Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(16); color: window.text; text: monitorsModel.count > 0 ? monitorsModel.get(0).name : "Unknown" }  // Monitor name
                                        Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.pixelSize: window.s(12); color: window.subtext0; text: window.currentSimW + "x" + window.currentSimH + " @ " + (monitorsModel.count > 0 ? monitorsModel.get(0).rate : "60") + "Hz" }  // Resolution and refresh rate
                                    }
                                }
                            }
                        }
                    }
                }

                // --------------------------------------------------
                // MODE 2: MULTI-MONITOR (3+ Supported)                                        // Comment: visualization for multiple monitors with drag-to-arrange
                // --------------------------------------------------
                Item {                                                                           // Container for multi-monitor view
                    anchors.fill: parent
                    visible: monitorsModel.count > 1                                               // Visible when 2+ monitors exist

                    Item {                                                                        // Zoom/pan container for the multi-monitor canvas
                        id: multiMonitorView
                        width: window.s(380); height: window.s(280); anchors.centerIn: parent; clip: true  // Fixed size, centered, clips overflow

                        Grid {                                                                     // Decorative background grid of dots
                            anchors.centerIn: parent; rows: 25; columns: 34; spacing: window.s(18)
                            Repeater { model: 850; Rectangle { width: window.s(2); height: window.s(2); radius: window.s(1); color: Qt.alpha(window.text, 0.1) } }  // 850 dots at 10% text opacity
                        }

                        property real targetScale: {                                                // Calculates the scale to fit all monitors in the viewport
                            if (monitorsModel.count < 2) return 1.0;
                            let minX = 999999, minY = 999999, maxX = -999999, maxY = -999999;       // Initialize bounds tracking
                            
                            for (let i = 0; i < monitorsModel.count; i++) {                         // Finds the bounding box of all monitors
                                let m = monitorsModel.get(i); let isP = m.transform === 1 || m.transform === 3;
                                let w = ((isP ? m.resH : m.resW) / m.sysScale) * window.uiScale;
                                let h = ((isP ? m.resW : m.resH) / m.sysScale) * window.uiScale;
                                minX = Math.min(minX, m.uiX); minY = Math.min(minY, m.uiY);
                                maxX = Math.max(maxX, m.uiX + w); maxY = Math.max(maxY, m.uiY + h);
                            }
                            
                            let requiredW = (maxX - minX) + 80;                                     // Total width with padding
                            let requiredH = (maxY - minY) + 80;                                     // Total height with padding
                            
                            return Math.min(1.8 * scaler.baseScale, Math.min(window.s(340) / requiredW, window.s(240) / requiredH));  // Returns scale that fits within viewport, capped at 1.8x base scale
                        }

                        property real offsetX: {                                                     // Calculates X offset to center the monitor cluster
                            if (monitorsModel.count < 2) return 0;
                            let minX = 999999, maxX = -999999;
                            for (let i = 0; i < monitorsModel.count; i++) { let m = monitorsModel.get(i); let isP = m.transform === 1 || m.transform === 3; let w = ((isP ? m.resH : m.resW) / m.sysScale) * window.uiScale; minX = Math.min(minX, m.uiX); maxX = Math.max(maxX, m.uiX + w); }
                            let centerX = minX + (maxX - minX) / 2;                                  // Center of the cluster
                            return window.s(190) - (centerX * targetScale);                           // Offset to center in the 380-wide viewport
                        }

                        property real offsetY: {                                                     // Calculates Y offset to center the monitor cluster
                            if (monitorsModel.count < 2) return 0;
                            let minY = 999999, maxY = -999999;
                            for (let i = 0; i < monitorsModel.count; i++) { let m = monitorsModel.get(i); let isP = m.transform === 1 || m.transform === 3; let h = ((isP ? m.resW : m.resH) / m.sysScale) * window.uiScale; minY = Math.min(minY, m.uiY); maxY = Math.max(maxY, m.uiY + h); }
                            let centerY = minY + (maxY - minY) / 2;                                  // Center of the cluster
                            return window.s(140) - (centerY * targetScale);                           // Offset to center in the 280-tall viewport
                        }

                        Item {                                                                       // Transform node that applies pan and zoom
                            id: transformNode
                            x: multiMonitorView.offsetX; y: multiMonitorView.offsetY; scale: multiMonitorView.targetScale; transformOrigin: Item.TopLeft  // Positioned and scaled
                            Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }  // Smooth pan animation
                            Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

                            Repeater {                                                               // Repeats a delegate for each monitor in the model
                                id: monitorRepeater; model: monitorsModel

                                Item {                                                                // Container for each monitor card
                                    property bool isActive: window.activeEditIndex === index             // True if this is the actively edited monitor
                                    property bool isPortrait: model.transform === 1 || model.transform === 3  // True if portrait orientation

                                    // THE VISIBLE SNAPPED MONITOR CARD                                   // Comment: the visual card representing the monitor
                                    Rectangle {
                                        id: monitorCard
                                        x: model.uiX; y: model.uiY                                        // Position from model's virtual coordinates
                                        width: (isPortrait ? model.resH : model.resW) / model.sysScale * window.uiScale   // Virtual width (swapped if portrait)
                                        height: (isPortrait ? model.resW : model.resH) / model.sysScale * window.uiScale  // Virtual height (swapped if portrait)
                                        
                                        radius: 8; color: isActive ? window.surface1 : window.crust        // Highlighted if active
                                        border.color: isActive ? window.selectedResAccent : window.surface2  // Accent border if active
                                        border.width: isActive ? 2 : 1; z: isActive ? 5 : 0                 // Thicker border, higher z-index if active

                                        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                                        Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                                        Behavior on border.color { ColorAnimation { duration: 300 } }
                                        Behavior on color { ColorAnimation { duration: 300 } }
                                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                                        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

                                        Item {                                                           // Monitor info overlay (counter-scales to stay readable)
                                            anchors.centerIn: parent; width: 110; height: 80
                                            property real idealScale: 1.2 / transformNode.scale            // Inverse of the main zoom
                                            property real maxPhysicalScale: isPortrait 
                                                ? Math.min((parent.width * 0.9) / height, (parent.height * 0.9) / width) 
                                                : Math.min((parent.width * 0.9) / width, (parent.height * 0.9) / height)  // Bounds check
                                            scale: Math.min(idealScale, maxPhysicalScale)                   // Safe scale to fit within card
                                            
                                            ColumnLayout { anchors.centerIn: parent; spacing: 2
                                                rotation: model.transform * 90                              // Rotates content to match monitor orientation
                                                Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                                                Text { Layout.alignment: Qt.AlignHCenter; font.family: "Iosevka Nerd Font"; font.pixelSize: 32; color: isActive ? window.selectedResAccent : window.text; text: "󰍹"; Behavior on color { ColorAnimation { duration: 300 } } }
                                                Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: 13; color: window.text; text: model.name }
                                                Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.pixelSize: 10; color: window.subtext0; text: model.resW + "x" + model.resH + " @ " + model.rate + "Hz" }
                                            }
                                        }
                                    }

                                    // THE INVISIBLE GHOST DRAGGER                                            // Comment: invisible draggable item that handles monitor repositioning
                                    Item {
                                        id: ghostDrag; x: model.uiX; y: model.uiY; width: monitorCard.width; height: monitorCard.height; z: isActive ? 10 : 1  // Matches card position and size

                                        MouseArea {                                                          // Mouse area for drag interaction
                                            id: ghostMa; anchors.fill: parent; drag.target: ghostDrag; drag.axis: Drag.XAndYAxis  // Enables dragging in both axes
                                            
                                            onPressed: { window.activeEditIndex = index; ghostDrag.x = model.uiX; ghostDrag.y = model.uiY; }  // Selects this monitor on press, resets drag position

                                            onPositionChanged: {                                              // Called continuously during drag
                                                if (drag.active && monitorsModel.count >= 2) {                 // If dragging and multiple monitors
                                                    let mW = monitorCard.width; let mH = monitorCard.height;   // Moving monitor dimensions
                                                    let padding = 40; let boundMinX = 999999, boundMinY = 999999, boundMaxX = -999999, boundMaxY = -999999;
                                                    
                                                    for (let j = 0; j < monitorsModel.count; j++) {            // Calculates drag boundaries based on other monitors
                                                        if (j === index) continue; let sModel = monitorsModel.get(j); let sIsP = sModel.transform === 1 || sModel.transform === 3;
                                                        let sW = ((sIsP ? sModel.resH : sModel.resW) / sModel.sysScale) * window.uiScale; let sH = ((sIsP ? sModel.resW : sModel.resH) / sModel.sysScale) * window.uiScale;
                                                        boundMinX = Math.min(boundMinX, sModel.uiX - mW - padding); boundMinY = Math.min(boundMinY, sModel.uiY - mH - padding);
                                                        boundMaxX = Math.max(boundMaxX, sModel.uiX + sW + padding); boundMaxY = Math.max(boundMaxY, sModel.uiY + sH + padding);
                                                    }

                                                    ghostDrag.x = Math.max(boundMinX, Math.min(ghostDrag.x, boundMaxX));  // Clamps X within boundaries
                                                    ghostDrag.y = Math.max(boundMinY, Math.min(ghostDrag.y, boundMaxY));  // Clamps Y within boundaries

                                                    let bestX = ghostDrag.x; let bestY = ghostDrag.y; let bestDist = 999999;
                                                    for (let j = 0; j < monitorsModel.count; j++) {           // Snaps to nearest perimeter of other monitors
                                                        if (j === index) continue; let sModel = monitorsModel.get(j); let sIsP = sModel.transform === 1 || sModel.transform === 3;
                                                        let sW = ((sIsP ? sModel.resH : sModel.resW) / sModel.sysScale) * window.uiScale; let sH = ((sIsP ? sModel.resW : sModel.resH) / sModel.sysScale) * window.uiScale;
                                                        let snapped = window.getPerimeterSnap(ghostDrag.x, ghostDrag.y, sModel.uiX, sModel.uiY, sW, sH, mW, mH, 20);  // Snap with 20-unit threshold
                                                        let dist = Math.hypot(ghostDrag.x - snapped.x, ghostDrag.y - snapped.y);
                                                        if (dist < bestDist) { bestDist = dist; bestX = snapped.x; bestY = snapped.y; }
                                                    }

                                                    if (!window.isOverlappingAny(bestX, bestY, mW, mH, index)) {  // Only apply if no overlap with other monitors
                                                        monitorsModel.setProperty(index, "uiX", bestX); monitorsModel.setProperty(index, "uiY", bestY);
                                                    }
                                                }
                                            }

                                            onReleased: { ghostDrag.x = model.uiX; ghostDrag.y = model.uiY; }  // Resets ghost position on release
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // INTERACTIVE SELECTION GRIDS                                                 // Comment: right side controls for resolution, rotation, and refresh rate
            // ==========================================
            Item {                                                                         // Container for the right-side settings panel
                anchors.left: leftVisualArea.right                                           // Starts to the right of the visual area
                anchors.right: parent.right                                                   // Extends to the right edge
                anchors.verticalCenter: parent.verticalCenter                                 // Vertically centered
                anchors.verticalCenterOffset: window.s(-10) // Tweak layout slightly downwards  // Slight downward offset
                anchors.leftMargin: window.s(10); anchors.rightMargin: window.s(30)          // Margins
                height: rightSideContainer.implicitHeight                                    // Height follows content

                opacity: window.introProgress                                                  // Fades in with intro
                transform: Translate { y: window.uiYOffset }                                    // Slides up from offset during intro

                SequentialAnimation { id: menuTransitionAnim                                   // Subtle animation when switching between monitors
                    ParallelAnimation {
                        ScaleAnimator { target: rightSideContainer; from: 0.99; to: 1.0; duration: 200; easing.type: Easing.OutSine }  // Quick scale bounce
                        NumberAnimation { target: highlightFlash; property: "opacity"; from: 0.05; to: 0.0; duration: 250; easing.type: Easing.OutQuad }  // Flash fades out
                    }
                }

                Rectangle { id: highlightFlash; anchors.fill: rightSideContainer; anchors.margins: window.s(-10); color: window.selectedResAccent; opacity: 0.0; radius: window.s(12) }  // Flash overlay (normally invisible)

                ColumnLayout { id: rightSideContainer; anchors.fill: parent; spacing: window.s(10)  // Main column layout for settings

                    // --- RESOLUTION CARDS SECTION ---                                         // Comment: grid of resolution buttons
                    GridLayout { id: resGrid; Layout.fillWidth: true; columns: 2; columnSpacing: window.s(10); rowSpacing: window.s(10)  // 2-column grid

                        Repeater { model: window.resList                                         // Repeats for each resolution option

                            delegate: Rectangle {                                                 // Resolution card delegate
                                property var modelData: window.resList[index]; Layout.fillWidth: true; Layout.preferredHeight: window.s(45); radius: window.s(12)  // Card dimensions
                                property bool isSel: { if (monitorsModel.count === 0) return false; let activeMon = monitorsModel.get(window.activeEditIndex); return activeMon.resW === modelData.w && activeMon.resH === modelData.h; }  // True if this resolution is currently selected
                                property color accentColor: modelData.accent                       // Accent color for this resolution
                                
                                color: isSel ? Qt.alpha(accentColor, 0.15) : (resMa.containsMouse ? window.surface0 : window.mantle)  // 15% accent tint if selected, hover highlight, or mantle default
                                border.color: isSel ? accentColor : (resMa.containsMouse ? window.surface1 : "transparent")  // Colored border if selected
                                border.width: isSel ? 2 : 1
                                Behavior on color { ColorAnimation { duration: 200 } }; Behavior on border.color { ColorAnimation { duration: 200 } }

                                RowLayout { anchors.fill: parent; anchors.margins: window.s(12); spacing: window.s(8)
                                    Text { font.family: "JetBrains Mono"; font.weight: isSel ? Font.Black : Font.Bold; font.pixelSize: window.s(15); color: isSel ? accentColor : window.text; text: modelData.l; Behavior on color { ColorAnimation { duration: 200 } } }  // Resolution label (4K, QHD, etc.)
                                    Item { Layout.fillWidth: true }                                // Spacer
                                    Text { font.family: "JetBrains Mono"; font.pixelSize: window.s(11); color: isSel ? window.text : window.overlay0; text: modelData.w + "x" + modelData.h; Behavior on color { ColorAnimation { duration: 200 } } }  // Resolution dimensions
                                }

                                scale: resMa.pressed ? 0.96 : 1.0; Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }  // Press animation

                                MouseArea { id: resMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { window.activeFocusIndex = 0; if (monitorsModel.count > 0) { window.selectedResAccent = accentColor; monitorsModel.setProperty(window.activeEditIndex, "resW", modelData.w); monitorsModel.setProperty(window.activeEditIndex, "resH", modelData.h); delayedLayoutUpdate.restart(); } }  // Selects this resolution on click
                                }
                            }
                        }
                    }

                    Item { Layout.preferredHeight: window.s(2) }  // Small spacer

                    // --- ROTATION DIAL (CLOCK-STYLE) SECTION ---                           // Comment: circular rotation selector
                    RowLayout { Layout.fillWidth: true; Layout.preferredHeight: window.s(120)
                        Item { Layout.fillWidth: true }                                       // Left spacer for centering

                        Rectangle { id: clockDial; Layout.preferredWidth: window.s(120); Layout.preferredHeight: window.s(120); Layout.alignment: Qt.AlignCenter; radius: width / 2; color: window.surface0; border.color: window.activeFocusIndex === 1 ? window.selectedResAccent : window.surface1; border.width: window.activeFocusIndex === 1 ? window.s(3) : window.s(2); Behavior on border.color { ColorAnimation { duration: 200 } }; Behavior on border.width { NumberAnimation { duration: 200 } }  // Circular dial with focus-highlighted border

                            // 12-Hour Clock Tick Marks                                              // Comment: decorative tick marks around the dial
                            Repeater { model: 12
                                Item { anchors.fill: parent; rotation: index * 30                    // Each tick rotated by 30 degrees
                                    Rectangle { width: index % 3 === 0 ? window.s(4) : window.s(2); height: index % 3 === 0 ? window.s(8) : window.s(4); radius: width / 2; color: index % 3 === 0 ? window.subtext0 : window.surface2; anchors.top: parent.top; anchors.topMargin: window.s(4); anchors.horizontalCenter: parent.horizontalCenter }  // Every 3rd tick is larger (12, 3, 6, 9 o'clock positions)
                                }
                            }

                            // The Interactive Pointer                                              // Comment: the rotating pointer indicating current orientation
                            Item { id: dialPointer; anchors.fill: parent; property int activeTransform: monitorsModel.count > 0 ? monitorsModel.get(window.activeEditIndex).transform : 0; rotation: activeTransform * 90; Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutBack;} }  // Rotates by transform*90°

                                Rectangle { width: window.s(5); height: parent.height / 2 - window.s(20); radius: window.s(2.5); color: window.selectedResAccent; anchors.bottom: parent.verticalCenter; anchors.horizontalCenter: parent.horizontalCenter; Behavior on color { ColorAnimation { duration: 300 } } }  // Pointer line from center upward
                                Rectangle { width: window.s(18); height: window.s(18); radius: width / 2; color: window.base; border.color: window.selectedResAccent; border.width: window.s(4); anchors.centerIn: parent; Behavior on border.color { ColorAnimation { duration: 300 } } }  // Center dot
                            }

                            MouseArea { id: dialMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                function updateAngle(mouse) { if (monitorsModel.count === 0) return; window.activeFocusIndex = 1; let dx = mouse.x - width / 2; let dy = mouse.y - height / 2; if (Math.hypot(dx, dy) < window.s(20)) return; let snap = 0; if (Math.abs(dx) > Math.abs(dy)) { snap = dx > 0 ? 1 : 3; } else { snap = dy > 0 ? 2 : 0; } monitorsModel.setProperty(window.activeEditIndex, "transform", snap); delayedLayoutUpdate.restart(); }  // Determines orientation from mouse angle relative to center; snaps to nearest 90°
                                onPressed: (mouse) => updateAngle(mouse); onPositionChanged: (mouse) => { if (pressed) updateAngle(mouse) }  // Updates on press and drag
                            }
                        }

                        Item { Layout.fillWidth: true }                                       // Right spacer for centering
                    }
                    Item { Layout.preferredHeight: window.s(2) }  // Small spacer

                    // --- REFRESH RATE SLIDER SECTION ---                                     // Comment: horizontal slider for refresh rate
                    Item { id: sliderContainer; Layout.fillWidth: true; Layout.preferredHeight: window.s(45); Layout.leftMargin: window.s(6); Layout.rightMargin: window.s(6)
                        property var rates: [60, 75, 100, 120, 144, 165, 180, 240, 360]       // Available refresh rate options
                        property var rateColors: [window.red, window.mauve, window.blue, window.sapphire, window.teal, window.pink, window.yellow, window.green, window.peach]  // Accent colors for each rate
                        
                        property int currentIndex: { if (monitorsModel.count === 0) return 0; let currentVal = parseInt(monitorsModel.get(window.activeEditIndex).rate) || 60; let closestIdx = 0; let minDiff = 9999; for (let i = 0; i < rates.length; i++) { let diff = Math.abs(rates[i] - currentVal); if (diff < minDiff) { minDiff = diff; closestIdx = i; } } return closestIdx; }  // Finds closest rate to current value

                        property real visualPct: currentIndex / (rates.length - 1)               // Visual position as 0-1 percentage
                        onCurrentIndexChanged: { if (!sliderMa.pressed) visualPct = currentIndex / (rates.length - 1); }  // Updates visual position when not dragging
                        
                        function updateSelectionVisual(idx) { if (monitorsModel.count === 0) return; visualPct = idx / (rates.length - 1); monitorsModel.setProperty(window.activeEditIndex, "rate", rates[idx].toString()); window.selectedRateAccent = rateColors[idx]; }  // Updates model and visual

                        Rectangle { id: track; anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: window.s(15); anchors.rightMargin: window.s(15); anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: window.s(-10); height: window.s(12); radius: window.s(6); color: window.mantle; border.color: window.crust; border.width: 1  // Slider track
                            Rectangle { id: trackFill; width: Math.max(0, knob.x + knob.width / 2); height: parent.height; radius: parent.radius; color: window.selectedRateAccent; Behavior on color { ColorAnimation { duration: 200 } } }  // Filled portion of track
                            Rectangle { id: knob; width: window.s(24); height: window.s(24); radius: window.s(12); color: sliderMa.containsPress ? window.selectedRateAccent : window.text; anchors.verticalCenter: parent.verticalCenter; x: (sliderContainer.visualPct * parent.width) - width / 2; Behavior on x { enabled: !sliderMa.pressed; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }; Behavior on color { ColorAnimation { duration: 150 } }; border.width: (sliderMa.containsMouse || window.activeFocusIndex === 2) ? window.s(4) : 0; border.color: Qt.alpha(window.selectedRateAccent, 0.4); Behavior on border.width { NumberAnimation { duration: 150 } } }  // Draggable knob
                        }

                        Repeater { model: sliderContainer.rates.length                          // Labels for each rate tick
                            Item { x: track.x + (index / (sliderContainer.rates.length - 1)) * track.width; y: track.y + window.s(20)  // Positioned under the track
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: sliderContainer.rates[index]; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); font.weight: sliderContainer.currentIndex === index ? Font.Bold : Font.Normal; color: sliderContainer.currentIndex === index ? window.selectedRateAccent : window.overlay0; Behavior on color { ColorAnimation { duration: 200 } } }  // Bold highlighted label for current rate
                            }
                        }

                        MouseArea { id: sliderMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            function updateSelection(mouseX, snapToGrid) { if (monitorsModel.count === 0) return; window.activeFocusIndex = 2; let pct = (mouseX - track.x) / track.width; pct = Math.max(0, Math.min(1, pct)); let idx = Math.round(pct * (sliderContainer.rates.length - 1)); if (snapToGrid) { sliderContainer.visualPct = idx / (sliderContainer.rates.length - 1); } else { sliderContainer.visualPct = pct; } monitorsModel.setProperty(window.activeEditIndex, "rate", sliderContainer.rates[idx].toString()); window.selectedRateAccent = sliderContainer.rateColors[idx]; }  // Calculates rate from mouse position
                            onPressed: (mouse) => updateSelection(mouse.x, false); onPositionChanged: (mouse) => { if (pressed) updateSelection(mouse.x, false) }; onReleased: (mouse) => updateSelection(mouse.x, true); onCanceled: () => sliderContainer.visualPct = sliderContainer.currentIndex / (sliderContainer.rates.length - 1)  // Snaps on release
                        }
                    }

                    Item { Layout.preferredHeight: window.s(15) }  // Spacer before apply button

                    // ==========================================
                    // FLOATING APPLY BUTTON                                                  // Comment: gradient apply button with glow effect
                    // ==========================================
                    Item { id: applyButtonContainer; Layout.alignment: Qt.AlignRight; Layout.preferredWidth: window.s(170); Layout.preferredHeight: window.s(50)

                        MultiEffect { source: applyBtn; anchors.fill: applyBtn; shadowEnabled: true; shadowColor: window.selectedRateAccent; shadowBlur: window.applyHovered || window.activeFocusIndex === 3 ? 1.2 : 0.6; shadowOpacity: window.applyHovered || window.activeFocusIndex === 3 ? 0.6 : 0.2; shadowVerticalOffset: window.s(4); z: -1; Behavior on shadowBlur { NumberAnimation { duration: 300 } }; Behavior on shadowOpacity { NumberAnimation { duration: 300 } }; Behavior on shadowColor { ColorAnimation { duration: 400 } } }  // Glow shadow effect behind the button

                        Rectangle { id: applyBtn; anchors.fill: parent; radius: window.s(25)
                            gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0.0; color: window.selectedResAccent; Behavior on color { ColorAnimation { duration: 400 } } }; GradientStop { position: 1.0; color: window.selectedRateAccent; Behavior on color { ColorAnimation { duration: 400 } } } }  // Horizontal gradient from resolution accent to rate accent
                            border.color: window.activeFocusIndex === 3 ? window.crust : "transparent"; border.width: window.activeFocusIndex === 3 ? window.s(2) : 0  // Visible border when focused
                            scale: window.applyPressed ? 0.94 : (window.applyHovered || window.activeFocusIndex === 3 ? 1.04 : 1.0); Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }  // Scale feedback

                            Rectangle { id: flashRect; anchors.fill: parent; radius: window.s(25); color: window.text; opacity: 0.0; PropertyAnimation on opacity { id: applyFlashAnim; to: 0.0; duration: 400; easing.type: Easing.OutExpo } }  // White flash overlay on apply

                            RowLayout { anchors.centerIn: parent; spacing: window.s(8)
                                Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(20); color: window.crust; text: "󰸵" }  // Apply icon
                                Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(14); color: window.crust; text: monitorsModel.count > 1 ? "Apply All" : "Apply" }  // "Apply" or "Apply All" text
                            }
                        }

                        MouseArea { id: applyMa; anchors.fill: parent; z: 10; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onEntered: { window.applyHovered = true; window.activeFocusIndex = 3; }; onExited: window.applyHovered = false; onPressed: window.applyPressed = true; onReleased: window.applyPressed = false; onCanceled: window.applyPressed = false
                            onClicked: window.triggerApply()                               // Calls the apply function on click
                        }
                    }
                }
            }
        }
    }
}