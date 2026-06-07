// import QtQuick
// import QtQuick.Layouts
// import QtQuick.Window
// import QtCore
// import Qt.labs.folderlistmodel
// import QtMultimedia
// import Quickshell
// import Quickshell.Io
// import "../" 

// Item {
//     id: window
//     width: Screen.width

//     Scaler {
//         id: scaler
//         currentWidth: Screen.width
//     }
    
//     function s(val) { 
//         return scaler.s(val); 
//     }

//     MatugenColors { id: _theme }

//     property string widgetArg: ""
//     property string targetWallName: ""
//     property bool initialFocusSet: false
//     property int visibleItemCount: -1
//     property int scrollAccum: 0
//     property real scrollThreshold: window.s(300)

//     property string currentFilter: "All"
//     property string _lastFilter: "All"
//     property string searchQuery: ""
//     property bool isOnlineSearch: false
//     property bool isSearchPaused: false
//     property bool hasSearched: false
//     property var colorMap: ({})
//     property int cacheVersion: 0 
    
//     property bool isDownloadingWallpaper: false
//     property string currentDownloadName: ""
    
//     property bool isApplying: false
//     property bool isMonitorSelectorOpen: false
    
//     Timer {
//         id: applyUnlockTimer
//         interval: 250
//         onTriggered: window.isApplying = false
//     }
    
//     property bool isStartup: localFolderModel.status === FolderListModel.Loading || srcModel.status === FolderListModel.Loading
//     property bool isReady: visible && localFolderModel.status === FolderListModel.Ready
//     property bool isSearchActive: window.currentFilter === "Search" && window.hasSearched && searchFolderModel.status === FolderListModel.Loading
    
//     property string lastSearchName: ""
//     property bool isModelChanging: false
//     property bool searchIndexRestored: false
    
//     property bool isScrollingBlocked: window.currentFilter === "Search" && window.hasSearched && window.isSearchActive && !window.isSearchPaused
//     property bool jumpToLastOnFilterChange: false

//     readonly property var filterData: [
//         { name: "All", hex: "", label: "All" },
//         { name: "Video", hex: "", label: "Vid" },
//         { name: "Red", hex: "#FF4500", label: "" },
//         { name: "Orange", hex: "#FFA500", label: "" },
//         { name: "Yellow", hex: "#FFD700", label: "" },
//         { name: "Green", hex: "#32CD32", label: "" },
//         { name: "Blue", hex: "#1E90FF", label: "" },
//         { name: "Purple", hex: "#8A2BE2", label: "" },
//         { name: "Pink", hex: "#FF69B4", label: "" },
//         { name: "Monochrome", hex: "#A9A9A9", label: "" },
//         { name: "Search", hex: "", label: "Search" } 
//     ]

//     ListModel { id: monitorModel }

//     Process {
//         id: monitorProc
//         command: ["sh", "-c", "export PATH=$PATH:/usr/bin:/usr/local/bin:/run/current-system/sw/bin && hyprctl monitors -j"]
//         running: false
        
//         stdout: StdioCollector {
//             onStreamFinished: {
//                 console.log("[MonitorSync] Process finished. Reading stdout directly.");
//                 let response = this.text; 
                
//                 if (response && response.trim().length > 0) {
//                     try {
//                         var monitors = JSON.parse(response);
//                         console.log("[MonitorSync] JSON parsed successfully. Found " + monitors.length + " monitors.");
                        
//                         monitorModel.clear();
//                         for (var i = 0; i < monitors.length; i++) {
//                             monitorModel.append({ "name": monitors[i].name, "selected": true });
//                             console.log("[MonitorSync] -> Injected: " + monitors[i].name);
//                         }
//                     } catch(e) {
//                         console.log("[MonitorSync] ERROR parsing JSON: " + e);
//                         console.log("[MonitorSync] RAW TEXT DUMP: " + response);
//                     }
//                 } else {
//                     console.log("[MonitorSync] ERROR: stdout was empty.");
//                 }
//             }
//         }
//     }

//     function loadMonitors() {
//         console.log("[MonitorSync] Starting native hyprctl process...");
//         monitorProc.running = true;
//     }

//     function getMonitorOutputs() {
//         if (monitorModel.count <= 1) return "all"; 
        
//         let selected = [];
//         for (let i = 0; i < monitorModel.count; i++) {
//             if (monitorModel.get(i).selected) {
//                 selected.push(monitorModel.get(i).name);
//             }
//         }
        
//         if (selected.length === 0) return "none";
//         if (selected.length === monitorModel.count) return "all";
        
//         return selected.join(",");
//     }

//     function applyWallpaper(safeFileName, isVideo) {
//         if (!safeFileName || window.isApplying) return;
        
//         let outputs = window.getMonitorOutputs();
//         if (outputs === "none") return;
        
//         window.isApplying = true;
//         applyUnlockTimer.restart();
        
//         window.targetWallName = safeFileName;
//         let cleanName = window.getCleanName(safeFileName);
//         let reloadScript = Qt.resolvedUrl("matugen_reload.sh").toString();
        
//         if (reloadScript.startsWith("file://")) {
//             reloadScript = decodeURIComponent(reloadScript.substring(7));
//         }

//         const escapeBash = (str) => String(str).replace(/(["\\$`])/g, '\\$1');
//         const randomTransition = window.transitions[Math.floor(Math.random() * window.transitions.length)];
//         const escOutputs = escapeBash(outputs);
        
//         const logFile = "/tmp/qs_swww_debug.log";
        
//         if (window.currentFilter === "Search" && window.hasSearched) {
//             let alreadyExists = window.isDownloaded(safeFileName);
//             let destFile = window.srcDir + "/" + safeFileName;
//             let finalThumb = decodeURIComponent(window.thumbDir.replace("file://", "")) + "/" + safeFileName;
//             let tempThumb = decodeURIComponent(window.searchDir.replace("file://", "")) + "/" + safeFileName;
//             let mapFile = Quickshell.env("HOME") + "/.cache/wallpaper_picker/search_map.txt";

//             if (alreadyExists) {
//                 const applyScript = `
//                     export DEST_FILE="${escapeBash(destFile)}"
//                     export FINAL_THUMB="${escapeBash(finalThumb)}"
//                     export RELOAD_SCRIPT="${escapeBash(reloadScript)}"
//                     export TARGET_MONITORS="${escOutputs}"
                    
//                     cp "$DEST_FILE" /tmp/lock_bg.png || true
//                     pkill mpvpaper || true
                    
//                     echo "" >> ${logFile}
//                     echo "[$(date +'%H:%M:%S.%3N')] APPLYING CACHED SEARCH: $DEST_FILE TO $TARGET_MONITORS" >> ${logFile}
                    
//                     if [ "$TARGET_MONITORS" = "all" ]; then
//                         swww img "$DEST_FILE" --transition-type ${randomTransition} --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 >> ${logFile} 2>&1 &
//                     else
//                         swww img -o "$TARGET_MONITORS" "$DEST_FILE" --transition-type ${randomTransition} --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 >> ${logFile} 2>&1 &
//                     fi
                    
//                     ( matugen image "$FINAL_THUMB" || true; bash "$RELOAD_SCRIPT" || true ) &
//                 `;
//                 Quickshell.execDetached(["bash", "-c", applyScript]);
//             } else {
//                 window.isDownloadingWallpaper = true;
//                 window.currentDownloadName = safeFileName;

//                 const downloadScript = `
//                     export SAFE_NAME="${escapeBash(safeFileName)}"
//                     export DEST_FILE="${escapeBash(destFile)}"
//                     export FINAL_THUMB="${escapeBash(finalThumb)}"
//                     export TEMP_THUMB="${escapeBash(tempThumb)}"
//                     export RELOAD_SCRIPT="${escapeBash(reloadScript)}"
//                     export MAP_FILE="${escapeBash(mapFile)}"
//                     export TARGET_MONITORS="${escOutputs}"
                    
//                     URL=$(awk -F'|' -v fname="$SAFE_NAME" '$1 == fname {print $2; exit}' "$MAP_FILE")
//                     if [ -n "$URL" ]; then
//                         curl -s -L -A "Mozilla/5.0" "$URL" -o "$DEST_FILE.tmp"
                        
//                         if file "$DEST_FILE.tmp" | grep -iq "webp"; then
//                             magick "$DEST_FILE.tmp" "$DEST_FILE"
//                             rm -f "$DEST_FILE.tmp"
//                         else
//                             mv "$DEST_FILE.tmp" "$DEST_FILE"
//                         fi
                        
//                         cp "$TEMP_THUMB" "$FINAL_THUMB"
//                         magick "$DEST_FILE" -resize x420 -quality 70 "$FINAL_THUMB" || true
                        
//                         cp "$DEST_FILE" /tmp/lock_bg.png || true
//                         pkill mpvpaper || true
                        
//                         echo "" >> ${logFile}
//                         echo "[$(date +'%H:%M:%S.%3N')] APPLYING NEW DOWNLOAD: $DEST_FILE TO $TARGET_MONITORS" >> ${logFile}
                        
//                         if [ "$TARGET_MONITORS" = "all" ]; then
//                             swww img "$DEST_FILE" --transition-type ${randomTransition} --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 >> ${logFile} 2>&1 &
//                         else
//                             swww img -o "$TARGET_MONITORS" "$DEST_FILE" --transition-type ${randomTransition} --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 >> ${logFile} 2>&1 &
//                         fi
                        
//                         ( matugen image "$FINAL_THUMB" || true; bash "$RELOAD_SCRIPT" || true ) &
//                     fi
//                 `;
//                 Quickshell.execDetached(["bash", "-c", downloadScript]);
//             }
//             return;
//         }

//         const originalFile = window.srcDir + "/" + cleanName;
//         const thumbFile = Quickshell.env("HOME") + "/.cache/wallpaper_picker/thumbs/" + safeFileName;
        
//         const escOriginal = escapeBash(originalFile);
//         const escThumb = escapeBash(thumbFile);
//         const escReload = escapeBash(reloadScript);

//         let wallpaperCmd = "";
        
//         if (isVideo) {
//             wallpaperCmd = `
//                 echo "" >> ${logFile}
//                 echo "[$(date +'%H:%M:%S.%3N')] APPLYING LOCAL VIDEO: ${escOriginal} TO ${escOutputs}" >> ${logFile}
                
//                 if [ "${escOutputs}" = "all" ]; then
//                     mpvpaper -o 'loop --no-audio --hwdec=auto --profile=high-quality --video-sync=display-resample --interpolation --tscale=oversample' '*' "${escOriginal}" >> ${logFile} 2>&1 &
//                 else
//                     IFS=',' read -ra MON_ARR <<< "${escOutputs}"
//                     for mon in "\${MON_ARR[@]}"; do
//                         mpvpaper -o 'loop --no-audio --hwdec=auto --profile=high-quality --video-sync=display-resample --interpolation --tscale=oversample' "\$mon" "${escOriginal}" >> ${logFile} 2>&1 &
//                     done
//                 fi
//             `;
//         } else {
//             wallpaperCmd = `
//                 echo "" >> ${logFile}
//                 echo "[$(date +'%H:%M:%S.%3N')] APPLYING LOCAL IMAGE: ${escOriginal} TO ${escOutputs}" >> ${logFile}
                
//                 if [ "${escOutputs}" = "all" ]; then
//                     swww img "${escOriginal}" --transition-type ${randomTransition} --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 >> ${logFile} 2>&1 &
//                 else
//                     swww img -o "${escOutputs}" "${escOriginal}" --transition-type ${randomTransition} --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 >> ${logFile} 2>&1 &
//                 fi
//             `;
//         }

//         const fullScript = `
//             cp "${isVideo ? escThumb : escOriginal}" /tmp/lock_bg.png || true
//             pkill mpvpaper || true
            
//             ${wallpaperCmd}
//             ( matugen image "${escThumb}" || true; bash "${escReload}" || true ) &
//         `;
//         Quickshell.execDetached(["bash", "-c", fullScript]);
//     }
    
//     Settings {
//         id: searchState
//         category: "QS_WallpaperPicker"
//         property string query: ""
//         property bool searched: false
//         property string lastName: ""
//     }

//     onIsSearchPausedChanged: {
//         Quickshell.execDetached(["bash", "-c", "echo '" + (isSearchPaused ? "pause" : "run") + "' > /tmp/ddg_search_control"]);
//     }

//     onVisibleChanged: {
//         if (!visible) {
//             window.initialFocusSet = false;
//             window.searchIndexRestored = false;
//             window.isApplying = false;
//             window.isMonitorSelectorOpen = false;
            
//             if (window.hasSearched) {
//                 window.isSearchPaused = true;
//             }
//         } else {
//             window.isFilterAnimating = true;
//             filterAnimationTimer.restart();

//             if (window.currentFilter !== "Search") {
//                 window.applyFilters(true);
//             } else if (window.hasSearched) {
//                 window.searchIndexRestored = false;
//                 window.isSearchPaused = true;
//                 window.trySearchFocus();
//                 window.syncSearchModel();
//             }
//         }
//     }

//     property bool isLoading: localFolderModel.status === FolderListModel.Loading || 
//                              srcModel.status === FolderListModel.Loading ||
//                              (window.currentFilter === "Search" && searchFolderModel.status === FolderListModel.Loading)

//     property bool showSpinner: window.isDownloadingWallpaper || 
//                                (window.currentFilter === "Search" && window.hasSearched && !window.isSearchPaused) || 
//                                (window.currentFilter !== "Search" && window.isLoading)

//     property string currentNotification: {
//         if (window.isDownloadingWallpaper) return "Downloading wallpaper...";

//         if (window.currentFilter === "Search") {
//             if (!window.hasSearched) return "Type something to search...";
//             if (window.isSearchPaused) return "Search Paused";
//             if (window.visibleItemCount === 0) return "Searching DDG (FHD+)...";
//             return "Generating thumbnails...";
//         }

//         if (isLoading) return "Generating thumbnails...";
//         if (window.visibleItemCount === 0) return "No wallpapers found";
        
//         if (window.currentFilter === "All") return "";
//         if (window.currentFilter === "Video") return "Videos";
        
//         return window.currentFilter;
//     }
    
//     property bool showNotification: !window.isStartup && currentNotification !== ""

//     function getCleanName(name) {
//         if (!name) return "";
//         let clean = String(name);
//         return clean.startsWith("000_") ? clean.substring(4) : clean;
//     }

//     function isDownloaded(name) {
//         if (!name) return false;
//         for (let i = 0; i < srcModel.count; i++) {
//             if (srcModel.get(i, "fileName") === name) return true;
//         }
//         return false;
//     }

//     onWidgetArgChanged: {
//         if (widgetArg !== "") {
//             targetWallName = widgetArg;
//             initialFocusSet = false;
//             tryFocus();
//         }
//     }

//     function executeFocusRestore(targetIndex, isSearchRestore, requirePositioning) {
//         let targetModel = window.getModelForFilter(window.currentFilter);
        
//         if (targetIndex !== -1 && targetIndex < targetModel.count) {
//             window.isModelChanging = true;
            
//             if (requirePositioning) {
//                 view.forceLayout();
//                 view.positionViewAtIndex(targetIndex, ListView.Center);
//             }
            
//             view.currentIndex = targetIndex;
            
//             if (isSearchRestore) {
//                 window.searchIndexRestored = true;
//             }
            
//             window.isModelChanging = false;
//             window.initialFocusSet = true;
//         } else if (isSearchRestore) {
//             window.searchIndexRestored = true;
//         }
//     }

//     function tryFocus() {
//         if (initialFocusSet) return;

//         if (localProxyModel.count > 0) {
//             let foundIndex = -1;
//             let cleanTarget = window.getCleanName(targetWallName);

//             if (cleanTarget !== "") {
//                 for (let i = 0; i < localProxyModel.count; i++) {
//                     let fname = localProxyModel.get(i).fileName || "";
//                     if (window.getCleanName(fname) === cleanTarget) {
//                         foundIndex = i;
//                         break;
//                     }
//                 }
//             }

//             let finalIndex = foundIndex !== -1 ? foundIndex : 0;
//             window.executeFocusRestore(finalIndex, false, true);
//         }
//     }
    
//     function trySearchFocus() {
//         if (window.searchIndexRestored || searchProxyModel.count === 0) return;

//         if (window.lastSearchName === "") {
//              window.searchIndexRestored = true;
//              return;
//         }

//         for (let i = 0; i < searchProxyModel.count; i++) {
//             let fname = searchProxyModel.get(i).fileName || "";
//             if (fname === window.lastSearchName) {
//                 window.executeFocusRestore(i, true, true);
//                 return;
//             }
//         }
        
//         if (searchFolderModel.status === FolderListModel.Ready && searchProxyModel.count === searchFolderModel.count) {
//              window.searchIndexRestored = true;
//         }
//     }

//     function getModelForFilter(filter) {
//         return filter === "Search" ? searchProxyModel : localProxyModel;
//     }

//     function updateVisibleCount() {
//         let targetModel = window.getModelForFilter(window.currentFilter);
        
//         if (!targetModel || targetModel.count === 0) {
//             window.visibleItemCount = 0;
//             return;
//         }
//         let count = 0;
//         for (let i = 0; i < targetModel.count; i++) {
//             let fname = targetModel.get(i).fileName || "";
//             let isVid = fname.startsWith("000_");
//             if (checkItemMatchesFilter(fname, isVid, window.cacheVersion, window.currentFilter)) {
//                 count++;
//             }
//         }
//         window.visibleItemCount = count;
//     }

//     function triggerOnlineSearch() {
//         if (searchInput.text.trim() === "") return;
        
//         window.isModelChanging = true;
//         searchProxyModel.clear();
//         window.lastSearchName = "";
//         searchState.lastName = "";
        
//         if (window.currentFilter === "Search") {
//             view.currentIndex = 0;
//             view.positionViewAtIndex(0, ListView.Center);
//         }
//         window.isModelChanging = false;

//         window.searchIndexRestored = true;
//         window.isOnlineSearch = true;
//         window.hasSearched = true;
        
//         window.visibleItemCount = 0;
        
//         searchState.searched = true;
//         searchState.query = searchInput.text.trim();
        
//         window.isSearchPaused = false;
//         window.searchQuery = searchInput.text.trim();
        
//         let rawSearchDir = decodeURIComponent(window.searchDir.replace(/^file:\/\//, ""));
//         let scriptPath = decodeURIComponent(Qt.resolvedUrl("ddg_search.sh").toString().replace(/^file:\/\//, ""));
        
//         const cmd = `
//             exec > /tmp/qs_ddg_run.log 2>&1
//             echo "=== QML Shell Handoff Successful ==="
//             export PATH=$PATH:/run/current-system/sw/bin
            
//             echo "Gracefully stopping old processes..."
//             echo 'stop' > /tmp/ddg_search_control
            
//             for p in $(pgrep -f ddg_search.sh); do
//                 if [ "$p" != "$$" ] && [ "$p" != "$BASHPID" ]; then
//                     kill -9 $p 2>/dev/null || true
//                 fi
//             done
//             pkill -f "[g]et_ddg_links.py" || true
//             sleep 0.2
            
//             echo "Clearing old cache..."
//             rm -rf "${rawSearchDir}"/* || true
//             rm -f "${rawSearchDir}/../search_map.txt" || true
            
//             echo "Setting control state back to run..."
//             echo 'run' > /tmp/ddg_search_control
            
//             echo "Executing new search pipeline..."
//             bash "${scriptPath}" "${window.searchQuery}" &
//         `;
        
//         Quickshell.execDetached(["bash", "-c", cmd]);
        
//         searchInput.focus = false;
//         view.forceActiveFocus();
//     }

