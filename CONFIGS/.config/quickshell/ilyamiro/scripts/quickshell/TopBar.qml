// //@ pragma UseQApplication
// import QtQuick
// import QtQuick.Layouts
// import QtQuick.Controls
// import Quickshell
// import Quickshell.Io
// import Quickshell.Wayland
// import Quickshell.Services.SystemTray

// Variants {
//     model: Quickshell.screens

//     delegate: Component {
//         PanelWindow {
//             id: barWindow
//             property bool pendingReload: false

//             IpcHandler {
//                 target: "topbar"
//                 function forceReload() {
//                     Quickshell.reload(true) 
//                 }
//                 function queueReload() {
//                     if (!barWindow.isSettingsOpen) {
//                         Quickshell.reload(true)
//                     } else {
//                         barWindow.pendingReload = true
//                     }
//                 }
//                 function toggleUpdate() {
//                     barWindow.forceUpdateShow = !barWindow.forceUpdateShow
//                 }
//             }

//             required property var modelData
//             screen: modelData

//             anchors {
//                 top: true
//                 left: true
//                 right: true
//             }

//             Scaler {
//                 id: scaler
//                 currentWidth: barWindow.width
//             }

//             property real baseScale: scaler.baseScale

//             function s(val) { 
//                 return scaler.s(val); 
//             }

//             property int barHeight: s(48)

//             height: barHeight
//             margins { top: s(8); bottom: 0; left: s(4); right: s(4) }
//             exclusiveZone: barHeight 
//             color: "transparent"

//             MatugenColors {
//                 id: mocha
//             }

//             property bool showHelpIcon: true
//             property bool isRecording: false
            
//             property bool updateAvailable: false
//             property bool forceUpdateShow: false
//             property bool isUpdateVisible: updateAvailable || forceUpdateShow
            
//             property int workspaceCount: 8
            
//             property string activeWidget: "" 
//             property bool isSettingsOpen: activeWidget === "settings"

//             property real settingsSlideProgress: isSettingsOpen ? 1.0 : 0.0
//             Behavior on settingsSlideProgress { 
//                 enabled: barWindow.startupCascadeFinished
//                 NumberAnimation { duration: 600; easing.type: Easing.OutExpo } 
//             }

//             onIsSettingsOpenChanged: {
//                 if (!barWindow.isSettingsOpen && barWindow.pendingReload) {
//                     barWindow.pendingReload = false;
//                     Quickshell.reload(true);
//                 }
//             }

//             Process {
//                 id: widgetPoller
//                 command: ["bash", "-c", "cat /tmp/qs_current_widget 2>/dev/null || echo ''"]
//                 running: true
//                 stdout: StdioCollector {
//                     onStreamFinished: {
//                         let txt = this.text.trim();
//                         if (barWindow.activeWidget !== txt) barWindow.activeWidget = txt;
//                     }
//                 }
//             }

//             Process {
//                 id: widgetWatcher
//                 command: ["bash", "-c", "while [ ! -f /tmp/qs_current_widget ]; do sleep 1; done; inotifywait -qq -e modify,close_write /tmp/qs_current_widget"]
//                 running: true
//                 onExited: {
//                     widgetPoller.running = false;
//                     widgetPoller.running = true;
//                     running = false;
//                     running = true;
//                 }
//             }
            
//             Process {
//                 id: recPoller
//                 command: ["bash", "-c", "if [ -s ~/.cache/qs_recording_state/rec_pid ] && kill -0 $(cat ~/.cache/qs_recording_state/rec_pid) 2>/dev/null; then echo '1'; else echo '0'; fi"]
//                 stdout: StdioCollector {
//                     onStreamFinished: {
//                         barWindow.isRecording = (this.text.trim() === "1");
//                     }
//                 }
//             }

//             Timer {
//                 interval: 500; running: true; repeat: true
//                 onTriggered: {
//                     recPoller.running = false;
//                     recPoller.running = true;
//                 }
//             }

//             Process {
//                 id: updatePoller
//                 command: ["bash", "-c", "if [ -f ~/.cache/qs_update_pending ]; then echo '1'; else echo '0'; fi"]
//                 stdout: StdioCollector {
//                     onStreamFinished: {
//                         barWindow.updateAvailable = (this.text.trim() === "1");
//                     }
//                 }
//             }

//             Timer {
//                 interval: 2000; running: true; repeat: true
//                 onTriggered: {
//                     updatePoller.running = false;
//                     updatePoller.running = true;
//                 }
//             }
            
//             Process {
//                 id: settingsReader
//                 command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null || echo '{}'"]
//                 running: true
//                 stdout: StdioCollector {
//                     onStreamFinished: {
//                         try {
//                             if (this.text && this.text.trim().length > 0 && this.text.trim() !== "{}") {
//                                 let parsed = JSON.parse(this.text);
                                
//                                 if (parsed.topbarHelpIcon !== undefined && barWindow.showHelpIcon !== parsed.topbarHelpIcon) {
//                                     barWindow.showHelpIcon = parsed.topbarHelpIcon;
//                                 }
                                
//                                 if (parsed.workspaceCount !== undefined && barWindow.workspaceCount !== parsed.workspaceCount) {
//                                     barWindow.workspaceCount = parsed.workspaceCount;
//                                     wsDaemon.running = false;
//                                     wsDaemon.running = true;
//                                 }
//                             }
//                         } catch (e) {}
//                     }
//                 }
//             }

//             Process {
//                 id: settingsWatcher
//                 command: ["bash", "-c", "while [ ! -f ~/.config/hypr/settings.json ]; do sleep 1; done; inotifywait -qq -e modify,close_write ~/.config/hypr/settings.json"]
//                 running: true
//                 stdout: StdioCollector {
//                     onStreamFinished: {
//                         settingsReader.running = false;
//                         settingsReader.running = true;
                        
//                         settingsWatcher.running = false;
//                         settingsWatcher.running = true;
//                     }
//                 }
//             }
            
//             property bool isDesktop: false
//             property string ethStatus: "Ethernet"

//             Process {
//                 id: chassisDetector
//                 running: true
//                 command: ["bash", "-c", "if ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then echo 'laptop'; else echo 'desktop'; fi"]
//                 stdout: StdioCollector {
//                     onStreamFinished: {
//                         barWindow.isDesktop = (this.text.trim() === "desktop");
//                     }
//                 }
//             }

//             property bool isStartupReady: false
//             Timer { interval: 10; running: true; onTriggered: barWindow.isStartupReady = true }
            
//             property bool startupCascadeFinished: false
//             Timer { interval: 1000; running: true; onTriggered: barWindow.startupCascadeFinished = true }
            
//             property bool fastPollerLoaded: false
//             property bool isDataReady: fastPollerLoaded
//             Timer { interval: 600; running: true; onTriggered: barWindow.isDataReady = true }
            
//             property string timeStr: ""
//             property string fullDateStr: ""
//             property int typeInIndex: 0
//             property string dateStr: fullDateStr.substring(0, typeInIndex)

//             property string weatherIcon: ""
//             property string weatherTemp: "--°"
//             property string weatherHex: mocha.yellow
            
//             property string wifiStatus: "Off"
//             property string wifiIcon: "󰤮"
//             property string wifiSsid: ""
            
//             property string btStatus: "Off"
//             property string btIcon: "󰂲"
//             property string btDevice: ""
            
//             property string volPercent: "0%"
//             property string volIcon: "󰕾"
//             property bool isMuted: false
            
//             property string batPercent: "100%"
//             property string batIcon: "󰁹"
//             property string batStatus: "Unknown"
            
//             property string kbLayout: "us"
            
//             ListModel { 
//                 id: workspacesModel 
//                 property int activeIndex: 0
//             }
            
//             property var musicData: { "status": "Stopped", "title": "", "artUrl": "", "timeStr": "" }

//             property string displayTitle: ""
//             property string displayTime: ""
//             property string displayArtUrl: ""

//             onMusicDataChanged: {
//                 if (musicData && musicData.status !== "Stopped" && musicData.title !== "") {
//                     displayTitle = musicData.title;
//                     displayTime = musicData.timeStr;
//                     displayArtUrl = musicData.artUrl;
//                 }
//             }

//             property bool isMediaActive: barWindow.musicData.status !== "Stopped" && barWindow.musicData.title !== ""
//             property bool isWifiOn: barWindow.wifiStatus.toLowerCase() === "enabled" || barWindow.wifiStatus.toLowerCase() === "on"
//             property bool isBtOn: barWindow.btStatus.toLowerCase() === "enabled" || barWindow.btStatus.toLowerCase() === "on"
//             property bool showEthernet: barWindow.ethStatus === "Connected" || (barWindow.isDesktop && !barWindow.isWifiOn)
            
//             property bool isSoundActive: !barWindow.isMuted && parseInt(barWindow.volPercent) > 0
//             property int batCap: parseInt(barWindow.batPercent) || 0
//             property bool isCharging: barWindow.batStatus === "Charging" || barWindow.batStatus === "Full"
            
//             property color batDynamicColor: {
//                 if (isCharging) return mocha.green;
//                 if (batCap <= 20) return mocha.red;
//                 return mocha.text; 
//             }

//             Process {
//                 id: wsDaemon
//                 command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/workspaces.sh"]
//                 running: true
//             }

//             Process {
//                 id: wsReader
//                 command: ["cat", "/tmp/qs_workspaces.json"]
//                 stdout: StdioCollector {
//                     onStreamFinished: {
//                         let txt = this.text.trim();
//                         if (txt !== "") {
//                             try { 
//                                 let newData = JSON.parse(txt);
                                
//                                 while (workspacesModel.count < newData.length) {
//                                     workspacesModel.append({ "wsId": "", "wsState": "" });
//                                 }
                                
//                                 while (workspacesModel.count > newData.length) {
//                                     workspacesModel.remove(workspacesModel.count - 1);
//                                 }
                                
//                                 let newActive = -1;

//                                 for (let i = 0; i < newData.length; i++) {
//                                     if (newData[i].state === "active") newActive = i;

//                                     if (workspacesModel.get(i).wsState !== newData[i].state) {
//                                         workspacesModel.setProperty(i, "wsState", newData[i].state);
//                                     }
//                                     if (workspacesModel.get(i).wsId !== newData[i].id.toString()) {
//                                         workspacesModel.setProperty(i, "wsId", newData[i].id.toString());
//                                     }
//                                 }

//                                 if (newActive !== -1 && workspacesModel.activeIndex !== newActive) {
//                                     workspacesModel.activeIndex = newActive;
//                                 }

//                             } catch(e) {}
//                         }
//                     }
//                 }
//             }

//             Process {
//                 id: wsWatcher
//                 running: true
//                 command: ["bash", "-c", "inotifywait -qq -e close_write,modify /tmp/qs_workspaces.json"]
//                 onExited: {
//                     wsReader.running = false;
//                     wsReader.running = true;
//                     running = false;
//                     running = true;
//                 }
//             }

//             Process {
//                 id: musicForceRefresh
//                 running: true
//                 command: ["bash", "-c", "bash ~/.config/hypr/scripts/quickshell/music/music_info.sh | tee /tmp/music_info.json"]
//                 stdout: StdioCollector {
//                     onStreamFinished: {
//                         let txt = this.text.trim();
//                         if (txt !== "") {
//                             try { barWindow.musicData = JSON.parse(txt); } catch(e) {}
//                         }
//                     }
//                 }
//             }

//             Timer {
//                 interval: 1000
//                 running: true
//                 repeat: true
//                 onTriggered: {
//                     if (!barWindow.musicData || barWindow.musicData.status !== "Playing") return;
//                     if (!barWindow.musicData.timeStr || barWindow.musicData.timeStr === "") return;

//                     let parts = barWindow.musicData.timeStr.split(" / ");
//                     if (parts.length !== 2) return;

//                     let posParts = parts[0].split(":").map(Number);
//                     let lenParts = parts[1].split(":").map(Number);

//                     let posSecs = (posParts.length === 3) 
//                         ? (posParts[0] * 3600 + posParts[1] * 60 + posParts[2]) 
//                         : (posParts[0] * 60 + posParts[1]);

//                     let lenSecs = (lenParts.length === 3) 
//                         ? (lenParts[0] * 3600 + lenParts[1] * 60 + lenParts[2]) 
//                         : (lenParts[0] * 60 + lenParts[1]);

//                     if (isNaN(posSecs) || isNaN(lenSecs)) return;

//                     posSecs++;
//                     if (posSecs > lenSecs) posSecs = lenSecs;

//                     let newPosStr = "";
//                     if (posParts.length === 3) {
//                         let h = Math.floor(posSecs / 3600);
//                         let m = Math.floor((posSecs % 3600) / 60);
//                         let s = posSecs % 60;
//                         newPosStr = h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
//                     } else {
//                         let m = Math.floor(posSecs / 60);
//                         let s = posSecs % 60;
//                         newPosStr = (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
//                     }

//                     let newData = Object.assign({}, barWindow.musicData);
//                     newData.timeStr = newPosStr + " / " + parts[1];
//                     newData.positionStr = newPosStr;
//                     if (lenSecs > 0) newData.percent = (posSecs / lenSecs) * 100;
                    
//                     barWindow.musicData = newData;
//                 }
//             }

//             Process {
//                 id: mprisWatcher
//                 running: true
//                 command: ["bash", "-c", "dbus-monitor --session \"type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='org.mpris.MediaPlayer2.Player'\" \"type='signal',interface='org.mpris.MediaPlayer2.Player',member='Seeked'\" 2>/dev/null | grep -m 1 'member=' > /dev/null || sleep 2"]
//                 onExited: {
//                     musicForceRefresh.running = false;
//                     musicForceRefresh.running = true;
//                     running = false;
//                     running = true;
//                 }
//             }

//             Timer {
//                 id: artRetryTimer
//                 interval: 500
//                 repeat: true
//                 running: barWindow.displayArtUrl && barWindow.displayArtUrl.indexOf("placeholder_blank.png") !== -1
//                 onTriggered: {
//                     musicForceRefresh.running = false;
//                     musicForceRefresh.running = true;
//                 }
//             }

//             Process {
//                 id: kbPoller; running: true
//                 command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/kb_fetch.sh"]
//                 stdout: StdioCollector {
//                     onStreamFinished: {
//                         let txt = this.text.trim();
//                         if (txt !== "" && barWindow.kbLayout !== txt) barWindow.kbLayout = txt;
//                         kbWaiter.running = false;
//                         kbWaiter.running = true;
//                         barWindow.fastPollerLoaded = true; 
//                     }
//                 }
//             }
//             Process { id: kbWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/kb_wait.sh"]; onExited: { kbPoller.running = false; kbPoller.running = true; } }

//             Process {
//                 id: audioPoller; running: true
//                 command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_fetch.sh"]
//                 stdout: StdioCollector {
//                     onStreamFinished: {
//                         let txt = this.text.trim();
//                         if (txt !== "") {
//                             try {
//                                 let data = JSON.parse(txt);
//                                 let newVol = data.volume.toString() + "%";
//                                 if (barWindow.volPercent !== newVol) barWindow.volPercent = newVol;
//                                 if (barWindow.volIcon !== data.icon) barWindow.volIcon = data.icon;
//                                 let newMuted = (data.is_muted === "true");
//                                 if (barWindow.isMuted !== newMuted) barWindow.isMuted = newMuted;
//                             } catch(e) {}
//                         }
//                         audioWaiter.running = false;
//                         audioWaiter.running = true;
//                     }
//                 }
//             }
//             Process { id: audioWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_wait.sh"]; onExited: { audioPoller.running = false; audioPoller.running = true; } }

//             Process {
//                 id: networkPoller; running: true
//                 command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_fetch.sh"]
//                 stdout: StdioCollector {
//                     onStreamFinished: {
//                         let txt = this.text.trim();
//                         if (txt !== "") {
//                             try {
//                                 let data = JSON.parse(txt);
//                                 if (barWindow.wifiStatus !== data.status) barWindow.wifiStatus = data.status;
//                                 if (barWindow.wifiIcon !== data.icon) barWindow.wifiIcon = data.icon;
//                                 if (barWindow.wifiSsid !== data.ssid) barWindow.wifiSsid = data.ssid;
//                                 if (barWindow.ethStatus !== data.eth_status) barWindow.ethStatus = data.eth_status;
//                             } catch(e) {}
//                         }
//                         networkWaiter.running = false;
//                         networkWaiter.running = true;
//                     }
//                 }
//             }
//             Process { id: networkWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_wait.sh"]; onExited: { networkPoller.running = false; networkPoller.running = true; } }

//             Process {
//                 id: btPoller; running: true
//                 command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_fetch.sh"]
//                 stdout: StdioCollector {
//                     onStreamFinished: {
//                         let txt = this.text.trim();
//                         if (txt !== "") {
//                             try {
//                                 let data = JSON.parse(txt);
//                                 if (barWindow.btStatus !== data.status) barWindow.btStatus = data.status;
//                                 if (barWindow.btIcon !== data.icon) barWindow.btIcon = data.icon;
//                                 if (barWindow.btDevice !== data.connected) barWindow.btDevice = data.connected;
//                             } catch(e) {}
//                         }
//                         btWaiter.running = false;
//                         btWaiter.running = true;
//                     }
//                 }
//             }
//             Process { id: btWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_wait.sh"]; onExited: { btPoller.running = false; btPoller.running = true; } }

//             Process {
//                 id: batteryPoller; running: true
//                 command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_fetch.sh"]
//                 stdout: StdioCollector {
//                     onStreamFinished: {
//                         let txt = this.text.trim();
//                         if (txt !== "") {
//                             try {
//                                 let data = JSON.parse(txt);
//                                 let newBat = data.percent.toString() + "%";
//                                 if (barWindow.batPercent !== newBat) barWindow.batPercent = newBat;
//                                 if (barWindow.batIcon !== data.icon) barWindow.batIcon = data.icon;
//                                 if (barWindow.batStatus !== data.status) barWindow.batStatus = data.status;
//                             } catch(e) {}
//                         }
//                         batteryWaiter.running = false;
//                         batteryWaiter.running = true;
//                     }
//                 }
//             }
//             Process { id: batteryWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_wait.sh"]; onExited: { batteryPoller.running = false; batteryPoller.running = true; } }


//             Process {
//                 id: weatherPoller
//                 command: ["bash", "-c", `
//                     echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-icon)"
//                     echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-temp)"
//                     echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-hex)"
//                 `]
//                 stdout: StdioCollector {
//                     onStreamFinished: {
//                         let lines = this.text.trim().split("\n");
//                         if (lines.length >= 3) {
//                             barWindow.weatherIcon = lines[0];
//                             barWindow.weatherTemp = lines[1];
//                             barWindow.weatherHex = lines[2] || mocha.yellow;
//                         }
//                     }
//                 }
//             }
//             Timer { interval: 150000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { weatherPoller.running = false; weatherPoller.running = true; } }


//             Timer {
//                 interval: 1000; running: true; repeat: true; triggeredOnStart: true
//                 onTriggered: {
//                     let d = new Date();
//                     barWindow.timeStr = Qt.formatDateTime(d, "HH:mm:ss");
//                     barWindow.fullDateStr = Qt.formatDateTime(d, "dddd, MMMM dd");
//                     if (barWindow.typeInIndex >= barWindow.fullDateStr.length) {
//                         barWindow.typeInIndex = barWindow.fullDateStr.length;
//                     }
//                 }
//             }

