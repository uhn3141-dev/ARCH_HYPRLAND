// .pragma library

// function getScale(mw, mh, userScale) {
//     if (arguments.length === 2) {
//         userScale = mh;
//         mh = mw * (1080.0 / 1920.0);
//     }

//     if (mw <= 0 || mh <= 0) return 1.0;
    
//     let rw = mw / 1920.0;
//     let rh = mh / 1080.0;
//     let r = Math.min(rw, rh);
    
//     let baseScale = 1.0;
    
//     if (r <= 1.0) {
//         baseScale = Math.max(0.35, Math.pow(r, 0.85));
//     } else {
//         baseScale = Math.pow(r, 0.5);
//     }
    
//     return baseScale * (userScale !== undefined ? userScale : 1.0);
// }

// function s(val, scale) {
//     return Math.round(val * scale);
// }

// function getLayout(name, mx, my, mw, mh, userScale) {
//     let scale = getScale(mw, mh, userScale);

//     let base = {
//         // --- Top Right Popups ---
//         "battery":   { w: s(801, scale), h: s(760, scale), rx: mw - s(805, scale), ry: s(60, scale), comp: "battery/BatteryPopup.qml" },
//         "network":   { w: s(900, scale), h: s(700, scale), rx: mw - s(904, scale), ry: s(60, scale), comp: "network/NetworkPopup.qml" },
//         "volume":    { w: s(450, scale), h: s(700, scale), rx: mw - s(455, scale), ry: s(60, scale), comp: "volume/VolumePopup.qml" },
        
//         // --- Central Standard Tools ---
//         "applauncher": { w: s(800, scale), h: s(700, scale), rx: Math.floor((mw/2)-(s(800, scale)/2)), ry: Math.floor((mh/2)-(s(700, scale)/2)), comp: "applauncher/appLauncher.qml" },
//         "clipboard": { w: s(800, scale), h: s(700, scale), rx: Math.floor((mw/2)-(s(800, scale)/2)), ry: Math.floor((mh/2)-(s(700, scale)/2)), comp: "clipboard/ClipboardManager.qml" },
//         "monitors":  { w: s(800, scale), h: s(650, scale), rx: Math.floor((mw/2)-(s(800, scale)/2)), ry: Math.floor((mh/2)-(s(650, scale)/2)), comp: "monitors/MonitorPopup.qml" },
//         "stewart":   { w: s(800, scale), h: s(650, scale), rx: Math.floor((mw/2)-(s(800, scale)/2)), ry: Math.floor((mh/2)-(s(650, scale)/2)), comp: "stewart/stewart.qml" },

//         // --- Central Large Tools ---
//         "focustime": { w: s(900, scale), h: s(700, scale), rx: Math.floor((mw/2)-(s(900, scale)/2)), ry: Math.floor((mh/2)-(s(700, scale)/2)), comp: "focustime/FocusTimePopup.qml" },

//         // --- Extralarge / Custom Centered ---
//         "guide":     { w: s(1200, scale), h: s(750, scale), rx: Math.floor((mw/2)-(s(1200, scale)/2)), ry: Math.floor((mh/2)-(s(750, scale)/2)), comp: "guide/GuidePopup.qml" },
//         "calendar":  { w: s(1450, scale), h: s(750, scale), rx: Math.floor((mw/2)-(s(1450, scale)/2)), ry: s(60, scale), comp: "calendar/CalendarPopup.qml" },
//         "updater":   { w: s(500, scale),  h: s(600, scale), rx: Math.floor((mw/2)-(s(500, scale)/2)), ry: Math.floor((mh/2)-(s(600, scale)/2)), comp: "updater/UpdaterPopup.qml" },
//         "wallpaper": { w: mw, h: s(650, scale), rx: 0, ry: Math.floor((mh/2)-(s(650, scale)/2)), comp: "wallpaper/WallpaperPicker.qml" },
        
//         // --- Top Left Edge ---
//         "music":     { w: s(700, scale), h: s(650, scale), rx: s(5, scale), ry: s(60, scale), comp: "music/MusicPopup.qml" },

//         "movies": {
//             w: s(1370, scale),
//             h: s(850, scale),
//             rx: Math.floor((mw / 2) - (s(1370, scale) / 2)),
//             ry: mh - s(850, scale),
//             comp: "movies/MovieWidget.qml"
//         },
        
//         // --- Screen Spanning Panels ---
//         "settings":  { w: s(450, scale), h: mh - s(0, scale), rx: s(0, scale), ry: s(0, scale), comp: "settings/SettingsPopup.qml" },
        
//         // --- Utility ---
//         "hidden":    { w: 1, h: 1, rx: -5000 - mx, ry: -5000 - my, comp: "" } 
//     };

//     if (!base[name]) return null;
    