//     readonly property string homeDir: "file://" + Quickshell.env("HOME")
//     readonly property string thumbDir: homeDir + "/.cache/wallpaper_picker/thumbs"
//     readonly property string searchDir: homeDir + "/.cache/wallpaper_picker/search_thumbs"
//     readonly property string srcDir: {
//         const dir = Quickshell.env("WALLPAPER_DIR")
//         return (dir && dir !== "") 
//         ? dir 
//         : Quickshell.env("HOME") + "/Pictures/Wallpapers"
//     }

//     readonly property var transitions: ["simple", "fade", "left", "right", "top", "bottom", "wipe", "grow", "center", "outer", "random", "wave"]

//     readonly property real itemWidth: window.s(400)
//     readonly property real itemHeight: window.s(420)
//     readonly property real borderWidth: window.s(3)
//     readonly property real spacing: window.s(10)
//     readonly property real skewFactor: -0.35

//     Timer {
//         id: scrollThrottle
//         interval: 150
//     }

//     property bool isFilterAnimating: false
//     Timer {
//         id: filterAnimationTimer
//         interval: 800
//         onTriggered: window.isFilterAnimating = false
//     }

//     property bool isItemAnimating: false
//     Timer {
//         id: itemAnimationTimer
//         interval: 500
//         onTriggered: window.isItemAnimating = false
//     }

//     function getHexBucket(hexStr) {
//         if (!hexStr) return "Monochrome";
        
//         hexStr = String(hexStr).trim().replace(/#/g, '');
//         if (hexStr.length > 6) hexStr = hexStr.substring(0, 6);
//         if (hexStr.length !== 6) return "Monochrome";

//         let r = parseInt(hexStr.substring(0,2), 16) / 255;
//         let g = parseInt(hexStr.substring(2,4), 16) / 255;
//         let b = parseInt(hexStr.substring(4,6), 16) / 255;

//         if (isNaN(r) || isNaN(g) || isNaN(b)) return "Monochrome";

//         let max = Math.max(r, g, b), min = Math.min(r, g, b);
//         let d = max - min;
        
//         let h = 0;
//         let s = max === 0 ? 0 : d / max;
//         let v = max;

//         if (max !== min) {
//             if (max === r) {
//                 h = (g - b) / d + (g < b ? 6 : 0);
//             } else if (max === g) {
//                 h = (b - r) / d + 2;
//             } else {
//                 h = (r - g) / d + 4;
//             }
//             h /= 6;
//         }
//         h = h * 360;

//         if (s < 0.05 || v < 0.08) return "Monochrome";

//         if (h >= 345 || h < 15) return "Red";
//         if (h >= 15 && h < 45) return "Orange";
//         if (h >= 45 && h < 75) return "Yellow";
//         if (h >= 75 && h < 165) return "Green";
//         if (h >= 165 && h < 260) return "Blue";
//         if (h >= 260 && h < 315) return "Purple";
//         if (h >= 315 && h < 345) return "Pink";

//         return "Monochrome";
//     }

//     function checkItemMatchesFilter(fileName, isVid, cv, filter) {
//         if (filter === "Search") return true;

//         if (filter === "All") return true;
//         if (filter === "Video") return isVid;
        
//         let hexColor = window.colorMap[String(fileName)];
//         if (!hexColor) return filter === "Monochrome";
        
//         return window.getHexBucket(hexColor) === filter;
//     }

//     FolderListModel {
//         id: markerModel
//         folder: "file://" + Quickshell.env("HOME") + "/.cache/wallpaper_picker/colors_markers"
//         showDirs: false
//         nameFilters: ["*_HEX_*"]
        
//         onCountChanged: window.processMarkers()
//         onStatusChanged: {
//             if (status === FolderListModel.Ready) window.processMarkers()
//         }
//     }

//     FolderListModel {
//         id: srcModel
//         folder: "file://" + window.srcDir
//         nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"]
//         showDirs: false
        
//         onCountChanged: {
//             if (window.isDownloadingWallpaper && window.isDownloaded(window.currentDownloadName)) {
//                 window.isDownloadingWallpaper = false;
//             }
//         }
//     }

//     function processMarkers() {
//         let newMap = {};
//         for (let i = 0; i < markerModel.count; i++) {
//             let markerName = markerModel.get(i, "fileName") || "";
//             if (!markerName) continue;
            
//             let splitIdx = markerName.lastIndexOf("_HEX_");
//             if (splitIdx !== -1) {
//                 let fName = markerName.substring(0, splitIdx);
//                 let hexCode = markerName.substring(splitIdx + 5);
//                 newMap[fName] = "#" + hexCode;
//             }
//         }
//         window.colorMap = newMap;
//         window.cacheVersion++;
//         window.updateVisibleCount();
//     }

//     function triggerColorExtraction() {
//         const extractScript = `
//             COLOR_DIR="$HOME/.cache/wallpaper_picker/colors_markers"
//             THUMBS="$HOME/.cache/wallpaper_picker/thumbs"
//             CSV="$HOME/.cache/wallpaper_picker/colors.csv"
            
//             mkdir -p "$COLOR_DIR"
            
//             if [ -f "$CSV" ]; then
//                 while IFS=, read -r fname hexcode; do
//                     cleanhex=$(echo "$hexcode" | tr -d '\r#' | cut -c 1-6)
//                     if [ -n "$cleanhex" ] && [ -n "$fname" ]; then
//                         touch "$COLOR_DIR/$fname""_HEX_$cleanhex" 2>/dev/null
//                     fi
//                 done < "$CSV"
//                 mv "$CSV" "$CSV.bak" 2>/dev/null
//             fi
            
//             if command -v magick &> /dev/null; then CMD="magick"; else CMD="convert"; fi
            
//             for file in "$THUMBS"/*; do
//                 if [ -f "$file" ]; then
//                     filename=$(basename "$file")
//                     found=0
//                     for marker in "$COLOR_DIR/$filename"_HEX_*; do
//                         if [ -e "$marker" ]; then found=1; break; fi
//                     done
                    
//                     if [ $found -eq 0 ]; then
//                         hex=$($CMD "$file" -modulate 100,200 -resize "1x1^" -gravity center -extent 1x1 -depth 8 -format "%[hex:p{0,0}]" info:- 2>/dev/null | grep -oE '[0-9A-Fa-f]{6}' | head -n 1)
//                         if [ -n "$hex" ]; then
//                             touch "$COLOR_DIR/$filename""_HEX_$hex"
//                         fi
//                     fi
//                 fi
//             done
//         `;
//         Quickshell.execDetached(["bash", "-c", extractScript]);
//     }

//     function stepToNextValidIndex(direction) {
//         let targetModel = window.getModelForFilter(window.currentFilter);
//         if (!targetModel || targetModel.count === 0) return;
        
//         let start = view.currentIndex;
//         let found = -1;

//         if (direction === 1) {
//             for (let i = start + 1; i < targetModel.count; i++) {
//                 let fname = targetModel.get(i).fileName || "";
//                 let isVid = fname.startsWith("000_");
//                 if (checkItemMatchesFilter(fname, isVid, window.cacheVersion, window.currentFilter)) {
//                     found = i; break;
//                 }
//             }
//         } else {
//             for (let i = start - 1; i >= 0; i--) {
//                 let fname = targetModel.get(i).fileName || "";
//                 let isVid = fname.startsWith("000_");
//                 if (checkItemMatchesFilter(fname, isVid, window.cacheVersion, window.currentFilter)) {
//                     found = i; break;
//                 }
//             }
//         }

//         if (found !== -1) {
//             view.currentIndex = found;
//             return;
//         }

//         let filterOrder = ["All", "Video", "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink", "Monochrome"];
//         let currentFilterIdx = filterOrder.indexOf(window.currentFilter);

//         if (currentFilterIdx === -1) {
//             let current = start;
//             for (let i = 0; i < targetModel.count; i++) {
//                 current = (current + direction + targetModel.count) % targetModel.count;
//                 let fname = targetModel.get(current).fileName || "";
//                 let isVid = fname.startsWith("000_");
                
//                 if (checkItemMatchesFilter(fname, isVid, window.cacheVersion, window.currentFilter)) {
//                     view.currentIndex = current;
//                     return;
//                 }
//             }
//             return;
//         }

//         let nextFilterIdx = currentFilterIdx + direction;

//         if (nextFilterIdx >= 0 && nextFilterIdx < filterOrder.length) {
//             window.jumpToLastOnFilterChange = (direction === -1);
//             window.currentFilter = filterOrder[nextFilterIdx];
//         }
//     }

//     function cycleFilter(direction) {
//         let currentIdx = -1;
//         for (let i = 0; i < window.filterData.length; i++) {
//             if (window.filterData[i].name === window.currentFilter) {
//                 currentIdx = i;
//                 break;
//             }
//         }
        
//         if (currentIdx !== -1) {
//             let nextIdx = (currentIdx + direction + window.filterData.length) % window.filterData.length;
//             window.currentFilter = window.filterData[nextIdx].name;
//         }
//     }

//     function applyFilters(forceSnap) {
//         let targetModel = window.getModelForFilter(window.currentFilter);
        
//         if (!targetModel || targetModel.count === 0) {
//             window.updateVisibleCount();
//             return;
//         }

//         if (window.currentFilter === "Search") {
//             window.updateVisibleCount();
//             return;
//         }

//         let firstValidIndex = -1;
//         let lastValidIndex = -1;
//         let cleanTarget = window.getCleanName(window.targetWallName);
//         let targetIndex = -1;

//         for (let i = 0; i < targetModel.count; i++) {
//             let fname = targetModel.get(i).fileName || "";
//             let isVid = fname.startsWith("000_");
            
//             if (checkItemMatchesFilter(fname, isVid, window.cacheVersion, window.currentFilter)) {
//                 if (firstValidIndex === -1) {
//                     firstValidIndex = i;
//                 }
//                 lastValidIndex = i;
                
//                 if (cleanTarget !== "" && window.getCleanName(fname) === cleanTarget) {
//                     targetIndex = i;
//                 }
//             }
//         }

//         let indexToFocus = -1;

//         if (targetIndex !== -1) {
//              indexToFocus = targetIndex;
//         } else if (window.jumpToLastOnFilterChange && lastValidIndex !== -1) {
//             indexToFocus = lastValidIndex;
//         } else if (firstValidIndex !== -1) {
//             indexToFocus = firstValidIndex;
//         }

//         window.jumpToLastOnFilterChange = false;
        
//         if (indexToFocus !== -1) {
//             window.executeFocusRestore(indexToFocus, false, forceSnap === true);
//         }
        
//         window.updateVisibleCount();
//     }

//     onCurrentFilterChanged: {
//         window.isFilterAnimating = true;
//         filterAnimationTimer.restart();
//         window.isModelChanging = true;
//         let returningFromSearch = (window._lastFilter === "Search" && window.currentFilter !== "Search");
//         window._lastFilter = window.currentFilter;
        
//         if (returningFromSearch) {
//              window.searchIndexRestored = false;
//         }
        
//         Qt.callLater(() => {
//             view.forceActiveFocus();

//             if (window.currentFilter === "Search") {
//                 if (window.hasSearched) {
//                     window.searchIndexRestored = false;
//                     window.trySearchFocus();
//                 }
//             } else {
//                 window.applyFilters(returningFromSearch);
//             }
//             window.isModelChanging = false;
//         });
//     }

//     Shortcut { 
//         sequence: "Left"; 
//         enabled: !window.isScrollingBlocked && !window.isApplying
//         onActivated: window.stepToNextValidIndex(-1) 
//     }
//     Shortcut { 
//         sequence: "Right"; 
//         enabled: !window.isScrollingBlocked && !window.isApplying
//         onActivated: window.stepToNextValidIndex(1) 
//     }
    
//     Shortcut { 
//         sequence: "Return"
//         enabled: !searchInput.activeFocus && !window.isScrollingBlocked && !window.isApplying
//         onActivated: { 
//             let targetModel = window.getModelForFilter(window.currentFilter);
//             if (view.currentIndex >= 0 && view.currentIndex < targetModel.count) {
//                 let fname = targetModel.get(view.currentIndex).fileName;
//                 if (fname) {
//                     let isVid = String(fname).startsWith("000_");
//                     window.applyWallpaper(String(fname), isVid);
//                 }
//             }
//         } 
//     }
    
//     Shortcut { sequence: "Escape"; enabled: !window.isApplying; onActivated: { if (window.currentFilter === "Search") { window.currentFilter = "All"; } } }
//     Shortcut { sequence: "Tab"; enabled: !window.isApplying; onActivated: window.cycleFilter(1) }
//     Shortcut { sequence: "Backtab"; enabled: !window.isApplying; onActivated: window.cycleFilter(-1) }

//     ListModel { id: localProxyModel }
//     ListModel { id: searchProxyModel }
    
//     readonly property var activeModel: window.currentFilter === "Search" ? searchProxyModel : localProxyModel

//     FolderListModel {
//         id: localFolderModel
//         folder: window.thumbDir
//         nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"]
//         showDirs: false
//         sortField: FolderListModel.Name
        
//         onCountChanged: window.syncLocalModel()
//         onStatusChanged: { if (status === FolderListModel.Ready) window.syncLocalModel() }
//     }

//     function syncLocalModel() {
//         let startIdx = localProxyModel.count;
//         let endIdx = localFolderModel.count;
        
//         if (endIdx < startIdx) {
//             window.isModelChanging = true;
//             localProxyModel.clear();
//             startIdx = 0;
//             window.isModelChanging = false;
//         }

//         let batch = [];
//         for (let i = startIdx; i < endIdx; i++) {
//             let fn = localFolderModel.get(i, "fileName");
//             let fu = localFolderModel.get(i, "fileUrl");
//             if (fn !== undefined) {
//                 batch.push({ "fileName": fn, "fileUrl": String(fu) });
//             }
//         }
        
//         if (batch.length > 0) {
//             localProxyModel.append(batch);
//         }

//         if (window.currentFilter !== "Search") window.updateVisibleCount();
        
//         if (!window.initialFocusSet && window.currentFilter !== "Search" && localProxyModel.count > 0) {
//             window.tryFocus();
//         }
//     }

//     function syncSearchModel() {
//         let startIdx = searchProxyModel.count;
//         let endIdx = searchFolderModel.count;
        
//         if (endIdx < startIdx) {
//             window.isModelChanging = true;
//             searchProxyModel.clear();
//             startIdx = 0;
//             window.isModelChanging = false;
//         }

//         let batch = [];
//         for (let i = startIdx; i < endIdx; i++) {
//             let fn = searchFolderModel.get(i, "fileName");
//             let fu = searchFolderModel.get(i, "fileUrl");
//             if (fn !== undefined) {
//                 batch.push({ "fileName": fn, "fileUrl": String(fu) });
//             }
//         }
        
//         if (batch.length > 0) {
//             searchProxyModel.append(batch);
//         }

//         if (window.currentFilter === "Search") window.updateVisibleCount();

//         if (window.currentFilter === "Search" && window.hasSearched) {
//             if (!window.searchIndexRestored) {
//                 window.trySearchFocus();
//             }
            
//             if (window.isScrollingBlocked && startIdx === 0 && searchProxyModel.count > 0 && window.lastSearchName === "") {
//                 view.forceLayout();
//                 view.currentIndex = 0;
//                 view.positionViewAtIndex(0, ListView.Center);
//             }
//         }
//     }
//     FolderListModel {
//         id: searchFolderModel
//         folder: window.searchDir
//         nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"]
//         showDirs: false
//         sortField: FolderListModel.Name
        
//         onFolderChanged: {
//             window.isModelChanging = true;
//             searchProxyModel.clear()
//             window.isModelChanging = false;
//         }
        
//         onCountChanged: window.syncSearchModel()
//         onStatusChanged: { if (status === FolderListModel.Ready) window.syncSearchModel() }
//     }

     
//     ListView {
//         id: view
//         anchors.fill: parent
        
//         opacity: window.isReady ? 1.0 : 0.0
//         anchors.margins: window.isReady ? 0 : window.s(40)
        
//         Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }
//         Behavior on anchors.margins { NumberAnimation { duration: 700; easing.type: Easing.OutExpo } }

//         spacing: 0
//         orientation: ListView.Horizontal
//         clip: false

//         interactive: !window.isScrollingBlocked && !window.isApplying
//         cacheBuffer: 2000

//         highlightRangeMode: ListView.StrictlyEnforceRange
//         preferredHighlightBegin: (width / 2) - ((window.itemWidth * 1.5 + window.spacing) / 2)
//         preferredHighlightEnd: (width / 2) + ((window.itemWidth * 1.5 + window.spacing) / 2)
        
//         highlightMoveDuration: window.initialFocusSet ? 500 : 0
//         focus: true
        
//         onCurrentIndexChanged: {
//             window.isItemAnimating = true;
//             itemAnimationTimer.restart();

//             if (view.model !== searchProxyModel || window.currentFilter !== "Search") return;
            
//             if (!window.isModelChanging && window.hasSearched && window.searchIndexRestored) {
//                 if (currentIndex >= 0 && currentIndex < searchProxyModel.count) {
//                     let fname = searchProxyModel.get(currentIndex).fileName;
//                     if (fname !== undefined && fname !== "") {
//                         window.lastSearchName = String(fname);
//                         searchState.lastName = String(fname);
//                     }
//                 }
//             }
//         }
        
//         add: Transition {
//             enabled: window.initialFocusSet
//             ParallelAnimation {
//                 NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic }
//                 NumberAnimation { property: "scale"; from: 0.5; to: 1; duration: 400; easing.type: Easing.OutBack }
//             }
//         }
//         addDisplaced: Transition {
//             enabled: window.initialFocusSet
//             NumberAnimation { property: "x"; duration: 400; easing.type: Easing.OutCubic }
//         }

//         header: Item { width: Math.max(0, (view.width / 2) - ((window.itemWidth * 1.5) / 2)) }
//         footer: Item { width: Math.max(0, (view.width / 2) - ((window.itemWidth * 1.5) / 2)) }

//         model: window.activeModel

//         MouseArea {
//             anchors.fill: parent
//             acceptedButtons: Qt.NoButton

//             onWheel: (wheel) => {
//                 if (window.isScrollingBlocked || window.isApplying) {
//                     wheel.accepted = true;
//                     return;
//                 }

//                 if (scrollThrottle.running) {
//                    wheel.accepted = true
//                    return
//                 }

//                 let dx = wheel.angleDelta.x
//                 let dy = wheel.angleDelta.y
//                 let delta = Math.abs(dx) > Math.abs(dy) ? dx : dy

//                 scrollAccum += delta

//                 if (Math.abs(scrollAccum) >= scrollThreshold) {
//                     window.stepToNextValidIndex(scrollAccum > 0 ? -1 : 1)
//                     scrollAccum = 0
//                     scrollThrottle.start()
//                 }

//                 wheel.accepted = true
//             }        
//         }

//         delegate: Item {
//             id: delegateRoot
            
//             readonly property string safeFileName: fileName !== undefined ? String(fileName) : ""
            
//             readonly property bool isCurrent: ListView.isCurrentItem && !window.isScrollingBlocked
//             readonly property bool isFakeSelected: window.isScrollingBlocked && index === 0
//             readonly property bool isVisuallyEnlarged: isCurrent || isFakeSelected
            
//             readonly property bool isVideo: safeFileName.startsWith("000_")
//             readonly property bool matchesFilter: window.checkItemMatchesFilter(safeFileName, isVideo, window.cacheVersion, window.currentFilter)
            
//             readonly property real targetWidth: isVisuallyEnlarged ? (window.itemWidth * 1.5) : (window.itemWidth * 0.5)
//             readonly property real targetHeight: isVisuallyEnlarged ? (window.itemHeight + window.s(30)) : window.itemHeight
            
//             property bool isPlayingVideo: false

