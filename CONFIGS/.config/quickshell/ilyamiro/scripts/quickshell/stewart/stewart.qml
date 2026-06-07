// import QtQuick
// import QtQuick.Effects
// import "../"

// Item {
//     id: root

//     MatugenColors { id: _theme }
    
//     // -------------------------------------------------------------------------
//     // COLORS (Dynamic Matugen Palette)
//     // -------------------------------------------------------------------------
//     readonly property color base: _theme.base
//     readonly property color mantle: _theme.mantle
//     readonly property color crust: _theme.crust
//     readonly property color text: _theme.text
//     readonly property color surface0: _theme.surface0
//     readonly property color surface1: _theme.surface1
//     readonly property color surface2: _theme.surface2
    
//     readonly property color mauve: _theme.mauve
//     readonly property color pink: _theme.pink
//     readonly property color blue: _theme.blue
//     readonly property color sapphire: _theme.sapphire

//     // Master Container
//     Rectangle {
//         id: windowContent
//         anchors.fill: parent
//         radius: 12
//         color: root.base 
//         clip: true

//         // ---------------------------------------------------------------------
//         // GLOBAL THEME & STATE CONTROLS
//         // ---------------------------------------------------------------------
        
//         // 5. Slow Color Temperature Drift (Fixed for Live Theme Reloading)
//         property real baseBlend: 0.0
//         SequentialAnimation on baseBlend {
//             loops: Animation.Infinite; running: true
//             NumberAnimation { to: 1.0; duration: 15000; easing.type: Easing.InOutSine }
//             NumberAnimation { to: 0.0; duration: 15000; easing.type: Easing.InOutSine }
//         }
//         // Dynamically tints between mauve and pink based on the live theme properties
//         property color currentBasePurple: Qt.tint(root.mauve, Qt.rgba(root.pink.r, root.pink.g, root.pink.b, baseBlend))

//         property real accentBlend: 0.0
//         SequentialAnimation on accentBlend {
//             loops: Animation.Infinite; running: true
//             NumberAnimation { to: 1.0; duration: 15000; easing.type: Easing.InOutSine }
//             NumberAnimation { to: 0.0; duration: 15000; easing.type: Easing.InOutSine }
//         }
//         // Dynamically tints between blue and sapphire based on the live theme properties
//         property color currentAccentLavender: Qt.tint(root.blue, Qt.rgba(root.sapphire.r, root.sapphire.g, root.sapphire.b, accentBlend))

//         // Animation States
//         property real calmState: 0.0 
//         property real popShockwave: 0.0 

//         // 9. Breathing Phase Offsets (Continuous Time Engine)
//         property real time: 0
//         NumberAnimation on time { 
//             from: 0; to: Math.PI * 2; duration: 15000; loops: Animation.Infinite; running: true 
//         }
        
//         // 3 separate breathing phases for organic offset
//         property real breathA: (Math.sin(time * 3) + 1) / 2       // Glow phase
//         property real breathB: (Math.sin(time * 3 + 0.6) + 1) / 2 // Core phase
//         property real breathC: (Math.sin(time * 3 + 1.2) + 1) / 2 // Background phase

//         // Window Entrance Animation
//         opacity: 0.0
//         scale: 0.98
        
//         Component.onCompleted: entranceAnimation.start()
        
//         ParallelAnimation {
//             id: entranceAnimation
//             NumberAnimation { target: windowContent; property: "opacity"; to: 1.0; duration: 400; easing.type: Easing.OutCubic }
//             NumberAnimation { target: windowContent; property: "scale"; to: 1.0; duration: 400; easing.type: Easing.OutCubic }
//         }

//         property real globalOrbitAngle: 0
//         NumberAnimation on globalOrbitAngle {
//             from: 0; to: Math.PI * 2; duration: 60000; loops: Animation.Infinite; running: true
//         }

//         // ---------------------------------------------------------------------
//         // BACKGROUND ARTIFACTS
//         // ---------------------------------------------------------------------

//         // 1. Large Flowing Background Orb A
//         Rectangle {
//             id: backgroundOrbA
//             width: parent.width * 0.8
//             height: width
//             radius: width / 2
            
//             // 1. Subtle Depth Parallax (Follows worldCenter drift slightly)
//             // 6. Energy Density Shift After Calm (Reduced amplitude)
//             x: (parent.width / 2 - width / 2) + Math.cos(windowContent.globalOrbitAngle * 2) * (250 - windowContent.calmState * 60) + (worldCenter.driftX * 0.4)
//             y: (parent.height / 2 - height / 2) + Math.sin(windowContent.globalOrbitAngle * 2) * (150 - windowContent.calmState * 40) + (worldCenter.driftY * 0.4)
            
//             // Offset breathing C
//             opacity: 0.025 + (windowContent.breathC * 0.015 * (1.0 - (windowContent.calmState * 0.3)))
//             color: windowContent.currentBasePurple
//             antialiasing: true
            
//             layer.enabled: true
//             layer.effect: MultiEffect { blurEnabled: true; blurMax: 64; blur: 1.0 }
//         }

//         // 2. Large Flowing Background Orb B
//         Rectangle {
//             id: backgroundOrbB
//             width: parent.width * 0.9
//             height: width
//             radius: width / 2
            
//             x: (parent.width / 2 - width / 2) + Math.sin(windowContent.globalOrbitAngle * 1.5) * -(250 - windowContent.calmState * 60) + (worldCenter.driftX * 0.3)
//             y: (parent.height / 2 - height / 2) + Math.cos(windowContent.globalOrbitAngle * 1.5) * -(150 - windowContent.calmState * 40) + (worldCenter.driftY * 0.3)
            
//             opacity: 0.020 + (windowContent.breathC * 0.012 * (1.0 - (windowContent.calmState * 0.3)))
//             color: windowContent.currentAccentLavender
//             antialiasing: true
            
//             layer.enabled: true
//             layer.effect: MultiEffect { blurEnabled: true; blurMax: 80; blur: 1.0 }
//         }

//         // 3. Gravitational Floating Particles (Improved Naturalism)
//         Repeater {
//             model: 20 
            
//             Rectangle {
//                 id: particle
//                 property real randomPhase: index * 0.47
//                 property real baseX: (index * 113) % root.width
//                 property real baseY: (index * 137) % root.height
                
//                 property real vecX: (root.width / 2) - baseX
//                 property real vecY: (root.height / 2) - baseY
                
//                 width: (index % 4) + 3
//                 height: width
//                 radius: width / 2
                
