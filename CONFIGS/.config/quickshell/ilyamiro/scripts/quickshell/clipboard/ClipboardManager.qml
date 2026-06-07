// import QtQuick
// import QtQuick.Window
// import QtQuick.Effects
// import QtQuick.Layouts
// import QtQuick.Controls
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
    
//     function s(val) { 
//         return scaler.s(val); 
//     }

//     MatugenColors { id: _theme }
    
//     readonly property color base: _theme.base
//     readonly property color crust: _theme.crust
//     readonly property color text: _theme.text
//     readonly property color subtext0: _theme.subtext0
//     readonly property color surface0: _theme.surface0
//     readonly property color surface1: _theme.surface1
//     readonly property color surface2: _theme.surface2
//     readonly property color mauve: _theme.mauve || "#cba6f7"
//     readonly property color blue: _theme.blue

//     property var allClips: []
    
//     // Pagination properties
//     property int currentOffset: 0
//     property int fetchLimit: 24 
//     property bool isLoading: false
//     property bool hasMore: true
    
//     // Global state
//     property int navDuration: 0
//     property bool previewMode: false
//     property bool previewAnimationDone: false
//     property string fullTextPreview: ""
//     property int pendingIndex: -1

//     property real layoutWidth: width
//     property real layoutHeight: height

//     // Startup state to prevent accordion layout shifts
//     property bool isInitialLoad: true

//     onPreviewModeChanged: {
//         if (!previewMode) {
//             fullTextPreview = "";
//             previewAnimationDone = false;
//         }
//     }

//     Process {
//         id: fullTextFetcher
//         running: false
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 window.fullTextPreview = this.text;
//             }
//         }
//     }

//     function updatePreviewText() {
//         window.fullTextPreview = "";
//         let item = clipModel.get(clipList.currentIndex);
//         if (item && item.type === "text") {
//             fullTextFetcher.command = ["cliphist", "decode", item.id.toString()];
//             fullTextFetcher.running = true;
//         }
//     }

