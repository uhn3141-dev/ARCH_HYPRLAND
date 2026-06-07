// import QtQuick
// import QtQuick.Window
// import QtQuick.Controls
// import QtQuick.Layouts
// import Quickshell
// import Quickshell.Wayland
// import Quickshell.Io

// PanelWindow {
//     id: root
//     color: "transparent"

//     WlrLayershell.namespace: "qs-screenshot-overlay"
//     WlrLayershell.layer: WlrLayer.Overlay
//     WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    
//     exclusionMode: ExclusionMode.Ignore 
//     focusable: true
//     screen: Quickshell.cursorScreen
//     width: screen.width
//     height: screen.height

//     Scaler { id: scaler; currentWidth: width }
//     function s(val) { return scaler.s(val); }
    
//     MatugenColors { id: _theme }
//     property color dimColor: Qt.alpha(_theme.crust, 0.50)
//     property color selectionTint: Qt.alpha(_theme.mauve, 0.05)
//     property color handleColor: _theme.text
//     property color accentColor: _theme.mauve

//     property bool isEditMode: Quickshell.env("QS_SCREENSHOT_EDIT") === "true"
    
//     property string cachedMode: Quickshell.env("QS_CACHED_MODE") || "false"
//     property bool isVideoMode: cachedMode === "true"

//     onIsVideoModeChanged: {
//         Quickshell.execDetached(["bash", "-c", "echo '" + (root.isVideoMode ? "true" : "false") + "' > ~/.cache/qs_screenshot_mode"]);
        
//         // Smart Geometry Snapping for Portal Support
//         if (root.isVideoMode) {
//             root.preStartX = root.startX; 
//             root.preStartY = root.startY;
//             root.preEndX = root.endX; 
//             root.preEndY = root.endY;
            
//             root.startX = 0; 
//             root.startY = 0; 
//             root.endX = root.width; 
//             root.endY = root.height;
//             root.hasSelection = true;
//         } else {
//             root.startX = root.preStartX; 
//             root.startY = root.preStartY;
//             root.endX = root.preEndX; 
//             root.endY = root.preEndY;
            
//             if (Math.abs(root.endX - root.startX) < 10 || Math.abs(root.endY - root.startY) < 10) {
//                 root.hasSelection = false;
//             }
//         }
//     }
    
//     // --- Audio State Persistence ---
//     property real deskVol: Quickshell.env("QS_DESK_VOL") ? parseFloat(Quickshell.env("QS_DESK_VOL")) : 1.0
//     property bool deskMute: Quickshell.env("QS_DESK_MUTE") === "true"
//     property real micVol: Quickshell.env("QS_MIC_VOL") ? parseFloat(Quickshell.env("QS_MIC_VOL")) : 1.0
//     property bool micMute: Quickshell.env("QS_MIC_MUTE") === "true"
//     property string micDevice: Quickshell.env("QS_MIC_DEV") || ""

//     function saveAudioPrefs() {
//         let data = `${deskVol},${deskMute},${micVol},${micMute},${micDevice}`
//         Quickshell.execDetached(["bash", "-c", `echo '${data}' > ~/.cache/qs_audio_prefs`])
//     }

//     // --- Dynamic Mic Loader ---
//     ListModel { id: micModel }
    
//     Component.onCompleted: {
//         let micData = Quickshell.env("QS_MIC_LIST") || ""
//         if (micData.trim() !== "") {
//             let lines = micData.trim().split('\n')
//             for (let line of lines) {
//                 let parts = line.split('|')
//                 if (parts.length >= 2) {
//                     micModel.append({ devName: parts[0], devDesc: parts.slice(1).join('|') })
//                 }
//             }
//         }
        
//         if (root.micDevice === "" && micModel.count > 0) {
//             root.micDevice = micModel.get(0).devName
//             saveAudioPrefs()
//         }
//     }

//     // --- Geometry State ---
//     property string cachedGeom: Quickshell.env("QS_CACHED_GEOM") || ""
//     property var cachedParts: cachedGeom.trim() !== "" ? cachedGeom.trim().split(",") : []
//     property bool hasValidCache: cachedParts.length === 4 && parseFloat(cachedParts[2]) > 10

//     property real startX: hasValidCache ? parseFloat(cachedParts[0]) : 0
//     property real startY: hasValidCache ? parseFloat(cachedParts[1]) : 0
//     property real endX: hasValidCache ? (parseFloat(cachedParts[0]) + parseFloat(cachedParts[2])) : 0
//     property real endY: hasValidCache ? (parseFloat(cachedParts[1]) + parseFloat(cachedParts[3])) : 0
    
//     // Fluid Geometry Snapping
//     Behavior on startX { enabled: !root.isSelecting; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
//     Behavior on startY { enabled: !root.isSelecting; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
//     Behavior on endX { enabled: !root.isSelecting; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
//     Behavior on endY { enabled: !root.isSelecting; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

//     property bool hasSelection: hasValidCache
//     property bool isSelecting: false
//     property bool isMaximized: false
//     property real preStartX: 0
//     property real preStartY: 0
//     property real preEndX: 0
//     property real preEndY: 0

//     property real selX: Math.min(startX, endX)
//     property real selY: Math.min(startY, endY)
//     property real selW: Math.abs(endX - startX)
//     property real selH: Math.abs(endY - startY)
    
//     property string geometryString: `${Math.round(selX + screen.x)},${Math.round(selY + screen.y)} ${Math.round(selW)}x${Math.round(selH)}`
//     property int interactionMode: 0
//     property real anchorX: 0; property real anchorY: 0
//     property real initX: 0; property real initY: 0
//     property real initW: 0; property real initH: 0

//     // --- QR Scanner State ---
//     property bool isScanningQr: false
//     property bool showQrPopup: false
//     property bool isQrSuccess: false
//     ListModel { id: qrModel }

//     function saveCache() {
//         if (root.hasSelection && !root.isVideoMode) {
//             let data = Math.round(root.selX) + "," + Math.round(root.selY) + "," + Math.round(root.selW) + "," + Math.round(root.selH);
//             Quickshell.execDetached(["bash", "-c", "echo '" + data + "' > ~/.cache/qs_screenshot_geom"]);
//         }
//     }

//     ParallelAnimation {
//         id: maximizeAnim
//         property real targetStartX; property real targetStartY
//         property real targetEndX; property real targetEndY

//         NumberAnimation { target: root; property: "startX"; to: maximizeAnim.targetStartX; duration: 250; easing.type: Easing.InOutQuad }
//         NumberAnimation { target: root; property: "startY"; to: maximizeAnim.targetStartY; duration: 250; easing.type: Easing.InOutQuad }
//         NumberAnimation { target: root; property: "endX"; to: maximizeAnim.targetEndX; duration: 250; easing.type: Easing.InOutQuad }
//         NumberAnimation { target: root; property: "endY"; to: maximizeAnim.targetEndY; duration: 250; easing.type: Easing.InOutQuad }
//         onFinished: root.saveCache()
//     }

//     function toggleMaximize() {
//         if (root.isVideoMode) return;
//         if (!isMaximized) {
//             preStartX = root.startX; preStartY = root.startY;
//             preEndX = root.endX; preEndY = root.endY;
//             maximizeAnim.targetStartX = 0; maximizeAnim.targetStartY = 0;
//             maximizeAnim.targetEndX = root.width; maximizeAnim.targetEndY = root.height;
//             isMaximized = true;
//         } else {
//             maximizeAnim.targetStartX = preStartX; maximizeAnim.targetStartY = preStartY;
//             maximizeAnim.targetEndX = preEndX; maximizeAnim.targetEndY = preEndY;
//             isMaximized = false;
//         }
//         maximizeAnim.restart();
//     }

//     // --- Keyboard Shortcuts ---
//     Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
//     Shortcut { sequence: "Return"; onActivated: { if (root.hasSelection) root.executeCapture(root.isEditMode && !root.isVideoMode, root.isVideoMode) } }
//     Shortcut { sequence: "Tab"; onActivated: root.isVideoMode = !root.isVideoMode }
//     Shortcut { sequence: "Left"; onActivated: root.isVideoMode = false }
//     Shortcut { sequence: "Right"; onActivated: root.isVideoMode = true }
//     Shortcut { sequence: "F11"; onActivated: root.toggleMaximize() }

//     // --- Animated Revealer for Fluid Transitions ---
//     component AnimWrap: Item {
//         property bool isShown: false
//         property real contentWidth: 0
//         property real rightPadding: s(3) // Reducción de padding lateral para los íconos
//         property real targetWidth: contentWidth + rightPadding
        
//         width: isShown ? targetWidth : 0
//         height: parent.height
//         opacity: isShown ? 1.0 : 0.0
//         clip: true
        
//         Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
//         Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
        
//         default property alias content: internalWrapper.children
//         Item { 
//             id: internalWrapper
//             width: contentWidth 
//             height: parent.height 
//         }
//     }

//     // --- Global Reusable Toolbar Button (Matte Edition) ---
//     component ToolbarBtn: Rectangle {
//         id: tBtn
//         property string iconTxt: ""
//         property string label: ""
//         property bool isDanger: false
//         signal clicked()

//         height: s(36)
//         width: label !== "" ? (txt.implicitWidth + s(36)) : s(36)
//         radius: s(18)
        
//         // Idle is a solid base color, full matte filled-look
//         color: tBtn.isDanger ? _theme.red : (maBtn.containsMouse ? _theme.surface1 : _theme.surface0)
//         Behavior on color { ColorAnimation { duration: 150 } }

//         RowLayout {
//             anchors.centerIn: parent; spacing: s(6)
//             Text { 
//                 font.family: "Iosevka Nerd Font"
//                 text: tBtn.iconTxt
//                 color: tBtn.isDanger ? _theme.crust : _theme.text
//                 font.pixelSize: s(18) 
//             }
//             Text { 
//                 id: txt
//                 visible: tBtn.label !== ""
//                 font.family: "JetBrains Mono"
//                 font.weight: Font.DemiBold
//                 text: tBtn.label
//                 color: tBtn.isDanger ? _theme.crust : _theme.text
//                 font.pixelSize: s(13) 
//             }
//         }
//         MouseArea { 
//             id: maBtn
//             anchors.fill: parent
//             hoverEnabled: true
//             cursorShape: Qt.PointingHandCursor
//             onClicked: tBtn.clicked() 
//         }
//     }

//     Item {
//         anchors.fill: parent
//         z: 1
//         Rectangle {
//             anchors.fill: parent
//             color: root.dimColor
//             opacity: (!root.isSelecting && !root.hasSelection) ? 1.0 : 0.0
//             Behavior on opacity { NumberAnimation { duration: 150 } }
//             Text {
//                 anchors.centerIn: parent
//                 text: root.isVideoMode ? "Click Record (Portal handles area selection)" : "Select region to capture"
//                 font.family: "JetBrains Mono"; font.weight: Font.DemiBold; font.pixelSize: s(24); color: _theme.text
//             }
//         }
//         Item {
//             anchors.fill: parent
//             opacity: (root.isSelecting || root.hasSelection) ? 1.0 : 0.0
//             Behavior on opacity { NumberAnimation { duration: 150 } }
//             Rectangle { x: 0; y: 0; width: parent.width; height: root.selY; color: root.dimColor } 
//             Rectangle { x: 0; y: root.selY + root.selH; width: parent.width; height: parent.height - (root.selY + root.selH); color: root.dimColor }
//             Rectangle { x: 0; y: root.selY; width: root.selX; height: root.selH; color: root.dimColor } 
//             Rectangle { x: root.selX + root.selW; y: root.selY; width: parent.width - (root.selX + root.selW); height: root.selH; color: root.dimColor } 
//         }
//     }

//     Rectangle {
//         visible: root.isSelecting || root.hasSelection
//         x: root.selX; y: root.selY; width: root.selW; height: root.selH
//         color: (root.showQrPopup && root.isQrSuccess) ? Qt.alpha(_theme.green, 0.15) : (root.isVideoMode ? Qt.alpha(_theme.red, 0.05) : root.selectionTint)
//         border.color: (root.showQrPopup && root.isQrSuccess) ? _theme.green : (root.isVideoMode ? _theme.red : root.accentColor)
//         border.width: s(4)
//         z: 5
//     }

//     Repeater {
//         model: qrModel
//         delegate: Rectangle {
//             visible: opacity > 0
//             opacity: (root.showQrPopup && model.qSuccess && model.qW > 0) ? 1.0 : 0.0
//             property real pad: (root.showQrPopup && model.qSuccess) ? s(5) : 0
//             x: model.qW > 0 ? (model.qX - pad) : model.qX
//             y: model.qH > 0 ? (model.qY - pad) : model.qY
//             width: model.qW > 0 ? (model.qW + (pad * 2)) : 0
//             height: model.qH > 0 ? (model.qH + (pad * 2)) : 0
//             color: Qt.alpha(_theme.green, 0.25)
//             border.color: _theme.green
//             border.width: s(3)
//             radius: s(8)
//             z: 34
//             Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
//             Behavior on pad { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
//         }
//     }

//     component Handle: Rectangle {
//         width: s(20); height: s(20); radius: s(10)
//         color: root.handleColor; border.color: root.accentColor; border.width: s(4)
//         visible: (root.hasSelection || root.isSelecting) && !root.isScanningQr && !root.showQrPopup && !root.isVideoMode; z: 10
//     }
//     Handle { x: root.selX - width / 2; y: root.selY - height / 2 } 
//     Handle { x: root.selX + root.selW - width / 2; y: root.selY - height / 2 } 
//     Handle { x: root.selX - width / 2; y: root.selY + root.selH - height / 2 } 
//     Handle { x: root.selX + root.selW - width / 2; y: root.selY + root.selH - height / 2 } 

//     MouseArea {
//         anchors.fill: parent
//         hoverEnabled: true
//         acceptedButtons: Qt.LeftButton | Qt.RightButton
//         z: 20 

//         function getInteractionMode(mx, my, mods) {
//             if (!root.hasSelection) return 1; 
//             if (mods & Qt.ShiftModifier) return 2; 
//             let margin = s(20) 
//             let onLeftLine = Math.abs(mx - root.selX) <= margin; 
//             let onRightLine = Math.abs(mx - (root.selX + root.selW)) <= margin
//             let onTopLine = Math.abs(my - root.selY) <= margin; 
//             let onBottomLine = Math.abs(my - (root.selY + root.selH)) <= margin
//             let withinX = mx >= (root.selX - margin) && mx <= (root.selX + root.selW + margin);
//             let withinY = my >= (root.selY - margin) && my <= (root.selY + root.selH + margin);

//             if (onTopLine && onLeftLine) return 3; 
//             if (onTopLine && onRightLine) return 5;
//             if (onBottomLine && onLeftLine) return 8; 
//             if (onBottomLine && onRightLine) return 10;
//             if (onTopLine && withinX) return 4; 
//             if (onBottomLine && withinX) return 9;
//             if (onLeftLine && withinY) return 6; 
//             if (onRightLine && withinY) return 7;
//             return 1;
//         }

//         onPositionChanged: (mouse) => {
//             if (root.isVideoMode) { cursorShape = Qt.ArrowCursor; return; }
//             let mode = root.isSelecting ? root.interactionMode : getInteractionMode(mouse.x, mouse.y, mouse.modifiers)
//             switch(mode) {
//                 case 2: cursorShape = Qt.ClosedHandCursor; break;
//                 case 3: case 10: cursorShape = Qt.SizeFDiagCursor; break;
//                 case 5: case 8: cursorShape = Qt.SizeBDiagCursor; break;
//                 case 4: case 9: cursorShape = Qt.SizeVerCursor; break;
//                 case 6: case 7: cursorShape = Qt.SizeHorCursor; break;
//                 default: cursorShape = Qt.CrossCursor; break;
//             }

//             if (!root.isSelecting) return;
//             let dx = mouse.x - root.anchorX; let dy = mouse.y - root.anchorY
//             let clamp = (val, min, max) => Math.max(min, Math.min(max, val))

