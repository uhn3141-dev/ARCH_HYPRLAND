// import QtQuick
// import QtQuick.Window
// import QtQuick.Controls
// import QtQuick.Layouts
// import Quickshell
// import Quickshell.Wayland
// import Quickshell.Io 
// import "../" 
// import "../WindowRegistry.js" as Registry

// PanelWindow {
//     id: popupWindow

//     // These properties are passed from Main.qml
//     property var popupModel
//     property real uiScale: 1.0

//     // Fetch the registry properties dynamically based on the current screen width and uiScale
//     property var layoutConfig: Registry.getPopupLayout(Screen.width, popupWindow.uiScale)

//     WlrLayershell.namespace: "qs-popups"
//     WlrLayershell.layer: WlrLayer.Overlay
    
//     anchors {
//         top: true
//         right: true
//     }
    
//     margins {
//         top: popupWindow.layoutConfig.marginTop
//         right: popupWindow.layoutConfig.marginRight
//     }

//     exclusionMode: ExclusionMode.Ignore
//     focusable: false 
//     color: "transparent"

//     width: popupWindow.layoutConfig.w
//     height: Math.min(popupList.contentHeight, Screen.height * 0.8)

//     // Smoothly adjust window height so it doesn't instantly snap when popups are added/removed
//     Behavior on height {
//         NumberAnimation { duration: 400; easing.type: Easing.OutQuint }
//     }

//     property bool dndEnabled: false

//     // --- DND Polling Mechanism ---
//     Process {
//         id: dndPoller
//         command: ["bash", "-c", "cat ~/.cache/qs_dnd 2>/dev/null || echo '0'"]
//         stdout: StdioCollector {
//             onStreamFinished: popupWindow.dndEnabled = (this.text.trim() === "1")
//         }
//     }
//     Timer {
//         interval: 1000; running: true; repeat: true; triggeredOnStart: true
//         onTriggered: dndPoller.running = true
//     }

//     // --- WRAPPER ITEM FOR OPACITY FIX ---
//     // Instead of fading the window, we fade the contents inside it.
//     Item {
//         id: contentWrapper
//         anchors.fill: parent
        
//         opacity: popupWindow.dndEnabled ? 0.0 : 1.0
//         visible: opacity > 0.01 // Only hide completely when the fade out is basically done
//         Behavior on opacity { NumberAnimation { duration: 300 } }

//         MatugenColors { id: _theme }

//         property var blobPalette1: [_theme.mauve, _theme.blue, _theme.peach, _theme.green, _theme.pink]
//         property var blobPalette2: [_theme.sapphire, _theme.teal, _theme.maroon, _theme.yellow, _theme.red]

//         property real globalOrbitAngle: 0
//         NumberAnimation on globalOrbitAngle {
//             from: 0; to: Math.PI * 2; duration: 25000; loops: Animation.Infinite; running: true
//         }

//         ListView {
//             id: popupList
//             anchors.fill: parent
//             model: popupWindow.popupModel
//             spacing: popupWindow.layoutConfig.spacing
//             interactive: false 
//             clip: false 

//             add: Transition {
//                 ParallelAnimation {
//                     NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 400; easing.type: Easing.OutQuint }
//                     NumberAnimation { property: "x"; from: popupWindow.width * 0.4; to: 0; duration: 500; easing.type: Easing.OutQuint }
//                     NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 500; easing.type: Easing.OutQuint }
//                 }
//             }
            
//             remove: Transition {
//                 ParallelAnimation {
//                     NumberAnimation { property: "opacity"; to: 0.0; duration: 350; easing.type: Easing.OutQuint }
//                     NumberAnimation { property: "x"; to: popupWindow.width * 0.4; duration: 400; easing.type: Easing.OutQuint }
//                     NumberAnimation { property: "scale"; to: 0.9; duration: 400; easing.type: Easing.OutQuint }
//                 }
//             }

//             displaced: Transition {
//                 NumberAnimation { properties: "x,y"; duration: 450; easing.type: Easing.OutQuint }
//             }

//             delegate: Item {
//                 id: delegateRoot
//                 width: ListView.view.width
//                 height: contentCol.height + (popupWindow.layoutConfig.padding * 2)

//                 property string fullSummary: model.summary || ""
//                 property string fullBody: model.body || ""
//                 property int typeLenSum: 0
//                 property int typeLenBody: 0

//                 ParallelAnimation {
//                     running: true
//                     NumberAnimation { 
//                         target: delegateRoot; property: "typeLenSum"; 
//                         from: 0; to: fullSummary.length; 
//                         duration: Math.min(fullSummary.length * 20, 600); 
//                         easing.type: Easing.OutCubic 
//                     }
//                     SequentialAnimation {
//                         PauseAnimation { duration: 150 }
//                         NumberAnimation { 
//                             target: delegateRoot; property: "typeLenBody"; 
//                             from: 0; to: fullBody.length; 
//                             duration: Math.min(fullBody.length * 15, 1200); 
//                             easing.type: Easing.OutCubic 
//                         }
//                     }
//                 }

//                 Rectangle {
//                     id: popupCard
//                     anchors.fill: parent
//                     radius: popupWindow.layoutConfig.radius
                    
