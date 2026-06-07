// import QtQuick
// import QtQuick.Layouts
// import QtQuick.Effects
// import QtQuick.Window
// import QtCore
// import Quickshell
// import Quickshell.Io
// import "../"

// Item {
//     id: window
//     focus: true

//     Scaler {
//         id: scaler
//         currentWidth: Screen.width
//     }

//     function s(val) { return scaler.s(val); }

//     Shortcut {
//         sequence: "Tab"
//         onActivated: {
//             if (window.pendingWifiId !== "") {
//                 window.pendingWifiId = ""; window.pendingWifiSsid = "";
//                 return;
//             }
//             window.playSfx("switch.wav");
//             let modes = [];
//             if (window.ethPresent) modes.push("eth");
//             if (window.wifiPresent) modes.push("wifi");
//             if (window.btPresent) modes.push("bt");
//             if (modes.length > 1) {
//                 let idx = modes.indexOf(window.activeMode);
//                 let nextMode = modes[(idx + 1) % modes.length];
//                 if (window.activeMode !== nextMode) {
//                     window.powerAnimAllowed = false;
//                     powerAnimBlocker.restart();
//                     window.activeMode = nextMode;
//                 }
//             }
//         }
//     }

//     Settings {
//         id: cache
//         category: "QS_NetworkWidgetUnified"
//         property string lastWifiSsid: ""
//         property string lastWifiJson: ""
//         property string lastBtJson: ""
//         property string lastEthJson: ""
//     }

//     readonly property string cacheDir: Quickshell.env("XDG_RUNTIME_DIR") ? (Quickshell.env("XDG_RUNTIME_DIR") + "/qs_network") : (Quickshell.env("HOME") + "/.cache/qs_network")
//     readonly property string modeFilePath: cacheDir + "/mode"

//     property bool ethPresent: false
//     property bool wifiPresent: false
//     property bool btPresent: false

//     property bool ethFirstLoad: true
//     property bool wifiFirstLoad: true
//     property bool btFirstLoad: true

//     property bool powerAnimAllowed: false
//     Timer { id: powerAnimBlocker; interval: 250; running: true; onTriggered: window.powerAnimAllowed = true }

//     // FAILSAGE TIMER: If scripts hang indefinitely, unblock validation after 1.5 seconds so the UI isn't stuck!
//     Timer {
//         id: firstLoadFailsafe
//         interval: 1500
//         running: true
//         onTriggered: {
//             let blocked = false;
//             if (window.ethFirstLoad) { window.ethFirstLoad = false; blocked = true; }
//             if (window.wifiFirstLoad) { window.wifiFirstLoad = false; blocked = true; }
//             if (window.btFirstLoad) { window.btFirstLoad = false; blocked = true; }
//             if (blocked) window.validateActiveMode();
//         }
//     }

//     property bool isValidatingMode: false
//     function validateActiveMode() {
//         if (window.ethFirstLoad || window.wifiFirstLoad || window.btFirstLoad) return;
//         if (isValidatingMode) return;
//         isValidatingMode = true;

//         let validModes = [];
//         if (window.ethPresent) validModes.push("eth");
//         if (window.wifiPresent) validModes.push("wifi");
//         if (window.btPresent) validModes.push("bt");

//         if (validModes.length > 0 && validModes.indexOf(window.activeMode) === -1) {
//             window.powerAnimAllowed = false;
//             powerAnimBlocker.restart();
//             window.activeMode = validModes[0];
//         }

//         isValidatingMode = false;
//     }

//     property bool ignoreNextModeFileUpdate: false
//     Process {
//         id: modeReader
//         command: ["bash", "-c", "cat '" + window.modeFilePath + "' 2>/dev/null"]
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 let mode = this.text.trim();
//                 if ((mode === "wifi" || mode === "bt" || mode === "eth") && window.activeMode !== mode) {
//                     if ((mode === "eth" && window.ethPresent) || 
//                         (mode === "wifi" && window.wifiPresent) || 
//                         (mode === "bt" && window.btPresent)) {
//                         window.powerAnimAllowed = false;
//                         powerAnimBlocker.restart();
//                         window.ignoreNextModeFileUpdate = true;
//                         window.activeMode = mode;
//                     }
//                 }
//             }
//         }
//     }

//     Timer { interval: 100; running: true; repeat: true; onTriggered: modeReader.running = true }

//     Component.onCompleted: {
//         window.powerAnimAllowed = false;
//         powerAnimBlocker.restart();
//         Quickshell.execDetached(["bash", "-c", "mkdir -p '" + window.cacheDir + "'; if [ ! -f '" + window.modeFilePath + "' ]; then echo '" + activeMode + "' > '" + window.modeFilePath + "'; fi"]);
        
//         let hasCache = false;
//         if (cache.lastEthJson !== "") { processEthJson(cache.lastEthJson, true); hasCache = true; }
//         if (cache.lastWifiJson !== "") { processWifiJson(cache.lastWifiJson, true); hasCache = true; }
//         if (cache.lastBtJson !== "") { processBtJson(cache.lastBtJson, true); hasCache = true; }
        
//         // INSTANT CACHE PRE-VALIDATION
//         // Evaluates the hardware 'present' states saved in settings and switches tabs 
//         // instantly, bypassing the 1.5s failsafe timer.
//         if (hasCache) {
//             let validModes = [];
//             if (window.ethPresent) validModes.push("eth");
//             if (window.wifiPresent) validModes.push("wifi");
//             if (window.btPresent) validModes.push("bt");

//             if (validModes.length > 0 && validModes.indexOf(window.activeMode) === -1) {
//                 window.activeMode = validModes[0];
//                 window.powerAnimAllowed = false;
//                 powerAnimBlocker.restart();
//             }
//         }

//         introState = 1.0;
//         if (window.activeMode === "wifi") savedNetworksFetcher.running = true;
//     }


//     function playSfx(filename) {
//         try {
//             let rawUrl = Qt.resolvedUrl("sounds/" + filename).toString();
//             let cleanPath = rawUrl;
//             if (cleanPath.indexOf("file://") === 0) cleanPath = cleanPath.substring(7); 
//             let cmd = "pw-play '" + cleanPath + "' 2>/dev/null || paplay '" + cleanPath + "' 2>/dev/null";
//             Quickshell.execDetached(["sh", "-c", cmd]);
//         } catch(e) {}
//     }

//     MatugenColors { id: _theme }

//     readonly property color base: _theme.base
//     readonly property color mantle: _theme.mantle
//     readonly property color crust: _theme.crust
//     readonly property color text: _theme.text
//     readonly property color subtext0: _theme.subtext0
//     readonly property color overlay0: _theme.overlay0
//     readonly property color overlay1: _theme.overlay1
//     readonly property color surface0: _theme.surface0
//     readonly property color surface1: _theme.surface1
//     readonly property color surface2: _theme.surface2
//     readonly property color mauve: _theme.mauve
//     readonly property color pink: _theme.pink
//     readonly property color sapphire: _theme.sapphire
//     readonly property color blue: _theme.blue
//     readonly property color red: _theme.red
//     readonly property color maroon: _theme.maroon
//     readonly property color peach: _theme.peach

//     readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/network"
    
//     readonly property color sharedAccent: Qt.lighter(window.sapphire, 1.15) 
//     readonly property color btAccent: window.mauve

//     property string activeMode: "bt"
//     readonly property color activeColor: activeMode === "bt" ? window.btAccent : window.sharedAccent
//     readonly property color activeGradientSecondary: Qt.darker(window.activeColor, 1.25)

//     property var busyTasks: ({})
//     property var disconnectingDevices: ({})
//     property string connectingId: ""
//     property string failedId: ""
    
//     Timer { id: busyTimeout; interval: 15000; onTriggered: { window.busyTasks = ({}); window.disconnectingDevices = ({}); window.connectingId = ""; } }
//     Timer { id: failClearTimer; interval: 4000; onTriggered: window.failedId = "" }

//     Timer { id: ethPendingReset; interval: 8000; onTriggered: { window.ethPowerPending = false; window.expectedEthPower = ""; } }
//     Timer { id: wifiPendingReset; interval: 8000; onTriggered: { window.wifiPowerPending = false; window.expectedWifiPower = ""; } }
//     Timer { id: btPendingReset; interval: 8000; onTriggered: { window.btPowerPending = false; window.expectedBtPower = ""; } }

//     property bool showInfoView: false

//     property string pendingWifiSsid: ""
//     property string pendingWifiId: ""
//     property var savedWifiNetworks: []

//     Process {
//         id: savedNetworksFetcher
//         command: ["bash", "-c", "nmcli -t -f NAME connection show | grep -v 'lo'"]
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 let text = this.text.trim();
//                 window.savedWifiNetworks = text ? text.split('\n') : [];
//             }
//         }
//     }

//     Process {
//         id: connectProcess
//         property string targetId: ""
//         property string targetSsid: ""

//         onExited: {
//             let code = exitCode;
//             let bt = window.busyTasks;
//             delete bt[targetId];
//             window.busyTasks = Object.assign({}, bt);
            
//             if (code !== 0) {
//                 window.failedId = targetId;
//                 failClearTimer.restart();
//                 window.playSfx("error.wav"); 
                
//                 if (window.activeMode === "wifi" && targetSsid !== "") {
//                     Quickshell.execDetached(["bash", "-c", "nmcli connection delete '" + targetSsid + "' 2>/dev/null"]);
//                     let newSaved = [];
//                     for(let i = 0; i < window.savedWifiNetworks.length; i++) {
//                         if(window.savedWifiNetworks[i] !== targetSsid) {
//                             newSaved.push(window.savedWifiNetworks[i]);
//                         }
//                     }
//                     window.savedWifiNetworks = newSaved;
//                 }
//             }
//             window.connectingId = "";
//             if (window.activeMode === "eth") ethPoller.running = true;
//             else if (window.activeMode === "wifi") wifiPoller.running = true; 
//             else btPoller.running = true;
//         }
//     }

//     function connectDevice(mode, id, macOrSsid, password) {
//         window.connectingId = id;
//         window.failedId = "";
//         let bt = window.busyTasks;
//         bt[id] = true;
//         window.busyTasks = Object.assign({}, bt);
//         busyTimeout.restart();

//         connectProcess.targetId = id;
//         connectProcess.targetSsid = (mode === "wifi") ? macOrSsid : ""; 
        
//         if (mode === "eth") {
//             connectProcess.command = ["bash", "-c", "nmcli device connect '" + macOrSsid + "'"];
//         } else if (mode === "wifi") {
//             if (password !== "") {
//                 connectProcess.command = ["bash", "-c", "nmcli device wifi connect '" + macOrSsid + "' password '" + password + "'"];
//             } else {
//                 connectProcess.command = ["bash", "-c", "nmcli device wifi connect '" + macOrSsid + "'"];
//             }
//         } else {
//             connectProcess.command = ["bash", "-c", window.scriptsDir + "/bluetooth_panel_logic.sh --connect '" + macOrSsid + "'"];
//         }
//         connectProcess.running = true;
//     }

//     property var currentCores: [null, null, null, null, null]
//     property var coreVisualIndices: [0, 0, 0, 0, 0]
//     property int activeCoreCount: 0
//     property real smoothedActiveCoreCount: activeCoreCount
//     Behavior on smoothedActiveCoreCount { NumberAnimation { duration: 1000; easing.type: Easing.InOutExpo } }

//     function syncCores() {
//         let list = [];
//         if (activeMode === "eth") {
//             list = window.ethConnected ? [window.ethConnected] : [];
//         } else if (activeMode === "wifi") {
//             let wValid = !!window.wifiConnected && window.wifiConnected.ssid !== undefined;
//             list = wValid ? [window.wifiConnected] : [];
//         } else {
//             list = window.btConnected;
//         }

//         if (!currentPower) list = [];
//         else if (!Array.isArray(list)) list = [list];

//         let newCores = [window.currentCores[0], window.currentCores[1], window.currentCores[2], window.currentCores[3], window.currentCores[4]];
//         let found = [false, false, false, false, false];

//         for (let i = 0; i < list.length && i < 5; i++) {
//             let dev = list[i];
//             let id = activeMode === "wifi" ? dev.ssid : (activeMode === "eth" ? dev.id : dev.mac);
//             for (let c = 0; c < 5; c++) {
//                 if (newCores[c]) {
//                     let cId = activeMode === "wifi" ? newCores[c].ssid : (activeMode === "eth" ? newCores[c].id : newCores[c].mac);
//                     if (cId === id) { found[c] = true; newCores[c] = dev; break; }
//                 }
//             }
//         }

//         for (let c = 0; c < 5; c++) { if (!found[c]) newCores[c] = null; }

//         for (let i = 0; i < list.length && i < 5; i++) {
//             let dev = list[i];
//             let id = activeMode === "wifi" ? dev.ssid : (activeMode === "eth" ? dev.id : dev.mac);
//             let isFound = false;
//             for (let c = 0; c < 5; c++) {
//                 if (newCores[c]) {
//                     let cId = activeMode === "wifi" ? newCores[c].ssid : (activeMode === "eth" ? newCores[c].id : newCores[c].mac);
//                     if (cId === id) { isFound = true; break; }
//                 }
//             }
//             if (!isFound) {
//                 for (let c = 0; c < 5; c++) {
//                     if (!newCores[c]) { newCores[c] = dev; break; }
//                 }
//             }
//         }

//         window.currentCores = [...newCores];

//         let activeCount = 0;
//         let newVis = [0, 0, 0, 0, 0];
//         for (let c = 0; c < 5; c++) {
//             if (newCores[c]) {
//                 newVis[c] = activeCount;
//                 activeCount++;
//             }
//         }
//         window.coreVisualIndices = newVis;
//         window.activeCoreCount = activeCount;
//     }

//     onCurrentConnChanged: {
//         showInfoView = currentConn;
//         if (currentConn) updateInfoNodes();
//     }

//     onActiveModeChanged: {
//         if (!window.ignoreNextModeFileUpdate) {
//             Quickshell.execDetached(["bash", "-c", "echo '" + window.activeMode + "' > '" + window.modeFilePath + "'"]);
//         }
//         window.ignoreNextModeFileUpdate = false;
        
//         window.pendingWifiId = ""; window.pendingWifiSsid = "";
//         if (window.activeMode === "wifi") savedNetworksFetcher.running = true;

//         infoListModel.clear();
//         window.busyTasks = ({});
//         window.disconnectingDevices = ({});
//         window.currentCores = [null, null, null, null, null];
//         window.coreVisualIndices = [0, 0, 0, 0, 0];
//         window.activeCoreCount = 0;
//         syncCores();
//         window.showInfoView = window.currentConn;
//         if (window.showInfoView) window.updateInfoNodes();
//     }

//     ListModel { id: wifiListModel }
//     ListModel { id: btListModel }
//     ListModel { id: infoListModel }

//     function syncModel(listModel, dataArray) {
//         for (let i = listModel.count - 1; i >= 0; i--) {
//             let id = listModel.get(i).id;
//             let found = false;
//             for (let j = 0; j < dataArray.length; j++) {
//                 if (id === dataArray[j].id) { found = true; break; }
//             }
//             if (!found) { listModel.remove(i); }
//         }
        
//         for (let i = 0; i < dataArray.length && i < 30; i++) {
//             let d = dataArray[i];
//             let foundIdx = -1;
//             for (let j = i; j < listModel.count; j++) {
//                 if (listModel.get(j).id === d.id) { foundIdx = j; break; }
//             }
            
//             let obj = {
//                 id: d.id || "", ssid: d.ssid || "", mac: d.mac || "",
//                 name: d.name || d.ssid || "", icon: d.icon || "", security: d.security || "", action: d.action || "",
//                 isInfoNode: d.isInfoNode || false, isActionable: d.isActionable !== undefined ? d.isActionable : false, 
//                 cmdStr: d.cmdStr || "", parentIndex: d.parentIndex !== undefined ? d.parentIndex : -1
//             };

//             if (foundIdx === -1) {
//                 listModel.insert(i, obj);
//             } else {
//                 if (foundIdx !== i) { listModel.move(foundIdx, i, 1); }
//                 for (let key in obj) { 
//                     if (listModel.get(i)[key] !== obj[key]) {
//                         listModel.setProperty(i, key, obj[key]); 
//                     }
//                 }
//             }
//         }
//     }

//     property int hoveredCardCount: 0
//     readonly property bool isListLocked: hoveredCardCount > 0
//     property var nextWifiList: null
//     property var nextBtList: null
//     property var nextInfoList: null

//     onIsListLockedChanged: {
//         if (!isListLocked) {
//             if (nextWifiList !== null) { window.syncModel(wifiListModel, nextWifiList); window.wifiList = nextWifiList; nextWifiList = null; }
//             if (nextBtList !== null) { window.syncModel(btListModel, nextBtList); window.btList = nextBtList; nextBtList = null; }
//             if (nextInfoList !== null) { window.syncModel(infoListModel, nextInfoList); nextInfoList = null; }
//         }
//     }

//     property string ethDeviceName: "" 
//     property bool ethPowerPending: false
//     property string expectedEthPower: ""
//     property string ethPower: "off"
//     property var ethConnected: null
//     readonly property bool isEthConn: !!window.ethConnected

//     onEthConnectedChanged: { syncCores(); if (window.currentConn && window.activeMode === "eth") updateInfoNodes(); }

//     property bool wifiPowerPending: false
//     property string expectedWifiPower: ""
//     property string wifiPower: "off"
//     property var wifiConnected: null
//     property var wifiList: []
//     property string strongestWifiSsid: ""
//     readonly property bool isWifiConn: !!window.wifiConnected && window.wifiConnected.ssid !== undefined

//     readonly property string targetWifiSsid: {
//         let found = false;
//         if (cache.lastWifiSsid !== "") {
//             for (let i = 0; i < wifiList.length; i++) {
//                 if (wifiList[i].id === cache.lastWifiSsid) { found = true; break; }
//             }
//         }
//         return found ? cache.lastWifiSsid : strongestWifiSsid;
//     }

//     onWifiConnectedChanged: {
//         if (window.wifiConnected && window.wifiConnected.ssid) { cache.lastWifiSsid = window.wifiConnected.ssid; }
//         syncCores();
//         if (window.currentConn && window.activeMode === "wifi") updateInfoNodes();
//     }

//     property bool btPowerPending: false
//     property string expectedBtPower: ""
//     property string btPower: "off"
//     property var btConnected: []
//     property var btList: []
//     readonly property bool isBtConn: window.btConnected.length > 0
    
//     onBtConnectedChanged: { 
//         syncCores();
//         if (window.currentConn && window.activeMode === "bt") updateInfoNodes() 
//     }

//     readonly property bool currentPower: activeMode === "eth" ? window.ethPower === "on" : (activeMode === "wifi" ? window.wifiPower === "on" : window.btPower === "on")
//     onCurrentPowerChanged: { syncCores(); }

//     readonly property bool currentPowerPending: activeMode === "eth" ? window.ethPowerPending : (activeMode === "wifi" ? window.wifiPowerPending : window.btPowerPending)
//     readonly property bool currentConn: activeMode === "eth" ? window.isEthConn : (activeMode === "wifi" ? window.isWifiConn : window.isBtConn)
    
//     readonly property var currentObjList: activeMode === "eth" ? (window.isEthConn ? [window.ethConnected] : []) : (activeMode === "wifi" ? (window.isWifiConn ? [window.wifiConnected] : []) : window.btConnected)
    
//     readonly property bool isLogicMultiState: window.activeMode === "bt" && window.activeCoreCount > 1
    
//     property real multiTransitionState: (isLogicMultiState && window.currentPower) ? 1.0 : 0.0
//     Behavior on multiTransitionState { NumberAnimation { duration: 1200; easing.type: Easing.InOutExpo } }

//     function updateInfoNodes() {
//         let nodes = [];
//         let cList = [];
        
//         if (window.activeMode === "eth") {
//             cList = window.ethConnected ? [window.ethConnected] : [];
//         } else if (window.activeMode === "wifi") {
//             let wConn = window.wifiConnected;
//             if (Array.isArray(wConn)) wConn = wConn[0]; 
//             cList = (!!wConn && wConn.ssid !== undefined) ? [wConn] : [];
//         } else {
//             cList = window.btConnected;
//         }
        
//         if (window.currentConn && cList.length > 0) {
//             for (let i = 0; i < cList.length; i++) {
//                 let obj = cList[i];
//                 let cIndex = 0;
                
//                 if (window.activeMode === "bt") {
//                     for (let c = 0; c < 5; c++) {
//                         if (window.currentCores[c] && window.currentCores[c].mac === obj.mac) { cIndex = c; break; }
//                     }
//                 }

//                 if (window.activeMode === "eth") {
//                     nodes.push({ id: "ip", name: obj.ip || "No IP", icon: "󰩟", action: "IP Address", isInfoNode: true, isActionable: false, parentIndex: cIndex });
//                     nodes.push({ id: "spd", name: obj.speed || "Unknown", icon: "󰓅", action: "Link Speed", isInfoNode: true, isActionable: false, parentIndex: cIndex });
//                     nodes.push({ id: "mac", name: obj.mac || "Unknown", icon: "󰒋", action: "MAC Address", isInfoNode: true, isActionable: false, parentIndex: cIndex });
//                 } else if (window.activeMode === "wifi") {
//                     let sigValue = obj.signal !== undefined ? obj.signal + "%" : "Calculating...";
//                     nodes.push({ id: "sig_" + i, name: sigValue, icon: obj.icon || "󰤨", action: "Signal Strength", isInfoNode: true, isActionable: false, parentIndex: cIndex });
//                     nodes.push({ id: "sec_" + i, name: obj.security || "Open", icon: "󰦝", action: "Security", isInfoNode: true, isActionable: false, parentIndex: cIndex });
//                     if (obj.ip) nodes.push({ id: "ip_" + i, name: obj.ip, icon: "󰩟", action: "IP Address", isInfoNode: true, isActionable: false, parentIndex: cIndex });
//                     if (obj.freq) nodes.push({ id: "freq_" + i, name: obj.freq, icon: "󰖧", action: "Band", isInfoNode: true, isActionable: false, parentIndex: cIndex });
//                 } else {
//                     nodes.push({ id: "bat_" + obj.mac, name: (obj.battery || "0") + "%", icon: "󰥉", action: "Battery", isInfoNode: true, isActionable: false, parentIndex: cIndex });
//                     if (obj.profile) {
//                         nodes.push({ id: "prof_" + obj.mac, name: obj.profile, icon: (obj.profile === "Hi-Fi (A2DP)" ? "󰓃" : "󰋎"), action: "Audio Profile", isInfoNode: true, isActionable: false, parentIndex: cIndex });
//                     }
//                     nodes.push({ id: "mac_" + obj.mac, name: obj.mac || "Unknown", icon: "󰒋", action: "MAC Address", isInfoNode: true, isActionable: false, parentIndex: cIndex });
//                 }
//             }
//             if (window.activeMode !== "eth") {
//                 nodes.push({ id: "action_scan", name: "Scan Devices", icon: "󰍉", action: "Switch View", isInfoNode: true, isActionable: true, cmdStr: "TOGGLE_VIEW", parentIndex: -1 });
//             }
//         }
        
//         if (window.isListLocked && window.activeMode !== "eth") window.nextInfoList = nodes;
//         else { window.syncModel(infoListModel, nodes); window.nextInfoList = null; }
//     }

//     function processEthJson(textData, isCache = false) {
//         if (!isCache && window.ethFirstLoad) {
//             window.powerAnimAllowed = false;
//             powerAnimBlocker.restart();
//             window.ethFirstLoad = false;
//         }
//         if (textData === "") { if (!isCache) validateActiveMode(); return; }
//         try {
//             let data = JSON.parse(textData);
//             window.ethPresent = data.present === true;
//             let fetchedDevice = data.device || "";
//             if (fetchedDevice !== "") window.ethDeviceName = fetchedDevice;
//             let fetchedPower = data.power || "off";
            
//             if (window.ethPowerPending) {
//                 window.ethPower = window.expectedEthPower; 
//                 if (fetchedPower === window.expectedEthPower) {
//                     window.ethPowerPending = false; 
//                     ethPendingReset.stop();
//                 }
//             } else {
//                 window.ethPower = fetchedPower;
//                 window.expectedEthPower = "";
//             }

//             let newConnected = data.connected;
//             if (JSON.stringify(window.ethConnected) !== JSON.stringify(newConnected)) {
//                 if (!window.isEthConn && newConnected && window.activeMode === "eth") window.playSfx("connect.wav");
//                 window.ethConnected = newConnected;
//             }
//         } catch(e) {}
//         if (!isCache) validateActiveMode();
//     }

//     function processWifiJson(textData, isCache = false) {
//         if (!isCache && window.wifiFirstLoad) {
//             window.powerAnimAllowed = false;
//             powerAnimBlocker.restart();
//             window.wifiFirstLoad = false;
//         }
//         if (textData === "") { if (!isCache) validateActiveMode(); return; }
//         try {
//             let data = JSON.parse(textData);
//             window.wifiPresent = data.present === true;
//             let fetchedPower = data.power || "off";
            
//             if (window.wifiPowerPending) {
//                 window.wifiPower = window.expectedWifiPower; 
//                 if (fetchedPower === window.expectedWifiPower) {
//                     window.wifiPowerPending = false; 
//                     wifiPendingReset.stop();
//                 }
//             } else {
//                 window.wifiPower = fetchedPower;
//                 window.expectedWifiPower = "";
//             }

//             let wasWifiConn = !!window.wifiConnected && window.wifiConnected.ssid !== undefined;
//             let newConnected = data.connected;
//             let newNetworks = data.networks ? data.networks : [];

//             if (newConnected && newConnected.ssid) {
//                 let match = newNetworks.find(n => n.id === newConnected.ssid || n.ssid === newConnected.ssid);
//                 if (match) {
//                     newConnected.icon = match.icon || newConnected.icon;
//                     newConnected.name = match.name || newConnected.name;
//                     newConnected.security = match.security || newConnected.security;
//                     newConnected.signal = match.signal || newConnected.signal;
//                     newConnected.freq = match.freq || newConnected.freq;
//                     newConnected.ip = match.ip || newConnected.ip;
//                 }
//             }

//             let isNowWifiConn = !!newConnected && newConnected.ssid !== undefined;

//             if (JSON.stringify(window.wifiConnected) !== JSON.stringify(newConnected)) {
//                 window.wifiConnected = newConnected;
//             }
            
//             if (newNetworks.length > 0) {
//                 let maxSig = -1; let bestSsid = newNetworks[0].id;
//                 for (let i = 0; i < newNetworks.length; i++) {
//                     let sig = parseInt(newNetworks[i].signal || 0);
//                     if (sig > maxSig) { maxSig = sig; bestSsid = newNetworks[i].id; }
//                 }
//                 window.strongestWifiSsid = bestSsid;
//             } else { window.strongestWifiSsid = ""; }

//             newNetworks.sort((a, b) => a.id.localeCompare(b.id));

//             if (isNowWifiConn && window.activeMode === "wifi") {
//                 newNetworks.push({ id: "action_settings", ssid: "Current Device", mac: "", name: "Current Device", icon: "󰒓", security: "", action: "View Info", isInfoNode: false, isActionable: true, cmdStr: "TOGGLE_VIEW", parentIndex: -1 });
//             }

//             if (JSON.stringify(window.wifiList) !== JSON.stringify(newNetworks)) {
//                 if (window.isListLocked) window.nextWifiList = newNetworks;
//                 else { window.syncModel(wifiListModel, newNetworks); window.wifiList = newNetworks; window.nextWifiList = null; }
//             }

//             if (window.activeMode === "wifi") {
//                 if (!wasWifiConn && isNowWifiConn) {
//                     window.showInfoView = true;
//                 }
                
//                 let dd = window.disconnectingDevices;
//                 let ddChanged = false;
//                 for (let ssid in dd) {
//                     if (!isNowWifiConn || (newConnected && newConnected.ssid !== ssid)) {
//                         delete dd[ssid];
//                         ddChanged = true;
//                     }
//                 }
//                 if (ddChanged) {
//                     window.disconnectingDevices = Object.assign({}, dd);
//                     if (Object.keys(window.disconnectingDevices).length === 0 && Object.keys(window.busyTasks).length === 0) busyTimeout.stop();
//                 }
                
//                 let newlyConnected = false;
//                 let bt = window.busyTasks;
//                 if (isNowWifiConn && newConnected && bt[newConnected.ssid]) {
//                     newlyConnected = true;
//                     delete bt[newConnected.ssid];
//                     window.connectingId = "";
//                 }
//                 if (newlyConnected) {
//                     window.playSfx("connect.wav");
//                     window.busyTasks = Object.assign({}, bt);
//                     if (Object.keys(window.busyTasks).length === 0 && Object.keys(window.disconnectingDevices).length === 0) busyTimeout.stop();
//                 }

//                 if (isNowWifiConn || window.isBtConn || window.isEthConn) window.updateInfoNodes();
//             }
//         } catch(e) {}
//         if (!isCache) validateActiveMode();
//     }

//     function processBtJson(textData, isCache = false) {
//         if (!isCache && window.btFirstLoad) {
//             window.powerAnimAllowed = false;
//             powerAnimBlocker.restart();
//             window.btFirstLoad = false;
//         }
//         if (textData === "") { if (!isCache) validateActiveMode(); return; }
//         try {
//             let data = JSON.parse(textData);
//             window.btPresent = data.present === true;
//             let fetchedPower = data.power || "off";
            
//             if (window.btPowerPending) {
//                 window.btPower = window.expectedBtPower; 
//                 if (fetchedPower === window.expectedBtPower) {
//                     window.btPowerPending = false; 
//                     btPendingReset.stop();
//                 }
//             } else {
//                 window.btPower = fetchedPower;
//                 window.expectedBtPower = "";
//             }

//             let oldBtLen = window.btConnected.length;
//             let newBtConnected = data.connected || [];
//             if (!Array.isArray(newBtConnected)) newBtConnected = [newBtConnected];
//             let isNowBtConn = newBtConnected.length > 0;