//             Timer {
//                 id: typewriterTimer
//                 interval: 40
//                 running: barWindow.isStartupReady && barWindow.typeInIndex < barWindow.fullDateStr.length
//                 repeat: true
//                 onTriggered: barWindow.typeInIndex += 1
//             }

//             Item {
//                 anchors.fill: parent

//                 Rectangle {
//                     id: leftContent
//                     y: (parent.height - barWindow.barHeight) / 2
//                     height: barWindow.barHeight

//                     color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
//                     radius: barWindow.s(14)
//                     border.width: 1
//                     border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)
//                     clip: true
                    
//                     property bool showLayout: false
                    
//                     opacity: (showLayout && !barWindow.isSettingsOpen) ? 1 : 0
//                     enabled: !barWindow.isSettingsOpen
                    
//                     property real targetX: (showLayout && !barWindow.isSettingsOpen) ? 0 : barWindow.s(-200)
//                     x: targetX
//                     Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
//                     Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    
//                     Timer {
//                         running: barWindow.isStartupReady
//                         interval: 10
//                         onTriggered: leftContent.showLayout = true
//                     }

//                     width: leftLayout.width + barWindow.s(16)

//                     Row {
//                         id: leftLayout
//                         anchors.verticalCenter: parent.verticalCenter
//                         anchors.left: parent.left
//                         anchors.leftMargin: barWindow.s(8)
//                         spacing: barWindow.s(4)
                        
//                         property int pillHeight: barWindow.s(34)

//                         Rectangle {
//                             property bool isHovered: helpMouse.containsMouse
//                             color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : "transparent"
//                             radius: barWindow.s(10)
                            
//                             property real targetWidth: barWindow.showHelpIcon ? barWindow.s(34) : 0
//                             width: targetWidth
//                             height: parent.pillHeight
//                             visible: targetWidth > 0 || opacity > 0
//                             opacity: barWindow.showHelpIcon ? 1.0 : 0.0
//                             clip: true
                            
//                             Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
//                             Behavior on opacity { NumberAnimation { duration: 300 } }
//                             Behavior on color { ColorAnimation { duration: 200 } }
                            
//                             Text {
//                                 anchors.centerIn: parent
//                                 text: "󰋗"
//                                 font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(22)
//                                 color: parent.isHovered ? mocha.teal : mocha.text
//                                 Behavior on color { ColorAnimation { duration: 200 } }
//                                 scale: parent.isHovered ? 1.15 : 1.0
//                                 Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                             }
//                             MouseArea {
//                                 id: helpMouse
//                                 anchors.fill: parent
//                                 hoverEnabled: true
//                                 onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle guide"])
//                             }
//                         }

//                         Rectangle {
//                             property bool isHovered: searchMouse.containsMouse
//                             color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : "transparent"
//                             radius: barWindow.s(10)
//                             height: parent.pillHeight; width: barWindow.s(34)
                            
//                             Behavior on color { ColorAnimation { duration: 200 } }
                            
//                             Text {
//                                 anchors.centerIn: parent
//                                 text: "󰍉"
//                                 font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(22)
//                                 color: parent.isHovered ? mocha.blue : mocha.text
//                                 Behavior on color { ColorAnimation { duration: 200 } }
//                                 scale: parent.isHovered ? 1.15 : 1.0
//                                 Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                             }
//                             MouseArea {
//                                 id: searchMouse
//                                 anchors.fill: parent
//                                 hoverEnabled: true
//                                 onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle applauncher"])
//                             }
//                         }

//                         Rectangle {
//                             property bool isHovered: settingsMouse.containsMouse
//                             color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : "transparent"
//                             radius: barWindow.s(10)
//                             height: parent.pillHeight; width: barWindow.s(34)
                            
//                             Behavior on color { ColorAnimation { duration: 200 } }
                            
//                             Text {
//                                 anchors.centerIn: parent
//                                 text: ""
//                                 font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(22)
//                                 color: parent.isHovered ? mocha.blue : mocha.text
//                                 Behavior on color { ColorAnimation { duration: 200 } }
//                                 scale: parent.isHovered ? 1.15 : 1.0
//                                 Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                             }
//                             MouseArea {
//                                 id: settingsMouse
//                                 anchors.fill: parent
//                                 hoverEnabled: true
//                                 onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle settings"])
//                             }
//                         }

//                         Rectangle {
//                             id: updateButton
//                             property bool isHovered: updateMouse.containsMouse
//                             color: isHovered ? Qt.rgba(mocha.green.r, mocha.green.g, mocha.green.b, 0.15) : "transparent"
//                             radius: barWindow.s(10)
                            
//                             width: barWindow.isUpdateVisible ? barWindow.s(34) : 0
//                             height: parent.pillHeight
                            
//                             visible: width > 0 || opacity > 0
//                             opacity: barWindow.isUpdateVisible ? 1.0 : 0.0
//                             clip: false 
                            
//                             Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
//                             Behavior on opacity { NumberAnimation { duration: 300 } }
//                             Behavior on color { ColorAnimation { duration: 200 } }
                            
//                             Rectangle {
//                                 anchors.centerIn: parent
//                                 width: parent.width
//                                 height: parent.height
//                                 radius: parent.radius
//                                 color: mocha.green
//                                 z: -1
                                
//                                 SequentialAnimation on scale {
//                                     running: barWindow.isUpdateVisible && !updateButton.isHovered
//                                     loops: Animation.Infinite
//                                     NumberAnimation { from: 1.0; to: 1.3; duration: 2000; easing.type: Easing.OutCubic }
//                                 }
//                                 SequentialAnimation on opacity {
//                                     running: barWindow.isUpdateVisible && !updateButton.isHovered
//                                     loops: Animation.Infinite
//                                     NumberAnimation { from: 0.15; to: 0.0; duration: 2000; easing.type: Easing.OutCubic }
//                                 }
//                             }
                            
//                             Text {
//                                 anchors.centerIn: parent
//                                 text: "󰚰"
//                                 font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(22)
//                                 color: parent.isHovered ? mocha.text : mocha.green
//                                 Behavior on color { ColorAnimation { duration: 200 } }
                                
//                                 rotation: parent.isHovered ? 360 : 0
//                                 Behavior on rotation {
//                                     NumberAnimation { 
//                                         duration: 600
//                                         easing.type: Easing.OutBack
//                                     }
//                                 }

//                                 scale: parent.isHovered ? 1.15 : 1.0
//                                 Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                             }

//                             MouseArea {
//                                 id: updateMouse
//                                 anchors.fill: parent
//                                 hoverEnabled: true
//                                 onClicked: {
//                                     barWindow.updateAvailable = false;
//                                     barWindow.forceUpdateShow = false;
//                                     Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle updater"]);
//                                 }
//                             }
//                         }
//                     }
//                 }
                
//                 Rectangle {
//                     id: workspacesBox
//                     color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
//                     radius: barWindow.s(14); border.width: 1; border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.05)
//                     height: barWindow.barHeight
//                     y: (parent.height - barWindow.barHeight) / 2
//                     clip: true
                    
//                     width: workspacesModel.count > 0 ? wsLayout.implicitWidth + barWindow.s(20) : 0
                    
//                     property real defaultX: leftContent.x + leftContent.width + barWindow.s(4)
//                     property real settingsX: mediaBox.settingsX - width - (width > 0 ? barWindow.s(4) : 0)
                                        
//                     x: defaultX + (settingsX - defaultX) * barWindow.settingsSlideProgress

//                     property bool limitActive: barWindow.isSettingsOpen && barWindow.isMediaActive

//                     visible: width > 0 || opacity > 0
//                     opacity: workspacesModel.count > 0 ? 1 : 0
//                     Behavior on opacity { NumberAnimation { duration: 300 } }

//                     Rectangle {
//                         id: activeHighlight
//                         y: (workspacesBox.height - barWindow.s(32)) / 2
//                         height: barWindow.s(32)
//                         radius: barWindow.s(10)
//                         color: mocha.mauve
//                         z: 0

//                         property int prevIdx: 0
//                         property int curIdx: workspacesModel.activeIndex

//                         onCurIdxChanged: {
//                             if (curIdx > prevIdx) {
//                                 rightAnim.duration = 200; leftAnim.duration = 350;
//                             } else if (curIdx < prevIdx) {
//                                 leftAnim.duration = 200; rightAnim.duration = 350;
//                             }
//                             prevIdx = curIdx;
//                         }

//                         // FIXED: Calculate step size to perfectly match the rounded width + rounded spacing of the Row elements.
//                         property real stepSize: barWindow.s(32) + barWindow.s(6)
//                         property real targetLeft: wsLayout.x + (curIdx * stepSize)
//                         property real targetRight: targetLeft + barWindow.s(32)

//                         property real actualLeft: targetLeft
//                         property real actualRight: targetRight

//                         Behavior on actualLeft { NumberAnimation { id: leftAnim; duration: 250; easing.type: Easing.OutExpo } }
//                         Behavior on actualRight { NumberAnimation { id: rightAnim; duration: 250; easing.type: Easing.OutExpo } }

//                         x: actualLeft
//                         width: actualRight - actualLeft
//                         opacity: workspacesModel.count > 0 ? 1 : 0
//                     }

//                     Row {
//                         id: wsLayout
//                         anchors.centerIn: parent
//                         spacing: barWindow.s(6)
                        
//                         Repeater {
//                             model: workspacesModel
//                             delegate: Rectangle {
//                                 id: wsPill
                                
//                                 property bool isLimited: workspacesBox.limitActive && index >= 6
//                                 visible: !isLimited
                                
//                                 property bool isHovered: wsPillMouse.containsMouse
                                
//                                 property string stateLabel: model.wsState
//                                 property string wsName: model.wsId
                                
//                                 property real targetWidth: barWindow.s(32)
//                                 width: targetWidth
//                                 Behavior on targetWidth { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                
//                                 height: barWindow.s(32); radius: barWindow.s(10)
                                
//                                 color: isHovered ? Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.1) : (stateLabel === "occupied" ? Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.15) : "transparent")

//                                 scale: isHovered && stateLabel !== "active" ? 1.08 : 1.0
//                                 Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                
//                                 property bool initAnimTrigger: false
//                                 opacity: initAnimTrigger ? 1 : 0
//                                 transform: Translate {
//                                     y: wsPill.initAnimTrigger ? 0 : barWindow.s(15)
//                                     Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
//                                 }

//                                 Component.onCompleted: {
//                                     if (!barWindow.startupCascadeFinished) {
//                                         animTimer.interval = index * 60;
//                                         animTimer.start();
//                                     } else {
//                                         initAnimTrigger = true;
//                                     }
//                                 }

//                                 Timer {
//                                     id: animTimer
//                                     running: false
//                                     repeat: false
//                                     onTriggered: wsPill.initAnimTrigger = true
//                                 }
                                
//                                 Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
//                                 Behavior on color { ColorAnimation { duration: 250 } }

//                                 Text {
//                                     anchors.centerIn: parent
//                                     text: wsName
//                                     font.family: "JetBrains Mono"
//                                     font.pixelSize: barWindow.s(14)
//                                     font.weight: stateLabel === "active" ? Font.Black : (stateLabel === "occupied" ? Font.Bold : Font.Medium)
                                    
//                                     color: index === workspacesModel.activeIndex ? mocha.crust : (isHovered ? mocha.text : (stateLabel === "occupied" ? mocha.text : mocha.overlay0))
                                    
//                                     Behavior on color { ColorAnimation { duration: 250 } }
//                                 }
//                                 MouseArea {
//                                     id: wsPillMouse
//                                     hoverEnabled: true
//                                     anchors.fill: parent
//                                     onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh " + wsName])
//                                 }
//                             }
//                         }
//                     }
//                 }

//                 Rectangle {
//                     id: mediaBox
//                     color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
//                     radius: barWindow.s(14); border.width: 1; border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.05)
//                     y: (parent.height - barWindow.barHeight) / 2
//                     height: barWindow.barHeight
//                     clip: true 
                    
//                     width: barWindow.isMediaActive ? innerMediaLayout.implicitWidth + barWindow.s(24) : 0
//                     Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

//                     property real defaultX: workspacesBox.defaultX + workspacesBox.width + (workspacesBox.width > 0 ? barWindow.s(4) : 0)
//                     property real settingsX: centerBox.settingsX - width - (width > 0 ? barWindow.s(4) : 0)

//                     x: defaultX + (settingsX - defaultX) * barWindow.settingsSlideProgress

//                     visible: width > 0 || opacity > 0
//                     opacity: barWindow.isMediaActive ? 1.0 : 0.0
//                     Behavior on opacity { NumberAnimation { duration: 400 } }
                    
//                     Item {
//                         id: mediaLayoutContainer
//                         anchors.verticalCenter: parent.verticalCenter
//                         anchors.left: parent.left
//                         anchors.leftMargin: barWindow.s(12)
//                         height: parent.height
//                         width: innerMediaLayout.implicitWidth
                        
//                         opacity: barWindow.isMediaActive ? 1.0 : 0.0
//                         transform: Translate { 
//                             x: barWindow.isMediaActive ? 0 : barWindow.s(-20) 
//                             Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutQuint } }
//                         }
//                         Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

//                         Row {
//                             id: innerMediaLayout
//                             anchors.verticalCenter: parent.verticalCenter
//                             spacing: barWindow.width < 1920 ? barWindow.s(8) : barWindow.s(16)
                            
//                             MouseArea {
//                                 id: mediaInfoMouse
//                                 width: infoLayout.width
//                                 height: innerMediaLayout.height
//                                 hoverEnabled: true
//                                 onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle music"])
                                
//                                 Row {
//                                     id: infoLayout
//                                     anchors.verticalCenter: parent.verticalCenter
//                                     spacing: barWindow.s(10)
                                    
//                                     scale: mediaInfoMouse.containsMouse ? 1.02 : 1.0
//                                     Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

//                                     Rectangle {
//                                         width: barWindow.s(32); height: barWindow.s(32); radius: barWindow.s(8); color: mocha.surface1
//                                         border.width: barWindow.musicData.status === "Playing" ? 1 : 0
//                                         border.color: mocha.mauve
//                                         clip: true
//                                         Image { 
//                                             anchors.fill: parent; 
//                                             source: barWindow.displayArtUrl || ""; 
//                                             fillMode: Image.PreserveAspectCrop 
//                                         }
                                        
//                                         Rectangle {
//                                             anchors.fill: parent
//                                             color: Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.2)
//                                         }
//                                     }
//                                     Column {
//                                         spacing: -2
//                                         anchors.verticalCenter: parent.verticalCenter
//                                         property real maxColWidth: barWindow.width < 1920 ? barWindow.s(120) : barWindow.s(180)
//                                         width: maxColWidth 
                                        
//                                         Text { 
//                                             text: barWindow.displayTitle; 
//                                             font.family: "JetBrains Mono"; 
//                                             font.weight: Font.Black; 
//                                             font.pixelSize: barWindow.s(13); 
//                                             color: mocha.text;
//                                             width: parent.width
//                                             elide: Text.ElideRight; 
//                                         }
//                                         Text { 
//                                             text: barWindow.displayTime; 
//                                             font.family: "JetBrains Mono"; 
//                                             font.weight: Font.Black; 
//                                             font.pixelSize: barWindow.s(10); 
//                                             color: mocha.subtext0;
//                                             width: parent.width
//                                             elide: Text.ElideRight;
//                                         }
//                                     }
//                                 }
//                             }

//                             Row {
//                                 anchors.verticalCenter: parent.verticalCenter
//                                 spacing: barWindow.width < 1920 ? barWindow.s(4) : barWindow.s(8)
//                                 Item { 
//                                     width: barWindow.s(24); height: barWindow.s(24); 
//                                     anchors.verticalCenter: parent.verticalCenter
//                                     Text { 
//                                         anchors.centerIn: parent; text: "󰒮"; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(26); 
//                                         color: prevMouse.containsMouse ? mocha.text : mocha.overlay2; 
//                                         Behavior on color { ColorAnimation { duration: 150 } }
//                                         scale: prevMouse.containsMouse ? 1.1 : 1.0
//                                         Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
//                                     }
//                                     MouseArea { id: prevMouse; hoverEnabled: true; anchors.fill: parent; onClicked: { Quickshell.execDetached(["playerctl", "previous"]); musicForceRefresh.running = true; } } 
//                                 }
//                                 Item { 
//                                     width: barWindow.s(28); height: barWindow.s(28); 
//                                     anchors.verticalCenter: parent.verticalCenter
//                                     Text { 
//                                         anchors.centerIn: parent; text: barWindow.musicData.status === "Playing" ? "󰏤" : "󰐊"; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(30); 
//                                         color: playMouse.containsMouse ? mocha.green : mocha.text; 
//                                         Behavior on color { ColorAnimation { duration: 150 } }
//                                         scale: playMouse.containsMouse ? 1.15 : 1.0
//                                         Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
//                                     }
//                                     MouseArea { id: playMouse; hoverEnabled: true; anchors.fill: parent; onClicked: { Quickshell.execDetached(["playerctl", "play-pause"]); musicForceRefresh.running = true; } } 
//                                 }
//                                 Item { 
//                                     width: barWindow.s(24); height: barWindow.s(24); 
//                                     anchors.verticalCenter: parent.verticalCenter
//                                     Text { 
//                                         anchors.centerIn: parent; text: "󰒭"; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(26); 
//                                         color: nextMouse.containsMouse ? mocha.text : mocha.overlay2; 
//                                         Behavior on color { ColorAnimation { duration: 150 } }
//                                         scale: nextMouse.containsMouse ? 1.1 : 1.0
//                                         Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
//                                     }
//                                     MouseArea { id: nextMouse; hoverEnabled: true; anchors.fill: parent; onClicked: { Quickshell.execDetached(["playerctl", "next"]); musicForceRefresh.running = true; } } 
//                                 }
//                             }
//                         }
//                     }
//                 }

//                 Rectangle {
//                     id: centerBox
//                     property bool isHovered: centerMouse.containsMouse
//                     color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.95) : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
//                     radius: barWindow.s(14); border.width: 1; border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, isHovered ? 0.15 : 0.05)
                    
//                     y: (parent.height - barWindow.barHeight) / 2
//                     height: barWindow.barHeight
                    
//                     width: centerLayout.implicitWidth + barWindow.s(36)
//                     Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                    
//                     property real pureCenter: (parent.width - width) / 2
//                     property real minCenterDefaultX: mediaBox.defaultX + mediaBox.width + (mediaBox.width > 0 ? barWindow.s(4) : 0)
//                     property real settingsX: barWindow.width - rightContent.width - width - barWindow.s(4)
//                     property real defaultX: Math.max(minCenterDefaultX, pureCenter)
                    
//                     x: defaultX + (settingsX - defaultX) * barWindow.settingsSlideProgress
                    
//                     property bool showLayout: false
//                     opacity: showLayout ? 1 : 0
//                     transform: Translate {
//                         y: centerBox.showLayout ? 0 : barWindow.s(-30)
//                         Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
//                     }