//             if (root.interactionMode === 1) { 
//                 root.endX = clamp(mouse.x, 0, root.width); root.endY = clamp(mouse.y, 0, root.height)
//             } else if (root.interactionMode === 2) { 
//                 let targetX = clamp(root.initX + dx, 0, root.width - root.initW); let targetY = clamp(root.initY + dy, 0, root.height - root.initH)
//                 root.startX = targetX; root.startY = targetY; root.endX = targetX + root.initW; root.endY = targetY + root.initH;
//             } else { 
//                 let nx = root.initX, ny = root.initY, nw = root.initW, nh = root.initH
//                 if ([3, 6, 8].includes(root.interactionMode)) { nx = clamp(root.initX + dx, 0, root.initX + root.initW - 10); nw = root.initW + (root.initX - nx) }
//                 if ([5, 7, 10].includes(root.interactionMode)) { nw = clamp(root.initW + dx, 10, root.width - root.initX) }
//                 if ([3, 4, 5].includes(root.interactionMode)) { ny = clamp(root.initY + dy, 0, root.initY + root.initH - 10); nh = root.initH + (root.initY - ny) }
//                 if ([8, 9, 10].includes(root.interactionMode)) { nh = clamp(root.initH + dy, 10, root.height - root.initY) }
//                 root.startX = nx; root.startY = ny; root.endX = nx + nw; root.endY = ny + nh;
//             }
//         }

//         onPressed: (mouse) => {
//             if (mouse.button === Qt.RightButton) { Qt.quit(); return; }
//             if (root.isVideoMode) return; 

//             root.isScanningQr = false;
//             root.showQrPopup = false;
//             qrWaitTimer.stop();

//             maximizeAnim.stop() 
//             root.interactionMode = getInteractionMode(mouse.x, mouse.y, mouse.modifiers)
//             root.isSelecting = true
//             if (root.interactionMode !== 1) root.isMaximized = false;
//             root.anchorX = mouse.x; root.anchorY = mouse.y
//             root.initX = root.selX; root.initY = root.selY; root.initW = root.selW; root.initH = root.selH;

//             if (root.interactionMode === 1) {
//                 let clamp = (val, min, max) => Math.max(min, Math.min(max, val))
//                 let clampedX = clamp(mouse.x, 0, root.width); let clampedY = clamp(mouse.y, 0, root.height)
//                 root.startX = clampedX; root.startY = clampedY; root.endX = clampedX; root.endY = clampedY;
//                 root.hasSelection = false; root.isMaximized = false
//             }
//         }

//         onReleased: {
//             if (root.isSelecting) {
//                 root.isSelecting = false
//                 if (root.selW > 10 && root.selH > 10) {
//                     root.hasSelection = true; root.saveCache()
//                 } else { root.hasSelection = false }
//             }
//         }
//     }

//     // --- Main Bottom Toolbar (Smooth Matte Rounded Rect) ---
//     Item {
//         id: toolbar
//         z: 30 
        
//         // Fully expanded total height
//         property real totalHeight: s(120)
//         property bool fitsOutsideBottom: (root.selY + root.selH + totalHeight + s(15)) <= root.height

//         visible: root.hasSelection && !root.isSelecting && !root.isScanningQr && !root.showQrPopup
        
//         width: Math.max(toolbarRow.width + s(64), s(340))
//         height: totalHeight 

//         x: Math.max(s(10), Math.min(parent.width - width - s(10), root.selX + (root.selW / 2) - (width / 2)))
//         y: fitsOutsideBottom ? (root.selY + root.selH + s(15)) : 
//            ((root.selY - height - s(15)) >= 0 ? (root.selY - height - s(15)) : (root.height - height - s(15)))

//         // The Smooth Translucent Matte Background
//         Rectangle {
//             anchors.fill: parent
//             color: Qt.rgba(_theme.base.r, _theme.base.g, _theme.base.b, 0.85)
//             border.color: Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.08)
//             border.width: s(1)
//             radius: s(24)
//         }

//         component AudioControl: RowLayout {
//             property string iconOn: ""
//             property string iconOff: ""
//             property real volumeValue: 1.0
//             property bool mutedValue: false
//             property bool hasDropdown: false
            
//             signal volumeUpdate(real newVol)
//             signal muteUpdate(bool newMute)
//             signal dropdownClicked()

//             spacing: s(4)

//             Rectangle {
//                 width: s(30); height: s(30); radius: s(15)
//                 // Filled, solid matte-look on idle
//                 color: maIcon.containsMouse ? _theme.surface2 : _theme.surface0
//                 Behavior on color { ColorAnimation { duration: 150 } }

//                 Text {
//                     anchors.centerIn: parent
//                     font.family: "Iosevka Nerd Font"
//                     text: parent.parent.mutedValue ? parent.parent.iconOff : parent.parent.iconOn
//                     color: parent.parent.mutedValue ? _theme.red : _theme.text
//                     font.pixelSize: s(16)
//                 }
//                 MouseArea {
//                     id: maIcon; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                     onClicked: parent.parent.muteUpdate(!parent.parent.mutedValue)
//                 }
//             }

//             Slider {
//                 Layout.preferredWidth: s(60)
//                 from: 0.0; to: 1.0; value: parent.volumeValue
//                 onValueChanged: parent.volumeUpdate(value)

//                 background: Rectangle {
//                     x: parent.leftPadding; y: parent.topPadding + parent.availableHeight / 2 - height / 2
//                     implicitWidth: s(60); implicitHeight: s(4)
//                     width: parent.availableWidth; height: implicitHeight
//                     radius: s(2)
//                     color: _theme.surface2
//                     Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; color: parent.parent.parent.mutedValue ? _theme.subtext0 : _theme.mauve; radius: s(2) }
//                 }
//                 handle: Rectangle {
//                     x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
//                     y: parent.topPadding + parent.availableHeight / 2 - height / 2
//                     implicitWidth: s(12); implicitHeight: s(12); radius: s(6)
//                     color: parent.parent.parent.mutedValue ? _theme.subtext0 : _theme.mauve
//                 }
//             }

//             Rectangle {
//                 visible: parent.hasDropdown
//                 width: s(20); height: s(30); color: "transparent"
//                 Text {
//                     anchors.centerIn: parent
//                     font.family: "Iosevka Nerd Font"
//                     // Correcting dropdown icon orientation base on position relative to fitsOutsideBottom
//                     text: toolbar.fitsOutsideBottom ? "󰅃" : "󰅀" 
//                     color: _theme.text
//                     font.pixelSize: s(16)
//                 }
//                 MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.parent.dropdownClicked() }
//             }
//         }

//         Rectangle {
//             id: micDropdown
//             visible: false
//             width: s(280)
//             height: micModel.count === 0 ? s(40) : Math.min(s(180), micModel.count * s(36))
//             x: -s(140) 
//             // Correcting dropdown positioning
//             y: toolbar.fitsOutsideBottom ? (toolbar.height + s(8)) : (-height - s(8))
//             color: Qt.rgba(_theme.base.r, _theme.base.g, _theme.base.b, 0.95)
//             border.color: Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.08)
//             border.width: s(1)
//             radius: s(12)
//             z: 50

//             Text {
//                 visible: micModel.count === 0
//                 anchors.centerIn: parent
//                 text: "No Microphones (Install pulseaudio)"
//                 color: _theme.subtext0
//                 font.pixelSize: s(12)
//             }

//             ListView {
//                 visible: micModel.count > 0
//                 anchors.fill: parent; anchors.margins: s(4)
//                 model: micModel
//                 clip: true
//                 delegate: Rectangle {
//                     width: ListView.view.width; height: s(32); radius: s(6)
//                     color: maList.containsMouse ? _theme.surface0 : "transparent"
//                     RowLayout {
//                         anchors.fill: parent; anchors.margins: s(6)
//                         Text { text: model.devDesc; color: root.micDevice === model.devName ? _theme.mauve : _theme.text; font.pixelSize: s(12); elide: Text.ElideRight; Layout.fillWidth: true }
//                     }
//                     MouseArea { 
//                         id: maList; anchors.fill: parent; hoverEnabled: true; 
//                         onClicked: { root.micDevice = model.devName; root.saveAudioPrefs(); micDropdown.visible = false } 
//                     }
//                 }
//             }
//         }

//         // Top Content: The Action Tools
//         Row {
//             id: toolbarRow
//             anchors.top: parent.top
//             anchors.topMargin: s(12)
//             anchors.horizontalCenter: parent.horizontalCenter
//             height: root.s(36)
//             spacing: 0

//             // Tab Switcher with Morphing Animation (Stretchy Mauve Pill)
//             Item {
//                 // Width is slightly bigger to handle reducced icon padding on right
//                 width: s(110) + s(3); height: parent.height
                
//                 Rectangle {
//                     width: s(110); height: s(36); radius: s(18) 
//                     color: _theme.surface0
                    
//                     Rectangle {
//                         id: activeHighlight
//                         y: s(2)
//                         height: parent.height - s(4)
//                         radius: s(16) 
//                         color: _theme.mauve
//                         z: 0

//                         property bool curVideoMode: root.isVideoMode
//                         onCurVideoModeChanged: {
//                             // Morph duration/easing when going right vs left
//                             if (curVideoMode) { // Moving right
//                                 rightAnim.duration = 200; leftAnim.duration = 350;
//                             } else { // Moving left
//                                 leftAnim.duration = 200; rightAnim.duration = 350;
//                             }
//                         }

//                         property real targetLeft: curVideoMode ? (parent.width / 2) : s(2)
//                         property real targetRight: targetLeft + (parent.width / 2) - s(2)

//                         property real actualLeft: targetLeft
//                         property real actualRight: targetRight

//                         Behavior on actualLeft { NumberAnimation { id: leftAnim; duration: 250; easing.type: Easing.OutExpo } }
//                         Behavior on actualRight { NumberAnimation { id: rightAnim; duration: 250; easing.type: Easing.OutExpo } }

//                         x: actualLeft
//                         width: actualRight - actualLeft
//                     }
                    
//                     Row {
//                         anchors.fill: parent
//                         z: 1
//                         Item {
//                             width: parent.width / 2; height: parent.height
//                             Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: "󰄄"; color: !root.isVideoMode ? _theme.crust : _theme.text; font.pixelSize: s(16) }
//                             MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.isVideoMode = false }
//                         }
//                         Item {
//                             width: parent.width / 2; height: parent.height
//                             Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: ""; color: root.isVideoMode ? _theme.crust : _theme.text; font.pixelSize: s(16) }
//                             MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.isVideoMode = true }
//                         }
//                     }
//                 }
//             }

//             // Video Controls
//             AnimWrap {
//                 isShown: root.isVideoMode; contentWidth: s(2)
//                 Rectangle { width: s(2); height: s(16); anchors.verticalCenter: parent.verticalCenter; color: _theme.surface0; radius: s(1) }
//             }

//             AnimWrap {
//                 isShown: root.isVideoMode; contentWidth: s(94)
//                 AudioControl { 
//                     id: deskAudio; width: parent.width; height: parent.height
//                     iconOn: "󰓃"; iconOff: "󰓄" 
//                     volumeValue: root.deskVol; mutedValue: root.deskMute
//                     onVolumeUpdate: (v) => { root.deskVol = v; root.saveAudioPrefs() }
//                     onMuteUpdate: (m) => { root.deskMute = m; root.saveAudioPrefs() }
//                 }
//             }
            
//             AnimWrap {
//                 isShown: root.isVideoMode; contentWidth: s(118)
//                 AudioControl { 
//                     id: micAudio; width: parent.width; height: parent.height
//                     iconOn: "󰍬"; iconOff: "󰍭"; hasDropdown: true
//                     volumeValue: root.micVol; mutedValue: root.micMute
//                     onVolumeUpdate: (v) => { root.micVol = v; root.saveAudioPrefs() }
//                     onMuteUpdate: (m) => { root.micMute = m; root.saveAudioPrefs() }
//                     onDropdownClicked: { micDropdown.visible = !micDropdown.visible; micDropdown.x = mapToItem(toolbar, 0, 0).x - s(120) }
//                 }
//             }

//             // Image Controls
//             AnimWrap {
//                 isShown: !root.isVideoMode; contentWidth: s(2)
//                 Rectangle { width: s(2); height: s(16); anchors.verticalCenter: parent.verticalCenter; color: _theme.surface0; radius: s(1) }
//             }

//             AnimWrap {
//                 isShown: !root.isVideoMode; contentWidth: s(36)
//                 ToolbarBtn { iconTxt: "󰏫"; onClicked: root.executeCapture(true, false) }
//             }

//             AnimWrap {
//                 isShown: !root.isVideoMode; contentWidth: s(36)
//                 ToolbarBtn { iconTxt: "⿻"; onClicked: root.performQrScan() }
//             }

//             AnimWrap {
//                 isShown: !root.isVideoMode; contentWidth: s(2)
//                 Rectangle { width: s(2); height: s(16); anchors.verticalCenter: parent.verticalCenter; color: _theme.surface0; radius: s(1) }
//             }
            
//             AnimWrap {
//                 isShown: !root.isVideoMode; contentWidth: s(36)
//                 ToolbarBtn { iconTxt: root.isMaximized ? "" : ""; onClicked: root.toggleMaximize() }
//             }

//             // Universal Close Button
//             Item {
//                 width: s(2) + s(3) + s(36); height: parent.height // Widened width for reducced padding on right
//                 Row {
//                     anchors.verticalCenter: parent.verticalCenter
//                     height: parent.height
//                     spacing: s(3) // Reducción de padding lateral para los íconos en top part
//                     Rectangle { width: s(2); height: s(16); anchors.verticalCenter: parent.verticalCenter; color: _theme.surface0; radius: s(1);}
//                     ToolbarBtn { 
//                         anchors.verticalCenter: parent.verticalCenter
//                         iconTxt: "󰅖"; isDanger: true; onClicked: Qt.quit() 
//                     }
//                 }
//             }
//         }

//         // Bottom Content: Center Capture Layout with Dynamic Gradient Lines
//         Item {
//             id: captureSection
//             anchors.bottom: parent.bottom
//             anchors.bottomMargin: s(12)
//             anchors.horizontalCenter: parent.horizontalCenter
//             width: parent.width
//             height: s(56) // Aumento ligero de altura para el capture circle más grande
//             z: 10

//             // Smooth Left Line + Hover Wave
//             Rectangle {
//                 id: leftLineBase
//                 height: s(4) // Líneas horizontales más gruesas
//                 radius: s(2) // Radio escalado
//                 color: Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.1) // Subtle structural line
//                 anchors.left: parent.left
//                 anchors.leftMargin: s(24)
//                 anchors.right: actionBtnContainer.left
//                 anchors.rightMargin: s(16)
//                 anchors.verticalCenter: parent.verticalCenter
//                 clip: true

//                 // Stretchy gradient 'wave'
//                 Rectangle {
//                     anchors.right: parent.right
//                     anchors.top: parent.top
//                     anchors.bottom: parent.bottom
//                     // Stretches left when hovered
//                     width: actionArea.containsMouse ? parent.width : 0
//                     radius: s(2)
//                     Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.InOutExpo } }
                    
//                     gradient: Gradient {
//                         orientation: Gradient.Horizontal
//                         GradientStop { position: 0.0; color: root.isVideoMode ? _theme.red : root.accentColor }
//                         GradientStop { position: 1.0; color: "transparent" }
//                     }
//                 }
//             }

//             // Central Capture Circle (Slightly Bigger)
//             Item {
//                 id: actionBtnContainer
//                 width: s(56) // Círculo 'capture' un poco más grande
//                 height: width
//                 anchors.centerIn: parent
//                 z: 20
                
//                 Rectangle {
//                     anchors.fill: parent
//                     radius: width / 2
//                     color: "transparent"
//                     border.color: root.isVideoMode ? Qt.alpha(_theme.red, 0.4) : Qt.alpha(_theme.surface1, 0.8)
//                     border.width: s(2)
//                     Behavior on border.color { ColorAnimation { duration: 250 } }
//                 }