//             if (JSON.stringify(window.btConnected) !== JSON.stringify(newBtConnected)) {
//                 window.btConnected = newBtConnected;
//             }

//             let newDevices = data.devices ? data.devices : [];
//             newDevices.sort((a, b) => a.id.localeCompare(b.id));

//             if (isNowBtConn && window.activeMode === "bt") {
//                 newDevices.push({ id: "action_settings", ssid: "", mac: "action_settings", name: "Current Device", icon: "󰒓", action: "View Info", isInfoNode: false, isActionable: true, cmdStr: "TOGGLE_VIEW", parentIndex: -1 });
//             }

//             if (JSON.stringify(window.btList) !== JSON.stringify(newDevices)) {
//                 if (window.isListLocked) window.nextBtList = newDevices;
//                 else { window.syncModel(btListModel, newDevices); window.btList = newDevices; window.nextBtList = null; }
//             }

//             if (window.activeMode === "bt") {
//                 if (newBtConnected.length > oldBtLen) {
//                     window.showInfoView = true;
//                 }

//                 let dd = window.disconnectingDevices;
//                 let ddChanged = false;
//                 for (let mac in dd) {
//                     let stillConnected = false;
//                     for (let i = 0; i < newBtConnected.length; i++) {
//                         if (newBtConnected[i].mac === mac) { stillConnected = true; break; }
//                     }
//                     if (!stillConnected) {
//                         delete dd[mac];
//                         ddChanged = true;
//                     }
//                 }
//                 if (ddChanged) {
//                     window.disconnectingDevices = Object.assign({}, dd);
//                     if (Object.keys(window.disconnectingDevices).length === 0 && Object.keys(window.busyTasks).length === 0) busyTimeout.stop();
//                 }
                
//                 let newlyConnected = false;
//                 let bt = window.busyTasks;
//                 for (let i = 0; i < newBtConnected.length; i++) {
//                     let mac = newBtConnected[i].mac;
//                     if (bt[mac]) {
//                         newlyConnected = true;
//                         delete bt[mac];
//                         window.connectingId = "";
//                     }
//                 }
//                 if (newlyConnected) {
//                     window.playSfx("connect.wav");
//                     window.busyTasks = Object.assign({}, bt);
//                     if (Object.keys(window.busyTasks).length === 0 && Object.keys(window.disconnectingDevices).length === 0) busyTimeout.stop();
//                 }

//                 if (isNowBtConn || window.isWifiConn || window.isEthConn) window.updateInfoNodes();
//             }
//         } catch(e) {}
//         if (!isCache) validateActiveMode();
//     }

//     Process {
//         id: ethPoller
//         command: ["bash", window.scriptsDir + "/eth_panel_logic.sh"]
//         running: true
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 cache.lastEthJson = this.text.trim();
//                 processEthJson(cache.lastEthJson);
//             }
//         }
//     }

//     Process {
//         id: wifiPoller
//         command: ["bash", window.scriptsDir + "/wifi_panel_logic.sh"]
//         running: true
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 cache.lastWifiJson = this.text.trim();
//                 processWifiJson(cache.lastWifiJson);
//             }
//         }
//     }

//     Process {
//         id: btPoller
//         command: ["bash", window.scriptsDir + "/bluetooth_panel_logic.sh", "--status"]
//         running: true
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 cache.lastBtJson = this.text.trim();
//                 processBtJson(cache.lastBtJson);
//             }
//         }
//     }
    
//     Timer {
//         interval: (Object.keys(window.busyTasks).length > 0 || Object.keys(window.disconnectingDevices).length > 0) ? 1000 : 3000
//         running: true; repeat: true
//         onTriggered: { 
//             if (!ethPoller.running) ethPoller.running = true; 
//             if (!wifiPoller.running) wifiPoller.running = true; 
//             if (!btPoller.running) btPoller.running = true; 
//         }
//     }

//     property real globalOrbitAngle: 0
//     NumberAnimation on globalOrbitAngle {
//         from: 0; to: Math.PI * 2; duration: 200000; loops: Animation.Infinite; running: true
//     }

//     property real introState: 0.0
//     Behavior on introState { NumberAnimation { duration: 1500; easing.type: Easing.OutCubic } }

//     component LoadingDots : Row {
//         spacing: window.s(5)
//         property color dotCol: window.text
//         Repeater {
//             model: 3
//             Rectangle {
//                 width: window.s(6); height: window.s(6); radius: window.s(3); color: dotCol
//                 SequentialAnimation on y {
//                     loops: Animation.Infinite
//                     PauseAnimation { duration: index * 100 }
//                     NumberAnimation { from: 0; to: window.s(-6); duration: 250; easing.type: Easing.OutSine }
//                     NumberAnimation { from: window.s(-6); to: 0; duration: 250; easing.type: Easing.InSine }
//                     PauseAnimation { duration: (2 - index) * 100 }
//                 }
//             }
//         }
//     }

//     Item {
//         anchors.fill: parent

//         Rectangle {
//             anchors.fill: parent
//             radius: window.s(20)
//             color: window.base
//             border.color: window.surface0
//             border.width: 1
//             clip: true
            
//             Rectangle {
//                 width: parent.width * 0.8; height: width; radius: width / 2
//                 x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)
//                 y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)
//                 opacity: window.currentPower ? 0.08 : 0.02
//                 color: window.currentConn ? window.activeColor : window.surface2
//                 Behavior on color { ColorAnimation { duration: 1000 } }
//                 Behavior on opacity { NumberAnimation { duration: 1000 } }
//                 visible: opacity > 0.01
//             }
            
//             Rectangle {
//                 width: parent.width * 0.9; height: width; radius: width / 2
//                 x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)
//                 y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)
//                 opacity: window.currentPower ? 0.06 : 0.01
//                 color: window.currentConn ? window.activeGradientSecondary : window.surface1
//                 Behavior on color { ColorAnimation { duration: 1000 } }
//                 Behavior on opacity { NumberAnimation { duration: 1000 } }
//                 visible: opacity > 0.01
//             }

//             Item {
//                 id: radarItem
//                 anchors.fill: parent
//                 anchors.bottomMargin: window.s(80) 
//                 opacity: window.currentPower ? 1.0 : 0.0
//                 scale: window.currentPower ? 1.0 : 1.05
//                 visible: opacity > 0.01
//                 Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutQuad } }
//                 Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                
//                 Repeater {
//                     model: 3
//                     Rectangle {
//                         anchors.centerIn: parent
//                         width: window.s(280) + (index * window.s(170))
//                         height: width
//                         radius: width / 2
//                         color: "transparent"
                        
//                         border.color: Object.keys(window.disconnectingDevices).length > 0 ? window.red : window.activeColor
//                         border.width: Object.keys(window.disconnectingDevices).length > 0 ? window.s(2) : 1
                        
//                         Behavior on border.color { ColorAnimation { duration: 150 } }
//                         Behavior on border.width { NumberAnimation { duration: 150 } }

//                         opacity: Object.keys(window.disconnectingDevices).length > 0 ? 0.2 : (window.currentConn ? 0.08 - (index * 0.02) : 0.03)
//                         Behavior on opacity { NumberAnimation { duration: 150 } }
//                     }
//                 }
//             }

//             Canvas {
//                 id: nodeLinesCanvas
//                 anchors.fill: parent
//                 anchors.bottomMargin: window.s(80)
//                 z: 0 
//                 opacity: (window.currentConn && window.showInfoView && window.currentPower) ? 1.0 : 0.0
//                 visible: opacity > 0.01
//                 Behavior on opacity { NumberAnimation { duration: 500 } }
                
//                 property real scaleTrigger: window.s(1)
//                 onScaleTriggerChanged: requestPaint()

//                 Timer {
//                     id: lightningTimer
//                     interval: 45
//                     running: nodeLinesCanvas.opacity > 0.01 && window.currentPower 
//                     repeat: true
//                     onTriggered: nodeLinesCanvas.requestPaint()
//                 }

//                 Connections {
//                     target: window
//                     function onGlobalOrbitAngleChanged() { 
//                         if (window.currentConn && window.showInfoView && window.currentPower) nodeLinesCanvas.requestPaint() 
//                     }
//                 }
                
//                 onPaint: {
//                     var ctx = getContext("2d");
//                     var s = window.s;
//                     ctx.clearRect(0, 0, width, height);
//                     if (!window.currentConn || !window.showInfoView || !window.currentPower) return;
                    
//                     var time = Date.now() / 1000;
                    
//                     var time = Date.now() / 1000;
//                     ctx.lineJoin = "round";
//                     ctx.lineCap = "round";

//                     var tWave1 = time * 2.5;
//                     var tWave2 = time * -1.5;

//                     for (var i = 0; i < orbitRepeater.count; i++) {
//                         var item = orbitRepeater.itemAt(i);
//                         if (!item || !item.isLoaded) continue;

//                         var targetX = item.x + item.width / 2;
//                         var targetY = item.y + item.height / 2;

//                         function drawStrands(startX, startY, parentFade, parentWidth) {
//                             var dx = targetX - startX;
//                             var dy = targetY - startY;
//                             var fullDist = Math.sqrt(dx * dx + dy * dy);
                            
//                             if (fullDist < s(10)) return;

//                             var alpha = Math.atan2(dy, dx);
//                             var cosA = Math.cos(alpha);
//                             var sinA = Math.sin(alpha);
                            
//                             var coreVisualRadius = parentWidth / 2;
//                             var startOffset = coreVisualRadius + s(5); 
//                             var endOffset = s(35); 
                            
//                             var drawDist = fullDist - startOffset - endOffset;
//                             if (drawDist <= 0) return;
                            
//                             var steps = 8;
//                             var perpX = -sinA;
//                             var perpY = cosA;

//                             var sX = startX + cosA * startOffset;
//                             var sY = startY + sinA * startOffset;

//                             var distanceFactor = Math.max(0, 1.0 - (fullDist / 400.0));
//                             var dynamicLineWidthCore = s(1.0) + (distanceFactor * s(2.0));
//                             var dynamicLineWidthGlow = s(4.0) + (distanceFactor * s(4.0));
//                             var dynamicAlpha = (0.2 + (distanceFactor * 0.7)) * parentFade;

//                             ctx.beginPath();
//                             ctx.moveTo(sX, sY);
//                             for (var j = 1; j <= steps; j++) {
//                                 var t = j / steps;
//                                 var currentDist = drawDist * t;
//                                 var envelope = Math.sin(t * Math.PI);
//                                 var offset = Math.sin(tWave1 + t * 6) * s(6) * envelope + ((Math.random() - 0.5) * s(5.0) * distanceFactor);
//                                 ctx.lineTo(sX + cosA * currentDist + perpX * offset, sY + sinA * currentDist + perpY * offset);
//                             }
//                             ctx.lineWidth = dynamicLineWidthGlow;
//                             ctx.strokeStyle = window.activeColor;
//                             ctx.globalAlpha = dynamicAlpha * 0.15;
//                             ctx.stroke();

//                             ctx.lineWidth = dynamicLineWidthCore;
//                             ctx.strokeStyle = "#ffffff";
//                             ctx.globalAlpha = dynamicAlpha;
//                             ctx.stroke();

//                             ctx.beginPath();
//                             ctx.moveTo(sX, sY);
//                             for (var k = 1; k <= steps; k++) {
//                                 var tk = k / steps;
//                                 var currentDistK = drawDist * tk;
//                                 var envelopeK = Math.sin(tk * Math.PI);
//                                 var offsetK = Math.cos(tWave2 + tk * 8) * s(12) * envelopeK + ((Math.random() - 0.5) * s(3.0) * distanceFactor);
//                                 ctx.lineTo(sX + cosA * currentDistK + perpX * offsetK, sY + sinA * currentDistK + perpY * offsetK);
//                             }
//                             ctx.lineWidth = dynamicLineWidthCore * 1.5;
//                             ctx.strokeStyle = window.activeColor;
//                             ctx.globalAlpha = dynamicAlpha * 0.3;
//                             ctx.stroke();
//                         }

//                         if (item.myParentIdx === -1) {
//                             for (var c = 0; c < coreRepeater.count; c++) {
//                                 var cItem = coreRepeater.itemAt(c);
//                                 if (cItem && cItem.activeTransition > 0.01) {
//                                     drawStrands(cItem.x + cItem.width/2, cItem.y + cItem.height/2, cItem.activeTransition, cItem.width);
//                                 }
//                             }
//                         } else {
//                             var pItem = coreRepeater.itemAt(item.myParentIdx);
//                             if (pItem && pItem.activeTransition > 0.01) {
//                                 drawStrands(pItem.x + pItem.width/2, pItem.y + pItem.height/2, pItem.activeTransition, pItem.width);
//                             }
//                         }
//                     }
//                 }
//             }

//             Item {
//                 id: orbitContainer
//                 anchors.fill: parent
//                 anchors.bottomMargin: window.s(80) 
//                 z: 1

//                 Repeater {
//                     id: coreRepeater
//                     model: 5

//                     delegate: Item {
//                         id: coreContainer
                        
//                         property var myDevice: window.currentCores[index]
                        
//                         property bool isPrimary: index === 0
//                         property bool hasDevice: myDevice !== null
//                         property bool isReallyActive: window.currentPower && (hasDevice || (isPrimary && window.activeCoreCount === 0))

//                         property real activeTransition: isReallyActive ? 1.0 : 0.0
                        
//                         Behavior on activeTransition { 
//                             enabled: window.introState >= 1.0; 
//                             NumberAnimation { duration: 1400; easing.type: Easing.OutExpo } 
//                         }

//                         property real multiShift: window.activeMode === "wifi" || window.activeMode === "eth" ? 0.0 : window.multiTransitionState

//                         width: window.currentPower ? (window.s(200) - (window.s(30) * multiShift) - (window.s(15) * Math.max(0, window.smoothedActiveCoreCount - 2))) : window.s(160)
//                         height: width
                        
//                         property real myBaseAngle: (window.coreVisualIndices[index] / Math.max(1, window.activeCoreCount)) * Math.PI * 2
//                         property real animatedBaseAngle: myBaseAngle
//                         Behavior on animatedBaseAngle { NumberAnimation { duration: 1000; easing.type: Easing.InOutExpo } }
                        
//                         property real coreOrbitAngle: window.globalOrbitAngle * 1.5 + animatedBaseAngle
                        
//                         property real myOrbitRadiusX: window.s(180) + (window.activeCoreCount > 2 ? window.s(20) : 0)
//                         property real myOrbitRadiusY: window.s(110) + (window.activeCoreCount > 2 ? window.s(15) : 0)

//                         x: window.activeMode === "eth" ? (orbitContainer.width / 2 - width / 2) : ((orbitContainer.width / 2 - width / 2) + (Math.cos(coreOrbitAngle) * myOrbitRadiusX * multiShift * activeTransition))
//                         y: window.activeMode === "eth" ? (orbitContainer.height / 2 - height / 2) : ((orbitContainer.height / 2 - height / 2) + (Math.sin(coreOrbitAngle) * myOrbitRadiusY * multiShift * activeTransition))
                        
//                         opacity: activeTransition
//                         scale: centralCore.bumpScale * (0.8 + 0.2 * activeTransition)
//                         visible: opacity > 0.01

//                         property string myId: myDevice ? (window.activeMode === "wifi" ? myDevice.ssid : (window.activeMode === "eth" ? myDevice.id : myDevice.mac)) : "unknown"
//                         property bool isMyDisconnecting: !!window.disconnectingDevices[myId]

//                         property bool showScanning: isPrimary && window.currentPower && !window.currentConn && window.pendingWifiId === "" && window.activeMode !== "eth"
//                         property bool showConnected: window.currentConn && hasDevice && window.pendingWifiId === ""
//                         property bool showPassword: isPrimary && window.pendingWifiId !== "" && window.activeMode === "wifi"
//                         property bool showEthDisconnected: isPrimary && window.currentPower && !window.currentConn && window.activeMode === "eth"

//                         MultiEffect {
//                             source: centralCore
//                             anchors.fill: centralCore
//                             shadowEnabled: true
//                             shadowColor: "#000000"
//                             shadowOpacity: window.currentPower ? 0.5 : 0.0
//                             shadowBlur: 1.2
//                             shadowVerticalOffset: window.s(6)
//                             z: -1
//                             Behavior on shadowOpacity { NumberAnimation { duration: 600 } }
//                         }

//                         Rectangle {
//                             id: centralCore
//                             anchors.fill: parent
//                             radius: width / 2
                            
//                             property real disconnectFill: 0.0
//                             property bool disconnectTriggered: false
//                             property real flashOpacity: 0.0
//                             property real bumpScale: 1.0
//                             property bool isDangerState: coreMa.containsMouse || disconnectFill > 0 || isMyDisconnecting

//                             SequentialAnimation on bumpScale {
//                                 id: coreBumpAnim
//                                 running: false
//                                 NumberAnimation { to: 1.15; duration: 200; easing.type: Easing.OutBack }
//                                 NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.OutQuint }
//                             }

//                             gradient: Gradient {
//                                 orientation: Gradient.Vertical
//                                 GradientStop {
//                                     position: 0.0
//                                     color: {
//                                         if (!window.currentPower) return window.mantle;
//                                         if (isMyDisconnecting) return window.surface0; 
//                                         if (centralCore.isDangerState && window.currentConn && !showPassword) return Qt.lighter(window.red, 1.15);
//                                         return window.currentConn || showPassword ? Qt.lighter(window.activeColor, 1.15) : window.surface0;
//                                     }
//                                     Behavior on color { ColorAnimation { duration: 300 } }
//                                 }
//                                 GradientStop {
//                                     position: 1.0
//                                     color: {
//                                         if (!window.currentPower) return window.crust;
//                                         if (isMyDisconnecting) return window.base; 
//                                         if (centralCore.isDangerState && window.currentConn && !showPassword) return window.red;
//                                         return window.currentConn || showPassword ? window.activeColor : window.base;
//                                     }
//                                     Behavior on color { ColorAnimation { duration: 300 } }
//                                 }
//                             }

//                             border.color: {
//                                 if (!window.currentPower) return window.crust;
//                                 if (isMyDisconnecting) return window.surface0;
//                                 if (centralCore.isDangerState && window.currentConn && !showPassword) return window.maroon;
//                                 return window.currentConn || showPassword ? Qt.lighter(window.activeColor, 1.1) : window.surface1;
//                             }
//                             border.width: window.s(2)
//                             Behavior on border.color { ColorAnimation { duration: 300 } }
                            
//                             Rectangle {
//                                 anchors.fill: parent
//                                 radius: parent.radius
//                                 color: "#ffffff"
//                                 opacity: centralCore.flashOpacity
//                                 PropertyAnimation on opacity { id: coreFlashAnim; to: 0; duration: 500; easing.type: Easing.OutExpo }
//                             }

//                             Canvas {
//                                 id: coreWave
//                                 anchors.fill: parent
//                                 visible: centralCore.disconnectFill > 0
//                                 opacity: 0.95
                                
//                                 property real scaleTrigger: window.s(1)
//                                 onScaleTriggerChanged: requestPaint()

//                                 property real wavePhase: 0.0
//                                 NumberAnimation on wavePhase {
//                                     running: centralCore.disconnectFill > 0.0 && centralCore.disconnectFill < 1.0
//                                     loops: Animation.Infinite
//                                     from: 0; to: Math.PI * 2; duration: 800
//                                 }
//                                 onWavePhaseChanged: requestPaint()
//                                 Connections { target: centralCore; function onDisconnectFillChanged() { coreWave.requestPaint() } }

//                                 onPaint: {
//                                     var ctx = getContext("2d");
//                                     var s = window.s;
//                                     ctx.clearRect(0, 0, width, height);
//                                     if (centralCore.disconnectFill <= 0.001) return;

//                                     var r = width / 2;
//                                     var fillY = height * (1.0 - centralCore.disconnectFill);

//                                     ctx.save();
//                                     ctx.beginPath();
//                                     ctx.arc(r, r, r, 0, 2 * Math.PI);
//                                     ctx.clip(); 

//                                     ctx.beginPath();
//                                     ctx.moveTo(0, fillY);
//                                     if (centralCore.disconnectFill < 0.99) {
//                                         var waveAmp = s(10) * Math.sin(centralCore.disconnectFill * Math.PI);
//                                         var cp1y = fillY + Math.sin(wavePhase) * waveAmp;
//                                         var cp2y = fillY + Math.cos(wavePhase + Math.PI) * waveAmp;
//                                         ctx.bezierCurveTo(width * 0.33, cp2y, width * 0.66, cp1y, width, fillY);
//                                         ctx.lineTo(width, height);
//                                         ctx.lineTo(0, height);
//                                     } else {
//                                         ctx.lineTo(width, 0);
//                                         ctx.lineTo(width, height);
//                                         ctx.lineTo(0, height);
//                                     }
//                                     ctx.closePath();
                                    
//                                     var grad = ctx.createLinearGradient(0, 0, 0, height);
//                                     grad.addColorStop(0, window.surface1.toString()); 
//                                     grad.addColorStop(1, window.crust.toString());
//                                     ctx.fillStyle = grad;
//                                     ctx.fill();
//                                     ctx.restore();
//                                 }
//                             }

//                             Rectangle {
//                                 anchors.centerIn: parent
//                                 width: parent.width + window.s(40)
//                                 height: width
//                                 radius: width / 2
//                                 color: centralCore.isDangerState && window.currentConn && !showPassword ? window.red : window.activeColor
//                                 opacity: (window.currentConn || showPassword) && !isMyDisconnecting ? (centralCore.isDangerState && !showPassword ? 0.3 : 0.15) : 0.0
//                                 z: -1
//                                 Behavior on color { ColorAnimation { duration: 200 } }
//                                 Behavior on opacity { NumberAnimation { duration: 300 } }
                                
//                                 SequentialAnimation on scale {
//                                     loops: Animation.Infinite; running: window.currentConn || showPassword
//                                     NumberAnimation { to: 1.1; duration: 2000; easing.type: Easing.InOutSine }
//                                     NumberAnimation { to: 1.0; duration: 2000; easing.type: Easing.InOutSine }
//                                 }
//                             }
                            
//                             Rectangle {
//                                 anchors.centerIn: parent
//                                 width: parent.width + window.s(15)
//                                 height: width
//                                 radius: width / 2
//                                 color: "transparent"
//                                 border.color: centralCore.isDangerState && !showPassword ? window.red : window.activeColor
//                                 border.width: window.s(3)
//                                 z: -2
                                
//                                 property real pulseOp: 0.0
//                                 property real pulseSc: 1.0
//                                 opacity: ((window.currentConn || showPassword) && window.showInfoView && window.currentPower && !isMyDisconnecting) ? pulseOp : 0.0
//                                 scale: pulseSc
                                
//                                 Timer {
//                                     interval: 45
//                                     running: parent.opacity > 0.01
//                                     repeat: true
//                                     onTriggered: {
//                                         var time = Date.now() / 1000;
//                                         parent.pulseOp = 0.3 + Math.sin(time * 2.5) * 0.15;
//                                         parent.pulseSc = 1.02 + Math.cos(time * 3.0) * 0.02;
//                                     }
//                                 }
//                             }

//                             Item {
//                                 anchors.fill: parent
//                                 opacity: showScanning ? 1.0 : 0.0
//                                 visible: opacity > 0.01
//                                 Behavior on opacity { NumberAnimation { duration: 400 } }

//                                 Repeater {
//                                     model: 3
//                                     Rectangle {
//                                         anchors.centerIn: parent
//                                         width: parent.width * 0.4; height: width; radius: width / 2
//                                         color: "transparent"
//                                         border.color: window.activeColor; border.width: window.s(2)
//                                         SequentialAnimation on scale {
//                                             running: showScanning; loops: Animation.Infinite
//                                             PauseAnimation { duration: index * 400 }
//                                             NumberAnimation { from: 1.0; to: 2.5; duration: 2000; easing.type: Easing.OutSine }
//                                         }
//                                         SequentialAnimation on opacity {
//                                             running: showScanning; loops: Animation.Infinite
//                                             PauseAnimation { duration: index * 400 }
//                                             NumberAnimation { from: 0.8; to: 0.0; duration: 2000; easing.type: Easing.OutSine }
//                                         }
//                                     }
//                                 }
//                                 Text {
//                                     anchors.centerIn: parent
//                                     font.family: "Iosevka Nerd Font"
//                                     font.pixelSize: window.s(48) - (window.s(16) * coreContainer.multiShift)
//                                     color: window.activeColor
//                                     text: window.activeMode === "wifi" ? "󰤨" : (window.activeMode === "eth" ? "󰈀" : "󰂯")
//                                     SequentialAnimation on opacity {
//                                         running: showScanning; loops: Animation.Infinite
//                                         NumberAnimation { to: 0.5; duration: 1000; easing.type: Easing.InOutSine }
//                                         NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
//                                     }
//                                 }
//                             }

//                             ColumnLayout {
//                                 anchors.centerIn: parent
//                                 spacing: window.s(10)
//                                 visible: showEthDisconnected
//                                 opacity: visible ? 1.0 : 0.0
//                                 Behavior on opacity { NumberAnimation { duration: 300 } }
//                                 Text { Layout.alignment: Qt.AlignHCenter; font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(48); color: window.overlay0; text: "󰈂" }
//                                 Text { Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(14); color: window.overlay0; text: window.currentPowerPending ? (window.expectedEthPower === "on" ? "Powering On..." : "Powering Off...") : "Disconnected" }
//                             }

//                             Item {
//                                 id: pwdLayer
//                                 anchors.fill: parent
//                                 opacity: showPassword ? 1.0 : 0.0
//                                 visible: opacity > 0.01
//                                 scale: showPassword ? 1.0 : 0.8
//                                 Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
//                                 Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutSine } }
                                
//                                 ColumnLayout {
//                                     anchors.centerIn: parent
//                                     spacing: window.s(8)
                                    
//                                     Text { Layout.alignment: Qt.AlignHCenter; font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(32); color: window.crust; text: "󰤨" }
                                    
//                                     Text { 
//                                         Layout.alignment: Qt.AlignHCenter; Layout.maximumWidth: pwdLayer.width - window.s(40)
//                                         font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(13)
//                                         color: window.crust; text: window.pendingWifiSsid; elide: Text.ElideRight 
//                                     }
                                    
//                                     Rectangle {
//                                         Layout.alignment: Qt.AlignHCenter
//                                         Layout.preferredWidth: pwdLayer.width - window.s(40); height: window.s(36)
//                                         radius: window.s(18)
//                                         color: window.surface0
//                                         border.color: wifiPasswordField.activeFocus ? window.crust : "transparent"
//                                         border.width: 1
//                                         Behavior on border.color { ColorAnimation { duration: 200 } }
                                        
//                                         TextInput {
//                                             id: wifiPasswordField
//                                             anchors.fill: parent
//                                             anchors.leftMargin: window.s(15); anchors.rightMargin: window.s(15)
//                                             verticalAlignment: TextInput.AlignVCenter
//                                             font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.text
//                                             echoMode: TextInput.Password; clip: true
//                                             onAccepted: {
//                                                 if (text.trim() !== "") {
//                                                     window.connectDevice(window.activeMode, window.pendingWifiId, window.pendingWifiSsid, text);
//                                                     window.pendingWifiId = ""; window.pendingWifiSsid = ""; text = "";
//                                                     window.forceActiveFocus();
//                                                 }
//                                             }
//                                             Keys.onEscapePressed: { window.pendingWifiId = ""; window.pendingWifiSsid = ""; text = ""; window.forceActiveFocus(); }
//                                         }
//                                     }
//                                 }
                                
//                                 Timer { id: deferFocusTimer; interval: 50; onTriggered: wifiPasswordField.forceActiveFocus() }
//                                 onVisibleChanged: { if (visible) { wifiPasswordField.text = ""; deferFocusTimer.start(); } }
//                             }

//                             Item {
//                                 anchors.fill: parent
//                                 opacity: showConnected ? 1.0 : 0.0
//                                 visible: opacity > 0.01
//                                 scale: showConnected ? 1.0 : 0.95
//                                 Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
//                                 Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutSine } }

//                                 ColumnLayout {
//                                     id: baseCoreText
//                                     anchors.centerIn: parent
//                                     spacing: window.s(4)

//                                     Text {
//                                         Layout.alignment: Qt.AlignHCenter
//                                         font.family: "Iosevka Nerd Font"
//                                         font.pixelSize: window.s(48) - (window.s(16) * coreContainer.multiShift)
//                                         color: isMyDisconnecting ? window.overlay1 : window.crust
//                                         text: isMyDisconnecting ? "" : (coreMa.containsMouse ? (window.activeMode === "wifi" ? "󰖪" : (window.activeMode === "eth" ? "󰈂" : "󰂲")) : (coreContainer.myDevice ? (coreContainer.myDevice.icon || (window.activeMode === "wifi" ? "󰤨" : (window.activeMode === "eth" ? "󰈀" : "󰂯"))) : ""))
//                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                     }
//                                     LoadingDots { Layout.alignment: Qt.AlignHCenter; visible: isMyDisconnecting; dotCol: window.overlay1 }
//                                     Text {
//                                         Layout.alignment: Qt.AlignHCenter
//                                         Layout.maximumWidth: window.s(150) - (window.s(50) * coreContainer.multiShift)
//                                         horizontalAlignment: Text.AlignHCenter
//                                         font.family: "JetBrains Mono"; font.weight: Font.Black
//                                         font.pixelSize: window.s(16) - (window.s(4) * coreContainer.multiShift)
//                                         color: isMyDisconnecting ? window.overlay1 : window.crust
//                                         text: coreContainer.myDevice ? (window.activeMode === "wifi" ? coreContainer.myDevice.ssid : coreContainer.myDevice.name) : ""
//                                         elide: Text.ElideRight
//                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                     }
//                                     Text {
//                                         Layout.alignment: Qt.AlignHCenter
//                                         font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(11)
//                                         color: isMyDisconnecting ? window.overlay1 : (coreMa.containsMouse ? window.crust : "#99000000")
//                                         text: isMyDisconnecting ? "Disconnecting..." : (centralCore.disconnectFill > 0.01 ? "Hold..." : "Connected")
//                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                     }
//                                 }