//                     Timer {
//                         running: barWindow.isStartupReady
//                         interval: 150
//                         onTriggered: centerBox.showLayout = true
//                     }

//                     Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

//                     scale: isHovered ? 1.03 : 1.0
//                     Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
//                     Behavior on color { ColorAnimation { duration: 250 } }
                    
//                     MouseArea {
//                         id: centerMouse
//                         anchors.fill: parent
//                         hoverEnabled: true
//                         onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle calendar"])
//                     }

//                     RowLayout {
//                         id: centerLayout
//                         anchors.centerIn: parent
//                         spacing: barWindow.s(24)

//                         ColumnLayout {
//                             spacing: -2
//                             Text { text: barWindow.timeStr; Layout.alignment: Qt.AlignLeft; font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(16); font.weight: Font.Black; color: mocha.blue }
//                             Text { text: barWindow.dateStr; Layout.alignment: Qt.AlignLeft; font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(11); font.weight: Font.Bold; color: mocha.subtext0 }
//                         }

//                         RowLayout {
//                             spacing: barWindow.s(8)
//                             Text { 
//                                 text: barWindow.weatherIcon; 
//                                 Layout.alignment: Qt.AlignVCenter;
//                                 font.family: "Iosevka Nerd Font"; 
//                                 font.pixelSize: barWindow.s(24); 
//                                 color: Qt.tint(barWindow.weatherHex, Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.4)) 
//                             }
//                             Text { 
//                                 text: barWindow.weatherTemp; 
//                                 Layout.alignment: Qt.AlignVCenter;
//                                 font.family: "JetBrains Mono"; 
//                                 font.pixelSize: barWindow.s(17); 
//                                 font.weight: Font.Black; 
//                                 color: mocha.peach 
//                             }
//                         }
//                     }
//                 }

//                 Row {
//                     id: rightContent
//                     anchors.right: parent.right
//                     anchors.verticalCenter: parent.verticalCenter
//                     spacing: barWindow.s(4)
                    
//                     property bool showLayout: false
//                     opacity: showLayout ? 1 : 0
//                     transform: Translate {
//                         x: rightContent.showLayout ? 0 : barWindow.s(30)
//                         Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
//                     }
                    
//                     Timer {
//                         running: barWindow.isStartupReady && barWindow.isDataReady
//                         interval: 250
//                         onTriggered: rightContent.showLayout = true
//                     }

//                     Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

//                     Rectangle {
//                         height: barWindow.barHeight
//                         radius: barWindow.s(14)
//                         border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)
//                         border.width: 1
//                         color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                        
//                         property real targetWidth: trayRepeater.count > 0 ? trayLayout.width + barWindow.s(24) : 0
//                         width: targetWidth
//                         Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                        
//                         visible: targetWidth > 0
//                         opacity: targetWidth > 0 ? 1 : 0
//                         Behavior on opacity { NumberAnimation { duration: 300 } }

//                         Row {
//                             id: trayLayout
//                             anchors.centerIn: parent
//                             spacing: barWindow.s(10)

//                             Repeater {
//                                 id: trayRepeater
//                                 model: SystemTray.items
//                                 delegate: Image {
//                                     id: trayIcon
//                                     source: modelData.icon || ""
//                                     fillMode: Image.PreserveAspectFit
                                    
//                                     sourceSize: Qt.size(barWindow.s(18), barWindow.s(18))
//                                     width: barWindow.s(18)
//                                     height: barWindow.s(18)
//                                     anchors.verticalCenter: parent.verticalCenter
                                    
//                                     property bool isHovered: trayMouse.containsMouse
//                                     property bool initAnimTrigger: false
//                                     opacity: initAnimTrigger ? (isHovered ? 1.0 : 0.8) : 0.0
//                                     scale: initAnimTrigger ? (isHovered ? 1.15 : 1.0) : 0.0

//                                     Component.onCompleted: {
//                                         if (!barWindow.startupCascadeFinished) {
//                                             trayAnimTimer.interval = index * 50;
//                                             trayAnimTimer.start();
//                                         } else {
//                                             initAnimTrigger = true;
//                                         }
//                                     }
//                                     Timer {
//                                         id: trayAnimTimer
//                                         running: false
//                                         repeat: false
//                                         onTriggered: trayIcon.initAnimTrigger = true
//                                     }

//                                     Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
//                                     Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

//                                     QsMenuAnchor {
//                                         id: menuAnchor
//                                         anchor.window: barWindow
//                                         anchor.item: trayIcon
//                                         menu: modelData.menu
//                                     }

//                                     MouseArea {
//                                         id: trayMouse
//                                         anchors.fill: parent
//                                         hoverEnabled: true
//                                         acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
//                                         onClicked: mouse => {
//                                             if (mouse.button === Qt.LeftButton) {
//                                                 if (modelData.isMenuOnly || modelData.onlyMenu) {
//                                                     menuAnchor.open();
//                                                 } else if (typeof modelData.activate === "function") {
//                                                     modelData.activate(); 
//                                                 }
//                                             } else if (mouse.button === Qt.MiddleButton) {
//                                                 if (typeof modelData.secondaryActivate === "function") {
//                                                     modelData.secondaryActivate();
//                                                 }
//                                             } else if (mouse.button === Qt.RightButton) {
//                                                 if (modelData.menu) { 
//                                                     menuAnchor.open();
//                                                 } else if (typeof modelData.contextMenu === "function") {
//                                                     modelData.contextMenu(mouse.x, mouse.y);
//                                                 } else {
//                                                     modelData.activate(); 
//                                                 }
//                                             }
//                                         }
//                                     }
//                                 }
//                             }
//                         }
//                     }

//                     Rectangle {
//                         height: barWindow.barHeight
//                         radius: barWindow.s(14)
//                         border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)
//                         border.width: 1
//                         color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
//                         clip: true
                        
//                         width: sysLayout.implicitWidth + barWindow.s(20)

//                         Row {
//                             id: sysLayout
//                             anchors.centerIn: parent
//                             spacing: barWindow.s(8) 

//                             property int pillHeight: barWindow.s(34)

//                             Rectangle {
//                                 property bool isHovered: kbMouse.containsMouse
//                                 color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
//                                 radius: barWindow.s(10); height: sysLayout.pillHeight;
//                                 clip: true
                                
//                                 property real targetWidth: kbLayoutRow.implicitWidth + barWindow.s(24)
//                                 width: targetWidth
//                                 Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                                
//                                 scale: isHovered ? 1.05 : 1.0
//                                 Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                                 Behavior on color { ColorAnimation { duration: 200 } }

//                                 property bool initAnimTrigger: false
//                                 Timer { running: rightContent.showLayout && !parent.initAnimTrigger; interval: 0; onTriggered: parent.initAnimTrigger = true }
//                                 opacity: initAnimTrigger ? 1 : 0
//                                 transform: Translate { y: parent.initAnimTrigger ? 0 : barWindow.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
//                                 Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

//                                 Row { 
//                                     id: kbLayoutRow
//                                     anchors.verticalCenter: parent.verticalCenter
//                                     anchors.left: parent.left
//                                     anchors.leftMargin: barWindow.s(12)
//                                     spacing: barWindow.s(8)
//                                     Text { anchors.verticalCenter: parent.verticalCenter; text: "󰌌"; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(16); color: parent.parent.isHovered ? mocha.text : mocha.overlay2 }
//                                     Text { anchors.verticalCenter: parent.verticalCenter; text: barWindow.kbLayout; font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(13); font.weight: Font.Black; color: mocha.text }
//                                 }
//                                 MouseArea { id: kbMouse; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "main", "next"]) }
//                             }

//                             Rectangle {
//                                 id: wifiPill
//                                 property bool isHovered: wifiMouse.containsMouse
//                                 radius: barWindow.s(10); height: sysLayout.pillHeight; 
//                                 color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
//                                 clip: true
                                
//                                 Rectangle {
//                                     anchors.fill: parent
//                                     radius: barWindow.s(10)
//                                     opacity: barWindow.showEthernet ? (barWindow.ethStatus === "Connected" ? 1.0 : 0.0) : (barWindow.isWifiOn ? 1.0 : 0.0)
//                                     Behavior on opacity { NumberAnimation { duration: 300 } }
//                                     gradient: Gradient {
//                                         orientation: Gradient.Horizontal
//                                         GradientStop { position: 0.0; color: mocha.blue }
//                                         GradientStop { position: 1.0; color: Qt.lighter(mocha.blue, 1.3) }
//                                     }
//                                 }

//                                 property real targetWidth: wifiLayoutRow.implicitWidth + barWindow.s(24)
//                                 width: targetWidth
//                                 Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                                
//                                 scale: isHovered ? 1.05 : 1.0
//                                 Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                                 Behavior on color { ColorAnimation { duration: 200 } }

//                                 property bool initAnimTrigger: false
//                                 Timer { running: rightContent.showLayout && !parent.initAnimTrigger; interval: 50; onTriggered: parent.initAnimTrigger = true }
//                                 opacity: initAnimTrigger ? 1 : 0
//                                 transform: Translate { y: parent.initAnimTrigger ? 0 : barWindow.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
//                                 Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

//                                 Row { 
//                                     id: wifiLayoutRow
//                                     anchors.verticalCenter: parent.verticalCenter
//                                     anchors.left: parent.left
//                                     anchors.leftMargin: barWindow.s(12)
//                                     spacing: barWindow.s(8)
//                                     Text { 
//                                         anchors.verticalCenter: parent.verticalCenter; 
//                                         text: barWindow.showEthernet ? "󰈀" : barWindow.wifiIcon;
//                                         font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(16);
//                                         color: barWindow.showEthernet ? (barWindow.ethStatus === "Connected" ? mocha.base : mocha.subtext0) : (barWindow.isWifiOn ? mocha.base : mocha.subtext0)
//                                     }
//                                     Text { 
//                                         id: wifiText
//                                         anchors.verticalCenter: parent.verticalCenter
//                                         text: barWindow.showEthernet ? barWindow.ethStatus : ((barWindow.isWifiOn ? (barWindow.wifiSsid !== "" ? barWindow.wifiSsid : "On") : "Off"))
//                                         visible: text !== ""
//                                         font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(13); font.weight: Font.Black;
//                                         color: barWindow.showEthernet ? (barWindow.ethStatus === "Connected" ? mocha.base : mocha.text) : (barWindow.isWifiOn ? mocha.base : mocha.text);
//                                         width: Math.min(implicitWidth, barWindow.s(100)); elide: Text.ElideRight 
//                                     }
//                                 }
//                                 MouseArea { id: wifiMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle network wifi"]) }
//                             }

//                             Rectangle {
//                                 id: btPill
//                                 property bool isHovered: btMouse.containsMouse
//                                 radius: barWindow.s(10); height: sysLayout.pillHeight
//                                 clip: true
//                                 color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                                
//                                 Rectangle {
//                                     anchors.fill: parent
//                                     radius: barWindow.s(10)
//                                     opacity: barWindow.isBtOn ? 1.0 : 0.0
//                                     Behavior on opacity { NumberAnimation { duration: 300 } }
//                                     gradient: Gradient {
//                                         orientation: Gradient.Horizontal
//                                         GradientStop { position: 0.0; color: mocha.mauve }
//                                         GradientStop { position: 1.0; color: Qt.lighter(mocha.mauve, 1.3) }
//                                     }
//                                 }

//                                 property real targetWidth: barWindow.isDesktop ? 0 : btLayoutRow.implicitWidth + barWindow.s(24)
//                                 width: targetWidth
//                                 visible: targetWidth > 0
//                                 Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

//                                 scale: isHovered ? 1.05 : 1.0
//                                 Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                                 Behavior on color { ColorAnimation { duration: 200 } }

//                                 property bool initAnimTrigger: false
//                                 Timer { running: rightContent.showLayout && !parent.initAnimTrigger; interval: 100; onTriggered: parent.initAnimTrigger = true }
//                                 opacity: initAnimTrigger ? 1 : 0
//                                 transform: Translate { y: parent.initAnimTrigger ? 0 : barWindow.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
//                                 Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

//                                 Row { 
//                                     id: btLayoutRow
//                                     anchors.verticalCenter: parent.verticalCenter
//                                     anchors.left: parent.left
//                                     anchors.leftMargin: barWindow.s(12)
//                                     spacing: barWindow.s(8)
//                                     Text { anchors.verticalCenter: parent.verticalCenter; text: barWindow.btIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(16); color: barWindow.isBtOn ? mocha.base : mocha.subtext0 }
//                                     Text { 
//                                         id: btText
//                                         anchors.verticalCenter: parent.verticalCenter
//                                         text: barWindow.btDevice
//                                         visible: text !== ""; 
//                                         font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(13); font.weight: Font.Black; 
//                                         color: barWindow.isBtOn ? mocha.base : mocha.text; 
//                                         width: Math.min(implicitWidth, barWindow.s(100)); elide: Text.ElideRight 
//                                     }
//                                 }
//                                 MouseArea { id: btMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle network bt"]) }
//                             }

//                             Rectangle {
//                                 property bool isHovered: volMouse.containsMouse
//                                 color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
//                                 radius: barWindow.s(10); height: sysLayout.pillHeight;
//                                 clip: true

//                                 Rectangle {
//                                     anchors.fill: parent
//                                     radius: barWindow.s(10)
//                                     opacity: barWindow.isSoundActive ? 1.0 : 0.0
//                                     Behavior on opacity { NumberAnimation { duration: 300 } }
//                                     gradient: Gradient {
//                                         orientation: Gradient.Horizontal
//                                         GradientStop { position: 0.0; color: mocha.peach }
//                                         GradientStop { position: 1.0; color: Qt.lighter(mocha.peach, 1.3) }
//                                     }
//                                 }
                                
//                                 property real targetWidth: volLayoutRow.implicitWidth + barWindow.s(24)
//                                 width: targetWidth
//                                 Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                                
//                                 scale: isHovered ? 1.05 : 1.0
//                                 Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                                 Behavior on color { ColorAnimation { duration: 200 } }

//                                 property bool initAnimTrigger: false
//                                 Timer { running: rightContent.showLayout && !parent.initAnimTrigger; interval: 150; onTriggered: parent.initAnimTrigger = true }
//                                 opacity: initAnimTrigger ? 1 : 0
//                                 transform: Translate { y: parent.initAnimTrigger ? 0 : barWindow.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
//                                 Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

//                                 Row { 
//                                     id: volLayoutRow
//                                     anchors.verticalCenter: parent.verticalCenter
//                                     anchors.left: parent.left
//                                     anchors.leftMargin: barWindow.s(12)
//                                     spacing: barWindow.s(8)
//                                     Text { 
//                                         anchors.verticalCenter: parent.verticalCenter
//                                         text: barWindow.volIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(16); 
//                                         color: barWindow.isSoundActive ? mocha.base : mocha.subtext0 
//                                     }
//                                     Text { 
//                                         anchors.verticalCenter: parent.verticalCenter
//                                         text: barWindow.volPercent; 
//                                         font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(13); font.weight: Font.Black; 
//                                         color: barWindow.isSoundActive ? mocha.base : mocha.text; 
//                                     }
//                                 }
//                                 MouseArea { id: volMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle volume"]) }
//                             }

//                             Rectangle {
//                                 property bool isHovered: batMouse.containsMouse
//                                 color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4); 
//                                 radius: barWindow.s(10); height: sysLayout.pillHeight;
//                                 clip: true

//                                 Rectangle {
//                                     anchors.fill: parent
//                                     radius: barWindow.s(10)
//                                     opacity: 1.0 
//                                     Behavior on opacity { NumberAnimation { duration: 300 } }
//                                     gradient: Gradient {
//                                         orientation: Gradient.Horizontal
//                                         GradientStop { position: 0.0; color: barWindow.isDesktop ? mocha.red : barWindow.batDynamicColor; Behavior on color { ColorAnimation { duration: 300 } } }
//                                         GradientStop { position: 1.0; color: barWindow.isDesktop ? Qt.lighter(mocha.red, 1.3) : Qt.lighter(barWindow.batDynamicColor, 1.3); Behavior on color { ColorAnimation { duration: 300 } } }
//                                     }
//                                 }
                                
//                                 property real targetWidth: barWindow.isDesktop ? barWindow.s(34) : batLayoutRow.implicitWidth + barWindow.s(24)
//                                 width: targetWidth
//                                 Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                                
//                                 scale: isHovered ? 1.05 : 1.0
//                                 Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                                 Behavior on color { ColorAnimation { duration: 200 } }

//                                 property bool initAnimTrigger: false
//                                 Timer { running: rightContent.showLayout && !parent.initAnimTrigger; interval: 200; onTriggered: parent.initAnimTrigger = true }
//                                 opacity: initAnimTrigger ? 1 : 0
//                                 transform: Translate { y: parent.initAnimTrigger ? 0 : barWindow.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
//                                 Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

//                                 Row { 
//                                     id: batLayoutRow
//                                     anchors.centerIn: parent
//                                     spacing: barWindow.s(8)
//                                     Text { 
//                                         anchors.verticalCenter: parent.verticalCenter
//                                         text: barWindow.isDesktop ? "" : barWindow.batIcon; 
//                                         font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.isDesktop ? barWindow.s(18) : barWindow.s(16); 
//                                         color: mocha.base 
//                                         Behavior on color { ColorAnimation { duration: 300 } }
//                                     }
//                                     Text { 
//                                         anchors.verticalCenter: parent.verticalCenter
//                                         visible: !barWindow.isDesktop
//                                         text: barWindow.batPercent; font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(13); font.weight: Font.Black; 
//                                         color: mocha.base 
//                                         Behavior on color { ColorAnimation { duration: 300 } }
//                                     }
//                                 }
//                                 MouseArea { id: batMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle battery"]) }
//                             }                        
// 	         	}
// 		    }
// 		    Rectangle {
//                         id: recButton
//                         property bool isHovered: recMouse.containsMouse
                        
//                         color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.95) : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
//                         radius: barWindow.s(14)
//                         border.width: 1
//                         border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, isHovered ? 0.15 : 0.05)

//                         property real targetWidth: barWindow.isRecording ? barWindow.barHeight : 0
//                         width: targetWidth
//                         height: barWindow.barHeight 

//                         visible: targetWidth > 0 || opacity > 0
//                         opacity: barWindow.isRecording ? 1.0 : 0.0
//                         clip: true

//                         Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
//                         Behavior on opacity { NumberAnimation { duration: 300 } }
                        
//                         scale: isHovered ? 1.05 : 1.0
//                         Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                         Behavior on color { ColorAnimation { duration: 200 } }

//                         Text {
//                             id: recIcon
//                             anchors.centerIn: parent
//                             text: "" 
//                             font.family: "Iosevka Nerd Font"
//                             font.pixelSize: barWindow.s(20)
//                             color: mocha.red
                            
//                             SequentialAnimation on opacity {
//                                 running: barWindow.isRecording && !recButton.isHovered
//                                 loops: Animation.Infinite
//                                 NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
//                                 NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
//                             }
//                             SequentialAnimation on scale {
//                                 running: barWindow.isRecording && !recButton.isHovered
//                                 loops: Animation.Infinite
//                                 NumberAnimation { to: 1.15; duration: 600; easing.type: Easing.InOutSine }
//                                 NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
//                             }
//                         }
                        
