import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

PopupWindow {
    id: soundPopup

    // === State ===
    property string activeTab: "outputs"
    property string activeId: ""
    property string activeName: "No Device"
    property string activeDesc: ""
    property int activeVol: 0
    property bool volumeBoost: false
    property bool activeMute: false
    property string activeIcon: "󰓃"
    property bool draggingMaster: false
    property bool heroExpanded: false
    property int balance: 0
    property string sampleRate: ""
    property string audioProfile: ""
    property int leftChannelVol: 100
    property int rightChannelVol: 100
    property bool monoMode: false
    property int savedLeftVol: 100
    property int savedRightVol: 100
    readonly property color tabColor: {
        if (activeTab === "outputs")
            return "#2196F3";

        if (activeTab === "inputs")
            return "#9C27B0";

        return "#4CAF50";
    }
    // === Entry Animations ===
    property real introHero: 0
    property real introTabs: 0
    property real introList: 0
    property var draggingNodes: ({
    })

    function syncModel(listModel, dataArray) {
        function isExternal(desc, name) {
            if (desc.indexOf("headset") !== -1)
                return true;

            if (desc.indexOf("headphone") !== -1)
                return true;

            if (desc.indexOf("buds") !== -1)
                return true;

            if (desc.indexOf("pods") !== -1)
                return true;

            if (desc.indexOf("bluetooth") !== -1)
                return true;

            if (desc.indexOf("usb") !== -1)
                return true;

            if (name.indexOf("bluez") !== -1)
                return true;

            return false;
        }

        dataArray.sort(function(a, b) {
            var descA = (a.description || "").toLowerCase();
            var descB = (b.description || "").toLowerCase();
            var nameA = (a.name || "").toLowerCase();
            var nameB = (b.name || "").toLowerCase();
            var extA = isExternal(descA, nameA);
            var extB = isExternal(descB, nameB);
            if (extA && !extB)
                return -1;

            if (!extA && extB)
                return 1;

            if (a.mute && !b.mute)
                return 1;

            if (!a.mute && b.mute)
                return -1;

            return b.volume - a.volume;
        });
        for (let i = listModel.count - 1; i >= 0; i--) {
            let id = listModel.get(i).id;
            let found = false;
            for (let j = 0; j < dataArray.length; j++) {
                if (id === dataArray[j].id) {
                    found = true;
                    break;
                }
            }
            if (!found)
                listModel.remove(i);

        }
        for (let i = 0; i < dataArray.length; i++) {
            let d = dataArray[i];
            let foundIdx = -1;
            for (let j = i; j < listModel.count; j++) {
                if (listModel.get(j).id === d.id) {
                    foundIdx = j;
                    break;
                }
            }
            let obj = {
                "id": d.id,
                "name": d.name,
                "description": d.description,
                "volume": d.volume,
                "mute": d.mute,
                "is_default": d.is_default,
                "icon": d.icon
            };
            if (foundIdx === -1) {
                listModel.insert(i, obj);
            } else {
                if (foundIdx !== i)
                    listModel.move(foundIdx, i, 1);

                for (let key in obj) {
                    if (key === "volume" && draggingNodes[obj.id])
                        continue;

                    if (listModel.get(i)[key] !== obj[key])
                        listModel.setProperty(i, key, obj[key]);

                }
            }
        }
    }

    function updateHero() {
        let targetModel = (activeTab === "inputs") ? inputsModel : outputsModel;
        for (let i = 0; i < targetModel.count; i++) {
            let d = targetModel.get(i);
            if (d.is_default) {
                activeId = d.id;
                activeName = d.description;
                activeDesc = d.name;
                activeIcon = d.icon;
                if (!draggingMaster) {
                    activeVol = d.volume;
                    activeMute = d.mute;
                    leftChannelVol = d.volume;
                    rightChannelVol = d.volume;
                }
                if (d.name.indexOf("bluez") !== -1)
                    getAudioProfile(d.name);

                return ;
            }
        }
        if (targetModel.count > 0) {
            let d = targetModel.get(0);
            activeId = d.id;
            activeName = d.description;
            activeDesc = d.name;
            activeIcon = d.icon;
            if (!draggingMaster) {
                activeVol = d.volume;
                activeMute = d.mute;
                leftChannelVol = d.volume;
                rightChannelVol = d.volume;
            }
            if (d.name.indexOf("bluez") !== -1)
                getAudioProfile(d.name);

        }
    }

    function getProfileLabel(profile) {
        if (!profile)
            return "Unknown";

        if (profile.indexOf("a2dp-sink-sbc_xq") !== -1)
            return "A2DP (SBC-XQ)";

        if (profile.indexOf("a2dp-sink") !== -1)
            return "A2DP (SBC)";

        if (profile.indexOf("headset-head-unit-cvsd") !== -1)
            return "HFP (CVSD)";

        if (profile.indexOf("headset-head-unit") !== -1)
            return "HFP (mSBC)";

        if (profile.indexOf("headset") !== -1)
            return "Headset";

        if (profile.indexOf("a2dp") !== -1)
            return "A2DP";

        if (profile.indexOf("off") !== -1)
            return "Off";

        return profile;
    }

    function getAudioProfile(desc) {
        let cardName = desc;
        if (cardName.indexOf("bluez_output.") !== -1)
            cardName = cardName.replace("bluez_output.", "bluez_card.");
        else if (cardName.indexOf("bluez_input.") !== -1)
            cardName = cardName.replace("bluez_input.", "bluez_card.");
        cardName = cardName.replace(/\.\d+$/, "");
        let cmd = "import Quickshell.Io; Process { command: [\"bash\", \"-c\", \"pactl list cards | awk '/Name:.*" + cardName + "/{found=1} found && /Active Profile:/{print $NF; exit}'\"]; stdout: StdioCollector { onStreamFinished: { var prof = text.trim(); if (prof) audioProfile = prof; } } }";
        let process = Qt.createQmlObject(cmd, soundPopup);
        process.running = true;
    }

    anchor.window: root
    anchor.rect.x: root.width / 2 - width / 2
    anchor.rect.y: 31
    implicitWidth: 320
    implicitHeight: 420
    color: 'transparent'
    visible: false
    onVisibleChanged: {
        if (visible) {
            introHero = 0;
            introTabs = 0;
            introList = 0;
            entryAnim.restart();
        }
    }
    // Restore on first load
    Component.onCompleted: {
        audioManager.getAudioState();
        Qt.callLater(function() {
            audioManager.restoreVolumes();
        }, 2000);
    }

    ParallelAnimation {
        id: entryAnim

        NumberAnimation {
            target: soundPopup
            property: "introHero"
            from: 0
            to: 1
            duration: 400
            easing.type: Easing.OutBack
        }

        SequentialAnimation {
            PauseAnimation {
                duration: 150
            }

            NumberAnimation {
                target: soundPopup
                property: "introTabs"
                from: 0
                to: 1
                duration: 400
                easing.type: Easing.OutBack
            }

        }

        SequentialAnimation {
            PauseAnimation {
                duration: 250
            }

            NumberAnimation {
                target: soundPopup
                property: "introList"
                from: 0
                to: 1
                duration: 500
                easing.type: Easing.OutBack
            }

        }

    }

    // === Data Models ===
    ListModel {
        id: outputsModel
    }

    ListModel {
        id: inputsModel
    }

    ListModel {
        id: appsModel
    }

    Timer {
        id: syncDelay

        interval: 600
        onTriggered: {
            draggingNodes = ({
            });
            draggingMaster = false;
        }
    }

    // === Audio Manager ===
    QtObject {
        id: audioManager

        property string scriptsDir: _HOMEDIR + "/.config/quickshell/popups/Sound"
        property string volumeCacheFile: _HOMEDIR + "/.config/quickshell/popups/Sound/qs_volumes.json"
        property string lastRestoredDevices: ""

        function getAudioState() {
            let cmd = "import Quickshell.Io; Process { command: [\"python3\", audioManager.scriptsDir + \"/get_audio_state.py\"]; stdout: StdioCollector { onStreamFinished: { try { var data = JSON.parse(text.trim()); ";
            cmd += "syncModel(outputsModel, data.outputs || []); ";
            cmd += "syncModel(inputsModel, data.inputs || []); ";
            cmd += "syncModel(appsModel, data.apps || []); ";
            cmd += "updateHero(); ";
            cmd += "audioManager.restoreVolumes(); ";
            cmd += "} catch(e) {} } } }";
            let process = Qt.createQmlObject(cmd, soundPopup);
            process.running = true;
        }

        function setMasterVolume(type, id, val) {
            Quickshell.execDetached(["bash", "-c", "pactl set-" + type + "-volume " + id + " " + val + "%"]);
        }

        function toggleMute(type, id) {
            Quickshell.execDetached(["bash", scriptsDir + "/audio_control.sh", "toggle-mute", type, id]);
        }

        function setDefault(type, name) {
            Quickshell.execDetached(["bash", "-c", "pactl set-default-" + type + " '" + name + "'"]);
            Qt.callLater(getAudioState, 500);
        }

        function cycleProfile(cardName) {
            Quickshell.execDetached(["bash", "-c", "CARD='" + cardName + "'; " + "CURRENT=$(pactl list cards | awk '/Name:.*" + cardName + "/{found=1} found && /Active Profile:/{print $NF; exit}'); " + "FOUND=0; " + "for PROFILE in a2dp-sink a2dp-sink-sbc_xq headset-head-unit headset-head-unit-cvsd; do " + "  if [ $FOUND -eq 1 ]; then pactl set-card-profile $CARD $PROFILE 2>/dev/null && break; fi; " + "  if [ \"$PROFILE\" = \"$CURRENT\" ]; then FOUND=1; fi; " + "done; " + "if [ $FOUND -eq 1 ]; then pactl set-card-profile $CARD a2dp-sink 2>/dev/null; fi"]);
            Qt.callLater(getAudioState, 500);
        }

        function killStream(id) {
            Quickshell.execDetached(["bash", "-c", "pw-cli destroy " + id]);
            Qt.callLater(getAudioState, 300);
        }

        function moveStream(streamId, sinkName) {
            Quickshell.execDetached(["bash", "-c", "pactl move-sink-input " + streamId + " " + sinkName]);
            Qt.callLater(getAudioState, 300);
        }

        function toggleMono() {
            monoMode = !monoMode;
            let type = activeTab === "inputs" ? "source" : "sink";
            if (monoMode) {
                savedLeftVol = leftChannelVol;
                savedRightVol = rightChannelVol;
                let avg = Math.round((leftChannelVol + rightChannelVol) / 2);
                leftChannelVol = avg;
                rightChannelVol = avg;
                balance = 0;
                Quickshell.execDetached(["bash", "-c", "pactl set-" + type + "-volume " + activeId + " " + avg + "% " + avg + "%"]);
            } else {
                leftChannelVol = savedLeftVol;
                rightChannelVol = savedRightVol;
                Quickshell.execDetached(["bash", "-c", "pactl set-" + type + "-volume " + activeId + " " + savedLeftVol + "% " + savedRightVol + "%"]);
            }
        }

        function saveVolumes() {
            if (outputsModel.count === 0)
                return ;

            let data = {
                "outputs": [],
                "inputs": [],
                "apps": []
            };
            for (let i = 0; i < outputsModel.count; i++) {
                let d = outputsModel.get(i);
                data.outputs.push({
                    "name": d.name || "",
                    "volume": d.volume || 0,
                    "mute": d.mute || false
                });
            }
            for (let i = 0; i < inputsModel.count; i++) {
                let d = inputsModel.get(i);
                data.inputs.push({
                    "name": d.name || "",
                    "volume": d.volume || 0,
                    "mute": d.mute || false
                });
            }
            for (let i = 0; i < appsModel.count; i++) {
                let d = appsModel.get(i);
                data.apps.push({
                    "description": d.description || "",
                    "volume": d.volume || 0,
                    "mute": d.mute || false
                });
            }
            let jsonStr = JSON.stringify(data);
            // Use printf and a temp file to avoid quote issues
            Quickshell.execDetached(["bash", "-c", "printf '%s' '" + jsonStr.replace(/'/g, "'\\''") + "' > /tmp/qs_vol_tmp.json && mkdir -p ~/.cache && mv /tmp/qs_vol_tmp.json " + volumeCacheFile]);
        }

        function restoreVolumes() {
            // console.log("[Volume] Devices changed, restoring... outputs:", outputsModel.count, "inputs:", inputsModel.count, "apps:", appsModel.count)

            if (outputsModel.count === 0 && inputsModel.count === 0)
                return ;

            // Create fingerprint of current devices
            let fingerprint = "";
            for (let i = 0; i < outputsModel.count; i++) fingerprint += outputsModel.get(i).name + ","
            for (let i = 0; i < inputsModel.count; i++) fingerprint += inputsModel.get(i).name + ","
            for (let i = 0; i < appsModel.count; i++) fingerprint += appsModel.get(i).description + ","
            // Skip if same devices already restored
            if (fingerprint === lastRestoredDevices)
                return ;

            lastRestoredDevices = fingerprint;
            let cmd = "import Quickshell.Io; Process { command: [\"bash\", \"-c\", \"cat " + volumeCacheFile + " 2>/dev/null || echo '{}'\"]; stdout: StdioCollector { onStreamFinished: { try { var cache = JSON.parse(text.trim());";
            // Restore output volumes
            cmd += "for (let i = 0; i < outputsModel.count; i++) {";
            cmd += "  for (let j = 0; j < (cache.outputs || []).length; j++) {";
            cmd += "    if (outputsModel.get(i).name === cache.outputs[j].name) {";
            cmd += "      outputsModel.setProperty(i, 'volume', cache.outputs[j].volume);";
            cmd += "      outputsModel.setProperty(i, 'mute', cache.outputs[j].mute);";
            cmd += "      var vol = cache.outputs[j].volume;";
            cmd += "      audioManager.setMasterVolume('sink', outputsModel.get(i).id, vol);";
            cmd += "      if (cache.outputs[j].mute) audioManager.toggleMute('sink', outputsModel.get(i).id);";
            cmd += "    }";
            cmd += "  }";
            cmd += "}";
            // Restore input volumes
            cmd += "for (let i = 0; i < inputsModel.count; i++) {";
            cmd += "  for (let j = 0; j < (cache.inputs || []).length; j++) {";
            cmd += "    if (inputsModel.get(i).name === cache.inputs[j].name) {";
            cmd += "      inputsModel.setProperty(i, 'volume', cache.inputs[j].volume);";
            cmd += "      inputsModel.setProperty(i, 'mute', cache.inputs[j].mute);";
            cmd += "      audioManager.setMasterVolume('source', inputsModel.get(i).id, cache.inputs[j].volume);";
            cmd += "    }";
            cmd += "  }";
            cmd += "}";
            // Restore app volumes
            cmd += "for (let i = 0; i < appsModel.count; i++) {";
            cmd += "  for (let j = 0; j < (cache.apps || []).length; j++) {";
            cmd += "    if (appsModel.get(i).description === cache.apps[j].description) {";
            cmd += "      appsModel.setProperty(i, 'volume', cache.apps[j].volume);";
            cmd += "      audioManager.setMasterVolume('sink-input', appsModel.get(i).id, cache.apps[j].volume);";
            cmd += "    }";
            cmd += "  }";
            cmd += "}";
            cmd += "} catch(e) { console.log('[Volume] Error:', e); } } } }";
            let process = Qt.createQmlObject(cmd, soundPopup);
            process.running = true;
        }

    }

    // Save volumes every 10 seconds
    Timer {
        // audioManager.restoreVolumes()

        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            audioManager.saveVolumes();
        }
    }

    Timer {
        interval: 2000
        running: soundPopup.visible
        repeat: true
        onTriggered: audioManager.getAudioState()
    }

    Rectangle {
        id: soundPanel

        anchors.fill: parent
        color: theme.colSurface
        radius: 20
        border.width: 3
        border.color: theme.colSurface
        opacity: soundPopup.visible ? 1 : 0
        scale: soundPopup.visible ? 1 : 0.2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ============================================================
            // HERO SECTION (Expandable)
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: heroExpanded ? 125 : 80
                color: theme.colSecondary
                radius: 14
                clip: true
                opacity: soundPopup.introHero

                // Main hero row
                RowLayout {
                    height: 60
                    spacing: 12

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 10
                    }

                    // Device orb
                    Rectangle {
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 56
                        radius: 28
                        color: activeMute ? "#FF5252" : tabColor
                        Layout.bottomMargin: heroExpanded ? 10 : 0

                        Canvas {
                            id: orbWave

                            property real wavePhase: 0

                            anchors.fill: parent
                            onWavePhaseChanged: orbWave.requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                if (activeVol <= 0)
                                    return ;

                                var r = width / 2;
                                var fillY = height * (1 - activeVol / (volumeBoost ? 150 : 100));
                                ctx.save();
                                ctx.beginPath();
                                ctx.arc(r, r, r, 0, Math.PI * 2);
                                ctx.clip();
                                ctx.beginPath();
                                ctx.moveTo(0, fillY);
                                if (activeVol < ((volumeBoost ? 150 : 100) - 1)) {
                                    var amp = 4 * Math.sin(activeVol / (volumeBoost ? 150 : 100) * Math.PI);
                                    ctx.bezierCurveTo(width * 0.33, fillY + Math.sin(wavePhase) * amp, width * 0.66, fillY + Math.cos(wavePhase + Math.PI) * amp, width, fillY);
                                    ctx.lineTo(width, height);
                                    ctx.lineTo(0, height);
                                } else {
                                    ctx.lineTo(width, 0);
                                    ctx.lineTo(width, height);
                                    ctx.lineTo(0, height);
                                }
                                ctx.closePath();
                                var grad = ctx.createLinearGradient(0, 0, 0, height);
                                grad.addColorStop(0, Qt.lighter(tabColor, 1.3).toString());
                                grad.addColorStop(1, tabColor.toString());
                                ctx.fillStyle = grad;
                                ctx.fill();
                                ctx.restore();
                            }

                            Connections {
                                function onActiveVolChanged() {
                                    orbWave.requestPaint();
                                }

                                target: soundPopup
                            }

                            NumberAnimation on wavePhase {
                                running: activeVol > 0 && activeVol < (volumeBoost ? 150 : 100)
                                loops: Animation.Infinite
                                from: 0
                                to: Math.PI * 2
                                duration: 1200
                            }

                        }

                        Text {
                            anchors.centerIn: parent
                            text: activeMute ? "MUTE" : activeVol + "%"
                            color: activeVol > 50 ? "#fff" : theme.colOnSecondary
                            font.pixelSize: config.fontSize * 1.4
                            font.weight: Font.Black
                            font.family: "monospace"
                            z: 1
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let type = activeTab === "inputs" ? "source" : "sink";
                                audioManager.toggleMute(type, activeId);
                                audioManager.getAudioState();
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 300
                            }

                        }

                        Behavior on Layout.bottomMargin {
                            NumberAnimation {
                                duration: 200
                            }

                        }

                    }

                    // Device info + Master slider
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: activeName || "No Device"
                                color: theme.colOnSecondary
                                font.pixelSize: config.fontSize * 1.1
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: activeDesc || ""
                                color: theme.colOnSecondary
                                font.pixelSize: config.fontSize * 0.75
                                opacity: 0.7
                                elide: Text.ElideRight
                            }

                        }

                        // Master slider
                        Rectangle {
                            Layout.fillWidth: true
                            height: 20
                            radius: 10
                            color: theme.colSurfaceVariant
                            opacity: activeMute ? 0.4 : 1
                            Layout.bottomMargin: heroExpanded ? 10 : 0

                            Rectangle {
                                width: Math.max(16, (parent.width - 4) * (activeVol / (volumeBoost ? 150 : 100)))
                                radius: 9
                                color: activeMute ? theme.colSurfaceVariant : tabColor

                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                    margins: 2
                                }

                                Behavior on width {
                                    enabled: !draggingMaster

                                    NumberAnimation {
                                        duration: 200
                                    }

                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                    }

                                }

                            }

                            MouseArea {
                                function updateMaster(mx) {
                                    let maxVol = volumeBoost ? 150 : 100;
                                    let pct = Math.max(0, Math.min(maxVol, Math.round((mx / width) * maxVol)));
                                    activeVol = pct;
                                    leftChannelVol = pct;
                                    rightChannelVol = pct;
                                    let type = activeTab === "inputs" ? "source" : "sink";
                                    audioManager.setMasterVolume(type, activeId, pct);
                                }

                                anchors.fill: parent
                                cursorShape: activeMute ? Qt.ArrowCursor : Qt.PointingHandCursor
                                enabled: !activeMute
                                onPressed: (mouse) => {
                                    syncDelay.stop();
                                    draggingMaster = true;
                                    updateMaster(mouse.x);
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed)
                                        updateMaster(mouse.x);

                                }
                                onReleased: {
                                    syncDelay.restart();
                                    audioManager.getAudioState();
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                }

                            }

                            Behavior on Layout.bottomMargin {
                                NumberAnimation {
                                    duration: 200
                                }

                            }

                        }

                    }

                }

                // Click to expand
                MouseArea {
                    height: 40
                    z: 1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: heroExpanded = !heroExpanded

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }

                }

                // === Expanded content ===
                ColumnLayout {
                    z: 2
                    spacing: 8
                    opacity: heroExpanded ? 1 : 0
                    visible: opacity > 0.7

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        topMargin: 72
                        margins: 10
                    }

                    // Balance slider
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "L"
                            color: theme.colOnSecondary
                            font.pixelSize: config.fontSize * 0.7
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 14
                            radius: 7
                            color: theme.colSurfaceVariant

                            Rectangle {
                                height: parent.height
                                width: 6
                                radius: 3
                                color: tabColor
                                x: Math.max(0, Math.min(parent.width - 6, ((balance + 100) / 200) * (parent.width - 6)))

                                Behavior on x {
                                    NumberAnimation {
                                        duration: 100
                                    }

                                }

                            }

                            MouseArea {
                                function updateBalance(mx) {
                                    balance = Math.round(((mx / width) * 200) - 100);
                                    if (balance < 0) {
                                        leftChannelVol = activeVol;
                                        rightChannelVol = Math.round(activeVol * (1 + balance / 100));
                                    } else if (balance > 0) {
                                        leftChannelVol = Math.round(activeVol * (1 - balance / 100));
                                        rightChannelVol = activeVol;
                                    } else {
                                        leftChannelVol = activeVol;
                                        rightChannelVol = activeVol;
                                    }
                                    let type = activeTab === "inputs" ? "source" : "sink";
                                    Quickshell.execDetached(["bash", "-c", "pactl set-" + type + "-volume " + activeId + " " + leftChannelVol + "% " + rightChannelVol + "%"]);
                                }

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onPressed: (mouse) => {
                                    return updateBalance(mouse.x);
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed)
                                        updateBalance(mouse.x);

                                }
                            }

                        }

                        Text {
                            text: "R"
                            color: theme.colOnSecondary
                            font.pixelSize: config.fontSize * 0.7
                        }

                    }

                    // Mono toggle + Boost + Profile + Sample rate
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "Mono"
                            color: theme.colOnSecondary
                            font.pixelSize: config.fontSize * 0.7
                        }

                        Rectangle {
                            width: 32
                            height: 18
                            radius: 9
                            color: monoMode ? tabColor : theme.colSurfaceVariant

                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                color: "white"
                                x: monoMode ? 16 : 2
                                y: 2

                                Behavior on x {
                                    NumberAnimation {
                                        duration: 150
                                    }

                                }

                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: audioManager.toggleMono()
                            }

                        }

                        // Boost button
                        Rectangle {
                            height: 20
                            width: boostText.implicitWidth + 14
                            radius: 10
                            color: volumeBoost ? "#FF5722" : theme.colSurfaceVariant

                            Text {
                                id: boostText

                                anchors.centerIn: parent
                                text: "Boost"
                                color: volumeBoost ? "#fff" : theme.colOnSurfaceVariant
                                font.pixelSize: config.fontSize * 0.6
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    volumeBoost = !volumeBoost;
                                    if (!volumeBoost && activeVol > 100) {
                                        activeVol = 100;
                                        leftChannelVol = 100;
                                        rightChannelVol = 100;
                                        let type = activeTab === "inputs" ? "source" : "sink";
                                        audioManager.setMasterVolume(type, activeId, 100);
                                    }
                                }
                            }

                        }

                        // Profile cycle button (Bluetooth only)
                        Rectangle {
                            Layout.fillWidth: true
                            height: 24
                            radius: 12
                            color: theme.colSurfaceVariant
                            visible: activeDesc.toLowerCase().indexOf("bluez") !== -1

                            Text {
                                anchors.centerIn: parent
                                text: getProfileLabel(audioProfile)
                                color: theme.colOnSurfaceVariant
                                font.pixelSize: config.fontSize * 0.7
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let cardName = activeDesc;
                                    if (cardName.indexOf("bluez_output.") !== -1)
                                        cardName = cardName.replace("bluez_output.", "bluez_card.");
                                    else if (cardName.indexOf("bluez_input.") !== -1)
                                        cardName = cardName.replace("bluez_input.", "bluez_card.");
                                    cardName = cardName.replace(/\.\d+$/, "");
                                    audioManager.cycleProfile(cardName);
                                }
                            }

                        }

                        Text {
                            text: sampleRate || "48kHz"
                            color: theme.colOnSecondary
                            font.pixelSize: config.fontSize * 0.7
                            opacity: 0.6
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }

                    }

                }

                transform: Translate {
                    y: 15 * (1 - soundPopup.introHero)
                }

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }

                }

            }

            // ============================================================
            // TABS
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                color: theme.colSecondary
                radius: 14
                opacity: soundPopup.introTabs

                Rectangle {
                    width: (parent.width - 6) / 3
                    height: parent.height - 6
                    y: 3
                    radius: 10
                    color: tabColor
                    x: activeTab === "outputs" ? 3 : (activeTab === "inputs" ? width + 3 : width * 2 + 3)

                    Behavior on x {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.2
                        }

                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 300
                        }

                    }

                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 0

                    TabButton {
                        text: "󰓃 Outputs"
                        tabId: "outputs"
                    }

                    TabButton {
                        text: "󰍬 Inputs"
                        tabId: "inputs"
                    }

                    TabButton {
                        text: "󰎆 Streams"
                        tabId: "apps"
                    }

                }

                transform: Translate {
                    y: 15 * (1 - soundPopup.introTabs)
                }

            }

            // ============================================================
            // DEVICE LIST
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: theme.colSecondary
                radius: 14
                clip: true
                opacity: soundPopup.introList

                ListView {
                    id: deviceList

                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: activeTab === "outputs" ? outputsModel : (activeTab === "inputs" ? inputsModel : appsModel)

                    displaced: Transition {
                        SpringAnimation {
                            properties: "y"
                            spring: 3
                            damping: 0.3
                            mass: 0.3
                        }

                    }

                    delegate: Rectangle {
                        id: deviceCard

                        property bool isActive: model.is_default && activeTab !== "apps"
                        property bool cardExpanded: false

                        width: deviceList.width
                        height: cardExpanded ? (activeTab === "apps" ? 85 : 72) : 72
                        color: model.is_default && activeTab !== "apps" ? tabColor : theme.colPrimary
                        radius: 10
                        clip: true

                        RowLayout {
                            height: 50
                            spacing: 8

                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 10
                            }

                            Text {
                                text: {
                                    if (activeTab === "inputs")
                                        return "󰍬";

                                    if (activeTab === "apps")
                                        return "󰎆";

                                    let desc = (model.description || "").toLowerCase();
                                    if (desc.indexOf("headset") !== -1 || desc.indexOf("headphone") !== -1)
                                        return "󰋎";

                                    return "󰓃";
                                }
                                font.pixelSize: config.fontSize * 1.5
                                color: isActive ? "#fff" : theme.colOnPrimary
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: model.description || "Unknown"
                                    color: isActive ? "#fff" : theme.colOnPrimary
                                    font.pixelSize: config.fontSize * 1
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: isActive ? "Active Default" : (model.name || "")
                                    color: isActive ? Qt.darker("#fff", 1.3) : theme.colOnPrimary
                                    font.pixelSize: config.fontSize * 0.7
                                    opacity: isActive ? 0.8 : 0.5
                                    elide: Text.ElideRight
                                    visible: text !== ""
                                }

                            }

                            RowLayout {
                                spacing: 6
                                visible: !isActive
                                Layout.alignment: Qt.AlignVCenter

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: muteHover.containsMouse ? theme.colSurfaceVariant : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: model.mute || model.volume === 0 ? "󰖁" : (model.volume > 50 ? "󰕾" : "󰖀")
                                        color: model.mute ? "#FF5252" : theme.colOnPrimary
                                        font.pixelSize: config.fontSize * 1
                                    }

                                    MouseArea {
                                        id: muteHover

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let type = activeTab === "inputs" ? "source" : (activeTab === "apps" ? "sink-input" : "sink");
                                            audioManager.toggleMute(type, model.id);
                                            audioManager.getAudioState();
                                        }
                                    }

                                }

                                Rectangle {
                                    Layout.preferredWidth: 100
                                    height: 16
                                    radius: 8
                                    color: theme.colSurfaceVariant
                                    opacity: model.mute ? 0.4 : 1

                                    Rectangle {
                                        width: Math.max(12, (parent.width - 4) * (model.volume / (volumeBoost ? 150 : 100)))
                                        radius: 7
                                        color: model.mute ? theme.colSurfaceVariant : tabColor

                                        anchors {
                                            left: parent.left
                                            top: parent.top
                                            bottom: parent.bottom
                                            margins: 2
                                        }

                                        Behavior on width {
                                            enabled: !draggingNodes[model.id]

                                            NumberAnimation {
                                                duration: 200
                                            }

                                        }

                                    }

                                    MouseArea {
                                        id: miniSliderMa

                                        function updateVol(mx) {
                                            let maxVol = volumeBoost ? 150 : 100;
                                            let pct = Math.max(0, Math.min(maxVol, Math.round((mx / width) * maxVol)));
                                            let targetModel = activeTab === "outputs" ? outputsModel : (activeTab === "inputs" ? inputsModel : appsModel);
                                            for (let i = 0; i < targetModel.count; i++) {
                                                if (targetModel.get(i).id === model.id) {
                                                    targetModel.setProperty(i, "volume", pct);
                                                    break;
                                                }
                                            }
                                            let type = activeTab === "inputs" ? "source" : (activeTab === "apps" ? "sink-input" : "sink");
                                            audioManager.setMasterVolume(type, model.id, pct);
                                        }

                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: (mouse) => {
                                            syncDelay.stop();
                                            draggingNodes[model.id] = true;
                                            updateVol(mouse.x);
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (pressed)
                                                updateVol(mouse.x);

                                        }
                                        onReleased: {
                                            syncDelay.restart();
                                            audioManager.getAudioState();
                                        }
                                    }

                                }

                                Text {
                                    text: model.volume + "%"
                                    color: theme.colOnPrimary
                                    font.pixelSize: config.fontSize * 0.7
                                    font.weight: Font.Medium
                                    Layout.preferredWidth: 30
                                }

                            }

                        }

                        MouseArea {
                            id: cardMa

                            height: 35
                            hoverEnabled: activeTab !== "apps"
                            cursorShape: activeTab !== "apps" && !isActive ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (activeTab !== "apps" && !isActive) {
                                    let type = activeTab === "outputs" ? "sink" : "source";
                                    audioManager.setDefault(type, model.name);
                                } else if (activeTab === "apps") {
                                    cardExpanded = !cardExpanded;
                                }
                            }

                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                            }

                        }

                        ColumnLayout {
                            z: 2
                            spacing: 6
                            opacity: cardExpanded && activeTab === "apps" ? 1 : 0
                            visible: opacity > 0.7

                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                margins: 8
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 24
                                    radius: 12
                                    color: theme.colSurfaceVariant

                                    Text {
                                        id: streamOutputText

                                        anchors.centerIn: parent
                                        text: "▸ Output"
                                        color: theme.colOnSurfaceVariant
                                        font.pixelSize: config.fontSize * 0.65
                                        elide: Text.ElideRight
                                        width: parent.width - 16
                                    }

                                    Timer {
                                        interval: 100
                                        running: cardExpanded
                                        repeat: false
                                        onTriggered: {
                                            let cmd = "import Quickshell.Io; Process { command: [\"bash\", \"-c\", \"pactl list sink-inputs | awk '/Sink Input #" + model.id + "/{found=1} found && /Sink:/{print $2; exit}'\"]; stdout: StdioCollector { onStreamFinished: {";
                                            cmd += "var sinkId = text.trim();";
                                            cmd += "for (var i = 0; i < outputsModel.count; i++) {";
                                            cmd += "  if (outputsModel.get(i).id === sinkId) {";
                                            cmd += "    var n = outputsModel.get(i).description || outputsModel.get(i).name || 'Output';";
                                            cmd += "    if (n.length > 15) n = n.substring(0, 13) + '..';";
                                            cmd += "    streamOutputText.text = '▸ ' + n; break;";
                                            cmd += "  }";
                                            cmd += "}";
                                            cmd += "} } }";
                                            let process = Qt.createQmlObject(cmd, soundPopup);
                                            process.running = true;
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let getCmd = "import Quickshell.Io; Process { command: [\"bash\", \"-c\", \"pactl list sink-inputs | awk '/Sink Input #" + model.id + "/{found=1} found && /Sink:/{print $2; exit}'\"]; stdout: StdioCollector { onStreamFinished: {";
                                            getCmd += "var currentSinkIndex = text.trim();";
                                            getCmd += "var currentSinkName = '';";
                                            getCmd += "for (var i = 0; i < outputsModel.count; i++) {";
                                            getCmd += "  if (outputsModel.get(i).id === currentSinkIndex) { currentSinkName = outputsModel.get(i).name; break; }";
                                            getCmd += "}";
                                            getCmd += "var nextSink = ''; var found = false;";
                                            getCmd += "for (var i = 0; i < outputsModel.count; i++) {";
                                            getCmd += "  if (found) { nextSink = outputsModel.get(i).name; break; }";
                                            getCmd += "  if (outputsModel.get(i).name === currentSinkName) found = true;";
                                            getCmd += "}";
                                            getCmd += "if (!nextSink && outputsModel.count > 0) nextSink = outputsModel.get(0).name;";
                                            getCmd += "if (nextSink) {";
                                            getCmd += "  audioManager.moveStream(" + model.id + ", nextSink);";
                                            getCmd += "  for (var i = 0; i < outputsModel.count; i++) {";
                                            getCmd += "    if (outputsModel.get(i).name === nextSink) {";
                                            getCmd += "      var n = outputsModel.get(i).description || outputsModel.get(i).name || 'Output';";
                                            getCmd += "      if (n.length > 15) n = n.substring(0, 13) + '..';";
                                            getCmd += "      streamOutputText.text = '▸ ' + n; break;";
                                            getCmd += "    }";
                                            getCmd += "  }";
                                            getCmd += "}";
                                            getCmd += "} } }";
                                            let process = Qt.createQmlObject(getCmd, soundPopup);
                                            process.running = true;
                                        }
                                    }

                                }

                                Rectangle {
                                    width: 50
                                    height: 24
                                    radius: 12
                                    color: "#FF5252"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Kill"
                                        color: "#fff"
                                        font.pixelSize: config.fontSize * 0.7
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached(["bash", "-c", "pw-cli destroy " + model.id]);
                                            Qt.callLater(function() {
                                                audioManager.getAudioState();
                                            }, 300);
                                        }
                                    }

                                }

                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                }

                            }

                        }

                        Behavior on height {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }

                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }

                        }

                    }

                }

                transform: Translate {
                    y: 15 * (1 - soundPopup.introList)
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

    // ============================================================
    // COMPONENT: TabButton
    // ============================================================
    component TabButton: Rectangle {
        property string text: ""
        property string tabId: ""

        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "transparent"

        Text {
            anchors.centerIn: parent
            text: parent.text
            color: activeTab === parent.tabId ? theme.colOnPrimary : theme.colOnSecondary
            font.pixelSize: config.fontSize * 0.85
            font.weight: Font.Medium
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                activeTab = parent.tabId;
                updateHero();
            }
        }

    }

}
