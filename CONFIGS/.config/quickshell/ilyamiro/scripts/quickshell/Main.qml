// import QtQuick
// import QtQuick.Window
// import QtQuick.Controls
// import Quickshell
// import Quickshell.Io
// import Quickshell.Wayland
// import Quickshell.Services.Notifications
// import "WindowRegistry.js" as Registry

// import "notifications" as Notifs

// PanelWindow {
//     id: masterWindow
//     color: "transparent"
    
//     IpcHandler {
//         target: "main"
    
//         function forceReload() {
//             Quickshell.reload(true) 
//         }
//     }

//     WlrLayershell.namespace: "qs-master"
//     WlrLayershell.layer: WlrLayer.Overlay
    
//     exclusionMode: ExclusionMode.Ignore 
//     focusable: true

//     implicitWidth: masterWindow.screen.width
//     implicitHeight: masterWindow.screen.height

//     visible: isVisible

//     mask: Region { item: topBarHole; intersection: Intersection.Xor }
    
//     Item {
//         id: topBarHole
//         anchors.top: parent.top
//         anchors.left: parent.left
//         anchors.right: parent.right
//         height: 48 

//         anchors.leftMargin: (masterWindow.currentActive !== "hidden" && masterWindow.animX < 10) ? masterWindow.animW : 0
//         anchors.rightMargin: (masterWindow.currentActive !== "hidden" && (masterWindow.animX + masterWindow.animW) > (parent.width - 10)) ? masterWindow.animW : 0
        
//         Behavior on anchors.leftMargin { NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.InOutCubic } }
//         Behavior on anchors.rightMargin { NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.InOutCubic } }
//     }

//     MouseArea {
//         anchors.fill: parent
//         enabled: masterWindow.isVisible
//         onClicked: switchWidget("hidden", "")
//     }

//     // =========================================================
//     // --- DAEMON: PRELOADING SYSTEM
//     // =========================================================
//     Item {
//         id: preloaderContainer
//         visible: false
//     }

//     Component.onCompleted: {
//         Qt.callLater(() => {
//             let widgetsToPreload = ["settings", "search", "help"];
//             for (let i = 0; i < widgetsToPreload.length; i++) {
//                 let t = getLayout(widgetsToPreload[i]);
//                 if (t && t.comp) {
//                     t.comp.incubateObject(preloaderContainer, {
//                         "notifModel": masterWindow.notifModel
//                     }, Qt.Asynchronous);
//                 }
//             }
//         });
//     }

//     property string currentActive: "hidden"

//     onCurrentActiveChanged: {
//         Quickshell.execDetached(["bash", "-c", "echo '" + currentActive + "' > /tmp/qs_current_widget"]);
//     }

//     property bool isVisible: false
//     property string activeArg: ""
//     property bool disableMorph: false 
//     property int morphDuration: 250
//     property int exitDuration: 170 

//     property real animW: 1
//     property real animH: 1
//     property real animX: 0
//     property real animY: 0
    
//     property real targetW: 1
//     property real targetH: 1

//     property real globalUiScale: 1.0

//     // =========================================================
//     // --- DAEMON: NOTIFICATION HANDLING
//     // =========================================================
//     ListModel {
//         id: globalNotificationHistory
//     }

//     ListModel {
//         id: activePopupsModel
//     }

//     property int _popupCounter: 0

//     function removePopup(uid) {
//         for (let i = 0; i < activePopupsModel.count; i++) {
//             if (activePopupsModel.get(i).uid === uid) {
//                 activePopupsModel.remove(i);
//                 break;
//             }
//         }
//     }

//     NotificationServer {
//         id: globalNotificationServer
//         bodySupported: true
//         actionsSupported: true
//         imageSupported: true

//         onNotification: (n) => {
//             console.log("Saving to history:", n.appName, "-", n.summary);
            
//             let notifData = {
//                 "appName": n.appName !== "" ? n.appName : "System",
//                 "summary": n.summary !== "" ? n.summary : "No Title",
//                 "body": n.body !== "" ? n.body : "",
//                 "iconPath": n.appIcon !== "" ? n.appIcon : "",
//                 "notif": n
//             };

//             globalNotificationHistory.insert(0, notifData);

//             masterWindow._popupCounter++;
//             let popupData = Object.assign({ "uid": masterWindow._popupCounter }, notifData);
//             activePopupsModel.append(popupData);
//         }
//     }   
//     property var notifModel: globalNotificationHistory
    
//     Notifs.NotificationPopups {
//         id: osdPopups
//         popupModel: activePopupsModel
//         uiScale: masterWindow.globalUiScale
//     }
//     // =========================================================

//     onGlobalUiScaleChanged: {
//         handleNativeScreenChange();
//     }