//                     color: _theme.base
//                     border.color: _theme.surface1
//                     border.width: 1
//                     clip: true 
                    
//                     property color blob1Color: contentWrapper.blobPalette1[index % 5]
//                     property color blob2Color: contentWrapper.blobPalette2[index % 5]

//                     Rectangle {
//                         width: parent.width * 0.7; height: width; radius: width / 2
//                         x: (parent.width / 2 - width / 2) + Math.cos(contentWrapper.globalOrbitAngle * 2 + index) * 60
//                         y: (parent.height / 2 - height / 2) + Math.sin(contentWrapper.globalOrbitAngle * 2 + index) * 30
//                         color: popupCard.blob1Color
//                         opacity: 0.12
//                     }
                    
//                     Rectangle {
//                         width: parent.width * 0.5; height: width; radius: width / 2
//                         x: (parent.width / 2 - width / 2) + Math.sin(contentWrapper.globalOrbitAngle * 1.5 - index) * -50
//                         y: (parent.height / 2 - height / 2) + Math.cos(contentWrapper.globalOrbitAngle * 1.5 - index) * -40
//                         color: popupCard.blob2Color
//                         opacity: 0.10
//                     }

//                     Timer {
//                         interval: 5000
//                         running: true
//                         onTriggered: masterWindow.removePopup(model.uid)
//                     }

//                     MouseArea {
//                         anchors.fill: parent
//                         hoverEnabled: true
//                         cursorShape: Qt.PointingHandCursor
                        
//                         onClicked: {
//                             // 1. Intercept custom scripts and open the FOLDER natively in QML
//                             if ((model.appName === "Screenshot" || model.appName === "Screen Recorder") && model.iconPath !== "") {
//                                 // Extract the folder path by cutting off everything after the last '/'
//                                 let folderPath = model.iconPath.substring(0, model.iconPath.lastIndexOf('/'))
//                                 Quickshell.execDetached(["xdg-open", folderPath])
//                             } 
//                             // 2. Standard Freedesktop action for regular apps
//                             else {
//                                 if (model.notif && typeof model.notif.invokeAction === "function") {
//                                     model.notif.invokeAction("default")
//                                 }
//                             }

//                             // 3. Clean up and close
//                             if (model.notif && typeof model.notif.close === "function") {
//                                 model.notif.close()
//                             }
//                             masterWindow.removePopup(model.uid)
//                         }
                        
//                         Rectangle {
//                             anchors.fill: parent
//                             radius: parent.radius
//                             color: _theme.surface0
//                             opacity: parent.containsMouse ? 0.3 : 0.0
//                             Behavior on opacity { NumberAnimation { duration: 250 } }
//                         }
//                     }
//                     ColumnLayout {
//                         id: contentCol
//                         anchors.left: parent.left
//                         anchors.right: parent.right
//                         anchors.top: parent.top
//                         anchors.margins: popupWindow.layoutConfig.padding
//                         spacing: 6 * popupWindow.uiScale

//                         Text {
//                             text: model.appName || "System"
//                             font.family: "JetBrains Mono"
//                             font.weight: Font.Medium
//                             font.pixelSize: 12 * popupWindow.uiScale
//                             color: _theme.overlay1
//                             Layout.fillWidth: true
//                         }

//                         Item {
//                             Layout.fillWidth: true
//                             Layout.preferredHeight: hiddenSummary.implicitHeight

//                             Text {
//                                 id: hiddenSummary
//                                 text: delegateRoot.fullSummary
//                                 width: parent.width
//                                 font.family: "JetBrains Mono"
//                                 font.weight: Font.Bold
//                                 font.pixelSize: 15 * popupWindow.uiScale
//                                 wrapMode: Text.Wrap
//                                 visible: false
//                             }

//                             Text {
//                                 anchors.fill: parent
//                                 text: delegateRoot.fullSummary.substring(0, delegateRoot.typeLenSum)
//                                 font: hiddenSummary.font
//                                 color: _theme.text
//                                 wrapMode: Text.Wrap
//                             }
//                         }

//                         Item {
//                             Layout.fillWidth: true
//                             Layout.preferredHeight: hiddenBody.implicitHeight
//                             visible: delegateRoot.fullBody !== ""

//                             Text {
//                                 id: hiddenBody
//                                 text: delegateRoot.fullBody
//                                 width: parent.width
//                                 font.family: "JetBrains Mono"
//                                 font.weight: Font.Medium
//                                 font.pixelSize: 13 * popupWindow.uiScale
//                                 wrapMode: Text.Wrap
//                                 textFormat: Text.PlainText
//                                 visible: false
//                             }

//                             Text {
//                                 anchors.fill: parent
//                                 text: delegateRoot.fullBody.substring(0, delegateRoot.typeLenBody)
//                                 font: hiddenBody.font
//                                 color: _theme.subtext0 
//                                 wrapMode: Text.Wrap
//                                 textFormat: Text.PlainText
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }

// =============================================================================
// NOTIFICATION POPUPS - Quickshell Panel Window for Desktop Notifications
// =============================================================================
// Architecture Overview:
// This is a dedicated panel window that displays Freedesktop.org-compliant
// desktop notifications. It's designed as an overlay layer that appears
// in the top-right corner of the screen. The architecture follows:
//
// 1. PanelWindow (Quickshell's Wayland panel primitive) creates a dedicated
//    surface on the compositor's overlay layer
// 2. A ListView with animated add/remove transitions displays notifications
// 3. Each notification has a typewriter text reveal animation
// 4. Notifications auto-dismiss after 5 seconds
// 5. DND (Do Not Disturb) mode hides all popups via a polling mechanism
//
// KEY ARCHITECTURAL DECISIONS:
// - Opacity fix: Instead of fading the PanelWindow itself (which can cause
//   compositor issues with Wayland layer surfaces), we fade an internal
//   wrapper Item. This prevents the window from becoming unmapped during
//   the fade animation.
// - Typewriter effect: Using substring(0, typeLenSum) with animated
//   typeLenSum/bod properties creates a character-by-character reveal.
//   Hidden Text elements measure the full text height for layout, while
//   visible Text elements show only the revealed portion.
// - Blob animations: Each notification card has two decorative gradient
//   circles that slowly orbit, creating visual interest without being
//   distracting. Colors cycle through the theme palette based on index.
// - Layout from registry: PopupLayout configuration (margins, spacing,
//   padding, radius) is fetched dynamically from WindowRegistry.js based
//   on screen width and UI scale, allowing responsive layouts.

// -----------------------------------------------------------------------------
// MODULE IMPORTS
// -----------------------------------------------------------------------------

// QtQuick: Core QML types - Item, Rectangle, Text, animations, transitions
import QtQuick

// QtQuick.Window: Screen.width/height for responsive layout calculations
import QtQuick.Window

// QtQuick.Controls: (imported but not directly used in visible code;
// may be needed for internal ListView functionality)
import QtQuick.Controls

// QtQuick.Layouts: ColumnLayout for flexible notification content layout
import QtQuick.Layouts

// Quickshell: Shell framework integration, provides PanelWindow type
import Quickshell

// Quickshell.Wayland: Wayland-specific types
// WlrLayershell - attaches this window to wlroots layer shell protocol
// WlrLayer - enum for layer selection (Background, Bottom, Top, Overlay)
// ExclusionMode - controls how the compositor excludes space for this surface
import Quickshell.Wayland

// Quickshell.Io: Process (run external commands), StdioCollector (capture output)
import Quickshell.Io

// Import parent directory for shared components (MatugenColors, etc.)
import "../"

// Import JavaScript file for layout calculations and window registry
// Registry.getPopupLayout() returns margin/spacing/padding/radius config
// based on screen dimensions and UI scale factor
import "../WindowRegistry.js" as Registry