//     let t = base[name];
//     t.x = mx + t.rx;
//     t.y = my + t.ry;
    
//     return t;
// }

// function getPopupLayout(mw, mh, userScale) {
//     if (arguments.length === 2) {
//         userScale = mh;
//         mh = mw * (1080.0 / 1920.0);
//     }
    
//     let scale = getScale(mw, mh, userScale);
//     return {
//         w: s(350, scale),
//         marginTop: s(60, scale),
//         marginRight: s(20, scale),
//         spacing: s(12, scale),
//         radius: s(14, scale),
//         padding: s(12, scale)
//     };
// }




.pragma library
// ^ Declares this file as a JavaScript library module in QML. This allows it to be imported by other QML files (e.g., `import "WindowRegistry.js" as Registry`) and its functions become available through the namespace. Unlike inline JavaScript, library files are shared across all imports rather than being duplicated per file.

function getScale(mw, mh, userScale) {
    // ^ Calculates a base scale factor for responsive UI sizing based on screen dimensions. Takes three parameters: mw (monitor width in pixels), mh (monitor height in pixels), and userScale (an additional user-defined scale multiplier, e.g., for high-DPI preferences). Returns a floating-point scale factor.

    if (arguments.length === 2) {
        // ^ If only two arguments were passed to the function (meaning userScale was omitted and the second argument is actually userScale, not height).

        userScale = mh;
        // ^ Treats the second argument as the userScale value instead of height.

        mh = mw * (1080.0 / 1920.0);
        // ^ Estimates the height based on the width assuming a 16:9 aspect ratio (1920/1080 = 16:9). For example, if width is 2560, height becomes 2560 * (1080/1920) = 1440. This provides a fallback when height isn't explicitly provided.
    }

    if (mw <= 0 || mh <= 0) return 1.0;
    // ^ Safety check: if either dimension is zero or negative (invalid screen data), returns 1.0 (100% scale, no scaling). Prevents division by zero errors and negative scale factors.
    
    let rw = mw / 1920.0;
    // ^ Calculates the width ratio: how much wider the current screen is compared to the 1080p reference resolution (1920px). A 3840px ultrawide would give rw = 2.0.

    let rh = mh / 1080.0;
    // ^ Calculates the height ratio: how much taller the current screen is compared to 1080px reference. A 2160px 4K display would give rh = 2.0.

    let r = Math.min(rw, rh);
    // ^ Takes the smaller of the two ratios. This ensures the UI scales uniformly based on the most constrained dimension, preventing elements from becoming too large on ultrawide displays or too small on tall displays. For a 2560x1080 ultrawide: rw=1.33, rh=1.0, so r=1.0 (no scaling).
    
    let baseScale = 1.0;
    // ^ Initializes the base scale to 1.0 (100%).
    
    if (r <= 1.0) {
        // ^ If the screen is at or below the reference resolution (1920x1080 or smaller).

        baseScale = Math.max(0.35, Math.pow(r, 0.85));
        // ^ Applies a power curve with an exponent of 0.85, which creates a gentle scaling reduction for smaller screens. The Math.max ensures the scale never drops below 0.35 (35%), preventing UI elements from becoming too tiny on very small screens like 720p laptops. For a 1366x768 screen: r≈0.71, pow(0.71, 0.85)≈0.75, so the UI scales to 75% of the design size.
    } else {
        // ^ If the screen is larger than the reference resolution (above 1080p).

        baseScale = Math.pow(r, 0.5);
        // ^ Applies a square root curve (exponent 0.5) for gentler growth on large displays. This prevents UI elements from becoming excessively large on 4K screens. For a 3840x2160 display: r=2.0, pow(2.0, 0.5)=1.41, so UI elements scale to 141% of design size rather than 200%.
    }
    
    return baseScale * (userScale !== undefined ? userScale : 1.0);
    // ^ Multiplies the calculated base scale by the user-defined scale factor. If no userScale was provided (undefined), defaults to 1.0 (no additional scaling). This allows users to set a global UI scale preference (e.g., 1.25 for 125%) that multiplies with the automatic screen-based scaling. The final result is the complete scale factor used for all UI element sizing.
}

function s(val, scale) {
    // ^ A convenience function that scales a design-time pixel value to a runtime pixel value. Takes two parameters: val (the base pixel value designed at 1920x1080) and scale (the calculated scale factor from getScale()). Returns an integer pixel value.

    return Math.round(val * scale);
    // ^ Multiplies the base value by the scale factor and rounds to the nearest integer. For example, s(48, 1.5) = Math.round(72.0) = 72. Rounding ensures pixel-perfect rendering without subpixel blurring.
}