//     Process {
//         id: settingsReader
//         command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null || echo '{}'"]
//         running: true 
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 try {
//                     if (this.text && this.text.trim().length > 0 && this.text.trim() !== "{}") {
//                         let parsed = JSON.parse(this.text);
//                         if (parsed.uiScale !== undefined && masterWindow.globalUiScale !== parsed.uiScale) {
//                             masterWindow.globalUiScale = parsed.uiScale;
//                         }
//                     }
//                 } catch (e) {
//                     console.log("Error parsing settings.json in main.qml:", e);
//                 }
//             }
//         }
//     }

//     Process {
//         id: settingsWatcher
//         command: ["bash", "-c", "while [ ! -f ~/.config/hypr/settings.json ]; do sleep 1; done; inotifywait -qq -e modify,close_write ~/.config/hypr/settings.json"]
//         running: true
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 settingsReader.running = false;
//                 settingsReader.running = true;
                
//                 settingsWatcher.running = false;
//                 settingsWatcher.running = true;
//             }
//         }
//     }

//     function getLayout(name) {
//         return Registry.getLayout(name, 0, 0, masterWindow.width, masterWindow.height, masterWindow.globalUiScale);
//     }

//     Connections {
//         target: masterWindow
//         function onWidthChanged() { handleNativeScreenChange(); }
//         function onHeightChanged() { handleNativeScreenChange(); }
//     }

//     function handleNativeScreenChange() {
//         if (masterWindow.currentActive === "hidden") return;
        
//         let t = getLayout(masterWindow.currentActive);
//         if (t) {
//             let currentItem = widgetStack.currentItem;
            
//             // Check if the current widget has dynamic dimensional overrides
//             let finalW = (currentItem && currentItem.targetMasterWidth !== undefined) ? currentItem.targetMasterWidth : t.w;
//             let finalH = (currentItem && currentItem.targetMasterHeight !== undefined) ? currentItem.targetMasterHeight : t.h;
            
//             // Re-center X if the width dynamically changed
//             let finalX = t.rx;
//             if (currentItem && currentItem.targetMasterWidth !== undefined && finalW !== t.w) {
//                 finalX = Math.floor((masterWindow.width / 2) - (finalW / 2));
//             }

//             masterWindow.animX = finalX;
//             masterWindow.animY = t.ry;
//             masterWindow.animW = finalW;
//             masterWindow.animH = finalH;
//             masterWindow.targetW = finalW;
//             masterWindow.targetH = finalH;
//         }
//     }

//     onIsVisibleChanged: {
//         if (isVisible) widgetStack.forceActiveFocus();
//     }

//     Item {
//         x: masterWindow.animX
//         y: masterWindow.animY
//         width: masterWindow.animW
//         height: masterWindow.animH
//         clip: true 

//         // Continuous bounding box morphing
//         Behavior on x { enabled: !masterWindow.disableMorph; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.InOutCubic } }
//         Behavior on y { enabled: !masterWindow.disableMorph; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.InOutCubic } }
//         Behavior on width { enabled: !masterWindow.disableMorph; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.InOutCubic } }
//         Behavior on height { enabled: !masterWindow.disableMorph; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.InOutCubic } }

//         opacity: masterWindow.isVisible ? 1.0 : 0.0
//         Behavior on opacity { NumberAnimation { duration: masterWindow.morphDuration === 170 ? 130 : 100; easing.type: Easing.InOutCubic } }

//         MouseArea {
//             anchors.fill: parent
//         }

//         // Full anchoring so the content properly morphs with the box
//         Item {
//             anchors.fill: parent

//             StackView {
//                 id: widgetStack
//                 anchors.fill: parent
//                 focus: true
                
//                 Keys.onEscapePressed: {
//                     switchWidget("hidden", "");
//                     event.accepted = true;
//                 }

//                 onCurrentItemChanged: {
//                     if (currentItem) currentItem.forceActiveFocus();
//                 }

//                 replaceEnter: Transition {
//                     SequentialAnimation {
//                         PropertyAction { property: "z"; value: -1 }
//                         // Keep new widget fully opaque. The old widget acts as a shield while this one sets up.
//                         NumberAnimation { property: "opacity"; from: 1.0; to: 1.0; duration: masterWindow.morphDuration }
//                     }
//                 }
                
//                 replaceExit: Transition {
//                     SequentialAnimation {
//                         PropertyAction { property: "z"; value: 1 }
//                         ParallelAnimation {
//                             SequentialAnimation {
//                                 // THE SHIELD: Hold old widget completely opaque for 30ms.
//                                 PauseAnimation { duration: 30 }
//                                 NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: masterWindow.morphDuration - 30; easing.type: Easing.InOutQuad }
//                             }
//                             NumberAnimation { property: "scale"; from: 1.0; to: 1.05; duration: masterWindow.morphDuration; easing.type: Easing.OutCubic }
//                         }
//                     }
//                 }
//             }
//         }
//     }

//     function switchWidget(newWidget, arg) {
//         prepTimer.stop();
//         delayedClear.stop();
    
//         if (newWidget === "hidden") {
//             if (currentActive !== "hidden") {
//                 masterWindow.morphDuration = 170; 
//                 masterWindow.exitDuration = 170;
//                 masterWindow.disableMorph = false;
                
//                 masterWindow.animW = 1;
//                 masterWindow.animH = 1;
//                 masterWindow.isVisible = false; 
                
//                 delayedClear.start();
//             }
//         } else {
//             if (currentActive === "hidden" || !masterWindow.isVisible) {
//                 masterWindow.morphDuration = 250; 
//                 masterWindow.exitDuration = 250;
//                 masterWindow.disableMorph = false;
                
//                 let t = getLayout(newWidget);
//                 masterWindow.animX = t.rx;
//                 masterWindow.animY = t.ry;
//                 masterWindow.animW = t.w;
//                 masterWindow.animH = t.h;
//                 masterWindow.targetW = t.w;
//                 masterWindow.targetH = t.h;
//             } else {
//                 masterWindow.morphDuration = 300; 
//                 masterWindow.disableMorph = false;
//                 masterWindow.exitDuration = (newWidget === "wallpaper") ? 125 : 300;
//             }
    
//         prepTimer.newWidget = newWidget;
//         prepTimer.newArg = arg;
//         prepTimer.start();
//         }
//     }

//     Timer {
//         id: prepTimer
//         interval: 15 
//         property string newWidget: ""
//         property string newArg: ""
//         onTriggered: executeSwitch(newWidget, newArg, false)
//     }

//     function executeSwitch(newWidget, arg, immediate) {
//         masterWindow.currentActive = newWidget;
//         masterWindow.activeArg = arg;
        
//         let t = getLayout(newWidget);
//         masterWindow.animX = t.rx;
//         masterWindow.animY = t.ry;
//         masterWindow.animW = t.w;
//         masterWindow.animH = t.h;
//         masterWindow.targetW = t.w;
//         masterWindow.targetH = t.h;
        
//         let props = newWidget === "wallpaper" ? { "widgetArg": arg } : {};
// 	props["notifModel"] = masterWindow.notifModel;
// 	props["layoutWidth"] = t.w;
// 	props["layoutHeight"] = t.h;

//         if (immediate) {
//             widgetStack.replace(t.comp, props, StackView.Immediate);
//         } else {
//             widgetStack.replace(t.comp, props);
//         }
        
//         // Ensure Main.qml respects the dynamic size of the newly loaded widget immediately
//         let currentItem = widgetStack.currentItem;
//         if (currentItem) {
//             if (currentItem.targetMasterWidth !== undefined) {
//                 let dynW = currentItem.targetMasterWidth;
//                 masterWindow.animW = dynW;
//                 masterWindow.targetW = dynW;
//                 masterWindow.animX = Math.floor((masterWindow.width / 2) - (dynW / 2));
//             }
//             if (currentItem.targetMasterHeight !== undefined) {
//                 masterWindow.animH = currentItem.targetMasterHeight;
//                 masterWindow.targetH = currentItem.targetMasterHeight;
//             }
//         }
        
//         masterWindow.isVisible = true;
//     }
//     // =========================================================
//     // --- IPC: EVENT-DRIVEN WATCHER
//     // =========================================================
//     Process {
//         id: ipcWatcher
//         command: ["bash", "-c",
//             "touch /tmp/qs_widget_state; " +
//             "inotifywait -qq -e close_write /tmp/qs_widget_state 2>/dev/null; " +
//             "cat /tmp/qs_widget_state"
//         ]
//         running: true
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 let rawCmd = this.text.trim();

//                 if (rawCmd !== "") {
//                     let parts = rawCmd.split(":");
//                     let cmd = parts[0];

//                     // Determine if the widget is currently in its closing animation
//                     let isClosing = (masterWindow.currentActive !== "hidden" && !masterWindow.isVisible);
//                     let effectivelyActive = isClosing ? "hidden" : masterWindow.currentActive;

//                     if (cmd === "close") {
//                         switchWidget("hidden", "");
//                     } else if (cmd === "toggle" || cmd === "open") {
//                         let targetWidget = parts.length > 1 ? parts[1] : "";
//                         let arg = parts.length > 2 ? parts.slice(2).join(":") : "";

//                         delayedClear.stop();
                        
//                         // Use effectivelyActive so a closing widget isn't accidentally toggled off again
//                         if (targetWidget === effectivelyActive) {
//                             let currentItem = widgetStack.currentItem;
                            
//                             if (arg !== "" && currentItem && currentItem.activeMode !== undefined && currentItem.activeMode !== arg) {
//                                 currentItem.activeMode = arg;
//                             } 
//                             else if (cmd === "toggle") {
//                                 switchWidget("hidden", "");
//                             }
                            
//                         } else if (getLayout(targetWidget)) {
//                             switchWidget(targetWidget, arg);
//                         }
//                     } else if (getLayout(cmd)) { 
//                         let arg = parts.length > 1 ? parts.slice(1).join(":") : "";
//                         delayedClear.stop();
                        
//                         if (cmd === effectivelyActive) {
//                             let currentItem = widgetStack.currentItem;
//                             if (arg !== "" && currentItem && currentItem.activeMode !== undefined && currentItem.activeMode !== arg) {
//                                 currentItem.activeMode = arg;
//                             } else {
//                                 switchWidget("hidden", "");
//                             }
//                         } else {
//                             switchWidget(cmd, arg);
//                         }
//                     }
//                 }

//                 ipcWatcher.running = false;
//                 ipcWatcher.running = true;
//             }
//         }
//     }   
//     Timer {
//         id: delayedClear
//         interval: masterWindow.morphDuration 
//         onTriggered: {
//             masterWindow.currentActive = "hidden";
//             widgetStack.clear();
//             masterWindow.disableMorph = false;
//         }
//     }
// }







import QtQuick
// ^ Imports the QtQuick module, providing all fundamental QML types (Item, Rectangle, animations, bindings, etc.) for building the user interface.

import QtQuick.Window
// ^ Imports the Window module, providing access to screen properties like Screen.width and Screen.height for positioning and sizing calculations.

import QtQuick.Controls
// ^ Imports Qt Quick Controls, providing StackView for widget transitions and other standard UI components.

import Quickshell
// ^ Imports the Quickshell module, providing the PanelWindow type, Process management, environment access, and shell integration for Wayland.

import Quickshell.Io
// ^ Imports the Quickshell Io module, providing StdioCollector for capturing process output asynchronously from shell commands.

import Quickshell.Wayland
// ^ Imports the Quickshell Wayland module, providing WlrLayershell for layer shell protocol integration (overlay, top, bottom layers) and other Wayland-specific types.

import Quickshell.Services.Notifications
// ^ Imports the Notifications module, providing NotificationServer for receiving and managing desktop notifications from other applications via the Freedesktop Notification protocol.

import "WindowRegistry.js" as Registry
// ^ Imports a JavaScript file (WindowRegistry.js) as a module named "Registry". This file contains layout definitions for all widgets, specifying their position, size, and QML component for each widget type.

import "notifications" as Notifs
// ^ Imports the "notifications" directory as a module named "Notifs", providing access to the NotificationPopups component that renders notification toast popups.

PanelWindow {
    // ^ Defines the root window as a PanelWindow, which is a Quickshell-specific window type designed for desktop panels and overlays. It integrates with the compositor as a layer shell surface.

    id: masterWindow
    // ^ Assigns the global identifier "masterWindow" for referencing throughout the application.

    color: "transparent"
    // ^ Sets the background color to transparent, allowing the widgets and popups to be seen against the desktop without a solid background rectangle.
    
    IpcHandler {
        // ^ Creates an IPC (Inter-Process Communication) handler that listens for commands from external processes (e.g., shell scripts) targeting this QuickShell instance.

        target: "main"
        // ^ The IPC channel name "main" identifies this handler—external commands target "main" to communicate with this Main.qml instance.
    
        function forceReload() {
            // ^ Defines a remotely callable function that forces a complete reload of the QML application.

            Quickshell.reload(true) 
            // ^ Calls Quickshell's reload function with the argument `true`, which likely indicates a full/force reload, re-reading all QML files and reinitializing the application state.
        }
    }

    WlrLayershell.namespace: "qs-master"
    // ^ Sets the layer shell namespace to "qs-master", a unique identifier that tells the compositor which layer surface this is. Multiple QuickShell instances can coexist with different namespaces.

    WlrLayershell.layer: WlrLayer.Overlay
    // ^ Places this window on the "Overlay" layer, which is above regular windows, panels, and most other surfaces. This ensures the widget popups and overlays appear on top of all other content.

    exclusionMode: ExclusionMode.Ignore 
    // ^ Sets the exclusion mode to "Ignore", meaning this panel will not push other shell surfaces (like panels) out of the way. It simply floats over everything.

    focusable: true
    // ^ Allows this window to receive keyboard focus, which is essential for widgets with text input, keyboard shortcuts, or Escape-to-close functionality.

    implicitWidth: masterWindow.screen.height
    // ^ Sets the implicit width to the full screen width, ensuring the window covers the entire display area even when widgets are smaller.

    implicitHeight: masterWindow.screen.height
    // ^ Sets the implicit height to the full screen height, providing a full-screen canvas for positioning widgets anywhere on the display.

    visible: isVisible
    // ^ Binds the window's visibility to the custom `isVisible` property. When `isVisible` is false, the entire overlay is hidden from view.

    mask: Region { item: topBarHole; intersection: Intersection.Xor }
    // ^ Creates an input mask using the XOR intersection mode: this cuts a hole in the input region corresponding to the topBarHole item's area. Mouse events pass through this hole to windows below, while the rest of the screen (where widgets appear) captures input. The top bar area is excluded from input blocking so users can interact with the actual bar beneath.

    Item {
        // ^ Defines the region that will be "cut out" from the input mask, allowing clicks to pass through to the top bar below.

        id: topBarHole
        // ^ Assigns the identifier for the mask definition above.

        anchors.top: parent.top
        // ^ Positioned at the very top of the screen.

        anchors.left: parent.left
        // ^ Starts from the left edge.

        anchors.right: parent.right
        // ^ Extends to the right edge (full width by default).

        height: 48 
        // ^ The standard top bar height of 48 pixels, matching the TopBar's height.

        anchors.leftMargin: (masterWindow.currentActive !== "hidden" && masterWindow.animX < 10) ? masterWindow.animW : 0
        // ^ Dynamically adjusts the left margin: when a widget is open AND it's positioned very close to the left edge (within 10px), the hole's left margin expands by the widget's width. This extends the click-through hole to cover the area behind the widget, preventing dead zones. Otherwise, margin is 0.

        anchors.rightMargin: (masterWindow.currentActive !== "hidden" && (masterWindow.animX + masterWindow.animW) > (parent.width - 10)) ? masterWindow.animW : 0
        // ^ Same logic for the right side: when a widget is near the right edge, the right margin expands to cover behind it, ensuring the top bar remains clickable across its full width minus the widget area.

        Behavior on anchors.leftMargin { NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.InOutCubic } }
        // ^ Smoothly animates changes to the left margin, matching the widget morphing duration and easing for seamless transition.

        Behavior on anchors.rightMargin { NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.InOutCubic } }
        // ^ Smoothly animates right margin changes with the same timing and easing.
    }

    MouseArea {
        // ^ A full-screen invisible mouse area that captures clicks anywhere on the overlay when a widget is visible.

        anchors.fill: parent
        // ^ Covers the entire screen.

        enabled: masterWindow.isVisible
        // ^ Only active when the overlay is visible (a widget is open).

        onClicked: switchWidget("hidden", "")
        // ^ Any click on the background (not on the widget itself) closes the current widget by switching to the "hidden" state with no arguments.
    }

    // =========================================================
    // --- DAEMON: PRELOADING SYSTEM
    // =========================================================
    Item {
        // ^ An invisible container used for preloading widget components asynchronously. By incubating components here before they're needed, widget opening feels instant.

        id: preloaderContainer
        // ^ Assigns the identifier for the incubation target.

        visible: false
        // ^ Hidden from view—this container exists solely to hold preloaded component instances in the background.
    }

    Component.onCompleted: {
        // ^ Runs once when the master window has finished initializing.

        Qt.callLater(() => {
            // ^ Qt.callLater defers the enclosed function to run after the current event loop cycle, ensuring the UI is fully set up before starting intensive preloading.

            let widgetsToPreload = ["settings", "search", "help"];
            // ^ Array of widget names to preload. These are prioritized because they might be opened early in the session.

            for (let i = 0; i < widgetsToPreload.length; i++) {
                // ^ Iterates over each widget to preload.

                let t = getLayout(widgetsToPreload[i]);
                // ^ Retrieves the layout definition object for the current widget, which contains position, size, and component information.

                if (t && t.comp) {
                    // ^ If a valid layout was found and it has a component reference.

                    t.comp.incubateObject(preloaderContainer, {
                        "notifModel": masterWindow.notifModel
                    }, Qt.Asynchronous);
                    // ^ Incubates (creates an instance of) the widget component as a child of the preloaderContainer. The initial properties include the notification model. Using `Qt.Asynchronous` means the component loads in a background thread, preventing UI freezes during preloading.
                }
            }
        });
    }

    property string currentActive: "hidden"
    // ^ Tracks which widget is currently active/open. "hidden" means no widget is shown. Other values correspond to widget names like "calendar", "network", "wallpaper", etc.

    onCurrentActiveChanged: {
        // ^ Called whenever the currentActive property changes.

        Quickshell.execDetached(["bash", "-c", "echo '" + currentActive + "' > /tmp/qs_current_widget"]);
        // ^ Writes the currently active widget name to a temporary file. Other scripts or services can read this file to know which QuickShell widget is currently open, enabling contextual behavior.
    }

    property bool isVisible: false
    // ^ Tracks whether the overlay is currently visible (a widget is open or animating). When false, the window is hidden. Bound to the window's `visible` property.

    property string activeArg: ""
    // ^ Stores any additional argument passed when opening a widget (e.g., the specific network mode "wifi" when opening the network panel).

    property bool disableMorph: false 
    // ^ When true, disables the position/size animation (morphing) for instant transitions. Used when switching between widgets of drastically different types where morphing would look odd.

    property int morphDuration: 250
    // ^ The duration in milliseconds for the widget resize/reposition animation. Default 250ms for opening, may be shortened for closing.

    property int exitDuration: 170 
    // ^ The duration in milliseconds for the exit/closing animation. Slightly faster than opening (170ms vs 250ms) for snappy dismissal.

    property real animW: 1
    // ^ The current animated width of the widget container. Starts at 1px (nearly invisible) and animates to the target width when a widget opens.

    property real animH: 1
    // ^ The current animated height of the widget container. Starts at 1px and animates to the target height.

    property real animX: 0
    // ^ The current animated X position of the widget container. Animates from the previous widget's position or from a corner.

    property real animY: 0
    // ^ The current animated Y position of the widget container.

    property real targetW: 1
    // ^ The target width the animation is moving toward. Set when a widget opens or when the screen resolution changes.

    property real targetH: 1
    // ^ The target height the animation is moving toward.

    property real globalUiScale: 1.0
    // ^ The global UI scale factor, used to adjust widget sizes for high-DPI displays. Loaded from settings.json and distributed to all widgets.

    // =========================================================
    // --- DAEMON: NOTIFICATION HANDLING
    // =========================================================
    ListModel {
        // ^ A ListModel that stores the complete history of all received notifications. This persists for the session and can be viewed in a notification history widget.

        id: globalNotificationHistory
        // ^ Assigns the identifier for accessing the notification history.
    }

    ListModel {
        // ^ A ListModel that tracks currently active/popup notifications. Each entry corresponds to a visible notification toast on screen.

        id: activePopupsModel
        // ^ Assigns the identifier for the popup system to use.
    }

    property int _popupCounter: 0
    // ^ An internal counter that assigns a unique ID to each incoming notification popup. Incremented for every notification received. The underscore prefix conventionally indicates a private property.

    function removePopup(uid) {
        // ^ Removes a notification popup from the active model by its unique ID.

        for (let i = 0; i < activePopupsModel.count; i++) {
            // ^ Iterates through all active popups.

            if (activePopupsModel.get(i).uid === uid) {
                // ^ Finds the popup with the matching unique ID.

                activePopupsModel.remove(i);
                // ^ Removes that entry from the model, which causes the corresponding visual popup to disappear.

                break;
                // ^ Exits the loop once found and removed.
            }
        }
    }

    NotificationServer {
        // ^ Creates a NotificationServer that implements the Freedesktop Notification protocol. This allows other applications to send notifications to QuickShell, which will display them as custom-styled popups.

        id: globalNotificationServer
        // ^ Assigns the identifier for referencing.

        bodySupported: true
        // ^ Enables support for notification body text (the detailed message below the summary).

        actionsSupported: true
        // ^ Enables support for notification actions (buttons that users can click in response to a notification).

        imageSupported: true
        // ^ Enables support for notification images/icons, allowing rich media in notifications.

        onNotification: (n) => {
            // ^ Signal handler called whenever a new notification is received. The `n` parameter is the notification object with properties like appName, summary, body, appIcon, etc.

            console.log("Saving to history:", n.appName, "-", n.summary);
            // ^ Logs the notification to the console for debugging purposes.

            let notifData = {
                "appName": n.appName !== "" ? n.appName : "System",
                "summary": n.summary !== "" ? n.summary : "No Title",
                "body": n.body !== "" ? n.body : "",
                "iconPath": n.appIcon !== "" ? n.appIcon : "",
                "notif": n
            };
            // ^ Creates a sanitized data object from the notification, providing defaults for empty fields: "System" for app name, "No Title" for summary, empty strings for body and icon.

            globalNotificationHistory.insert(0, notifData);
            // ^ Inserts the new notification at the beginning of the history model (position 0), so newest notifications appear first.

            masterWindow._popupCounter++;
            // ^ Increments the popup counter to get a new unique ID.

            let popupData = Object.assign({ "uid": masterWindow._popupCounter }, notifData);
            // ^ Creates a popup data object by merging the unique ID with the notification data using Object.assign. This popup-specific copy includes a uid for removal tracking.

            activePopupsModel.append(popupData);
            // ^ Adds the popup to the active popups model, which triggers the visual notification toast to appear on screen.
        }
    }   

    property var notifModel: globalNotificationHistory
    // ^ Exposes the notification history model as a property that can be passed to widgets. This allows any widget to display recent notifications.

    Notifs.NotificationPopups {
        // ^ Instantiates the NotificationPopups component from the imported "notifications" module.

        id: osdPopups
        // ^ Assigns the identifier "osdPopups" for this notification display component.

        popupModel: activePopupsModel
        // ^ Passes the active popups model to the component, so it displays toasts for each entry.

        uiScale: masterWindow.globalUiScale
        // ^ Passes the global UI scale to ensure notification popups are properly sized on high-DPI displays.
    }
    // =========================================================

    onGlobalUiScaleChanged: {
        // ^ Called when the global UI scale changes (e.g., due to settings update).

        handleNativeScreenChange();
        // ^ Calls the screen change handler to reposition and resize the current widget with the new scale factor.
    }

    Process {
        // ^ A Process that reads the UI scale from the settings JSON file at startup.

        id: settingsReader
        // ^ Assigns the identifier for referencing this process.

        command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null || echo '{}'"]
        // ^ Reads the settings JSON file, suppressing errors if it doesn't exist, and falls back to an empty JSON object.

        running: true 
        // ^ Runs immediately on startup.

        stdout: StdioCollector {
            // ^ Captures the JSON output.

            onStreamFinished: {
                // ^ Called when the file has been read.

                try {
                    // ^ Try block to safely parse potentially malformed JSON.

                    if (this.text && this.text.trim().length > 0 && this.text.trim() !== "{}") {
                        // ^ If there's meaningful content in the settings file.

                        let parsed = JSON.parse(this.text);
                        // ^ Parses the JSON text into an object.

                        if (parsed.uiScale !== undefined && masterWindow.globalUiScale !== parsed.uiScale) {
                            // ^ If the uiScale setting exists AND is different from the current value.

                            masterWindow.globalUiScale = parsed.uiScale;
                            // ^ Updates the global UI scale, which triggers onGlobalUiScaleChanged.
                        }
                    }
                } catch (e) {
                    // ^ Catches any parsing errors.

                    console.log("Error parsing settings.json in main.qml:", e);
                    // ^ Logs the error for debugging.
                }
            }
        }
    }

    Process {
        // ^ A Process that watches the settings JSON file for changes using inotifywait.

        id: settingsWatcher
        // ^ Assigns the identifier.

        command: ["bash", "-c", "while [ ! -f ~/.config/hypr/settings.json ]; do sleep 1; done; inotifywait -qq -e modify,close_write ~/.config/hypr/settings.json"]
        // ^ A bash command that: (1) waits in a loop until the settings file exists (sleeping 1 second between checks), (2) then uses inotifywait to block until the file is modified. The `-qq` flag makes it very quiet, `-e modify,close_write` watches for file modification events.

        running: true
        // ^ Starts running immediately.

        stdout: StdioCollector {
            // ^ Captures output (though inotifywait -qq outputs nothing on success).

            onStreamFinished: {
                // ^ Called when inotifywait detects a modification.

                settingsReader.running = false;
                // ^ Stops the reader process if it was still running.

                settingsReader.running = true;
                // ^ Restarts the reader to re-read the updated settings file.

                settingsWatcher.running = false;
                // ^ Stops this watcher process.

                settingsWatcher.running = true;
                // ^ Restarts the watcher to continue monitoring for further changes. This restart pattern ensures clean process state and avoids zombie processes.
            }
        }
    }

    function getLayout(name) {
        // ^ Retrieves the layout definition for a widget by name. This function delegates to the WindowRegistry.js module.

        return Registry.getLayout(name, 0, 0, masterWindow.width, masterWindow.height, masterWindow.globalUiScale);
        // ^ Calls the Registry's getLayout function, passing the widget name, default offsets (0,0), the window dimensions, and the UI scale. Returns an object with position (rx, ry), size (w, h), and component reference (comp) for the widget.
    }

    Connections {
        // ^ Creates connections to signals from the masterWindow itself, enabling responsive layout adjustments.

        target: masterWindow
        // ^ Connects to the masterWindow's signals.

        function onWidthChanged() { handleNativeScreenChange(); }
        // ^ When the window width changes (e.g., display resolution change, monitor hotplug), calls the screen change handler.

        function onHeightChanged() { handleNativeScreenChange(); }
        // ^ When the window height changes, also triggers layout recalculation.
    }

    function handleNativeScreenChange() {
        // ^ Handles screen resolution or scaling changes by recalculating widget position and size.

        if (masterWindow.currentActive === "hidden") return;
        // ^ If no widget is currently open, there's nothing to reposition—exit early.

        let t = getLayout(masterWindow.currentActive);
        // ^ Gets the layout definition for the currently active widget.

        if (t) {
            // ^ If a valid layout was found.

            let currentItem = widgetStack.currentItem;
            // ^ Gets a reference to the currently displayed widget item in the StackView.

            // Check if the current widget has dynamic dimensional overrides
            let finalW = (currentItem && currentItem.targetMasterWidth !== undefined) ? currentItem.targetMasterWidth : t.w;
            // ^ If the current widget item has a custom target width (dynamic sizing), use it; otherwise use the layout's default width.

            let finalH = (currentItem && currentItem.targetMasterHeight !== undefined) ? currentItem.targetMasterHeight : t.h;
            // ^ Same logic for height—allows widgets to override their default height.

            // Re-center X if the width dynamically changed
            let finalX = t.rx;
            // ^ Starts with the layout's default X position.

            if (currentItem && currentItem.targetMasterWidth !== undefined && finalW !== t.w) {
                // ^ If the widget has a dynamic width that differs from the layout default.

                finalX = Math.floor((masterWindow.width / 2) - (finalW / 2));
                // ^ Recalculates X to center the widget horizontally based on its new width.
            }

            masterWindow.animX = finalX;
            // ^ Updates the animated X position, triggering the morphing animation.

            masterWindow.animY = t.ry;
            // ^ Updates the animated Y position from the layout.

            masterWindow.animW = finalW;
            // ^ Updates the animated width.

            masterWindow.animH = finalH;
            // ^ Updates the animated height.

            masterWindow.targetW = finalW;
            // ^ Updates the target width to match.

            masterWindow.targetH = finalH;
            // ^ Updates the target height to match.
        }
    }

    onIsVisibleChanged: {
        // ^ Called when the isVisible property changes.

        if (isVisible) widgetStack.forceActiveFocus();
        // ^ When becoming visible, forces keyboard focus to the widget stack so keyboard shortcuts (like Escape) work immediately.
    }

    Item {
        // ^ The container that holds the widget and animates its position and size (the morphing box).

        x: masterWindow.animX
        // ^ Bound to the animated X position, so the container moves smoothly.

        y: masterWindow.animY
        // ^ Bound to the animated Y position.

        width: masterWindow.animW
        // ^ Bound to the animated width.

        height: masterWindow.animH
        // ^ Bound to the animated height.

        clip: true 
        // ^ Clips child content to the container's boundaries. Essential during animations to prevent the widget from being visible outside its intended area while morphing.

        // Continuous bounding box morphing
        Behavior on x { enabled: !masterWindow.disableMorph; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.InOutCubic } }
        // ^ Animates X position changes smoothly when morphing is enabled. Uses the current morphDuration with a cubic easing for natural motion.

        Behavior on y { enabled: !masterWindow.disableMorph; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.InOutCubic } }
        // ^ Animates Y position changes with the same timing and easing.

        Behavior on width { enabled: !masterWindow.disableMorph; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.InOutCubic } }
        // ^ Animates width changes, creating the expanding/contracting widget effect.

        Behavior on height { enabled: !masterWindow.disableMorph; NumberAnimation { duration: masterWindow.morphDuration; easing.type: Easing.InOutCubic } }
        // ^ Animates height changes, completing the morphing effect.

        opacity: masterWindow.isVisible ? 1.0 : 0.0
        // ^ The container is fully opaque when visible, fully transparent when hidden.

        Behavior on opacity { NumberAnimation { duration: masterWindow.morphDuration === 170 ? 130 : 100; easing.type: Easing.InOutCubic } }
        // ^ Animates opacity changes: faster fade when closing (130ms when morphDuration is 170ms for closing), slightly slower otherwise (100ms).

        MouseArea {
            // ^ An empty mouse area that fills the container, preventing clicks on the widget from passing through to the background dismiss click zone.

            anchors.fill: parent
            // ^ Covers the entire animated container.
        }

        // Full anchoring so the content properly morphs with the box
        Item {
            // ^ An item that fills the animated container, serving as the direct parent for the StackView.

            anchors.fill: parent
            // ^ Matches the animated container's size exactly, ensuring the widget content scales with the morphing box.

            StackView {
                // ^ A StackView that manages widget transitions. It can display one widget at a time and provides push/pop/replace navigation with transition animations.

                id: widgetStack
                // ^ Assigns the identifier for programmatic control.

                anchors.fill: parent
                // ^ Fills the parent item, which is the animated container.

                focus: true
                // ^ Ensures the StackView has focus by default, allowing keyboard input to reach active widgets.
                
                Keys.onEscapePressed: {
                    // ^ Handles the Escape key globally for the StackView.

                    switchWidget("hidden", "");
                    // ^ Closes the current widget by switching to hidden state.

                    event.accepted = true;
                    // ^ Marks the event as handled to prevent further propagation.
                }

                onCurrentItemChanged: {
                    // ^ Called when the visible widget in the stack changes.

                    if (currentItem) currentItem.forceActiveFocus();
                    // ^ Forces keyboard focus to the newly displayed widget item, ensuring it can immediately receive key input.
                }

                replaceEnter: Transition {
                    // ^ Defines the transition animation when a new widget enters the stack (replacing the previous one).

                    SequentialAnimation {
                        // ^ A sequence of animations for the entering widget.

                        PropertyAction { property: "z"; value: -1 }
                        // ^ Immediately sets the entering widget's z-index to -1, placing it BEHIND the exiting widget. This is part of the "shield" technique.

                        // Keep new widget fully opaque. The old widget acts as a shield while this one sets up.
                        NumberAnimation { property: "opacity"; from: 1.0; to: 1.0; duration: masterWindow.morphDuration }
                        // ^ Keeps the entering widget at full opacity throughout the transition. The exiting widget's animation hides the fact that the new widget is already present behind it.
                    }
                }
                
                replaceExit: Transition {
                    // ^ Defines the transition animation when the old widget exits the stack.

                    SequentialAnimation {
                        // ^ A sequence of animations for the exiting widget.

                        PropertyAction { property: "z"; value: 1 }
                        // ^ Immediately sets the exiting widget's z-index to 1, placing it IN FRONT of the entering widget. This is the "shield" that covers the new widget while it loads.

                        ParallelAnimation {
                            // ^ Two animations run simultaneously on the exiting widget.

                            SequentialAnimation {
                                // ^ A sub-sequence for the opacity fade.

                                // THE SHIELD: Hold old widget completely opaque for 30ms.
                                PauseAnimation { duration: 30 }
                                // ^ Initially pauses for 30ms at full opacity. This gives the entering widget a moment to load and render its first frame before the old widget starts fading.

                                NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: masterWindow.morphDuration - 30; easing.type: Easing.InOutQuad }
                                // ^ After the 30ms pause, fades the old widget out over the remaining morph duration. The transition is slightly shorter than the full duration to account for the initial pause.
                            }

                            NumberAnimation { property: "scale"; from: 1.0; to: 1.05; duration: masterWindow.morphDuration; easing.type: Easing.OutCubic }
                            // ^ Simultaneously, the old widget slightly scales up to 105%, creating a subtle "push forward" effect as it fades away. The easing out creates a smooth deceleration.
                        }
                    }
                }
            }
        }
    }

    function switchWidget(newWidget, arg) {
        // ^ The main function for switching between widgets. Handles opening, closing, and morphing between widgets. Takes the widget name and an optional argument.

        prepTimer.stop();
        // ^ Stops any pending preparation timer from a previous switch.

        delayedClear.stop();
        // ^ Stops any pending delayed clear timer.
    
        if (newWidget === "hidden") {
            // ^ If switching to "hidden" (closing the current widget).

            if (currentActive !== "hidden") {
                // ^ Only proceed if there's actually a widget to close.

                masterWindow.morphDuration = 170; 
                // ^ Sets a faster morph duration for closing (170ms vs 250ms for opening).

                masterWindow.exitDuration = 170;
                // ^ Sets the exit duration to match.

                masterWindow.disableMorph = false;
                // ^ Ensures morphing is enabled for the close animation.

                masterWindow.animW = 1;
                // ^ Sets the animated width to 1px, causing the container to shrink to a tiny point.

                masterWindow.animH = 1;
                // ^ Sets the animated height to 1px.

                masterWindow.isVisible = false; 
                // ^ Sets visibility to false, which triggers the opacity fade out.

                delayedClear.start();
                // ^ Starts the delayed clear timer that will fully clear the stack after the animation completes.
            }
        } else {
            // ^ Opening a new widget or switching from one widget to another.

            if (currentActive === "hidden" || !masterWindow.isVisible) {
                // ^ If no widget is currently open (starting from hidden state).

                masterWindow.morphDuration = 250; 
                // ^ Uses the standard 250ms for opening animations.

                masterWindow.exitDuration = 250;
                // ^ Standard exit duration.

                masterWindow.disableMorph = false;
                // ^ Enables morphing for the open animation.

                let t = getLayout(newWidget);
                // ^ Gets the layout for the new widget.

                masterWindow.animX = t.rx;
                // ^ Sets the target X position from the layout.

                masterWindow.animY = t.ry;
                // ^ Sets the target Y position.

                masterWindow.animW = t.w;
                // ^ Sets the target width.

                masterWindow.animH = t.h;
                // ^ Sets the target height.

                masterWindow.targetW = t.w;
                // ^ Records the target width.

                masterWindow.targetH = t.h;
                // ^ Records the target height.
            } else {
                // ^ If switching from one widget to another (both visible).

                masterWindow.morphDuration = 300; 
                // ^ Uses a longer morph duration (300ms) for smoother cross-widget transitions.

                masterWindow.disableMorph = false;
                // ^ Enables morphing.

                masterWindow.exitDuration = (newWidget === "wallpaper") ? 125 : 300;
                // ^ Custom exit duration: wallpaper transitions are faster (125ms) for a snappier feel, others use the standard 300ms.
            }
    
            prepTimer.newWidget = newWidget;
            // ^ Stores the target widget for the preparation timer.

            prepTimer.newArg = arg;
            // ^ Stores the widget argument.

            prepTimer.start();
            // ^ Starts the preparation timer (15ms delay) before executing the switch.
        }
    }

    Timer {
        // ^ A brief delay timer that decouples the switch command from the actual execution, allowing property bindings to settle before the transition begins.

        id: prepTimer
        // ^ Assigns the identifier.

        interval: 15 
        // ^ A very short 15ms delay—long enough for QML property bindings to update, but short enough to feel instantaneous to the user.

        property string newWidget: ""
        // ^ Stores the target widget name for the switch.

        property string newArg: ""
        // ^ Stores the widget argument.

        onTriggered: executeSwitch(newWidget, newArg, false)
        // ^ When the timer fires, calls executeSwitch with the stored values. The `false` parameter means this is not an immediate switch (animated).
    }

    function executeSwitch(newWidget, arg, immediate) {
        // ^ Performs the actual widget switch, updating properties and replacing the stack view content.

        masterWindow.currentActive = newWidget;
        // ^ Updates the currently active widget name, which triggers onCurrentActiveChanged.

        masterWindow.activeArg = arg;
        // ^ Stores the widget argument for reference.

        let t = getLayout(newWidget);
        // ^ Gets the layout definition for the new widget.

        masterWindow.animX = t.rx;
        // ^ Sets the animated X position.

        masterWindow.animY = t.ry;
        // ^ Sets the animated Y position.

        masterWindow.animW = t.w;
        // ^ Sets the animated width.

        masterWindow.animH = t.h;
        // ^ Sets the animated height.

        masterWindow.targetW = t.w;
        // ^ Records the target width.

        masterWindow.targetH = t.h;
        // ^ Records the target height.

        let props = newWidget === "wallpaper" ? { "widgetArg": arg } : {};
        // ^ Creates an initial properties object. If opening the wallpaper widget, passes the argument as "widgetArg" (used to highlight the current wallpaper thumbnail).

        props["notifModel"] = masterWindow.notifModel;
        // ^ Always passes the notification history model to every widget, ensuring they can access notifications.

        props["layoutWidth"] = t.w;
        // ^ Passes the layout width to the widget so it knows its allocated space.

        props["layoutHeight"] = t.h;
        // ^ Passes the layout height to the widget.

        if (immediate) {
            // ^ If an immediate switch was requested (no animation).

            widgetStack.replace(t.comp, props, StackView.Immediate);
            // ^ Replaces the current stack item with the new widget component instantly, without transition animations.
        } else {
            widgetStack.replace(t.comp, props);
            // ^ Replaces with the standard animated transition (the replaceEnter/replaceExit transitions defined above).
        }
        
        // Ensure Main.qml respects the dynamic size of the newly loaded widget immediately
        let currentItem = widgetStack.currentItem;
        // ^ Gets a reference to the newly loaded widget item.

        if (currentItem) {
            // ^ If the widget loaded successfully.

            if (currentItem.targetMasterWidth !== undefined) {
                // ^ If the widget has a custom target width property.

                let dynW = currentItem.targetMasterWidth;
                // ^ Gets the dynamic width.

                masterWindow.animW = dynW;
                // ^ Updates the animated width immediately (bypassing layout default).

                masterWindow.targetW = dynW;
                // ^ Updates the target width.

                masterWindow.animX = Math.floor((masterWindow.width / 2) - (dynW / 2));
                // ^ Re-centers the container horizontally based on the new width.
            }

            if (currentItem.targetMasterHeight !== undefined) {
                // ^ If the widget has a custom target height.

                masterWindow.animH = currentItem.targetMasterHeight;
                // ^ Updates the animated height.

                masterWindow.targetH = currentItem.targetMasterHeight;
                // ^ Updates the target height.
            }
        }
        
        masterWindow.isVisible = true;
        // ^ Sets visibility to true, making the overlay and the new widget visible with animation.
    }

    // =========================================================
    // --- IPC: EVENT-DRIVEN WATCHER
    // =========================================================
    Process {
        // ^ A Process that continuously monitors the IPC file for commands from external scripts.

        id: ipcWatcher
        // ^ Assigns the identifier.

        command: ["bash", "-c",
            "touch /tmp/qs_widget_state; " +
            "inotifywait -qq -e close_write /tmp/qs_widget_state 2>/dev/null; " +
            "cat /tmp/qs_widget_state"
        ]
        // ^ A bash command that: (1) ensures the IPC file exists with `touch`, (2) uses inotifywait to block until the file is written to (closed after writing), (3) reads and outputs the file contents.

        running: true
        // ^ Starts immediately and runs continuously.

        stdout: StdioCollector {
            // ^ Captures each command from the IPC file.

            onStreamFinished: {
                // ^ Called when a command is received.

                let rawCmd = this.text.trim();
                // ^ Gets the command text and trims whitespace.

                if (rawCmd !== "") {
                    // ^ Only processes non-empty commands.

                    let parts = rawCmd.split(":");
                    // ^ Splits the command by colon. Format: "action:target:subtarget" or just "action".

                    let cmd = parts[0];
                    // ^ Extracts the first part as the command/action.

                    // Determine if the widget is currently in its closing animation
                    let isClosing = (masterWindow.currentActive !== "hidden" && !masterWindow.isVisible);
                    // ^ Detects if a widget is in the process of closing: currentActive is not "hidden" but isVisible is false (fading out).

                    let effectivelyActive = isClosing ? "hidden" : masterWindow.currentActive;
                    // ^ If closing, treats the state as if already hidden. This prevents toggling a widget that's already animating away.

                    if (cmd === "close") {
                        // ^ If the command is "close".

                        switchWidget("hidden", "");
                        // ^ Hides any open widget.

                    } else if (cmd === "toggle" || cmd === "open") {
                        // ^ If the command is "toggle" or "open".

                        let targetWidget = parts.length > 1 ? parts[1] : "";
                        // ^ Extracts the target widget name from the second part, or empty string.

                        let arg = parts.length > 2 ? parts.slice(2).join(":") : "";
                        // ^ Extracts any additional arguments (rejoining with colons in case the argument contained colons).

                        delayedClear.stop();
                        // ^ Cancels any pending delayed clear.
                        
                        // Use effectivelyActive so a closing widget isn't accidentally toggled off again
                        if (targetWidget === effectivelyActive) {
                            // ^ If the target widget is the same as the currently active (or effectively hidden) widget.

                            let currentItem = widgetStack.currentItem;
                            // ^ Gets the current widget item.

                            if (arg !== "" && currentItem && currentItem.activeMode !== undefined && currentItem.activeMode !== arg) {
                                // ^ If an argument is provided AND the current widget has an activeMode property AND it's different from the argument.

                                currentItem.activeMode = arg;
                                // ^ Updates the widget's mode to the new argument (e.g., switching from "wifi" to "bluetooth" tab within the network widget).
                            } 
                            else if (cmd === "toggle") {
                                // ^ If it's a toggle command and the same widget is active.

                                switchWidget("hidden", "");
                                // ^ Toggle off: close the widget.
                            }
                            
                        } else if (getLayout(targetWidget)) {
                            // ^ If the target widget is different AND it's a valid widget name.

                            switchWidget(targetWidget, arg);
                            // ^ Open the new widget with the argument.
                        }

                    } else if (getLayout(cmd)) { 
                        // ^ If the command itself is a valid widget name (e.g., "calendar").

                        let arg = parts.length > 1 ? parts.slice(1).join(":") : "";
                        // ^ Extracts arguments after the widget name.

                        delayedClear.stop();
                        // ^ Cancels delayed clear.

                        if (cmd === effectivelyActive) {
                            // ^ If this widget is already active.

                            let currentItem = widgetStack.currentItem;
                            // ^ Gets the current widget.

                            if (arg !== "" && currentItem && currentItem.activeMode !== undefined && currentItem.activeMode !== arg) {
                                // ^ If the mode is being changed.

                                currentItem.activeMode = arg;
                                // ^ Updates the mode.
                            } else {
                                switchWidget("hidden", "");
                                // ^ Otherwise, toggle off (close) the widget.
                            }
                        } else {
                            switchWidget(cmd, arg);
                            // ^ Open the new widget.
                        }
                    }
                }

                ipcWatcher.running = false;
                // ^ Stops the IPC watcher process.

                ipcWatcher.running = true;
                // ^ Restarts the watcher to wait for the next IPC command. This restart pattern ensures clean process state.
            }
        }
    }   

    Timer {
        // ^ A timer that delays the final cleanup after a widget is closed, ensuring animations complete before the stack is cleared.

        id: delayedClear
        // ^ Assigns the identifier.

        interval: masterWindow.morphDuration 
        // ^ Waits for the full morphing duration (170ms for close) to ensure animations finish.

        onTriggered: {
            // ^ Called when the timer fires.

            masterWindow.currentActive = "hidden";
            // ^ Officially sets the current widget to "hidden".

            widgetStack.clear();
            // ^ Clears all items from the stack, freeing memory and ensuring a clean state for the next widget.

            masterWindow.disableMorph = false;
            // ^ Re-enables morphing for future transitions.
        }
    }
}