//                         MouseArea {
//                             id: recMouse
//                             anchors.fill: parent
//                             hoverEnabled: true
//                             onClicked: {
//                                 barWindow.isRecording = false; 
//                                 Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/screenshot.sh"]); 
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }


//@ pragma UseQApplication
// ^ Originally intended as a QML pragma directive to use QApplication instead of QGuiApplication, but commented out. This might be needed for certain Qt Widgets integration, though currently disabled.

import QtQuick
// ^ Imports the QtQuick module, providing all basic QML types (Item, Rectangle, Text, etc.), property bindings, animations, and the component system.

import QtQuick.Layouts
// ^ Imports the Layouts module, providing RowLayout, ColumnLayout, and other layout types that automatically position and size their children.

import QtQuick.Controls
// ^ Imports Qt Quick Controls, though this bar uses mostly custom elements rather than standard controls.

import Quickshell
// ^ Imports the Quickshell module, providing PanelWindow, Process management, Variants (for multi-screen support), and shell integration.

import Quickshell.Io
// ^ Imports the Quickshell Io module, providing StdioCollector for capturing process output asynchronously.

import Quickshell.Wayland
// ^ Imports the Quickshell Wayland module for WlrLayershell configuration and Wayland protocol integration.

import Quickshell.Services.SystemTray
// ^ Imports the SystemTray service, providing access to the Freedesktop system tray protocol, displaying tray icons from other applications.