//             Timer {
//                 id: videoPlayTimer
//                 interval: 250
//                 running: delegateRoot.isVisuallyEnlarged && delegateRoot.isVideo && !window.isScrollingBlocked && !window.isFilterAnimating && !window.isItemAnimating
//                 onTriggered: {
//                     if (delegateRoot.isVisuallyEnlarged && delegateRoot.isVideo) {
//                         delegateRoot.isPlayingVideo = true;
//                         previewPlayer.play();
//                     }
//                 }
//             }

//             onIsVisuallyEnlargedChanged: {
//                 if (!isVisuallyEnlarged) {
//                     isPlayingVideo = false;
//                     videoPlayTimer.stop();
//                     previewPlayer.stop();
//                 }
//             }
            
//             width: matchesFilter ? (targetWidth + window.spacing) : 0
//             visible: width > 0.1 || opacity > 0.01
//             opacity: matchesFilter ? (isVisuallyEnlarged ? 1.0 : 0.6) : 0.0
            
//             scale: matchesFilter ? 1.0 : 0.5

//             height: matchesFilter ? targetHeight : 0
//             anchors.verticalCenter: parent.verticalCenter
//             anchors.verticalCenterOffset: window.s(15)

//             z: isVisuallyEnlarged ? 10 : 1
            
//             Behavior on scale { enabled: window.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
//             Behavior on width { enabled: window.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
//             Behavior on height { enabled: window.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
//             Behavior on opacity { enabled: window.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }

//             Item {
//                 anchors.centerIn: parent
//                 anchors.horizontalCenterOffset: ((window.itemHeight - height) / 2) * window.skewFactor
                
//                 width: parent.width > 0 ? parent.width * (targetWidth / (targetWidth + window.spacing)) : 0
//                 height: parent.height

//                 transform: Matrix4x4 {
//                     property real s: window.skewFactor
//                     matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
//                 }
                
//                 MouseArea {
//                     anchors.fill: parent
//                     enabled: delegateRoot.matchesFilter && !window.isScrollingBlocked && !window.isApplying
//                     onClicked: {
//                         view.currentIndex = index
//                         window.applyWallpaper(delegateRoot.safeFileName, delegateRoot.isVideo)
//                     }
//                 }

//                 Image {
//                     anchors.fill: parent
//                     source: fileUrl !== undefined ? fileUrl : ""
//                     sourceSize: Qt.size(1, 1)
//                     fillMode: Image.Stretch
//                     visible: true
//                     asynchronous: true
//                 }

//                 Item {
//                     anchors.fill: parent
//                     anchors.margins: window.borderWidth
//                     Rectangle { anchors.fill: parent; color: _theme.base }
//                     clip: true

//                     Image {
//                         anchors.centerIn: parent
//                         anchors.horizontalCenterOffset: window.s(-50)
//                         width: (window.itemWidth * 1.5) + ((window.itemHeight + window.s(30)) * Math.abs(window.skewFactor)) + window.s(50)
//                         height: window.itemHeight + window.s(30)
//                         fillMode: Image.PreserveAspectCrop
//                         source: fileUrl !== undefined ? fileUrl : ""
//                         asynchronous: true

//                         transform: Matrix4x4 {
//                             property real s: -window.skewFactor
//                             matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
//                         }
//                     }
                    
//                     MediaPlayer {
//                         id: previewPlayer
//                         source: delegateRoot.isPlayingVideo ? "file://" + window.srcDir + "/" + window.getCleanName(delegateRoot.safeFileName) : ""
//                         audioOutput: AudioOutput { muted: true }
//                         videoOutput: previewOutput
//                         loops: MediaPlayer.Infinite
//                     }

//                     VideoOutput {
//                         id: previewOutput
//                         anchors.centerIn: parent
//                         anchors.horizontalCenterOffset: window.s(-50)
//                         width: (window.itemWidth * 1.5) + ((window.itemHeight + window.s(30)) * Math.abs(window.skewFactor)) + window.s(50)
//                         height: window.itemHeight + window.s(30)
//                         fillMode: VideoOutput.PreserveAspectCrop
//                         visible: delegateRoot.isPlayingVideo && previewPlayer.playbackState === MediaPlayer.PlayingState

//                         transform: Matrix4x4 {
//                             property real s: -window.skewFactor
//                             matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
//                         }
//                     }
                    
//                     Rectangle {
//                         visible: delegateRoot.isVideo && (!delegateRoot.isPlayingVideo || previewPlayer.playbackState !== MediaPlayer.PlayingState)
//                         anchors.top: parent.top
//                         anchors.right: parent.right
//                         anchors.margins: window.s(10)
//                         width: window.s(32)
//                         height: window.s(32)
//                         radius: window.s(6)
//                         color: Qt.rgba(_theme.base.r, _theme.base.g, _theme.base.b, 0.6)
//                         transform: Matrix4x4 {
//                             property real s: -window.skewFactor
//                             matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
//                         }
                        
//                         Canvas {
//                             anchors.fill: parent
//                             anchors.margins: window.s(8)
//                             property real scaleTrigger: window.s(1)
//                             onScaleTriggerChanged: requestPaint()
//                             onPaint: {
//                                 var ctx = getContext("2d");
//                                 var s = window.s;
//                                 ctx.reset();
//                                 ctx.fillStyle = Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.93);
//                                 ctx.beginPath();
//                                 ctx.moveTo(s(4), 0);
//                                 ctx.lineTo(s(14), s(8));
//                                 ctx.lineTo(s(4), s(16));
//                                 ctx.closePath();
//                                 ctx.fill();
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }

//     Rectangle {
//         id: filterBarBackground
//         anchors.top: parent.top
        
//         anchors.topMargin: window.isReady ? window.s(40) : window.s(-100)
//         opacity: window.isReady ? 1.0 : 0.0
//         Behavior on anchors.topMargin { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
//         Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

//         anchors.horizontalCenter: parent.horizontalCenter
//         z: 20
//         height: window.s(56)
//         width: filterRow.width + window.s(24)
//         radius: window.s(14)
        
//         color: Qt.rgba(_theme.mantle.r, _theme.mantle.g, _theme.mantle.b, 0.90)
//         border.color: _theme.surface2
//         border.width: 1

//         Row {
//             id: filterRow
//             anchors.centerIn: parent
//             spacing: window.s(12)

//             Rectangle {
//                 id: notifDrawer
//                 height: window.s(44)
//                 property real paddingLeft: window.showSpinner ? window.s(40) : window.s(16)
//                 property real targetWidth: window.showNotification ? Math.min(notifTextDrawer.implicitWidth + paddingLeft + window.s(20), window.s(300)) : 0
//                 width: targetWidth
//                 visible: width > 0.1
//                 radius: window.s(10)
//                 clip: true
//                 anchors.verticalCenter: parent.verticalCenter
                
//                 color: window.showNotification ? _theme.surface2 : "transparent"
//                 border.color: window.showNotification ? _theme.surface1 : "transparent"
//                 border.width: 1

//                 Behavior on width { 
//                     NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 0.5 } 
//                 }
//                 Behavior on color { ColorAnimation { duration: 400 } }
//                 Behavior on border.color { ColorAnimation { duration: 400 } }

//                 Item {
//                     visible: window.showSpinner
//                     width: window.s(44)
//                     height: window.s(44)
//                     anchors.left: parent.left
//                     anchors.verticalCenter: parent.verticalCenter

//                     Canvas {
//                         id: notifSpinner
//                         width: window.s(14)
//                         height: window.s(14)
//                         anchors.centerIn: parent
//                         property real scaleTrigger: window.s(1)
//                         onScaleTriggerChanged: requestPaint()

//                         onPaint: {
//                             var ctx = getContext("2d");
//                             var s = window.s;
//                             ctx.reset();
//                             ctx.lineWidth = s(2);
//                             ctx.strokeStyle = Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.3);
//                             ctx.beginPath();
//                             ctx.arc(s(7), s(7), s(5), 0, Math.PI * 2);
//                             ctx.stroke();
                            
//                             ctx.strokeStyle = Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.9);
//                             ctx.beginPath();
//                             ctx.arc(s(7), s(7), s(5), 0, Math.PI * 0.5);
//                             ctx.stroke();
//                         }
//                         RotationAnimation on rotation {
//                             loops: Animation.Infinite
//                             from: 0; to: 360
//                             duration: 800
//                             running: window.showSpinner && window.showNotification
//                         }
//                     }
//                 }

//                 Text {
//                     id: notifTextDrawer
//                     anchors.left: parent.left
//                     anchors.leftMargin: window.showSpinner ? window.s(40) : window.s(16)
//                     anchors.verticalCenter: parent.verticalCenter
//                     width: Math.min(implicitWidth, window.s(300) - anchors.leftMargin - window.s(16))
//                     text: window.currentNotification
                    
//                     color: _theme.text
//                     font.family: "JetBrains Mono"
//                     font.pixelSize: window.s(14)
//                     font.bold: true
//                     elide: Text.ElideRight

//                     opacity: window.showNotification ? 0.9 : 0.0
//                     Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
//                     Behavior on anchors.leftMargin { 
//                         NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 0.5 } 
//                     }
//                 }
//             }

//             Rectangle {
//                 id: monitorDrawer
//                 visible: monitorModel.count > 1
//                 height: window.s(44)
                
//                 property real expandedWidth: window.s(44) + monitorListRow.width + window.s(8)
//                 width: visible ? (window.isMonitorSelectorOpen ? expandedWidth : window.s(44)) : 0
                
//                 radius: window.s(10)
//                 clip: true
//                 anchors.verticalCenter: parent.verticalCenter
                
//                 color: window.isMonitorSelectorOpen ? _theme.surface2 : "transparent"
//                 border.color: window.isMonitorSelectorOpen ? _theme.text : _theme.surface1
//                 border.width: window.isMonitorSelectorOpen ? window.s(2) : 1
                
//                 Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
//                 Behavior on color { ColorAnimation { duration: 400 } }
//                 Behavior on border.color { ColorAnimation { duration: 400 } }

//                 MouseArea {
//                     id: monitorIconMouse
//                     width: window.s(44)
//                     height: window.s(44)
//                     anchors.left: parent.left
//                     anchors.verticalCenter: parent.verticalCenter
//                     hoverEnabled: true
//                     enabled: !window.isApplying
//                     cursorShape: Qt.PointingHandCursor
//                     onClicked: window.isMonitorSelectorOpen = !window.isMonitorSelectorOpen
//                 }

//                 Canvas {
//                     id: monitorIcon
//                     width: window.s(18)
//                     height: window.s(18)
//                     anchors.centerIn: monitorIconMouse
//                     property string activeColor: window.isMonitorSelectorOpen ? _theme.text : (monitorIconMouse.containsMouse ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7))
//                     onActiveColorChanged: requestPaint()
//                     property real scaleTrigger: window.s(1)
//                     onScaleTriggerChanged: requestPaint()

//                     onPaint: {
//                         var ctx = getContext("2d");
//                         var s = window.s;
//                         ctx.reset();
//                         ctx.lineWidth = s(2);
//                         ctx.strokeStyle = activeColor;
//                         ctx.lineJoin = "round";
//                         ctx.lineCap = "round";
                        
//                         ctx.beginPath();
//                         ctx.rect(s(2), s(3), s(14), s(9));
//                         ctx.stroke();
                        
//                         ctx.beginPath();
//                         ctx.moveTo(s(9), s(12));
//                         ctx.lineTo(s(9), s(16));
//                         ctx.moveTo(s(5), s(16));
//                         ctx.lineTo(s(13), s(16));
//                         ctx.stroke();
//                     }
//                 }

//                 Row {
//                     id: monitorListRow
//                     anchors.left: monitorIconMouse.right
//                     anchors.verticalCenter: parent.verticalCenter
//                     spacing: window.s(8)
                    
//                     opacity: window.isMonitorSelectorOpen ? 1.0 : 0.0
//                     Behavior on opacity { NumberAnimation { duration: 300 } }

//                     Repeater {
//                         model: monitorModel
//                         delegate: Item {
//                             width: monitorText.contentWidth + window.s(16)
//                             height: window.s(32)
//                             anchors.verticalCenter: parent.verticalCenter
                            
//                             Rectangle {
//                                 anchors.fill: parent
//                                 radius: window.s(6)
//                                 color: model.selected ? _theme.text : _theme.surface1
//                                 border.color: model.selected ? _theme.text : _theme.surface2
//                                 border.width: 1
                                
//                                 Behavior on color { ColorAnimation { duration: 250 } }
//                                 Behavior on border.color { ColorAnimation { duration: 250 } }
                                
//                                 Text {
//                                     id: monitorText
//                                     text: model.name
//                                     anchors.centerIn: parent
//                                     color: model.selected ? _theme.base : _theme.text
//                                     font.family: "JetBrains Mono"
//                                     font.pixelSize: window.s(12)
//                                     font.bold: model.selected
//                                     Behavior on color { ColorAnimation { duration: 250 } }
//                                 }
//                             }

//                             MouseArea {
//                                 anchors.fill: parent
//                                 hoverEnabled: true
//                                 enabled: window.isMonitorSelectorOpen && !window.isApplying
//                                 cursorShape: Qt.PointingHandCursor
//                                 onClicked: {
//                                     if (model.selected) {
//                                         let activeCount = 0;
//                                         for (let i = 0; i < monitorModel.count; i++) {
//                                             if (monitorModel.get(i).selected) activeCount++;
//                                         }
//                                         if (activeCount > 1) {
//                                             monitorModel.setProperty(index, "selected", false);
//                                         }
//                                     } else {
//                                         monitorModel.setProperty(index, "selected", true);
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }

//             Repeater {
//                 model: window.filterData

//                 delegate: Item {
//                     visible: modelData.name !== "Search"
//                     width: !visible ? 0 : ((modelData.name === "Video" || modelData.name === "All") ? window.s(44) : (modelData.hex === "" ? filterText.contentWidth + window.s(24) : window.s(36)))
//                     height: !visible ? 0 : window.s(36)
//                     anchors.verticalCenter: parent.verticalCenter
                    
//                     Rectangle {
//                         anchors.fill: parent
//                         radius: window.s(10)
//                         color: modelData.hex === "" 
//                                 ? (window.currentFilter === modelData.name ? _theme.surface2 : "transparent") 
//                                 : modelData.hex
                        
//                         border.color: window.currentFilter === modelData.name ? _theme.text : _theme.surface1
//                         border.width: window.currentFilter === modelData.name ? window.s(2) : 1
//                         scale: window.currentFilter === modelData.name ? 1.15 : (filterMouse.containsMouse ? 1.08 : 1.0)
                        
//                         Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
//                         Behavior on border.color { ColorAnimation { duration: 300 } }

//                         Text {
//                             id: filterText
//                             visible: modelData.hex === "" && modelData.name !== "Video" && modelData.name !== "All"
//                             text: modelData.label
//                             anchors.centerIn: parent
//                             color: window.currentFilter === modelData.name ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7)
//                             font.family: "JetBrains Mono"
//                             font.pixelSize: window.s(14)
//                             font.bold: window.currentFilter === modelData.name
//                             Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutQuart } }
//                         }

//                         Canvas {
//                             visible: modelData.name === "Video"
//                             width: window.s(14); height: window.s(16)
//                             anchors.centerIn: parent
//                             anchors.horizontalCenterOffset: window.s(2)
//                             property string activeColor: window.currentFilter === modelData.name ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7)
//                             onActiveColorChanged: requestPaint()
//                             property real scaleTrigger: window.s(1)
//                             onScaleTriggerChanged: requestPaint()

//                             onPaint: {
//                                 var ctx = getContext("2d");
//                                 var s = window.s;
//                                 ctx.reset();
//                                 ctx.fillStyle = activeColor;
//                                 ctx.beginPath();
//                                 ctx.moveTo(0, 0);
//                                 ctx.lineTo(s(14), s(8));
//                                 ctx.lineTo(0, s(16));
//                                 ctx.closePath();
//                                 ctx.fill();
//                             }
//                         }

//                         Canvas {
//                             visible: modelData.name === "All"
//                             width: window.s(14); height: window.s(14)
//                             anchors.centerIn: parent
//                             property string activeColor: window.currentFilter === modelData.name ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7)
//                             onActiveColorChanged: requestPaint()
//                             property real scaleTrigger: window.s(1)
//                             onScaleTriggerChanged: requestPaint()

//                             onPaint: {
//                                 var ctx = getContext("2d");
//                                 var s = window.s;
//                                 ctx.reset();
//                                 ctx.fillStyle = activeColor;
//                                 ctx.fillRect(0, 0, s(6), s(6));
//                                 ctx.fillRect(s(8), 0, s(6), s(6));
//                                 ctx.fillRect(0, s(8), s(6), s(6));
//                                 ctx.fillRect(s(8), s(8), s(6), s(6));
//                             }
//                         }
//                     }

//                     MouseArea {
//                         id: filterMouse
//                         anchors.fill: parent
//                         hoverEnabled: true
//                         enabled: !window.isApplying
//                         onClicked: window.currentFilter = modelData.name
//                         cursorShape: Qt.PointingHandCursor
//                     }
//                 }
//             }

//             Rectangle {
//                 id: searchControlBtn
//                 visible: window.currentFilter === "Search" && window.hasSearched
//                 width: visible ? window.s(44) : 0
//                 height: window.s(44)
//                 radius: window.s(10)
//                 clip: true
//                 anchors.verticalCenter: parent.verticalCenter
//                 color: window.isSearchPaused ? _theme.surface2 : "transparent"
//                 border.color: window.isSearchPaused ? _theme.text : _theme.surface1
//                 border.width: window.isSearchPaused ? window.s(2) : 1
                
//                 Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
//                 Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutQuart } }
                
//                 MouseArea {
//                     id: scMouse
//                     anchors.fill: parent
//                     hoverEnabled: true
//                     enabled: !window.isApplying
//                     cursorShape: Qt.PointingHandCursor
//                     onClicked: window.isSearchPaused = !window.isSearchPaused
//                 }
                
//                 Canvas {
//                     width: window.s(44); height: window.s(44)
//                     anchors.centerIn: parent
//                     property bool paused: window.isSearchPaused
//                     property string activeColor: paused ? _theme.text : (scMouse.containsMouse ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7))
//                     onActiveColorChanged: requestPaint()
//                     onPausedChanged: requestPaint()
//                     property real scaleTrigger: window.s(1)
//                     onScaleTriggerChanged: requestPaint()
                    
//                     onPaint: {
//                         var ctx = getContext("2d");
//                         var s = window.s;
//                         ctx.reset();
//                         ctx.fillStyle = activeColor;
//                         if (!paused) {
//                             ctx.fillRect(s(15), s(14), s(4), s(16));
//                             ctx.fillRect(s(25), s(14), s(4), s(16));
//                         } else {
//                             ctx.beginPath();
//                             ctx.moveTo(s(16), s(12));
//                             ctx.lineTo(s(32), s(22));
//                             ctx.lineTo(s(16), s(32));
//                             ctx.closePath();
//                             ctx.fill();
//                         }
//                     }
//                 }
//             }

//             Rectangle {
//                 id: searchBox
//                 height: window.s(44)
//                 width: window.currentFilter === "Search" ? window.s(360) : window.s(44)
//                 radius: window.s(10)
//                 clip: true
//                 anchors.verticalCenter: parent.verticalCenter
                
//                 color: window.currentFilter === "Search" ? Qt.rgba(_theme.surface2.r, _theme.surface2.g, _theme.surface2.b, 0.8) : "transparent"
//                 border.color: window.currentFilter === "Search" ? _theme.text : _theme.surface1
//                 border.width: window.currentFilter === "Search" ? window.s(2) : 1
                
//                 Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
//                 Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutQuart } }
//                 Behavior on border.color { ColorAnimation { duration: 400 } }