//                 // 4. Improve Particle Naturalism (Elliptical drift instead of vertical bounce)
//                 // 1. Parallax addition
//                 x: baseX + Math.cos(windowContent.time * 4 + randomPhase) * 15 * windowContent.calmState + (worldCenter.driftX * 0.8) - (vecX * 0.04 * windowContent.popShockwave)
//                 y: baseY + Math.sin(windowContent.time * 3 + randomPhase) * 15 * windowContent.calmState + (worldCenter.driftY * 0.8) - (vecY * 0.04 * windowContent.popShockwave)
                
//                 color: index % 3 === 0 ? windowContent.currentAccentLavender : windowContent.currentBasePurple
                
//                 opacity: ((index % 3) * 0.1 + 0.1) + (windowContent.popShockwave * 0.2)
//                 antialiasing: true

//                 layer.enabled: true
//                 layer.effect: MultiEffect { blurEnabled: true; blurMax: (index % 3) * 3 + 2; blur: 1.0 }
//             }
//         }

//         // ---------------------------------------------------------------------
//         // THE ASSISTANT CORE
//         // ---------------------------------------------------------------------
        
//         // Premium Glow Aura
//         Item {
//             id: orbGlow
//             anchors.centerIn: parent
//             width: 150
//             height: 150
            
//             property real baseOpacity: 0.0
//             property real baseScale: 0.8
            
//             // 9. Offset breathing A
//             // 6. Energy Shift (Lowers glow mildly in calm state)
//             opacity: baseOpacity * (1.0 - (windowContent.calmState * 0.2)) * (0.8 + (windowContent.breathA * 0.2))
//             scale: baseScale + (windowContent.breathA * 0.03)

//             Repeater {
//                 model: 2 
//                 Rectangle {
//                     anchors.centerIn: parent
//                     width: parent.width + (index * 40) + 20
//                     height: width
//                     radius: width / 2
//                     color: windowContent.currentBasePurple 
//                     opacity: index === 0 ? 0.12 : 0.05
//                     antialiasing: true
//                 }
//             }
//         }

//         // Redesigned Diffuse Shockwave Fade 
//         Rectangle {
//             id: diffuseShockwave
//             anchors.centerIn: parent
//             width: 150
//             height: 150
//             radius: width / 2
//             color: windowContent.currentAccentLavender
//             opacity: windowContent.popShockwave * 0.12 
//             scale: 1.0 + (windowContent.popShockwave * 0.8) 
//             antialiasing: true
//         }

//         // Center Wrapper
//         Item {
//             id: worldCenter
//             width: 150
//             height: 150
            
//             property real driftX: 0
//             property real driftY: 0
            
//             SequentialAnimation on driftX {
//                 loops: Animation.Infinite
//                 NumberAnimation { to: 2; duration: 7450; easing.type: Easing.InOutSine }
//                 NumberAnimation { to: -1.5; duration: 6920; easing.type: Easing.InOutSine }
//             }
//             SequentialAnimation on driftY {
//                 loops: Animation.Infinite
//                 NumberAnimation { to: 1.5; duration: 8210; easing.type: Easing.InOutSine }
//                 NumberAnimation { to: -2; duration: 7630; easing.type: Easing.InOutSine }
//             }

//             anchors.centerIn: parent
//             anchors.horizontalCenterOffset: driftX
//             anchors.verticalCenterOffset: driftY
            
//             // 10. Ultra-Subtle Idle Micro Drift
//             rotation: windowContent.calmState * Math.sin(windowContent.time * 2) * 2.0

//             Item {
//                 id: orb
//                 anchors.fill: parent

//                 // 1. Loading Shell
//                 Rectangle {
//                     id: loadingShell
//                     anchors.fill: parent
//                     radius: width / 2
//                     antialiasing: true
//                     opacity: 1.0
                    
//                     gradient: Gradient {
//                         orientation: Gradient.Horizontal
//                         GradientStop { position: 0.0; color: root.surface2 }
//                         GradientStop { position: 1.0; color: root.surface0 }
//                     }
//                 }

//                 // 2. Activated Energy Core
//                 Item {
//                     id: activeEnergyCore
//                     anchors.fill: parent
//                     opacity: 0.0
                    
//                     // 9. Offset breathing B
//                     scale: 1.0 + (windowContent.breathB * 0.015)

//                     // Layer A: Oscillating Base Gradient
//                     Rectangle {
//                         id: fluidGradientLayer
//                         anchors.fill: parent
//                         radius: width / 2
//                         antialiasing: true
                        
//                         property real oscRotation: 0
//                         SequentialAnimation on oscRotation {
//                             loops: Animation.Infinite
//                             NumberAnimation { to: 15; duration: 6000; easing.type: Easing.InOutSine }
//                             NumberAnimation { to: -15; duration: 6000; easing.type: Easing.InOutSine }
//                         }
//                         rotation: oscRotation

//                         gradient: Gradient {
//                             orientation: Gradient.Horizontal
//                             GradientStop { 
//                                 position: 0.0 
//                                 color: windowContent.currentBasePurple 
//                                 SequentialAnimation on position {
//                                     loops: Animation.Infinite
//                                     NumberAnimation { to: 0.2; duration: 5000; easing.type: Easing.InOutSine }
//                                     NumberAnimation { to: 0.0; duration: 5000; easing.type: Easing.InOutSine }
//                                 }
//                             }
//                             GradientStop { 
//                                 position: 1.0 
//                                 color: windowContent.currentAccentLavender 
//                                 SequentialAnimation on position {
//                                     loops: Animation.Infinite
//                                     NumberAnimation { to: 0.8; duration: 4500; easing.type: Easing.InOutSine }
//                                     NumberAnimation { to: 1.0; duration: 4500; easing.type: Easing.InOutSine }
//                                 }
//                             }
//                         }
//                     }

//                     // 2. Micro Inner Pulse to Core (Circulating core energy, not scaling)
//                     Item {
//                         anchors.fill: parent
//                         opacity: 0.3 + (windowContent.breathB * 0.2)
                        
//                         Rectangle {
//                             anchors.centerIn: parent
//                             width: parent.width * 0.6
//                             height: width
//                             radius: width / 2
//                             color: windowContent.currentAccentLavender
//                             opacity: 0.4
//                             layer.enabled: true
//                             layer.effect: MultiEffect { blurEnabled: true; blurMax: 32; blur: 1.0 }
//                         }
//                     }

//                     // Layer B: Subtle transparent mask oscillating opposite
//                     Rectangle {
//                         anchors.fill: parent
//                         radius: width / 2
//                         antialiasing: true
//                         opacity: 0.8
                        
//                         property real maskRotation: 0
//                         SequentialAnimation on maskRotation {
//                             loops: Animation.Infinite
//                             NumberAnimation { to: -20; duration: 7000; easing.type: Easing.InOutSine }
//                             NumberAnimation { to: 20; duration: 7000; easing.type: Easing.InOutSine }
//                         }
//                         rotation: maskRotation