Variants {
    // ^ Variants is a Quickshell type that creates one instance of its delegate for each item in its model. Here, it creates one top bar per connected screen/monitor.

    model: Quickshell.screens
    // ^ Uses Quickshell.screens as the model, which contains all currently connected display outputs. This ensures a top bar appears on every monitor.

    delegate: Component {
        // ^ Defines the component template that will be instantiated for each screen. Everything inside this delegate is the actual top bar for one monitor.

        PanelWindow {
            // ^ The root element for each bar instance is a PanelWindow—a layer shell surface designed for desktop panels.

            id: barWindow
            // ^ Assigns the identifier "barWindow" for referencing this bar instance throughout its component tree.

            property bool pendingReload: false
            // ^ Tracks whether a reload was requested while the settings panel was open. If true, the reload will occur when settings close.

            IpcHandler {
                // ^ Creates an IPC handler that allows external processes to communicate with this bar instance.

                target: "topbar"
                // ^ The IPC channel name—external commands target "topbar" to communicate with this bar.

                function forceReload() {
                    // ^ Remotely callable function that forces an immediate reload of the bar.

                    Quickshell.reload(true) 
                    // ^ Calls Quickshell's reload with the force flag, completely reinitializing the bar.
                }

                function queueReload() {
                    // ^ Remotely callable function that reloads immediately if settings aren't open, or defers the reload.

                    if (!barWindow.isSettingsOpen) {
                        // ^ If the settings panel is not currently open.
                        Quickshell.reload(true)
                        // ^ Reloads immediately.
                    } else {
                        barWindow.pendingReload = true
                        // ^ Defers the reload until settings are closed (checked in onIsSettingsOpenChanged).
                    }
                }

                function toggleUpdate() {
                    // ^ Remotely callable function to toggle the update button visibility.

                    barWindow.forceUpdateShow = !barWindow.forceUpdateShow
                    // ^ Flips the forceUpdateShow flag, which can show the update button even when no update is pending.
                }
            }

            required property var modelData
            // ^ A required property that receives the current screen data from the Variants model. 'required' ensures it must be provided.

            screen: modelData
            // ^ Assigns this bar instance to the specific screen from the model, positioning it on that display.

            anchors {
                top: true
                left: true
                right: true
            }
            // ^ Anchors the panel to the top edge of the screen, spanning the full width from left to right.

            Scaler {
                // ^ Instantiates the Scaler component to calculate a base scale factor based on this screen's width.

                id: scaler
                // ^ Identifier for accessing the scale factor.

                currentWidth: barWindow.width
                // ^ Passes the current bar width (which equals the screen width) to the scaler for responsive sizing.
            }

            property real baseScale: scaler.baseScale
            // ^ Exposes the scaler's baseScale as a convenience property for use throughout the bar.

            function s(val) { 
                // ^ Convenience function that scales a design-time pixel value using the bar's scale factor.

                return scaler.s(val); 
                // ^ Delegates to the scaler's s() function.
            }

            property int barHeight: s(48)
            // ^ Defines the bar height as 48 scaled pixels. All bar elements use this for consistent vertical sizing.

            height: barHeight
            // ^ Sets the panel window's height.

            margins { top: s(8); bottom: 0; left: s(4); right: s(4) }
            // ^ Adds small margins around the bar: 8px top gap from screen edge, 0px bottom, 4px on left and right sides.

            exclusiveZone: barHeight 
            // ^ Tells the compositor to reserve this much screen space exclusively for the bar. Windows won't overlap this zone, and maximized windows will stop at the bar's bottom edge.

            color: "transparent"
            // ^ Makes the panel window background transparent so the rounded rectangles within it appear to float.

            MatugenColors {
                // ^ Instantiates the MatugenColors component to access the system's Material You color scheme.

                id: mocha
                // ^ Assigns the identifier "mocha" for accessing theme colors throughout the bar.
            }

            property bool showHelpIcon: true
            // ^ Controls visibility of the help icon in the left section. Can be toggled via settings.

            property bool isRecording: false
            // ^ Tracks whether a screen recording is currently active. When true, shows the recording indicator button.

            property bool updateAvailable: false
            // ^ Tracks whether a system update is available. Set by polling the update pending file.

            property bool forceUpdateShow: false
            // ^ When true, forces the update button to be visible regardless of actual update availability. Toggled via IPC.

            property bool isUpdateVisible: updateAvailable || forceUpdateShow
            // ^ The update button is visible if either an update is available OR it's force-shown.

            property int workspaceCount: 8
            // ^ The number of workspaces to display. Defaults to 8, can be changed via settings.

            property string activeWidget: "" 
            // ^ Tracks which QuickShell widget is currently open (e.g., "calendar", "network"). Updated by the widget poller.

            property bool isSettingsOpen: activeWidget === "settings"
            // ^ Convenience boolean that's true when the settings widget is the currently active widget.

            property real settingsSlideProgress: isSettingsOpen ? 1.0 : 0.0
            // ^ Animation progress value (0.0 to 1.0) that drives the sliding transition of bar elements when settings open/close. 1.0 = settings open (elements slide left).

            Behavior on settingsSlideProgress { 
                // ^ Animates the settingsSlideProgress property.

                enabled: barWindow.startupCascadeFinished
                // ^ Only enables the animation after the startup cascade is complete, preventing unwanted animation on initial load.

                NumberAnimation { duration: 600; easing.type: Easing.OutExpo } 
                // ^ Smooth 600ms animation with exponential easing for the slide transition.
            }

            onIsSettingsOpenChanged: {
                // ^ Called when the settings panel opens or closes.

                if (!barWindow.isSettingsOpen && barWindow.pendingReload) {
                    // ^ If settings just closed AND a reload was pending.
                    barWindow.pendingReload = false;
                    // ^ Clears the pending flag.
                    Quickshell.reload(true);
                    // ^ Executes the deferred reload now that settings are closed.
                }
            }

            Process {
                // ^ A Process that reads which widget is currently active from the temporary file.

                id: widgetPoller
                // ^ Identifier.

                command: ["bash", "-c", "cat /tmp/qs_current_widget 2>/dev/null || echo ''"]
                // ^ Reads the active widget name from the IPC file, defaulting to empty string if file doesn't exist.

                running: true
                // ^ Runs immediately on startup.

                stdout: StdioCollector {
                    // ^ Captures the file contents.

                    onStreamFinished: {
                        // ^ Called when the file is read.
                        let txt = this.text.trim();
                        // ^ Gets the trimmed widget name.
                        if (barWindow.activeWidget !== txt) barWindow.activeWidget = txt;
                        // ^ Updates the active widget property if it changed, triggering the settingsSlideProgress animation.
                    }
                }
            }

            Process {
                // ^ A Process that watches the active widget file for changes using inotifywait.

                id: widgetWatcher
                // ^ Identifier.

                command: ["bash", "-c", "while [ ! -f /tmp/qs_current_widget ]; do sleep 1; done; inotifywait -qq -e modify,close_write /tmp/qs_current_widget"]
                // ^ Waits for the file to exist, then blocks until it's modified.

                running: true
                // ^ Starts immediately.

                onExited: {
                    // ^ Called when inotifywait detects a change.
                    widgetPoller.running = false;
                    // ^ Stops the previous poller.
                    widgetPoller.running = true;
                    // ^ Restarts the poller to read the new widget name.
                    running = false;
                    // ^ Stops this watcher.
                    running = true;
                    // ^ Restarts the watcher to wait for the next change.
                }
            }
            
            Process {
                // ^ A Process that checks if a screen recording is currently active.

                id: recPoller
                // ^ Identifier.

                command: ["bash", "-c", "if [ -s ~/.cache/qs_recording_state/rec_pid ] && kill -0 $(cat ~/.cache/qs_recording_state/rec_pid) 2>/dev/null; then echo '1'; else echo '0'; fi"]
                // ^ Checks if the recording PID file exists AND the process with that PID is still alive. Outputs "1" if recording, "0" otherwise.

                stdout: StdioCollector {
                    // ^ Captures output.

                    onStreamFinished: {
                        // ^ Called when check completes.
                        barWindow.isRecording = (this.text.trim() === "1");
                        // ^ Sets the recording flag based on the check result.
                    }
                }
            }

            Timer {
                // ^ A timer that periodically polls the recording state.

                interval: 500; running: true; repeat: true
                // ^ Every 500ms (twice per second) for responsive recording indicator updates.

                onTriggered: {
                    // ^ When the timer fires.
                    recPoller.running = false;
                    // ^ Stops previous poll.
                    recPoller.running = true;
                    // ^ Starts a new poll.
                }
            }

            Process {
                // ^ A Process that checks if a system update is pending.

                id: updatePoller
                // ^ Identifier.

                command: ["bash", "-c", "if [ -f ~/.cache/qs_update_pending ]; then echo '1'; else echo '0'; fi"]
                // ^ Checks for the existence of the update pending flag file.

                stdout: StdioCollector {
                    // ^ Captures output.

                    onStreamFinished: {
                        // ^ Called when check completes.
                        barWindow.updateAvailable = (this.text.trim() === "1");
                        // ^ Sets the update available flag.
                    }
                }
            }

            Timer {
                // ^ Timer for periodic update checking.

                interval: 2000; running: true; repeat: true
                // ^ Every 2 seconds for update status.

                onTriggered: {
                    // ^ Restarts the poller each cycle.
                    updatePoller.running = false;
                    updatePoller.running = true;
                }
            }
            
            Process {
                // ^ A Process that reads the settings JSON file to get bar-specific configurations.

                id: settingsReader
                // ^ Identifier.

                command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null || echo '{}'"]
                // ^ Reads the settings file, falling back to empty JSON object.

                running: true
                // ^ Runs on startup.

                stdout: StdioCollector {
                    // ^ Captures the JSON.

                    onStreamFinished: {
                        // ^ Processes the settings.
                        try {
                            if (this.text && this.text.trim().length > 0 && this.text.trim() !== "{}") {
                                // ^ If there's meaningful content.
                                let parsed = JSON.parse(this.text);
                                // ^ Parses the JSON.

                                if (parsed.topbarHelpIcon !== undefined && barWindow.showHelpIcon !== parsed.topbarHelpIcon) {
                                    // ^ If the help icon setting exists and differs from current.
                                    barWindow.showHelpIcon = parsed.topbarHelpIcon;
                                    // ^ Updates the help icon visibility.
                                }
                                
                                if (parsed.workspaceCount !== undefined && barWindow.workspaceCount !== parsed.workspaceCount) {
                                    // ^ If workspace count setting exists and differs.
                                    barWindow.workspaceCount = parsed.workspaceCount;
                                    // ^ Updates the count.
                                    wsDaemon.running = false;
                                    // ^ Restarts the workspace daemon to reflect the new count.
                                    wsDaemon.running = true;
                                }
                            }
                        } catch (e) {}
                        // ^ Silently ignores parsing errors.
                    }
                }
            }

            Process {
                // ^ A Process that watches the settings file for changes.

                id: settingsWatcher
                // ^ Identifier.

                command: ["bash", "-c", "while [ ! -f ~/.config/hypr/settings.json ]; do sleep 1; done; inotifywait -qq -e modify,close_write ~/.config/hypr/settings.json"]
                // ^ Waits for the file then blocks until modified.

                running: true
                // ^ Starts immediately.

                stdout: StdioCollector {
                    // ^ Captures output.

                    onStreamFinished: {
                        // ^ When settings change.
                        settingsReader.running = false;
                        // ^ Restarts the reader.
                        settingsReader.running = true;
                        
                        settingsWatcher.running = false;
                        // ^ Restarts the watcher.
                        settingsWatcher.running = true;
                    }
                }
            }
            
            property bool isDesktop: false
            // ^ Tracks whether the system is a desktop (no battery) or laptop. Determined by the chassis detector.

            property string ethStatus: "Ethernet"
            // ^ Stores the Ethernet connection status string (e.g., "Connected", "Disconnected").

            Process {
                // ^ A Process that detects if the system is a laptop or desktop by checking for batteries.

                id: chassisDetector
                // ^ Identifier.

                running: true
                // ^ Runs once on startup.

                command: ["bash", "-c", "if ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then echo 'laptop'; else echo 'desktop'; fi"]
                // ^ Checks for battery devices in sysfs. Outputs "laptop" or "desktop".

                stdout: StdioCollector {
                    // ^ Captures output.

                    onStreamFinished: {
                        // ^ When detection completes.
                        barWindow.isDesktop = (this.text.trim() === "desktop");
                        // ^ Sets the isDesktop flag based on detection result.
                    }
                }
            }

            property bool isStartupReady: false
            // ^ Indicates that the very initial startup is complete (set after 10ms delay).

            Timer { interval: 10; running: true; onTriggered: barWindow.isStartupReady = true }
            // ^ Sets isStartupReady after a tiny 10ms delay, triggering the typewriter date animation.

            property bool startupCascadeFinished: false
            // ^ Indicates the full startup cascade is complete (set after 1 second). This allows smooth staggered animations.

            Timer { interval: 1000; running: true; onTriggered: barWindow.startupCascadeFinished = true }
            // ^ Marks the cascade as finished after 1 second.

            property bool fastPollerLoaded: false
            // ^ Set to true when the first fast poll (keyboard layout) completes, indicating essential data is available.

            property bool isDataReady: fastPollerLoaded
            // ^ Convenience alias: data is ready when the fast poller has completed its first fetch.

            Timer { interval: 600; running: true; onTriggered: barWindow.isDataReady = true }
            // ^ Fallback: after 600ms, considers data ready even if the poller hasn't completed, preventing indefinite loading states.
            
            property string timeStr: ""
            // ^ Stores the current time string in "HH:mm:ss" format. Updated every second by the clock timer.

            property string fullDateStr: ""
            // ^ Stores the complete date string (e.g., "Monday, January 15"). The typewriter animation reveals this character by character.

            property int typeInIndex: 0
            // ^ Current character index for the typewriter date animation. Increments to reveal the date one character at a time.

            property string dateStr: fullDateStr.substring(0, typeInIndex)
            // ^ The currently visible portion of the date string, from the start up to the typeInIndex. This creates the typewriter effect.

            property string weatherIcon: ""
            // ^ Current weather icon character (Nerd Font glyph). Defaults to a thermometer icon.

            property string weatherTemp: "--°"
            // ^ Current temperature display string. Defaults to "--°" placeholder.

            property string weatherHex: mocha.yellow
            // ^ The weather accent color as a hex/color value. Defaults to yellow from the theme.

            property string wifiStatus: "Off"
            // ^ Current WiFi status string (e.g., "Enabled", "Off", "Connected").

            property string wifiIcon: "󰤮"
            // ^ WiFi signal strength icon. Updated based on signal quality.

            property string wifiSsid: ""
            // ^ Current connected WiFi network name (SSID). Empty if not connected.

            property string btStatus: "Off"
            // ^ Bluetooth status string (e.g., "Enabled", "Off").

            property string btIcon: "󰂲"
            // ^ Bluetooth icon, changes based on connection state.

            property string btDevice: ""
            // ^ Name of the currently connected Bluetooth device. Empty if none connected.

            property string volPercent: "0%"
            // ^ Current volume percentage as a string (e.g., "75%").

            property string volIcon: "󰕾"
            // ^ Volume icon based on level and mute state.

            property bool isMuted: false
            // ^ Tracks whether audio is currently muted.

            property string batPercent: "100%"
            // ^ Current battery percentage as a string (e.g., "85%").

            property string batIcon: "󰁹"
            // ^ Battery icon based on charge level and charging state.

            property string batStatus: "Unknown"
            // ^ Battery status string (e.g., "Charging", "Discharging", "Full").

            property string kbLayout: "us"
            // ^ Current keyboard layout code (e.g., "us", "de", "fr").
            
            ListModel { 
                // ^ A ListModel that holds workspace data for the workspace indicators.

                id: workspacesModel 
                // ^ Identifier for the workspace model.

                property int activeIndex: 0
                // ^ Tracks the index of the currently active workspace within the model.
            }
            
            property var musicData: { "status": "Stopped", "title": "", "artUrl": "", "timeStr": "" }
            // ^ An object holding current media playback information: status, title, album art URL, and time position string. Defaults to stopped state.

            property string displayTitle: ""
            // ^ The media title shown in the bar. Mirrors musicData.title when media is active.

            property string displayTime: ""
            // ^ The media time string shown in the bar. Mirrors musicData.timeStr when active.

            property string displayArtUrl: ""
            // ^ The album art URL shown in the bar. Mirrors musicData.artUrl when active.

            onMusicDataChanged: {
                // ^ Called when music data updates from the player.

                if (musicData && musicData.status !== "Stopped" && musicData.title !== "") {
                    // ^ If media is playing and has a title.
                    displayTitle = musicData.title;
                    // ^ Updates the display title.
                    displayTime = musicData.timeStr;
                    // ^ Updates the display time.
                    displayArtUrl = musicData.artUrl;
                    // ^ Updates the album art.
                }
            }

            property bool isMediaActive: barWindow.musicData.status !== "Stopped" && barWindow.musicData.title !== ""
            // ^ True when media is actively playing and has a title—triggers the media box to appear.

            property bool isWifiOn: barWindow.wifiStatus.toLowerCase() === "enabled" || barWindow.wifiStatus.toLowerCase() === "on"
            // ^ True when WiFi is enabled/on, case-insensitive check.

            property bool isBtOn: barWindow.btStatus.toLowerCase() === "enabled" || barWindow.btStatus.toLowerCase() === "on"
            // ^ True when Bluetooth is enabled/on.

            property bool showEthernet: barWindow.ethStatus === "Connected" || (barWindow.isDesktop && !barWindow.isWifiOn)
            // ^ Shows Ethernet info when connected, OR when on a desktop with WiFi off (desktop likely uses Ethernet).

            property bool isSoundActive: !barWindow.isMuted && parseInt(barWindow.volPercent) > 0
            // ^ True when audio is not muted AND volume is above 0%.

            property int batCap: parseInt(barWindow.batPercent) || 0
            // ^ Integer battery percentage parsed from the string, defaulting to 0.

            property bool isCharging: barWindow.batStatus === "Charging" || barWindow.batStatus === "Full"
            // ^ True when battery is charging or full.

            property color batDynamicColor: {
                // ^ Dynamically determines the battery indicator color.

                if (isCharging) return mocha.green;
                // ^ Green when charging.
                if (batCap <= 20) return mocha.red;
                // ^ Red when battery is critically low (20% or less).
                return mocha.text; 
                // ^ Normal text color otherwise.
            }

            Process {
                // ^ A Process that runs the workspace monitoring daemon script.

                id: wsDaemon
                // ^ Identifier.

                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/workspaces.sh"]
                // ^ Runs the workspace shell script that tracks active workspaces and outputs their state to a JSON file.

                running: true
                // ^ Starts immediately.
            }

            Process {
                // ^ A Process that reads the workspace state from the JSON file produced by the workspace daemon.

                id: wsReader
                // ^ Identifier.

                command: ["cat", "/tmp/qs_workspaces.json"]
                // ^ Reads the workspace JSON file.

                stdout: StdioCollector {
                    // ^ Captures the JSON.

                    onStreamFinished: {
                        // ^ When the file is read.
                        let txt = this.text.trim();
                        if (txt !== "") {
                            // ^ If there's content.
                            try { 
                                let newData = JSON.parse(txt);
                                // ^ Parses the JSON array of workspace objects.
                                
                                while (workspacesModel.count < newData.length) {
                                    // ^ If the model has fewer entries than needed.
                                    workspacesModel.append({ "wsId": "", "wsState": "" });
                                    // ^ Appends new entries to match the required count.
                                }
                                
                                while (workspacesModel.count > newData.length) {
                                    // ^ If the model has more entries than needed (workspace count decreased).
                                    workspacesModel.remove(workspacesModel.count - 1);
                                    // ^ Removes excess entries from the end.
                                }
                                
                                let newActive = -1;
                                // ^ Tracks the index of the active workspace.

                                for (let i = 0; i < newData.length; i++) {
                                    // ^ Iterates through workspace data.
                                    if (newData[i].state === "active") newActive = i;
                                    // ^ Records the active workspace index.

                                    if (workspacesModel.get(i).wsState !== newData[i].state) {
                                        // ^ If state changed.
                                        workspacesModel.setProperty(i, "wsState", newData[i].state);
                                        // ^ Updates the state.
                                    }
                                    if (workspacesModel.get(i).wsId !== newData[i].id.toString()) {
                                        // ^ If workspace ID changed.
                                        workspacesModel.setProperty(i, "wsId", newData[i].id.toString());
                                        // ^ Updates the ID.
                                    }
                                }

                                if (newActive !== -1 && workspacesModel.activeIndex !== newActive) {
                                    // ^ If the active workspace changed.
                                    workspacesModel.activeIndex = newActive;
                                    // ^ Updates the active index, triggering the highlight animation.
                                }

                            } catch(e) {}
                            // ^ Silently ignores JSON parse errors.
                        }
                    }
                }
            }

            Process {
                // ^ A Process that watches the workspace JSON file for changes.

                id: wsWatcher
                // ^ Identifier.

                running: true
                // ^ Starts immediately.

                command: ["bash", "-c", "inotifywait -qq -e close_write,modify /tmp/qs_workspaces.json"]
                // ^ Blocks until the workspace file is modified or written to.

                onExited: {
                    // ^ When the file changes.
                    wsReader.running = false;
                    // ^ Stops the previous reader.
                    wsReader.running = true;
                    // ^ Restarts the reader to parse the updated file.
                    running = false;
                    // ^ Stops this watcher.
                    running = true;
                    // ^ Restarts the watcher for the next change.
                }
            }

            Process {
                // ^ A Process that fetches current media playback information from MPRIS.

                id: musicForceRefresh
                // ^ Identifier.

                running: true
                // ^ Runs on startup.

                command: ["bash", "-c", "bash ~/.config/hypr/scripts/quickshell/music/music_info.sh | tee /tmp/music_info.json"]
                // ^ Runs the music info script, which queries playerctl for current media status, and saves the output to a JSON file while also passing it through.

                stdout: StdioCollector {
                    // ^ Captures the JSON output.

                    onStreamFinished: {
                        // ^ When the script completes.
                        let txt = this.text.trim();
                        if (txt !== "") {
                            // ^ If there's content.
                            try { barWindow.musicData = JSON.parse(txt); } catch(e) {}
                            // ^ Parses the JSON and updates the music data object, triggering the media display.
                        }
                    }
                }
            }

            Timer {
                // ^ A timer that simulates media playback progress by incrementing the position every second.

                interval: 1000
                // ^ Fires every 1 second.

                running: true
                // ^ Always running.

                repeat: true
                // ^ Repeats indefinitely.

                onTriggered: {
                    // ^ Each second, updates the playback position.

                    if (!barWindow.musicData || barWindow.musicData.status !== "Playing") return;
                    // ^ Only processes when media is actively playing.

                    if (!barWindow.musicData.timeStr || barWindow.musicData.timeStr === "") return;
                    // ^ Skips if there's no time string.

                    let parts = barWindow.musicData.timeStr.split(" / ");
                    // ^ Splits "position / duration" into two parts.

                    if (parts.length !== 2) return;
                    // ^ Requires both position and duration.

                    let posParts = parts[0].split(":").map(Number);
                    // ^ Splits position "MM:SS" or "HH:MM:SS" into numeric parts.

                    let lenParts = parts[1].split(":").map(Number);
                    // ^ Splits duration similarly.

                    let posSecs = (posParts.length === 3) 
                        ? (posParts[0] * 3600 + posParts[1] * 60 + posParts[2]) 
                        : (posParts[0] * 60 + posParts[1]);
                    // ^ Converts position to total seconds. Handles both HH:MM:SS and MM:SS formats.

                    let lenSecs = (lenParts.length === 3) 
                        ? (lenParts[0] * 3600 + lenParts[1] * 60 + lenParts[2]) 
                        : (lenParts[0] * 60 + lenParts[1]);
                    // ^ Converts duration to total seconds.

                    if (isNaN(posSecs) || isNaN(lenSecs)) return;
                    // ^ Validates the conversion.

                    posSecs++;
                    // ^ Increments position by 1 second.

                    if (posSecs > lenSecs) posSecs = lenSecs;
                    // ^ Caps position at duration (song finished).

                    let newPosStr = "";
                    // ^ Builds the new position string.
                    if (posParts.length === 3) {
                        // ^ If using HH:MM:SS format.
                        let h = Math.floor(posSecs / 3600);
                        let m = Math.floor((posSecs % 3600) / 60);
                        let s = posSecs % 60;
                        newPosStr = h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
                        // ^ Formats with leading zeros for minutes and seconds.
                    } else {
                        // ^ If using MM:SS format.
                        let m = Math.floor(posSecs / 60);
                        let s = posSecs % 60;
                        newPosStr = (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
                        // ^ Formats with leading zeros.
                    }

                    let newData = Object.assign({}, barWindow.musicData);
                    // ^ Creates a shallow copy of the music data.
                    newData.timeStr = newPosStr + " / " + parts[1];
                    // ^ Updates the time string.
                    newData.positionStr = newPosStr;
                    // ^ Adds a separate position string.

                    if (lenSecs > 0) newData.percent = (posSecs / lenSecs) * 100;
                    // ^ Calculates playback percentage.
                    
                    barWindow.musicData = newData;
                    // ^ Updates the music data, triggering display refresh.
                }
            }

            Process {
                // ^ A Process that watches D-Bus for MPRIS media player changes.

                id: mprisWatcher
                // ^ Identifier.

                running: true
                // ^ Starts immediately.

                command: ["bash", "-c", "dbus-monitor --session \"type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='org.mpris.MediaPlayer2.Player'\" \"type='signal',interface='org.mpris.MediaPlayer2.Player',member='Seeked'\" 2>/dev/null | grep -m 1 'member=' > /dev/null || sleep 2"]
                // ^ Monitors D-Bus for MPRIS property changes and seek events. When detected, exits and triggers a refresh. If no event within 2 seconds (due to the sleep fallback), still exits.

                onExited: {
                    // ^ When a media change is detected or timeout occurs.
                    musicForceRefresh.running = false;
                    // ^ Stops previous refresh.
                    musicForceRefresh.running = true;
                    // ^ Starts new refresh to get updated media info.
                    running = false;
                    // ^ Stops this watcher.
                    running = true;
                    // ^ Restarts the watcher for the next event.
                }
            }

            Timer {
                // ^ A timer that retries fetching album art when the placeholder image is detected.

                id: artRetryTimer
                // ^ Identifier.

                interval: 500
                // ^ Every 500ms.

                repeat: true
                // ^ Repeats while condition is true.

                running: barWindow.displayArtUrl && barWindow.displayArtUrl.indexOf("placeholder_blank.png") !== -1
                // ^ Only runs when the current art URL contains the placeholder image filename, indicating the real art hasn't loaded yet.

                onTriggered: {
                    // ^ Each trigger attempts a refresh.
                    musicForceRefresh.running = false;
                    musicForceRefresh.running = true;
                    // ^ Restarts the music info fetcher to try getting the real album art.
                }
            }

            Process {
                // ^ A Process that fetches the current keyboard layout.

                id: kbPoller; running: true
                // ^ Identifier; starts immediately.

                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/kb_fetch.sh"]
                // ^ Runs the keyboard fetch script.

                stdout: StdioCollector {
                    // ^ Captures the layout string.

                    onStreamFinished: {
                        // ^ When the fetch completes.
                        let txt = this.text.trim();
                        if (txt !== "" && barWindow.kbLayout !== txt) barWindow.kbLayout = txt;
                        // ^ Updates keyboard layout if it changed.
                        kbWaiter.running = false;
                        // ^ Stops the waiter.
                        kbWaiter.running = true;
                        // ^ Starts the waiter that will trigger the next fetch when a change occurs.
                        barWindow.fastPollerLoaded = true; 
                        // ^ Marks that the fast initial poll is complete, signaling data readiness.
                    }
                }
            }

            Process { id: kbWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/kb_wait.sh"]; onExited: { kbPoller.running = false; kbPoller.running = true; } }
            // ^ The keyboard waiter process that blocks until the keyboard layout changes (using inotifywait or similar), then triggers a new fetch. Creates an event-driven poll cycle: fetch → wait → fetch → wait.

            Process {
                // ^ A Process that fetches current audio state.

                id: audioPoller; running: true
                // ^ Identifier; starts immediately.

                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_fetch.sh"]
                // ^ Runs the audio fetch script.

                stdout: StdioCollector {
                    // ^ Captures JSON output.

                    onStreamFinished: {
                        // ^ When fetch completes.
                        let txt = this.text.trim();
                        if (txt !== "") {
                            // ^ If there's output.
                            try {
                                let data = JSON.parse(txt);
                                // ^ Parses the JSON.
                                let newVol = data.volume.toString() + "%";
                                // ^ Formats volume as percentage string.
                                if (barWindow.volPercent !== newVol) barWindow.volPercent = newVol;
                                // ^ Updates volume if changed.
                                if (barWindow.volIcon !== data.icon) barWindow.volIcon = data.icon;
                                // ^ Updates volume icon if changed.
                                let newMuted = (data.is_muted === "true");
                                // ^ Converts mute string to boolean.
                                if (barWindow.isMuted !== newMuted) barWindow.isMuted = newMuted;
                                // ^ Updates mute state if changed.
                            } catch(e) {}
                            // ^ Silently ignores parse errors.
                        }
                        audioWaiter.running = false;
                        // ^ Stops waiter.
                        audioWaiter.running = true;
                        // ^ Restarts waiter for next change event.
                    }
                }
            }

            Process { id: audioWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_wait.sh"]; onExited: { audioPoller.running = false; audioPoller.running = true; } }
            // ^ Audio waiter that blocks until volume/mute changes, then triggers a new fetch. Creates an event-driven cycle.

            Process {
                // ^ A Process that fetches current network state.

                id: networkPoller; running: true
                // ^ Identifier; starts immediately.

                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_fetch.sh"]
                // ^ Runs the network fetch script.

                stdout: StdioCollector {
                    // ^ Captures JSON output.

                    onStreamFinished: {
                        // ^ When fetch completes.
                        let txt = this.text.trim();
                        if (txt !== "") {
                            // ^ If there's output.
                            try {
                                let data = JSON.parse(txt);
                                // ^ Parses the JSON.
                                if (barWindow.wifiStatus !== data.status) barWindow.wifiStatus = data.status;
                                // ^ Updates WiFi status.
                                if (barWindow.wifiIcon !== data.icon) barWindow.wifiIcon = data.icon;
                                // ^ Updates WiFi icon.
                                if (barWindow.wifiSsid !== data.ssid) barWindow.wifiSsid = data.ssid;
                                // ^ Updates connected SSID.
                                if (barWindow.ethStatus !== data.eth_status) barWindow.ethStatus = data.eth_status;
                                // ^ Updates Ethernet status.
                            } catch(e) {}
                            // ^ Silently ignores parse errors.
                        }
                        networkWaiter.running = false;
                        // ^ Stops waiter.
                        networkWaiter.running = true;
                        // ^ Restarts waiter.
                    }
                }
            }

            Process { id: networkWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_wait.sh"]; onExited: { networkPoller.running = false; networkPoller.running = true; } }
            // ^ Network waiter that blocks until network changes, then triggers a new fetch.

            Process {
                // ^ A Process that fetches current Bluetooth state.

                id: btPoller; running: true
                // ^ Identifier; starts immediately.

                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_fetch.sh"]
                // ^ Runs the Bluetooth fetch script.

                stdout: StdioCollector {
                    // ^ Captures JSON output.

                    onStreamFinished: {
                        // ^ When fetch completes.
                        let txt = this.text.trim();
                        if (txt !== "") {
                            // ^ If there's output.
                            try {
                                let data = JSON.parse(txt);
                                // ^ Parses the JSON.
                                if (barWindow.btStatus !== data.status) barWindow.btStatus = data.status;
                                // ^ Updates Bluetooth status.
                                if (barWindow.btIcon !== data.icon) barWindow.btIcon = data.icon;
                                // ^ Updates Bluetooth icon.
                                if (barWindow.btDevice !== data.connected) barWindow.btDevice = data.connected;
                                // ^ Updates connected device name.
                            } catch(e) {}
                            // ^ Silently ignores errors.
                        }
                        btWaiter.running = false;
                        // ^ Stops waiter.
                        btWaiter.running = true;
                        // ^ Restarts waiter.
                    }
                }
            }

            Process { id: btWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_wait.sh"]; onExited: { btPoller.running = false; btPoller.running = true; } }
            // ^ Bluetooth waiter that blocks until Bluetooth changes, then triggers a new fetch.

            Process {
                // ^ A Process that fetches current battery state.

                id: batteryPoller; running: true
                // ^ Identifier; starts immediately.

                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_fetch.sh"]
                // ^ Runs the battery fetch script.

                stdout: StdioCollector {
                    // ^ Captures JSON output.

                    onStreamFinished: {
                        // ^ When fetch completes.
                        let txt = this.text.trim();
                        if (txt !== "") {
                            // ^ If there's output.
                            try {
                                let data = JSON.parse(txt);
                                // ^ Parses the JSON.
                                let newBat = data.percent.toString() + "%";
                                // ^ Formats battery percentage.
                                if (barWindow.batPercent !== newBat) barWindow.batPercent = newBat;
                                // ^ Updates percentage.
                                if (barWindow.batIcon !== data.icon) barWindow.batIcon = data.icon;
                                // ^ Updates battery icon.
                                if (barWindow.batStatus !== data.status) barWindow.batStatus = data.status;
                                // ^ Updates battery status.
                            } catch(e) {}
                            // ^ Silently ignores errors.
                        }
                        batteryWaiter.running = false;
                        // ^ Stops waiter.
                        batteryWaiter.running = true;
                        // ^ Restarts waiter.
                    }
                }
            }

            Process { id: batteryWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_wait.sh"]; onExited: { batteryPoller.running = false; batteryPoller.running = true; } }
            // ^ Battery waiter that blocks until battery state changes, then triggers a new fetch.


            Process {
                // ^ A Process that fetches current weather data.

                id: weatherPoller
                // ^ Identifier.

                command: ["bash", "-c", `
                    echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-icon)"
                    echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-temp)"
                    echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-hex)"
                `]
                // ^ Runs the weather script three times to get icon, temperature, and accent color, outputting each on a separate line.

                stdout: StdioCollector {
                    // ^ Captures the three-line output.

                    onStreamFinished: {
                        // ^ When weather data is fetched.
                        let lines = this.text.trim().split("\n");
                        // ^ Splits output into lines.
                        if (lines.length >= 3) {
                            // ^ If all three values are present.
                            barWindow.weatherIcon = lines[0];
                            // ^ Updates weather icon (line 1).
                            barWindow.weatherTemp = lines[1];
                            // ^ Updates temperature (line 2).
                            barWindow.weatherHex = lines[2] || mocha.yellow;
                            // ^ Updates weather accent color (line 3), defaulting to yellow.
                        }
                    }
                }
            }

            Timer { interval: 150000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { weatherPoller.running = false; weatherPoller.running = true; } }
            // ^ Timer that fetches weather every 150,000ms (2.5 minutes). Fires immediately on start for instant weather display.


            Timer {
                // ^ The main clock timer that updates the displayed time and date every second.

                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                // ^ Fires every second, starts immediately, fires on start.

                onTriggered: {
                    // ^ Each second:
                    let d = new Date();
                    // ^ Creates a new Date object with current time.
                    barWindow.timeStr = Qt.formatDateTime(d, "HH:mm:ss");
                    // ^ Formats as 24-hour time with seconds.
                    barWindow.fullDateStr = Qt.formatDateTime(d, "dddd, MMMM dd");
                    // ^ Formats as full weekday, month, and day (e.g., "Monday, January 15").
                    if (barWindow.typeInIndex >= barWindow.fullDateStr.length) {
                        // ^ If the typewriter has revealed all characters.
                        barWindow.typeInIndex = barWindow.fullDateStr.length;
                        // ^ Caps the index at the full length.
                    }
                }
            }

            Timer {
                // ^ The typewriter animation timer that reveals the date one character at a time.

                id: typewriterTimer
                // ^ Identifier.

                interval: 40
                // ^ Every 40ms for a fast but visible typing effect (approximately 25 characters per second).

                running: barWindow.isStartupReady && barWindow.typeInIndex < barWindow.fullDateStr.length
                // ^ Only runs when startup is ready AND the full date hasn't been fully revealed yet.

                repeat: true
                // ^ Repeats until the condition becomes false.

                onTriggered: barWindow.typeInIndex += 1
                // ^ Increments the visible character index by one each trigger.
            }

            Item {
                // ^ The main container that fills the bar window and holds all visible bar elements.

                anchors.fill: parent
                // ^ Fills the entire bar panel area.

                Rectangle {
                    // ^ The left content box containing help, search, settings, and update buttons.

                    id: leftContent
                    // ^ Identifier for positioning calculations.

                    y: (parent.height - barWindow.barHeight) / 2
                    // ^ Vertically centers the box within the bar (accounting for the top margin).

                    height: barWindow.barHeight
                    // ^ Full bar height.

                    color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                    // ^ Semi-transparent base color (75% opacity) for the frosted glass effect.

                    radius: barWindow.s(14)
                    // ^ 14px scaled corner radius for rounded card appearance.

                    border.width: 1
                    // ^ 1px border.

                    border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)
                    // ^ Very subtle text-colored border (8% opacity).

                    clip: true
                    // ^ Clips child content to the rounded boundaries.
                    
                    property bool showLayout: false
                    // ^ Controls whether the left content is visible (animated).
                    
                    opacity: (showLayout && !barWindow.isSettingsOpen) ? 1 : 0
                    // ^ Visible when layout is shown AND settings aren't open. Hidden during settings to make room.

                    enabled: !barWindow.isSettingsOpen
                    // ^ Disabled (non-interactive) when settings are open.
                    
                    property real targetX: (showLayout && !barWindow.isSettingsOpen) ? 0 : barWindow.s(-200)
                    // ^ Slides off-screen to the left (-200px) when hidden, at 0 when visible.

                    x: targetX
                    // ^ Positions using the targetX property.

                    Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                    // ^ Smooth 600ms slide animation.

                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    // ^ Smooth 400ms fade animation.
                    
                    Timer {
                        // ^ A tiny delay timer that triggers the slide-in animation after startup.

                        running: barWindow.isStartupReady
                        // ^ Runs once startup is ready.

                        interval: 10
                        // ^ 10ms delay for a barely perceptible stagger.

                        onTriggered: leftContent.showLayout = true
                        // ^ Reveals the left content.
                    }

                    width: leftLayout.width + barWindow.s(16)
                    // ^ Dynamic width based on the inner row content plus 16px padding.

                    Row {
                        // ^ Horizontally arranges the left buttons.

                        id: leftLayout
                        // ^ Identifier for width measurement.

                        anchors.verticalCenter: parent.verticalCenter
                        // ^ Vertically centered in the box.

                        anchors.left: parent.left
                        // ^ Anchored to the left edge.

                        anchors.leftMargin: barWindow.s(8)
                        // ^ 8px left padding.

                        spacing: barWindow.s(4)
                        // ^ 4px spacing between buttons.
                        
                        property int pillHeight: barWindow.s(34)
                        // ^ Standard height for the icon pills (34px scaled).

                        Rectangle {
                            // ^ The help/guide icon button. Only visible when showHelpIcon is true.

                            property bool isHovered: helpMouse.containsMouse
                            // ^ Tracks hover state for visual feedback.

                            color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : "transparent"
                            // ^ Surface1 color on hover, transparent when idle.

                            radius: barWindow.s(10)
                            // ^ 10px corner radius.
                            
                            property real targetWidth: barWindow.showHelpIcon ? barWindow.s(34) : 0
                            // ^ Width is 34px when visible, 0 when hidden (for smooth collapse animation).

                            width: targetWidth
                            // ^ Bound to the target width.

                            height: parent.pillHeight
                            // ^ Standard pill height.

                            visible: targetWidth > 0 || opacity > 0
                            // ^ Visible when there's width or opacity, preventing layout jumps.

                            opacity: barWindow.showHelpIcon ? 1.0 : 0.0
                            // ^ Fully opaque when shown, transparent when hidden.

                            clip: true
                            // ^ Clips the icon when width is collapsing.
                            
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                            // ^ Smooth width animation for expand/collapse.

                            Behavior on opacity { NumberAnimation { duration: 300 } }
                            // ^ Smooth fade.

                            Behavior on color { ColorAnimation { duration: 200 } }
                            // ^ Quick hover color transition.
                            
                            Text {
                                // ^ The help icon (question mark circle).

                                anchors.centerIn: parent
                                // ^ Centered.

                                text: "󰋗"
                                // ^ Nerd Font help icon.

                                font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(22)
                                // ^ Icon font at 22px.

                                color: parent.isHovered ? mocha.teal : mocha.text
                                // ^ Teal accent on hover, normal text color otherwise.

                                Behavior on color { ColorAnimation { duration: 200 } }
                                // ^ Smooth color transition.

                                scale: parent.isHovered ? 1.15 : 1.0
                                // ^ Slightly enlarges on hover.

                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                // ^ Bouncy scale animation.
                            }

                            MouseArea {
                                // ^ Click handler for help button.

                                id: helpMouse
                                // ^ Identifier for the hover binding above.

                                anchors.fill: parent
                                // ^ Fills the button.

                                hoverEnabled: true
                                // ^ Enables hover detection.

                                onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle guide"])
                                // ^ Toggles the guide widget via the manager script.
                            }
                        }

                        Rectangle {
                            // ^ The search/app launcher button.

                            property bool isHovered: searchMouse.containsMouse
                            // ^ Tracks hover state.

                            color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : "transparent"
                            // ^ Surface1 on hover, transparent otherwise.

                            radius: barWindow.s(10)
                            // ^ 10px radius.

                            height: parent.pillHeight; width: barWindow.s(34)
                            // ^ Fixed size: 34px square.
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                            // ^ Quick hover color transition.
                            
                            Text {
                                // ^ The search icon (magnifying glass).

                                anchors.centerIn: parent
                                // ^ Centered.

                                text: "󰍉"
                                // ^ Search icon.

                                font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(22)
                                // ^ Icon font at 22px.

                                color: parent.isHovered ? mocha.blue : mocha.text
                                // ^ Blue accent on hover, normal text otherwise.

                                Behavior on color { ColorAnimation { duration: 200 } }
                                // ^ Smooth color transition.

                                scale: parent.isHovered ? 1.15 : 1.0
                                // ^ Slight enlargement on hover.

                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                // ^ Bouncy scale.
                            }

                            MouseArea {
                                // ^ Click handler.

                                id: searchMouse
                                // ^ Identifier.

                                anchors.fill: parent
                                // ^ Fills button.

                                hoverEnabled: true
                                // ^ Enables hover.

                                onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle applauncher"])
                                // ^ Toggles the application launcher widget.
                            }
                        }

                        Rectangle {
                            // ^ The settings gear button.

                            property bool isHovered: settingsMouse.containsMouse
                            // ^ Tracks hover.

                            color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : "transparent"
                            // ^ Surface1 on hover.

                            radius: barWindow.s(10)
                            // ^ 10px radius.

                            height: parent.pillHeight; width: barWindow.s(34)
                            // ^ 34px square.
                            
                            Behavior on color { ColorAnimation { duration: 200 } }
                            // ^ Quick hover transition.
                            
                            Text {
                                // ^ The settings gear icon.

                                anchors.centerIn: parent
                                // ^ Centered.

                                text: ""
                                // ^ Gear/cog icon.

                                font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(22)
                                // ^ Icon font at 22px.

                                color: parent.isHovered ? mocha.blue : mocha.text
                                // ^ Blue on hover.

                                Behavior on color { ColorAnimation { duration: 200 } }
                                // ^ Smooth color.

                                scale: parent.isHovered ? 1.15 : 1.0
                                // ^ Hover enlargement.

                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                // ^ Bouncy scale.
                            }

                            MouseArea {
                                // ^ Click handler.

                                id: settingsMouse
                                // ^ Identifier.

                                anchors.fill: parent
                                // ^ Fills button.

                                hoverEnabled: true
                                // ^ Enables hover.

                                onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle settings"])
                                // ^ Toggles the settings widget.
                            }
                        }

                        Rectangle {
                            // ^ The system update button. Only visible when an update is pending or force-shown. Features a pulsing green glow animation.

                            id: updateButton
                            // ^ Identifier.

                            property bool isHovered: updateMouse.containsMouse
                            // ^ Tracks hover.

                            color: isHovered ? Qt.rgba(mocha.green.r, mocha.green.g, mocha.green.b, 0.15) : "transparent"
                            // ^ Green tint on hover, transparent otherwise.
                            radius: barWindow.s(10)
                            // ^ 10px radius.
                            
                            width: barWindow.isUpdateVisible ? barWindow.s(34) : 0
                            // ^ 34px when visible, collapses to 0 when hidden.

                            height: parent.pillHeight
                            // ^ Standard pill height.
                            
                            visible: width > 0 || opacity > 0
                            // ^ Visible while animating.

                            opacity: barWindow.isUpdateVisible ? 1.0 : 0.0
                            // ^ Opaque when visible, transparent when hidden.

                            clip: false 
                            // ^ Does NOT clip children, allowing the glow animation to extend beyond the button bounds.
                            
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                            // ^ Smooth width collapse/expand.

                            Behavior on opacity { NumberAnimation { duration: 300 } }
                            // ^ Smooth fade.

                            Behavior on color { ColorAnimation { duration: 200 } }
                            // ^ Quick hover color.

                            Rectangle {
                                // ^ The pulsing green glow circle behind the update icon.

                                anchors.centerIn: parent
                                // ^ Centered on the button.

                                width: parent.width
                                // ^ Matches parent width.

                                height: parent.height
                                // ^ Matches parent height.

                                radius: parent.radius
                                // ^ Matches parent radius.

                                color: mocha.green
                                // ^ Green accent color.

                                z: -1
                                // ^ Rendered behind the icon.
                                
                                SequentialAnimation on scale {
                                    // ^ Pulsing scale animation.

                                    running: barWindow.isUpdateVisible && !updateButton.isHovered
                                    // ^ Only pulses when update is visible AND not hovered (hover stops the pulse).

                                    loops: Animation.Infinite
                                    // ^ Loops forever.

                                    NumberAnimation { from: 1.0; to: 1.3; duration: 2000; easing.type: Easing.OutCubic }
                                    // ^ Expands from 100% to 130% over 2 seconds. Only one direction—the loop will restart from 1.0.
                                }

                                SequentialAnimation on opacity {
                                    // ^ Pulsing opacity animation synchronized with scale.

                                    running: barWindow.isUpdateVisible && !updateButton.isHovered
                                    // ^ Same running condition.

                                    loops: Animation.Infinite
                                    // ^ Loops forever.

                                    NumberAnimation { from: 0.15; to: 0.0; duration: 2000; easing.type: Easing.OutCubic }
                                    // ^ Fades from 15% to 0% opacity over 2 seconds, then loops back to 15%.
                                }
                            }
                            
                            Text {
                                // ^ The update/download icon.

                                anchors.centerIn: parent
                                // ^ Centered.

                                text: "󰚰"
                                // ^ Download/update icon.

                                font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(22)
                                // ^ Icon font at 22px.

                                color: parent.isHovered ? mocha.text : mocha.green
                                // ^ Normal text color on hover (for contrast against green background), green otherwise.

                                Behavior on color { ColorAnimation { duration: 200 } }
                                // ^ Smooth color.

                                rotation: parent.isHovered ? 360 : 0
                                // ^ Spins a full 360 degrees on hover.

                                Behavior on rotation {
                                    // ^ Animated rotation.
                                    NumberAnimation { 
                                        duration: 600
                                        // ^ 600ms spin.
                                        easing.type: Easing.OutBack
                                        // ^ Back easing for a satisfying overshoot.
                                    }
                                }

                                scale: parent.isHovered ? 1.15 : 1.0
                                // ^ Slight enlargement on hover.

                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                // ^ Bouncy scale.
                            }

                            MouseArea {
                                // ^ Click handler.

                                id: updateMouse
                                // ^ Identifier.

                                anchors.fill: parent
                                // ^ Fills button.

                                hoverEnabled: true
                                // ^ Enables hover.

                                onClicked: {
                                    // ^ When clicked:
                                    barWindow.updateAvailable = false;
                                    // ^ Clears the update flag.
                                    barWindow.forceUpdateShow = false;
                                    // ^ Clears force-show flag.
                                    Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle updater"]);
                                    // ^ Opens the updater widget.
                                }
                            }
                        }
                    }
                }
                
                Rectangle {
                    // ^ The workspace indicators box in the center-left area.

                    id: workspacesBox
                    // ^ Identifier.

                    color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                    // ^ Semi-transparent base color.

                    radius: barWindow.s(14); border.width: 1; border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.05)
                    // ^ Rounded card with subtle border.

                    height: barWindow.barHeight
                    // ^ Full bar height.

                    y: (parent.height - barWindow.barHeight) / 2
                    // ^ Vertically centered.

                    clip: true
                    // ^ Clips workspace pills to the rounded box.
                    
                    width: workspacesModel.count > 0 ? wsLayout.implicitWidth + barWindow.s(20) : 0
                    // ^ Width based on workspace count plus 20px padding. Zero width when no workspaces.
                    
                    property real defaultX: leftContent.x + leftContent.width + barWindow.s(4)
                    // ^ Default X position: immediately after the left content box with 4px gap.

                    property real settingsX: mediaBox.settingsX - width - (width > 0 ? barWindow.s(4) : 0)
                    // ^ X position when settings are open: positioned relative to the media box's settings position.
                                        
                    x: defaultX + (settingsX - defaultX) * barWindow.settingsSlideProgress
                    // ^ Smoothly interpolates between default and settings positions using the settingsSlideProgress.

                    property bool limitActive: barWindow.isSettingsOpen && barWindow.isMediaActive
                    // ^ When true, limits the number of visible workspace indicators to make room for settings.

                    visible: width > 0 || opacity > 0
                    // ^ Visible when there's width or during animation.

                    opacity: workspacesModel.count > 0 ? 1 : 0
                    // ^ Opaque when there are workspaces.

                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    // ^ Smooth fade.

                    Rectangle {
                        // ^ The animated highlight that slides between workspace indicators.

                        id: activeHighlight
                        // ^ Identifier.

                        y: (workspacesBox.height - barWindow.s(32)) / 2
                        // ^ Vertically centered in the box.

                        height: barWindow.s(32)
                        // ^ 32px tall.

                        radius: barWindow.s(10)
                        // ^ 10px radius.

                        color: mocha.mauve
                        // ^ Mauve accent for the active workspace indicator.

                        z: 0
                        // ^ Rendered behind the workspace numbers.

                        property int prevIdx: 0
                        // ^ Stores the previous active index for direction detection.

                        property int curIdx: workspacesModel.activeIndex
                        // ^ Mirrors the current active workspace index.

                        onCurIdxChanged: {
                            // ^ When the active workspace changes.
                            if (curIdx > prevIdx) {
                                // ^ Moving right.
                                rightAnim.duration = 200; leftAnim.duration = 350;
                                // ^ Faster right edge, slower left edge trailing for stretchy morph.
                            } else if (curIdx < prevIdx) {
                                // ^ Moving left.
                                leftAnim.duration = 200; rightAnim.duration = 350;
                                // ^ Faster left edge, slower right edge trailing.
                            }
                            prevIdx = curIdx;
                            // ^ Updates the previous index.
                        }

                        // FIXED: Calculate step size to perfectly match the rounded width + rounded spacing of the Row elements.
                        property real stepSize: barWindow.s(32) + barWindow.s(6)
                        // ^ Each workspace pill is 32px wide with 6px spacing, so the step between centers is 38px.

                        property real targetLeft: wsLayout.x + (curIdx * stepSize)
                        // ^ The target left edge position for the highlight.

                        property real targetRight: targetLeft + barWindow.s(32)
                        // ^ The target right edge (left + 32px width).

                        property real actualLeft: targetLeft
                        // ^ Property that animates to targetLeft.

                        property real actualRight: targetRight
                        // ^ Property that animates to targetRight.

                        Behavior on actualLeft { NumberAnimation { id: leftAnim; duration: 250; easing.type: Easing.OutExpo } }
                        // ^ Animated left edge with dynamically adjusted duration.

                        Behavior on actualRight { NumberAnimation { id: rightAnim; duration: 250; easing.type: Easing.OutExpo } }
                        // ^ Animated right edge.

                        x: actualLeft
                        // ^ Positions at the animated left edge.

                        width: actualRight - actualLeft
                        // ^ Width is the difference between edges, creating the stretchy morph.

                        opacity: workspacesModel.count > 0 ? 1 : 0
                        // ^ Visible when workspaces exist.
                    }

                    Row {
                        // ^ Horizontally arranges the workspace number pills.

                        id: wsLayout
                        // ^ Identifier.

                        anchors.centerIn: parent
                        // ^ Centered in the box.

                        spacing: barWindow.s(6)
                        // ^ 6px spacing between pills.
                        
                        Repeater {
                            // ^ Creates one pill for each workspace in the model.

                            model: workspacesModel
                            // ^ Uses the workspace data model.

                            delegate: Rectangle {
                                // ^ Each workspace is a rounded rectangle pill.

                                id: wsPill
                                // ^ Identifier for the pill.
                                
                                property bool isLimited: workspacesBox.limitActive && index >= 6
                                // ^ When limited mode is active, workspaces beyond index 5 (6th and above) are hidden to save space.

                                visible: !isLimited
                                // ^ Hidden when limited.
                                
                                property bool isHovered: wsPillMouse.containsMouse
                                // ^ Tracks hover state.
                                
                                property string stateLabel: model.wsState
                                // ^ The workspace state from the model ("active", "occupied", "empty").

                                property string wsName: model.wsId
                                // ^ The workspace ID/number to display.
                                
                                property real targetWidth: barWindow.s(32)
                                // ^ Fixed width of 32px.

                                width: targetWidth
                                // ^ Bound to target width.

                                Behavior on targetWidth { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                // ^ Bouncy width animation for any size changes.
                                
                                height: barWindow.s(32); radius: barWindow.s(10)
                                // ^ 32px square with 10px radius.
                                
                                color: isHovered ? Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.1) : (stateLabel === "occupied" ? Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.15) : "transparent")
                                // ^ Text highlight on hover, subtle occupied indicator, transparent for empty.

                                scale: isHovered && stateLabel !== "active" ? 1.08 : 1.0
                                // ^ Slight enlargement on hover for non-active workspaces.

                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                // ^ Bouncy scale animation.
                                
                                property bool initAnimTrigger: false
                                // ^ Controls the staggered entrance animation.

                                opacity: initAnimTrigger ? 1 : 0
                                // ^ Visible after the animation trigger.

                                transform: Translate {
                                    // ^ Slides up from below during entrance animation.
                                    y: wsPill.initAnimTrigger ? 0 : barWindow.s(15)
                                    // ^ Starts 15px lower, slides to 0.
                                    Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                                    // ^ Bouncy slide-up.
                                }

                                Component.onCompleted: {
                                    // ^ When the pill is created.
                                    if (!barWindow.startupCascadeFinished) {
                                        // ^ During initial startup.
                                        animTimer.interval = index * 60;
                                        // ^ Staggers the animation: each pill starts 60ms later than the previous.
                                        animTimer.start();
                                        // ^ Starts the delayed trigger.
                                    } else {
                                        // ^ If bar is reloading (not initial startup).
                                        initAnimTrigger = true;
                                        // ^ Shows immediately without animation.
                                    }
                                }

                                Timer {
                                    // ^ Delayed trigger for the staggered entrance.
                                    id: animTimer
                                    running: false
                                    repeat: false
                                    onTriggered: wsPill.initAnimTrigger = true
                                    // ^ Triggers the entrance animation.
                                }
                                
                                Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                // ^ Smooth fade.

                                Behavior on color { ColorAnimation { duration: 250 } }
                                // ^ Smooth color transitions.

                                Text {
                                    // ^ The workspace number.

                                    anchors.centerIn: parent
                                    // ^ Centered in the pill.

                                    text: wsName
                                    // ^ Displays the workspace ID (number).

                                    font.family: "JetBrains Mono"
                                    // ^ Monospace font.

                                    font.pixelSize: barWindow.s(14)
                                    // ^ 14px text.

                                    font.weight: stateLabel === "active" ? Font.Black : (stateLabel === "occupied" ? Font.Bold : Font.Medium)
                                    // ^ Black (boldest) for active, Bold for occupied, Medium for empty.
                                    
                                    color: index === workspacesModel.activeIndex ? mocha.crust : (isHovered ? mocha.text : (stateLabel === "occupied" ? mocha.text : mocha.overlay0))
                                    // ^ Crust (darkest) when active, text color on hover or occupied, subdued overlay0 for empty.
                                    
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                    // ^ Smooth color transitions.
                                }

                                MouseArea {
                                    // ^ Click handler to switch to this workspace.

                                    id: wsPillMouse
                                    // ^ Identifier for hover binding.

                                    hoverEnabled: true
                                    // ^ Enables hover detection.

                                    anchors.fill: parent
                                    // ^ Fills the pill.

                                    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh " + wsName])
                                    // ^ Calls the manager script with the workspace number to switch to it.
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    // ^ The media player box that appears when media is active.

                    id: mediaBox
                    // ^ Identifier.

                    color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                    // ^ Semi-transparent base.

                    radius: barWindow.s(14); border.width: 1; border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.05)
                    // ^ Rounded card with subtle border.

                    y: (parent.height - barWindow.barHeight) / 2
                    // ^ Vertically centered.

                    height: barWindow.barHeight
                    // ^ Full bar height.

                    clip: true 
                    // ^ Clips content to rounded bounds.
                    
                    width: barWindow.isMediaActive ? innerMediaLayout.implicitWidth + barWindow.s(24) : 0
                    // ^ Dynamic width based on content when active, zero when inactive.

                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                    // ^ Smooth width expand/collapse.

                    property real defaultX: workspacesBox.defaultX + workspacesBox.width + (workspacesBox.width > 0 ? barWindow.s(4) : 0)
                    // ^ Default position: after the workspaces box with gap.

                    property real settingsX: centerBox.settingsX - width - (width > 0 ? barWindow.s(4) : 0)
                    // ^ Settings position: just before the center box.

                    x: defaultX + (settingsX - defaultX) * barWindow.settingsSlideProgress
                    // ^ Smoothly interpolates position based on settings slide progress.

                    visible: width > 0 || opacity > 0
                    // ^ Visible when there's width or during animation.

                    opacity: barWindow.isMediaActive ? 1.0 : 0.0
                    // ^ Opaque when media is active.

                    Behavior on opacity { NumberAnimation { duration: 400 } }
                    // ^ Smooth fade.
                    
                    Item {
                        // ^ Container for the media info and controls with its own entrance animation.

                        id: mediaLayoutContainer
                        // ^ Identifier.

                        anchors.verticalCenter: parent.verticalCenter
                        // ^ Vertically centered in the media box.

                        anchors.left: parent.left
                        // ^ Anchored to the left edge.

                        anchors.leftMargin: barWindow.s(12)
                        // ^ 12px left padding.

                        height: parent.height
                        // ^ Full box height.

                        width: innerMediaLayout.implicitWidth
                        // ^ Width based on the inner row content.
                        
                        opacity: barWindow.isMediaActive ? 1.0 : 0.0
                        // ^ Fades with media active state.

                        transform: Translate { 
                            // ^ Slides in from the left when appearing.
                            x: barWindow.isMediaActive ? 0 : barWindow.s(-20) 
                            // ^ Starts 20px left, slides to 0.

                            Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutQuint } }
                            // ^ Smooth 700ms slide-in.
                        }

                        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                        // ^ Smooth 500ms fade.

                        Row {
                            // ^ Horizontally arranges the album art/title area and the playback controls.

                            id: innerMediaLayout
                            // ^ Identifier for width measurement.

                            anchors.verticalCenter: parent.verticalCenter
                            // ^ Vertically centered.

                            spacing: barWindow.width < 1920 ? barWindow.s(8) : barWindow.s(16)
                            // ^ Tighter spacing on smaller screens (<1920px), more generous on larger screens.
                            
                            MouseArea {
                                // ^ Click handler for the album art/title area.

                                id: mediaInfoMouse
                                // ^ Identifier.

                                width: infoLayout.width
                                // ^ Width of the inner info layout.

                                height: innerMediaLayout.height
                                // ^ Full row height.

                                hoverEnabled: true
                                // ^ Enables hover for the scale effect.

                                onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle music"])
                                // ^ Opens the full music widget on click.
                                
                                Row {
                                    // ^ Arranges album art and track info.

                                    id: infoLayout
                                    // ^ Identifier.

                                    anchors.verticalCenter: parent.verticalCenter
                                    // ^ Vertically centered.

                                    spacing: barWindow.s(10)
                                    // ^ 10px between art and text.
                                    
                                    scale: mediaInfoMouse.containsMouse ? 1.02 : 1.0
                                    // ^ Subtle enlargement on hover.

                                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                    // ^ Smooth scale animation.

                                    Rectangle {
                                        // ^ Album art thumbnail container.

                                        width: barWindow.s(32); height: barWindow.s(32); radius: barWindow.s(8); color: mocha.surface1
                                        // ^ 32px square with 8px radius, surface1 background.

                                        border.width: barWindow.musicData.status === "Playing" ? 1 : 0
                                        // ^ 1px border only when playing.

                                        border.color: mocha.mauve
                                        // ^ Mauve border when playing.

                                        clip: true
                                        // ^ Clips the image to the rounded corners.

                                        Image { 
                                            // ^ The album art image.

                                            anchors.fill: parent; 
                                            // ^ Fills the thumbnail.

                                            source: barWindow.displayArtUrl || ""; 
                                            // ^ Loads from the art URL, or empty string if no art.

                                            fillMode: Image.PreserveAspectCrop 
                                            // ^ Crops to fill while preserving aspect ratio.
                                        }
                                        
                                        Rectangle {
                                            // ^ A subtle mauve tint overlay on the art.

                                            anchors.fill: parent
                                            // ^ Fills the thumbnail.

                                            color: Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.2)
                                            // ^ 20% opacity mauve overlay for a consistent tint.
                                        }
                                    }

                                    Column {
                                        // ^ Stacks track title and time.

                                        spacing: -2
                                        // ^ Slight negative spacing for tighter vertical packing.

                                        anchors.verticalCenter: parent.verticalCenter
                                        // ^ Vertically centered.

                                        property real maxColWidth: barWindow.width < 1920 ? barWindow.s(120) : barWindow.s(180)
                                        // ^ Width limit for the text column: 120px on smaller screens, 180px on larger.

                                        width: maxColWidth 
                                        // ^ Fixed width for the column.
                                        
                                        Text { 
                                            // ^ Track title.

                                            text: barWindow.displayTitle; 
                                            // ^ Shows the current track title.

                                            font.family: "JetBrains Mono"; 
                                            // ^ Monospace font.

                                            font.weight: Font.Black; 
                                            // ^ Boldest weight.

                                            font.pixelSize: barWindow.s(13); 
                                            // ^ 13px text.

                                            color: mocha.text;
                                            // ^ Primary text color.

                                            width: parent.width
                                            // ^ Full column width.

                                            elide: Text.ElideRight; 
                                            // ^ Elides on the right with "..." if too long.
                                        }

                                        Text { 
                                            // ^ Time position string.

                                            text: barWindow.displayTime; 
                                            // ^ Shows "MM:SS / MM:SS" or similar.

                                            font.family: "JetBrains Mono"; 
                                            // ^ Monospace font.

                                            font.weight: Font.Black; 
                                            // ^ Boldest.

                                            font.pixelSize: barWindow.s(10); 
                                            // ^ 10px smaller text.

                                            color: mocha.subtext0;
                                            // ^ Subdued text color for secondary info.

                                            width: parent.width
                                            // ^ Full column width.

                                            elide: Text.ElideRight;
                                            // ^ Elides if too long.
                                        }
                                    }
                                }
                            }

                            Row {
                                // ^ Playback control buttons: previous, play/pause, next.

                                anchors.verticalCenter: parent.verticalCenter
                                // ^ Vertically centered.

                                spacing: barWindow.width < 1920 ? barWindow.s(4) : barWindow.s(8)
                                // ^ Tighter spacing on smaller screens.

                                Item { 
                                    // ^ Previous track button.

                                    width: barWindow.s(24); height: barWindow.s(24); 
                                    // ^ 24px square.

                                    anchors.verticalCenter: parent.verticalCenter
                                    // ^ Vertically centered.

                                    Text { 
                                        // ^ Previous icon.

                                        anchors.centerIn: parent; text: "󰒮"; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(26); 
                                        // ^ Previous track icon.

                                        color: prevMouse.containsMouse ? mocha.text : mocha.overlay2; 
                                        // ^ Full text color on hover, subdued otherwise.

                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        // ^ Quick color transition.

                                        scale: prevMouse.containsMouse ? 1.1 : 1.0
                                        // ^ Slight enlargement on hover.

                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                        // ^ Bouncy scale.
                                    }

                                    MouseArea { id: prevMouse; hoverEnabled: true; anchors.fill: parent; onClicked: { Quickshell.execDetached(["playerctl", "previous"]); musicForceRefresh.running = true; } } 
                                    // ^ Sends "previous" command to playerctl, then refreshes music data.
                                }

                                Item { 
                                    // ^ Play/Pause toggle button.

                                    width: barWindow.s(28); height: barWindow.s(28); 
                                    // ^ Slightly larger (28px) for emphasis.

                                    anchors.verticalCenter: parent.verticalCenter
                                    // ^ Vertically centered.

                                    Text { 
                                        // ^ Play or pause icon based on current state.

                                        anchors.centerIn: parent; text: barWindow.musicData.status === "Playing" ? "󰏤" : "󰐊"; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(30); 
                                        // ^ Pause icon when playing, play icon when paused/stopped.

                                        color: playMouse.containsMouse ? mocha.green : mocha.text; 
                                        // ^ Green accent on hover, normal text otherwise.

                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        // ^ Quick color.

                                        scale: playMouse.containsMouse ? 1.15 : 1.0
                                        // ^ Larger hover enlargement than prev/next.

                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                        // ^ Bouncy scale.
                                    }

                                    MouseArea { id: playMouse; hoverEnabled: true; anchors.fill: parent; onClicked: { Quickshell.execDetached(["playerctl", "play-pause"]); musicForceRefresh.running = true; } } 
                                    // ^ Toggles play/pause, then refreshes.
                                }

                                Item { 
                                    // ^ Next track button.

                                    width: barWindow.s(24); height: barWindow.s(24); 
                                    // ^ 24px square, matching previous.

                                    anchors.verticalCenter: parent.verticalCenter
                                    // ^ Vertically centered.

                                    Text { 
                                        // ^ Next icon.

                                        anchors.centerIn: parent; text: "󰒭"; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(26); 
                                        // ^ Next track icon.

                                        color: nextMouse.containsMouse ? mocha.text : mocha.overlay2; 
                                        // ^ Full color on hover.

                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        // ^ Quick color.

                                        scale: nextMouse.containsMouse ? 1.1 : 1.0
                                        // ^ Slight hover enlargement.

                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                        // ^ Bouncy scale.
                                    }

                                    MouseArea { id: nextMouse; hoverEnabled: true; anchors.fill: parent; onClicked: { Quickshell.execDetached(["playerctl", "next"]); musicForceRefresh.running = true; } } 
                                    // ^ Sends "next" command, then refreshes.
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    // ^ The center box containing the time, date, and weather information.

                    id: centerBox
                    // ^ Identifier.

                    property bool isHovered: centerMouse.containsMouse
                    // ^ Tracks hover for visual effects.

                    color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.95) : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                    // ^ Slightly elevated/lighter when hovered, normal base when idle.

                    radius: barWindow.s(14); border.width: 1; border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, isHovered ? 0.15 : 0.05)
                    // ^ Border becomes more visible on hover (15% vs 5% opacity).

                    y: (parent.height - barWindow.barHeight) / 2
                    // ^ Vertically centered.

                    height: barWindow.barHeight
                    // ^ Full bar height.
                    
                    width: centerLayout.implicitWidth + barWindow.s(36)
                    // ^ Dynamic width based on content plus 36px padding.

                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                    // ^ Smooth width changes.
                    
                    property real pureCenter: (parent.width - width) / 2
                    // ^ The X position that would perfectly center this box on the bar.

                    property real minCenterDefaultX: mediaBox.defaultX + mediaBox.width + (mediaBox.width > 0 ? barWindow.s(4) : 0)
                    // ^ The minimum X position: after the media box (or workspaces if no media) with a gap.

                    property real settingsX: barWindow.width - rightContent.width - width - barWindow.s(4)
                    // ^ X position when settings are open: positioned just before the right content.

                    property real defaultX: Math.max(minCenterDefaultX, pureCenter)
                    // ^ Default position: the higher of "centered" and "after media box", preventing overlap.
                    
                    x: defaultX + (settingsX - defaultX) * barWindow.settingsSlideProgress
                    // ^ Smoothly interpolates position.

                    property bool showLayout: false
                    // ^ Controls entrance animation.

                    opacity: showLayout ? 1 : 0
                    // ^ Visible after entrance trigger.

                    transform: Translate {
                        // ^ Drops down from above during entrance.
                        y: centerBox.showLayout ? 0 : barWindow.s(-30)
                        // ^ Starts 30px up, drops to 0.

                        Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                        // ^ Bouncy drop-down with slight overshoot (1.1) for a lively feel.
                    }

                    Timer {
                        // ^ Delayed trigger for entrance animation.

                        running: barWindow.isStartupReady
                        // ^ Runs after startup ready.

                        interval: 150
                        // ^ 150ms delay for stagger.

                        onTriggered: centerBox.showLayout = true
                        // ^ Triggers the entrance animation.
                    }

                    Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    // ^ Smooth fade.

                    scale: isHovered ? 1.03 : 1.0
                    // ^ Slightly enlarges on hover (3%).

                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                    // ^ Smooth scale animation.

                    Behavior on color { ColorAnimation { duration: 250 } }
                    // ^ Quick color transition.
                    
                    MouseArea {
                        // ^ Click handler for the center box.

                        id: centerMouse
                        // ^ Identifier for hover binding.

                        anchors.fill: parent
                        // ^ Fills the box.

                        hoverEnabled: true
                        // ^ Enables hover detection.

                        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle calendar"])
                        // ^ Opens the calendar widget on click.
                    }

                    RowLayout {
                        // ^ Arranges the time/date column and weather column side by side.

                        id: centerLayout
                        // ^ Identifier for width measurement.

                        anchors.centerIn: parent
                        // ^ Centered in the box.

                        spacing: barWindow.s(24)
                        // ^ 24px spacing between time and weather.

                        ColumnLayout {
                            // ^ Stacks time and date vertically.

                            spacing: -2
                            // ^ Tight vertical packing.

                            Text { text: barWindow.timeStr; Layout.alignment: Qt.AlignLeft; font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(16); font.weight: Font.Black; color: mocha.blue }
                            // ^ Time display in blue accent, 16px, boldest weight.

                            Text { text: barWindow.dateStr; Layout.alignment: Qt.AlignLeft; font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(11); font.weight: Font.Bold; color: mocha.subtext0 }
                            // ^ Date display with typewriter effect (shows partial string during animation), 11px, subdued color.
                        }

                        RowLayout {
                            // ^ Arranges weather icon and temperature.

                            spacing: barWindow.s(8)
                            // ^ 8px between icon and temp.

                            Text { 
                                // ^ Weather icon.

                                text: barWindow.weatherIcon; 
                                // ^ Current weather icon glyph.

                                Layout.alignment: Qt.AlignVCenter;
                                // ^ Vertically centered.

                                font.family: "Iosevka Nerd Font"; 
                                // ^ Icon font.

                                font.pixelSize: barWindow.s(24); 
                                // ^ 24px icon.

                                color: Qt.tint(barWindow.weatherHex, Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.4)) 
                                // ^ Tints the weather accent color with 40% mauve for a blended, thematic appearance.
                            }

                            Text { 
                                // ^ Temperature display.

                                text: barWindow.weatherTemp; 
                                // ^ Current temperature string.

                                Layout.alignment: Qt.AlignVCenter;
                                // ^ Vertically centered.

                                font.family: "JetBrains Mono"; 
                                // ^ Monospace.

                                font.pixelSize: barWindow.s(17); 
                                // ^ 17px prominent text.

                                font.weight: Font.Black; 
                                // ^ Boldest weight.

                                color: mocha.peach 
                                // ^ Peach accent color.
                            }
                        }
                    }
                }

                Row {
                    // ^ The right section containing system tray, status pills, and recording button.

                    id: rightContent
                    // ^ Identifier.

                    anchors.right: parent.right
                    // ^ Anchored to the right edge.

                    anchors.verticalCenter: parent.verticalCenter
                    // ^ Vertically centered.

                    spacing: barWindow.s(4)
                    // ^ 4px spacing between right-side elements.
                    
                    property bool showLayout: false
                    // ^ Controls entrance animation.

                    opacity: showLayout ? 1 : 0
                    // ^ Visible after trigger.

                    transform: Translate {
                        // ^ Slides in from the right during entrance.
                        x: rightContent.showLayout ? 0 : barWindow.s(30)
                        // ^ Starts 30px right, slides to 0.
                        Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                        // ^ Bouncy slide-in.
                    }
                    
                    Timer {
                        // ^ Delayed trigger for entrance (staggered after center box).

                        running: barWindow.isStartupReady && barWindow.isDataReady
                        // ^ Requires both startup ready AND data ready.

                        interval: 250
                        // ^ 250ms delay.

                        onTriggered: rightContent.showLayout = true
                        // ^ Triggers the entrance.
                    }

                    Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    // ^ Smooth fade.

                    Rectangle {
                        // ^ The system tray container. Shows icons from applications that support the system tray protocol.

                        height: barWindow.barHeight
                        // ^ Full bar height.
                        radius: barWindow.s(14)
                        // ^ Rounded card.
                        border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)
                        // ^ Subtle border.
                        border.width: 1
                        // ^ 1px border.
                        color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                        // ^ Semi-transparent base.
                        
                        property real targetWidth: trayRepeater.count > 0 ? trayLayout.width + barWindow.s(24) : 0
                        // ^ Width depends on tray icon count: visible when there are icons, zero when empty.
                        width: targetWidth
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                        // ^ Smooth width animation.
                        
                        visible: targetWidth > 0
                        // ^ Hidden when no tray icons.
                        opacity: targetWidth > 0 ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                        // ^ Smooth fade.

                        Row {
                            // ^ Horizontally arranges tray icons.
                            id: trayLayout
                            anchors.centerIn: parent
                            spacing: barWindow.s(10)

                            Repeater {
                                // ^ Creates one tray icon for each system tray item.
                                id: trayRepeater
                                model: SystemTray.items
                                // ^ Uses the SystemTray service's items list as the model.
                                delegate: Image {
                                    // ^ Each tray icon is an Image.
                                    id: trayIcon
                                    source: modelData.icon || ""
                                    // ^ Loads the icon provided by the application.
                                    fillMode: Image.PreserveAspectFit
                                    // ^ Maintains aspect ratio.
                                    
                                    sourceSize: Qt.size(barWindow.s(18), barWindow.s(18))
                                    // ^ Scales icons to 18px for consistent sizing.
                                    width: barWindow.s(18)
                                    height: barWindow.s(18)
                                    anchors.verticalCenter: parent.verticalCenter
                                    
                                    property bool isHovered: trayMouse.containsMouse
                                    // ^ Tracks hover.
                                    property bool initAnimTrigger: false
                                    // ^ Controls staggered entrance.
                                    opacity: initAnimTrigger ? (isHovered ? 1.0 : 0.8) : 0.0
                                    // ^ 100% on hover, 80% normally, 0% during entrance.
                                    scale: initAnimTrigger ? (isHovered ? 1.15 : 1.0) : 0.0
                                    // ^ Slight enlargement on hover, normal otherwise, scaled to nothing during entrance.

                                    Component.onCompleted: {
                                        // ^ Staggered entrance animation.
                                        if (!barWindow.startupCascadeFinished) {
                                            trayAnimTimer.interval = index * 50;
                                            trayAnimTimer.start();
                                        } else {
                                            initAnimTrigger = true;
                                        }
                                    }
                                    Timer {
                                        id: trayAnimTimer
                                        running: false
                                        repeat: false
                                        onTriggered: trayIcon.initAnimTrigger = true
                                    }

                                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                                    QsMenuAnchor {
                                        // ^ Anchors a context menu to this tray icon.
                                        id: menuAnchor
                                        anchor.window: barWindow
                                        anchor.item: trayIcon
                                        menu: modelData.menu
                                        // ^ Uses the menu provided by the application.
                                    }

                                    MouseArea {
                                        // ^ Handles clicks on tray icons with left/middle/right button support.
                                        id: trayMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                        onClicked: mouse => {
                                            if (mouse.button === Qt.LeftButton) {
                                                // ^ Left click.
                                                if (modelData.isMenuOnly || modelData.onlyMenu) {
                                                    menuAnchor.open();
                                                    // ^ Opens menu if the item is menu-only.
                                                } else if (typeof modelData.activate === "function") {
                                                    modelData.activate(); 
                                                    // ^ Otherwise activates the application.
                                                }
                                            } else if (mouse.button === Qt.MiddleButton) {
                                                // ^ Middle click for secondary action.
                                                if (typeof modelData.secondaryActivate === "function") {
                                                    modelData.secondaryActivate();
                                                }
                                            } else if (mouse.button === Qt.RightButton) {
                                                // ^ Right click for context menu.
                                                if (modelData.menu) { 
                                                    menuAnchor.open();
                                                } else if (typeof modelData.contextMenu === "function") {
                                                    modelData.contextMenu(mouse.x, mouse.y);
                                                } else {
                                                    modelData.activate(); 
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        // ^ The system status pills container (keyboard layout, WiFi, Bluetooth, volume, battery).

                        height: barWindow.barHeight
                        // ^ Full bar height.
                        radius: barWindow.s(14)
                        // ^ Rounded card.
                        border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)
                        // ^ Subtle border.
                        border.width: 1
                        // ^ 1px border.
                        color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                        // ^ Semi-transparent base.
                        clip: true
                        // ^ Clips content.
                        
                        width: sysLayout.implicitWidth + barWindow.s(20)
                        // ^ Dynamic width based on pill content plus 20px padding.

                        Row {
                            // ^ Horizontally arranges all status pills.
                            id: sysLayout
                            anchors.centerIn: parent
                            spacing: barWindow.s(8) 
                            // ^ 8px spacing between pills.

                            property int pillHeight: barWindow.s(34)
                            // ^ Standard height for status pills.

                            Rectangle {
                                // ^ Keyboard layout pill.

                                property bool isHovered: kbMouse.containsMouse
                                // ^ Tracks hover.
                                color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                                // ^ Slightly lighter on hover.
                                radius: barWindow.s(10); height: sysLayout.pillHeight;
                                // ^ 10px radius, standard height.
                                clip: true
                                // ^ Clips content.
                                
                                property real targetWidth: kbLayoutRow.implicitWidth + barWindow.s(24)
                                // ^ Dynamic width based on content.
                                width: targetWidth
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                                // ^ Smooth width animation.
                                
                                scale: isHovered ? 1.05 : 1.0
                                // ^ Slight enlargement on hover.
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                // ^ Bouncy scale.
                                Behavior on color { ColorAnimation { duration: 200 } }
                                // ^ Quick color.

                                property bool initAnimTrigger: false
                                // ^ Staggered entrance.
                                Timer { running: rightContent.showLayout && !parent.initAnimTrigger; interval: 0; onTriggered: parent.initAnimTrigger = true }
                                // ^ First pill to appear (0ms delay).
                                opacity: initAnimTrigger ? 1 : 0
                                transform: Translate { y: parent.initAnimTrigger ? 0 : barWindow.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
                                // ^ Slides up from below.
                                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                                Row { 
                                    // ^ Keyboard icon and layout text.
                                    id: kbLayoutRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: barWindow.s(12)
                                    spacing: barWindow.s(8)
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: "󰌌"; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(16); color: parent.parent.isHovered ? mocha.text : mocha.overlay2 }
                                    // ^ Keyboard icon.
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: barWindow.kbLayout; font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(13); font.weight: Font.Black; color: mocha.text }
                                    // ^ Layout code (e.g., "US").
                                }
                                MouseArea { id: kbMouse; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "main", "next"]) }
                                // ^ Switches to the next keyboard layout on click.
                            }

                            Rectangle {
                                // ^ WiFi/Ethernet status pill.
                                id: wifiPill
                                property bool isHovered: wifiMouse.containsMouse
                                radius: barWindow.s(10); height: sysLayout.pillHeight; 
                                color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                                clip: true
                                // ^ Clips content.
                                
                                Rectangle {
                                    // ^ A gradient overlay that appears when WiFi is on or Ethernet is connected.
                                    anchors.fill: parent
                                    radius: barWindow.s(10)
                                    opacity: barWindow.showEthernet ? (barWindow.ethStatus === "Connected" ? 1.0 : 0.0) : (barWindow.isWifiOn ? 1.0 : 0.0)
                                    // ^ Visible when connected via Ethernet or WiFi.
                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: mocha.blue }
                                        GradientStop { position: 1.0; color: Qt.lighter(mocha.blue, 1.3) }
                                        // ^ Blue gradient from left to right.
                                    }
                                }

                                property real targetWidth: wifiLayoutRow.implicitWidth + barWindow.s(24)
                                width: targetWidth
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                                
                                scale: isHovered ? 1.05 : 1.0
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                property bool initAnimTrigger: false
                                Timer { running: rightContent.showLayout && !parent.initAnimTrigger; interval: 50; onTriggered: parent.initAnimTrigger = true }
                                // ^ Second pill (50ms delay).
                                opacity: initAnimTrigger ? 1 : 0
                                transform: Translate { y: parent.initAnimTrigger ? 0 : barWindow.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
                                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                                Row { 
                                    id: wifiLayoutRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: barWindow.s(12)
                                    spacing: barWindow.s(8)
                                    Text { 
                                        anchors.verticalCenter: parent.verticalCenter; 
                                        text: barWindow.showEthernet ? "󰈀" : barWindow.wifiIcon;
                                        // ^ Shows Ethernet icon or WiFi signal icon.
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(16);
                                        color: barWindow.showEthernet ? (barWindow.ethStatus === "Connected" ? mocha.base : mocha.subtext0) : (barWindow.isWifiOn ? mocha.base : mocha.subtext0)
                                        // ^ Base color (contrast against blue gradient) when connected, subdued when not.
                                    }
                                    Text { 
                                        id: wifiText
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: barWindow.showEthernet ? barWindow.ethStatus : ((barWindow.isWifiOn ? (barWindow.wifiSsid !== "" ? barWindow.wifiSsid : "On") : "Off"))
                                        // ^ Shows Ethernet status, WiFi SSID, "On", or "Off".
                                        visible: text !== ""
                                        font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(13); font.weight: Font.Black;
                                        color: barWindow.showEthernet ? (barWindow.ethStatus === "Connected" ? mocha.base : mocha.text) : (barWindow.isWifiOn ? mocha.base : mocha.text);
                                        // ^ Base color when connected, normal text otherwise.
                                        width: Math.min(implicitWidth, barWindow.s(100)); elide: Text.ElideRight 
                                        // ^ Caps width at 100px with ellipsis.
                                    }
                                }
                                MouseArea { id: wifiMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle network wifi"]) }
                                // ^ Opens the network widget in WiFi mode.
                            }

                            Rectangle {
                                // ^ Bluetooth status pill.
                                id: btPill
                                property bool isHovered: btMouse.containsMouse
                                radius: barWindow.s(10); height: sysLayout.pillHeight
                                clip: true
                                color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                                
                                Rectangle {
                                    // ^ Gradient overlay when Bluetooth is on.
                                    anchors.fill: parent
                                    radius: barWindow.s(10)
                                    opacity: barWindow.isBtOn ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: mocha.mauve }
                                        GradientStop { position: 1.0; color: Qt.lighter(mocha.mauve, 1.3) }
                                        // ^ Mauve gradient.
                                    }
                                }

                                property real targetWidth: barWindow.isDesktop ? 0 : btLayoutRow.implicitWidth + barWindow.s(24)
                                // ^ Hidden on desktops (no Bluetooth typically), visible on laptops.
                                width: targetWidth
                                visible: targetWidth > 0
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

                                scale: isHovered ? 1.05 : 1.0
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                property bool initAnimTrigger: false
                                Timer { running: rightContent.showLayout && !parent.initAnimTrigger; interval: 100; onTriggered: parent.initAnimTrigger = true }
                                // ^ Third pill (100ms delay).
                                opacity: initAnimTrigger ? 1 : 0
                                transform: Translate { y: parent.initAnimTrigger ? 0 : barWindow.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
                                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                                Row { 
                                    id: btLayoutRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: barWindow.s(12)
                                    spacing: barWindow.s(8)
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: barWindow.btIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(16); color: barWindow.isBtOn ? mocha.base : mocha.subtext0 }
                                    // ^ Bluetooth icon.
                                    Text { 
                                        id: btText
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: barWindow.btDevice
                                        // ^ Connected device name.
                                        visible: text !== ""; 
                                        font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(13); font.weight: Font.Black; 
                                        color: barWindow.isBtOn ? mocha.base : mocha.text; 
                                        // ^ Base color when on, normal text when off.
                                        width: Math.min(implicitWidth, barWindow.s(100)); elide: Text.ElideRight 
                                    }
                                }
                                MouseArea { id: btMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle network bt"]) }
                                // ^ Opens network widget in Bluetooth mode.
                            }

                            Rectangle {
                                // ^ Volume status pill.
                                property bool isHovered: volMouse.containsMouse
                                color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                                radius: barWindow.s(10); height: sysLayout.pillHeight;
                                clip: true

                                Rectangle {
                                    // ^ Gradient overlay when sound is active.
                                    anchors.fill: parent
                                    radius: barWindow.s(10)
                                    opacity: barWindow.isSoundActive ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: mocha.peach }
                                        GradientStop { position: 1.0; color: Qt.lighter(mocha.peach, 1.3) }
                                        // ^ Peach gradient.
                                    }
                                }
                                
                                property real targetWidth: volLayoutRow.implicitWidth + barWindow.s(24)
                                width: targetWidth
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                                
                                scale: isHovered ? 1.05 : 1.0
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                property bool initAnimTrigger: false
                                Timer { running: rightContent.showLayout && !parent.initAnimTrigger; interval: 150; onTriggered: parent.initAnimTrigger = true }
                                // ^ Fourth pill (150ms delay).
                                opacity: initAnimTrigger ? 1 : 0
                                transform: Translate { y: parent.initAnimTrigger ? 0 : barWindow.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
                                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                                Row { 
                                    id: volLayoutRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: barWindow.s(12)
                                    spacing: barWindow.s(8)
                                    Text { 
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: barWindow.volIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(16); 
                                        color: barWindow.isSoundActive ? mocha.base : mocha.subtext0 
                                        // ^ Base color when active, subdued otherwise.
                                    }
                                    Text { 
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: barWindow.volPercent; 
                                        font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(13); font.weight: Font.Black; 
                                        color: barWindow.isSoundActive ? mocha.base : mocha.text; 
                                        // ^ Base color when active, normal text when muted.
                                    }
                                }
                                MouseArea { id: volMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle volume"]) }
                                // ^ Opens the volume widget.
                            }

                            Rectangle {
                                // ^ Battery status pill (or power icon on desktops).
                                property bool isHovered: batMouse.containsMouse
                                color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4); 
                                radius: barWindow.s(10); height: sysLayout.pillHeight;
                                clip: true

                                Rectangle {
                                    // ^ Gradient overlay that dynamically changes color based on battery state.
                                    anchors.fill: parent
                                    radius: barWindow.s(10)
                                    opacity: 1.0 
                                    // ^ Always visible.
                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: barWindow.isDesktop ? mocha.red : barWindow.batDynamicColor; Behavior on color { ColorAnimation { duration: 300 } } }
                                        // ^ Red on desktop, dynamic battery color on laptop.
                                        GradientStop { position: 1.0; color: barWindow.isDesktop ? Qt.lighter(mocha.red, 1.3) : Qt.lighter(barWindow.batDynamicColor, 1.3); Behavior on color { ColorAnimation { duration: 300 } } }
                                        // ^ Lighter version for gradient.
                                    }
                                }
                                
                                property real targetWidth: barWindow.isDesktop ? barWindow.s(34) : batLayoutRow.implicitWidth + barWindow.s(24)
                                // ^ Fixed 34px on desktop (icon only), dynamic on laptop.
                                width: targetWidth
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                                
                                scale: isHovered ? 1.05 : 1.0
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                property bool initAnimTrigger: false
                                Timer { running: rightContent.showLayout && !parent.initAnimTrigger; interval: 200; onTriggered: parent.initAnimTrigger = true }
                                // ^ Fifth pill (200ms delay).
                                opacity: initAnimTrigger ? 1 : 0
                                transform: Translate { y: parent.initAnimTrigger ? 0 : barWindow.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
                                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                                Row { 
                                    id: batLayoutRow
                                    anchors.centerIn: parent
                                    spacing: barWindow.s(8)
                                    Text { 
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: barWindow.isDesktop ? "" : barWindow.batIcon; 
                                        // ^ Power icon on desktop, battery icon on laptop.
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.isDesktop ? barWindow.s(18) : barWindow.s(16); 
                                        // ^ Slightly larger icon on desktop (icon only).
                                        color: mocha.base 
                                        // ^ Base color for contrast against the gradient.
                                        Behavior on color { ColorAnimation { duration: 300 } }
                                    }
                                    Text { 
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !barWindow.isDesktop
                                        // ^ Hidden on desktop (no percentage to show).
                                        text: barWindow.batPercent; font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(13); font.weight: Font.Black; 
                                        color: mocha.base 
                                        // ^ Base color for contrast.
                                        Behavior on color { ColorAnimation { duration: 300 } }
                                    }
                                }
                                MouseArea { id: batMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle battery"]) }
                                // ^ Opens the battery widget.
                            }                        
                        }
                    }

                    Rectangle {
                        // ^ The screen recording indicator button. Appears when a recording is in progress with a pulsing red icon.

                        id: recButton
                        // ^ Identifier.

                        property bool isHovered: recMouse.containsMouse
                        // ^ Tracks hover.
                        
                        color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.95) : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                        // ^ Slightly lighter on hover.

                        radius: barWindow.s(14)
                        // ^ Rounded card.

                        border.width: 1
                        // ^ 1px border.

                        border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, isHovered ? 0.15 : 0.05)
                        // ^ More visible border on hover.

                        property real targetWidth: barWindow.isRecording ? barWindow.barHeight : 0
                        // ^ Full bar height width when recording, zero when not (square button).

                        width: targetWidth
                        // ^ Bound to target width.

                        height: barWindow.barHeight 
                        // ^ Full bar height.

                        visible: targetWidth > 0 || opacity > 0
                        // ^ Visible when there's width or during animation.

                        opacity: barWindow.isRecording ? 1.0 : 0.0
                        // ^ Opaque when recording.

                        clip: true
                        // ^ Clips content.

                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                        // ^ Smooth width animation.

                        Behavior on opacity { NumberAnimation { duration: 300 } }
                        // ^ Smooth fade.
                        
                        scale: isHovered ? 1.05 : 1.0
                        // ^ Slight enlargement on hover.

                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        // ^ Bouncy scale.

                        Behavior on color { ColorAnimation { duration: 200 } }
                        // ^ Quick color transition.

                        Text {
                            // ^ The recording indicator icon (circle with dot) that pulses when recording.

                            id: recIcon
                            // ^ Identifier.

                            anchors.centerIn: parent
                            // ^ Centered in the button.

                            text: "" 
                            // ^ Record circle icon.

                            font.family: "Iosevka Nerd Font"
                            // ^ Icon font.

                            font.pixelSize: barWindow.s(20)
                            // ^ 20px icon.

                            color: mocha.red
                            // ^ Red color.
                            
                            SequentialAnimation on opacity {
                                // ^ Pulsing opacity animation.

                                running: barWindow.isRecording && !recButton.isHovered
                                // ^ Pulses only when recording and not hovered.

                                loops: Animation.Infinite
                                // ^ Loops forever.

                                NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                                // ^ Fades to 30% over 600ms.

                                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                                // ^ Fades back to 100% over 600ms.
                            }

                            SequentialAnimation on scale {
                                // ^ Synchronized pulsing scale animation.

                                running: barWindow.isRecording && !recButton.isHovered
                                // ^ Same running condition.

                                loops: Animation.Infinite
                                // ^ Loops forever.

                                NumberAnimation { to: 1.15; duration: 600; easing.type: Easing.InOutSine }
                                // ^ Grows to 115% over 600ms.

                                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                                // ^ Shrinks back to 100% over 600ms.
                            }
                        }
                        
                        MouseArea {
                            // ^ Click handler to stop recording.

                            id: recMouse
                            // ^ Identifier.

                            anchors.fill: parent
                            // ^ Fills the button.

                            hoverEnabled: true
                            // ^ Enables hover.

                            onClicked: {
                                // ^ When clicked:
                                barWindow.isRecording = false; 
                                // ^ Clears recording flag (immediate visual feedback).

                                Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/screenshot.sh"]); 
                                // ^ Runs screenshot.sh which will detect the recording PID file and stop the recording.
                            }
                        }
                    }
                }
            }
        }
    }
}