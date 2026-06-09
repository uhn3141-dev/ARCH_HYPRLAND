import "../../" as Root
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PopupWindow {
    id: musicPopup

    // ─── Accent Colors (replace with your theme’s accents if desired) ───
    readonly property color mauve: "#cba6f7"
    readonly property color pink: "#f38ba8"
    readonly property color blue: "#89b4fa"
    readonly property color lavender: "#b4befe"
    readonly property color red: "#f38ba8"
    readonly property color yellow: "#f9e2af"
    // ─── Data ───
    property var musicData: ({
        "title": "Not Playing",
        "artist": "",
        "status": "Stopped",
        "percent": 0,
        "lengthStr": "00:00",
        "positionStr": "00:00",
        "timeStr": "--:-- / --:--",
        "source": "Offline",
        "playerName": "",
        "blur": "",
        "grad": "",
        "textColor": "#cdd6f4",
        "deviceIcon": "󰓃",
        "deviceName": "Speaker",
        "artUrl": ""
    })
    property var eqData: ({
        "b1": 0,
        "b2": 0,
        "b3": 0,
        "b4": 0,
        "b5": 0,
        "b6": 0,
        "b7": 0,
        "b8": 0,
        "b9": 0,
        "b10": 0,
        "preset": "Flat",
        "pending": false
    })
    property bool userIsSeeking: false
    property bool userToggledPlay: false
    property real lastEqUpdate: 0
    // Animation states
    property real catppuccinFlowOffset: 0
    property real globalOrbitAngle: 0
    // EQ Lightning
    property real eqLightningProgress: 0
    property real eqLightningFade: 1
    // Entry animations
    property real introMain: 0
    property real introCover: 0
    property real introText: 0
    property real introControls: 0
    property real introSeparator: 0
    property real introEqHeader: 0
    property real introEqSliders: 0
    property real introPresets: 0

    function triggerEqLightning() {
        eqLightningAnim.restart();
    }

    // ─── Helper ───
    function execCmd(cmdStr) {
        var safeCmd = cmdStr.replace(/`/g, "\\`");
        var p = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["bash", "-c", \`${safeCmd}\`]
                running: true
                onExited: (exitCode) => destroy()
            }
        `, musicPopup);
    }

    function applyPreset(presetName) {
        var presets = {
            "Flat": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            "Bass": [5, 7, 5, 2, 1, 0, 0, 0, 1, 2],
            "Treble": [-2, -1, 0, 1, 2, 3, 4, 5, 6, 6],
            "Vocal": [-2, -1, 1, 3, 5, 5, 4, 2, 1, 0],
            "Pop": [2, 4, 2, 0, 1, 2, 4, 2, 1, 2],
            "Rock": [5, 4, 2, -1, -2, -1, 2, 4, 5, 6],
            "Jazz": [3, 3, 1, 1, 1, 1, 2, 1, 2, 3],
            "Classic": [0, 1, 2, 2, 2, 2, 1, 2, 3, 4]
        };
        if (presets[presetName]) {
            var temp = Object.assign({
            }, eqData);
            for (var i = 0; i < 10; i++) temp["b" + (i + 1)] = presets[presetName][i]
            temp.preset = presetName;
            temp.pending = false;
            eqData = temp;
            lastEqUpdate = Date.now();
            triggerEqLightning();
            execCmd(`bash ${_HOMEDIR}/.config/quickshell/popups/Music/equalizer.sh preset ${presetName}`);
        }
    }

    anchor.window: root
    anchor.rect.x: root.width / 2 - width / 2
    anchor.rect.y: 31
    implicitWidth: 320
    implicitHeight: 520
    color: 'transparent'
    visible: false

    // Theme & Config (same pattern as your other panels)
    Root.Theme {
        id: theme
    }

    Root.Config {
        id: config
    }

    SequentialAnimation {
        id: eqLightningAnim

        running: false

        ScriptAction {
            script: {
                eqLightningFade = 0;
                eqLightningProgress = 0;
            }
        }

        NumberAnimation {
            target: musicPopup
            property: "eqLightningProgress"
            from: 0
            to: 10
            duration: 650
            easing.type: Easing.OutSine
        }

        PauseAnimation {
            duration: 150
        }

        NumberAnimation {
            target: musicPopup
            property: "eqLightningFade"
            from: 0
            to: 1
            duration: 800
            easing.type: Easing.OutQuad
        }

        ScriptAction {
            script: {
                eqLightningProgress = 0;
            }
        }

    }

    ParallelAnimation {
        running: true

        NumberAnimation {
            target: musicPopup
            property: "introMain"
            from: 0
            to: 1
            duration: 760
            easing.type: Easing.OutQuart
        }

        SequentialAnimation {
            PauseAnimation {
                duration: 70
            }

            NumberAnimation {
                target: musicPopup
                property: "introCover"
                from: 0
                to: 1
                duration: 810
                easing.type: Easing.OutBack
                easing.overshoot: 1
            }

        }

        SequentialAnimation {
            PauseAnimation {
                duration: 150
            }

            NumberAnimation {
                target: musicPopup
                property: "introText"
                from: 0
                to: 1
                duration: 760
                easing.type: Easing.OutQuart
            }

        }

        SequentialAnimation {
            PauseAnimation {
                duration: 230
            }

            NumberAnimation {
                target: musicPopup
                property: "introControls"
                from: 0
                to: 1
                duration: 760
                easing.type: Easing.OutBack
                easing.overshoot: 0.8
            }

        }

        SequentialAnimation {
            PauseAnimation {
                duration: 310
            }

            NumberAnimation {
                target: musicPopup
                property: "introSeparator"
                from: 0
                to: 1
                duration: 660
                easing.type: Easing.OutQuart
            }

        }

        SequentialAnimation {
            PauseAnimation {
                duration: 370
            }

            NumberAnimation {
                target: musicPopup
                property: "introEqHeader"
                from: 0
                to: 1
                duration: 710
                easing.type: Easing.OutQuart
            }

        }

        SequentialAnimation {
            PauseAnimation {
                duration: 430
            }

            NumberAnimation {
                target: musicPopup
                property: "introEqSliders"
                from: 0
                to: 1
                duration: 860
                easing.type: Easing.OutExpo
            }

        }

        SequentialAnimation {
            PauseAnimation {
                duration: 550
            }

            NumberAnimation {
                target: musicPopup
                property: "introPresets"
                from: 0
                to: 1
                duration: 810
                easing.type: Easing.OutBack
                easing.overshoot: 0.8
            }

        }

    }

    // ─── Polling ───
    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!musicProc.running)
                musicProc.running = true;

            if (!eqProc.running)
                eqProc.running = true;

        }
    }

    Process {
        id: musicProc

        running: false
        command: ["bash", _HOMEDIR + "/.config/quickshell/popups/Music/music_info.sh"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var newData = JSON.parse(text.trim());
                    if (userToggledPlay)
                        newData.status = musicData.status;

                    musicData = newData;
                } catch (e) {
                }
            }
        }

    }

    Process {
        id: eqProc

        running: false
        command: ["bash", _HOMEDIR + "/.config/quickshell/popups/Music/equalizer.sh", "get"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (Date.now() - lastEqUpdate < 2000)
                    return ;

                try {
                    eqData = JSON.parse(text.trim());
                } catch (e) {
                }
            }
        }

    }

    // ─── UI ───
    Rectangle {
        id: panelBg

        anchors.fill: parent
        color: theme.colSurface
        radius: 20
        border.width: 3
        border.color: theme.colSurface
        opacity: introMain
        scale: 0.92 + (0.08 * introMain)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ─── Cover Art + Info ───
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 140
                spacing: 15

                // Cover
                Rectangle {
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 120
                    radius: 60
                    color: theme.colSecondary
                    border.width: 4
                    border.color: musicData.status === "Playing" ? mauve : theme.colSurfaceVariant

                    Image {
                        anchors.fill: parent
                        anchors.margins: 4
                        source: musicData.artUrl ? "file://" + musicData.artUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: width / 2
                        color: mauve
                        opacity: 0.15
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 500
                        }

                    }

                }

                // Title, Artist, Progress
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Title (marquee simplified – single line elide)
                    Text {
                        Layout.fillWidth: true
                        text: musicData.title || "Not Playing"
                        color: theme.colOnSurface
                        font.pixelSize: config.fontSize * 1.4
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        text: musicData.artist ? "by " + musicData.artist : ""
                        color: theme.colOnSurfaceVariant
                        font.pixelSize: config.fontSize * 0.9
                    }
                    // Progress bar

                    Rectangle {
                        Layout.fillWidth: true
                        height: 12
                        radius: 6
                        color: theme.colSurfaceVariant

                        Rectangle {
                            height: parent.height
                            width: parent.width * (musicData.percent / 100)
                            radius: 6
                            color: mauve

                            Behavior on width {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.OutSine
                                }

                            }

                        }

                    }

                    RowLayout {
                        Text {
                            text: musicData.positionStr
                            color: theme.colOnSurfaceVariant
                            font.pixelSize: config.fontSize * 0.7
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: musicData.lengthStr
                            color: theme.colOnSurfaceVariant
                            font.pixelSize: config.fontSize * 0.7
                        }

                    }

                }

            }

            // ─── Media Controls ───
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 25

                Rectangle {
                    width: 30
                    height: 30
                    radius: 15
                    color: theme.colSecondary

                    Text {
                        anchors.centerIn: parent
                        text: "⏮"
                        color: theme.colOnSecondary
                        font.pixelSize: config.fontSize * 1.2
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: execCmd("playerctl previous")
                    }

                }

                Rectangle {
                    width: 50
                    height: 50
                    radius: 25
                    color: mauve

                    Text {
                        anchors.centerIn: parent
                        text: musicData.status === "Playing" ? "⏸" : "▶"
                        color: "#fff"
                        font.pixelSize: config.fontSize * 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            userToggledPlay = true;
                            var temp = Object.assign({
                            }, musicData);
                            temp.status = temp.status === "Playing" ? "Paused" : "Playing";
                            musicData = temp;
                            execCmd("playerctl play-pause");
                        }
                    }

                }

                Rectangle {
                    width: 30
                    height: 30
                    radius: 15
                    color: theme.colSecondary

                    Text {
                        anchors.centerIn: parent
                        text: "⏭"
                        color: theme.colOnSecondary
                        font.pixelSize: config.fontSize * 1.2
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: execCmd("playerctl next")
                    }

                }

            }

            // ─── Separator ───
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: theme.colSurfaceVariant
                opacity: 0.3
            }

            // ─── Equalizer Header ───
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Equalizer"
                    color: mauve
                    font.pixelSize: config.fontSize * 1.1
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                Rectangle {
                    height: 24
                    width: applyTxt.implicitWidth + 20
                    radius: 12
                    color: eqData.pending ? mauve : theme.colSecondary

                    Text {
                        id: applyTxt

                        anchors.centerIn: parent
                        text: eqData.pending ? "Apply" : "Saved"
                        color: eqData.pending ? "#fff" : theme.colOnSecondary
                        font.pixelSize: config.fontSize * 0.7
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (eqData.pending) {
                                var temp = Object.assign({
                                }, eqData);
                                temp.pending = false;
                                eqData = temp;
                                lastEqUpdate = Date.now();
                                triggerEqLightning();
                                execCmd(`bash ${_HOMEDIR}/.config/quickshell/popups/Music/equalizer.sh apply`);
                            }
                        }
                    }

                }

            }

            // ─── EQ Sliders (10 bands) ───
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                spacing: 0

                Repeater {
                    model: 10

                    delegate: Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Rectangle {
                                Layout.fillWidth: true
                                height: 80
                                radius: 4
                                color: theme.colSurfaceVariant

                                // Slider
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: parent.height * ((eqData["b" + (index + 1)] + 12) / 24)
                                    radius: 4
                                    color: index % 2 === 0 ? mauve : pink

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: 350
                                            easing.type: Easing.OutQuart
                                        }

                                    }

                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onPositionChanged: (mouse) => {
                                        if (pressed) {
                                            var newVal = Math.round(12 - (mouse.y / height) * 24);
                                            newVal = Math.max(-12, Math.min(12, newVal));
                                            var temp = Object.assign({
                                            }, eqData);
                                            temp["b" + (index + 1)] = newVal;
                                            temp.preset = "Custom";
                                            temp.pending = true;
                                            eqData = temp;
                                            lastEqUpdate = Date.now();
                                            execCmd(`bash ${_HOMEDIR}/.config/quickshell/popups/Music/equalizer.sh set_band ${index+1} ${newVal}`);
                                        }
                                    }
                                }

                            }

                            Text {
                                text: ["31", "63", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"][index]
                                color: theme.colOnSurfaceVariant
                                font.pixelSize: config.fontSize * 0.6
                                Layout.alignment: Qt.AlignHCenter
                            }

                        }

                    }

                }

            }

            // ─── Presets ───
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 6
                columnSpacing: 6

                Repeater {
                    model: ["Flat", "Bass", "Treble", "Vocal", "Pop", "Rock", "Jazz", "Classic"]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: 8
                        color: eqData.preset === modelData ? mauve : theme.colSecondary

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: eqData.preset === modelData ? "#fff" : theme.colOnSecondary
                            font.pixelSize: config.fontSize * 0.7
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: applyPreset(modelData)
                        }

                    }

                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutBack
            }

        }

    }

    NumberAnimation on catppuccinFlowOffset {
        from: 0
        to: 1
        duration: 8000
        loops: Animation.Infinite
        running: true
    }

    NumberAnimation on globalOrbitAngle {
        from: 0
        to: Math.PI * 2
        duration: 90000
        loops: Animation.Infinite
        running: true
    }

}