//                 Rectangle {
//                     // Círculo interno escalado
//                     width: actionArea.pressed ? s(32) : (actionArea.containsMouse ? s(40) : s(36))
//                     height: width
//                     radius: width / 2
//                     anchors.centerIn: parent
//                     color: root.isVideoMode ? _theme.red : root.accentColor
//                     Behavior on color { ColorAnimation { duration: 250 } }
//                     Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
//                 }

//                 MouseArea {
//                     id: actionArea
//                     anchors.fill: parent
//                     hoverEnabled: true
//                     cursorShape: Qt.PointingHandCursor
//                     onClicked: root.executeCapture(false, root.isVideoMode)
//                 }
//             }

//             // Smooth Right Line + Hover Wave
//             Rectangle {
//                 id: rightLineBase
//                 height: s(4) // Líneas horizontales más gruesas
//                 radius: s(2) // Radio escalado
//                 color: Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.1)
//                 anchors.right: parent.right
//                 anchors.rightMargin: s(24)
//                 anchors.left: actionBtnContainer.right
//                 anchors.leftMargin: s(16)
//                 anchors.verticalCenter: parent.verticalCenter
//                 clip: true

//                 // Stretchy gradient 'wave'
//                 Rectangle {
//                     anchors.left: parent.left
//                     anchors.top: parent.top
//                     anchors.bottom: parent.bottom
//                     // Stretches right when hovered
//                     width: actionArea.containsMouse ? parent.width : 0
//                     radius: s(2)
//                     Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.InOutExpo } }
                    
//                     gradient: Gradient {
//                         orientation: Gradient.Horizontal
//                         GradientStop { position: 0.0; color: "transparent" }
//                         GradientStop { position: 1.0; color: root.isVideoMode ? _theme.red : root.accentColor }
//                     }
//                 }
//             }
//         }
//     }

//     // --- QR Popup and Backend Hooks ---
//     Repeater {
//         model: qrModel
//         delegate: Rectangle {
//             id: qrPopupItem
//             visible: opacity > 0
//             opacity: (root.showQrPopup && !root.isSelecting) ? 1.0 : 0.0
            
//             x: model.qTargetX
//             y: model.qTargetY + (model.fitsTop ? (1.0 - opacity) * s(15) : -(1.0 - opacity) * s(15))
            
//             width: qrPopupLayout.implicitWidth + s(32)
//             height: s(52)
//             radius: s(26)
//             color: _theme.base
//             border.color: model.qSuccess ? _theme.green : _theme.red
//             border.width: s(2)

//             property bool isHovered: maHover.containsMouse
//             scale: isHovered ? 1.0 : model.qBaseScale
//             z: isHovered ? 100 : (40 - index)
//             transformOrigin: Item.Center

//             Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
//             Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

//             MouseArea { id: maHover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }

//             RowLayout {
//                 id: qrPopupLayout
//                 anchors.centerIn: parent
//                 spacing: s(8)

//                 Text {
//                     text: model.qText
//                     color: model.qSuccess ? _theme.text : _theme.red
//                     font.family: "JetBrains Mono"
//                     font.pixelSize: s(13)
//                     font.weight: Font.DemiBold
//                     Layout.maximumWidth: s(400)
//                     Layout.leftMargin: s(8)
//                     elide: Text.ElideRight
//                     wrapMode: Text.NoWrap
//                 }

//                 Rectangle { visible: model.qSuccess; width: s(2); Layout.fillHeight: true; Layout.topMargin: s(10); Layout.bottomMargin: s(10); color: _theme.surface0; radius: s(1) }

//                 ToolbarBtn {
//                     visible: model.qSuccess
//                     iconTxt: "󰆏"
//                     onClicked: {
//                         Quickshell.execDetached(["bash", "-c", `echo -n '${model.qText.replace(/'/g, "'\\''")}' | wl-copy`]);
//                         root.showQrPopup = false;
//                     }
//                 }

//                 ToolbarBtn {
//                     visible: model.qSuccess && (model.qText.startsWith("http://") || model.qText.startsWith("https://"))
//                     iconTxt: "󰌹"
//                     onClicked: {
//                         Quickshell.execDetached(["xdg-open", model.qText]);
//                         Qt.quit();
//                     }
//                 }

//                 Rectangle { width: s(2); Layout.fillHeight: true; Layout.topMargin: s(10); Layout.bottomMargin: s(10); color: _theme.surface0; radius: s(1) }
//                 ToolbarBtn { iconTxt: "󰅖"; isDanger: true; onClicked: root.showQrPopup = false }
//             }
//         }
//     }

//     Process {
//         id: qrReaderProcess
//         property string accumulated: ""
//         command: ["cat", "/tmp/qs_qr_result"]
//         stdout: SplitParser { splitMarker: ""; onRead: data => qrReaderProcess.accumulated += data }
        
//         onExited: (exitCode) => {
//             let res = qrReaderProcess.accumulated.trim()
//             qrReaderProcess.accumulated = ""
//             root.isScanningQr = false
//             qrModel.clear()
    
//             if (exitCode !== 0 || res === "") {
//                 qrModel.append({ 
//                     qX: root.selX + (root.selW / 2), qY: root.selY + (root.selH / 2), qW: 0, qH: 0, 
//                     qText: "Scan timed out or failed.", qSuccess: false,
//                     qTargetX: root.selX + (root.selW / 2) - s(100), qTargetY: root.selY + (root.selH / 2),
//                     qBaseScale: 1.0, fitsTop: false 
//                 })
//                 root.isQrSuccess = false
//                 root.showQrPopup = true
//                 return
//             }

//             let lines = res.split('\n');
//             let anySuccess = false;
//             let qrs = [];

//             for (let i = 0; i < lines.length; i++) {
//                 let line = lines[i].trim();
//                 if (line === "") continue;
//                 let delimiterIdx = line.indexOf('|||');
//                 if (delimiterIdx === -1) continue;

//                 let coordStr = line.substring(0, delimiterIdx);
//                 let actualText = line.substring(delimiterIdx + 3).replace(/\\n/g, '\n').replace(/\\\\/g, '\\');
//                 let coords = coordStr.split(',');

//                 if (coords.length === 4 && !isNaN(parseInt(coords[0]))) {
//                     let x = parseInt(coords[0]); let y = parseInt(coords[1]); let w = parseInt(coords[2]); let h = parseInt(coords[3]);
                    
//                     let successState = !(actualText === "NOT_FOUND" || actualText.startsWith("ERROR:"));
//                     if (successState) anySuccess = true;
//                     let cleanText = successState ? actualText.replace(/^QR-Code:/, "") : (actualText === "NOT_FOUND" ? "No QR code found." : actualText);
                    
//                     let estTextWidth = Math.min(s(400), cleanText.length * s(8.5));
//                     let pw = estTextWidth + (successState ? s(140) : s(40)); 
//                     let ph = s(52);
//                     let absX = root.selX + x; let absY = root.selY + y;
//                     let cx = absX + (w / 2);
//                     let fitsTop = (absY - ph - s(15)) >= root.selY;
//                     let idealX = cx - (pw / 2);
//                     let targetX = Math.max(s(10), Math.min(root.width - pw - s(10), idealX));
//                     let targetY = fitsTop ? (absY - ph - s(15)) : (absY + h + s(15));

//                     qrs.push({ qX: absX, qY: absY, qW: w, qH: h, qText: cleanText, qSuccess: successState, pw: pw, ph: ph, targetX: targetX, targetY: targetY, cx: targetX + (pw / 2), cy: targetY + (ph / 2), scale: 1.0, fitsTop: fitsTop });
//                 }
//             }

//             for (let pass = 0; pass < 5; pass++) {
//                 for (let i = 0; i < qrs.length; i++) {
//                     for (let j = i + 1; j < qrs.length; j++) {
//                         let A = qrs[i]; let B = qrs[j];
//                         let dx = Math.abs(A.cx - B.cx); let dy = Math.abs(A.cy - B.cy);
//                         let req_x = (A.pw * A.scale + B.pw * B.scale) / 2 + s(10);
//                         let req_y = (A.ph * A.scale + B.ph * B.scale) / 2 + s(10);
                        
//                         if (dx < req_x && dy < req_y) {
//                             let factorX = dx > 0 ? (dx - s(10)) * 2 / (A.pw + B.pw) : 0;
//                             let factorY = dy > 0 ? (dy - s(10)) * 2 / (A.ph + B.ph) : 0;
//                             let maxFactor = Math.max(factorX, factorY);
//                             maxFactor = Math.max(0.35, maxFactor); 
//                             A.scale = Math.min(A.scale, maxFactor); B.scale = Math.min(B.scale, maxFactor);
//                         }
//                     }
//                 }
//             }

//             if (qrs.length === 0) {
//                 qrModel.append({ 
//                     qX: root.selX + (root.selW / 2), qY: root.selY + (root.selH / 2), qW: 0, qH: 0, 
//                     qText: "No QR code found.", qSuccess: false,
//                     qTargetX: root.selX + (root.selW / 2) - s(100), qTargetY: root.selY + (root.selH / 2),
//                     qBaseScale: 1.0, fitsTop: false 
//                 });
//             } else {
//                 for (let i = 0; i < qrs.length; i++) {
//                     qrModel.append({ qX: qrs[i].qX, qY: qrs[i].qY, qW: qrs[i].qW, qH: qrs[i].qH, qText: qrs[i].qText, qSuccess: qrs[i].qSuccess, qTargetX: qrs[i].targetX, qTargetY: qrs[i].targetY, qBaseScale: qrs[i].scale, fitsTop: qrs[i].fitsTop });
//                 }
//             }

//             root.isQrSuccess = anySuccess;
//             root.showQrPopup = true
//             Quickshell.execDetached(["bash", "-c", "rm -f /tmp/qs_qr_result"])
//         }
//     }
    
//     Timer {
//         id: qrWaitTimer
//         interval: 1200  
//         repeat: false
//         onTriggered: qrReaderProcess.running = true
//     }
    
//     function performQrScan() {
//         Quickshell.execDetached(["bash", "-c", "rm -f /tmp/qs_qr_result"])
//         root.isScanningQr = true; root.showQrPopup = false; qrModel.clear()
//         let cmd = `bash ~/.config/hypr/scripts/screenshot.sh --geometry "${root.geometryString}" --scan-qr`
//         Quickshell.execDetached(["bash", "-c", cmd])
//         qrWaitTimer.start()
//     }   
    
//     Timer {
//         id: captureTimer
//         property string pendingCmd: ""
//         interval: 80
//         repeat: false
//         onTriggered: {
//             Quickshell.execDetached(["bash", "-c", pendingCmd])
//             Qt.quit()
//         }
//     }
    
//     function executeCapture(openEditor, isRecord) {
//         let cmd = `bash ~/.config/hypr/scripts/screenshot.sh --geometry "${root.geometryString}"`
//         if (isRecord) {
//             cmd += " --record"
//             cmd += ` --desk-vol ${root.deskVol} --desk-mute ${root.deskMute}`
//             cmd += ` --mic-vol ${root.micVol} --mic-mute ${root.micMute}`
//             if (root.micDevice !== "") cmd += ` --mic-dev "${root.micDevice}"`
//         }
//         if (openEditor) cmd += " --edit"
    
//         root.visible = false
//         captureTimer.pendingCmd = cmd
//         captureTimer.start()
//     }
// }




import QtQuick
// ^ Imports the QtQuick module, providing all basic QML types including Item, Rectangle, Text, animations, bindings, and the component system.

import QtQuick.Window
// ^ Imports the Window module for accessing screen coordinates and dimensions, used to calculate the absolute geometry string including screen offset.

import QtQuick.Controls
// ^ Imports Qt Quick Controls, providing Slider for audio volume control and Shortcut for keyboard bindings.

import QtQuick.Layouts
// ^ Imports the Layouts module, providing RowLayout and Layout fill properties for responsive toolbar arrangement.

import Quickshell
// ^ Imports the Quickshell module for PanelWindow, Process management, environment variables, and Wayland shell integration.

import Quickshell.Wayland
// ^ Imports Quickshell Wayland for WlrLayershell configuration (layer, namespace, keyboard focus) and WlrKeyboardFocus exclusivity.

import Quickshell.Io
// ^ Imports Quickshell Io for StdioCollector used in Process output capture.