// =============================================================================
// PANEL WINDOW - The Wayland surface that hosts all notification popups
// =============================================================================
// PanelWindow is Quickshell's wrapper around wlr_layer_shell.
// It creates a dedicated Wayland surface positioned by the compositor
// according to layer shell protocol requests.
PanelWindow {
    id: popupWindow  // Root identifier, referenced throughout

    // =========================================================================
    // EXTERNAL PROPERTIES - Injected by Main.qml when creating this window
    // =========================================================================

    // popupModel: A ListModel (or similar) containing notification data
    // Each entry has: uid, appName, summary, body, iconPath, notif object
    // This is the data source for the ListView
    property var popupModel

    // uiScale: Global UI scale factor from the main configuration
    // Multiplied into all pixel sizes for consistent scaling
    // Default 1.0 means no scaling
    property real uiScale: 1.0

    // =========================================================================
    // LAYOUT CONFIGURATION - Fetched from WindowRegistry.js
    // =========================================================================
    // Registry.getPopupLayout() takes screen width and UI scale as parameters
    // and returns an object with:
    //   - w: window width
    //   - marginTop: distance from screen top edge
    //   - marginRight: distance from screen right edge
    //   - spacing: vertical gap between notification cards
    //   - padding: internal padding within each notification card
    //   - radius: corner radius for notification cards
    //
    // This is evaluated ONCE at creation time, not reactively.
    // The Screen.width value is captured at component creation.
    property var layoutConfig: Registry.getPopupLayout(
        Screen.width,           // Current screen width in pixels
        popupWindow.uiScale     // UI scale factor
    )

    // =========================================================================
    // WAYLAND LAYER SHELL CONFIGURATION
    // =========================================================================

    // namespace: Identifies this layer surface to the compositor
    // Multiple windows with the same namespace can be managed together
    WlrLayershell.namespace: "qs-popups"

    // layer: WlrLayer.Overlay places this above all normal windows
    // including fullscreen apps, but below screen lockers
    // WlrLayer enum values: Background, Bottom, Top, Overlay
    WlrLayershell.layer: WlrLayer.Overlay

    // anchors: Which screen edges to anchor to
    // top: true - anchored to top edge of screen
    // right: true - anchored to right edge of screen
    // This positions the window in the top-right corner
    anchors {
        top: true
        right: true
    }

    // margins: Distance from the anchored edges
    // Uses the layoutConfig values for responsive spacing
    // These prevent the popups from touching the screen bezel
    margins {
        top: popupWindow.layoutConfig.marginTop      // e.g., 10-20px from top
        right: popupWindow.layoutConfig.marginRight   // e.g., 10-20px from right
    }

    // =========================================================================
    // EXCLUSION MODE - How the compositor reserves space
    // =========================================================================
    // ExclusionMode.Ignore: The compositor does NOT reserve space for this
    // surface. Other windows can overlap it freely. This is correct for
    // notification overlays - they float above everything without pushing
    // other windows around.
    exclusionMode: ExclusionMode.Ignore

    // focusable: false - Notifications should not steal keyboard focus
    // from whatever the user is doing. They're passive informational overlays.
    focusable: false

    // color: "transparent" - The window itself has no background
    // All visual styling is done by the internal Rectangle elements
    color: "transparent"

    // =========================================================================
    // WINDOW DIMENSIONS
    // =========================================================================
    // Width: Fixed from layout config (typically 350-450px depending on screen)
    width: popupWindow.layoutConfig.w

    // Height: Dynamic, based on the total height of all notification cards
    // but capped at 80% of screen height to prevent overflow on small screens
    // popupList.contentHeight is the total height of all delegates + spacing
    // Math.min ensures we never exceed 80% of the display
    height: Math.min(popupList.contentHeight, Screen.height * 0.8)

    // =========================================================================
    // HEIGHT ANIMATION - Smooth expansion/contraction
    // =========================================================================
    // Without this Behavior, the window height would instantly snap when
    // notifications are added or removed. The 400ms OutQuint animation
    // creates a smooth, organic resize that's fast enough to not feel
    // sluggish but slow enough to be perceived as intentional motion.
    //
    // OutQuint easing: Very fast initial movement that quickly decelerates.
    // Formula: t^5, so at 50% time, only ~3% of the distance remains.
    // This makes the window feel responsive (moves fast initially) while
    // giving a soft landing.
    Behavior on height {
        NumberAnimation {
            duration: 400                // 0.4 seconds
            easing.type: Easing.OutQuint // Quintic deceleration
        }
    }

    // =========================================================================
    // DO NOT DISTURB - Global notification suppression
    // =========================================================================
    // dndEnabled controls whether notifications are visible.
    // When true, the contentWrapper fades to opacity 0, effectively hiding
    // all notifications while they still technically exist in the list.
    property bool dndEnabled: false

    // =========================================================================
    // DND POLLING MECHANISM - File-based state detection
    // =========================================================================
    // Reads a simple flag file at ~/.cache/qs_dnd
    // The file contains "1" (DND enabled) or "0" (DND disabled)
    // This allows external scripts or keybindings to toggle DND
    // by writing to this file, and the popup window picks it up.

    // Process: Runs a bash one-liner to read the DND flag file
    // "cat ~/.cache/qs_dnd 2>/dev/null || echo '0'" means:
    // - Try to read the file
    // - If it doesn't exist (error), output "0" instead
    // This gracefully handles the file not existing yet
    Process {
        id: dndPoller
        command: ["bash", "-c",
            "cat ~/.cache/qs_dnd 2>/dev/null || echo '0'"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Trim whitespace, compare to "1" to set the flag
                popupWindow.dndEnabled = (this.text.trim() === "1")
            }
        }
    }

    // Timer: Polls the DND file every 1 second
    // interval: 1000ms = 1 second polling
    // running: true - starts immediately
    // repeat: true - keeps polling
    // triggeredOnStart: true - fires immediately on startup, not after 1s delay
    // This ensures DND state is detected on first load without waiting
    Timer {
        interval: 1000         // Check every second
        running: true          // Start the timer
        repeat: true           // Loop forever
        triggeredOnStart: true // Also fire at time 0
        onTriggered: dndPoller.running = true  // Trigger the poll
    }

    // =========================================================================
    // CONTENT WRAPPER - Opacity fade container (the "Opacity Fix")
    // =========================================================================
    // EXPLANATION OF THE OPACITY FIX:
    // Wayland layer shell surfaces have specific behavior when their opacity
    // reaches 0. The compositor may unmap (hide) the surface entirely,
    // which can cause visual glitches or cause the compositor to rearrange
    // other layer surfaces. By keeping the PanelWindow always at full opacity
    // and instead fading an internal wrapper Item, we maintain the layer
    // surface's presence on screen while achieving a visual fade-out.
    //
    // This is a common pattern in Wayland shell development:
    // The shell surface is a "container" that always exists; internal
    // content fades in/out without affecting the compositor's layout.
    Item {
        id: contentWrapper
        anchors.fill: parent  // Fill the entire panel window

        // Opacity controlled by DND state:
        // DND on  -> 0.0 (fully transparent, notifications hidden)
        // DND off -> 1.0 (fully opaque, notifications visible)
        opacity: popupWindow.dndEnabled ? 0.0 : 1.0

        // Optimization: When opacity is effectively 0, set visible to false
        // This prevents the QML renderer from processing this entire subtree
        // opacity > 0.01 means "visible until the fade is essentially complete"
        // The 0.01 threshold prevents a single-frame flash at the end of fade
        visible: opacity > 0.01

        // Smooth 300ms fade transition for DND toggle
        // 300ms is fast enough to feel instant but slow enough to be visible
        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }

        // =====================================================================
        // THEME COLORS - Per-instance MatugenColors
        // =====================================================================
        // Each instance of this component gets its own MatugenColors.
        // This ensures color consistency within this window even if the
        // system theme changes. The colors are loaded once at creation.
        MatugenColors { id: _theme }

        // =====================================================================
        // BLOB COLOR PALETTES - Cycling decorative colors
        // =====================================================================
        // Two arrays of 5 colors each, cycling through different theme accents.
        // Each notification card gets blob1Color and blob2Color from these
        // arrays, indexed by [index % 5]. This means the 1st and 6th
        // notification share the same blob colors, creating a repeating
        // pattern. The two arrays are offset from each other so blob1
        // and blob2 on the same card are always different colors.
        //
        // Palette 1: mauve, blue, peach, green, pink
        // Palette 2: sapphire, teal, maroon, yellow, red
        // Each card gets one color from each palette, creating color harmony
        property var blobPalette1: [
            _theme.mauve, _theme.blue, _theme.peach,
            _theme.green, _theme.pink
        ]
        property var blobPalette2: [
            _theme.sapphire, _theme.teal, _theme.maroon,
            _theme.yellow, _theme.red
        ]

        // =====================================================================
        // GLOBAL ORBIT ANGLE - Continuous rotation for blob animation
        // =====================================================================
        // Drives the slow orbital motion of decorative blobs inside each
        // notification card. Rotates a full 2π (360°) over 25 seconds.
        // 25 seconds per full rotation = very slow, subtle motion that
        // doesn't distract but adds "liveness" to the UI.
        property real globalOrbitAngle: 0
        NumberAnimation on globalOrbitAngle {
            from: 0                    // Start at 0 radians
            to: Math.PI * 2            // End at 2π (full circle)
            duration: 25000            // 25 seconds per rotation
            loops: Animation.Infinite  // Never stop
            running: true              // Start immediately
        }

        // =====================================================================
        // LIST VIEW - Scrollable list of notification cards
        // =====================================================================
        // ListView is a highly optimized QML type for displaying lists.
        // It only instantiates delegates that are visible (or near-visible),
        // making it efficient for potentially large numbers of notifications.
        ListView {
            id: popupList
            anchors.fill: parent               // Fill the content wrapper
            model: popupWindow.popupModel       // Data source from Main.qml
            spacing: popupWindow.layoutConfig.spacing  // Gap between cards
            interactive: false                 // Disable user scrolling
            // Notifications stack from top; user shouldn't scroll them
            clip: false                        // Don't clip to bounds
            // Allows the add/remove animations to extend beyond the list bounds
            // without being cut off (e.g., sliding in from the right)

            // =================================================================
            // ADD TRANSITION - Animation when a notification appears
            // =================================================================
            // ParallelAnimation runs multiple animations simultaneously.
            // The new delegate:
            // 1. Fades in from transparent to opaque (0 → 1)
            // 2. Slides in from the right (40% of window width offset → 0)
            // 3. Scales up slightly (0.9 → 1.0) for a "pop-in" effect
            //
            // Combined, these create a polished "slide-in from right with
            // subtle scale-up" entrance animation that draws attention
            // without being aggressive.
            add: Transition {
                ParallelAnimation {
                    // Opacity fade-in: 400ms, OutQuint easing
                    // OutQuint means it reaches near-full opacity very quickly
                    // and then slowly settles to exactly 1.0
                    NumberAnimation {
                        property: "opacity"
                        from: 0.0
                        to: 1.0
                        duration: 400
                        easing.type: Easing.OutQuint
                    }
                    // Horizontal slide: starts 40% of window width to the right
                    // and slides left into position. 500ms, OutQuint easing.
                    // The longer duration on x compared to opacity creates
                    // a slight stagger effect (slide continues after fade-in)
                    NumberAnimation {
                        property: "x"
                        from: popupWindow.width * 0.4  // 40% from right
                        to: 0
                        duration: 500
                        easing.type: Easing.OutQuint
                    }
                    // Scale pop-in: starts at 90% size, grows to 100%
                    // 500ms to match the slide duration
                    // Together with the slide, this creates an "easing in"
                    // spatial effect like the card is swinging into place
                    NumberAnimation {
                        property: "scale"
                        from: 0.9
                        to: 1.0
                        duration: 500
                        easing.type: Easing.OutQuint
                    }
                }
            }

            // =================================================================
            // REMOVE TRANSITION - Animation when a notification is dismissed
            // =================================================================
            // Mirror of the add transition but reversed:
            // - Fade out (350ms)
            // - Slide out to the right (400ms)
            // - Scale down (400ms)
            //
            // Slightly faster durations than add (350/400 vs 400/500)
            // because removal should feel quicker - the user is done with it.
            remove: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "opacity"
                        to: 0.0          // Fade to invisible
                        duration: 350
                        easing.type: Easing.OutQuint
                    }
                    NumberAnimation {
                        property: "x"
                        to: popupWindow.width * 0.4  // Slide right
                        duration: 400
                        easing.type: Easing.OutQuint
                    }
                    NumberAnimation {
                        property: "scale"
                        to: 0.9           // Shrink slightly
                        duration: 400
                        easing.type: Easing.OutQuint
                    }
                }
            }

            // =================================================================
            // DISPLACED TRANSITION - Animation for items that shift position
            // =================================================================
            // When a notification above is removed, the ones below slide up
            // to fill the gap. This animation smooths that vertical movement.
            // "properties: 'x,y'" means it animates both horizontal and
            // vertical position changes. 450ms OutQuint for smooth shuffling.
            displaced: Transition {
                NumberAnimation {
                    properties: "x,y"     // Animate both axes
                    duration: 450         // Slightly longer than remove
                    easing.type: Easing.OutQuint
                }
            }

            // =================================================================
            // DELEGATE - Individual notification card
            // =================================================================
            // Each notification in the model is rendered by this delegate.
            // It creates a card with:
            // - Decorative orbiting blobs (ambient animation)
            // - App name header
            // - Summary text with typewriter reveal animation
            // - Body text with delayed typewriter reveal animation
            // - 5-second auto-dismiss timer
            // - Click handling for notification actions
            delegate: Item {
                id: delegateRoot

                // Width: Full width of the ListView (the popup window width)
                width: ListView.view.width

                // Height: Dynamic, based on the content column height
                // plus top and bottom padding from layoutConfig
                // contentCol.height is calculated from the Text elements
                height: contentCol.height +
                    (popupWindow.layoutConfig.padding * 2)

                // =============================================================
                // TYPWRITER TEXT REVEAL - Character-by-character animation
                // =============================================================
                // The typewriter effect works by:
                // 1. Storing the full text in fullSummary and fullBody
                // 2. Having animated "typeLen" counters that increase over time
                // 3. Displaying substring(0, typeLen) of the full text
                // 4. Hidden Text elements measure the full text for layout
                //
                // This approach ensures the card height is correct from the
                // start (measured by hidden elements) while the visible text
                // gradually reveals character by character.

                // Full text content from the notification model
                property string fullSummary: model.summary || ""  // Title line
                property string fullBody: model.body || ""        // Detail text

                // Animated counters: how many characters to reveal
                // typeLenSum: summary character count (reveals first)
                // typeLenBody: body character count (reveals after delay)
                property int typeLenSum: 0
                property int typeLenBody: 0

                // =============================================================
                // TYPEWRITER ANIMATION - Parallel reveal with staggered start
                // =============================================================
                // Two animations running in parallel:
                // 1. Summary reveals immediately, character by character
                // 2. Body reveals after 150ms delay
                //
                // Duration calculations:
                // - Summary: fullSummary.length * 20ms per character,
                //   capped at 600ms maximum
                //   (30 chars at 20ms = 600ms, any longer stays at 600ms)
                // - Body: fullBody.length * 15ms per character,
                //   capped at 1200ms maximum
                //   (80 chars at 15ms = 1200ms)
                //
                // The body types slightly slower per character (15ms vs 20ms
                // for summary) because body text is usually longer and should
                // feel more substantial. OutCubic easing creates a natural
                // "speeding up then slowing down" rhythm.
                ParallelAnimation {
                    running: true  // Start immediately when delegate is created

                    // SUMMARY TYPEWRITER
                    NumberAnimation {
                        target: delegateRoot
                        property: "typeLenSum"  // Animate the counter
                        from: 0                  // Start with 0 characters
                        to: fullSummary.length    // End with all characters
                        duration: Math.min(
                            fullSummary.length * 20,  // 20ms per character
                            600                       // Maximum 600ms
                        )
                        easing.type: Easing.OutCubic
                        // OutCubic: accelerates quickly, then decelerates
                        // Creates the feeling of a fast typist
                    }

                    // BODY TYPEWRITER (delayed start)
                    SequentialAnimation {
                        // Wait 150ms before starting body text
                        // This creates a natural pause between title and body
                        // like a person reading the title before the details
                        PauseAnimation { duration: 150 }

                        NumberAnimation {
                            target: delegateRoot
                            property: "typeLenBody"
                            from: 0
                            to: fullBody.length
                            duration: Math.min(
                                fullBody.length * 15,  // 15ms per character
                                1200                    // Maximum 1200ms
                            )
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                // =============================================================
                // NOTIFICATION CARD - The visible card rectangle
                // =============================================================
                Rectangle {
                    id: popupCard
                    anchors.fill: parent
                    radius: popupWindow.layoutConfig.radius  // From registry

                    // Card background: base theme color (dark surface)
                    color: _theme.base

                    // Subtle border in surface1 color for definition
                    // Without this, the card blends into transparent background
                    border.color: _theme.surface1
                    border.width: 1

                    // clip: true - Essential for the decorative blobs
                    // Without clipping, the orbiting circles would extend
                    // beyond the card's rounded corners, breaking the design
                    clip: true

                    // =========================================================
                    // DECORATIVE BLOB COLORS
                    // =========================================================
                    // Each card gets two colors from the palettes.
                    // The index % 5 cycles through 5 colors, so cards
                    // repeat their color scheme every 5 notifications.
                    property color blob1Color: contentWrapper.blobPalette1[
                        index % 5
                    ]
                    property color blob2Color: contentWrapper.blobPalette2[
                        index % 5
                    ]

                    // =========================================================
                    // DECORATIVE BLOB 1 - Large orbiting circle
                    // =========================================================
                    // A semi-transparent colored circle that slowly orbits
                    // within the card. Parameters:
                    // - Width: 70% of card width (creates a large ambient shape)
                    // - X position: centered + cosine orbit at 60px amplitude
                    //   The "index" offset ensures each card's blob starts at
                    //   a different position, preventing synchronized motion
                    // - Y position: centered + sine orbit at 30px amplitude
                    // - Color from blobPalette1
                    // - Opacity 0.12 = very subtle, 12% visible
                    Rectangle {
                        width: parent.width * 0.7
                        height: width          // Square...
                        radius: width / 2       // ...made circular by radius
                        // X orbit: cos(orbitAngle * 2 + index) * 60px
                        // *2 makes this blob move faster than global rotation
                        // +index offsets each card's phase
                        x: (parent.width / 2 - width / 2) +
                            Math.cos(contentWrapper.globalOrbitAngle * 2 +
                                     index) * 60
                        // Y orbit: sin(orbitAngle * 2 + index) * 30px
                        // Smaller amplitude (30 vs 60) creates elliptical orbit
                        y: (parent.height / 2 - height / 2) +
                            Math.sin(contentWrapper.globalOrbitAngle * 2 +
                                     index) * 30
                        color: popupCard.blob1Color
                        opacity: 0.12  // Very subtle
                    }

                    // =========================================================
                    // DECORATIVE BLOB 2 - Smaller counter-orbiting circle
                    // =========================================================
                    // Similar to blob 1 but:
                    // - Smaller (50% vs 70% of card width)
                    // - Uses sin for X and cos for Y (90° phase shift)
                    // - Negative amplitudes (-50, -40) = orbits opposite direction
                    // - Different speed (*1.5 instead of *2)
                    // - Uses blobPalette2 for color variety
                    // - Slightly lower opacity (0.10 vs 0.12)
                    Rectangle {
                        width: parent.width * 0.5
                        height: width
                        radius: width / 2
                        // sin for X (instead of cos) = 90° phase shift
                        // -index reverses the phase offset direction
                        x: (parent.width / 2 - width / 2) +
                            Math.sin(contentWrapper.globalOrbitAngle * 1.5 -
                                     index) * -50
                        // cos for Y = phase shifted
                        y: (parent.height / 2 - height / 2) +
                            Math.cos(contentWrapper.globalOrbitAngle * 1.5 -
                                     index) * -40
                        color: popupCard.blob2Color
                        opacity: 0.10
                    }

                    // =========================================================
                    // AUTO-DISMISS TIMER - 5 second notification lifetime
                    // =========================================================
                    // Each notification auto-dismisses after 5 seconds.
                    // This follows the Freedesktop notification spec which
                    // recommends auto-expiration for non-critical notifications.
                    // The timer calls masterWindow.removePopup() which
                    // removes this notification from the model, triggering
                    // the remove transition animation.
                    Timer {
                        interval: 5000   // 5 seconds
                        running: true    // Start immediately when card appears
                        onTriggered: masterWindow.removePopup(model.uid)
                        // model.uid is the unique identifier for this notification
                    }

                    // =========================================================
                    // MOUSE AREA - Click handling for the entire card
                    // =========================================================
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true  // Enable hover state tracking
                        cursorShape: Qt.PointingHandCursor  // Hand cursor on hover

                        onClicked: {
                            // NOTIFICATION ACTION HANDLING
                            // Two types of actions are supported:
                            // 1. Screenshot/Screen Recorder apps: Open the
                            //    folder containing the captured file
                            // 2. Standard apps: Invoke the notification's
                            //    default action (usually opens the app)

                            // CASE 1: Screenshot or Screen Recorder
                            // When model.appName matches and iconPath exists,
                            // extract the folder path from the icon path.
                            // The icon path is assumed to be the actual
                            // screenshot/recording file, e.g.:
                            // /home/user/Pictures/Screenshots/shot_2024.png
                            // We want to open: /home/user/Pictures/Screenshots/
                            if ((model.appName === "Screenshot" ||
                                 model.appName === "Screen Recorder") &&
                                model.iconPath !== "") {
                                // Extract directory path:
                                // lastIndexOf('/') finds the last slash
                                // substring(0, lastSlashIndex) gives the
                                // directory without the filename
                                let folderPath = model.iconPath.substring(
                                    0,
                                    model.iconPath.lastIndexOf('/')
                                )
                                // Open the folder in the default file manager
                                Quickshell.execDetached(
                                    ["xdg-open", folderPath]
                                )
                            }
                            // CASE 2: Standard Freedesktop notification
                            // The model.notif object is a Notification instance
                            // with invokeAction() and close() methods per the
                            // Freedesktop notification spec
                            else {
                                if (model.notif &&
                                    typeof model.notif.invokeAction ===
                                    "function") {
                                    // "default" is the standard action name
                                    // for the primary notification action
                                    model.notif.invokeAction("default")
                                }
                            }

                            // CLEANUP: Close the notification properly
                            // This removes it from the notification daemon
                            if (model.notif &&
                                typeof model.notif.close === "function") {
                                model.notif.close()
                            }
                            // Remove from our popup model, triggering the
                            // remove transition animation
                            masterWindow.removePopup(model.uid)
                        }

                        // =====================================================
                        // HOVER HIGHLIGHT - Subtle surface overlay on hover
                        // =====================================================
                        // A semi-transparent rectangle that appears when the
                        // mouse hovers over the notification card.
                        // Opacity 0.3 = 30% of surface0 color overlaid.
                        // This provides visual feedback that the card is
                        // clickable without being too aggressive.
                        // 250ms fade for smooth transition.
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius  // Match card corners
                            color: _theme.surface0  // Light overlay color
                            opacity: parent.containsMouse ? 0.3 : 0.0
                            Behavior on opacity {
                                NumberAnimation { duration: 250 }
                            }
                        }
                    }

                    // =========================================================
                    // CONTENT COLUMN - App name, summary, and body text
                    // =========================================================
                    // ColumnLayout automatically sizes to fit its children.
                    // Its height determines the delegate's height through
                    // the delegateRoot.height binding.
                    ColumnLayout {
                        id: contentCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        // Margins from the layout config's padding value
                        anchors.margins: popupWindow.layoutConfig.padding
                        // Spacing between child items, scaled by uiScale
                        // 6 * uiScale ensures consistent spacing at any scale
                        spacing: 6 * popupWindow.uiScale

                        // =====================================================
                        // APP NAME - Small header showing the source app
                        // =====================================================
                        Text {
                            // model.appName comes from the notification data
                            // Fallback to "System" if not provided
                            text: model.appName || "System"
                            font.family: "JetBrains Mono"  // Monospace for clean look
                            font.weight: Font.Medium        // Medium weight (500)
                            font.pixelSize: 12 * popupWindow.uiScale  // Scaled
                            color: _theme.overlay1  // Subtle/muted color
                            Layout.fillWidth: true   // Take full width
                        }

                        // =====================================================
                        // SUMMARY TEXT - The notification title with typewriter
                        // =====================================================
                        // This uses a clever two-element technique:
                        // 1. hiddenSummary: invisible, measures full text height
                        //    for layout purposes. Its implicitHeight sets the
                        //    parent Item's preferredHeight.
                        // 2. Visible Text: shows only substring(0, typeLenSum)
                        //    characters. As typeLenSum animates from 0 to
                        //    full length, the text reveals character by character.
                        //
                        // The parent Item wraps both with Layout.preferredHeight
                        // bound to hiddenSummary.implicitHeight. This means
                        // the layout always reserves space for the full text,
                        // preventing the card from "growing" as characters appear.
                        Item {
                            Layout.fillWidth: true
                            // Reserve the full text height from the start
                            Layout.preferredHeight: hiddenSummary.implicitHeight

                            // Hidden measurement element
                            Text {
                                id: hiddenSummary
                                text: delegateRoot.fullSummary  // Full text
                                width: parent.width
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold  // Bold for titles
                                font.pixelSize: 15 * popupWindow.uiScale
                                wrapMode: Text.Wrap  // Multi-line support
                                visible: false  // Hidden, but still measures
                            }

                            // Visible typewriter text
                            Text {
                                anchors.fill: parent  // Same size as parent
                                // Show only revealed characters:
                                // substring(0, typeLenSum) extracts from
                                // start to the current animated count
                                text: delegateRoot.fullSummary.substring(
                                    0, delegateRoot.typeLenSum
                                )
                                font: hiddenSummary.font  // Same font properties
                                color: _theme.text  // Primary text color (bright)
                                wrapMode: Text.Wrap  // Multi-line support
                            }
                        }

                        // =====================================================
                        // BODY TEXT - Detail text with delayed typewriter
                        // =====================================================
                        // Same pattern as summary but:
                        // - Only visible when fullBody is not empty
                        // - Uses Medium weight instead of Bold (less emphasis)
                        // - Smaller font (13 vs 15 pixel size)
                        // - Subtext0 color (dimmer than primary text)
                        // - textFormat: Text.PlainText prevents any markdown/
                        //   HTML interpretation (security and consistency)
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: hiddenBody.implicitHeight
                            // Hide entirely if there's no body text
                            visible: delegateRoot.fullBody !== ""

                            // Hidden measurement element
                            Text {
                                id: hiddenBody
                                text: delegateRoot.fullBody
                                width: parent.width
                                font.family: "JetBrains Mono"
                                font.weight: Font.Medium
                                font.pixelSize: 13 * popupWindow.uiScale
                                wrapMode: Text.Wrap
                                textFormat: Text.PlainText  // No HTML parsing
                                visible: false
                            }

                            // Visible typewriter text
                            Text {
                                anchors.fill: parent
                                // Show only revealed body characters
                                text: delegateRoot.fullBody.substring(
                                    0, delegateRoot.typeLenBody
                                )
                                font: hiddenBody.font
                                color: _theme.subtext0  // Dimmer secondary text
                                wrapMode: Text.Wrap
                                textFormat: Text.PlainText
                            }
                        }
                    }
                }
            }
        }
    }
}