//                                 Item {
//                                     id: waveClipItem
//                                     anchors.bottom: parent.bottom
//                                     anchors.left: parent.left
//                                     anchors.right: parent.right
//                                     height: Math.min(parent.height, Math.max(0, parent.height * centralCore.disconnectFill + window.s(8)))
//                                     clip: true
//                                     visible: centralCore.disconnectFill > 0

//                                     ColumnLayout {
//                                         spacing: window.s(4)
//                                         x: waveClipItem.width / 2 - width / 2
//                                         y: (centralCore.height / 2) - (height / 2) - (centralCore.height - waveClipItem.height)

//                                         Text {
//                                             Layout.alignment: Qt.AlignHCenter
//                                             font.family: "Iosevka Nerd Font"
//                                             font.pixelSize: window.s(48) - (window.s(16) * coreContainer.multiShift)
//                                             color: window.text
//                                             text: isMyDisconnecting ? "" : (coreMa.containsMouse ? (window.activeMode === "wifi" ? "󰖪" : (window.activeMode === "eth" ? "󰈂" : "󰂲")) : (coreContainer.myDevice ? (coreContainer.myDevice.icon || (window.activeMode === "wifi" ? "󰤨" : (window.activeMode === "eth" ? "󰈀" : "󰂯"))) : ""))
//                                         }
//                                         LoadingDots { Layout.alignment: Qt.AlignHCenter; visible: isMyDisconnecting; dotCol: window.text }
//                                         Text {
//                                             Layout.alignment: Qt.AlignHCenter
//                                             Layout.maximumWidth: window.s(150) - (window.s(50) * coreContainer.multiShift)
//                                             horizontalAlignment: Text.AlignHCenter
//                                             font.family: "JetBrains Mono"; font.weight: Font.Black
//                                             font.pixelSize: window.s(16) - (window.s(4) * coreContainer.multiShift)
//                                             color: window.text
//                                             text: coreContainer.myDevice ? (window.activeMode === "wifi" ? coreContainer.myDevice.ssid : coreContainer.myDevice.name) : ""
//                                             elide: Text.ElideRight
//                                         }
//                                         Text {
//                                             Layout.alignment: Qt.AlignHCenter
//                                             font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(11)
//                                             color: window.text
//                                             text: isMyDisconnecting ? "Disconnecting..." : (centralCore.disconnectFill > 0.01 ? "Hold..." : "Connected")
//                                         }
//                                     }
//                                 }
//                             }

//                             MouseArea {
//                                 id: coreMa
//                                 anchors.fill: parent
//                                 hoverEnabled: true
//                                 cursorShape: window.currentConn && !isMyDisconnecting && !showPassword ? Qt.PointingHandCursor : Qt.ArrowCursor
                                
//                                 onPressed: {
//                                     if (window.currentConn && !isMyDisconnecting && !centralCore.disconnectTriggered && !showPassword) {
//                                         coreDrainAnim.stop();
//                                         coreFillAnim.start();
//                                     }
//                                 }
//                                 onReleased: {
//                                     if (!centralCore.disconnectTriggered && !isMyDisconnecting && !showPassword) {
//                                         coreFillAnim.stop();
//                                         coreDrainAnim.start();
//                                     }
//                                 }
//                             }

//                             NumberAnimation {
//                                 id: coreFillAnim
//                                 target: centralCore
//                                 property: "disconnectFill"
//                                 to: 1.0
//                                 duration: 700 * (1.0 - centralCore.disconnectFill) 
//                                 easing.type: Easing.InSine
//                                 onFinished: {
//                                     if (!coreMa.pressed) {
//                                         centralCore.disconnectFill = 0.0;
//                                         return;
//                                     }

//                                     centralCore.disconnectTriggered = true;
//                                     centralCore.flashOpacity = 0.6;
//                                     cardFlashAnim.start();
//                                     coreBumpAnim.start();
                                    
//                                     window.playSfx("disconnect.wav");
                                    
//                                     let dd = window.disconnectingDevices;
//                                     dd[coreContainer.myId] = true;
//                                     window.disconnectingDevices = Object.assign({}, dd);
//                                     busyTimeout.restart();
                                    
//                                     let cmd = "";
//                                     if (window.activeMode === "eth") cmd = "nmcli device disconnect '" + coreContainer.myId + "'";
//                                     else if (window.activeMode === "wifi") cmd = "nmcli device disconnect $(nmcli -t -f DEVICE,TYPE d | grep wifi | cut -d: -f1 | head -n1)";
//                                     else cmd = "bash " + window.scriptsDir + "/bluetooth_panel_logic.sh --disconnect '" + coreContainer.myId + "'";
//                                     Quickshell.execDetached(["sh", "-c", cmd])
                                    
//                                     centralCore.disconnectFill = 0.0;
//                                     centralCore.disconnectTriggered = false;
                                    
//                                     if (window.activeMode === "eth") ethPoller.running = true;
//                                     else if (window.activeMode === "wifi") wifiPoller.running = true; 
//                                     else btPoller.running = true;
//                                 }
//                             }
                            
//                             NumberAnimation {
//                                 id: coreDrainAnim
//                                 target: centralCore
//                                 property: "disconnectFill"
//                                 to: 0.0
//                                 duration: 1000 * centralCore.disconnectFill 
//                                 easing.type: Easing.OutQuad
//                             }
//                         }
//                     }
//                 }

//                 Item {
//                     anchors.fill: parent
//                     opacity: window.currentPower ? 1.0 : 0.0
//                     visible: opacity > 0.01
//                     Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutQuad } }

//                     Repeater {
//                         id: orbitRepeater
//                         model: (window.currentConn && window.showInfoView) ? infoListModel : (window.activeMode === "wifi" ? wifiListModel : (window.activeMode === "bt" ? btListModel : null))
                        
//                         delegate: Item {
//                             id: floatCardDelegateContainer
//                             width: window.s(170); height: window.s(60)

//                             property bool isLoaded: false
//                             opacity: isLoaded ? 1.0 : 0.0
//                             visible: opacity > 0.01
//                             Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

//                             property real entryAnim: isLoaded ? 1.0 : 0.0
//                             Behavior on entryAnim { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }

//                             Timer {
//                                 running: true
//                                 interval: window.activeMode === "eth" ? (600 + (index * 80)) : (40 + (index * 30)) 
//                                 onTriggered: floatCardDelegateContainer.isLoaded = true
//                             }

//                             property int myParentIdx: model.parentIndex !== undefined ? model.parentIndex : -1
                            
//                             property int siblingsCount: {
//                                 let c = 0;
//                                 let m = orbitRepeater.model;
//                                 if (m && m.count !== undefined) {
//                                     for (let i = 0; i < m.count; i++) {
//                                         let d = m.get(i);
//                                         if (d && (d.parentIndex !== undefined ? d.parentIndex : -1) === myParentIdx) c++;
//                                     }
//                                 }
//                                 return Math.max(1, c);
//                             }
//                             property int localIndex: {
//                                 let idx = 0;
//                                 let m = orbitRepeater.model;
//                                 if (m && m.count !== undefined) {
//                                     for (let i = 0; i < index; i++) {
//                                         let d = m.get(i);
//                                         if (d && (d.parentIndex !== undefined ? d.parentIndex : -1) === myParentIdx) idx++;
//                                     }
//                                 }
//                                 return idx;
//                             }

//                             property real unifiedRatio: window.activeMode === "wifi" || window.activeMode === "eth" ? 0.0 : window.multiTransitionState

//                             property real activeCount: (unifiedRatio > 0.5 && myParentIdx !== -1) ? siblingsCount : orbitRepeater.count
//                             property real dynamicScale: activeCount > 10 ? Math.max(0.6, 12.0 / activeCount) : (unifiedRatio > 0.5 ? (window.activeCoreCount > 2 ? 0.7 : 0.8) : 1.0)
                            
//                             property real safeMultiShift: window.activeMode === "wifi" || window.activeMode === "eth" ? 0.0 : window.multiTransitionState
//                             property var pItem: myParentIdx !== -1 ? coreRepeater.itemAt(myParentIdx) : null
                            
//                             property real parentX: pItem ? (orbitContainer.width / 2) + (Math.cos(parentCoreAngle) * pItem.myOrbitRadiusX * safeMultiShift * pItem.activeTransition) : (orbitContainer.width / 2)
//                             property real parentY: pItem ? (orbitContainer.height / 2) + (Math.sin(parentCoreAngle) * pItem.myOrbitRadiusY * safeMultiShift * pItem.activeTransition) : (orbitContainer.height / 2)

//                             property real parentBaseAngle: pItem ? pItem.animatedBaseAngle : 0
                            
//                             property real targetSingleBaseAngle: (index / Math.max(1, orbitRepeater.count)) * Math.PI * 2
//                             property real singleBaseAngle: targetSingleBaseAngle
//                             Behavior on singleBaseAngle { NumberAnimation { duration: 800; easing.type: Easing.OutExpo } }

//                             property real singleLiveAngle: (window.globalOrbitAngle * 1.5) + singleBaseAngle
                            
//                             property real arcSpread: Math.PI * 0.8 
//                             property real targetNodeOffset: (siblingsCount > 1) ? ((localIndex / (siblingsCount - 1)) - 0.5) * arcSpread : 0
//                             property real nodeOffset: targetNodeOffset
//                             Behavior on nodeOffset { NumberAnimation { duration: 800; easing.type: Easing.OutExpo } }

//                             property real parentCoreAngle: (window.globalOrbitAngle * 1.5) + parentBaseAngle
//                             property real multiLiveAngle: myParentIdx === -1 ? singleLiveAngle : (parentCoreAngle + nodeOffset)

//                             property int ringIndex: isInfoNode ? 0 : index % 2
//                             property real targetRingOffset: ringIndex * window.s(40)
//                             property real ringOffset: targetRingOffset
//                             Behavior on ringOffset { NumberAnimation { duration: 800; easing.type: Easing.OutExpo } }

//                             property real singleRadX: isInfoNode ? window.s(280) : window.s(320) + ringOffset
//                             property real singleRadY: isInfoNode ? window.s(180) : window.s(200) + ringOffset
                            
//                             property real multiRadX: isInfoNode ? (myParentIdx === -1 ? 0 : (window.activeCoreCount > 2 ? window.s(180) : window.s(160))) : window.s(340) + ringOffset
//                             property real multiRadY: isInfoNode ? (myParentIdx === -1 ? 0 : (window.activeCoreCount > 2 ? window.s(180) : window.s(160))) : window.s(240) + ringOffset

//                             property real currentRadX: window.activeMode === "eth" ? window.s(280) : ((singleRadX * (1 - unifiedRatio)) + (multiRadX * unifiedRatio))
//                             property real currentRadY: window.activeMode === "eth" ? window.s(180) : ((singleRadY * (1 - unifiedRatio)) + (multiRadY * unifiedRatio))
//                             property real currentAngle: (singleLiveAngle * (1 - unifiedRatio)) + (multiLiveAngle * unifiedRatio)
                            
//                             property real pwrDrift: window.currentPower ? 0 : window.s(40)
//                             Behavior on pwrDrift { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

//                             property real animRadX: (currentRadX + pwrDrift) * (0.25 + 0.75 * entryAnim)
//                             property real animRadY: (currentRadY + pwrDrift) * (0.25 + 0.75 * entryAnim)

//                             property real targetX: myParentIdx === -1 
//                                 ? (orbitContainer.width / 2) - (width / 2) + Math.cos(currentAngle) * animRadX
//                                 : parentX - (width / 2) + Math.cos(currentAngle) * animRadX
                                
//                             property real targetY: myParentIdx === -1 
//                                 ? (orbitContainer.height / 2) - (height / 2) + Math.sin(currentAngle) * animRadY
//                                 : parentY - (height / 2) + Math.sin(currentAngle) * animRadY

//                             property real liveBob: myParentIdx === -1 && isInfoNode 
//                                 ? Math.sin(window.globalOrbitAngle * 6) * window.s(12) * (1 - unifiedRatio) 
//                                 : 0

//                             x: targetX
//                             y: targetY + liveBob

//                             scale: (!isLoaded ? 0.0 : (floatMa.pressed ? dynamicScale * 0.95 : (floatCard.locksList ? dynamicScale * 1.08 : dynamicScale))) * floatCard.bumpScale
//                             Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
//                             z: floatCard.locksList ? 10 : index

//                             MultiEffect {
//                                 source: floatCard
//                                 anchors.fill: floatCard
//                                 shadowEnabled: window.currentPower && floatCardDelegateContainer.opacity > 0.05
//                                 shadowColor: "#000000"
//                                 shadowOpacity: 0.3
//                                 shadowBlur: 0.8
//                                 shadowVerticalOffset: window.s(4)
//                                 z: -1
//                             }

//                             Rectangle {
//                                 id: floatCard
//                                 anchors.fill: parent
//                                 radius: window.s(14)
                                
//                                 property string itemId: id
//                                 property string itemName: name
                                
//                                 property bool isMyBusy: window.connectingId === itemId || !!window.busyTasks[itemId]
//                                 property bool isFailed: window.failedId === itemId
                                
//                                 property bool isPairedBT: window.activeMode === "bt" && action === "Connect"
//                                 property bool isTargetWifi: window.activeMode === "wifi" && !window.isWifiConn && itemId === window.targetWifiSsid
//                                 property bool isSpecialAction: itemId === "action_scan" || itemId === "action_settings"
//                                 property bool isHighlighted: isPairedBT || isTargetWifi || isSpecialAction
                                
//                                 property bool isCurrentlyConnected: {
//                                     if (window.activeMode === "eth") return (window.ethConnected && window.ethConnected.id === itemId);
//                                     if (window.activeMode === "wifi") return (window.wifiConnected && window.wifiConnected.ssid === itemId);
//                                     for (let i = 0; i < window.btConnected.length; i++) {
//                                         if (window.btConnected[i].mac === itemId) return true;
//                                     }
//                                     return false;
//                                 }
                                
//                                 property bool isInteractable: !isInfoNode || isActionable
//                                 property bool locksList: isInteractable && (floatMa.containsMouse || floatMa.pressed)
//                                 onLocksListChanged: { if (locksList) window.hoveredCardCount++; else window.hoveredCardCount--; }
//                                 Component.onDestruction: { if (locksList) window.hoveredCardCount--; }
                                
//                                 property real bumpScale: 1.0
//                                 SequentialAnimation on bumpScale {
//                                     id: cardBumpAnim
//                                     running: false
//                                     NumberAnimation { to: 1.2; duration: 200; easing.type: Easing.OutBack }
//                                     NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.OutQuint }
//                                 }

//                                 property real nameImplicitWidth: baseNameText.implicitWidth
//                                 property real nameContainerWidth: nameContainerBase.width
//                                 property bool doMarquee: floatMa.containsMouse && nameImplicitWidth > nameContainerWidth
//                                 property real textOffset: 0

//                                 SequentialAnimation on textOffset {
//                                     running: floatCard.doMarquee
//                                     loops: Animation.Infinite
//                                     PauseAnimation { duration: 600 } 
//                                     NumberAnimation {
//                                         from: 0
//                                         to: -(floatCard.nameImplicitWidth + window.s(30))
//                                         duration: (floatCard.nameImplicitWidth + window.s(30)) * 35
//                                     }
//                                 }
//                                 onDoMarqueeChanged: if (!doMarquee) textOffset = 0;

//                                 property real fillLevel: 0.0
//                                 property bool triggered: false
//                                 property real flashOpacity: 0.0
                                
//                                 property real renderFill: (isCurrentlyConnected) ? 1.0 : fillLevel
                                
//                                 onIsFailedChanged: {
//                                     if (isFailed) {
//                                         triggered = false;
//                                         drainAnim.start();
//                                     }
//                                 }

//                                 Connections {
//                                     target: window
//                                     function onPendingWifiIdChanged() {
//                                         if (window.pendingWifiId === "" && floatCard.fillLevel > 0 && !floatCard.isMyBusy && !floatCard.isCurrentlyConnected) {
//                                             floatCard.triggered = false;
//                                             drainAnim.start();
//                                         }
//                                     }
//                                 }

//                                 color: locksList ? "#2affffff" : "#0effffff"
//                                 Behavior on color { ColorAnimation { duration: 200 } }
                                
//                                 Rectangle {
//                                     anchors.fill: parent
//                                     radius: parent.radius
//                                     color: window.red
//                                     opacity: floatCard.isFailed ? 0.3 : 0.0
//                                     Behavior on opacity { NumberAnimation { duration: 300 } }
//                                 }

//                                 Rectangle {
//                                     anchors.fill: parent
//                                     radius: window.s(14)
//                                     color: "transparent"
//                                     border.width: 1
//                                     border.color: floatCard.isFailed ? window.red : window.surface2
//                                     visible: !isHighlighted && !locksList
//                                     Behavior on border.color { ColorAnimation { duration: 300 } }
//                                 }

//                                 Rectangle {
//                                     anchors.fill: parent
//                                     radius: window.s(14)
//                                     opacity: locksList || isHighlighted ? 1.0 : 0.0
//                                     color: "transparent"
//                                     border.width: isHighlighted && !locksList ? 1 : window.s(2)
//                                     border.color: floatCard.isFailed ? window.red : "transparent"
//                                     Behavior on opacity { NumberAnimation { duration: 250 } }
                                    
//                                     Rectangle {
//                                         anchors.fill: parent
//                                         anchors.margins: isHighlighted && !locksList ? 1 : window.s(2)
//                                         radius: window.s(12)
//                                         color: window.base
//                                         opacity: locksList ? 0.9 : 1.0
//                                     }
                                    
//                                     gradient: Gradient {
//                                         orientation: Gradient.Horizontal
//                                         GradientStop { position: 0.0; color: floatCard.isFailed ? Qt.lighter(window.red, 1.15) : Qt.lighter(window.activeColor, 1.15) }
//                                         GradientStop { position: 1.0; color: floatCard.isFailed ? window.red : window.activeColor }
//                                     }
//                                     z: -1
//                                 }

//                                 Rectangle {
//                                     anchors.fill: parent
//                                     radius: window.s(14)
//                                     color: "#ffffff"
//                                     opacity: floatCard.flashOpacity
//                                     PropertyAnimation on opacity { id: cardFlashAnim; to: 0; duration: 500; easing.type: Easing.OutExpo }
//                                     z: 5
//                                 }

//                                 Canvas {
//                                     id: waveCanvas
//                                     anchors.fill: parent
                                    
//                                     property real scaleTrigger: window.s(1)
//                                     onScaleTriggerChanged: requestPaint()

//                                     property real wavePhase: 0.0
                                    
//                                     NumberAnimation on wavePhase {
//                                         running: floatCard.renderFill > 0.0 && floatCard.renderFill < 1.0
//                                         loops: Animation.Infinite
//                                         from: 0; to: Math.PI * 2
//                                         duration: 800
//                                     }

//                                     onWavePhaseChanged: requestPaint()
//                                     Connections { target: floatCard; function onRenderFillChanged() { waveCanvas.requestPaint() } }

//                                     onPaint: {
//                                         var ctx = getContext("2d");
//                                         var s = window.s;
//                                         ctx.clearRect(0, 0, width, height);
//                                         if (floatCard.renderFill <= 0.001) return;

//                                         var currentW = width * floatCard.renderFill;
//                                         var r = s(14); 

//                                         ctx.save();
//                                         ctx.beginPath();
//                                         ctx.moveTo(0, 0);
                                        
//                                         if (floatCard.renderFill < 0.99) {
//                                             var waveAmp = s(12) * Math.sin(floatCard.renderFill * Math.PI); 
//                                             if (currentW - waveAmp < 0) waveAmp = currentW;
//                                             var cp1x = currentW + Math.sin(wavePhase) * waveAmp;
//                                             var cp2x = currentW + Math.cos(wavePhase + Math.PI) * waveAmp;

//                                             ctx.lineTo(currentW, 0);
//                                             ctx.bezierCurveTo(cp2x, height * 0.33, cp1x, height * 0.66, currentW, height);
//                                             ctx.lineTo(0, height);
//                                         } else {
//                                             ctx.lineTo(width, 0);
//                                             ctx.lineTo(width, height);
//                                             ctx.lineTo(0, height);
//                                         }
//                                         ctx.closePath();
//                                         ctx.clip(); 

//                                         ctx.beginPath();
//                                         ctx.moveTo(r, 0);
//                                         ctx.lineTo(width - r, 0);
//                                         ctx.arcTo(width, 0, width, r, r);
//                                         ctx.lineTo(width, height - r);
//                                         ctx.arcTo(width, height, width - r, height, r);
//                                         ctx.lineTo(r, height);
//                                         ctx.arcTo(0, height, 0, height - r, r);
//                                         ctx.lineTo(0, r);
//                                         ctx.arcTo(0, 0, r, 0, r);
//                                         ctx.closePath();

//                                         var grad = ctx.createLinearGradient(0, 0, currentW, 0);
//                                         grad.addColorStop(0, Qt.lighter(window.activeColor, 1.15).toString());
//                                         grad.addColorStop(1, window.activeColor.toString());
//                                         ctx.fillStyle = grad;
//                                         ctx.fill();

//                                         ctx.restore();
//                                     }
//                                 }

//                                 Rectangle {
//                                     anchors.fill: parent
//                                     radius: parent.radius
//                                     color: "transparent"
//                                     border.color: window.activeColor
//                                     border.width: window.s(2)
//                                     visible: parent.isHighlighted && !parent.isMyBusy && !parent.isCurrentlyConnected && !parent.isFailed
                                    
//                                     SequentialAnimation on scale {
//                                         loops: Animation.Infinite; running: parent.visible
//                                         NumberAnimation { to: 1.15; duration: 1200; easing.type: Easing.InOutSine }
//                                         NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
//                                     }
//                                     SequentialAnimation on opacity {
//                                         loops: Animation.Infinite; running: parent.visible
//                                         NumberAnimation { to: 0.0; duration: 1200; easing.type: Easing.InOutSine }
//                                         NumberAnimation { to: 0.8; duration: 1200; easing.type: Easing.InOutSine }
//                                     }
//                                 }

//                                 RowLayout {
//                                     id: baseTextRow
//                                     anchors.fill: parent
//                                     anchors.margins: window.s(12)
//                                     spacing: window.s(10)
                                    
//                                     Text {
//                                         font.family: "Iosevka Nerd Font"
//                                         font.pixelSize: window.s(20)
//                                         color: floatCard.isFailed ? window.red : (floatCard.isMyBusy ? window.text : window.activeColor)
//                                         text: icon
//                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                     }
                                    
//                                     ColumnLayout {
//                                         Layout.fillWidth: true
//                                         spacing: window.s(2)
                                        
//                                         Item {
//                                             id: nameContainerBase
//                                             Layout.fillWidth: true
//                                             height: window.s(18)
//                                             clip: true

//                                             Text {
//                                                 id: baseNameText
//                                                 anchors.left: parent.left
//                                                 anchors.leftMargin: floatCard.textOffset
//                                                 anchors.verticalCenter: parent.verticalCenter
//                                                 text: floatCard.itemName
//                                                 font.family: "JetBrains Mono"
//                                                 font.weight: Font.Bold
//                                                 font.pixelSize: window.s(13)
//                                                 color: floatCard.isFailed ? window.red : (floatCard.isHighlighted ? window.activeColor : window.text)
//                                                 Behavior on color { ColorAnimation { duration: 200 } }
//                                             }
//                                             Text {
//                                                 anchors.left: baseNameText.right
//                                                 anchors.leftMargin: window.s(30)
//                                                 anchors.verticalCenter: parent.verticalCenter
//                                                 visible: floatCard.doMarquee
//                                                 text: floatCard.itemName
//                                                 font.family: "JetBrains Mono"
//                                                 font.weight: Font.Bold
//                                                 font.pixelSize: window.s(13)
//                                                 color: floatCard.isFailed ? window.red : (floatCard.isHighlighted ? window.activeColor : window.text)
//                                             }
//                                         }
                                        
//                                         Text {
//                                             font.family: "JetBrains Mono"
//                                             font.pixelSize: window.s(10)
//                                             color: floatCard.isFailed ? window.maroon : (floatCard.isMyBusy ? window.activeColor : window.overlay0)
//                                             text: floatCard.isFailed ? "Connection Failed" : (floatCard.isMyBusy ? "Connecting..." : (floatCard.renderFill > 0.1 && floatCard.renderFill < 1.0 ? "Hold..." : action))
//                                             Behavior on color { ColorAnimation { duration: 200 } }
//                                         }
//                                     }
//                                 }

//                                 Item {
//                                     anchors.left: parent.left
//                                     anchors.top: parent.top
//                                     anchors.bottom: parent.bottom
//                                     width: floatCard.width * floatCard.renderFill
//                                     clip: true
                                    
//                                     RowLayout {
//                                         x: baseTextRow.x; y: baseTextRow.y
//                                         width: baseTextRow.width; height: baseTextRow.height
//                                         spacing: window.s(10)
                                        
//                                         Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(20); color: window.crust; text: icon }
                                        
//                                         ColumnLayout {
//                                             Layout.fillWidth: true
//                                             spacing: window.s(2)

//                                             Item {
//                                                 Layout.fillWidth: true
//                                                 height: window.s(18)
//                                                 clip: true
                                                
//                                                 Text {
//                                                     id: filledNameText
//                                                     anchors.left: parent.left
//                                                     anchors.leftMargin: floatCard.textOffset
//                                                     anchors.verticalCenter: parent.verticalCenter
//                                                     text: floatCard.itemName
//                                                     font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(13); color: window.crust 
//                                                 }
//                                                 Text { 
//                                                     anchors.left: filledNameText.right
//                                                     anchors.leftMargin: window.s(30)
//                                                     anchors.verticalCenter: parent.verticalCenter
//                                                     visible: floatCard.doMarquee
//                                                     text: floatCard.itemName
//                                                     font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(13); color: window.crust 
//                                                 }
//                                             }
//                                             Text {
//                                                 font.family: "JetBrains Mono"; font.pixelSize: window.s(10); color: window.crust
//                                                 text: floatCard.isMyBusy ? "Connecting..." : (floatCard.renderFill > 0.1 && floatCard.renderFill < 1.0 ? "Hold..." : action)
//                                             }
//                                         }
//                                     }
//                                 }

//                                 MouseArea {
//                                     id: floatMa
//                                     anchors.fill: parent
//                                     hoverEnabled: floatCard.isInteractable
                                    
//                                     cursorShape: (floatCard.triggered || floatCard.isMyBusy || floatCard.renderFill === 1.0 || !floatCard.isInteractable) ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    
//                                     onPressed: { 
//                                         if (floatCard.isInteractable && !floatCard.triggered && !floatCard.isMyBusy && floatCard.fillLevel === 0.0) {
//                                             if (window.pendingWifiId !== "") {
//                                                 window.pendingWifiId = ""; window.pendingWifiSsid = "";
//                                             }
//                                             drainAnim.stop()
//                                             fillAnim.start()
//                                         }
//                                     }
//                                     onReleased: {
//                                         if (floatCard.isInteractable && !floatCard.triggered && !floatCard.isMyBusy && floatCard.fillLevel < 1.0) {
//                                             fillAnim.stop()
//                                             drainAnim.start()
//                                         }
//                                     }
//                                 }

//                                 NumberAnimation {
//                                     id: fillAnim
//                                     target: floatCard
//                                     property: "fillLevel"
//                                     to: 1.0
//                                     duration: 600 * (1.0 - floatCard.fillLevel) 
//                                     easing.type: Easing.InSine
//                                     onFinished: {
//                                         floatCard.triggered = true;
//                                         floatCard.flashOpacity = 0.6;
//                                         cardFlashAnim.start();
//                                         cardBumpAnim.start();
                                        
//                                         if (cmdStr === "TOGGLE_VIEW") {
//                                             window.playSfx("switch.wav");
//                                             window.showInfoView = !window.showInfoView;
//                                             floatCard.triggered = false;
//                                             drainAnim.start();
//                                         } else if (isInfoNode && cmdStr) {
//                                             Quickshell.execDetached(["sh", "-c", cmdStr]);
//                                             if (window.activeMode === "bt") btPoller.running = true;
//                                             floatCard.triggered = false;
//                                             drainAnim.start(); 
//                                         } else {
//                                             let sec = typeof security !== "undefined" && security ? security.trim().toLowerCase() : "";
//                                             let isSecure = sec !== "" && sec !== "open" && sec !== "--" && sec !== "none";
//                                             let isSaved = false;
//                                             for (let i = 0; i < window.savedWifiNetworks.length; i++) {
//                                                 if (window.savedWifiNetworks[i] === ssid) { isSaved = true; break; }
//                                             }

//                                             if (window.activeMode === "wifi" && isSecure && !isSaved) {
//                                                 window.pendingWifiSsid = ssid;
//                                                 window.pendingWifiId = floatCard.itemId;
//                                             } else {
//                                                 window.connectDevice(window.activeMode, floatCard.itemId, window.activeMode === "wifi" ? ssid : (window.activeMode === "eth" ? floatCard.itemId : mac), "");
//                                             }
//                                         }
//                                     }
//                                 }
                                
//                                 NumberAnimation {
//                                     id: drainAnim
//                                     target: floatCard
//                                     property: "fillLevel"
//                                     to: 0.0
//                                     duration: 1500 * floatCard.fillLevel 
//                                     easing.type: Easing.OutQuad
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }

//             Rectangle {
//                 id: bottomTabsContainer
//                 anchors.bottom: parent.bottom
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 anchors.bottomMargin: window.s(25)
//                 width: window.s(360)
//                 height: window.s(54)
//                 radius: window.s(14)
//                 color: "#1affffff" 
//                 border.color: "#1affffff"
//                 border.width: 1
//                 visible: window.ethPresent || window.wifiPresent || window.btPresent