PanelWindow {
    // ^ The root element is a PanelWindow—a Quickshell-specific window that integrates with the Wayland layer shell protocol, perfect for overlays and popups.

    id: root
    // ^ Assigns the global identifier "root" for referencing this overlay from all nested components.

    color: "transparent"
    // ^ Makes the window background completely transparent so only the drawn overlay elements are visible.

    WlrLayershell.namespace: "qs-screenshot-overlay"
    // ^ Sets a unique layer shell namespace identifying this surface to the compositor, preventing conflicts with other QuickShell windows.

    WlrLayershell.layer: WlrLayer.Overlay
    // ^ Places this window on the Overlay layer, above regular windows, panels, and most other content—ideal for a screenshot selection tool.

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    // ^ Requests exclusive keyboard focus, meaning this overlay captures ALL keyboard input while visible, preventing key presses from reaching windows below (essential for shortcut keys to work).

    exclusionMode: ExclusionMode.Ignore 
    // ^ Prevents this panel from pushing other layer surfaces out of the way—it simply floats over everything.

    focusable: true
    // ^ Allows this window to receive and maintain keyboard focus.

    screen: Quickshell.cursorScreen
    // ^ Assigns this overlay to the screen where the mouse cursor is currently located, ensuring the screenshot tool appears on the correct monitor in multi-display setups.

    width: screen.width
    // ^ Matches the width of the assigned screen, covering the entire display.

    height: screen.height
    // ^ Matches the height of the assigned screen, providing full-screen coverage for region selection.

    Scaler { id: scaler; currentWidth: width }
    // ^ Instantiates the Scaler component with the current window width to calculate a base scale factor for responsive sizing. The scaler adapts all UI element sizes proportionally to the screen resolution.

    function s(val) { return scaler.s(val); }
    // ^ Convenience function that scales a design-time pixel value to the appropriate runtime size using the scaler. All UI elements use this function (e.g., `s(20)`) to maintain consistent proportions across different screen sizes.

    MatugenColors { id: _theme }
    // ^ Instantiates the MatugenColors component to access the system's Material You color scheme, providing theme-consistent colors throughout the overlay.

    property color dimColor: Qt.alpha(_theme.crust, 0.50)
    // ^ Creates a semi-transparent dimming color from the crust color at 50% opacity. Used for the dark overlay outside the selection rectangle.

    property color selectionTint: Qt.alpha(_theme.mauve, 0.05)
    // ^ Creates a very subtle mauve tint (5% opacity) for the interior of the selection rectangle, giving a gentle visual indication of the selected area.

    property color handleColor: _theme.text
    // ^ The color for the corner resize handles, using the primary text color for clear visibility.

    property color accentColor: _theme.mauve
    // ^ The primary accent color (mauve) used for borders, active highlights, and interactive elements throughout the overlay.

    property bool isEditMode: Quickshell.env("QS_SCREENSHOT_EDIT") === "true"
    // ^ Reads the QS_SCREENSHOT_EDIT environment variable (set by the screenshot.sh script) to determine if the screenshot should open in the editor after capture. Compares to string "true" to set the boolean.

    property string cachedMode: Quickshell.env("QS_CACHED_MODE") || "false"
    // ^ Reads the cached mode from the QS_CACHED_MODE environment variable, defaulting to "false" (image mode) if not set. This restores the user's previous mode selection.

    property bool isVideoMode: cachedMode === "true"
    // ^ Converts the cached mode string to a boolean. When true, the overlay is in video recording mode (showing audio controls); when false, it's in screenshot mode.

    onIsVideoModeChanged: {
        // ^ Called whenever the user switches between screenshot and video recording modes.

        Quickshell.execDetached(["bash", "-c", "echo '" + (root.isVideoMode ? "true" : "false") + "' > ~/.cache/qs_screenshot_mode"]);
        // ^ Persists the current mode to a cache file so it's restored on next use.

        // Smart Geometry Snapping for Portal Support
        if (root.isVideoMode) {
            // ^ When switching to video mode.

            root.preStartX = root.startX; 
            root.preStartY = root.startY;
            root.preEndX = root.endX; 
            root.preEndY = root.endY;
            // ^ Saves the current selection geometry so it can be restored when switching back to image mode.

            root.startX = 0; 
            root.startY = 0; 
            root.endX = root.width; 
            root.endY = root.height;
            // ^ Automatically expands the selection to cover the entire screen in video mode. This is necessary because screen recording via the portal captures the full screen—the portal handles its own region selection.

            root.hasSelection = true;
            // ^ Marks that a selection exists (the full screen).
        } else {
            // ^ When switching back to image mode.

            root.startX = root.preStartX; 
            root.startY = root.preStartY;
            root.endX = root.preEndX; 
            root.endY = root.preEndY;
            // ^ Restores the previously saved image selection geometry.

            if (Math.abs(root.endX - root.startX) < 10 || Math.abs(root.endY - root.startY) < 10) {
                // ^ If the restored selection is too small (less than 10px in either dimension).
                root.hasSelection = false;
                // ^ Clears the selection so the user can draw a new one.
            }
        }
    }
    
    // --- Audio State Persistence ---
    property real deskVol: Quickshell.env("QS_DESK_VOL") ? parseFloat(Quickshell.env("QS_DESK_VOL")) : 1.0
    // ^ Reads the desktop audio volume from the QS_DESK_VOL environment variable, parsing it as a float. Defaults to 1.0 (100%) if not set. This restores the user's previous desktop audio level.

    property bool deskMute: Quickshell.env("QS_DESK_MUTE") === "true"
    // ^ Reads the desktop audio mute state from the QS_DESK_MUTE environment variable. True if the string equals "true", false otherwise.

    property real micVol: Quickshell.env("QS_MIC_VOL") ? parseFloat(Quickshell.env("QS_MIC_VOL")) : 1.0
    // ^ Reads the microphone volume from QS_MIC_VOL environment variable, defaulting to 1.0 (100%).

    property bool micMute: Quickshell.env("QS_MIC_MUTE") === "true"
    // ^ Reads the microphone mute state from QS_MIC_MUTE environment variable.

    property string micDevice: Quickshell.env("QS_MIC_DEV") || ""
    // ^ Reads the selected microphone device name from QS_MIC_DEV environment variable, defaulting to empty string if not set.

    function saveAudioPrefs() {
        // ^ Persists all audio settings to a cache file so they survive overlay restarts.

        let data = `${deskVol},${deskMute},${micVol},${micMute},${micDevice}`
        // ^ Constructs a comma-separated string of all audio preferences.

        Quickshell.execDetached(["bash", "-c", `echo '${data}' > ~/.cache/qs_audio_prefs`])
        // ^ Writes the preference string to the audio prefs cache file in a detached background process.
    }

    // --- Dynamic Mic Loader ---
    ListModel { id: micModel }
    // ^ A ListModel that will hold the list of available microphone devices. Each entry contains devName and devDesc properties. Populated on component completion.

    Component.onCompleted: {
        // ^ Runs once when the overlay finishes initializing.

        let micData = Quickshell.env("QS_MIC_LIST") || ""
        // ^ Reads the QS_MIC_LIST environment variable (set by screenshot.sh), which contains a newline-separated list of microphone devices in "name|description" format.

        if (micData.trim() !== "") {
            // ^ If microphone data was provided.
            let lines = micData.trim().split('\n')
            // ^ Splits the data into individual lines.
            for (let line of lines) {
                // ^ Iterates over each microphone entry.
                let parts = line.split('|')
                // ^ Splits by the pipe character to separate device name and description.
                if (parts.length >= 2) {
                    // ^ If both name and description are present.
                    micModel.append({ devName: parts[0], devDesc: parts.slice(1).join('|') })
                    // ^ Appends the device to the model. Uses slice(1).join('|') to handle descriptions that contain pipe characters.
                }
            }
        }
        
        if (root.micDevice === "" && micModel.count > 0) {
            // ^ If no microphone was previously selected but devices are available.
            root.micDevice = micModel.get(0).devName
            // ^ Selects the first available microphone as default.
            saveAudioPrefs()
            // ^ Saves this default selection to the cache.
        }
    }

    // --- Geometry State ---
    property string cachedGeom: Quickshell.env("QS_CACHED_GEOM") || ""
    // ^ Reads the previously cached selection geometry from the QS_CACHED_GEOM environment variable (set by screenshot.sh). Empty string if no previous selection.

    property var cachedParts: cachedGeom.trim() !== "" ? cachedGeom.trim().split(",") : []
    // ^ Splits the cached geometry string by commas into an array. Empty array if no cached geometry exists.

    property bool hasValidCache: cachedParts.length === 4 && parseFloat(cachedParts[2]) > 10
    // ^ Validates the cache: must have exactly 4 parts (x, y, w, h) AND the width (index 2) must be greater than 10px (a meaningful selection, not a stray click).

    property real startX: hasValidCache ? parseFloat(cachedParts[0]) : 0
    // ^ Sets the selection start X coordinate from cache if valid, otherwise 0 (top-left corner).

    property real startY: hasValidCache ? parseFloat(cachedParts[1]) : 0
    // ^ Sets the selection start Y from cache or 0.

    property real endX: hasValidCache ? (parseFloat(cachedParts[0]) + parseFloat(cachedParts[2])) : 0
    // ^ Calculates the end X from cache (startX + width) if valid, otherwise 0.

    property real endY: hasValidCache ? (parseFloat(cachedParts[1]) + parseFloat(cachedParts[3])) : 0
    // ^ Calculates the end Y from cache (startY + height) if valid, otherwise 0.
    
    // Fluid Geometry Snapping
    Behavior on startX { enabled: !root.isSelecting; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
    // ^ Animates startX changes smoothly over 350ms when NOT actively dragging a selection. The exponential easing creates a natural settling effect when switching modes or restoring geometry.

    Behavior on startY { enabled: !root.isSelecting; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
    // ^ Same smooth animation for startY changes.

    Behavior on endX { enabled: !root.isSelecting; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
    // ^ Smooth endX animation when not dragging.

    Behavior on endY { enabled: !root.isSelecting; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
    // ^ Smooth endY animation for polished transitions.

    property bool hasSelection: hasValidCache
    // ^ Tracks whether a valid selection exists. Initially based on the cache validity, updated as the user interacts.

    property bool isSelecting: false
    // ^ Tracks whether the user is currently in the process of drawing a new selection rectangle.

    property bool isMaximized: false
    // ^ Tracks whether the selection is maximized to the full screen. Toggled by the maximize button or F11 key.

    property real preStartX: 0
    // ^ Stores the selection start X before maximizing, enabling restoration of the previous selection.

    property real preStartY: 0
    // ^ Stores the selection start Y before maximizing.

    property real preEndX: 0
    // ^ Stores the selection end X before maximizing.

    property real preEndY: 0
    // ^ Stores the selection end Y before maximizing.

    property real selX: Math.min(startX, endX)
    // ^ Calculates the actual left edge of the selection (minimum of start and end X), handling selections drawn in any direction.

    property real selY: Math.min(startY, endY)
    // ^ Calculates the actual top edge of the selection (minimum of start and end Y).

    property real selW: Math.abs(endX - startX)
    // ^ Calculates the absolute width of the selection, regardless of drag direction.

    property real selH: Math.abs(endY - startY)
    // ^ Calculates the absolute height of the selection.

    property string geometryString: `${Math.round(selX + screen.x)},${Math.round(selY + screen.y)} ${Math.round(selW)}x${Math.round(selH)}`
    // ^ Constructs the grim-compatible geometry string in "x,y widthxheight" format. Adds screen.x and screen.y offsets to convert from window-local coordinates to global screen coordinates for multi-monitor setups. Values are rounded to integers.

    property int interactionMode: 0
    // ^ Tracks the current interaction mode: 0=none, 1=drawing new selection, 2=moving selection, 3-10=resizing from various edges/corners.

    property real anchorX: 0; property real anchorY: 0
    // ^ Stores the mouse position when a drag operation begins, used as the reference point for calculating deltas.

    property real initX: 0; property real initY: 0; property real initW: 0; property real initH: 0
    // ^ Stores the initial selection geometry at the start of a move or resize operation, enabling delta-based transformations.

    // --- QR Scanner State ---
    property bool isScanningQr: false
    // ^ Tracks whether a QR code scan is currently in progress (waiting for the backend script to complete).

    property bool showQrPopup: false
    // ^ Controls visibility of the QR code result popups.

    property bool isQrSuccess: false
    // ^ Tracks whether the QR scan found at least one successful decode. Affects the selection rectangle color (green for success).

    ListModel { id: qrModel }
    // ^ Holds the QR code scan results. Each entry contains position data (qX, qY, qW, qH), decoded text, success status, and popup positioning info.

    function saveCache() {
        // ^ Persists the current selection geometry to a cache file if a valid selection exists.

        if (root.hasSelection && !root.isVideoMode) {
            // ^ Only saves if there's a valid selection AND we're not in video mode (video mode uses full screen, no need to cache).

            let data = Math.round(root.selX) + "," + Math.round(root.selY) + "," + Math.round(root.selW) + "," + Math.round(root.selH);
            // ^ Constructs the cache string: "x,y,width,height" with rounded integer values.

            Quickshell.execDetached(["bash", "-c", "echo '" + data + "' > ~/.cache/qs_screenshot_geom"]);
            // ^ Writes the geometry data to the cache file.
        }
    }

    ParallelAnimation {
        // ^ A reusable animation that smoothly transitions the selection rectangle between states (e.g., maximizing/restoring).

        id: maximizeAnim
        // ^ Identifier for referencing the animation.

        property real targetStartX; property real targetStartY
        // ^ Target start coordinates for the animation.

        property real targetEndX; property real targetEndY
        // ^ Target end coordinates for the animation.

        NumberAnimation { target: root; property: "startX"; to: maximizeAnim.targetStartX; duration: 250; easing.type: Easing.InOutQuad }
        // ^ Animates startX to its target over 250ms with smooth quadratic easing.

        NumberAnimation { target: root; property: "startY"; to: maximizeAnim.targetStartY; duration: 250; easing.type: Easing.InOutQuad }
        // ^ Animates startY simultaneously.

        NumberAnimation { target: root; property: "endX"; to: maximizeAnim.targetEndX; duration: 250; easing.type: Easing.InOutQuad }
        // ^ Animates endX simultaneously.

        NumberAnimation { target: root; property: "endY"; to: maximizeAnim.targetEndY; duration: 250; easing.type: Easing.InOutQuad }
        // ^ Animates endY simultaneously, completing the smooth selection morph.

        onFinished: root.saveCache()
        // ^ Once the animation completes, saves the new geometry to the cache.
    }

    function toggleMaximize() {
        // ^ Toggles the selection between its previous size and full screen.

        if (root.isVideoMode) return;
        // ^ Maximize has no effect in video mode since it's already full screen.

        if (!isMaximized) {
            // ^ If currently not maximized, save current geometry and expand to full screen.

            preStartX = root.startX; preStartY = root.startY;
            preEndX = root.endX; preEndY = root.endY;
            // ^ Saves the current geometry for restoration.

            maximizeAnim.targetStartX = 0; maximizeAnim.targetStartY = 0;
            maximizeAnim.targetEndX = root.width; maximizeAnim.targetEndY = root.height;
            // ^ Sets targets to cover the entire screen.

            isMaximized = true;
            // ^ Updates state.
        } else {
            // ^ If currently maximized, restore previous geometry.

            maximizeAnim.targetStartX = preStartX; maximizeAnim.targetStartY = preStartY;
            maximizeAnim.targetEndX = preEndX; maximizeAnim.targetEndY = preEndY;
            // ^ Sets targets to the previously saved geometry.

            isMaximized = false;
            // ^ Updates state.
        }

        maximizeAnim.restart();
        // ^ Starts (or restarts) the animation to transition smoothly.
    }

    // --- Keyboard Shortcuts ---
    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
    // ^ Pressing Escape closes the screenshot overlay without capturing.

    Shortcut { sequence: "Return"; onActivated: { if (root.hasSelection) root.executeCapture(root.isEditMode && !root.isVideoMode, root.isVideoMode) } }
    // ^ Pressing Enter captures the selection. Passes edit mode only for screenshots (not video), and passes the current mode (video or image).

    Shortcut { sequence: "Tab"; onActivated: root.isVideoMode = !root.isVideoMode }
    // ^ Pressing Tab toggles between screenshot and video recording modes.

    Shortcut { sequence: "Left"; onActivated: root.isVideoMode = false }
    // ^ Left arrow switches to image/screenshot mode.

    Shortcut { sequence: "Right"; onActivated: root.isVideoMode = true }
    // ^ Right arrow switches to video recording mode.

    Shortcut { sequence: "F11"; onActivated: root.toggleMaximize() }
    // ^ F11 toggles the maximize/restore of the selection rectangle.

    // --- Animated Revealer for Fluid Transitions ---
    component AnimWrap: Item {
        // ^ Defines a reusable component (using the `component` keyword, a Qt 6 feature) that smoothly reveals/hides its content with animated width and opacity. Used extensively in the toolbar to show/hide mode-specific controls.

        property bool isShown: false
        // ^ Controls whether the content is visible (expanded) or hidden (collapsed).

        property real contentWidth: 0
        // ^ The natural width of the content being wrapped. This determines the expanded width.

        property real rightPadding: s(3) // Reducción de padding lateral para los íconos
        // ^ Small padding (3 scaled pixels) added to the content width for breathing room. Comment notes this reduces lateral padding for icons.

        property real targetWidth: contentWidth + rightPadding
        // ^ The total width when expanded: content width plus padding.

        width: isShown ? targetWidth : 0
        // ^ Binds the actual width: full target width when shown, zero when hidden.

        height: parent.height
        // ^ Matches the parent height for proper vertical alignment.

        opacity: isShown ? 1.0 : 0.0
        // ^ Fully opaque when shown, transparent when hidden.

        clip: true
        // ^ Clips content when the width is smaller than the content, preventing overflow during animation.

        Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
        // ^ Smoothly animates width changes over 350ms with quartic easing out for a polished expand/collapse effect.

        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
        // ^ Smoothly animates opacity with the same timing, creating a cohesive reveal animation.

        default property alias content: internalWrapper.children
        // ^ Makes any children declared inside AnimWrap automatically become children of the internalWrapper, enabling clean syntax like `AnimWrap { ... }`.

        Item { 
            // ^ Internal wrapper that holds the actual content at its natural width.

            id: internalWrapper
            // ^ Identifier for the content container.

            width: contentWidth 
            // ^ Fixed at the natural content width, not affected by the outer animation.

            height: parent.height 
            // ^ Matches parent height.
        }
    }

    // --- Global Reusable Toolbar Button (Matte Edition) ---
    component ToolbarBtn: Rectangle {
        // ^ Defines a reusable toolbar button component with a matte finish, hover effects, and optional danger mode (red).

        id: tBtn
        // ^ Internal identifier for the button instance.

        property string iconTxt: ""
        // ^ The icon text to display (uses Nerd Font glyphs).

        property string label: ""
        // ^ Optional text label to show alongside the icon. Empty by default (icon-only mode).

        property bool isDanger: false
        // ^ When true, colors the button red for destructive actions like close/cancel.

        signal clicked()
        // ^ Signal emitted when the button is clicked.

        height: s(36)
        // ^ Fixed height of 36 scaled pixels.

        width: label !== "" ? (txt.implicitWidth + s(36)) : s(36)
        // ^ Dynamic width: if there's a label, measures the text width and adds padding. Otherwise, same as height for a square icon-only button.

        radius: s(18)
        // ^ Half the height for a perfect pill shape (fully rounded ends).
        
        // Idle is a solid base color, full matte filled-look
        color: tBtn.isDanger ? _theme.red : (maBtn.containsMouse ? _theme.surface1 : _theme.surface0)
        // ^ Background color: red for danger buttons, elevated surface1 on hover, base surface0 when idle. All solid fills for the matte aesthetic.

        Behavior on color { ColorAnimation { duration: 150 } }
        // ^ Quick 150ms color transition for responsive hover feedback.

        RowLayout {
            // ^ Horizontally arranges the icon and optional label.

            anchors.centerIn: parent; spacing: s(6)
            // ^ Centered in the button with small spacing between icon and text.

            Text { 
                font.family: "Iosevka Nerd Font"
                // ^ Nerd Font for the icon glyph.

                text: tBtn.iconTxt
                // ^ Displays the icon character.

                color: tBtn.isDanger ? _theme.crust : _theme.text
                // ^ Crust color (darkest) for danger buttons (contrast against red), normal text color otherwise.

                font.pixelSize: s(18) 
                // ^ 18px scaled icon size.
            }

            Text { 
                id: txt
                // ^ Identifier for measuring implicitWidth above.

                visible: tBtn.label !== ""
                // ^ Only visible when a label is provided.

                font.family: "JetBrains Mono"
                // ^ Monospace font for the label text.

                font.weight: Font.DemiBold
                // ^ Semi-bold weight for legibility.

                text: tBtn.label
                // ^ Displays the button label.

                color: tBtn.isDanger ? _theme.crust : _theme.text
                // ^ Matching color logic with the icon.

                font.pixelSize: s(13) 
                // ^ Slightly smaller text for the label.
            }
        }

        MouseArea { 
            id: maBtn
            // ^ Identifier for the containsMouse binding above.

            anchors.fill: parent
            // ^ Fills the entire button.

            hoverEnabled: true
            // ^ Enables hover detection for the visual effect.

            cursorShape: Qt.PointingHandCursor
            // ^ Shows a pointing hand cursor on hover, indicating clickability.

            onClicked: tBtn.clicked() 
            // ^ Emits the clicked signal when the button is pressed.
        }
    }

    Item {
        // ^ The main overlay background layer containing the dimming rectangles and instructional text.

        anchors.fill: parent
        // ^ Covers the entire screen.

        z: 1
        // ^ Rendered just above the base layer, below the interactive elements.

        Rectangle {
            // ^ The full-screen dimming overlay shown when no selection exists.

            anchors.fill: parent
            // ^ Covers the entire screen.

            color: root.dimColor
            // ^ Semi-transparent crust color (50% opacity) for the dimming effect.

            opacity: (!root.isSelecting && !root.hasSelection) ? 1.0 : 0.0
            // ^ Fully visible only when no selection is active (idle state). Fades out when the user starts selecting or a selection exists.

            Behavior on opacity { NumberAnimation { duration: 150 } }
            // ^ Quick 150ms fade transition.

            Text {
                // ^ Instructional text shown when no selection exists.

                anchors.centerIn: parent
                // ^ Centered on screen.

                text: root.isVideoMode ? "Click Record (Portal handles area selection)" : "Select region to capture"
                // ^ Context-aware instruction: in video mode, explains that the portal handles selection; in image mode, prompts the user to select a region.

                font.family: "JetBrains Mono"; font.weight: Font.DemiBold; font.pixelSize: s(24); color: _theme.text
                // ^ Large, bold, monospace text in the theme's text color.
            }
        }

        Item {
            // ^ Container for the four dimming rectangles that create the "cutout" effect around the selection.

            anchors.fill: parent
            // ^ Fills the screen.

            opacity: (root.isSelecting || root.hasSelection) ? 1.0 : 0.0
            // ^ Visible only when selecting or a selection exists (the cutout view).

            Behavior on opacity { NumberAnimation { duration: 150 } }
            // ^ Smooth fade transition.

            Rectangle { x: 0; y: 0; width: parent.width; height: root.selY; color: root.dimColor } 
            // ^ Top dimming rectangle: spans the full width, from the top edge down to the top of the selection.

            Rectangle { x: 0; y: root.selY + root.selH; width: parent.width; height: parent.height - (root.selY + root.selH); color: root.dimColor }
            // ^ Bottom dimming rectangle: spans full width, from below the selection to the bottom edge.

            Rectangle { x: 0; y: root.selY; width: root.selX; height: root.selH; color: root.dimColor } 
            // ^ Left dimming rectangle: from the left edge to the left of the selection, matching the selection's height.

            Rectangle { x: root.selX + root.selW; y: root.selY; width: parent.width - (root.selX + root.selW); height: root.selH; color: root.dimColor } 
            // ^ Right dimming rectangle: from the right of the selection to the right edge of the screen.
        }
    }

    Rectangle {
        // ^ The selection rectangle border that highlights the chosen capture area.

        visible: root.isSelecting || root.hasSelection
        // ^ Visible when actively selecting or a selection exists.

        x: root.selX; y: root.selY; width: root.selW; height: root.selH
        // ^ Positioned and sized to match the current selection.

        color: (root.showQrPopup && root.isQrSuccess) ? Qt.alpha(_theme.green, 0.15) : (root.isVideoMode ? Qt.alpha(_theme.red, 0.05) : root.selectionTint)
        // ^ Interior fill color: green tint (15% opacity) on successful QR scan, red tint (5%) in video mode, subtle mauve tint otherwise.

        border.color: (root.showQrPopup && root.isQrSuccess) ? _theme.green : (root.isVideoMode ? _theme.red : root.accentColor)
        // ^ Border color: green for QR success, red for video, mauve accent for normal image mode.

        border.width: s(4)
        // ^ Thick 4px scaled border for clear visibility of the selection area.

        z: 5
        // ^ Rendered above the dimming layer but below the handles and toolbar.
    }

    Repeater {
        // ^ Creates visual rectangles for each QR code found in the image, highlighting their positions with animated borders.

        model: qrModel
        // ^ Uses the QR results model as the data source.

        delegate: Rectangle {
            // ^ Each QR code gets a highlighted rectangle delegate.

            visible: opacity > 0
            // ^ Only visible when opacity is above zero (prevents interaction when hidden).

            opacity: (root.showQrPopup && model.qSuccess && model.qW > 0) ? 1.0 : 0.0
            // ^ Visible only when QR popups are shown, the scan was successful, and the QR code has valid dimensions.

            property real pad: (root.showQrPopup && model.qSuccess) ? s(5) : 0
            // ^ A padding value (5px scaled) that expands the rectangle slightly around the QR code for visual clarity. Only applied on success.

            x: model.qW > 0 ? (model.qX - pad) : model.qX
            // ^ X position from the model, adjusted by padding when dimensions are valid.

            y: model.qH > 0 ? (model.qY - pad) : model.qY
            // ^ Y position adjusted by padding.

            width: model.qW > 0 ? (model.qW + (pad * 2)) : 0
            // ^ Width from model expanded by double padding (both sides).

            height: model.qH > 0 ? (model.qH + (pad * 2)) : 0
            // ^ Height expanded by double padding.

            color: Qt.alpha(_theme.green, 0.25)
            // ^ Semi-transparent green fill (25% opacity) highlighting the QR code location.

            border.color: _theme.green
            // ^ Green border for clear visual identification.

            border.width: s(3)
            // ^ 3px scaled border width.

            radius: s(8)
            // ^ Rounded corners (8px scaled) for a softer highlight appearance.

            z: 34
            // ^ Rendered above most other elements to ensure QR highlights are visible.

            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
            // ^ Smooth 400ms fade animation when appearing/disappearing.

            Behavior on pad { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
            // ^ Animates the padding changes for a smooth expansion/contraction effect.
        }
    }

    component Handle: Rectangle {
        // ^ Defines a reusable corner resize handle component—a circular grab point at each corner of the selection.

        width: s(20); height: s(20); radius: s(10)
        // ^ 20px diameter circle with 10px radius for a perfect round shape.

        color: root.handleColor; border.color: root.accentColor; border.width: s(4)
        // ^ Text-colored fill with a thick mauve accent border (4px) for high visibility.

        visible: (root.hasSelection || root.isSelecting) && !root.isScanningQr && !root.showQrPopup && !root.isVideoMode; z: 10
        // ^ Only visible when there's an active selection AND not scanning QR codes, not showing QR popups, and not in video mode (video doesn't support custom regions).
    }

    Handle { x: root.selX - width / 2; y: root.selY - height / 2 } 
    // ^ Top-left handle: centered on the corner of the selection rectangle (offset by half handle size to center on the corner point).

    Handle { x: root.selX + root.selW - width / 2; y: root.selY - height / 2 } 
    // ^ Top-right handle: centered on the top-right corner.

    Handle { x: root.selX - width / 2; y: root.selY + root.selH - height / 2 } 
    // ^ Bottom-left handle: centered on the bottom-left corner.

    Handle { x: root.selX + root.selW - width / 2; y: root.selY + root.selH - height / 2 } 
    // ^ Bottom-right handle: centered on the bottom-right corner. All four handles provide symmetric resize controls.

    MouseArea {
        // ^ The main interactive area covering the entire screen. Handles all mouse events for drawing selection, moving, resizing, and cursor shape updates.

        anchors.fill: parent
        // ^ Covers the full screen.

        hoverEnabled: true
        // ^ Enables hover detection for cursor shape updates without requiring a mouse press.

        acceptedButtons: Qt.LeftButton | Qt.RightButton
        // ^ Accepts both left (for selecting/interacting) and right (for canceling/exit) mouse buttons.

        z: 20 
        // ^ Rendered above the dimming layer and selection rectangle, ensuring it captures all mouse events.

        function getInteractionMode(mx, my, mods) {
            // ^ Determines the interaction mode based on mouse position relative to the selection rectangle. Takes mouse x, y coordinates and keyboard modifiers.

            if (!root.hasSelection) return 1; 
            // ^ If no selection exists yet, mode 1: start drawing a new selection.

            if (mods & Qt.ShiftModifier) return 2; 
            // ^ If Shift is held, mode 2: move the entire selection.

            let margin = s(20) 
            // ^ Hit-test margin of 20 scaled pixels around edges and corners for easier grabbing.

            let onLeftLine = Math.abs(mx - root.selX) <= margin; 
            // ^ True if mouse is within the margin of the left edge.

            let onRightLine = Math.abs(mx - (root.selX + root.selW)) <= margin
            // ^ True if mouse is within the margin of the right edge.

            let onTopLine = Math.abs(my - root.selY) <= margin; 
            // ^ True if mouse is within the margin of the top edge.

            let onBottomLine = Math.abs(my - (root.selY + root.selH)) <= margin
            // ^ True if mouse is within the margin of the bottom edge.

            let withinX = mx >= (root.selX - margin) && mx <= (root.selX + root.selW + margin);
            // ^ True if mouse is horizontally within the selection bounds (plus margin).

            let withinY = my >= (root.selY - margin) && my <= (root.selY + root.selH + margin);
            // ^ True if mouse is vertically within the selection bounds (plus margin).

            if (onTopLine && onLeftLine) return 3; 
            // ^ Top-left corner: mode 3 (resize from top-left).

            if (onTopLine && onRightLine) return 5;
            // ^ Top-right corner: mode 5 (resize from top-right).

            if (onBottomLine && onLeftLine) return 8; 
            // ^ Bottom-left corner: mode 8 (resize from bottom-left).

            if (onBottomLine && onRightLine) return 10;
            // ^ Bottom-right corner: mode 10 (resize from bottom-right).

            if (onTopLine && withinX) return 4; 
            // ^ Top edge (not corners): mode 4 (resize height from top).

            if (onBottomLine && withinX) return 9;
            // ^ Bottom edge: mode 9 (resize height from bottom).

            if (onLeftLine && withinY) return 6; 
            // ^ Left edge: mode 6 (resize width from left).

            if (onRightLine && withinY) return 7;
            // ^ Right edge: mode 7 (resize width from right).

            return 1;
            // ^ Default: mode 1 (draw new selection, clicking inside the existing selection starts a new one).
        }

        onPositionChanged: (mouse) => {
            // ^ Called whenever the mouse moves over this MouseArea.

            if (root.isVideoMode) { cursorShape = Qt.ArrowCursor; return; }
            // ^ In video mode, disables all selection interaction—uses simple arrow cursor.

            let mode = root.isSelecting ? root.interactionMode : getInteractionMode(mouse.x, mouse.y, mouse.modifiers)
            // ^ Determines the current mode: if actively dragging, uses the stored mode; otherwise calculates based on current mouse position.

            switch(mode) {
                // ^ Sets the cursor shape based on the interaction mode.
                case 2: cursorShape = Qt.ClosedHandCursor; break;
                // ^ Move mode: closed hand cursor.
                case 3: case 10: cursorShape = Qt.SizeFDiagCursor; break;
                // ^ Top-left and bottom-right corners: diagonal resize cursor (\).
                case 5: case 8: cursorShape = Qt.SizeBDiagCursor; break;
                // ^ Top-right and bottom-left corners: opposite diagonal resize cursor (/).
                case 4: case 9: cursorShape = Qt.SizeVerCursor; break;
                // ^ Top and bottom edges: vertical resize cursor (↕).
                case 6: case 7: cursorShape = Qt.SizeHorCursor; break;
                // ^ Left and right edges: horizontal resize cursor (↔).
                default: cursorShape = Qt.CrossCursor; break;
                // ^ Default/selection mode: crosshair cursor for drawing new selection.
            }

            if (!root.isSelecting) return;
            // ^ If not currently dragging, only update cursor—don't modify geometry.

            let dx = mouse.x - root.anchorX; let dy = mouse.y - root.anchorY
            // ^ Calculates the delta from the anchor point where the drag started.

            let clamp = (val, min, max) => Math.max(min, Math.min(max, val))
            // ^ Defines a helper function to constrain a value between min and max bounds.

            if (root.interactionMode === 1) { 
                // ^ Mode 1: Drawing a new selection rectangle.

                root.endX = clamp(mouse.x, 0, root.width); root.endY = clamp(mouse.y, 0, root.height)
                // ^ Sets the end point to the current mouse position, clamped within screen bounds.

            } else if (root.interactionMode === 2) { 
                // ^ Mode 2: Moving the entire selection.

                let targetX = clamp(root.initX + dx, 0, root.width - root.initW); let targetY = clamp(root.initY + dy, 0, root.height - root.initH)
                // ^ Calculates the new position by adding deltas to the initial position, clamping to keep the selection fully within the screen.

                root.startX = targetX; root.startY = targetY; root.endX = targetX + root.initW; root.endY = targetY + root.initH;
                // ^ Updates all four bounds based on the new position and initial size.

            } else { 
                // ^ Modes 3-10: Resizing from edges or corners.

                let nx = root.initX, ny = root.initY, nw = root.initW, nh = root.initH
                // ^ Starts with the initial selection geometry as the base for modification.

                if ([3, 6, 8].includes(root.interactionMode)) { nx = clamp(root.initX + dx, 0, root.initX + root.initW - 10); nw = root.initW + (root.initX - nx) }
                // ^ For modes affecting the left side (3=top-left, 6=left edge, 8=bottom-left): moves the left edge by dx, clamped to leave at least 10px width. Adjusts width to maintain the right edge position.

                if ([5, 7, 10].includes(root.interactionMode)) { nw = clamp(root.initW + dx, 10, root.width - root.initX) }
                // ^ For modes affecting the right side (5=top-right, 7=right edge, 10=bottom-right): adjusts width by dx, clamped to minimum 10px and maximum screen width.

                if ([3, 4, 5].includes(root.interactionMode)) { ny = clamp(root.initY + dy, 0, root.initY + root.initH - 10); nh = root.initH + (root.initY - ny) }
                // ^ For modes affecting the top side (3=top-left, 4=top edge, 5=top-right): moves the top edge by dy, clamped to leave at least 10px height. Adjusts height to maintain bottom position.

                if ([8, 9, 10].includes(root.interactionMode)) { nh = clamp(root.initH + dy, 10, root.height - root.initY) }
                // ^ For modes affecting the bottom side (8=bottom-left, 9=bottom edge, 10=bottom-right): adjusts height by dy, clamped to minimum 10px.

                root.startX = nx; root.startY = ny; root.endX = nx + nw; root.endY = ny + nh;
                // ^ Applies all the calculated changes to the selection rectangle bounds.
            }
        }

        onPressed: (mouse) => {
            // ^ Called when a mouse button is pressed down.

            if (mouse.button === Qt.RightButton) { Qt.quit(); return; }
            // ^ Right-click immediately closes the overlay without capturing (quick cancel).

            if (root.isVideoMode) return; 
            // ^ No selection interactions in video mode.

            root.isScanningQr = false;
            // ^ Cancels any in-progress QR scan when the user starts a new interaction.

            root.showQrPopup = false;
            // ^ Hides any QR result popups.

            qrWaitTimer.stop();
            // ^ Stops the QR wait timer if it was running.

            maximizeAnim.stop() 
            // ^ Stops any in-progress maximize/restore animation to prevent conflicts.

            root.interactionMode = getInteractionMode(mouse.x, mouse.y, mouse.modifiers)
            // ^ Determines the interaction mode based on where the user clicked and any modifier keys.

            root.isSelecting = true
            // ^ Sets the selecting flag, which disables the geometry animations for smooth dragging.

            if (root.interactionMode !== 1) root.isMaximized = false;
            // ^ If not starting a new selection (i.e., modifying an existing one), clears the maximized flag.

            root.anchorX = mouse.x; root.anchorY = mouse.y
            // ^ Records the anchor point—the position where the drag started—for calculating deltas.

            root.initX = root.selX; root.initY = root.selY; root.initW = root.selW; root.initH = root.selH;
            // ^ Saves the initial selection geometry before modification begins.

            if (root.interactionMode === 1) {
                // ^ If starting a new selection.
                let clamp = (val, min, max) => Math.max(min, Math.min(max, val))
                // ^ Clamping helper for screen bounds.
                let clampedX = clamp(mouse.x, 0, root.width); let clampedY = clamp(mouse.y, 0, root.height)
                // ^ Clamps the start point to be within the screen.
                root.startX = clampedX; root.startY = clampedY; root.endX = clampedX; root.endY = clampedY;
                // ^ Initializes the selection to a zero-size rectangle at the click point.
                root.hasSelection = false; root.isMaximized = false
                // ^ Clears any previous selection and maximized state.
            }
        }

        onReleased: {
            // ^ Called when the mouse button is released after a drag.

            if (root.isSelecting) {
                // ^ Only processes if we were actively selecting.

                root.isSelecting = false
                // ^ Clears the selecting flag, re-enabling geometry animations.

                if (root.selW > 10 && root.selH > 10) {
                    // ^ If the resulting selection is larger than 10px in both dimensions (a meaningful selection).

                    root.hasSelection = true; root.saveCache()
                    // ^ Confirms the selection and saves it to the cache file.

                } else { root.hasSelection = false }
                // ^ If the selection is too small (likely a click without dragging), discards it.
            }
        }
    }

    // --- Main Bottom Toolbar (Smooth Matte Rounded Rect) ---
    Item {
        // ^ Container for the toolbar that appears near the selection rectangle when a valid selection exists.

        id: toolbar
        // ^ Identifier for positioning calculations.

        z: 30 
        // ^ Rendered above the selection rectangle and handles.

        // Fully expanded total height
        property real totalHeight: s(120)
        // ^ The full height of the toolbar when all sections are visible.

        property bool fitsOutsideBottom: (root.selY + root.selH + totalHeight + s(15)) <= root.height
        // ^ Checks if there's enough space to place the toolbar BELOW the selection. True if (selection bottom + toolbar height + 15px margin) fits within the screen.

        visible: root.hasSelection && !root.isSelecting && !root.isScanningQr && !root.showQrPopup
        // ^ Only visible when: there's a valid selection, the user isn't currently dragging, no QR scan is in progress, and QR popups aren't showing.

        width: Math.max(toolbarRow.width + s(64), s(340))
        // ^ Dynamic width: at least 340px (scaled) or the content width plus 64px padding, whichever is larger.

        height: totalHeight 
        // ^ Full toolbar height.

        x: Math.max(s(10), Math.min(parent.width - width - s(10), root.selX + (root.selW / 2) - (width / 2)))
        // ^ Centers the toolbar horizontally on the selection center, clamped to stay at least 10px from screen edges. Uses max/min to enforce the bounds.

        y: fitsOutsideBottom ? (root.selY + root.selH + s(15)) : 
           ((root.selY - height - s(15)) >= 0 ? (root.selY - height - s(15)) : (root.height - height - s(15)))
        // ^ Smart vertical placement: prefer below the selection with 15px gap; if that doesn't fit, try above the selection; if that also doesn't fit, place at the bottom of the screen with 15px margin.

        // The Smooth Translucent Matte Background
        Rectangle {
            // ^ The background card of the toolbar.

            anchors.fill: parent
            // ^ Fills the toolbar item.

            color: Qt.rgba(_theme.base.r, _theme.base.g, _theme.base.b, 0.85)
            // ^ Semi-transparent (85% opacity) base color for a frosted glass effect that shows the dimmed background through it.

            border.color: Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.08)
            // ^ Very subtle text-colored border (8% opacity) for a refined edge.

            border.width: s(1)
            // ^ 1px scaled border.

            radius: s(24)
            // ^ Large corner radius (24px scaled) for a smooth, modern card appearance.
        }

        component AudioControl: RowLayout {
            // ^ Defines a reusable audio control component that combines a mute toggle icon, a volume slider, and an optional dropdown trigger for device selection.

            property string iconOn: ""
            // ^ Nerd Font icon glyph to show when audio is active (not muted).

            property string iconOff: ""
            // ^ Nerd Font icon glyph to show when audio is muted.

            property real volumeValue: 1.0
            // ^ The current volume level as a float from 0.0 to 1.0.

            property bool mutedValue: false
            // ^ Whether the audio is currently muted.

            property bool hasDropdown: false
            // ^ Whether this control has a device selection dropdown (used for microphone selection).
            
            signal volumeUpdate(real newVol)
            // ^ Signal emitted when the slider value changes.

            signal muteUpdate(bool newMute)
            // ^ Signal emitted when the mute button is toggled.

            signal dropdownClicked()
            // ^ Signal emitted when the dropdown arrow is clicked.

            spacing: s(4)
            // ^ Tight spacing between icon, slider, and dropdown.

            Rectangle {
                // ^ The mute toggle button—a circular icon.

                width: s(30); height: s(30); radius: s(15)
                // ^ 30px diameter circle with 15px radius.

                // Filled, solid matte-look on idle
                color: maIcon.containsMouse ? _theme.surface2 : _theme.surface0
                // ^ Elevated surface color on hover, base surface color when idle.

                Behavior on color { ColorAnimation { duration: 150 } }
                // ^ Quick color transition for hover feedback.

                Text {
                    // ^ The mute/unmute icon.

                    anchors.centerIn: parent
                    // ^ Centered in the circle.

                    font.family: "Iosevka Nerd Font"
                    // ^ Nerd Font for the icon.

                    text: parent.parent.mutedValue ? parent.parent.iconOff : parent.parent.iconOn
                    // ^ Shows the "off" icon when muted, "on" icon otherwise. Navigates up to the AudioControl via parent.parent.

                    color: parent.parent.mutedValue ? _theme.red : _theme.text
                    // ^ Red when muted (warning indication), normal text color otherwise.

                    font.pixelSize: s(16)
                    // ^ 16px scaled icon size.
                }

                MouseArea {
                    // ^ Click handler for the mute toggle.

                    id: maIcon; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    // ^ Fills the circle, hover enabled for the visual effect, hand cursor on hover.

                    onClicked: parent.parent.muteUpdate(!parent.parent.mutedValue)
                    // ^ Toggles the mute state by emitting muteUpdate with the inverted current state.
                }
            }

            Slider {
                // ^ A volume slider control (from Qt Quick Controls).

                Layout.preferredWidth: s(60)
                // ^ Fixed width of 60 scaled pixels for the slider track.

                from: 0.0; to: 1.0; value: parent.volumeValue
                // ^ Range from 0% to 100%, bound to the volumeValue property.

                onValueChanged: parent.volumeUpdate(value)
                // ^ Emits volumeUpdate whenever the slider position changes.

                background: Rectangle {
                    // ^ Custom background track for the slider.

                    x: parent.leftPadding; y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    // ^ Centers the track vertically in the slider's available area.

                    implicitWidth: s(60); implicitHeight: s(4)
                    // ^ 60px wide, 4px tall track.

                    width: parent.availableWidth; height: implicitHeight
                    // ^ Uses available width, fixed height.

                    radius: s(2)
                    // ^ Subtle 2px radius for slightly rounded ends.

                    color: _theme.surface2
                    // ^ Surface color for the inactive portion of the track.

                    Rectangle { width: parent.parent.visualPosition * parent.width; height: parent.height; color: parent.parent.parent.mutedValue ? _theme.subtext0 : _theme.mauve; radius: s(2) }
                    // ^ The filled portion of the track: width proportional to the slider's visualPosition (0.0 to 1.0). Colored mauve when active, subdued subtext0 when muted.
                }

                handle: Rectangle {
                    // ^ Custom handle (thumb) for the slider.

                    x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                    // ^ Positions the handle based on the current value.

                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    // ^ Vertically centers the handle on the track.

                    implicitWidth: s(12); implicitHeight: s(12); radius: s(6)
                    // ^ 12px diameter circle with 6px radius.

                    color: parent.parent.parent.mutedValue ? _theme.subtext0 : _theme.mauve
                    // ^ Color matches the track fill: mauve when active, subdued when muted.
                }
            }

            Rectangle {
                // ^ The dropdown trigger arrow (only visible when hasDropdown is true).

                visible: parent.hasDropdown
                // ^ Only shown for controls that have device selection (microphone).

                width: s(20); height: s(30); color: "transparent"
                // ^ Transparent background, fixed size for the arrow area.

                Text {
                    // ^ The dropdown arrow icon.

                    anchors.centerIn: parent
                    // ^ Centered.

                    font.family: "Iosevka Nerd Font"
                    // ^ Nerd Font for the arrow icon.

                    // Correcting dropdown icon orientation base on position relative to fitsOutsideBottom
                    text: toolbar.fitsOutsideBottom ? "󰅃" : "󰅀" 
                    // ^ Shows downward arrow (󰅃) when toolbar is below selection (dropdown opens downward), upward arrow (󰅀) when toolbar is above selection (dropdown opens upward).

                    color: _theme.text
                    // ^ Text color for the arrow.

                    font.pixelSize: s(16)
                    // ^ 16px scaled icon size.
                }

                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.parent.dropdownClicked() }
                // ^ Click handler that emits the dropdownClicked signal to toggle device selection visibility.
            }
        }

        Rectangle {
            // ^ The microphone device selection dropdown panel.

            id: micDropdown
            // ^ Identifier for visibility toggling.

            visible: false
            // ^ Initially hidden; shown when the microphone dropdown arrow is clicked.

            width: s(280)
            // ^ Fixed width of 280 scaled pixels.

            height: micModel.count === 0 ? s(40) : Math.min(s(180), micModel.count * s(36))
            // ^ Dynamic height: 40px for "no devices" message, otherwise capped at 180px or the number of devices * 36px (whichever is smaller).

            x: -s(140) 
            // ^ Centered relative to the toolbar's audio control (offset by half width).

            // Correcting dropdown positioning
            y: toolbar.fitsOutsideBottom ? (toolbar.height + s(8)) : (-height - s(8))
            // ^ Positions below the toolbar (with 8px gap) when toolbar is below selection, above the toolbar when toolbar is above selection.

            color: Qt.rgba(_theme.base.r, _theme.base.g, _theme.base.b, 0.95)
            // ^ Nearly opaque base color (95%) for the dropdown background.

            border.color: Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.08)
            // ^ Subtle border like the main toolbar.

            border.width: s(1)
            // ^ 1px border.

            radius: s(12)
            // ^ 12px corner radius for the card.

            z: 50
            // ^ High z-index to appear above all other elements.

            Text {
                // ^ Placeholder text when no microphones are available.

                visible: micModel.count === 0
                // ^ Only shown when the microphone model is empty.

                anchors.centerIn: parent
                // ^ Centered in the dropdown.

                text: "No Microphones (Install pulseaudio)"
                // ^ Informative message guiding the user to install PulseAudio/PipeWire.

                color: _theme.subtext0
                // ^ Subdued text color.

                font.pixelSize: s(12)
                // ^ Small text size.
            }

            ListView {
                // ^ Scrollable list of available microphones.

                visible: micModel.count > 0
                // ^ Only shown when devices are available.

                anchors.fill: parent; anchors.margins: s(4)
                // ^ Fills the dropdown with 4px margins.

                model: micModel
                // ^ Uses the microphone device model as its data source.

                clip: true
                // ^ Clips content to the dropdown's rounded boundaries.

                delegate: Rectangle {
                    // ^ Each microphone device is a selectable row.

                    width: ListView.view.width; height: s(32); radius: s(6)
                    // ^ Full width of the list, 32px height, 6px rounded corners.

                    color: maList.containsMouse ? _theme.surface0 : "transparent"
                    // ^ Surface color highlight on hover, transparent otherwise.

                    RowLayout {
                        // ^ Layout for the device description.

                        anchors.fill: parent; anchors.margins: s(6)
                        // ^ Fills the row with 6px padding.

                        Text { text: model.devDesc; color: root.micDevice === model.devName ? _theme.mauve : _theme.text; font.pixelSize: s(12); elide: Text.ElideRight; Layout.fillWidth: true }
                        // ^ Shows the device description. Highlighted in mauve if this device is currently selected, normal text color otherwise. Text elides on the right if too long.
                    }

                    MouseArea { 
                        // ^ Click handler to select this device.

                        id: maList; anchors.fill: parent; hoverEnabled: true; 
                        // ^ Fills the row, hover enabled for visual effect.

                        onClicked: { root.micDevice = model.devName; root.saveAudioPrefs(); micDropdown.visible = false } 
                        // ^ Selects this device, saves preferences, and closes the dropdown.
                    }
                }
            }
        }

        // Top Content: The Action Tools
        Row {
            // ^ The top row of the toolbar containing the mode switcher, audio controls, and action buttons.

            id: toolbarRow
            // ^ Identifier for width measurement.

            anchors.top: parent.top
            // ^ Anchored to the top of the toolbar.

            anchors.topMargin: s(12)
            // ^ 12px margin from the top.

            anchors.horizontalCenter: parent.horizontalCenter
            // ^ Horizontally centered in the toolbar.

            height: root.s(36)
            // ^ Fixed height of 36px.

            spacing: 0
            // ^ No automatic spacing—AnimWrap components manage their own widths for smooth reveal animations.

            // Tab Switcher with Morphing Animation (Stretchy Mauve Pill)
            Item {
                // ^ Container for the image/video mode switcher toggle.

                // Width is slightly bigger to handle reducced icon padding on right
                width: s(110) + s(3); height: parent.height
                // ^ 110px + 3px extra for the toggle, matching parent height.
                
                Rectangle {
                    // ^ The background pill of the mode switcher.

                    width: s(110); height: s(36); radius: s(18) 
                    // ^ 110px wide, 36px tall, 18px radius for a perfect capsule shape.

                    color: _theme.surface0
                    // ^ Surface color background.
                    
                    Rectangle {
                        // ^ The animated highlight that slides between image and video positions.

                        id: activeHighlight
                        // ^ Identifier for animation control.

                        y: s(2)
                        // ^ 2px from the top of the pill for a small inset.

                        height: parent.height - s(4)
                        // ^ 4px shorter than the pill (2px inset on both top and bottom).

                        radius: s(16) 
                        // ^ Slightly smaller radius than the pill for a nested look.

                        color: _theme.mauve
                        // ^ Mauve accent color for the active indicator.

                        z: 0
                        // ^ Rendered behind the icons.

                        property bool curVideoMode: root.isVideoMode
                        // ^ Mirrors the current video mode for animation triggering.

                        onCurVideoModeChanged: {
                            // ^ When video mode changes, adjusts animation durations for direction-aware morphing.

                            // Morph duration/easing when going right vs left
                            if (curVideoMode) { // Moving right
                                rightAnim.duration = 200; leftAnim.duration = 350;
                                // ^ Faster move right (200ms), slower left edge catching up (350ms) for a stretchy feel.
                            } else { // Moving left
                                leftAnim.duration = 200; rightAnim.duration = 350;
                                // ^ Faster move left, slower right edge trailing.
                            }
                        }

                        property real targetLeft: curVideoMode ? (parent.width / 2) : s(2)
                        // ^ When in video mode, left edge moves to the midpoint; when in image mode, to 2px from left.

                        property real targetRight: targetLeft + (parent.width / 2) - s(2)
                        // ^ Right edge is always left edge + half pill width - 2px inset.

                        property real actualLeft: targetLeft
                        // ^ Property that animates to targetLeft.

                        property real actualRight: targetRight
                        // ^ Property that animates to targetRight.

                        Behavior on actualLeft { NumberAnimation { id: leftAnim; duration: 250; easing.type: Easing.OutExpo } }
                        // ^ Animates actualLeft changes, using the dynamically adjusted duration.

                        Behavior on actualRight { NumberAnimation { id: rightAnim; duration: 250; easing.type: Easing.OutExpo } }
                        // ^ Animates actualRight changes independently for the stretchy morphing effect.

                        x: actualLeft
                        // ^ Positions the highlight at the animated left edge.

                        width: actualRight - actualLeft
                        // ^ Width is the difference between the animated edges, creating the stretchy morph.
                    }
                    
                    Row {
                        // ^ Row containing the two icon areas (image and video).

                        anchors.fill: parent
                        // ^ Fills the pill.

                        z: 1
                        // ^ Rendered above the highlight.

                        Item {
                            // ^ Left half: image mode icon.

                            width: parent.width / 2; height: parent.height
                            // ^ Occupies the left half of the pill.

                            Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: "󰄄"; color: !root.isVideoMode ? _theme.crust : _theme.text; font.pixelSize: s(16) }
                            // ^ Image icon: crust color (darkest, for contrast on mauve) when active, normal text color when inactive.

                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.isVideoMode = false }
                            // ^ Clicking switches to image mode.
                        }

                        Item {
                            // ^ Right half: video mode icon.

                            width: parent.width / 2; height: parent.height
                            // ^ Occupies the right half.

                            Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: ""; color: root.isVideoMode ? _theme.crust : _theme.text; font.pixelSize: s(16) }
                            // ^ Video icon with the same active/inactive color logic.

                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.isVideoMode = true }
                            // ^ Clicking switches to video mode.
                        }
                    }
                }
            }

            // Video Controls
            AnimWrap {
                // ^ Wraps the first separator line with smooth reveal animation.

                isShown: root.isVideoMode; contentWidth: s(2)
                // ^ Only shown in video mode, 2px wide separator.

                Rectangle { width: s(2); height: s(16); anchors.verticalCenter: parent.verticalCenter; color: _theme.surface0; radius: s(1) }
                // ^ A thin vertical separator line, vertically centered in the toolbar row.
            }

            AnimWrap {
                // ^ Desktop audio control (visible in video mode).

                isShown: root.isVideoMode; contentWidth: s(94)
                // ^ Reveals in video mode, 94px wide for the control.

                AudioControl { 
                    id: deskAudio; width: parent.width; height: parent.height
                    // ^ Desktop audio instance.

                    iconOn: "󰓃"; iconOff: "󰓄" 
                    // ^ Speaker icons: on (sound waves) and off (muted).

                    volumeValue: root.deskVol; mutedValue: root.deskMute
                    // ^ Bound to the root's desktop audio properties.

                    onVolumeUpdate: (v) => { root.deskVol = v; root.saveAudioPrefs() }
                    // ^ Updates volume and persists.

                    onMuteUpdate: (m) => { root.deskMute = m; root.saveAudioPrefs() }
                    // ^ Updates mute state and persists.
                }
            }
            
            AnimWrap {
                // ^ Microphone audio control (visible in video mode).

                isShown: root.isVideoMode; contentWidth: s(118)
                // ^ Slightly wider (118px) to accommodate the dropdown arrow.

                AudioControl { 
                    id: micAudio; width: parent.width; height: parent.height
                    // ^ Microphone audio instance.

                    iconOn: "󰍬"; iconOff: "󰍭"; hasDropdown: true
                    // ^ Microphone icons and enables the device selection dropdown.

                    volumeValue: root.micVol; mutedValue: root.micMute
                    // ^ Bound to microphone properties.

                    onVolumeUpdate: (v) => { root.micVol = v; root.saveAudioPrefs() }
                    // ^ Updates microphone volume and persists.

                    onMuteUpdate: (m) => { root.micMute = m; root.saveAudioPrefs() }
                    // ^ Updates microphone mute and persists.

                    onDropdownClicked: { micDropdown.visible = !micDropdown.visible; micDropdown.x = mapToItem(toolbar, 0, 0).x - s(120) }
                    // ^ Toggles the microphone device dropdown visibility and positions it relative to the toolbar.
                }
            }

            // Image Controls
            AnimWrap {
                // ^ Separator for image controls.

                isShown: !root.isVideoMode; contentWidth: s(2)
                // ^ Only shown in image mode.

                Rectangle { width: s(2); height: s(16); anchors.verticalCenter: parent.verticalCenter; color: _theme.surface0; radius: s(1) }
                // ^ Thin vertical separator line.
            }

            AnimWrap {
                // ^ Edit button (opens screenshot in satty editor).

                isShown: !root.isVideoMode; contentWidth: s(36)
                // ^ Shown only in image mode, 36px wide for the icon button.

                ToolbarBtn { iconTxt: "󰏫"; onClicked: root.executeCapture(true, false) }
                // ^ Edit icon (pencil), captures with edit mode enabled (openEditor=true, isRecord=false).
            }

            AnimWrap {
                // ^ QR scan button.

                isShown: !root.isVideoMode; contentWidth: s(36)

                ToolbarBtn { iconTxt: "⿻"; onClicked: root.performQrScan() }
                // ^ QR scan icon (overlapping rectangles), triggers the QR scanning process.
            }

            AnimWrap {
                // ^ Separator before maximize button.

                isShown: !root.isVideoMode; contentWidth: s(2)

                Rectangle { width: s(2); height: s(16); anchors.verticalCenter: parent.verticalCenter; color: _theme.surface0; radius: s(1) }
                // ^ Thin separator.
            }
            
            AnimWrap {
                // ^ Maximize/restore toggle button.

                isShown: !root.isVideoMode; contentWidth: s(36)

                ToolbarBtn { iconTxt: root.isMaximized ? "" : ""; onClicked: root.toggleMaximize() }
                // ^ Shows restore icon when maximized, maximize icon otherwise. Toggles between full screen and previous selection.
            }

            // Universal Close Button
            Item {
                // ^ Container for the close button (always visible regardless of mode).

                width: s(2) + s(3) + s(36); height: parent.height // Widened width for reducced padding on right
                // ^ Total width: 2px separator + 3px gap + 36px button.

                Row {
                    // ^ Row containing separator and close button.

                    anchors.verticalCenter: parent.verticalCenter
                    // ^ Vertically centered.

                    height: parent.height
                    // ^ Full row height.

                    spacing: s(3) // Reducción de padding lateral para los íconos en top part
                    // ^ 3px spacing between separator and button (comment notes reduced lateral padding for icons).

                    Rectangle { width: s(2); height: s(16); anchors.verticalCenter: parent.verticalCenter; color: _theme.surface0; radius: s(1);}
                    // ^ Thin vertical separator line before the close button.

                    ToolbarBtn { 
                        anchors.verticalCenter: parent.verticalCenter
                        // ^ Vertically centered.

                        iconTxt: "󰅖"; isDanger: true; onClicked: Qt.quit() 
                        // ^ Close/cancel icon (X) with danger styling (red). Closes the overlay without capturing.
                    }
                }
            }
        }

        // Bottom Content: Center Capture Layout with Dynamic Gradient Lines
        Item {
            // ^ The bottom section of the toolbar containing the animated gradient lines and central capture button.

            id: captureSection
            // ^ Identifier.

            anchors.bottom: parent.bottom
            // ^ Anchored to the bottom of the toolbar.

            anchors.bottomMargin: s(12)
            // ^ 12px margin from the bottom.

            anchors.horizontalCenter: parent.horizontalCenter
            // ^ Horizontally centered.

            width: parent.width
            // ^ Full width of the toolbar.

            height: s(56) // Aumento ligero de altura para el capture circle más grande
            // ^ 56px height (comment notes slight increase for larger capture circle).

            z: 10
            // ^ Rendered above the background.

            // Smooth Left Line + Hover Wave
            Rectangle {
                // ^ The left gradient line that stretches from the edge toward the capture button.

                id: leftLineBase
                // ^ Identifier.

                height: s(4) // Líneas horizontales más gruesas
                // ^ 4px thick horizontal line (comment: thicker horizontal lines).

                radius: s(2) // Radio escalado
                // ^ 2px radius for slightly rounded ends (comment: scaled radius).

                color: Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.1) // Subtle structural line
                // ^ Very subtle text color (10% opacity) for the base line—barely visible.

                anchors.left: parent.left
                // ^ Starts from the left edge of the section.

                anchors.leftMargin: s(24)
                // ^ 24px inset from the left edge.

                anchors.right: actionBtnContainer.left
                // ^ Extends to the left edge of the capture button container.

                anchors.rightMargin: s(16)
                // ^ 16px gap before the button.

                anchors.verticalCenter: parent.verticalCenter
                // ^ Vertically centered in the section.

                clip: true
                // ^ Clips the animated gradient rectangle to this line's bounds.

                // Stretchy gradient 'wave'
                Rectangle {
                    // ^ The animated gradient overlay that stretches from the right toward the left when hovered.

                    anchors.right: parent.right
                    // ^ Anchored to the right edge (near the button).

                    anchors.top: parent.top
                    // ^ Full height of the line.

                    anchors.bottom: parent.bottom
                    // ^ Full height.

                    // Stretches left when hovered
                    width: actionArea.containsMouse ? parent.width : 0
                    // ^ Full width (stretching left) when the capture button is hovered, zero width (hidden) otherwise.

                    radius: s(2)
                    // ^ Matching radius.

                    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.InOutExpo } }
                    // ^ Smooth 500ms width animation with exponential easing for an elegant stretch effect.

                    gradient: Gradient {
                        // ^ A horizontal gradient for the wave effect.

                        orientation: Gradient.Horizontal
                        // ^ Left-to-right gradient.

                        GradientStop { position: 0.0; color: root.isVideoMode ? _theme.red : root.accentColor }
                        // ^ Left edge: red in video mode, mauve in image mode.

                        GradientStop { position: 1.0; color: "transparent" }
                        // ^ Right edge: fades to transparent, creating a directional glow toward the button.
                    }
                }
            }

            // Central Capture Circle (Slightly Bigger)
            Item {
                // ^ Container for the central capture/record button.

                id: actionBtnContainer
                // ^ Identifier for the gradient lines to anchor to.

                width: s(56) // Círculo 'capture' un poco más grande
                // ^ 56px diameter (comment: slightly larger capture circle).

                height: width
                // ^ Perfect square for a circular button.

                anchors.centerIn: parent
                // ^ Centered in the capture section.

                z: 20
                // ^ Above the gradient lines.
                
                Rectangle {
                    // ^ The outer ring of the capture button.

                    anchors.fill: parent
                    // ^ Fills the container.

                    radius: width / 2
                    // ^ Perfect circle.

                    color: "transparent"
                    // ^ Transparent fill—only the border is visible.

                    border.color: root.isVideoMode ? Qt.alpha(_theme.red, 0.4) : Qt.alpha(_theme.surface1, 0.8)
                    // ^ Video mode: semi-transparent red ring (40% opacity). Image mode: more opaque surface1 ring (80% opacity).

                    border.width: s(2)
                    // ^ 2px border width.

                    Behavior on border.color { ColorAnimation { duration: 250 } }
                    // ^ Smooth color transition when switching modes.
                }

                Rectangle {
                    // ^ The inner solid circle of the capture button (the main visual).

                    // Círculo interno escalado
                    width: actionArea.pressed ? s(32) : (actionArea.containsMouse ? s(40) : s(36))
                    // ^ Dynamic size: shrinks to 32px when pressed, grows to 40px on hover, 36px idle. Provides tactile feedback.

                    height: width
                    // ^ Maintains circular shape.

                    radius: width / 2
                    // ^ Perfect circle.

                    anchors.centerIn: parent
                    // ^ Centered in the outer ring.

                    color: root.isVideoMode ? _theme.red : root.accentColor
                    // ^ Red in video mode (record indicator), mauve in image mode.

                    Behavior on color { ColorAnimation { duration: 250 } }
                    // ^ Smooth color transitions.

                    Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                    // ^ Bouncy size animation with back easing for satisfying tactile response.
                }

                MouseArea {
                    // ^ Click handler for the capture button.

                    id: actionArea
                    // ^ Identifier used by the gradient lines' hover detection.

                    anchors.fill: parent
                    // ^ Fills the entire button area.

                    hoverEnabled: true
                    // ^ Enables hover detection for the gradient wave and size animations.

                    cursorShape: Qt.PointingHandCursor
                    // ^ Hand cursor on hover.

                    onClicked: root.executeCapture(false, root.isVideoMode)
                    // ^ Executes capture with edit mode off (direct save) and the current mode (video or image).
                }
            }

            // Smooth Right Line + Hover Wave
            Rectangle {
                // ^ The right gradient line, mirroring the left line's behavior but stretching left toward the button.

                id: rightLineBase
                // ^ Identifier.

                height: s(4) // Líneas horizontales más gruesas
                // ^ 4px thick line.

                radius: s(2) // Radio escalado
                // ^ 2px radius.

                color: Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.1)
                // ^ Same subtle base color as the left line.

                anchors.right: parent.right
                // ^ Anchored to the right edge.

                anchors.rightMargin: s(24)
                // ^ 24px inset from the right.

                anchors.left: actionBtnContainer.right
                // ^ Starts from the right edge of the button container.

                anchors.leftMargin: s(16)
                // ^ 16px gap after the button.

                anchors.verticalCenter: parent.verticalCenter
                // ^ Vertically centered.

                clip: true
                // ^ Clips the animated overlay.

                // Stretchy gradient 'wave'
                Rectangle {
                    // ^ The animated gradient stretching right from the button when hovered.

                    anchors.left: parent.left
                    // ^ Anchored to the left edge (near the button).

                    anchors.top: parent.top
                    // ^ Full height.

                    anchors.bottom: parent.bottom
                    // ^ Full height.

                    // Stretches right when hovered
                    width: actionArea.containsMouse ? parent.width : 0
                    // ^ Expands to full width when button is hovered.

                    radius: s(2)
                    // ^ Matching radius.

                    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.InOutExpo } }
                    // ^ Smooth stretch animation.

                    gradient: Gradient {
                        // ^ Horizontal gradient for the right wave.

                        orientation: Gradient.Horizontal

                        GradientStop { position: 0.0; color: "transparent" }
                        // ^ Left edge: transparent (near the button).

                        GradientStop { position: 1.0; color: root.isVideoMode ? _theme.red : root.accentColor }
                        // ^ Right edge: accent color, fading in from the button outward.
                    }
                }
            }
        }
    }

    // --- QR Popup and Backend Hooks ---
    Repeater {
        // ^ Creates popup rectangles for each QR code result, displaying the decoded text and action buttons.

        model: qrModel
        // ^ Uses the QR results model.

        delegate: Rectangle {
            // ^ Each QR code gets a popup card.

            id: qrPopupItem
            // ^ Identifier for animation bindings.

            visible: opacity > 0
            // ^ Hidden when fully transparent to avoid interaction issues.

            opacity: (root.showQrPopup && !root.isSelecting) ? 1.0 : 0.0
            // ^ Visible when QR popups are shown and the user isn't actively selecting.

            x: model.qTargetX
            // ^ X position from the model's calculated target.

            y: model.qTargetY + (model.fitsTop ? (1.0 - opacity) * s(15) : -(1.0 - opacity) * s(15))
            // ^ Y position with an animated offset: slides in from 15px away in the direction it will finally rest, creating a subtle entrance animation.

            width: qrPopupLayout.implicitWidth + s(32)
            // ^ Dynamic width based on content plus 32px padding.

            height: s(52)
            // ^ Fixed height of 52px.

            radius: s(26)
            // ^ Half the height for a perfect pill shape.

            color: _theme.base
            // ^ Base color background.

            border.color: model.qSuccess ? _theme.green : _theme.red
            // ^ Green border for successful QR reads, red for failures/errors.

            border.width: s(2)
            // ^ 2px border.

            property bool isHovered: maHover.containsMouse
            // ^ Tracks hover state for scale animation.

            scale: isHovered ? 1.0 : model.qBaseScale
            // ^ Full scale on hover, potentially reduced scale (from collision avoidance algorithm) otherwise.

            z: isHovered ? 100 : (40 - index)
            // ^ Brings hovered popup to the very front (z=100). Others stack with decreasing z based on index.

            transformOrigin: Item.Center
            // ^ Scale transform originates from the center of the popup.

            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
            // ^ Smooth 400ms fade animation.

            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
            // ^ Smooth 250ms scale animation.

            MouseArea { id: maHover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
            // ^ Hover detection only (accepts no buttons) to enable the scale-on-hover effect.

            RowLayout {
                // ^ Arranges the QR text, copy button, open link button, and close button horizontally.

                id: qrPopupLayout
                // ^ Identifier for width measurement.

                anchors.centerIn: parent
                // ^ Centered in the popup pill.

                spacing: s(8)
                // ^ 8px spacing between elements.

                Text {
                    // ^ The decoded QR code text.

                    text: model.qText
                    // ^ Shows the decoded content.

                    color: model.qSuccess ? _theme.text : _theme.red
                    // ^ Normal text color on success, red for errors.

                    font.family: "JetBrains Mono"
                    // ^ Monospace font for code/URL display.

                    font.pixelSize: s(13)
                    // ^ 13px text.

                    font.weight: Font.DemiBold
                    // ^ Semi-bold for readability.

                    Layout.maximumWidth: s(400)
                    // ^ Caps the text width at 400px to prevent overly wide popups.

                    Layout.leftMargin: s(8)
                    // ^ 8px left margin.

                    elide: Text.ElideRight
                    // ^ Elides text on the right with "..." if it exceeds the maximum width.

                    wrapMode: Text.NoWrap
                    // ^ Single line display—no wrapping.
                }

                Rectangle { visible: model.qSuccess; width: s(2); Layout.fillHeight: true; Layout.topMargin: s(10); Layout.bottomMargin: s(10); color: _theme.surface0; radius: s(1) }
                // ^ Vertical separator line, only visible on successful reads. Spans the full height with 10px vertical margins.

                ToolbarBtn {
                    // ^ Copy to clipboard button.

                    visible: model.qSuccess
                    // ^ Only shown on successful QR reads.

                    iconTxt: "󰆏"
                    // ^ Copy icon.

                    onClicked: {
                        Quickshell.execDetached(["bash", "-c", `echo -n '${model.qText.replace(/'/g, "'\\''")}' | wl-copy`]);
                        // ^ Copies the decoded text to the Wayland clipboard using wl-copy. Single quotes in the text are escaped for bash safety.

                        root.showQrPopup = false;
                        // ^ Hides all QR popups after copying.
                    }
                }

                ToolbarBtn {
                    // ^ Open in browser button (only for URLs).

                    visible: model.qSuccess && (model.qText.startsWith("http://") || model.qText.startsWith("https://"))
                    // ^ Only shown for successful reads that are URLs.

                    iconTxt: "󰌹"
                    // ^ Open/external link icon.

                    onClicked: {
                        Quickshell.execDetached(["xdg-open", model.qText]);
                        // ^ Opens the URL in the default browser.

                        Qt.quit();
                        // ^ Closes the entire overlay after opening the link.
                    }
                }

                Rectangle { width: s(2); Layout.fillHeight: true; Layout.topMargin: s(10); Layout.bottomMargin: s(10); color: _theme.surface0; radius: s(1) }
                // ^ Another separator before the close button.

                ToolbarBtn { iconTxt: "󰅖"; isDanger: true; onClicked: root.showQrPopup = false }
                // ^ Close button with danger styling, hides the QR popups.
            }
        }
    }

    Process {
        // ^ A Process that reads the QR scan results from the temporary file produced by the QR scanning script.

        id: qrReaderProcess
        // ^ Identifier.

        property string accumulated: ""
        // ^ Accumulates the output text as it's read in chunks via the SplitParser.

        command: ["cat", "/tmp/qs_qr_result"]
        // ^ Reads the QR result file using cat.

        stdout: SplitParser { splitMarker: ""; onRead: data => qrReaderProcess.accumulated += data }
        // ^ Uses a SplitParser (a Quickshell Io type) to receive output chunks. With an empty splitMarker, it reads all output. Each chunk is appended to the accumulated string.

        onExited: (exitCode) => {
            // ^ Called when the cat process finishes (the result file is fully read).

            let res = qrReaderProcess.accumulated.trim()
            // ^ Gets the complete result text.

            qrReaderProcess.accumulated = ""
            // ^ Resets the accumulator for future scans.

            root.isScanningQr = false
            // ^ Clears the scanning flag.

            qrModel.clear()
            // ^ Clears any previous QR results from the model.
    
            if (exitCode !== 0 || res === "") {
                // ^ If the process failed or the result is empty.

                qrModel.append({ 
                    qX: root.selX + (root.selW / 2), qY: root.selY + (root.selH / 2), qW: 0, qH: 0, 
                    qText: "Scan timed out or failed.", qSuccess: false,
                    qTargetX: root.selX + (root.selW / 2) - s(100), qTargetY: root.selY + (root.selH / 2),
                    qBaseScale: 1.0, fitsTop: false 
                })
                // ^ Adds a failure entry to the model, positioned at the center of the selection.

                root.isQrSuccess = false
                // ^ Marks scan as unsuccessful.

                root.showQrPopup = true
                // ^ Shows the failure popup.

                return
                // ^ Exits early.
            }

            let lines = res.split('\n');
            // ^ Splits the result into individual lines (each line represents one QR code).

            let anySuccess = false;
            // ^ Tracks whether at least one QR code was successfully decoded.

            let qrs = [];
            // ^ Array to hold all detected QR codes for collision avoidance processing.

            for (let i = 0; i < lines.length; i++) {
                // ^ Iterates over each result line.

                let line = lines[i].trim();
                // ^ Trims whitespace.

                if (line === "") continue;
                // ^ Skips empty lines.

                let delimiterIdx = line.indexOf('|||');
                // ^ Finds the delimiter between coordinates and text.

                if (delimiterIdx === -1) continue;
                // ^ Skips lines without the expected format.

                let coordStr = line.substring(0, delimiterIdx);
                // ^ Extracts the coordinate portion (before "|||").

                let actualText = line.substring(delimiterIdx + 3).replace(/\\n/g, '\n').replace(/\\\\/g, '\\');
                // ^ Extracts the text portion (after "|||"), unescaping newlines and backslashes.

                let coords = coordStr.split(',');
                // ^ Splits the coordinate string into an array [x, y, w, h].

                if (coords.length === 4 && !isNaN(parseInt(coords[0]))) {
                    // ^ Validates that we have 4 coordinates and the first one is a number.

                    let x = parseInt(coords[0]); let y = parseInt(coords[1]); let w = parseInt(coords[2]); let h = parseInt(coords[3]);
                    // ^ Parses all four coordinate values as integers.

                    let successState = !(actualText === "NOT_FOUND" || actualText.startsWith("ERROR:"));
                    // ^ Determines success: false only for "NOT_FOUND" or error messages.

                    if (successState) anySuccess = true;
                    // ^ Sets the global success flag if any QR code was decoded.

                    let cleanText = successState ? actualText.replace(/^QR-Code:/, "") : (actualText === "NOT_FOUND" ? "No QR code found." : actualText);
                    // ^ Cleans up the text: removes "QR-Code:" prefix from successful reads, converts "NOT_FOUND" to a user-friendly message, or keeps error text.

                    let estTextWidth = Math.min(s(400), cleanText.length * s(8.5));
                    // ^ Estimates the text width based on character count (8.5px per character), capped at 400px.

                    let pw = estTextWidth + (successState ? s(140) : s(40)); 
                    // ^ Calculates popup width: text width + 140px for action buttons on success, 40px for error.

                    let ph = s(52);
                    // ^ Fixed popup height.

                    let absX = root.selX + x; let absY = root.selY + y;
                    // ^ Converts from selection-relative coordinates to screen-absolute coordinates.

                    let cx = absX + (w / 2);
                    // ^ Center X of the QR code on screen.

                    let fitsTop = (absY - ph - s(15)) >= root.selY;
                    // ^ Checks if the popup fits above the QR code (with 15px gap) within the selection area.

                    let idealX = cx - (pw / 2);
                    // ^ Ideal X position: centered on the QR code.

                    let targetX = Math.max(s(10), Math.min(root.width - pw - s(10), idealX));
                    // ^ Clamps the X position to keep the popup at least 10px from screen edges.

                    let targetY = fitsTop ? (absY - ph - s(15)) : (absY + h + s(15));
                    // ^ Y position: above the QR code if it fits, below otherwise.

                    qrs.push({ qX: absX, qY: absY, qW: w, qH: h, qText: cleanText, qSuccess: successState, pw: pw, ph: ph, targetX: targetX, targetY: targetY, cx: targetX + (pw / 2), cy: targetY + (ph / 2), scale: 1.0, fitsTop: fitsTop });
                    // ^ Pushes the QR code data to the processing array with all positioning information.
                }
            }

            for (let pass = 0; pass < 5; pass++) {
                // ^ Runs 5 iterations of collision avoidance to shrink overlapping popups.

                for (let i = 0; i < qrs.length; i++) {
                    // ^ Iterates over each QR code.

                    for (let j = i + 1; j < qrs.length; j++) {
                        // ^ Compares with every other QR code (upper triangle only to avoid duplicate comparisons).

                        let A = qrs[i]; let B = qrs[j];
                        // ^ References the two QR codes being compared.

                        let dx = Math.abs(A.cx - B.cx); let dy = Math.abs(A.cy - B.cy);
                        // ^ Calculates the center-to-center distance in X and Y.

                        let req_x = (A.pw * A.scale + B.pw * B.scale) / 2 + s(10);
                        let req_y = (A.ph * A.scale + B.ph * B.scale) / 2 + s(10);
                        // ^ Calculates the required distance to avoid overlap: half the sum of scaled widths/heights plus 10px margin.

                        if (dx < req_x && dy < req_y) {
                            // ^ If the popups overlap (both X and Y distances are less than required).

                            let factorX = dx > 0 ? (dx - s(10)) * 2 / (A.pw + B.pw) : 0;
                            let factorY = dy > 0 ? (dy - s(10)) * 2 / (A.ph + B.ph) : 0;
                            // ^ Calculates scale factors based on how much space is available in each dimension.

                            let maxFactor = Math.max(factorX, factorY);
                            // ^ Uses the more restrictive (larger) factor.

                            maxFactor = Math.max(0.35, maxFactor); 
                            // ^ Ensures the scale doesn't go below 35% (keeping popups at least somewhat readable).

                            A.scale = Math.min(A.scale, maxFactor); B.scale = Math.min(B.scale, maxFactor);
                            // ^ Shrinks both popups to the calculated scale if it's smaller than their current scale.
                        }
                    }
                }
            }

            if (qrs.length === 0) {
                // ^ If no valid QR codes were found after processing.

                qrModel.append({ 
                    qX: root.selX + (root.selW / 2), qY: root.selY + (root.selH / 2), qW: 0, qH: 0, 
                    qText: "No QR code found.", qSuccess: false,
                    qTargetX: root.selX + (root.selW / 2) - s(100), qTargetY: root.selY + (root.selH / 2),
                    qBaseScale: 1.0, fitsTop: false 
                });
                // ^ Adds a "not found" entry at the center of the selection.
            } else {
                // ^ If QR codes were found.

                for (let i = 0; i < qrs.length; i++) {
                    // ^ Iterates over processed QR codes.

                    qrModel.append({ qX: qrs[i].qX, qY: qrs[i].qY, qW: qrs[i].qW, qH: qrs[i].qH, qText: qrs[i].qText, qSuccess: qrs[i].qSuccess, qTargetX: qrs[i].targetX, qTargetY: qrs[i].targetY, qBaseScale: qrs[i].scale, fitsTop: qrs[i].fitsTop });
                    // ^ Appends each QR code to the model with its final computed position and scale.
                }
            }

            root.isQrSuccess = anySuccess;
            // ^ Sets the global success flag.

            root.showQrPopup = true
            // ^ Shows all QR popups.

            Quickshell.execDetached(["bash", "-c", "rm -f /tmp/qs_qr_result"])
            // ^ Cleans up the temporary QR result file.
        }
    }
    
    Timer {
        // ^ A timer that waits for the QR scanning script to complete before reading results.

        id: qrWaitTimer
        // ^ Identifier.

        interval: 1200  
        // ^ 1.2 second (1200ms) wait—gives the scanning script time to capture and process.

        repeat: false
        // ^ Fires only once per scan.

        onTriggered: qrReaderProcess.running = true
        // ^ Starts the result reader process after the wait.
    }
    
    function performQrScan() {
        // ^ Initiates a QR code scan of the currently selected region.

        Quickshell.execDetached(["bash", "-c", "rm -f /tmp/qs_qr_result"])
        // ^ Clears any previous QR result file.

        root.isScanningQr = true; root.showQrPopup = false; qrModel.clear()
        // ^ Sets scanning state, hides any existing popups, and clears the model.

        let cmd = `bash ~/.config/hypr/scripts/screenshot.sh --geometry "${root.geometryString}" --scan-qr`
        // ^ Constructs the command to run the screenshot script in QR scan mode with the current selection geometry.

        Quickshell.execDetached(["bash", "-c", cmd])
        // ^ Executes the QR scan in a detached background process.

        qrWaitTimer.start()
        // ^ Starts the wait timer; when it fires, the result reader will start.
    }   
    
    Timer {
        // ^ A brief delay timer that ensures the overlay hides before the capture command executes, preventing the overlay from appearing in the screenshot/recording.

        id: captureTimer
        // ^ Identifier.

        property string pendingCmd: ""
        // ^ Stores the capture command to execute after the delay.

        interval: 80
        // ^ 80ms delay—long enough for the window to hide, short enough to feel instant.

        repeat: false
        // ^ Fires once.

        onTriggered: {
            Quickshell.execDetached(["bash", "-c", pendingCmd])
            // ^ Executes the stored capture command.

            Qt.quit()
            // ^ Closes the overlay after triggering the capture.
        }
    }
    
    function executeCapture(openEditor, isRecord) {
        // ^ Constructs and schedules the capture command based on the current mode and settings.

        let cmd = `bash ~/.config/hypr/scripts/screenshot.sh --geometry "${root.geometryString}"`
        // ^ Base command with the current selection geometry.

        if (isRecord) {
            // ^ If video recording mode.

            cmd += " --record"
            // ^ Adds the record flag.

            cmd += ` --desk-vol ${root.deskVol} --desk-mute ${root.deskMute}`
            // ^ Passes desktop audio settings.

            cmd += ` --mic-vol ${root.micVol} --mic-mute ${root.micMute}`
            // ^ Passes microphone audio settings.

            if (root.micDevice !== "") cmd += ` --mic-dev "${root.micDevice}"`
            // ^ Passes the selected microphone device if chosen.
        }

        if (openEditor) cmd += " --edit"
        // ^ Adds the edit flag if the screenshot should open in an editor.

        root.visible = false
        // ^ Immediately hides the overlay so it doesn't appear in the capture.

        captureTimer.pendingCmd = cmd
        // ^ Stores the command for the timer.

        captureTimer.start()
        // ^ Starts the 80ms delay timer before executing the capture.
    }
}