function getLayout(name, mx, my, mw, mh, userScale) {
    // ^ The main layout function that returns position, size, and component information for a given widget. Takes six parameters: name (widget identifier string like "calendar" or "network"), mx (monitor/screen X offset for multi-monitor setups), my (monitor Y offset), mw (monitor width), mh (monitor height), and userScale (user-defined scale preference). Returns an object with w, h, rx, ry (relative position), x, y (absolute position), and comp (QML component path).

    let scale = getScale(mw, mh, userScale);
    // ^ Calculates the unified scale factor for this screen using the specified dimensions and user preference.

    let base = {
        // ^ Defines a dictionary object mapping widget names to their layout definitions. Each widget has relative position (rx, ry from monitor origin), size (w, h in scaled pixels), and a QML component file path.

        // --- Top Right Popups ---
        "battery":   { w: s(801, scale), h: s(760, scale), rx: mw - s(805, scale), ry: s(60, scale), comp: "battery/BatteryPopup.qml" },
        // ^ Battery widget: 801x760 pixels, positioned 4px from the right edge of the screen (mw - 805, leaving room for a 4px gap) and 60px from the top. Loads BatteryPopup.qml.

        "network":   { w: s(900, scale), h: s(700, scale), rx: mw - s(904, scale), ry: s(60, scale), comp: "network/NetworkPopup.qml" },
        // ^ Network widget: 900x700 pixels, 4px from the right edge (mw - 904), 60px from top. Slightly wider than battery for the network controls.

        "volume":    { w: s(450, scale), h: s(700, scale), rx: mw - s(455, scale), ry: s(60, scale), comp: "volume/VolumePopup.qml" },
        // ^ Volume widget: 450x700 pixels, 5px from the right edge (mw - 455), 60px from top. Narrower since volume controls don't need much horizontal space.
        
        // --- Central Standard Tools ---
        "applauncher": { w: s(800, scale), h: s(700, scale), rx: Math.floor((mw/2)-(s(800, scale)/2)), ry: Math.floor((mh/2)-(s(700, scale)/2)), comp: "applauncher/appLauncher.qml" },
        // ^ Application launcher: 800x700 pixels, perfectly centered both horizontally and vertically on the monitor. Math.floor ensures integer positioning for sharp rendering.

        "clipboard": { w: s(800, scale), h: s(700, scale), rx: Math.floor((mw/2)-(s(800, scale)/2)), ry: Math.floor((mh/2)-(s(700, scale)/2)), comp: "clipboard/ClipboardManager.qml" },
        // ^ Clipboard manager: same centered dimensions as the app launcher for visual consistency among central tools.

        "monitors":  { w: s(800, scale), h: s(650, scale), rx: Math.floor((mw/2)-(s(800, scale)/2)), ry: Math.floor((mh/2)-(s(650, scale)/2)), comp: "monitors/MonitorPopup.qml" },
        // ^ Monitor management: 800x650 pixels centered. Slightly shorter than the app launcher/clipboard.

        "stewart":   { w: s(800, scale), h: s(650, scale), rx: Math.floor((mw/2)-(s(800, scale)/2)), ry: Math.floor((mh/2)-(s(650, scale)/2)), comp: "stewart/stewart.qml" },
        // ^ Stewart widget (likely a system info or control panel): same dimensions as monitors for consistency.

        // --- Central Large Tools ---
        "focustime": { w: s(900, scale), h: s(700, scale), rx: Math.floor((mw/2)-(s(900, scale)/2)), ry: Math.floor((mh/2)-(s(700, scale)/2)), comp: "focustime/FocusTimePopup.qml" },
        // ^ Focus time/Pomodoro widget: 900x700 pixels, larger than standard tools, centered. Provides more space for timer displays and settings.

        // --- Extralarge / Custom Centered ---
        "guide":     { w: s(1200, scale), h: s(750, scale), rx: Math.floor((mw/2)-(s(1200, scale)/2)), ry: Math.floor((mh/2)-(s(750, scale)/2)), comp: "guide/GuidePopup.qml" },
        // ^ Guide/help overlay: 1200x750 pixels, the largest centered popup. Substantial size needed for documentation and preview images.

        "calendar":  { w: s(1450, scale), h: s(750, scale), rx: Math.floor((mw/2)-(s(1450, scale)/2)), ry: s(60, scale), comp: "calendar/CalendarPopup.qml" },
        // ^ Calendar widget: 1450x750 pixels, the widest widget. Centered horizontally but positioned 60px from the top rather than vertically centered, giving it a top-docked panel feel while maintaining horizontal centering.

        "updater":   { w: s(500, scale),  h: s(600, scale), rx: Math.floor((mw/2)-(s(500, scale)/2)), ry: Math.floor((mh/2)-(s(600, scale)/2)), comp: "updater/UpdaterPopup.qml" },
        // ^ System updater: 500x600 pixels, centered. Compact size for a focused update dialog with progress information.

        "wallpaper": { w: mw, h: s(650, scale), rx: 0, ry: Math.floor((mh/2)-(s(650, scale)/2)), comp: "wallpaper/WallpaperPicker.qml" },
        // ^ Wallpaper picker: spans the full monitor width (mw), 650px tall, vertically centered. The full-width layout accommodates rows of wallpaper thumbnails.

        // --- Top Left Edge ---
        "music":     { w: s(700, scale), h: s(650, scale), rx: s(5, scale), ry: s(60, scale), comp: "music/MusicPopup.qml" },
        // ^ Music player widget: 700x650 pixels, positioned 5px from the left edge and 60px from the top. Mirrors the top-right popup positioning but on the left side.

        "movies": {
            // ^ Movie widget (likely for searching/displaying movie information).

            w: s(1370, scale),
            // ^ Width of 1370 pixels scaled—very wide, nearly full screen on 1080p.

            h: s(850, scale),
            // ^ Height of 850 pixels scaled—tall to display movie posters and details.

            rx: Math.floor((mw / 2) - (s(1370, scale) / 2)),
            // ^ Horizontally centered on the monitor.

            ry: mh - s(850, scale),
            // ^ Anchored to the bottom of the screen (monitor height minus widget height = 0 from bottom).

            comp: "movies/MovieWidget.qml"
            // ^ Loads the MovieWidget QML component.
        },
        
        // --- Screen Spanning Panels ---
        "settings":  { w: s(450, scale), h: mh - s(0, scale), rx: s(0, scale), ry: s(0, scale), comp: "settings/SettingsPopup.qml" },
        // ^ Settings panel: 450px wide, spans the full screen height (mh - 0). Positioned at the very left edge (rx=0) and very top (ry=0). This creates a left sidebar panel that fills the entire vertical space, typical for settings interfaces.

        // --- Utility ---
        "hidden":    { w: 1, h: 1, rx: -5000 - mx, ry: -5000 - my, comp: "" } 
        // ^ Hidden/widget state: a tiny 1x1 pixel element positioned far off-screen (-5000px both horizontally and vertically, offset by the monitor position to account for multi-monitor). The empty comp string means no component is loaded. This is the "closed" state used when no widget is active, effectively hiding the overlay by collapsing it to a single invisible pixel far outside the visible area.
    };

    if (!base[name]) return null;
    // ^ If the requested widget name doesn't exist in the base dictionary, returns null. The calling code in Main.qml checks for null to determine if a widget name is valid.

    let t = base[name];
    // ^ Retrieves the layout object for the requested widget from the base dictionary.

    t.x = mx + t.rx;
    // ^ Calculates the absolute X position by adding the monitor's X offset (mx) to the relative X position (rx). Essential for multi-monitor setups where the second monitor might start at x=1920 or higher.

    t.y = my + t.ry;
    // ^ Calculates the absolute Y position by adding the monitor's Y offset (my) to the relative Y position (ry). Handles multi-monitor layouts where monitors may be stacked vertically.

    return t;
    // ^ Returns the complete layout object containing w, h, rx, ry, x, y (both relative and absolute positions), and comp (component path). The calling code uses these values to position, size, and load the widget.
}