//                 // The Morphing Highlight Pill
//                 Rectangle {
//                     id: activeTabHighlight
//                     y: window.s(6)
//                     height: bottomTabsContainer.height - window.s(12)
//                     radius: window.s(10)
//                     z: 0

//                     property int prevIdx: 1
//                     property int curIdx: window.activeMode === "eth" ? 0 : (window.activeMode === "wifi" ? 1 : 2)

//                     onCurIdxChanged: {
//                         if (curIdx > prevIdx) { rightAnim.duration = 200; leftAnim.duration = 350; }
//                         else if (curIdx < prevIdx) { leftAnim.duration = 200; rightAnim.duration = 350; }
//                         prevIdx = curIdx;
//                     }

//                     property Item activeItem: {
//                         if (window.activeMode === "eth" && window.ethPresent) return ethTabRect;
//                         if (window.activeMode === "wifi" && window.wifiPresent) return wifiTabRect;
//                         if (window.activeMode === "bt" && window.btPresent) return btTabRect;
//                         return null;
//                     }

//                     property real targetLeft: activeItem ? activeItem.x : 0
//                     property real targetRight: activeItem ? (activeItem.x + activeItem.width) : 0

//                     property real actualLeft: targetLeft
//                     property real actualRight: targetRight

//                     Behavior on actualLeft { NumberAnimation { id: leftAnim; duration: 250; easing.type: Easing.OutExpo } }
//                     Behavior on actualRight { NumberAnimation { id: rightAnim; duration: 250; easing.type: Easing.OutExpo } }

//                     x: window.s(6) + actualLeft
//                     width: Math.max(0, actualRight - actualLeft)
//                     opacity: activeItem ? 1.0 : 0.0
//                     Behavior on opacity { NumberAnimation { duration: 300 } }

//                     gradient: Gradient {
//                         orientation: Gradient.Horizontal
//                         GradientStop { position: 0.0; color: Qt.lighter(window.activeColor, 1.15) }
//                         GradientStop { position: 1.0; color: window.activeColor }
//                     }
//                 }

//                 RowLayout {
//                     id: tabsLayout
//                     anchors.fill: parent
//                     anchors.margins: window.s(6)
//                     spacing: window.s(6)

//                     Rectangle {
//                         id: ethTabRect
//                         Layout.fillWidth: true
//                         Layout.fillHeight: true
//                         visible: window.ethPresent
//                         radius: window.s(10)
//                         color: window.activeMode === "eth" ? "transparent" : (ethTabMa.containsMouse ? window.surface1 : "transparent")
//                         Behavior on color { ColorAnimation { duration: 200 } }

//                         RowLayout {
//                             anchors.centerIn: parent
//                             spacing: window.s(8)
//                             Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18); color: window.activeMode === "eth" ? window.crust : window.text; text: "󰈀"; Behavior on color { ColorAnimation{duration:200} } }
//                             Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(13); color: window.activeMode === "eth" ? window.crust : window.text; text: "Ethernet"; Behavior on color { ColorAnimation{duration:200} } }
//                         }
//                         MouseArea {
//                             id: ethTabMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                             onClicked: {
//                                 if (window.pendingWifiId !== "") { window.pendingWifiId = ""; window.pendingWifiSsid = ""; }
//                                 if (window.activeMode !== "eth") {
//                                     window.powerAnimAllowed = false;
//                                     powerAnimBlocker.restart();
//                                     window.playSfx("switch.wav");
//                                     window.activeMode = "eth";
//                                 }
//                             }
//                         }
//                     }

//                     Rectangle { visible: window.ethPresent && (window.wifiPresent || window.btPresent); width: 1; Layout.fillHeight: true; Layout.margins: window.s(5); color: "#33ffffff" }

//                     Rectangle {
//                         id: wifiTabRect
//                         Layout.fillWidth: true
//                         Layout.fillHeight: true
//                         visible: window.wifiPresent
//                         radius: window.s(10)
                        
//                         color: window.activeMode === "wifi" ? "transparent" : (wifiTabMa.containsMouse ? window.surface1 : "transparent")
//                         Behavior on color { ColorAnimation { duration: 200 } }

//                         RowLayout {
//                             anchors.centerIn: parent
//                             spacing: window.s(8)
//                             Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18); color: window.activeMode === "wifi" ? window.crust : window.text; text: "󰤨"; Behavior on color { ColorAnimation{duration:200} } }
//                             Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(13); color: window.activeMode === "wifi" ? window.crust : window.text; text: "Wi-Fi"; Behavior on color { ColorAnimation{duration:200} } }
//                         }
//                         MouseArea {
//                             id: wifiTabMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                             onClicked: {
//                                 if (window.pendingWifiId !== "") { window.pendingWifiId = ""; window.pendingWifiSsid = ""; }
//                                 if (window.activeMode !== "wifi") {
//                                     window.powerAnimAllowed = false;
//                                     powerAnimBlocker.restart();
//                                     window.playSfx("switch.wav");
//                                     window.activeMode = "wifi";
//                                 }
//                             }
//                         }
//                     }

//                     Rectangle { visible: window.wifiPresent && window.btPresent; width: 1; Layout.fillHeight: true; Layout.margins: window.s(5); color: "#33ffffff" }

//                     Rectangle {
//                         id: btTabRect
//                         Layout.fillWidth: true
//                         Layout.fillHeight: true
//                         visible: window.btPresent
//                         radius: window.s(10)
//                         color: window.activeMode === "bt" ? "transparent" : (btTabMa.containsMouse ? window.surface1 : "transparent")
//                         Behavior on color { ColorAnimation { duration: 200 } }

//                         RowLayout {
//                             anchors.centerIn: parent
//                             spacing: window.s(8)
//                             Text { font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18); color: window.activeMode === "bt" ? window.crust : window.text; text: "󰂯"; Behavior on color { ColorAnimation{duration:200} } }
//                             Text { font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: window.s(13); color: window.activeMode === "bt" ? window.crust : window.text; text: "Bluetooth"; Behavior on color { ColorAnimation{duration:200} } }
//                         }
//                         MouseArea {
//                             id: btTabMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                             onClicked: {
//                                 if (window.pendingWifiId !== "") { window.pendingWifiId = ""; window.pendingWifiSsid = ""; }
//                                 if (window.activeMode !== "bt") {
//                                     window.powerAnimAllowed = false;
//                                     powerAnimBlocker.restart();
//                                     window.playSfx("switch.wav");
//                                     window.activeMode = "bt";
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }

//             Item {
//                 id: powerToggleContainer
//                 z: 100

//                 // FIXED: Replaced direct Behavior on x/y with an interpolation value.
//                 // This completely removes lag and overshooting when the parent window resizes/morphs.
//                 property real pwrMorph: window.currentPower ? 1.0 : 0.0
//                 Behavior on pwrMorph {
//                     enabled: window.powerAnimAllowed;
//                     NumberAnimation { duration: 800; easing.type: Easing.InOutQuint }
//                 }

//                 width: window.s(160) + (window.s(48) - window.s(160)) * pwrMorph
//                 height: width

//                 x: {
//                     let startX = (parent.width / 2) - window.s(80);
//                     let endX = parent.width - window.s(30) - window.s(48);
//                     return startX + (endX - startX) * pwrMorph;
//                 }
                
//                 y: {
//                     let startY = (parent.height - window.s(80)) / 2 - window.s(80);
//                     let endY = parent.height - window.s(30) - window.s(48);
//                     return startY + (endY - startY) * pwrMorph;
//                 }

//                 MultiEffect {
//                     source: powerBtnRect
//                     anchors.fill: powerBtnRect
//                     shadowEnabled: true
//                     shadowColor: "#000000"
//                     shadowOpacity: 0.4
//                     shadowBlur: 1.2
//                     shadowVerticalOffset: window.s(4)
//                 }

//                 Rectangle {
//                     id: powerBtnRect
//                     anchors.fill: parent
//                     radius: width / 2
                    
//                     scale: pwrMa.pressed ? 0.95 : (pwrMa.containsMouse ? 1.05 : 1.0)
//                     Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

//                     gradient: Gradient {
//                         orientation: Gradient.Vertical
//                         GradientStop { position: 0.0; color: window.currentPower ? "transparent" : window.surface1 }
//                         GradientStop { position: 1.0; color: window.currentPower ? "transparent" : window.crust }
//                     }

//                     border.color: window.currentPowerPending ? window.activeColor : (window.currentPower ? "transparent" : window.surface2)
//                     border.width: window.s(2)
//                     Behavior on border.color { enabled: window.powerAnimAllowed; ColorAnimation { duration: 800; easing.type: Easing.InOutQuint } }

//                     Rectangle {
//                         anchors.fill: parent
//                         radius: parent.radius
//                         opacity: window.currentPower ? 1.0 : 0.0
//                         Behavior on opacity { enabled: window.powerAnimAllowed; NumberAnimation { duration: 800; easing.type: Easing.InOutQuint } }
//                         gradient: Gradient {
//                             orientation: Gradient.Horizontal
//                             GradientStop { position: 0.0; color: Qt.lighter(window.activeColor, 1.15) }
//                             GradientStop { position: 1.0; color: window.activeColor }
//                         }
//                     }

//                     Text {
//                         id: pwrIcon
//                         anchors.centerIn: parent
//                         font.family: "Iosevka Nerd Font"
//                         font.pixelSize: window.currentPower ? window.s(22) : window.s(64)
//                         color: window.currentPower ? window.crust : window.text
//                         text: window.currentPowerPending ? "󰑮" : ""
//                         Behavior on font.pixelSize { enabled: window.powerAnimAllowed; NumberAnimation { duration: 800; easing.type: Easing.InOutQuint } }
//                         Behavior on color { enabled: window.powerAnimAllowed; ColorAnimation { duration: 800; easing.type: Easing.InOutQuint } }

//                         RotationAnimation {
//                             target: pwrIcon
//                             property: "rotation"
//                             from: 0; to: 360
//                             duration: 800
//                             loops: Animation.Infinite
//                             running: window.currentPowerPending
//                             onRunningChanged: {
//                                 if (!running) pwrIcon.rotation = 0;
//                             }
//                         }
//                     }

//                     MouseArea {
//                         id: pwrMa
//                         anchors.fill: parent
//                         hoverEnabled: true
//                         cursorShape: Qt.PointingHandCursor
//                         onClicked: {
//                             if (window.pendingWifiId !== "") { window.pendingWifiId = ""; window.pendingWifiSsid = ""; }
                            
//                             if (window.activeMode === "eth") {
//                                 if (window.ethPowerPending) return;
//                                 window.expectedEthPower = window.ethPower === "on" ? "off" : "on";
//                                 window.ethPowerPending = true;
//                                 if (window.expectedEthPower === "on") window.playSfx("power_on.wav"); else window.playSfx("power_off.wav");
//                                 ethPendingReset.restart();
//                                 window.ethPower = window.expectedEthPower; 
//                                 let targetDev = window.ethDeviceName !== "" ? window.ethDeviceName : (window.currentCores[0] ? window.currentCores[0].id : "");
//                                 if (targetDev !== "") {
//                                     if (window.expectedEthPower === "on") Quickshell.execDetached(["nmcli", "device", "connect", targetDev]);
//                                     else Quickshell.execDetached(["nmcli", "device", "disconnect", targetDev]);
//                                 }
//                                 ethPoller.running = true;
//                             } else if (window.activeMode === "wifi") {
//                                 if (window.wifiPowerPending) return;
//                                 window.expectedWifiPower = window.wifiPower === "on" ? "off" : "on";
//                                 window.wifiPowerPending = true;
//                                 if (window.expectedWifiPower === "on") window.playSfx("power_on.wav"); else window.playSfx("power_off.wav");
//                                 wifiPendingReset.restart();
//                                 window.wifiPower = window.expectedWifiPower;
//                                 Quickshell.execDetached(["nmcli", "radio", "wifi", window.wifiPower]);
//                                 wifiPoller.running = true;
//                             } else {
//                                 if (window.btPowerPending) return;
//                                 window.expectedBtPower = window.btPower === "on" ? "off" : "on";
//                                 window.btPowerPending = true;
//                                 if (window.expectedBtPower === "on") window.playSfx("power_on.wav"); else window.playSfx("power_off.wav");
//                                 btPendingReset.restart();
//                                 window.btPower = window.expectedBtPower;
//                                 Quickshell.execDetached(["bash", window.scriptsDir + "/bluetooth_panel_logic.sh", "--toggle"]);
//                                 btPoller.running = true;
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }




// =============================================================================
// QUICKSHELL NETWORK WIDGET - UNIFIED NETWORK MANAGER UI
// =============================================================================
// Architecture Overview:
// This is a single-file QML component that implements a complete network
// management interface. It follows a reactive, state-driven architecture:
//
// DATA FLOW:
// 1. Shell scripts (poller processes) fetch system state via nmcli/bluetoothctl
// 2. JSON output is parsed into QML properties (ethPresent, wifiPower, etc.)
// 3. UI elements bind to these properties with animated transitions
// 4. User interactions trigger process execution (connect/disconnect/toggle)
// 5. Poller refresh confirms state changes
//
// STATE MANAGEMENT PATTERN:
// - "Optimistic UI": Power state updates immediately on click, confirmed later
// - "Pending State": ethPowerPending/wifiPowerPending/btPowerPending flags
//   prevent double-clicks and show loading spinners
// - "Expected State": expectedEthPower etc. track what we asked for
// - "Reality Check": Poller output either confirms or corrects optimistic state
//
// ANIMATION PHILOSOPHY:
// - Physics-based easing (Expo, Quint, Back) for natural feel
// - Continuous orbital motion via globalOrbitAngle (slow perpetual rotation)
// - Wave-based procedural animation (node lines, disconnect fill)
// - Multi-transition state machine for 1-device vs multi-device layouts
// =============================================================================

// -----------------------------------------------------------------------------
// MODULE IMPORTS - Each provides specific QML types and functionality
// -----------------------------------------------------------------------------

// QtQuick provides the foundational QML types: Item, Rectangle, Text, etc.
// Also includes the animation framework: NumberAnimation, SequentialAnimation, etc.
import QtQuick

// QtQuick.Layouts provides RowLayout, ColumnLayout, and Layout attached properties
// These are critical for responsive layouts that adapt to content size
import QtQuick.Layouts

// QtQuick.Effects provides MultiEffect - a hardware-accelerated effect system
// MultiEffect combines shadow, blur, colorize, and more into a single GPU pass
// More performant than layering multiple individual effects
import QtQuick.Effects

// QtQuick.Window exposes Screen.width/height for resolution-aware scaling
import QtQuick.Window

// QtCore provides Settings (persistent storage), QUrl, and other non-GUI utilities
import QtCore

// Quickshell is the desktop shell framework this widget runs inside
// It provides the windowing context and shell integration
import Quickshell

// Quickshell.Io provides Process (for running external commands), StdioCollector
// (for capturing output), and execDetached for fire-and-forget processes
import Quickshell.Io

// Import the parent directory to access sibling QML components
// This resolves Scaler.qml, MatugenColors.qml which are in the parent folder
import "../"