//                 MouseArea {
//                     id: searchMouseArea
//                     anchors.fill: parent
//                     hoverEnabled: true
//                     enabled: !window.isApplying
//                     cursorShape: Qt.PointingHandCursor
//                     onClicked: {
//                         if (window.currentFilter !== "Search") {
//                             window.currentFilter = "Search"
//                         } else {
//                             window.currentFilter = "All"
//                         }
//                     }
//                 }

//                 Canvas {
//                     id: searchIcon
//                     width: window.s(44)
//                     height: window.s(44)
//                     anchors.left: parent.left
//                     anchors.leftMargin: window.currentFilter === "Search" ? window.s(5) : 0
//                     anchors.verticalCenter: parent.verticalCenter
//                     Behavior on anchors.leftMargin { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
//                     property string activeColor: window.currentFilter === "Search" ? _theme.text : (searchMouseArea.containsMouse ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7))
//                     onActiveColorChanged: requestPaint()
//                     property real scaleTrigger: window.s(1)
//                     onScaleTriggerChanged: requestPaint()

//                     onPaint: {
//                         var ctx = getContext("2d");
//                         var s = window.s;
//                         ctx.reset();
//                         ctx.lineWidth = s(3);
//                         ctx.strokeStyle = activeColor;
//                         ctx.beginPath();
//                         ctx.arc(s(18), s(18), s(7), 0, Math.PI * 2);
//                         ctx.stroke();
//                         ctx.beginPath();
//                         ctx.moveTo(s(23), s(23));
//                         ctx.lineTo(s(31), s(31));
//                         ctx.stroke();
//                     }
//                 }

//                 TextInput {
//                     id: searchInput
//                     anchors.left: searchIcon.right
//                     anchors.right: submitBtn.left
//                     anchors.rightMargin: window.s(8)
//                     anchors.verticalCenter: parent.verticalCenter
                    
//                     opacity: window.currentFilter === "Search" ? 1.0 : 0.0
//                     visible: opacity > 0
//                     Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
                    
//                     color: _theme.text
//                     font.family: "JetBrains Mono"
//                     font.pixelSize: window.s(16)
//                     clip: true
                    
//                     onTextEdited: {
//                         window.hasSearched = false;
//                         searchState.searched = false;
//                     }
                    
//                     onAccepted: {
//                         window.triggerOnlineSearch();
//                         searchInput.focus = false;
//                         view.forceActiveFocus();
//                     }
//                 }

//                 Rectangle {
//                     id: submitBtn
//                     width: window.s(32)
//                     height: window.s(32)
//                     radius: window.s(8)
//                     anchors.right: parent.right
//                     anchors.rightMargin: window.s(8)
//                     anchors.verticalCenter: parent.verticalCenter
                    
//                     opacity: window.currentFilter === "Search" ? 1.0 : 0.0
//                     visible: opacity > 0
//                     Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }

//                     color: submitMouseArea.containsMouse ? _theme.surface1 : "transparent"
//                     border.color: submitMouseArea.containsMouse ? _theme.text : _theme.surface2
//                     border.width: 1
//                     Behavior on color { ColorAnimation { duration: 300 } }

//                     MouseArea {
//                         id: submitMouseArea
//                         anchors.fill: parent
//                         cursorShape: Qt.PointingHandCursor
//                         hoverEnabled: true
//                         enabled: !window.isApplying
//                         onClicked: {
//                             window.triggerOnlineSearch();
//                         }
//                     }

//                     Canvas {
//                         width: window.s(16)
//                         height: window.s(16)
//                         anchors.centerIn: parent
//                         property string activeColor: submitMouseArea.containsMouse ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7)
//                         onActiveColorChanged: requestPaint()
//                         property real scaleTrigger: window.s(1)
//                         onScaleTriggerChanged: requestPaint()
                        
//                         onPaint: {
//                             var ctx = getContext("2d");
//                             var s = window.s;
//                             ctx.reset();
//                             ctx.lineWidth = s(2);
//                             ctx.lineCap = "round";
//                             ctx.lineJoin = "round";
//                             ctx.strokeStyle = activeColor;
                            
//                             ctx.beginPath();
//                             ctx.moveTo(s(2), s(8));
//                             ctx.lineTo(s(14), s(8));
//                             ctx.moveTo(s(9), s(3));
//                             ctx.lineTo(s(14), s(8));
//                             ctx.lineTo(s(9), s(13));
//                             ctx.stroke();
//                         }
//                     }
//                 }
//             }
//         }
//     }

//     Component.onCompleted: {
//         Quickshell.execDetached(["bash", "-c", "mkdir -p '" + decodeURIComponent(window.searchDir.replace("file://", "")) + "'"]);
        
//         window.loadMonitors();

//         if (searchState.searched) {
//             searchInput.text = searchState.query;
//             window.searchQuery = searchState.query;
//             window.hasSearched = true;
//             window.lastSearchName = searchState.lastName;
//             window.isSearchPaused = true;
//         }

//         view.forceActiveFocus();
//         window.processMarkers();
//         window.triggerColorExtraction();
//     }

//     Component.onDestruction: {
//         if (window.hasSearched) {
//             searchState.query = searchInput.text;
//             searchState.searched = window.hasSearched;
//             searchState.lastName = window.lastSearchName;
            
//             Quickshell.execDetached(["bash", "-c", "echo 'pause' > /tmp/ddg_search_control"]);
//         } else {
//             Quickshell.execDetached(["bash", "-c", "echo 'stop' > /tmp/ddg_search_control; for p in $(pgrep -f ddg_search.sh); do if [ \"$p\" != \"$$\" ] && [ \"$p\" != \"$BASHPID\" ]; then kill -9 $p 2>/dev/null || true; fi; done; pkill -f '[g]et_ddg_links.py'"]);
//         }
//     }
// }












import QtQuick                                                                  // Imports the QtQuick module for basic QML UI types and animation framework
import QtQuick.Layouts                                                          // Imports QtQuick.Layouts for RowLayout, ColumnLayout, and other layout types
import QtQuick.Window                                                           // Imports QtQuick.Window for accessing Screen properties like width
import QtCore                                                                   // Imports QtCore for core Qt types like Settings for persistent storage
import Qt.labs.folderlistmodel                                                  // Imports Qt.labs.folderlistmodel for FolderListModel to browse directories
import QtMultimedia                                                             // Imports QtMultimedia for MediaPlayer, VideoOutput, and AudioOutput for video wallpapers
import Quickshell                                                               // Imports Quickshell module for Hyprland shell/window management integration
import Quickshell.Io                                                            // Imports Quickshell.Io for Process and StdioCollector to run external commands
import "../"                                                                    // Imports parent directory to access shared components like Scaler and MatugenColors

