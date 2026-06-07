// import QtQuick
// import QtQuick.Window
// import QtQuick.Effects
// import QtQuick.Layouts
// import QtQuick.Controls
// import Quickshell
// import Quickshell.Io
// import "../"

// Item {
//     id: root
//     focus: true

//     Scaler {
//         id: scaler
//         currentWidth: Screen.width
//     }
//     function s(val) { 
//         return scaler.s(val); 
//     }
    
//     property bool isLayoutDropdownOpen: false

//     property bool isSearchMode: false
//     property string globalSearchQuery: ""

//     property int highlightedBox: -1

//     property int searchHighlightIndex: -1

//     property var searchResultItems: []

//     function rebuildSearchResultItems() {
//         let items = [];
//         for (let i = 0; i < root.allSettingsCards.length; i++) {
//             let card = root.allSettingsCards[i];
//             if (root.globalSearchMatches(card, root.globalSearchQuery)) {
//                 items.push({ kind: "card", cardIndex: i, kbIndex: -1 });
//             }
//         }
//         let kbIndices = root.matchingKeybindIndices;
//         for (let j = 0; j < kbIndices.length; j++) {
//             items.push({ kind: "keybind", cardIndex: -1, kbIndex: kbIndices[j] });
//         }
//         root.searchResultItems = items;
//         if (root.searchHighlightIndex >= items.length) {
//             root.searchHighlightIndex = items.length - 1;
//         }
//     }

//     onGlobalSearchQueryChanged: {
//         root.matchingKeybindIndices = root.getMatchingKeybindIndices(root.globalSearchQuery);
//         root.rebuildSearchResultItems();
//         root.searchHighlightIndex = -1;
//     }

//     onIsSearchModeChanged: {
//         if (!root.isSearchMode) {
//             root.searchHighlightIndex = -1;
//         } else {
//             root.rebuildSearchResultItems();
//         }
//     }

//     function activateSearchHighlight() {
//         if (root.searchHighlightIndex < 0 || root.searchHighlightIndex >= root.searchResultItems.length) return;
//         let item = root.searchResultItems[root.searchHighlightIndex];
//         if (item.kind === "card") {
//             let card = root.allSettingsCards[item.cardIndex];
//             jumpToSettingTimer.targetTab = card.tab;
//             jumpToSettingTimer.targetBox = card.boxIndex;
//             jumpToSettingTimer.start();
//             root.currentTab = card.tab;
//             if (card.tab === 0) root.tab0Loaded = true;
//             else if (card.tab === 1) root.tab1Loaded = true;
//             else if (card.tab === 2) root.tab2Loaded = true;
//         } else {
//             jumpToSettingTimer.targetTab = 2;
//             jumpToSettingTimer.targetBox = item.kbIndex;
//             jumpToSettingTimer.start();
//             root.currentTab = 2;
//             root.tab2Loaded = true;
//         }
//         root.isSearchMode = false;
//         root.forceActiveFocus();
//         globalSearchInput.text = "";
//         root.globalSearchQuery = "";
//     }

//     function scrollSearchToHighlight(idx) {
//         if (idx < 0 || idx >= root.searchResultItems.length) return;
//         let nCards = 0;
//         for (let i = 0; i < root.allSettingsCards.length; i++) {
//             if (root.globalSearchMatches(root.allSettingsCards[i], root.globalSearchQuery)) nCards++;
//         }
//         let itemH = root.s(60) + root.s(10);
//         let headerH = (root.matchingKeybindIndices.length > 0) ? root.s(32) + root.s(10) : 0;
//         let approxY = 0;
//         let it = root.searchResultItems[idx];
//         if (it.kind === "card") {
//             let pos = 0;
//             for (let i = 0; i < root.allSettingsCards.length; i++) {
//                 if (root.globalSearchMatches(root.allSettingsCards[i], root.globalSearchQuery)) {
//                     if (root.allSettingsCards[i] === root.allSettingsCards[item_cardIndex_from(idx)]) break;
//                     pos++;
//                 }
//             }
//             approxY = pos * itemH;
//         } else {
//             approxY = nCards * itemH + headerH + (idx - nCards) * itemH;
//         }
//         let target = Math.max(0, approxY - root.s(20));
//         searchResultsFlickable.contentY = Math.min(target, Math.max(0, searchResultsFlickable.contentHeight - searchResultsFlickable.height));
//     }

//     function item_cardIndex_from(idx) {
//         let item = root.searchResultItems[idx];
//         return item.cardIndex;
//     }

//     function clearHighlight() {
//         root.highlightedBox = -1;
//     }

//     function maxHighlightForTab(tab) {
//         if (tab === 0) return 6;
//         if (tab === 1) return 3;
//         if (tab === 2) return dynamicKeybindsModel.count - 1;
//         return -1;
//     }

//     function activateHighlightedBox() {
//         if (root.currentTab === 0) {
//             if (root.highlightedBox === 0) {
//                 Config.openGuideAtStartup = !Config.openGuideAtStartup;
//             } else if (root.highlightedBox === 1) {
//                 Config.topbarHelpIcon = !Config.topbarHelpIcon;
//             } else if (root.highlightedBox === 2) {
//             } else if (root.highlightedBox === 3) {
//                 if (generalLoader.item) generalLoader.item.focusLangInput();
//             } else if (root.highlightedBox === 4) {
//                 root.isLayoutDropdownOpen = !root.isLayoutDropdownOpen;
//             } else if (root.highlightedBox === 5) {
//                 if (generalLoader.item) generalLoader.item.focusWpDirInput();
//             } else if (root.highlightedBox === 6) {
//             }
//         } else if (root.currentTab === 1) {
//             if (root.highlightedBox === 0) {
//             } else if (root.highlightedBox === 1) {
//                 if (weatherLoader.item) weatherLoader.item.focusApiKey();
//             } else if (root.highlightedBox === 2) {
//                 if (weatherLoader.item) weatherLoader.item.focusCityId();
//             } else if (root.highlightedBox === 3) {
//             }
//         } else if (root.currentTab === 2) {
//             if (root.highlightedBox >= 0 && root.highlightedBox < dynamicKeybindsModel.count) {
//                 let isEd = dynamicKeybindsModel.get(root.highlightedBox).isEditing;
//                 dynamicKeybindsModel.setProperty(root.highlightedBox, "isEditing", !isEd);
//             }
//         }
//     }

//     onHighlightedBoxChanged: {
//         if (root.highlightedBox < 0) return;
//         Qt.callLater(function() { root.scrollHighlightedIntoView(); });
//     }

//     function scrollHighlightedIntoView() {
//         let box = root.highlightedBox;
//         if (box < 0) return;
//         if (root.currentTab === 0 && generalLoader.item) {
//             let approxY = 0;
//             if (box === 0 || box === 1) approxY = 0;
//             else if (box === 2) approxY = root.s(120);
//             else if (box === 3 || box === 4) approxY = root.s(240);
//             else if (box === 5) approxY = root.s(400);
//             else if (box === 6) approxY = root.s(520);
//             generalLoader.item.scrollToBox(approxY);
//         } else if (root.currentTab === 1 && weatherLoader.item) {
//             let approxY = 0;
//             if (box === 0) approxY = 0;
//             else if (box === 1) approxY = root.s(140);
//             else if (box === 2) approxY = root.s(240);
//             else if (box === 3) approxY = root.s(340);
//             weatherLoader.item.scrollToBox(approxY);
//         } else if (root.currentTab === 2 && keybindLoader.item) {
//             let approxY = box * root.s(56) + root.s(120);
//             keybindLoader.item.scrollToBox(approxY);
//         }
//     }

//     property int currentTab: 0
//     property var tabNames: ["General", "Weather", "Keybinds"]
//     property var tabIcons: ["󰒓", "󰖐", "󰌌"]
//     property var tabColors: ["teal", "blue", "peach"]

//     property bool tab0Loaded: false
//     property bool tab1Loaded: false
//     property bool tab2Loaded: false

//     onCurrentTabChanged: {
//         root.clearHighlight();
//         if (currentTab === 0) root.tab0Loaded = true;
//         else if (currentTab === 1) root.tab1Loaded = true;
//         else if (currentTab === 2) root.tab2Loaded = true;
//     }

//     Keys.onEscapePressed: {
//         if (root.isSearchMode) {
//             root.isSearchMode = false;
//             root.globalSearchQuery = "";
//             globalSearchInput.text = "";
//             root.searchHighlightIndex = -1;
//             event.accepted = true;
//         } else if (root.isLayoutDropdownOpen) {
//             root.isLayoutDropdownOpen = false;
//             event.accepted = true;
//         } else if (root.highlightedBox >= 0) {
//             root.clearHighlight();
//             event.accepted = true;
//         } else {
//             closeSequence.start();
//             event.accepted = true;
//         }
//     }

//     Keys.onTabPressed: (event) => {
//         if (root.isSearchMode) return;
//         root.currentTab = (root.currentTab + 1) % 3;
//         event.accepted = true;
//     }
//     Keys.onBacktabPressed: (event) => {
//         if (root.isSearchMode) return;
//         root.currentTab = (root.currentTab + 2) % 3;
//         event.accepted = true;
//     }

//     Keys.onPressed: (event) => {
//         if ((event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) || 
//             (event.key === Qt.Key_Slash && !root.isSearchMode)) {
//             root.isSearchMode = true;
//             globalSearchInput.forceActiveFocus();
//             event.accepted = true;
//             return;
//         }

//         if (root.isSearchMode) {
//             if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
//                 root.forceActiveFocus();
//                 let total = root.searchResultItems.length;
//                 if (total === 0) { event.accepted = true; return; }
//                 if (event.key === Qt.Key_Down) {
//                     if (root.searchHighlightIndex < total - 1) {
//                         root.searchHighlightIndex++;
//                     } else {
//                         root.searchHighlightIndex = 0;
//                     }
//                 } else {
//                     if (root.searchHighlightIndex > 0) {
//                         root.searchHighlightIndex--;
//                     } else if (root.searchHighlightIndex === 0) {
//                         root.searchHighlightIndex = total - 1;
//                     } else {
//                         root.searchHighlightIndex = total - 1;
//                     }
//                 }
//                 root.scrollSearchHighlightIntoView(root.searchHighlightIndex);
//                 event.accepted = true;
//                 return;
//             }
//             return;
//         }

//         if (root.isLayoutDropdownOpen) {
//             if (event.key === Qt.Key_Down) {
//                 if (generalLoader.item) generalLoader.item.layoutListIncrementIndex();
//                 event.accepted = true;
//             } else if (event.key === Qt.Key_Up) {
//                 if (generalLoader.item) generalLoader.item.layoutListDecrementIndex();
//                 event.accepted = true;
//             }
//             return;
//         }
        
//         if (event.key === Qt.Key_Left) {
//             if (root.currentTab === 0 && root.highlightedBox === 2) {
//                 Config.uiScale = Math.max(0.5, (Config.uiScale - 0.1).toFixed(1));
//                 event.accepted = true;
//                 return;
//             } else if (root.currentTab === 0 && root.highlightedBox === 6) {
//                 Config.workspaceCount = Math.max(2, Config.workspaceCount - 1);
//                 event.accepted = true;
//                 return;
//             }
//         }
//         if (event.key === Qt.Key_Right) {
//             if (root.currentTab === 0 && root.highlightedBox === 2) {
//                 Config.uiScale = Math.min(2.0, (Config.uiScale + 0.1).toFixed(1));
//                 event.accepted = true;
//                 return;
//             } else if (root.currentTab === 0 && root.highlightedBox === 6) {
//                 Config.workspaceCount = Math.min(10, Config.workspaceCount + 1);
//                 event.accepted = true;
//                 return;
//             }
//         }

//         if (event.key === Qt.Key_Down) {
//             let maxIdx = root.maxHighlightForTab(root.currentTab);
//             if (maxIdx < 0) { event.accepted = true; return; }
//             if (root.highlightedBox < maxIdx) {
//                 root.highlightedBox = root.highlightedBox + 1;
//             } else if (root.highlightedBox === maxIdx) {
//                 root.highlightedBox = -1;
//             } else {
//                 root.highlightedBox = 0;
//             }
//             event.accepted = true;
//         } else if (event.key === Qt.Key_Up) {
//             let maxIdx = root.maxHighlightForTab(root.currentTab);
//             if (maxIdx < 0) { event.accepted = true; return; }
//             if (root.highlightedBox > 0) {
//                 root.highlightedBox = root.highlightedBox - 1;
//             } else if (root.highlightedBox === 0) {
//                 root.highlightedBox = -1;
//             } else {
//                 root.highlightedBox = maxIdx;
//             }
//             event.accepted = true;
//         }
//     }

//     Keys.onReturnPressed: (event) => root.handleRootEnter(event)
//     Keys.onEnterPressed: (event) => root.handleRootEnter(event)

//     function handleRootEnter(event) {
//         if (root.isSearchMode) {
//             if (root.searchHighlightIndex >= 0) {
//                 root.activateSearchHighlight();
//                 event.accepted = true;
//             }
//             return;
//         }
//         if (root.isLayoutDropdownOpen) {
//             if (generalLoader.item) generalLoader.item.acceptLayoutSelection();
//             root.isLayoutDropdownOpen = false;
//             event.accepted = true;
//             return;
//         }
//         if (root.highlightedBox >= 0) {
//             root.activateHighlightedBox();
//             event.accepted = true;
//             return;
//         }
//         if (root.currentTab === 0) Config.saveAppSettings();
//         else if (root.currentTab === 1) Config.saveWeatherConfig();
//         else if (root.currentTab === 2) root.saveAllKeybinds();
//         event.accepted = true;
//     }

//     function scrollSearchHighlightIntoView(idx) {
//         if (idx < 0 || idx >= root.searchResultItems.length) return;

//         let nCards = 0;
//         for (let i = 0; i < root.allSettingsCards.length; i++) {
//             if (root.globalSearchMatches(root.allSettingsCards[i], root.globalSearchQuery)) nCards++;
//         }
//         let hasKbHeader = root.matchingKeybindIndices.length > 0;
//         let itemH = root.s(60) + root.s(10);
//         let headerH = hasKbHeader ? (root.s(32) + root.s(10)) : 0;

//         let approxY = 0;
//         let it = root.searchResultItems[idx];
//         if (it.kind === "card") {
//             let pos = 0;
//             for (let i = 0; i < root.searchResultItems.length; i++) {
//                 if (i === idx) break;
//                 if (root.searchResultItems[i].kind === "card") pos++;
//             }
//             approxY = pos * itemH;
//         } else {
//             let kbPos = 0;
//             for (let i = 0; i < root.searchResultItems.length; i++) {
//                 if (i === idx) break;
//                 if (root.searchResultItems[i].kind === "keybind") kbPos++;
//             }
//             approxY = nCards * itemH + headerH + kbPos * itemH;
//         }

//         let viewH = searchResultsFlickable.height;
//         let contentH = searchResultsFlickable.contentHeight;
//         let curY = searchResultsFlickable.contentY;
//         let itemTop = approxY;
//         let itemBottom = approxY + root.s(60);

//         if (itemTop < curY + root.s(10)) {
//             searchResultsFlickable.contentY = Math.max(0, itemTop - root.s(10));
//         } else if (itemBottom > curY + viewH - root.s(10)) {
//             searchResultsFlickable.contentY = Math.min(contentH - viewH, itemBottom - viewH + root.s(10));
//         }
//     }

//     MatugenColors { id: _theme }

//     readonly property color base: _theme.base
//     readonly property color mantle: _theme.mantle
//     readonly property color crust: _theme.crust
//     readonly property color text: _theme.text
//     readonly property color subtext0: _theme.subtext0
//     readonly property color subtext1: _theme.subtext1
//     readonly property color surface0: _theme.surface0
//     readonly property color surface1: _theme.surface1
//     readonly property color surface2: _theme.surface2
//     readonly property color overlay0: _theme.overlay0
//     readonly property color mauve: _theme.mauve
//     readonly property color pink: _theme.pink
//     readonly property color blue: _theme.blue
//     readonly property color sapphire: _theme.sapphire
//     readonly property color teal: _theme.teal
//     readonly property color green: _theme.green
//     readonly property color peach: _theme.peach
//     readonly property color yellow: _theme.yellow
//     readonly property color red: _theme.red

//     property var kbToggleModelArr: [
//         { label: "Alt + Shift", val: "grp:alt_shift_toggle" },
//         { label: "Win + Space", val: "grp:win_space_toggle" },
//         { label: "Caps Lock", val: "grp:caps_toggle" },
//         { label: "Ctrl + Shift", val: "grp:ctrl_shift_toggle" },
//         { label: "Ctrl + Alt", val: "grp:ctrl_alt_toggle" },
//         { label: "Right Alt", val: "grp:toggle" },
//         { label: "No Toggle", val: "" }
//     ]

//     function getKbToggleLabel(val) {
//         for (let i = 0; i < root.kbToggleModelArr.length; i++) {
//             if (root.kbToggleModelArr[i].val === val) return root.kbToggleModelArr[i].label;
//         }
//         return "Alt + Shift";
//     }

//     ListModel { id: dynamicKeybindsModel }
    
//     Connections {
//         target: Config
//         // Triggers the very first time Config finishes reading the JSON
//         function onKeybindsLoaded() {
//             dynamicKeybindsModel.clear();
//             dynamicKeybindsModel.append(Config.keybindsData);
//         }
//         // Triggers whenever you save and Config.keybindsData is overwritten
//         function onKeybindsDataChanged() {
//             dynamicKeybindsModel.clear();
//             dynamicKeybindsModel.append(Config.keybindsData);
//         }
//     }    
//     property var bindTypes: ["bind", "binde", "bindl", "bindel", "bindm"]
//     property var dispatchers: ["exec", "exec-once", "dispatch", "workspace", "movetoworkspace", "movewindow", "resizeactive", "movefocus", "togglefloating", "killactive"]

//     function saveAllKeybinds() {
//         let bindsArray = [];
//         for (let i = 0; i < dynamicKeybindsModel.count; i++) {
//             let item = dynamicKeybindsModel.get(i);
//             if (!item.key && !item.command) continue; 
//             bindsArray.push({
//                 type: item.type,
//                 mods: item.mods,
//                 key: item.key,
//                 dispatcher: item.dispatcher,
//                 command: item.command,
//                 isEditing: false // CRITICAL: This prevents QML from dropping the role!
//             });
//         }
//         Config.saveAllKeybinds(bindsArray);
//     }

//     function validateKeybind(index, mods, key, dispatcher, command) {
//         let validMods = ["SHIFT", "SHIFT_L", "SHIFT_R", "CAPS", "CTRL", "CONTROL", "ALT", "MOD2", "MOD3", "SUPER", "WIN", "LOGO", "MOD4", "MOD5", "$mainMod"];
//         let modArray = mods ? mods.replace(/&/g, " ").split(" ").filter(x => x !== "") : [];
        
//         for (let i = 0; i < modArray.length; i++) {
//             if (!validMods.includes(modArray[i])) {
//                 return "Invalid modifier: " + modArray[i] + ".\nKeys like SPACE cannot be used as modifiers.";
//             }
//         }

//         let currentModsNormalized = modArray.slice().sort().join(" ");
//         let currentKeyNormalized = key.trim().toLowerCase();

//         for (let i = 0; i < dynamicKeybindsModel.count; i++) {
//             if (i === index) continue;

//             let item = dynamicKeybindsModel.get(i);
//             if (!item.key) continue;

//             let itemModsNormalized = item.mods ? item.mods.replace(/&/g, " ").split(" ").filter(x => x !== "").sort().join(" ") : "";
//             let itemKeyNormalized = item.key.trim().toLowerCase();

//             if (itemModsNormalized === currentModsNormalized && itemKeyNormalized === currentKeyNormalized) {
//                 return "Duplicate keybind!\nThis exact combination already exists.";
//             }
//         }

//         return "VALID";
//     }

//     Timer {
//         id: scrollTimer
//         interval: 50
//         onTriggered: {
//             if (keybindLoader.item) {
//                 keybindLoader.item.scrollToBottom();
//             }
//         }
//     }

//     Timer {
//         id: jumpToSettingTimer
//         interval: 100
//         property int targetTab: 0
//         property int targetBox: -1

//         onTriggered: {
//             if (targetBox >= 0) {
//                 root.highlightedBox = targetBox;
                
//                 let approxY = 0;

//                 if (targetTab === 0 && generalLoader.item) {
//                     if (targetBox === 0 || targetBox === 1) approxY = 0;
//                     else if (targetBox === 2) approxY = root.s(120);
//                     else if (targetBox === 3 || targetBox === 4) approxY = root.s(240);
//                     else if (targetBox === 5) approxY = root.s(400);
//                     else if (targetBox === 6) approxY = root.s(520);
//                     generalLoader.item.scrollTo(approxY);
//                 } else if (targetTab === 1 && weatherLoader.item) {
//                     if (targetBox === 1) approxY = root.s(140);
//                     else if (targetBox === 2) approxY = root.s(240);
//                     else if (targetBox === 3) approxY = root.s(340);
//                     weatherLoader.item.scrollTo(approxY);
//                 } else if (targetTab === 2 && keybindLoader.item) {
//                     approxY = targetBox * (root.s(56)) + root.s(120);
//                     keybindLoader.item.scrollTo(approxY);
//                 }

//                 targetBox = -1;
//             }
//         }
//     }    

//     ListModel {
//         id: langModel

//         // --- Americas ---
//         ListElement { code: "us"; name: "English (US)" }
//         ListElement { code: "ca"; name: "English/French (Canada)" }
//         ListElement { code: "ca-multix"; name: "Canadian Multilingual" }
//         ListElement { code: "latam"; name: "Spanish (Latin America)" }
//         ListElement { code: "br"; name: "Portuguese (Brazil)" }
//         ListElement { code: "ar"; name: "Arabic (Latin America)" }
//         ListElement { code: "bo"; name: "Bolivia" }
//         ListElement { code: "cl"; name: "Chile" }
//         ListElement { code: "co"; name: "Colombia" }
//         ListElement { code: "cr"; name: "Costa Rica" }
//         ListElement { code: "cu"; name: "Cuba" }
//         ListElement { code: "do"; name: "Dominican Republic" }
//         ListElement { code: "ec"; name: "Ecuador" }
//         ListElement { code: "sv"; name: "El Salvador" }
//         ListElement { code: "gt"; name: "Guatemala" }
//         ListElement { code: "hn"; name: "Honduras" }
//         ListElement { code: "mx"; name: "Mexico" }
//         ListElement { code: "ni"; name: "Nicaragua" }
//         ListElement { code: "pa"; name: "Panama" }
//         ListElement { code: "py"; name: "Paraguay" }
//         ListElement { code: "pe"; name: "Peru" }
//         ListElement { code: "pr"; name: "Puerto Rico" }
//         ListElement { code: "uy"; name: "Uruguay" }
//         ListElement { code: "ve"; name: "Venezuela" }

//         // --- Europe (West, Central, & North) ---
//         ListElement { code: "gb"; name: "English (UK)" }
//         ListElement { code: "ie"; name: "English (Ireland)" }
//         ListElement { code: "gd"; name: "Scottish Gaelic" }
//         ListElement { code: "cy-gb"; name: "Welsh" }
//         ListElement { code: "fr"; name: "French" }
//         ListElement { code: "be"; name: "Belgian" }
//         ListElement { code: "ch"; name: "Swiss" }
//         ListElement { code: "de"; name: "German" }
//         ListElement { code: "at"; name: "Austrian" }
//         ListElement { code: "nl"; name: "Dutch" }
//         ListElement { code: "lu"; name: "Luxembourgish" }
//         ListElement { code: "es"; name: "Spanish" }
//         ListElement { code: "pt"; name: "Portuguese" }
//         ListElement { code: "it"; name: "Italian" }
//         ListElement { code: "mt"; name: "Maltese" }
//         ListElement { code: "se"; name: "Swedish" }
//         ListElement { code: "no"; name: "Norwegian" }
//         ListElement { code: "dk"; name: "Danish" }
//         ListElement { code: "fi"; name: "Finnish" }
//         ListElement { code: "is"; name: "Icelandic" }
//         ListElement { code: "fo"; name: "Faroese" }
//         ListElement { code: "gl"; name: "Greenlandic" }
//         ListElement { code: "pl"; name: "Polish" }
//         ListElement { code: "cz"; name: "Czech" }
//         ListElement { code: "sk"; name: "Slovak" }
//         ListElement { code: "hu"; name: "Hungarian" }
//         ListElement { code: "ad"; name: "Andorra" }
//         ListElement { code: "mc"; name: "Monaco" }
//         ListElement { code: "sm"; name: "San Marino" }
//         ListElement { code: "va"; name: "Vatican" }
//         ListElement { code: "epo"; name: "Esperanto" }
//         ListElement { code: "eu"; name: "Basque" }
//         ListElement { code: "ca-fr"; name: "Catalan" }

//         // --- Europe (East) & Caucasus ---
//         ListElement { code: "ru"; name: "Russian" }
//         ListElement { code: "ua"; name: "Ukrainian" }
//         ListElement { code: "by"; name: "Belarusian" }
//         ListElement { code: "ro"; name: "Romanian" }
//         ListElement { code: "bg"; name: "Bulgarian" }
//         ListElement { code: "rs"; name: "Serbian" }
//         ListElement { code: "hr"; name: "Croatian" }
//         ListElement { code: "si"; name: "Slovenian" }
//         ListElement { code: "mk"; name: "Macedonian" }
//         ListElement { code: "ba"; name: "Bosnian" }
//         ListElement { code: "me"; name: "Montenegrin" }
//         ListElement { code: "gr"; name: "Greek" }
//         ListElement { code: "cy"; name: "Cyprus" }
//         ListElement { code: "ee"; name: "Estonian" }
//         ListElement { code: "lv"; name: "Latvian" }
//         ListElement { code: "lt"; name: "Lithuanian" }
//         ListElement { code: "md"; name: "Moldovan" }
//         ListElement { code: "am"; name: "Armenian" }
//         ListElement { code: "ge"; name: "Georgian" }
//         ListElement { code: "az"; name: "Azerbaijani" }
//         ListElement { code: "kz"; name: "Kazakh" }
//         ListElement { code: "kg"; name: "Kyrgyz" }
//         ListElement { code: "tj"; name: "Tajik" }
//         ListElement { code: "tm"; name: "Turkmen" }
//         ListElement { code: "uz"; name: "Uzbek" }
//         ListElement { code: "mn"; name: "Mongolian" }
//         ListElement { code: "tat"; name: "Tatar" }
//         ListElement { code: "chu"; name: "Chuvash" }
//         ListElement { code: "os"; name: "Ossetian" }
//         ListElement { code: "udm"; name: "Udmurt" }
//         ListElement { code: "kbd"; name: "Kabardian" }
//         ListElement { code: "che"; name: "Chechen" }

//         // --- Asia & Pacific ---
//         ListElement { code: "au"; name: "English (Australia)" }
//         ListElement { code: "nz"; name: "English (New Zealand)" }
//         ListElement { code: "cn"; name: "Chinese" }
//         ListElement { code: "jp"; name: "Japanese" }
//         ListElement { code: "kr"; name: "Korean" }
//         ListElement { code: "tw"; name: "Taiwanese" }
//         ListElement { code: "hk"; name: "Hong Kong" }
//         ListElement { code: "in"; name: "Indian" }
//         ListElement { code: "pk"; name: "Pakistani" }
//         ListElement { code: "bd"; name: "Bangla" }
//         ListElement { code: "lk"; name: "Sri Lankan" }
//         ListElement { code: "np"; name: "Nepali" }
//         ListElement { code: "mv"; name: "Maldivian (Dhivehi)" }
//         ListElement { code: "bt"; name: "Bhutanese (Dzongkha)" }
//         ListElement { code: "af"; name: "Afghan (Pashto/Dari)" }
//         ListElement { code: "th"; name: "Thai" }
//         ListElement { code: "vn"; name: "Vietnamese" }
//         ListElement { code: "la"; name: "Lao" }
//         ListElement { code: "mm"; name: "Burmese" }
//         ListElement { code: "kh"; name: "Khmer" }
//         ListElement { code: "id"; name: "Indonesian" }
//         ListElement { code: "my"; name: "Malay" }
//         ListElement { code: "ph"; name: "Filipino" }
//         ListElement { code: "sg"; name: "Singaporean" }
//         ListElement { code: "bn"; name: "Bengali" }
//         ListElement { code: "ta"; name: "Tamil" }
//         ListElement { code: "te"; name: "Telugu" }
//         ListElement { code: "gu"; name: "Gujarati" }
//         ListElement { code: "pa"; name: "Punjabi" }
//         ListElement { code: "ml"; name: "Malayalam" }
//         ListElement { code: "kn"; name: "Kannada" }
//         ListElement { code: "or"; name: "Odia" }
//         ListElement { code: "as"; name: "Assamese" }
//         ListElement { code: "ur"; name: "Urdu" }

//         // --- Middle East & North Africa ---
//         ListElement { code: "il"; name: "Hebrew" }
//         ListElement { code: "ara"; name: "Arabic" }
//         ListElement { code: "iq"; name: "Iraqi" }
//         ListElement { code: "sy"; name: "Syrian" }
//         ListElement { code: "ir"; name: "Persian (Farsi)" }
//         ListElement { code: "ma"; name: "Moroccan" }
//         ListElement { code: "dz"; name: "Algerian" }
//         ListElement { code: "eg"; name: "Egyptian" }
//         ListElement { code: "ly"; name: "Libyan" }
//         ListElement { code: "tn"; name: "Tunisian" }
//         ListElement { code: "sd"; name: "Sudanese" }
//         ListElement { code: "lb"; name: "Lebanese" }
//         ListElement { code: "jo"; name: "Jordanian" }
//         ListElement { code: "ps"; name: "Palestinian" }
//         ListElement { code: "sa"; name: "Saudi Arabian" }
//         ListElement { code: "kw"; name: "Kuwaiti" }
//         ListElement { code: "bh"; name: "Bahraini" }
//         ListElement { code: "qa"; name: "Qatari" }
//         ListElement { code: "ae"; name: "UAE" }
//         ListElement { code: "om"; name: "Omani" }
//         ListElement { code: "ye"; name: "Yemeni" }

//         // --- Sub-Saharan Africa ---
//         ListElement { code: "za"; name: "English (South Africa)" }
//         ListElement { code: "ng"; name: "Nigerian" }
//         ListElement { code: "et"; name: "Ethiopian" }
//         ListElement { code: "sn"; name: "Senegalese" }
//         ListElement { code: "ke"; name: "Kenyan" }
//         ListElement { code: "tz"; name: "Tanzanian" }
//         ListElement { code: "gh"; name: "Ghanaian" }
//         ListElement { code: "cm"; name: "Cameroonian" }
//         ListElement { code: "ci"; name: "Ivorian" }
//         ListElement { code: "ml"; name: "Malian" }
//         ListElement { code: "gn"; name: "Guinean" }
//         ListElement { code: "cd"; name: "Congolese (DRC)" }
//         ListElement { code: "cg"; name: "Congolese (RC)" }
//         ListElement { code: "rw"; name: "Rwandan" }
//         ListElement { code: "bi"; name: "Burundian" }
//         ListElement { code: "ug"; name: "Ugandan" }
//         ListElement { code: "zm"; name: "Zambian" }
//         ListElement { code: "zw"; name: "Zimbabwean" }
//         ListElement { code: "mw"; name: "Malawian" }
//         ListElement { code: "mz"; name: "Mozambican" }
//         ListElement { code: "ao"; name: "Angolan" }
//         ListElement { code: "na"; name: "Namibian" }
//         ListElement { code: "bw"; name: "Motswana" }
//         ListElement { code: "mg"; name: "Malagasy" }
//         ListElement { code: "so"; name: "Somali" }
//         ListElement { code: "dj"; name: "Djiboutian" }
//         ListElement { code: "er"; name: "Eritrean" }
//         ListElement { code: "tg"; name: "Togolese" }
//         ListElement { code: "bj"; name: "Beninese" }
//         ListElement { code: "bf"; name: "Burkinabe" }
//         ListElement { code: "ne"; name: "Nigerien" }
//         ListElement { code: "td"; name: "Chadian" }
//         ListElement { code: "cf"; name: "Central African" }
//         ListElement { code: "gq"; name: "Equatorial Guinean" }
//         ListElement { code: "ga"; name: "Gabonese" }

//         // --- Alternative Layouts ---
//         ListElement { code: "us-intl"; name: "US International" }
//         ListElement { code: "dvorak"; name: "US Dvorak" }
//         ListElement { code: "colemak"; name: "US Colemak" }
//         ListElement { code: "norman"; name: "US Norman" }
//         ListElement { code: "workman"; name: "US Workman" }
//         ListElement { code: "math"; name: "Mathematics" }
//         ListElement { code: "brai"; name: "Braille" }
//     }

//     ListModel { id: pathSuggestModel }
//     ListModel { id: langSearchModel }

//     function updateLangSearch(query) {
//         langSearchModel.clear();
//         let q = query.trim().toLowerCase();
//         for (let i = 0; i < langModel.count; i++) {
//             let item = langModel.get(i);
//             if (q === "" || item.code.toLowerCase().includes(q) || item.name.toLowerCase().includes(q)) {
//                 langSearchModel.append({ code: item.code, name: item.name });
//             }
//         }
//     }

//     Process {
//         id: pathSuggestProc
//         property string query: ""
//         command: ["bash", "-c", "eval ls -dp " + query + "* 2>/dev/null | grep '/$' | head -n 5 || true"]
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 pathSuggestModel.clear();
//                 if (this.text) {
//                     let lines = this.text.trim().split('\n');
//                     for (let i = 0; i < lines.length; i++) {
//                         let line = lines[i];
//                         if (line.length > 0) {
//                             if (line.endsWith('/')) { line = line.slice(0, -1); }
//                             pathSuggestModel.append({ path: line });
//                         }
//                     }
//                 }
//             }
//         }
//     }

//     property var allSettingsCards: [
//         { tab: 0, boxIndex: 0, label: "Guide on startup",  desc: "Launch on login",        icon: "󰑊", color: "peach" },
//         { tab: 0, boxIndex: 1, label: "Help icon",         desc: "Show button in topbar",  icon: "󰋖", color: "blue" },
//         { tab: 0, boxIndex: 2, label: "UI Scale",          desc: "Base size scalar",       icon: "󰁦", color: "sapphire" },
//         { tab: 0, boxIndex: 3, label: "Keyboard layouts",  desc: "Matches hyprland.conf",  icon: "󰌌", color: "green" },
//         { tab: 0, boxIndex: 4, label: "Layout shortcut",   desc: "Toggle combination",     icon: "󰯍", color: "teal" },
//         { tab: 0, boxIndex: 5, label: "Wallpaper directory",desc: "Absolute source path",  icon: "󰋩", color: "mauve" },
//         { tab: 0, boxIndex: 6, label: "Workspaces",        desc: "Static count in topbar", icon: "󰽿", color: "red" },
//         { tab: 1, boxIndex: 1, label: "API Key",           desc: "OpenWeather API key",    icon: "󰌆", color: "blue" },
//         { tab: 1, boxIndex: 2, label: "City ID",           desc: "OpenWeather city ID",    icon: "󰖐", color: "blue" },
//         { tab: 1, boxIndex: 3, label: "Temperature Unit",  desc: "Celsius / Fahrenheit / K", icon: "󰔄", color: "blue" }
//     ]

//     function getMatchingKeybindIndices(query) {
//         if (query.trim() === "") return [];
//         let results = [];
//         try {
//             let re = new RegExp(query, "i");
//             for (let i = 0; i < dynamicKeybindsModel.count; i++) {
//                 let item = dynamicKeybindsModel.get(i);
//                 if (re.test(item.mods) || re.test(item.key) || re.test(item.dispatcher) || re.test(item.command) || re.test(item.type)) {
//                     results.push(i);
//                 }
//             }
//         } catch(e) {
//             let q = query.trim().toLowerCase();
//             for (let i = 0; i < dynamicKeybindsModel.count; i++) {
//                 let item = dynamicKeybindsModel.get(i);
//                 if ((item.mods && item.mods.toLowerCase().includes(q)) ||
//                     (item.key && item.key.toLowerCase().includes(q)) ||
//                     (item.dispatcher && item.dispatcher.toLowerCase().includes(q)) ||
//                     (item.command && item.command.toLowerCase().includes(q))) {
//                     results.push(i);
//                 }
//             }
//         }
//         return results;
//     }

//     property var matchingKeybindIndices: []

//     function globalSearchMatches(card, query) {
//         if (query.trim() === "") return false;
//         let q = query.trim().toLowerCase();
//         return card.label.toLowerCase().includes(q) || card.desc.toLowerCase().includes(q);
//     }

//     property real introContent: 0.0
//     Component.onCompleted: { 
//         root.tab0Loaded = true;
//         startupSequence.start(); 
        
//         // Since Config is a Singleton, it might ALREADY be loaded before 
//         // this window is created. If so, pull the data manually.
//         if (Config.dataReady && dynamicKeybindsModel.count === 0) {
//             dynamicKeybindsModel.append(Config.keybindsData);
//         }
//     }

//     SequentialAnimation {
//         id: startupSequence
//         PauseAnimation { duration: 50 }
//         NumberAnimation { 
//             target: root
//             property: "introContent"
//             from: 0.0
//             to: 1.0
//             duration: 600
//             easing.type: Easing.OutQuart
//         } 
//     }

//     SequentialAnimation {
//         id: closeSequence
//         NumberAnimation { 
//             target: root
//             property: "introContent"
//             to: 0.0
//             duration: 200
//             easing.type: Easing.InQuart
//         }
//         ScriptAction { 
//             script: {
//                 Quickshell.execDetached(["hyprctl", "dispatch", "submap", "reset"]);
//                 Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
//             } 
//         }    
//     }

//     Component {
//         id: generalTabComponent
//         Item {
//             id: generalTabRoot

//             function focusLangInput() { langInput.forceActiveFocus(); }
//             function focusWpDirInput() { wpDirInput.forceActiveFocus(); }
//             function layoutListIncrementIndex() { layoutListView.incrementCurrentIndex(); }
//             function layoutListDecrementIndex() { layoutListView.decrementCurrentIndex(); }
//             function acceptLayoutSelection() {
//                 if (layoutListView.currentIndex >= 0 && layoutListView.currentIndex < root.kbToggleModelArr.length) {
//                     Config.kbOptions = root.kbToggleModelArr[layoutListView.currentIndex].val;
//                 }
//             }
//             function scrollTo(y) {
//                 let maxY = Math.max(0, generalFlickable.contentHeight - generalFlickable.height);
//                 generalFlickable.contentY = Math.max(0, Math.min(y - root.s(40), maxY > 0 ? maxY : y));
//             }
//             function scrollToBox(approxItemY) {
//                 let viewH = generalFlickable.height;
//                 let itemTop = approxItemY;
//                 let itemBottom = approxItemY + root.s(80);
//                 let curY = generalFlickable.contentY;
//                 let maxY = Math.max(0, generalFlickable.contentHeight - viewH);
//                 if (itemTop < curY + root.s(10)) {
//                     generalFlickable.contentY = Math.max(0, itemTop - root.s(20));
//                 } else if (itemBottom > curY + viewH - root.s(10)) {
//                     generalFlickable.contentY = Math.min(maxY, itemBottom - viewH + root.s(20));
//                 }
//             }

//             Flickable {
//                 id: generalFlickable
//                 anchors.fill: parent
//                 contentWidth: width
//                 contentHeight: settingsMainCol.implicitHeight + root.s(100)
//                 boundsBehavior: Flickable.StopAtBounds
//                 clip: true

//                 MouseArea {
//                     anchors.fill: parent
//                     onClicked: root.clearHighlight()
//                     z: -1
//                 }

//                 ColumnLayout {
//                     id: settingsMainCol
//                     width: parent.width
//                     spacing: root.s(10)

//                     // ── Box 0: Guide on startup ──────────────────────────────
//                     Rectangle {
//                         id: box0
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: guideRow.implicitHeight + root.s(28)
//                         radius: root.s(12)

//                         property bool isActive: root.highlightedBox === 0
//                         color: isActive ? root.peach : root.surface0
//                         border.color: isActive ? root.peach : root.surface1
//                         border.width: 1
//                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

//                         MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 0; z: -1 }

//                         RowLayout {
//                             id: guideRow
//                             anchors.top: parent.top
//                             anchors.left: parent.left
//                             anchors.right: parent.right
//                             anchors.margins: root.s(16)
//                             spacing: root.s(14)
//                             Item {
//                                 Layout.preferredWidth: root.s(22)
//                                 Layout.alignment: Qt.AlignVCenter
//                                 Text {
//                                     anchors.centerIn: parent
//                                     text: "󰑊"
//                                     font.family: "Iosevka Nerd Font"
//                                     font.pixelSize: root.s(18)
//                                     color: box0.isActive ? root.base : root.peach
//                                     Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                 }
//                             }
//                             ColumnLayout {
//                                 Layout.fillWidth: true
//                                 Layout.alignment: Qt.AlignVCenter
//                                 spacing: root.s(3)
//                                 Text {
//                                     text: "Guide on startup"
//                                     font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
//                                     color: box0.isActive ? root.base : root.text
//                                     Layout.fillWidth: true
//                                     Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                 }
//                                 Text {
//                                     text: "Launch on login"
//                                     font.family: "Inter"; font.pixelSize: root.s(11)
//                                     color: box0.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7)
//                                     Layout.fillWidth: true
//                                     Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                 }
//                             }
//                             Rectangle {
//                                 Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
//                                 Layout.preferredWidth: root.s(40)
//                                 Layout.preferredHeight: root.s(22)
//                                 radius: root.s(11)
//                                 scale: toggle1Ma.containsMouse ? 1.05 : 1.0
//                                 Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
//                                 color: Config.openGuideAtStartup
//                                     ? (box0.isActive ? root.base : root.peach)
//                                     : Qt.alpha(root.surface2, box0.isActive ? 0.4 : 1.0)
//                                 Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                 Rectangle {
//                                     width: root.s(16); height: root.s(16); radius: root.s(8)
//                                     color: Config.openGuideAtStartup
//                                         ? (box0.isActive ? root.peach : root.base)
//                                         : (box0.isActive ? root.peach : root.surface0)
//                                     y: root.s(3); x: Config.openGuideAtStartup ? root.s(21) : root.s(3)
//                                     Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
//                                     Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                 }
//                                 MouseArea { id: toggle1Ma; anchors.fill: parent; hoverEnabled: true; onClicked: Config.openGuideAtStartup = !Config.openGuideAtStartup; cursorShape: Qt.PointingHandCursor }
//                             }
//                         }
//                     }

//                     // ── Box 1: Help icon ─────────────────────────────────────
//                     Rectangle {
//                         id: box1
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: helpIconRow.implicitHeight + root.s(28)
//                         radius: root.s(12)

//                         property bool isActive: root.highlightedBox === 1
//                         color: isActive ? root.blue : root.surface0
//                         border.color: isActive ? root.blue : root.surface1
//                         border.width: 1
//                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

//                         MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 1; z: -1 }

//                         RowLayout {
//                             id: helpIconRow
//                             anchors.top: parent.top
//                             anchors.left: parent.left
//                             anchors.right: parent.right
//                             anchors.margins: root.s(16)
//                             spacing: root.s(14)
//                             Item {
//                                 Layout.preferredWidth: root.s(22)
//                                 Layout.alignment: Qt.AlignVCenter
//                                 Text {
//                                     anchors.centerIn: parent; text: "󰋖"
//                                     font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
//                                     color: box1.isActive ? root.base : root.blue
//                                     Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                 }
//                             }
//                             ColumnLayout {
//                                 Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: root.s(3)
//                                 Text {
//                                     text: "Help icon"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
//                                     color: box1.isActive ? root.base : root.text; Layout.fillWidth: true
//                                     Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                 }
//                                 Text {
//                                     text: "Show button in topbar"; font.family: "Inter"; font.pixelSize: root.s(11)
//                                     color: box1.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
//                                     Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                 }
//                             }
//                             Rectangle {
//                                 Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
//                                 Layout.preferredWidth: root.s(40); Layout.preferredHeight: root.s(22); radius: root.s(11)
//                                 scale: toggle2Ma.containsMouse ? 1.05 : 1.0
//                                 Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
//                                 color: Config.topbarHelpIcon
//                                     ? (box1.isActive ? root.base : root.blue)
//                                     : Qt.alpha(root.surface2, box1.isActive ? 0.4 : 1.0)
//                                 Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                 Rectangle {
//                                     width: root.s(16); height: root.s(16); radius: root.s(8)
//                                     color: Config.topbarHelpIcon
//                                         ? (box1.isActive ? root.blue : root.base)
//                                         : (box1.isActive ? root.blue : root.surface0)
//                                     y: root.s(3); x: Config.topbarHelpIcon ? root.s(21) : root.s(3)
//                                     Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
//                                     Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                 }
//                                 MouseArea { id: toggle2Ma; anchors.fill: parent; hoverEnabled: true; onClicked: Config.topbarHelpIcon = !Config.topbarHelpIcon; cursorShape: Qt.PointingHandCursor }
//                             }
//                         }
//                     }

//                     // ── Box 2: UI Scale ──────────────────────────────────────
//                     Rectangle {
//                         id: box2
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: col2.implicitHeight + root.s(32)
//                         radius: root.s(12)

//                         property bool isActive: root.highlightedBox === 2
//                         color: isActive ? root.sapphire : root.surface0
//                         border.color: isActive ? root.sapphire : root.surface1
//                         border.width: 1
//                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

//                         MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 2; z: -1 }

//                         ColumnLayout {
//                             id: col2
//                             anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
//                             RowLayout {
//                                 Layout.fillWidth: true; spacing: root.s(14)
//                                 Item {
//                                     Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter
//                                     Text {
//                                         anchors.centerIn: parent; text: "󰁦"
//                                         font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
//                                         color: box2.isActive ? root.base : root.sapphire
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                 }
//                                 ColumnLayout {
//                                     Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: root.s(3)
//                                     Text {
//                                         text: "UI Scale"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
//                                         color: box2.isActive ? root.base : root.text; Layout.fillWidth: true
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                     Text {
//                                         text: "Base size scalar"; font.family: "Inter"; font.pixelSize: root.s(11)
//                                         color: box2.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                 }
//                                 RowLayout {
//                                     Layout.alignment: Qt.AlignVCenter | Qt.AlignRight; spacing: root.s(10)
//                                     Rectangle {
//                                         width: root.s(28); height: root.s(28); radius: root.s(6)
//                                         color: sMinusMa.pressed
//                                             ? Qt.alpha(root.base, 0.3)
//                                             : (sMinusMa.containsMouse
//                                                 ? Qt.alpha(root.base, 0.2)
//                                                 : Qt.alpha(root.base, 0.15))
//                                         scale: sMinusMa.pressed ? 0.90 : (sMinusMa.containsMouse ? 1.08 : 1.0)
//                                         Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
//                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                         Text {
//                                             anchors.centerIn: parent; text: "-"
//                                             font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: root.s(15)
//                                             color: box2.isActive ? root.base : root.sapphire
//                                             Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                         }
//                                         MouseArea { id: sMinusMa; anchors.fill: parent; hoverEnabled: true; onClicked: Config.uiScale = Math.max(0.5, (Config.uiScale - 0.1).toFixed(1)) }
//                                     }
//                                     Text { 
//                                         text: Config.uiScale.toFixed(1) + "x"
//                                         font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(13)
//                                         color: box2.isActive ? root.base : root.sapphire
//                                         Layout.minimumWidth: root.s(36); horizontalAlignment: Text.AlignHCenter
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                     Rectangle {
//                                         width: root.s(28); height: root.s(28); radius: root.s(6)
//                                         color: sPlusMa.pressed
//                                             ? Qt.alpha(root.base, 0.3)
//                                             : (sPlusMa.containsMouse ? Qt.alpha(root.base, 0.2) : Qt.alpha(root.base, 0.15))
//                                         scale: sPlusMa.pressed ? 0.90 : (sPlusMa.containsMouse ? 1.08 : 1.0)
//                                         Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
//                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                         Text {
//                                             anchors.centerIn: parent; text: "+"
//                                             font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: root.s(15)
//                                             color: box2.isActive ? root.base : root.sapphire
//                                             Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                         }
//                                         MouseArea { id: sPlusMa; anchors.fill: parent; hoverEnabled: true; onClicked: Config.uiScale = Math.min(2.0, (Config.uiScale + 0.1).toFixed(1)) }
//                                     }
//                                 }
//                             }
//                         }
//                     }

//                     // ── Box 3: Keyboard layouts ──────────────────────────────
//                     Rectangle {
//                         id: box3
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: col3lang.implicitHeight + root.s(32)
//                         radius: root.s(12)

//                         property bool isActive: root.highlightedBox === 3
//                         color: isActive ? root.green : root.surface0
//                         border.color: isActive ? root.green : root.surface1
//                         border.width: 1
//                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

//                         MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 3; z: -1 }

//                         ColumnLayout {
//                             id: col3lang
//                             anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
//                             spacing: root.s(16)
//                             RowLayout {
//                                 Layout.fillWidth: true; spacing: root.s(14)
//                                 Item {
//                                     Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignTop; Layout.topMargin: root.s(2)
//                                     Text {
//                                         anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
//                                         text: "󰌌"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
//                                         color: box3.isActive ? root.base : root.green
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                 }
//                                 ColumnLayout {
//                                     Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: root.s(3)
//                                     Text {
//                                         text: "Keyboard layouts"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
//                                         color: box3.isActive ? root.base : root.text; Layout.fillWidth: true
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                     Text {
//                                         text: "Matches hyprland.conf. Click ✖ to remove."; font.family: "Inter"; font.pixelSize: root.s(11)
//                                         color: box3.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                     Flow {
//                                         Layout.fillWidth: true; spacing: root.s(6); Layout.topMargin: root.s(8)
//                                         Repeater {
//                                             model: Config.language ? Config.language.split(",").filter(x => x.trim() !== "") : []
//                                             Rectangle {
//                                                 width: langChipLayout.implicitWidth + root.s(20); height: root.s(26); radius: root.s(13)
//                                                 color: box3.isActive ? Qt.alpha(root.base, 0.2) : root.surface1
//                                                 border.color: chipMa.containsMouse ? root.red : (box3.isActive ? Qt.alpha(root.base, 0.4) : "transparent")
//                                                 border.width: chipMa.containsMouse ? 1 : 0
//                                                 scale: chipMa.containsMouse ? 1.05 : 1.0
//                                                 Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
//                                                 Behavior on border.color { ColorAnimation { duration: 150 } }
//                                                 RowLayout {
//                                                     id: langChipLayout; anchors.centerIn: parent; spacing: root.s(6)
//                                                     Text {
//                                                         text: modelData; font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: root.s(11)
//                                                         color: chipMa.containsMouse ? root.red : (box3.isActive ? root.base : root.text)
//                                                         Behavior on color { ColorAnimation { duration: 150 } }
//                                                     }
//                                                     Text {
//                                                         text: "✖"; font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
//                                                         color: chipMa.containsMouse ? root.red : (box3.isActive ? Qt.alpha(root.base, 0.6) : root.subtext0)
//                                                         Behavior on color { ColorAnimation { duration: 150 } }
//                                                     }
//                                                 }
//                                                 MouseArea {
//                                                     id: chipMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                                                     onClicked: {
//                                                         let arr = Config.language.split(",").filter(x => x.trim() !== "");
//                                                         arr.splice(index, 1);
//                                                         Config.language = arr.join(",");
//                                                     }
//                                                 }
//                                             }
//                                         }
//                                     }
//                                 }
//                             }
//                             Rectangle {
//                                 Layout.fillWidth: true; Layout.preferredHeight: root.s(34); Layout.topMargin: root.s(8)
//                                 radius: root.s(7)
//                                 color: box3.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
//                                 border.color: langInput.activeFocus
//                                     ? (box3.isActive ? root.base : root.green)
//                                     : (box3.isActive ? Qt.alpha(root.base, 0.3) : root.surface2)
//                                 border.width: 1
//                                 Behavior on border.color { ColorAnimation { duration: 200 } }
//                                 Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                 TextInput {
//                                     id: langInput
//                                     anchors.fill: parent; anchors.margins: root.s(9)
//                                     verticalAlignment: TextInput.AlignVCenter
//                                     font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
//                                     color: box3.isActive ? root.base : root.text; clip: true; selectByMouse: true
//                                     Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     Keys.onPressed: (event) => {
//                                         if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down) {
//                                             if (langSearchModel.count > 0) { langListView.incrementCurrentIndex(); event.accepted = true; }
//                                         } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up) {
//                                             if (langSearchModel.count > 0) { langListView.decrementCurrentIndex(); event.accepted = true; }
//                                         }
//                                     }
//                                     Keys.onReturnPressed: (event) => langInputAccept(event)
//                                     Keys.onEnterPressed: (event) => langInputAccept(event)
//                                     function langInputAccept(event) {
//                                         if (langSearchModel.count > 0 && langListView.currentIndex >= 0) {
//                                             let item = langSearchModel.get(langListView.currentIndex);
//                                             let arr = Config.language ? Config.language.split(",").filter(x => x.trim() !== "") : [];
//                                             if (!arr.includes(item.code)) { arr.push(item.code); Config.language = arr.join(","); }
//                                         }
//                                         text = ""; focus = false; event.accepted = true;
//                                     }
//                                     onActiveFocusChanged: { if (activeFocus) root.updateLangSearch(text); }
//                                     onTextChanged: { root.updateLangSearch(text); }
//                                     Text {
//                                         text: "Search to add..."
//                                         color: box3.isActive ? Qt.alpha(root.base, 0.5) : Qt.alpha(root.subtext0, 0.7)
//                                         visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                 }
//                             }
//                             Rectangle {
//                                 Layout.fillWidth: true
//                                 Layout.preferredHeight: langInput.activeFocus && langSearchModel.count > 0 ? Math.min(root.s(160), langSearchModel.count * root.s(30) + root.s(8)) : 0
//                                 radius: root.s(7)
//                                 color: box3.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
//                                 border.color: box3.isActive ? Qt.alpha(root.base, 0.3) : root.surface1
//                                 border.width: 1
//                                 clip: true
//                                 Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                                 Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                 ListView {
//                                     id: langListView
//                                     anchors.fill: parent; anchors.topMargin: root.s(4); anchors.bottomMargin: root.s(4)
//                                     model: langSearchModel; interactive: true
//                                     opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0
//                                     Behavior on opacity { NumberAnimation { duration: 200 } }
//                                     ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }
//                                     delegate: Rectangle {
//                                         width: parent.width - root.s(8); height: root.s(30)
//                                         anchors.horizontalCenter: parent.horizontalCenter; radius: root.s(4)
//                                         property bool isHovered: sMa.containsMouse
//                                         color: isHovered
//                                             ? Qt.alpha(box3.isActive ? root.base : root.green, 0.2)
//                                             : (ListView.isCurrentItem ? Qt.alpha(box3.isActive ? root.base : root.green, 0.1) : "transparent")
//                                         Behavior on color { ColorAnimation { duration: 150 } }
//                                         RowLayout {
//                                             anchors.fill: parent; anchors.leftMargin: root.s(8); anchors.rightMargin: root.s(8); spacing: root.s(8)
//                                             Text { text: model.code; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(11); color: box3.isActive ? root.base : root.text; Behavior on color { ColorAnimation { duration: 150 } } }
//                                             Text { text: model.name; font.family: "Inter"; font.pixelSize: root.s(11); color: box3.isActive ? Qt.alpha(root.base, 0.7) : Qt.alpha(root.subtext0, 0.7); elide: Text.ElideRight; Layout.fillWidth: true; Behavior on color { ColorAnimation { duration: 150 } } }
//                                         }
//                                         MouseArea {
//                                             id: sMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                                             onClicked: {
//                                                 let arr = Config.language ? Config.language.split(",").filter(x => x.trim() !== "") : [];
//                                                 if (!arr.includes(model.code)) { arr.push(model.code); Config.language = arr.join(","); }
//                                                 langInput.text = ""; langInput.focus = false;
//                                             }
//                                         }
//                                     }
//                                 }
//                             }
//                         }                       
//                     }

//                     // ── Box 4: Layout shortcut ───────────────────────────────
//                     Rectangle {
//                         id: box4
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: col4layout.implicitHeight + root.s(32)
//                         radius: root.s(12)

//                         property bool isActive: root.highlightedBox === 4
//                         color: isActive ? root.teal : root.surface0
//                         border.color: isActive ? root.teal : root.surface1
//                         border.width: 1
//                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

//                         MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 4; z: -1 }

//                         ColumnLayout {
//                             id: col4layout
//                             anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
//                             spacing: root.s(16)
//                             RowLayout {
//                                 Layout.fillWidth: true; spacing: root.s(14)
//                                 Item {
//                                     Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignTop; Layout.topMargin: root.s(2)
//                                     Text {
//                                         anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
//                                         text: "󰯍"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
//                                         color: box4.isActive ? root.base : root.teal
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                 }
//                                 ColumnLayout {
//                                     Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: root.s(3)
//                                     Text {
//                                         text: "Layout shortcut"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
//                                         color: box4.isActive ? root.base : root.text; Layout.fillWidth: true
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                     Text {
//                                         text: "Toggle combination"; font.family: "Inter"; font.pixelSize: root.s(11)
//                                         color: box4.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                     Rectangle {
//                                         Layout.fillWidth: true; Layout.preferredHeight: root.s(34); Layout.topMargin: root.s(8)
//                                         radius: root.s(7)
//                                         color: box4.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
//                                         border.color: root.isLayoutDropdownOpen
//                                             ? (box4.isActive ? root.base : root.teal)
//                                             : (box4.isActive ? Qt.alpha(root.base, 0.3) : root.surface2)
//                                         border.width: 1
//                                         Behavior on border.color { ColorAnimation { duration: 200 } }
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                         RowLayout {
//                                             anchors.fill: parent; anchors.margins: root.s(9)
//                                             Text {
//                                                 text: root.getKbToggleLabel(Config.kbOptions)
//                                                 font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
//                                                 color: box4.isActive ? root.base : root.text; Layout.fillWidth: true
//                                                 Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                             }
//                                             Text {
//                                                 text: root.isLayoutDropdownOpen ? "▴" : "▾"; font.pixelSize: root.s(12)
//                                                 color: box4.isActive ? Qt.alpha(root.base, 0.7) : root.subtext0
//                                                 Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                             }
//                                         }
//                                         MouseArea {
//                                             anchors.fill: parent; cursorShape: Qt.PointingHandCursor
//                                             onClicked: {
//                                                 root.isLayoutDropdownOpen = !root.isLayoutDropdownOpen;
//                                                 if (root.isLayoutDropdownOpen) {
//                                                     let idx = root.kbToggleModelArr.findIndex(x => x.val === Config.kbOptions);
//                                                     layoutListView.currentIndex = Math.max(0, idx);
//                                                 }
//                                                 root.forceActiveFocus();
//                                             }
//                                         }
//                                     }
//                                     Rectangle {
//                                         Layout.fillWidth: true
//                                         Layout.preferredHeight: root.isLayoutDropdownOpen ? root.kbToggleModelArr.length * root.s(30) + root.s(8) : 0
//                                         radius: root.s(7)
//                                         color: box4.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
//                                         border.color: box4.isActive ? Qt.alpha(root.base, 0.3) : root.surface1
//                                         border.width: 1
//                                         clip: true
//                                         Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                         ListView {
//                                             id: layoutListView
//                                             anchors.fill: parent; anchors.topMargin: root.s(4); anchors.bottomMargin: root.s(4)
//                                             model: root.kbToggleModelArr; interactive: false
//                                             opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0
//                                             Behavior on opacity { NumberAnimation { duration: 200 } }
//                                             delegate: Rectangle {
//                                                 width: parent.width - root.s(8); height: root.s(30)
//                                                 anchors.horizontalCenter: parent.horizontalCenter; radius: root.s(4)
//                                                 property bool isHovered: toggleMa.containsMouse
//                                                 color: isHovered
//                                                     ? Qt.alpha(box4.isActive ? root.base : root.teal, 0.2)
//                                                     : (ListView.isCurrentItem ? Qt.alpha(box4.isActive ? root.base : root.teal, 0.1) : "transparent")
//                                                 Behavior on color { ColorAnimation { duration: 150 } }
//                                                 RowLayout {
//                                                     anchors.fill: parent; anchors.leftMargin: root.s(8); anchors.rightMargin: root.s(8)
//                                                     Text {
//                                                         text: modelData.label; font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
//                                                         color: Config.kbOptions === modelData.val
//                                                             ? (box4.isActive ? root.base : root.teal)
//                                                             : (box4.isActive ? Qt.alpha(root.base, 0.8) : root.text)
//                                                         Layout.fillWidth: true
//                                                         Behavior on color { ColorAnimation { duration: 150 } }
//                                                     }
//                                                 }
//                                                 MouseArea { id: toggleMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Config.kbOptions = modelData.val; root.isLayoutDropdownOpen = false; } }
//                                             }
//                                         }
//                                     }
//                                 }
//                             }
//                         }
//                     }

//                     // ── Box 5: Wallpaper directory ───────────────────────────
//                     Rectangle {
//                         id: box5
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: col5wp.implicitHeight + root.s(32)
//                         radius: root.s(12)

//                         property bool isActive: root.highlightedBox === 5
//                         color: isActive ? root.mauve : root.surface0
//                         border.color: isActive ? root.mauve : root.surface1
//                         border.width: 1
//                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

//                         MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 5; z: -1 }

//                         ColumnLayout {
//                             id: col5wp
//                             anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
//                             RowLayout {
//                                 Layout.fillWidth: true; spacing: root.s(14)
//                                 Item {
//                                     Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignTop; Layout.topMargin: root.s(2)
//                                     Text {
//                                         anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
//                                         text: "󰋩"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
//                                         color: box5.isActive ? root.base : root.mauve
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                 }
//                                 ColumnLayout {
//                                     Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: root.s(3)
//                                     Text {
//                                         text: "Wallpaper directory"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
//                                         color: box5.isActive ? root.base : root.text; Layout.fillWidth: true
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                     Text {
//                                         text: "Absolute source path"; font.family: "Inter"; font.pixelSize: root.s(11)
//                                         color: box5.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                     Rectangle {
//                                         Layout.fillWidth: true; Layout.preferredHeight: root.s(34); Layout.topMargin: root.s(8)
//                                         radius: root.s(7)
//                                         color: box5.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
//                                         border.color: wpDirInput.activeFocus
//                                             ? (box5.isActive ? root.base : root.mauve)
//                                             : (box5.isActive ? Qt.alpha(root.base, 0.3) : root.surface2)
//                                         border.width: 1
//                                         Behavior on border.color { ColorAnimation { duration: 200 } }
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                         TextInput {
//                                             id: wpDirInput
//                                             anchors.fill: parent; anchors.margins: root.s(9)
//                                             verticalAlignment: TextInput.AlignVCenter
//                                             text: Config.wallpaperDir
//                                             font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
//                                             color: box5.isActive ? root.base : root.text; clip: true; selectByMouse: true
//                                             Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                             Keys.onPressed: (event) => {
//                                                 if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down) {
//                                                     if (pathSuggestModel.count > 0) { wpSuggestListView.incrementCurrentIndex(); event.accepted = true; }
//                                                 } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up) {
//                                                     if (pathSuggestModel.count > 0) { wpSuggestListView.decrementCurrentIndex(); event.accepted = true; }
//                                                 }
//                                             }
//                                             Keys.onReturnPressed: (event) => wpDirInputAccept(event)
//                                             Keys.onEnterPressed: (event) => wpDirInputAccept(event)
//                                             function wpDirInputAccept(event) {
//                                                 if (pathSuggestModel.count > 0 && wpSuggestListView.currentIndex >= 0) {
//                                                     let item = pathSuggestModel.get(wpSuggestListView.currentIndex);
//                                                     if (item) { text = item.path; Config.wallpaperDir = text; }
//                                                 }
//                                                 pathSuggestModel.clear(); focus = false; event.accepted = true;
//                                             }
//                                             onActiveFocusChanged: {
//                                                 if (activeFocus) { pathSuggestProc.query = text; pathSuggestProc.running = false; pathSuggestProc.running = true; }
//                                             }
//                                             onTextChanged: {
//                                                 Config.wallpaperDir = text;
//                                                 if (activeFocus) { pathSuggestProc.query = text; pathSuggestProc.running = false; pathSuggestProc.running = true; }
//                                             }
//                                             Text {
//                                                 text: "Enter directory..."; color: box5.isActive ? Qt.alpha(root.base, 0.5) : root.subtext0
//                                                 visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter
//                                             }
//                                         }
//                                     }
//                                     Rectangle {
//                                         Layout.fillWidth: true
//                                         Layout.preferredHeight: wpDirInput.activeFocus && pathSuggestModel.count > 0 ? pathSuggestModel.count * root.s(28) + root.s(8) : 0
//                                         radius: root.s(7)
//                                         color: box5.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
//                                         border.color: box5.isActive ? Qt.alpha(root.base, 0.3) : root.surface1
//                                         border.width: 1
//                                         clip: true
//                                         Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                         ListView {
//                                             id: wpSuggestListView
//                                             anchors.fill: parent; anchors.topMargin: root.s(4); anchors.bottomMargin: root.s(4)
//                                             model: pathSuggestModel; interactive: false
//                                             opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0
//                                             Behavior on opacity { NumberAnimation { duration: 200 } }
//                                             delegate: Rectangle {
//                                                 width: parent.width - root.s(8); height: root.s(28)
//                                                 anchors.horizontalCenter: parent.horizontalCenter; radius: root.s(4)
//                                                 property bool isHovered: suggestMa.containsMouse
//                                                 color: isHovered
//                                                     ? Qt.alpha(box5.isActive ? root.base : root.mauve, 0.2)
//                                                     : (ListView.isCurrentItem ? Qt.alpha(box5.isActive ? root.base : root.mauve, 0.1) : "transparent")
//                                                 Behavior on color { ColorAnimation { duration: 150 } }
//                                                 Text {
//                                                     anchors.verticalCenter: parent.verticalCenter; x: root.s(8)
//                                                     text: model.path; font.family: "JetBrains Mono"; font.pixelSize: root.s(10)
//                                                     color: box5.isActive ? root.base : root.text
//                                                     elide: Text.ElideMiddle; width: parent.width - root.s(16)
//                                                     Behavior on color { ColorAnimation { duration: 150 } }
//                                                 }
//                                                 MouseArea { id: suggestMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { wpDirInput.text = model.path; pathSuggestModel.clear(); wpDirInput.focus = false; } }
//                                             }
//                                         }
//                                     }
//                                 }
//                             }
//                         }
//                     }

//                     // ── Box 6: Workspaces ────────────────────────────────────
//                     Rectangle {
//                         id: box6
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: col6ws.implicitHeight + root.s(32)
//                         radius: root.s(12)

//                         property bool isActive: root.highlightedBox === 6
//                         color: isActive ? root.red : root.surface0
//                         border.color: isActive ? root.red : root.surface1
//                         border.width: 1
//                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

//                         MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 6; z: -1 }

//                         ColumnLayout {
//                             id: col6ws
//                             anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
//                             RowLayout {
//                                 Layout.fillWidth: true; spacing: root.s(14)
//                                 Item {
//                                     Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter
//                                     Text {
//                                         anchors.centerIn: parent; text: "󰽿"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
//                                         color: box6.isActive ? root.base : root.red
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                 }
//                                 ColumnLayout {
//                                     Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: root.s(3)
//                                     Text {
//                                         text: "Workspaces"; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: root.s(14)
//                                         color: box6.isActive ? root.base : root.text; Layout.fillWidth: true
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                     Text {
//                                         text: "Static count in topbar"; font.family: "Inter"; font.pixelSize: root.s(11)
//                                         color: box6.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                 }
//                                 RowLayout {
//                                     Layout.alignment: Qt.AlignVCenter | Qt.AlignRight; spacing: root.s(10)
//                                     Rectangle {
//                                         width: root.s(28); height: root.s(28); radius: root.s(6)
//                                         color: wsMinusMa.pressed ? Qt.alpha(root.base, 0.3) : (wsMinusMa.containsMouse ? Qt.alpha(root.base, 0.2) : Qt.alpha(root.base, 0.15))
//                                         scale: wsMinusMa.pressed ? 0.90 : (wsMinusMa.containsMouse ? 1.08 : 1.0)
//                                         Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
//                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                         Text {
//                                             anchors.centerIn: parent; text: "-"
//                                             font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(15)
//                                             color: box6.isActive ? root.base : root.red
//                                             Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                         }
//                                         MouseArea { id: wsMinusMa; anchors.fill: parent; hoverEnabled: true; onClicked: Config.workspaceCount = Math.max(2, Config.workspaceCount - 1) }
//                                     }
//                                     Text { 
//                                         text: Config.workspaceCount.toString()
//                                         font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: root.s(14)
//                                         color: box6.isActive ? root.base : root.red
//                                         Layout.minimumWidth: root.s(36); horizontalAlignment: Text.AlignHCenter
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                     Rectangle {
//                                         width: root.s(28); height: root.s(28); radius: root.s(6)
//                                         color: wsPlusMa.pressed ? Qt.alpha(root.base, 0.3) : (wsPlusMa.containsMouse ? Qt.alpha(root.base, 0.2) : Qt.alpha(root.base, 0.15))
//                                         scale: wsPlusMa.pressed ? 0.90 : (wsPlusMa.containsMouse ? 1.08 : 1.0)
//                                         Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
//                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                         Text {
//                                             anchors.centerIn: parent; text: "+"
//                                             font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(15)
//                                             color: box6.isActive ? root.base : root.red
//                                             Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                         }
//                                         MouseArea { id: wsPlusMa; anchors.fill: parent; hoverEnabled: true; onClicked: Config.workspaceCount = Math.min(10, Config.workspaceCount + 1) }
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }        
//         }
//     }

//     Component {
//         id: weatherTabComponent
//         Item {
//             id: weatherTabRoot

//             function focusApiKey() { apiKeyInput.forceActiveFocus(); }
//             function focusCityId() { cityIdInput.forceActiveFocus(); }
//             function scrollTo(y) {
//                 let maxY = Math.max(0, weatherFlickable.contentHeight - weatherFlickable.height);
//                 weatherFlickable.contentY = Math.max(0, Math.min(y - root.s(40), maxY > 0 ? maxY : y));
//             }
//             function scrollToBox(approxItemY) {
//                 let viewH = weatherFlickable.height;
//                 let itemTop = approxItemY;
//                 let itemBottom = approxItemY + root.s(80);
//                 let curY = weatherFlickable.contentY;
//                 let maxY = Math.max(0, weatherFlickable.contentHeight - viewH);
//                 if (itemTop < curY + root.s(10)) {
//                     weatherFlickable.contentY = Math.max(0, itemTop - root.s(20));
//                 } else if (itemBottom > curY + viewH - root.s(10)) {
//                     weatherFlickable.contentY = Math.min(maxY, itemBottom - viewH + root.s(20));
//                 }
//             }

//             Component.onCompleted: {
//                 apiKeyInput.text = Config.weatherApiKey;
//                 cityIdInput.text = Config.weatherCityId;
//             }

//             Connections {
//                 target: Config
//                 function onWeatherApiKeyChanged() { if (apiKeyInput.text !== Config.weatherApiKey) apiKeyInput.text = Config.weatherApiKey; }
//                 function onWeatherCityIdChanged() { if (cityIdInput.text !== Config.weatherCityId) cityIdInput.text = Config.weatherCityId; }
//             }

//             property bool apiKeyVisible: false

//             Flickable {
//                 id: weatherFlickable
//                 anchors.fill: parent
//                 contentWidth: width
//                 contentHeight: wCol.implicitHeight + root.s(100)
//                 boundsBehavior: Flickable.StopAtBounds
//                 clip: true

//                 MouseArea { anchors.fill: parent; onClicked: root.clearHighlight(); z: -1 }

//                 ColumnLayout {
//                     id: wCol
//                     width: parent.width
//                     spacing: root.s(10)

//                     // ── Box 0: Instructions ──────────────────────────────────
//                     Rectangle {
//                         id: wBox0
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: instructionLayout.implicitHeight + root.s(28)
//                         radius: root.s(12)

//                         property bool isActive: root.highlightedBox === 0
//                         color: isActive ? root.blue : root.surface0
//                         border.color: isActive ? root.blue : root.surface1
//                         border.width: 1
//                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                         clip: true

//                         MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 0; z: -1 }

//                         ColumnLayout {
//                             id: instructionLayout
//                             anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(14)
//                             spacing: root.s(10)
//                             Text {
//                                 text: "Weather Widget Setup"; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: root.s(15)
//                                 color: wBox0.isActive ? root.base : root.text; Layout.bottomMargin: root.s(2)
//                                 Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                             }
//                             RowLayout {
//                                 spacing: root.s(10)
//                                 Rectangle {
//                                     width: root.s(22); height: root.s(22); radius: root.s(11)
//                                     color: wBox0.isActive ? Qt.alpha(root.base, 0.25) : Qt.alpha(root.blue, 0.2)
//                                     border.color: wBox0.isActive ? Qt.alpha(root.base, 0.5) : root.blue; border.width: 1
//                                     Behavior on color { ColorAnimation { duration: 220 } }
//                                     Text { anchors.centerIn: parent; text: "1"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(11); color: wBox0.isActive ? root.base : root.blue; Behavior on color { ColorAnimation { duration: 220 } } }
//                                 }
//                                 Text {
//                                     text: "Get an API Key"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(13)
//                                     color: wBox0.isActive ? root.base : root.text; Layout.fillWidth: true
//                                     Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                 }
//                             }
//                             RowLayout {
//                                 spacing: root.s(10); Layout.fillWidth: true
//                                 Item {
//                                     Layout.preferredWidth: root.s(22); Layout.fillHeight: true
//                                     Rectangle {
//                                         anchors.horizontalCenter: parent.horizontalCenter; width: 2; height: parent.height + root.s(10)
//                                         color: wBox0.isActive ? Qt.alpha(root.base, 0.3) : root.surface2
//                                         Behavior on color { ColorAnimation { duration: 220 } }
//                                     }
//                                 }
//                                 ColumnLayout {
//                                     Layout.fillWidth: true; spacing: root.s(6); Layout.topMargin: root.s(2); Layout.bottomMargin: root.s(2)
//                                     Repeater {
//                                         model: ["Go to openweathermap.org & create an account.", "Navigate to profile -> 'My API keys'.", "Generate a new key and paste it below."]
//                                         Rectangle {
//                                             Layout.fillWidth: true; Layout.preferredHeight: root.s(30)
//                                             radius: root.s(6)
//                                             color: wBox0.isActive ? Qt.alpha(root.base, 0.12) : root.surface0
//                                             border.color: wBox0.isActive ? Qt.alpha(root.base, 0.2) : root.surface1; border.width: 1
//                                             Behavior on color { ColorAnimation { duration: 220 } }
//                                             Behavior on border.color { ColorAnimation { duration: 220 } }
//                                             RowLayout { anchors.fill: parent; anchors.margins: root.s(7); spacing: root.s(7)
//                                                 Text { text: "󰄾"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(12); color: wBox0.isActive ? Qt.alpha(root.base, 0.6) : root.overlay0; Behavior on color { ColorAnimation { duration: 220 } } }
//                                                 Text { text: modelData; font.family: "Inter"; font.pixelSize: root.s(11); color: wBox0.isActive ? Qt.alpha(root.base, 0.85) : root.subtext1; Layout.fillWidth: true; Behavior on color { ColorAnimation { duration: 220 } } }
//                                             }
//                                         }
//                                     }
//                                 }
//                             }
//                             RowLayout {
//                                 spacing: root.s(10)
//                                 Rectangle {
//                                     width: root.s(22); height: root.s(22); radius: root.s(11)
//                                     color: wBox0.isActive ? Qt.alpha(root.base, 0.25) : Qt.alpha(root.peach, 0.2)
//                                     border.color: wBox0.isActive ? Qt.alpha(root.base, 0.5) : root.peach; border.width: 1
//                                     Behavior on color { ColorAnimation { duration: 220 } }
//                                     Text { anchors.centerIn: parent; text: "2"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(11); color: wBox0.isActive ? root.base : root.peach; Behavior on color { ColorAnimation { duration: 220 } } }
//                                 }
//                                 Text {
//                                     text: "Find your City ID"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(13)
//                                     color: wBox0.isActive ? root.base : root.text; Layout.fillWidth: true
//                                     Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                 }
//                             }
//                             RowLayout {
//                                 spacing: root.s(10); Layout.fillWidth: true
//                                 Item {
//                                     Layout.preferredWidth: root.s(22); Layout.fillHeight: true
//                                     Rectangle {
//                                         anchors.horizontalCenter: parent.horizontalCenter; width: 2; height: parent.height - root.s(10); anchors.top: parent.top
//                                         color: wBox0.isActive ? Qt.alpha(root.base, 0.3) : root.surface2
//                                         Behavior on color { ColorAnimation { duration: 220 } }
//                                         gradient: Gradient {
//                                             GradientStop { position: 0.0; color: wBox0.isActive ? Qt.alpha(root.base, 0.3) : root.surface2 }
//                                             GradientStop { position: 1.0; color: "transparent" }
//                                         }
//                                     }
//                                 }
//                                 ColumnLayout {
//                                     Layout.fillWidth: true; spacing: root.s(6); Layout.topMargin: root.s(2); Layout.bottomMargin: root.s(2)
//                                     Repeater {
//                                         model: ["Search for your city on openweathermap.org.", "Look at the URL (e.g. .../city/2643743).", "Copy the number at the end and paste below."]
//                                         Rectangle {
//                                             Layout.fillWidth: true; Layout.preferredHeight: root.s(30)
//                                             radius: root.s(6)
//                                             color: wBox0.isActive ? Qt.alpha(root.base, 0.12) : root.surface0
//                                             border.color: wBox0.isActive ? Qt.alpha(root.base, 0.2) : root.surface1; border.width: 1
//                                             Behavior on color { ColorAnimation { duration: 220 } }
//                                             Behavior on border.color { ColorAnimation { duration: 220 } }
//                                             RowLayout { anchors.fill: parent; anchors.margins: root.s(7); spacing: root.s(7)
//                                                 Text { text: "󰄾"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(12); color: wBox0.isActive ? Qt.alpha(root.base, 0.6) : root.overlay0; Behavior on color { ColorAnimation { duration: 220 } } }
//                                                 Text { text: modelData; font.family: "Inter"; font.pixelSize: root.s(11); color: wBox0.isActive ? Qt.alpha(root.base, 0.85) : root.subtext1; Layout.fillWidth: true; Behavior on color { ColorAnimation { duration: 220 } } }
//                                             }
//                                         }
//                                     }
//                                 }
//                             }
//                             Text {
//                                 text: "* Note: New API keys may take a few hours to activate."; font.family: "Inter"; font.pixelSize: root.s(10)
//                                 color: wBox0.isActive ? Qt.alpha(root.base, 0.7) : root.yellow; font.italic: true; Layout.topMargin: root.s(2)
//                                 Behavior on color { ColorAnimation { duration: 220 } }
//                             }
//                         }
//                     }

//                     // ── Box 1: API Key ───────────────────────────────────────
//                     Rectangle {
//                         id: wBox1
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: apiKeyRow.implicitHeight + root.s(28)
//                         radius: root.s(12)

//                         property bool isActive: root.highlightedBox === 1
//                         color: isActive ? root.blue : root.surface0
//                         border.color: isActive ? root.blue : root.surface1
//                         border.width: 1
//                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

//                         MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 1; z: -1 }

//                         ColumnLayout {
//                             id: apiKeyRow
//                             anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
//                             spacing: root.s(10)
//                             RowLayout {
//                                 Layout.fillWidth: true; spacing: root.s(14)
//                                 Item {
//                                     Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter
//                                     Text {
//                                         anchors.centerIn: parent; text: "󰌆"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
//                                         color: wBox1.isActive ? root.base : root.blue
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                 }
//                                 ColumnLayout {
//                                     Layout.fillWidth: true; spacing: root.s(3)
//                                     Text {
//                                         text: "API Key"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
//                                         color: wBox1.isActive ? root.base : root.text; Layout.fillWidth: true
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                     Text {
//                                         text: "OpenWeather API key"; font.family: "Inter"; font.pixelSize: root.s(11)
//                                         color: wBox1.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                 }
//                             }
//                             Rectangle {
//                                 Layout.fillWidth: true; Layout.preferredHeight: root.s(42)
//                                 radius: root.s(7)
//                                 color: wBox1.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
//                                 border.color: apiKeyInput.activeFocus
//                                     ? (wBox1.isActive ? root.base : root.blue)
//                                     : (wBox1.isActive ? Qt.alpha(root.base, 0.3) : root.surface2)
//                                 border.width: 1
//                                 Behavior on border.color { ColorAnimation { duration: 150 } }
//                                 Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                 RowLayout {
//                                     anchors.fill: parent; anchors.margins: root.s(10); spacing: root.s(10)
//                                     Text {
//                                         text: "󰌆"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(16)
//                                         color: wBox1.isActive ? Qt.alpha(root.base, 0.6) : root.subtext0
//                                         Behavior on color { ColorAnimation { duration: 220 } }
//                                     }
//                                     TextInput { 
//                                         id: apiKeyInput
//                                         Layout.fillWidth: true; Layout.fillHeight: true
//                                         verticalAlignment: TextInput.AlignVCenter
//                                         font.family: "JetBrains Mono"; font.pixelSize: root.s(12)
//                                         color: wBox1.isActive ? root.base : root.text; clip: true; selectByMouse: true
//                                         echoMode: weatherTabRoot.apiKeyVisible ? TextInput.Normal : TextInput.Password
//                                         passwordCharacter: "•"
//                                         onTextChanged: Config.weatherApiKey = text
//                                         Behavior on color { ColorAnimation { duration: 220 } }
//                                         Text {
//                                             text: "Enter API Key..."; color: wBox1.isActive ? Qt.alpha(root.base, 0.5) : root.subtext0
//                                             visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter
//                                             Behavior on color { ColorAnimation { duration: 220 } }
//                                         }
//                                     }
//                                     Rectangle {
//                                         width: root.s(24); height: root.s(24); radius: root.s(4); color: "transparent"
//                                         Text {
//                                             anchors.centerIn: parent; text: weatherTabRoot.apiKeyVisible ? "󰈈" : "󰈉"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(16)
//                                             color: eyeMa.containsMouse
//                                                 ? (wBox1.isActive ? root.base : root.blue)
//                                                 : (wBox1.isActive ? Qt.alpha(root.base, 0.6) : root.subtext0)
//                                             Behavior on color { ColorAnimation { duration: 150 } }
//                                         }
//                                         MouseArea { id: eyeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: weatherTabRoot.apiKeyVisible = !weatherTabRoot.apiKeyVisible }
//                                     }
//                                 }
//                             }
//                         }
//                     }

//                     // ── Box 2: City ID ───────────────────────────────────────
//                     Rectangle {
//                         id: wBox2
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: cityIdRow.implicitHeight + root.s(28)
//                         radius: root.s(12)

//                         property bool isActive: root.highlightedBox === 2
//                         color: isActive ? root.blue : root.surface0
//                         border.color: isActive ? root.blue : root.surface1
//                         border.width: 1
//                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

//                         MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 2; z: -1 }

//                         ColumnLayout {
//                             id: cityIdRow
//                             anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
//                             spacing: root.s(10)
//                             RowLayout {
//                                 Layout.fillWidth: true; spacing: root.s(14)
//                                 Item {
//                                     Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter
//                                     Text {
//                                         anchors.centerIn: parent; text: "󰖐"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
//                                         color: wBox2.isActive ? root.base : root.blue
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                 }
//                                 ColumnLayout {
//                                     Layout.fillWidth: true; spacing: root.s(3)
//                                     Text {
//                                         text: "City ID"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
//                                         color: wBox2.isActive ? root.base : root.text; Layout.fillWidth: true
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                     Text {
//                                         text: "OpenWeather city ID"; font.family: "Inter"; font.pixelSize: root.s(11)
//                                         color: wBox2.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                 }
//                             }
//                             Rectangle {
//                                 Layout.fillWidth: true; Layout.preferredHeight: root.s(42)
//                                 radius: root.s(7)
//                                 color: wBox2.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
//                                 border.color: cityIdInput.activeFocus
//                                     ? (wBox2.isActive ? root.base : root.blue)
//                                     : (wBox2.isActive ? Qt.alpha(root.base, 0.3) : root.surface2)
//                                 border.width: 1
//                                 Behavior on border.color { ColorAnimation { duration: 150 } }
//                                 Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                 TextInput {
//                                     id: cityIdInput
//                                     anchors.fill: parent; anchors.margins: root.s(10)
//                                     verticalAlignment: TextInput.AlignVCenter
//                                     font.family: "JetBrains Mono"; font.pixelSize: root.s(12)
//                                     color: wBox2.isActive ? root.base : root.text; clip: true; selectByMouse: true
//                                     onTextChanged: Config.weatherCityId = text
//                                     Behavior on color { ColorAnimation { duration: 220 } }
//                                     Text {
//                                         text: "City ID (e.g. 2624652)"; color: wBox2.isActive ? Qt.alpha(root.base, 0.5) : root.subtext0
//                                         visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter
//                                         Behavior on color { ColorAnimation { duration: 220 } }
//                                     }
//                                 }
//                             }
//                         }
//                     }

//                     // ── Box 3: Temperature Unit ──────────────────────────────
//                     Rectangle {
//                         id: wBox3
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: unitRow.implicitHeight + root.s(28)
//                         radius: root.s(12)

//                         property bool isActive: root.highlightedBox === 3
//                         color: isActive ? root.blue : root.surface0
//                         border.color: isActive ? root.blue : root.surface1
//                         border.width: 1
//                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

//                         MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 3; z: -1 }

//                         ColumnLayout {
//                             id: unitRow
//                             anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
//                             spacing: root.s(10)
//                             RowLayout {
//                                 Layout.fillWidth: true; spacing: root.s(14)
//                                 Item {
//                                     Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter
//                                     Text {
//                                         anchors.centerIn: parent; text: "°C"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18)
//                                         color: wBox3.isActive ? root.base : root.blue
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                 }
//                                 ColumnLayout {
//                                     Layout.fillWidth: true; spacing: root.s(3)
//                                     Text {
//                                         text: "Temperature Unit"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
//                                         color: wBox3.isActive ? root.base : root.text; Layout.fillWidth: true
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                     Text {
//                                         text: "Celsius / Fahrenheit / Kelvin"; font.family: "Inter"; font.pixelSize: root.s(11)
//                                         color: wBox3.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
//                                         Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
//                                     }
//                                 }
//                             }
//                             RowLayout {
//                                 Layout.fillWidth: true; spacing: root.s(8)
//                                 Repeater {
//                                     model: [{ val: "metric", label: "Celsius" }, { val: "imperial", label: "Fahrenheit" }, { val: "standard", label: "Kelvin" }]
//                                     Rectangle {
//                                         Layout.preferredWidth: root.s(88); Layout.preferredHeight: root.s(30); radius: root.s(6)
//                                         property bool isSelected: Config.weatherUnit === modelData.val
//                                         property bool parentActive: wBox3.isActive
//                                         color: isSelected
//                                             ? (parentActive ? Qt.alpha(root.base, 0.25) : root.blue)
//                                             : (parentActive ? Qt.alpha(root.base, 0.1) : "transparent")
//                                         border.color: isSelected
//                                             ? (parentActive ? Qt.alpha(root.base, 0.6) : root.blue)
//                                             : (parentActive ? Qt.alpha(root.base, 0.2) : root.surface1)
//                                         border.width: 1
//                                         Behavior on color { ColorAnimation { duration: 150 } }
//                                         Behavior on border.color { ColorAnimation { duration: 150 } }
//                                         Text {
//                                             anchors.centerIn: parent; text: modelData.label
//                                             font.family: "JetBrains Mono"; font.pixelSize: root.s(10); font.capitalization: Font.Capitalize
//                                             color: isSelected
//                                                 ? (parentActive ? root.base : root.base)
//                                                 : (parentActive ? Qt.alpha(root.base, 0.6) : root.subtext0)
//                                             Behavior on color { ColorAnimation { duration: 150 } }
//                                         }
//                                         MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Config.weatherUnit = modelData.val }
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }

    
//     Component {
//         id: keybindTabComponent
//         Item {
//             id: keybindTabRoot

//             function scrollToBottom() {
//                 keybindFlickable.contentY = Math.max(0, keybindsColLayout.implicitHeight - keybindFlickable.height + root.s(100));
//             }
//             function scrollTo(y) {
//                 let maxY = Math.max(0, keybindFlickable.contentHeight - keybindFlickable.height);
//                 keybindFlickable.contentY = Math.max(0, Math.min(y - root.s(40), maxY > 0 ? maxY : y));
//             }
//             function scrollToBox(approxItemY) {
//                 let viewH = keybindFlickable.height;
//                 let itemTop = approxItemY;
//                 let itemBottom = approxItemY + root.s(56);
//                 let curY = keybindFlickable.contentY;
//                 let maxY = Math.max(0, keybindFlickable.contentHeight - viewH);
//                 if (itemTop < curY + root.s(10)) {
//                     keybindFlickable.contentY = Math.max(0, itemTop - root.s(20));
//                 } else if (itemBottom > curY + viewH - root.s(10)) {
//                     keybindFlickable.contentY = Math.min(maxY, itemBottom - viewH + root.s(20));
//                 }
//             }

//             Flickable {
//                 id: keybindFlickable
//                 anchors.fill: parent
//                 contentWidth: width
//                 contentHeight: keybindsColLayout.implicitHeight + root.s(100)
//                 boundsBehavior: Flickable.StopAtBounds
//                 clip: true

//                 MouseArea { anchors.fill: parent; onClicked: root.clearHighlight(); z: -1 }

//                 ColumnLayout {
//                     id: keybindsColLayout
//                     width: parent.width
//                     spacing: root.s(8)

//                     Rectangle {
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: wsCol.implicitHeight + root.s(32)
//                         radius: root.s(12)
//                         color: root.surface0
//                         border.color: root.surface1; border.width: 1
//                         ColumnLayout {
//                             id: wsCol
//                             anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
//                             spacing: root.s(10)
//                             Text { text: "Workspaces (SUPER + 1-9)"; font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: root.s(12); color: root.text; Layout.alignment: Qt.AlignVCenter }
//                             Flow {
//                                 Layout.fillWidth: true; spacing: root.s(7)
//                                 Repeater {
//                                     model: 9
//                                     Rectangle {
//                                         property int wsNum: index + 1
//                                         width: root.s(30); height: root.s(30); radius: root.s(6)
//                                         color: wsMa.containsMouse ? root.peach : root.surface1
//                                         border.color: wsMa.containsMouse ? root.peach : "transparent"; border.width: 1
//                                         Behavior on color { ColorAnimation { duration: 150 } }
//                                         Text {
//                                             anchors.centerIn: parent; text: parent.wsNum
//                                             font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(11)
//                                             color: wsMa.containsMouse ? root.base : root.peach
//                                             Behavior on color { ColorAnimation { duration: 150 } }
//                                         }
//                                         MouseArea { id: wsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", wsNum.toString()]) }
//                                     }
//                                 }
//                             }
//                         }
//                     }

//                     ListView {
//                         id: kbListView
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: implicitHeight
//                         implicitHeight: dynamicKeybindsModel.count * root.s(56) + root.s(20)
//                         model: dynamicKeybindsModel
//                         interactive: false
//                         cacheBuffer: root.s(2000)
//                         displayMarginBeginning: root.s(100)
//                         displayMarginEnd: root.s(100)
//                         spacing: root.s(8)

//                         delegate: Rectangle {
//                             id: kbRowRect
//                             property int outerIndex: index 
//                             property bool isJumpHighlighted: root.highlightedBox === outerIndex
                            
//                             property bool layoutReady: false
//                             Component.onCompleted: Qt.callLater(() => layoutReady = true)

//                             width: kbListView.width
//                             height: root.s(44) + (model.isEditing ? editPanel.implicitHeight + root.s(12) : 0)
//                             radius: root.s(8)

//                             HoverHandler { id: rowHover }
//                             property bool isHovered: rowHover.hovered || model.isEditing || isJumpHighlighted
//                             property bool isTypeOpen: false
//                             property bool isDispOpen: false

//                             color: isJumpHighlighted ? root.surface1 : (isHovered ? root.surface1 : root.surface0)
//                             border.color: isJumpHighlighted ? root.peach : (isHovered ? Qt.alpha(root.peach, 0.5) : root.surface1)
//                             border.width: isJumpHighlighted ? 2 : 1

//                             Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
//                             Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }
//                             Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }
//                             Behavior on border.width { NumberAnimation { duration: 150 } }

//                             MouseArea { anchors.fill: parent; z: -2; onClicked: root.highlightedBox = outerIndex; }

//                             ColumnLayout {
//                                 anchors.fill: parent; anchors.margins: root.s(10); spacing: root.s(10)

//                                 Item {
//                                     Layout.fillWidth: true; Layout.preferredHeight: root.s(24); clip: true

//                                     Row {
//                                         id: modKeyContainer
//                                         anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: root.s(5)
//                                         Rectangle {
//                                             width: k1Text.implicitWidth + root.s(10); height: root.s(24); radius: root.s(4)
//                                             color: root.surface1
//                                             border.color: root.surface2; border.width: 1
//                                             visible: model.mods !== ""
//                                             Text {
//                                                 id: k1Text; anchors.centerIn: parent; text: model.mods
//                                                 font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(9)
//                                                 color: root.peach
//                                             }
//                                         }
//                                         Text {
//                                             text: "+"; font.family: "JetBrains Mono"; font.pixelSize: root.s(10)
//                                             color: root.overlay0
//                                             visible: model.mods !== "" && model.key !== ""; anchors.verticalCenter: parent.verticalCenter
//                                         }
//                                         Rectangle {
//                                             width: k2Text.implicitWidth + root.s(10); height: root.s(24); radius: root.s(4)
//                                             color: root.surface1
//                                             border.color: root.surface2; border.width: 1
//                                             visible: model.key !== ""
//                                             Text {
//                                                 id: k2Text; anchors.centerIn: parent; text: model.key
//                                                 font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(9)
//                                                 color: root.peach
//                                             }
//                                         }
//                                     }

//                                     // Edit button
//                                     Rectangle {
//                                         id: editButtonSlide
//                                         width: root.s(26); height: root.s(26); radius: root.s(6)
//                                         anchors.verticalCenter: parent.verticalCenter
//                                         x: kbRowRect.isHovered ? parent.width - width : parent.width
//                                         color: model.isEditing
//                                             ? root.peach
//                                             : (editMa.containsMouse ? root.peach : root.surface2)
                                            
//                                         Behavior on x { 
//                                             enabled: kbRowRect.layoutReady
//                                             NumberAnimation { duration: 250; easing.type: Easing.OutQuart } 
//                                         }
//                                         Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
                                        
//                                         Text {
//                                             anchors.centerIn: parent
//                                             text: model.isEditing ? "▴" : "󰏫"
//                                             font.family: model.isEditing ? "Inter" : "Iosevka Nerd Font"
//                                             font.pixelSize: root.s(13)
//                                             color: model.isEditing
//                                                 ? root.base
//                                                 : (editMa.containsMouse ? root.base : root.subtext0)
//                                             Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
//                                         }
//                                         MouseArea { 
//                                             id: editMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
//                                             onClicked: { 
//                                                 dynamicKeybindsModel.setProperty(outerIndex, "isEditing", !model.isEditing); 
//                                                 kbRowRect.isTypeOpen = false; 
//                                                 kbRowRect.isDispOpen = false; 
//                                                 if (!model.isEditing) {
//                                                     root.forceActiveFocus();
//                                                 }
//                                             } 
//                                         }
//                                     }
//                                     Item {
//                                         id: cmdClipRect
//                                         anchors.left: modKeyContainer.right; anchors.leftMargin: root.s(8)
//                                         anchors.right: editButtonSlide.left; anchors.rightMargin: root.s(6)
//                                         anchors.verticalCenter: parent.verticalCenter; height: parent.height; clip: true

//                                         property int marqueeSpacing: root.s(60)
//                                         property bool shouldMarquee: kbRowRect.isHovered && cmdTextMain.implicitWidth > width

//                                         Item {
//                                             id: marqueeContainer
//                                             height: parent.height
//                                             width: cmdClipRect.shouldMarquee ? cmdTextMain.implicitWidth * 2 + cmdClipRect.marqueeSpacing : parent.width
//                                             anchors.verticalCenter: parent.verticalCenter
//                                             anchors.right: cmdClipRect.shouldMarquee ? undefined : parent.right
//                                             anchors.left: cmdClipRect.shouldMarquee ? parent.left : undefined

//                                             Row {
//                                                 spacing: cmdClipRect.marqueeSpacing; anchors.verticalCenter: parent.verticalCenter
//                                                 anchors.right: cmdClipRect.shouldMarquee ? undefined : parent.right
//                                                 Text {
//                                                     id: cmdTextMain; text: (model.dispatcher + " " + model.command).trim()
//                                                     font.family: "JetBrains Mono"; font.pixelSize: root.s(10)
//                                                     color: root.subtext0
//                                                 }
//                                                 Text {
//                                                     id: cmdTextClone; text: cmdTextMain.text; font: cmdTextMain.font; color: cmdTextMain.color
//                                                     visible: cmdClipRect.shouldMarquee
//                                                 }
//                                             }

//                                             SequentialAnimation on x {
//                                                 id: cmdAnim; loops: Animation.Infinite
//                                                 running: cmdClipRect.shouldMarquee && kbRowRect.layoutReady
//                                                 PauseAnimation { duration: 1500 }
//                                                 NumberAnimation { from: 0; to: -(cmdTextMain.implicitWidth + cmdClipRect.marqueeSpacing); duration: (cmdTextMain.implicitWidth + cmdClipRect.marqueeSpacing) * 25 }
//                                                 PropertyAction { target: marqueeContainer; property: "x"; value: 0 }
//                                             }
//                                             onXChanged: { if (!cmdClipRect.shouldMarquee && x !== 0) x = 0; }
//                                         }

//                                         onShouldMarqueeChanged: {
//                                             if (shouldMarquee) { marqueeContainer.anchors.right = undefined; marqueeContainer.anchors.left = parent.left; marqueeContainer.x = 0; cmdAnim.restart(); }
//                                             else { cmdAnim.stop(); marqueeContainer.x = 0; marqueeContainer.anchors.left = undefined; marqueeContainer.anchors.right = parent.right; }
//                                         }
//                                     }

//                                     MouseArea {
//                                         id: bindMa
//                                         anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: editButtonSlide.left
//                                         hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton; enabled: !model.isEditing
//                                         onClicked: {
//                                             if (model.dispatcher.startsWith("exec")) { Quickshell.execDetached(["bash", "-c", model.command]); }
//                                             else { Quickshell.execDetached(["hyprctl", "dispatch", model.dispatcher, model.command]); }
//                                         }
//                                     }
//                                 }

//                                 // ── Edit panel ───────────────────────────────
//                                 ColumnLayout {
//                                     id: editPanel
//                                     Layout.fillWidth: true; visible: model.isEditing; spacing: root.s(8); clip: true

//                                     // Record shortcut
//                                     Rectangle {
//                                         Layout.fillWidth: true; Layout.preferredHeight: root.s(34)
//                                         radius: root.s(6)
//                                         color: recordMa.pressed || captureTrap.activeFocus
//                                             ? Qt.alpha(root.red, 0.12)
//                                             : root.surface0
//                                         border.color: recordMa.pressed || captureTrap.activeFocus
//                                             ? root.red
//                                             : root.surface2
//                                         border.width: 1
//                                         Behavior on color { ColorAnimation { duration: 150 } }
//                                         Behavior on border.color { ColorAnimation { duration: 150 } }
//                                         Text {
//                                             anchors.centerIn: parent; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(11)
//                                             color: captureTrap.activeFocus ? root.red : root.text
//                                             Behavior on color { ColorAnimation { duration: 150 } }
//                                             text: captureTrap.activeFocus ? "Press Keys (Esc to confirm)..." : (model.mods ? model.mods + " + " : "") + (model.key || "[Click to Record Shortcut]")
//                                         }
//                                         MouseArea {
//                                             id: recordMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
//                                             onClicked: { captureTrap.accumulatedMods = []; captureTrap.accumulatedKey = ""; captureTrap.forceActiveFocus(); }
//                                         }
//                                         Item {
//                                             id: captureTrap
//                                             focus: false
//                                             property var accumulatedMods: []
//                                             property string accumulatedKey: ""
//                                             Keys.onTabPressed: (event) => { event.accepted = true; processKey(event); }
//                                             Keys.onBacktabPressed: (event) => { event.accepted = true; processKey(event); }
//                                             Keys.onReturnPressed: (event) => { event.accepted = true; processKey(event); }
//                                             Keys.onEnterPressed: (event) => { event.accepted = true; processKey(event); }
//                                             Keys.onEscapePressed: (event) => { captureTrap.focus = false; event.accepted = true; }
//                                             Keys.onShortcutOverride: (event) => { event.accepted = true; }
//                                             Keys.onReleased: (event) => { event.accepted = true; }
//                                             Keys.onPressed: (event) => { event.accepted = true; processKey(event); }
//                                             function processKey(event) {
//                                                 if (event.key === Qt.Key_Escape) return;
//                                                 let newMods = [];
//                                                 if (event.modifiers & Qt.MetaModifier) newMods.push("$mainMod");
//                                                 if (event.modifiers & Qt.ControlModifier) newMods.push("CTRL");
//                                                 if (event.modifiers & Qt.AltModifier) newMods.push("ALT");
//                                                 if (event.modifiers & Qt.ShiftModifier) newMods.push("SHIFT_L");
//                                                 let isModifierOnly = (event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R ||
//                                                                       event.key === Qt.Key_Meta || event.key === Qt.Key_Control ||
//                                                                       event.key === Qt.Key_Alt || event.key === Qt.Key_Shift ||
//                                                                       event.key === Qt.Key_CapsLock);
//                                                 if (isModifierOnly) {
//                                                     let mergedMods = [...captureTrap.accumulatedMods];
//                                                     for (let m of newMods) { if (!mergedMods.includes(m)) mergedMods.push(m); }
//                                                     dynamicKeybindsModel.setProperty(outerIndex, "mods", mergedMods.join(" "));
//                                                     captureTrap.accumulatedMods = mergedMods;
//                                                     return;
//                                                 }
//                                                 let k = "";
//                                                 if (event.key === Qt.Key_Space) k = "SPACE";
//                                                 else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) k = "RETURN";
//                                                 else if (event.key === Qt.Key_Tab) k = "TAB";
//                                                 else if (event.key === Qt.Key_Print) k = "Print";
//                                                 else if (event.key === Qt.Key_Left) k = "left";
//                                                 else if (event.key === Qt.Key_Right) k = "right";
//                                                 else if (event.key === Qt.Key_Up) k = "up";
//                                                 else if (event.key === Qt.Key_Down) k = "down";
//                                                 else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F35) { k = "F" + (event.key - Qt.Key_F1 + 1); }
//                                                 else if (event.text && event.text.length > 0) k = event.text.toUpperCase();
//                                                 else k = event.key.toString();
//                                                 if (captureTrap.accumulatedKey !== "") {
//                                                     let prevMods = model.mods ? model.mods.split(" ").filter(x => x !== "") : [];
//                                                     if (!prevMods.includes(captureTrap.accumulatedKey)) prevMods.push(captureTrap.accumulatedKey);
//                                                     for (let m of newMods) { if (!prevMods.includes(m)) prevMods.push(m); }
//                                                     dynamicKeybindsModel.setProperty(outerIndex, "mods", prevMods.join(" "));
//                                                     captureTrap.accumulatedMods = prevMods;
//                                                 } else {
//                                                     let allMods = [...captureTrap.accumulatedMods];
//                                                     for (let m of newMods) { if (!allMods.includes(m)) allMods.push(m); }
//                                                     captureTrap.accumulatedMods = allMods;
//                                                     dynamicKeybindsModel.setProperty(outerIndex, "mods", allMods.join(" "));
//                                                 }
//                                                 captureTrap.accumulatedKey = k;
//                                                 dynamicKeybindsModel.setProperty(outerIndex, "key", k);
//                                             }
//                                             onActiveFocusChanged: {
//                                                 if (!activeFocus) { accumulatedMods = []; accumulatedKey = ""; Quickshell.execDetached(["hyprctl", "dispatch", "submap", "reset"]); }
//                                                 else { Quickshell.execDetached(["hyprctl", "dispatch", "submap", "passthru"]); }
//                                             }
//                                         }
//                                     }

//                                     RowLayout {
//                                         Layout.fillWidth: true; spacing: root.s(8); Layout.alignment: Qt.AlignTop; z: 2
//                                         ColumnLayout {
//                                             Layout.preferredWidth: (parent.width - root.s(8)) * 0.4; Layout.alignment: Qt.AlignTop; spacing: root.s(4)
//                                             Rectangle {
//                                                 Layout.fillWidth: true; Layout.preferredHeight: root.s(30)
//                                                 radius: root.s(6)
//                                                 scale: kbRowRect.isTypeOpen ? 1.02 : 1.0
//                                                 Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
//                                                 color: kbRowRect.isTypeOpen
//                                                     ? Qt.alpha(root.peach, 0.12)
//                                                     : root.surface0
//                                                 border.color: kbRowRect.isTypeOpen ? root.peach : root.surface2
//                                                 border.width: kbRowRect.isTypeOpen ? 2 : 1
//                                                 Behavior on border.color { ColorAnimation { duration: 200 } }
//                                                 Behavior on border.width { NumberAnimation { duration: 150 } }
//                                                 Behavior on color { ColorAnimation { duration: 200 } }
//                                                 RowLayout {
//                                                     anchors.fill: parent; anchors.margins: root.s(7)
//                                                     Text {
//                                                         text: model.type; font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
//                                                         color: kbRowRect.isTypeOpen ? root.peach : root.text; Layout.fillWidth: true
//                                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                                     }
//                                                     Text {
//                                                         text: kbRowRect.isTypeOpen ? "▴" : "▾"; font.pixelSize: root.s(10)
//                                                         color: kbRowRect.isTypeOpen ? root.peach : root.subtext0
//                                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                                     }
//                                                 }
//                                                 MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { kbRowRect.isTypeOpen = !kbRowRect.isTypeOpen; kbRowRect.isDispOpen = false; } }
//                                             }
//                                             Rectangle {
//                                                 Layout.fillWidth: true
//                                                 Layout.preferredHeight: kbRowRect.isTypeOpen ? root.bindTypes.length * root.s(26) : 0
//                                                 radius: root.s(6); color: root.surface0; clip: true
//                                                 border.color: root.surface1; border.width: kbRowRect.isTypeOpen ? 1 : 0
//                                                 Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                                                 ListView {
//                                                     anchors.fill: parent; model: root.bindTypes; interactive: false
//                                                     opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0
//                                                     delegate: Rectangle {
//                                                         width: parent.width; height: root.s(26)
//                                                         color: typeItemMa.containsMouse ? Qt.alpha(root.peach, 0.12) : "transparent"
//                                                         Behavior on color { ColorAnimation { duration: 120 } }
//                                                         Text {
//                                                             anchors.verticalCenter: parent.verticalCenter; x: root.s(8); text: modelData
//                                                             font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
//                                                             color: model.type === modelData ? root.peach : root.text
//                                                         }
//                                                         MouseArea { id: typeItemMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { dynamicKeybindsModel.setProperty(outerIndex, "type", modelData); kbRowRect.isTypeOpen = false; } }
//                                                     }
//                                                 }
//                                             }
//                                         }
//                                         ColumnLayout {
//                                             Layout.preferredWidth: (parent.width - root.s(8)) * 0.6; Layout.alignment: Qt.AlignTop; spacing: root.s(4)
//                                             Rectangle {
//                                                 Layout.fillWidth: true; Layout.preferredHeight: root.s(30)
//                                                 radius: root.s(6)
//                                                 scale: kbRowRect.isDispOpen ? 1.02 : 1.0
//                                                 Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
//                                                 color: kbRowRect.isDispOpen
//                                                     ? Qt.alpha(root.peach, 0.12)
//                                                     : root.surface0
//                                                 border.color: kbRowRect.isDispOpen ? root.peach : root.surface2
//                                                 border.width: kbRowRect.isDispOpen ? 2 : 1
//                                                 Behavior on border.color { ColorAnimation { duration: 200 } }
//                                                 Behavior on border.width { NumberAnimation { duration: 150 } }
//                                                 Behavior on color { ColorAnimation { duration: 200 } }
//                                                 RowLayout {
//                                                     anchors.fill: parent; anchors.margins: root.s(7)
//                                                     Text {
//                                                         text: model.dispatcher; font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
//                                                         color: kbRowRect.isDispOpen ? root.peach : root.text; Layout.fillWidth: true
//                                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                                     }
//                                                     Text {
//                                                         text: kbRowRect.isDispOpen ? "▴" : "▾"; font.pixelSize: root.s(10)
//                                                         color: kbRowRect.isDispOpen ? root.peach : root.subtext0
//                                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                                     }
//                                                 }
//                                                 MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { kbRowRect.isDispOpen = !kbRowRect.isDispOpen; kbRowRect.isTypeOpen = false; } }
//                                             }
//                                             Rectangle {
//                                                 Layout.fillWidth: true
//                                                 Layout.preferredHeight: kbRowRect.isDispOpen ? Math.min(root.s(140), root.dispatchers.length * root.s(26)) : 0
//                                                 radius: root.s(6); color: root.surface0; clip: true
//                                                 border.color: root.surface1; border.width: kbRowRect.isDispOpen ? 1 : 0
//                                                 Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                                                 ListView {
//                                                     anchors.fill: parent; model: root.dispatchers; interactive: true
//                                                     opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0
//                                                     ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }
//                                                     delegate: Rectangle {
//                                                         width: parent.width; height: root.s(26)
//                                                         color: dispItemMa.containsMouse ? Qt.alpha(root.peach, 0.12) : "transparent"
//                                                         Behavior on color { ColorAnimation { duration: 120 } }
//                                                         Text {
//                                                             anchors.verticalCenter: parent.verticalCenter; x: root.s(8); text: modelData
//                                                             font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
//                                                             color: model.dispatcher === modelData ? root.peach : root.text
//                                                         }
//                                                         MouseArea { id: dispItemMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { dynamicKeybindsModel.setProperty(outerIndex, "dispatcher", modelData); kbRowRect.isDispOpen = false; } }
//                                                     }
//                                                 }
//                                             }
//                                         }
//                                     }

//                                     // Command input
//                                     Rectangle {
//                                         Layout.fillWidth: true; Layout.preferredHeight: root.s(34)
//                                         radius: root.s(6)
//                                         color: cmdInput.activeFocus ? Qt.alpha(root.peach, 0.08) : root.surface0
//                                         border.color: cmdInput.activeFocus ? root.peach : root.surface2
//                                         border.width: 1; z: 1
//                                         Behavior on color { ColorAnimation { duration: 150 } }
//                                         Behavior on border.color { ColorAnimation { duration: 150 } }
//                                         TextInput {
//                                             id: cmdInput
//                                             anchors.fill: parent; anchors.margins: root.s(9)
//                                             verticalAlignment: TextInput.AlignVCenter
//                                             text: model.command
//                                             font.family: "JetBrains Mono"; font.pixelSize: root.s(11)
//                                             color: root.text; clip: true; selectByMouse: true
//                                             onTextChanged: dynamicKeybindsModel.setProperty(outerIndex, "command", text)
//                                             Text {
//                                                 text: "Command arguments..."
//                                                 color: root.subtext0
//                                                 visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter
//                                             }
//                                         }
//                                     }

//                                     RowLayout {
//                                         Layout.fillWidth: true; Layout.alignment: Qt.AlignRight; spacing: root.s(8); z: 0
//                                         // Delete button
//                                         Rectangle {
//                                             Layout.preferredWidth: root.s(80); Layout.preferredHeight: root.s(30); radius: root.s(7)
//                                             color: delMa.containsMouse ? root.red : root.surface1
//                                             border.color: delMa.containsMouse ? root.red : Qt.alpha(root.red, 0.4)
//                                             border.width: 1
//                                             Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
//                                             Behavior on border.color { ColorAnimation { duration: 180 } }
//                                             RowLayout {
//                                                 anchors.centerIn: parent; spacing: root.s(6)
//                                                 Text {
//                                                     text: "󰆴"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(14)
//                                                     color: delMa.containsMouse ? root.base : root.red
//                                                     Behavior on color { ColorAnimation { duration: 180 } }
//                                                 }
//                                                 Text {
//                                                     text: "Delete"; font.family: "JetBrains Mono"; font.pixelSize: root.s(10); font.weight: Font.Medium
//                                                     color: delMa.containsMouse ? root.base : root.red
//                                                     Behavior on color { ColorAnimation { duration: 180 } }
//                                                 }
//                                             }
//                                             MouseArea { 
//                                                 id: delMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
//                                                 onClicked: { 
//                                                     root.forceActiveFocus();
//                                                     dynamicKeybindsModel.remove(outerIndex); 
//                                                     root.saveAllKeybinds(); 
//                                                 } 
//                                             }
//                                         }
//                                         // Save button
//                                         Rectangle {
//                                             Layout.preferredWidth: root.s(80); Layout.preferredHeight: root.s(30); radius: root.s(7)
//                                             color: rowSaveMa.containsMouse ? root.green : root.surface1
//                                             border.color: rowSaveMa.containsMouse ? root.green : Qt.alpha(root.green, 0.4)
//                                             border.width: 1
//                                             Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
//                                             Behavior on border.color { ColorAnimation { duration: 180 } }
//                                             RowLayout {
//                                                 anchors.centerIn: parent; spacing: root.s(6)
//                                                 Text {
//                                                     text: "󰆓"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(14)
//                                                     color: rowSaveMa.containsMouse ? root.base : root.green
//                                                     Behavior on color { ColorAnimation { duration: 180 } }
//                                                 }
//                                                 Text {
//                                                     text: "Save"; font.family: "JetBrains Mono"; font.pixelSize: root.s(10); font.weight: Font.Medium
//                                                     color: rowSaveMa.containsMouse ? root.base : root.green
//                                                     Behavior on color { ColorAnimation { duration: 180 } }
//                                                 }
//                                             }
//                                             MouseArea {
//                                                 id: rowSaveMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                                                 onClicked: {
//                                                     let validationResult = root.validateKeybind(outerIndex, model.mods, model.key, model.dispatcher, model.command);
//                                                     if (validationResult !== "VALID") { 
//                                                         Quickshell.execDetached(["notify-send", "-u", "critical", "Keybind Error", validationResult]); 
//                                                         return; 
//                                                     }
//                                                     dynamicKeybindsModel.setProperty(outerIndex, "isEditing", false);
//                                                     root.forceActiveFocus();
//                                                     root.saveAllKeybinds();
//                                                 }
//                                             }
//                                         }
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     } 


//     // ── Main Panel ─────────────────────────────────────────────────────────────
//     Rectangle {
//         id: sidebarPanel
//         anchors.fill: parent
//         color: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.97)
//         radius: root.s(16)
//         border.width: 1
//         border.color: Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.9)
//         clip: true

//         Rectangle {
//             anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: root.s(16)
//             color: sidebarPanel.color
//             Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: sidebarPanel.border.color }
//             Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: sidebarPanel.border.color }
//             Rectangle { anchors.left: parent.left; width: 1; height: parent.height; color: sidebarPanel.border.color }
//         }

//         Item {
//             anchors.fill: parent
//             opacity: introContent
//             scale: 0.96 + (0.04 * introContent)
//             transform: Translate { y: root.s(40) * (1.0 - introContent) }

//             ColumnLayout {
//                 anchors.fill: parent
//                 anchors.margins: root.s(20)
//                 spacing: root.s(12)

//                 // ── Header ────────────────────────────────────────────────────
//                 RowLayout {
//                     Layout.fillWidth: true
//                     spacing: root.s(10)

//                     Text { 
//                         text: "Settings"; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: root.s(24)
//                         color: root.text; Layout.alignment: Qt.AlignVCenter 
//                     }

//                     Rectangle {
//                         visible: root.isSearchMode
//                         width: root.s(26); height: root.s(26); radius: root.s(6)
//                         color: closeSearchMa.containsMouse ? Qt.alpha(root.red, 0.15) : "transparent"
//                         border.color: closeSearchMa.containsMouse ? root.red : "transparent"; border.width: 1
//                         opacity: root.isSearchMode ? 1.0 : 0.0
//                         Behavior on opacity { NumberAnimation { duration: 200 } }
//                         Behavior on color { ColorAnimation { duration: 150 } }
//                         Text { anchors.centerIn: parent; text: "✕"; font.family: "Inter"; font.pixelSize: root.s(12); color: closeSearchMa.containsMouse ? root.red : root.subtext0; Behavior on color { ColorAnimation { duration: 150 } } }
//                         MouseArea {
//                             id: closeSearchMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                             onClicked: { root.isSearchMode = false; root.globalSearchQuery = ""; globalSearchInput.text = ""; root.searchHighlightIndex = -1; }
//                         }
//                     }

//                     Item { Layout.fillWidth: true }

//                     // Save button
//                     Rectangle {
//                         id: headerSaveBtn
//                         visible: root.currentTab !== 2 && !root.isSearchMode
//                         opacity: visible ? 1.0 : 0.0
//                         Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

//                         Layout.alignment: Qt.AlignVCenter
//                         Layout.preferredHeight: root.s(34)
//                         Layout.preferredWidth: saveBtnRow.implicitWidth + root.s(28)

//                         radius: root.s(8)
//                         scale: headerSaveMa.pressed ? 0.94 : (headerSaveMa.containsMouse ? 1.03 : 1.0)
//                         Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

//                         color: headerSaveMa.pressed
//                             ? Qt.darker(root.mauve, 1.15)
//                             : (headerSaveMa.containsMouse ? root.mauve : root.surface1)
//                         border.color: headerSaveMa.containsMouse ? root.mauve : Qt.alpha(root.mauve, 0.4)
//                         border.width: 1
//                         Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
//                         Behavior on border.color { ColorAnimation { duration: 180 } }

//                         RowLayout {
//                             id: saveBtnRow
//                             anchors.centerIn: parent
//                             spacing: root.s(7)
//                             Text { 
//                                 text: "󰆓"
//                                 font.family: "Iosevka Nerd Font"
//                                 font.pixelSize: root.s(15)
//                                 color: headerSaveMa.containsMouse ? root.base : root.mauve
//                                 Behavior on color { ColorAnimation { duration: 180 } }
//                             }
//                             Text { 
//                                 text: "Save"
//                                 font.family: "JetBrains Mono"
//                                 font.weight: Font.Bold
//                                 font.pixelSize: root.s(12)
//                                 color: headerSaveMa.containsMouse ? root.base : root.text
//                                 Behavior on color { ColorAnimation { duration: 180 } }
//                             }
//                         }

//                         MouseArea {
//                             id: headerSaveMa
//                             anchors.fill: parent
//                             hoverEnabled: true
//                             cursorShape: Qt.PointingHandCursor
//                             onClicked: {
//                                 if (root.currentTab === 0) Config.saveAppSettings();
//                                 else if (root.currentTab === 1) Config.saveWeatherConfig();
//                             }
//                         }
//                     }

//                     // Add button
//                     Rectangle {
//                         id: headerAddBtn
//                         visible: root.currentTab === 2 && !root.isSearchMode
//                         opacity: visible ? 1.0 : 0.0
//                         Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

//                         Layout.alignment: Qt.AlignVCenter
//                         Layout.preferredHeight: root.s(34)
//                         Layout.preferredWidth: addBtnRow.implicitWidth + root.s(28)

//                         radius: root.s(8)
//                         scale: headerAddMa.pressed ? 0.94 : (headerAddMa.containsMouse ? 1.03 : 1.0)
//                         Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

//                         color: headerAddMa.pressed
//                             ? Qt.darker(root.peach, 1.15)
//                             : (headerAddMa.containsMouse ? root.peach : root.surface1)
//                         border.color: headerAddMa.containsMouse ? root.peach : Qt.alpha(root.peach, 0.4)
//                         border.width: 1
//                         Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
//                         Behavior on border.color { ColorAnimation { duration: 180 } }

//                         RowLayout {
//                             id: addBtnRow
//                             anchors.centerIn: parent
//                             spacing: root.s(7)
//                             Text { 
//                                 text: "+"
//                                 font.family: "JetBrains Mono"
//                                 font.weight: Font.Bold
//                                 font.pixelSize: root.s(15)
//                                 color: headerAddMa.containsMouse ? root.base : root.peach
//                                 Behavior on color { ColorAnimation { duration: 180 } }
//                             }
//                             Text { 
//                                 text: "Add"
//                                 font.family: "JetBrains Mono"
//                                 font.weight: Font.Bold
//                                 font.pixelSize: root.s(12)
//                                 color: headerAddMa.containsMouse ? root.base : root.text
//                                 Behavior on color { ColorAnimation { duration: 180 } }
//                             }
//                         }

//                         MouseArea {
//                             id: headerAddMa
//                             anchors.fill: parent
//                             hoverEnabled: true
//                             cursorShape: Qt.PointingHandCursor
//                             onClicked: {
//                                 dynamicKeybindsModel.append({ type: "bind", mods: "", key: "", dispatcher: "exec", command: "", isEditing: true });
//                                 scrollTimer.start();
//                             }
//                         }
//                     }
//                 }

//                 // ── Search bar ────────────────────────────────────────────────
//                 Rectangle {
//                     Layout.fillWidth: true; Layout.preferredHeight: root.s(40); radius: root.s(10)
//                     color: root.isSearchMode
//                         ? Qt.alpha(root.sapphire, 0.06)
//                         : (globalSearchBarMa.containsMouse ? Qt.alpha(root.surface1, 0.6) : Qt.alpha(root.surface0, 0.5))
//                     border.color: root.isSearchMode ? root.sapphire : (globalSearchBarMa.containsMouse ? root.surface2 : root.surface1)
//                     border.width: root.isSearchMode ? 2 : 1
//                     Behavior on color { ColorAnimation { duration: 200 } }
//                     Behavior on border.color { ColorAnimation { duration: 200 } }
//                     Behavior on border.width { NumberAnimation { duration: 150 } }

//                     RowLayout {
//                         anchors.fill: parent; anchors.leftMargin: root.s(11); anchors.rightMargin: root.s(11); spacing: root.s(9)
//                         Text {
//                             text: "󰍉"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(15)
//                             color: root.isSearchMode ? root.sapphire : root.subtext0
//                             Behavior on color { ColorAnimation { duration: 200 } }
//                             MouseArea { anchors.fill: parent; anchors.margins: -root.s(6); hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.isSearchMode = true; globalSearchInput.forceActiveFocus(); } }
//                         }
//                         TextInput {
//                             id: globalSearchInput
//                             Layout.fillWidth: true; Layout.fillHeight: true; verticalAlignment: TextInput.AlignVCenter
//                             font.family: "JetBrains Mono"; font.pixelSize: root.s(12); color: root.text; clip: true; selectByMouse: true
//                             Text {
//                                 anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
//                                 text: root.isSearchMode ? "Search settings & keybinds..." : "Search"
//                                 color: Qt.alpha(root.subtext0, 0.45)
//                                 visible: !globalSearchInput.text && !globalSearchInput.activeFocus
//                                 font.family: "JetBrains Mono"; font.pixelSize: root.s(12)
//                             }
//                             onActiveFocusChanged: { if (activeFocus && !root.isSearchMode) root.isSearchMode = true; }
//                             onTextChanged: { root.globalSearchQuery = text; if (!root.isSearchMode && text.length > 0) root.isSearchMode = true; }
//                             Keys.onEscapePressed: { root.isSearchMode = false; root.globalSearchQuery = ""; text = ""; root.searchHighlightIndex = -1; root.forceActiveFocus(); }
//                             Keys.onDownPressed: (event) => {
//                                 root.forceActiveFocus();
//                                 let total = root.searchResultItems.length;
//                                 if (total === 0) { event.accepted = true; return; }
//                                 root.searchHighlightIndex = root.searchHighlightIndex < total - 1 ? root.searchHighlightIndex + 1 : 0;
//                                 root.scrollSearchHighlightIntoView(root.searchHighlightIndex);
//                                 event.accepted = true;
//                             }
//                             Keys.onUpPressed: (event) => {
//                                 root.forceActiveFocus();
//                                 let total = root.searchResultItems.length;
//                                 if (total === 0) { event.accepted = true; return; }
//                                 root.searchHighlightIndex = root.searchHighlightIndex > 0 ? root.searchHighlightIndex - 1 : (root.searchHighlightIndex === 0 ? total - 1 : total - 1);
//                                 root.scrollSearchHighlightIntoView(root.searchHighlightIndex);
//                                 event.accepted = true;
//                             }
//                             Keys.onReturnPressed: (event) => {
//                                 if (root.searchHighlightIndex >= 0) { root.activateSearchHighlight(); event.accepted = true; }
//                             }
//                             Keys.onEnterPressed: (event) => {
//                                 if (root.searchHighlightIndex >= 0) { root.activateSearchHighlight(); event.accepted = true; }
//                             }
//                         }
//                         Rectangle {
//                             visible: root.isSearchMode && globalSearchInput.text.length > 0; width: root.s(20); height: root.s(20); radius: root.s(4)
//                             color: clearSearchBtnMa.containsMouse ? Qt.alpha(root.red, 0.15) : "transparent"
//                             border.color: clearSearchBtnMa.containsMouse ? root.red : "transparent"; border.width: 1
//                             Behavior on color { ColorAnimation { duration: 150 } }
//                             Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: root.s(10); color: clearSearchBtnMa.containsMouse ? root.red : Qt.alpha(root.subtext0, 0.6); Behavior on color { ColorAnimation { duration: 150 } } }
//                             MouseArea { id: clearSearchBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { globalSearchInput.text = ""; globalSearchInput.forceActiveFocus(); } }
//                         }
//                     }
//                     MouseArea { id: globalSearchBarMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: !root.isSearchMode; onClicked: { root.isSearchMode = true; globalSearchInput.forceActiveFocus(); } }
//                 }

//                 // ── Tab bar ───────────────────────────────────────────────────
//                 Item {
//                     Layout.fillWidth: true
//                     Layout.preferredHeight: root.s(38)
//                     visible: !root.isSearchMode
//                     opacity: root.isSearchMode ? 0.0 : 1.0
//                     Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

//                     // Background track
//                     Rectangle {
//                         anchors.fill: parent; radius: root.s(10)
//                         color: root.surface0; border.color: root.surface1; border.width: 1
//                     }

//                     // Morphing pill
//                     Rectangle {
//                         id: tabHighlightPill
//                         y: root.s(3)
//                         height: root.s(32)
//                         radius: root.s(8)

//                         property color c0: root.teal
//                         property color c1: root.blue
//                         property color c2: root.peach
//                         property color targetColor: {
//                             if (root.currentTab === 0) return c0;
//                             if (root.currentTab === 1) return c1;
//                             return c2;
//                         }
//                         color: targetColor
//                         Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo } }

//                         property int prevTab: 0
//                         property int curTab: root.currentTab

//                         onCurTabChanged: {
//                             if (curTab > prevTab) {
//                                 tabRightAnim.duration = 200; tabLeftAnim.duration = 350;
//                             } else if (curTab < prevTab) {
//                                 tabLeftAnim.duration = 200; tabRightAnim.duration = 350;
//                             }
//                             prevTab = curTab;
//                         }

//                         property real tabW: (parent.width - root.s(6)) / 3
//                         property real targetLeft: root.s(3) + curTab * tabW
//                         property real targetRight: targetLeft + tabW

//                         property real actualLeft: targetLeft
//                         property real actualRight: targetRight

//                         Behavior on actualLeft { NumberAnimation { id: tabLeftAnim; duration: 250; easing.type: Easing.OutExpo } }
//                         Behavior on actualRight { NumberAnimation { id: tabRightAnim; duration: 250; easing.type: Easing.OutExpo } }

//                         x: actualLeft
//                         width: actualRight - actualLeft
//                     }

//                     Row {
//                         anchors.fill: parent
//                         anchors.margins: root.s(3)
//                         spacing: 0

//                         Repeater {
//                             model: root.tabNames.length
//                             Item {
//                                 width: (parent.width) / 3
//                                 height: parent.height

//                                 property bool isActive: root.currentTab === index

//                                 RowLayout {
//                                     anchors.centerIn: parent
//                                     spacing: root.s(7)
//                                     Text {
//                                         text: root.tabIcons[index]
//                                         font.family: "Iosevka Nerd Font"
//                                         font.pixelSize: root.s(14)
//                                         color: isActive ? root.base : root.subtext0
//                                         Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                                     }
//                                     Text {
//                                         text: root.tabNames[index]
//                                         font.family: "JetBrains Mono"
//                                         font.weight: isActive ? Font.Bold : Font.Medium
//                                         font.pixelSize: root.s(12)
//                                         color: isActive ? root.base : root.subtext0
//                                         Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                                     }
//                                 }

//                                 MouseArea {
//                                     anchors.fill: parent
//                                     hoverEnabled: true
//                                     cursorShape: Qt.PointingHandCursor
//                                     onClicked: { root.currentTab = index; root.clearHighlight(); }
//                                 }
//                             }
//                         }
//                     }
//                 }

//                 // ── Content area ──────────────────────────────────────────────
//                 Item {
//                     Layout.fillWidth: true; Layout.fillHeight: true

//                     // Search results
//                     Flickable {
//                         id: searchResultsFlickable
//                         anchors.fill: parent; contentWidth: width
//                         contentHeight: searchResultsCol.implicitHeight + root.s(40)
//                         boundsBehavior: Flickable.StopAtBounds; clip: true
//                         visible: root.isSearchMode
//                         opacity: root.isSearchMode ? 1.0 : 0.0
//                         Behavior on opacity { NumberAnimation { duration: 250 } }

//                         MouseArea { anchors.fill: parent; onClicked: root.clearHighlight(); z: -1 }

//                         ColumnLayout {
//                             id: searchResultsCol; width: parent.width; spacing: root.s(8)

//                             Item {
//                                 Layout.fillWidth: true; Layout.preferredHeight: root.s(80)
//                                 visible: root.globalSearchQuery.trim() === ""
//                                 ColumnLayout {
//                                     anchors.centerIn: parent; spacing: root.s(8)
//                                     Text { Layout.alignment: Qt.AlignHCenter; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(30); color: Qt.alpha(root.subtext0, 0.25) }
//                                     Text { Layout.alignment: Qt.AlignHCenter; text: "Type to search settings & keybinds..."; font.family: "JetBrains Mono"; font.pixelSize: root.s(12); color: Qt.alpha(root.subtext0, 0.35) }
//                                 }
//                             }

//                             Repeater {
//                                 id: settingsCardRepeater
//                                 model: root.allSettingsCards.length
//                                 delegate: Item {
//                                     property var card: root.allSettingsCards[index]
//                                     property bool matches: root.globalSearchMatches(card, root.globalSearchQuery)
//                                     property int searchListIndex: {
//                                         let pos = 0;
//                                         for (let i = 0; i < root.searchResultItems.length; i++) {
//                                             if (root.searchResultItems[i].kind === "card" && root.searchResultItems[i].cardIndex === index) { pos = i; break; }
//                                         }
//                                         return pos;
//                                     }
//                                     property bool isSearchHighlighted: matches && root.searchHighlightIndex === searchListIndex && root.searchHighlightIndex >= 0
//                                     Layout.fillWidth: true
//                                     Layout.preferredHeight: matches ? root.s(58) : 0
//                                     visible: matches; opacity: matches ? 1.0 : 0.0; clip: true
//                                     Behavior on Layout.preferredHeight { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
//                                     Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

//                                     Rectangle {
//                                         anchors.fill: parent; radius: root.s(10)
//                                         color: isSearchHighlighted
//                                             ? root.surface1
//                                             : (searchCardMa.containsMouse ? root.surface1 : root.surface0)
//                                         border.color: isSearchHighlighted ? root[card.color] : (searchCardMa.containsMouse ? root[card.color] : root.surface1)
//                                         border.width: isSearchHighlighted ? 2 : 1
//                                         Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }
//                                         Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }

//                                         RowLayout {
//                                             anchors.fill: parent; anchors.margins: root.s(12); spacing: root.s(12)
//                                             Rectangle {
//                                                 width: root.s(32); height: root.s(32); radius: root.s(8)
//                                                 color: Qt.alpha(root[card.color], 0.15)
//                                                 border.color: Qt.alpha(root[card.color], 0.3); border.width: 1
//                                                 Text {
//                                                     anchors.centerIn: parent; text: card.icon; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(15)
//                                                     color: root[card.color]
//                                                 }
//                                             }
//                                             ColumnLayout {
//                                                 Layout.fillWidth: true; spacing: root.s(2)
//                                                 Text {
//                                                     text: card.label; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(13)
//                                                     color: isSearchHighlighted ? root[card.color] : root.text; Layout.fillWidth: true
//                                                     Behavior on color { ColorAnimation { duration: 200 } }
//                                                 }
//                                                 Text {
//                                                     text: card.desc; font.family: "Inter"; font.pixelSize: root.s(10)
//                                                     color: Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
//                                                 }
//                                             }
//                                             Rectangle {
//                                                 height: root.s(20); width: tabBadgeText.implicitWidth + root.s(12); radius: root.s(10)
//                                                 color: Qt.alpha(root[root.tabColors[card.tab]], 0.15)
//                                                 border.color: Qt.alpha(root[root.tabColors[card.tab]], 0.4); border.width: 1
//                                                 Text {
//                                                     id: tabBadgeText; anchors.centerIn: parent; text: root.tabNames[card.tab]
//                                                     font.family: "JetBrains Mono"; font.pixelSize: root.s(9)
//                                                     color: root[root.tabColors[card.tab]]
//                                                 }
//                                             }
//                                             Text {
//                                                 text: "›"; font.family: "Inter"; font.pixelSize: root.s(18)
//                                                 color: isSearchHighlighted ? root[card.color] : (searchCardMa.containsMouse ? root[card.color] : root.subtext0)
//                                                 Behavior on color { ColorAnimation { duration: 150 } }
//                                             }
//                                         }
//                                         MouseArea {
//                                             id: searchCardMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                                             onClicked: {
//                                                 jumpToSettingTimer.targetTab = card.tab;
//                                                 jumpToSettingTimer.targetBox = card.boxIndex;
//                                                 jumpToSettingTimer.start();
//                                                 root.currentTab = card.tab;
//                                                 if (card.tab === 0) root.tab0Loaded = true;
//                                                 else if (card.tab === 1) root.tab1Loaded = true;
//                                                 else if (card.tab === 2) root.tab2Loaded = true;
//                                                 root.isSearchMode = false;
//                                                 root.forceActiveFocus();
//                                                 globalSearchInput.text = "";
//                                                 root.globalSearchQuery = "";
//                                             }
//                                         }
//                                     }
//                                 }
//                             }

//                             Item {
//                                 Layout.fillWidth: true
//                                 Layout.preferredHeight: (root.globalSearchQuery.trim() !== "" && root.matchingKeybindIndices.length > 0) ? root.s(30) : 0
//                                 visible: root.globalSearchQuery.trim() !== "" && root.matchingKeybindIndices.length > 0
//                                 opacity: visible ? 1.0 : 0.0; clip: true
//                                 Behavior on Layout.preferredHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
//                                 Behavior on opacity { NumberAnimation { duration: 200 } }
//                                 RowLayout {
//                                     anchors.fill: parent; anchors.leftMargin: root.s(4); spacing: root.s(8)
//                                     Rectangle { width: root.s(3); height: root.s(12); radius: root.s(2); color: root.peach }
//                                     Text { text: "Keybinds (" + root.matchingKeybindIndices.length + " match" + (root.matchingKeybindIndices.length !== 1 ? "es" : "") + ")"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(10); color: root.peach }
//                                 }
//                             }

//                             Repeater {
//                                 id: keybindResultRepeater
//                                 model: root.matchingKeybindIndices.length
//                                 delegate: Item {
//                                     property int kbIndex: root.matchingKeybindIndices[index]
//                                     property var kbItem: dynamicKeybindsModel.get(kbIndex)
//                                     property int searchListIndex: {
//                                         let nCards = 0;
//                                         for (let i = 0; i < root.allSettingsCards.length; i++) {
//                                             if (root.globalSearchMatches(root.allSettingsCards[i], root.globalSearchQuery)) nCards++;
//                                         }
//                                         return nCards + index;
//                                     }
//                                     property bool isSearchHighlighted: root.searchHighlightIndex === searchListIndex && root.searchHighlightIndex >= 0
//                                     Layout.fillWidth: true
//                                     Layout.preferredHeight: root.globalSearchQuery.trim() !== "" ? root.s(54) : 0
//                                     visible: root.globalSearchQuery.trim() !== ""; opacity: visible ? 1.0 : 0.0; clip: true
//                                     Behavior on Layout.preferredHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
//                                     Behavior on opacity { NumberAnimation { duration: 200 } }

//                                     Rectangle {
//                                         anchors.fill: parent; radius: root.s(10)
//                                         color: isSearchHighlighted ? root.surface1 : (kbResultMa.containsMouse ? root.surface1 : root.surface0)
//                                         border.color: isSearchHighlighted ? root.peach : (kbResultMa.containsMouse ? root.peach : root.surface1)
//                                         border.width: isSearchHighlighted ? 2 : 1
//                                         Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }
//                                         Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }

//                                         RowLayout {
//                                             anchors.fill: parent; anchors.margins: root.s(11); spacing: root.s(11)
//                                             Rectangle {
//                                                 width: root.s(32); height: root.s(32); radius: root.s(8)
//                                                 color: Qt.alpha(root.peach, 0.12)
//                                                 border.color: Qt.alpha(root.peach, 0.25); border.width: 1
//                                                 Text {
//                                                     anchors.centerIn: parent; text: "󰌌"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(15)
//                                                     color: root.peach
//                                                 }
//                                             }
//                                             ColumnLayout {
//                                                 Layout.fillWidth: true; spacing: root.s(3)
//                                                 Row {
//                                                     spacing: root.s(4)
//                                                     Rectangle {
//                                                         width: modsT.implicitWidth + root.s(8); height: root.s(18); radius: root.s(4)
//                                                         color: root.surface1
//                                                         border.color: root.surface2; border.width: 1
//                                                         visible: kbItem && kbItem.mods !== ""
//                                                         Text {
//                                                             id: modsT; anchors.centerIn: parent; text: kbItem ? kbItem.mods : ""
//                                                             font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(8)
//                                                             color: root.peach
//                                                         }
//                                                     }
//                                                     Text {
//                                                         text: "+"; font.family: "JetBrains Mono"; font.pixelSize: root.s(9)
//                                                         color: root.overlay0
//                                                         visible: kbItem && kbItem.mods !== "" && kbItem.key !== ""; anchors.verticalCenter: parent.verticalCenter
//                                                     }
//                                                     Rectangle {
//                                                         width: keyT.implicitWidth + root.s(8); height: root.s(18); radius: root.s(4)
//                                                         color: root.surface1
//                                                         border.color: root.surface2; border.width: 1
//                                                         visible: kbItem && kbItem.key !== ""
//                                                         Text {
//                                                             id: keyT; anchors.centerIn: parent; text: kbItem ? kbItem.key : ""
//                                                             font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(8)
//                                                             color: root.peach
//                                                         }
//                                                     }
//                                                 }
//                                                 Text {
//                                                     text: kbItem ? (kbItem.dispatcher + " " + kbItem.command).trim() : ""
//                                                     font.family: "JetBrains Mono"; font.pixelSize: root.s(9)
//                                                     color: isSearchHighlighted ? root.peach : Qt.alpha(root.subtext0, 0.7)
//                                                     elide: Text.ElideRight; Layout.fillWidth: true
//                                                     Behavior on color { ColorAnimation { duration: 200 } }
//                                                 }
//                                             }
//                                             Rectangle {
//                                                 height: root.s(20); width: kbBadgeText.implicitWidth + root.s(12); radius: root.s(10)
//                                                 color: Qt.alpha(root.peach, 0.12)
//                                                 border.color: Qt.alpha(root.peach, 0.35); border.width: 1
//                                                 Text {
//                                                     id: kbBadgeText; anchors.centerIn: parent; text: "Keybinds"
//                                                     font.family: "JetBrains Mono"; font.pixelSize: root.s(9)
//                                                     color: root.peach
//                                                 }
//                                             }
//                                             Text {
//                                                 text: "›"; font.family: "Inter"; font.pixelSize: root.s(18)
//                                                 color: isSearchHighlighted ? root.peach : (kbResultMa.containsMouse ? root.peach : root.subtext0)
//                                                 Behavior on color { ColorAnimation { duration: 150 } }
//                                             }
//                                         }
//                                         MouseArea {
//                                             id: kbResultMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
//                                             onClicked: {
//                                                 jumpToSettingTimer.targetTab = 2;
//                                                 jumpToSettingTimer.targetBox = kbIndex;
//                                                 jumpToSettingTimer.start();
//                                                 root.currentTab = 2;
//                                                 root.tab2Loaded = true;
//                                                 root.isSearchMode = false;
//                                                 root.forceActiveFocus();
//                                                 globalSearchInput.text = "";
//                                                 root.globalSearchQuery = "";
//                                             }
//                                         }
//                                     }
//                                 }
//                             }
//                         }
//                     }

//                     Loader {
//                         id: generalLoader
//                         anchors.fill: parent
//                         active: root.tab0Loaded && Config.dataReady
//                         sourceComponent: generalTabComponent
//                         visible: root.currentTab === 0 && !root.isSearchMode
//                         opacity: visible ? 1.0 : 0.0
//                         Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                         function focusLangInput() { if (item) item.focusLangInput(); }
//                         function focusWpDirInput() { if (item) item.focusWpDirInput(); }
//                         function layoutListIncrementIndex() { if (item) item.layoutListIncrementIndex(); }
//                         function layoutListDecrementIndex() { if (item) item.layoutListDecrementIndex(); }
//                         function acceptLayoutSelection() { if (item) item.acceptLayoutSelection(); }
//                         function scrollTo(y) { if (item) item.scrollTo(y); }
//                         function scrollToBox(y) { if (item) item.scrollToBox(y); }
//                     }

//                     Loader {
//                         id: weatherLoader
//                         anchors.fill: parent
//                         active: root.tab1Loaded && Config.dataReady
//                         sourceComponent: weatherTabComponent
//                         visible: root.currentTab === 1 && !root.isSearchMode
//                         opacity: visible ? 1.0 : 0.0
//                         Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                         function focusApiKey() { if (item) item.focusApiKey(); }
//                         function focusCityId() { if (item) item.focusCityId(); }
//                         function scrollTo(y) { if (item) item.scrollTo(y); }
//                         function scrollToBox(y) { if (item) item.scrollToBox(y); }
//                     }

//                     Loader {
//                         id: keybindLoader
//                         anchors.fill: parent
//                         active: root.tab2Loaded && Config.dataReady
//                         sourceComponent: keybindTabComponent
//                         visible: root.currentTab === 2 && !root.isSearchMode
//                         opacity: visible ? 1.0 : 0.0
//                         Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
//                         function scrollToBottom() { if (item) item.scrollToBottom(); }
//                         function scrollTo(y) { if (item) item.scrollTo(y); }
//                         function scrollToBox(y) { if (item) item.scrollToBox(y); }
//                     }
//                 }
//             }
//         }
//     }
// }
// =============================================================================
// SETTINGS POPUP - Configuration Panel for Quickshell
// =============================================================================
// Architecture Overview:
// This is the main settings interface for the entire Quickshell environment.
// It's a tabbed panel with three sections: General, Weather, and Keybinds.
// The UI is designed for both mouse and keyboard navigation with a
// highlight-based focus system, global search functionality, and
// keyboard-driven controls throughout.
//
// KEY SYSTEMS:
// 1. TAB SYSTEM: Three tabs (General/Weather/Keybinds) loaded on-demand
//    via Loader components for performance
// 2. HIGHLIGHT SYSTEM: A single highlightedBox property tracks which
//    setting control has focus, navigable with arrow keys
// 3. GLOBAL SEARCH: Ctrl+F or / activates search mode, searches all
//    settings cards and keybinds, with scroll-to-result functionality
// 4. LAYOUT DROPDOWN: Keyboard layout toggle selector with keyboard nav
// 5. KEYBIND EDITOR: Dynamic list of keybinds with inline editing,
//    validation, and duplicate detection
// 6. CLOSE ANIMATION: Fade-out with submap reset and window close

// -----------------------------------------------------------------------------
// MODULE IMPORTS
// -----------------------------------------------------------------------------

// QtQuick: Core QML types - Item, Rectangle, Text, animations, ListModel, etc.
import QtQuick

// QtQuick.Window: Screen.width/height for responsive layout calculations
import QtQuick.Window

// QtQuick.Effects: MultiEffect for shadows and visual effects
import QtQuick.Effects

// QtQuick.Layouts: RowLayout, ColumnLayout for flexible responsive layouts
import QtQuick.Layouts

// QtQuick.Controls: (imported for potential ScrollView or other controls)
import QtQuick.Controls

// Quickshell: Shell framework for desktop integration
import Quickshell

// Quickshell.Io: Process (run external commands), StdioCollector (capture output),
// execDetached (fire-and-forget commands)
import Quickshell.Io

// Import parent directory for shared components (Scaler, MatugenColors, Config)
import "../"

// =============================================================================
// ROOT ITEM - The entire settings panel
// =============================================================================
Item {
    id: root  // Root identifier used throughout for property access

    // focus: true ensures this item receives keyboard events
    // Critical for the keyboard navigation system (arrow keys, enter, escape, etc.)
    focus: true

    // =========================================================================
    // SCALER - Resolution-independent sizing system
    // =========================================================================
    // The Scaler component computes a scaling factor based on Screen.width.
    // All visual sizes use root.s(value) to multiply by this factor.
    // This ensures the UI looks consistent across different resolutions.
    Scaler {
        id: scaler
        currentWidth: Screen.width  // Bind to actual screen width
    }

    // Convenience function: s(10) returns 10 * scalingFactor
    // Using a function reduces boilerplate throughout the file
    function s(val) { 
        return scaler.s(val); 
    }
    
    // =========================================================================
    // LAYOUT DROPDOWN STATE - Whether the keyboard layout selector is open
    // =========================================================================
    // When true, a dropdown list of keyboard layout toggle options is visible.
    // Keyboard navigation (Up/Down/Enter) is redirected to the dropdown.
    property bool isLayoutDropdownOpen: false

    // =========================================================================
    // SEARCH MODE STATE - Global search across all settings
    // =========================================================================
    // When true, a search input is focused and search results are displayed.
    // Keyboard navigation is redirected to search results.
    property bool isSearchMode: false

    // The current search query string, bound to the search input field
    property string globalSearchQuery: ""

    // =========================================================================
    // HIGHLIGHT SYSTEM - Which setting control has keyboard focus
    // =========================================================================
    // highlightedBox tracks the currently focused setting within a tab.
    // -1 means no setting is highlighted (default state).
    // Each tab has its own set of box indices (0-6 for General, 0-3 for Weather,
    // 0-N for Keybinds where N is the number of keybinds).
    // Arrow keys navigate between boxes; Enter activates the highlighted box.
    property int highlightedBox: -1

    // =========================================================================
    // SEARCH HIGHLIGHT - Which search result is currently selected
    // =========================================================================
    // Index into searchResultItems array. -1 means no result selected.
    // Up/Down arrows navigate; Enter activates the selected result.
    property int searchHighlightIndex: -1

    // =========================================================================
    // SEARCH RESULTS - Array of matching items from global search
    // =========================================================================
    // Each item is an object: { kind: "card"|"keybind", cardIndex: N, kbIndex: N }
    // cardIndex refers to allSettingsCards array index
    // kbIndex refers to dynamicKeybindsModel index
    property var searchResultItems: []

    // =========================================================================
    // REBUILD SEARCH RESULTS - Called when search query changes
    // =========================================================================
    // Iterates through all settings cards and keybinds, finds matches,
    // and builds the searchResultItems array. Also clamps the highlight
    // index if it exceeds the new result count.
    function rebuildSearchResultItems() {
        let items = [];  // Initialize empty results array

        // STEP 1: Search through all settings cards
        for (let i = 0; i < root.allSettingsCards.length; i++) {
            let card = root.allSettingsCards[i];
            // globalSearchMatches checks if the card's label or description
            // contains the search query (case-insensitive)
            if (root.globalSearchMatches(card, root.globalSearchQuery)) {
                // Add as a "card" kind result with the card's array index
                items.push({ kind: "card", cardIndex: i, kbIndex: -1 });
            }
        }

        // STEP 2: Search through keybinds
        // matchingKeybindIndices is computed separately and cached
        let kbIndices = root.matchingKeybindIndices;
        for (let j = 0; j < kbIndices.length; j++) {
            // Add as a "keybind" kind result with the keybind's model index
            items.push({ kind: "keybind", cardIndex: -1, kbIndex: kbIndices[j] });
        }

        // Update the results array (triggers UI update)
        root.searchResultItems = items;

        // Clamp highlight index if it's now out of bounds
        if (root.searchHighlightIndex >= items.length) {
            root.searchHighlightIndex = items.length - 1;
        }
    }

    // =========================================================================
    // SEARCH QUERY CHANGE HANDLER - Reacts to search input changes
    // =========================================================================
    // When the user types in the search box, this handler:
    // 1. Updates the matching keybind indices
    // 2. Rebuilds the combined search results
    // 3. Resets the highlight index (user hasn't navigated yet)
    onGlobalSearchQueryChanged: {
        root.matchingKeybindIndices = root.getMatchingKeybindIndices(
            root.globalSearchQuery
        );
        root.rebuildSearchResultItems();
        root.searchHighlightIndex = -1;  // Reset selection
    }

    // =========================================================================
    // SEARCH MODE CHANGE HANDLER - Entering/leaving search mode
    // =========================================================================
    // When exiting search mode, reset the highlight index.
    // When entering, rebuild results to populate the search list.
    onIsSearchModeChanged: {
        if (!root.isSearchMode) {
            root.searchHighlightIndex = -1;  // Clear selection on exit
        } else {
            root.rebuildSearchResultItems();  // Populate results on entry
        }
    }

    // =========================================================================
    // ACTIVATE SEARCH HIGHLIGHT - Navigate to and activate the selected result
    // =========================================================================
    // When the user presses Enter on a search result, this function:
    // 1. Identifies which setting/keybind was selected
    // 2. Jumps to the appropriate tab
    // 3. Highlights the specific box/card
    // 4. Scrolls it into view
    // 5. Exits search mode
    function activateSearchHighlight() {
        // Bounds check
        if (root.searchHighlightIndex < 0 ||
            root.searchHighlightIndex >= root.searchResultItems.length) return;

        let item = root.searchResultItems[root.searchHighlightIndex];

        if (item.kind === "card") {
            // SETTINGS CARD: Navigate to its tab and highlight it
            let card = root.allSettingsCards[item.cardIndex];

            // Set up the jump timer to scroll after tab switch
            jumpToSettingTimer.targetTab = card.tab;
            jumpToSettingTimer.targetBox = card.boxIndex;
            jumpToSettingTimer.start();

            // Switch to the target tab
            root.currentTab = card.tab;

            // Mark tab as loaded so its content appears
            // Lazy loading: tabs only load when first accessed
            if (card.tab === 0) root.tab0Loaded = true;
            else if (card.tab === 1) root.tab1Loaded = true;
            else if (card.tab === 2) root.tab2Loaded = true;
        } else {
            // KEYBIND: Navigate to Keybinds tab and highlight the keybind
            jumpToSettingTimer.targetTab = 2;       // Tab 2 = Keybinds
            jumpToSettingTimer.targetBox = item.kbIndex;
            jumpToSettingTimer.start();

            root.currentTab = 2;
            root.tab2Loaded = true;
        }

        // Exit search mode and clean up
        root.isSearchMode = false;
        root.forceActiveFocus();        // Return focus to root for keyboard nav
        globalSearchInput.text = "";    // Clear the search input
        root.globalSearchQuery = "";    // Reset the query
    }

    // =========================================================================
    // SCROLL SEARCH TO HIGHLIGHT - Ensure the selected search result is visible
    // =========================================================================
    // Calculates the approximate Y position of the highlighted result
    // within the search results flickable and scrolls to make it visible.
    function scrollSearchToHighlight(idx) {
        // Bounds check
        if (idx < 0 || idx >= root.searchResultItems.length) return;

        // Count how many card results come before keybind results
        let nCards = 0;
        for (let i = 0; i < root.allSettingsCards.length; i++) {
            if (root.globalSearchMatches(
                root.allSettingsCards[i], root.globalSearchQuery)) nCards++;
        }

        // Calculate item and header heights (scaled)
        let itemH = root.s(60) + root.s(10);   // Card height + spacing
        // Keybinds section has a header if there are matching keybinds
        let headerH = (root.matchingKeybindIndices.length > 0) ?
            root.s(32) + root.s(10) : 0;

        let approxY = 0;  // Accumulator for Y position
        let it = root.searchResultItems[idx];

        if (it.kind === "card") {
            // Cards come first in the list
            let pos = 0;
            // Count how many matching cards come before this one
            for (let i = 0; i < root.allSettingsCards.length; i++) {
                if (root.globalSearchMatches(
                    root.allSettingsCards[i], root.globalSearchQuery)) {
                    if (root.allSettingsCards[i] ===
                        root.allSettingsCards[item_cardIndex_from(idx)]) break;
                    pos++;
                }
            }
            approxY = pos * itemH;  // Position = cards before * card height
        } else {
            // Keybinds come after all cards + header
            approxY = nCards * itemH + headerH +
                (idx - nCards) * itemH;
            // (idx - nCards) = position within keybind results
        }

        // Add some padding and clamp to valid scroll range
        let target = Math.max(0, approxY - root.s(20));
        searchResultsFlickable.contentY = Math.min(
            target,
            Math.max(0, searchResultsFlickable.contentHeight -
                     searchResultsFlickable.height)
        );
    }

    // =========================================================================
    // HELPER: Extract cardIndex from a search result item
    // =========================================================================
    function item_cardIndex_from(idx) {
        let item = root.searchResultItems[idx];
        return item.cardIndex;
    }

    // =========================================================================
    // CLEAR HIGHLIGHT - Deselect the currently highlighted box
    // =========================================================================
    // Resets highlightedBox to -1 (nothing selected).
    // Used when clicking on empty space or pressing Escape.
    function clearHighlight() {
        root.highlightedBox = -1;
    }

    // =========================================================================
    // MAX HIGHLIGHT FOR TAB - Returns the highest valid box index for a tab
    // =========================================================================
    // Each tab has a different number of highlightable boxes:
    // Tab 0 (General): 0-6 (7 boxes: guide, help, scale, layout, toggle, wpdir, workspaces)
    // Tab 1 (Weather): 0-3 (4 boxes: api key, city id, temp unit, etc.)
    // Tab 2 (Keybinds): 0 to (keybindCount - 1) - dynamic
    function maxHighlightForTab(tab) {
        if (tab === 0) return 6;
        if (tab === 1) return 3;
        if (tab === 2) return dynamicKeybindsModel.count - 1;
        return -1;  // Unknown tab
    }

    // =========================================================================
    // ACTIVATE HIGHLIGHTED BOX - Perform the action for the selected box
    // =========================================================================
    // Called when Enter is pressed while a box is highlighted.
    // The action depends on which tab and which box is selected:
    // - General: Toggle switches, focus inputs, open dropdowns
    // - Weather: Focus input fields
    // - Keybinds: Toggle edit mode on the selected keybind
    function activateHighlightedBox() {
        if (root.currentTab === 0) {
            // ── GENERAL TAB ──
            if (root.highlightedBox === 0) {
                // Box 0: Toggle "Guide on startup"
                Config.openGuideAtStartup = !Config.openGuideAtStartup;
            } else if (root.highlightedBox === 1) {
                // Box 1: Toggle "Help icon in topbar"
                Config.topbarHelpIcon = !Config.topbarHelpIcon;
            } else if (root.highlightedBox === 2) {
                // Box 2: UI Scale (handled by left/right arrow keys in onPressed)
                // No action on Enter - scale is adjusted with arrow keys
            } else if (root.highlightedBox === 3) {
                // Box 3: Focus the keyboard layout language input
                if (generalLoader.item) generalLoader.item.focusLangInput();
            } else if (root.highlightedBox === 4) {
                // Box 4: Toggle the layout shortcut dropdown
                root.isLayoutDropdownOpen = !root.isLayoutDropdownOpen;
            } else if (root.highlightedBox === 5) {
                // Box 5: Focus the wallpaper directory input
                if (generalLoader.item) generalLoader.item.focusWpDirInput();
            } else if (root.highlightedBox === 6) {
                // Box 6: Workspace count (handled by left/right arrow keys)
                // No action on Enter
            }
        } else if (root.currentTab === 1) {
            // ── WEATHER TAB ──
            if (root.highlightedBox === 0) {
                // Box 0: (currently no action defined)
            } else if (root.highlightedBox === 1) {
                // Box 1: Focus API key input
                if (weatherLoader.item) weatherLoader.item.focusApiKey();
            } else if (root.highlightedBox === 2) {
                // Box 2: Focus City ID input
                if (weatherLoader.item) weatherLoader.item.focusCityId();
            } else if (root.highlightedBox === 3) {
                // Box 3: (temperature unit, handled elsewhere)
            }
        } else if (root.currentTab === 2) {
            // ── KEYBINDS TAB ──
            if (root.highlightedBox >= 0 &&
                root.highlightedBox < dynamicKeybindsModel.count) {
                // Toggle the editing state of the selected keybind
                let isEd = dynamicKeybindsModel.get(
                    root.highlightedBox).isEditing;
                dynamicKeybindsModel.setProperty(
                    root.highlightedBox, "isEditing", !isEd);
            }
        }
    }

    // =========================================================================
    // HIGHLIGHT CHANGE HANDLER - Scroll to show the newly highlighted box
    // =========================================================================
    // When the user navigates with arrow keys and highlightedBox changes,
    // this handler triggers a deferred scroll to ensure the highlighted
    // setting is visible in the flickable content area.
    // Qt.callLater defers the call to the next event loop iteration,
    // allowing the tab's Loader to finish rendering before scrolling.
    onHighlightedBoxChanged: {
        if (root.highlightedBox < 0) return;  // Nothing highlighted, skip
        Qt.callLater(function() {
            root.scrollHighlightedIntoView();
        });
    }

    // =========================================================================
    // SCROLL HIGHLIGHTED INTO VIEW - Calculate and set scroll position
    // =========================================================================
    // Each tab's content is in a Flickable/Loader. This function calculates
    // the approximate Y position of the highlighted box based on its index
    // and tells the appropriate loader to scroll there.
    function scrollHighlightedIntoView() {
        let box = root.highlightedBox;
        if (box < 0) return;

        if (root.currentTab === 0 && generalLoader.item) {
            // General tab: hardcoded approximate Y positions for each box
            let approxY = 0;
            if (box === 0 || box === 1) approxY = 0;           // Top section
            else if (box === 2) approxY = root.s(120);          // UI Scale section
            else if (box === 3 || box === 4) approxY = root.s(240); // Layout section
            else if (box === 5) approxY = root.s(400);          // Wallpaper section
            else if (box === 6) approxY = root.s(520);          // Workspaces section
            generalLoader.item.scrollToBox(approxY);
        } else if (root.currentTab === 1 && weatherLoader.item) {
            // Weather tab: approximate Y positions
            let approxY = 0;
            if (box === 0) approxY = 0;              // Top
            else if (box === 1) approxY = root.s(140); // API Key
            else if (box === 2) approxY = root.s(240); // City ID
            else if (box === 3) approxY = root.s(340); // Temp Unit
            weatherLoader.item.scrollToBox(approxY);
        } else if (root.currentTab === 2 && keybindLoader.item) {
            // Keybinds tab: linear spacing, each keybind is ~56px + 120px header
            let approxY = box * root.s(56) + root.s(120);
            keybindLoader.item.scrollToBox(approxY);
        }
    }

    // =========================================================================
    // TAB SYSTEM - Three-tab settings interface
    // =========================================================================
    // currentTab: 0=General, 1=Weather, 2=Keybinds
    // tabNames/tabIcons/tabColors: Display data for each tab
    // tabXLoaded: Lazy loading flags - tabs only load when first accessed
    property int currentTab: 0
    property var tabNames: ["General", "Weather", "Keybinds"]
    property var tabIcons: ["󰒓", "󰖐", "󰌌"]       // Nerd Font icons
    property var tabColors: ["teal", "blue", "peach"]  // Theme color names

    // Lazy loading flags: prevent loading tab content until the user
    // actually switches to that tab. This improves initial load time.
    property bool tab0Loaded: false
    property bool tab1Loaded: false
    property bool tab2Loaded: false

    // =========================================================================
    // TAB CHANGE HANDLER - Clear highlight and mark tab as loaded
    // =========================================================================
    onCurrentTabChanged: {
        root.clearHighlight();  // Deselect any highlighted box on tab switch
        // Mark the new tab as loaded so its Loader creates the content
        if (currentTab === 0) root.tab0Loaded = true;
        else if (currentTab === 1) root.tab1Loaded = true;
        else if (currentTab === 2) root.tab2Loaded = true;
    }

    // =========================================================================
    // ESCAPE KEY HANDLER - Multi-level dismiss behavior
    // =========================================================================
    // Escape has a priority chain:
    // 1. If search mode is active, exit search mode
    // 2. If layout dropdown is open, close it
    // 3. If a box is highlighted, clear the highlight
    // 4. If nothing else, close the settings panel (trigger close animation)
    Keys.onEscapePressed: {
        if (root.isSearchMode) {
            // Exit search mode: clear everything and close the search
            root.isSearchMode = false;
            root.globalSearchQuery = "";
            globalSearchInput.text = "";
            root.searchHighlightIndex = -1;
            event.accepted = true;  // Mark as handled
        } else if (root.isLayoutDropdownOpen) {
            // Close the layout dropdown
            root.isLayoutDropdownOpen = false;
            event.accepted = true;
        } else if (root.highlightedBox >= 0) {
            // Deselect the highlighted box
            root.clearHighlight();
            event.accepted = true;
        } else {
            // Close the entire settings panel
            closeSequence.start();
            event.accepted = true;
        }
    }

    // =========================================================================
    // TAB/Shift+TAB HANDLERS - Cycle between tabs
    // =========================================================================
    // Tab: Move to next tab (0→1→2→0)
    // Shift+Tab (Backtab): Move to previous tab (0→2→1→0)
    // Both are ignored when search mode is active (Tab might be used for
    // navigating search results in some implementations)
    Keys.onTabPressed: (event) => {
        if (root.isSearchMode) return;  // Don't interfere with search
        root.currentTab = (root.currentTab + 1) % 3;  // Next tab with wrap
        event.accepted = true;
    }
    Keys.onBacktabPressed: (event) => {
        if (root.isSearchMode) return;
        // +2 mod 3 is equivalent to -1 mod 3 (previous tab with wrap)
        root.currentTab = (root.currentTab + 2) % 3;
        event.accepted = true;
    }

    // =========================================================================
    // KEY PRESS HANDLER - Comprehensive keyboard navigation
    // =========================================================================
    // This is the central keyboard handler. It processes keys in priority order:
    // 1. Ctrl+F or / → Activate search mode
    // 2. Search mode keys (Up/Down for navigation)
    // 3. Dropdown keys (Up/Down for layout list)
    // 4. Left/Right arrows for UI Scale and Workspace Count adjustment
    // 5. Up/Down arrows for box highlight navigation
    Keys.onPressed: (event) => {
        // ── PRIORITY 1: Activate search mode ──
        // Ctrl+F (standard "find" shortcut) or / (vim-style search)
        // Only / activates when NOT already in search mode
        if ((event.key === Qt.Key_F &&
             (event.modifiers & Qt.ControlModifier)) || 
            (event.key === Qt.Key_Slash && !root.isSearchMode)) {
            root.isSearchMode = true;                   // Enter search mode
            globalSearchInput.forceActiveFocus();        // Focus the input
            event.accepted = true;
            return;  // Don't process further
        }

        // ── PRIORITY 2: Search mode navigation ──
        if (root.isSearchMode) {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                // Move focus back to root so subsequent key events are handled here
                root.forceActiveFocus();
                let total = root.searchResultItems.length;
                if (total === 0) {
                    event.accepted = true;
                    return;  // No results to navigate
                }

                if (event.key === Qt.Key_Down) {
                    // Down: increment highlight, wrap to top if at end
                    if (root.searchHighlightIndex < total - 1) {
                        root.searchHighlightIndex++;
                    } else {
                        root.searchHighlightIndex = 0;  // Wrap to first
                    }
                } else {
                    // Up: decrement highlight, wrap to bottom if at start
                    if (root.searchHighlightIndex > 0) {
                        root.searchHighlightIndex--;
                    } else if (root.searchHighlightIndex === 0) {
                        root.searchHighlightIndex = total - 1;  // Wrap to last
                    } else {
                        root.searchHighlightIndex = total - 1;  // From -1, go to last
                    }
                }
                // Scroll to make the new highlight visible
                root.scrollSearchHighlightIntoView(root.searchHighlightIndex);
                event.accepted = true;
                return;
            }
            // In search mode, don't process any other keys here
            return;
        }

        // ── PRIORITY 3: Layout dropdown navigation ──
        if (root.isLayoutDropdownOpen) {
            if (event.key === Qt.Key_Down) {
                // Move selection down in the layout list
                if (generalLoader.item)
                    generalLoader.item.layoutListIncrementIndex();
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                // Move selection up in the layout list
                if (generalLoader.item)
                    generalLoader.item.layoutListDecrementIndex();
                event.accepted = true;
            }
            return;  // Don't process other keys when dropdown is open
        }
        
        // ── PRIORITY 4: Left/Right arrows for specific controls ──
        // These adjust values when the relevant box is highlighted
        if (event.key === Qt.Key_Left) {
            if (root.currentTab === 0 && root.highlightedBox === 2) {
                // UI Scale: decrease by 0.1, minimum 0.5
                Config.uiScale = Math.max(0.5,
                    (Config.uiScale - 0.1).toFixed(1));
                event.accepted = true;
                return;
            } else if (root.currentTab === 0 && root.highlightedBox === 6) {
                // Workspace count: decrease by 1, minimum 2
                Config.workspaceCount = Math.max(2,
                    Config.workspaceCount - 1);
                event.accepted = true;
                return;
            }
        }
        if (event.key === Qt.Key_Right) {
            if (root.currentTab === 0 && root.highlightedBox === 2) {
                // UI Scale: increase by 0.1, maximum 2.0
                Config.uiScale = Math.min(2.0,
                    (Config.uiScale + 0.1).toFixed(1));
                event.accepted = true;
                return;
            } else if (root.currentTab === 0 && root.highlightedBox === 6) {
                // Workspace count: increase by 1, maximum 10
                Config.workspaceCount = Math.min(10,
                    Config.workspaceCount + 1);
                event.accepted = true;
                return;
            }
        }

        // ── PRIORITY 5: Up/Down arrows for box highlight navigation ──
        if (event.key === Qt.Key_Down) {
            let maxIdx = root.maxHighlightForTab(root.currentTab);
            if (maxIdx < 0) {
                event.accepted = true;
                return;  // No highlightable boxes
            }
            if (root.highlightedBox < maxIdx) {
                // Move down one box
                root.highlightedBox = root.highlightedBox + 1;
            } else if (root.highlightedBox === maxIdx) {
                // At the last box: deselect (go to -1)
                root.highlightedBox = -1;
            } else {
                // Nothing selected: select first box
                root.highlightedBox = 0;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            let maxIdx = root.maxHighlightForTab(root.currentTab);
            if (maxIdx < 0) {
                event.accepted = true;
                return;
            }
            if (root.highlightedBox > 0) {
                // Move up one box
                root.highlightedBox = root.highlightedBox - 1;
            } else if (root.highlightedBox === 0) {
                // At the first box: deselect
                root.highlightedBox = -1;
            } else {
                // Nothing selected: select last box
                root.highlightedBox = maxIdx;
            }
            event.accepted = true;
        }
    }

    // =========================================================================
    // ENTER/RETURN HANDLERS - Activate the current selection
    // =========================================================================
    // Both Keys.onReturnPressed and Keys.onEnterPressed call the same handler.
    // This handles:
    // 1. Search mode: activate the highlighted search result
    // 2. Dropdown open: accept the selected layout option
    // 3. Box highlighted: activate that box's action
    // 4. Nothing selected: save current tab's settings
    Keys.onReturnPressed: (event) => root.handleRootEnter(event)
    Keys.onEnterPressed: (event) => root.handleRootEnter(event)

    function handleRootEnter(event) {
        if (root.isSearchMode) {
            // Activate the selected search result (jump to that setting)
            if (root.searchHighlightIndex >= 0) {
                root.activateSearchHighlight();
                event.accepted = true;
            }
            return;
        }
        if (root.isLayoutDropdownOpen) {
            // Accept the selected layout option
            if (generalLoader.item)
                generalLoader.item.acceptLayoutSelection();
            root.isLayoutDropdownOpen = false;
            event.accepted = true;
            return;
        }
        if (root.highlightedBox >= 0) {
            // Activate the highlighted box (toggle, focus, etc.)
            root.activateHighlightedBox();
            event.accepted = true;
            return;
        }
        // Nothing selected: save current tab's settings
        if (root.currentTab === 0) Config.saveAppSettings();
        else if (root.currentTab === 1) Config.saveWeatherConfig();
        else if (root.currentTab === 2) root.saveAllKeybinds();
        event.accepted = true;
    }

    // =========================================================================
    // SCROLL SEARCH HIGHLIGHT INTO VIEW - Ensure search result is visible
    // =========================================================================
    // Calculates the position of a search result item and scrolls the
    // search results flickable to make it visible with padding.
    function scrollSearchHighlightIntoView(idx) {
        if (idx < 0 || idx >= root.searchResultItems.length) return;

        // Count cards before keybinds (for position calculation)
        let nCards = 0;
        for (let i = 0; i < root.allSettingsCards.length; i++) {
            if (root.globalSearchMatches(
                root.allSettingsCards[i], root.globalSearchQuery)) nCards++;
        }
        let hasKbHeader = root.matchingKeybindIndices.length > 0;
        let itemH = root.s(60) + root.s(10);   // Item height + spacing
        let headerH = hasKbHeader ?
            (root.s(32) + root.s(10)) : 0;      // Header height if keybinds exist

        let approxY = 0;
        let it = root.searchResultItems[idx];
        if (it.kind === "card") {
            // Count card results before this one
            let pos = 0;
            for (let i = 0; i < root.searchResultItems.length; i++) {
                if (i === idx) break;
                if (root.searchResultItems[i].kind === "card") pos++;
            }
            approxY = pos * itemH;
        } else {
            // Count keybind results before this one
            let kbPos = 0;
            for (let i = 0; i < root.searchResultItems.length; i++) {
                if (i === idx) break;
                if (root.searchResultItems[i].kind === "keybind") kbPos++;
            }
            // Position = all cards + header + preceding keybinds
            approxY = nCards * itemH + headerH + kbPos * itemH;
        }

        // Get viewport and content dimensions
        let viewH = searchResultsFlickable.height;
        let contentH = searchResultsFlickable.contentHeight;
        let curY = searchResultsFlickable.contentY;
        let itemTop = approxY;
        let itemBottom = approxY + root.s(60);

        // Scroll if the item is above the visible area (with padding)
        if (itemTop < curY + root.s(10)) {
            searchResultsFlickable.contentY = Math.max(
                0, itemTop - root.s(10)
            );
        }
        // Scroll if the item is below the visible area (with padding)
        else if (itemBottom > curY + viewH - root.s(10)) {
            searchResultsFlickable.contentY = Math.min(
                contentH - viewH,
                itemBottom - viewH + root.s(10)
            );
        }
    }

    // =========================================================================
    // THEME COLORS - Matugen/Material Design color system
    // =========================================================================
    // MatugenColors reads the system color scheme and exposes all palette colors.
    // These are readonly to prevent accidental modification.
    MatugenColors { id: _theme }

    readonly property color base: _theme.base           // Main background
    readonly property color mantle: _theme.mantle       // Slightly darker bg
    readonly property color crust: _theme.crust         // Darkest bg
    readonly property color text: _theme.text           // Primary text
    readonly property color subtext0: _theme.subtext0   // Secondary text
    readonly property color subtext1: _theme.subtext1   // Tertiary text
    readonly property color surface0: _theme.surface0   // Card bg (darkest)
    readonly property color surface1: _theme.surface1   // Card bg (medium)
    readonly property color surface2: _theme.surface2   // Card bg (lightest)
    readonly property color overlay0: _theme.overlay0   // Muted overlay
    readonly property color mauve: _theme.mauve         // Accent: purple
    readonly property color pink: _theme.pink           // Accent: pink
    readonly property color blue: _theme.blue           // Accent: blue
    readonly property color sapphire: _theme.sapphire   // Accent: dark blue
    readonly property color teal: _theme.teal           // Accent: teal
    readonly property color green: _theme.green         // Accent: green
    readonly property color peach: _theme.peach         // Accent: warm orange
    readonly property color yellow: _theme.yellow       // Accent: yellow
    readonly property color red: _theme.red             // Accent: red (errors)

    // =========================================================================
    // KEYBOARD TOGGLE MODEL - Layout switching options
    // =========================================================================
    // Array of objects mapping display labels to XKB options values.
    // These are the available keyboard layout toggle combinations.
    // The 'val' property corresponds to XKB grp: options.
    property var kbToggleModelArr: [
        { label: "Alt + Shift",     val: "grp:alt_shift_toggle" },
        { label: "Win + Space",     val: "grp:win_space_toggle" },
        { label: "Caps Lock",       val: "grp:caps_toggle" },
        { label: "Ctrl + Shift",    val: "grp:ctrl_shift_toggle" },
        { label: "Ctrl + Alt",      val: "grp:ctrl_alt_toggle" },
        { label: "Right Alt",       val: "grp:toggle" },
        { label: "No Toggle",       val: "" }                // Empty = no toggle
    ]

    // =========================================================================
    // GET KB TOGGLE LABEL - Convert a toggle value to its display label
    // =========================================================================
    // Searches the kbToggleModelArr for a matching 'val' and returns the label.
    // If not found, defaults to "Alt + Shift" (most common default).
    function getKbToggleLabel(val) {
        for (let i = 0; i < root.kbToggleModelArr.length; i++) {
            if (root.kbToggleModelArr[i].val === val)
                return root.kbToggleModelArr[i].label;
        }
        return "Alt + Shift";  // Fallback default
    }

    // =========================================================================
    // DYNAMIC KEYBINDS MODEL - Editable keybind list
    // =========================================================================
    // ListModel that holds all user-configurable keybinds.
    // Each entry has: type, mods, key, dispatcher, command, isEditing
    // Populated from Config.keybindsData when loaded or changed.
    ListModel { id: dynamicKeybindsModel }
    
    // =========================================================================
    // CONFIG CONNECTIONS - React to keybind data changes
    // =========================================================================
    // Two signals from the Config singleton:
    // 1. onKeybindsLoaded: Fires when Config first reads the JSON file
    // 2. onKeybindsDataChanged: Fires when Config.keybindsData is overwritten
    // Both clear the model and re-populate from the current data.
    Connections {
        target: Config
        function onKeybindsLoaded() {
            dynamicKeybindsModel.clear();        // Clear existing entries
            dynamicKeybindsModel.append(Config.keybindsData);  // Re-populate
        }
        function onKeybindsDataChanged() {
            dynamicKeybindsModel.clear();
            dynamicKeybindsModel.append(Config.keybindsData);
        }
    }    

    // =========================================================================
    // KEYBIND TYPE DEFINITIONS
    // =========================================================================
    // bindTypes: Valid Hyprland bind prefixes
    // bind = regular keybind
    // binde = exec-on-repeat (fires continuously while held)
    // bindl = locked keybind (works when screen is locked)
    // bindel = exec-on-repeat + locked
    // bindm = mouse bind
    property var bindTypes: ["bind", "binde", "bindl", "bindel", "bindm"]

    // dispatchers: Valid Hyprland dispatcher commands
    // exec / exec-once: Run a command
    // dispatch: Execute a Hyprland dispatcher (e.g., "workspace, 1")
    // workspace: Switch to workspace
    // movetoworkspace: Move window to workspace
    // movewindow: Move window in direction
    // resizeactive: Resize active window
    // movefocus: Move focus in direction
    // togglefloating: Toggle floating mode
    // killactive: Close active window
    property var dispatchers: [
        "exec", "exec-once", "dispatch", "workspace",
        "movetoworkspace", "movewindow", "resizeactive",
        "movefocus", "togglefloating", "killactive"
    ]

    // =========================================================================
    // SAVE ALL KEYBINDS - Serialize the dynamic model back to Config
    // =========================================================================
    // Iterates through the dynamicKeybindsModel, builds an array of objects,
    // and passes it to Config.saveAllKeybinds() which writes it to disk.
    // IMPORTANT: isEditing is explicitly set to false in the saved data
    // to prevent QML from persisting the editing state.
    function saveAllKeybinds() {
        let bindsArray = [];
        for (let i = 0; i < dynamicKeybindsModel.count; i++) {
            let item = dynamicKeybindsModel.get(i);
            if (!item.key && !item.command) continue;  // Skip empty entries
            bindsArray.push({
                type: item.type,
                mods: item.mods,
                key: item.key,
                dispatcher: item.dispatcher,
                command: item.command,
                isEditing: false  // CRITICAL: Prevent QML from saving edit state
            });
        }
        Config.saveAllKeybinds(bindsArray);
    }

    // =========================================================================
    // VALIDATE KEYBIND - Check for invalid modifiers and duplicates
    // =========================================================================
    // Returns "VALID" if the keybind is acceptable, or an error message string.
    // Validation steps:
    // 1. Parse the mods string into an array (split by space or &)
    // 2. Check each modifier against the validMods list
    // 3. Normalize and compare against all other keybinds for duplicates
    function validateKeybind(index, mods, key, dispatcher, command) {
        // Valid modifier key names in Hyprland
        let validMods = [
            "SHIFT", "SHIFT_L", "SHIFT_R", "CAPS", "CTRL", "CONTROL",
            "ALT", "MOD2", "MOD3", "SUPER", "WIN", "LOGO", "MOD4",
            "MOD5", "$mainMod"
        ];

        // Parse mods: replace & with space, split, filter empty strings
        let modArray = mods ?
            mods.replace(/&/g, " ").split(" ").filter(x => x !== "") : [];
        
        // Check each modifier against the valid list
        for (let i = 0; i < modArray.length; i++) {
            if (!validMods.includes(modArray[i])) {
                return "Invalid modifier: " + modArray[i] +
                    ".\nKeys like SPACE cannot be used as modifiers.";
            }
        }

        // Normalize for duplicate checking: sort mods alphabetically,
        // lowercase the key
        let currentModsNormalized = modArray.slice().sort().join(" ");
        let currentKeyNormalized = key.trim().toLowerCase();

        // Check against all other keybinds in the model
        for (let i = 0; i < dynamicKeybindsModel.count; i++) {
            if (i === index) continue;  // Skip the keybind being edited

            let item = dynamicKeybindsModel.get(i);
            if (!item.key) continue;  // Skip keybinds with no key set

            // Normalize the comparison keybind the same way
            let itemModsNormalized = item.mods ?
                item.mods.replace(/&/g, " ")
                    .split(" ")
                    .filter(x => x !== "")
                    .sort()
                    .join(" ") : "";
            let itemKeyNormalized = item.key.trim().toLowerCase();

            // Check for exact duplicate
            if (itemModsNormalized === currentModsNormalized &&
                itemKeyNormalized === currentKeyNormalized) {
                return "Duplicate keybind!\nThis exact combination already exists.";
            }
        }

        return "VALID";  // All checks passed
    }

    // =========================================================================
    // SCROLL TIMER - Auto-scroll to bottom after adding a keybind
    // =========================================================================
    // 50ms delay ensures the new keybind delegate is created before scrolling.
    Timer {
        id: scrollTimer
        interval: 50
        onTriggered: {
            if (keybindLoader.item) {
                keybindLoader.item.scrollToBottom();
            }
        }
    }

    // =========================================================================
    // JUMP TO SETTING TIMER - Delayed scroll after tab switch
    // =========================================================================
    // When navigating from search results or other jump actions, the target
    // tab's Loader needs time to create the content before we can scroll.
    // This timer waits 100ms then scrolls and highlights the target box.
    Timer {
        id: jumpToSettingTimer
        interval: 100  // Wait for Loader to render content
        property int targetTab: 0      // Tab to switch to
        property int targetBox: -1     // Box to highlight

        onTriggered: {
            if (targetBox >= 0) {
                root.highlightedBox = targetBox;  // Set the highlight

                let approxY = 0;

                // Calculate scroll position based on tab and box
                if (targetTab === 0 && generalLoader.item) {
                    if (targetBox === 0 || targetBox === 1) approxY = 0;
                    else if (targetBox === 2) approxY = root.s(120);
                    else if (targetBox === 3 || targetBox === 4) approxY = root.s(240);
                    else if (targetBox === 5) approxY = root.s(400);
                    else if (targetBox === 6) approxY = root.s(520);
                    generalLoader.item.scrollTo(approxY);
                } else if (targetTab === 1 && weatherLoader.item) {
                    if (targetBox === 1) approxY = root.s(140);
                    else if (targetBox === 2) approxY = root.s(240);
                    else if (targetBox === 3) approxY = root.s(340);
                    weatherLoader.item.scrollTo(approxY);
                } else if (targetTab === 2 && keybindLoader.item) {
                    approxY = targetBox * (root.s(56)) + root.s(120);
                    keybindLoader.item.scrollTo(approxY);
                }

                targetBox = -1;  // Reset for next use
            }
        }
    }    

    // =========================================================================
    // LANGUAGE MODEL - Comprehensive keyboard layout list
    // =========================================================================
    // ListModel containing hundreds of keyboard layouts organized by region.
    // Each entry has:
    // - code: The XKB layout code (e.g., "us", "gb", "jp")
    // - name: Human-readable name (e.g., "English (US)", "Japanese")
    //
    // Organized into regional sections:
    // 1. Americas (US, Canada, Latin America, South America)
    // 2. Europe West/Central/North (UK, France, Germany, Nordic, etc.)
    // 3. Europe East & Caucasus (Russia, Ukraine, Balkans, Central Asia)
    // 4. Asia & Pacific (China, Japan, Korea, India, Southeast Asia)
    // 5. Middle East & North Africa (Arabic, Hebrew, Persian)
    // 6. Sub-Saharan Africa
    // 7. Alternative Layouts (Dvorak, Colemak, etc.)
    ListModel {
        id: langModel

        // --- Americas ---
        ListElement { code: "us"; name: "English (US)" }
        ListElement { code: "ca"; name: "English/French (Canada)" }
        ListElement { code: "ca-multix"; name: "Canadian Multilingual" }
        ListElement { code: "latam"; name: "Spanish (Latin America)" }
        ListElement { code: "br"; name: "Portuguese (Brazil)" }
        ListElement { code: "ar"; name: "Arabic (Latin America)" }
        ListElement { code: "bo"; name: "Bolivia" }
        ListElement { code: "cl"; name: "Chile" }
        ListElement { code: "co"; name: "Colombia" }
        ListElement { code: "cr"; name: "Costa Rica" }
        ListElement { code: "cu"; name: "Cuba" }
        ListElement { code: "do"; name: "Dominican Republic" }
        ListElement { code: "ec"; name: "Ecuador" }
        ListElement { code: "sv"; name: "El Salvador" }
        ListElement { code: "gt"; name: "Guatemala" }
        ListElement { code: "hn"; name: "Honduras" }
        ListElement { code: "mx"; name: "Mexico" }
        ListElement { code: "ni"; name: "Nicaragua" }
        ListElement { code: "pa"; name: "Panama" }
        ListElement { code: "py"; name: "Paraguay" }
        ListElement { code: "pe"; name: "Peru" }
        ListElement { code: "pr"; name: "Puerto Rico" }
        ListElement { code: "uy"; name: "Uruguay" }
        ListElement { code: "ve"; name: "Venezuela" }

        // --- Europe (West, Central, & North) ---
        ListElement { code: "gb"; name: "English (UK)" }
        ListElement { code: "ie"; name: "English (Ireland)" }
        ListElement { code: "gd"; name: "Scottish Gaelic" }
        ListElement { code: "cy-gb"; name: "Welsh" }
        ListElement { code: "fr"; name: "French" }
        ListElement { code: "be"; name: "Belgian" }
        ListElement { code: "ch"; name: "Swiss" }
        ListElement { code: "de"; name: "German" }
        ListElement { code: "at"; name: "Austrian" }
        ListElement { code: "nl"; name: "Dutch" }
        ListElement { code: "lu"; name: "Luxembourgish" }
        ListElement { code: "es"; name: "Spanish" }
        ListElement { code: "pt"; name: "Portuguese" }
        ListElement { code: "it"; name: "Italian" }
        ListElement { code: "mt"; name: "Maltese" }
        ListElement { code: "se"; name: "Swedish" }
        ListElement { code: "no"; name: "Norwegian" }
        ListElement { code: "dk"; name: "Danish" }
        ListElement { code: "fi"; name: "Finnish" }
        ListElement { code: "is"; name: "Icelandic" }
        ListElement { code: "fo"; name: "Faroese" }
        ListElement { code: "gl"; name: "Greenlandic" }
        ListElement { code: "pl"; name: "Polish" }
        ListElement { code: "cz"; name: "Czech" }
        ListElement { code: "sk"; name: "Slovak" }
        ListElement { code: "hu"; name: "Hungarian" }
        ListElement { code: "ad"; name: "Andorra" }
        ListElement { code: "mc"; name: "Monaco" }
        ListElement { code: "sm"; name: "San Marino" }
        ListElement { code: "va"; name: "Vatican" }
        ListElement { code: "epo"; name: "Esperanto" }
        ListElement { code: "eu"; name: "Basque" }
        ListElement { code: "ca-fr"; name: "Catalan" }

        // --- Europe (East) & Caucasus ---
        ListElement { code: "ru"; name: "Russian" }
        ListElement { code: "ua"; name: "Ukrainian" }
        ListElement { code: "by"; name: "Belarusian" }
        ListElement { code: "ro"; name: "Romanian" }
        ListElement { code: "bg"; name: "Bulgarian" }
        ListElement { code: "rs"; name: "Serbian" }
        ListElement { code: "hr"; name: "Croatian" }
        ListElement { code: "si"; name: "Slovenian" }
        ListElement { code: "mk"; name: "Macedonian" }
        ListElement { code: "ba"; name: "Bosnian" }
        ListElement { code: "me"; name: "Montenegrin" }
        ListElement { code: "gr"; name: "Greek" }
        ListElement { code: "cy"; name: "Cyprus" }
        ListElement { code: "ee"; name: "Estonian" }
        ListElement { code: "lv"; name: "Latvian" }
        ListElement { code: "lt"; name: "Lithuanian" }
        ListElement { code: "md"; name: "Moldovan" }
        ListElement { code: "am"; name: "Armenian" }
        ListElement { code: "ge"; name: "Georgian" }
        ListElement { code: "az"; name: "Azerbaijani" }
        ListElement { code: "kz"; name: "Kazakh" }
        ListElement { code: "kg"; name: "Kyrgyz" }
        ListElement { code: "tj"; name: "Tajik" }
        ListElement { code: "tm"; name: "Turkmen" }
        ListElement { code: "uz"; name: "Uzbek" }
        ListElement { code: "mn"; name: "Mongolian" }
        ListElement { code: "tat"; name: "Tatar" }
        ListElement { code: "chu"; name: "Chuvash" }
        ListElement { code: "os"; name: "Ossetian" }
        ListElement { code: "udm"; name: "Udmurt" }
        ListElement { code: "kbd"; name: "Kabardian" }
        ListElement { code: "che"; name: "Chechen" }

        // --- Asia & Pacific ---
        ListElement { code: "au"; name: "English (Australia)" }
        ListElement { code: "nz"; name: "English (New Zealand)" }
        ListElement { code: "cn"; name: "Chinese" }
        ListElement { code: "jp"; name: "Japanese" }
        ListElement { code: "kr"; name: "Korean" }
        ListElement { code: "tw"; name: "Taiwanese" }
        ListElement { code: "hk"; name: "Hong Kong" }
        ListElement { code: "in"; name: "Indian" }
        ListElement { code: "pk"; name: "Pakistani" }
        ListElement { code: "bd"; name: "Bangla" }
        ListElement { code: "lk"; name: "Sri Lankan" }
        ListElement { code: "np"; name: "Nepali" }
        ListElement { code: "mv"; name: "Maldivian (Dhivehi)" }
        ListElement { code: "bt"; name: "Bhutanese (Dzongkha)" }
        ListElement { code: "af"; name: "Afghan (Pashto/Dari)" }
        ListElement { code: "th"; name: "Thai" }
        ListElement { code: "vn"; name: "Vietnamese" }
        ListElement { code: "la"; name: "Lao" }
        ListElement { code: "mm"; name: "Burmese" }
        ListElement { code: "kh"; name: "Khmer" }
        ListElement { code: "id"; name: "Indonesian" }
        ListElement { code: "my"; name: "Malay" }
        ListElement { code: "ph"; name: "Filipino" }
        ListElement { code: "sg"; name: "Singaporean" }
        ListElement { code: "bn"; name: "Bengali" }
        ListElement { code: "ta"; name: "Tamil" }
        ListElement { code: "te"; name: "Telugu" }
        ListElement { code: "gu"; name: "Gujarati" }
        ListElement { code: "pa"; name: "Punjabi" }
        ListElement { code: "ml"; name: "Malayalam" }
        ListElement { code: "kn"; name: "Kannada" }
        ListElement { code: "or"; name: "Odia" }
        ListElement { code: "as"; name: "Assamese" }
        ListElement { code: "ur"; name: "Urdu" }

        // --- Middle East & North Africa ---
        ListElement { code: "il"; name: "Hebrew" }
        ListElement { code: "ara"; name: "Arabic" }
        ListElement { code: "iq"; name: "Iraqi" }
        ListElement { code: "sy"; name: "Syrian" }
        ListElement { code: "ir"; name: "Persian (Farsi)" }
        ListElement { code: "ma"; name: "Moroccan" }
        ListElement { code: "dz"; name: "Algerian" }
        ListElement { code: "eg"; name: "Egyptian" }
        ListElement { code: "ly"; name: "Libyan" }
        ListElement { code: "tn"; name: "Tunisian" }
        ListElement { code: "sd"; name: "Sudanese" }
        ListElement { code: "lb"; name: "Lebanese" }
        ListElement { code: "jo"; name: "Jordanian" }
        ListElement { code: "ps"; name: "Palestinian" }
        ListElement { code: "sa"; name: "Saudi Arabian" }
        ListElement { code: "kw"; name: "Kuwaiti" }
        ListElement { code: "bh"; name: "Bahraini" }
        ListElement { code: "qa"; name: "Qatari" }
        ListElement { code: "ae"; name: "UAE" }
        ListElement { code: "om"; name: "Omani" }
        ListElement { code: "ye"; name: "Yemeni" }

        // --- Sub-Saharan Africa ---
        ListElement { code: "za"; name: "English (South Africa)" }
        ListElement { code: "ng"; name: "Nigerian" }
        ListElement { code: "et"; name: "Ethiopian" }
        ListElement { code: "sn"; name: "Senegalese" }
        ListElement { code: "ke"; name: "Kenyan" }
        ListElement { code: "tz"; name: "Tanzanian" }
        ListElement { code: "gh"; name: "Ghanaian" }
        ListElement { code: "cm"; name: "Cameroonian" }
        ListElement { code: "ci"; name: "Ivorian" }
        ListElement { code: "ml"; name: "Malian" }
        ListElement { code: "gn"; name: "Guinean" }
        ListElement { code: "cd"; name: "Congolese (DRC)" }
        ListElement { code: "cg"; name: "Congolese (RC)" }
        ListElement { code: "rw"; name: "Rwandan" }
        ListElement { code: "bi"; name: "Burundian" }
        ListElement { code: "ug"; name: "Ugandan" }
        ListElement { code: "zm"; name: "Zambian" }
        ListElement { code: "zw"; name: "Zimbabwean" }
        ListElement { code: "mw"; name: "Malawian" }
        ListElement { code: "mz"; name: "Mozambican" }
        ListElement { code: "ao"; name: "Angolan" }
        ListElement { code: "na"; name: "Namibian" }
        ListElement { code: "bw"; name: "Motswana" }
        ListElement { code: "mg"; name: "Malagasy" }
        ListElement { code: "so"; name: "Somali" }
        ListElement { code: "dj"; name: "Djiboutian" }
        ListElement { code: "er"; name: "Eritrean" }
        ListElement { code: "tg"; name: "Togolese" }
        ListElement { code: "bj"; name: "Beninese" }
        ListElement { code: "bf"; name: "Burkinabe" }
        ListElement { code: "ne"; name: "Nigerien" }
        ListElement { code: "td"; name: "Chadian" }
        ListElement { code: "cf"; name: "Central African" }
        ListElement { code: "gq"; name: "Equatorial Guinean" }
        ListElement { code: "ga"; name: "Gabonese" }

        // --- Alternative Layouts ---
        ListElement { code: "us-intl"; name: "US International" }
        ListElement { code: "dvorak"; name: "US Dvorak" }
        ListElement { code: "colemak"; name: "US Colemak" }
        ListElement { code: "norman"; name: "US Norman" }
        ListElement { code: "workman"; name: "US Workman" }
        ListElement { code: "math"; name: "Mathematics" }
        ListElement { code: "brai"; name: "Braille" }
    }

    // =========================================================================
    // PATH SUGGEST MODEL - Filesystem path autocomplete
    // =========================================================================
    // Populated by pathSuggestProc when the user types in a directory path.
    // Each entry has a 'path' property with a suggested directory.
    ListModel { id: pathSuggestModel }

    // =========================================================================
    // LANGUAGE SEARCH MODEL - Filtered keyboard layouts
    // =========================================================================
    // Populated by updateLangSearch() when the user types in the layout search.
    // Contains only layouts matching the search query.
    ListModel { id: langSearchModel }

    // =========================================================================
    // UPDATE LANGUAGE SEARCH - Filter langModel by query
    // =========================================================================
    // Clears the search model and re-populates with matching layouts.
    // Matches on both code and name, case-insensitive.
    // An empty query shows ALL layouts.
    function updateLangSearch(query) {
        langSearchModel.clear();
        let q = query.trim().toLowerCase();
        for (let i = 0; i < langModel.count; i++) {
            let item = langModel.get(i);
            if (q === "" ||
                item.code.toLowerCase().includes(q) ||
                item.name.toLowerCase().includes(q)) {
                langSearchModel.append({
                    code: item.code,
                    name: item.name
                });
            }
        }
    }

    // =========================================================================
    // PATH SUGGEST PROCESS - Shell command for directory autocomplete
    // =========================================================================
    // Runs 'ls -dp' with the current query + wildcard, filtering for
    // directories only (grep '/$'), showing first 5 results.
    // This provides real-time filesystem path suggestions.
    Process {
        id: pathSuggestProc
        property string query: ""  // Current path query
        command: ["bash", "-c",
            "eval ls -dp " + query + "* 2>/dev/null | grep '/$' | head -n 5 || true"]
        // eval: expands the query string (handles ~, $HOME, etc.)
        // ls -dp: list directories, append / to directory names
        // grep '/$': only show entries ending with / (directories)
        // head -n 5: limit to 5 results
        // || true: always return success exit code
        stdout: StdioCollector {
            onStreamFinished: {
                pathSuggestModel.clear();
                if (this.text) {
                    let lines = this.text.trim().split('\n');
                    for (let i = 0; i < lines.length; i++) {
                        let line = lines[i];
                        if (line.length > 0) {
                            // Remove trailing slash for display
                            if (line.endsWith('/')) {
                                line = line.slice(0, -1);
                            }
                            pathSuggestModel.append({ path: line });
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // ALL SETTINGS CARDS - Registry of all searchable settings
    // =========================================================================
    // Array of card descriptors used by the global search system.
    // Each card has:
    // - tab: Which tab it belongs to (0=General, 1=Weather, 2=Keybinds)
    // - boxIndex: The highlight box index within that tab
    // - label: Display name (searched)
    // - desc: Description text (searched)
    // - icon: Nerd Font icon
    // - color: Theme color name for the icon
    //
    // Note: boxIndex values may skip numbers (e.g., Weather has 1,2,3 but not 0)
    property var allSettingsCards: [
        { tab: 0, boxIndex: 0, label: "Guide on startup",
          desc: "Launch on login", icon: "󰑊", color: "peach" },
        { tab: 0, boxIndex: 1, label: "Help icon",
          desc: "Show button in topbar", icon: "󰋖", color: "blue" },
        { tab: 0, boxIndex: 2, label: "UI Scale",
          desc: "Base size scalar", icon: "󰁦", color: "sapphire" },
        { tab: 0, boxIndex: 3, label: "Keyboard layouts",
          desc: "Matches hyprland.conf", icon: "󰌌", color: "green" },
        { tab: 0, boxIndex: 4, label: "Layout shortcut",
          desc: "Toggle combination", icon: "󰯍", color: "teal" },
        { tab: 0, boxIndex: 5, label: "Wallpaper directory",
          desc: "Absolute source path", icon: "󰋩", color: "mauve" },
        { tab: 0, boxIndex: 6, label: "Workspaces",
          desc: "Static count in topbar", icon: "󰽿", color: "red" },
        { tab: 1, boxIndex: 1, label: "API Key",
          desc: "OpenWeather API key", icon: "󰌆", color: "blue" },
        { tab: 1, boxIndex: 2, label: "City ID",
          desc: "OpenWeather city ID", icon: "󰖐", color: "blue" },
        { tab: 1, boxIndex: 3, label: "Temperature Unit",
          desc: "Celsius / Fahrenheit / K", icon: "󰔄", color: "blue" }
    ]

    // =========================================================================
    // GET MATCHING KEYBIND INDICES - Search keybinds for a query
    // =========================================================================
    // Returns an array of indices into dynamicKeybindsModel that match
    // the search query. Tries regex first (for advanced users), falls back
    // to case-insensitive substring matching if the regex is invalid.
    function getMatchingKeybindIndices(query) {
        if (query.trim() === "") return [];  // Empty query = no results
        let results = [];
        try {
            // Try regex matching for power users
            let re = new RegExp(query, "i");  // "i" flag = case-insensitive
            for (let i = 0; i < dynamicKeybindsModel.count; i++) {
                let item = dynamicKeybindsModel.get(i);
                // Search in mods, key, dispatcher, command, and type fields
                if (re.test(item.mods) || re.test(item.key) ||
                    re.test(item.dispatcher) || re.test(item.command) ||
                    re.test(item.type)) {
                    results.push(i);
                }
            }
        } catch(e) {
            // Regex failed (invalid pattern): fall back to simple substring search
            let q = query.trim().toLowerCase();
            for (let i = 0; i < dynamicKeybindsModel.count; i++) {
                let item = dynamicKeybindsModel.get(i);
                if ((item.mods && item.mods.toLowerCase().includes(q)) ||
                    (item.key && item.key.toLowerCase().includes(q)) ||
                    (item.dispatcher &&
                     item.dispatcher.toLowerCase().includes(q)) ||
                    (item.command &&
                     item.command.toLowerCase().includes(q))) {
                    results.push(i);
                }
            }
        }
        return results;
    }

    // =========================================================================
    // MATCHING KEYBIND INDICES - Cached search results for keybinds
    // =========================================================================
    // Updated by onGlobalSearchQueryChanged, used by rebuildSearchResultItems
    property var matchingKeybindIndices: []

    // =========================================================================
    // GLOBAL SEARCH MATCHES - Check if a settings card matches a query
    // =========================================================================
    // Case-insensitive substring match on both label and description.
    // Empty query returns false (don't show all cards when search is empty).
    function globalSearchMatches(card, query) {
        if (query.trim() === "") return false;
        let q = query.trim().toLowerCase();
        return card.label.toLowerCase().includes(q) ||
            card.desc.toLowerCase().includes(q);
    }

    // =========================================================================
    // INTRO CONTENT ANIMATION - Fade-in/out for the settings panel
    // =========================================================================
    // Controls the opacity/scale of the main content for entrance/exit.
    // 0.0 = hidden, 1.0 = fully visible.
    property real introContent: 0.0

    // =========================================================================
    // COMPONENT INITIALIZATION - Startup actions
    // =========================================================================
    Component.onCompleted: { 
        root.tab0Loaded = true;     // Load the first tab immediately
        startupSequence.start();    // Start the fade-in animation
        
        // EDGE CASE: Config singleton may have loaded keybind data BEFORE
        // this settings window was created. If so, the Connections signal
        // already fired and was missed. Manually populate the model.
        if (Config.dataReady && dynamicKeybindsModel.count === 0) {
            dynamicKeybindsModel.append(Config.keybindsData);
        }
    }

    // =========================================================================
    // STARTUP SEQUENCE - Fade-in animation on panel open
    // =========================================================================
    // 50ms pause (allows layout to stabilize), then 600ms fade-in.
    // OutQuart easing: fast start, slow finish for a polished entrance.
    SequentialAnimation {
        id: startupSequence
        PauseAnimation { duration: 50 }  // Brief pause for layout stability
        NumberAnimation { 
            target: root
            property: "introContent"
            from: 0.0
            to: 1.0
            duration: 600
            easing.type: Easing.OutQuart
        } 
    }

    // =========================================================================
    // CLOSE SEQUENCE - Fade-out animation and cleanup on panel close
    // =========================================================================
    // 1. Fade out content over 200ms (InQuart: slow start, fast finish)
    // 2. Execute cleanup: reset Hyprland submap and close the window
    SequentialAnimation {
        id: closeSequence
        NumberAnimation { 
            target: root
            property: "introContent"
            to: 0.0
            duration: 200
            easing.type: Easing.InQuart
        }
        ScriptAction { 
            script: {
                // Reset Hyprland's keybind submap (exits the settings keybind mode)
                Quickshell.execDetached([
                    "hyprctl", "dispatch", "submap", "reset"
                ]);
                // Tell the Quickshell manager to close this window
                Quickshell.execDetached([
                    "bash",
                    Quickshell.env("HOME") +
                    "/.config/hypr/scripts/qs_manager.sh",
                    "close"
                ]);
            } 
        }    
    }

    // =========================================================================
    // GENERAL TAB COMPONENT - Content for the General settings tab
    // =========================================================================
    // This is a Component (template) that's instantiated by a Loader when
    // tab0Loaded becomes true. Using a Component + Loader enables lazy loading:
    // the content isn't created until the user actually visits the tab.
    Component {
        id: generalTabComponent
        Item {
            id: generalTabRoot

            // =================================================================
            // PUBLIC FUNCTIONS - Called by root to control this tab's content
            // =================================================================

            // Focus the keyboard layout language search input
            function focusLangInput() { langInput.forceActiveFocus(); }

            // Focus the wallpaper directory input
            function focusWpDirInput() { wpDirInput.forceActiveFocus(); }

            // Move layout dropdown selection down one item
            function layoutListIncrementIndex() {
                layoutListView.incrementCurrentIndex();
            }

            // Move layout dropdown selection up one item
            function layoutListDecrementIndex() {
                layoutListView.decrementCurrentIndex();
            }

            // Accept the currently selected layout option
            function acceptLayoutSelection() {
                if (layoutListView.currentIndex >= 0 &&
                    layoutListView.currentIndex < root.kbToggleModelArr.length) {
                    Config.kbOptions =
                        root.kbToggleModelArr[layoutListView.currentIndex].val;
                }
            }

            // Scroll to an absolute Y position (with bounds clamping)
            function scrollTo(y) {
                let maxY = Math.max(0,
                    generalFlickable.contentHeight - generalFlickable.height);
                generalFlickable.contentY = Math.max(0,
                    Math.min(y - root.s(40), maxY > 0 ? maxY : y));
            }

            // Scroll to make a specific box visible
            // approxItemY: the approximate Y position of the box
            function scrollToBox(approxItemY) {
                let viewH = generalFlickable.height;
                let itemTop = approxItemY;
                let itemBottom = approxItemY + root.s(80);  // Estimated box height
                let curY = generalFlickable.contentY;
                let maxY = Math.max(0,
                    generalFlickable.contentHeight - viewH);

                // Scroll up if the item is above the visible area
                if (itemTop < curY + root.s(10)) {
                    generalFlickable.contentY = Math.max(0,
                        itemTop - root.s(20));
                }
                // Scroll down if the item is below the visible area
                else if (itemBottom > curY + viewH - root.s(10)) {
                    generalFlickable.contentY = Math.min(maxY,
                        itemBottom - viewH + root.s(20));
                }
            }

            // =================================================================
            // FLICKABLE - Scrollable container for settings content
            // =================================================================
            Flickable {
                id: generalFlickable
                anchors.fill: parent
                contentWidth: width   // No horizontal scrolling
                // Content height: column height + 100px bottom padding
                contentHeight: settingsMainCol.implicitHeight + root.s(100)
                boundsBehavior: Flickable.StopAtBounds  // Don't overscroll
                clip: true  // Clip content to bounds

                // Transparent MouseArea behind all content:
                // Clicking on empty space clears the highlight
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.clearHighlight()
                    z: -1  // Behind all other content
                }

                // =============================================================
                // MAIN SETTINGS COLUMN - Vertical layout of all setting boxes
                // =============================================================
                ColumnLayout {
                    id: settingsMainCol
                    width: parent.width
                    spacing: root.s(10)  // Gap between boxes

                    // ─────────────────────────────────────────────────────────
                    // BOX 0: GUIDE ON STARTUP - Toggle switch
                    // ─────────────────────────────────────────────────────────
                    Rectangle {
                        id: box0
                        Layout.fillWidth: true
                        // Height: content height + 28px padding (14 top + 14 bottom)
                        Layout.preferredHeight: guideRow.implicitHeight +
                            root.s(28)
                        radius: root.s(12)  // Rounded corners

                        // Active state: when this box is highlighted (index 0)
                        property bool isActive: root.highlightedBox === 0

                        // Background: peach when active, surface0 when not
                        color: isActive ? root.peach : root.surface0
                        // Border: peach when active, surface1 when not
                        border.color: isActive ? root.peach : root.surface1
                        border.width: 1
                        // Smooth color transition for highlight feedback
                        Behavior on color {
                            ColorAnimation {
                                duration: 220
                                easing.type: Easing.OutExpo
                            }
                        }

                        // Click to highlight this box
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.highlightedBox = 0
                            z: -1  // Behind content so RowLayout receives clicks
                        }

                        // Content row: icon, label/description, toggle switch
                        RowLayout {
                            id: guideRow
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: root.s(16)  // 16px padding
                            spacing: root.s(14)           // Gap between elements

                            // ICON
                            Item {
                                Layout.preferredWidth: root.s(22)
                                Layout.alignment: Qt.AlignVCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰑊"  // Nerd Font guide/book icon
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: root.s(18)
                                    // Icon color: base (white) when active, peach when inactive
                                    color: box0.isActive ? root.base : root.peach
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 220
                                            easing.type: Easing.OutExpo
                                        }
                                    }
                                }
                            }

                            // LABEL + DESCRIPTION
                            ColumnLayout {
                                Layout.fillWidth: true  // Take remaining space
                                Layout.alignment: Qt.AlignVCenter
                                spacing: root.s(3)

                                // Title
                                Text {
                                    text: "Guide on startup"
                                    font.family: "Inter"
                                    font.weight: Font.Medium
                                    font.pixelSize: root.s(14)
                                    // Text color: base (white) when active, text when not
                                    color: box0.isActive ? root.base : root.text
                                    Layout.fillWidth: true
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 220
                                            easing.type: Easing.OutExpo
                                        }
                                    }
                                }

                                // Description
                                Text {
                                    text: "Launch on login"
                                    font.family: "Inter"
                                    font.pixelSize: root.s(11)
                                    // Description: 75% opacity when active, 70% when not
                                    // Qt.alpha(color, alpha) creates a color with alpha
                                    color: box0.isActive ?
                                        Qt.alpha(root.base, 0.75) :
                                        Qt.alpha(root.subtext0, 0.7)
                                    Layout.fillWidth: true
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 220
                                            easing.type: Easing.OutExpo
                                        }
                                    }
                                }
                            }

                            // TOGGLE SWITCH
                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                Layout.preferredWidth: root.s(40)   // Track width
                                Layout.preferredHeight: root.s(22)  // Track height
                                radius: root.s(11)  // Half height = pill shape

                                // Scale up slightly on hover for tactile feedback
                                scale: toggle1Ma.containsMouse ? 1.05 : 1.0
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutBack
                                    }
                                }

                                // Track color depends on state:
                                // ON + active: base (white)
                                // ON + inactive: peach
                                // OFF + active: 40% opacity surface2
                                // OFF + inactive: 100% opacity surface2
                                color: Config.openGuideAtStartup
                                    ? (box0.isActive ? root.base : root.peach)
                                    : Qt.alpha(root.surface2,
                                              box0.isActive ? 0.4 : 1.0)
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 220
                                        easing.type: Easing.OutExpo
                                    }
                                }

                                // The toggle knob
                                Rectangle {
                                    width: root.s(16)
                                    height: root.s(16)
                                    radius: root.s(8)  // Circle

                                    // Knob color:
                                    // ON + active: peach
                                    // ON + inactive: base (white)
                                    // OFF + active: peach
                                    // OFF + inactive: surface0
                                    color: Config.openGuideAtStartup
                                        ? (box0.isActive ? root.peach : root.base)
                                        : (box0.isActive ? root.peach : root.surface0)

                                    // Vertical center: (22 - 16) / 2 = 3px from top
                                    y: root.s(3)
                                    // Horizontal position: right when ON, left when OFF
                                    x: Config.openGuideAtStartup ?
                                        root.s(21) : root.s(3)
                                    // Animated slide
                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 250
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 220
                                            easing.type: Easing.OutExpo
                                        }
                                    }
                                }

                                // Click handler to toggle the setting
                                MouseArea {
                                    id: toggle1Ma
                                    anchors.fill: parent
                                    hoverEnabled: true  // Enable hover scale
                                    onClicked: Config.openGuideAtStartup =
                                        !Config.openGuideAtStartup
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }
                    // ── Box 1: Help icon ───────────────────────────────────── // Comment divider labeling this as the Help icon settings box
                    Rectangle {                                                    // Defines a rectangular UI element
                        id: box1                                                  // Unique identifier for this rectangle, used to reference it elsewhere
                        Layout.fillWidth: true                                    // Makes the rectangle expand to fill available horizontal space in its layout
                        Layout.preferredHeight: helpIconRow.implicitHeight + root.s(28) // Sets preferred height to content height plus scaled padding of 28
                        radius: root.s(12)                                        // Rounds the corners with a 12-unit radius scaled by UI scale factor

                        property bool isActive: root.highlightedBox === 1         // Boolean property: true when this box is the currently highlighted one (index 1)
                        color: isActive ? root.blue : root.surface0               // Background color: blue when active/highlighted, surface0 (dark) when inactive
                        border.color: isActive ? root.blue : root.surface1        // Border color: matches the active/inactive state with appropriate theme colors
                        border.width: 1                                           // Sets a 1-pixel wide border around the rectangle
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Animates color changes over 220ms with an exponential ease-out curve for smooth transitions

                        MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 1; z: -1 } // Clickable area covering the entire rectangle; sets highlighted box to 1 when clicked; z-index -1 places it behind other interactive elements

                        RowLayout {                                                // Arranges child items horizontally in a row
                            id: helpIconRow                                        // Unique identifier for this row layout
                            anchors.top: parent.top                                // Anchors the top of this row to the top of the parent rectangle
                            anchors.left: parent.left                              // Anchors the left side to the parent's left edge
                            anchors.right: parent.right                            // Anchors the right side to the parent's right edge, stretching to fill width
                            anchors.margins: root.s(16)                            // Applies 16-unit scaled margin on all sides from the parent edges
                            spacing: root.s(14)                                    // Sets 14-unit scaled spacing between child items in the row
                            Item {                                                // Empty container item used for layout spacing and positioning
                                Layout.preferredWidth: root.s(22)                  // Sets preferred width to 22 scaled units for this spacer
                                Layout.alignment: Qt.AlignVCenter                  // Vertically centers this item within the row layout
                                Text {                                            // Text element for displaying the Nerd Font icon
                                    anchors.centerIn: parent; text: "󰋖"          // Centers text in parent; displays the help icon character
                                    font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18) // Uses Iosevka Nerd Font at 18 scaled pixels for icon rendering
                                    color: box1.isActive ? root.base : root.blue   // Text color: base (light) when active, blue when inactive
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth 220ms color transition with exponential easing
                                }
                            }
                            ColumnLayout {                                        // Arranges child items vertically in a column
                                Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: root.s(3) // Fills available width, centers vertically in parent, 3-unit spacing between children
                                Text {                                            // Title text element
                                    text: "Help icon"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14) // Displays "Help icon" in Inter Medium font at 14 scaled pixels
                                    color: box1.isActive ? root.base : root.text; Layout.fillWidth: true // Color changes with active state; fills available width for proper text alignment
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Animated color transition over 220ms
                                }
                                Text {                                            // Description text element
                                    text: "Show button in topbar"; font.family: "Inter"; font.pixelSize: root.s(11) // Displays description in Inter font at 11 scaled pixels
                                    color: box1.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true // Semi-transparent base color when active, subtext color when inactive
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color animation
                                }
                            }
                            Rectangle {                                           // Toggle switch container rectangle
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight  // Vertically centers and right-aligns within the row
                                Layout.preferredWidth: root.s(40); Layout.preferredHeight: root.s(22); radius: root.s(11) // Toggle switch dimensions: 40x22 scaled units with rounded corners
                                scale: toggle2Ma.containsMouse ? 1.05 : 1.0       // Slightly enlarges (5%) when mouse hovers for visual feedback
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } } // Smooth scale animation with back easing for a bouncy effect
                                color: Config.topbarHelpIcon                       // Background color conditional on whether help icon is enabled in config
                                    ? (box1.isActive ? root.base : root.blue)      // If enabled: base color when box active, blue when inactive
                                    : Qt.alpha(root.surface2, box1.isActive ? 0.4 : 1.0) // If disabled: semi-transparent surface2 when active, full opacity when inactive
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color transition animation
                                Rectangle {                                       // Inner toggle circle/knob
                                    width: root.s(16); height: root.s(16); radius: root.s(8) // Circular knob: 16x16 with 8px radius for perfect circle
                                    color: Config.topbarHelpIcon                  // Knob color depends on toggle state
                                        ? (box1.isActive ? root.blue : root.base)  // When enabled: blue knob on active, base colored on inactive
                                        : (box1.isActive ? root.blue : root.surface0) // When disabled: blue when active, surface0 when inactive
                                    y: root.s(3); x: Config.topbarHelpIcon ? root.s(21) : root.s(3) // Vertical position: 3 units from top; horizontal: slides right when enabled, left when disabled
                                    Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack } } // Animated sliding with back easing for the toggle knob
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color transition
                                }
                                MouseArea { id: toggle2Ma; anchors.fill: parent; hoverEnabled: true; onClicked: Config.topbarHelpIcon = !Config.topbarHelpIcon; cursorShape: Qt.PointingHandCursor } // Clickable area for toggle; enables hover detection; toggles config value on click; shows hand cursor on hover
                            }
                        }
                    }
                    // ── Box 2: UI Scale ────────────────────────────────────── // Comment divider indicating this section configures the UI scaling factor
                    Rectangle {                                                    // Defines a rectangular container for the UI scale settings
                        id: box2                                                  // Unique identifier "box2" for referencing this rectangle throughout the file
                        Layout.fillWidth: true                                    // Makes the rectangle stretch to fill all available horizontal space in its parent layout
                        Layout.preferredHeight: col2.implicitHeight + root.s(32)  // Sets height to the natural content height plus 32 scaled units of padding
                        radius: root.s(12)                                        // Rounds all four corners with a radius of 12 scaled units for a modern card appearance

                        property bool isActive: root.highlightedBox === 2         // Custom boolean property: true when this specific box (index 2) is selected/highlighted
                        color: isActive ? root.sapphire : root.surface0           // Background color logic: sapphire blue when active, dark surface0 when not active
                        border.color: isActive ? root.sapphire : root.surface1    // Border color: matches background when active (sapphire), surface1 when inactive for subtle outline
                        border.width: 1                                           // Thin 1-pixel border width around the rectangle perimeter
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Animates background color changes over 220 milliseconds with exponential ease-out curve

                        MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 2; z: -1 } // Full-size clickable area; sets this box as highlighted when clicked; z-index -1 places it behind child elements so they remain interactive

                        ColumnLayout {                                            // Vertical layout container that stacks children from top to bottom
                            id: col2                                              // Unique identifier "col2" for referencing this column layout
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16) // Anchors to all sides of parent with 16-unit scaled margin inset
                            RowLayout {                                           // Horizontal layout container for arranging icon, labels, and controls side by side
                                Layout.fillWidth: true; spacing: root.s(14)       // Expands to fill full column width; 14 scaled units of space between child elements
                                Item {                                            // Container item serving as a fixed-width spacer for the icon
                                    Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter // Fixed 22-unit width; vertically centered within the row
                                    Text {                                        // Text element displaying the Nerd Font icon character
                                        anchors.centerIn: parent; text: "󰁦"      // Centers the icon text within its parent container; displays the scale icon glyph
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18) // Uses Iosevka Nerd Font family at 18 scaled pixels for crisp icon rendering
                                        color: box2.isActive ? root.base : root.sapphire // Icon color: light base when box is active, sapphire when inactive for visual state indication
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth 220ms color transition when active state changes
                                    }
                                }
                                ColumnLayout {                                    // Vertical layout for the title and description text labels
                                    Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: root.s(3) // Fills remaining width; vertically centered; 3-unit gap between texts
                                    Text {                                        // Title label text element
                                        text: "UI Scale"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14) // Displays "UI Scale" in Inter Medium weight at 14 scaled pixels
                                        color: box2.isActive ? root.base : root.text; Layout.fillWidth: true // White base when active, standard text color when inactive; fills available width
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Animated color transition on active state changes
                                    }
                                    Text {                                        // Description subtitle text element
                                        text: "Base size scalar"; font.family: "Inter"; font.pixelSize: root.s(11) // Shows "Base size scalar" description in Inter font at 11 scaled pixels
                                        color: box2.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true // 75% opacity base when active, 70% subtext when inactive
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color fading animation
                                    }
                                }
                                RowLayout {                                       // Horizontal layout for the minus button, value display, and plus button
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight; spacing: root.s(10) // Right-aligned and vertically centered; 10-unit spacing between controls
                                    Rectangle {                                   // Minus button background rectangle
                                        width: root.s(28); height: root.s(28); radius: root.s(6) // 28x28 square button with 6-unit rounded corners
                                        color: sMinusMa.pressed                    // Button color depends on interaction state
                                            ? Qt.alpha(root.base, 0.3)             // When pressed: 30% opacity base color for pressed feedback
                                            : (sMinusMa.containsMouse              // When not pressed, check hover state
                                                ? Qt.alpha(root.base, 0.2)         // When hovered: 20% opacity base color
                                                : Qt.alpha(root.base, 0.15))       // Default state: 15% opacity base color
                                        scale: sMinusMa.pressed ? 0.90 : (sMinusMa.containsMouse ? 1.08 : 1.0) // Shrinks to 90% when pressed, grows to 108% when hovered, normal at 100%
                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } } // Animated scale changes over 200ms with quartic ease-out
                                        Behavior on color { ColorAnimation { duration: 200 } } // 200ms color transition for button states
                                        Text {                                    // Minus symbol text inside button
                                            anchors.centerIn: parent; text: "-"   // Centers the minus character in the button; displays "-"
                                            font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: root.s(15) // Monospace font, medium weight, 15 scaled pixels
                                            color: box2.isActive ? root.base : root.sapphire // Symbol color: base when active, sapphire when inactive
                                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth symbol color transition
                                        }
                                        MouseArea { id: sMinusMa; anchors.fill: parent; hoverEnabled: true; onClicked: Config.uiScale = Math.max(0.5, (Config.uiScale - 0.1).toFixed(1)) } // Interactive area for minus button; on click decreases UI scale by 0.1, minimum 0.5, rounded to 1 decimal
                                    }
                                    Text {                                        // Current scale value display
                                        text: Config.uiScale.toFixed(1) + "x"     // Shows current UI scale value formatted to 1 decimal place with "x" suffix (e.g., "1.0x")
                                        font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(13) // Monospace bold font at 13 scaled pixels
                                        color: box2.isActive ? root.base : root.sapphire // Text color matches active/inactive state
                                        Layout.minimumWidth: root.s(36); horizontalAlignment: Text.AlignHCenter // Minimum 36-unit width; centered text alignment
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth text color animation
                                    }
                                    Rectangle {                                   // Plus button background rectangle
                                        width: root.s(28); height: root.s(28); radius: root.s(6) // 28x28 square button with 6-unit rounded corners
                                        color: sPlusMa.pressed                    // Button color depends on interaction state
                                            ? Qt.alpha(root.base, 0.3)             // When pressed: 30% opacity base color
                                            : (sPlusMa.containsMouse ? Qt.alpha(root.base, 0.2) : Qt.alpha(root.base, 0.15)) // 20% on hover, 15% default
                                        scale: sPlusMa.pressed ? 0.90 : (sPlusMa.containsMouse ? 1.08 : 1.0) // Interactive scale feedback: 90% pressed, 108% hovered, 100% default
                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } } // Animated scale changes
                                        Behavior on color { ColorAnimation { duration: 200 } } // Smooth color transitions
                                        Text {                                    // Plus symbol text inside button
                                            anchors.centerIn: parent; text: "+"   // Centers the plus character; displays "+"
                                            font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: root.s(15) // Monospace medium font at 15 pixels
                                            color: box2.isActive ? root.base : root.sapphire // Symbol color follows active state
                                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth symbol color transition
                                        }
                                        MouseArea { id: sPlusMa; anchors.fill: parent; hoverEnabled: true; onClicked: Config.uiScale = Math.min(2.0, (Config.uiScale + 0.1).toFixed(1)) } // Interactive area for plus button; on click increases scale by 0.1, maximum 2.0, rounded to 1 decimal
                                    }
                                }
                            }
                        }
                    }

                    // ── Box 3: Keyboard layouts ────────────────────────────── // Comment divider indicating keyboard layout configuration section
                    Rectangle {                                                    // Main container rectangle for keyboard layout settings
                        id: box3                                                  // Unique identifier "box3" for this rectangle element
                        Layout.fillWidth: true                                    // Expands horizontally to fill the entire available width in the parent layout
                        Layout.preferredHeight: col3lang.implicitHeight + root.s(32) // Dynamic height based on content natural height plus 32 units of scaled padding
                        radius: root.s(12)                                        // Corner rounding radius of 12 scaled units for card-style appearance

                        property bool isActive: root.highlightedBox === 3         // Boolean property tracking if this box (index 3) is currently highlighted/selected
                        color: isActive ? root.green : root.surface0              // Background: green when this box is active/highlighted, dark surface0 otherwise
                        border.color: isActive ? root.green : root.surface1       // Border: green to match when active, subtle surface1 when inactive
                        border.width: 1                                           // 1-pixel border thickness
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Animated background color changes with 220ms exponential ease-out

                        MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 3; z: -1 } // Full-area clickable region; sets highlight to box 3 on click; z-index -1 for behind children

                        ColumnLayout {                                            // Vertical stacking layout for organizing keyboard layout content
                            id: col3lang                                          // Identifier "col3lang" for referencing this column layout
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16) // Anchored to parent with 16-unit margin on all sides
                            spacing: root.s(16)                                   // 16 scaled units of vertical spacing between child elements in the column
                            RowLayout {                                           // Horizontal layout for icon and label section
                                Layout.fillWidth: true; spacing: root.s(14)       // Fills full width with 14-unit gap between items
                                Item {                                            // Spacer container for the keyboard icon
                                    Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignTop; Layout.topMargin: root.s(2) // Fixed 22-unit width; aligns to top with 2-unit top margin
                                    Text {                                        // Icon text element
                                        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter // Anchored to top and horizontally centered
                                        text: "󰌌"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18) // Keyboard icon glyph in Nerd Font at 18 scaled pixels
                                        color: box3.isActive ? root.base : root.green // Base color when active, green when inactive
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth icon color transitions
                                    }
                                }
                                ColumnLayout {                                    // Vertical layout for title and description
                                    Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: root.s(3) // Fills width; top-aligned; 3-unit gap between texts
                                    Text {                                        // Title text
                                        text: "Keyboard layouts"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14) // "Keyboard layouts" in Inter Medium at 14 pixels
                                        color: box3.isActive ? root.base : root.text; Layout.fillWidth: true // Active-dependent coloring; fills width
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Animated color
                                    }
                                    Text {                                        // Description/instruction text
                                        text: "Matches hyprland.conf. Click ✖ to remove."; font.family: "Inter"; font.pixelSize: root.s(11) // Instructions about matching config and removal
                                        color: box3.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true // Semi-transparent colors based on state
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color transition
                                    }
                                    Flow {                                        // Flow layout that wraps child items to next line when space runs out
                                        Layout.fillWidth: true; spacing: root.s(6); Layout.topMargin: root.s(8) // Full width; 6-unit spacing; 8-unit top margin
                                        Repeater {                                // Repeater creates items dynamically from a data model
                                            model: Config.language ? Config.language.split(",").filter(x => x.trim() !== "") : [] // Model: splits language string by commas, filters out empty strings, or empty array if null
                                            Rectangle {                           // Individual language chip/tag rectangle
                                                width: langChipLayout.implicitWidth + root.s(20); height: root.s(26); radius: root.s(13) // Dynamic width based on content plus padding; 26px height; pill-shaped with 13px radius
                                                color: box3.isActive ? Qt.alpha(root.base, 0.2) : root.surface1 // Semi-transparent base when active, surface1 when inactive
                                                border.color: chipMa.containsMouse ? root.red : (box3.isActive ? Qt.alpha(root.base, 0.4) : "transparent") // Red border on hover, semi-transparent base when active, transparent otherwise
                                                border.width: chipMa.containsMouse ? 1 : 0 // 1px border only visible on hover
                                                scale: chipMa.containsMouse ? 1.05 : 1.0 // Slight 5% enlargement on hover for visual feedback
                                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } } // Spring-like scale animation
                                                Behavior on border.color { ColorAnimation { duration: 150 } } // Smooth border color transition
                                                RowLayout {                       // Horizontal layout inside the chip
                                                    id: langChipLayout; anchors.centerIn: parent; spacing: root.s(6) // Centered in chip; 6-unit spacing
                                                    Text {                        // Language code text (e.g., "us", "de")
                                                        text: modelData; font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: root.s(11) // Displays language code from model data in monospace font
                                                        color: chipMa.containsMouse ? root.red : (box3.isActive ? root.base : root.text) // Red on hover, base when active, standard text otherwise
                                                        Behavior on color { ColorAnimation { duration: 150 } } // Quick color transition
                                                    }
                                                    Text {                        // Remove button (✖) text
                                                        text: "✖"; font.family: "JetBrains Mono"; font.pixelSize: root.s(11) // Multiplication sign as remove icon in monospace font
                                                        color: chipMa.containsMouse ? root.red : (box3.isActive ? Qt.alpha(root.base, 0.6) : root.subtext0) // Red on hover for danger indication, otherwise faded
                                                        Behavior on color { ColorAnimation { duration: 150 } } // Quick color animation
                                                    }
                                                }
                                                MouseArea {                     // Interactive area covering the entire chip
                                                    id: chipMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor // Full coverage; hover tracking enabled; hand cursor
                                                    onClicked: {                  // Click handler to remove this language from the list
                                                        let arr = Config.language.split(",").filter(x => x.trim() !== ""); // Split current language config into array, removing empty strings
                                                        arr.splice(index, 1);     // Remove this item from the array at the current repeater index
                                                        Config.language = arr.join(","); // Join remaining items back into comma-separated string and save to config
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            Rectangle {                                           // Text input field background rectangle
                                Layout.fillWidth: true; Layout.preferredHeight: root.s(34); Layout.topMargin: root.s(8) // Full width; 34-unit height; 8-unit top margin
                                radius: root.s(7)                                 // 7-unit corner radius
                                color: box3.isActive ? Qt.alpha(root.base, 0.15) : root.surface0 // Semi-transparent base when active, surface0 otherwise
                                border.color: langInput.activeFocus               // Border color depends on focus state
                                    ? (box3.isActive ? root.base : root.green)     // When focused: base color if active, green if inactive
                                    : (box3.isActive ? Qt.alpha(root.base, 0.3) : root.surface2) // When unfocused: semi-transparent base or surface2
                                border.width: 1                                   // 1-pixel border
                                Behavior on border.color { ColorAnimation { duration: 200 } } // Smooth border color changes
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth background color
                                TextInput {                                       // Text input field for searching/adding languages
                                    id: langInput                                 // Identifier "langInput" for this text input
                                    anchors.fill: parent; anchors.margins: root.s(9) // Fills parent with 9-unit margin padding inside
                                    verticalAlignment: TextInput.AlignVCenter     // Vertically centers the typed text
                                    font.family: "JetBrains Mono"; font.pixelSize: root.s(11) // Monospace font at 11 scaled pixels
                                    color: box3.isActive ? root.base : root.text; clip: true; selectByMouse: true // Text color based on active state; clips overflow; allows mouse text selection
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Animated text color
                                    Keys.onPressed: (event) => {                   // Keyboard press handler for navigation
                                        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down) { // When Tab or Down arrow pressed
                                            if (langSearchModel.count > 0) { langListView.incrementCurrentIndex(); event.accepted = true; } // Move selection down in suggestions list if items exist
                                        } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up) { // When Shift+Tab or Up arrow pressed
                                            if (langSearchModel.count > 0) { langListView.decrementCurrentIndex(); event.accepted = true; } // Move selection up in suggestions list
                                        }
                                    }
                                    Keys.onReturnPressed: (event) => langInputAccept(event) // Enter key calls accept function
                                    Keys.onEnterPressed: (event) => langInputAccept(event) // Numpad Enter also calls accept function
                                    function langInputAccept(event) {               // Function to accept the currently highlighted suggestion
                                        if (langSearchModel.count > 0 && langListView.currentIndex >= 0) { // If suggestions exist and an item is selected
                                            let item = langSearchModel.get(langListView.currentIndex); // Get the selected item from the model
                                            let arr = Config.language ? Config.language.split(",").filter(x => x.trim() !== "") : []; // Parse current language list
                                            if (!arr.includes(item.code)) { arr.push(item.code); Config.language = arr.join(","); } // Add language code if not already present
                                        }
                                        text = ""; focus = false; event.accepted = true; // Clear input, remove focus, mark event as handled
                                    }
                                    onActiveFocusChanged: { if (activeFocus) root.updateLangSearch(text); } // When focus gained, trigger search update
                                    onTextChanged: { root.updateLangSearch(text); } // When text changes, update search results in real-time
                                    Text {                                        // Placeholder text when input is empty
                                        text: "Search to add..."                  // Placeholder prompt text
                                        color: box3.isActive ? Qt.alpha(root.base, 0.5) : Qt.alpha(root.subtext0, 0.7) // Faded color appropriate for placeholder
                                        visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter // Only visible when empty and unfocused; uses same font; vertically centered
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth placeholder color transition
                                    }
                                }
                            }
                            Rectangle {                                           // Dropdown suggestion list container
                                Layout.fillWidth: true                            // Full width of parent
                                Layout.preferredHeight: langInput.activeFocus && langSearchModel.count > 0 ? Math.min(root.s(160), langSearchModel.count * root.s(30) + root.s(8)) : 0 // Height: 0 when no focus/items, otherwise calculated based on item count, max 160 units
                                radius: root.s(7)                                 // 7-unit corner radius
                                color: box3.isActive ? Qt.alpha(root.base, 0.15) : root.surface0 // Background based on active state
                                border.color: box3.isActive ? Qt.alpha(root.base, 0.3) : root.surface1 // Subtle border
                                border.width: 1                                   // 1-pixel border
                                clip: true                                        // Clips child content to this rectangle's bounds (hides overflow)
                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } } // Animated height expansion/collapse
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth background color
                                ListView {                                        // Scrollable list view for language suggestions
                                    id: langListView                             // Identifier "langListView"
                                    anchors.fill: parent; anchors.topMargin: root.s(4); anchors.bottomMargin: root.s(4) // Fills parent with 4-unit vertical margins
                                    model: langSearchModel; interactive: true     // Data source is langSearchModel; scrolling enabled
                                    opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0 // Fully opaque when tall enough, invisible when collapsed
                                    Behavior on opacity { NumberAnimation { duration: 200 } } // Smooth fade in/out
                                    ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded } // Vertical scrollbar shown only when needed
                                    delegate: Rectangle {                         // Template for each suggestion item
                                        width: parent.width - root.s(8); height: root.s(30) // Slightly narrower than parent; 30-unit height
                                        anchors.horizontalCenter: parent.horizontalCenter; radius: root.s(4) // Horizontally centered; 4-unit rounded corners
                                        property bool isHovered: sMa.containsMouse // Boolean tracking hover state
                                        color: isHovered                          // Background color based on interaction
                                            ? Qt.alpha(box3.isActive ? root.base : root.green, 0.2) // 20% opacity accent when hovered
                                            : (ListView.isCurrentItem ? Qt.alpha(box3.isActive ? root.base : root.green, 0.1) : "transparent") // 10% opacity when selected/current, transparent otherwise
                                        Behavior on color { ColorAnimation { duration: 150 } } // Quick background color transition
                                        RowLayout {                               // Horizontal layout for suggestion content
                                            anchors.fill: parent; anchors.leftMargin: root.s(8); anchors.rightMargin: root.s(8); spacing: root.s(8) // Fills with 8-unit horizontal margins; 8-unit spacing
                                            Text { text: model.code; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(11); color: box3.isActive ? root.base : root.text; Behavior on color { ColorAnimation { duration: 150 } } } // Language code in bold monospace
                                            Text { text: model.name; font.family: "Inter"; font.pixelSize: root.s(11); color: box3.isActive ? Qt.alpha(root.base, 0.7) : Qt.alpha(root.subtext0, 0.7); elide: Text.ElideRight; Layout.fillWidth: true; Behavior on color { ColorAnimation { duration: 150 } } } // Full language name, elided if too long
                                        }
                                        MouseArea {                             // Interactive area for each suggestion
                                            id: sMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor // Full coverage; hover enabled; hand cursor
                                            onClicked: {                          // Click handler to add this language
                                                let arr = Config.language ? Config.language.split(",").filter(x => x.trim() !== "") : []; // Parse current languages
                                                if (!arr.includes(model.code)) { arr.push(model.code); Config.language = arr.join(","); } // Add if not duplicate
                                                langInput.text = ""; langInput.focus = false; // Clear input and remove focus
                                            }
                                        }
                                    }
                                }
                            }
                        }                       
                    }

                    // ── Box 4: Layout shortcut ─────────────────────────────── // Comment divider for keyboard layout toggle shortcut settings
                    Rectangle {                                                    // Container rectangle for layout shortcut configuration
                        id: box4                                                  // Unique identifier "box4"
                        Layout.fillWidth: true                                    // Expands to fill full available width
                        Layout.preferredHeight: col4layout.implicitHeight + root.s(32) // Height based on content plus 32-unit padding
                        radius: root.s(12)                                        // 12-unit rounded corners

                        property bool isActive: root.highlightedBox === 4         // True when this box (index 4) is highlighted/selected
                        color: isActive ? root.teal : root.surface0               // Teal background when active, dark surface0 otherwise
                        border.color: isActive ? root.teal : root.surface1        // Border color matches background when active
                        border.width: 1                                           // 1-pixel border
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth background color animation

                        MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 4; z: -1 } // Click to highlight this box

                        ColumnLayout {                                            // Vertical layout for content
                            id: col4layout                                        // Identifier "col4layout"
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16) // Anchored with 16-unit margins
                            spacing: root.s(16)                                   // 16-unit vertical spacing between children
                            RowLayout {                                           // Horizontal layout for icon and labels
                                Layout.fillWidth: true; spacing: root.s(14)       // Full width; 14-unit horizontal gap
                                Item {                                            // Icon container
                                    Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignTop; Layout.topMargin: root.s(2) // Fixed width; top-aligned
                                    Text {                                        // Icon glyph
                                        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter // Top-anchored, horizontally centered
                                        text: "󰯍"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18) // Layout/toggle icon in Nerd Font
                                        color: box4.isActive ? root.base : root.teal // Color based on active state
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth icon color
                                    }
                                }
                                ColumnLayout {                                    // Vertical layout for text content
                                    Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: root.s(3) // Full width; top-aligned; 3-unit gap
                                    Text {                                        // Title label
                                        text: "Layout shortcut"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14) // "Layout shortcut" title
                                        color: box4.isActive ? root.base : root.text; Layout.fillWidth: true // Active-dependent color
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Animated color
                                    }
                                    Text {                                        // Description label
                                        text: "Toggle combination"; font.family: "Inter"; font.pixelSize: root.s(11) // "Toggle combination" description
                                        color: box4.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true // Semi-transparent colors
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                    }
                                    Rectangle {                                   // Dropdown trigger button background
                                        Layout.fillWidth: true; Layout.preferredHeight: root.s(34); Layout.topMargin: root.s(8) // Full width; 34-unit height; 8-unit top margin
                                        radius: root.s(7)                         // 7-unit corner radius
                                        color: box4.isActive ? Qt.alpha(root.base, 0.15) : root.surface0 // Semi-transparent or surface color
                                        border.color: root.isLayoutDropdownOpen    // Border color depends on dropdown state
                                            ? (box4.isActive ? root.base : root.teal) // When open: base or teal
                                            : (box4.isActive ? Qt.alpha(root.base, 0.3) : root.surface2) // When closed: faded base or surface2
                                        border.width: 1                           // 1-pixel border
                                        Behavior on border.color { ColorAnimation { duration: 200 } } // Smooth border color
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth background color
                                        RowLayout {                               // Horizontal layout inside dropdown trigger
                                            anchors.fill: parent; anchors.margins: root.s(9) // Fills with 9-unit margin
                                            Text {                                // Currently selected option text
                                                text: root.getKbToggleLabel(Config.kbOptions) // Gets display label for current keyboard toggle option
                                                font.family: "JetBrains Mono"; font.pixelSize: root.s(11) // Monospace font at 11 pixels
                                                color: box4.isActive ? root.base : root.text; Layout.fillWidth: true // Active-dependent color; fills available space
                                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                            }
                                            Text {                                // Dropdown arrow indicator
                                                text: root.isLayoutDropdownOpen ? "▴" : "▾"; font.pixelSize: root.s(12) // Up arrow when open, down arrow when closed
                                                color: box4.isActive ? Qt.alpha(root.base, 0.7) : root.subtext0 // Faded color for arrow
                                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth arrow color
                                            }
                                        }
                                        MouseArea {                             // Clickable area to toggle dropdown
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor // Full coverage; hand cursor
                                            onClicked: {                          // Click handler
                                                root.isLayoutDropdownOpen = !root.isLayoutDropdownOpen; // Toggle dropdown visibility
                                                if (root.isLayoutDropdownOpen) {   // If opening the dropdown
                                                    let idx = root.kbToggleModelArr.findIndex(x => x.val === Config.kbOptions); // Find current value index in options array
                                                    layoutListView.currentIndex = Math.max(0, idx); // Set list view to that index (minimum 0)
                                                }
                                                root.forceActiveFocus();          // Force focus on root to handle keyboard events
                                            }
                                        }
                                    }
                                    Rectangle {                                   // Dropdown list container
                                        Layout.fillWidth: true                    // Full width
                                        Layout.preferredHeight: root.isLayoutDropdownOpen ? root.kbToggleModelArr.length * root.s(30) + root.s(8) : 0 // Height based on option count when open, 0 when closed
                                        radius: root.s(7)                         // 7-unit corner radius
                                        color: box4.isActive ? Qt.alpha(root.base, 0.15) : root.surface0 // Background based on active state
                                        border.color: box4.isActive ? Qt.alpha(root.base, 0.3) : root.surface1 // Subtle border
                                        border.width: 1                           // 1-pixel border
                                        clip: true                                // Clips content to bounds
                                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } } // Animated height
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth background
                                        ListView {                                // List view for dropdown options
                                            id: layoutListView                   // Identifier "layoutListView"
                                            anchors.fill: parent; anchors.topMargin: root.s(4); anchors.bottomMargin: root.s(4) // Fills parent with 4-unit vertical margins
                                            model: root.kbToggleModelArr; interactive: false // Data model from root; scrolling disabled (static list)
                                            opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0 // Visible only when dropdown is open
                                            Behavior on opacity { NumberAnimation { duration: 200 } } // Smooth fade
                                            delegate: Rectangle {                 // Template for each dropdown option
                                                width: parent.width - root.s(8); height: root.s(30) // Slightly narrower; 30-unit height
                                                anchors.horizontalCenter: parent.horizontalCenter; radius: root.s(4) // Centered horizontally; 4-unit radius
                                                property bool isHovered: toggleMa.containsMouse // Hover state tracking
                                                color: isHovered                  // Background color
                                                    ? Qt.alpha(box4.isActive ? root.base : root.teal, 0.2) // 20% accent on hover
                                                    : (ListView.isCurrentItem ? Qt.alpha(box4.isActive ? root.base : root.teal, 0.1) : "transparent") // 10% when selected, transparent otherwise
                                                Behavior on color { ColorAnimation { duration: 150 } } // Quick background animation
                                                RowLayout {                       // Horizontal layout for option content
                                                    anchors.fill: parent; anchors.leftMargin: root.s(8); anchors.rightMargin: root.s(8) // Fills with horizontal margins
                                                    Text {                        // Option label text
                                                        text: modelData.label; font.family: "JetBrains Mono"; font.pixelSize: root.s(11) // Displays option label in monospace
                                                        color: Config.kbOptions === modelData.val // Color logic
                                                            ? (box4.isActive ? root.base : root.teal) // Accent color when this is current value
                                                            : (box4.isActive ? Qt.alpha(root.base, 0.8) : root.text) // Faded base or normal text when not selected
                                                        Layout.fillWidth: true    // Fills available width
                                                        Behavior on color { ColorAnimation { duration: 150 } } // Quick color transition
                                                    }
                                                }
                                                MouseArea { id: toggleMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Config.kbOptions = modelData.val; root.isLayoutDropdownOpen = false; } } // Click to select this option and close dropdown
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Box 5: Wallpaper directory ─────────────────────────── // Comment divider for wallpaper directory path configuration
                    Rectangle {                                                    // Main container for wallpaper directory settings
                        id: box5                                                  // Unique identifier "box5"
                        Layout.fillWidth: true                                    // Expands to fill full available width
                        Layout.preferredHeight: col5wp.implicitHeight + root.s(32) // Dynamic height from content plus padding
                        radius: root.s(12)                                        // 12-unit corner rounding

                        property bool isActive: root.highlightedBox === 5         // True when this box (index 5) is highlighted
                        color: isActive ? root.mauve : root.surface0              // Mauve background when active, surface0 otherwise
                        border.color: isActive ? root.mauve : root.surface1       // Border color matches when active
                        border.width: 1                                           // 1-pixel border
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth background color transition

                        MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 5; z: -1 } // Click area to highlight this box

                        ColumnLayout {                                            // Vertical layout container
                            id: col5wp                                             // Identifier "col5wp"
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16) // Anchored with 16-unit margins
                            RowLayout {                                           // Horizontal layout for icon and text
                                Layout.fillWidth: true; spacing: root.s(14)       // Full width; 14-unit gap
                                Item {                                            // Icon container spacer
                                    Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignTop; Layout.topMargin: root.s(2) // Fixed width; top-aligned
                                    Text {                                        // Wallpaper icon
                                        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter // Top-anchored, centered horizontally
                                        text: "󰋩"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18) // Wallpaper/image icon in Nerd Font
                                        color: box5.isActive ? root.base : root.mauve // Active-dependent color
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth icon color
                                    }
                                }
                                ColumnLayout {                                    // Vertical text layout
                                    Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: root.s(3) // Full width; top-aligned; 3-unit gap
                                    Text {                                        // Title text
                                        text: "Wallpaper directory"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14) // "Wallpaper directory" title
                                        color: box5.isActive ? root.base : root.text; Layout.fillWidth: true // Active-dependent color
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Animated color
                                    }
                                    Text {                                        // Description text
                                        text: "Absolute source path"; font.family: "Inter"; font.pixelSize: root.s(11) // "Absolute source path" description
                                        color: box5.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true // Semi-transparent colors
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                    }
                                    Rectangle {                                   // Path input field background
                                        Layout.fillWidth: true; Layout.preferredHeight: root.s(34); Layout.topMargin: root.s(8) // Full width; 34-unit height; 8-unit top margin
                                        radius: root.s(7)                         // 7-unit corner radius
                                        color: box5.isActive ? Qt.alpha(root.base, 0.15) : root.surface0 // Background based on state
                                        border.color: wpDirInput.activeFocus       // Border color depends on focus
                                            ? (box5.isActive ? root.base : root.mauve) // Focused: base or mauve
                                            : (box5.isActive ? Qt.alpha(root.base, 0.3) : root.surface2) // Unfocused: faded
                                        border.width: 1                           // 1-pixel border
                                        Behavior on border.color { ColorAnimation { duration: 200 } } // Smooth border
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth background
                                        TextInput {                               // Text input for directory path
                                            id: wpDirInput                        // Identifier "wpDirInput"
                                            anchors.fill: parent; anchors.margins: root.s(9) // Fills parent with 9-unit padding
                                            verticalAlignment: TextInput.AlignVCenter // Vertically centered text
                                            text: Config.wallpaperDir             // Bound to wallpaper directory config value
                                            font.family: "JetBrains Mono"; font.pixelSize: root.s(11) // Monospace font at 11 pixels
                                            color: box5.isActive ? root.base : root.text; clip: true; selectByMouse: true // Text color; clips overflow; mouse selection enabled
                                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth text color
                                            Keys.onPressed: (event) => {           // Keyboard navigation handler
                                                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down) { // Tab or Down key
                                                    if (pathSuggestModel.count > 0) { wpSuggestListView.incrementCurrentIndex(); event.accepted = true; } // Move selection down
                                                } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up) { // Shift+Tab or Up key
                                                    if (pathSuggestModel.count > 0) { wpSuggestListView.decrementCurrentIndex(); event.accepted = true; } // Move selection up
                                                }
                                            }
                                            Keys.onReturnPressed: (event) => wpDirInputAccept(event) // Enter key calls accept function
                                            Keys.onEnterPressed: (event) => wpDirInputAccept(event) // Numpad Enter calls accept
                                            function wpDirInputAccept(event) {      // Function to accept path suggestion
                                                if (pathSuggestModel.count > 0 && wpSuggestListView.currentIndex >= 0) { // If suggestions exist and an item is selected
                                                    let item = pathSuggestModel.get(wpSuggestListView.currentIndex); // Get selected suggestion
                                                    if (item) { text = item.path; Config.wallpaperDir = text; } // Set text and config if item exists
                                                }
                                                pathSuggestModel.clear(); focus = false; event.accepted = true; // Clear suggestions, remove focus, mark handled
                                            }
                                            onActiveFocusChanged: {               // When focus changes
                                                if (activeFocus) { pathSuggestProc.query = text; pathSuggestProc.running = false; pathSuggestProc.running = true; } // Trigger path suggestion process when focused
                                            }
                                            onTextChanged: {                      // When text content changes
                                                Config.wallpaperDir = text;       // Update config in real-time
                                                if (activeFocus) { pathSuggestProc.query = text; pathSuggestProc.running = false; pathSuggestProc.running = true; } // Update suggestions if focused
                                            }
                                            Text {                                // Placeholder text
                                                text: "Enter directory..."; color: box5.isActive ? Qt.alpha(root.base, 0.5) : root.subtext0 // Placeholder prompt with faded color
                                                visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter // Visible when empty and unfocused
                                            }
                                        }
                                    }
                                    Rectangle {                                   // Path suggestion dropdown container
                                        Layout.fillWidth: true                    // Full width
                                        Layout.preferredHeight: wpDirInput.activeFocus && pathSuggestModel.count > 0 ? pathSuggestModel.count * root.s(28) + root.s(8) : 0 // Height based on suggestion count when focused
                                        radius: root.s(7)                         // 7-unit corner radius
                                        color: box5.isActive ? Qt.alpha(root.base, 0.15) : root.surface0 // Background based on state
                                        border.color: box5.isActive ? Qt.alpha(root.base, 0.3) : root.surface1 // Subtle border
                                        border.width: 1                           // 1-pixel border
                                        clip: true                                // Clips content
                                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } } // Animated height
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth background
                                        ListView {                                // List view for path suggestions
                                            id: wpSuggestListView                 // Identifier "wpSuggestListView"
                                            anchors.fill: parent; anchors.topMargin: root.s(4); anchors.bottomMargin: root.s(4) // Fills parent with vertical margins
                                            model: pathSuggestModel; interactive: false // Data model; scrolling disabled
                                            opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0 // Visible when open
                                            Behavior on opacity { NumberAnimation { duration: 200 } } // Smooth fade
                                            delegate: Rectangle {                 // Template for each suggestion item
                                                width: parent.width - root.s(8); height: root.s(28) // Slightly narrower; 28-unit height
                                                anchors.horizontalCenter: parent.horizontalCenter; radius: root.s(4) // Centered; 4-unit radius
                                                property bool isHovered: suggestMa.containsMouse // Hover tracking
                                                color: isHovered                  // Background color
                                                    ? Qt.alpha(box5.isActive ? root.base : root.mauve, 0.2) // 20% accent on hover
                                                    : (ListView.isCurrentItem ? Qt.alpha(box5.isActive ? root.base : root.mauve, 0.1) : "transparent") // 10% when selected
                                                Behavior on color { ColorAnimation { duration: 150 } } // Quick background transition
                                                Text {                            // Path display text
                                                    anchors.verticalCenter: parent.verticalCenter; x: root.s(8) // Vertically centered; 8-unit left padding
                                                    text: model.path; font.family: "JetBrains Mono"; font.pixelSize: root.s(10) // Shows full path in monospace
                                                    color: box5.isActive ? root.base : root.text // Active-dependent color
                                                    elide: Text.ElideMiddle; width: parent.width - root.s(16) // Elides middle of long paths; width accounts for padding
                                                    Behavior on color { ColorAnimation { duration: 150 } } // Quick color transition
                                                }
                                                MouseArea { id: suggestMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { wpDirInput.text = model.path; pathSuggestModel.clear(); wpDirInput.focus = false; } } // Click to select path, clear suggestions, remove focus
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Box 6: Workspaces ──────────────────────────────────── // Comment divider for workspace count configuration
                    Rectangle {                                                    // Container rectangle for workspace settings
                        id: box6                                                  // Unique identifier "box6"
                        Layout.fillWidth: true                                    // Expands to fill full available width
                        Layout.preferredHeight: col6ws.implicitHeight + root.s(32) // Dynamic height from content plus padding
                        radius: root.s(12)                                        // 12-unit corner rounding

                        property bool isActive: root.highlightedBox === 6         // True when this box (index 6) is highlighted
                        color: isActive ? root.red : root.surface0                // Red background when active, surface0 otherwise
                        border.color: isActive ? root.red : root.surface1         // Border matches when active
                        border.width: 1                                           // 1-pixel border
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth background animation

                        MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 6; z: -1 } // Click to highlight this box

                        ColumnLayout {                                            // Vertical layout container
                            id: col6ws                                              // Identifier "col6ws"
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16) // Anchored with 16-unit margins
                            RowLayout {                                           // Horizontal layout for icon, labels, and controls
                                Layout.fillWidth: true; spacing: root.s(14)       // Full width; 14-unit gap
                                Item {                                            // Icon container spacer
                                    Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter // Fixed width; vertically centered
                                    Text {                                        // Workspace icon
                                        anchors.centerIn: parent; text: "󰽿"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18) // Workspace/grid icon in Nerd Font
                                        color: box6.isActive ? root.base : root.red // Active-dependent color
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth icon color
                                    }
                                }
                                ColumnLayout {                                    // Vertical text layout
                                    Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: root.s(3) // Full width; vertically centered; 3-unit gap
                                    Text {                                        // Title text
                                        text: "Workspaces"; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: root.s(14) // "Workspaces" title in bold
                                        color: box6.isActive ? root.base : root.text; Layout.fillWidth: true // Active-dependent color
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Animated color
                                    }
                                    Text {                                        // Description text
                                        text: "Static count in topbar"; font.family: "Inter"; font.pixelSize: root.s(11) // "Static count in topbar" description
                                        color: box6.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true // Semi-transparent colors
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                    }
                                }
                                RowLayout {                                       // Horizontal layout for minus, count, plus controls
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight; spacing: root.s(10) // Right-aligned, vertically centered; 10-unit spacing
                                    Rectangle {                                   // Minus button background
                                        width: root.s(28); height: root.s(28); radius: root.s(6) // 28x28 square; 6-unit radius
                                        color: wsMinusMa.pressed ? Qt.alpha(root.base, 0.3) : (wsMinusMa.containsMouse ? Qt.alpha(root.base, 0.2) : Qt.alpha(root.base, 0.15)) // Interactive color states
                                        scale: wsMinusMa.pressed ? 0.90 : (wsMinusMa.containsMouse ? 1.08 : 1.0) // Interactive scale feedback
                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } } // Animated scale
                                        Behavior on color { ColorAnimation { duration: 200 } } // Smooth color
                                        Text {                                    // Minus symbol
                                            anchors.centerIn: parent; text: "-"   // Centered minus sign
                                            font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(15) // Monospace bold at 15 pixels
                                            color: box6.isActive ? root.base : root.red // Active-dependent color
                                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                        }
                                        MouseArea { id: wsMinusMa; anchors.fill: parent; hoverEnabled: true; onClicked: Config.workspaceCount = Math.max(2, Config.workspaceCount - 1) } // Click to decrease workspace count, minimum 2
                                    }
                                    Text {                                        // Current workspace count display
                                        text: Config.workspaceCount.toString()    // Shows current count as string
                                        font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: root.s(14) // Monospace black (heaviest) weight at 14 pixels
                                        color: box6.isActive ? root.base : root.red // Active-dependent color
                                        Layout.minimumWidth: root.s(36); horizontalAlignment: Text.AlignHCenter // Minimum 36-unit width; centered
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                    }
                                    Rectangle {                                   // Plus button background
                                        width: root.s(28); height: root.s(28); radius: root.s(6) // 28x28 square; 6-unit radius
                                        color: wsPlusMa.pressed ? Qt.alpha(root.base, 0.3) : (wsPlusMa.containsMouse ? Qt.alpha(root.base, 0.2) : Qt.alpha(root.base, 0.15)) // Interactive color states
                                        scale: wsPlusMa.pressed ? 0.90 : (wsPlusMa.containsMouse ? 1.08 : 1.0) // Interactive scale feedback
                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } } // Animated scale
                                        Behavior on color { ColorAnimation { duration: 200 } } // Smooth color
                                        Text {                                    // Plus symbol
                                            anchors.centerIn: parent; text: "+"   // Centered plus sign
                                            font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(15) // Monospace bold at 15 pixels
                                            color: box6.isActive ? root.base : root.red // Active-dependent color
                                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                        }
                                        MouseArea { id: wsPlusMa; anchors.fill: parent; hoverEnabled: true; onClicked: Config.workspaceCount = Math.min(10, Config.workspaceCount + 1) } // Click to increase workspace count, maximum 10
                                    }
                                }
                            }
                        }
                    }
                }
            }        
        }
    }

    Component {                                                                   // Defines a reusable component for the weather settings tab
        id: weatherTabComponent                                                   // Component identifier "weatherTabComponent" for instantiating weather tab
        Item {                                                                    // Base item container for the weather tab content
            id: weatherTabRoot                                                    // Root identifier for this weather tab instance

            function focusApiKey() { apiKeyInput.forceActiveFocus(); }             // Helper function to programmatically focus the API key input field
            function focusCityId() { cityIdInput.forceActiveFocus(); }            // Helper function to focus the City ID input field
            function scrollTo(y) {                                                // Function to scroll the flickable to a specific Y position
                let maxY = Math.max(0, weatherFlickable.contentHeight - weatherFlickable.height); // Calculate maximum scrollable Y (content height minus view height, minimum 0)
                weatherFlickable.contentY = Math.max(0, Math.min(y - root.s(40), maxY > 0 ? maxY : y)); // Set scroll position, offset by 40 units, clamped between 0 and maxY
            }
            function scrollToBox(approxItemY) {                                   // Function to scroll to make a specific box visible
                let viewH = weatherFlickable.height;                              // Get the visible height of the flickable viewport
                let itemTop = approxItemY;                                        // Top position of the item to scroll to
                let itemBottom = approxItemY + root.s(80);                        // Estimated bottom position (item top + 80 units estimated height)
                let curY = weatherFlickable.contentY;                             // Current scroll position
                let maxY = Math.max(0, weatherFlickable.contentHeight - viewH);   // Maximum possible scroll position
                if (itemTop < curY + root.s(10)) {                                // If item is above the current viewport (with 10-unit buffer)
                    weatherFlickable.contentY = Math.max(0, itemTop - root.s(20)); // Scroll up so item is 20 units from top
                } else if (itemBottom > curY + viewH - root.s(10)) {              // If item is below the current viewport (with 10-unit buffer)
                    weatherFlickable.contentY = Math.min(maxY, itemBottom - viewH + root.s(20)); // Scroll down so item bottom is 20 units from bottom
                }
            }

            Component.onCompleted: {                                              // Code that runs when this component finishes loading
                apiKeyInput.text = Config.weatherApiKey;                          // Initialize API key input with current config value
                cityIdInput.text = Config.weatherCityId;                          // Initialize City ID input with current config value
            }

            Connections {                                                         // Establishes signal connections to external Config object
                target: Config                                                    // Connect to the Config singleton/object
                function onWeatherApiKeyChanged() { if (apiKeyInput.text !== Config.weatherApiKey) apiKeyInput.text = Config.weatherApiKey; } // When API key changes externally, update input if different
                function onWeatherCityIdChanged() { if (cityIdInput.text !== Config.weatherCityId) cityIdInput.text = Config.weatherCityId; } // When City ID changes externally, update input if different
            }

            property bool apiKeyVisible: false                                    // Boolean property controlling API key visibility (show/hide password)

            Flickable {                                                           // Scrollable container for the weather tab content
                id: weatherFlickable                                              // Identifier "weatherFlickable"
                anchors.fill: parent                                              // Fills the entire parent area
                contentWidth: width                                                // Content width matches flickable width (no horizontal scrolling)
                contentHeight: wCol.implicitHeight + root.s(100)                  // Content height based on column content plus 100-unit padding
                boundsBehavior: Flickable.StopAtBounds                            // Stops scrolling at content boundaries (no overshoot/bounce)
                clip: true                                                        // Clips content to flickable bounds

                MouseArea { anchors.fill: parent; onClicked: root.clearHighlight(); z: -1 } // Click on background to clear any highlighted box

                ColumnLayout {                                                    // Main vertical layout for weather tab content
                    id: wCol                                                       // Identifier "wCol"
                    width: parent.width                                            // Width matches parent
                    spacing: root.s(10)                                            // 10-unit vertical spacing between children

                    // ── Box 0: Instructions ────────────────────────────────── // Comment divider for weather setup instructions box
                    Rectangle {                                                    // Instruction box container
                        id: wBox0                                                  // Identifier "wBox0"
                        Layout.fillWidth: true                                    // Fills full width
                        Layout.preferredHeight: instructionLayout.implicitHeight + root.s(28) // Dynamic height based on content plus 28-unit padding
                        radius: root.s(12)                                        // 12-unit corner radius

                        property bool isActive: root.highlightedBox === 0         // True when this instruction box (index 0) is highlighted
                        color: isActive ? root.blue : root.surface0               // Blue when active, surface0 otherwise
                        border.color: isActive ? root.blue : root.surface1        // Border matches active state
                        border.width: 1                                           // 1-pixel border
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth background animation
                        clip: true                                                // Clips content to bounds

                        MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 0; z: -1 } // Click to highlight instruction box

                        ColumnLayout {                                            // Vertical layout for instruction content
                            id: instructionLayout                                 // Identifier "instructionLayout"
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(14) // Anchored with 14-unit margins
                            spacing: root.s(10)                                   // 10-unit vertical spacing
                            Text {                                                // Title text for instructions
                                text: "Weather Widget Setup"; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: root.s(15) // Bold title "Weather Widget Setup"
                                color: wBox0.isActive ? root.base : root.text; Layout.bottomMargin: root.s(2) // Active-dependent color; 2-unit bottom margin
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                            }
                            RowLayout {                                           // Horizontal layout for step 1 header
                                spacing: root.s(10)                               // 10-unit spacing between step number and text
                                Rectangle {                                       // Step number circle background
                                    width: root.s(22); height: root.s(22); radius: root.s(11) // 22x22 circle; radius half of width for perfect circle
                                    color: wBox0.isActive ? Qt.alpha(root.base, 0.25) : Qt.alpha(root.blue, 0.2) // Semi-transparent based on state
                                    border.color: wBox0.isActive ? Qt.alpha(root.base, 0.5) : root.blue; border.width: 1 // Subtle border
                                    Behavior on color { ColorAnimation { duration: 220 } } // Smooth color
                                    Text { anchors.centerIn: parent; text: "1"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(11); color: wBox0.isActive ? root.base : root.blue; Behavior on color { ColorAnimation { duration: 220 } } } // Step number "1" centered
                                }
                                Text {                                            // Step 1 instruction text
                                    text: "Get an API Key"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(13) // "Get an API Key" instruction
                                    color: wBox0.isActive ? root.base : root.text; Layout.fillWidth: true // Active-dependent color; fills width
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                }
                            }
                            RowLayout {                                           // Horizontal layout for step 1 substeps with connecting line
                                spacing: root.s(10); Layout.fillWidth: true       // 10-unit spacing; fills width
                                Item {                                            // Spacer for the connecting vertical line
                                    Layout.preferredWidth: root.s(22); Layout.fillHeight: true // Matches step circle width; fills height for line
                                    Rectangle {                                   // Vertical connecting line
                                        anchors.horizontalCenter: parent.horizontalCenter; width: 2; height: parent.height + root.s(10) // 2px wide; extends 10 units beyond parent
                                        color: wBox0.isActive ? Qt.alpha(root.base, 0.3) : root.surface2 // Semi-transparent based on state
                                        Behavior on color { ColorAnimation { duration: 220 } } // Smooth color
                                    }
                                }
                                ColumnLayout {                                    // Vertical layout for substep items
                                    Layout.fillWidth: true; spacing: root.s(6); Layout.topMargin: root.s(2); Layout.bottomMargin: root.s(2) // Fills width; 6-unit spacing; 2-unit vertical margins
                                    Repeater {                                    // Creates repeating items from a data model array
                                        model: ["Go to openweathermap.org & create an account.", "Navigate to profile -> 'My API keys'.", "Generate a new key and paste it below."] // Array of instruction strings
                                        Rectangle {                               // Individual substep container
                                            Layout.fillWidth: true; Layout.preferredHeight: root.s(30) // Full width; 30-unit height
                                            radius: root.s(6)                     // 6-unit corner radius
                                            color: wBox0.isActive ? Qt.alpha(root.base, 0.12) : root.surface0 // Very subtle background
                                            border.color: wBox0.isActive ? Qt.alpha(root.base, 0.2) : root.surface1; border.width: 1 // Subtle border
                                            Behavior on color { ColorAnimation { duration: 220 } } // Smooth color
                                            Behavior on border.color { ColorAnimation { duration: 220 } } // Smooth border color
                                            RowLayout { anchors.fill: parent; anchors.margins: root.s(7); spacing: root.s(7) // Fills with 7-unit margin; 7-unit spacing
                                                Text { text: "󰄾"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(12); color: wBox0.isActive ? Qt.alpha(root.base, 0.6) : root.overlay0; Behavior on color { ColorAnimation { duration: 220 } } } // Checkmark bullet icon
                                                Text { text: modelData; font.family: "Inter"; font.pixelSize: root.s(11); color: wBox0.isActive ? Qt.alpha(root.base, 0.85) : root.subtext1; Layout.fillWidth: true; Behavior on color { ColorAnimation { duration: 220 } } } // Instruction text from model
                                            }
                                        }
                                    }
                                }
                            }
                            RowLayout {                                           // Horizontal layout for step 2 header
                                spacing: root.s(10)                               // 10-unit spacing
                                Rectangle {                                       // Step number circle for step 2
                                    width: root.s(22); height: root.s(22); radius: root.s(11) // 22x22 circle
                                    color: wBox0.isActive ? Qt.alpha(root.base, 0.25) : Qt.alpha(root.peach, 0.2) // Peach-tinted when inactive
                                    border.color: wBox0.isActive ? Qt.alpha(root.base, 0.5) : root.peach; border.width: 1 // Peach border when inactive
                                    Behavior on color { ColorAnimation { duration: 220 } } // Smooth color
                                    Text { anchors.centerIn: parent; text: "2"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(11); color: wBox0.isActive ? root.base : root.peach; Behavior on color { ColorAnimation { duration: 220 } } } // Step number "2"
                                }
                                Text {                                            // Step 2 instruction text
                                    text: "Find your City ID"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(13) // "Find your City ID"
                                    color: wBox0.isActive ? root.base : root.text; Layout.fillWidth: true // Active-dependent color
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                }
                            }
                            RowLayout {                                           // Horizontal layout for step 2 substeps with fading connecting line
                                spacing: root.s(10); Layout.fillWidth: true       // 10-unit spacing; fills width
                                Item {                                            // Spacer for fading vertical line
                                    Layout.preferredWidth: root.s(22); Layout.fillHeight: true // Matches step circle width
                                    Rectangle {                                   // Fading vertical line (shorter, fades at bottom)
                                        anchors.horizontalCenter: parent.horizontalCenter; width: 2; height: parent.height - root.s(10); anchors.top: parent.top // 2px wide; shorter than parent; top-anchored
                                        color: wBox0.isActive ? Qt.alpha(root.base, 0.3) : root.surface2 // Semi-transparent
                                        Behavior on color { ColorAnimation { duration: 220 } } // Smooth color
                                        gradient: Gradient {                      // Gradient to fade out at bottom
                                            GradientStop { position: 0.0; color: wBox0.isActive ? Qt.alpha(root.base, 0.3) : root.surface2 } // Full color at top
                                            GradientStop { position: 1.0; color: "transparent" } // Transparent at bottom
                                        }
                                    }
                                }
                                ColumnLayout {                                    // Vertical layout for step 2 substeps
                                    Layout.fillWidth: true; spacing: root.s(6); Layout.topMargin: root.s(2); Layout.bottomMargin: root.s(2) // Full width; 6-unit spacing; vertical margins
                                    Repeater {                                    // Repeater for step 2 instructions
                                        model: ["Search for your city on openweathermap.org.", "Look at the URL (e.g. .../city/2643743).", "Copy the number at the end and paste below."] // Step 2 instruction array
                                        Rectangle {                               // Individual substep
                                            Layout.fillWidth: true; Layout.preferredHeight: root.s(30) // Full width; 30-unit height
                                            radius: root.s(6)                     // 6-unit corner radius
                                            color: wBox0.isActive ? Qt.alpha(root.base, 0.12) : root.surface0 // Subtle background
                                            border.color: wBox0.isActive ? Qt.alpha(root.base, 0.2) : root.surface1; border.width: 1 // Subtle border
                                            Behavior on color { ColorAnimation { duration: 220 } } // Smooth color
                                            Behavior on border.color { ColorAnimation { duration: 220 } } // Smooth border
                                            RowLayout { anchors.fill: parent; anchors.margins: root.s(7); spacing: root.s(7) // Fills with margins
                                                Text { text: "󰄾"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(12); color: wBox0.isActive ? Qt.alpha(root.base, 0.6) : root.overlay0; Behavior on color { ColorAnimation { duration: 220 } } } // Checkmark bullet
                                                Text { text: modelData; font.family: "Inter"; font.pixelSize: root.s(11); color: wBox0.isActive ? Qt.alpha(root.base, 0.85) : root.subtext1; Layout.fillWidth: true; Behavior on color { ColorAnimation { duration: 220 } } } // Instruction text
                                            }
                                        }
                                    }
                                }
                            }
                            Text {                                                // Warning note about API key activation delay
                                text: "* Note: New API keys may take a few hours to activate."; font.family: "Inter"; font.pixelSize: root.s(10) // Warning note in italic
                                color: wBox0.isActive ? Qt.alpha(root.base, 0.7) : root.yellow; font.italic: true; Layout.topMargin: root.s(2) // Yellow warning color when inactive; italic; 2-unit top margin
                                Behavior on color { ColorAnimation { duration: 220 } } // Smooth color
                            }
                        }
                    }

                    // ── Box 1: API Key ─────────────────────────────────────── // Comment divider for API key input box
                    Rectangle {                                                    // API key container
                        id: wBox1                                                  // Identifier "wBox1"
                        Layout.fillWidth: true                                    // Full width
                        Layout.preferredHeight: apiKeyRow.implicitHeight + root.s(28) // Dynamic height from content plus padding
                        radius: root.s(12)                                        // 12-unit corner radius

                        property bool isActive: root.highlightedBox === 1         // True when highlighted (index 1)
                        color: isActive ? root.blue : root.surface0               // Blue when active
                        border.color: isActive ? root.blue : root.surface1        // Matching border
                        border.width: 1                                           // 1-pixel border
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color

                        MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 1; z: -1 } // Click to highlight

                        ColumnLayout {                                            // Vertical layout for API key content
                            id: apiKeyRow                                          // Identifier "apiKeyRow"
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16) // Anchored with 16-unit margins
                            spacing: root.s(10)                                   // 10-unit spacing
                            RowLayout {                                           // Horizontal layout for icon and labels
                                Layout.fillWidth: true; spacing: root.s(14)       // Full width; 14-unit spacing
                                Item {                                            // Icon spacer
                                    Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter // Fixed width; vertically centered
                                    Text {                                        // Key icon
                                        anchors.centerIn: parent; text: "󰌆"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18) // Key icon in Nerd Font
                                        color: wBox1.isActive ? root.base : root.blue // Active-dependent color
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                    }
                                }
                                ColumnLayout {                                    // Vertical text layout
                                    Layout.fillWidth: true; spacing: root.s(3)    // Full width; 3-unit gap
                                    Text {                                        // Title "API Key"
                                        text: "API Key"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14) // Medium weight title
                                        color: wBox1.isActive ? root.base : root.text; Layout.fillWidth: true // Active-dependent color
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                    }
                                    Text {                                        // Description
                                        text: "OpenWeather API key"; font.family: "Inter"; font.pixelSize: root.s(11) // "OpenWeather API key" subtitle
                                        color: wBox1.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true // Semi-transparent
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                    }
                                }
                            }
                            Rectangle {                                           // Input field background
                                Layout.fillWidth: true; Layout.preferredHeight: root.s(42) // Full width; 42-unit height
                                radius: root.s(7)                                 // 7-unit radius
                                color: wBox1.isActive ? Qt.alpha(root.base, 0.15) : root.surface0 // Background based on state
                                border.color: apiKeyInput.activeFocus              // Border depends on focus
                                    ? (wBox1.isActive ? root.base : root.blue)     // Focused: accent color
                                    : (wBox1.isActive ? Qt.alpha(root.base, 0.3) : root.surface2) // Unfocused: subtle
                                border.width: 1                                   // 1-pixel border
                                Behavior on border.color { ColorAnimation { duration: 150 } } // Quick border transition
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth background
                                RowLayout {                                       // Horizontal layout for input and visibility toggle
                                    anchors.fill: parent; anchors.margins: root.s(10); spacing: root.s(10) // Fills with 10-unit margin; 10-unit spacing
                                    Text {                                        // Key icon inside input
                                        text: "󰌆"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(16) // Smaller key icon
                                        color: wBox1.isActive ? Qt.alpha(root.base, 0.6) : root.subtext0 // Faded icon color
                                        Behavior on color { ColorAnimation { duration: 220 } } // Smooth color
                                    }
                                    TextInput {                                   // API key input field
                                        id: apiKeyInput                           // Identifier "apiKeyInput"
                                        Layout.fillWidth: true; Layout.fillHeight: true // Fills available space
                                        verticalAlignment: TextInput.AlignVCenter // Vertically centered text
                                        font.family: "JetBrains Mono"; font.pixelSize: root.s(12) // Monospace font at 12 pixels
                                        color: wBox1.isActive ? root.base : root.text; clip: true; selectByMouse: true // Text color; clips overflow; mouse selectable
                                        echoMode: weatherTabRoot.apiKeyVisible ? TextInput.Normal : TextInput.Password // Shows password dots unless visibility toggled
                                        passwordCharacter: "•"                     // Uses bullet character for hidden text
                                        onTextChanged: Config.weatherApiKey = text // Updates config in real-time as user types
                                        Behavior on color { ColorAnimation { duration: 220 } } // Smooth text color
                                        Text {                                    // Placeholder text
                                            text: "Enter API Key..."; color: wBox1.isActive ? Qt.alpha(root.base, 0.5) : root.subtext0 // Placeholder prompt
                                            visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter // Visible when empty and unfocused
                                            Behavior on color { ColorAnimation { duration: 220 } } // Smooth placeholder color
                                        }
                                    }
                                    Rectangle {                                   // Visibility toggle button
                                        width: root.s(24); height: root.s(24); radius: root.s(4); color: "transparent" // 24x24 transparent square; 4-unit radius
                                        Text {                                    // Eye icon for visibility toggle
                                            anchors.centerIn: parent; text: weatherTabRoot.apiKeyVisible ? "󰈈" : "󰈉"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(16) // Open eye when visible, closed eye when hidden
                                            color: eyeMa.containsMouse            // Color depends on hover
                                                ? (wBox1.isActive ? root.base : root.blue) // Accent on hover
                                                : (wBox1.isActive ? Qt.alpha(root.base, 0.6) : root.subtext0) // Faded otherwise
                                            Behavior on color { ColorAnimation { duration: 150 } } // Quick color transition
                                        }
                                        MouseArea { id: eyeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: weatherTabRoot.apiKeyVisible = !weatherTabRoot.apiKeyVisible } // Toggle visibility on click
                                    }
                                }
                            }
                        }
                    }

                    // ── Box 2: City ID ─────────────────────────────────────── // Comment divider for City ID input box
                    Rectangle {                                                    // City ID container
                        id: wBox2                                                  // Identifier "wBox2"
                        Layout.fillWidth: true                                    // Full width
                        Layout.preferredHeight: cityIdRow.implicitHeight + root.s(28) // Dynamic height from content plus padding
                        radius: root.s(12)                                        // 12-unit corner radius

                        property bool isActive: root.highlightedBox === 2         // True when highlighted (index 2)
                        color: isActive ? root.blue : root.surface0               // Blue when active
                        border.color: isActive ? root.blue : root.surface1        // Matching border
                        border.width: 1                                           // 1-pixel border
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color

                        MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 2; z: -1 } // Click to highlight

                        ColumnLayout {                                            // Vertical layout for City ID content
                            id: cityIdRow                                          // Identifier "cityIdRow"
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16) // Anchored with 16-unit margins
                            spacing: root.s(10)                                   // 10-unit spacing
                            RowLayout {                                           // Horizontal layout for icon and labels
                                Layout.fillWidth: true; spacing: root.s(14)       // Full width; 14-unit spacing
                                Item {                                            // Icon spacer
                                    Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter // Fixed width; vertically centered
                                    Text {                                        // City/building icon
                                        anchors.centerIn: parent; text: "󰖐"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18) // City icon in Nerd Font
                                        color: wBox2.isActive ? root.base : root.blue // Active-dependent color
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                    }
                                }
                                ColumnLayout {                                    // Vertical text layout
                                    Layout.fillWidth: true; spacing: root.s(3)    // Full width; 3-unit gap
                                    Text {                                        // Title "City ID"
                                        text: "City ID"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14) // Medium weight title
                                        color: wBox2.isActive ? root.base : root.text; Layout.fillWidth: true // Active-dependent color
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                    }
                                    Text {                                        // Description
                                        text: "OpenWeather city ID"; font.family: "Inter"; font.pixelSize: root.s(11) // "OpenWeather city ID" subtitle
                                        color: wBox2.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true // Semi-transparent
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                    }
                                }
                            }
                            Rectangle {                                           // Input field background
                                Layout.fillWidth: true; Layout.preferredHeight: root.s(42) // Full width; 42-unit height
                                radius: root.s(7)                                 // 7-unit radius
                                color: wBox2.isActive ? Qt.alpha(root.base, 0.15) : root.surface0 // Background based on state
                                border.color: cityIdInput.activeFocus              // Border depends on focus
                                    ? (wBox2.isActive ? root.base : root.blue)     // Focused: accent color
                                    : (wBox2.isActive ? Qt.alpha(root.base, 0.3) : root.surface2) // Unfocused: subtle
                                border.width: 1                                   // 1-pixel border
                                Behavior on border.color { ColorAnimation { duration: 150 } } // Quick border transition
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth background
                                TextInput {                                       // City ID input field
                                    id: cityIdInput                               // Identifier "cityIdInput"
                                    anchors.fill: parent; anchors.margins: root.s(10) // Fills parent with 10-unit margin
                                    verticalAlignment: TextInput.AlignVCenter     // Vertically centered text
                                    font.family: "JetBrains Mono"; font.pixelSize: root.s(12) // Monospace font at 12 pixels
                                    color: wBox2.isActive ? root.base : root.text; clip: true; selectByMouse: true // Text color; clips; selectable
                                    onTextChanged: Config.weatherCityId = text    // Updates config in real-time
                                    Behavior on color { ColorAnimation { duration: 220 } } // Smooth text color
                                    Text {                                        // Placeholder text with example
                                        text: "City ID (e.g. 2624652)"; color: wBox2.isActive ? Qt.alpha(root.base, 0.5) : root.subtext0 // Example placeholder
                                        visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter // Visible when empty and unfocused
                                        Behavior on color { ColorAnimation { duration: 220 } } // Smooth placeholder color
                                    }
                                }
                            }
                        }
                    }

                    // ── Box 3: Temperature Unit ────────────────────────────── // Comment divider for temperature unit selection box
                    Rectangle {                                                    // Temperature unit container
                        id: wBox3                                                  // Identifier "wBox3"
                        Layout.fillWidth: true                                    // Full width
                        Layout.preferredHeight: unitRow.implicitHeight + root.s(28) // Dynamic height from content plus padding
                        radius: root.s(12)                                        // 12-unit corner radius

                        property bool isActive: root.highlightedBox === 3         // True when highlighted (index 3)
                        color: isActive ? root.blue : root.surface0               // Blue when active
                        border.color: isActive ? root.blue : root.surface1        // Matching border
                        border.width: 1                                           // 1-pixel border
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color

                        MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 3; z: -1 } // Click to highlight

                        ColumnLayout {                                            // Vertical layout for unit selection content
                            id: unitRow                                            // Identifier "unitRow"
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16) // Anchored with 16-unit margins
                            spacing: root.s(10)                                   // 10-unit spacing
                            RowLayout {                                           // Horizontal layout for icon and labels
                                Layout.fillWidth: true; spacing: root.s(14)       // Full width; 14-unit spacing
                                Item {                                            // Icon spacer
                                    Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter // Fixed width; vertically centered
                                    Text {                                        // Temperature/degree icon
                                        anchors.centerIn: parent; text: "°C"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(18) // Celsius symbol as icon
                                        color: wBox3.isActive ? root.base : root.blue // Active-dependent color
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                    }
                                }
                                ColumnLayout {                                    // Vertical text layout
                                    Layout.fillWidth: true; spacing: root.s(3)    // Full width; 3-unit gap
                                    Text {                                        // Title "Temperature Unit"
                                        text: "Temperature Unit"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14) // Medium weight title
                                        color: wBox3.isActive ? root.base : root.text; Layout.fillWidth: true // Active-dependent color
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                    }
                                    Text {                                        // Description of options
                                        text: "Celsius / Fahrenheit / Kelvin"; font.family: "Inter"; font.pixelSize: root.s(11) // Shows available unit options
                                        color: wBox3.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true // Semi-transparent
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } } // Smooth color
                                    }
                                }
                            }
                            RowLayout {                                           // Horizontal layout for unit option buttons
                                Layout.fillWidth: true; spacing: root.s(8)        // Full width; 8-unit spacing between buttons
                                Repeater {                                        // Repeater to create three unit option buttons
                                    model: [{ val: "metric", label: "Celsius" }, { val: "imperial", label: "Fahrenheit" }, { val: "standard", label: "Kelvin" }] // Array of unit options with value and display label
                                    Rectangle {                                   // Individual unit option button
                                        Layout.preferredWidth: root.s(88); Layout.preferredHeight: root.s(30); radius: root.s(6) // 88x30 button; 6-unit radius
                                        property bool isSelected: Config.weatherUnit === modelData.val // True if this unit matches current config
                                        property bool parentActive: wBox3.isActive // Reference to parent's active state
                                        color: isSelected                         // Background based on selection state
                                            ? (parentActive ? Qt.alpha(root.base, 0.25) : root.blue) // Selected: semi-transparent base when active, blue otherwise
                                            : (parentActive ? Qt.alpha(root.base, 0.1) : "transparent") // Not selected: very subtle or transparent
                                        border.color: isSelected                   // Border based on selection
                                            ? (parentActive ? Qt.alpha(root.base, 0.6) : root.blue) // Selected border: matching accent
                                            : (parentActive ? Qt.alpha(root.base, 0.2) : root.surface1) // Not selected: subtle border
                                        border.width: 1                           // 1-pixel border
                                        Behavior on color { ColorAnimation { duration: 150 } } // Quick color transition
                                        Behavior on border.color { ColorAnimation { duration: 150 } } // Quick border transition
                                        Text {                                    // Button label
                                            anchors.centerIn: parent; text: modelData.label // Centers label text (Celsius/Fahrenheit/Kelvin)
                                            font.family: "JetBrains Mono"; font.pixelSize: root.s(10); font.capitalization: Font.Capitalize // Monospace font; capitalized
                                            color: isSelected                     // Text color based on selection
                                                ? (parentActive ? root.base : root.base) // Selected: base color (white)
                                                : (parentActive ? Qt.alpha(root.base, 0.6) : root.subtext0) // Not selected: faded
                                            Behavior on color { ColorAnimation { duration: 150 } } // Quick text color transition
                                        }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Config.weatherUnit = modelData.val } // Click to set this unit in config
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    
    Component {                                                                   // Defines a reusable component for the keybinds settings tab
        id: keybindTabComponent                                                   // Component identifier "keybindTabComponent"
        Item {                                                                    // Base item container for keybinds tab
            id: keybindTabRoot                                                    // Root identifier for this keybinds tab

            function scrollToBottom() {                                           // Function to scroll to the bottom of the keybinds list
                keybindFlickable.contentY = Math.max(0, keybindsColLayout.implicitHeight - keybindFlickable.height + root.s(100)); // Set scroll to bottom, accounting for 100-unit padding
            }
            function scrollTo(y) {                                                // Function to scroll to a specific Y position
                let maxY = Math.max(0, keybindFlickable.contentHeight - keybindFlickable.height); // Calculate maximum scrollable Y
                keybindFlickable.contentY = Math.max(0, Math.min(y - root.s(40), maxY > 0 ? maxY : y)); // Set scroll with 40-unit offset, clamped to valid range
            }
            function scrollToBox(approxItemY) {                                   // Function to scroll to make a specific keybind box visible
                let viewH = keybindFlickable.height;                              // Visible height of flickable
                let itemTop = approxItemY;                                        // Approximate top of target item
                let itemBottom = approxItemY + root.s(56);                        // Estimated bottom (56 units tall)
                let curY = keybindFlickable.contentY;                             // Current scroll position
                let maxY = Math.max(0, keybindFlickable.contentHeight - viewH);   // Maximum scroll position
                if (itemTop < curY + root.s(10)) {                                // If item is above viewport (10-unit buffer)
                    keybindFlickable.contentY = Math.max(0, itemTop - root.s(20)); // Scroll up with 20-unit top margin
                } else if (itemBottom > curY + viewH - root.s(10)) {              // If item is below viewport
                    keybindFlickable.contentY = Math.min(maxY, itemBottom - viewH + root.s(20)); // Scroll down with 20-unit bottom margin
                }
            }

            Flickable {                                                           // Scrollable container for keybinds content
                id: keybindFlickable                                              // Identifier "keybindFlickable"
                anchors.fill: parent                                              // Fills entire parent area
                contentWidth: width                                                // Content width matches flickable width
                contentHeight: keybindsColLayout.implicitHeight + root.s(100)     // Content height based on column content plus 100-unit bottom padding
                boundsBehavior: Flickable.StopAtBounds                            // Stops at content boundaries
                clip: true                                                        // Clips content to bounds

                MouseArea { anchors.fill: parent; onClicked: root.clearHighlight(); z: -1 } // Click background to clear highlights

                ColumnLayout {                                                    // Main vertical layout for keybinds content
                    id: keybindsColLayout                                         // Identifier "keybindsColLayout"
                    width: parent.width                                            // Width matches parent
                    spacing: root.s(8)                                             // 8-unit vertical spacing between children

                    Rectangle {                                                   // Workspace shortcuts info box
                        Layout.fillWidth: true                                    // Full width
                        Layout.preferredHeight: wsCol.implicitHeight + root.s(32) // Height based on content plus 32-unit padding
                        radius: root.s(12)                                        // 12-unit corner radius
                        color: root.surface0                                      // Dark surface background
                        border.color: root.surface1; border.width: 1              // Subtle border
                        ColumnLayout {                                            // Vertical layout for workspace content
                            id: wsCol                                              // Identifier "wsCol"
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16) // Anchored with 16-unit margins
                            spacing: root.s(10)                                   // 10-unit vertical spacing
                            Text { text: "Workspaces (SUPER + 1-9)"; font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: root.s(12); color: root.text; Layout.alignment: Qt.AlignVCenter } // Title showing workspace shortcut info, centered
                            Flow {                                                // Flow layout that wraps workspace number buttons
                                Layout.fillWidth: true; spacing: root.s(7)        // Full width; 7-unit spacing between buttons
                                Repeater {                                        // Creates 9 workspace buttons (1-9)
                                    model: 9                                      // Model with 9 items
                                    Rectangle {                                   // Individual workspace number button
                                        property int wsNum: index + 1             // Workspace number (1-based, from index 0-8)
                                        width: root.s(30); height: root.s(30); radius: root.s(6) // 30x30 square button; 6-unit radius
                                        color: wsMa.containsMouse ? root.peach : root.surface1 // Peach on hover, surface1 otherwise
                                        border.color: wsMa.containsMouse ? root.peach : "transparent"; border.width: 1 // Peach border on hover
                                        Behavior on color { ColorAnimation { duration: 150 } } // Quick color transition
                                        Text {                                    // Workspace number display
                                            anchors.centerIn: parent; text: parent.wsNum // Centers number text
                                            font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(11) // Bold monospace at 11 pixels
                                            color: wsMa.containsMouse ? root.base : root.peach // White on hover, peach normally
                                            Behavior on color { ColorAnimation { duration: 150 } } // Quick text color transition
                                        }
                                        MouseArea { id: wsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", wsNum.toString()]) } // Click runs qs_manager.sh with workspace number
                                    }
                                }
                            }
                        }
                    }

                    ListView {                                                    // List view for dynamic keybind entries
                        id: kbListView                                            // Identifier "kbListView"
                        Layout.fillWidth: true                                    // Full width
                        Layout.preferredHeight: implicitHeight                    // Height matches natural content height
                        implicitHeight: dynamicKeybindsModel.count * root.s(56) + root.s(20) // Calculated height: item count times 56 units plus 20-unit padding
                        model: dynamicKeybindsModel                               // Data model for keybinds
                        interactive: false                                        // Disables scrolling (parent Flickable handles scrolling)
                        cacheBuffer: root.s(2000)                                 // Caches 2000 units of items above/below viewport for smooth scrolling
                        displayMarginBeginning: root.s(100)                       // Shows 100 units of margin before first item
                        displayMarginEnd: root.s(100)                             // Shows 100 units of margin after last item
                        spacing: root.s(8)                                        // 8-unit spacing between keybind items

                        delegate: Rectangle {                                     // Template/delegate for each keybind entry
                            id: kbRowRect                                         // Identifier "kbRowRect" for this keybind row
                            property int outerIndex: index                        // Stores the index of this item in the model
                            property bool isJumpHighlighted: root.highlightedBox === outerIndex // True when this row is highlighted via search jump
                            
                            property bool layoutReady: false                      // Tracks if layout has completed initial setup
                            Component.onCompleted: Qt.callLater(() => layoutReady = true) // Sets layoutReady to true after component fully loads (deferred)

                            width: kbListView.width                               // Width matches parent list view
                            height: root.s(44) + (model.isEditing ? editPanel.implicitHeight + root.s(12) : 0) // Base height 44 units; expands when editing to show edit panel plus 12-unit padding
                            radius: root.s(8)                                     // 8-unit corner radius

                            HoverHandler { id: rowHover }                          // Built-in hover handler for detecting mouse hover
                            property bool isHovered: rowHover.hovered || model.isEditing || isJumpHighlighted // True when hovered, editing, or jump-highlighted
                            property bool isTypeOpen: false                        // Tracks if type dropdown is open
                            property bool isDispOpen: false                        // Tracks if dispatcher dropdown is open

                            color: isJumpHighlighted ? root.surface1 : (isHovered ? root.surface1 : root.surface0) // Highlighted: surface1; hovered: surface1; default: surface0
                            border.color: isJumpHighlighted ? root.peach : (isHovered ? Qt.alpha(root.peach, 0.5) : root.surface1) // Jump highlight: peach; hover: faded peach; default: surface1
                            border.width: isJumpHighlighted ? 2 : 1               // 2px border when jump-highlighted, 1px otherwise

                            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } } // Animated height changes for edit panel expansion
                            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } } // Smooth background color
                            Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } } // Smooth border color
                            Behavior on border.width { NumberAnimation { duration: 150 } } // Smooth border width

                            MouseArea { anchors.fill: parent; z: -2; onClicked: root.highlightedBox = outerIndex; } // Click row to highlight it (z: -2 behind other interactive elements)

                            ColumnLayout {                                        // Vertical layout for keybind row content
                                anchors.fill: parent; anchors.margins: root.s(10); spacing: root.s(10) // Fills parent with 10-unit margin and spacing

                                Item {                                            // Container for the top row (key combination display)
                                    Layout.fillWidth: true; Layout.preferredHeight: root.s(24); clip: true // Full width; 24-unit height; clips overflow

                                    Row {                                         // Horizontal row for modifier and key badges
                                        id: modKeyContainer                       // Identifier "modKeyContainer"
                                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: root.s(5) // Left-aligned; vertically centered; 5-unit spacing
                                        Rectangle {                               // Modifier key badge
                                            width: k1Text.implicitWidth + root.s(10); height: root.s(24); radius: root.s(4) // Dynamic width based on text plus padding; 24-unit height; 4-unit radius
                                            color: root.surface1                  // Surface1 background
                                            border.color: root.surface2; border.width: 1 // Subtle border
                                            visible: model.mods !== ""            // Only visible when modifiers exist
                                            Text {                                // Modifier text (e.g., "SUPER SHIFT")
                                                id: k1Text; anchors.centerIn: parent; text: model.mods // Centers modifier string
                                                font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(9) // Bold monospace at 9 pixels
                                                color: root.peach                 // Peach accent color for modifiers
                                            }
                                        }
                                        Text {                                    // Plus sign between modifier and key
                                            text: "+"; font.family: "JetBrains Mono"; font.pixelSize: root.s(10) // Plus separator
                                            color: root.overlay0                  // Muted overlay color
                                            visible: model.mods !== "" && model.key !== ""; anchors.verticalCenter: parent.verticalCenter // Visible only when both mods and key exist
                                        }
                                        Rectangle {                               // Key badge
                                            width: k2Text.implicitWidth + root.s(10); height: root.s(24); radius: root.s(4) // Dynamic width; 24-unit height; 4-unit radius
                                            color: root.surface1                  // Surface1 background
                                            border.color: root.surface2; border.width: 1 // Subtle border
                                            visible: model.key !== ""             // Visible only when key exists
                                            Text {                                // Key text (e.g., "A", "Return")
                                                id: k2Text; anchors.centerIn: parent; text: model.key // Centers key string
                                                font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(9) // Bold monospace at 9 pixels
                                                color: root.peach                 // Peach accent color
                                            }
                                        }
                                    }

                                    // Edit button
                                    Rectangle {                                   // Edit/expand button (slides in from right)
                                        id: editButtonSlide                       // Identifier "editButtonSlide"
                                        width: root.s(26); height: root.s(26); radius: root.s(6) // 26x26 button; 6-unit radius
                                        anchors.verticalCenter: parent.verticalCenter // Vertically centered in parent
                                        x: kbRowRect.isHovered ? parent.width - width : parent.width // Slides to left edge when hovered, off-screen to right when not
                                        color: model.isEditing                    // Color based on editing state
                                            ? root.peach                          // Peach when editing (active)
                                            : (editMa.containsMouse ? root.peach : root.surface2) // Peach on hover, surface2 otherwise
                                            
                                        Behavior on x {                            // Animated horizontal sliding
                                            enabled: kbRowRect.layoutReady        // Animation only after layout is ready
                                            NumberAnimation { duration: 250; easing.type: Easing.OutQuart } // 250ms quartic ease-out slide
                                        }
                                        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } } // Smooth button color
                                        
                                        Text {                                    // Button icon text
                                            anchors.centerIn: parent              // Centers icon in button
                                            text: model.isEditing ? "▴" : "󰏫"    // Up triangle when editing (collapse), edit icon when collapsed
                                            font.family: model.isEditing ? "Inter" : "Iosevka Nerd Font" // Different font depending on state
                                            font.pixelSize: root.s(13)           // 13-pixel icon
                                            color: model.isEditing                // Icon color
                                                ? root.base                       // Base (white) when editing
                                                : (editMa.containsMouse ? root.base : root.subtext0) // White on hover, subtext0 otherwise
                                            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } } // Smooth icon color
                                        }
                                        MouseArea {                               // Interactive area for edit button
                                            id: editMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor // Full coverage; hover enabled; hand cursor
                                            onClicked: {                          // Click handler to toggle edit mode
                                                dynamicKeybindsModel.setProperty(outerIndex, "isEditing", !model.isEditing); // Toggle editing state
                                                kbRowRect.isTypeOpen = false;     // Close type dropdown
                                                kbRowRect.isDispOpen = false;     // Close dispatcher dropdown
                                                if (!model.isEditing) {           // If closing edit mode
                                                    root.forceActiveFocus();      // Return focus to root
                                                }
                                            } 
                                        }
                                    }
                                    Item {                                        // Container for the command text with marquee scrolling effect
                                        id: cmdClipRect                           // Identifier "cmdClipRect"
                                        anchors.left: modKeyContainer.right; anchors.leftMargin: root.s(8) // Positioned to right of key badges with 8-unit margin
                                        anchors.right: editButtonSlide.left; anchors.rightMargin: root.s(6) // Extends to left of edit button with 6-unit margin
                                        anchors.verticalCenter: parent.verticalCenter; height: parent.height; clip: true // Vertically centered; matches parent height; clips overflow for marquee

                                        property int marqueeSpacing: root.s(60)   // 60-unit spacing between duplicated text for seamless marquee
                                        property bool shouldMarquee: kbRowRect.isHovered && cmdTextMain.implicitWidth > width // True when hovered AND text is wider than container (needs scrolling)

                                        Item {                                    // Container that moves for marquee animation
                                            id: marqueeContainer                  // Identifier "marqueeContainer"
                                            height: parent.height                 // Matches parent height
                                            width: cmdClipRect.shouldMarquee ? cmdTextMain.implicitWidth * 2 + cmdClipRect.marqueeSpacing : parent.width // When marquee: double text width plus spacing; otherwise matches parent
                                            anchors.verticalCenter: parent.verticalCenter // Vertically centered
                                            anchors.right: cmdClipRect.shouldMarquee ? undefined : parent.right // Right-anchored when not marqueeing, undefined when marqueeing
                                            anchors.left: cmdClipRect.shouldMarquee ? parent.left : undefined // Left-anchored when marqueeing

                                            Row {                                 // Horizontal row containing text and its clone
                                                spacing: cmdClipRect.marqueeSpacing; anchors.verticalCenter: parent.verticalCenter // Spacing between text copies; vertically centered
                                                anchors.right: cmdClipRect.shouldMarquee ? undefined : parent.right // Right-anchored when static
                                                Text {                            // Main command text
                                                    id: cmdTextMain; text: (model.dispatcher + " " + model.command).trim() // Displays dispatcher and command combined
                                                    font.family: "JetBrains Mono"; font.pixelSize: root.s(10) // Monospace at 10 pixels
                                                    color: root.subtext0          // Muted subtext color
                                                }
                                                Text {                            // Clone of command text for seamless looping marquee
                                                    id: cmdTextClone; text: cmdTextMain.text; font: cmdTextMain.font; color: cmdTextMain.color // Identical text and styling
                                                    visible: cmdClipRect.shouldMarquee // Only visible during marquee animation
                                                }
                                            }

                                            SequentialAnimation on x {             // Animation sequence for marquee scrolling
                                                id: cmdAnim; running: cmdClipRect.shouldMarquee && kbRowRect.layoutReady // Runs when marquee needed and layout ready
                                                loops: Animation.Infinite         // Loops infinitely
                                                PauseAnimation { duration: 1500 }  // Pause 1.5 seconds at start
                                                NumberAnimation { from: 0; to: -(cmdTextMain.implicitWidth + cmdClipRect.marqueeSpacing); duration: (cmdTextMain.implicitWidth + cmdClipRect.marqueeSpacing) * 25 } // Scrolls left by one text width plus spacing; speed proportional to text length
                                                PropertyAction { target: marqueeContainer; property: "x"; value: 0 } // Instantly resets position to 0 after scroll completes
                                            }
                                            onXChanged: { if (!cmdClipRect.shouldMarquee && x !== 0) x = 0; } // Reset x to 0 when marquee stops
                                        }

                                        onShouldMarqueeChanged: {                 // When marquee state changes
                                            if (shouldMarquee) { marqueeContainer.anchors.right = undefined; marqueeContainer.anchors.left = parent.left; marqueeContainer.x = 0; cmdAnim.restart(); } // Setup for marquee: left-anchor, reset position, start animation
                                            else { cmdAnim.stop(); marqueeContainer.x = 0; marqueeContainer.anchors.left = undefined; marqueeContainer.anchors.right = parent.right; } // Stop marquee: right-anchor, reset position, stop animation
                                        }
                                    }

                                    MouseArea {                                   // Clickable area on the keybind display (left portion)
                                        id: bindMa                                // Identifier "bindMa"
                                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: editButtonSlide.left // Covers from left edge to edit button
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton; enabled: !model.isEditing // Hand cursor; only left click; disabled when editing
                                        onClicked: {                              // Click handler to execute the keybind
                                            if (model.dispatcher.startsWith("exec")) { Quickshell.execDetached(["bash", "-c", model.command]); } // If dispatcher starts with "exec", run command via bash
                                            else { Quickshell.execDetached(["hyprctl", "dispatch", model.dispatcher, model.command]); } // Otherwise dispatch via hyprctl
                                        }
                                    }
                                }

                                // ── Edit panel ─────────────────────────────── // Comment divider for the editable keybind configuration panel
                                ColumnLayout {                                    // Vertical layout for edit controls
                                    id: editPanel                                 // Identifier "editPanel"
                                    Layout.fillWidth: true; visible: model.isEditing; spacing: root.s(8); clip: true // Full width; only visible when editing; 8-unit spacing; clips content

                                    // Record shortcut
                                    Rectangle {                                   // Shortcut recording button/area
                                        Layout.fillWidth: true; Layout.preferredHeight: root.s(34) // Full width; 34-unit height
                                        radius: root.s(6)                         // 6-unit corner radius
                                        color: recordMa.pressed || captureTrap.activeFocus // Background when pressed or focused
                                            ? Qt.alpha(root.red, 0.12)             // Light red tint when active
                                            : root.surface0                        // Surface0 when idle
                                        border.color: recordMa.pressed || captureTrap.activeFocus // Border when active
                                            ? root.red                            // Red border when active
                                            : root.surface2                        // Surface2 border when idle
                                        border.width: 1                           // 1-pixel border
                                        Behavior on color { ColorAnimation { duration: 150 } } // Quick background transition
                                        Behavior on border.color { ColorAnimation { duration: 150 } } // Quick border transition
                                        Text {                                    // Recording prompt text
                                            anchors.centerIn: parent; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(11) // Bold monospace centered text
                                            color: captureTrap.activeFocus ? root.red : root.text // Red when actively recording, normal text otherwise
                                            Behavior on color { ColorAnimation { duration: 150 } } // Quick text color
                                            text: captureTrap.activeFocus ? "Press Keys (Esc to confirm)..." : (model.mods ? model.mods + " + " : "") + (model.key || "[Click to Record Shortcut]") // Shows instructions when recording, or current shortcut, or click prompt
                                        }
                                        MouseArea {                               // Clickable area to start recording
                                            id: recordMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor // Full coverage; hand cursor
                                            onClicked: { captureTrap.accumulatedMods = []; captureTrap.accumulatedKey = ""; captureTrap.forceActiveFocus(); } // Reset accumulated keys and focus the capture trap to start recording
                                        }
                                        Item {                                    // Invisible item that captures keyboard input
                                            id: captureTrap                       // Identifier "captureTrap"
                                            focus: false                          // Initially not focused
                                            property var accumulatedMods: []       // Array to store captured modifier keys
                                            property string accumulatedKey: ""     // String for the captured main key
                                            Keys.onTabPressed: (event) => { event.accepted = true; processKey(event); } // Capture Tab key
                                            Keys.onBacktabPressed: (event) => { event.accepted = true; processKey(event); } // Capture Shift+Tab
                                            Keys.onReturnPressed: (event) => { event.accepted = true; processKey(event); } // Capture Enter key
                                            Keys.onEnterPressed: (event) => { event.accepted = true; processKey(event); } // Capture Numpad Enter
                                            Keys.onEscapePressed: (event) => { captureTrap.focus = false; event.accepted = true; } // Escape stops recording
                                            Keys.onShortcutOverride: (event) => { event.accepted = true; } // Prevent shortcuts from interfering
                                            Keys.onReleased: (event) => { event.accepted = true; } // Accept all key releases
                                            Keys.onPressed: (event) => { event.accepted = true; processKey(event); } // Handle all key presses
                                            function processKey(event) {           // Function to process captured key events
                                                if (event.key === Qt.Key_Escape) return; // Ignore Escape key
                                                let newMods = [];                  // Array for new modifier keys
                                                if (event.modifiers & Qt.MetaModifier) newMods.push("$mainMod"); // Add Super/Win key if pressed
                                                if (event.modifiers & Qt.ControlModifier) newMods.push("CTRL"); // Add Control if pressed
                                                if (event.modifiers & Qt.AltModifier) newMods.push("ALT"); // Add Alt if pressed
                                                if (event.modifiers & Qt.ShiftModifier) newMods.push("SHIFT_L"); // Add Shift if pressed
                                                let isModifierOnly = (event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R || // Check if pressed key is only a modifier
                                                                      event.key === Qt.Key_Meta || event.key === Qt.Key_Control ||
                                                                      event.key === Qt.Key_Alt || event.key === Qt.Key_Shift ||
                                                                      event.key === Qt.Key_CapsLock);
                                                if (isModifierOnly) {              // If only a modifier key was pressed
                                                    let mergedMods = [...captureTrap.accumulatedMods]; // Copy current accumulated mods
                                                    for (let m of newMods) { if (!mergedMods.includes(m)) mergedMods.push(m); } // Add new mods if not already present
                                                    dynamicKeybindsModel.setProperty(outerIndex, "mods", mergedMods.join(" ")); // Update model mods
                                                    captureTrap.accumulatedMods = mergedMods; // Update accumulated mods
                                                    return;                       // Exit function
                                                }
                                                let k = "";                       // String for the key
                                                if (event.key === Qt.Key_Space) k = "SPACE"; // Map Space key
                                                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) k = "RETURN"; // Map Enter keys
                                                else if (event.key === Qt.Key_Tab) k = "TAB"; // Map Tab
                                                else if (event.key === Qt.Key_Print) k = "Print"; // Map Print Screen
                                                else if (event.key === Qt.Key_Left) k = "left"; // Map left arrow
                                                else if (event.key === Qt.Key_Right) k = "right"; // Map right arrow
                                                else if (event.key === Qt.Key_Up) k = "up"; // Map up arrow
                                                else if (event.key === Qt.Key_Down) k = "down"; // Map down arrow
                                                else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F35) { k = "F" + (event.key - Qt.Key_F1 + 1); } // Map function keys F1-F35
                                                else if (event.text && event.text.length > 0) k = event.text.toUpperCase(); // Use uppercase text for regular keys
                                                else k = event.key.toString();     // Fallback to key code string
                                                if (captureTrap.accumulatedKey !== "") { // If we already have a key, treat new key as additional modifier
                                                    let prevMods = model.mods ? model.mods.split(" ").filter(x => x !== "") : []; // Get current mods
                                                    if (!prevMods.includes(captureTrap.accumulatedKey)) prevMods.push(captureTrap.accumulatedKey); // Add previous key as modifier
                                                    for (let m of newMods) { if (!prevMods.includes(m)) prevMods.push(m); } // Add new mods
                                                    dynamicKeybindsModel.setProperty(outerIndex, "mods", prevMods.join(" ")); // Update model
                                                    captureTrap.accumulatedMods = prevMods; // Update accumulated
                                                } else {                          // First key press
                                                    let allMods = [...captureTrap.accumulatedMods]; // Copy accumulated mods
                                                    for (let m of newMods) { if (!allMods.includes(m)) allMods.push(m); } // Add new mods
                                                    captureTrap.accumulatedMods = allMods; // Store all mods
                                                    dynamicKeybindsModel.setProperty(outerIndex, "mods", allMods.join(" ")); // Update model
                                                }
                                                captureTrap.accumulatedKey = k;   // Store the captured key
                                                dynamicKeybindsModel.setProperty(outerIndex, "key", k); // Update model key
                                            }
                                            onActiveFocusChanged: {               // When focus changes (recording starts/stops)
                                                if (!activeFocus) { accumulatedMods = []; accumulatedKey = ""; Quickshell.execDetached(["hyprctl", "dispatch", "submap", "reset"]); } // Reset state and hyprland submap when losing focus
                                                else { Quickshell.execDetached(["hyprctl", "dispatch", "submap", "passthru"]); } // Set passthrough submap when gaining focus (prevents keybind conflicts during recording)
                                            }
                                        }
                                    }

                                    RowLayout {                                   // Horizontal layout for type and dispatcher dropdowns
                                        Layout.fillWidth: true; spacing: root.s(8); Layout.alignment: Qt.AlignTop; z: 2 // Full width; 8-unit spacing; top-aligned; z-index 2 above other elements
                                        ColumnLayout {                            // Vertical layout for type dropdown
                                            Layout.preferredWidth: (parent.width - root.s(8)) * 0.4; Layout.alignment: Qt.AlignTop; spacing: root.s(4) // 40% width; top-aligned; 4-unit spacing
                                            Rectangle {                           // Type dropdown trigger button
                                                Layout.fillWidth: true; Layout.preferredHeight: root.s(30) // Full width; 30-unit height
                                                radius: root.s(6)                 // 6-unit radius
                                                scale: kbRowRect.isTypeOpen ? 1.02 : 1.0 // Slight enlargement when dropdown open
                                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } } // Bouncy scale animation
                                                color: kbRowRect.isTypeOpen       // Background when open
                                                    ? Qt.alpha(root.peach, 0.12)  // Light peach when open
                                                    : root.surface0               // Surface0 when closed
                                                border.color: kbRowRect.isTypeOpen ? root.peach : root.surface2 // Peach border when open, surface2 when closed
                                                border.width: kbRowRect.isTypeOpen ? 2 : 1 // Thicker border when open
                                                Behavior on border.color { ColorAnimation { duration: 200 } } // Smooth border
                                                Behavior on border.width { NumberAnimation { duration: 150 } } // Smooth border width
                                                Behavior on color { ColorAnimation { duration: 200 } } // Smooth background
                                                RowLayout {                       // Horizontal layout inside button
                                                    anchors.fill: parent; anchors.margins: root.s(7) // Fills with 7-unit margin
                                                    Text {                        // Current type value display
                                                        text: model.type; font.family: "JetBrains Mono"; font.pixelSize: root.s(11) // Shows current bind type
                                                        color: kbRowRect.isTypeOpen ? root.peach : root.text; Layout.fillWidth: true // Peach when open, normal otherwise
                                                        Behavior on color { ColorAnimation { duration: 200 } } // Smooth text color
                                                    }
                                                    Text {                        // Dropdown arrow indicator
                                                        text: kbRowRect.isTypeOpen ? "▴" : "▾"; font.pixelSize: root.s(10) // Up arrow when open, down when closed
                                                        color: kbRowRect.isTypeOpen ? root.peach : root.subtext0 // Matching color
                                                        Behavior on color { ColorAnimation { duration: 200 } } // Smooth arrow color
                                                    }
                                                }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { kbRowRect.isTypeOpen = !kbRowRect.isTypeOpen; kbRowRect.isDispOpen = false; } } // Toggle type dropdown, close dispatcher dropdown
                                            }
                                            Rectangle {                           // Type dropdown list container
                                                Layout.fillWidth: true            // Full width
                                                Layout.preferredHeight: kbRowRect.isTypeOpen ? root.bindTypes.length * root.s(26) : 0 // Height based on item count when open, 0 when closed
                                                radius: root.s(6); color: root.surface0; clip: true // 6-unit radius; surface0; clips content
                                                border.color: root.surface1; border.width: kbRowRect.isTypeOpen ? 1 : 0 // Border visible only when open
                                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } } // Animated height
                                                ListView {                        // List of type options
                                                    anchors.fill: parent; model: root.bindTypes; interactive: false // Fills parent; uses bindTypes model; no scrolling
                                                    opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0 // Visible only when expanded
                                                    delegate: Rectangle {         // Individual type option
                                                        width: parent.width; height: root.s(26) // Full width; 26-unit height
                                                        color: typeItemMa.containsMouse ? Qt.alpha(root.peach, 0.12) : "transparent" // Peach highlight on hover
                                                        Behavior on color { ColorAnimation { duration: 120 } } // Quick hover effect
                                                        Text {                    // Type option text
                                                            anchors.verticalCenter: parent.verticalCenter; x: root.s(8); text: modelData // Vertically centered; 8-unit left padding; option text
                                                            font.family: "JetBrains Mono"; font.pixelSize: root.s(11) // Monospace at 11 pixels
                                                            color: model.type === modelData ? root.peach : root.text // Peach if current selection, normal otherwise
                                                        }
                                                        MouseArea { id: typeItemMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { dynamicKeybindsModel.setProperty(outerIndex, "type", modelData); kbRowRect.isTypeOpen = false; } } // Click to select type and close dropdown
                                                    }
                                                }
                                            }
                                        }
                                        ColumnLayout {                            // Vertical layout for dispatcher dropdown
                                            Layout.preferredWidth: (parent.width - root.s(8)) * 0.6; Layout.alignment: Qt.AlignTop; spacing: root.s(4) // 60% width; top-aligned; 4-unit spacing
                                            Rectangle {                           // Dispatcher dropdown trigger
                                                Layout.fillWidth: true; Layout.preferredHeight: root.s(30) // Full width; 30-unit height
                                                radius: root.s(6)                 // 6-unit radius
                                                scale: kbRowRect.isDispOpen ? 1.02 : 1.0 // Slight enlargement when open
                                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } } // Bouncy scale
                                                color: kbRowRect.isDispOpen       // Background based on state
                                                    ? Qt.alpha(root.peach, 0.12)  // Light peach when open
                                                    : root.surface0               // Surface0 when closed
                                                border.color: kbRowRect.isDispOpen ? root.peach : root.surface2 // Peach border when open
                                                border.width: kbRowRect.isDispOpen ? 2 : 1 // Thicker border when open
                                                Behavior on border.color { ColorAnimation { duration: 200 } } // Smooth border
                                                Behavior on border.width { NumberAnimation { duration: 150 } } // Smooth border width
                                                Behavior on color { ColorAnimation { duration: 200 } } // Smooth background
                                                RowLayout {                       // Horizontal layout inside button
                                                    anchors.fill: parent; anchors.margins: root.s(7) // Fills with 7-unit margin
                                                    Text {                        // Current dispatcher display
                                                        text: model.dispatcher; font.family: "JetBrains Mono"; font.pixelSize: root.s(11) // Shows current dispatcher value
                                                        color: kbRowRect.isDispOpen ? root.peach : root.text; Layout.fillWidth: true // Peach when open
                                                        Behavior on color { ColorAnimation { duration: 200 } } // Smooth color
                                                    }
                                                    Text {                        // Dropdown arrow
                                                        text: kbRowRect.isDispOpen ? "▴" : "▾"; font.pixelSize: root.s(10) // Arrow indicator
                                                        color: kbRowRect.isDispOpen ? root.peach : root.subtext0 // Matching color
                                                        Behavior on color { ColorAnimation { duration: 200 } } // Smooth arrow color
                                                    }
                                                }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { kbRowRect.isDispOpen = !kbRowRect.isDispOpen; kbRowRect.isTypeOpen = false; } } // Toggle dispatcher dropdown, close type dropdown
                                            }
                                            Rectangle {                           // Dispatcher dropdown list container
                                                Layout.fillWidth: true            // Full width
                                                Layout.preferredHeight: kbRowRect.isDispOpen ? Math.min(root.s(140), root.dispatchers.length * root.s(26)) : 0 // Height based on items, max 140 units, 0 when closed
                                                radius: root.s(6); color: root.surface0; clip: true // 6-unit radius; surface0; clips
                                                border.color: root.surface1; border.width: kbRowRect.isDispOpen ? 1 : 0 // Border when open
                                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } } // Animated height
                                                ListView {                        // Scrollable list of dispatcher options
                                                    anchors.fill: parent; model: root.dispatchers; interactive: true // Fills parent; uses dispatchers model; scrollable
                                                    opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0 // Visible when expanded
                                                    ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded } // Scrollbar when needed
                                                    delegate: Rectangle {         // Individual dispatcher option
                                                        width: parent.width; height: root.s(26) // Full width; 26-unit height
                                                        color: dispItemMa.containsMouse ? Qt.alpha(root.peach, 0.12) : "transparent" // Peach hover highlight
                                                        Behavior on color { ColorAnimation { duration: 120 } } // Quick hover
                                                        Text {                    // Dispatcher option text
                                                            anchors.verticalCenter: parent.verticalCenter; x: root.s(8); text: modelData // Centered; 8-unit padding; option text
                                                            font.family: "JetBrains Mono"; font.pixelSize: root.s(11) // Monospace at 11 pixels
                                                            color: model.dispatcher === modelData ? root.peach : root.text // Peach if selected
                                                        }
                                                        MouseArea { id: dispItemMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { dynamicKeybindsModel.setProperty(outerIndex, "dispatcher", modelData); kbRowRect.isDispOpen = false; } } // Click to select dispatcher and close dropdown
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Command input
                                    Rectangle {                                   // Command text input field background
                                        Layout.fillWidth: true; Layout.preferredHeight: root.s(34) // Full width; 34-unit height
                                        radius: root.s(6)                         // 6-unit radius
                                        color: cmdInput.activeFocus ? Qt.alpha(root.peach, 0.08) : root.surface0 // Light peach tint when focused
                                        border.color: cmdInput.activeFocus ? root.peach : root.surface2 // Peach border when focused
                                        border.width: 1; z: 1                     // 1-pixel border; z-index 1
                                        Behavior on color { ColorAnimation { duration: 150 } } // Quick background transition
                                        Behavior on border.color { ColorAnimation { duration: 150 } } // Quick border transition
                                        TextInput {                               // Command text input
                                            id: cmdInput                          // Identifier "cmdInput"
                                            anchors.fill: parent; anchors.margins: root.s(9) // Fills parent with 9-unit margin
                                            verticalAlignment: TextInput.AlignVCenter // Vertically centered text
                                            text: model.command                   // Bound to model command
                                            font.family: "JetBrains Mono"; font.pixelSize: root.s(11) // Monospace at 11 pixels
                                            color: root.text; clip: true; selectByMouse: true // Normal text color; clips; mouse selectable
                                            onTextChanged: dynamicKeybindsModel.setProperty(outerIndex, "command", text) // Update model on text change
                                            Text {                                // Placeholder text
                                                text: "Command arguments..."      // Placeholder prompt
                                                color: root.subtext0              // Subtext color
                                                visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter // Visible when empty and unfocused
                                            }
                                        }
                                    }

                                    RowLayout {                                   // Horizontal layout for Delete and Save buttons
                                        Layout.fillWidth: true; Layout.alignment: Qt.AlignRight; spacing: root.s(8); z: 0 // Full width; right-aligned; 8-unit spacing; z-index 0
                                        // Delete button
                                        Rectangle {                               // Delete button background
                                            Layout.preferredWidth: root.s(80); Layout.preferredHeight: root.s(30); radius: root.s(7) // 80x30 button; 7-unit radius
                                            color: delMa.containsMouse ? root.red : root.surface1 // Red on hover, surface1 otherwise
                                            border.color: delMa.containsMouse ? root.red : Qt.alpha(root.red, 0.4) // Red border on hover, faded red otherwise
                                            border.width: 1                       // 1-pixel border
                                            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } } // Smooth button color
                                            Behavior on border.color { ColorAnimation { duration: 180 } } // Smooth border color
                                            RowLayout {                           // Horizontal layout for icon and text
                                                anchors.centerIn: parent; spacing: root.s(6) // Centered in button; 6-unit spacing
                                                Text {                            // Trash/delete icon
                                                    text: "󰆴"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(14) // Delete icon in Nerd Font
                                                    color: delMa.containsMouse ? root.base : root.red // White on hover, red otherwise
                                                    Behavior on color { ColorAnimation { duration: 180 } } // Smooth icon color
                                                }
                                                Text {                            // "Delete" label
                                                    text: "Delete"; font.family: "JetBrains Mono"; font.pixelSize: root.s(10); font.weight: Font.Medium // Medium monospace "Delete"
                                                    color: delMa.containsMouse ? root.base : root.red // White on hover, red otherwise
                                                    Behavior on color { ColorAnimation { duration: 180 } } // Smooth text color
                                                }
                                            }
                                            MouseArea {                           // Interactive area for delete
                                                id: delMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor // Full coverage; hover; hand cursor
                                                onClicked: {                      // Click handler
                                                    root.forceActiveFocus();      // Return focus to root
                                                    dynamicKeybindsModel.remove(outerIndex); // Remove this keybind from model
                                                    root.saveAllKeybinds();       // Save updated keybinds
                                                } 
                                            }
                                        }
                                        // Save button
                                        Rectangle {                               // Save button background
                                            Layout.preferredWidth: root.s(80); Layout.preferredHeight: root.s(30); radius: root.s(7) // 80x30 button; 7-unit radius
                                            color: rowSaveMa.containsMouse ? root.green : root.surface1 // Green on hover, surface1 otherwise
                                            border.color: rowSaveMa.containsMouse ? root.green : Qt.alpha(root.green, 0.4) // Green border on hover
                                            border.width: 1                       // 1-pixel border
                                            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } } // Smooth button color
                                            Behavior on border.color { ColorAnimation { duration: 180 } } // Smooth border
                                            RowLayout {                           // Horizontal layout for icon and text
                                                anchors.centerIn: parent; spacing: root.s(6) // Centered; 6-unit spacing
                                                Text {                            // Save/floppy disk icon
                                                    text: "󰆓"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(14) // Save icon in Nerd Font
                                                    color: rowSaveMa.containsMouse ? root.base : root.green // White on hover, green otherwise
                                                    Behavior on color { ColorAnimation { duration: 180 } } // Smooth icon color
                                                }
                                                Text {                            // "Save" label
                                                    text: "Save"; font.family: "JetBrains Mono"; font.pixelSize: root.s(10); font.weight: Font.Medium // Medium monospace "Save"
                                                    color: rowSaveMa.containsMouse ? root.base : root.green // White on hover, green otherwise
                                                    Behavior on color { ColorAnimation { duration: 180 } } // Smooth text color
                                                }
                                            }
                                            MouseArea {                           // Interactive area for save
                                                id: rowSaveMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor // Full coverage; hover; hand cursor
                                                onClicked: {                      // Click handler
                                                    let validationResult = root.validateKeybind(outerIndex, model.mods, model.key, model.dispatcher, model.command); // Validate the keybind
                                                    if (validationResult !== "VALID") {  // If validation fails
                                                        Quickshell.execDetached(["notify-send", "-u", "critical", "Keybind Error", validationResult]); // Show error notification
                                                        return;                   // Stop save
                                                    }
                                                    dynamicKeybindsModel.setProperty(outerIndex, "isEditing", false); // Close edit mode
                                                    root.forceActiveFocus();      // Return focus to root
                                                    root.saveAllKeybinds();       // Save all keybinds
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    } 


    // ── Main Panel ───────────────────────────────────────────────────────────── // Comment divider for the main settings panel sidebar
    Rectangle {                                                                   // Main panel background rectangle
        id: sidebarPanel                                                          // Identifier "sidebarPanel"
        anchors.fill: parent                                                      // Fills entire parent window
        color: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.97)               // Near-opaque base color (97% opacity)
        radius: root.s(16)                                                        // 16-unit corner radius for rounded panel corners
        border.width: 1                                                           // 1-pixel border
        border.color: Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.9) // Surface1 border at 90% opacity
        clip: true                                                                // Clips content to rounded corners

        Rectangle {                                                               // Left edge overlay to clean up border rendering at rounded corners
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: root.s(16) // Covers left 16 units
            color: sidebarPanel.color                                             // Same color as panel (hides border artifacts)
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: sidebarPanel.border.color } // Top 1px border line
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: sidebarPanel.border.color } // Bottom 1px border line
            Rectangle { anchors.left: parent.left; width: 1; height: parent.height; color: sidebarPanel.border.color } // Left 1px border line
        }

        Item {                                                                    // Container for the animated intro content
            anchors.fill: parent                                                  // Fills the panel
            opacity: introContent                                                 // Bound to intro animation progress (0.0 to 1.0)
            scale: 0.96 + (0.04 * introContent)                                   // Scales from 96% to 100% during intro animation
            transform: Translate { y: root.s(40) * (1.0 - introContent) }         // Slides up from 40 units below during intro

            ColumnLayout {                                                        // Main vertical layout for panel content
                anchors.fill: parent                                              // Fills the animated item
                anchors.margins: root.s(20)                                       // 20-unit margin from edges
                spacing: root.s(12)                                               // 12-unit vertical spacing between sections

                // ── Header ──────────────────────────────────────────────────── // Comment divider for header section
                RowLayout {                                                       // Horizontal layout for header (title and buttons)
                    Layout.fillWidth: true                                        // Full width
                    spacing: root.s(10)                                           // 10-unit spacing between items

                    Text {                                                        // "Settings" title
                        text: "Settings"; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: root.s(24) // Bold "Settings" heading at 24 pixels
                        color: root.text; Layout.alignment: Qt.AlignVCenter       // Normal text color; vertically centered
                    }

                    Rectangle {                                                   // Close search button (appears when searching)
                        visible: root.isSearchMode                                // Only visible when in search mode
                        width: root.s(26); height: root.s(26); radius: root.s(6)  // 26x26 button; 6-unit radius
                        color: closeSearchMa.containsMouse ? Qt.alpha(root.red, 0.15) : "transparent" // Red tint on hover
                        border.color: closeSearchMa.containsMouse ? root.red : "transparent"; border.width: 1 // Red border on hover
                        opacity: root.isSearchMode ? 1.0 : 0.0                   // Fades in/out with search mode
                        Behavior on opacity { NumberAnimation { duration: 200 } } // Smooth opacity transition
                        Behavior on color { ColorAnimation { duration: 150 } }    // Quick color transition
                        Text { anchors.centerIn: parent; text: "✕"; font.family: "Inter"; font.pixelSize: root.s(12); color: closeSearchMa.containsMouse ? root.red : root.subtext0; Behavior on color { ColorAnimation { duration: 150 } } } // Close "✕" icon; red on hover
                        MouseArea {                                               // Clickable area
                            id: closeSearchMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor // Full coverage; hover; hand cursor
                            onClicked: { root.isSearchMode = false; root.globalSearchQuery = ""; globalSearchInput.text = ""; root.searchHighlightIndex = -1; } // Exit search mode and reset
                        }
                    }

                    Item { Layout.fillWidth: true }                               // Spacer to push buttons to the right

                    // Save button
                    Rectangle {                                                   // Header save button (for app/weather tabs)
                        id: headerSaveBtn                                         // Identifier "headerSaveBtn"
                        visible: root.currentTab !== 2 && !root.isSearchMode      // Visible on tabs 0 and 1, hidden on keybinds tab and during search
                        opacity: visible ? 1.0 : 0.0                              // Fades with visibility
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } } // Smooth opacity

                        Layout.alignment: Qt.AlignVCenter                         // Vertically centered
                        Layout.preferredHeight: root.s(34)                        // 34-unit height
                        Layout.preferredWidth: saveBtnRow.implicitWidth + root.s(28) // Dynamic width based on content plus padding

                        radius: root.s(8)                                         // 8-unit corner radius
                        scale: headerSaveMa.pressed ? 0.94 : (headerSaveMa.containsMouse ? 1.03 : 1.0) // Shrinks on press, grows on hover
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } } // Bouncy scale animation

                        color: headerSaveMa.pressed                               // Background color based on interaction
                            ? Qt.darker(root.mauve, 1.15)                          // Darker mauve when pressed
                            : (headerSaveMa.containsMouse ? root.mauve : root.surface1) // Mauve on hover, surface1 default
                        border.color: headerSaveMa.containsMouse ? root.mauve : Qt.alpha(root.mauve, 0.4) // Mauve border on hover, faded default
                        border.width: 1                                           // 1-pixel border
                        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } } // Smooth button color
                        Behavior on border.color { ColorAnimation { duration: 180 } } // Smooth border color

                        RowLayout {                                               // Horizontal layout for save icon and text
                            id: saveBtnRow                                        // Identifier "saveBtnRow"
                            anchors.centerIn: parent                              // Centered in button
                            spacing: root.s(7)                                    // 7-unit spacing
                            Text {                                                // Save icon
                                text: "󰆓"                                        // Floppy disk/save icon
                                font.family: "Iosevka Nerd Font"                  // Nerd Font for icon
                                font.pixelSize: root.s(15)                        // 15-pixel icon
                                color: headerSaveMa.containsMouse ? root.base : root.mauve // White on hover, mauve default
                                Behavior on color { ColorAnimation { duration: 180 } } // Smooth icon color
                            }
                            Text {                                                // "Save" text
                                text: "Save"                                      // Save label
                                font.family: "JetBrains Mono"                     // Monospace font
                                font.weight: Font.Bold                            // Bold weight
                                font.pixelSize: root.s(12)                        // 12-pixel text
                                color: headerSaveMa.containsMouse ? root.base : root.text // White on hover, normal default
                                Behavior on color { ColorAnimation { duration: 180 } } // Smooth text color
                            }
                        }

                        MouseArea {                                               // Interactive area
                            id: headerSaveMa                                      // Identifier "headerSaveMa"
                            anchors.fill: parent                                  // Full coverage
                            hoverEnabled: true                                    // Hover tracking enabled
                            cursorShape: Qt.PointingHandCursor                    // Hand cursor
                            onClicked: {                                          // Click handler
                                if (root.currentTab === 0) Config.saveAppSettings(); // Save app settings on tab 0
                                else if (root.currentTab === 1) Config.saveWeatherConfig(); // Save weather config on tab 1
                            }
                        }
                    }

                    // Add button
                    Rectangle {                                                   // Add keybind button (only on keybinds tab)
                        id: headerAddBtn                                          // Identifier "headerAddBtn"
                        visible: root.currentTab === 2 && !root.isSearchMode      // Only visible on keybinds tab and not searching
                        opacity: visible ? 1.0 : 0.0                              // Fades with visibility
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } } // Smooth opacity

                        Layout.alignment: Qt.AlignVCenter                         // Vertically centered
                        Layout.preferredHeight: root.s(34)                        // 34-unit height
                        Layout.preferredWidth: addBtnRow.implicitWidth + root.s(28) // Dynamic width

                        radius: root.s(8)                                         // 8-unit radius
                        scale: headerAddMa.pressed ? 0.94 : (headerAddMa.containsMouse ? 1.03 : 1.0) // Interactive scale
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } } // Bouncy scale

                        color: headerAddMa.pressed                                // Background color
                            ? Qt.darker(root.peach, 1.15)                          // Darker peach when pressed
                            : (headerAddMa.containsMouse ? root.peach : root.surface1) // Peach on hover, surface1 default
                        border.color: headerAddMa.containsMouse ? root.peach : Qt.alpha(root.peach, 0.4) // Peach border on hover
                        border.width: 1                                           // 1-pixel border
                        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } } // Smooth color
                        Behavior on border.color { ColorAnimation { duration: 180 } } // Smooth border

                        RowLayout {                                               // Horizontal layout for add icon and text
                            id: addBtnRow                                         // Identifier "addBtnRow"
                            anchors.centerIn: parent                              // Centered
                            spacing: root.s(7)                                    // 7-unit spacing
                            Text {                                                // Plus icon
                                text: "+"                                         // Plus sign
                                font.family: "JetBrains Mono"                     // Monospace
                                font.weight: Font.Bold                            // Bold
                                font.pixelSize: root.s(15)                        // 15-pixel
                                color: headerAddMa.containsMouse ? root.base : root.peach // White on hover, peach default
                                Behavior on color { ColorAnimation { duration: 180 } } // Smooth color
                            }
                            Text {                                                // "Add" text
                                text: "Add"                                       // Add label
                                font.family: "JetBrains Mono"                     // Monospace
                                font.weight: Font.Bold                            // Bold
                                font.pixelSize: root.s(12)                        // 12-pixel
                                color: headerAddMa.containsMouse ? root.base : root.text // White on hover, normal default
                                Behavior on color { ColorAnimation { duration: 180 } } // Smooth color
                            }
                        }

                        MouseArea {                                               // Interactive area
                            id: headerAddMa                                       // Identifier "headerAddMa"
                            anchors.fill: parent                                  // Full coverage
                            hoverEnabled: true                                    // Hover tracking
                            cursorShape: Qt.PointingHandCursor                    // Hand cursor
                            onClicked: {                                          // Click handler
                                dynamicKeybindsModel.append({ type: "bind", mods: "", key: "", dispatcher: "exec", command: "", isEditing: true }); // Add new keybind entry with defaults
                                scrollTimer.start();                              // Start timer to scroll to new entry
                            }
                        }
                    }
                }

                // ── Search bar ──────────────────────────────────────────────── // Comment divider for global search bar
                Rectangle {                                                       // Search bar background
                    Layout.fillWidth: true; Layout.preferredHeight: root.s(40); radius: root.s(10) // Full width; 40-unit height; 10-unit radius
                    color: root.isSearchMode                                      // Background color
                        ? Qt.alpha(root.sapphire, 0.06)                            // Very subtle sapphire tint when searching
                        : (globalSearchBarMa.containsMouse ? Qt.alpha(root.surface1, 0.6) : Qt.alpha(root.surface0, 0.5)) // Surface1 on hover, surface0 default (both semi-transparent)
                    border.color: root.isSearchMode ? root.sapphire : (globalSearchBarMa.containsMouse ? root.surface2 : root.surface1) // Sapphire border when searching, surface2 on hover
                    border.width: root.isSearchMode ? 2 : 1                       // 2px border when searching, 1px otherwise
                    Behavior on color { ColorAnimation { duration: 200 } }        // Smooth background color
                    Behavior on border.color { ColorAnimation { duration: 200 } } // Smooth border color
                    Behavior on border.width { NumberAnimation { duration: 150 } } // Smooth border width

                    RowLayout {                                                   // Horizontal layout for search icon and input
                        anchors.fill: parent; anchors.leftMargin: root.s(11); anchors.rightMargin: root.s(11); spacing: root.s(9) // Fills with 11-unit horizontal margins; 9-unit spacing
                        Text {                                                    // Search/magnifying glass icon
                            text: "󰍉"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(15) // Search icon in Nerd Font
                            color: root.isSearchMode ? root.sapphire : root.subtext0 // Sapphire when searching, subtext0 default
                            Behavior on color { ColorAnimation { duration: 200 } } // Smooth icon color
                            MouseArea { anchors.fill: parent; anchors.margins: -root.s(6); hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.isSearchMode = true; globalSearchInput.forceActiveFocus(); } } // Click icon to enter search mode (expanded hit area)
                        }
                        TextInput {                                               // Search text input field
                            id: globalSearchInput                                 // Identifier "globalSearchInput"
                            Layout.fillWidth: true; Layout.fillHeight: true; verticalAlignment: TextInput.AlignVCenter // Fills space; vertically centered text
                            font.family: "JetBrains Mono"; font.pixelSize: root.s(12); color: root.text; clip: true; selectByMouse: true // Monospace at 12px; normal text; clips; selectable
                            Text {                                                // Placeholder text
                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter // Left-aligned; vertically centered
                                text: root.isSearchMode ? "Search settings & keybinds..." : "Search" // Context-aware placeholder
                                color: Qt.alpha(root.subtext0, 0.45)             // Faded subtext
                                visible: !globalSearchInput.text && !globalSearchInput.activeFocus // Visible when empty and unfocused
                                font.family: "JetBrains Mono"; font.pixelSize: root.s(12) // Matching font
                            }
                            onActiveFocusChanged: { if (activeFocus && !root.isSearchMode) root.isSearchMode = true; } // Enter search mode when field gains focus
                            onTextChanged: { root.globalSearchQuery = text; if (!root.isSearchMode && text.length > 0) root.isSearchMode = true; } // Update search query; enter search mode when typing
                            Keys.onEscapePressed: { root.isSearchMode = false; root.globalSearchQuery = ""; text = ""; root.searchHighlightIndex = -1; root.forceActiveFocus(); } // Escape exits search and resets
                            Keys.onDownPressed: (event) => {                      // Down arrow navigates search results
                                root.forceActiveFocus();                           // Focus root for keyboard handling
                                let total = root.searchResultItems.length;        // Get total number of search results
                                if (total === 0) { event.accepted = true; return; } // No results, ignore
                                root.searchHighlightIndex = root.searchHighlightIndex < total - 1 ? root.searchHighlightIndex + 1 : 0; // Move highlight down, wrap to top
                                root.scrollSearchHighlightIntoView(root.searchHighlightIndex); // Scroll to show highlighted item
                                event.accepted = true;                            // Mark event handled
                            }
                            Keys.onUpPressed: (event) => {                        // Up arrow navigates search results
                                root.forceActiveFocus();                           // Focus root
                                let total = root.searchResultItems.length;        // Total results
                                if (total === 0) { event.accepted = true; return; } // No results
                                root.searchHighlightIndex = root.searchHighlightIndex > 0 ? root.searchHighlightIndex - 1 : (root.searchHighlightIndex === 0 ? total - 1 : total - 1); // Move up, wrap to bottom
                                root.scrollSearchHighlightIntoView(root.searchHighlightIndex); // Scroll to item
                                event.accepted = true;                            // Mark handled
                            }
                            Keys.onReturnPressed: (event) => {                    // Enter activates highlighted result
                                if (root.searchHighlightIndex >= 0) { root.activateSearchHighlight(); event.accepted = true; } // Activate if valid index
                            }
                            Keys.onEnterPressed: (event) => {                     // Numpad Enter also activates
                                if (root.searchHighlightIndex >= 0) { root.activateSearchHighlight(); event.accepted = true; }
                            }
                        }
                        Rectangle {                                               // Clear search button
                            visible: root.isSearchMode && globalSearchInput.text.length > 0; width: root.s(20); height: root.s(20); radius: root.s(4) // Visible when searching with text; 20x20; 4-unit radius
                            color: clearSearchBtnMa.containsMouse ? Qt.alpha(root.red, 0.15) : "transparent" // Red tint on hover
                            border.color: clearSearchBtnMa.containsMouse ? root.red : "transparent"; border.width: 1 // Red border on hover
                            Behavior on color { ColorAnimation { duration: 150 } } // Quick color
                            Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: root.s(10); color: clearSearchBtnMa.containsMouse ? root.red : Qt.alpha(root.subtext0, 0.6); Behavior on color { ColorAnimation { duration: 150 } } } // Close icon
                            MouseArea { id: clearSearchBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { globalSearchInput.text = ""; globalSearchInput.forceActiveFocus(); } } // Clear text and refocus
                        }
                    }
                    MouseArea { id: globalSearchBarMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: !root.isSearchMode; onClicked: { root.isSearchMode = true; globalSearchInput.forceActiveFocus(); } } // Click bar to enter search mode when not already searching
                }

                // ── Tab bar ─────────────────────────────────────────────────── // Comment divider for tab navigation bar
                Item {                                                            // Tab bar container
                    Layout.fillWidth: true                                        // Full width
                    Layout.preferredHeight: root.s(38)                            // 38-unit height
                    visible: !root.isSearchMode                                   // Hidden during search
                    opacity: root.isSearchMode ? 0.0 : 1.0                        // Fades out during search
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } } // Smooth opacity

                    // Background track
                    Rectangle {                                                   // Tab bar background
                        anchors.fill: parent; radius: root.s(10)                  // Fills parent; 10-unit radius
                        color: root.surface0; border.color: root.surface1; border.width: 1 // Dark surface with subtle border
                    }

                    // Morphing pill
                    Rectangle {                                                   // Animated active tab indicator pill
                        id: tabHighlightPill                                      // Identifier "tabHighlightPill"
                        y: root.s(3)                                              // 3 units from top
                        height: root.s(32)                                        // 32-unit height
                        radius: root.s(8)                                         // 8-unit corner radius

                        property color c0: root.teal                              // Color for tab 0 (App settings)
                        property color c1: root.blue                              // Color for tab 1 (Weather)
                        property color c2: root.peach                             // Color for tab 2 (Keybinds)
                        property color targetColor: {                             // Computed target color based on current tab
                            if (root.currentTab === 0) return c0;                 // Teal for tab 0
                            if (root.currentTab === 1) return c1;                 // Blue for tab 1
                            return c2;                                            // Peach for tab 2
                        }
                        color: targetColor                                        // Set pill color to target
                        Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo } } // Smooth color transition when tab changes

                        property int prevTab: 0                                   // Tracks previous tab for direction-aware animation
                        property int curTab: root.currentTab                      // Current tab index

                        onCurTabChanged: {                                        // When tab changes
                            if (curTab > prevTab) {                               // Moving right
                                tabRightAnim.duration = 200; tabLeftAnim.duration = 350; // Faster right edge, slower left edge for stretch effect
                            } else if (curTab < prevTab) {                        // Moving left
                                tabLeftAnim.duration = 200; tabRightAnim.duration = 350; // Faster left edge, slower right edge
                            }
                            prevTab = curTab;                                     // Update previous tab
                        }

                        property real tabW: (parent.width - root.s(6)) / 3        // Width of each tab section
                        property real targetLeft: root.s(3) + curTab * tabW       // Target left position based on current tab
                        property real targetRight: targetLeft + tabW              // Target right position

                        property real actualLeft: targetLeft                      // Animated left position
                        property real actualRight: targetRight                    // Animated right position

                        Behavior on actualLeft { NumberAnimation { id: tabLeftAnim; duration: 250; easing.type: Easing.OutExpo } } // Animate left edge
                        Behavior on actualRight { NumberAnimation { id: tabRightAnim; duration: 250; easing.type: Easing.OutExpo } } // Animate right edge

                        x: actualLeft                                             // Set x from animated left position
                        width: actualRight - actualLeft                           // Set width from difference of animated positions
                    }

                    Row {                                                         // Row of tab buttons overlaid on the background
                        anchors.fill: parent                                      // Fills parent
                        anchors.margins: root.s(3)                                // 3-unit margin
                        spacing: 0                                                // No spacing (tabs touch each other)

                        Repeater {                                                // Creates tabs from tab names model
                            model: root.tabNames.length                           // Number of tabs
                            Item {                                                // Individual tab item
                                width: (parent.width) / 3                         // Equal width for each tab
                                height: parent.height                             // Full height

                                property bool isActive: root.currentTab === index // True when this tab is selected

                                RowLayout {                                       // Horizontal layout for icon and label
                                    anchors.centerIn: parent                      // Centered in tab
                                    spacing: root.s(7)                            // 7-unit spacing
                                    Text {                                        // Tab icon
                                        text: root.tabIcons[index]                // Icon from tabIcons array
                                        font.family: "Iosevka Nerd Font"          // Nerd Font for icons
                                        font.pixelSize: root.s(14)                // 14-pixel icon
                                        color: isActive ? root.base : root.subtext0 // White when active, subtext0 default
                                        Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutExpo } } // Smooth icon color
                                    }
                                    Text {                                        // Tab label
                                        text: root.tabNames[index]                // Label from tabNames array
                                        font.family: "JetBrains Mono"             // Monospace font
                                        font.weight: isActive ? Font.Bold : Font.Medium // Bold when active, medium default
                                        font.pixelSize: root.s(12)                // 12-pixel text
                                        color: isActive ? root.base : root.subtext0 // White when active, subtext0 default
                                        Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutExpo } } // Smooth text color
                                    }
                                }

                                MouseArea {                                       // Clickable area for tab switching
                                    anchors.fill: parent                          // Full coverage
                                    hoverEnabled: true                            // Hover tracking
                                    cursorShape: Qt.PointingHandCursor            // Hand cursor
                                    onClicked: { root.currentTab = index; root.clearHighlight(); } // Switch to this tab and clear any box highlight
                                }
                            }
                        }
                    }
                }

                // ── Content area ────────────────────────────────────────────── // Comment divider for main content area
                Item {                                                            // Content area container
                    Layout.fillWidth: true; Layout.fillHeight: true               // Fills all remaining space

                    // Search results
                    Flickable {                                                   // Scrollable container for search results
                        id: searchResultsFlickable                                // Identifier "searchResultsFlickable"
                        anchors.fill: parent; contentWidth: width                 // Fills parent; content width matches
                        contentHeight: searchResultsCol.implicitHeight + root.s(40) // Content height plus 40-unit padding
                        boundsBehavior: Flickable.StopAtBounds; clip: true        // Stops at bounds; clips content
                        visible: root.isSearchMode                                // Only visible during search
                        opacity: root.isSearchMode ? 1.0 : 0.0                    // Fades with search mode
                        Behavior on opacity { NumberAnimation { duration: 250 } } // Smooth fade

                        MouseArea { anchors.fill: parent; onClicked: root.clearHighlight(); z: -1 } // Click background to clear highlights

                        ColumnLayout {                                            // Vertical layout for search result items
                            id: searchResultsCol; width: parent.width; spacing: root.s(8) // Full width; 8-unit spacing

                            Item {                                                // Empty state placeholder
                                Layout.fillWidth: true; Layout.preferredHeight: root.s(80) // Full width; 80-unit height
                                visible: root.globalSearchQuery.trim() === ""     // Only visible when search is empty
                                ColumnLayout {                                    // Centered empty state content
                                    anchors.centerIn: parent; spacing: root.s(8)  // Centered; 8-unit spacing
                                    Text { Layout.alignment: Qt.AlignHCenter; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(30); color: Qt.alpha(root.subtext0, 0.25) } // Empty/blank icon placeholder
                                    Text { Layout.alignment: Qt.AlignHCenter; text: "Type to search settings & keybinds..."; font.family: "JetBrains Mono"; font.pixelSize: root.s(12); color: Qt.alpha(root.subtext0, 0.35) } // Instruction text
                                }
                            }

                            Repeater {                                            // Creates search result cards for settings
                                id: settingsCardRepeater                          // Identifier "settingsCardRepeater"
                                model: root.allSettingsCards.length               // Model based on number of settings cards
                                delegate: Item {                                  // Delegate for each settings card result
                                    property var card: root.allSettingsCards[index] // Reference to the card data
                                    property bool matches: root.globalSearchMatches(card, root.globalSearchQuery) // True if card matches search query
                                    property int searchListIndex: {               // Position in flattened search results list
                                        let pos = 0;                              // Start counter
                                        for (let i = 0; i < root.searchResultItems.length; i++) { // Iterate all search results
                                            if (root.searchResultItems[i].kind === "card" && root.searchResultItems[i].cardIndex === index) { pos = i; break; } // Find this card's position
                                        }
                                        return pos;                               // Return position
                                    }
                                    property bool isSearchHighlighted: matches && root.searchHighlightIndex === searchListIndex && root.searchHighlightIndex >= 0 // True when this card is highlighted in search
                                    Layout.fillWidth: true                        // Full width
                                    Layout.preferredHeight: matches ? root.s(58) : 0 // 58-unit height when matching, 0 when not (collapses)
                                    visible: matches; opacity: matches ? 1.0 : 0.0; clip: true // Visible only when matching; fades; clips
                                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } } // Animated height for appearing/disappearing
                                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } } // Smooth opacity

                                    Rectangle {                                   // Card background
                                        anchors.fill: parent; radius: root.s(10)  // Fills; 10-unit radius
                                        color: isSearchHighlighted                // Background based on state
                                            ? root.surface1                       // Surface1 when highlighted
                                            : (searchCardMa.containsMouse ? root.surface1 : root.surface0) // Surface1 on hover, surface0 default
                                        border.color: isSearchHighlighted ? root[card.color] : (searchCardMa.containsMouse ? root[card.color] : root.surface1) // Accent border when highlighted/hovered
                                        border.width: isSearchHighlighted ? 2 : 1 // 2px when highlighted
                                        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } } // Smooth color
                                        Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } } // Smooth border

                                        RowLayout {                               // Horizontal layout for card content
                                            anchors.fill: parent; anchors.margins: root.s(12); spacing: root.s(12) // Fills with 12-unit margin and spacing
                                            Rectangle {                           // Card icon background
                                                width: root.s(32); height: root.s(32); radius: root.s(8) // 32x32 icon box; 8-unit radius
                                                color: Qt.alpha(root[card.color], 0.15) // Tinted background
                                                border.color: Qt.alpha(root[card.color], 0.3); border.width: 1 // Tinted border
                                                Text {                            // Card icon
                                                    anchors.centerIn: parent; text: card.icon; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(15) // Centered Nerd Font icon
                                                    color: root[card.color]       // Accent color
                                                }
                                            }
                                            ColumnLayout {                        // Vertical layout for card text
                                                Layout.fillWidth: true; spacing: root.s(2) // Fills width; 2-unit spacing
                                                Text {                            // Card title
                                                    text: card.label; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(13) // Card label in medium Inter
                                                    color: isSearchHighlighted ? root[card.color] : root.text; Layout.fillWidth: true // Accent when highlighted, normal otherwise
                                                    Behavior on color { ColorAnimation { duration: 200 } } // Smooth color
                                                }
                                                Text {                            // Card description
                                                    text: card.desc; font.family: "Inter"; font.pixelSize: root.s(10) // Description text
                                                    color: Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true // Faded subtext
                                                }
                                            }
                                            Rectangle {                           // Tab badge showing which tab this setting is on
                                                height: root.s(20); width: tabBadgeText.implicitWidth + root.s(12); radius: root.s(10) // Dynamic width; pill shape
                                                color: Qt.alpha(root[root.tabColors[card.tab]], 0.15) // Tinted background
                                                border.color: Qt.alpha(root[root.tabColors[card.tab]], 0.4); border.width: 1 // Tinted border
                                                Text {                            // Tab name in badge
                                                    id: tabBadgeText; anchors.centerIn: parent; text: root.tabNames[card.tab] // Tab name
                                                    font.family: "JetBrains Mono"; font.pixelSize: root.s(9) // Small monospace
                                                    color: root[root.tabColors[card.tab]] // Tab accent color
                                                }
                                            }
                                            Text {                                // Arrow indicator
                                                text: "›"; font.family: "Inter"; font.pixelSize: root.s(18) // Right-pointing arrow
                                                color: isSearchHighlighted ? root[card.color] : (searchCardMa.containsMouse ? root[card.color] : root.subtext0) // Accent when highlighted/hovered
                                                Behavior on color { ColorAnimation { duration: 150 } } // Quick color
                                            }
                                        }
                                        MouseArea {                               // Clickable area
                                            id: searchCardMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor // Full coverage; hover; hand cursor
                                            onClicked: {                          // Click handler to jump to this setting
                                                jumpToSettingTimer.targetTab = card.tab; // Set target tab
                                                jumpToSettingTimer.targetBox = card.boxIndex; // Set target box
                                                jumpToSettingTimer.start();       // Start timer (delayed execution)
                                                root.currentTab = card.tab;       // Switch to target tab
                                                if (card.tab === 0) root.tab0Loaded = true; // Mark tab 0 as loaded
                                                else if (card.tab === 1) root.tab1Loaded = true; // Mark tab 1 as loaded
                                                else if (card.tab === 2) root.tab2Loaded = true; // Mark tab 2 as loaded
                                                root.isSearchMode = false;        // Exit search mode
                                                root.forceActiveFocus();           // Focus root
                                                globalSearchInput.text = "";       // Clear search input
                                                root.globalSearchQuery = "";       // Clear search query
                                            }
                                        }
                                    }
                                }
                            }

                            Item {                                                // Section header for keybind results
                                Layout.fillWidth: true                            // Full width
                                Layout.preferredHeight: (root.globalSearchQuery.trim() !== "" && root.matchingKeybindIndices.length > 0) ? root.s(30) : 0 // 30-unit height when keybinds match, 0 otherwise
                                visible: root.globalSearchQuery.trim() !== "" && root.matchingKeybindIndices.length > 0 // Visible when query exists and keybinds found
                                opacity: visible ? 1.0 : 0.0; clip: true          // Fades; clips
                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } } // Animated height
                                Behavior on opacity { NumberAnimation { duration: 200 } } // Smooth opacity
                                RowLayout {                                       // Horizontal layout for header content
                                    anchors.fill: parent; anchors.leftMargin: root.s(4); spacing: root.s(8) // Fills with 4-unit left margin; 8-unit spacing
                                    Rectangle { width: root.s(3); height: root.s(12); radius: root.s(2); color: root.peach } // Small peach accent bar
                                    Text { text: "Keybinds (" + root.matchingKeybindIndices.length + " match" + (root.matchingKeybindIndices.length !== 1 ? "es" : "") + ")"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(10); color: root.peach } // "Keybinds (N matches)" header
                                }
                            }

                            Repeater {                                            // Creates search result items for keybinds
                                id: keybindResultRepeater                         // Identifier "keybindResultRepeater"
                                model: root.matchingKeybindIndices.length         // Model based on number of matching keybinds
                                delegate: Item {                                  // Delegate for each keybind result
                                    property int kbIndex: root.matchingKeybindIndices[index] // Index in keybinds model
                                    property var kbItem: dynamicKeybindsModel.get(kbIndex) // The actual keybind item data
                                    property int searchListIndex: {               // Position in flattened search results
                                        let nCards = 0;                            // Count of matching cards
                                        for (let i = 0; i < root.allSettingsCards.length; i++) { // Count matching settings cards
                                            if (root.globalSearchMatches(root.allSettingsCards[i], root.globalSearchQuery)) nCards++;
                                        }
                                        return nCards + index;                    // Keybind position after all cards
                                    }
                                    property bool isSearchHighlighted: root.searchHighlightIndex === searchListIndex && root.searchHighlightIndex >= 0 // True when highlighted
                                    Layout.fillWidth: true                        // Full width
                                    Layout.preferredHeight: root.globalSearchQuery.trim() !== "" ? root.s(54) : 0 // 54-unit height when query exists
                                    visible: root.globalSearchQuery.trim() !== ""; opacity: visible ? 1.0 : 0.0; clip: true // Visible when query exists
                                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } } // Animated height
                                    Behavior on opacity { NumberAnimation { duration: 200 } } // Smooth opacity

                                    Rectangle {                                   // Keybind result card background
                                        anchors.fill: parent; radius: root.s(10)  // Fills; 10-unit radius
                                        color: isSearchHighlighted ? root.surface1 : (kbResultMa.containsMouse ? root.surface1 : root.surface0) // Highlighted/hovered/default
                                        border.color: isSearchHighlighted ? root.peach : (kbResultMa.containsMouse ? root.peach : root.surface1) // Peach accent when highlighted/hovered
                                        border.width: isSearchHighlighted ? 2 : 1 // 2px when highlighted
                                        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } } // Smooth color
                                        Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } } // Smooth border

                                        RowLayout {                               // Horizontal layout for keybind card
                                            anchors.fill: parent; anchors.margins: root.s(11); spacing: root.s(11) // Fills with 11-unit margin and spacing
                                            Rectangle {                           // Keybind icon background
                                                width: root.s(32); height: root.s(32); radius: root.s(8) // 32x32; 8-unit radius
                                                color: Qt.alpha(root.peach, 0.12) // Peach-tinted
                                                border.color: Qt.alpha(root.peach, 0.25); border.width: 1 // Peach-tinted border
                                                Text {                            // Keyboard icon
                                                    anchors.centerIn: parent; text: "󰌌"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(15) // Keyboard icon
                                                    color: root.peach             // Peach color
                                                }
                                            }
                                            ColumnLayout {                        // Vertical layout for keybind info
                                                Layout.fillWidth: true; spacing: root.s(3) // Fills width; 3-unit spacing
                                                Row {                             // Row for modifier and key badges
                                                    spacing: root.s(4)            // 4-unit spacing
                                                    Rectangle {                   // Modifier badge
                                                        width: modsT.implicitWidth + root.s(8); height: root.s(18); radius: root.s(4) // Dynamic width; 18px height
                                                        color: root.surface1      // Surface1
                                                        border.color: root.surface2; border.width: 1 // Subtle border
                                                        visible: kbItem && kbItem.mods !== "" // Visible when mods exist
                                                        Text {                    // Modifier text
                                                            id: modsT; anchors.centerIn: parent; text: kbItem ? kbItem.mods : "" // Modifier string
                                                            font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(8) // Bold tiny monospace
                                                            color: root.peach     // Peach
                                                        }
                                                    }
                                                    Text {                        // Plus separator
                                                        text: "+"; font.family: "JetBrains Mono"; font.pixelSize: root.s(9) // Plus sign
                                                        color: root.overlay0      // Muted
                                                        visible: kbItem && kbItem.mods !== "" && kbItem.key !== ""; anchors.verticalCenter: parent.verticalCenter // Visible when both exist
                                                    }
                                                    Rectangle {                   // Key badge
                                                        width: keyT.implicitWidth + root.s(8); height: root.s(18); radius: root.s(4) // Dynamic width; 18px height
                                                        color: root.surface1      // Surface1
                                                        border.color: root.surface2; border.width: 1 // Subtle border
                                                        visible: kbItem && kbItem.key !== "" // Visible when key exists
                                                        Text {                    // Key text
                                                            id: keyT; anchors.centerIn: parent; text: kbItem ? kbItem.key : "" // Key string
                                                            font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(8) // Bold tiny monospace
                                                            color: root.peach     // Peach
                                                        }
                                                    }
                                                }
                                                Text {                            // Command text
                                                    text: kbItem ? (kbItem.dispatcher + " " + kbItem.command).trim() : "" // Dispatcher + command
                                                    font.family: "JetBrains Mono"; font.pixelSize: root.s(9) // Small monospace
                                                    color: isSearchHighlighted ? root.peach : Qt.alpha(root.subtext0, 0.7) // Peach when highlighted
                                                    elide: Text.ElideRight; Layout.fillWidth: true // Elide if too long
                                                    Behavior on color { ColorAnimation { duration: 200 } } // Smooth color
                                                }
                                            }
                                            Rectangle {                           // "Keybinds" badge
                                                height: root.s(20); width: kbBadgeText.implicitWidth + root.s(12); radius: root.s(10) // Dynamic width; pill
                                                color: Qt.alpha(root.peach, 0.12) // Peach-tinted
                                                border.color: Qt.alpha(root.peach, 0.35); border.width: 1 // Peach border
                                                Text {                            // Badge text
                                                    id: kbBadgeText; anchors.centerIn: parent; text: "Keybinds" // "Keybinds" label
                                                    font.family: "JetBrains Mono"; font.pixelSize: root.s(9) // Small monospace
                                                    color: root.peach             // Peach
                                                }
                                            }
                                            Text {                                // Arrow indicator
                                                text: "›"; font.family: "Inter"; font.pixelSize: root.s(18) // Right arrow
                                                color: isSearchHighlighted ? root.peach : (kbResultMa.containsMouse ? root.peach : root.subtext0) // Peach when highlighted/hovered
                                                Behavior on color { ColorAnimation { duration: 150 } } // Quick color
                                            }
                                        }
                                        MouseArea {                               // Interactive clickable area for the keybind search result card
                                            id: kbResultMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor // Covers entire card; enables hover detection; changes cursor to pointing hand on hover
                                            onClicked: {                          // Code executed when user clicks this keybind search result
                                                jumpToSettingTimer.targetTab = 2; // Sets the target tab for the delayed jump to tab index 2 (Keybinds tab)
                                                jumpToSettingTimer.targetBox = kbIndex; // Sets the specific keybind index to highlight after jumping
                                                jumpToSettingTimer.start();       // Starts the timer that will execute the jump after a short delay
                                                root.currentTab = 2;              // Immediately switches the visible tab to the Keybinds tab (index 2)
                                                root.tab2Loaded = true;           // Marks keybinds tab content as loaded so its Loader activates
                                                root.isSearchMode = false;        // Exits search mode, hiding search results and showing normal tab content
                                                root.forceActiveFocus();           // Forces keyboard focus back to the root item
                                                globalSearchInput.text = "";       // Clears the search input field text
                                                root.globalSearchQuery = "";       // Resets the global search query string to empty
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Loader {                                                      // Dynamic loader component that instantiates tab content on demand
                        id: generalLoader                                         // Unique identifier "generalLoader" for referencing this loader
                        anchors.fill: parent                                      // Makes the loader fill the entire parent content area
                        active: root.tab0Loaded && Config.dataReady               // Only loads the component when tab 0 has been requested AND config data is ready (lazy loading)
                        sourceComponent: generalTabComponent                      // Specifies which QML component to instantiate when active (the general/app settings tab)
                        visible: root.currentTab === 0 && !root.isSearchMode      // Only visible when tab 0 is selected and search mode is not active
                        opacity: visible ? 1.0 : 0.0                              // Full opacity when visible, fully transparent when hidden
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } } // Smooth fade transition over 250ms with exponential ease-out
                        function focusLangInput() { if (item) item.focusLangInput(); } // Bridge function: calls focusLangInput() on the loaded component if it exists
                        function focusWpDirInput() { if (item) item.focusWpDirInput(); } // Bridge function: calls focusWpDirInput() on the loaded component if it exists
                        function layoutListIncrementIndex() { if (item) item.layoutListIncrementIndex(); } // Bridge function: navigates layout dropdown selection down
                        function layoutListDecrementIndex() { if (item) item.layoutListDecrementIndex(); } // Bridge function: navigates layout dropdown selection up
                        function acceptLayoutSelection() { if (item) item.acceptLayoutSelection(); } // Bridge function: confirms current layout dropdown selection
                        function scrollTo(y) { if (item) item.scrollTo(y); }      // Bridge function: scrolls the loaded tab content to a specific Y coordinate
                        function scrollToBox(y) { if (item) item.scrollToBox(y); } // Bridge function: scrolls to make a specific settings box visible
                    }

                    Loader {                                                      // Dynamic loader for the weather settings tab content
                        id: weatherLoader                                         // Unique identifier "weatherLoader"
                        anchors.fill: parent                                      // Fills the entire parent content area
                        active: root.tab1Loaded && Config.dataReady               // Activates when tab 1 has been requested AND config data is available
                        sourceComponent: weatherTabComponent                      // Loads the weatherTabComponent when active
                        visible: root.currentTab === 1 && !root.isSearchMode      // Only visible when weather tab (index 1) is selected and not searching
                        opacity: visible ? 1.0 : 0.0                              // Full opacity when visible, transparent otherwise
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } } // Smooth 250ms fade animation
                        function focusApiKey() { if (item) item.focusApiKey(); }  // Bridge function: focuses the API key input field in weather tab
                        function focusCityId() { if (item) item.focusCityId(); }  // Bridge function: focuses the City ID input field in weather tab
                        function scrollTo(y) { if (item) item.scrollTo(y); }      // Bridge function: scrolls weather tab to specific Y position
                        function scrollToBox(y) { if (item) item.scrollToBox(y); } // Bridge function: scrolls to make a weather settings box visible
                    }

                    Loader {                                                      // Dynamic loader for the keybinds settings tab content
                        id: keybindLoader                                         // Unique identifier "keybindLoader"
                        anchors.fill: parent                                      // Fills the entire parent content area
                        active: root.tab2Loaded && Config.dataReady               // Activates when keybinds tab (index 2) has been requested AND config is ready
                        sourceComponent: keybindTabComponent                      // Loads the keybindTabComponent when active
                        visible: root.currentTab === 2 && !root.isSearchMode      // Only visible when keybinds tab is selected and not in search mode
                        opacity: visible ? 1.0 : 0.0                              // Full opacity when visible, transparent otherwise
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } } // Smooth fade transition
                        function scrollToBottom() { if (item) item.scrollToBottom(); } // Bridge function: scrolls keybinds list to the very bottom
                        function scrollTo(y) { if (item) item.scrollTo(y); }      // Bridge function: scrolls keybinds tab to specific Y coordinate
                        function scrollToBox(y) { if (item) item.scrollToBox(y); } // Bridge function: scrolls to make a specific keybind entry visible
                    }
                }
            }
        }
    }
}