// =============================================================================
// ROOT ITEM - The entire widget is a single Item with window-level focus
// =============================================================================
Item {
    // The 'id' property creates a named reference accessible throughout the file
    // 'window' is chosen because this acts like a self-contained window
    id: window

    // focus: true ensures this item receives keyboard events
    // Required for the Tab key shortcut to work
    focus: true

    // =========================================================================
    // SCALER - Resolution-independent sizing system
    // =========================================================================
    // The Scaler component computes a scaling factor based on Screen.width
    // All visual sizes use window.s(value) to multiply by this factor
    // This ensures the UI looks consistent on 1080p, 1440p, 4K, etc.
    // The scaler typically maps a base design (e.g., 1920px) to actual screen width
    Scaler {
        id: scaler
        currentWidth: Screen.width  // Bind to actual screen width
    }

    // Convenience function: s(10) returns 10 * scalingFactor
    // Using a function instead of direct Scaler access reduces boilerplate
    // throughout the file: window.s(10) vs scaler.s(10)
    function s(val) { return scaler.s(val); }

    // =========================================================================
    // KEYBOARD SHORTCUT - Tab cycles through available network modes
    // =========================================================================
    Shortcut {
        sequence: "Tab"  // Bind to physical Tab key press
        onActivated: {
            // If a WiFi password dialog is showing, Tab dismisses it instead
            // This is a common UX pattern: Tab = cancel/escape in input contexts
            if (window.pendingWifiId !== "") {
                window.pendingWifiId = ""; window.pendingWifiSsid = "";
                return;  // Exit early, don't perform mode switch
            }
            // Play a sound effect for auditory feedback
            window.playSfx("switch.wav");
            // Build an ordered list of available modes based on hardware detection
            let modes = [];
            if (window.ethPresent) modes.push("eth");   // Ethernet first if available
            if (window.wifiPresent) modes.push("wifi"); // Then WiFi
            if (window.btPresent) modes.push("bt");     // Then Bluetooth
            // Only cycle if there are multiple modes to switch between
            if (modes.length > 1) {
                let idx = modes.indexOf(window.activeMode);          // Find current
                let nextMode = modes[(idx + 1) % modes.length];     // Next with wrap-around
                if (window.activeMode !== nextMode) {               // Only if different
                    window.powerAnimAllowed = false;                 // Lock the morph animation
                    powerAnimBlocker.restart();                     // Start 250ms delay timer
                    window.activeMode = nextMode;                   // Trigger mode switch
                }
            }
        }
    }

    // =========================================================================
    // PERSISTENT SETTINGS - Cached state survives widget restarts
    // =========================================================================
    // QSettings-backed storage. Data persists to disk automatically.
    // Category groups settings together, avoiding key collisions.
    // Used to immediately restore UI state before pollers return fresh data.
    Settings {
        id: cache
        category: "QS_NetworkWidgetUnified"  // Unique namespace for this widget
        property string lastWifiSsid: ""      // Remember last connected WiFi
        property string lastWifiJson: ""      // Full WiFi state cache
        property string lastBtJson: ""        // Full Bluetooth state cache
        property string lastEthJson: ""       // Full Ethernet state cache
    }

    // =========================================================================
    // CACHE DIRECTORY - Runtime file storage location
    // =========================================================================
    // XDG_RUNTIME_DIR is the standard Linux runtime directory (/run/user/1000)
    // It's tmpfs (in-memory), fast, and cleared on reboot - ideal for runtime state
    // Fallback to ~/.cache if XDG_RUNTIME_DIR is not set (unusual but safe)
    readonly property string cacheDir: Quickshell.env("XDG_RUNTIME_DIR") ?
        (Quickshell.env("XDG_RUNTIME_DIR") + "/qs_network") :
        (Quickshell.env("HOME") + "/.cache/qs_network")

    // The mode file enables cross-instance communication
    // Multiple instances of this widget can read/write the same file
    // to synchronize their active mode (e.g., if shown on multiple monitors)
    readonly property string modeFilePath: cacheDir + "/mode"

    // =========================================================================
    // HARDWARE PRESENCE FLAGS - What hardware actually exists
    // =========================================================================
    // These are set to 'true' by the poller JSON data when the corresponding
    // hardware is detected on the system. They control tab visibility.
    // Default 'false' means tabs are hidden until hardware is confirmed.
    property bool ethPresent: false
    property bool wifiPresent: false
    property bool btPresent: false

    // =========================================================================
    // FIRST LOAD GUARDS - Prevent UI flicker during initial poll
    // =========================================================================
    // Each mode has a "firstLoad" flag. The UI blocks validation until
    // all active pollers have returned their first response OR the
    // failsafe timer fires (1.5s timeout). This prevents the UI from
    // briefly showing wrong tabs before hardware is detected.
    property bool ethFirstLoad: true
    property bool wifiFirstLoad: true
    property bool btFirstLoad: true

    // =========================================================================
    // POWER ANIMATION GATE - Prevents unwanted morph animations
    // =========================================================================
    // The power button morphs between a large centered circle and a small
    // corner circle. This animation should only play for user-initiated
    // toggles, NOT during initial load or programmatic mode switches.
    // powerAnimBlocker is a 250ms timer that starts with running:true
    // on first load, blocking animation until it fires. It's restarted
    // whenever we want to suppress animation.
    property bool powerAnimAllowed: false  // Gate variable
    Timer {
        id: powerAnimBlocker
        interval: 250          // 250ms delay
        running: true          // Start immediately on component load
        onTriggered: window.powerAnimAllowed = true  // Open the gate
    }

    // =========================================================================
    // FAILSAFE TIMER - Deadlock prevention for script failures
    // =========================================================================
    // If the poller scripts hang, crash, or never return data, the UI would
    // be stuck in "firstLoad" state forever, showing nothing. This timer
    // forces all firstLoad flags to false after 1.5 seconds, unblocking
    // the UI. The 1.5s window allows normal polling (typically 100-500ms)
    // to complete while preventing permanent deadlock.
    Timer {
        id: firstLoadFailsafe
        interval: 1500  // 1.5 second safety timeout
        running: true   // Start immediately
        onTriggered: {
            let blocked = false;
            // Force-clear any firstLoad flags still set
            if (window.ethFirstLoad) { window.ethFirstLoad = false; blocked = true; }
            if (window.wifiFirstLoad) { window.wifiFirstLoad = false; blocked = true; }
            if (window.btFirstLoad) { window.btFirstLoad = false; blocked = true; }
            // If any were still blocked, re-run validation
            if (blocked) window.validateActiveMode();
        }
    }

    // =========================================================================
    // VALIDATION - Ensures active mode is actually available
    // =========================================================================
    // isValidatingMode prevents recursive re-entry. If validateActiveMode()
    // is called while already running, the second call is ignored.
    property bool isValidatingMode: false

    function validateActiveMode() {
        // Don't validate if any mode is still waiting for first poll
        if (window.ethFirstLoad || window.wifiFirstLoad || window.btFirstLoad) return;
        // Prevent recursive calls
        if (isValidatingMode) return;
        isValidatingMode = true;  // Set re-entry guard

        // Build list of modes that have confirmed hardware
        let validModes = [];
        if (window.ethPresent) validModes.push("eth");
        if (window.wifiPresent) validModes.push("wifi");
        if (window.btPresent) validModes.push("bt");

        // If current activeMode isn't in the valid list, switch to the first valid
        // This handles the case where hardware was removed or the cached mode
        // is for hardware that doesn't exist
        if (validModes.length > 0 && validModes.indexOf(window.activeMode) === -1) {
            window.powerAnimAllowed = false;      // Suppress morph animation
            powerAnimBlocker.restart();           // Re-block for 250ms
            window.activeMode = validModes[0];    // Switch to first available
        }

        isValidatingMode = false;  // Release re-entry guard
    }

    // =========================================================================
    // MODE FILE SYNCHRONIZATION - Cross-instance communication
    // =========================================================================
    // When multiple instances of this widget exist (e.g., on different monitors
    // or in different panels), they should show the same active mode.
    // Writing to modeFilePath on local changes and reading it periodically
    // keeps them synchronized.
    //
    // ignoreNextModeFileUpdate prevents infinite loops:
    // Instance A writes "wifi" -> Instance B reads "wifi", switches,
    // then writes "wifi" -> Instance A reads "wifi", switches... infinite loop!
    // Setting this flag before writing suppresses the next incoming read.
    property bool ignoreNextModeFileUpdate: false

    Process {
        id: modeReader
        // Read the mode file, suppressing errors if it doesn't exist yet
        command: ["bash", "-c", "cat '" + window.modeFilePath + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let mode = this.text.trim();  // Remove whitespace/newlines
                // Validate: must be one of the three known modes AND different
                // from current to avoid unnecessary switches
                if ((mode === "wifi" || mode === "bt" || mode === "eth") &&
                    window.activeMode !== mode) {
                    // Also verify the hardware actually exists before switching
                    if ((mode === "eth" && window.ethPresent) ||
                        (mode === "wifi" && window.wifiPresent) ||
                        (mode === "bt" && window.btPresent)) {
                        window.powerAnimAllowed = false;
                        powerAnimBlocker.restart();
                        window.ignoreNextModeFileUpdate = true;  // Don't write back
                        window.activeMode = mode;
                    }
                }
            }
        }
    }

    // Poll the mode file every 100ms for cross-instance synchronization
    // 100ms is fast enough for near-instant sync but slow enough to not
    // cause significant CPU usage from process spawning
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: modeReader.running = true  // Trigger the mode reader process
    }

    // =========================================================================
    // COMPONENT INITIALIZATION - Runs once when the widget is created
    // =========================================================================
    Component.onCompleted: {
        // Block power morph animation during initialization
        window.powerAnimAllowed = false;
        powerAnimBlocker.restart();

        // Create cache directory if it doesn't exist, and initialize mode file
        // The shell command: mkdir -p (create dirs), then check if mode file
        // exists; if not, write the current activeMode to it
        Quickshell.execDetached(["bash", "-c",
            "mkdir -p '" + window.cacheDir + "'; " +
            "if [ ! -f '" + window.modeFilePath + "' ]; then " +
            "echo '" + activeMode + "' > '" + window.modeFilePath + "'; fi"
        ]);

        // Load cached state from persistent settings
        // This provides instant UI population before the first poller returns
        // The 'true' argument marks these as cache loads (suppresses sounds,
        // skips firstLoad flag updates)
        let hasCache = false;
        if (cache.lastEthJson !== "") { processEthJson(cache.lastEthJson, true); hasCache = true; }
        if (cache.lastWifiJson !== "") { processWifiJson(cache.lastWifiJson, true); hasCache = true; }
        if (cache.lastBtJson !== "") { processBtJson(cache.lastBtJson, true); hasCache = true; }

        // INSTANT CACHE PRE-VALIDATION
        // After loading cached data, we know the hardware states immediately.
        // We can validate and switch tabs NOW instead of waiting for the
        // 1.5 second failsafe timer. This eliminates a visible delay on startup.
        if (hasCache) {
            let validModes = [];
            if (window.ethPresent) validModes.push("eth");
            if (window.wifiPresent) validModes.push("wifi");
            if (window.btPresent) validModes.push("bt");

            if (validModes.length > 0 && validModes.indexOf(window.activeMode) === -1) {
                window.activeMode = validModes[0];
                window.powerAnimAllowed = false;
                powerAnimBlocker.restart();
            }
        }

        // introState controls the entry animation. Setting to 1.0 means
        // "animation complete" - elements that use this for staggered entry
        // will appear immediately. Could be set to 0.0 for a delayed intro.
        introState = 1.0;

        // If WiFi is active, immediately fetch the list of saved/known networks
        // This populates the savedNetworks list for the "known network" auto-connect logic
        if (window.activeMode === "wifi") savedNetworksFetcher.running = true;
    }

    // =========================================================================
    // SOUND EFFECT PLAYER - Audio feedback for UI interactions
    // =========================================================================
    // Uses pw-play (PipeWire) with fallback to paplay (PulseAudio)
    // Both are tried, errors suppressed (2>/dev/null), so it works
    // regardless of which sound server is running
    function playSfx(filename) {
        try {
            // Qt.resolvedUrl converts a relative path to an absolute file:// URL
            // relative to the location of this QML file
            let rawUrl = Qt.resolvedUrl("sounds/" + filename).toString();
            let cleanPath = rawUrl;
            // Strip the file:// prefix (7 characters) to get a plain path
            // that shell commands can use
            if (cleanPath.indexOf("file://") === 0) cleanPath = cleanPath.substring(7);
            // Try PipeWire first (modern), fall back to PulseAudio (legacy)
            let cmd = "pw-play '" + cleanPath + "' 2>/dev/null || paplay '" + cleanPath + "' 2>/dev/null";
            // execDetached: fire and forget, don't wait for completion
            Quickshell.execDetached(["sh", "-c", cmd]);
        } catch(e) {
            // Silently ignore all errors - sound effects are non-critical
        }
    }

    // =========================================================================
    // THEME COLORS - From Matugen/material design color system
    // =========================================================================
    // MatugenColors reads the current system color scheme (generated by matugen
    // from the wallpaper) and exposes the full Material Design color palette.
    // These are readonly to prevent accidental modification of theme colors.
    MatugenColors { id: _theme }

    readonly property color base: _theme.base          // Main background color
    readonly property color mantle: _theme.mantle      // Slightly darker background
    readonly property color crust: _theme.crust        // Darkest background
    readonly property color text: _theme.text          // Primary text color
    readonly property color subtext0: _theme.subtext0  // Secondary text (dimmer)
    readonly property color overlay0: _theme.overlay0  // Overlay/muted element color
    readonly property color overlay1: _theme.overlay1  // Slightly brighter overlay
    readonly property color surface0: _theme.surface0  // Card/surface background (darkest)
    readonly property color surface1: _theme.surface1  // Card/surface background (medium)
    readonly property color surface2: _theme.surface2  // Card/surface background (lightest)
    readonly property color mauve: _theme.mauve        // Accent: purple
    readonly property color pink: _theme.pink          // Accent: pink
    readonly property color sapphire: _theme.sapphire  // Accent: blue
    readonly property color blue: _theme.blue          // Accent: lighter blue
    readonly property color red: _theme.red            // Accent: red (errors/danger)
    readonly property color maroon: _theme.maroon      // Accent: dark red
    readonly property color peach: _theme.peach        // Accent: warm orange-pink

    // =========================================================================
    // SCRIPT DIRECTORY - Location of shell scripts
    // =========================================================================
    // Uses HOME env var to build the absolute path. This is more reliable
    // than relative paths when scripts are called from different working dirs.
    readonly property string scriptsDir: Quickshell.env("HOME") +
        "/.config/hypr/scripts/quickshell/network"

    // =========================================================================
    // ACCENT COLOR SYSTEM - Color differentiation between modes
    // =========================================================================
    // Ethernet and WiFi share a "sharedAccent" (brightened sapphire/blue)
    // Bluetooth gets its own "btAccent" (mauve/purple)
    // This creates visual distinction: you always know which tab is active
    // by the dominant color without reading the label.
    readonly property color sharedAccent: Qt.lighter(window.sapphire, 1.15)
    readonly property color btAccent: window.mauve

    // =========================================================================
    // ACTIVE MODE - The currently selected network interface
    // =========================================================================
    // Defaults to "bt" but will be switched to the first detected hardware
    // by validateActiveMode() during initialization.
    // All UI elements reactively update when this changes.
    property string activeMode: "bt"

    // Dynamic accent color that changes with activeMode
    readonly property color activeColor: activeMode === "bt" ?
        window.btAccent : window.sharedAccent

    // Darker variant for gradients and secondary elements
    // Qt.darker with factor 1.25 produces a noticeably darker shade
    readonly property color activeGradientSecondary: Qt.darker(window.activeColor, 1.25)

    // =========================================================================
    // BUSY/STATE TRACKING - Connection lifecycle management
    // =========================================================================
    // busyTasks: Object keyed by device ID. When a device is connecting or
    // disconnecting, its ID is added to this object. The UI shows spinners.
    // Uses plain object instead of Set for easier property change detection.
    property var busyTasks: ({})

    // disconnectingDevices: Subset of busyTasks specifically for disconnect.
    // Used to show red warning state in the radar rings and core elements.
    property var disconnectingDevices: ({})

    // connectingId: The single device currently being connected.
    // Empty string means no active connection attempt.
    property string connectingId: ""

    // failedId: Device ID that most recently failed to connect.
    // Cleared after 4 seconds by failClearTimer.
    property string failedId: ""

    // Global timeout: If any task takes more than 15 seconds, assume it hung
    // and clear all busy states. Prevents permanent spinner display.
    Timer {
        id: busyTimeout
        interval: 15000  // 15 seconds
        onTriggered: {
            window.busyTasks = ({});           // Clear all busy flags
            window.disconnectingDevices = ({}); // Clear all disconnecting flags
            window.connectingId = "";          // Clear active connection
        }
    }

    // Clear the failed state after 4 seconds
    // The red error indicator is temporary - it auto-clears
    Timer {
        id: failClearTimer
        interval: 4000  // 4 seconds
        onTriggered: window.failedId = ""
    }

    // =========================================================================
    // POWER PENDING TIMEOUTS - Optimistic UI safety nets
    // =========================================================================
    // When the user toggles power, we optimistically update the UI immediately
    // (expectedXxxPower). The poller will eventually confirm the change.
    // But if the poller never confirms (script failure, permission error, etc.),
    // these timers clear the pending state after 8 seconds, reverting to
    // whatever the poller last reported.
    Timer {
        id: ethPendingReset
        interval: 8000  // 8 seconds
        onTriggered: {
            window.ethPowerPending = false;    // Clear pending flag
            window.expectedEthPower = "";      // Clear expected state
        }
    }
    Timer {
        id: wifiPendingReset
        interval: 8000
        onTriggered: {
            window.wifiPowerPending = false;
            window.expectedWifiPower = "";
        }
    }
    Timer {
        id: btPendingReset
        interval: 8000
        onTriggered: {
            window.btPowerPending = false;
            window.expectedBtPower = "";
        }
    }

    // =========================================================================
    // INFO VIEW TOGGLE - Shows/hides detailed connection info
    // =========================================================================
    // When true, the widget shows info nodes (IP, MAC, signal strength, etc.)
    // instead of the device list. Toggled by the "action_scan" / "action_settings"
    // cards or automatically when a new connection is established.
    property bool showInfoView: false

    // =========================================================================
    // WIFI PASSWORD PROMPT STATE
    // =========================================================================
    // When a secure WiFi network that isn't saved is selected, instead of
    // connecting immediately, we show a password prompt. These properties
    // track which network is awaiting a password.
    property string pendingWifiSsid: ""  // Display name (SSID)
    property string pendingWifiId: ""    // Internal ID for connection

    // =========================================================================
    // SAVED WIFI NETWORKS - Known networks for auto-connection logic
    // =========================================================================
    // Populated by savedNetworksFetcher process using nmcli.
    // Used to determine if a secure network needs a password prompt:
    // - Known network + secure = nmcli uses saved credentials, no prompt
    // - Unknown network + secure = show password prompt
    property var savedWifiNetworks: []

    // Process to fetch saved/known WiFi connection names
    // nmcli -t: tabular output (machine-parseable)
    // -f NAME: only show connection name field
    // grep -v 'lo': exclude loopback interface
    Process {
        id: savedNetworksFetcher
        command: ["bash", "-c",
            "nmcli -t -f NAME connection show | grep -v 'lo'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text.trim();
                // Split by newline to get array of network names
                window.savedWifiNetworks = text ? text.split('\n') : [];
            }
        }
    }

    // =========================================================================
    // CONNECTION PROCESS - Executes connect commands and handles results
    // =========================================================================
    // A single Process instance reused for all connection types.
    // targetId and targetSsid are set before running to configure the command.
    // The onExited handler processes success/failure uniformly.
    Process {
        id: connectProcess
        property string targetId: ""     // Device/network identifier
        property string targetSsid: ""   // SSID for WiFi (used for cleanup on failure)

        onExited: {
            let code = exitCode;  // 0 = success, non-zero = failure

            // Remove from busy tasks regardless of outcome
            let bt = window.busyTasks;
            delete bt[targetId];
            // Object.assign creates a new object reference, triggering
            // QML property change detection (necessary because we mutated
            // the object in place, which QML doesn't detect)
            window.busyTasks = Object.assign({}, bt);

            if (code !== 0) {
                // Connection FAILED
                window.failedId = targetId;
                failClearTimer.restart();
                window.playSfx("error.wav");

                // WiFi-specific cleanup: delete the failed connection profile
                // that nmcli may have created, so it doesn't clutter the list
                if (window.activeMode === "wifi" && targetSsid !== "") {
                    Quickshell.execDetached(["bash", "-c",
                        "nmcli connection delete '" + targetSsid + "' 2>/dev/null"]);
                    // Remove from saved networks list
                    let newSaved = [];
                    for(let i = 0; i < window.savedWifiNetworks.length; i++) {
                        if(window.savedWifiNetworks[i] !== targetSsid) {
                            newSaved.push(window.savedWifiNetworks[i]);
                        }
                    }
                    window.savedWifiNetworks = newSaved;
                }
            }

            // Clear connecting state
            window.connectingId = "";

            // Trigger immediate poll refresh to get updated state
            if (window.activeMode === "eth") ethPoller.running = true;
            else if (window.activeMode === "wifi") wifiPoller.running = true;
            else btPoller.running = true;
        }
    }

    // =========================================================================
    // CONNECT DEVICE FUNCTION - Unified connection interface
    // =========================================================================
    // Handles all three modes (eth/wifi/bt) with a single function.
    // Parameters:
    //   mode: "eth", "wifi", or "bt"
    //   id: internal device/network ID
    //   macOrSsid: MAC address (eth/bt) or SSID (wifi)
    //   password: WiFi password (empty string for open networks or non-wifi)
    function connectDevice(mode, id, macOrSsid, password) {
        window.connectingId = id;
        window.failedId = "";

        // Mark as busy
        let bt = window.busyTasks;
        bt[id] = true;
        window.busyTasks = Object.assign({}, bt);  // Trigger QML change detection
        busyTimeout.restart();  // Reset the 15-second failsafe

        connectProcess.targetId = id;
        connectProcess.targetSsid = (mode === "wifi") ? macOrSsid : "";

        // Build the appropriate nmcli command for each mode
        if (mode === "eth") {
            connectProcess.command = ["bash", "-c",
                "nmcli device connect '" + macOrSsid + "'"];
        } else if (mode === "wifi") {
            if (password !== "") {
                connectProcess.command = ["bash", "-c",
                    "nmcli device wifi connect '" + macOrSsid +
                    "' password '" + password + "'"];
            } else {
                connectProcess.command = ["bash", "-c",
                    "nmcli device wifi connect '" + macOrSsid + "'"];
            }
        } else {
            // Bluetooth uses a custom script for bluetoothctl interaction
            connectProcess.command = ["bash", "-c",
                window.scriptsDir + "/bluetooth_panel_logic.sh --connect '" +
                macOrSsid + "'"];
        }
        connectProcess.running = true;  // Execute the command
    }

    // =========================================================================
    // CORE SYSTEM - Visual representation of connected devices
    // =========================================================================
    // The "cores" are the central circle elements in the orbital layout.
    // Each core can represent one connected device. There are 5 slots.
    // The system maps real connected devices to these 5 visual slots,
    // handling additions, removals, and reordering smoothly.
    //
    // currentCores: Array of 5 device objects (or null for empty slots)
    // coreVisualIndices: Maps slot index to visual position for orbital spacing
    // activeCoreCount: Number of non-null cores (0-5)
    // smoothedActiveCoreCount: Animated version for gradual visual transitions

    property var currentCores: [null, null, null, null, null]
    property var coreVisualIndices: [0, 0, 0, 0, 0]
    property int activeCoreCount: 0
    property real smoothedActiveCoreCount: activeCoreCount
    Behavior on smoothedActiveCoreCount {
        NumberAnimation {
            duration: 1000                    // 1 second smooth transition
            easing.type: Easing.InOutExpo     // Exponential easing: slow start/end, fast middle
        }
    }

    // =========================================================================
    // SYNC CORES FUNCTION - Maps real devices to visual core slots
    // =========================================================================
    // This is the heart of the orbital layout logic. It takes the current
    // list of connected devices and maps them to the 5 visual core positions.
    //
    // Algorithm:
    // 1. Get the list of currently connected devices for the active mode
    // 2. Preserve existing core assignments where possible (devices stay in
    //    their current positions even as the list updates)
    // 3. Clear cores for devices that disconnected
    // 4. Fill empty cores with newly connected devices
    // 5. Calculate orbital positions based on activeCoreCount
    function syncCores() {
        let list = [];

        // Get connected devices based on mode
        if (activeMode === "eth") {
            // Ethernet: single device, wrapped in array for uniform handling
            list = window.ethConnected ? [window.ethConnected] : [];
        } else if (activeMode === "wifi") {
            // WiFi: single device, validate it has an SSID
            let wValid = !!window.wifiConnected &&
                window.wifiConnected.ssid !== undefined;
            list = wValid ? [window.wifiConnected] : [];
        } else {
            // Bluetooth: can have multiple simultaneous connections
            list = window.btConnected;
        }

        // If power is off, no devices should show
        if (!currentPower) list = [];
        // Ensure list is always an array (defensive programming)
        else if (!Array.isArray(list)) list = [list];

        // Clone current cores for comparison
        let newCores = [
            window.currentCores[0], window.currentCores[1],
            window.currentCores[2], window.currentCores[3],
            window.currentCores[4]
        ];
        let found = [false, false, false, false, false];  // Track matched slots

        // PASS 1: Update existing cores that still have their device connected
        for (let i = 0; i < list.length && i < 5; i++) {
            let dev = list[i];
            // Get unique identifier based on mode
            let id = activeMode === "wifi" ? dev.ssid :
                     (activeMode === "eth" ? dev.id : dev.mac);
            // Search for this device in existing cores
            for (let c = 0; c < 5; c++) {
                if (newCores[c]) {
                    let cId = activeMode === "wifi" ? newCores[c].ssid :
                              (activeMode === "eth" ? newCores[c].id :
                               newCores[c].mac);
                    if (cId === id) {
                        found[c] = true;        // Mark slot as still valid
                        newCores[c] = dev;      // Update with latest data
                        break;
                    }
                }
            }
        }

        // Clear cores for devices that disconnected
        for (let c = 0; c < 5; c++) {
            if (!found[c]) newCores[c] = null;
        }

        // PASS 2: Fill empty slots with new devices
        for (let i = 0; i < list.length && i < 5; i++) {
            let dev = list[i];
            let id = activeMode === "wifi" ? dev.ssid :
                     (activeMode === "eth" ? dev.id : dev.mac);
            // Check if this device already has a core slot
            let isFound = false;
            for (let c = 0; c < 5; c++) {
                if (newCores[c]) {
                    let cId = activeMode === "wifi" ? newCores[c].ssid :
                              (activeMode === "eth" ? newCores[c].id :
                               newCores[c].mac);
                    if (cId === id) { isFound = true; break; }
                }
            }
            // If not found, assign to the first empty slot
            if (!isFound) {
                for (let c = 0; c < 5; c++) {
                    if (!newCores[c]) { newCores[c] = dev; break; }
                }
            }
        }

        // Update with spread operator to create new array reference
        window.currentCores = [...newCores];

        // Calculate visual indices for orbital spacing
        // Devices are evenly distributed around the orbit circle
        let activeCount = 0;
        let newVis = [0, 0, 0, 0, 0];
        for (let c = 0; c < 5; c++) {
            if (newCores[c]) {
                newVis[c] = activeCount;  // Sequential index for orbit position
                activeCount++;
            }
        }
        window.coreVisualIndices = newVis;
        window.activeCoreCount = activeCount;  // Trigger smoothed transition
    }

    // =========================================================================
    // REACTIVE CONNECTION HANDLERS
    // =========================================================================
    onCurrentConnChanged: {
        showInfoView = currentConn;  // Auto-show info when connected
        if (currentConn) updateInfoNodes();  // Populate info nodes
    }

    // =========================================================================
    // MODE SWITCH HANDLER - Cleans up and reinitializes on mode change
    // =========================================================================
    onActiveModeChanged: {
        // Write mode to file for cross-instance sync
        // Only if we're not ignoring (to prevent ping-pong with modeReader)
        if (!window.ignoreNextModeFileUpdate) {
            Quickshell.execDetached(["bash", "-c",
                "echo '" + window.activeMode + "' > '" +
                window.modeFilePath + "'"]);
        }
        window.ignoreNextModeFileUpdate = false;  // Reset for next change

        // Clear any pending WiFi password prompt
        window.pendingWifiId = "";
        window.pendingWifiSsid = "";

        // Refresh saved networks list when switching to WiFi
        if (window.activeMode === "wifi") savedNetworksFetcher.running = true;

        // COMPLETE STATE RESET
        // All mode-specific state is cleared and rebuilt from poller data
        infoListModel.clear();
        window.busyTasks = ({});
        window.disconnectingDevices = ({});
        window.currentCores = [null, null, null, null, null];
        window.coreVisualIndices = [0, 0, 0, 0, 0];
        window.activeCoreCount = 0;
        syncCores();  // Rebuild core layout
        window.showInfoView = window.currentConn;  // Update info visibility
        if (window.showInfoView) window.updateInfoNodes();
    }

    // =========================================================================
    // LIST MODELS - QML's native list data structure for Repeater binding
    // =========================================================================
    // ListModel is a key-value list that Repeater can directly use as a model.
    // Each entry is an object with named properties.
    // These three models hold the data for the orbit card system.
    ListModel { id: wifiListModel }
    ListModel { id: btListModel }
    ListModel { id: infoListModel }

    // =========================================================================
    // SYNC MODEL FUNCTION - Efficient diff-based list model update
    // =========================================================================
    // Compares the current ListModel contents with a new data array and
    // applies minimal changes: removes deleted items, inserts new items,
    // moves reordered items, and updates changed properties.
    // This is MUCH more efficient than clearing and rebuilding the model,
    // especially important for smooth animations during polling updates.
    function syncModel(listModel, dataArray) {
        // STEP 1: Remove items that no longer exist in the data array
        // Iterate backwards to avoid index shifting during removal
        for (let i = listModel.count - 1; i >= 0; i--) {
            let id = listModel.get(i).id;
            let found = false;
            for (let j = 0; j < dataArray.length; j++) {
                if (id === dataArray[j].id) { found = true; break; }
            }
            if (!found) { listModel.remove(i); }  // Item disappeared, remove it
        }

        // STEP 2: Update or insert items (limit to 30 for performance)
        for (let i = 0; i < dataArray.length && i < 30; i++) {
            let d = dataArray[i];
            // Find if this item already exists in the model (at or after position i)
            let foundIdx = -1;
            for (let j = i; j < listModel.count; j++) {
                if (listModel.get(j).id === d.id) { foundIdx = j; break; }
            }

            // Build a normalized object with defaults for all properties
            let obj = {
                id: d.id || "",
                ssid: d.ssid || "",
                mac: d.mac || "",
                name: d.name || d.ssid || "",
                icon: d.icon || "",
                security: d.security || "",
                action: d.action || "",
                isInfoNode: d.isInfoNode || false,
                isActionable: d.isActionable !== undefined ? d.isActionable : false,
                cmdStr: d.cmdStr || "",
                parentIndex: d.parentIndex !== undefined ? d.parentIndex : -1
            };

            if (foundIdx === -1) {
                // New item: insert at the expected position
                listModel.insert(i, obj);
            } else {
                // Existing item: move to correct position if needed
                if (foundIdx !== i) { listModel.move(foundIdx, i, 1); }
                // Update any changed properties (selective update)
                for (let key in obj) {
                    if (listModel.get(i)[key] !== obj[key]) {
                        listModel.setProperty(i, key, obj[key]);
                    }
                }
            }
        }
    }

    // =========================================================================
    // LIST LOCKING - Prevents visual disruption during interaction
    // =========================================================================
    // When the user hovers over a card, the list shouldn't suddenly reorder
    // because new poller data arrived. "List locking" defers model updates
    // until the user moves their mouse away.
    //
    // hoveredCardCount: Incremented when a card enters "locked" state
    // isListLocked: True when any card is being hovered/pressed
    // nextXxxList: Deferred updates stored here, applied when unlocked

    property int hoveredCardCount: 0
    readonly property bool isListLocked: hoveredCardCount > 0
    property var nextWifiList: null
    property var nextBtList: null
    property var nextInfoList: null

    onIsListLockedChanged: {
        if (!isListLocked) {  // List just unlocked - apply deferred updates
            if (nextWifiList !== null) {
                window.syncModel(wifiListModel, nextWifiList);
                window.wifiList = nextWifiList;
                nextWifiList = null;
            }
            if (nextBtList !== null) {
                window.syncModel(btListModel, nextBtList);
                window.btList = nextBtList;
                nextBtList = null;
            }
            if (nextInfoList !== null) {
                window.syncModel(infoListModel, nextInfoList);
                nextInfoList = null;
            }
        }
    }

    // =========================================================================
    // ETHERNET STATE - Single-device wired connection
    // =========================================================================
    property string ethDeviceName: ""          // Interface name (e.g., "enp3s0")
    property bool ethPowerPending: false       // Optimistic power toggle in progress
    property string expectedEthPower: ""       // What we asked for ("on"/"off")
    property string ethPower: "off"            // Current confirmed power state
    property var ethConnected: null            // null or {id, ip, mac, speed}
    readonly property bool isEthConn: !!window.ethConnected  // !! converts to boolean

    onEthConnectedChanged: {
        syncCores();  // Update core layout
        if (window.currentConn && window.activeMode === "eth") updateInfoNodes();
    }

    // =========================================================================
    // WIFI STATE - Single-device wireless connection with scan list
    // =========================================================================
    property bool wifiPowerPending: false
    property string expectedWifiPower: ""
    property string wifiPower: "off"
    property var wifiConnected: null           // null or {ssid, signal, security, ip, freq}
    property var wifiList: []                  // Array of available networks
    property string strongestWifiSsid: ""      // Auto-computed from signal strength

    // Boolean with validation: true only if connected AND has a valid SSID
    readonly property bool isWifiConn: !!window.wifiConnected &&
        window.wifiConnected.ssid !== undefined

    // TARGET WIFI SSID - Which network to highlight/auto-connect
    // Priority: Last connected SSID (if still in range) > Strongest signal
    // This determines which network gets the pulsing highlight ring
    readonly property string targetWifiSsid: {
        let found = false;
        if (cache.lastWifiSsid !== "") {
            // Check if the previously connected network is still visible
            for (let i = 0; i < wifiList.length; i++) {
                if (wifiList[i].id === cache.lastWifiSsid) {
                    found = true;
                    break;
                }
            }
        }
        return found ? cache.lastWifiSsid : strongestWifiSsid;
    }

    onWifiConnectedChanged: {
        // Cache the connected SSID for next session's targetWifiSsid
        if (window.wifiConnected && window.wifiConnected.ssid) {
            cache.lastWifiSsid = window.wifiConnected.ssid;
        }
        syncCores();
        if (window.currentConn && window.activeMode === "wifi") updateInfoNodes();
    }

    // =========================================================================
    // BLUETOOTH STATE - Multi-device wireless connections
    // =========================================================================
    property bool btPowerPending: false
    property string expectedBtPower: ""
    property string btPower: "off"
    property var btConnected: []               // Array of connected devices
    property var btList: []                    // Array of available/pairable devices
    readonly property bool isBtConn: window.btConnected.length > 0

    onBtConnectedChanged: {
        syncCores();
        if (window.currentConn && window.activeMode === "bt") updateInfoNodes();
    }

    // =========================================================================
    // DERIVED POWER/CONNECTION STATE - Convenience properties for current mode
    // =========================================================================
    // These avoid writing "activeMode === 'eth' ? ethXxx : wifiXxx..." everywhere
    readonly property bool currentPower: activeMode === "eth" ?
        window.ethPower === "on" :
        (activeMode === "wifi" ? window.wifiPower === "on" : window.btPower === "on")

    onCurrentPowerChanged: { syncCores(); }  // Power change affects core visibility

    readonly property bool currentPowerPending: activeMode === "eth" ?
        window.ethPowerPending :
        (activeMode === "wifi" ? window.wifiPowerPending : window.btPowerPending)

    readonly property bool currentConn: activeMode === "eth" ?
        window.isEthConn :
        (activeMode === "wifi" ? window.isWifiConn : window.isBtConn)

    readonly property var currentObjList: activeMode === "eth" ?
        (window.isEthConn ? [window.ethConnected] : []) :
        (activeMode === "wifi" ?
            (window.isWifiConn ? [window.wifiConnected] : []) :
            window.btConnected)

    // =========================================================================
    // MULTI-TRANSITION STATE - Single vs Multi device layout animation
    // =========================================================================
    // When Bluetooth has multiple devices connected, the layout transitions
    // from a single centered orbit to a distributed multi-core layout.
    // isLogicMultiState gates this transition.
    // multiTransitionState animates from 0.0 (single layout) to 1.0 (multi layout)
    // All orbital math interpolates between single and multi radii/angles
    // using this value.
    readonly property bool isLogicMultiState: window.activeMode === "bt" &&
        window.activeCoreCount > 1

    property real multiTransitionState: (isLogicMultiState && window.currentPower) ?
        1.0 : 0.0
    Behavior on multiTransitionState {
        NumberAnimation {
            duration: 1200                 // 1.2 second morph
            easing.type: Easing.InOutExpo  // Smooth acceleration/deceleration
        }
    }

    // =========================================================================
    // UPDATE INFO NODES - Populates the info view with connection details
    // =========================================================================
    // Builds an array of info node objects for the current connection(s).
    // Each node has: id, name, icon, action, isInfoNode, isActionable, cmdStr, parentIndex
    // parentIndex links the node to a specific core (for multi-device Bluetooth)
    function updateInfoNodes() {
        let nodes = [];
        let cList = [];

        // Get the connected device list for the current mode
        if (window.activeMode === "eth") {
            cList = window.ethConnected ? [window.ethConnected] : [];
        } else if (window.activeMode === "wifi") {
            let wConn = window.wifiConnected;
            if (Array.isArray(wConn)) wConn = wConn[0];  // Take first if somehow array
            cList = (!!wConn && wConn.ssid !== undefined) ? [wConn] : [];
        } else {
            cList = window.btConnected;
        }

        if (window.currentConn && cList.length > 0) {
            for (let i = 0; i < cList.length; i++) {
                let obj = cList[i];
                let cIndex = 0;

                // For Bluetooth, find which core this device maps to
                if (window.activeMode === "bt") {
                    for (let c = 0; c < 5; c++) {
                        if (window.currentCores[c] &&
                            window.currentCores[c].mac === obj.mac) {
                            cIndex = c;
                            break;
                        }
                    }
                }

                // Add mode-specific info nodes
                if (window.activeMode === "eth") {
                    // Ethernet: IP, speed, MAC
                    nodes.push({ id: "ip", name: obj.ip || "No IP",
                        icon: "󰩟", action: "IP Address",
                        isInfoNode: true, isActionable: false,
                        parentIndex: cIndex });
                    nodes.push({ id: "spd", name: obj.speed || "Unknown",
                        icon: "󰓅", action: "Link Speed",
                        isInfoNode: true, isActionable: false,
                        parentIndex: cIndex });
                    nodes.push({ id: "mac", name: obj.mac || "Unknown",
                        icon: "󰒋", action: "MAC Address",
                        isInfoNode: true, isActionable: false,
                        parentIndex: cIndex });
                } else if (window.activeMode === "wifi") {
                    // WiFi: signal, security, IP, band/frequency
                    let sigValue = obj.signal !== undefined ?
                        obj.signal + "%" : "Calculating...";
                    nodes.push({ id: "sig_" + i, name: sigValue,
                        icon: obj.icon || "󰤨", action: "Signal Strength",
                        isInfoNode: true, isActionable: false,
                        parentIndex: cIndex });
                    nodes.push({ id: "sec_" + i,
                        name: obj.security || "Open",
                        icon: "󰦝", action: "Security",
                        isInfoNode: true, isActionable: false,
                        parentIndex: cIndex });
                    if (obj.ip) nodes.push({ id: "ip_" + i, name: obj.ip,
                        icon: "󰩟", action: "IP Address",
                        isInfoNode: true, isActionable: false,
                        parentIndex: cIndex });
                    if (obj.freq) nodes.push({ id: "freq_" + i, name: obj.freq,
                        icon: "󰖧", action: "Band",
                        isInfoNode: true, isActionable: false,
                        parentIndex: cIndex });
                } else {
                    // Bluetooth: battery, audio profile, MAC
                    nodes.push({ id: "bat_" + obj.mac,
                        name: (obj.battery || "0") + "%",
                        icon: "󰥉", action: "Battery",
                        isInfoNode: true, isActionable: false,
                        parentIndex: cIndex });
                    if (obj.profile) {
                        nodes.push({ id: "prof_" + obj.mac,
                            name: obj.profile,
                            icon: (obj.profile === "Hi-Fi (A2DP)" ?
                                "󰓃" : "󰋎"),
                            action: "Audio Profile",
                            isInfoNode: true, isActionable: false,
                            parentIndex: cIndex });
                    }
                    nodes.push({ id: "mac_" + obj.mac,
                        name: obj.mac || "Unknown",
                        icon: "󰒋", action: "MAC Address",
                        isInfoNode: true, isActionable: false,
                        parentIndex: cIndex });
                }
            }
            // Add a "scan devices" action to return to device list
            if (window.activeMode !== "eth") {
                nodes.push({ id: "action_scan",
                    name: "Scan Devices", icon: "󰍉",
                    action: "Switch View",
                    isInfoNode: true, isActionable: true,
                    cmdStr: "TOGGLE_VIEW", parentIndex: -1 });
            }
        }

        // Apply to model, respecting list lock
        if (window.isListLocked && window.activeMode !== "eth") {
            window.nextInfoList = nodes;  // Defer if list is locked
        } else {
            window.syncModel(infoListModel, nodes);
            window.nextInfoList = null;
        }
    }

    // =========================================================================
    // JSON PROCESSORS - Parse poller output and update state
    // =========================================================================
    // Three nearly-identical functions that parse the JSON output from
    // eth/wifi/bt poller scripts and update all related state properties.
    // Each handles: present detection, power state, pending resolution,
    // connection data, and device list updates.

    function processEthJson(textData, isCache = false) {
        // If this is a live poll (not cache), mark first load complete
        if (!isCache && window.ethFirstLoad) {
            window.powerAnimAllowed = false;
            powerAnimBlocker.restart();
            window.ethFirstLoad = false;
        }
        if (textData === "") {
            if (!isCache) validateActiveMode();
            return;
        }
        try {
            let data = JSON.parse(textData);
            window.ethPresent = data.present === true;  // Hardware exists?
            let fetchedDevice = data.device || "";
            if (fetchedDevice !== "") window.ethDeviceName = fetchedDevice;
            let fetchedPower = data.power || "off";

            // PENDING RESOLUTION: If we optimistically changed power,
            // check if the poller confirms our expected state
            if (window.ethPowerPending) {
                window.ethPower = window.expectedEthPower;  // Keep showing expected
                if (fetchedPower === window.expectedEthPower) {
                    window.ethPowerPending = false;  // Confirmed!
                    ethPendingReset.stop();          // Cancel timeout
                }
            } else {
                window.ethPower = fetchedPower;  // Update from poller
                window.expectedEthPower = "";
            }

            // Connection data update (only if changed, to avoid unnecessary syncs)
            let newConnected = data.connected;
            if (JSON.stringify(window.ethConnected) !== JSON.stringify(newConnected)) {
                // Play sound on new connection (not on cache load)
                if (!window.isEthConn && newConnected && window.activeMode === "eth") {
                    window.playSfx("connect.wav");
                }
                window.ethConnected = newConnected;
            }
        } catch(e) {
            // JSON parse error - silently ignore malformed data
        }
        if (!isCache) validateActiveMode();
    }

    function processWifiJson(textData, isCache = false) {
        if (!isCache && window.wifiFirstLoad) {
            window.powerAnimAllowed = false;
            powerAnimBlocker.restart();
            window.wifiFirstLoad = false;
        }
        if (textData === "") {
            if (!isCache) validateActiveMode();
            return;
        }
        try {
            let data = JSON.parse(textData);
            window.wifiPresent = data.present === true;
            let fetchedPower = data.power || "off";

            if (window.wifiPowerPending) {
                window.wifiPower = window.expectedWifiPower;
                if (fetchedPower === window.expectedWifiPower) {
                    window.wifiPowerPending = false;
                    wifiPendingReset.stop();
                }
            } else {
                window.wifiPower = fetchedPower;
                window.expectedWifiPower = "";
            }

            let wasWifiConn = !!window.wifiConnected &&
                window.wifiConnected.ssid !== undefined;
            let newConnected = data.connected;
            let newNetworks = data.networks ? data.networks : [];

            // ENRICHMENT: If connected to a network, merge its scan data
            // (signal, security, frequency) into the connected object
            if (newConnected && newConnected.ssid) {
                let match = newNetworks.find(n =>
                    n.id === newConnected.ssid || n.ssid === newConnected.ssid);
                if (match) {
                    newConnected.icon = match.icon || newConnected.icon;
                    newConnected.name = match.name || newConnected.name;
                    newConnected.security = match.security || newConnected.security;
                    newConnected.signal = match.signal || newConnected.signal;
                    newConnected.freq = match.freq || newConnected.freq;
                    newConnected.ip = match.ip || newConnected.ip;
                }
            }

            let isNowWifiConn = !!newConnected && newConnected.ssid !== undefined;

            // Update connected state if changed
            if (JSON.stringify(window.wifiConnected) !==
                JSON.stringify(newConnected)) {
                window.wifiConnected = newConnected;
            }

            // Find the network with the strongest signal for target highlighting
            if (newNetworks.length > 0) {
                let maxSig = -1;
                let bestSsid = newNetworks[0].id;
                for (let i = 0; i < newNetworks.length; i++) {
                    let sig = parseInt(newNetworks[i].signal || 0);
                    if (sig > maxSig) {
                        maxSig = sig;
                        bestSsid = newNetworks[i].id;
                    }
                }
                window.strongestWifiSsid = bestSsid;
            } else {
                window.strongestWifiSsid = "";
            }

            // Sort networks alphabetically for consistent display
            newNetworks.sort((a, b) => a.id.localeCompare(b.id));

            // Add a "Current Device" action card when connected
            if (isNowWifiConn && window.activeMode === "wifi") {
                newNetworks.push({
                    id: "action_settings", ssid: "Current Device",
                    mac: "", name: "Current Device", icon: "󰒓",
                    security: "", action: "View Info",
                    isInfoNode: false, isActionable: true,
                    cmdStr: "TOGGLE_VIEW", parentIndex: -1
                });
            }

            // Update the WiFi list model (with lock check)
            if (JSON.stringify(window.wifiList) !== JSON.stringify(newNetworks)) {
                if (window.isListLocked) {
                    window.nextWifiList = newNetworks;  // Defer
                } else {
                    window.syncModel(wifiListModel, newNetworks);
                    window.wifiList = newNetworks;
                    window.nextWifiList = null;
                }
            }

            if (window.activeMode === "wifi") {
                // Auto-show info view on new connection
                if (!wasWifiConn && isNowWifiConn) {
                    window.showInfoView = true;
                }

                // Clean up disconnecting devices that are no longer connected
                let dd = window.disconnectingDevices;
                let ddChanged = false;
                for (let ssid in dd) {
                    if (!isNowWifiConn ||
                        (newConnected && newConnected.ssid !== ssid)) {
                        delete dd[ssid];
                        ddChanged = true;
                    }
                }
                if (ddChanged) {
                    window.disconnectingDevices = Object.assign({}, dd);
                    if (Object.keys(window.disconnectingDevices).length === 0 &&
                        Object.keys(window.busyTasks).length === 0) {
                        busyTimeout.stop();
                    }
                }

                // Detect newly connected device and clear its busy state
                let newlyConnected = false;
                let bt = window.busyTasks;
                if (isNowWifiConn && newConnected && bt[newConnected.ssid]) {
                    newlyConnected = true;
                    delete bt[newConnected.ssid];
                    window.connectingId = "";
                }
                if (newlyConnected) {
                    window.playSfx("connect.wav");
                    window.busyTasks = Object.assign({}, bt);
                    if (Object.keys(window.busyTasks).length === 0 &&
                        Object.keys(window.disconnectingDevices).length === 0) {
                        busyTimeout.stop();
                    }
                }

                if (isNowWifiConn || window.isBtConn || window.isEthConn) {
                    window.updateInfoNodes();
                }
            }
        } catch(e) {}
        if (!isCache) validateActiveMode();
    }

    function processBtJson(textData, isCache = false) {
        if (!isCache && window.btFirstLoad) {
            window.powerAnimAllowed = false;
            powerAnimBlocker.restart();
            window.btFirstLoad = false;
        }
        if (textData === "") {
            if (!isCache) validateActiveMode();
            return;
        }
        try {
            let data = JSON.parse(textData);
            window.btPresent = data.present === true;
            let fetchedPower = data.power || "off";

            if (window.btPowerPending) {
                window.btPower = window.expectedBtPower;
                if (fetchedPower === window.expectedBtPower) {
                    window.btPowerPending = false;
                    btPendingReset.stop();
                }
            } else {
                window.btPower = fetchedPower;
                window.expectedBtPower = "";
            }

            let oldBtLen = window.btConnected.length;
            let newBtConnected = data.connected || [];
            if (!Array.isArray(newBtConnected)) {
                newBtConnected = [newBtConnected];
            }
            let isNowBtConn = newBtConnected.length > 0;

            if (JSON.stringify(window.btConnected) !==
                JSON.stringify(newBtConnected)) {
                window.btConnected = newBtConnected;
            }

            let newDevices = data.devices ? data.devices : [];
            newDevices.sort((a, b) => a.id.localeCompare(b.id));

            if (isNowBtConn && window.activeMode === "bt") {
                newDevices.push({
                    id: "action_settings", ssid: "",
                    mac: "action_settings", name: "Current Device",
                    icon: "󰒓", action: "View Info",
                    isInfoNode: false, isActionable: true,
                    cmdStr: "TOGGLE_VIEW", parentIndex: -1
                });
            }

            if (JSON.stringify(window.btList) !== JSON.stringify(newDevices)) {
                if (window.isListLocked) {
                    window.nextBtList = newDevices;
                } else {
                    window.syncModel(btListModel, newDevices);
                    window.btList = newDevices;
                    window.nextBtList = null;
                }
            }

            if (window.activeMode === "bt") {
                if (newBtConnected.length > oldBtLen) {
                    window.showInfoView = true;
                }

                let dd = window.disconnectingDevices;
                let ddChanged = false;
                for (let mac in dd) {
                    let stillConnected = false;
                    for (let i = 0; i < newBtConnected.length; i++) {
                        if (newBtConnected[i].mac === mac) {
                            stillConnected = true;
                            break;
                        }
                    }
                    if (!stillConnected) {
                        delete dd[mac];
                        ddChanged = true;
                    }
                }
                if (ddChanged) {
                    window.disconnectingDevices = Object.assign({}, dd);
                    if (Object.keys(window.disconnectingDevices).length === 0 &&
                        Object.keys(window.busyTasks).length === 0) {
                        busyTimeout.stop();
                    }
                }

                let newlyConnected = false;
                let bt = window.busyTasks;
                for (let i = 0; i < newBtConnected.length; i++) {
                    let mac = newBtConnected[i].mac;
                    if (bt[mac]) {
                        newlyConnected = true;
                        delete bt[mac];
                        window.connectingId = "";
                    }
                }
                if (newlyConnected) {
                    window.playSfx("connect.wav");
                    window.busyTasks = Object.assign({}, bt);
                    if (Object.keys(window.busyTasks).length === 0 &&
                        Object.keys(window.disconnectingDevices).length === 0) {
                        busyTimeout.stop();
                    }
                }

                if (isNowBtConn || window.isWifiConn || window.isEthConn) {
                    window.updateInfoNodes();
                }
            }
        } catch(e) {}
        if (!isCache) validateActiveMode();
    }

    // =========================================================================
    // POLLER PROCESSES - Continuous system state monitoring
    // =========================================================================
    // Each poller runs a shell script that outputs JSON to stdout.
    // The JSON is cached in Settings for instant restoration on restart.
    // The adaptive timer manages polling frequency.

    Process {
        id: ethPoller
        command: ["bash", window.scriptsDir + "/eth_panel_logic.sh"]
        running: true  // Start immediately
        stdout: StdioCollector {
            onStreamFinished: {
                cache.lastEthJson = this.text.trim();  // Cache for next session
                processEthJson(cache.lastEthJson);      // Process the data
            }
        }
    }

    Process {
        id: wifiPoller
        command: ["bash", window.scriptsDir + "/wifi_panel_logic.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                cache.lastWifiJson = this.text.trim();
                processWifiJson(cache.lastWifiJson);
            }
        }
    }

    Process {
        id: btPoller
        command: ["bash",
            window.scriptsDir + "/bluetooth_panel_logic.sh", "--status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                cache.lastBtJson = this.text.trim();
                processBtJson(cache.lastBtJson);
            }
        }
    }

    // ADAPTIVE POLLING TIMER
    // When busy (connecting/disconnecting): poll every 1 second for responsive UI
    // When idle: poll every 3 seconds to reduce CPU usage
    // Always restarts pollers if they've stopped (error recovery)
    Timer {
        interval: (Object.keys(window.busyTasks).length > 0 ||
                   Object.keys(window.disconnectingDevices).length > 0) ? 1000 : 3000
        running: true
        repeat: true
        onTriggered: {
            if (!ethPoller.running) ethPoller.running = true;
            if (!wifiPoller.running) wifiPoller.running = true;
            if (!btPoller.running) btPoller.running = true;
        }
    }

    // =========================================================================
    // GLOBAL ORBIT ANGLE - Perpetual background rotation animation
    // =========================================================================
    // This single value drives all orbital motion in the UI.
    // It rotates from 0 to 2π (full circle) over 200,000 milliseconds.
    // 200,000ms = 200 seconds ≈ 3.33 minutes per full rotation
    //
    // Why so slow? It creates a barely-perceptible sense of life in the
    // background without being distracting. All orbiting elements multiply
    // this angle by different factors for varied motion speeds.
    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0
        to: Math.PI * 2
        duration: 200000           // 200 seconds for one full rotation
        loops: Animation.Infinite  // Never stops
        running: true              // Start immediately
    }

    // =========================================================================
    // INTRO ANIMATION STATE - Controls staggered entry of elements
    // =========================================================================
    // Used by core elements to delay their appearance until after the
    // initial data load. When set to 0.0, elements with 'enabled:
    // window.introState >= 1.0' won't animate their transitions.
    property real introState: 0.0
    Behavior on introState {
        NumberAnimation {
            duration: 1500             // 1.5 second intro
            easing.type: Easing.OutCubic  // Decelerating: fast start, slow finish
        }
    }

    // =========================================================================
    // LOADING DOTS COMPONENT - Animated "..." indicator
    // =========================================================================
    // Reusable component for showing a loading/processing state.
    // Three dots bounce in sequence with staggered timing.
    // Used in disconnecting states and wherever a wait indicator is needed.
    component LoadingDots : Row {
        spacing: window.s(5)           // Gap between dots
        property color dotCol: window.text  // Configurable color
        Repeater {
            model: 3  // Three dots
            Rectangle {
                width: window.s(6)     // Small circle
                height: window.s(6)
                radius: window.s(3)    // Half of width = perfect circle
                color: dotCol

                // Bouncing animation with per-dot stagger
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    // Stagger by index: dot 0 starts immediately,
                    // dot 1 waits 100ms, dot 2 waits 200ms
                    PauseAnimation { duration: index * 100 }

                    // Bounce UP: moves 6 scaled pixels upward over 250ms
                    // OutSine easing: starts fast, decelerates at peak
                    NumberAnimation {
                        from: 0
                        to: window.s(-6)  // Negative = upward in QML coordinates
                        duration: 250
                        easing.type: Easing.OutSine
                    }

                    // Bounce DOWN: returns to original position
                    // InSine easing: starts slow, accelerates (gravity-like)
                    NumberAnimation {
                        from: window.s(-6)
                        to: 0
                        duration: 250
                        easing.type: Easing.InSine
                    }

                    // Stagger pause: dot 2 waits 0ms, dot 1 waits 100ms,
                    // dot 0 waits 200ms (reverse of start stagger)
                    PauseAnimation { duration: (2 - index) * 100 }
                }
            }
        }
    }

    // =========================================================================
    // MAIN UI CONTAINER
    // =========================================================================
    Item {
        anchors.fill: parent

        // =====================================================================
        // BACKGROUND - Rounded rectangle with orbiting decorative circles
        // =====================================================================
        Rectangle {
            anchors.fill: parent
            radius: window.s(20)      // Consistent corner radius
            color: window.base         // Theme background
            border.color: window.surface0  // Subtle border for definition
            border.width: 1
            clip: true                 // Keep decorative circles inside bounds

            // -----------------------------------------------------------------
            // DECORATIVE ORBITING CIRCLES - Ambient background animation
            // -----------------------------------------------------------------
            // Two large semi-transparent circles that slowly orbit.
            // They're more visible when power is on, subtly indicating activity.
            // The orbit is driven by globalOrbitAngle with different multipliers
            // and directions for organic, non-mechanical motion.

            // Circle 1: 80% of parent width, orbits with cos/sin at 2x speed
            Rectangle {
                width: parent.width * 0.8
                height: width
                radius: width / 2  // Circle
                // X position: centered + cosine orbit at 150px amplitude
                x: (parent.width / 2 - width / 2) +
                   Math.cos(window.globalOrbitAngle * 2) * window.s(150)
                // Y position: centered + sine orbit at 100px amplitude
                y: (parent.height / 2 - height / 2) +
                   Math.sin(window.globalOrbitAngle * 2) * window.s(100)
                // More visible when powered on (8% vs 2%)
                opacity: window.currentPower ? 0.08 : 0.02
                // Color reflects connection state
                color: window.currentConn ? window.activeColor : window.surface2
                Behavior on color { ColorAnimation { duration: 1000 } }
                Behavior on opacity { NumberAnimation { duration: 1000 } }
                visible: opacity > 0.01  // Optimization: don't render near-invisible
            }

            // Circle 2: 90% of parent width, different orbit parameters
            Rectangle {
                width: parent.width * 0.9
                height: width
                radius: width / 2
                // Uses sin for X and cos for Y with negative amplitudes
                // This creates an orbit in the opposite direction
                x: (parent.width / 2 - width / 2) +
                   Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)
                y: (parent.height / 2 - height / 2) +
                   Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)
                opacity: window.currentPower ? 0.06 : 0.01
                color: window.currentConn ? window.activeGradientSecondary : window.surface1
                Behavior on color { ColorAnimation { duration: 1000 } }
                Behavior on opacity { NumberAnimation { duration: 1000 } }
                visible: opacity > 0.01
            }

            // -----------------------------------------------------------------
            // RADAR RINGS - Concentric circles indicating scanning/activity
            // -----------------------------------------------------------------
            // Three concentric rings centered in the orbit area.
            // When powered on, they're visible with subtle opacity.
            // When disconnecting, they turn red and thicken.
            Item {
                id: radarItem
                anchors.fill: parent
                anchors.bottomMargin: window.s(80)  // Leave space for bottom tabs
                opacity: window.currentPower ? 1.0 : 0.0
                scale: window.currentPower ? 1.0 : 1.05  // Slight shrink when off
                visible: opacity > 0.01
                Behavior on opacity {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.InOutQuad
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }

                Repeater {
                    model: 3  // Three rings
                    Rectangle {
                        anchors.centerIn: parent
                        // Each ring is larger: 280, 450, 620 (scaled)
                        width: window.s(280) + (index * window.s(170))
                        height: width
                        radius: width / 2
                        color: "transparent"  // Only border is visible

                        // Red when disconnecting, active color otherwise
                        border.color: Object.keys(window.disconnectingDevices).length > 0 ?
                            window.red : window.activeColor
                        // Thicker border when disconnecting (2 vs 1)
                        border.width: Object.keys(window.disconnectingDevices).length > 0 ?
                            window.s(2) : 1

                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on border.width { NumberAnimation { duration: 150 } }

                        // Outer rings are more transparent
                        // Connected: 0.08, 0.06, 0.04
                        // Disconnected: 0.03 for all
                        // Disconnecting: 0.2 for all
                        opacity: Object.keys(window.disconnectingDevices).length > 0 ?
                            0.2 :
                            (window.currentConn ?
                                0.08 - (index * 0.02) : 0.03)
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }
            }

            // -----------------------------------------------------------------
            // NODE LINES CANVAS - Procedural animated connections
            // -----------------------------------------------------------------
            // Uses HTML5 Canvas API for drawing animated "energy strands"
            // between core circles and their orbiting info/device nodes.
            // The animation uses two wave functions (sine and cosine at
            // different frequencies) to create organic, lightning-like lines.
            Canvas {
                id: nodeLinesCanvas
                anchors.fill: parent
                anchors.bottomMargin: window.s(80)
                z: 0  // Behind all other orbit elements
                opacity: (window.currentConn && window.showInfoView &&
                          window.currentPower) ? 1.0 : 0.0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 500 } }

                // Trigger repaint when scale changes (window resize)
                property real scaleTrigger: window.s(1)
                onScaleTriggerChanged: requestPaint()

                // Fast timer for procedural animation (~22 FPS)
                // This redraws the canvas frequently for smooth wave motion
                Timer {
                    id: lightningTimer
                    interval: 45  // ~22 frames per second
                    running: nodeLinesCanvas.opacity > 0.01 && window.currentPower
                    repeat: true
                    onTriggered: nodeLinesCanvas.requestPaint()
                }

                // Repaint when orbit angle changes (continuous motion)
                Connections {
                    target: window
                    function onGlobalOrbitAngleChanged() {
                        if (window.currentConn && window.showInfoView &&
                            window.currentPower) {
                            nodeLinesCanvas.requestPaint();
                        }
                    }
                }

                onPaint: {
                    var ctx = getContext("2d");  // Get 2D drawing context
                    var s = window.s;            // Scaling function
                    ctx.clearRect(0, 0, width, height);  // Clear previous frame

                    // Only draw if we have a connection and info view is showing
                    if (!window.currentConn || !window.showInfoView ||
                        !window.currentPower) return;

                    // Time-based animation parameters
                    // Date.now() / 1000 gives seconds with millisecond precision
                    var time = Date.now() / 1000;

                    ctx.lineJoin = "round";  // Smooth line corners
                    ctx.lineCap = "round";   // Smooth line ends

                    // Two wave phases at different speeds and directions
                    var tWave1 = time * 2.5;   // Faster wave
                    var tWave2 = time * -1.5;  // Slower, opposite direction

                    // Iterate through all orbit delegate items (info/dev cards)
                    for (var i = 0; i < orbitRepeater.count; i++) {
                        var item = orbitRepeater.itemAt(i);
                        if (!item || !item.isLoaded) continue;  // Skip unloaded

                        // Calculate center position of the target node
                        var targetX = item.x + item.width / 2;
                        var targetY = item.y + item.height / 2;

                        // Helper function to draw "energy strands" from
                        // a start point to this target node
                        function drawStrands(startX, startY, parentFade, parentWidth) {
                            // Vector from start to target
                            var dx = targetX - startX;
                            var dy = targetY - startY;
                            var fullDist = Math.sqrt(dx * dx + dy * dy);

                            if (fullDist < s(10)) return;  // Too close, skip

                            // Angle from start to target
                            var alpha = Math.atan2(dy, dx);
                            var cosA = Math.cos(alpha);
                            var sinA = Math.sin(alpha);

                            // Start drawing from just outside the core circle
                            var coreVisualRadius = parentWidth / 2;
                            var startOffset = coreVisualRadius + s(5);
                            // End drawing before the node center
                            var endOffset = s(35);

                            var drawDist = fullDist - startOffset - endOffset;
                            if (drawDist <= 0) return;  // No room to draw

                            var steps = 8;  // Number of line segments
                            // Perpendicular direction for wave offset
                            var perpX = -sinA;
                            var perpY = cosA;

                            // Actual start coordinates
                            var sX = startX + cosA * startOffset;
                            var sY = startY + sinA * startOffset;

                            // Distance factor: lines are more prominent when
                            // nodes are closer to their core
                            var distanceFactor = Math.max(0,
                                1.0 - (fullDist / 400.0));

                            // Dynamic styling based on distance
                            var dynamicLineWidthCore = s(1.0) +
                                (distanceFactor * s(2.0));
                            var dynamicLineWidthGlow = s(4.0) +
                                (distanceFactor * s(4.0));
                            var dynamicAlpha = (0.2 + (distanceFactor * 0.7)) *
                                parentFade;

                            // ---- PASS 1: Glow layer (wide, very transparent) ----
                            ctx.beginPath();
                            ctx.moveTo(sX, sY);
                            for (var j = 1; j <= steps; j++) {
                                var t = j / steps;  // Progress 0-1
                                var currentDist = drawDist * t;
                                // Envelope: 0 at start, 1 at middle, 0 at end
                                // Creates a tapered line that's thickest in the middle
                                var envelope = Math.sin(t * Math.PI);
                                // Wave offset + slight randomness for organic feel
                                var offset = Math.sin(tWave1 + t * 6) * s(6) *
                                    envelope +
                                    ((Math.random() - 0.5) * s(5.0) *
                                     distanceFactor);
                                ctx.lineTo(
                                    sX + cosA * currentDist + perpX * offset,
                                    sY + sinA * currentDist + perpY * offset
                                );
                            }
                            ctx.lineWidth = dynamicLineWidthGlow;
                            ctx.strokeStyle = window.activeColor;
                            ctx.globalAlpha = dynamicAlpha * 0.15;  // Very faint
                            ctx.stroke();

                            // ---- PASS 2: Core bright line ----
                            ctx.lineWidth = dynamicLineWidthCore;
                            ctx.strokeStyle = "#ffffff";  // White core
                            ctx.globalAlpha = dynamicAlpha;
                            ctx.stroke();  // Re-stroke the same path with new style

                            // ---- PASS 3: Secondary colored wave ----
                            // Uses a different wave function for visual complexity
                            ctx.beginPath();
                            ctx.moveTo(sX, sY);
                            for (var k = 1; k <= steps; k++) {
                                var tk = k / steps;
                                var currentDistK = drawDist * tk;
                                var envelopeK = Math.sin(tk * Math.PI);
                                // Different wave: cos instead of sin, larger amplitude
                                var offsetK = Math.cos(tWave2 + tk * 8) *
                                    s(12) * envelopeK +
                                    ((Math.random() - 0.5) * s(3.0) *
                                     distanceFactor);
                                ctx.lineTo(
                                    sX + cosA * currentDistK + perpX * offsetK,
                                    sY + sinA * currentDistK + perpY * offsetK
                                );
                            }
                            ctx.lineWidth = dynamicLineWidthCore * 1.5;
                            ctx.strokeStyle = window.activeColor;
                            ctx.globalAlpha = dynamicAlpha * 0.3;
                            ctx.stroke();
                        }

                        // Draw strands from appropriate core(s) to this node
                        if (item.myParentIdx === -1) {
                            // Root-level node: connect to ALL visible cores
                            for (var c = 0; c < coreRepeater.count; c++) {
                                var cItem = coreRepeater.itemAt(c);
                                if (cItem && cItem.activeTransition > 0.01) {
                                    drawStrands(
                                        cItem.x + cItem.width / 2,
                                        cItem.y + cItem.height / 2,
                                        cItem.activeTransition,
                                        cItem.width
                                    );
                                }
                            }
                        } else {
                            // Child node: connect only to its parent core
                            var pItem = coreRepeater.itemAt(item.myParentIdx);
                            if (pItem && pItem.activeTransition > 0.01) {
                                drawStrands(
                                    pItem.x + pItem.width / 2,
                                    pItem.y + pItem.height / 2,
                                    pItem.activeTransition,
                                    pItem.width
                                );
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // ORBIT CONTAINER - Parent for cores and floating cards
            // -----------------------------------------------------------------
            Item {
                id: orbitContainer
                anchors.fill: parent
                anchors.bottomMargin: window.s(80)
                z: 1  // Above canvas, below tabs

                // =============================================================
                // CORE REPEATER - 5 Core circle elements
                // =============================================================
                // These are the main circular elements representing connected
                // devices. They orbit when multiple are present, or center
                // when single. Each can show: scanning, connected, password
                // prompt, or disconnected states.
                Repeater {
                    id: coreRepeater
                    model: 5  // Always 5 slots (some may be hidden)

                    delegate: Item {
                        id: coreContainer

                        // ----- Core data binding -----
                        property var myDevice: window.currentCores[index]

                        // ----- State booleans -----
                        property bool isPrimary: index === 0
                        property bool hasDevice: myDevice !== null
                        // "Really active" means the core should be visible:
                        // power is on AND (has a device OR is the primary
                        // core with no other devices - shows scanning state)
                        property bool isReallyActive: window.currentPower &&
                            (hasDevice || (isPrimary &&
                             window.activeCoreCount === 0))

                        // ----- Active transition (visibility/fade) -----
                        property real activeTransition: isReallyActive ? 1.0 : 0.0
                        Behavior on activeTransition {
                            // Only animate after intro is complete
                            enabled: window.introState >= 1.0
                            NumberAnimation {
                                duration: 1400
                                easing.type: Easing.OutExpo
                                // OutExpo: very fast start, long deceleration tail
                            }
                        }

                        // ----- Multi-transition shift -----
                        // Only applies to Bluetooth (wifi/eth are always single)
                        property real multiShift: window.activeMode === "wifi" ||
                            window.activeMode === "eth" ?
                            0.0 : window.multiTransitionState

                        // ----- Core size -----
                        // Size decreases when:
                        // - In multi mode (multiShift > 0)
                        // - More than 2 active cores (each additional reduces size)
                        width: window.currentPower ?
                            (window.s(200) -
                             (window.s(30) * multiShift) -
                             (window.s(15) * Math.max(0,
                              window.smoothedActiveCoreCount - 2))) :
                            window.s(160)
                        height: width

                        // ----- Orbital position calculation -----
                        // Base angle: distributes cores evenly around the circle
                        // Uses coreVisualIndices for consistent ordering
                        property real myBaseAngle:
                            (window.coreVisualIndices[index] /
                             Math.max(1, window.activeCoreCount)) *
                            Math.PI * 2
                        property real animatedBaseAngle: myBaseAngle
                        Behavior on animatedBaseAngle {
                            NumberAnimation {
                                duration: 1000
                                easing.type: Easing.InOutExpo
                            }
                        }

                        // Final orbit angle: global rotation + base position
                        property real coreOrbitAngle:
                            window.globalOrbitAngle * 1.5 + animatedBaseAngle

                        // Orbit radius increases when more cores are active
                        property real myOrbitRadiusX:
                            window.s(180) +
                            (window.activeCoreCount > 2 ? window.s(20) : 0)
                        property real myOrbitRadiusY:
                            window.s(110) +
                            (window.activeCoreCount > 2 ? window.s(15) : 0)

                        // ----- Position -----
                        // Ethernet: always centered
                        // Others: orbital position based on angle and radius
                        // multiShift * activeTransition: only orbit when both
                        // multi mode is active AND this core is visible
                        x: window.activeMode === "eth" ?
                            (orbitContainer.width / 2 - width / 2) :
                            ((orbitContainer.width / 2 - width / 2) +
                             (Math.cos(coreOrbitAngle) * myOrbitRadiusX *
                              multiShift * activeTransition))
                        y: window.activeMode === "eth" ?
                            (orbitContainer.height / 2 - height / 2) :
                            ((orbitContainer.height / 2 - height / 2) +
                             (Math.sin(coreOrbitAngle) * myOrbitRadiusY *
                              multiShift * activeTransition))

                        // ----- Visual properties -----
                        opacity: activeTransition
                        scale: centralCore.bumpScale *
                            (0.8 + 0.2 * activeTransition)
                        visible: opacity > 0.01

                        // ----- Device identification -----
                        property string myId: myDevice ?
                            (window.activeMode === "wifi" ? myDevice.ssid :
                             (window.activeMode === "eth" ? myDevice.id :
                              myDevice.mac)) : "unknown"
                        property bool isMyDisconnecting:
                            !!window.disconnectingDevices[myId]

                        // ----- Display mode flags -----
                        // Scanning: primary core, power on, no connection,
                        // no pending password, not ethernet
                        property bool showScanning: isPrimary &&
                            window.currentPower && !window.currentConn &&
                            window.pendingWifiId === "" &&
                            window.activeMode !== "eth"
                        // Connected: has connection, this core has device,
                        // no pending password
                        property bool showConnected: window.currentConn &&
                            hasDevice && window.pendingWifiId === ""
                        // Password: primary core, pending WiFi password
                        property bool showPassword: isPrimary &&
                            window.pendingWifiId !== "" &&
                            window.activeMode === "wifi"
                        // Ethernet disconnected: primary, power on, no conn, eth mode
                        property bool showEthDisconnected: isPrimary &&
                            window.currentPower && !window.currentConn &&
                            window.activeMode === "eth"

                        // ----- Shadow effect -----
                        MultiEffect {
                            source: centralCore
                            anchors.fill: centralCore
                            shadowEnabled: true
                            shadowColor: "#000000"
                            shadowOpacity: window.currentPower ? 0.5 : 0.0
                            shadowBlur: 1.2
                            shadowVerticalOffset: window.s(6)
                            z: -1  // Behind the core
                            Behavior on shadowOpacity {
                                NumberAnimation { duration: 600 }
                            }
                        }

                        // ===== CENTRAL CORE RECTANGLE =====
                        Rectangle {
                            id: centralCore
                            anchors.fill: parent
                            radius: width / 2  // Perfect circle

                            // Disconnect fill animation state
                            property real disconnectFill: 0.0    // 0 to 1
                            property bool disconnectTriggered: false
                            property real flashOpacity: 0.0
                            property real bumpScale: 1.0
                            property bool isDangerState:
                                coreMa.containsMouse ||
                                disconnectFill > 0 ||
                                isMyDisconnecting

                            // Bump animation on disconnect
                            SequentialAnimation on bumpScale {
                                id: coreBumpAnim
                                running: false
                                NumberAnimation {
                                    to: 1.15
                                    duration: 200
                                    easing.type: Easing.OutBack
                                    // OutBack: overshoots slightly before settling
                                }
                                NumberAnimation {
                                    to: 1.0
                                    duration: 600
                                    easing.type: Easing.OutQuint
                                }
                            }

                            // ----- Gradient fill -----
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop {
                                    position: 0.0  // Top
                                    color: {
                                        if (!window.currentPower)
                                            return window.mantle;
                                        if (isMyDisconnecting)
                                            return window.surface0;
                                        if (centralCore.isDangerState &&
                                            window.currentConn && !showPassword)
                                            return Qt.lighter(window.red, 1.15);
                                        return window.currentConn || showPassword ?
                                            Qt.lighter(window.activeColor, 1.15) :
                                            window.surface0;
                                    }
                                    Behavior on color {
                                        ColorAnimation { duration: 300 }
                                    }
                                }
                                GradientStop {
                                    position: 1.0  // Bottom
                                    color: {
                                        if (!window.currentPower)
                                            return window.crust;
                                        if (isMyDisconnecting)
                                            return window.base;
                                        if (centralCore.isDangerState &&
                                            window.currentConn && !showPassword)
                                            return window.red;
                                        return window.currentConn || showPassword ?
                                            window.activeColor : window.base;
                                    }
                                    Behavior on color {
                                        ColorAnimation { duration: 300 }
                                    }
                                }
                            }

                            // ----- Border -----
                            border.color: {
                                if (!window.currentPower) return window.crust;
                                if (isMyDisconnecting) return window.surface0;
                                if (centralCore.isDangerState &&
                                    window.currentConn && !showPassword)
                                    return window.maroon;
                                return window.currentConn || showPassword ?
                                    Qt.lighter(window.activeColor, 1.1) :
                                    window.surface1;
                            }
                            border.width: window.s(2)
                            Behavior on border.color {
                                ColorAnimation { duration: 300 }
                            }

                            // ----- White flash overlay -----
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: "#ffffff"
                                opacity: centralCore.flashOpacity
                                PropertyAnimation on opacity {
                                    id: coreFlashAnim
                                    to: 0
                                    duration: 500
                                    easing.type: Easing.OutExpo
                                }
                            }

                            // ----- Wave fill canvas (disconnect animation) -----
                            Canvas {
                                id: coreWave
                                anchors.fill: parent
                                visible: centralCore.disconnectFill > 0
                                opacity: 0.95

                                property real scaleTrigger: window.s(1)
                                onScaleTriggerChanged: requestPaint()

                                property real wavePhase: 0.0
                                NumberAnimation on wavePhase {
                                    running: centralCore.disconnectFill > 0.0 &&
                                        centralCore.disconnectFill < 1.0
                                    loops: Animation.Infinite
                                    from: 0
                                    to: Math.PI * 2
                                    duration: 800
                                }
                                onWavePhaseChanged: requestPaint()
                                Connections {
                                    target: centralCore
                                    function onDisconnectFillChanged() {
                                        coreWave.requestPaint()
                                    }
                                }

                                onPaint: {
                                    var ctx = getContext("2d");
                                    var s = window.s;
                                    ctx.clearRect(0, 0, width, height);
                                    if (centralCore.disconnectFill <= 0.001) return;

                                    var r = width / 2;
                                    // Fill level from bottom: 1.0 = full, 0.0 = empty
                                    var fillY = height *
                                        (1.0 - centralCore.disconnectFill);

                                    ctx.save();
                                    // Clip to circle shape
                                    ctx.beginPath();
                                    ctx.arc(r, r, r, 0, 2 * Math.PI);
                                    ctx.clip();

                                    // Draw fill area with wavy top edge
                                    ctx.beginPath();
                                    ctx.moveTo(0, fillY);
                                    if (centralCore.disconnectFill < 0.99) {
                                        // Wavy top edge using bezier curve
                                        var waveAmp = s(10) *
                                            Math.sin(centralCore.disconnectFill *
                                                     Math.PI);
                                        var cp1y = fillY +
                                            Math.sin(wavePhase) * waveAmp;
                                        var cp2y = fillY +
                                            Math.cos(wavePhase + Math.PI) *
                                            waveAmp;
                                        ctx.bezierCurveTo(
                                            width * 0.33, cp2y,
                                            width * 0.66, cp1y,
                                            width, fillY
                                        );
                                        ctx.lineTo(width, height);
                                        ctx.lineTo(0, height);
                                    } else {
                                        // Almost full: just fill entirely
                                        ctx.lineTo(width, 0);
                                        ctx.lineTo(width, height);
                                        ctx.lineTo(0, height);
                                    }
                                    ctx.closePath();

                                    // Vertical gradient for the fill
                                    var grad = ctx.createLinearGradient(
                                        0, 0, 0, height);
                                    grad.addColorStop(0,
                                        window.surface1.toString());
                                    grad.addColorStop(1,
                                        window.crust.toString());
                                    ctx.fillStyle = grad;
                                    ctx.fill();
                                    ctx.restore();
                                }
                            }

                            // ----- Pulsing glow ring (behind core) -----
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + window.s(40)
                                height: width
                                radius: width / 2
                                color: centralCore.isDangerState &&
                                    window.currentConn && !showPassword ?
                                    window.red : window.activeColor
                                opacity: (window.currentConn || showPassword) &&
                                    !isMyDisconnecting ?
                                    (centralCore.isDangerState &&
                                     !showPassword ? 0.3 : 0.15) : 0.0
                                z: -1
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                                Behavior on opacity {
                                    NumberAnimation { duration: 300 }
                                }

                                // Continuous slow pulse
                                SequentialAnimation on scale {
                                    loops: Animation.Infinite
                                    running: window.currentConn || showPassword
                                    NumberAnimation {
                                        to: 1.1
                                        duration: 2000
                                        easing.type: Easing.InOutSine
                                    }
                                    NumberAnimation {
                                        to: 1.0
                                        duration: 2000
                                        easing.type: Easing.InOutSine
                                    }
                                }
                            }

                            // ----- Animated border ring -----
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + window.s(15)
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.color: centralCore.isDangerState &&
                                    !showPassword ? window.red :
                                    window.activeColor
                                border.width: window.s(3)
                                z: -2

                                property real pulseOp: 0.0
                                property real pulseSc: 1.0
                                opacity: ((window.currentConn || showPassword) &&
                                    window.showInfoView &&
                                    window.currentPower &&
                                    !isMyDisconnecting) ? pulseOp : 0.0
                                scale: pulseSc

                                // Fast pulse animation using timer
                                Timer {
                                    interval: 45  // ~22 fps
                                    running: parent.opacity > 0.01
                                    repeat: true
                                    onTriggered: {
                                        var time = Date.now() / 1000;
                                        parent.pulseOp = 0.3 +
                                            Math.sin(time * 2.5) * 0.15;
                                        parent.pulseSc = 1.02 +
                                            Math.cos(time * 3.0) * 0.02;
                                    }
                                }
                            }

                            // ===== SCANNING STATE =====
                            Item {
                                anchors.fill: parent
                                opacity: showScanning ? 1.0 : 0.0
                                visible: opacity > 0.01
                                Behavior on opacity {
                                    NumberAnimation { duration: 400 }
                                }

                                // Expanding search rings
                                Repeater {
                                    model: 3
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.4
                                        height: width
                                        radius: width / 2
                                        color: "transparent"
                                        border.color: window.activeColor
                                        border.width: window.s(2)

                                        // Staggered expansion
                                        SequentialAnimation on scale {
                                            running: showScanning
                                            loops: Animation.Infinite
                                            PauseAnimation {
                                                duration: index * 400
                                            }
                                            NumberAnimation {
                                                from: 1.0
                                                to: 2.5
                                                duration: 2000
                                                easing.type: Easing.OutSine
                                            }
                                        }
                                        // Staggered fade
                                        SequentialAnimation on opacity {
                                            running: showScanning
                                            loops: Animation.Infinite
                                            PauseAnimation {
                                                duration: index * 400
                                            }
                                            NumberAnimation {
                                                from: 0.8
                                                to: 0.0
                                                duration: 2000
                                                easing.type: Easing.OutSine
                                            }
                                        }
                                    }
                                }

                                // Mode-specific icon
                                Text {
                                    anchors.centerIn: parent
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: window.s(48) -
                                        (window.s(16) * coreContainer.multiShift)
                                    color: window.activeColor
                                    text: window.activeMode === "wifi" ?
                                        "󰤨" : (window.activeMode === "eth" ?
                                        "󰈀" : "󰂯")
                                    // Gentle breathing animation
                                    SequentialAnimation on opacity {
                                        running: showScanning
                                        loops: Animation.Infinite
                                        NumberAnimation {
                                            to: 0.5
                                            duration: 1000
                                            easing.type: Easing.InOutSine
                                        }
                                        NumberAnimation {
                                            to: 1.0
                                            duration: 1000
                                            easing.type: Easing.InOutSine
                                        }
                                    }
                                }
                            }

                            // ===== ETHERNET DISCONNECTED STATE =====
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: window.s(10)
                                visible: showEthDisconnected
                                opacity: visible ? 1.0 : 0.0
                                Behavior on opacity {
                                    NumberAnimation { duration: 300 }
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: window.s(48)
                                    color: window.overlay0
                                    text: "󰈂"  // Disconnected eth icon
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Bold
                                    font.pixelSize: window.s(14)
                                    color: window.overlay0
                                    text: window.currentPowerPending ?
                                        (window.expectedEthPower === "on" ?
                                         "Powering On..." : "Powering Off...") :
                                        "Disconnected"
                                }
                            }

                            // ===== PASSWORD INPUT LAYER =====
                            Item {
                                id: pwdLayer
                                anchors.fill: parent
                                opacity: showPassword ? 1.0 : 0.0
                                visible: opacity > 0.01
                                scale: showPassword ? 1.0 : 0.8
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 400
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 1.5
                                        // OutBack with overshoot creates a
                                        // bouncy, spring-like entrance
                                    }
                                }
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutSine
                                    }
                                }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: window.s(8)

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: window.s(32)
                                        color: window.crust
                                        text: "󰤨"  // Lock icon
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.maximumWidth: pwdLayer.width -
                                            window.s(40)
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                        font.pixelSize: window.s(13)
                                        color: window.crust
                                        text: window.pendingWifiSsid
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredWidth: pwdLayer.width -
                                            window.s(40)
                                        height: window.s(36)
                                        radius: window.s(18)  // Pill shape
                                        color: window.surface0
                                        border.color: wifiPasswordField.activeFocus ?
                                            window.crust : "transparent"
                                        border.width: 1
                                        Behavior on border.color {
                                            ColorAnimation { duration: 200 }
                                        }

                                        TextInput {
                                            id: wifiPasswordField
                                            anchors.fill: parent
                                            anchors.leftMargin: window.s(15)
                                            anchors.rightMargin: window.s(15)
                                            verticalAlignment: TextInput.AlignVCenter
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: window.s(13)
                                            color: window.text
                                            echoMode: TextInput.Password
                                            // Password mode: shows dots instead of characters
                                            clip: true
                                            onAccepted: {
                                                // Enter key: submit password
                                                if (text.trim() !== "") {
                                                    window.connectDevice(
                                                        window.activeMode,
                                                        window.pendingWifiId,
                                                        window.pendingWifiSsid,
                                                        text
                                                    );
                                                    window.pendingWifiId = "";
                                                    window.pendingWifiSsid = "";
                                                    text = "";
                                                    window.forceActiveFocus();
                                                }
                                            }
                                            Keys.onEscapePressed: {
                                                // Escape key: cancel
                                                window.pendingWifiId = "";
                                                window.pendingWifiSsid = "";
                                                text = "";
                                                window.forceActiveFocus();
                                            }
                                        }
                                    }
                                }

                                // Delay focus by 50ms to ensure the TextInput
                                // is fully constructed before focusing
                                Timer {
                                    id: deferFocusTimer
                                    interval: 50
                                    onTriggered: wifiPasswordField.forceActiveFocus()
                                }
                                onVisibleChanged: {
                                    if (visible) {
                                        wifiPasswordField.text = "";
                                        deferFocusTimer.start();
                                    }
                                }
                            }

                            // ===== CONNECTED STATE =====
                            Item {
                                anchors.fill: parent
                                opacity: showConnected ? 1.0 : 0.0
                                visible: opacity > 0.01
                                scale: showConnected ? 1.0 : 0.95
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 400
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 1.2
                                    }
                                }
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutSine
                                    }
                                }

                                // Normal text layer
                                ColumnLayout {
                                    id: baseCoreText
                                    anchors.centerIn: parent
                                    spacing: window.s(4)

                                    // Device icon
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: window.s(48) -
                                            (window.s(16) *
                                             coreContainer.multiShift)
                                        color: isMyDisconnecting ?
                                            window.overlay1 : window.crust
                                        // Show disconnect icon on hover
                                        text: isMyDisconnecting ? "" :
                                            (coreMa.containsMouse ?
                                                (window.activeMode === "wifi" ?
                                                 "󰖪" :  // Disconnect wifi
                                                 (window.activeMode === "eth" ?
                                                  "󰈂" :   // Disconnect eth
                                                  "󰂲")) :  // Disconnect bt
                                                (coreContainer.myDevice ?
                                                    (coreContainer.myDevice.icon ||
                                                     (window.activeMode === "wifi" ?
                                                      "󰤨" :
                                                      (window.activeMode === "eth" ?
                                                       "󰈀" : "󰂯"))) : ""))
                                        Behavior on color {
                                            ColorAnimation { duration: 200 }
                                        }
                                    }

                                    // Loading dots for disconnecting
                                    LoadingDots {
                                        Layout.alignment: Qt.AlignHCenter
                                        visible: isMyDisconnecting
                                        dotCol: window.overlay1
                                    }

                                    // Device name
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.maximumWidth: window.s(150) -
                                            (window.s(50) *
                                             coreContainer.multiShift)
                                        horizontalAlignment: Text.AlignHCenter
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Black
                                        font.pixelSize: window.s(16) -
                                            (window.s(4) *
                                             coreContainer.multiShift)
                                        color: isMyDisconnecting ?
                                            window.overlay1 : window.crust
                                        text: coreContainer.myDevice ?
                                            (window.activeMode === "wifi" ?
                                             coreContainer.myDevice.ssid :
                                             coreContainer.myDevice.name) : ""
                                        elide: Text.ElideRight
                                        Behavior on color {
                                            ColorAnimation { duration: 200 }
                                        }
                                    }

                                    // Status text (Connected / Hold... / Disconnecting...)
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                        font.pixelSize: window.s(11)
                                        color: isMyDisconnecting ?
                                            window.overlay1 :
                                            (coreMa.containsMouse ?
                                             window.crust : "#99000000")
                                        // "#99000000" = 60% transparent black
                                        text: isMyDisconnecting ?
                                            "Disconnecting..." :
                                            (centralCore.disconnectFill > 0.01 ?
                                             "Hold..." : "Connected")
                                        Behavior on color {
                                            ColorAnimation { duration: 200 }
                                        }
                                    }
                                }

                                // Wave clip overlay (fills from bottom during disconnect hold)
                                Item {
                                    id: waveClipItem
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: Math.min(parent.height,
                                        Math.max(0, parent.height *
                                                 centralCore.disconnectFill +
                                                 window.s(8)))
                                    clip: true
                                    visible: centralCore.disconnectFill > 0

                                    // Duplicate text with inverted colors (white on fill)
                                    ColumnLayout {
                                        spacing: window.s(4)
                                        // Position to align with baseCoreText
                                        x: waveClipItem.width / 2 - width / 2
                                        y: (centralCore.height / 2) -
                                            (height / 2) -
                                            (centralCore.height -
                                             waveClipItem.height)

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: window.s(48) -
                                                (window.s(16) *
                                                 coreContainer.multiShift)
                                            color: window.text
                                            text: isMyDisconnecting ? "" :
                                                (coreMa.containsMouse ?
                                                    (window.activeMode === "wifi" ?
                                                     "󰖪" :
                                                     (window.activeMode === "eth" ?
                                                      "󰈂" : "󰂲")) :
                                                    (coreContainer.myDevice ?
                                                        (coreContainer.myDevice.icon ||
                                                         (window.activeMode === "wifi" ?
                                                          "󰤨" :
                                                          (window.activeMode === "eth" ?
                                                           "󰈀" : "󰂯"))) : ""))
                                        }
                                        LoadingDots {
                                            Layout.alignment: Qt.AlignHCenter
                                            visible: isMyDisconnecting
                                            dotCol: window.text
                                        }
                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.maximumWidth: window.s(150) -
                                                (window.s(50) *
                                                 coreContainer.multiShift)
                                            horizontalAlignment: Text.AlignHCenter
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Black
                                            font.pixelSize: window.s(16) -
                                                (window.s(4) *
                                                 coreContainer.multiShift)
                                            color: window.text
                                            text: coreContainer.myDevice ?
                                                (window.activeMode === "wifi" ?
                                                 coreContainer.myDevice.ssid :
                                                 coreContainer.myDevice.name) : ""
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Bold
                                            font.pixelSize: window.s(11)
                                            color: window.text
                                            text: isMyDisconnecting ?
                                                "Disconnecting..." :
                                                (centralCore.disconnectFill > 0.01 ?
                                                 "Hold..." : "Connected")
                                        }
                                    }
                                }
                            }

                            // ===== MOUSE AREA (HOLD TO DISCONNECT) =====
                            MouseArea {
                                id: coreMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: window.currentConn &&
                                    !isMyDisconnecting && !showPassword ?
                                    Qt.PointingHandCursor : Qt.ArrowCursor

                                onPressed: {
                                    // Only start fill if connected and not
                                    // already disconnecting or in password mode
                                    if (window.currentConn &&
                                        !isMyDisconnecting &&
                                        !centralCore.disconnectTriggered &&
                                        !showPassword) {
                                        coreDrainAnim.stop();
                                        coreFillAnim.start();
                                    }
                                }
                                onReleased: {
                                    // Drain if released before trigger
                                    if (!centralCore.disconnectTriggered &&
                                        !isMyDisconnecting && !showPassword) {
                                        coreFillAnim.stop();
                                        coreDrainAnim.start();
                                    }
                                }
                            }

                            // Fill animation: hold to fill the core
                            NumberAnimation {
                                id: coreFillAnim
                                target: centralCore
                                property: "disconnectFill"
                                to: 1.0
                                // Duration scales with remaining fill:
                                // Empty -> 700ms, Half -> 350ms
                                duration: 700 * (1.0 - centralCore.disconnectFill)
                                easing.type: Easing.InSine
                                onFinished: {
                                    // If mouse was released during fill, reset
                                    if (!coreMa.pressed) {
                                        centralCore.disconnectFill = 0.0;
                                        return;
                                    }

                                    // TRIGGER DISCONNECT
                                    centralCore.disconnectTriggered = true;
                                    centralCore.flashOpacity = 0.6;
                                    cardFlashAnim.start();   // White flash
                                    coreBumpAnim.start();    // Bump animation

                                    window.playSfx("disconnect.wav");

                                    // Mark as disconnecting
                                    let dd = window.disconnectingDevices;
                                    dd[coreContainer.myId] = true;
                                    window.disconnectingDevices =
                                        Object.assign({}, dd);
                                    busyTimeout.restart();

                                    // Build and execute disconnect command
                                    let cmd = "";
                                    if (window.activeMode === "eth") {
                                        cmd = "nmcli device disconnect '" +
                                            coreContainer.myId + "'";
                                    } else if (window.activeMode === "wifi") {
                                        cmd = "nmcli device disconnect " +
                                            "$(nmcli -t -f DEVICE,TYPE d | " +
                                            "grep wifi | cut -d: -f1 | head -n1)";
                                    } else {
                                        cmd = "bash " + window.scriptsDir +
                                            "/bluetooth_panel_logic.sh " +
                                            "--disconnect '" +
                                            coreContainer.myId + "'";
                                    }
                                    Quickshell.execDetached(["sh", "-c", cmd]);

                                    // Reset visual state
                                    centralCore.disconnectFill = 0.0;
                                    centralCore.disconnectTriggered = false;

                                    // Refresh poller
                                    if (window.activeMode === "eth")
                                        ethPoller.running = true;
                                    else if (window.activeMode === "wifi")
                                        wifiPoller.running = true;
                                    else btPoller.running = true;
                                }
                            }

                            // Drain animation: fill returns to 0 on release
                            NumberAnimation {
                                id: coreDrainAnim
                                target: centralCore
                                property: "disconnectFill"
                                to: 0.0
                                // Duration proportional to current fill:
                                // Full -> 1000ms, Half -> 500ms
                                duration: 1000 * centralCore.disconnectFill
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }

                // =============================================================
                // FLOATING CARDS CONTAINER - Visible when powered on
                // =============================================================
                Item {
                    anchors.fill: parent
                    opacity: window.currentPower ? 1.0 : 0.0
                    visible: opacity > 0.01
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 600
                            easing.type: Easing.InOutQuad
                        }
                    }

                    // =========================================================
                    // ORBIT REPEATER - WiFi/BT devices or Info nodes
                    // =========================================================
                    // Model switches based on current view state:
                    // - Info view showing: infoListModel
                    // - WiFi mode: wifiListModel
                    // - BT mode: btListModel
                    Repeater {
                        id: orbitRepeater
                        model: (window.currentConn && window.showInfoView) ?
                            infoListModel :
                            (window.activeMode === "wifi" ?
                             wifiListModel :
                             (window.activeMode === "bt" ? btListModel : null))

                        delegate: Item {
                            id: floatCardDelegateContainer
                            width: window.s(170)
                            height: window.s(60)

                            // ---- Loaded state (staggered animation) ----
                            property bool isLoaded: false
                            opacity: isLoaded ? 1.0 : 0.0
                            visible: opacity > 0.01
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.OutQuint
                                }
                            }

                            property real entryAnim: isLoaded ? 1.0 : 0.0
                            Behavior on entryAnim {
                                NumberAnimation {
                                    duration: 600
                                    easing.type: Easing.OutBack
                                }
                            }

                            // Staggered loading timer
                            Timer {
                                running: true
                                interval: window.activeMode === "eth" ?
                                    (600 + (index * 80)) :
                                    (40 + (index * 30))
                                onTriggered: floatCardDelegateContainer.isLoaded = true
                            }

                            // ---- Parent core relationship ----
                            property int myParentIdx: model.parentIndex !== undefined ?
                                model.parentIndex : -1

                            // Count how many siblings share the same parent
                            property int siblingsCount: {
                                let c = 0;
                                let m = orbitRepeater.model;
                                if (m && m.count !== undefined) {
                                    for (let i = 0; i < m.count; i++) {
                                        let d = m.get(i);
                                        if (d && (d.parentIndex !== undefined ?
                                                  d.parentIndex : -1) ===
                                            myParentIdx) c++;
                                    }
                                }
                                return Math.max(1, c);
                            }

                            // Local index among siblings
                            property int localIndex: {
                                let idx = 0;
                                let m = orbitRepeater.model;
                                if (m && m.count !== undefined) {
                                    for (let i = 0; i < index; i++) {
                                        let d = m.get(i);
                                        if (d && (d.parentIndex !== undefined ?
                                                  d.parentIndex : -1) ===
                                            myParentIdx) idx++;
                                    }
                                }
                                return idx;
                            }

                            // ---- Orbital positioning ----
                            // unifiedRatio: 0 = single layout, 1 = multi layout
                            property real unifiedRatio:
                                window.activeMode === "wifi" ||
                                window.activeMode === "eth" ?
                                0.0 : window.multiTransitionState

                            // How many items in the current ring
                            property real activeCount:
                                (unifiedRatio > 0.5 && myParentIdx !== -1) ?
                                siblingsCount : orbitRepeater.count

                            // Scale down when many items
                            property real dynamicScale:
                                activeCount > 10 ?
                                Math.max(0.6, 12.0 / activeCount) :
                                (unifiedRatio > 0.5 ?
                                    (window.activeCoreCount > 2 ? 0.7 : 0.8) :
                                    1.0)

                            property real safeMultiShift:
                                window.activeMode === "wifi" ||
                                window.activeMode === "eth" ?
                                0.0 : window.multiTransitionState

                            property var pItem: myParentIdx !== -1 ?
                                coreRepeater.itemAt(myParentIdx) : null

                            // Parent core position
                            property real parentX: pItem ?
                                (orbitContainer.width / 2) +
                                (Math.cos(parentCoreAngle) *
                                 pItem.myOrbitRadiusX *
                                 safeMultiShift *
                                 pItem.activeTransition) :
                                (orbitContainer.width / 2)
                            property real parentY: pItem ?
                                (orbitContainer.height / 2) +
                                (Math.sin(parentCoreAngle) *
                                 pItem.myOrbitRadiusY *
                                 safeMultiShift *
                                 pItem.activeTransition) :
                                (orbitContainer.height / 2)

                            property real parentBaseAngle:
                                pItem ? pItem.animatedBaseAngle : 0

                            // Single mode: evenly distributed around full circle
                            property real targetSingleBaseAngle:
                                (index / Math.max(1, orbitRepeater.count)) *
                                Math.PI * 2
                            property real singleBaseAngle: targetSingleBaseAngle
                            Behavior on singleBaseAngle {
                                NumberAnimation {
                                    duration: 800
                                    easing.type: Easing.OutExpo
                                }
                            }

                            property real singleLiveAngle:
                                (window.globalOrbitAngle * 1.5) + singleBaseAngle

                            // Multi mode: children spread in an arc around parent
                            property real arcSpread: Math.PI * 0.8  // 144 degrees
                            property real targetNodeOffset:
                                (siblingsCount > 1) ?
                                ((localIndex / (siblingsCount - 1)) - 0.5) *
                                arcSpread : 0
                            property real nodeOffset: targetNodeOffset
                            Behavior on nodeOffset {
                                NumberAnimation {
                                    duration: 800
                                    easing.type: Easing.OutExpo
                                }
                            }

                            property real parentCoreAngle:
                                (window.globalOrbitAngle * 1.5) + parentBaseAngle
                            property real multiLiveAngle:
                                myParentIdx === -1 ?
                                singleLiveAngle :
                                (parentCoreAngle + nodeOffset)

                            // Ring system: info nodes inner, devices outer
                            property int ringIndex: isInfoNode ? 0 : index % 2
                            property real targetRingOffset:
                                ringIndex * window.s(40)
                            property real ringOffset: targetRingOffset
                            Behavior on ringOffset {
                                NumberAnimation {
                                    duration: 800
                                    easing.type: Easing.OutExpo
                                }
                            }

                            // Orbit radii
                            property real singleRadX: isInfoNode ?
                                window.s(280) : window.s(320) + ringOffset
                            property real singleRadY: isInfoNode ?
                                window.s(180) : window.s(200) + ringOffset

                            property real multiRadX: isInfoNode ?
                                (myParentIdx === -1 ? 0 :
                                 (window.activeCoreCount > 2 ?
                                  window.s(180) : window.s(160))) :
                                window.s(340) + ringOffset
                            property real multiRadY: isInfoNode ?
                                (myParentIdx === -1 ? 0 :
                                 (window.activeCoreCount > 2 ?
                                  window.s(180) : window.s(160))) :
                                window.s(240) + ringOffset

                            // Interpolated radii and angle
                            property real currentRadX:
                                window.activeMode === "eth" ?
                                window.s(280) :
                                ((singleRadX * (1 - unifiedRatio)) +
                                 (multiRadX * unifiedRatio))
                            property real currentRadY:
                                window.activeMode === "eth" ?
                                window.s(180) :
                                ((singleRadY * (1 - unifiedRatio)) +
                                 (multiRadY * unifiedRatio))
                            property real currentAngle:
                                (singleLiveAngle * (1 - unifiedRatio)) +
                                (multiLiveAngle * unifiedRatio)

                            // Power-off drift: cards slide outward when power off
                            property real pwrDrift:
                                window.currentPower ? 0 : window.s(40)
                            Behavior on pwrDrift {
                                NumberAnimation {
                                    duration: 600
                                    easing.type: Easing.OutQuint
                                }
                            }

                            // Entry animation affects effective radius
                            property real animRadX:
                                (currentRadX + pwrDrift) *
                                (0.25 + 0.75 * entryAnim)
                            property real animRadY:
                                (currentRadY + pwrDrift) *
                                (0.25 + 0.75 * entryAnim)

                            // Final position
                            property real targetX: myParentIdx === -1 ?
                                (orbitContainer.width / 2) - (width / 2) +
                                Math.cos(currentAngle) * animRadX :
                                parentX - (width / 2) +
                                Math.cos(currentAngle) * animRadX

                            property real targetY: myParentIdx === -1 ?
                                (orbitContainer.height / 2) - (height / 2) +
                                Math.sin(currentAngle) * animRadY :
                                parentY - (height / 2) +
                                Math.sin(currentAngle) * animRadY

                            // Subtle bobbing for root info nodes
                            property real liveBob:
                                myParentIdx === -1 && isInfoNode ?
                                Math.sin(window.globalOrbitAngle * 6) *
                                window.s(12) * (1 - unifiedRatio) : 0

                            x: targetX
                            y: targetY + liveBob

                            // Scale: 0 unloaded, 0.95 pressed, 1.08 hovered
                            scale: (!isLoaded ? 0.0 :
                                    (floatMa.pressed ? dynamicScale * 0.95 :
                                     (floatCard.locksList ?
                                      dynamicScale * 1.08 : dynamicScale))) *
                                   floatCard.bumpScale
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.OutQuart
                                }
                            }
                            z: floatCard.locksList ? 10 : index
                            // Raised z-index when hovered for shadow clarity

                            // ---- Shadow ----
                            MultiEffect {
                                source: floatCard
                                anchors.fill: floatCard
                                shadowEnabled: window.currentPower &&
                                    floatCardDelegateContainer.opacity > 0.05
                                shadowColor: "#000000"
                                shadowOpacity: 0.3
                                shadowBlur: 0.8
                                shadowVerticalOffset: window.s(4)
                                z: -1
                            }

                            // ===== FLOATING CARD =====
                            Rectangle {
                                id: floatCard
                                anchors.fill: parent
                                radius: window.s(14)

                                // ---- Card identity ----
                                property string itemId: id
                                property string itemName: name

                                // ---- State flags ----
                                property bool isMyBusy:
                                    window.connectingId === itemId ||
                                    !!window.busyTasks[itemId]
                                property bool isFailed:
                                    window.failedId === itemId
                                property bool isPairedBT:
                                    window.activeMode === "bt" &&
                                    action === "Connect"
                                property bool isTargetWifi:
                                    window.activeMode === "wifi" &&
                                    !window.isWifiConn &&
                                    itemId === window.targetWifiSsid
                                property bool isSpecialAction:
                                    itemId === "action_scan" ||
                                    itemId === "action_settings"
                                property bool isHighlighted:
                                    isPairedBT || isTargetWifi || isSpecialAction

                                property bool isCurrentlyConnected: {
                                    if (window.activeMode === "eth")
                                        return (window.ethConnected &&
                                                window.ethConnected.id === itemId);
                                    if (window.activeMode === "wifi")
                                        return (window.wifiConnected &&
                                                window.wifiConnected.ssid === itemId);
                                    for (let i = 0; i < window.btConnected.length; i++) {
                                        if (window.btConnected[i].mac === itemId)
                                            return true;
                                    }
                                    return false;
                                }

                                property bool isInteractable:
                                    !isInfoNode || isActionable

                                // ---- List locking ----
                                property bool locksList:
                                    isInteractable &&
                                    (floatMa.containsMouse || floatMa.pressed)
                                onLocksListChanged: {
                                    if (locksList)
                                        window.hoveredCardCount++;
                                    else
                                        window.hoveredCardCount--;
                                }
                                Component.onDestruction: {
                                    if (locksList) window.hoveredCardCount--;
                                }

                                property real bumpScale: 1.0
                                SequentialAnimation on bumpScale {
                                    id: cardBumpAnim
                                    running: false
                                    NumberAnimation {
                                        to: 1.2; duration: 200
                                        easing.type: Easing.OutBack
                                    }
                                    NumberAnimation {
                                        to: 1.0; duration: 600
                                        easing.type: Easing.OutQuint
                                    }
                                }

                                // ---- Marquee for long names ----
                                property real nameImplicitWidth:
                                    baseNameText.implicitWidth
                                property real nameContainerWidth:
                                    nameContainerBase.width
                                property bool doMarquee:
                                    floatMa.containsMouse &&
                                    nameImplicitWidth > nameContainerWidth
                                property real textOffset: 0

                                SequentialAnimation on textOffset {
                                    running: floatCard.doMarquee
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: 600 }
                                    NumberAnimation {
                                        from: 0
                                        to: -(floatCard.nameImplicitWidth +
                                              window.s(30))
                                        duration: (floatCard.nameImplicitWidth +
                                                   window.s(30)) * 35
                                    }
                                }
                                onDoMarqueeChanged: {
                                    if (!doMarquee) textOffset = 0;
                                }

                                // ---- Hold-to-connect fill state ----
                                property real fillLevel: 0.0
                                property bool triggered: false
                                property real flashOpacity: 0.0
                                property real renderFill:
                                    (isCurrentlyConnected) ? 1.0 : fillLevel

                                onIsFailedChanged: {
                                    if (isFailed) {
                                        triggered = false;
                                        drainAnim.start();
                                    }
                                }

                                Connections {
                                    target: window
                                    function onPendingWifiIdChanged() {
                                        if (window.pendingWifiId === "" &&
                                            floatCard.fillLevel > 0 &&
                                            !floatCard.isMyBusy &&
                                            !floatCard.isCurrentlyConnected) {
                                            floatCard.triggered = false;
                                            drainAnim.start();
                                        }
                                    }
                                }

                                // ---- Background ----
                                color: locksList ? "#2affffff" : "#0effffff"
                                // "#2affffff" = ~16% white (hovered)
                                // "#0effffff" = ~5% white (default)
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }

                                // ---- Red overlay for failed ----
                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: window.red
                                    opacity: floatCard.isFailed ? 0.3 : 0.0
                                    Behavior on opacity {
                                        NumberAnimation { duration: 300 }
                                    }
                                }

                                // ---- Default border ----
                                Rectangle {
                                    anchors.fill: parent
                                    radius: window.s(14)
                                    color: "transparent"
                                    border.width: 1
                                    border.color: floatCard.isFailed ?
                                        window.red : window.surface2
                                    visible: !isHighlighted && !locksList
                                    Behavior on border.color {
                                        ColorAnimation { duration: 300 }
                                    }
                                }

                                // ---- Highlighted border with gradient ----
                                Rectangle {
                                    anchors.fill: parent
                                    radius: window.s(14)
                                    opacity: locksList || isHighlighted ? 1.0 : 0.0
                                    color: "transparent"
                                    border.width: isHighlighted && !locksList ?
                                        1 : window.s(2)
                                    border.color: floatCard.isFailed ?
                                        window.red : "transparent"
                                    Behavior on opacity {
                                        NumberAnimation { duration: 250 }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: isHighlighted && !locksList ?
                                            1 : window.s(2)
                                        radius: window.s(12)
                                        color: window.base
                                        opacity: locksList ? 0.9 : 1.0
                                    }

                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop {
                                            position: 0.0
                                            color: floatCard.isFailed ?
                                                Qt.lighter(window.red, 1.15) :
                                                Qt.lighter(window.activeColor, 1.15)
                                        }
                                        GradientStop {
                                            position: 1.0
                                            color: floatCard.isFailed ?
                                                window.red : window.activeColor
                                        }
                                    }
                                    z: -1
                                }

                                // ---- White flash ----
                                Rectangle {
                                    anchors.fill: parent
                                    radius: window.s(14)
                                    color: "#ffffff"
                                    opacity: floatCard.flashOpacity
                                    PropertyAnimation on opacity {
                                        id: cardFlashAnim
                                        to: 0
                                        duration: 500
                                        easing.type: Easing.OutExpo
                                    }
                                    z: 5
                                }

                                // ---- Wave fill canvas ----
                                Canvas {
                                    id: waveCanvas
                                    anchors.fill: parent

                                    property real scaleTrigger: window.s(1)
                                    onScaleTriggerChanged: requestPaint()

                                    property real wavePhase: 0.0
                                    NumberAnimation on wavePhase {
                                        running: floatCard.renderFill > 0.0 &&
                                            floatCard.renderFill < 1.0
                                        loops: Animation.Infinite
                                        from: 0; to: Math.PI * 2
                                        duration: 800
                                    }
                                    onWavePhaseChanged: requestPaint()
                                    Connections {
                                        target: floatCard
                                        function onRenderFillChanged() {
                                            waveCanvas.requestPaint()
                                        }
                                    }

                                    onPaint: {
                                        var ctx = getContext("2d");
                                        var s = window.s;
                                        ctx.clearRect(0, 0, width, height);
                                        if (floatCard.renderFill <= 0.001) return;

                                        var currentW = width * floatCard.renderFill;
                                        var r = s(14);

                                        ctx.save();
                                        ctx.beginPath();
                                        ctx.moveTo(0, 0);

                                        if (floatCard.renderFill < 0.99) {
                                            var waveAmp = s(12) *
                                                Math.sin(floatCard.renderFill *
                                                         Math.PI);
                                            if (currentW - waveAmp < 0)
                                                waveAmp = currentW;
                                            var cp1x = currentW +
                                                Math.sin(wavePhase) * waveAmp;
                                            var cp2x = currentW +
                                                Math.cos(wavePhase + Math.PI) *
                                                waveAmp;
                                            ctx.lineTo(currentW, 0);
                                            ctx.bezierCurveTo(
                                                cp2x, height * 0.33,
                                                cp1x, height * 0.66,
                                                currentW, height
                                            );
                                            ctx.lineTo(0, height);
                                        } else {
                                            ctx.lineTo(width, 0);
                                            ctx.lineTo(width, height);
                                            ctx.lineTo(0, height);
                                        }
                                        ctx.closePath();
                                        ctx.clip();

                                        ctx.beginPath();
                                        ctx.moveTo(r, 0);
                                        ctx.lineTo(width - r, 0);
                                        ctx.arcTo(width, 0, width, r, r);
                                        ctx.lineTo(width, height - r);
                                        ctx.arcTo(width, height,
                                                 width - r, height, r);
                                        ctx.lineTo(r, height);
                                        ctx.arcTo(0, height, 0, height - r, r);
                                        ctx.lineTo(0, r);
                                        ctx.arcTo(0, 0, r, 0, r);
                                        ctx.closePath();

                                        var grad = ctx.createLinearGradient(
                                            0, 0, currentW, 0);
                                        grad.addColorStop(0,
                                            Qt.lighter(window.activeColor, 1.15)
                                            .toString());
                                        grad.addColorStop(1,
                                            window.activeColor.toString());
                                        ctx.fillStyle = grad;
                                        ctx.fill();
                                        ctx.restore();
                                    }
                                }

                                // ---- Pulsing highlight ring ----
                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: "transparent"
                                    border.color: window.activeColor
                                    border.width: window.s(2)
                                    visible: parent.isHighlighted &&
                                        !parent.isMyBusy &&
                                        !parent.isCurrentlyConnected &&
                                        !parent.isFailed

                                    SequentialAnimation on scale {
                                        loops: Animation.Infinite
                                        running: parent.visible
                                        NumberAnimation {
                                            to: 1.15; duration: 1200
                                            easing.type: Easing.InOutSine
                                        }
                                        NumberAnimation {
                                            to: 1.0; duration: 1200
                                            easing.type: Easing.InOutSine
                                        }
                                    }
                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        running: parent.visible
                                        NumberAnimation {
                                            to: 0.0; duration: 1200
                                            easing.type: Easing.InOutSine
                                        }
                                        NumberAnimation {
                                            to: 0.8; duration: 1200
                                            easing.type: Easing.InOutSine
                                        }
                                    }
                                }

                                // ---- Base text row ----
                                RowLayout {
                                    id: baseTextRow
                                    anchors.fill: parent
                                    anchors.margins: window.s(12)
                                    spacing: window.s(10)

                                    Text {
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: window.s(20)
                                        color: floatCard.isFailed ?
                                            window.red :
                                            (floatCard.isMyBusy ?
                                             window.text : window.activeColor)
                                        text: icon
                                        Behavior on color {
                                            ColorAnimation { duration: 200 }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: window.s(2)

                                        Item {
                                            id: nameContainerBase
                                            Layout.fillWidth: true
                                            height: window.s(18)
                                            clip: true

                                            Text {
                                                id: baseNameText
                                                anchors.left: parent.left
                                                anchors.leftMargin: floatCard.textOffset
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: floatCard.itemName
                                                font.family: "JetBrains Mono"
                                                font.weight: Font.Bold
                                                font.pixelSize: window.s(13)
                                                color: floatCard.isFailed ?
                                                    window.red :
                                                    (floatCard.isHighlighted ?
                                                     window.activeColor : window.text)
                                                Behavior on color {
                                                    ColorAnimation { duration: 200 }
                                                }
                                            }
                                            Text {
                                                anchors.left: baseNameText.right
                                                anchors.leftMargin: window.s(30)
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: floatCard.doMarquee
                                                text: floatCard.itemName
                                                font.family: "JetBrains Mono"
                                                font.weight: Font.Bold
                                                font.pixelSize: window.s(13)
                                                color: floatCard.isFailed ?
                                                    window.red :
                                                    (floatCard.isHighlighted ?
                                                     window.activeColor : window.text)
                                            }
                                        }

                                        Text {
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: window.s(10)
                                            color: floatCard.isFailed ?
                                                window.maroon :
                                                (floatCard.isMyBusy ?
                                                 window.activeColor : window.overlay0)
                                            text: floatCard.isFailed ?
                                                "Connection Failed" :
                                                (floatCard.isMyBusy ?
                                                 "Connecting..." :
                                                 (floatCard.renderFill > 0.1 &&
                                                  floatCard.renderFill < 1.0 ?
                                                  "Hold..." : action))
                                            Behavior on color {
                                                ColorAnimation { duration: 200 }
                                            }
                                        }
                                    }
                                }

                                // ---- Filled overlay text (inverted colors) ----
                                Item {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: floatCard.width * floatCard.renderFill
                                    clip: true

                                    RowLayout {
                                        x: baseTextRow.x
                                        y: baseTextRow.y
                                        width: baseTextRow.width
                                        height: baseTextRow.height
                                        spacing: window.s(10)

                                        Text {
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: window.s(20)
                                            color: window.crust
                                            text: icon
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: window.s(2)
                                            Item {
                                                Layout.fillWidth: true
                                                height: window.s(18)
                                                clip: true
                                                Text {
                                                    id: filledNameText
                                                    anchors.left: parent.left
                                                    anchors.leftMargin: floatCard.textOffset
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: floatCard.itemName
                                                    font.family: "JetBrains Mono"
                                                    font.weight: Font.Bold
                                                    font.pixelSize: window.s(13)
                                                    color: window.crust
                                                }
                                                Text {
                                                    anchors.left: filledNameText.right
                                                    anchors.leftMargin: window.s(30)
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    visible: floatCard.doMarquee
                                                    text: floatCard.itemName
                                                    font.family: "JetBrains Mono"
                                                    font.weight: Font.Bold
                                                    font.pixelSize: window.s(13)
                                                    color: window.crust
                                                }
                                            }
                                            Text {
                                                font.family: "JetBrains Mono"
                                                font.pixelSize: window.s(10)
                                                color: window.crust
                                                text: floatCard.isMyBusy ?
                                                    "Connecting..." :
                                                    (floatCard.renderFill > 0.1 &&
                                                     floatCard.renderFill < 1.0 ?
                                                     "Hold..." : action)
                                            }
                                        }
                                    }
                                }

                                // ---- Mouse Area (hold to connect) ----
                                MouseArea {
                                    id: floatMa
                                    anchors.fill: parent
                                    hoverEnabled: floatCard.isInteractable

                                    cursorShape: (floatCard.triggered ||
                                        floatCard.isMyBusy ||
                                        floatCard.renderFill === 1.0 ||
                                        !floatCard.isInteractable) ?
                                        Qt.ArrowCursor : Qt.PointingHandCursor

                                    onPressed: {
                                        if (floatCard.isInteractable &&
                                            !floatCard.triggered &&
                                            !floatCard.isMyBusy &&
                                            floatCard.fillLevel === 0.0) {
                                            if (window.pendingWifiId !== "") {
                                                window.pendingWifiId = "";
                                                window.pendingWifiSsid = "";
                                            }
                                            drainAnim.stop();
                                            fillAnim.start();
                                        }
                                    }
                                    onReleased: {
                                        if (floatCard.isInteractable &&
                                            !floatCard.triggered &&
                                            !floatCard.isMyBusy &&
                                            floatCard.fillLevel < 1.0) {
                                            fillAnim.stop();
                                            drainAnim.start();
                                        }
                                    }
                                }

                                // Fill animation
                                NumberAnimation {
                                    id: fillAnim
                                    target: floatCard
                                    property: "fillLevel"
                                    to: 1.0
                                    duration: 600 * (1.0 - floatCard.fillLevel)
                                    easing.type: Easing.InSine
                                    onFinished: {
                                        floatCard.triggered = true;
                                        floatCard.flashOpacity = 0.6;
                                        cardFlashAnim.start();
                                        cardBumpAnim.start();

                                        if (cmdStr === "TOGGLE_VIEW") {
                                            window.playSfx("switch.wav");
                                            window.showInfoView = !window.showInfoView;
                                            floatCard.triggered = false;
                                            drainAnim.start();
                                        } else if (isInfoNode && cmdStr) {
                                            Quickshell.execDetached(
                                                ["sh", "-c", cmdStr]);
                                            if (window.activeMode === "bt")
                                                btPoller.running = true;
                                            floatCard.triggered = false;
                                            drainAnim.start();
                                        } else {
                                            let sec = typeof security !== "undefined" &&
                                                security ?
                                                security.trim().toLowerCase() : "";
                                            let isSecure = sec !== "" &&
                                                sec !== "open" &&
                                                sec !== "--" &&
                                                sec !== "none";
                                            let isSaved = false;
                                            for (let i = 0;
                                                 i < window.savedWifiNetworks.length;
                                                 i++) {
                                                if (window.savedWifiNetworks[i] ===
                                                    ssid) {
                                                    isSaved = true;
                                                    break;
                                                }
                                            }

                                            if (window.activeMode === "wifi" &&
                                                isSecure && !isSaved) {
                                                window.pendingWifiSsid = ssid;
                                                window.pendingWifiId = floatCard.itemId;
                                            } else {
                                                window.connectDevice(
                                                    window.activeMode,
                                                    floatCard.itemId,
                                                    window.activeMode === "wifi" ?
                                                    ssid :
                                                    (window.activeMode === "eth" ?
                                                     floatCard.itemId : mac),
                                                    ""
                                                );
                                            }
                                        }
                                    }
                                }

                                // Drain animation
                                NumberAnimation {
                                    id: drainAnim
                                    target: floatCard
                                    property: "fillLevel"
                                    to: 0.0
                                    duration: 1500 * floatCard.fillLevel
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // BOTTOM TAB BAR - Mode switcher (Ethernet / Wi-Fi / Bluetooth)
            // -----------------------------------------------------------------
            Rectangle {
                id: bottomTabsContainer
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: window.s(25)
                width: window.s(360)
                height: window.s(54)
                radius: window.s(14)
                color: "#1affffff"  // ~10% white
                border.color: "#1affffff"
                border.width: 1
                visible: window.ethPresent ||
                    window.wifiPresent || window.btPresent

                // Morphing highlight pill
                Rectangle {
                    id: activeTabHighlight
                    y: window.s(6)
                    height: bottomTabsContainer.height - window.s(12)
                    radius: window.s(10)
                    z: 0

                    property int prevIdx: 1  // Start at WiFi
                    property int curIdx: window.activeMode === "eth" ? 0 :
                        (window.activeMode === "wifi" ? 1 : 2)

                    onCurIdxChanged: {
                        // Animate faster in the direction of movement
                        if (curIdx > prevIdx) {
                            rightAnim.duration = 200;
                            leftAnim.duration = 350;
                        } else if (curIdx < prevIdx) {
                            leftAnim.duration = 200;
                            rightAnim.duration = 350;
                        }
                        prevIdx = curIdx;
                    }

                    property Item activeItem: {
                        if (window.activeMode === "eth" && window.ethPresent)
                            return ethTabRect;
                        if (window.activeMode === "wifi" && window.wifiPresent)
                            return wifiTabRect;
                        if (window.activeMode === "bt" && window.btPresent)
                            return btTabRect;
                        return null;
                    }

                    property real targetLeft: activeItem ? activeItem.x : 0
                    property real targetRight: activeItem ?
                        (activeItem.x + activeItem.width) : 0

                    property real actualLeft: targetLeft
                    property real actualRight: targetRight

                    Behavior on actualLeft {
                        NumberAnimation {
                            id: leftAnim
                            duration: 250
                            easing.type: Easing.OutExpo
                        }
                    }
                    Behavior on actualRight {
                        NumberAnimation {
                            id: rightAnim
                            duration: 250
                            easing.type: Easing.OutExpo
                        }
                    }

                    x: window.s(6) + actualLeft
                    width: Math.max(0, actualRight - actualLeft)
                    opacity: activeItem ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation { duration: 300 }
                    }

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0.0
                            color: Qt.lighter(window.activeColor, 1.15)
                        }
                        GradientStop {
                            position: 1.0
                            color: window.activeColor
                        }
                    }
                }

                RowLayout {
                    id: tabsLayout
                    anchors.fill: parent
                    anchors.margins: window.s(6)
                    spacing: window.s(6)

                    // ---- Ethernet Tab ----
                    Rectangle {
                        id: ethTabRect
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: window.ethPresent
                        radius: window.s(10)
                        color: window.activeMode === "eth" ?
                            "transparent" :
                            (ethTabMa.containsMouse ?
                             window.surface1 : "transparent")
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: window.s(8)
                            Text {
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: window.s(18)
                                color: window.activeMode === "eth" ?
                                    window.crust : window.text
                                text: "󰈀"
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }
                            Text {
                                font.family: "JetBrains Mono"
                                font.weight: Font.Black
                                font.pixelSize: window.s(13)
                                color: window.activeMode === "eth" ?
                                    window.crust : window.text
                                text: "Ethernet"
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }
                        }
                        MouseArea {
                            id: ethTabMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (window.pendingWifiId !== "") {
                                    window.pendingWifiId = "";
                                    window.pendingWifiSsid = "";
                                }
                                if (window.activeMode !== "eth") {
                                    window.powerAnimAllowed = false;
                                    powerAnimBlocker.restart();
                                    window.playSfx("switch.wav");
                                    window.activeMode = "eth";
                                }
                            }
                        }
                    }

                    // Separator
                    Rectangle {
                        visible: window.ethPresent &&
                            (window.wifiPresent || window.btPresent)
                        width: 1
                        Layout.fillHeight: true
                        Layout.margins: window.s(5)
                        color: "#33ffffff"  // ~20% white
                    }

                    // ---- WiFi Tab ----
                    Rectangle {
                        id: wifiTabRect
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: window.wifiPresent
                        radius: window.s(10)
                        color: window.activeMode === "wifi" ?
                            "transparent" :
                            (wifiTabMa.containsMouse ?
                             window.surface1 : "transparent")
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: window.s(8)
                            Text {
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: window.s(18)
                                color: window.activeMode === "wifi" ?
                                    window.crust : window.text
                                text: "󰤨"
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }
                            Text {
                                font.family: "JetBrains Mono"
                                font.weight: Font.Black
                                font.pixelSize: window.s(13)
                                color: window.activeMode === "wifi" ?
                                    window.crust : window.text
                                text: "Wi-Fi"
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }
                        }
                        MouseArea {
                            id: wifiTabMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (window.pendingWifiId !== "") {
                                    window.pendingWifiId = "";
                                    window.pendingWifiSsid = "";
                                }
                                if (window.activeMode !== "wifi") {
                                    window.powerAnimAllowed = false;
                                    powerAnimBlocker.restart();
                                    window.playSfx("switch.wav");
                                    window.activeMode = "wifi";
                                }
                            }
                        }
                    }

                    // Separator
                    Rectangle {
                        visible: window.wifiPresent && window.btPresent
                        width: 1
                        Layout.fillHeight: true
                        Layout.margins: window.s(5)
                        color: "#33ffffff"
                    }

                    // ---- Bluetooth Tab ----
                    Rectangle {
                        id: btTabRect
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: window.btPresent
                        radius: window.s(10)
                        color: window.activeMode === "bt" ?
                            "transparent" :
                            (btTabMa.containsMouse ?
                             window.surface1 : "transparent")
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: window.s(8)
                            Text {
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: window.s(18)
                                color: window.activeMode === "bt" ?
                                    window.crust : window.text
                                text: "󰂯"
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }
                            Text {
                                font.family: "JetBrains Mono"
                                font.weight: Font.Black
                                font.pixelSize: window.s(13)
                                color: window.activeMode === "bt" ?
                                    window.crust : window.text
                                text: "Bluetooth"
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }
                        }
                        MouseArea {
                            id: btTabMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (window.pendingWifiId !== "") {
                                    window.pendingWifiId = "";
                                    window.pendingWifiSsid = "";
                                }
                                if (window.activeMode !== "bt") {
                                    window.powerAnimAllowed = false;
                                    powerAnimBlocker.restart();
                                    window.playSfx("switch.wav");
                                    window.activeMode = "bt";
                                }
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // POWER TOGGLE BUTTON - Morphs between center and corner
            // -----------------------------------------------------------------
            // When power is OFF: large centered button (calls to action)
            // When power is ON: small button in bottom-right corner (status)
            // The morph is driven by pwrMorph (0.0 = off, 1.0 = on)
            Item {
                id: powerToggleContainer
                z: 100  // Always on top of everything

                // Using a single float for position interpolation instead
                // of direct Behavior on x/y prevents lag and overshooting
                // during parent resize events
                property real pwrMorph: window.currentPower ? 1.0 : 0.0
                Behavior on pwrMorph {
                    enabled: window.powerAnimAllowed
                    NumberAnimation {
                        duration: 800
                        easing.type: Easing.InOutQuint
                    }
                }

                // Size: 160 when off (large), 48 when on (small)
                width: window.s(160) +
                    (window.s(48) - window.s(160)) * pwrMorph
                height: width

                // Position: center when off, bottom-right when on
                x: {
                    let startX = (parent.width / 2) - window.s(80);
                    let endX = parent.width - window.s(30) - window.s(48);
                    return startX + (endX - startX) * pwrMorph;
                }
                y: {
                    let startY = (parent.height - window.s(80)) / 2 -
                        window.s(80);
                    let endY = parent.height - window.s(30) - window.s(48);
                    return startY + (endY - startY) * pwrMorph;
                }

                // Shadow
                MultiEffect {
                    source: powerBtnRect
                    anchors.fill: powerBtnRect
                    shadowEnabled: true
                    shadowColor: "#000000"
                    shadowOpacity: 0.4
                    shadowBlur: 1.2
                    shadowVerticalOffset: window.s(4)
                }

                Rectangle {
                    id: powerBtnRect
                    anchors.fill: parent
                    radius: width / 2

                    // Press/hover scale feedback
                    scale: pwrMa.pressed ? 0.95 :
                        (pwrMa.containsMouse ? 1.05 : 1.0)
                    Behavior on scale {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }

                    // Off state gradient (visible through transparent when on)
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop {
                            position: 0.0
                            color: window.currentPower ?
                                "transparent" : window.surface1
                        }
                        GradientStop {
                            position: 1.0
                            color: window.currentPower ?
                                "transparent" : window.crust
                        }
                    }

                    border.color: window.currentPowerPending ?
                        window.activeColor :
                        (window.currentPower ? "transparent" : window.surface2)
                    border.width: window.s(2)
                    Behavior on border.color {
                        enabled: window.powerAnimAllowed
                        ColorAnimation {
                            duration: 800
                            easing.type: Easing.InOutQuint
                        }
                    }

                    // On state accent fill (fades in)
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        opacity: window.currentPower ? 1.0 : 0.0
                        Behavior on opacity {
                            enabled: window.powerAnimAllowed
                            NumberAnimation {
                                duration: 800
                                easing.type: Easing.InOutQuint
                            }
                        }
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0.0
                                color: Qt.lighter(window.activeColor, 1.15)
                            }
                            GradientStop {
                                position: 1.0
                                color: window.activeColor
                            }
                        }
                    }

                    // Power icon
                    Text {
                        id: pwrIcon
                        anchors.centerIn: parent
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: window.currentPower ?
                            window.s(22) : window.s(64)
                        color: window.currentPower ?
                            window.crust : window.text
                        text: window.currentPowerPending ? "󰑮" : ""
                        // "󰑮" = spinner icon, "" = power icon
                        Behavior on font.pixelSize {
                            enabled: window.powerAnimAllowed
                            NumberAnimation {
                                duration: 800
                                easing.type: Easing.InOutQuint
                            }
                        }
                        Behavior on color {
                            enabled: window.powerAnimAllowed
                            ColorAnimation {
                                duration: 800
                                easing.type: Easing.InOutQuint
                            }
                        }

                        // Spin when pending
                        RotationAnimation {
                            target: pwrIcon
                            property: "rotation"
                            from: 0; to: 360
                            duration: 800
                            loops: Animation.Infinite
                            running: window.currentPowerPending
                            onRunningChanged: {
                                if (!running) pwrIcon.rotation = 0;
                            }
                        }
                    }

                    // Click handler
                    MouseArea {
                        id: pwrMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Clear any pending WiFi password
                            if (window.pendingWifiId !== "") {
                                window.pendingWifiId = "";
                                window.pendingWifiSsid = "";
                            }

                            // Mode-specific toggle logic
                            if (window.activeMode === "eth") {
                                if (window.ethPowerPending) return;
                                window.expectedEthPower =
                                    window.ethPower === "on" ? "off" : "on";
                                window.ethPowerPending = true;
                                if (window.expectedEthPower === "on")
                                    window.playSfx("power_on.wav");
                                else window.playSfx("power_off.wav");
                                ethPendingReset.restart();
                                window.ethPower = window.expectedEthPower;
                                let targetDev = window.ethDeviceName !== "" ?
                                    window.ethDeviceName :
                                    (window.currentCores[0] ?
                                     window.currentCores[0].id : "");
                                if (targetDev !== "") {
                                    if (window.expectedEthPower === "on")
                                        Quickshell.execDetached(
                                            ["nmcli", "device", "connect",
                                             targetDev]);
                                    else
                                        Quickshell.execDetached(
                                            ["nmcli", "device", "disconnect",
                                             targetDev]);
                                }
                                ethPoller.running = true;
                            } else if (window.activeMode === "wifi") {
                                if (window.wifiPowerPending) return;
                                window.expectedWifiPower =
                                    window.wifiPower === "on" ? "off" : "on";
                                window.wifiPowerPending = true;
                                if (window.expectedWifiPower === "on")
                                    window.playSfx("power_on.wav");
                                else window.playSfx("power_off.wav");
                                wifiPendingReset.restart();
                                window.wifiPower = window.expectedWifiPower;
                                Quickshell.execDetached(
                                    ["nmcli", "radio", "wifi",
                                     window.wifiPower]);
                                wifiPoller.running = true;
                            } else {
                                if (window.btPowerPending) return;
                                window.expectedBtPower =
                                    window.btPower === "on" ? "off" : "on";
                                window.btPowerPending = true;
                                if (window.expectedBtPower === "on")
                                    window.playSfx("power_on.wav");
                                else window.playSfx("power_off.wav");
                                btPendingReset.restart();
                                window.btPower = window.expectedBtPower;
                                Quickshell.execDetached(
                                    ["bash",
                                     window.scriptsDir +
                                     "/bluetooth_panel_logic.sh",
                                     "--toggle"]);
                                btPoller.running = true;
                            }
                        }
                    }
                }
            }
        }
    }
}