//                         gradient: Gradient {
//                             orientation: Gradient.Vertical
//                             GradientStop { position: 0.0; color: "transparent" }
//                             GradientStop { position: 0.4; color: windowContent.currentAccentLavender } 
//                             GradientStop { position: 0.6; color: windowContent.currentAccentLavender } 
//                             GradientStop { position: 1.0; color: "transparent" }
//                         }
//                     }

//                     // 7. Subtle Orb Surface Noise (Simulated via rotating organic low-opacity elements)
//                     Item {
//                         anchors.fill: parent
//                         opacity: 0.03
//                         clip: true
//                         layer.enabled: true
//                         layer.effect: MultiEffect { blurEnabled: true; blurMax: 2; blur: 1.0 }
//                         Repeater {
//                             model: 24
//                             Rectangle {
//                                 property real angle: index * 15
//                                 property real dist: (index * 4) % (parent.width / 2.2)
//                                 x: (parent.width / 2) + Math.cos(angle) * dist - width/2
//                                 y: (parent.height / 2) + Math.sin(angle) * dist - height/2
//                                 width: (index % 3) + 2
//                                 height: width
//                                 radius: width/2
//                                 color: root.text
//                                 rotation: windowContent.time * 20 * (index % 2 === 0 ? 1 : -1)
//                             }
//                         }
//                     }

//                     // 4. Subtle Light Refraction Sweep
//                     Rectangle {
//                         id: refractionLayer
//                         anchors.fill: parent
//                         radius: width / 2
//                         antialiasing: true
//                         rotation: 25
//                         color: "transparent"
                        
//                         // 6. Density Shift (Diminish refraction sweeps slightly on idle)
//                         opacity: 1.0 - (windowContent.calmState * 0.2)
                        
//                         property real sweepPos: 0.0
                        
//                         SequentialAnimation on sweepPos {
//                             loops: Animation.Infinite
//                             running: true
//                             NumberAnimation { from: -0.5; to: 1.5; duration: 8000; easing.type: Easing.InOutSine }
//                             PauseAnimation { duration: 4000 } 
//                         }

//                         gradient: Gradient {
//                             orientation: Gradient.Horizontal
//                             GradientStop { position: Math.max(0.0, Math.min(1.0, refractionLayer.sweepPos - 0.2)); color: "transparent" }
//                             GradientStop { position: Math.max(0.0, Math.min(1.0, refractionLayer.sweepPos)); color: Qt.alpha(root.text, 0.08) }
//                             GradientStop { position: Math.max(0.0, Math.min(1.0, refractionLayer.sweepPos + 0.2)); color: "transparent" }
//                         }
//                     }

//                     // 3. Soft Ambient Edge Lighting (Inner rim light via blurred border trick)
//                     Rectangle {
//                         anchors.fill: parent
//                         anchors.margins: 1 // Keep inside bounds
//                         radius: width / 2
//                         color: "transparent"
//                         border.width: 1.5
//                         border.color: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.15 + windowContent.breathA * 0.1)
//                         antialiasing: true
//                         layer.enabled: true
//                         layer.effect: MultiEffect { blurEnabled: true; blurMax: 4; blur: 1.0 }
//                     }
//                 }
//             }
//         }

//         // ---------------------------------------------------------------------
//         // MASTER CINEMATIC SEQUENCE
//         // ---------------------------------------------------------------------
//         SequentialAnimation {
//             id: introSequence
//             running: true

//             PauseAnimation { duration: 200 } 

//             // Phase 1: Loading Wind-Up
//             NumberAnimation {
//                 target: loadingShell
//                 property: "rotation"
//                 from: 0
//                 to: 360 
//                 duration: 1200 
//                 easing.type: Easing.InCubic
//             }

//             // Phase 2: Anticipation Contraction
//             NumberAnimation { 
//                 target: orb; 
//                 property: "scale"; 
//                 to: 0.96; 
//                 duration: 250; 
//                 easing.type: Easing.InOutSine 
//             }
            
//             PauseAnimation { duration: 100 }

//             // Phase 3: The Transformation Pop
//             ParallelAnimation {
//                 NumberAnimation { target: loadingShell; property: "opacity"; to: 0.0; duration: 150 }
//                 NumberAnimation { target: activeEnergyCore; property: "opacity"; to: 1.0; duration: 300 }

//                 SequentialAnimation {
//                     NumberAnimation { target: orb; property: "scale"; to: 1.05; duration: 200; easing.type: Easing.OutCubic }
//                     NumberAnimation { target: orb; property: "scale"; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
//                 }
                
//                 // 8. Refine Shockwave Dissipation (Asymmetrical decay: Fast rise, slow lingering fade)
//                 SequentialAnimation {
//                     NumberAnimation { target: windowContent; property: "popShockwave"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
//                     NumberAnimation { target: windowContent; property: "popShockwave"; to: 0.0; duration: 1200; easing.type: Easing.OutQuart } 
//                 }

//                 NumberAnimation { target: orbGlow; property: "baseOpacity"; to: 1.0; duration: 400; easing.type: Easing.InOutSine }
//                 NumberAnimation { target: orbGlow; property: "baseScale"; to: 1.0; duration: 600; easing.type: Easing.OutBack }
//             }

//             // Phase 4: Settle into Calm Idle State
//             NumberAnimation {
//                 target: windowContent
//                 property: "calmState"
//                 from: 0.0
//                 to: 1.0
//                 duration: 2500
//                 easing.type: Easing.InOutSine
//             }
//         }
//     }
// }


import QtQuick                                                                  // Imports the QtQuick module, providing basic QML types for building user interfaces
import QtQuick.Effects                                                          // Imports the QtQuick.Effects module for graphical effects like blur and color adjustments
import "../"                                                                    // Imports parent directory, allowing access to components in the root quickshell folder