function getPopupLayout(mw, mh, userScale) {
    // ^ Returns a standardized layout configuration for notification popups. Takes monitor width, height, and user scale. Unlike getLayout which returns widget-specific layouts, this returns a uniform popup layout config.

    if (arguments.length === 2) {
        // ^ Handles the case where userScale is omitted (only width and height provided, but the second argument is actually userScale).

        userScale = mh;
        // ^ Treats the second argument as userScale.

        mh = mw * (1080.0 / 1920.0);
        // ^ Estimates height from width assuming 16:9 aspect ratio.
    }
    
    let scale = getScale(mw, mh, userScale);
    // ^ Calculates the scale factor for this screen.

    return {
        // ^ Returns an object with standardized popup dimensions and spacing values.

        w: s(350, scale),
        // ^ Fixed width of 350 scaled pixels for notification popup cards, providing a consistent readable width.

        marginTop: s(60, scale),
        // ^ Top margin of 60 scaled pixels, giving clearance from the top bar so notifications don't overlap the panel.

        marginRight: s(20, scale),
        // ^ Right margin of 20 scaled pixels, keeping popups away from the right screen edge with comfortable padding.

        spacing: s(12, scale),
        // ^ Vertical spacing of 12 scaled pixels between stacked notification popups, preventing visual crowding.

        radius: s(14, scale),
        // ^ Corner radius of 14 scaled pixels for the popup cards, matching the design language of other rounded UI elements.

        padding: s(12, scale)
        // ^ Internal padding of 12 scaled pixels within each popup card, ensuring content has breathing room from the card edges.
    };
}