//     Process {
//         id: clipFetcher
//         running: true
//         command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/clipboard/clip_fetcher.py", window.currentOffset, window.fetchLimit]
        
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 try {
//                     if (this.text && this.text.trim().length > 0) {
//                         let newItems = JSON.parse(this.text);
                        
//                         if (newItems.length < window.fetchLimit) {
//                             window.hasMore = false;
//                         }
                        
//                         if (window.currentOffset === 0) {
//                             let isDifferent = window.allClips.length !== newItems.length;
//                             if (!isDifferent) {
//                                 for (let i = 0; i < newItems.length; i++) {
//                                     if (window.allClips[i].id !== newItems[i].id) {
//                                         isDifferent = true;
//                                         break;
//                                     }
//                                 }
//                             }

//                             if (isDifferent || window.allClips.length === 0) {
//                                 window.allClips = newItems;
//                                 window.filterClips(searchInput.text);
//                             }
//                         } else {
//                             window.appendClips(newItems);
//                         }
//                     }
//                 } catch(e) {
//                     console.log("Error parsing clipboard list: ", e);
//                 } finally {
//                     window.isLoading = false;
//                     window.isInitialLoad = false;
//                 }
//             }
//         }
//     }

//     ListModel {
//         id: clipModel
//     }

//     function loadMore() {
//         if (isLoading || !hasMore) return;
//         isLoading = true;
//         currentOffset += fetchLimit;
//         clipFetcher.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/clipboard/clip_fetcher.py", window.currentOffset, window.fetchLimit];
//         clipFetcher.running = true;
//     }

//     function appendClips(newItems) {
//         let q = searchInput.text.toLowerCase();
//         for (let i = 0; i < newItems.length; i++) {
//             allClips.push(newItems[i]);
//             if (q === "" || newItems[i].type === "image" || newItems[i].content.toLowerCase().includes(q)) {
//                 clipModel.append(newItems[i]);
//             }
//         }
        
//         if (window.pendingIndex !== -1) {
//             if (window.pendingIndex < clipModel.count) {
//                 clipList.currentIndex = window.pendingIndex;
//             } else {
//                 clipList.currentIndex = clipModel.count - 1;
//             }
//             window.pendingIndex = -1;
//         }
//     }

//     function filterClips(query) {
//         clipList.currentIndex = -1;
//         clipList.positionViewAtBeginning();

//         let q = query.toLowerCase();
//         clipModel.clear();

//         for (let i = 0; i < allClips.length; i++) {
//             if (allClips[i].type === "image" || allClips[i].content.toLowerCase().includes(q)) {
//                 clipModel.append(allClips[i]);
//             }
//         }

//         if (clipModel.count > 0) {
//             clipList.currentIndex = 0;
//         }
//     }

//     function copyToClipboard(id) {
//         Quickshell.execDetached(["bash", "-c", "cliphist decode " + id + " | wl-copy"]);
//         Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
//     }

//     Timer {
//         id: focusTimer
//         interval: 50
//         running: true
//         repeat: false
//         onTriggered: searchInput.forceActiveFocus()
//     }

//     Connections {
//         target: window
//         function onVisibleChanged() {
//             if (window.visible) {
//                 if (window.allClips.length === 0) {
//                     window.isInitialLoad = true;
//                 }

//                 focusTimer.restart();
//                 introPhaseAnim.restart();
//                 window.navDuration = 0; 
//                 window.previewMode = false;
//                 window.previewAnimationDone = false;
//                 window.fullTextPreview = "";
//                 window.pendingIndex = -1;
                
//                 window.currentOffset = 0;
//                 window.hasMore = true;
//                 window.isLoading = true;
//                 clipFetcher.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/clipboard/clip_fetcher.py", 0, window.fetchLimit];
//                 clipFetcher.running = true;
//             } else {
//                 searchInput.text = "";
//                 window.pendingIndex = -1;
                
//                 window.filterClips("");
//                 if (clipModel.count > 0) {
//                     clipList.currentIndex = 0;
//                     clipList.positionViewAtBeginning();
//                 }
//             }
//         }
//     }

//     property real globalOrbitAngle: 0
//     NumberAnimation on globalOrbitAngle {
//         from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
//     }

//     property real introPhase: 0
//     NumberAnimation on introPhase {
//         id: introPhaseAnim
//         from: 0; to: 1; duration: 600; easing.type: Easing.OutExpo; running: true 
//     }

//     Rectangle {
//         id: mainBg
//         width: layoutWidth
        
//         property real searchHeight: window.s(65)
//         property real separatorHeight: 1
        
//         property int cols: 3
//         property real cellH: window.s(145) 
        
//         property real maxVisibleRows: 4 
//         property real visibleRows: maxVisibleRows
//         property real animatedListHeight: visibleRows * cellH
//         property real animatedMargins: window.s(20)

//         height: searchHeight + separatorHeight + animatedMargins + animatedListHeight

//         anchors.top: parent.top
//         anchors.horizontalCenter: parent.horizontalCenter

//         radius: window.s(16)
//         color: Qt.rgba(window.base.r, window.base.g, window.base.b, 1.0)
//         border.color: window.surface1
//         border.width: 1
//         clip: true

//         transform: Translate { y: (window.introPhase - 1) * window.s(60) }
//         opacity: window.introPhase

//         Rectangle {
//             width: parent.width * 0.8; height: width; radius: width / 2
//             x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)
//             y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)
//             opacity: 0.08
//             color: window.mauve
//             Behavior on color { ColorAnimation { duration: 1000 } }
//         }
        
//         Rectangle {
//             width: parent.width * 0.9; height: width; radius: width / 2
//             x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)
//             y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)
//             opacity: 0.06
//             color: window.blue
//             Behavior on color { ColorAnimation { duration: 1000 } }
//         }

//         Rectangle {
//             id: headerArea
//             anchors.top: parent.top
//             anchors.left: parent.left
//             anchors.right: parent.right
//             height: mainBg.searchHeight
//             color: "transparent"
            
//             RowLayout {
//                 anchors.fill: parent
//                 anchors.margins: window.s(15)
//                 anchors.leftMargin: window.s(20)
//                 anchors.rightMargin: window.s(20)
//                 spacing: window.s(15)

//                 Item {
//                     width: window.s(18)
//                     height: window.s(18)

//                     Text {
//                         anchors.centerIn: parent
//                         text: "󰅌"
//                         font.family: "Iosevka Nerd Font"
//                         font.pixelSize: window.s(18)
//                         color: searchInput.activeFocus ? window.mauve : window.subtext0
                        
//                         opacity: !window.previewMode ? 1 : 0
//                         scale: !window.previewMode ? 1 : 0.5
//                         rotation: !window.previewMode ? 0 : -90
                        
//                         Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
//                         Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
//                         Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
//                         Behavior on color { ColorAnimation { duration: 100 } }
//                     }

//                     Text {
//                         anchors.centerIn: parent
//                         text: "󰈈"
//                         font.family: "Iosevka Nerd Font"
//                         font.pixelSize: window.s(18)
//                         color: window.mauve
                        
//                         opacity: window.previewMode ? 1 : 0
//                         scale: window.previewMode ? 1 : 0.5
//                         rotation: window.previewMode ? 0 : 90
                        
//                         Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
//                         Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
//                         Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
//                     }
//                 }

//                 TextField {
//                     id: searchInput
//                     Layout.fillWidth: true
//                     Layout.fillHeight: true
//                     background: Item {} 
//                     color: window.text
//                     font.family: "JetBrains Mono"
//                     font.pixelSize: window.s(16)
                    
//                     placeholderText: "Search"
//                     placeholderTextColor: window.subtext0 
                    
//                     verticalAlignment: TextInput.AlignVCenter
//                     focus: true

//                     onTextChanged: {
//                         if (window.previewMode) { window.previewMode = false; }
//                         window.pendingIndex = -1;
//                         filterClips(text);
//                     }

//                     Keys.onTabPressed: {
//                         if (clipModel.count > 0) {
//                             window.previewMode = !window.previewMode;
//                             if (window.previewMode) {
//                                 window.updatePreviewText();
//                             }
//                         }
//                         event.accepted = true;
//                     }

//                     Keys.onRightPressed: {
//                         window.previewMode = false;
//                         window.navDuration = 250; 
//                         window.pendingIndex = -1;
                        
//                         let targetIdx = clipList.currentIndex + 1;
//                         if (targetIdx < clipModel.count) { 
//                             clipList.currentIndex = targetIdx; 
//                         } else if (window.hasMore) {
//                             window.pendingIndex = targetIdx;
//                             window.loadMore();
//                         }
//                         event.accepted = true;
//                     }
                    
//                     Keys.onLeftPressed: {
//                         window.previewMode = false;
//                         window.navDuration = 250;
//                         window.pendingIndex = -1;
                        
//                         if (clipList.currentIndex > 0) { clipList.currentIndex--; }
//                         event.accepted = true;
//                     }
                    
//                     Keys.onDownPressed: {
//                         if (window.previewMode && textPreviewFlickable.visible) {
//                             textPreviewFlickable.contentY = Math.min(textPreviewFlickable.contentY + window.s(60), Math.max(0, textPreviewFlickable.contentHeight - textPreviewFlickable.height));
//                         } else {
//                             window.previewMode = false;
//                             window.navDuration = 250;
//                             window.pendingIndex = -1;
                            
//                             let targetIdx = clipList.currentIndex + mainBg.cols;
//                             if (targetIdx < clipModel.count) {
//                                 clipList.currentIndex = targetIdx;
//                             } else if (window.hasMore) {
//                                 window.pendingIndex = targetIdx;
//                                 window.loadMore();
//                             } else {
//                                 clipList.currentIndex = clipModel.count - 1;
//                             }
//                         }
//                         event.accepted = true;
//                     }
                    
//                     Keys.onUpPressed: {
//                         if (window.previewMode && textPreviewFlickable.visible) {
//                             textPreviewFlickable.contentY = Math.max(textPreviewFlickable.contentY - window.s(60), 0);
//                         } else {
//                             window.previewMode = false;
//                             window.navDuration = 250;
//                             window.pendingIndex = -1;
                            
//                             if (clipList.currentIndex - mainBg.cols >= 0) { clipList.currentIndex -= mainBg.cols; }
//                         }
//                         event.accepted = true;
//                     }
                    
//                     Keys.onReturnPressed: {
//                         if (clipList.currentIndex >= 0 && clipList.currentIndex < clipModel.count) {
//                             copyToClipboard(clipModel.get(clipList.currentIndex).id);
//                         }
//                         event.accepted = true;
//                     }
                    
//                     Keys.onEscapePressed: {
//                         if (window.previewMode) {
//                             window.previewMode = false;
//                         } else {
//                             Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
//                         }
//                         event.accepted = true;
//                     }
//                 }
//             }
//         }

//         Rectangle {
//             id: separatorLine
//             anchors.top: headerArea.bottom
//             anchors.left: parent.left
//             anchors.right: parent.right
//             height: mainBg.separatorHeight
//             color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5)
//         }

//         GridView {
//             id: clipList
//             anchors.top: separatorLine.bottom
//             anchors.left: parent.left
//             anchors.right: parent.right
//             anchors.topMargin: mainBg.animatedMargins / 2
//             anchors.bottomMargin: mainBg.animatedMargins / 2
//             anchors.leftMargin: window.s(10)
//             anchors.rightMargin: window.s(10)
//             height: mainBg.animatedListHeight
            
//             clip: true
//             model: clipModel

// 	    cellWidth: Math.floor((mainBg.width - window.s(20)) / mainBg.cols)
// 	    cellHeight: mainBg.cellH
            
//             currentIndex: 0
//             boundsBehavior: Flickable.StopAtBounds

//             highlightFollowsCurrentItem: false

//             populate: Transition {
//     		NumberAnimation { property: "opacity"; from: 1; to: 1; duration: 0 }
// 	    }
            
//             add: Transition {
//                 id: addTrans
//                 SequentialAnimation {
//                     PropertyAction { property: "opacity"; value: 0 }
//                     PropertyAction { property: "scale"; value: 0.8 }
//                     PauseAnimation { duration: 10 }
//                     ParallelAnimation {
//                         NumberAnimation { property: "opacity"; to: 1; duration: 250; easing.type: Easing.OutCubic }
//                         NumberAnimation { property: "scale"; to: 1; duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
//                     }
//                 }
//             }
            
//             displaced: Transition {
//                 NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutExpo }
//             }
            
//             onContentYChanged: {
//                 if (contentY + height >= contentHeight - window.s(80)) {
//                     window.loadMore();
//                 }
//             }

//             Behavior on contentY {
//                 enabled: window.navDuration > 0
//                 NumberAnimation { duration: 250; easing.type: Easing.OutExpo }
//             }

//             onCurrentIndexChanged: {
//                 if (currentIndex >= 0 && clipList.model !== null) {
//                     if (currentIndex >= clipModel.count - (mainBg.cols * 2)) {
//                         window.loadMore();
//                     }
                    
//                     let row = Math.floor(currentIndex / mainBg.cols);
//                     let targetTop = row * mainBg.cellH;
//                     let targetBottom = targetTop + mainBg.cellH;

//                     if (window.navDuration > 0) {
//                         if (targetTop < contentY) {
//                             contentY = targetTop;
//                         } else if (targetBottom > contentY + height) {
//                             contentY = targetBottom - height;
//                         }
//                     } else {
//                         positionViewAtIndex(currentIndex, GridView.Contain);
//                     }
//                 }
//             }

//             ScrollBar.vertical: ScrollBar {
//                 active: true
//                 policy: ScrollBar.AsNeeded
//                 contentItem: Rectangle {
//                     implicitWidth: window.s(4)
//                     radius: window.s(2)
//                     color: window.surface2
//                     opacity: 0.5
//                 }
//             }

//             highlight: Item {
//                 z: 0 
//                 Rectangle {
//                     id: activeHighlight
//                     width: clipList.cellWidth - window.s(10)
//                     height: clipList.cellHeight - window.s(10)
//                     radius: window.s(8)
//                     color: window.mauve

//                     property int curIdx: clipList.currentIndex
//                     property real targetX: curIdx === -1 || clipList.model === null ? 0 : (curIdx % mainBg.cols) * clipList.cellWidth
//                     property real targetY: curIdx === -1 || clipList.model === null ? 0 : Math.floor(curIdx / mainBg.cols) * clipList.cellHeight

//                     Behavior on x { NumberAnimation { duration: window.navDuration > 0 ? window.navDuration : 350; easing.type: Easing.OutExpo } }
//                     Behavior on y { NumberAnimation { duration: window.navDuration > 0 ? window.navDuration : 350; easing.type: Easing.OutExpo } }

//                     x: targetX + window.s(5)
//                     y: targetY + window.s(5)
//                     opacity: clipList.count > 0 && clipList.currentIndex >= 0 && clipList.model !== null ? 1 : 0
//                     Behavior on opacity { NumberAnimation { duration: 300 } }
//                 }
//             }

//             delegate: Item {
//                 id: delegateRoot
//                 width: clipList.cellWidth
//                 height: clipList.cellHeight
                
//                 z: index === clipList.currentIndex ? 50 : 1
                
//                 Rectangle {
//                     id: cardBg
//                     x: window.s(5)
//                     y: window.s(5)
//                     width: parent.width - window.s(10)
//                     height: parent.height - window.s(10)
                    
//                     radius: window.s(8)
                    
//                     color: ma.containsMouse && index !== clipList.currentIndex ? Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.4) : "transparent"
//                     Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutSine } }

//                     Rectangle {
//                         z: 2
//                         x: window.s(8)
//                         y: window.s(8)
//                         width: window.s(22)
//                         height: window.s(22)
//                         radius: window.s(6)
                        
//                         color: index === clipList.currentIndex ? window.crust : Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.85)
                        
//                         Text {
//                             anchors.centerIn: parent
//                             text: (index + 1)
//                             font.family: "JetBrains Mono"
//                             font.pixelSize: window.s(11)
//                             font.weight: Font.Bold
//                             color: index === clipList.currentIndex ? window.mauve : window.text
//                         }
//                     }

//                     Rectangle {
//                         anchors.fill: parent
//                         anchors.margins: window.s(4)
//                         visible: model.type === "image"
//                         color: "transparent"
//                         radius: window.s(6)
//                         clip: true
                        
//                         Image {
//                             anchors.fill: parent
//                             source: model.type === "image" ? "file://" + model.content : ""
//                             fillMode: Image.PreserveAspectFit
//                             asynchronous: true 
//                             cache: true
//                             smooth: true
//                             mipmap: true
//                         }
//                     }

//                     Item {
//                         anchors.fill: parent
//                         anchors.margins: window.s(12)
//                         anchors.topMargin: window.s(36)
//                         visible: model.type === "text"
//                         clip: true

//                         Text {
//                             anchors.fill: parent
//                             text: model.content
//                             font.family: "JetBrains Mono"
//                             font.pixelSize: window.s(13)
//                             font.weight: index === clipList.currentIndex ? Font.Bold : Font.Medium
//                             color: index === clipList.currentIndex ? window.base : window.text
//                             wrapMode: Text.Wrap
//                             elide: Text.ElideRight
//                             verticalAlignment: Text.AlignTop
//                             maximumLineCount: 4 
                            
//                             property real textShift: index === clipList.currentIndex ? window.s(4) : 0
//                             transform: Translate { x: textShift }
//                             Behavior on textShift { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
//                             Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo } }
//                         }
//                     }

//                     MouseArea {
//                         id: ma
//                         anchors.fill: parent
//                         hoverEnabled: !window.previewMode
//                         enabled: !window.previewMode
//                         acceptedButtons: Qt.LeftButton | Qt.RightButton
//                         onClicked: (mouse) => {
//                             window.navDuration = 250;
//                             clipList.currentIndex = index;
                            
//                             if (mouse.button === Qt.RightButton) {
//                                 window.previewMode = true;
//                                 window.updatePreviewText();
//                             } else {
//                                 copyToClipboard(model.id);
//                             }
//                         }
//                     }
//                 }
//             }
//         }

//         // FULL SCREEN PREVIEW OVERLAY
//         Rectangle {
//             id: previewMorph
//             z: 100
            
//             property var curItem: clipList.currentIndex >= 0 && clipModel.count > 0 ? clipModel.get(clipList.currentIndex) : null
//             property int curIdx: clipList.currentIndex !== -1 ? clipList.currentIndex : 0
            
//             property real gridX: window.s(10)
//             property real gridY: mainBg.searchHeight + mainBg.separatorHeight + mainBg.animatedMargins / 2
//             property real gridW: mainBg.width - window.s(20)
//             property real gridH: mainBg.animatedListHeight
            
//             property real startX: gridX + (curIdx % mainBg.cols) * clipList.cellWidth + window.s(5)
//             property real startY: gridY + Math.floor(curIdx / mainBg.cols) * clipList.cellHeight - clipList.contentY + window.s(5)
//             property real startW: clipList.cellWidth - window.s(10)
//             property real startH: clipList.cellHeight - window.s(10)
            
//             color: window.crust
//             border.color: window.mauve
//             border.width: window.previewMode ? window.s(2) : 0
//             Behavior on border.width { NumberAnimation { duration: 150 } }
//             clip: true
            
//             Image {
//                 anchors.top: parent.top
//                 anchors.left: parent.left
//                 anchors.right: parent.right
//                 anchors.bottom: parent.bottom
//                 anchors.margins: window.s(20)
                
//                 source: (previewMorph.curItem && previewMorph.curItem.type === "image") ? "file://" + previewMorph.curItem.content : ""
//                 fillMode: Image.PreserveAspectFit
//                 asynchronous: true 
//                 visible: previewMorph.curItem && previewMorph.curItem.type === "image"
                
//                 opacity: window.previewMode ? 1 : 0
//                 Behavior on opacity { NumberAnimation { duration: 150;  } }
//             }
            
//             Flickable {
//                 id: textPreviewFlickable
//                 anchors.top: parent.top
//                 anchors.left: parent.left
//                 anchors.right: parent.right
//                 anchors.bottom: parent.bottom
//                 anchors.margins: window.s(20)
                
//                 contentWidth: width
//                 contentHeight: textPreviewContent.paintedHeight
//                 clip: true
                
//                 Behavior on contentY { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                
//                 visible: previewMorph.curItem && previewMorph.curItem.type === "text"
//                 opacity: window.previewMode ? 1 : 0
//                 Behavior on opacity { NumberAnimation { duration: 150;  } }
                
//                 TextEdit {
//                     id: textPreviewContent
//                     width: parent.width
                    
//                     text: {
//                         if (!window.previewMode || !previewMorph.curItem || previewMorph.curItem.type !== "text") return "";
                        
//                         if (window.fullTextPreview !== "") {
//                             if (!window.previewAnimationDone && window.fullTextPreview.length > 3000) {
//                                 return window.fullTextPreview.substring(0, 3000);
//                             }
//                             return window.fullTextPreview;
//                         }
                        
//                         return previewMorph.curItem.content; 
//                     }
                    
//                     color: window.text
//                     font.family: "JetBrains Mono"
//                     font.pixelSize: window.s(14)
//                     wrapMode: TextEdit.Wrap
//                     readOnly: true
//                     selectByMouse: true
//                     selectionColor: window.surface2
//                     selectedTextColor: window.mauve
//                 }
//             }
            
//             states: [
//                 State {
//                     name: "hidden"
//                     when: !window.previewMode
//                     PropertyChanges { 
//                         target: previewMorph; 
//                         opacity: 0; 
//                         x: previewMorph.startX; 
//                         y: previewMorph.startY; 
//                         width: previewMorph.startW; 
//                         height: previewMorph.startH; 
//                         radius: window.s(8) 
//                     }
//                 },
//                 State {
//                     name: "visible"
//                     when: window.previewMode
//                     PropertyChanges { 
//                         target: previewMorph; 
//                         opacity: 1; 
//                         x: previewMorph.gridX; 
//                         y: previewMorph.gridY; 
//                         width: previewMorph.gridW; 
//                         height: previewMorph.gridH; 
//                         radius: window.s(12) 
//                     }
//                 }
//             ]
            
//             transitions: [
//                 Transition {
//                     from: "hidden"; to: "visible"
//                     SequentialAnimation {
//                         ParallelAnimation {
//                             NumberAnimation { target: previewMorph; property: "opacity"; duration: 50 } 
//                             NumberAnimation { properties: "x,y,width,height,radius"; duration: 300; easing.type: Easing.OutExpo } 
//                         }
//                         ScriptAction { script: { window.previewAnimationDone = true; } }
//                     }
//                 },
//                 Transition {
//                     from: "visible"; to: "hidden"
//                     ParallelAnimation {
//                         NumberAnimation { properties: "x,y,width,height,radius"; duration: 250; easing.type: Easing.OutExpo } 
//                         SequentialAnimation {
//                             PauseAnimation { duration: 150 }
//                             NumberAnimation { target: previewMorph; property: "opacity"; to: 0; duration: 100 }
//                         }
//                     }
//                 }
//             ]
//         }
//     }
// }
import QtQuick                                                                    // Imports the QtQuick module which provides the basic QML types for creating user interfaces (Item, Rectangle, Text, etc.)
import QtQuick.Window                                                             // Imports the QtQuick.Window module which provides the Window type and access to Screen properties like width/height
import QtQuick.Effects                                                            // Imports the QtQuick.Effects module for graphical effects (though not directly used in this file, may be available for child components)
import QtQuick.Layouts                                                            // Imports the QtQuick.Layouts module which provides layout containers like RowLayout, ColumnLayout, GridLayout for automatic positioning
import QtQuick.Controls                                                           // Imports the QtQuick.Controls module which provides reusable UI controls like TextField, ScrollBar, etc.
import Quickshell                                                                 // Imports the Quickshell module - the core shell framework that provides Process, execDetached, env, and other shell integration features
import Quickshell.Io                                                              // Imports Quickshell's I/O module which provides StdioCollector for capturing process standard output streams
import "../"                                                                      // Imports the parent directory's QML components, giving access to Scaler and MatugenColors defined in sibling files

Item {                                                                            // Root item of this component - a basic invisible container that holds all other UI elements
    id: window                                                                    // Assigns the id "window" to this root Item so it can be referenced by child elements using "window.propertyName"
    focus: true                                                                   // Ensures this Item has keyboard focus when the component is visible, allowing keyboard input to be captured

    Scaler {                                                                      // Creates an instance of the Scaler component (defined in Scaler.qml) for resolution-independent sizing
        id: scaler                                                                // Assigns the id "scaler" so its methods can be called from anywhere in this component
        currentWidth: Screen.width                                                // Passes the current screen width in pixels to the Scaler so it can calculate scaling factors based on a reference resolution
    }
    
    function s(val) {                                                            // Defines a convenience function "s()" that scales a value using the Scaler component
        return scaler.s(val);                                                     // Calls the Scaler's s() method with the provided value and returns the scaled result
    }

    MatugenColors { id: _theme }                                                  // Creates an instance of MatugenColors (from MatugenColors.qml) that reads the current system color scheme generated by matugen/material you; assigns it the id "_theme" (underscore prefix suggests internal use)
    
    readonly property color base: _theme.base                                     // Creates a read-only property that exposes the base background color from the theme (used for main backgrounds)
    readonly property color crust: _theme.crust                                   // Creates a read-only property for the crust color - the darkest surface color in the Catppuccin palette, used for elevated/dark backgrounds
    readonly property color text: _theme.text                                     // Creates a read-only property for the primary text color from the theme
    readonly property color subtext0: _theme.subtext0                            // Creates a read-only property for the secondary/subdued text color, used for placeholder text and less important labels
    readonly property color surface0: _theme.surface0                            // Creates a read-only property for the lowest surface color (slightly lighter than base), used for subtle card backgrounds
    readonly property color surface1: _theme.surface1                            // Creates a read-only property for a medium surface color, used for borders and slightly elevated elements
    readonly property color surface2: _theme.surface2                            // Creates a read-only property for the highest surface color, used for scrollbars and more prominent elements
    readonly property color mauve: _theme.mauve || "#cba6f7"                     // Creates a read-only property for the mauve accent color with a fallback hex value "#cba6f7" (a soft purple) if the theme doesn't provide it
    readonly property color blue: _theme.blue                                     // Creates a read-only property for the blue accent color from the theme

    property var allClips: []                                                     // Declares a dynamic property holding an array that stores all fetched clipboard items (unfiltered full list); initialized as an empty JavaScript array
    
    // Pagination properties                                                       // Comment block indicating the following properties control pagination/infinite scroll behavior
    property int currentOffset: 0                                                 // Tracks the current pagination offset - how many items have been fetched so far; starts at 0 (beginning)
    property int fetchLimit: 24                                                   // Defines the number of clipboard items to fetch per page/request; set to 24 items at a time
    property bool isLoading: false                                                // A boolean flag that is true while a fetch operation is in progress, used to prevent duplicate simultaneous requests
    property bool hasMore: true                                                   // A boolean flag indicating whether there are more clipboard items available to fetch from the backend; initially true, set to false when the backend returns fewer items than fetchLimit
    
    // Global state                                                                // Comment block indicating these properties track global UI state across the component
    property int navDuration: 0                                                   // Controls the animation duration for navigation movements; set to 0 for instant movement, 250 for animated navigation (keyboard arrow keys)
    property bool previewMode: false                                              // Boolean flag that toggles full-screen preview mode for the currently selected clipboard item; when true, shows expanded content
    property bool previewAnimationDone: false                                    // Boolean flag that tracks whether the full preview text animation/loading is complete; used to show abbreviated text during loading
    property string fullTextPreview: ""                                           // Stores the fully decoded text content of a clipboard item (fetched via cliphist decode) for display in the preview overlay
    property int pendingIndex: -1                                                 // When loading more items, stores the index that should be selected once loading completes; -1 means no pending selection

    property real layoutWidth: width                                              // A convenience property that mirrors the component's current width; can be used for layout calculations
    property real layoutHeight: height                                            // A convenience property that mirrors the component's current height; can be used for layout calculations

    // Startup state to prevent accordion layout shifts                             // Comment explaining this flag prevents unwanted visual layout changes during initial component loading
    property bool isInitialLoad: true                                             // Boolean flag indicating this is the first time the component is loading; used to control animation behavior during startup

    onPreviewModeChanged: {                                                       // Signal handler that triggers when the previewMode property changes value
        if (!previewMode) {                                                       // If preview mode was just turned OFF (user exited preview)
            fullTextPreview = "";                                                  // Clears the stored full text preview content to free memory
            previewAnimationDone = false;                                          // Resets the animation done flag so next preview start shows abbreviated text while loading
        }
    }

    Process {                                                                     // Creates a Quickshell Process object to run external commands (cliphist decode) for fetching full text of clipboard items
        id: fullTextFetcher                                                       // Assigns the id "fullTextFetcher" so it can be referenced to start/stop the process
        running: false                                                            // Initially the process is not running; it will be started only when needed to fetch full text
        stdout: StdioCollector {                                                  // Configures a StdioCollector to capture the standard output (stdout) of this process
            onStreamFinished: {                                                   // Signal handler that triggers when the process completes and stdout stream is fully collected
                window.fullTextPreview = this.text;                               // Stores the collected output text (full decoded clipboard content) into the fullTextPreview property
            }
        }
    }

    function updatePreviewText() {                                                // Defines a JavaScript function to initiate fetching the full decoded text for the current preview item
        window.fullTextPreview = "";                                              // Clears any previously fetched full text to show loading state
        let item = clipModel.get(clipList.currentIndex);                         // Retrieves the data object for the currently selected item from the clipModel using the GridView's currentIndex
        if (item && item.type === "text") {                                      // Checks if the item exists AND if its type is "text" (we only decode text items, not images)
            fullTextFetcher.command = ["cliphist", "decode", item.id.toString()]; // Sets the command array for the Process: runs "cliphist decode <id>" to retrieve the original text content from the clipboard history
            fullTextFetcher.running = true;                                       // Starts the fullTextFetcher process, which will run the command and capture its output
        }
    }

    Process {                                                                     // Creates the main Quickshell Process object that fetches the clipboard item list from the Python backend
        id: clipFetcher                                                           // Assigns the id "clipFetcher" for referencing this process throughout the component
        running: true                                                             // The process starts running immediately when the component loads, fetching the initial batch of clipboard items
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/clipboard/clip_fetcher.py", window.currentOffset, window.fetchLimit]  // Sets the command array: runs Python 3 with the clip_fetcher.py script, passing the current offset (0 initially) and fetch limit as arguments; the script queries cliphist and returns paginated JSON
        
        stdout: StdioCollector {                                                  // Configures a StdioCollector to capture the standard output from the Python script
            onStreamFinished: {                                                   // Signal handler that triggers when the Python script completes and all output is collected
                try {                                                              // Opens a try block to handle potential JSON parsing errors gracefully
                    if (this.text && this.text.trim().length > 0) {              // Checks if the collected output text exists and contains non-whitespace characters
                        let newItems = JSON.parse(this.text);                    // Parses the JSON output from the Python script into a JavaScript array of clipboard item objects
                        
                        if (newItems.length < window.fetchLimit) {               // If the number of items returned is less than the fetch limit (24)
                            window.hasMore = false;                               // Sets hasMore to false - there are no more items to fetch from the backend
                        }
                        
                        if (window.currentOffset === 0) {                        // If this is the first page fetch (offset is 0, meaning initial load or refresh)
                            let isDifferent = window.allClips.length !== newItems.length;  // Starts by checking if the array lengths differ - if so, the data has definitely changed
                            if (!isDifferent) {                                   // If the lengths are the same, we need to do a deeper comparison
                                for (let i = 0; i < newItems.length; i++) {      // Iterates through each item in the new items array
                                    if (window.allClips[i].id !== newItems[i].id) {  // Compares the id of each item at the same index; clipboard item IDs are unique identifiers
                                        isDifferent = true;                       // If any ID differs, mark that the data has changed
                                        break;                                    // Break out of the loop early since we already know the data is different
                                    }
                                }
                            }

                            if (isDifferent || window.allClips.length === 0) {   // If the data has changed OR the current clip array is empty (first ever load)
                                window.allClips = newItems;                       // Replace the entire allClips array with the newly fetched items
                                window.filterClips(searchInput.text);            // Re-apply the current search filter to populate the visible clipModel with matching items
                            }
                        } else {                                                  // If this is NOT the first page (offset > 0, meaning a "load more" request)
                            window.appendClips(newItems);                         // Append the new items to the existing allClips array and update the filtered model
                        }
                    }
                } catch(e) {                                                      // Catches any errors that occur during JSON parsing or processing
                    console.log("Error parsing clipboard list: ", e);            // Logs the error to the console with a descriptive message for debugging
                } finally {                                                       // The finally block executes regardless of success or failure
                    window.isLoading = false;                                     // Resets the loading flag so new fetch requests can be made
                    window.isInitialLoad = false;                                 // Marks initial load as complete, allowing normal animations to play
                }
            }
        }
    }

    ListModel {                                                                   // Creates a ListModel that serves as the data source for the GridView - this is the filtered, displayable list
        id: clipModel                                                             // Assigns the id "clipModel" so it can be referenced to add/remove/query items
    }

    function loadMore() {                                                         // Defines a function that triggers loading the next page of clipboard items (infinite scroll)
        if (isLoading || !hasMore) return;                                        // Guard clause: if already loading or no more items exist, exit the function immediately without doing anything
        isLoading = true;                                                         // Sets the loading flag to true to prevent concurrent load requests
        currentOffset += fetchLimit;                                              // Increments the current offset by the fetch limit (24) to get the next page of items
        clipFetcher.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/clipboard/clip_fetcher.py", window.currentOffset, window.fetchLimit];  // Updates the clipFetcher command with the new offset value
        clipFetcher.running = true;                                              // Restarts the clipFetcher process to fetch the next page of clipboard items
    }

    function appendClips(newItems) {                                              // Defines a function that appends newly fetched items to the full list and updates the filtered model
        let q = searchInput.text.toLowerCase();                                  // Gets the current search query from the search input field and converts to lowercase for case-insensitive comparison
        for (let i = 0; i < newItems.length; i++) {                             // Iterates through each item in the newly fetched batch
            allClips.push(newItems[i]);                                           // Adds the item to the end of the full allClips array (unfiltered master list)
            if (q === "" || newItems[i].type === "image" || newItems[i].content.toLowerCase().includes(q)) {  // If no search query is active, OR the item is an image, OR the item's text content contains the search query
                clipModel.append(newItems[i]);                                    // Also add the item to the filtered clipModel so it appears in the GridView
            }
        }
        
        if (window.pendingIndex !== -1) {                                        // If there is a pending index waiting to be selected (set during keyboard navigation that triggered a load)
            if (window.pendingIndex < clipModel.count) {                         // If the pending index is within the bounds of the now-updated clipModel
                clipList.currentIndex = window.pendingIndex;                      // Set the GridView's current index to the pending index, selecting that item
            } else {                                                              // If the pending index is beyond the model (shouldn't normally happen but guards against edge cases)
                clipList.currentIndex = clipModel.count - 1;                     // Fall back to selecting the last available item in the model
            }
            window.pendingIndex = -1;                                             // Reset the pending index to -1 (no pending selection) since it has been resolved
        }
    }

    function filterClips(query) {                                                 // Defines the main filter function that repopulates clipModel based on a search query
        clipList.currentIndex = -1;                                               // Resets the GridView's current index to -1 (no selection) to prevent index errors during model rebuild
        clipList.positionViewAtBeginning();                                       // Scrolls the GridView back to the very beginning (top) of the list

        let q = query.toLowerCase();                                              // Converts the search query to lowercase for case-insensitive matching
        clipModel.clear();                                                        // Removes all items from the clipModel (the filtered display model)

        for (let i = 0; i < allClips.length; i++) {                             // Iterates through every item in the full allClips array
            if (allClips[i].type === "image" || allClips[i].content.toLowerCase().includes(q)) {  // If the item is an image (always show images) OR its text content includes the search query
                clipModel.append(allClips[i]);                                    // Add this item to the filtered clipModel so it appears in the GridView
            }
        }

        if (clipModel.count > 0) {                                               // If after filtering there is at least one item in the model
            clipList.currentIndex = 0;                                            // Select the first item in the filtered list by setting the GridView's currentIndex to 0
        }
    }

    function copyToClipboard(id) {                                                // Defines a function that copies a clipboard history item back to the active system clipboard
        Quickshell.execDetached(["bash", "-c", "cliphist decode " + id + " | wl-copy"]);  // Runs a detached bash command: decodes the cliphist entry by its ID and pipes it to wl-copy (Wayland clipboard tool); execDetached means the shell doesn't wait for it to finish
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);  // After copying, closes the Quickshell launcher window by calling the qs_manager.sh script with the "close" argument
    }

    Timer {                                                                       // Creates a QML Timer that fires once shortly after component initialization
        id: focusTimer                                                            // Assigns the id "focusTimer" so it can be restarted when needed
        interval: 50                                                              // Sets the timer interval to 50 milliseconds - a very short delay to allow the component to fully render first
        running: true                                                             // Starts the timer immediately when the component loads
        repeat: false                                                             // The timer only fires once (single-shot), not repeatedly
        onTriggered: searchInput.forceActiveFocus()                              // When the timer fires, forcefully gives keyboard focus to the search input field so the user can start typing immediately
    }

    Connections {                                                                 // Creates a Connections object to handle signals from the window's visibility changes
        target: window                                                            // Specifies that this Connections object is watching the root "window" Item for signals
        function onVisibleChanged() {                                             // Signal handler for when the window's visible property changes (shown or hidden)
            if (window.visible) {                                                 // If the window just became visible (user opened the clipboard launcher)
                if (window.allClips.length === 0) {                              // If the clipboard data hasn't been fetched yet (first time opening)
                    window.isInitialLoad = true;                                  // Set the initial load flag to suppress certain animations during first data load
                }

                focusTimer.restart();                                             // Restarts the focus timer to give keyboard focus to the search input after a tiny delay
                introPhaseAnim.restart();                                         // Restarts the intro animation that slides/fades in the main background rectangle
                window.navDuration = 0;                                          // Resets navigation duration to 0 (instant movement) for the fresh open
                window.previewMode = false;                                       // Ensures preview mode is off when opening the launcher
                window.previewAnimationDone = false;                              // Resets the preview animation flag
                window.fullTextPreview = "";                                      // Clears any leftover full text preview content
                window.pendingIndex = -1;                                         // Resets any pending selection index
                
                window.currentOffset = 0;                                        // Resets pagination offset to 0 to fetch from the beginning
                window.hasMore = true;                                            // Resets the hasMore flag to true (assume there are more items until proven otherwise)
                window.isLoading = true;                                          // Sets loading flag to true immediately to prevent duplicate fetches
                clipFetcher.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/clipboard/clip_fetcher.py", 0, window.fetchLimit];  // Updates the command to fetch from offset 0 (fresh load)
                clipFetcher.running = true;                                       // Starts the clipFetcher process to fetch the latest clipboard items
            } else {                                                              // If the window just became hidden (user closed the launcher)
                searchInput.text = "";                                            // Clears the search input text so it's empty next time the launcher opens
                window.pendingIndex = -1;                                         // Resets any pending selection index
                
                window.filterClips("");                                           // Re-runs the filter with an empty query, effectively showing all items (resets filter state)
                if (clipModel.count > 0) {                                       // If there are items in the filtered model
                    clipList.currentIndex = 0;                                    // Select the first item as default
                    clipList.positionViewAtBeginning();                           // Scroll the grid view back to the top
                }
            }
        }
    }

    property real globalOrbitAngle: 0                                             // Declares a floating-point property to track the angle for the decorative orbiting background shapes; starts at 0 radians
    NumberAnimation on globalOrbitAngle {                                         // Attaches a NumberAnimation directly to the globalOrbitAngle property
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true  // Animates the angle from 0 to 2π (full circle, ~6.283 radians) over 90 seconds (1.5 minutes), loops infinitely, and starts running immediately on component load
    }

    property real introPhase: 0                                                   // Declares a property to control the intro animation phase; 0 = hidden/start, 1 = fully visible/complete
    NumberAnimation on introPhase {                                               // Attaches a NumberAnimation directly to the introPhase property
        id: introPhaseAnim                                                        // Assigns the id "introPhaseAnim" so it can be restarted when the window is shown
        from: 0; to: 1; duration: 600; easing.type: Easing.OutExpo; running: true  // Animates from 0 to 1 over 600ms with OutExpo easing (fast start, smooth deceleration at the end), starts running immediately on component load
    }

    Rectangle {                                                                   // Creates the main background rectangle that contains all the clipboard UI elements
        id: mainBg                                                                // Assigns the id "mainBg" so child elements and other components can reference this rectangle's dimensions
        width: layoutWidth                                                        // Sets the width to match the parent's layoutWidth property (window width)
        
        property real searchHeight: window.s(65)                                  // Defines a custom property for the height of the search bar area, scaled using the s() function (65 reference units)
        property real separatorHeight: 1                                          // Defines the height of the thin separator line between search bar and content area (1 pixel)
        
        property int cols: 3                                                      // Defines the number of columns in the clipboard grid; set to 3 columns
        property real cellH: window.s(145)                                        // Defines the height of each grid cell (clipboard item card), scaled to 145 reference units
        
        property real maxVisibleRows: 4                                           // Defines the maximum number of visible rows in the grid before scrolling; set to 4 rows
        property real visibleRows: maxVisibleRows                                 // A property that mirrors maxVisibleRows (could be dynamically adjusted, but currently fixed at 4)
        property real animatedListHeight: visibleRows * cellH                     // Calculates the total height of the visible grid area by multiplying rows by cell height
        property real animatedMargins: window.s(20)                               // Defines the vertical margins/padding around the grid content, scaled to 20 reference units

        height: searchHeight + separatorHeight + animatedMargins + animatedListHeight  // Sets the total height of the main background: search bar + separator + top/bottom margins + grid area
        anchors.top: parent.top                                                   // Anchors the top of the background to the top of the parent (window)
        anchors.horizontalCenter: parent.horizontalCenter                         // Centers the background horizontally within the parent window

        radius: window.s(16)                                                      // Rounds the corners of the background rectangle, scaled to 16 reference units for a smooth modern look
        color: Qt.rgba(window.base.r, window.base.g, window.base.b, 1.0)        // Sets the background color to the theme's base color with full opacity (alpha = 1.0), using Qt.rgba to create a fully opaque color from the base color components
        border.color: window.surface1                                             // Sets the border color to the theme's surface1 color for a subtle outline
        border.width: 1                                                           // Sets the border width to 1 pixel for a thin, elegant border
        clip: true                                                                // Enables clipping - any child content that extends beyond this rectangle's rounded corners will be cut off

        transform: Translate { y: (window.introPhase - 1) * window.s(60) }      // Applies a vertical translation transform: when introPhase is 0, the y offset is -60 (slides up from below); when introPhase is 1, the y offset is 0 (normal position); creates a slide-up entrance animation
        opacity: window.introPhase                                                // Binds the opacity of the entire background to the introPhase (0 = invisible, 1 = fully visible), creating a fade-in effect synced with the slide

        Rectangle {                                                               // Creates the first decorative floating orb/shape in the background for visual interest
            width: parent.width * 0.8; height: width; radius: width / 2          // Makes this a circle: width is 80% of parent width, height equals width (square), radius is half (perfect circle)
            x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)  // Positions the circle's x coordinate: centers it in the parent, then offsets by cosine of (angle * 2) times 150 units, creating a horizontal oscillation at 2x the base frequency
            y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)  // Positions the circle's y coordinate: centers vertically, then offsets by sine of (angle * 2) times 100 units, creating vertical oscillation; together with x forms a Lissajous-like orbital pattern
            opacity: 0.08                                                         // Makes the decorative orb very subtle and faint (8% opacity) so it doesn't distract from the UI
            color: window.mauve                                                   // Colors the orb with the theme's mauve accent color for a cohesive look
            Behavior on color { ColorAnimation { duration: 1000 } }              // When the color changes (theme switch), animates to the new color smoothly over 1 second
        }
        
        Rectangle {                                                               // Creates the second decorative floating orb with different parameters for variety
            width: parent.width * 0.9; height: width; radius: width / 2          // Makes a larger circle: 90% of parent width for a bigger, more diffuse shape
            x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)  // Uses sine for x-axis (instead of cosine) and negative 150 units offset, creating a different orbital path at 1.5x frequency
            y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)  // Uses cosine for y-axis with negative 100 units, making this orb orbit in a counter-direction to the first one
            opacity: 0.06                                                         // Even more subtle than the first orb at 6% opacity
            color: window.blue                                                    // Uses the blue accent color instead of mauve for color contrast between the two orbs
            Behavior on color { ColorAnimation { duration: 1000 } }              // Smooth 1-second color transition when the theme changes
        }

        Rectangle {                                                               // Creates the header area rectangle that contains the search bar
            id: headerArea                                                        // Assigns id "headerArea" for referencing by the separator line below
            anchors.top: parent.top                                               // Anchors to the top of the main background
            anchors.left: parent.left                                             // Anchors to the left edge of the main background
            anchors.right: parent.right                                           // Anchors to the right edge of the main background (stretches full width)
            height: mainBg.searchHeight                                           // Sets height to the searchHeight property (65 scaled units)
            color: "transparent"                                                  // Makes the header area itself transparent - it's just a container, not visually visible
            
            RowLayout {                                                           // Creates a horizontal row layout to arrange the search icon and input field side by side
                anchors.fill: parent                                               // Makes the RowLayout fill the entire header area
                anchors.margins: window.s(15)                                     // Sets uniform margins of 15 scaled units on all sides of the RowLayout
                anchors.leftMargin: window.s(20)                                  // Overrides the left margin to 20 units for a bit more padding on the left
                anchors.rightMargin: window.s(20)                                 // Overrides the right margin to 20 units for balanced padding
                spacing: window.s(15)                                             // Sets spacing between child elements to 15 scaled units

                Item {                                                            // Creates a container Item for the search/preview icon (allows stacking two icons)
                    width: window.s(18)                                           // Sets width to 18 scaled units
                    height: window.s(18)                                          // Sets height to 18 scaled units (square container)

                    Text {                                                        // Creates the first text element showing the clipboard/search icon (󰅌)
                        anchors.centerIn: parent                                   // Centers this text element within the parent Item
                        text: "󰅌"                                                // Sets the text to the Nerd Font clipboard icon (looks like a clipboard with paper)
                        font.family: "Iosevka Nerd Font"                          // Uses the Iosevka Nerd Font which includes the required glyph icons
                        font.pixelSize: window.s(18)                              // Sets the font size to 18 scaled units
                        color: searchInput.activeFocus ? window.mauve : window.subtext0  // If the search input has focus, color the icon mauve (accent); otherwise use subtext0 (muted)
                        
                        opacity: !window.previewMode ? 1 : 0                     // When NOT in preview mode, the search icon is fully visible; when in preview mode, it's invisible
                        scale: !window.previewMode ? 1 : 0.5                      // When NOT in preview mode, the icon is at full scale; when in preview mode, shrinks to 50%
                        rotation: !window.previewMode ? 0 : -90                  // When NOT in preview mode, no rotation; when switching to preview mode, rotates -90 degrees
                        
                        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }  // Smooth 150ms opacity transition using InOutQuad easing (smooth acceleration and deceleration)
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }     // 150ms scale animation with OutBack easing (overshoots slightly and bounces back for a playful effect)
                        Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }   // 150ms rotation animation with OutBack easing
                        Behavior on color { ColorAnimation { duration: 100 } }    // Quick 100ms color transition when focus changes
                    }

                    Text {                                                        // Creates the second text element showing the preview/back icon (󰈈) - stacked on top of the first
                        anchors.centerIn: parent                                   // Centers this icon in the same position as the first icon
                        text: "󰈈"                                                // Sets the text to the Nerd Font "back/return" icon (curved arrow pointing left, indicating exit preview)
                        font.family: "Iosevka Nerd Font"                          // Same Nerd Font for consistent icon rendering
                        font.pixelSize: window.s(18)                              // Same font size as the first icon
                        color: window.mauve                                        // Always uses the mauve accent color when visible (preview mode active)
                        
                        opacity: window.previewMode ? 1 : 0                      // Reverse of the first icon: visible ONLY when in preview mode, invisible otherwise
                        scale: window.previewMode ? 1 : 0.5                       // Full scale in preview mode, shrinks to 50% when not in preview
                        rotation: window.previewMode ? 0 : 90                    // No rotation in preview mode, rotates 90 degrees when switching to normal mode (opposite direction)
                        
                        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }  // Same smooth opacity animation as the first icon
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }     // Same bouncy scale animation
                        Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }   // Same bouncy rotation animation
                    }
                }

                TextField {                                                       // Creates the search input field where users type to filter clipboard items
                    id: searchInput                                               // Assigns id "searchInput" for referencing throughout the component
                    Layout.fillWidth: true                                        // Makes the TextField expand horizontally to fill all available space in the RowLayout
                    Layout.fillHeight: true                                       // Makes the TextField expand vertically to fill the header area height
                    background: Item {}                                           // Sets the background to an empty Item, effectively removing the default TextField background styling for a clean look
                    color: window.text                                            // Sets the text color to the theme's primary text color
                    font.family: "JetBrains Mono"                                // Uses JetBrains Mono monospace font for the search input text
                    font.pixelSize: window.s(16)                                  // Sets font size to 16 scaled units
                    
                    placeholderText: "Search"                                     // Shows "Search" as placeholder text when the field is empty
                    placeholderTextColor: window.subtext0                         // Colors the placeholder text with the subdued subtext0 color
                    
                    verticalAlignment: TextInput.AlignVCenter                     // Vertically centers the text within the input field
                    focus: true                                                   // Initially gives keyboard focus to this field (overridden by the focusTimer shortly after load)

                    onTextChanged: {                                              // Signal handler called every time the text in the search field changes
                        if (window.previewMode) { window.previewMode = false; }  // If currently in preview mode, exit preview mode when the user starts typing a new search
                        window.pendingIndex = -1;                                 // Clear any pending selection index since the filter results will change
                        filterClips(text);                                        // Call the filter function with the current text to update the displayed clipboard items
                    }

                    Keys.onTabPressed: {                                          // Handler for when the Tab key is pressed while the search field has focus
                        if (clipModel.count > 0) {                               // Only toggle preview if there are items in the filtered model
                            window.previewMode = !window.previewMode;             // Toggle preview mode on/off
                            if (window.previewMode) {                             // If preview mode was just turned ON
                                window.updatePreviewText();                       // Fetch the full decoded text for the currently selected item
                            }
                        }
                        event.accepted = true;                                    // Mark the key event as handled so it doesn't propagate further
                    }

                    Keys.onRightPressed: {                                        // Handler for the Right arrow key press
                        window.previewMode = false;                               // Exit preview mode if active
                        window.navDuration = 250;                                // Set navigation animation duration to 250ms for smooth movement
                        window.pendingIndex = -1;                                 // Clear any pending selection
                        
                        let targetIdx = clipList.currentIndex + 1;              // Calculate the target index: one item to the right
                        if (targetIdx < clipModel.count) {                       // If the target index is within bounds
                            clipList.currentIndex = targetIdx;                    // Move the selection to the right
                        } else if (window.hasMore) {                              // If beyond the last item but more items are available to load
                            window.pendingIndex = targetIdx;                      // Store the target index as pending (will be selected after loading)
                            window.loadMore();                                    // Trigger loading the next page of items
                        }
                        event.accepted = true;                                    // Mark event as handled
                    }
                    
                    Keys.onLeftPressed: {                                         // Handler for the Left arrow key press
                        window.previewMode = false;                               // Exit preview mode
                        window.navDuration = 250;                                // Enable smooth navigation animation
                        window.pendingIndex = -1;                                 // Clear pending selection
                        
                        if (clipList.currentIndex > 0) { clipList.currentIndex--; }  // If not at the first item, move selection one step left
                        event.accepted = true;                                    // Mark event as handled
                    }
                    
                    Keys.onDownPressed: {                                         // Handler for the Down arrow key press
                        if (window.previewMode && textPreviewFlickable.visible) {  // If in preview mode and the text preview is visible
                            textPreviewFlickable.contentY = Math.min(textPreviewFlickable.contentY + window.s(60), Math.max(0, textPreviewFlickable.contentHeight - textPreviewFlickable.height));  // Scroll the text preview down by 60 units, but clamp to prevent scrolling past the end of the content
                        } else {                                                  // If not in text preview mode, navigate the grid
                            window.previewMode = false;                           // Exit preview mode if active
                            window.navDuration = 250;                            // Enable smooth navigation animation
                            window.pendingIndex = -1;                             // Clear pending selection
                            
                            let targetIdx = clipList.currentIndex + mainBg.cols;  // Calculate target: one full row down (current index + number of columns)
                            if (targetIdx < clipModel.count) {                   // If within bounds
                                clipList.currentIndex = targetIdx;                // Move selection down one row
                            } else if (window.hasMore) {                          // If beyond bounds but more items exist
                                window.pendingIndex = targetIdx;                  // Store as pending selection
                                window.loadMore();                                // Load more items
                            } else {                                              // If beyond bounds and no more items
                                clipList.currentIndex = clipModel.count - 1;      // Select the last available item instead
                            }
                        }
                        event.accepted = true;                                    // Mark event as handled
                    }
                    
                    Keys.onUpPressed: {                                           // Handler for the Up arrow key press
                        if (window.previewMode && textPreviewFlickable.visible) {  // If in text preview mode
                            textPreviewFlickable.contentY = Math.max(textPreviewFlickable.contentY - window.s(60), 0);  // Scroll the text preview up by 60 units, but don't scroll above position 0
                        } else {                                                  // If not in text preview mode
                            window.previewMode = false;                           // Exit preview mode
                            window.navDuration = 250;                            // Enable smooth navigation
                            window.pendingIndex = -1;                             // Clear pending selection
                            
                            if (clipList.currentIndex - mainBg.cols >= 0) { clipList.currentIndex -= mainBg.cols; }  // If not on the first row, move selection up one full row
                        }
                        event.accepted = true;                                    // Mark event as handled
                    }
                    
                    Keys.onReturnPressed: {                                       // Handler for the Enter/Return key press
                        if (clipList.currentIndex >= 0 && clipList.currentIndex < clipModel.count) {  // If there is a valid selection
                            copyToClipboard(clipModel.get(clipList.currentIndex).id);  // Copy the selected item's content to the system clipboard by its ID
                        }
                        event.accepted = true;                                    // Mark event as handled
                    }
                    
                    Keys.onEscapePressed: {                                       // Handler for the Escape key press
                        if (window.previewMode) {                                 // If currently in preview mode
                            window.previewMode = false;                           // Exit preview mode (first Escape press)
                        } else {                                                  // If not in preview mode (second Escape press, or first if not previewing)
                            Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);  // Close the entire Quickshell launcher window
                        }
                        event.accepted = true;                                    // Mark event as handled
                    }
                }
            }
        }

        Rectangle {                                                               // Creates the thin separator line between the search header and the grid content
            id: separatorLine                                                     // Assigns id "separatorLine" for potential referencing
            anchors.top: headerArea.bottom                                        // Anchors the top of the separator to the bottom of the header area
            anchors.left: parent.left                                             // Stretches to the left edge of the main background
            anchors.right: parent.right                                           // Stretches to the right edge of the main background (full width)
            height: mainBg.separatorHeight                                        // Sets height to the separatorHeight property (1 pixel)
            color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5)  // Colors the line with surface1 at 50% opacity for a subtle visual divider
        }

        GridView {                                                                // Creates a GridView to display clipboard items in a grid layout with keyboard navigation and scrolling
            id: clipList                                                          // Assigns id "clipList" for referencing the GridView throughout the component
            anchors.top: separatorLine.bottom                                     // Anchors the top of the grid to the bottom of the separator line
            anchors.left: parent.left                                             // Stretches to the left edge
            anchors.right: parent.right                                           // Stretches to the right edge
            anchors.topMargin: mainBg.animatedMargins / 2                         // Sets the top margin to half the animatedMargins value (10 scaled units)
            anchors.bottomMargin: mainBg.animatedMargins / 2                      // Sets the bottom margin to half the animatedMargins value
            anchors.leftMargin: window.s(10)                                      // Sets left margin to 10 scaled units
            anchors.rightMargin: window.s(10)                                     // Sets right margin to 10 scaled units
            height: mainBg.animatedListHeight                                     // Sets the height to match the calculated animated list height (4 rows * cell height)
            
            clip: true                                                            // Clips content that extends beyond the GridView bounds (important for scrolling)
            model: clipModel                                                      // Sets the data model to the filtered clipModel ListModel

            cellWidth: Math.floor((mainBg.width - window.s(20)) / mainBg.cols)   // Calculates cell width by taking available width (total minus margins), dividing by 3 columns, and flooring to integer pixels
            cellHeight: mainBg.cellH                                              // Sets each cell's height to the cellH property (145 scaled units)
            
            currentIndex: 0                                                       // Initially selects the first item (index 0)
            boundsBehavior: Flickable.StopAtBounds                                // Prevents the grid from flicking/bouncing past the edges (stops firmly at bounds)

            highlightFollowsCurrentItem: false                                    // Disables the default highlight behavior - we implement a custom highlight rectangle instead

            populate: Transition {                                                // Defines the transition for items appearing when the view is first populated
                NumberAnimation { property: "opacity"; from: 1; to: 1; duration: 0 }  // Effectively no animation - items appear instantly with full opacity (duration 0)
            }
            
            add: Transition {                                                     // Defines the transition animation for new items being added to the grid
                id: addTrans                                                      // Assigns id "addTrans" for referencing this transition
                SequentialAnimation {                                              // Creates a sequential animation (steps run one after another)
                    PropertyAction { property: "opacity"; value: 0 }              // Step 1: Instantly sets the new item's opacity to 0 (invisible)
                    PropertyAction { property: "scale"; value: 0.8 }              // Step 2: Instantly sets the new item's scale to 80% (slightly shrunk)
                    PauseAnimation { duration: 10 }                               // Step 3: Waits 10 milliseconds (tiny delay for visual staggering)
                    ParallelAnimation {                                            // Step 4: Runs these animations simultaneously
                        NumberAnimation { property: "opacity"; to: 1; duration: 250; easing.type: Easing.OutCubic }  // Fades opacity from 0 to 1 over 250ms with smooth OutCubic easing
                        NumberAnimation { property: "scale"; to: 1; duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 }  // Scales from 80% to 100% over 400ms with OutBack easing and slight overshoot (1.2) for a bouncy pop-in effect
                    }
                }
            }
            
            displaced: Transition {                                               // Defines the transition for existing items that get shifted when new items are added or items are removed
                NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutExpo }  // Animates the x and y position changes of displaced items over 400ms with strong OutExpo easing (fast start, smooth deceleration)
            }
            
            onContentYChanged: {                                                  // Signal handler triggered when the grid's vertical scroll position changes
                if (contentY + height >= contentHeight - window.s(80)) {          // If the user has scrolled close to the bottom (within 80 scaled units of the end)
                    window.loadMore();                                             // Trigger loading the next page of clipboard items (infinite scroll)
                }
            }

            Behavior on contentY {                                                // Attaches a Behavior to the contentY property for smooth scrolling animation
                enabled: window.navDuration > 0                                   // Only enables this animated behavior when navDuration is greater than 0 (keyboard navigation)
                NumberAnimation { duration: 250; easing.type: Easing.OutExpo }    // Animates scroll position changes over 250ms with OutExpo easing for smooth keyboard-driven scrolling
            }

            onCurrentIndexChanged: {                                              // Signal handler triggered when the currently selected index changes
                if (currentIndex >= 0 && clipList.model !== null) {              // Only process if there's a valid selection and the model exists
                    if (currentIndex >= clipModel.count - (mainBg.cols * 2)) {    // If the selection is within the last two rows of the current model
                        window.loadMore();                                         // Preemptively load more items so the user can continue scrolling
                    }
                    
                    let row = Math.floor(currentIndex / mainBg.cols);             // Calculate which row the selected item is in by dividing index by columns
                    let targetTop = row * mainBg.cellH;                           // Calculate the top edge y-position of that row
                    let targetBottom = targetTop + mainBg.cellH;                  // Calculate the bottom edge y-position of that row

                    if (window.navDuration > 0) {                                 // If smooth navigation is enabled (keyboard was used)
                        if (targetTop < contentY) {                                // If the target row is above the currently visible area
                            contentY = targetTop;                                  // Scroll so the target row is at the top of the view
                        } else if (targetBottom > contentY + height) {            // If the target row is below the currently visible area
                            contentY = targetBottom - height;                      // Scroll so the target row is at the bottom of the view
                        }
                    } else {                                                      // If navDuration is 0 (mouse click selection, instant positioning)
                        positionViewAtIndex(currentIndex, GridView.Contain);      // Use the built-in method to ensure the selected item is visible, but don't center it aggressively (Contain mode)
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {                                       // Attaches a vertical scrollbar to the GridView
                active: true                                                      // Keeps the scrollbar always active (visible when needed)
                policy: ScrollBar.AsNeeded                                        // Shows the scrollbar only when the content is scrollable
                contentItem: Rectangle {                                          // Customizes the scrollbar's visual appearance
                    implicitWidth: window.s(4)                                    // Sets the scrollbar width to 4 scaled units (thin and modern)
                    radius: window.s(2)                                           // Rounds the scrollbar edges with 2 unit radius
                    color: window.surface2                                        // Colors the scrollbar with the surface2 theme color
                    opacity: 0.5                                                  // Makes the scrollbar semi-transparent (50% opacity)
                }
            }

            highlight: Item {                                                     // Creates a custom highlight indicator that follows the current item
                z: 0                                                             // Sets the z-order to 0 (behind the delegate items which have higher z when selected)
                Rectangle {                                                       // The actual visual highlight rectangle
                    id: activeHighlight                                            // Assigns id "activeHighlight" for referencing
                    width: clipList.cellWidth - window.s(10)                      // Sets width to cell width minus 10 units of padding
                    height: clipList.cellHeight - window.s(10)                    // Sets height to cell height minus 10 units of padding
                    radius: window.s(8)                                           // Rounds the corners with 8 unit radius
                    color: window.mauve                                            // Colors the highlight with the mauve accent color

                    property int curIdx: clipList.currentIndex                     // Custom property that tracks the current selected index
                    property real targetX: curIdx === -1 || clipList.model === null ? 0 : (curIdx % mainBg.cols) * clipList.cellWidth  // Calculates the x position: if no selection or no model, x=0; otherwise column position * cell width
                    property real targetY: curIdx === -1 || clipList.model === null ? 0 : Math.floor(curIdx / mainBg.cols) * clipList.cellHeight  // Calculates the y position: if no selection or no model, y=0; otherwise row position * cell height

                    Behavior on x { NumberAnimation { duration: window.navDuration > 0 ? window.navDuration : 350; easing.type: Easing.OutExpo } }  // Animates x position changes: uses navDuration if set, otherwise 350ms, with OutExpo easing
                    Behavior on y { NumberAnimation { duration: window.navDuration > 0 ? window.navDuration : 350; easing.type: Easing.OutExpo } }  // Animates y position changes with the same timing

                    x: targetX + window.s(5)                                      // Positions the highlight at the calculated x plus 5 units padding
                    y: targetY + window.s(5)                                      // Positions the highlight at the calculated y plus 5 units padding
                    opacity: clipList.count > 0 && clipList.currentIndex >= 0 && clipList.model !== null ? 1 : 0  // Shows the highlight only when there are items and a valid selection; hides it otherwise
                    Behavior on opacity { NumberAnimation { duration: 300 } }     // Smooth 300ms opacity transition for the highlight appearing/disappearing
                }
            }

            delegate: Item {                                                      // Defines the delegate - the template for each individual clipboard item cell in the grid
                id: delegateRoot                                                   // Assigns id "delegateRoot" for the root of each cell
                width: clipList.cellWidth                                          // Sets the delegate width to match the grid's cell width
                height: clipList.cellHeight                                        // Sets the delegate height to match the grid's cell height
                
                z: index === clipList.currentIndex ? 50 : 1                       // Raises the z-order of the currently selected item to 50 (above the highlight which is at z=0); other items are at z=1
                
                Rectangle {                                                        // Creates the visual card background for each clipboard item
                    id: cardBg                                                      // Assigns id "cardBg" for referencing
                    x: window.s(5)                                                  // Positions 5 units from the left edge of the delegate
                    y: window.s(5)                                                  // Positions 5 units from the top edge of the delegate
                    width: parent.width - window.s(10)                              // Width is parent width minus 10 units (5 on each side for padding)
                    height: parent.height - window.s(10)                            // Height is parent height minus 10 units
                    
                    radius: window.s(8)                                             // Rounds the card corners with 8 unit radius
                    
                    color: ma.containsMouse && index !== clipList.currentIndex ? Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.4) : "transparent"  // If the mouse is hovering over this card AND it's not the currently selected item, shows a subtle surface0 highlight at 40% opacity; otherwise transparent
                    Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutSine } }  // Smooth 250ms color transition when hover state changes, using gentle OutSine easing

                    Rectangle {                                                     // Creates the numbered badge in the top-left corner of each card
                        z: 2                                                        // Sets z-order to 2 so it appears above the card background and content
                        x: window.s(8)                                              // Positions 8 units from the left
                        y: window.s(8)                                              // Positions 8 units from the top
                        width: window.s(22)                                         // Sets width to 22 scaled units
                        height: window.s(22)                                        // Sets height to 22 scaled units (square badge)
                        radius: window.s(6)                                         // Rounds the badge corners with 6 unit radius
                        
                        color: index === clipList.currentIndex ? window.crust : Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.85)  // If this is the selected item, uses the dark crust color; otherwise uses surface0 at 85% opacity
                        
                        Text {                                                      // The number text inside the badge
                            anchors.centerIn: parent                                  // Centers the text within the badge rectangle
                            text: (index + 1)                                        // Displays the item number (index + 1 to show 1-based numbering for users)
                            font.family: "JetBrains Mono"                            // Uses JetBrains Mono for clear number rendering
                            font.pixelSize: window.s(11)                             // Sets font size to 11 scaled units
                            font.weight: Font.Bold                                    // Makes the number bold for visibility
                            color: index === clipList.currentIndex ? window.mauve : window.text  // Selected item's number is mauve, others are regular text color
                        }
                    }

                    Rectangle {                                                     // Container rectangle for image previews (only visible for image-type clipboard items)
                        anchors.fill: parent                                         // Fills the entire card area
                        anchors.margins: window.s(4)                                  // Adds 4 units of margin on all sides
                        visible: model.type === "image"                               // Only visible when the clipboard item is an image
                        color: "transparent"                                          // Transparent background - the image itself provides the visual
                        radius: window.s(6)                                           // Rounds the corners
                        clip: true                                                    // Clips the image to the rounded rectangle shape
                        
                        Image {                                                       // The actual image element for displaying clipboard image thumbnails
                            anchors.fill: parent                                       // Fills the container rectangle
                            source: model.type === "image" ? "file://" + model.content : ""  // If the item is an image, constructs a file:// URL from the content path; otherwise empty string
                            fillMode: Image.PreserveAspectFit                           // Scales the image to fit within the bounds while preserving aspect ratio (no cropping)
                            asynchronous: true                                          // Loads the image asynchronously so the UI doesn't freeze while loading large images
                            cache: true                                                 // Enables image caching for faster subsequent loads
                            smooth: true                                                // Enables smooth scaling for better visual quality when images are resized
                            mipmap: true                                                // Enables mipmap filtering for better quality when images are scaled down
                        }
                    }

                    Item {                                                          // Container item for text content preview (only visible for text-type clipboard items)
                        anchors.fill: parent                                         // Fills the card area
                        anchors.margins: window.s(12)                                 // Adds 12 units of margin
                        anchors.topMargin: window.s(36)                               // Adds extra top margin (36 units) to clear the numbered badge
                        visible: model.type === "text"                                // Only visible for text-type items
                        clip: true                                                    // Clips text that overflows the container

                        Text {                                                        // The text element displaying the clipboard text content preview
                            anchors.fill: parent                                       // Fills the container item
                            text: model.content                                        // Displays the text content from the model data
                            font.family: "JetBrains Mono"                              // Uses monospace font for text preview
                            font.pixelSize: window.s(13)                               // Sets font size to 13 scaled units
                            font.weight: index === clipList.currentIndex ? Font.Bold : Font.Medium  // Selected item's text is bold, others are medium weight
                            color: index === clipList.currentIndex ? window.base : window.text  // Selected item's text uses the base color (visible on mauve highlight), others use regular text color
                            wrapMode: Text.Wrap                                        // Wraps long lines to fit within the width
                            elide: Text.ElideRight                                     // If text is too long vertically, shows "..." at the end
                            verticalAlignment: Text.AlignTop                           // Aligns text to the top of the container
                            maximumLineCount: 4                                        // Limits displayed text to 4 lines maximum
                            
                            property real textShift: index === clipList.currentIndex ? window.s(4) : 0  // Custom property: shifts text 4 units to the right when selected (visual effect)
                            transform: Translate { x: textShift }                      // Applies the horizontal translation based on textShift value
                            Behavior on textShift { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }  // Smooth 500ms animation when text shift changes
                            Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo } }  // Smooth 300ms color transition when selection changes
                        }
                    }

                    MouseArea {                                                     // Creates a mouse interaction area over the entire card
                        id: ma                                                        // Assigns id "ma" for referencing the hover state
                        anchors.fill: parent                                          // Fills the entire card area
                        hoverEnabled: !window.previewMode                             // Enables hover detection only when NOT in preview mode
                        enabled: !window.previewMode                                  // Disables mouse clicks when in preview mode
                        acceptedButtons: Qt.LeftButton | Qt.RightButton               // Accepts both left and right mouse button clicks
                        onClicked: (mouse) => {                                       // Mouse click handler with the mouse event parameter
                            window.navDuration = 250;                                  // Enables smooth navigation animation (250ms)
                            clipList.currentIndex = index;                             // Selects this item in the grid
                            
                            if (mouse.button === Qt.RightButton) {                     // If the right mouse button was clicked
                                window.previewMode = true;                              // Enter preview mode to see the full content
                                window.updatePreviewText();                             // Fetch the full decoded text for preview
                            } else {                                                    // If the left mouse button was clicked
                                copyToClipboard(model.id);                              // Copy this item to the system clipboard immediately
                            }
                        }
                    }
                }
            }
        }

        // FULL SCREEN PREVIEW OVERLAY                                                // Comment block indicating the following code handles the full-screen preview that expands from a card to fill the grid area
        Rectangle {                                                                   // Creates the preview overlay rectangle that morphs from the selected card to full size
            id: previewMorph                                                           // Assigns id "previewMorph" for referencing throughout the component
            z: 100                                                                     // Sets very high z-order (100) so the preview appears above all other UI elements
            
            property var curItem: clipList.currentIndex >= 0 && clipModel.count > 0 ? clipModel.get(clipList.currentIndex) : null  // Custom property: gets the data object for the currently selected item; null if nothing selected
            property int curIdx: clipList.currentIndex !== -1 ? clipList.currentIndex : 0  // Custom property: stores the current index (defaults to 0 if nothing selected to avoid errors)
            
            property real gridX: window.s(10)                                          // Defines the x position of the grid area (with left margin)
            property real gridY: mainBg.searchHeight + mainBg.separatorHeight + mainBg.animatedMargins / 2  // Calculates the y position of the grid area (below header and separator, plus top margin)
            property real gridW: mainBg.width - window.s(20)                           // Calculates the full width available in the grid area
            property real gridH: mainBg.animatedListHeight                             // The full height of the grid area
            
            property real startX: gridX + (curIdx % mainBg.cols) * clipList.cellWidth + window.s(5)  // Calculates the starting x position: grid left edge + column offset * cell width + 5 padding
            property real startY: gridY + Math.floor(curIdx / mainBg.cols) * clipList.cellHeight - clipList.contentY + window.s(5)  // Calculates starting y: grid top + row offset * cell height - scroll offset + 5 padding
            property real startW: clipList.cellWidth - window.s(10)                    // Starting width: cell width minus 10 units padding
            property real startH: clipList.cellHeight - window.s(10)                   // Starting height: cell height minus 10 units padding
            
            color: window.crust                                                         // Background color for the preview: uses the dark crust color from the theme
            border.color: window.mauve                                                  // Border color: mauve accent for a highlighted outline
            border.width: window.previewMode ? window.s(2) : 0                          // Border visible (2 units) only when in preview mode; hidden otherwise
            Behavior on border.width { NumberAnimation { duration: 150 } }               // Smooth 150ms animation when border width changes
            clip: true                                                                    // Clips content to the rounded rectangle bounds
            
            Image {                                                                       // Image element for displaying image previews in the overlay
                anchors.top: parent.top                                                    // Anchors to the top of the preview rectangle
                anchors.left: parent.left                                                  // Anchors to the left
                anchors.right: parent.right                                                // Anchors to the right (stretches horizontally)
                anchors.bottom: parent.bottom                                              // Anchors to the bottom (stretches vertically)
                anchors.margins: window.s(20)                                              // Adds 20 units of margin for padding
                
                source: (previewMorph.curItem && previewMorph.curItem.type === "image") ? "file://" + previewMorph.curItem.content : ""  // If the current preview item is an image, constructs file URL; otherwise empty
                fillMode: Image.PreserveAspectFit                                          // Scales the image to fit while maintaining aspect ratio
                asynchronous: true                                                         // Loads asynchronously to prevent UI freezing
                visible: previewMorph.curItem && previewMorph.curItem.type === "image"     // Only visible when previewing an image item
                
                opacity: window.previewMode ? 1 : 0                                        // Visible only in preview mode
                Behavior on opacity { NumberAnimation { duration: 150;  } }                // Smooth 150ms opacity transition
            }
            
            Flickable {                                                                     // Creates a scrollable container for text preview content
                id: textPreviewFlickable                                                     // Assigns id "textPreviewFlickable" for controlling scroll position
                anchors.top: parent.top                                                      // Anchors to preview rectangle edges
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: window.s(20)                                                // 20 units of margin
                
                contentWidth: width                                                          // Content width matches the Flickable width (no horizontal scrolling)
                contentHeight: textPreviewContent.paintedHeight                              // Content height is the actual painted height of the text (enables vertical scrolling)
                clip: true                                                                    // Clips text that overflows the viewport
                
                Behavior on contentY { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }  // Smooth 150ms animation for scroll position changes (arrow key scrolling)
                
                visible: previewMorph.curItem && previewMorph.curItem.type === "text"        // Only visible when previewing a text item
                opacity: window.previewMode ? 1 : 0                                          // Visible only in preview mode
                Behavior on opacity { NumberAnimation { duration: 150;  } }                  // Smooth 150ms opacity transition
                
                TextEdit {                                                                      // A read-only text display (using TextEdit for selection support) for showing the full clipboard text
                    id: textPreviewContent                                                       // Assigns id "textPreviewContent"
                    width: parent.width                                                           // Matches the Flickable width
                    
                    text: {                                                                       // Complex text property with logic for showing abbreviated or full content
                        if (!window.previewMode || !previewMorph.curItem || previewMorph.curItem.type !== "text") return "";  // If not in preview mode, or no item, or not text type: return empty string
                        
                        if (window.fullTextPreview !== "") {                                      // If the full decoded text has been fetched
                            if (!window.previewAnimationDone && window.fullTextPreview.length > 3000) {  // If the animation isn't done yet AND the full text is very long (>3000 chars)
                                return window.fullTextPreview.substring(0, 3000);                  // Show only the first 3000 characters as an abbreviated preview while animating
                            }
                            return window.fullTextPreview;                                        // Otherwise show the complete decoded text
                        }
                        
                        return previewMorph.curItem.content;                                      // Fallback: if full text hasn't been fetched yet, show the truncated content from the model
                    }
                    
                    color: window.text                                                            // Text color from theme
                    font.family: "JetBrains Mono"                                                // Monospace font for text display
                    font.pixelSize: window.s(14)                                                  // Font size 14 scaled units
                    wrapMode: TextEdit.Wrap                                                        // Wraps long lines
                    readOnly: true                                                                  // Makes the text non-editable (display only)
                    selectByMouse: true                                                             // Allows the user to select text with the mouse for copying
                    selectionColor: window.surface2                                                // Color of the text selection highlight
                    selectedTextColor: window.mauve                                                // Color of the selected text itself
                }
            }
            
            states: [                                                                              // Defines the two visual states for the preview overlay
                State {                                                                             // The "hidden" state when preview mode is off
                    name: "hidden"                                                                    // Names this state "hidden"
                    when: !window.previewMode                                                         // This state is active when previewMode is false
                    PropertyChanges {                                                                 // Specifies property changes to apply in this state
                        target: previewMorph;                                                          // Applies changes to the previewMorph rectangle
                        opacity: 0;                                                                     // Makes it invisible
                        x: previewMorph.startX;                                                         // Positions it at the selected card's x position
                        y: previewMorph.startY;                                                         // Positions at the card's y position
                        width: previewMorph.startW;                                                     // Sizes to match the card width
                        height: previewMorph.startH;                                                    // Sizes to match the card height
                        radius: window.s(8)                                                             // Uses the same corner radius as the cards
                    }
                },
                State {                                                                             // The "visible" state when preview mode is on
                    name: "visible"                                                                   // Names this state "visible"
                    when: window.previewMode                                                          // Active when previewMode is true
                    PropertyChanges {                                                                 // Specifies property changes
                        target: previewMorph;                                                          // Applies to previewMorph
                        opacity: 1;                                                                     // Fully visible
                        x: previewMorph.gridX;                                                          // Expands to fill the grid area horizontally
                        y: previewMorph.gridY;                                                          // Expands to fill the grid area vertically
                        width: previewMorph.gridW;                                                      // Full grid width
                        height: previewMorph.gridH;                                                     // Full grid height
                        radius: window.s(12)                                                            // Slightly larger corner radius for the expanded state
                    }
                }
            ]
            
            transitions: [                                                                        // Defines animations between states
                Transition {                                                                      // Transition from hidden to visible (entering preview)
                    from: "hidden"; to: "visible"                                                  // Specifies which states this transition applies to
                    SequentialAnimation {                                                           // Runs animations in sequence
                        ParallelAnimation {                                                           // These two animations run simultaneously
                            NumberAnimation { target: previewMorph; property: "opacity"; duration: 50 }   // Quickly fades in opacity over 50ms
                            NumberAnimation { properties: "x,y,width,height,radius"; duration: 300; easing.type: Easing.OutExpo }  // Morphs position, size, and corner radius over 300ms with smooth OutExpo easing
                        }
                        ScriptAction { script: { window.previewAnimationDone = true; } }            // After the morph animation completes, marks the preview animation as done so full text can be shown
                    }
                },
                Transition {                                                                      // Transition from visible to hidden (exiting preview)
                    from: "visible"; to: "hidden"                                                  // Reverse direction
                    ParallelAnimation {                                                              // These two run in parallel
                        NumberAnimation { properties: "x,y,width,height,radius"; duration: 250; easing.type: Easing.OutExpo }  // Morphs back to card size over 250ms
                        SequentialAnimation {                                                        // Sequential sub-animation for opacity
                            PauseAnimation { duration: 150 }                                           // Waits 150ms before starting to fade out (keeps it visible while morphing)
                            NumberAnimation { target: previewMorph; property: "opacity"; to: 0; duration: 100 }  // Fades out over 100ms
                        }
                    }
                }
            ]
        }
    }
}