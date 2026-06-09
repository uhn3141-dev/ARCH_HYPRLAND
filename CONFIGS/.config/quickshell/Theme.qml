import QtQuick
import Quickshell
import Quickshell.Io

Item {
    // Base16 colors
    // property var base16: ({})

    id: root

    // MD3 Colors
    property color colPrimary: '#ffb2bf'
    property color colOnPrimary: "#561d2b"
    property color colPrimaryContainer: "#713341"
    property color colOnPrimaryContainer: "#ffd9de"
    property color colPrimaryFixed: "#ffd9de"
    property color colPrimaryFixedDim: "#ffb2bf"
    property color colOnPrimaryFixed: "#3a0716"
    property color colOnPrimaryFixedVarient: "#713341"
    property color colInversePrimary: "#8e4958"
    property color colSecondary: "#e4bdc2"
    property color colOnSecondary: "#43292e"
    property color colSecondaryContainer: "#5c3f44"
    property color colOnSecondaryContainer: "#ffd9de"
    property color colSecondaryFixed: "#ffd9de"
    property color colSecondaryFixedDim: "#e4bdc2"
    property color colOnSecondaryFixed: "#2c1519"
    property color colOnSecondaryFixedVariant: "#5c3f44"
    property color colTertiary: "#ebbe90"
    property color colTertiaryContainer: "#5f401d"
    property color colOnTertiary: "#452a08"
    property color colOnTertiaryContainer: "#ffddbb"
    property color colTertiaryFixed: "#ffddbb"
    property color colTertiaryFixedDim: "#ebbe90"
    property color colOnTertiaryFixed: "#2b1700"
    property color colOnTertiaryFixedVariant: "#5f401d"
    property color colBackground: "#191112"
    property color colOnBackground: "#f0dee0"
    property color colSurface: "#191112"
    property color colSurfaceVariant: "#524345"
    property color colOnSurface: "#f0dee0"
    property color colOnSurfaceVariant: "#d6c2c4"
    property color colInverseSurface: "#f0dee0"
    property color colInverseOnSurface: "#382e2f"
    property color colSurfaceDim: "#191112"
    property color colSurfaceBright: "#413738"
    property color colSurfaceContainerLowest: "#140c0d"
    property color colSurfaceContainerLow: "#22191b"
    property color colSurfaceContainer: "#261d1f"
    property color colSurfaceContainerHigh: "#312829"
    property color colSurfaceContainerHighest: "#3c3234"
    property color colSurfaceTint: "#ffb2bf"
    property color colOutline: "#9f8c8e"
    property color colOutlineVariant: "#524345"
    property color colError: "#ffb4ab"
    property color colOnError: "#690005"
    property color colErrorContainer: "#93000a"
    property color colOnErrorContainer: "#ffdad6"
    property color colScrim: "#000000"
    property color colShadow: "#000000"
    property color colSourceColor: "#f96388"
    property string rawJson: ""

    Process {
        id: themeReader

        command: ["cat", Quickshell.env("HOME") + "/.config/quickshell/colors.json"]

        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "" && txt !== root.rawJson) {
                    //console.log("Theme updated successfully! Primary:", root.colPrimary);
                    // Load base16 colors if present
                    // if (c.base16) {
                    //     root.base16 = {}
                    //     for (let key in c.base16) {
                    //         root.base16[key] = c.base16[key];
                    //     }
                    // }

                    root.rawJson = txt;
                    try {
                        let c = JSON.parse(txt);
                        if (c.md3) {
                            if (c.md3.primary)
                                root.colPrimary = c.md3.primary;

                            if (c.md3.on_primary)
                                root.colOnPrimary = c.md3.on_primary;

                            if (c.md3.primary_container)
                                root.colPrimaryContainer = c.md3.primary_container;

                            if (c.md3.on_primary_container)
                                root.colOnPrimaryContainer = c.md3.on_primary_container;

                            if (c.md3.primary_fixed)
                                root.colPrimaryFixed = c.md3.primary_fixed;

                            if (c.md3.primary_fixed_dim)
                                root.colPrimaryFixedDim = c.md3.primary_fixed_dim;

                            if (c.md3.on_primary_fixed)
                                root.colOnPrimaryFixed = c.md3.on_primary_fixed;

                            if (c.md3.on_primary_fixed_variant)
                                root.colOnPrimaryFixedVarient = c.md3.on_primary_fixed_variant;

                            if (c.md3.inverse_primary)
                                root.colInversePrimary = c.md3.inverse_primary;

                            if (c.md3.secondary)
                                root.colSecondary = c.md3.secondary;

                            if (c.md3.on_secondary)
                                root.colOnSecondary = c.md3.on_secondary;

                            if (c.md3.secondary_container)
                                root.colSecondaryContainer = c.md3.secondary_container;

                            if (c.md3.on_secondary_container)
                                root.colOnSecondaryContainer = c.md3.on_secondary_container;

                            if (c.md3.secondary_fixed)
                                root.colSecondaryFixed = c.md3.secondary_fixed;

                            if (c.md3.secondary_fixed_dim)
                                root.colSecondaryFixedDim = c.md3.secondary_fixed_dim;

                            if (c.md3.on_secondary_fixed)
                                root.colOnSecondaryFixed = c.md3.on_secondary_fixed;

                            if (c.md3.on_secondary_fixed_variant)
                                root.colOnSecondaryFixedVariant = c.md3.on_secondary_fixed_variant;

                            if (c.md3.tertiary)
                                root.colTertiary = c.md3.tertiary;

                            if (c.md3.on_tertiary)
                                root.colOnTertiary = c.md3.on_tertiary;

                            if (c.md3.tertiary_container)
                                root.colTertiaryContainer = c.md3.tertiary_container;

                            if (c.md3.on_tertiary_container)
                                root.colOnTertiaryContainer = c.md3.on_tertiary_container;

                            if (c.md3.tertiary_fixed)
                                root.colTertiaryFixed = c.md3.tertiary_fixed;

                            if (c.md3.tertiary_fixed_dim)
                                root.colTertiaryFixedDim = c.md3.tertiary_fixed_dim;

                            if (c.md3.on_tertiary_fixed)
                                root.colOnTertiaryFixed = c.md3.on_tertiary_fixed;

                            if (c.md3.on_tertiary_fixed_variant)
                                root.colOnTertiaryFixedVariant = c.md3.on_tertiary_fixed_variant;

                            if (c.md3.background)
                                root.colBackground = c.md3.background;

                            if (c.md3.on_background)
                                root.colOnBackground = c.md3.on_background;

                            if (c.md3.surface)
                                root.colSurface = c.md3.surface;

                            if (c.md3.on_surface)
                                root.colOnSurface = c.md3.on_surface;

                            if (c.md3.surface_variant)
                                root.colSurfaceVariant = c.md3.surface_variant;

                            if (c.md3.on_surface_variant)
                                root.colOnSurfaceVariant = c.md3.on_surface_variant;

                            if (c.md3.inverse_surface)
                                root.colInverseSurface = c.md3.inverse_surface;

                            if (c.md3.inverse_on_surface)
                                root.colInverseOnSurface = c.md3.inverse_on_surface;

                            if (c.md3.surface_dim)
                                root.colSurfaceDim = c.md3.surface_dim;

                            if (c.md3.surface_bright)
                                root.colSurfaceBright = c.md3.surface_bright;

                            if (c.md3.surface_container_lowest)
                                root.colSurfaceContainerLowest = c.md3.surface_container_lowest;

                            if (c.md3.surface_container_low)
                                root.colSurfaceContainerLow = c.md3.surface_container_low;

                            if (c.md3.surface_container)
                                root.colSurfaceContainer = c.md3.surface_container;

                            if (c.md3.surface_container_high)
                                root.colSurfaceContainerHigh = c.md3.surface_container_high;

                            if (c.md3.surface_container_highest)
                                root.colSurfaceContainerHighest = c.md3.surface_container_highest;

                            if (c.md3.surface_tint)
                                root.colSurfaceTint = c.md3.surface_tint;

                            if (c.md3.outline)
                                root.colOutline = c.md3.outline;

                            if (c.md3.outline_variant)
                                root.colOutlineVariant = c.md3.outline_variant;

                            if (c.md3.error)
                                root.colError = c.md3.error;

                            if (c.md3.on_error)
                                root.colOnError = c.md3.on_error;

                            if (c.md3.error_container)
                                root.colErrorContainer = c.md3.error_container;

                            if (c.md3.on_error_container)
                                root.colOnErrorContainer = c.md3.on_error_container;

                            if (c.md3.scrim)
                                root.colScrim = c.md3.scrim;

                            if (c.md3.shadow)
                                root.colShadow = c.md3.shadow;

                            if (c.md3.source_color)
                                root.colSourceColor = c.md3.source_color;

                        }
                    } catch (e) {
                        console.log("Error parsing JSON:", e);
                    }
                }
            }
        }

    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            themeReader.running = true;
        }
    }

}