Item {                                                                          // Root container item for the entire wallpaper picker popup
    id: window                                                                  // Unique identifier "window" for referencing this root item throughout the file
    width: Screen.width                                                         // Sets the width to match the physical screen width

    Scaler {                                                                    // Instantiates Scaler component for consistent responsive UI sizing
        id: scaler                                                              // Unique identifier "scaler" for this scaling instance
        currentWidth: Screen.width                                              // Binds the scaler to the actual physical screen width
    }
    
    function s(val) {                                                           // Helper function that scales a value according to screen dimensions
        return scaler.s(val);                                                   // Delegates to the scaler instance's s() method
    }

    MatugenColors { id: _theme }                                                // Instantiates MatugenColors component for dynamic theme color palette

    property string widgetArg: ""                                               // Property to receive widget arguments (target wallpaper name for focus)
    property string targetWallName: ""                                          // Stores the name of the wallpaper to focus/select initially
    property bool initialFocusSet: false                                        // Tracks whether the initial focus/selection has been applied
    property int visibleItemCount: -1                                           // Count of items matching current filter (-1 means not yet calculated)
    property int scrollAccum: 0                                                 // Accumulated scroll delta for scroll-to-navigate behavior
    property real scrollThreshold: window.s(300)                                // Threshold of accumulated scroll before switching to next item

    property string currentFilter: "All"                                        // Currently active color/video filter (default: "All")
    property string _lastFilter: "All"                                          // Internal tracking of previous filter for transition detection
    property string searchQuery: ""                                             // Stores the current search query text
    property bool isOnlineSearch: false                                         // Flag indicating an online DDG search is in progress
    property bool isSearchPaused: false                                         // Flag to pause/resume the search download pipeline
    property bool hasSearched: false                                            // Tracks whether a search has been executed at least once
    property var colorMap: ({})                                                 // Dictionary mapping filenames to their dominant hex colors
    property int cacheVersion: 0                                                // Version counter incremented when color cache updates
    
    property bool isDownloadingWallpaper: false                                 // Flag when a full-resolution wallpaper is being downloaded
    property string currentDownloadName: ""                                     // Filename of the wallpaper currently being downloaded
    
    property bool isApplying: false                                             // Flag to prevent multiple simultaneous wallpaper applications
    property bool isMonitorSelectorOpen: false                                  // Toggles the monitor selection panel visibility
    
    Timer {                                                                     // Timer to unlock the apply state after a short delay
        id: applyUnlockTimer                                                    // Unique identifier "applyUnlockTimer"
        interval: 250                                                           // 250ms delay before unlocking
        onTriggered: window.isApplying = false                                  // When timer fires, re-enables wallpaper application
    }
    
    property bool isStartup: localFolderModel.status === FolderListModel.Loading || srcModel.status === FolderListModel.Loading // True during initial loading of folder models
    property bool isReady: visible && localFolderModel.status === FolderListModel.Ready // True when popup is visible and thumbnails are loaded
    property bool isSearchActive: window.currentFilter === "Search" && window.hasSearched && searchFolderModel.status === FolderListModel.Loading // True during active search loading
    
    property string lastSearchName: ""                                          // Stores the last selected search result filename for focus restoration
    property bool isModelChanging: false                                        // Flag to prevent loops during model synchronization
    property bool searchIndexRestored: false                                    // Tracks whether search index has been restored after model change
    
    property bool isScrollingBlocked: window.currentFilter === "Search" && window.hasSearched && window.isSearchActive && !window.isSearchPaused // Blocks scrolling during active search
    property bool jumpToLastOnFilterChange: false                               // When true, jumps to last item when filter changes (for reverse navigation)

    readonly property var filterData: [                                         // Array of filter categories with their properties
        { name: "All", hex: "", label: "All" },                                 // All wallpapers filter (no color)
        { name: "Video", hex: "", label: "Vid" },                               // Video wallpapers filter
        { name: "Red", hex: "#FF4500", label: "" },                             // Red color filter (OrangeRed hex)
        { name: "Orange", hex: "#FFA500", label: "" },                          // Orange color filter
        { name: "Yellow", hex: "#FFD700", label: "" },                          // Yellow color filter (Gold)
        { name: "Green", hex: "#32CD32", label: "" },                           // Green color filter (LimeGreen)
        { name: "Blue", hex: "#1E90FF", label: "" },                            // Blue color filter (DodgerBlue)
        { name: "Purple", hex: "#8A2BE2", label: "" },                          // Purple color filter (BlueViolet)
        { name: "Pink", hex: "#FF69B4", label: "" },                            // Pink color filter (HotPink)
        { name: "Monochrome", hex: "#A9A9A9", label: "" },                      // Monochrome/grayscale filter (DarkGray)
        { name: "Search", hex: "", label: "Search" }                            // Online search filter
    ]

    ListModel { id: monitorModel }                                              // ListModel storing monitor names and selection states

    Process {                                                                   // Process component that fetches monitor information via hyprctl
        id: monitorProc                                                         // Unique identifier "monitorProc"
        command: ["sh", "-c", "export PATH=$PATH:/usr/bin:/usr/local/bin:/run/current-system/sw/bin && hyprctl monitors -j"] // Runs hyprctl with JSON output, ensuring path includes common binary locations
        running: false                                                          // Does not run automatically (triggered by loadMonitors())
        
        stdout: StdioCollector {                                                // Collects the standard output from the process
            onStreamFinished: {                                                 // Callback when hyprctl completes
                console.log("[MonitorSync] Process finished. Reading stdout directly."); // Debug log
                let response = this.text;                                       // Gets the raw text output
                
                if (response && response.trim().length > 0) {                   // If output exists and is not just whitespace
                    try {                                                       // Try to parse JSON
                        var monitors = JSON.parse(response);                    // Parse the JSON array of monitors
                        console.log("[MonitorSync] JSON parsed successfully. Found " + monitors.length + " monitors."); // Debug log
                        
                        monitorModel.clear();                                   // Clear existing monitor entries
                        for (var i = 0; i < monitors.length; i++) {             // Iterate through each monitor
                            monitorModel.append({ "name": monitors[i].name, "selected": true }); // Add monitor with selected=true by default
                            console.log("[MonitorSync] -> Injected: " + monitors[i].name); // Debug log
                        }
                    } catch(e) {                                                // If JSON parsing fails
                        console.log("[MonitorSync] ERROR parsing JSON: " + e);  // Log the parse error
                        console.log("[MonitorSync] RAW TEXT DUMP: " + response); // Log raw output for debugging
                    }
                } else {                                                        // If output is empty
                    console.log("[MonitorSync] ERROR: stdout was empty.");      // Log empty output error
                }
            }
        }
    }

    function loadMonitors() {                                                   // Function to trigger monitor detection
        console.log("[MonitorSync] Starting native hyprctl process...");        // Debug log
        monitorProc.running = true;                                             // Start the hyprctl process
    }

    function getMonitorOutputs() {                                              // Function that returns the comma-separated list of selected monitors
        if (monitorModel.count <= 1) return "all";                              // If only one monitor or none, apply to all
        
        let selected = [];                                                      // Array to collect selected monitor names
        for (let i = 0; i < monitorModel.count; i++) {                          // Iterate through all monitors
            if (monitorModel.get(i).selected) {                                 // If this monitor is selected
                selected.push(monitorModel.get(i).name);                        // Add its name to the array
            }
        }
        
        if (selected.length === 0) return "none";                               // If nothing selected, return "none"
        if (selected.length === monitorModel.count) return "all";               // If all selected, return "all"
        
        return selected.join(",");                                              // Return comma-separated list of monitor names
    }

    function applyWallpaper(safeFileName, isVideo) {                            // Main function to apply a wallpaper (image or video)
        if (!safeFileName || window.isApplying) return;                         // Exit if no filename or already applying
        
        let outputs = window.getMonitorOutputs();                               // Get the target monitor outputs
        if (outputs === "none") return;                                         // Exit if no monitors selected
        
        window.isApplying = true;                                               // Set applying flag to prevent concurrent operations
        applyUnlockTimer.restart();                                             // Start the unlock timer
        
        window.targetWallName = safeFileName;                                   // Store the target wallpaper name
        let cleanName = window.getCleanName(safeFileName);                      // Remove video prefix if present
        let reloadScript = Qt.resolvedUrl("matugen_reload.sh").toString();      // Get the absolute path to the matugen reload script
        
        if (reloadScript.startsWith("file://")) {                               // If URL starts with file:// protocol
            reloadScript = decodeURIComponent(reloadScript.substring(7));       // Convert to local filesystem path
        }

        const escapeBash = (str) => String(str).replace(/(["\\$`])/g, '\\$1');  // Helper function to escape special characters for bash
        const randomTransition = window.transitions[Math.floor(Math.random() * window.transitions.length)]; // Pick a random swww transition type
        const escOutputs = escapeBash(outputs);                                 // Escape monitor outputs string for bash
        
        const logFile = "/tmp/qs_swww_debug.log";                               // Path to debug log file
        
        if (window.currentFilter === "Search" && window.hasSearched) {          // If applying a search result wallpaper
            let alreadyExists = window.isDownloaded(safeFileName);              // Check if the full image was already downloaded
            let destFile = window.srcDir + "/" + safeFileName;                  // Destination path in wallpaper directory
            let finalThumb = decodeURIComponent(window.thumbDir.replace("file://", "")) + "/" + safeFileName; // Path for thumbnail in thumbs dir
            let tempThumb = decodeURIComponent(window.searchDir.replace("file://", "")) + "/" + safeFileName; // Path in search thumbs dir
            let mapFile = Quickshell.env("HOME") + "/.cache/wallpaper_picker/search_map.txt"; // Path to URL mapping file

            if (alreadyExists) {                                                // If the wallpaper was previously downloaded
                const applyScript = `                                           // Multi-line bash script (template literal)
                    export DEST_FILE="${escapeBash(destFile)}"                  // Set destination file variable
                    export FINAL_THUMB="${escapeBash(finalThumb)}"              // Set thumbnail path variable
                    export RELOAD_SCRIPT="${escapeBash(reloadScript)}"          // Set reload script path
                    export TARGET_MONITORS="${escOutputs}"                      // Set target monitors
                    
                    cp "$DEST_FILE" /tmp/lock_bg.png || true                    // Copy wallpaper for lock screen
                    pkill mpvpaper || true                                      // Kill any running video wallpaper
                    
                    echo "" >> ${logFile}                                       // Add blank line to log
                    echo "[$(date +'%H:%M:%S.%3N')] APPLYING CACHED SEARCH: $DEST_FILE TO $TARGET_MONITORS" >> ${logFile} // Log the application
                    
                    if [ "$TARGET_MONITORS" = "all" ]; then                     // If applying to all monitors
                        swww img "$DEST_FILE" --transition-type ${randomTransition} --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 >> ${logFile} 2>&1 & // Apply with swww to all monitors
                    else                                                        // If specific monitors
                        swww img -o "$TARGET_MONITORS" "$DEST_FILE" --transition-type ${randomTransition} --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 >> ${logFile} 2>&1 & // Apply to specified monitors
                    fi
                    
                    ( matugen image "$FINAL_THUMB" || true; bash "$RELOAD_SCRIPT" || true ) & // Generate colors and reload theme in background
                `;
                Quickshell.execDetached(["bash", "-c", applyScript]);           // Execute the script detached
            } else {                                                            // If wallpaper needs to be downloaded first
                window.isDownloadingWallpaper = true;                           // Set downloading flag
                window.currentDownloadName = safeFileName;                      // Store the current download name

                const downloadScript = `                                        // Multi-line download and apply script
                    export SAFE_NAME="${escapeBash(safeFileName)}"              // Set safe filename
                    export DEST_FILE="${escapeBash(destFile)}"                  // Set destination path
                    export FINAL_THUMB="${escapeBash(finalThumb)}"              // Set final thumbnail path
                    export TEMP_THUMB="${escapeBash(tempThumb)}"                // Set temp thumbnail path
                    export RELOAD_SCRIPT="${escapeBash(reloadScript)}"          // Set reload script path
                    export MAP_FILE="${escapeBash(mapFile)}"                    // Set map file path
                    export TARGET_MONITORS="${escOutputs}"                      // Set target monitors
                    
                    URL=$(awk -F'|' -v fname="$SAFE_NAME" '$1 == fname {print $2; exit}' "$MAP_FILE") // Look up full URL from map file
                    if [ -n "$URL" ]; then                                      // If URL was found
                        curl -s -L -A "Mozilla/5.0" "$URL" -o "$DEST_FILE.tmp" // Download the full resolution image
                        
                        if file "$DEST_FILE.tmp" | grep -iq "webp"; then        // If downloaded file is webp
                            magick "$DEST_FILE.tmp" "$DEST_FILE"               // Convert to jpg using ImageMagick
                            rm -f "$DEST_FILE.tmp"                              // Remove temp file
                        else                                                    // If not webp
                            mv "$DEST_FILE.tmp" "$DEST_FILE"                    // Just rename temp to final
                        fi
                        
                        cp "$TEMP_THUMB" "$FINAL_THUMB"                         // Copy thumbnail to permanent location
                        magick "$DEST_FILE" -resize x420 -quality 70 "$FINAL_THUMB" || true // Generate proper thumbnail
                        
                        cp "$DEST_FILE" /tmp/lock_bg.png || true                // Copy for lock screen
                        pkill mpvpaper || true                                  // Kill video wallpaper
                        
                        echo "" >> ${logFile}                                   // Add blank line to log
                        echo "[$(date +'%H:%M:%S.%3N')] APPLYING NEW DOWNLOAD: $DEST_FILE TO $TARGET_MONITORS" >> ${logFile} // Log
                        
                        if [ "$TARGET_MONITORS" = "all" ]; then                 // If all monitors
                            swww img "$DEST_FILE" --transition-type ${randomTransition} --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 >> ${logFile} 2>&1 & // Apply wallpaper
                        else
                            swww img -o "$TARGET_MONITORS" "$DEST_FILE" --transition-type ${randomTransition} --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 >> ${logFile} 2>&1 &
                        fi
                        
                        ( matugen image "$FINAL_THUMB" || true; bash "$RELOAD_SCRIPT" || true ) & // Generate theme
                    fi
                `;
                Quickshell.execDetached(["bash", "-c", downloadScript]);        // Execute download script
            }
            return;                                                             // Exit early (search handling complete)
        }

        const originalFile = window.srcDir + "/" + cleanName;                   // Full path to local wallpaper file
        const thumbFile = Quickshell.env("HOME") + "/.cache/wallpaper_picker/thumbs/" + safeFileName; // Path to thumbnail
        
        const escOriginal = escapeBash(originalFile);                           // Escape original file path
        const escThumb = escapeBash(thumbFile);                                 // Escape thumbnail path
        const escReload = escapeBash(reloadScript);                             // Escape reload script path

        let wallpaperCmd = "";                                                  // Variable to hold the wallpaper command
        
        if (isVideo) {                                                          // If it's a video wallpaper
            wallpaperCmd = `                                                    // Video wallpaper command template
                echo "" >> ${logFile}
                echo "[$(date +'%H:%M:%S.%3N')] APPLYING LOCAL VIDEO: ${escOriginal} TO ${escOutputs}" >> ${logFile} // Log
                
                if [ "${escOutputs}" = "all" ]; then                            // If all monitors
                    mpvpaper -o 'loop --no-audio --hwdec=auto --profile=high-quality --video-sync=display-resample --interpolation --tscale=oversample' '*' "${escOriginal}" >> ${logFile} 2>&1 & // mpvpaper with all monitors
                else                                                            // If specific monitors
                    IFS=',' read -ra MON_ARR <<< "${escOutputs}"               // Split monitor list into array
                    for mon in "\${MON_ARR[@]}"; do                            // Loop through each monitor
                        mpvpaper -o 'loop --no-audio --hwdec=auto --profile=high-quality --video-sync=display-resample --interpolation --tscale=oversample' "\$mon" "${escOriginal}" >> ${logFile} 2>&1 & // Apply mpvpaper per monitor
                    done
                fi
            `;
        } else {                                                                // If it's a static image
            wallpaperCmd = `                                                    // Image wallpaper command
                echo "" >> ${logFile}
                echo "[$(date +'%H:%M:%S.%3N')] APPLYING LOCAL IMAGE: ${escOriginal} TO ${escOutputs}" >> ${logFile} // Log
                
                if [ "${escOutputs}" = "all" ]; then                            // If all monitors
                    swww img "${escOriginal}" --transition-type ${randomTransition} --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 >> ${logFile} 2>&1 & // swww to all
                else                                                            // If specific monitors
                    swww img -o "${escOutputs}" "${escOriginal}" --transition-type ${randomTransition} --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 >> ${logFile} 2>&1 & // swww to selected
                fi
            `;
        }

        const fullScript = `                                                    // Complete script combining all steps
            cp "${isVideo ? escThumb : escOriginal}" /tmp/lock_bg.png || true   // Copy for lock screen (thumbnail for video, original for image)
            pkill mpvpaper || true                                              // Kill any existing video wallpaper
            
            ${wallpaperCmd}                                                     // Execute the wallpaper command
            ( matugen image "${escThumb}" || true; bash "${escReload}" || true ) & // Generate theme colors in background
        `;
        Quickshell.execDetached(["bash", "-c", fullScript]);                    // Execute the complete script
    }
    Settings {                                                                   // Persistent settings storage that survives application restarts
        id: searchState                                                          // Unique identifier "searchState" for the settings instance
        category: "QS_WallpaperPicker"                                            // Settings category/group name for organization
        property string query: ""                                                // Persists the last search query text
        property bool searched: false                                            // Persists whether a search was performed
        property string lastName: ""                                             // Persists the last selected search result filename
    }

    onIsSearchPausedChanged: {                                                   // Signal handler when search pause state changes
        Quickshell.execDetached(["bash", "-c", "echo '" + (isSearchPaused ? "pause" : "run") + "' > /tmp/ddg_search_control"]); // Writes "pause" or "run" to the DDG search control file
    }

    onVisibleChanged: {                                                          // Signal handler when the popup visibility changes
        if (!visible) {                                                          // When popup is being hidden
            window.initialFocusSet = false;                                      // Reset initial focus flag
            window.searchIndexRestored = false;                                  // Reset search index restored flag
            window.isApplying = false;                                           // Reset applying flag
            window.isMonitorSelectorOpen = false;                                // Close monitor selector
            
            if (window.hasSearched) {                                            // If a search was active
                window.isSearchPaused = true;                                    // Pause the search pipeline
            }
        } else {                                                                 // When popup becomes visible
            window.isFilterAnimating = true;                                     // Set filter animation flag
            filterAnimationTimer.restart();                                      // Start the filter animation timer

            if (window.currentFilter !== "Search") {                             // If not on search tab
                window.applyFilters(true);                                       // Apply current filter with snap-to-position
            } else if (window.hasSearched) {                                     // If on search tab and previously searched
                window.searchIndexRestored = false;                              // Allow search index restoration
                window.isSearchPaused = true;                                    // Start paused (user can resume)
                window.trySearchFocus();                                         // Try to restore focus to last selected
                window.syncSearchModel();                                        // Sync search model with folder
            }
        }
    }

    property bool isLoading: localFolderModel.status === FolderListModel.Loading ||  // True when either local thumbnails are loading
                             srcModel.status === FolderListModel.Loading ||       // or source wallpapers are loading
                             (window.currentFilter === "Search" && searchFolderModel.status === FolderListModel.Loading) // or search results are loading

    property bool showSpinner: window.isDownloadingWallpaper ||                   // Show spinner when downloading a wallpaper
                               (window.currentFilter === "Search" && window.hasSearched && !window.isSearchPaused) ||  // or during active search
                               (window.currentFilter !== "Search" && window.isLoading) // or when loading local wallpapers

    property string currentNotification: {                                        // Computed notification text based on current state
        if (window.isDownloadingWallpaper) return "Downloading wallpaper...";     // Message during wallpaper download

        if (window.currentFilter === "Search") {                                  // If on search tab
            if (!window.hasSearched) return "Type something to search...";        // Prompt before searching
            if (window.isSearchPaused) return "Search Paused";                    // Status when paused
            if (window.visibleItemCount === 0) return "Searching DDG (FHD+)...";  // Active search message
            return "Generating thumbnails...";                                    // Post-search thumbnail generation
        }

        if (isLoading) return "Generating thumbnails...";                         // Loading message for local wallpapers
        if (window.visibleItemCount === 0) return "No wallpapers found";          // Empty state message
        
        if (window.currentFilter === "All") return "";                            // No notification for All filter
        if (window.currentFilter === "Video") return "Videos";                    // Video filter label
        
        return window.currentFilter;                                              // Color filter name as notification
    }
    
    property bool showNotification: !window.isStartup && currentNotification !== "" // Show notification when not starting up and message exists

    function getCleanName(name) {                                                // Function that removes the "000_" video prefix from filenames
        if (!name) return "";                                                    // Return empty if name is null/undefined
        let clean = String(name);                                                // Convert to string
        return clean.startsWith("000_") ? clean.substring(4) : clean;            // Remove "000_" prefix if present, otherwise return as-is
    }

    function isDownloaded(name) {                                                // Function that checks if a wallpaper exists in the source directory
        if (!name) return false;                                                 // Return false if name is empty
        for (let i = 0; i < srcModel.count; i++) {                               // Iterate through source directory model
            if (srcModel.get(i, "fileName") === name) return true;               // Return true if filename matches
        }
        return false;                                                            // Return false if not found
    }

    onWidgetArgChanged: {                                                        // Signal handler when widget arguments change
        if (widgetArg !== "") {                                                  // If an argument was provided
            targetWallName = widgetArg;                                          // Set the target wallpaper name
            initialFocusSet = false;                                             // Reset focus to allow re-focusing
            tryFocus();                                                          // Attempt to focus on the target
        }
    }

    function executeFocusRestore(targetIndex, isSearchRestore, requirePositioning) { // Function that sets the list view focus to a specific index
        let targetModel = window.getModelForFilter(window.currentFilter);        // Get the appropriate model for current filter
        
        if (targetIndex !== -1 && targetIndex < targetModel.count) {             // If index is valid within model bounds
            window.isModelChanging = true;                                       // Set flag to prevent change loops
            
            if (requirePositioning) {                                            // If exact positioning is needed
                view.forceLayout();                                              // Force layout update
                view.positionViewAtIndex(targetIndex, ListView.Center);          // Position the target at center of view
            }
            
            view.currentIndex = targetIndex;                                     // Set the current index
            
            if (isSearchRestore) {                                               // If this is a search restore operation
                window.searchIndexRestored = true;                               // Mark search index as restored
            }
            
            window.isModelChanging = false;                                      // Clear model changing flag
            window.initialFocusSet = true;                                       // Mark initial focus as set
        } else if (isSearchRestore) {                                            // If search restore but no valid index
            window.searchIndexRestored = true;                                   // Mark as restored anyway (avoids infinite retry)
        }
    }

    function tryFocus() {                                                        // Function that attempts to focus on the target wallpaper in local model
        if (initialFocusSet) return;                                             // Exit if focus already set

        if (localProxyModel.count > 0) {                                         // If there are items in the proxy model
            let foundIndex = -1;                                                 // Initialize found index
            let cleanTarget = window.getCleanName(targetWallName);               // Clean the target name

            if (cleanTarget !== "") {                                            // If a target name exists
                for (let i = 0; i < localProxyModel.count; i++) {               // Iterate through proxy model
                    let fname = localProxyModel.get(i).fileName || "";           // Get filename at current index
                    if (window.getCleanName(fname) === cleanTarget) {            // Compare cleaned names
                        foundIndex = i;                                          // Store matching index
                        break;                                                   // Exit loop
                    }
                }
            }

            let finalIndex = foundIndex !== -1 ? foundIndex : 0;                 // Use found index or default to first item
            window.executeFocusRestore(finalIndex, false, true);                 // Execute the focus restore
        }
    }
    
    function trySearchFocus() {                                                  // Function that attempts to restore focus in search results
        if (window.searchIndexRestored || searchProxyModel.count === 0) return;  // Exit if already restored or no items

        if (window.lastSearchName === "") {                                      // If no last search name
             window.searchIndexRestored = true;                                  // Mark as restored
             return;                                                             // Exit
        }

        for (let i = 0; i < searchProxyModel.count; i++) {                      // Iterate through search results
            let fname = searchProxyModel.get(i).fileName || "";                  // Get filename
            if (fname === window.lastSearchName) {                               // If matches last selected
                window.executeFocusRestore(i, true, true);                       // Restore focus to this index
                return;                                                          // Exit
            }
        }
        
        if (searchFolderModel.status === FolderListModel.Ready && searchProxyModel.count === searchFolderModel.count) { // If fully loaded
             window.searchIndexRestored = true;                                  // Mark as restored
        }
    }

    function getModelForFilter(filter) {                                         // Helper that returns the appropriate proxy model for a filter
        return filter === "Search" ? searchProxyModel : localProxyModel;         // Search model for search, local model for everything else
    }

    function updateVisibleCount() {                                              // Function that counts items matching the current filter
        let targetModel = window.getModelForFilter(window.currentFilter);        // Get the model for current filter
        
        if (!targetModel || targetModel.count === 0) {                           // If model is empty or null
            window.visibleItemCount = 0;                                         // Set count to 0
            return;                                                              // Exit
        }
        let count = 0;                                                           // Initialize counter
        for (let i = 0; i < targetModel.count; i++) {                            // Iterate through model
            let fname = targetModel.get(i).fileName || "";                       // Get filename
            let isVid = fname.startsWith("000_");                                // Check if video
            if (checkItemMatchesFilter(fname, isVid, window.cacheVersion, window.currentFilter)) { // Check if matches filter
                count++;                                                         // Increment counter
            }
        }
        window.visibleItemCount = count;                                         // Store the count
    }

    function triggerOnlineSearch() {                                             // Function that initiates DuckDuckGo image search
        if (searchInput.text.trim() === "") return;                              // Exit if search input is empty
        
        window.isModelChanging = true;                                           // Set model changing flag
        searchProxyModel.clear();                                                // Clear existing search results
        window.lastSearchName = "";                                              // Reset last search name
        searchState.lastName = "";                                               // Clear persisted last name
        
        if (window.currentFilter === "Search") {                                 // If currently on search tab
            view.currentIndex = 0;                                               // Reset view to first item
            view.positionViewAtIndex(0, ListView.Center);                        // Center on first item
        }
        window.isModelChanging = false;                                          // Clear model changing flag

        window.searchIndexRestored = true;                                       // Mark as restored (prevents focus jumping)
        window.isOnlineSearch = true;                                            // Set online search flag
        window.hasSearched = true;                                               // Mark that a search has been done
        
        window.visibleItemCount = 0;                                             // Reset visible count
        
        searchState.searched = true;                                             // Persist search state
        searchState.query = searchInput.text.trim();                             // Persist search query
        
        window.isSearchPaused = false;                                           // Unpause the search pipeline
        window.searchQuery = searchInput.text.trim();                            // Store the query
        
        let rawSearchDir = decodeURIComponent(window.searchDir.replace(/^file:\/\//, "")); // Get raw search directory path
        let scriptPath = decodeURIComponent(Qt.resolvedUrl("ddg_search.sh").toString().replace(/^file:\/\//, "")); // Get absolute path to search script
        
        const cmd = `                                                            // Bash command to restart the search pipeline
            exec > /tmp/qs_ddg_run.log 2>&1                                      // Redirect all output to log file
            echo "=== QML Shell Handoff Successful ==="                          // Log handoff marker
            export PATH=$PATH:/run/current-system/sw/bin                         // Ensure system binaries are in PATH
            
            echo "Gracefully stopping old processes..."                          // Log
            echo 'stop' > /tmp/ddg_search_control                               // Send stop signal to any running search
            
            for p in $(pgrep -f ddg_search.sh); do                              // Find all running search processes
                if [ "$p" != "$$" ] && [ "$p" != "$BASHPID" ]; then             // Skip current process
                    kill -9 $p 2>/dev/null || true                              // Force kill old processes
                fi
            done
            pkill -f "[g]et_ddg_links.py" || true                               // Kill old Python scraper
            sleep 0.2                                                           // Brief pause for cleanup
            
            echo "Clearing old cache..."                                        // Log
            rm -rf "${rawSearchDir}"/* || true                                  // Delete old search thumbnails
            rm -f "${rawSearchDir}/../search_map.txt" || true                   // Delete old URL map
            
            echo "Setting control state back to run..."                         // Log
            echo 'run' > /tmp/ddg_search_control                                // Set control back to run
            
            echo "Executing new search pipeline..."                             // Log
            bash "${scriptPath}" "${window.searchQuery}" &                      // Execute search script with query in background
        `;
        
        Quickshell.execDetached(["bash", "-c", cmd]);                            // Execute the command detached
        
        searchInput.focus = false;                                               // Remove focus from search input
        view.forceActiveFocus();                                                 // Focus the main view for keyboard navigation
    }

    readonly property string homeDir: "file://" + Quickshell.env("HOME")         // Home directory as file URL
    readonly property string thumbDir: homeDir + "/.cache/wallpaper_picker/thumbs" // Local thumbnails directory URL
    readonly property string searchDir: homeDir + "/.cache/wallpaper_picker/search_thumbs" // Search thumbnails directory URL
    readonly property string srcDir: {                                            // Source wallpaper directory (computed)
        const dir = Quickshell.env("WALLPAPER_DIR")                               // Try WALLPAPER_DIR environment variable first
        return (dir && dir !== "")                                                // If set and not empty
        ? dir                                                                     // Use it
        : Quickshell.env("HOME") + "/Pictures/Wallpapers"                         // Otherwise use default
    }

    readonly property var transitions: ["simple", "fade", "left", "right", "top", "bottom", "wipe", "grow", "center", "outer", "random", "wave"] // Available swww transition types

    readonly property real itemWidth: window.s(400)                               // Scaled width of each wallpaper card
    readonly property real itemHeight: window.s(420)                              // Scaled height of each wallpaper card
    readonly property real borderWidth: window.s(3)                               // Scaled border width
    readonly property real spacing: window.s(10)                                  // Scaled spacing between cards
    readonly property real skewFactor: -0.35                                      // Skew factor for 3D perspective effect

    Timer {                                                                       // Timer for scroll throttling
        id: scrollThrottle                                                        // Unique identifier
        interval: 150                                                             // 150ms throttle interval
    }

    property bool isFilterAnimating: false                                        // Tracks if filter change animation is in progress
    Timer {                                                                       // Timer that ends filter animation state
        id: filterAnimationTimer                                                  // Unique identifier
        interval: 800                                                             // 800ms animation duration
        onTriggered: window.isFilterAnimating = false                             // Clear animation flag
    }

    property bool isItemAnimating: false                                          // Tracks if item transition animation is in progress
    Timer {                                                                       // Timer that ends item animation state
        id: itemAnimationTimer                                                    // Unique identifier
        interval: 500                                                             // 500ms animation duration
        onTriggered: window.isItemAnimating = false                               // Clear animation flag
    }

    function getHexBucket(hexStr) {                                               // Function that categorizes a hex color into a color bucket
        if (!hexStr) return "Monochrome";                                         // Default to Monochrome if no color
        
        hexStr = String(hexStr).trim().replace(/#/g, '');                         // Remove # and trim
        if (hexStr.length > 6) hexStr = hexStr.substring(0, 6);                   // Take first 6 chars if longer
        if (hexStr.length !== 6) return "Monochrome";                             // Invalid length defaults to Monochrome

        let r = parseInt(hexStr.substring(0,2), 16) / 255;                        // Parse red channel (0-1)
        let g = parseInt(hexStr.substring(2,4), 16) / 255;                        // Parse green channel (0-1)
        let b = parseInt(hexStr.substring(4,6), 16) / 255;                        // Parse blue channel (0-1)

        if (isNaN(r) || isNaN(g) || isNaN(b)) return "Monochrome";                // Invalid values default to Monochrome

        let max = Math.max(r, g, b), min = Math.min(r, g, b);                     // Find max and min channel values
        let d = max - min;                                                        // Calculate delta (range)
        
        let h = 0;                                                                // Initialize hue
        let s = max === 0 ? 0 : d / max;                                          // Calculate saturation (avoid division by zero)
        let v = max;                                                              // Value is max channel

        if (max !== min) {                                                        // If not grayscale
            if (max === r) {                                                      // Red is dominant
                h = (g - b) / d + (g < b ? 6 : 0);                                // Calculate hue for red-dominant
            } else if (max === g) {                                               // Green is dominant
                h = (b - r) / d + 2;                                              // Calculate hue for green-dominant
            } else {                                                              // Blue is dominant
                h = (r - g) / d + 4;                                              // Calculate hue for blue-dominant
            }
            h /= 6;                                                               // Normalize to 0-1
        }
        h = h * 360;                                                              // Convert to degrees

        if (s < 0.05 || v < 0.08) return "Monochrome";                            // Low saturation or value means grayscale

        if (h >= 345 || h < 15) return "Red";                                     // Red: 345-360 and 0-15 degrees
        if (h >= 15 && h < 45) return "Orange";                                   // Orange: 15-45 degrees
        if (h >= 45 && h < 75) return "Yellow";                                   // Yellow: 45-75 degrees
        if (h >= 75 && h < 165) return "Green";                                   // Green: 75-165 degrees
        if (h >= 165 && h < 260) return "Blue";                                   // Blue: 165-260 degrees
        if (h >= 260 && h < 315) return "Purple";                                 // Purple: 260-315 degrees
        if (h >= 315 && h < 345) return "Pink";                                   // Pink: 315-345 degrees

        return "Monochrome";                                                      // Fallback
    }

    function checkItemMatchesFilter(fileName, isVid, cv, filter) {                // Function that checks if an item matches the active filter
        if (filter === "Search") return true;                                     // Search shows everything

        if (filter === "All") return true;                                        // All filter shows everything
        if (filter === "Video") return isVid;                                     // Video filter only shows videos
        
        let hexColor = window.colorMap[String(fileName)];                         // Get stored color for this wallpaper
        if (!hexColor) return filter === "Monochrome";                            // No color defaults to Monochrome filter
        
        return window.getHexBucket(hexColor) === filter;                          // Check if color bucket matches filter
    }

    FolderListModel {                                                             // Model that watches the color markers directory
        id: markerModel                                                           // Unique identifier
        folder: "file://" + Quickshell.env("HOME") + "/.cache/wallpaper_picker/colors_markers" // Directory containing color marker files
        showDirs: false                                                           // Don't show subdirectories
        nameFilters: ["*_HEX_*"]                                                  // Only show files with "_HEX_" in name
        
        onCountChanged: window.processMarkers()                                   // When markers change, reprocess them
        onStatusChanged: {                                                        // When status changes
            if (status === FolderListModel.Ready) window.processMarkers()         // If ready, process markers
        }
    }

    FolderListModel {                                                             // Model that watches the source wallpaper directory
        id: srcModel                                                              // Unique identifier
        folder: "file://" + window.srcDir                                         // Points to the wallpaper source directory
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"] // Supported image and video formats
        showDirs: false                                                           // Don't show directories
        
        onCountChanged: {                                                         // When files are added/removed
            if (window.isDownloadingWallpaper && window.isDownloaded(window.currentDownloadName)) { // If waiting for a download
                window.isDownloadingWallpaper = false;                            // Clear downloading flag when file appears
            }
        }
    }

    function processMarkers() {                                                   // Function that reads color marker files and builds the color map
        let newMap = {};                                                          // New color map dictionary
        for (let i = 0; i < markerModel.count; i++) {                             // Iterate through marker files
            let markerName = markerModel.get(i, "fileName") || "";                // Get marker filename
            if (!markerName) continue;                                            // Skip empty names
            
            let splitIdx = markerName.lastIndexOf("_HEX_");                       // Find the "_HEX_" separator
            if (splitIdx !== -1) {                                                // If separator found
                let fName = markerName.substring(0, splitIdx);                    // Extract wallpaper filename
                let hexCode = markerName.substring(splitIdx + 5);                 // Extract hex color code
                newMap[fName] = "#" + hexCode;                                    // Store in map with # prefix
            }
        }
        window.colorMap = newMap;                                                 // Update the color map
        window.cacheVersion++;                                                    // Increment cache version to trigger UI updates
        window.updateVisibleCount();                                              // Recalculate visible item count
    }

    function triggerColorExtraction() {                                           // Function that runs ImageMagick to extract dominant colors from thumbnails
        const extractScript = `                                                   // Multi-line bash script
            COLOR_DIR="$HOME/.cache/wallpaper_picker/colors_markers"             // Color markers directory
            THUMBS="$HOME/.cache/wallpaper_picker/thumbs"                         // Thumbnails directory
            CSV="$HOME/.cache/wallpaper_picker/colors.csv"                        // Colors CSV cache
            
            mkdir -p "$COLOR_DIR"                                                 // Ensure markers directory exists
            
            if [ -f "$CSV" ]; then                                                // If CSV cache exists
                while IFS=, read -r fname hexcode; do                            // Read each line (filename,hex)
                    cleanhex=$(echo "$hexcode" | tr -d '\r#' | cut -c 1-6)       // Clean the hex code
                    if [ -n "$cleanhex" ] && [ -n "$fname" ]; then               // If both values exist
                        touch "$COLOR_DIR/$fname""_HEX_$cleanhex" 2>/dev/null    // Create marker file
                    fi
                done < "$CSV"                                                     // Read from CSV
                mv "$CSV" "$CSV.bak" 2>/dev/null                                  // Backup the processed CSV
            fi
            
            if command -v magick &> /dev/null; then CMD="magick"; else CMD="convert"; fi // Use magick if available, fallback to convert
            
            for file in "$THUMBS"/*; do                                           // Iterate through thumbnails
                if [ -f "$file" ]; then                                           // If it's a regular file
                    filename=$(basename "$file")                                  // Get just the filename
                    found=0                                                       // Reset found flag
                    for marker in "$COLOR_DIR/$filename"_HEX_*; do               // Check if marker already exists
                        if [ -e "$marker" ]; then found=1; break; fi              // Mark as found if exists
                    done
                    
                    if [ $found -eq 0 ]; then                                     // If no marker exists yet
                        hex=$($CMD "$file" -modulate 100,200 -resize "1x1^" -gravity center -extent 1x1 -depth 8 -format "%[hex:p{0,0}]" info:- 2>/dev/null | grep -oE '[0-9A-Fa-f]{6}' | head -n 1) // Extract dominant color: boost saturation, resize to 1x1 pixel, get hex
                        if [ -n "$hex" ]; then                                    // If hex was extracted
                            touch "$COLOR_DIR/$filename""_HEX_$hex"               // Create the color marker file
                        fi
                    fi
                fi
            done
        `;
        Quickshell.execDetached(["bash", "-c", extractScript]);                    // Execute color extraction in background
    }

    function stepToNextValidIndex(direction) {                                     // Function that moves selection to next/previous matching item
        let targetModel = window.getModelForFilter(window.currentFilter);          // Get current model
        if (!targetModel || targetModel.count === 0) return;                       // Exit if model empty
        
        let start = view.currentIndex;                                             // Start from current position
        let found = -1;                                                            // Initialize found index

        if (direction === 1) {                                                     // Moving forward/right
            for (let i = start + 1; i < targetModel.count; i++) {                  // Search forward from current
                let fname = targetModel.get(i).fileName || "";                     // Get filename
                let isVid = fname.startsWith("000_");                              // Check if video
                if (checkItemMatchesFilter(fname, isVid, window.cacheVersion, window.currentFilter)) { // If matches
                    found = i; break;                                              // Store and exit
                }
            }
        } else {                                                                   // Moving backward/left
            for (let i = start - 1; i >= 0; i--) {                                 // Search backward from current
                let fname = targetModel.get(i).fileName || "";                     // Get filename
                let isVid = fname.startsWith("000_");                              // Check if video
                if (checkItemMatchesFilter(fname, isVid, window.cacheVersion, window.currentFilter)) { // If matches
                    found = i; break;                                              // Store and exit
                }
            }
        }

        if (found !== -1) {                                                        // If a matching item was found
            view.currentIndex = found;                                             // Jump to it
            return;                                                                // Exit
        }

        let filterOrder = ["All", "Video", "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink", "Monochrome"]; // Filter cycling order
        let currentFilterIdx = filterOrder.indexOf(window.currentFilter);          // Find current filter position

        if (currentFilterIdx === -1) {                                             // If not in order (Search tab)
            let current = start;                                                   // Start from current
            for (let i = 0; i < targetModel.count; i++) {                          // Full cycle through model
                current = (current + direction + targetModel.count) % targetModel.count; // Wrap around
                let fname = targetModel.get(current).fileName || "";
                let isVid = fname.startsWith("000_");
                
                if (checkItemMatchesFilter(fname, isVid, window.cacheVersion, window.currentFilter)) {
                    view.currentIndex = current;                                   // Set to found index
                    return;
                }
            }
            return;                                                                // Nothing found
        }

        let nextFilterIdx = currentFilterIdx + direction;                          // Calculate next filter index

        if (nextFilterIdx >= 0 && nextFilterIdx < filterOrder.length) {            // If valid next filter
            window.jumpToLastOnFilterChange = (direction === -1);                  // Jump to last when going backward
            window.currentFilter = filterOrder[nextFilterIdx];                     // Switch to next filter
        }
    }

    function cycleFilter(direction) {                                              // Function that cycles through filters in order
        let currentIdx = -1;                                                       // Initialize current position
        for (let i = 0; i < window.filterData.length; i++) {                       // Search filter data array
            if (window.filterData[i].name === window.currentFilter) {              // If matches current
                currentIdx = i;                                                    // Store index
                break;
            }
        }
        
        if (currentIdx !== -1) {                                                   // If found
            let nextIdx = (currentIdx + direction + window.filterData.length) % window.filterData.length; // Calculate next with wrap
            window.currentFilter = window.filterData[nextIdx].name;                // Switch filter
        }
    }

    function applyFilters(forceSnap) {                                             // Function that applies the current filter and updates selection
        let targetModel = window.getModelForFilter(window.currentFilter);          // Get model for filter
        
        if (!targetModel || targetModel.count === 0) {                             // If model empty
            window.updateVisibleCount();                                           // Update count
            return;
        }

        if (window.currentFilter === "Search") {                                   // Search filter is handled separately
            window.updateVisibleCount();
            return;
        }

        let firstValidIndex = -1;                                                  // First matching item index
        let lastValidIndex = -1;                                                   // Last matching item index
        let cleanTarget = window.getCleanName(window.targetWallName);              // Cleaned target name
        let targetIndex = -1;                                                      // Index of target wallpaper

        for (let i = 0; i < targetModel.count; i++) {                              // Iterate through model
            let fname = targetModel.get(i).fileName || "";                         // Get filename
            let isVid = fname.startsWith("000_");                                  // Check video
            
            if (checkItemMatchesFilter(fname, isVid, window.cacheVersion, window.currentFilter)) { // If matches
                if (firstValidIndex === -1) {                                      // If first match
                    firstValidIndex = i;
                }
                lastValidIndex = i;                                                // Update last match
                
                if (cleanTarget !== "" && window.getCleanName(fname) === cleanTarget) { // If matches target
                    targetIndex = i;
                }
            }
        }

        let indexToFocus = -1;

        if (targetIndex !== -1) {                                                  // If target found
             indexToFocus = targetIndex;
        } else if (window.jumpToLastOnFilterChange && lastValidIndex !== -1) {     // If jumping to last
            indexToFocus = lastValidIndex;
        } else if (firstValidIndex !== -1) {                                       // Default to first
            indexToFocus = firstValidIndex;
        }

        window.jumpToLastOnFilterChange = false;                                   // Reset jump flag
        
        if (indexToFocus !== -1) {                                                 // If valid index
            window.executeFocusRestore(indexToFocus, false, forceSnap === true);   // Focus on it
        }
        
        window.updateVisibleCount();                                               // Update count
    }

    onCurrentFilterChanged: {                                                      // Signal handler when filter changes
        window.isFilterAnimating = true;                                           // Set animation flag
        filterAnimationTimer.restart();                                            // Restart animation timer
        window.isModelChanging = true;                                             // Set model changing flag
        let returningFromSearch = (window._lastFilter === "Search" && window.currentFilter !== "Search"); // Check if leaving search
        window._lastFilter = window.currentFilter;                                 // Update last filter
        
        if (returningFromSearch) {                                                 // If leaving search tab
             window.searchIndexRestored = false;                                   // Allow index restoration
        }
        
        Qt.callLater(() => {                                                       // Defer execution to next event loop cycle
            view.forceActiveFocus();                                               // Focus the view

            if (window.currentFilter === "Search") {                               // If switching to search
                if (window.hasSearched) {                                          // If previously searched
                    window.searchIndexRestored = false;                            // Allow restoration
                    window.trySearchFocus();                                       // Try to restore focus
                }
            } else {                                                               // If switching to local filter
                window.applyFilters(returningFromSearch);                          // Apply filter
            }
            window.isModelChanging = false;                                        // Clear flag
        });
    }

    Shortcut {                                                                     // Keyboard shortcut: Left arrow
        sequence: "Left";                                                          // Left arrow key
        enabled: !window.isScrollingBlocked && !window.isApplying                  // Only when not blocked or applying
        onActivated: window.stepToNextValidIndex(-1)                               // Move to previous item
    }
    Shortcut {                                                                     // Keyboard shortcut: Right arrow
        sequence: "Right";                                                         // Right arrow key
        enabled: !window.isScrollingBlocked && !window.isApplying                  // Only when not blocked
        onActivated: window.stepToNextValidIndex(1)                                // Move to next item
    }
    
    Shortcut {                                                                     // Keyboard shortcut: Enter/Return
        sequence: "Return"                                                         // Return key
        enabled: !searchInput.activeFocus && !window.isScrollingBlocked && !window.isApplying // When not typing in search
        onActivated: {                                                             // Handler
            let targetModel = window.getModelForFilter(window.currentFilter);      // Get model
            if (view.currentIndex >= 0 && view.currentIndex < targetModel.count) { // If valid index
                let fname = targetModel.get(view.currentIndex).fileName;           // Get filename
                if (fname) {                                                       // If file exists
                    let isVid = String(fname).startsWith("000_");                  // Check video
                    window.applyWallpaper(String(fname), isVid);                   // Apply the wallpaper
                }
            }
        } 
    }
    
    Shortcut { sequence: "Escape"; enabled: !window.isApplying; onActivated: { if (window.currentFilter === "Search") { window.currentFilter = "All"; } } } // Escape: exit search mode back to All
    Shortcut { sequence: "Tab"; enabled: !window.isApplying; onActivated: window.cycleFilter(1) }      // Tab: cycle filter forward
    Shortcut { sequence: "Backtab"; enabled: !window.isApplying; onActivated: window.cycleFilter(-1) } // Shift+Tab: cycle filter backward

    ListModel { id: localProxyModel }                                              // Proxy model for local wallpapers (synced from FolderListModel)
    ListModel { id: searchProxyModel }                                             // Proxy model for search results (synced from FolderListModel)
    
    readonly property var activeModel: window.currentFilter === "Search" ? searchProxyModel : localProxyModel // Active model based on current filter

    FolderListModel {                                                              // Watches the local thumbnails directory
        id: localFolderModel                                                       // Unique identifier
        folder: window.thumbDir                                                    // Points to thumbnails directory
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"] // Image and video formats
        showDirs: false                                                            // No directories
        sortField: FolderListModel.Name                                            // Sort by filename
        
        onCountChanged: window.syncLocalModel()                                    // Sync when count changes
        onStatusChanged: { if (status === FolderListModel.Ready) window.syncLocalModel() } // Sync when ready
    }

    function syncLocalModel() {                                                    // Function that synchronizes local proxy model with folder model
        let startIdx = localProxyModel.count;                                      // Start from current proxy count
        let endIdx = localFolderModel.count;                                       // End at folder model count
        
        if (endIdx < startIdx) {                                                   // If items were removed
            window.isModelChanging = true;                                         // Set flag
            localProxyModel.clear();                                               // Clear and rebuild
            startIdx = 0;                                                          // Reset start
            window.isModelChanging = false;                                        // Clear flag
        }

        let batch = [];                                                            // Batch array for new items
        for (let i = startIdx; i < endIdx; i++) {                                  // Iterate new items
            let fn = localFolderModel.get(i, "fileName");                          // Get filename
            let fu = localFolderModel.get(i, "fileUrl");                           // Get file URL
            if (fn !== undefined) {                                                // If filename exists
                batch.push({ "fileName": fn, "fileUrl": String(fu) });             // Add to batch
            }
        }
        
        if (batch.length > 0) {                                                    // If there are new items
            localProxyModel.append(batch);                                         // Append batch to proxy model
        }

        if (window.currentFilter !== "Search") window.updateVisibleCount();        // Update count for local filters
        
        if (!window.initialFocusSet && window.currentFilter !== "Search" && localProxyModel.count > 0) { // If focus not set
            window.tryFocus();                                                     // Try to focus
        }
    }

    function syncSearchModel() {                                                   // Function that synchronizes search proxy model
        let startIdx = searchProxyModel.count;                                     // Start from current count
        let endIdx = searchFolderModel.count;                                      // End at folder model count
        
        if (endIdx < startIdx) {                                                   // If items removed
            window.isModelChanging = true;                                         // Set flag
            searchProxyModel.clear();                                              // Clear and rebuild
            startIdx = 0;                                                          // Reset
            window.isModelChanging = false;                                        // Clear flag
        }

        let batch = [];                                                            // Batch array
        for (let i = startIdx; i < endIdx; i++) {                                  // Iterate new items
            let fn = searchFolderModel.get(i, "fileName");                         // Get filename
            let fu = searchFolderModel.get(i, "fileUrl");                          // Get URL
            if (fn !== undefined) {                                                // If exists
                batch.push({ "fileName": fn, "fileUrl": String(fu) });             // Add to batch
            }
        }
        
        if (batch.length > 0) {                                                    // If new items
            searchProxyModel.append(batch);                                        // Append
        }

        if (window.currentFilter === "Search") window.updateVisibleCount();        // Update count for search

        if (window.currentFilter === "Search" && window.hasSearched) {             // If on search tab
            if (!window.searchIndexRestored) {                                     // If not restored
                window.trySearchFocus();                                           // Try to restore
            }
            
            if (window.isScrollingBlocked && startIdx === 0 && searchProxyModel.count > 0 && window.lastSearchName === "") { // If first batch and scrolling blocked
                view.forceLayout();                                                // Force layout
                view.currentIndex = 0;                                             // Focus first
                view.positionViewAtIndex(0, ListView.Center);                      // Center it
            }
        }
    }
    FolderListModel {                                                              // Watches the search thumbnails directory
        id: searchFolderModel                                                      // Unique identifier
        folder: window.searchDir                                                   // Points to search thumbnails
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"] // Formats
        showDirs: false                                                            // No directories
        sortField: FolderListModel.Name                                            // Sort by name
        
        onFolderChanged: {                                                         // When folder path changes
            window.isModelChanging = true;                                         // Set flag
            searchProxyModel.clear()                                               // Clear proxy model
            window.isModelChanging = false;                                        // Clear flag
        }
        
        onCountChanged: window.syncSearchModel()                                   // Sync on count change
        onStatusChanged: { if (status === FolderListModel.Ready) window.syncSearchModel() } // Sync when ready
    }

     
    ListView {                                                                     // Main horizontal scrolling list of wallpaper cards
        id: view                                                                   // Unique identifier "view"
        anchors.fill: parent                                                       // Fills the entire window
        
        opacity: window.isReady ? 1.0 : 0.0                                        // Fades in when ready
        anchors.margins: window.isReady ? 0 : window.s(40)                         // Slides in from margins
        
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } } // Smooth fade
        Behavior on anchors.margins { NumberAnimation { duration: 700; easing.type: Easing.OutExpo } } // Smooth slide

        spacing: 0                                                                 // No spacing (managed by item width)
        orientation: ListView.Horizontal                                           // Horizontal scrolling
        clip: false                                                                // Allow items to extend beyond bounds (for 3D effect)

        interactive: !window.isScrollingBlocked && !window.isApplying              // Disable interaction during search or apply
        cacheBuffer: 2000                                                          // Cache 2000 pixels of items for smooth scrolling

        highlightRangeMode: ListView.StrictlyEnforceRange                          // Keep current item within visible range
        preferredHighlightBegin: (width / 2) - ((window.itemWidth * 1.5 + window.spacing) / 2) // Start of highlight zone (centered)
        preferredHighlightEnd: (width / 2) + ((window.itemWidth * 1.5 + window.spacing) / 2) // End of highlight zone (centered)
        
        highlightMoveDuration: window.initialFocusSet ? 500 : 0                    // Animated movement after initial focus (500ms), instant on first load
        focus: true                                                                // Accept keyboard focus
        
        onCurrentIndexChanged: {                                                   // When current item changes
            window.isItemAnimating = true;                                         // Set animation flag
            itemAnimationTimer.restart();                                          // Restart timer

            if (view.model !== searchProxyModel || window.currentFilter !== "Search") return; // Only track search selections
            
            if (!window.isModelChanging && window.hasSearched && window.searchIndexRestored) { // If user-initiated change
                if (currentIndex >= 0 && currentIndex < searchProxyModel.count) {  // If valid
                    let fname = searchProxyModel.get(currentIndex).fileName;       // Get filename
                    if (fname !== undefined && fname !== "") {                     // If exists
                        window.lastSearchName = String(fname);                     // Store last selected
                        searchState.lastName = String(fname);                      // Persist
                    }
                }
            }
        }
        
        add: Transition {                                                          // Animation when items are added
            enabled: window.initialFocusSet                                        // Only after initial focus
            ParallelAnimation {                                                    // Parallel animations
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic } // Fade in
                NumberAnimation { property: "scale"; from: 0.5; to: 1; duration: 400; easing.type: Easing.OutBack } // Scale up with overshoot
            }
        }
        addDisplaced: Transition {                                                 // Animation for displaced items
            enabled: window.initialFocusSet                                        // Only after initial focus
            NumberAnimation { property: "x"; duration: 400; easing.type: Easing.OutCubic } // Smooth horizontal movement
        }

        header: Item { width: Math.max(0, (view.width / 2) - ((window.itemWidth * 1.5) / 2)) } // Left spacer to center first item
        footer: Item { width: Math.max(0, (view.width / 2) - ((window.itemWidth * 1.5) / 2)) } // Right spacer to center last item

        model: window.activeModel                                                  // Use the active proxy model

        MouseArea {                                                                // Mouse area for scroll wheel handling
            anchors.fill: parent                                                   // Covers entire list
            acceptedButtons: Qt.NoButton                                           // Don't accept button clicks (pass through)

            onWheel: (wheel) => {                                                  // Mouse wheel handler
                if (window.isScrollingBlocked || window.isApplying) {              // If blocked
                    wheel.accepted = true;                                         // Accept to prevent propagation
                    return;
                }

                if (scrollThrottle.running) {                                      // If throttle active
                   wheel.accepted = true                                           // Accept and ignore
                   return
                }

                let dx = wheel.angleDelta.x                                        // Horizontal scroll delta
                let dy = wheel.angleDelta.y                                        // Vertical scroll delta
                let delta = Math.abs(dx) > Math.abs(dy) ? dx : dy                  // Use whichever is larger

                scrollAccum += delta                                               // Accumulate scroll

                if (Math.abs(scrollAccum) >= scrollThreshold) {                    // If accumulated enough
                    window.stepToNextValidIndex(scrollAccum > 0 ? -1 : 1)          // Navigate (inverted: scroll down = next)
                    scrollAccum = 0                                                // Reset accumulator
                    scrollThrottle.start()                                         // Start throttle
                }

                wheel.accepted = true                                              // Accept the event
            }        
        }

        delegate: Item {                                                           // Delegate defining each wallpaper card
            id: delegateRoot                                                       // Root item for the delegate
            
            readonly property string safeFileName: fileName !== undefined ? String(fileName) : "" // Safe string version of filename
            
            readonly property bool isCurrent: ListView.isCurrentItem && !window.isScrollingBlocked // Is this the current/centered item
            readonly property bool isFakeSelected: window.isScrollingBlocked && index === 0 // Fake selection during search
            readonly property bool isVisuallyEnlarged: isCurrent || isFakeSelected // Should this item appear enlarged
            
            readonly property bool isVideo: safeFileName.startsWith("000_")         // Is this a video wallpaper
            readonly property bool matchesFilter: window.checkItemMatchesFilter(safeFileName, isVideo, window.cacheVersion, window.currentFilter) // Does it match current filter
            
            readonly property real targetWidth: isVisuallyEnlarged ? (window.itemWidth * 1.5) : (window.itemWidth * 0.5) // Width: 1.5x when selected, 0.5x otherwise
            readonly property real targetHeight: isVisuallyEnlarged ? (window.itemHeight + window.s(30)) : window.itemHeight // Height: taller when selected
            
            property bool isPlayingVideo: false                                    // Whether video preview is playing

            Timer {                                                                // Timer before starting video preview
                id: videoPlayTimer                                                 // Unique identifier
                interval: 250                                                      // 250ms delay
                running: delegateRoot.isVisuallyEnlarged && delegateRoot.isVideo && !window.isScrollingBlocked && !window.isFilterAnimating && !window.isItemAnimating // Only when enlarged, is video, and not animating
                onTriggered: {                                                     // When timer fires
                    if (delegateRoot.isVisuallyEnlarged && delegateRoot.isVideo) { // Double-check conditions
                        delegateRoot.isPlayingVideo = true;                        // Start playing
                        previewPlayer.play();                                      // Begin playback
                    }
                }
            }

            onIsVisuallyEnlargedChanged: {                                         // When enlargement state changes
                if (!isVisuallyEnlarged) {                                         // If no longer enlarged
                    isPlayingVideo = false;                                        // Stop playing
                    videoPlayTimer.stop();                                         // Stop timer
                    previewPlayer.stop();                                          // Stop media player
                }
            }
            
            width: matchesFilter ? (targetWidth + window.spacing) : 0              // Width: full size if matching, 0 if not (hidden)
            visible: width > 0.1 || opacity > 0.01                                 // Visible if has width or opacity
            opacity: matchesFilter ? (isVisuallyEnlarged ? 1.0 : 0.6) : 0.0        // Opacity: full when enlarged, dimmed otherwise, hidden if not matching
            
            scale: matchesFilter ? 1.0 : 0.5                                       // Scale: normal if matching, shrunk if not

            height: matchesFilter ? targetHeight : 0                               // Height: full if matching, 0 if not
            anchors.verticalCenter: parent.verticalCenter                          // Vertically centered in list
            anchors.verticalCenterOffset: window.s(15)                             // Slight downward offset

            z: isVisuallyEnlarged ? 10 : 1                                         // z-index: higher when enlarged (on top)
            
            Behavior on scale { enabled: window.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } } // Animated scale
            Behavior on width { enabled: window.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } } // Animated width
            Behavior on height { enabled: window.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } } // Animated height
            Behavior on opacity { enabled: window.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } } // Animated opacity

            Item {                                                                 // Container for the 3D skewed card
                anchors.centerIn: parent                                           // Centered in delegate
                anchors.horizontalCenterOffset: ((window.itemHeight - height) / 2) * window.skewFactor // Offset for 3D perspective
                
                width: parent.width > 0 ? parent.width * (targetWidth / (targetWidth + window.spacing)) : 0 // Adjusted width
                height: parent.height                                              // Match parent height

                transform: Matrix4x4 {                                             // 3D transformation matrix
                    property real s: window.skewFactor                             // Skew factor
                    matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) // Shear/skew matrix for 3D effect
                }
                
                MouseArea {                                                        // Clickable area on the card
                    anchors.fill: parent                                           // Fill the skewed container
                    enabled: delegateRoot.matchesFilter && !window.isScrollingBlocked && !window.isApplying // Only when interactive
                    onClicked: {                                                   // Click handler
                        view.currentIndex = index                                  // Select this item
                        window.applyWallpaper(delegateRoot.safeFileName, delegateRoot.isVideo) // Apply the wallpaper
                    }
                }

                Image {                                                            // Background image (original un-skewed)
                    anchors.fill: parent                                           // Fill container
                    source: fileUrl !== undefined ? fileUrl : ""                    // Source from model
                    sourceSize: Qt.size(1, 1)                                     // Don't cache full resolution
                    fillMode: Image.Stretch                                        // Stretch to fill
                    visible: true                                                  // Always visible behind
                    asynchronous: true                                             // Load asynchronously
                }

                Item {                                                             // Container for the clipped and counter-skewed content
                    anchors.fill: parent                                           // Fill parent
                    anchors.margins: window.borderWidth                            // Inset by border width
                    Rectangle { anchors.fill: parent; color: _theme.base }         // Base color background
                    clip: true                                                     // Clip content to bounds

                    Image {                                                        // The actual wallpaper thumbnail (counter-skewed)
                        anchors.centerIn: parent                                   // Centered
                        anchors.horizontalCenterOffset: window.s(-50)              // Offset to compensate skew
                        width: (window.itemWidth * 1.5) + ((window.itemHeight + window.s(30)) * Math.abs(window.skewFactor)) + window.s(50) // Extra width for skew compensation
                        height: window.itemHeight + window.s(30)                   // Extra height
                        fillMode: Image.PreserveAspectCrop                         // Crop to fill
                        source: fileUrl !== undefined ? fileUrl : ""               // Source thumbnail
                        asynchronous: true                                         // Async loading

                        transform: Matrix4x4 {                                     // Counter-skew transformation
                            property real s: -window.skewFactor                    // Opposite skew
                            matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) // Inverse shear matrix
                        }
                    }
                    
                    MediaPlayer {                                                  // Media player for video wallpaper previews
                        id: previewPlayer                                          // Unique identifier
                        source: delegateRoot.isPlayingVideo ? "file://" + window.srcDir + "/" + window.getCleanName(delegateRoot.safeFileName) : "" // Source: clean path when playing, empty otherwise
                        audioOutput: AudioOutput { muted: true }                   // Muted audio output
                        videoOutput: previewOutput                                 // Video output to previewOutput
                        loops: MediaPlayer.Infinite                                // Loop infinitely
                    }

                    VideoOutput {                                                  // Video render output
                        id: previewOutput                                          // Unique identifier
                        anchors.centerIn: parent                                   // Centered like the image
                        anchors.horizontalCenterOffset: window.s(-50)              // Same offset
                        width: (window.itemWidth * 1.5) + ((window.itemHeight + window.s(30)) * Math.abs(window.skewFactor)) + window.s(50) // Same dimensions
                        height: window.itemHeight + window.s(30)
                        fillMode: VideoOutput.PreserveAspectCrop                   // Crop to fill
                        visible: delegateRoot.isPlayingVideo && previewPlayer.playbackState === MediaPlayer.PlayingState // Only visible when actually playing

                        transform: Matrix4x4 {                                     // Same counter-skew
                            property real s: -window.skewFactor
                            matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }
                    
                    Rectangle {                                                    // Video indicator badge (play triangle)
                        visible: delegateRoot.isVideo && (!delegateRoot.isPlayingVideo || previewPlayer.playbackState !== MediaPlayer.PlayingState) // Visible when video not actively playing
                        anchors.top: parent.top                                    // Top of card
                        anchors.right: parent.right                                // Right of card
                        anchors.margins: window.s(10)                             // Margin
                        width: window.s(32)                                       // Width
                        height: window.s(32)                                      // Height
                        radius: window.s(6)                                       // Rounded corners
                        color: Qt.rgba(_theme.base.r, _theme.base.g, _theme.base.b, 0.6) // Semi-transparent base
                        transform: Matrix4x4 {                                     // Counter-skew for badge
                            property real s: -window.skewFactor
                            matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                        
                        Canvas {                                                   // Play triangle icon
                            anchors.fill: parent                                   // Fill badge
                            anchors.margins: window.s(8)                          // Margin inside
                            property real scaleTrigger: window.s(1)               // Trigger repaint on scale change
                            onScaleTriggerChanged: requestPaint()                  // Repaint
                            onPaint: {                                             // Paint function
                                var ctx = getContext("2d");                        // Get context
                                var s = window.s;                                  // Scale function
                                ctx.reset();                                       // Reset context
                                ctx.fillStyle = Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.93); // Text color
                                ctx.beginPath();                                   // Begin path
                                ctx.moveTo(s(4), 0);                               // Top-left of triangle
                                ctx.lineTo(s(14), s(8));                           // Right point
                                ctx.lineTo(s(4), s(16));                           // Bottom-left
                                ctx.closePath();                                   // Close path
                                ctx.fill();                                        // Fill triangle
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {                                                                    // Filter bar background container
        id: filterBarBackground                                                    // Unique identifier
        anchors.top: parent.top                                                    // Top of window
        
        anchors.topMargin: window.isReady ? window.s(40) : window.s(-100)          // Slides down when ready
        opacity: window.isReady ? 1.0 : 0.0                                        // Fades in
        Behavior on anchors.topMargin { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } } // Smooth slide
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } } // Smooth fade

        anchors.horizontalCenter: parent.horizontalCenter                          // Centered horizontally
        z: 20                                                                      // Above wallpaper cards
        height: window.s(56)                                                       // Height
        width: filterRow.width + window.s(24)                                      // Dynamic width based on content
        radius: window.s(14)                                                       // Rounded corners
        
        color: Qt.rgba(_theme.mantle.r, _theme.mantle.g, _theme.mantle.b, 0.90)   // Semi-transparent mantle color
        border.color: _theme.surface2                                               // Surface2 border
        border.width: 1                                                            // 1px border

        Row {                                                                      // Horizontal row of filter controls
            id: filterRow                                                           // Unique identifier
            anchors.centerIn: parent                                                // Centered in bar
            spacing: window.s(12)                                                   // Spacing between items

            Rectangle {                                                            // Notification drawer (status messages)
                id: notifDrawer                                                     // Unique identifier
                height: window.s(44)                                               // Height
                property real paddingLeft: window.showSpinner ? window.s(40) : window.s(16) // Left padding (wider with spinner)
                property real targetWidth: window.showNotification ? Math.min(notifTextDrawer.implicitWidth + paddingLeft + window.s(20), window.s(300)) : 0 // Target width based on content
                width: targetWidth                                                  // Current width
                visible: width > 0.1                                                // Visible if has width
                radius: window.s(10)                                               // Rounded corners
                clip: true                                                          // Clip content
                anchors.verticalCenter: parent.verticalCenter                       // Vertically centered
                
                color: window.showNotification ? _theme.surface2 : "transparent"    // Colored when showing notification
                border.color: window.showNotification ? _theme.surface1 : "transparent" // Border when showing
                border.width: 1                                                     // 1px border

                Behavior on width {                                                  // Animated width
                    NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 0.5 } // Elastic animation
                }
                Behavior on color { ColorAnimation { duration: 400 } }               // Smooth color
                Behavior on border.color { ColorAnimation { duration: 400 } }        // Smooth border

                Item {                                                               // Spinner icon container
                    visible: window.showSpinner                                     // Visible when spinner active
                    width: window.s(44)                                             // Width
                    height: window.s(44)                                            // Height
                    anchors.left: parent.left                                       // Left aligned
                    anchors.verticalCenter: parent.verticalCenter                   // Vertically centered

                    Canvas {                                                         // Spinning arc indicator
                        id: notifSpinner                                            // Unique identifier
                        width: window.s(14)                                         // Width
                        height: window.s(14)                                        // Height
                        anchors.centerIn: parent                                    // Centered
                        property real scaleTrigger: window.s(1)                     // Repaint trigger
                        onScaleTriggerChanged: requestPaint()                       // Request repaint

                        onPaint: {                                                   // Paint function
                            var ctx = getContext("2d");                              // Get context
                            var s = window.s;                                        // Scale function
                            ctx.reset();                                             // Reset
                            ctx.lineWidth = s(2);                                    // Line width
                            ctx.strokeStyle = Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.3); // Faded circle
                            ctx.beginPath();                                         // Begin
                            ctx.arc(s(7), s(7), s(5), 0, Math.PI * 2);              // Full circle
                            ctx.stroke();                                            // Stroke circle
                            
                            ctx.strokeStyle = Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.9); // Bright arc
                            ctx.beginPath();                                         // Begin
                            ctx.arc(s(7), s(7), s(5), 0, Math.PI * 0.5);            // Quarter circle arc
                            ctx.stroke();                                            // Stroke arc
                        }
                        RotationAnimation on rotation {                              // Continuous rotation
                            loops: Animation.Infinite                                // Infinite
                            from: 0; to: 360                                         // Full rotation
                            duration: 800                                            // 800ms per rotation
                            running: window.showSpinner && window.showNotification   // Only when spinner shown
                        }
                    }
                }

                Text {                                                               // Notification text
                    id: notifTextDrawer                                              // Unique identifier
                    anchors.left: parent.left                                        // Left aligned
                    anchors.leftMargin: window.showSpinner ? window.s(40) : window.s(16) // Margin depends on spinner
                    anchors.verticalCenter: parent.verticalCenter                    // Vertically centered
                    width: Math.min(implicitWidth, window.s(300) - anchors.leftMargin - window.s(16)) // Constrained width
                    text: window.currentNotification                                 // Current notification text
                    
                    color: _theme.text                                               // Text color
                    font.family: "JetBrains Mono"                                    // Monospace font
                    font.pixelSize: window.s(14)                                     // Font size
                    font.bold: true                                                  // Bold
                    elide: Text.ElideRight                                            // Elide if too long

                    opacity: window.showNotification ? 0.9 : 0.0                     // Fade with notification
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } } // Smooth fade
                    Behavior on anchors.leftMargin {                                  // Animated margin
                        NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 0.5 } // Elastic
                    }
                }
            }

            Rectangle {                                                              // Monitor selector drawer
                id: monitorDrawer                                                    // Unique identifier
                visible: monitorModel.count > 1                                      // Only with multiple monitors
                height: window.s(44)                                                 // Height
                
                property real expandedWidth: window.s(44) + monitorListRow.width + window.s(8) // Width when expanded
                width: visible ? (window.isMonitorSelectorOpen ? expandedWidth : window.s(44)) : 0 // Width: icon only or expanded
                
                radius: window.s(10)                                                 // Rounded
                clip: true                                                           // Clip
                anchors.verticalCenter: parent.verticalCenter                        // Vertically centered
                
                color: window.isMonitorSelectorOpen ? _theme.surface2 : "transparent" // Colored when open
                border.color: window.isMonitorSelectorOpen ? _theme.text : _theme.surface1 // Accent border when open
                border.width: window.isMonitorSelectorOpen ? window.s(2) : 1         // Thicker border when open
                
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 0.5 } } // Elastic width
                Behavior on color { ColorAnimation { duration: 400 } }                // Smooth color
                Behavior on border.color { ColorAnimation { duration: 400 } }         // Smooth border

                MouseArea {                                                          // Clickable monitor icon
                    id: monitorIconMouse                                              // Unique identifier
                    width: window.s(44)                                              // Width
                    height: window.s(44)                                             // Height
                    anchors.left: parent.left                                        // Left aligned
                    anchors.verticalCenter: parent.verticalCenter                    // Vertically centered
                    hoverEnabled: true                                               // Enable hover
                    enabled: !window.isApplying                                      // Disabled during apply
                    cursorShape: Qt.PointingHandCursor                               // Hand cursor
                    onClicked: window.isMonitorSelectorOpen = !window.isMonitorSelectorOpen // Toggle selector
                }

                Canvas {                                                             // Monitor icon drawing
                    id: monitorIcon                                                  // Unique identifier
                    width: window.s(18)                                              // Width
                    height: window.s(18)                                             // Height
                    anchors.centerIn: monitorIconMouse                               // Centered on mouse area
                    property string activeColor: window.isMonitorSelectorOpen ? _theme.text : (monitorIconMouse.containsMouse ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7)) // Dynamic color
                    onActiveColorChanged: requestPaint()                             // Repaint on color change
                    property real scaleTrigger: window.s(1)                          // Scale trigger
                    onScaleTriggerChanged: requestPaint()                            // Repaint on scale change

                    onPaint: {                                                       // Paint function
                        var ctx = getContext("2d");                                  // Get context
                        var s = window.s;                                            // Scale function
                        ctx.reset();                                                 // Reset
                        ctx.lineWidth = s(2);                                        // Line width
                        ctx.strokeStyle = activeColor;                               // Stroke color
                        ctx.lineJoin = "round";                                      // Round joins
                        ctx.lineCap = "round";                                       // Round caps
                        
                        ctx.beginPath();                                             // Begin screen rectangle
                        ctx.rect(s(2), s(3), s(14), s(9));                          // Draw rectangle
                        ctx.stroke();                                                // Stroke
                        
                        ctx.beginPath();                                             // Begin stand
                        ctx.moveTo(s(9), s(12));                                     // Center bottom of screen
                        ctx.lineTo(s(9), s(16));                                     // Down to stand
                        ctx.moveTo(s(5), s(16));                                     // Left of base
                        ctx.lineTo(s(13), s(16));                                    // Right of base
                        ctx.stroke();                                                // Stroke stand
                    }
                }

                Row {                                                                // Row of monitor name buttons
                    id: monitorListRow                                               // Unique identifier
                    anchors.left: monitorIconMouse.right                             // To right of icon
                    anchors.verticalCenter: parent.verticalCenter                    // Vertically centered
                    spacing: window.s(8)                                             // Spacing
                    
                    opacity: window.isMonitorSelectorOpen ? 1.0 : 0.0                // Fade with expansion
                    Behavior on opacity { NumberAnimation { duration: 300 } }         // Smooth fade

                    Repeater {                                                       // Repeater for each monitor
                        model: monitorModel                                          // Monitor data model
                        delegate: Item {                                             // Individual monitor button
                            width: monitorText.contentWidth + window.s(16)           // Width based on text
                            height: window.s(32)                                    // Height
                            anchors.verticalCenter: parent.verticalCenter            // Vertically centered
                            
                            Rectangle {                                              // Button background
                                anchors.fill: parent                                 // Fill
                                radius: window.s(6)                                 // Rounded
                                color: model.selected ? _theme.text : _theme.surface1 // Selected: text color, unselected: surface1
                                border.color: model.selected ? _theme.text : _theme.surface2 // Matching border
                                border.width: 1                                     // 1px border
                                
                                Behavior on color { ColorAnimation { duration: 250 } } // Smooth color
                                Behavior on border.color { ColorAnimation { duration: 250 } } // Smooth border
                                
                                Text {                                               // Monitor name text
                                    id: monitorText                                  // Unique identifier
                                    text: model.name                                 // Monitor name from model
                                    anchors.centerIn: parent                         // Centered
                                    color: model.selected ? _theme.base : _theme.text // Inverted when selected
                                    font.family: "JetBrains Mono"                    // Monospace
                                    font.pixelSize: window.s(12)                     // Font size
                                    font.bold: model.selected                        // Bold when selected
                                    Behavior on color { ColorAnimation { duration: 250 } } // Smooth color
                                }
                            }

                            MouseArea {                                              // Clickable area
                                anchors.fill: parent                                 // Fill
                                hoverEnabled: true                                   // Hover
                                enabled: window.isMonitorSelectorOpen && !window.isApplying // Only when open
                                cursorShape: Qt.PointingHandCursor                   // Hand cursor
                                onClicked: {                                         // Click handler
                                    if (model.selected) {                            // If already selected
                                        let activeCount = 0;                         // Count selected
                                        for (let i = 0; i < monitorModel.count; i++) {
                                            if (monitorModel.get(i).selected) activeCount++;
                                        }
                                        if (activeCount > 1) {                       // Only deselect if more than one active
                                            monitorModel.setProperty(index, "selected", false); // Deselect
                                        }
                                    } else {                                         // If not selected
                                        monitorModel.setProperty(index, "selected", true); // Select
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Repeater {                                                               // Repeater for filter buttons
                model: window.filterData                                              // Filter data array

                delegate: Item {                                                      // Individual filter button
                    visible: modelData.name !== "Search"                              // Hide the Search filter button (handled by search box)
                    width: !visible ? 0 : ((modelData.name === "Video" || modelData.name === "All") ? window.s(44) : (modelData.hex === "" ? filterText.contentWidth + window.s(24) : window.s(36))) // Width based on type
                    height: !visible ? 0 : window.s(36)                              // Height
                    anchors.verticalCenter: parent.verticalCenter                     // Vertically centered
                    
                    Rectangle {                                                       // Filter button background
                        anchors.fill: parent                                          // Fill
                        radius: window.s(10)                                         // Rounded
                        color: modelData.hex === ""                                   // Background color
                                ? (window.currentFilter === modelData.name ? _theme.surface2 : "transparent") // Surface2 when active for text filters
                                : modelData.hex                                       // Use the filter hex color for color filters
                        
                        border.color: window.currentFilter === modelData.name ? _theme.text : _theme.surface1 // Accent border when active
                        border.width: window.currentFilter === modelData.name ? window.s(2) : 1 // Thicker when active
                        scale: window.currentFilter === modelData.name ? 1.15 : (filterMouse.containsMouse ? 1.08 : 1.0) // Enlarged when active, slightly on hover
                        
                        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } } // Elastic scale
                        Behavior on border.color { ColorAnimation { duration: 300 } } // Smooth border

                        Text {                                                       // Filter label text (for text-based filters)
                            id: filterText                                            // Unique identifier
                            visible: modelData.hex === "" && modelData.name !== "Video" && modelData.name !== "All" // Visible for named filters
                            text: modelData.label                                     // Label from model
                            anchors.centerIn: parent                                  // Centered
                            color: window.currentFilter === modelData.name ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7) // Bright when active
                            font.family: "JetBrains Mono"                             // Monospace
                            font.pixelSize: window.s(14)                             // Font size
                            font.bold: window.currentFilter === modelData.name        // Bold when active
                            Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutQuart } } // Smooth color
                        }

                        Canvas {                                                     // Play triangle for Video filter
                            visible: modelData.name === "Video"                      // Only for Video
                            width: window.s(14); height: window.s(16)               // Size
                            anchors.centerIn: parent                                 // Centered
                            anchors.horizontalCenterOffset: window.s(2)             // Slight right offset
                            property string activeColor: window.currentFilter === modelData.name ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7) // Dynamic color
                            onActiveColorChanged: requestPaint()                     // Repaint
                            property real scaleTrigger: window.s(1)                  // Scale trigger
                            onScaleTriggerChanged: requestPaint()                    // Repaint

                            onPaint: {                                               // Paint play triangle
                                var ctx = getContext("2d");
                                var s = window.s;
                                ctx.reset();
                                ctx.fillStyle = activeColor;
                                ctx.beginPath();
                                ctx.moveTo(0, 0);                                     // Top-left
                                ctx.lineTo(s(14), s(8));                              // Right point
                                ctx.lineTo(0, s(16));                                 // Bottom-left
                                ctx.closePath();
                                ctx.fill();
                            }
                        }

                        Canvas {                                                     // Grid icon for All filter
                            visible: modelData.name === "All"                        // Only for All
                            width: window.s(14); height: window.s(14)               // Size
                            anchors.centerIn: parent                                 // Centered
                            property string activeColor: window.currentFilter === modelData.name ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7) // Dynamic color
                            onActiveColorChanged: requestPaint()                     // Repaint
                            property real scaleTrigger: window.s(1)                  // Scale trigger
                            onScaleTriggerChanged: requestPaint()                    // Repaint

                            onPaint: {                                               // Paint 2x2 grid
                                var ctx = getContext("2d");
                                var s = window.s;
                                ctx.reset();
                                ctx.fillStyle = activeColor;
                                ctx.fillRect(0, 0, s(6), s(6));                      // Top-left square
                                ctx.fillRect(s(8), 0, s(6), s(6));                   // Top-right square
                                ctx.fillRect(0, s(8), s(6), s(6));                   // Bottom-left square
                                ctx.fillRect(s(8), s(8), s(6), s(6));                // Bottom-right square
                            }
                        }
                    }

                    MouseArea {                                                      // Clickable area for filter
                        id: filterMouse                                              // Unique identifier
                        anchors.fill: parent                                         // Fill
                        hoverEnabled: true                                           // Hover
                        enabled: !window.isApplying                                  // Disabled during apply
                        onClicked: window.currentFilter = modelData.name              // Set filter on click
                        cursorShape: Qt.PointingHandCursor                           // Hand cursor
                    }
                }
            }

            Rectangle {                                                              // Search pause/play toggle button
                id: searchControlBtn                                                 // Unique identifier
                visible: window.currentFilter === "Search" && window.hasSearched     // Only on search tab with results
                width: visible ? window.s(44) : 0                                    // Width when visible
                height: window.s(44)                                                 // Height
                radius: window.s(10)                                                 // Rounded
                clip: true                                                           // Clip
                anchors.verticalCenter: parent.verticalCenter                        // Vertically centered
                color: window.isSearchPaused ? _theme.surface2 : "transparent"        // Colored when paused
                border.color: window.isSearchPaused ? _theme.text : _theme.surface1   // Accent when paused
                border.width: window.isSearchPaused ? window.s(2) : 1                // Thicker when paused
                
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 0.5 } } // Elastic width
                Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutQuart } } // Smooth color
                
                MouseArea {                                                          // Clickable area
                    id: scMouse                                                      // Unique identifier
                    anchors.fill: parent                                             // Fill
                    hoverEnabled: true                                               // Hover
                    enabled: !window.isApplying                                      // Disabled during apply
                    cursorShape: Qt.PointingHandCursor                               // Hand cursor
                    onClicked: window.isSearchPaused = !window.isSearchPaused         // Toggle pause
                }
                
                Canvas {                                                             // Pause/Play icon
                    width: window.s(44); height: window.s(44)                       // Size
                    anchors.centerIn: parent                                         // Centered
                    property bool paused: window.isSearchPaused                      // Current state
                    property string activeColor: paused ? _theme.text : (scMouse.containsMouse ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7)) // Dynamic color
                    onActiveColorChanged: requestPaint()                             // Repaint
                    onPausedChanged: requestPaint()                                  // Repaint on state change
                    property real scaleTrigger: window.s(1)                          // Scale trigger
                    onScaleTriggerChanged: requestPaint()                            // Repaint
                    
                    onPaint: {                                                       // Paint function
                        var ctx = getContext("2d");
                        var s = window.s;
                        ctx.reset();
                        ctx.fillStyle = activeColor;
                        if (!paused) {                                               // If playing (show pause bars)
                            ctx.fillRect(s(15), s(14), s(4), s(16));                 // Left bar
                            ctx.fillRect(s(25), s(14), s(4), s(16));                 // Right bar
                        } else {                                                     // If paused (show play triangle)
                            ctx.beginPath();
                            ctx.moveTo(s(16), s(12));                                // Top-left
                            ctx.lineTo(s(32), s(22));                                // Right point
                            ctx.lineTo(s(16), s(32));                                // Bottom-left
                            ctx.closePath();
                            ctx.fill();
                        }
                    }
                }
            }

            Rectangle {                                                              // Search box container
                id: searchBox                                                        // Unique identifier
                height: window.s(44)                                                 // Height
                width: window.currentFilter === "Search" ? window.s(360) : window.s(44) // Width: expanded when on search tab
                radius: window.s(10)                                                 // Rounded
                clip: true                                                           // Clip
                anchors.verticalCenter: parent.verticalCenter                        // Vertically centered
                
                color: window.currentFilter === "Search" ? Qt.rgba(_theme.surface2.r, _theme.surface2.g, _theme.surface2.b, 0.8) : "transparent" // Colored when active
                border.color: window.currentFilter === "Search" ? _theme.text : _theme.surface1 // Accent when active
                border.width: window.currentFilter === "Search" ? window.s(2) : 1   // Thicker when active
                
                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 0.5 } } // Elastic width
                Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutQuart } } // Smooth color
                Behavior on border.color { ColorAnimation { duration: 400 } }        // Smooth border

                MouseArea {                                                          // Clickable area to toggle search
                    id: searchMouseArea                                              // Unique identifier
                    anchors.fill: parent                                             // Fill
                    hoverEnabled: true                                               // Hover
                    enabled: !window.isApplying                                      // Disabled during apply
                    cursorShape: Qt.PointingHandCursor                               // Hand cursor
                    onClicked: {                                                     // Click handler
                        if (window.currentFilter !== "Search") {                     // If not on search
                            window.currentFilter = "Search"                          // Switch to search
                        } else {                                                     // If on search
                            window.currentFilter = "All"                             // Switch back to All
                        }
                    }
                }

                Canvas {                                                             // Search magnifying glass icon
                    id: searchIcon                                                   // Unique identifier
                    width: window.s(44)                                              // Width
                    height: window.s(44)                                             // Height
                    anchors.left: parent.left                                        // Left aligned
                    anchors.leftMargin: window.currentFilter === "Search" ? window.s(5) : 0 // Margin when expanded
                    anchors.verticalCenter: parent.verticalCenter                    // Vertically centered
                    Behavior on anchors.leftMargin { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } } // Smooth margin
                    property string activeColor: window.currentFilter === "Search" ? _theme.text : (searchMouseArea.containsMouse ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7)) // Dynamic color
                    onActiveColorChanged: requestPaint()                             // Repaint
                    property real scaleTrigger: window.s(1)                          // Scale trigger
                    onScaleTriggerChanged: requestPaint()                            // Repaint

                    onPaint: {                                                       // Paint magnifying glass
                        var ctx = getContext("2d");
                        var s = window.s;
                        ctx.reset();
                        ctx.lineWidth = s(3);
                        ctx.strokeStyle = activeColor;
                        ctx.beginPath();
                        ctx.arc(s(18), s(18), s(7), 0, Math.PI * 2);                // Circle
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.moveTo(s(23), s(23));                                    // Handle start
                        ctx.lineTo(s(31), s(31));                                    // Handle end
                        ctx.stroke();
                    }
                }

                TextInput {                                                          // Search text input field
                    id: searchInput                                                  // Unique identifier
                    anchors.left: searchIcon.right                                   // Right of icon
                    anchors.right: submitBtn.left                                    // Left of submit button
                    anchors.rightMargin: window.s(8)                                // Right margin
                    anchors.verticalCenter: parent.verticalCenter                    // Vertically centered
                    
                    opacity: window.currentFilter === "Search" ? 1.0 : 0.0          // Visible when on search
                    visible: opacity > 0                                             // Hidden when transparent
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } } // Smooth fade
                    
                    color: _theme.text                                               // Text color
                    font.family: "JetBrains Mono"                                    // Monospace
                    font.pixelSize: window.s(16)                                    // Font size
                    clip: true                                                       // Clip
                    
                    onTextEdited: {                                                  // When user types
                        window.hasSearched = false;                                  // Reset search state
                        searchState.searched = false;                                // Clear persisted state
                    }
                    
                    onAccepted: {                                                    // When Enter pressed
                        window.triggerOnlineSearch();                                // Start the search
                        searchInput.focus = false;                                   // Remove focus
                        view.forceActiveFocus();                                     // Focus the wallpaper view
                    }
                }

                Rectangle {                                                          // Submit/search button
                    id: submitBtn                                                    // Unique identifier
                    width: window.s(32)                                              // Width
                    height: window.s(32)                                             // Height
                    radius: window.s(8)                                              // Rounded
                    anchors.right: parent.right                                      // Right aligned
                    anchors.rightMargin: window.s(8)                                // Right margin
                    anchors.verticalCenter: parent.verticalCenter                    // Vertically centered
                    
                    opacity: window.currentFilter === "Search" ? 1.0 : 0.0          // Visible when on search
                    visible: opacity > 0                                             // Hidden when transparent
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } } // Smooth fade

                    color: submitMouseArea.containsMouse ? _theme.surface1 : "transparent" // Highlight on hover
                    border.color: submitMouseArea.containsMouse ? _theme.text : _theme.surface2 // Border on hover
                    border.width: 1                                                  // 1px border
                    Behavior on color { ColorAnimation { duration: 300 } }           // Smooth color

                    MouseArea {                                                      // Clickable area
                        id: submitMouseArea                                          // Unique identifier
                        anchors.fill: parent                                         // Fill
                        cursorShape: Qt.PointingHandCursor                           // Hand cursor
                        hoverEnabled: true                                           // Hover
                        enabled: !window.isApplying                                  // Disabled during apply
                        onClicked: {                                                 // Click handler
                            window.triggerOnlineSearch();                            // Start search
                        }
                    }

                    Canvas {                                                         // Arrow icon for submit
                        width: window.s(16)                                          // Width
                        height: window.s(16)                                         // Height
                        anchors.centerIn: parent                                     // Centered
                        property string activeColor: submitMouseArea.containsMouse ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7) // Dynamic color
                        onActiveColorChanged: requestPaint()                         // Repaint
                        property real scaleTrigger: window.s(1)                      // Scale trigger
                        onScaleTriggerChanged: requestPaint()                        // Repaint
                        
                        onPaint: {                                                   // Paint right arrow
                            var ctx = getContext("2d");
                            var s = window.s;
                            ctx.reset();
                            ctx.lineWidth = s(2);
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";
                            ctx.strokeStyle = activeColor;
                            
                            ctx.beginPath();
                            ctx.moveTo(s(2), s(8));                                  // Left of arrow body
                            ctx.lineTo(s(14), s(8));                                 // Right of arrow body
                            ctx.moveTo(s(9), s(3));                                  // Top of arrowhead
                            ctx.lineTo(s(14), s(8));                                 // Arrowhead to body
                            ctx.lineTo(s(9), s(13));                                 // Bottom of arrowhead
                            ctx.stroke();
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {                                                       // Code that runs when the component finishes loading
        Quickshell.execDetached(["bash", "-c", "mkdir -p '" + decodeURIComponent(window.searchDir.replace("file://", "")) + "'"]); // Ensure search directory exists
        
        window.loadMonitors();                                                      // Load monitor information

        if (searchState.searched) {                                                 // If previous search state persisted
            searchInput.text = searchState.query;                                   // Restore search query
            window.searchQuery = searchState.query;                                 // Set search query
            window.hasSearched = true;                                              // Mark as searched
            window.lastSearchName = searchState.lastName;                           // Restore last selected
            window.isSearchPaused = true;                                           // Start paused
        }

        view.forceActiveFocus();                                                    // Focus the wallpaper view
        window.processMarkers();                                                    // Process color markers
        window.triggerColorExtraction();                                            // Start color extraction
    }

    Component.onDestruction: {                                                      // Code that runs when the component is destroyed (popup closed)
        if (window.hasSearched) {                                                   // If a search was performed
            searchState.query = searchInput.text;                                   // Persist search query
            searchState.searched = window.hasSearched;                              // Persist search state
            searchState.lastName = window.lastSearchName;                           // Persist last selected
            
            Quickshell.execDetached(["bash", "-c", "echo 'pause' > /tmp/ddg_search_control"]); // Pause the search pipeline
        } else {                                                                    // If no search was done
            Quickshell.execDetached(["bash", "-c", "echo 'stop' > /tmp/ddg_search_control; for p in $(pgrep -f ddg_search.sh); do if [ \"$p\" != \"$$\" ] && [ \"$p\" != \"$BASHPID\" ]; then kill -9 $p 2>/dev/null || true; fi; done; pkill -f '[g]et_ddg_links.py'"]); // Stop and kill all search processes
        }
    }
}