Item {                                                                          // Root item container for the entire lock screen component
    id: root                                                                    // Unique identifier "root" for referencing this top-level item throughout the file

    MatugenColors { id: _theme }                                                // Instantiates MatugenColors component with id "_theme" to access the dynamic color palette generated by matugen (material color generator)
    
    // ------------------------------------------------------------------------- // Visual divider comment marking the start of color property definitions
    // COLORS (Dynamic Matugen Palette)                                           // Section header indicating these are dynamic theme colors from matugen
    // ------------------------------------------------------------------------- // Visual divider closing the section header
    readonly property color base: _theme.base                                   // Read-only property exposing the base background color from the matugen theme (typically the darkest shade)
    readonly property color mantle: _theme.mantle                               // Read-only property for mantle color, a slightly lighter shade than base from the theme
    readonly property color crust: _theme.crust                                 // Read-only property for crust color, the lightest of the three background shades from the theme
    readonly property color text: _theme.text                                   // Read-only property for the primary text/foreground color from the matugen theme
    readonly property color surface0: _theme.surface0                           // Read-only property for surface0 color, the darkest UI surface color from the theme
    readonly property color surface1: _theme.surface1                           // Read-only property for surface1 color, a medium UI surface color from the theme
    readonly property color surface2: _theme.surface2                           // Read-only property for surface2 color, the lightest UI surface color from the theme
    
    readonly property color mauve: _theme.mauve                                 // Read-only property for mauve accent color from the matugen theme palette
    readonly property color pink: _theme.pink                                   // Read-only property for pink accent color from the matugen theme palette
    readonly property color blue: _theme.blue                                   // Read-only property for blue accent color from the matugen theme palette
    readonly property color sapphire: _theme.sapphire                           // Read-only property for sapphire accent color from the matugen theme palette

    // Master Container                                                          // Comment describing the main window container rectangle
    Rectangle {                                                                 // Main rectangular container that fills the entire lock screen window
        id: windowContent                                                       // Unique identifier "windowContent" for the master container
        anchors.fill: parent                                                    // Anchors to fill the entire parent item (the root Item)
        radius: 12                                                              // Rounds all four corners with a 12-pixel radius for a modern card-like appearance
        color: root.base                                                        // Sets background color to the base color from the matugen theme (darkest shade)
        clip: true                                                              // Enables clipping so child elements are cut off at the rounded rectangle boundaries

        // --------------------------------------------------------------------- // Visual divider for the global theme and state controls section
        // GLOBAL THEME & STATE CONTROLS                                          // Section header for animations and dynamic color blending
        // --------------------------------------------------------------------- // Visual divider closing the section header
        
        // 5. Slow Color Temperature Drift (Fixed for Live Theme Reloading)       // Comment explaining this animation creates a slow color temperature shift between mauve and pink
        property real baseBlend: 0.0                                            // Property tracking the blend factor between mauve and pink (0.0 = pure mauve, 1.0 = pure pink)
        SequentialAnimation on baseBlend {                                      // Sequential animation that runs on the baseBlend property, creating a continuous oscillation
            loops: Animation.Infinite; running: true                            // Loops infinitely and starts running immediately when the component loads
            NumberAnimation { to: 1.0; duration: 15000; easing.type: Easing.InOutSine } // Animates baseBlend from current value to 1.0 over 15 seconds with smooth sine easing
            NumberAnimation { to: 0.0; duration: 15000; easing.type: Easing.InOutSine } // Animates baseBlend back to 0.0 over 15 seconds, completing one full 30-second cycle
        }
        // Dynamically tints between mauve and pink based on the live theme properties // Comment explaining the color blending logic
        property color currentBasePurple: Qt.tint(root.mauve, Qt.rgba(root.pink.r, root.pink.g, root.pink.b, baseBlend)) // Creates a dynamic purple color by tinting mauve with pink at the current blend factor

        property real accentBlend: 0.0                                          // Property tracking the blend factor between blue and sapphire (0.0 = pure blue, 1.0 = pure sapphire)
        SequentialAnimation on accentBlend {                                    // Sequential animation that runs on the accentBlend property, creating continuous color oscillation
            loops: Animation.Infinite; running: true                            // Loops infinitely and starts running immediately
            NumberAnimation { to: 1.0; duration: 15000; easing.type: Easing.InOutSine } // Animates accentBlend to 1.0 over 15 seconds with sine easing
            NumberAnimation { to: 0.0; duration: 15000; easing.type: Easing.InOutSine } // Animates accentBlend back to 0.0 over 15 seconds, completing a 30-second cycle
        }
        // Dynamically tints between blue and sapphire based on the live theme properties // Comment explaining the accent color blending
        property color currentAccentLavender: Qt.tint(root.blue, Qt.rgba(root.sapphire.r, root.sapphire.g, root.sapphire.b, accentBlend)) // Creates a dynamic lavender color by tinting blue with sapphire at the current blend factor

        // Animation States                                                       // Comment marking the section for animation state properties
        property real calmState: 0.0                                            // Property tracking the calm/idle state progress (0.0 = just activated, 1.0 = fully settled), used to reduce animation intensity over time
        property real popShockwave: 0.0                                         // Property tracking the shockwave effect intensity (0.0 to 1.0), peaks during activation then dissipates

        // 9. Breathing Phase Offsets (Continuous Time Engine)                    // Comment explaining the breathing animation system using a continuous time value
        property real time: 0                                                   // Continuous time property that cycles through 0 to 2π for sine-based animations
        NumberAnimation on time {                                               // NumberAnimation that continuously updates the time property
            from: 0; to: Math.PI * 2; duration: 15000; loops: Animation.Infinite; running: true // Animates from 0 to 2π (full circle) over 15 seconds, looping infinitely
        }
        
        // 3 separate breathing phases for organic offset                         // Comment explaining the three phase-offset breathing animations for natural feel
        property real breathA: (Math.sin(time * 3) + 1) / 2                     // Breathing phase A: multiplies time by 3 for faster oscillation, converts sine (-1 to 1) to 0-1 range for opacity/scale use
        property real breathB: (Math.sin(time * 3 + 0.6) + 1) / 2               // Breathing phase B: same frequency as A but offset by 0.6 radians for a staggered organic feel
        property real breathC: (Math.sin(time * 3 + 1.2) + 1) / 2               // Breathing phase C: offset by 1.2 radians, creating three interleaved breathing rhythms across the interface

        // Window Entrance Animation                                              // Comment marking the initial entrance animation section
        opacity: 0.0                                                            // Starts the window fully transparent for fade-in animation
        scale: 0.98                                                             // Starts the window slightly scaled down (98%) for a subtle zoom-in effect
        
        Component.onCompleted: entranceAnimation.start()                        // When the component finishes loading, starts the entrance animation sequence
        
        ParallelAnimation {                                                     // Parallel animation that runs multiple property animations simultaneously
            id: entranceAnimation                                               // Unique identifier "entranceAnimation" for the fade-in and scale animation
            NumberAnimation { target: windowContent; property: "opacity"; to: 1.0; duration: 400; easing.type: Easing.OutCubic } // Fades windowContent opacity from 0 to 1 over 400ms with cubic ease-out
            NumberAnimation { target: windowContent; property: "scale"; to: 1.0; duration: 400; easing.type: Easing.OutCubic } // Scales windowContent from 0.98 to 1.0 over 400ms with cubic ease-out
        }

        property real globalOrbitAngle: 0                                       // Property for the global orbital rotation angle, used for background element movement
        NumberAnimation on globalOrbitAngle {                                   // NumberAnimation creating a very slow full rotation over 60 seconds
            from: 0; to: Math.PI * 2; duration: 60000; loops: Animation.Infinite; running: true // Full 360-degree rotation over 60 seconds, looping infinitely
        }

        // --------------------------------------------------------------------- // Visual divider for the background artifacts section
        // BACKGROUND ARTIFACTS                                                   // Section header for the decorative background orbs and particles
        // --------------------------------------------------------------------- // Visual divider closing the section header

        // 1. Large Flowing Background Orb A                                      // Comment describing the first large background decorative orb
        Rectangle {                                                             // Rectangle acting as a large glowing background orb
            id: backgroundOrbA                                                  // Unique identifier "backgroundOrbA" for the first background orb
            width: parent.width * 0.8                                           // Width is 80% of the parent window width for a large but contained orb
            height: width                                                       // Height matches width to maintain a perfect circle shape
            radius: width / 2                                                   // Radius is half the width, creating a circular shape from the rectangle
            
            // 1. Subtle Depth Parallax (Follows worldCenter drift slightly)      // Comment explaining the parallax effect that follows the world center movement
            // 6. Energy Density Shift After Calm (Reduced amplitude)             // Comment noting that movement amplitude decreases as calmState increases
            x: (parent.width / 2 - width / 2) + Math.cos(windowContent.globalOrbitAngle * 2) * (250 - windowContent.calmState * 60) + (worldCenter.driftX * 0.4) // X position: centered offset + orbital cosine movement (reduced by calm) + parallax from worldCenter drift
            y: (parent.height / 2 - height / 2) + Math.sin(windowContent.globalOrbitAngle * 2) * (150 - windowContent.calmState * 40) + (worldCenter.driftY * 0.4) // Y position: centered offset + orbital sine movement (reduced by calm) + parallax from worldCenter drift
            
            // Offset breathing C                                                  // Comment indicating this orb uses breathing phase C for opacity
            opacity: 0.025 + (windowContent.breathC * 0.015 * (1.0 - (windowContent.calmState * 0.3))) // Base opacity of 0.025 plus breathing variation that decreases as calmState increases
            color: windowContent.currentBasePurple                              // Uses the dynamic purple blend color (mauve-pink mix)
            antialiasing: true                                                  // Enables antialiasing for smooth edges on the circular shape
            
            layer.enabled: true                                                 // Enables layer rendering for applying effects to this item
            layer.effect: MultiEffect { blurEnabled: true; blurMax: 64; blur: 1.0 } // Applies a blur effect with maximum blur radius of 64 and full intensity (1.0) for a soft glowing appearance
        }

        // 2. Large Flowing Background Orb B                                      // Comment describing the second large background decorative orb
        Rectangle {                                                             // Rectangle for the second background orb
            id: backgroundOrbB                                                  // Unique identifier "backgroundOrbB"
            width: parent.width * 0.9                                           // Width is 90% of parent, slightly larger than Orb A
            height: width                                                       // Maintains square shape for circular rendering
            radius: width / 2                                                   // Circular radius
            
            x: (parent.width / 2 - width / 2) + Math.sin(windowContent.globalOrbitAngle * 1.5) * -(250 - windowContent.calmState * 60) + (worldCenter.driftX * 0.3) // X position uses sine (instead of cosine) with 1.5x frequency and negative direction for variation from Orb A
            y: (parent.height / 2 - height / 2) + Math.cos(windowContent.globalOrbitAngle * 1.5) * -(150 - windowContent.calmState * 40) + (worldCenter.driftY * 0.3) // Y position uses cosine with negative direction, creating a different orbital pattern
            
            opacity: 0.020 + (windowContent.breathC * 0.012 * (1.0 - (windowContent.calmState * 0.3))) // Slightly lower base opacity than Orb A, using same breathing phase C
            color: windowContent.currentAccentLavender                          // Uses the dynamic lavender blend color (blue-sapphire mix) for contrast with Orb A
            antialiasing: true                                                  // Smooth edges
            
            layer.enabled: true                                                 // Layer rendering enabled for blur effect
            layer.effect: MultiEffect { blurEnabled: true; blurMax: 80; blur: 1.0 } // Larger maximum blur (80) than Orb A for a more diffuse appearance
        }

        // 3. Gravitational Floating Particles (Improved Naturalism)               // Comment describing the particle system with naturalistic movement
        Repeater {                                                              // Repeater that creates multiple particle instances from a model
            model: 20                                                           // Creates 20 particle instances
            
            Rectangle {                                                         // Individual particle represented as a small rectangle (rendered as circle)
                id: particle                                                    // Unique identifier "particle" for each instance
                property real randomPhase: index * 0.47                         // Pseudo-random phase offset based on index for varied animation timing
                property real baseX: (index * 113) % root.width                 // Calculates a base X position using index and modulo to wrap within window width
                property real baseY: (index * 137) % root.height                // Calculates a base Y position using different multiplier for varied distribution
                
                property real vecX: (root.width / 2) - baseX                    // Vector X component from particle to center of screen (used for shockwave effect)
                property real vecY: (root.height / 2) - baseY                   // Vector Y component from particle to center of screen
                
                width: (index % 4) + 3                                          // Width varies between 3 and 6 pixels based on index modulo 4, creating size variety
                height: width                                                   // Height matches width for circular shape
                radius: width / 2                                               // Radius for circle rendering
                
                // 4. Improve Particle Naturalism (Elliptical drift instead of vertical bounce) // Comment noting the elliptical movement pattern
                // 1. Parallax addition                                           // Comment noting parallax from world center drift
                x: baseX + Math.cos(windowContent.time * 4 + randomPhase) * 15 * windowContent.calmState + (worldCenter.driftX * 0.8) - (vecX * 0.04 * windowContent.popShockwave) // X position: base + elliptical drift (scaled by calm) + parallax + shockwave push away from center
                y: baseY + Math.sin(windowContent.time * 3 + randomPhase) * 15 * windowContent.calmState + (worldCenter.driftY * 0.8) - (vecY * 0.04 * windowContent.popShockwave) // Y position: base + elliptical drift + parallax + shockwave push
                
                color: index % 3 === 0 ? windowContent.currentAccentLavender : windowContent.currentBasePurple // Alternates between lavender and purple based on index modulo 3 (every third is lavender)
                
                opacity: ((index % 3) * 0.1 + 0.1) + (windowContent.popShockwave * 0.2) // Opacity varies by index (0.1-0.3) plus additional during shockwave
                antialiasing: true                                              // Smooth circular edges

                layer.enabled: true                                             // Layer rendering for glow effect
                layer.effect: MultiEffect { blurEnabled: true; blurMax: (index % 3) * 3 + 2; blur: 1.0 } // Variable blur amount based on index (2-8 max blur), creating depth variety
            }
        }

        // --------------------------------------------------------------------- // Visual divider for the assistant core section
        // THE ASSISTANT CORE                                                      // Section header for the central animated orb/energy core
        // --------------------------------------------------------------------- // Visual divider closing the section header
        
        // Premium Glow Aura                                                       // Comment describing the glow aura surrounding the central orb
        Item {                                                                  // Container item for the glow aura effect
            id: orbGlow                                                         // Unique identifier "orbGlow"
            anchors.centerIn: parent                                            // Centers this item in the parent window
            width: 150                                                          // Fixed width of 150 pixels
            height: 150                                                         // Fixed height of 150 pixels
            
            property real baseOpacity: 0.0                                      // Base opacity starts at 0, animated to 1 during activation sequence
            property real baseScale: 0.8                                        // Base scale starts at 0.8, animated to 1.0 during activation
            
            // 9. Offset breathing A                                              // Comment indicating this uses breathing phase A
            // 6. Energy Shift (Lowers glow mildly in calm state)                 // Comment noting glow intensity decreases in calm state
            opacity: baseOpacity * (1.0 - (windowContent.calmState * 0.2)) * (0.8 + (windowContent.breathA * 0.2)) // Opacity combines base, calm reduction (up to 20%), and breathing variation (±20%)
            scale: baseScale + (windowContent.breathA * 0.03)                   // Scale slightly oscillates with breathing phase A (±3%)

            Repeater {                                                          // Repeater creating two concentric glow rings
                model: 2                                                        // Creates 2 glow ring instances
                Rectangle {                                                     // Individual glow ring
                    anchors.centerIn: parent                                    // Centers each ring in the orbGlow container
                    width: parent.width + (index * 40) + 20                     // Width increases with index: first ring +20, second ring +60 from parent width
                    height: width                                               // Maintains circular shape
                    radius: width / 2                                           // Circular radius
                    color: windowContent.currentBasePurple                      // Uses dynamic purple color for the glow
                    opacity: index === 0 ? 0.12 : 0.05                         // Inner ring (index 0) is more opaque (0.12), outer ring (index 1) is subtler (0.05)
                    antialiasing: true                                          // Smooth edges for the circular glow
                }
            }
        }

        // Redesigned Diffuse Shockwave Fade                                      // Comment describing the shockwave effect that radiates on activation
        Rectangle {                                                             // Rectangle for the expanding shockwave ring
            id: diffuseShockwave                                                // Unique identifier "diffuseShockwave"
            anchors.centerIn: parent                                            // Centered in the window
            width: 150                                                          // Base width of 150 pixels
            height: 150                                                         // Base height of 150 pixels
            radius: width / 2                                                   // Circular shape
            color: windowContent.currentAccentLavender                          // Uses lavender accent color for the shockwave
            opacity: windowContent.popShockwave * 0.12                          // Opacity directly proportional to shockwave intensity (max 12%)
            scale: 1.0 + (windowContent.popShockwave * 0.8)                     // Scale expands up to 80% larger as shockwave peaks
            antialiasing: true                                                  // Smooth edges
        }

        // Center Wrapper                                                          // Comment describing the wrapper for the central orb that drifts subtly
        Item {                                                                  // Container item for the central orb with drift animation
            id: worldCenter                                                     // Unique identifier "worldCenter"
            width: 150                                                          // Fixed width of 150 pixels
            height: 150                                                         // Fixed height of 150 pixels
            
            property real driftX: 0                                             // Horizontal drift offset, animated for subtle movement
            property real driftY: 0                                             // Vertical drift offset, animated for subtle movement
            
            SequentialAnimation on driftX {                                     // Sequential animation creating continuous horizontal drift
                loops: Animation.Infinite                                       // Loops infinitely
                NumberAnimation { to: 2; duration: 7450; easing.type: Easing.InOutSine } // Drifts right by 2 pixels over 7.45 seconds
                NumberAnimation { to: -1.5; duration: 6920; easing.type: Easing.InOutSine } // Drifts left by 1.5 pixels over 6.92 seconds
            }
            SequentialAnimation on driftY {                                     // Sequential animation for vertical drift
                loops: Animation.Infinite                                       // Loops infinitely
                NumberAnimation { to: 1.5; duration: 8210; easing.type: Easing.InOutSine } // Drifts down by 1.5 pixels over 8.21 seconds
                NumberAnimation { to: -2; duration: 7630; easing.type: Easing.InOutSine } // Drifts up by 2 pixels over 7.63 seconds
            }

            anchors.centerIn: parent                                            // Centers the worldCenter in the parent window
            anchors.horizontalCenterOffset: driftX                              // Offsets horizontal center by the current driftX value
            anchors.verticalCenterOffset: driftY                                // Offsets vertical center by the current driftY value
            
            // 10. Ultra-Subtle Idle Micro Drift                                   // Comment describing very subtle rotation during idle/calm state
            rotation: windowContent.calmState * Math.sin(windowContent.time * 2) * 2.0 // Rotation only active when calm, uses sine wave for gentle back-and-forth rocking (max ±2 degrees)

            Item {                                                              // Container item for the orb itself (loading shell and energy core)
                id: orb                                                         // Unique identifier "orb"
                anchors.fill: parent                                            // Fills the worldCenter container

                // 1. Loading Shell                                               // Comment describing the initial loading/shell state of the orb
                Rectangle {                                                     // Rectangle representing the loading shell (visible before activation)
                    id: loadingShell                                            // Unique identifier "loadingShell"
                    anchors.fill: parent                                        // Fills the orb container
                    radius: width / 2                                           // Circular shape
                    antialiasing: true                                          // Smooth edges
                    opacity: 1.0                                                // Fully opaque initially, fades out during activation
                    
                    gradient: Gradient {                                        // Gradient fill for the loading shell
                        orientation: Gradient.Horizontal                        // Horizontal gradient direction
                        GradientStop { position: 0.0; color: root.surface2 }   // Left side: surface2 color (lightest surface)
                        GradientStop { position: 1.0; color: root.surface0 }   // Right side: surface0 color (darkest surface), creating a 3D sphere illusion
                    }
                }

                // 2. Activated Energy Core                                       // Comment describing the energy core that appears after activation
                Item {                                                          // Container for the activated energy core
                    id: activeEnergyCore                                        // Unique identifier "activeEnergyCore"
                    anchors.fill: parent                                        // Fills the orb container
                    opacity: 0.0                                                // Starts fully transparent, fades in during activation
                    
                    // 9. Offset breathing B                                      // Comment indicating this uses breathing phase B
                    scale: 1.0 + (windowContent.breathB * 0.015)               // Scale subtly pulses with breathing phase B (±1.5%)

                    // Layer A: Oscillating Base Gradient                          // Comment describing the first layer: a rotating gradient
                    Rectangle {                                                 // Rectangle for the oscillating gradient layer
                        id: fluidGradientLayer                                  // Unique identifier "fluidGradientLayer"
                        anchors.fill: parent                                    // Fills the energy core
                        radius: width / 2                                       // Circular shape
                        antialiasing: true                                      // Smooth edges
                        
                        property real oscRotation: 0                            // Property for oscillation rotation angle
                        SequentialAnimation on oscRotation {                    // Sequential animation for back-and-forth rotation
                            loops: Animation.Infinite                           // Loops infinitely
                            NumberAnimation { to: 15; duration: 6000; easing.type: Easing.InOutSine } // Rotates to 15 degrees over 6 seconds
                            NumberAnimation { to: -15; duration: 6000; easing.type: Easing.InOutSine } // Rotates to -15 degrees over 6 seconds
                        }
                        rotation: oscRotation                                   // Applies the oscillating rotation to the gradient layer

                        gradient: Gradient {                                    // Gradient with animated color stops
                            orientation: Gradient.Horizontal                    // Horizontal gradient
                            GradientStop {                                      // First gradient stop (left side)
                                position: 0.0                                   // Starts at left edge
                                color: windowContent.currentBasePurple          // Uses dynamic purple color
                                SequentialAnimation on position {               // Animates the gradient stop position
                                    loops: Animation.Infinite                   // Loops infinitely
                                    NumberAnimation { to: 0.2; duration: 5000; easing.type: Easing.InOutSine } // Moves stop to 20% over 5 seconds
                                    NumberAnimation { to: 0.0; duration: 5000; easing.type: Easing.InOutSine } // Moves stop back to 0% over 5 seconds
                                }
                            }
                            GradientStop {                                      // Second gradient stop (right side)
                                position: 1.0                                   // Starts at right edge
                                color: windowContent.currentAccentLavender      // Uses dynamic lavender color
                                SequentialAnimation on position {               // Animates gradient stop position
                                    loops: Animation.Infinite                   // Loops infinitely
                                    NumberAnimation { to: 0.8; duration: 4500; easing.type: Easing.InOutSine } // Moves stop to 80% over 4.5 seconds
                                    NumberAnimation { to: 1.0; duration: 4500; easing.type: Easing.InOutSine } // Moves stop back to 100% over 4.5 seconds
                                }
                            }
                        }
                    }

                    // 2. Micro Inner Pulse to Core (Circulating core energy, not scaling) // Comment describing the inner pulse effect
                    Item {                                                      // Container for the micro inner pulse
                        anchors.fill: parent                                    // Fills the energy core
                        opacity: 0.3 + (windowContent.breathB * 0.2)           // Opacity pulses with breathing phase B (0.3 to 0.5)
                        
                        Rectangle {                                             // Small inner glowing rectangle
                            anchors.centerIn: parent                            // Centered in the energy core
                            width: parent.width * 0.6                           // 60% of parent width
                            height: width                                       // Circular shape
                            radius: width / 2                                   // Circular radius
                            color: windowContent.currentAccentLavender          // Lavender accent color
                            opacity: 0.4                                        // 40% opacity
                            layer.enabled: true                                 // Layer rendering for blur
                            layer.effect: MultiEffect { blurEnabled: true; blurMax: 32; blur: 1.0 } // Blurred for soft inner glow
                        }
                    }

                    // Layer B: Subtle transparent mask oscillating opposite       // Comment describing the second layer: an oscillating transparent mask
                    Rectangle {                                                 // Rectangle for the mask layer
                        anchors.fill: parent                                    // Fills the energy core
                        radius: width / 2                                       // Circular shape
                        antialiasing: true                                      // Smooth edges
                        opacity: 0.8                                            // 80% opacity for the mask
                        
                        property real maskRotation: 0                           // Property for mask rotation
                        SequentialAnimation on maskRotation {                   // Sequential animation for mask rotation
                            loops: Animation.Infinite                           // Loops infinitely
                            NumberAnimation { to: -20; duration: 7000; easing.type: Easing.InOutSine } // Rotates to -20 degrees over 7 seconds
                            NumberAnimation { to: 20; duration: 7000; easing.type: Easing.InOutSine } // Rotates to 20 degrees over 7 seconds (opposite direction from fluidGradientLayer)
                        }
                        rotation: maskRotation                                  // Applies the mask rotation

                        gradient: Gradient {                                    // Vertical gradient for the mask
                            orientation: Gradient.Vertical                      // Vertical orientation
                            GradientStop { position: 0.0; color: "transparent" } // Top: transparent
                            GradientStop { position: 0.4; color: windowContent.currentAccentLavender } // 40%: lavender accent
                            GradientStop { position: 0.6; color: windowContent.currentAccentLavender } // 60%: lavender accent (creates a band)
                            GradientStop { position: 1.0; color: "transparent" } // Bottom: transparent
                        }
                    }

                    // 7. Subtle Orb Surface Noise (Simulated via rotating organic low-opacity elements) // Comment describing surface noise/texture effect
                    Item {                                                      // Container for the surface noise particles
                        anchors.fill: parent                                    // Fills the energy core
                        opacity: 0.03                                           // Very subtle 3% opacity
                        clip: true                                              // Clips particles to circular bounds
                        layer.enabled: true                                     // Layer rendering
                        layer.effect: MultiEffect { blurEnabled: true; blurMax: 2; blur: 1.0 } // Slight blur for soft noise
                        Repeater {                                              // Repeater for noise particles
                            model: 24                                           // 24 noise particles
                            Rectangle {                                         // Individual noise particle
                                property real angle: index * 15                 // Angle based on index (0, 15, 30, ... 345 degrees)
                                property real dist: (index * 4) % (parent.width / 2.2) // Distance from center varies by index, modulo keeps within orb
                                x: (parent.width / 2) + Math.cos(angle) * dist - width/2 // X position calculated from angle and distance
                                y: (parent.height / 2) + Math.sin(angle) * dist - height/2 // Y position calculated from angle and distance
                                width: (index % 3) + 2                         // Width varies 2-4 pixels
                                height: width                                   // Square for circular rendering
                                radius: width/2                                 // Circular shape
                                color: root.text                                // Text color for the noise particles
                                rotation: windowContent.time * 20 * (index % 2 === 0 ? 1 : -1) // Rotates particles, alternating direction based on even/odd index
                            }
                        }
                    }

                    // 4. Subtle Light Refraction Sweep                            // Comment describing the light sweep/refraction effect
                    Rectangle {                                                 // Rectangle for the refraction sweep
                        id: refractionLayer                                     // Unique identifier "refractionLayer"
                        anchors.fill: parent                                    // Fills the energy core
                        radius: width / 2                                       // Circular shape
                        antialiasing: true                                      // Smooth edges
                        rotation: 25                                            // Rotated 25 degrees for diagonal sweep
                        color: "transparent"                                    // Transparent fill, only gradient shows
                        
                        // 6. Density Shift (Diminish refraction sweeps slightly on idle) // Comment noting refraction decreases in calm state
                        opacity: 1.0 - (windowContent.calmState * 0.2)         // Opacity decreases up to 20% in calm state
                        
                        property real sweepPos: 0.0                             // Property for the sweep position (0.0 to 1.5)
                        
                        SequentialAnimation on sweepPos {                       // Animation for the sweep position
                            loops: Animation.Infinite                           // Loops infinitely
                            running: true                                       // Starts running immediately
                            NumberAnimation { from: -0.5; to: 1.5; duration: 8000; easing.type: Easing.InOutSine } // Sweeps from -0.5 to 1.5 over 8 seconds
                            PauseAnimation { duration: 4000 }                   // Pauses for 4 seconds between sweeps
                        }

                        gradient: Gradient {                                    // Gradient that creates the sweeping light effect
                            orientation: Gradient.Horizontal                    // Horizontal gradient
                            GradientStop { position: Math.max(0.0, Math.min(1.0, refractionLayer.sweepPos - 0.2)); color: "transparent" } // Transparent before the sweep
                            GradientStop { position: Math.max(0.0, Math.min(1.0, refractionLayer.sweepPos)); color: Qt.alpha(root.text, 0.08) } // 8% opacity text color at sweep center
                            GradientStop { position: Math.max(0.0, Math.min(1.0, refractionLayer.sweepPos + 0.2)); color: "transparent" } // Transparent after the sweep
                        }
                    }

                    // 3. Soft Ambient Edge Lighting (Inner rim light via blurred border trick) // Comment describing the edge lighting effect
                    Rectangle {                                                 // Rectangle for the edge highlight
                        anchors.fill: parent                                    // Fills the energy core
                        anchors.margins: 1                                      // 1-pixel margin inside to keep border within bounds
                        radius: width / 2                                       // Circular shape matching the core
                        color: "transparent"                                    // Transparent fill
                        border.width: 1.5                                       // 1.5-pixel border for the rim light
                        border.color: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.15 + windowContent.breathA * 0.1) // Border color uses text color with alpha that breathes (15-25%)
                        antialiasing: true                                      // Smooth edges
                        layer.enabled: true                                     // Layer rendering
                        layer.effect: MultiEffect { blurEnabled: true; blurMax: 4; blur: 1.0 } // Blurred border creates soft inner rim glow
                    }
                }
            }
        }

        // --------------------------------------------------------------------- // Visual divider for the master cinematic sequence
        // MASTER CINEMATIC SEQUENCE                                                // Section header for the activation animation sequence
        // --------------------------------------------------------------------- // Visual divider closing the section header
        SequentialAnimation {                                                   // Sequential animation controlling the entire activation sequence
            id: introSequence                                                   // Unique identifier "introSequence"
            running: true                                                       // Starts running automatically when component loads

            PauseAnimation { duration: 200 }                                    // Initial 200ms pause before starting the sequence

            // Phase 1: Loading Wind-Up                                            // Comment describing the first phase: loading shell spins up
            NumberAnimation {                                                   // Animation for the loading shell rotation
                target: loadingShell                                            // Targets the loadingShell item
                property: "rotation"                                            // Animates the rotation property
                from: 0                                                         // Starts from 0 degrees
                to: 360                                                         // Rotates full 360 degrees
                duration: 1200                                                  // Over 1.2 seconds
                easing.type: Easing.InCubic                                     // Accelerating cubic easing (speeds up toward end)
            }

            // Phase 2: Anticipation Contraction                                   // Comment describing the second phase: orb contracts before explosion
            NumberAnimation {                                                   // Animation for the anticipation contraction
                target: orb;                                                    // Targets the orb item
                property: "scale";                                              // Animates the scale property
                to: 0.96;                                                       // Shrinks to 96% of original size
                duration: 250;                                                  // Over 250ms
                easing.type: Easing.InOutSine                                   // Smooth sine easing for natural feel
            }
            
            PauseAnimation { duration: 100 }                                    // Brief 100ms pause at the contracted state (builds tension)

            // Phase 3: The Transformation Pop                                     // Comment describing the third phase: the activation explosion
            ParallelAnimation {                                                 // Parallel animation running multiple transitions simultaneously
                NumberAnimation { target: loadingShell; property: "opacity"; to: 0.0; duration: 150 } // Loading shell fades out over 150ms
                NumberAnimation { target: activeEnergyCore; property: "opacity"; to: 1.0; duration: 300 } // Energy core fades in over 300ms

                SequentialAnimation {                                           // Nested sequential animation for the pop and settle scale
                    NumberAnimation { target: orb; property: "scale"; to: 1.05; duration: 200; easing.type: Easing.OutCubic } // Orb expands to 105% quickly (200ms, decelerating)
                    NumberAnimation { target: orb; property: "scale"; to: 1.0; duration: 800; easing.type: Easing.InOutSine } // Orb settles back to 100% slowly (800ms)
                }
                
                // 8. Refine Shockwave Dissipation (Asymmetrical decay: Fast rise, slow lingering fade) // Comment describing the shockwave animation profile
                SequentialAnimation {                                           // Sequential animation for shockwave effect
                    NumberAnimation { target: windowContent; property: "popShockwave"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic } // Shockwave rapidly rises to peak in 150ms (fast attack)
                    NumberAnimation { target: windowContent; property: "popShockwave"; to: 0.0; duration: 1200; easing.type: Easing.OutQuart } // Shockwave slowly dissipates over 1.2 seconds (long decay)
                }

                NumberAnimation { target: orbGlow; property: "baseOpacity"; to: 1.0; duration: 400; easing.type: Easing.InOutSine } // Glow aura fades in over 400ms
                NumberAnimation { target: orbGlow; property: "baseScale"; to: 1.0; duration: 600; easing.type: Easing.OutBack } // Glow aura scales to full size with back easing (slight overshoot) over 600ms
            }

            // Phase 4: Settle into Calm Idle State                                // Comment describing the final phase: settling into calm breathing state
            NumberAnimation {                                                   // Animation transitioning to calm state
                target: windowContent                                            // Targets the windowContent item
                property: "calmState"                                            // Animates the calmState property
                from: 0.0                                                       // From 0 (just activated)
                to: 1.0                                                         // To 1 (fully calm/settled)
                duration: 2500                                                  // Over 2.5 seconds
                easing.type: Easing.InOutSine                                   // Smooth sine easing for organic transition
            }
        }
    }
}