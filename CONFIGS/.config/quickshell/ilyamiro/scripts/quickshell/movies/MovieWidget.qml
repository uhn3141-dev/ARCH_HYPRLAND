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
//     readonly property color mantle: _theme.mantle
//     readonly property color text: _theme.text
//     readonly property color subtext0: _theme.subtext0
//     readonly property color surface0: _theme.surface0
//     readonly property color surface1: _theme.surface1
//     readonly property color surface2: _theme.surface2
//     readonly property color mauve: _theme.mauve || "#cba6f7"
//     readonly property color blue: _theme.blue || "#89b4fa"
//     readonly property color green: _theme.green || "#a6e3a1"
//     readonly property color red: _theme.red || "#f38ba8"

//     // --- STATE MANAGEMENT ---
//     property string currentView: "search" // "search" or "series"
//     property string mediaType: "movie" // "movie" or "tv"
//     property string filterSort: "Default"
//     property bool isSearching: searchInput.text.trim() !== ""
//     property bool isSearchingNetwork: false
//     property bool isSearchMode: window.isSearching
//     property string selectedImdbId: ""
//     property string selectedTitle: ""
//     property string selectedPoster: ""
//     property string selectedDescription: ""
//     property var seriesDataMap: ({})
//     property int currentSeason: 1
//     property bool isLoadingSeries: false
//     property bool trendingMoviesLoaded: false
//     property bool trendingTvLoaded: false
//     property bool isFetchingMovies: false
//     property bool isFetchingTv: false
//     property bool isLoadingPopular: isFetchingMovies || isFetchingTv
//     property var currentFetchResults: []
//     property var rawTrendingMovies: []
//     property var rawTrendingTv: []
//     property real trendingMoviesLastFetch: 0
//     property real trendingTvLastFetch: 0
//     readonly property real trendingCacheMaxAge: 12 * 60 * 60 * 1000
//     property bool seasonSwitching: false
//     property bool stateRestored: false
//     property bool pendingSeriesFocusRestore: false

//     Timer {
//         id: safetyLoadingTimer
//         interval: 12000
//         running: window.isLoadingPopular || window.isSearchingNetwork
//         repeat: false
//         onTriggered: {
//             window.isFetchingMovies = false
//             window.isFetchingTv = false
//             window.isSearchingNetwork = false
//         }
//     }

//     Timer {
//         id: searchDebounceTimer
//         interval: 400
//         repeat: false
//         onTriggered: {
//             if (searchInput.text.trim() !== "") {
//                 doSearch(searchInput.text)
//             }
//         }
//     }

//     Timer {
//         id: seriesFocusRestoreTimer
//         interval: 350
//         repeat: false
//         onTriggered: {
//             if (window.currentView === "series" && !window.isSourceModalOpen) {
//                 window.forceActiveFocus()
//                 window.pendingSeriesFocusRestore = false
//             }
//         }
//     }

//     // --- SHARED DISK I/O HELPER ---
//     function saveJsonToCache(filename, dataObj) {
//         let jsStr = JSON.stringify(dataObj).replace(/'/g, "'\\''")
//         Quickshell.execDetached(["bash", "-c", "mkdir -p ~/.cache && echo '" + jsStr + "' > ~/.cache/" + filename])
//     }

//     // --- PERSISTENT CACHE IO ---
//     Process {
//         id: readHistoryProc
//         command: ["bash", "-c", "cat ~/.cache/qs_movie_history.json 2>/dev/null || echo '[]'"]
//         running: false
//         stdout: SplitParser {
//             onRead: (data) => {
//                 try {
//                     let parsed = JSON.parse(data.trim())
//                     searchHistoryModel.clear()
//                     for (let i = parsed.length - 1; i >= 0; i--) {
//                         searchHistoryModel.insert(0, { query: parsed[i] })
//                     }
//                 } catch(e) {}
//             }
//         }
//     }

//     Process {
//         id: readWatchHistoryProc
//         command: ["bash", "-c", "cat ~/.cache/qs_movie_watch_history.json 2>/dev/null || echo '[]'"]
//         running: false
//         stdout: SplitParser {
//             onRead: (data) => {
//                 try {
//                     let parsed = JSON.parse(data.trim())
//                     watchHistoryModel.clear()
//                     for (let i = parsed.length - 1; i >= 0; i--) {
//                         watchHistoryModel.insert(0, parsed[i])
//                     }
//                 } catch(e) {}
//             }
//         }
//     }

//     function processTrendingCache(parsed, typeStr, targetModel) {
//         let now = Date.now()
//         let isMovie = typeStr === "movie"
//         let lastFetch = parsed[isMovie ? "moviesLastFetch" : "tvLastFetch"] || 0
//         let items = parsed[isMovie ? "movies" : "tv"]

//         if (items && items.length > 0) {
//             targetModel.clear()
//             if (isMovie) window.rawTrendingMovies = items; else window.rawTrendingTv = items
//             for (let i = 0; i < items.length; i++) targetModel.append(items[i])
            
//             if (isMovie) { window.trendingMoviesLoaded = true; window.isFetchingMovies = false; window.trendingMoviesLastFetch = lastFetch } 
//             else { window.trendingTvLoaded = true; window.isFetchingTv = false; window.trendingTvLastFetch = lastFetch }
            
//             if ((now - lastFetch) > window.trendingCacheMaxAge) fetchTrending(typeStr === "movie" ? "movie" : "series")
//         } else {
//             fetchTrending(typeStr === "movie" ? "movie" : "series")
//         }
//     }

//     Process {
//         id: readTrendingCacheProc
//         command: ["bash", "-c", "cat ~/.cache/qs_trending_cache.json 2>/dev/null || echo '{}'"]
//         running: false
//         stdout: SplitParser {
//             onRead: (data) => {
//                 try {
//                     let parsed = JSON.parse(data.trim())
//                     processTrendingCache(parsed, "movie", cachedTrendingMovies)
//                     processTrendingCache(parsed, "tv", cachedTrendingTv)
//                 } catch(e) {
//                     fetchTrending("movie")
//                     fetchTrending("series")
//                 }
//             }
//         }
//     }

//     Process {
//         id: readUiStateProc
//         command: ["bash", "-c", "cat ~/.cache/qs_ui_state.json 2>/dev/null || echo '{}'"]
//         running: false
//         stdout: SplitParser {
//             onRead: (data) => {
//                 try {
//                     let s = JSON.parse(data.trim())
//                     if (!s || Object.keys(s).length === 0) {
//                         window.stateRestored = true
//                         return
//                     }
//                     if (s.mediaType) window.mediaType = s.mediaType
//                     if (s.filterSort) {
//                         window.filterSort = s.filterSort
//                         let idx = filterSelector.model.indexOf(s.filterSort)
//                         if (idx >= 0) filterSelector.currentIndex = idx
//                     }
//                     if (s.searchText && s.searchText !== "") searchInput.text = s.searchText
//                     if (s.currentView) window.currentView = s.currentView
//                     if (s.selectedImdbId) window.selectedImdbId = s.selectedImdbId
//                     if (s.selectedTitle) window.selectedTitle = s.selectedTitle
//                     if (s.selectedPoster) window.selectedPoster = s.selectedPoster
//                     if (s.selectedDescription) window.selectedDescription = s.selectedDescription
//                     if (s.currentSeason) window.currentSeason = s.currentSeason
                    
//                     if (s.isSourceModalOpen && s.pendingMedia && s.pendingMedia.imdbId) {
//                         window.pendingMedia = s.pendingMedia
//                         window.foundSourceName = s.foundSourceName || ""
//                         for (let i = 0; i < sourceModel.count; i++) sourceModel.setProperty(i, "status", "pending")
//                         window.isSourceModalOpen = true
//                         if (s.checkingState === "found" && s.foundSourceName) {
//                             window.checkingState = "found"
//                             for (let i = 0; i < sourceModel.count; i++) {
//                                 if (sourceModel.get(i).name === s.foundSourceName) {
//                                     sourceModel.setProperty(i, "status", "success")
//                                     window.currentCheckIndex = i
//                                     break
//                                 }
//                             }
//                         } else {
//                             window.sourceCheckOrder = buildSourceOrder()
//                             window.sourceCheckStep = 0
//                             window.currentCheckIndex = window.sourceCheckOrder[0]
//                             window.checkingState = "checking"
//                             checkNextSource()
//                         }
//                     }
//                     if (s.currentView === "series" && s.selectedImdbId) {
//                         window.pendingSeriesFocusRestore = true
//                         fetchSeriesData(s.selectedImdbId, s.currentSeason || 1, "", "", true)
//                     }
//                     window.stateRestored = true
//                 } catch(e) {
//                     window.stateRestored = true
//                 }
//             }
//         }
//     }

//     property var sourcePrefs: ({})
//     Process {
//         id: readSourcePrefsProc
//         command: ["bash", "-c", "cat ~/.cache/qs_source_prefs.json 2>/dev/null || echo '{}'"]
//         running: false
//         stdout: SplitParser {
//             onRead: (data) => {
//                 try { window.sourcePrefs = JSON.parse(data.trim()) } 
//                 catch(e) { window.sourcePrefs = {} }
//             }
//         }
//     }

//     // --- SAVING CACHE FUNCTIONS ---
//     function saveUiState() {
//         saveJsonToCache("qs_ui_state.json", {
//             mediaType: window.mediaType, filterSort: window.filterSort, searchText: searchInput.text,
//             currentView: window.currentView, selectedImdbId: window.selectedImdbId,
//             selectedTitle: window.selectedTitle, selectedPoster: window.selectedPoster,
//             selectedDescription: window.selectedDescription, currentSeason: window.currentSeason,
//             isSourceModalOpen: window.isSourceModalOpen, checkingState: window.checkingState,
//             pendingMedia: window.pendingMedia, foundSourceName: window.foundSourceName
//         })
//     }

//     function saveHistory() {
//         let arr = []
//         for (let i = 0; i < searchHistoryModel.count; i++) arr.push(searchHistoryModel.get(i).query)
//         saveJsonToCache("qs_movie_history.json", arr)
//     }

//     function saveWatchHistory() {
//         let arr = []
//         for (let i = 0; i < watchHistoryModel.count; i++) {
//             let item = watchHistoryModel.get(i)
//             arr.push({ imdbId: item.imdbId, title: item.title, poster: item.poster, type: item.type })
//         }
//         saveJsonToCache("qs_movie_watch_history.json", arr)
//     }

//     function saveTrendingCache() {
//         if (cachedTrendingMovies.count === 0 || cachedTrendingTv.count === 0) return
//         let cacheObj = { moviesLastFetch: window.trendingMoviesLastFetch, tvLastFetch: window.trendingTvLastFetch, movies: [], tv: [] }
//         for (let i = 0; i < cachedTrendingMovies.count; i++) {
//             let m = cachedTrendingMovies.get(i)
//             cacheObj.movies.push({ imdbId: m.imdbId, title: m.title, poster: m.poster, type: m.type, year: m.year, rating: m.rating || 0, popularity: i })
//         }
//         for (let i = 0; i < cachedTrendingTv.count; i++) {
//             let t = cachedTrendingTv.get(i)
//             cacheObj.tv.push({ imdbId: t.imdbId, title: t.title, poster: t.poster, type: t.type, year: t.year, rating: t.rating || 0, popularity: i })
//         }
//         saveJsonToCache("qs_trending_cache.json", cacheObj)
//     }

//     function saveSourcePref(imdbId, sourceName) {
//         let prefs = window.sourcePrefs
//         prefs[imdbId] = sourceName
//         window.sourcePrefs = prefs
//         saveJsonToCache("qs_source_prefs.json", prefs)
//     }

//     // --- SOURCE MODEL ---
//     ListModel {
//         id: sourceModel
//         ListElement { name: "VidSrc.net";    urlMovie: "https://vidsrc.net/embed/movie/%1";                               urlTv: "https://vidsrc.net/embed/tv/%1/%2/%3";                            status: "pending" }
//         ListElement { name: "VidLink";       urlMovie: "https://vidlink.pro/movie/%1?autoplay=1";                         urlTv: "https://vidlink.pro/tv/%1/%2/%3?autoplay=1";                      status: "pending" }
//         ListElement { name: "VidSrc.pro";    urlMovie: "https://vidsrc.pro/embed/movie/%1";                               urlTv: "https://vidsrc.pro/embed/tv/%1/%2/%3";                            status: "pending" }
//         ListElement { name: "VidSrc.in";     urlMovie: "https://vidsrc.in/embed/movie/%1";                                urlTv: "https://vidsrc.in/embed/tv/%1/%2/%3";                             status: "pending" }
//         ListElement { name: "VidSrc.cc";     urlMovie: "https://vidsrc.cc/v2/embed/movie/%1?autoPlay=true";               urlTv: "https://vidsrc.cc/v2/embed/tv/%1/%2/%3?autoPlay=true";            status: "pending" }
//         ListElement { name: "Embed.su";      urlMovie: "https://embed.su/embed/movie/%1";                                 urlTv: "https://embed.su/embed/tv/%1/%2/%3";                              status: "pending" }
//         ListElement { name: "SmashyStream";  urlMovie: "https://player.smashy.stream/movie/%1";                           urlTv: "https://player.smashy.stream/tv/%1?s=%2&e=%3";                    status: "pending" }
//         ListElement { name: "AutoEmbed";     urlMovie: "https://autoembed.to/movie/imdb/%1";                              urlTv: "https://autoembed.to/tv/imdb/%1-%2-%3";                           status: "pending" }
//         ListElement { name: "2Embed";        urlMovie: "https://www.2embed.cc/embed/%1";                                  urlTv: "https://www.2embed.cc/embedtv/%1&s=%2&e=%3";                      status: "pending" }
//         ListElement { name: "MultiEmbed";    urlMovie: "https://multiembed.mov/directstream.php?video_id=%1";             urlTv: "https://multiembed.mov/directstream.php?video_id=%1&s=%2&e=%3";  status: "pending" }
//     }

//     // --- ANIMATIONS & FOCUS ---
//     property real introPhase: 0
//     NumberAnimation on introPhase {
//         id: introPhaseAnim
//         from: 0; to: 1; duration: 800; easing.type: Easing.OutQuart; running: true
//     }

//     Timer {
//         id: focusTimer
//         interval: 50; running: true; repeat: false
//         onTriggered: {
//             if (window.currentView === "search") searchInput.forceActiveFocus()
//             else window.forceActiveFocus()
//         }
//     }

//     Timer {
//         id: scrollToTopTimer
//         interval: 80; running: false; repeat: false
//         onTriggered: {
//             movieGrid.positionViewAtBeginning()
//             tvGrid.positionViewAtBeginning()
//             searchGrid.positionViewAtBeginning()
//         }
//     }

//     Component.onCompleted: {
//         readHistoryProc.running = true
//         readWatchHistoryProc.running = true
//         readSourcePrefsProc.running = true
//         window.isFetchingMovies = true
//         window.isFetchingTv = true
//         readTrendingCacheProc.running = true
//         readUiStateProc.running = true
//     }

//     Connections {
//         target: window
//         function onVisibleChanged() {
//             if (window.visible) {
//                 introPhaseAnim.restart()
//                 if (!window.isSourceModalOpen && window.currentView === "search") {
//                     focusTimer.restart()
//                     scrollToTopTimer.restart()
//                 } else if (window.currentView === "series") {
//                     seriesFocusRestoreTimer.restart()
//                 }
//                 if (searchHistoryModel.count === 0) readHistoryProc.running = true
//                 if (watchHistoryModel.count === 0) readWatchHistoryProc.running = true
//                 if (!window.trendingMoviesLoaded) fetchTrending("movie")
//                 if (!window.trendingTvLoaded) fetchTrending("series")
//                 if (searchInput.text !== "") doSearch(searchInput.text)
//                 if (window.currentView === "series" && window.selectedImdbId !== "" && episodeModel.count === 0) {
//                     fetchSeriesData(window.selectedImdbId, window.currentSeason, "", "", true)
//                 }
//             } else {
//                 saveUiState()
//             }
//         }
//     }

//     Keys.onPressed: (event) => {
//         if (window.isSourceModalOpen) {
//             if (event.key === Qt.Key_Escape) { window.closeSourceModal(); event.accepted = true }
//         } else if (window.currentView === "series") {
//             if (event.key === Qt.Key_Escape) {
//                 window.currentView = "search"
//                 searchInput.forceActiveFocus()
//                 event.accepted = true
//             } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
//                 let sCount = seasonModel.count
//                 if (sCount > 0) {
//                     let idx = -1
//                     for (let i = 0; i < sCount; i++) { if (seasonModel.get(i).seasonNum === window.currentSeason) { idx = i; break } }
//                     if (idx !== -1) {
//                         let step = event.key === Qt.Key_Tab ? 1 : -1
//                         window.currentSeason = seasonModel.get((idx + step + sCount) % sCount).seasonNum
//                         updateEpisodes(window.currentSeason)
//                     }
//                 }
//                 event.accepted = true
//             } else if (event.key === Qt.Key_Down) {
//                 if (epList.currentIndex < epList.count - 1) epList.currentIndex++; event.accepted = true
//             } else if (event.key === Qt.Key_Up) {
//                 if (epList.currentIndex > 0) epList.currentIndex--; event.accepted = true
//             } else if (event.key === Qt.Key_Return) {
//                 let ep = episodeModel.get(epList.currentIndex)
//                 if (ep) startSourceCheck("tv", window.selectedImdbId, window.selectedTitle, window.selectedPoster, window.currentSeason, ep.epNum)
//                 event.accepted = true
//             }
//         } else if (event.key === Qt.Key_Escape) {
//             saveUiState()
//             Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"])
//             event.accepted = true
//         }
//     }

//     property bool isKeyboardNav: false
//     Timer { id: keyboardNavTimer; interval: 500; repeat: false; onTriggered: window.isKeyboardNav = false }

//     ListModel { id: searchHistoryModel }
//     ListModel { id: watchHistoryModel }
//     ListModel { id: cachedTrendingMovies }
//     ListModel { id: cachedTrendingTv }
//     ListModel { id: searchResults }
//     ListModel { id: seasonModel }
//     ListModel { id: episodeModel }

//     function addToWatchHistory(item) {
//         for (let i = 0; i < watchHistoryModel.count; i++) {
//             if (watchHistoryModel.get(i).imdbId === item.imdbId) {
//                 watchHistoryModel.remove(i)
//                 break
//             }
//         }
//         watchHistoryModel.insert(0, item)
//         if (watchHistoryModel.count > 15) watchHistoryModel.remove(15)
//         saveWatchHistory()
//     }

//     function addSearchHistory(query) {
//         if (query.trim() === "") return
//         for (let i = 0; i < searchHistoryModel.count; i++) {
//             if (searchHistoryModel.get(i).query.toLowerCase() === query.toLowerCase()) {
//                 searchHistoryModel.remove(i)
//                 break
//             }
//         }
//         searchHistoryModel.insert(0, { query: query.trim() })
//         if (searchHistoryModel.count > 10) searchHistoryModel.remove(10)
//         saveHistory()
//     }

//     // ==========================================
//     // SOURCE CHECKING SYSTEM
//     // ==========================================
//     property bool isSourceModalOpen: false
//     property int currentCheckIndex: 0
//     property var pendingMedia: ({})
//     property string checkingState: "idle"
//     property string foundSourceName: ""
//     property var activeCheckXhr: null
//     readonly property var errorPagePatterns: [
//         "404", "not found", "no results", "video not found", "media not found",
//         "content not found", "page not found", "error 404", "does not exist"
//     ]

//     function buildSourceUrl(srcIndex) {
//         let src = sourceModel.get(srcIndex)
//         let m = pendingMedia
//         if (m.type === "movie") return src.urlMovie.arg(m.imdbId)
//         return src.urlTv.arg(m.imdbId).arg(m.season).arg(m.ep)
//     }

//     function buildSourceOrder() {
//         let order = []
//         let imdbId = pendingMedia.imdbId
//         let preferred = window.sourcePrefs[imdbId] || null
//         let prefIdx = -1
//         if (preferred) {
//             for (let i = 0; i < sourceModel.count; i++) {
//                 if (sourceModel.get(i).name === preferred) { prefIdx = i; break }
//             }
//         }
//         if (prefIdx !== -1) order.push(prefIdx)
//         for (let i = 0; i < sourceModel.count; i++) { if (i !== prefIdx) order.push(i) }
//         return order
//     }

//     property var sourceCheckOrder: []
//     property int sourceCheckStep: 0

//     function startSourceCheck(type, imdbId, title, poster, season, ep) {
//         pendingMedia = { type: type, imdbId: imdbId, title: title, poster: poster, season: season, ep: ep }
//         for (let i = 0; i < sourceModel.count; i++) sourceModel.setProperty(i, "status", "pending")
//         addToWatchHistory({ imdbId: imdbId, title: title, poster: poster, type: type })
//         window.sourceCheckOrder = buildSourceOrder()
//         window.sourceCheckStep = 0
//         window.currentCheckIndex = window.sourceCheckOrder[0]
//         window.foundSourceName = ""
//         window.isSourceModalOpen = true
//         window.checkingState = "checking"
//         if (sourceListUI) sourceListUI.positionViewAtBeginning()
//         checkNextSource()
//         saveUiState()
//     }

//     function closeSourceModal() {
//         if (window.activeCheckXhr !== null) {
//             try { window.activeCheckXhr.abort() } catch(e) {}
//             window.activeCheckXhr = null
//         }
//         window.isSourceModalOpen = false
//         window.checkingState = "idle"
//         if (window.currentView === "series") window.forceActiveFocus()
//         else searchInput.forceActiveFocus()
//         saveUiState()
//     }

//     function skipToNextSource() {
//         if (window.activeCheckXhr !== null) {
//             try { window.activeCheckXhr.abort() } catch(e) {}
//             window.activeCheckXhr = null
//         }
//         sourceModel.setProperty(window.currentCheckIndex, "status", "failed")
//         window.sourceCheckStep++
//         if (window.sourceCheckStep < window.sourceCheckOrder.length) {
//             window.currentCheckIndex = window.sourceCheckOrder[window.sourceCheckStep]
//             window.checkingState = "checking"
//             checkNextSource()
//         } else {
//             window.checkingState = "failed_all"
//         }
//     }

//     function checkNextSource() {
//         if (!window.isSourceModalOpen || window.checkingState !== "checking") return
//         if (window.sourceCheckStep >= window.sourceCheckOrder.length) {
//             window.checkingState = "failed_all"
//             return
//         }
        
//         window.currentCheckIndex = window.sourceCheckOrder[window.sourceCheckStep]
//         sourceModel.setProperty(window.currentCheckIndex, "status", "checking")
//         if (sourceListUI) sourceListUI.positionViewAtIndex(window.currentCheckIndex, ListView.Contain)
        
//         let idx = window.currentCheckIndex
//         let step = window.sourceCheckStep
//         let url = buildSourceUrl(idx)
//         let xhr = new XMLHttpRequest()
//         window.activeCheckXhr = xhr
        
//         xhr.open("GET", url, true)
//         xhr.timeout = 6000
//         xhr.onreadystatechange = function() {
//             if (xhr.readyState !== XMLHttpRequest.DONE || !window.isSourceModalOpen || window.checkingState !== "checking" || window.sourceCheckStep !== step) return
//             window.activeCheckXhr = null
//             let code = xhr.status
//             let body = xhr.responseText ? xhr.responseText.toLowerCase() : ""
            
//             if (code === 404 || code === 410) {
//                 sourceModel.setProperty(idx, "status", "failed")
//                 window.sourceCheckStep++
//                 checkNextSource()
//                 return
//             }
//             if (code === 200 && body.length < 3000) {
//                 let looksLikeError = false
//                 for (let i = 0; i < window.errorPagePatterns.length; i++) {
//                     if (body.indexOf(window.errorPagePatterns[i]) !== -1) {
//                         looksLikeError = true
//                         break
//                     }
//                 }
//                 if (looksLikeError) {
//                     sourceModel.setProperty(idx, "status", "failed")
//                     window.sourceCheckStep++
//                     checkNextSource()
//                     return
//                 }
//             }
//             let isLive = (code === 0) || (code >= 200 && code < 400) || code === 401 || code === 403
//             if (isLive) {
//                 sourceModel.setProperty(idx, "status", "success")
//                 window.foundSourceName = sourceModel.get(idx).name
//                 window.checkingState = "found"
//                 saveUiState()
//                 Quickshell.execDetached(["xdg-open", url])
//             } else {
//                 sourceModel.setProperty(idx, "status", "failed")
//                 window.sourceCheckStep++
//                 checkNextSource()
//             }
//         }
//         xhr.ontimeout = function() {
//             if (!window.isSourceModalOpen || window.checkingState !== "checking" || window.sourceCheckStep !== step) return
//             window.activeCheckXhr = null
//             sourceModel.setProperty(idx, "status", "failed")
//             window.sourceCheckStep++
//             checkNextSource()
//         }
//         xhr.onerror = function() {
//             if (!window.isSourceModalOpen || window.checkingState !== "checking" || window.sourceCheckStep !== step) return
//             window.activeCheckXhr = null
//             sourceModel.setProperty(idx, "status", "success")
//             window.foundSourceName = sourceModel.get(idx).name
//             window.checkingState = "found"
//             saveUiState()
//             Quickshell.execDetached(["xdg-open", url])
//         }
//         xhr.send()
//     }

//     // --- DATA FETCHING & FILTERING ---
//     function fetchTrending(typeStr) {
//         let isMovie = typeStr === "movie"
//         if (isMovie) window.isFetchingMovies = true; else window.isFetchingTv = true
        
//         var xhr = new XMLHttpRequest()
//         xhr.open("GET", "https://v3-cinemeta.strem.io/catalog/" + typeStr + "/top.json")
//         xhr.onerror = function() { if (isMovie) window.isFetchingMovies = false; else window.isFetchingTv = false }
//         xhr.onreadystatechange = function() {
//             if (xhr.readyState !== XMLHttpRequest.DONE) return
//             if (isMovie) window.isFetchingMovies = false; else window.isFetchingTv = false
//             if (xhr.status === 200) {
//                 try {
//                     let res = JSON.parse(xhr.responseText)
//                     if (res && res.metas) {
//                         let rawItems = []
//                         let targetModel = isMovie ? cachedTrendingMovies : cachedTrendingTv
//                         targetModel.clear()
//                         for (let i = 0; i < res.metas.length; i++) {
//                             let item = res.metas[i]
//                             if (!item.id || !item.poster) continue
//                             let entry = {
//                                 imdbId: item.id,
//                                 title: item.name || "Unknown",
//                                 poster: item.poster || item.posterShape || item.background || item.logo || "",
//                                 type: isMovie ? "movie" : "tv",
//                                 year: item.releaseInfo || "N/A",
//                                 rating: item.imdbRating || 0,
//                                 popularity: i
//                             }
//                             rawItems.push(entry)
//                             targetModel.append(entry)
//                         }
//                         if (isMovie) { window.rawTrendingMovies = rawItems; window.trendingMoviesLastFetch = Date.now(); window.trendingMoviesLoaded = true } 
//                         else { window.rawTrendingTv = rawItems; window.trendingTvLastFetch = Date.now(); window.trendingTvLoaded = true }
//                         saveTrendingCache()
//                     }
//                 } catch(e) {}
//             }
//         }
//         xhr.send()
//     }

//     function getSortValue(item, field) {
//         if (field === "year") return parseInt(item.year || item.releaseInfo || 0) || 0
//         if (field === "title") return (item.title || item.name || "").toString()
//         if (field === "rating") return parseFloat(item.rating || item.imdbRating || 0) || 0
//         return 0
//     }

//     function sortItems(items) {
//         let mode = window.filterSort
//         if (mode === "Year (Newest)") items.sort((a, b) => getSortValue(b, "year") - getSortValue(a, "year"))
//         else if (mode === "Year (Oldest)") items.sort((a, b) => getSortValue(a, "year") - getSortValue(b, "year"))
//         else if (mode === "Title (A-Z)") items.sort((a, b) => getSortValue(a, "title").localeCompare(getSortValue(b, "title")))
//         else if (mode === "Title (Z-A)") items.sort((a, b) => getSortValue(b, "title").localeCompare(getSortValue(a, "title")))
//         else if (mode === "Rating (Best)") items.sort((a, b) => getSortValue(b, "rating") - getSortValue(a, "rating"))
//         else if (mode === "Rating (Worst)") items.sort((a, b) => getSortValue(a, "rating") - getSortValue(b, "rating"))
//         return items
//     }

//     function applyFiltersToPopular() {
//         let rawMovies = sortItems(window.rawTrendingMovies.slice())
//         let rawTv = sortItems(window.rawTrendingTv.slice())
//         cachedTrendingMovies.clear(); for (let i = 0; i < rawMovies.length; i++) cachedTrendingMovies.append(rawMovies[i])
//         cachedTrendingTv.clear(); for (let i = 0; i < rawTv.length; i++) cachedTrendingTv.append(rawTv[i])
//         movieGrid.positionViewAtBeginning()
//         tvGrid.positionViewAtBeginning()
//     }

//     function applyFiltersAndPopulate() {
//         window.isKeyboardNav = false
//         searchResults.clear()
//         let items = sortItems(window.currentFetchResults.slice())
//         for (let i = 0; i < items.length; i++) {
//             let item = items[i]
//             if (!item.id) continue
//             searchResults.append({
//                 imdbId: item.id, title: item.name || "Unknown", poster: item.poster || "",
//                 type: item.type === "series" ? "tv" : "movie", year: item.releaseInfo || "N/A", rating: item.imdbRating || 0
//             })
//         }
//         Qt.callLater(function() {
//             if (searchGrid && searchGrid.count > 0) searchGrid.currentIndex = 0
//             if (movieGrid && movieGrid.count > 0) movieGrid.currentIndex = 0
//             if (tvGrid && tvGrid.count > 0) tvGrid.currentIndex = 0
//         })
//     }

//     function doSearch(query) {
//         let q = encodeURIComponent(query.trim())
//         let expectedType = window.mediaType
//         let typeStr = expectedType === "movie" ? "movie" : "series"
//         if (q === "") { searchResults.clear(); window.isSearchingNetwork = false; return }
//         addSearchHistory(query)
//         window.isSearchingNetwork = true
//         searchResults.clear()
//         var xhr = new XMLHttpRequest()
//         xhr.open("GET", "https://v3-cinemeta.strem.io/catalog/" + typeStr + "/top/search=" + q + ".json")
//         xhr.onerror = function() { window.isSearchingNetwork = false }
//         xhr.onreadystatechange = function() {
//             if (xhr.readyState !== XMLHttpRequest.DONE) return
//             if (window.mediaType === expectedType) {
//                 window.isSearchingNetwork = false
//                 if (xhr.status === 200) {
//                     try {
//                         let res = JSON.parse(xhr.responseText)
//                         if (res && res.metas) {
//                             window.currentFetchResults = res.metas
//                             applyFiltersAndPopulate()
//                             enrichSearchPosters(res.metas, typeStr)
//                         }
//                     } catch(e) {}
//                 }
//             }
//         }
//         xhr.send()
//     }

//     function enrichSearchPosters(metas, typeStr) {
//         for (let i = 0; i < metas.length; i++) {
//             let item = metas[i]
//             if (item.poster && item.poster !== "") continue
//             let capturedImdbId = item.id
//             ;(function(cImdbId) {
//                 var xhr2 = new XMLHttpRequest()
//                 xhr2.open("GET", "https://v3-cinemeta.strem.io/meta/" + typeStr + "/" + cImdbId + ".json")
//                 xhr2.onreadystatechange = function() {
//                     if (xhr2.readyState !== XMLHttpRequest.DONE) return
//                     if (xhr2.status === 200) {
//                         try {
//                             let res2 = JSON.parse(xhr2.responseText)
//                             if (res2 && res2.meta) {
//                                 let poster = res2.meta.poster || res2.meta.background || ""
//                                 if (poster !== "") {
//                                     for (let j = 0; j < searchResults.count; j++) {
//                                         if (searchResults.get(j).imdbId === cImdbId) {
//                                             searchResults.setProperty(j, "poster", poster)
//                                             break
//                                         }
//                                     }
//                                     return
//                                 }
//                             }
//                         } catch(e) {}
//                     }
//                     fetchPosterFallback(cImdbId, typeStr)
//                 }
//                 xhr2.send()
//             })(capturedImdbId)
//         }
//     }

//     function fetchPosterFallback(imdbId, typeStr) {
//         let rpdbUrl = "https://api.ratingposterdb.com/imdb/poster-default/" + imdbId + ".jpg"
//         var xhrCheck = new XMLHttpRequest()
//         xhrCheck.open("HEAD", rpdbUrl, true)
//         xhrCheck.timeout = 5000
//         xhrCheck.onreadystatechange = function() {
//             if (xhrCheck.readyState !== XMLHttpRequest.DONE) return
//             if (xhrCheck.status === 200) {
//                 for (let j = 0; j < searchResults.count; j++) {
//                     if (searchResults.get(j).imdbId === imdbId) {
//                         searchResults.setProperty(j, "poster", rpdbUrl)
//                         break
//                     }
//                 }
//             }
//         }
//         xhrCheck.onerror = function() { /* silently fail — delegate shows title fallback */ }
//         xhrCheck.send()
//     }

//     function fetchAndUpdatePoster(imdbId, typeStr, targetModel) {
//         var xhr = new XMLHttpRequest()
//         let metaType = typeStr === "tv" ? "series" : "movie"
//         xhr.open("GET", "https://v3-cinemeta.strem.io/meta/" + metaType + "/" + imdbId + ".json")
//         xhr.timeout = 6000
//         xhr.onreadystatechange = function() {
//             if (xhr.readyState !== XMLHttpRequest.DONE) return
//             let posterFound = ""
//             if (xhr.status === 200) {
//                 try {
//                     let res = JSON.parse(xhr.responseText)
//                     if (res && res.meta) posterFound = res.meta.poster || res.meta.background || ""
//                 } catch(e) {}
//             }
//             if (posterFound !== "") {
//                 for (let j = 0; j < targetModel.count; j++) {
//                     if (targetModel.get(j).imdbId === imdbId) {
//                         targetModel.setProperty(j, "poster", posterFound)
//                         break
//                     }
//                 }
//             } else {
//                 fetchPosterFallback(imdbId, metaType)
//             }
//         }
//         xhr.onerror = function() { fetchPosterFallback(imdbId, metaType) }
//         xhr.send()
//     }

//     function fetchSeriesData(imdbId, targetSeason, title, poster, isReload) {
//         if (!isReload) {
//             window.selectedImdbId = imdbId
//             window.selectedTitle = title
//             window.selectedPoster = poster
//             window.selectedDescription = ""
//             window.currentView = "series"
//             window.forceActiveFocus()
//         }
//         window.isLoadingSeries = true
//         seasonModel.clear()
//         episodeModel.clear()

//         var xhr = new XMLHttpRequest()
//         xhr.open("GET", "https://v3-cinemeta.strem.io/meta/series/" + imdbId + ".json")
//         xhr.onerror = function() { 
//             window.isLoadingSeries = false
//             if (isReload && window.pendingSeriesFocusRestore) seriesFocusRestoreTimer.restart()
//         }
//         xhr.onreadystatechange = function() {
//             if (xhr.readyState !== XMLHttpRequest.DONE) return
//             window.isLoadingSeries = false
//             if (xhr.status === 200) {
//                 try {
//                     var res = JSON.parse(xhr.responseText)
//                     if (res && res.meta) {
//                         if (!isReload || !window.selectedDescription) window.selectedDescription = res.meta.description || res.meta.synopsis || ""
//                         if ((!window.selectedPoster || window.selectedPoster === "") && res.meta.poster) window.selectedPoster = res.meta.poster
                        
//                         if (res.meta.videos) {
//                             let seasonsMap = {}
//                             for (let i = 0; i < res.meta.videos.length; i++) {
//                                 let v = res.meta.videos[i]
//                                 if (v.season === 0) continue
//                                 if (!seasonsMap[v.season]) seasonsMap[v.season] = []
//                                 let epTitle = v.name || v.title || null
//                                 if (epTitle && /^(episode\s*\d+|s\d+e\d+|ep\.?\s*\d+)$/i.test(epTitle.toLowerCase().trim())) epTitle = null
//                                 seasonsMap[v.season].push({
//                                     ep: v.episode,
//                                     title: epTitle || ("Episode " + v.episode),
//                                     hasRealTitle: epTitle !== null
//                                 })
//                             }
//                             let seasonKeys = Object.keys(seasonsMap).map(Number).sort((a, b) => a - b)
//                             for (let i = 0; i < seasonKeys.length; i++) seasonModel.append({ seasonNum: seasonKeys[i] })
//                             window.seriesDataMap = seasonsMap
                            
//                             let newTargetSeason = (isReload && seasonsMap[targetSeason]) ? targetSeason : (seasonKeys[0] || 1)
//                             window.currentSeason = newTargetSeason
//                             updateEpisodes(newTargetSeason)
//                         }
//                     }
//                 } catch(e) {}
//             }
//             if (isReload && window.pendingSeriesFocusRestore) seriesFocusRestoreTimer.restart()
//             if (!isReload) saveUiState()
//         }
//         xhr.send()
//     }

//     function loadSeriesDetails(imdbId, title, poster) {
//         fetchSeriesData(imdbId, 1, title, poster, false)
//     }

//     function updateEpisodes(seasonNum) {
//         window.seasonSwitching = true
//         seasonContentSwapTimer.targetSeason = seasonNum
//         seasonContentSwapTimer.restart()
//     }

//     Timer {
//         id: seasonContentSwapTimer
//         property int targetSeason: 1
//         interval: 220
//         repeat: false
//         onTriggered: {
//             episodeModel.clear()
//             let eps = window.seriesDataMap[targetSeason]
//             if (eps) {
//                 eps.sort((a, b) => a.ep - b.ep)
//                 for (let i = 0; i < eps.length; i++) {
//                     episodeModel.append({ epNum: eps[i].ep, epTitle: eps[i].title, hasRealTitle: eps[i].hasRealTitle || false })
//                 }
//             }
//             epList.currentIndex = 0
//             epList.positionViewAtBeginning()
//             seasonFadeInTimer.restart()
//         }
//     }

//     Timer { id: seasonFadeInTimer; interval: 30; repeat: false; onTriggered: window.seasonSwitching = false }

//     function getActiveGrid() {
//         if (window.isSearchMode) return searchGrid
//         if (window.mediaType === "movie") return movieGrid
//         return tvGrid
//     }

//     // --- SHARED STYLES ---
//     component CustomComboBox: ComboBox {
//         id: control
//         font.family: "JetBrains Mono"; font.pixelSize: window.s(14)
//         delegate: ItemDelegate {
//             width: control.width; height: window.s(36)
//             contentItem: Text { text: modelData || model.name; color: window.text; font: control.font; verticalAlignment: Text.AlignVCenter }
//             background: Rectangle { color: control.highlightedIndex === index ? window.surface1 : "transparent"; radius: window.s(10) }
//         }
//         indicator: Canvas {
//             id: canvas
//             x: control.width - width - control.rightPadding; y: control.topPadding + (control.availableHeight - height) / 2
//             width: 12; height: 8; contextType: "2d"
//             Connections { target: control; function onPressedChanged() { canvas.requestPaint() } }
//             onPaint: { var ctx = canvas.getContext("2d"); ctx.reset(); ctx.moveTo(0, 0); ctx.lineTo(width, 0); ctx.lineTo(width / 2, height); ctx.fillStyle = window.subtext0; ctx.fill() }
//         }
//         contentItem: Text { leftPadding: window.s(10); rightPadding: control.indicator.width + control.spacing; text: control.currentText; font: control.font; color: window.text; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
//         background: Rectangle { implicitWidth: window.s(180); implicitHeight: window.s(36); color: window.surface0; border.color: control.activeFocus ? window.surface2 : window.surface1; border.width: control.visualFocus ? 2 : 1; radius: window.s(10) }
//         popup: Popup {
//             y: control.height + window.s(4); width: control.width; implicitHeight: contentItem.implicitHeight; padding: window.s(4)
//             contentItem: ListView { clip: true; implicitHeight: contentHeight; model: control.popup.visible ? control.delegateModel : null; currentIndex: control.highlightedIndex; ScrollIndicator.vertical: ScrollIndicator { } }
//             background: Rectangle { color: window.crust; border.color: window.surface1; radius: window.s(14) }
//         }
//     }

//     component PosterDelegate: Rectangle {
//         width: window.s(120); height: width * 1.5
//         radius: window.s(10); color: window.crust; clip: true
//         property bool isHovered: posterMouse.containsMouse
//         Image {
//             id: posterImg
//             anchors.fill: parent
//             source: model.poster !== "" ? model.poster : ""
//             fillMode: Image.PreserveAspectCrop
//             asynchronous: true
//             smooth: true
//             cache: true
//             sourceSize.width: window.s(240)
//             sourceSize.height: window.s(360)
//             visible: status === Image.Ready
//         }
//         Rectangle {
//             anchors.fill: parent
//             color: window.surface0
//             visible: model.poster === "" || posterImg.status === Image.Error || posterImg.status === Image.Null
//             radius: window.s(10)
//             Column {
//                 anchors.centerIn: parent
//                 width: parent.width - window.s(10)
//                 spacing: window.s(6)
//                 Text {
//                     anchors.horizontalCenter: parent.horizontalCenter
//                     text: model.type === "tv" ? "📺" : "🎬"
//                     font.pixelSize: window.s(22)
//                 }
//                 Text {
//                     width: parent.width
//                     text: model.title || "Unknown"
//                     color: window.subtext0
//                     font.family: "JetBrains Mono"
//                     font.pixelSize: window.s(11)
//                     wrapMode: Text.WordWrap
//                     horizontalAlignment: Text.AlignHCenter
//                     maximumLineCount: 4
//                     elide: Text.ElideRight
//                 }
//             }
//         }
//         Rectangle {
//             anchors.fill: parent; radius: window.s(10)
//             color: window.mediaType === "tv" ? window.blue : window.mauve
//             opacity: parent.isHovered ? 0.3 : 0
//             Behavior on opacity { NumberAnimation { duration: 200 } }
//         }
//         MouseArea {
//             id: posterMouse; anchors.fill: parent; hoverEnabled: true
//             onClicked: {
//                 if (model.type === "movie") startSourceCheck("movie", model.imdbId, model.title, model.poster, 0, 0)
//                 else loadSeriesDetails(model.imdbId, model.title, model.poster)
//             }
//         }
//     }

//     Component {
//         id: dashboardHeaderComp
//         Item {
//             width: GridView.view.width
//             property bool hasSearch: searchHistoryModel.count > 0
//             property bool hasWatch: watchHistoryModel.count > 0
//             readonly property real searchSectionH: hasSearch ? (window.s(16) + window.s(12) + window.s(32) + window.s(28)) : 0
//             readonly property real watchSectionH: hasWatch ? (window.s(16) + window.s(12) + window.s(200) + window.s(28)) : 0
//             readonly property real popularLabelH: window.s(16) + window.s(16)
//             height: searchSectionH + watchSectionH + popularLabelH
//             Column {
//                 width: parent.width
//                 spacing: 0
//                 Item {
//                     width: parent.width
//                     height: parent.parent.searchSectionH
//                     visible: parent.parent.hasSearch
//                     Column {
//                         width: parent.width
//                         spacing: window.s(12)
//                         Text {
//                             text: "Recent Searches"
//                             color: window.text
//                             font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(16)
//                         }
//                         ListView {
//                             width: parent.width; height: window.s(32)
//                             orientation: ListView.Horizontal; spacing: window.s(8)
//                             model: searchHistoryModel; clip: true; interactive: false
//                             add: Transition {
//                                 ParallelAnimation {
//                                     NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400 }
//                                     NumberAnimation { property: "x"; from: -window.s(20); duration: 400; easing.type: Easing.OutQuart }
//                                 }
//                             }
//                             remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 200 } }
//                             displaced: Transition { NumberAnimation { property: "x"; duration: 300; easing.type: Easing.OutQuart } }
//                             delegate: Rectangle {
//                                 width: queryText.width + window.s(35); height: window.s(32)
//                                 radius: window.s(8); color: window.surface0
//                                 border.color: histMouse.containsMouse ? window.surface2 : window.surface1
//                                 Text {
//                                     id: queryText; text: model.query; color: window.text
//                                     font.family: "JetBrains Mono"; font.pixelSize: window.s(13)
//                                     anchors.left: parent.left; anchors.leftMargin: window.s(10)
//                                     anchors.verticalCenter: parent.verticalCenter
//                                 }
//                                 MouseArea {
//                                     id: histMouse; anchors.fill: parent; hoverEnabled: true
//                                     onClicked: { searchInput.text = model.query; doSearch(model.query) }
//                                 }
//                                 Rectangle {
//                                     width: window.s(20); height: window.s(20); radius: window.s(10)
//                                     color: closeMouse.containsMouse ? window.surface1 : "transparent"
//                                     anchors.right: parent.right; anchors.rightMargin: window.s(5)
//                                     anchors.verticalCenter: parent.verticalCenter
//                                     Text { text: "×"; anchors.centerIn: parent; color: window.subtext0; font.pixelSize: window.s(14) }
//                                     MouseArea {
//                                         id: closeMouse; anchors.fill: parent; hoverEnabled: true
//                                         onClicked: { searchHistoryModel.remove(index); window.saveHistory() }
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }
//                 Item {
//                     width: parent.width
//                     height: parent.parent.watchSectionH
//                     visible: parent.parent.hasWatch
//                     Column {
//                         width: parent.width
//                         spacing: window.s(12)
//                         Text {
//                             text: "Watch History"
//                             color: window.text
//                             font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(16)
//                         }
//                         ListView {
//                             width: parent.width; height: window.s(200)
//                             orientation: ListView.Horizontal; spacing: window.s(15)
//                             model: watchHistoryModel; clip: true
//                             delegate: PosterDelegate {}
//                             ScrollBar.horizontal: ScrollBar {
//                                 active: true
//                                 contentItem: Rectangle { radius: window.s(2); color: window.surface2 }
//                             }
//                         }
//                     }
//                 }
//                 Item {
//                     width: parent.width
//                     height: parent.parent.popularLabelH
//                     Text {
//                         anchors.top: parent.top; anchors.topMargin: window.s(4)
//                         text: window.mediaType === "movie" ? "Popular Movies" : "Popular TV Shows"
//                         color: window.text
//                         font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(16)
//                     }
//                 }
//             }
//         }
//     }

//     // --- UI LAYOUT ---
//     Rectangle {
//         id: mainBg
//         width: parent.width; height: parent.height
//         anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
//         radius: window.s(14)
//         color: Qt.rgba(window.base.r, window.base.g, window.base.b, 0.95)
//         border.color: Qt.rgba(window.text.r, window.text.g, window.text.b, 0.08)
//         border.width: 1
//         clip: true
//         transform: Translate { y: (1 - window.introPhase) * window.s(50) }
//         opacity: window.introPhase
//         ColumnLayout {
//             anchors.fill: parent
//             spacing: 0
//             visible: window.currentView === "search"
//             Rectangle {
//                 Layout.alignment: Qt.AlignTop; Layout.fillWidth: true; Layout.preferredHeight: window.s(120); color: "transparent"
//                 ColumnLayout {
//                     anchors.fill: parent; anchors.margins: window.s(15); spacing: window.s(10)
//                     RowLayout {
//                         Layout.fillWidth: true; spacing: window.s(15)
//                         Rectangle {
//                             Layout.preferredWidth: window.s(200); Layout.preferredHeight: window.s(36); radius: window.s(10); color: window.surface0
//                             Rectangle {
//                                 id: tabHighlight
//                                 width: parent.width / 2 - window.s(4); height: parent.height - window.s(8)
//                                 y: window.s(4); radius: window.s(8); color: window.mediaType === "movie" ? window.mauve : window.blue; z: 0
//                                 property real targetX: window.mediaType === "movie" ? window.s(4) : (parent.width / 2)
//                                 property real actualX: targetX
//                                 Behavior on actualX { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
//                                 x: actualX
//                             }
//                             RowLayout {
//                                 anchors.fill: parent; spacing: 0
//                                 MouseArea {
//                                     Layout.fillWidth: true; Layout.fillHeight: true
//                                     onClicked: { window.mediaType = "movie"; if (searchInput.text !== "") doSearch(searchInput.text) }
//                                     Text { anchors.centerIn: parent; text: "Movies"; font.family: "JetBrains Mono"; font.weight: window.mediaType === "movie" ? Font.Bold : Font.Medium; font.pixelSize: window.s(13); color: window.mediaType === "movie" ? window.crust : window.text }
//                                 }
//                                 MouseArea {
//                                     Layout.fillWidth: true; Layout.fillHeight: true
//                                     onClicked: { window.mediaType = "tv"; if (searchInput.text !== "") doSearch(searchInput.text) }
//                                     Text { anchors.centerIn: parent; text: "TV Shows"; font.family: "JetBrains Mono"; font.weight: window.mediaType === "tv" ? Font.Bold : Font.Medium; font.pixelSize: window.s(13); color: window.mediaType === "tv" ? window.crust : window.text }
//                                 }
//                             }
//                         }
//                         Item { Layout.fillWidth: true }
//                         CustomComboBox {
//                             id: filterSelector
//                             Layout.preferredWidth: window.s(180)
//                             model: ["Default", "Year (Newest)", "Year (Oldest)", "Title (A-Z)", "Title (Z-A)", "Rating (Best)", "Rating (Worst)"]
//                             onActivated: {
//                                 window.filterSort = currentText
//                                 applyFiltersAndPopulate()
//                                 applyFiltersToPopular()
//                             }
//                         }
//                     }
//                     TextField {
//                         id: searchInput
//                         Layout.fillWidth: true; Layout.preferredHeight: window.s(42)
//                         background: Rectangle {
//                             color: searchInput.activeFocus ? Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.6) : window.surface0
//                             radius: window.s(10); border.color: searchInput.activeFocus ? window.surface2 : "transparent"
//                             Behavior on color { ColorAnimation { duration: 200 } }
//                         }
//                         color: window.text; font.family: "JetBrains Mono"; font.pixelSize: window.s(15); leftPadding: window.s(15)
//                         placeholderText: "Search"
//                         placeholderTextColor: window.subtext0; verticalAlignment: TextInput.AlignVCenter
//                         onTextChanged: {
//                             if (text.trim() === "") { searchResults.clear(); window.isSearchingNetwork = false; searchDebounceTimer.stop() }
//                             else searchDebounceTimer.restart()
//                         }
//                         Keys.onRightPressed: {
//                             window.isKeyboardNav = true; keyboardNavTimer.restart()
//                             let g = getActiveGrid()
//                             if (g && g.count > 0 && g.currentIndex < g.count - 1) g.currentIndex++
//                             event.accepted = true
//                         }
//                         Keys.onLeftPressed: {
//                             window.isKeyboardNav = true; keyboardNavTimer.restart()
//                             let g = getActiveGrid()
//                             if (g && g.count > 0 && g.currentIndex > 0) g.currentIndex--
//                             event.accepted = true
//                         }
//                         Keys.onDownPressed: {
//                             window.isKeyboardNav = true; keyboardNavTimer.restart()
//                             let g = getActiveGrid()
//                             if (g && g.count > 0) {
//                                 let columns = Math.max(1, Math.floor(g.width / g.cellWidth))
//                                 if (g.currentIndex + columns < g.count) g.currentIndex += columns
//                             }
//                             event.accepted = true
//                         }
//                         Keys.onUpPressed: {
//                             window.isKeyboardNav = true; keyboardNavTimer.restart()
//                             let g = getActiveGrid()
//                             if (g && g.count > 0) {
//                                 let columns = Math.max(1, Math.floor(g.width / g.cellWidth))
//                                 if (g.currentIndex - columns >= 0) g.currentIndex -= columns
//                             }
//                             event.accepted = true
//                         }
//                         Keys.onTabPressed: { window.mediaType = window.mediaType === "movie" ? "tv" : "movie"; if (text.trim() !== "") doSearch(text); event.accepted = true }
//                         Keys.onBacktabPressed: { window.mediaType = window.mediaType === "movie" ? "tv" : "movie"; if (text.trim() !== "") doSearch(text); event.accepted = true }
//                         Keys.onReturnPressed: {
//                             if (text.trim() !== "" && searchResults.count === 0 && !window.isSearchingNetwork) {
//                                 doSearch(text)
//                             } else if (window.isKeyboardNav) {
//                                 let g = getActiveGrid()
//                                 if (g && g.count > 0 && g.currentIndex >= 0 && g.currentIndex < g.count) {
//                                     let item = g.model.get(g.currentIndex)
//                                     if (item) {
//                                         if (item.type === "movie") startSourceCheck("movie", item.imdbId, item.title, item.poster, 0, 0)
//                                         else loadSeriesDetails(item.imdbId, item.title, item.poster)
//                                     }
//                                 }
//                             }
//                             event.accepted = true
//                         }
//                     }
//                 }
//             }
//             Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5) }
//             Item {
//                 Layout.fillWidth: true; Layout.fillHeight: true
//                 Rectangle {
//                     anchors.fill: parent
//                     color: Qt.rgba(window.base.r, window.base.g, window.base.b, 0.8)
//                     visible: window.isSearchingNetwork || (!window.isSearchMode && window.isLoadingPopular)
//                     z: 10
//                     ColumnLayout {
//                         anchors.centerIn: parent; spacing: window.s(15)
//                         Item {
//                             Layout.alignment: Qt.AlignHCenter
//                             width: window.s(34); height: window.s(34)
//                             property real spinAngle: 0
//                             NumberAnimation on spinAngle {
//                                 from: 0; to: 360; duration: 900
//                                 loops: Animation.Infinite; running: true
//                                 easing.type: Easing.Linear
//                             }
//                             Canvas {
//                                 anchors.fill: parent
//                                 property real angle: parent.spinAngle
//                                 onAngleChanged: requestPaint()
//                                 onPaint: {
//                                     var ctx = getContext("2d")
//                                     ctx.reset()
//                                     var cx = width / 2, cy = height / 2, r = width / 2 - 3
//                                     var startRad = (parent.spinAngle - 90) * Math.PI / 180
//                                     var endRad = startRad + 1.7 * Math.PI
//                                     ctx.beginPath()
//                                     ctx.arc(cx, cy, r, startRad, endRad)
//                                     ctx.strokeStyle = window.mauve
//                                     ctx.lineWidth = 3
//                                     ctx.lineCap = "round"
//                                     ctx.stroke()
//                                 }
//                             }
//                         }
//                         Text { Layout.alignment: Qt.AlignHCenter; text: "Loading..."; color: window.text; font.family: "JetBrains Mono"; font.pixelSize: window.s(14) }
//                     }
//                 }
//                 Item {
//                     anchors.fill: parent; anchors.margins: window.s(15); visible: !window.isSearchingNetwork
//                     Component {
//                         id: gridHighlightComp
//                         Item {
//                             z: 0
//                             Rectangle {
//                                 color: window.surface0; border.color: window.surface1; border.width: 1; radius: window.s(10)
//                                 property real actX: parent.GridView.view.currentItem ? parent.GridView.view.currentItem.x + window.s(5) : 0
//                                 property real actY: parent.GridView.view.currentItem ? parent.GridView.view.currentItem.y + window.s(5) : 0
//                                 x: actX; y: actY; width: parent.GridView.view.cellWidth - window.s(10); height: parent.GridView.view.cellHeight - window.s(10)
//                                 Behavior on actX { enabled: window.isKeyboardNav; NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
//                                 Behavior on actY { enabled: window.isKeyboardNav; NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
//                                 opacity: parent.GridView.view.count > 0 && parent.GridView.view.currentIndex >= 0 ? 1 : 0
//                                 Behavior on opacity { NumberAnimation { duration: 300 } }
//                             }
//                         }
//                     }
//                     Component {
//                         id: mediaGridDelegate
//                         Item {
//                             width: GridView.view.cellWidth; height: GridView.view.cellHeight; z: 1
//                             Rectangle {
//                                 anchors.fill: parent; anchors.margins: window.s(5); radius: window.s(10); color: "transparent"
//                                 property bool isActive: index === parent.parent.GridView.view.currentIndex
//                                 ColumnLayout {
//                                     anchors.fill: parent; anchors.margins: window.s(10); spacing: window.s(8)
//                                     Rectangle {
//                                         Layout.fillWidth: true; Layout.fillHeight: true; radius: window.s(8); color: window.crust; clip: true
//                                         scale: parent.parent.isActive && window.isKeyboardNav ? 1.03 : 1.0
//                                         Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
//                                         Image {
//                                             id: gridImage
//                                             anchors.fill: parent
//                                             source: model.poster !== "" ? model.poster : ""
//                                             fillMode: Image.PreserveAspectCrop
//                                             asynchronous: true; smooth: true; cache: true
//                                             visible: status === Image.Ready
//                                         }
//                                         Rectangle {
//                                             anchors.fill: parent; color: window.surface0
//                                             visible: model.poster === "" || gridImage.status === Image.Error || gridImage.status === Image.Loading
//                                             radius: window.s(8)
//                                             property bool isLoading: model.poster !== "" && gridImage.status === Image.Loading
//                                             Rectangle {
//                                                 anchors.fill: parent; radius: window.s(8); color: "transparent"
//                                                 visible: parent.isLoading
//                                                 Rectangle {
//                                                     width: parent.width * 0.4; height: parent.height
//                                                     color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.4)
//                                                     property real shimX: -parent.parent.width
//                                                     x: shimX
//                                                     NumberAnimation on shimX {
//                                                         from: -parent.parent.width
//                                                         to: parent.parent.width * 1.5
//                                                         duration: 1200; loops: Animation.Infinite
//                                                         running: parent.parent.parent.isLoading
//                                                         easing.type: Easing.InOutSine
//                                                     }
//                                                 }
//                                             }
//                                             Text { anchors.centerIn: parent; width: parent.width - window.s(10); text: model.title || "Unknown"; color: window.subtext0; font.family: "JetBrains Mono"; font.pixelSize: window.s(12); wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; visible: !parent.isLoading }
//                                         }
//                                         Rectangle {
//                                             anchors.fill: parent; radius: window.s(8)
//                                             color: window.mediaType === "tv" ? window.blue : window.mauve
//                                             opacity: parent.parent.parent.isActive ? 0.2 : 0
//                                             Behavior on opacity { NumberAnimation { duration: 200 } }
//                                         }
//                                     }
//                                     Text {
//                                         Layout.fillWidth: true; text: model.title; font.family: "JetBrains Mono"; font.pixelSize: window.s(12); font.weight: Font.Bold
//                                         color: parent.parent.isActive ? window.text : window.subtext0
//                                         wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight; lineHeight: 1.1; horizontalAlignment: Text.AlignHCenter
//                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                     }
//                                     Text { Layout.fillWidth: true; text: model.year !== "N/A" ? model.year : ""; font.family: "JetBrains Mono"; font.pixelSize: window.s(11); color: window.surface2; horizontalAlignment: Text.AlignHCenter; visible: text !== "" }
//                                 }
//                                 MouseArea {
//                                     anchors.fill: parent; hoverEnabled: true
//                                     onEntered: { window.isKeyboardNav = false; parent.parent.GridView.view.currentIndex = index }
//                                     onClicked: {
//                                         if (model.type === "movie") startSourceCheck("movie", model.imdbId, model.title, model.poster, 0, 0)
//                                         else loadSeriesDetails(model.imdbId, model.title, model.poster)
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                     GridView {
//                         id: searchGrid
//                         anchors.fill: parent; visible: window.isSearchMode
//                         model: searchResults; cellWidth: Math.floor(width / 5); cellHeight: cellWidth * 1.5 + window.s(60)
//                         boundsBehavior: Flickable.StopAtBounds; highlightFollowsCurrentItem: false; clip: true
//                         ScrollBar.vertical: ScrollBar { active: true; contentItem: Rectangle { radius: window.s(2); color: window.surface2 } }
//                         Behavior on contentY { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
//                         add: Transition { ParallelAnimation { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutQuart } NumberAnimation { property: "y"; from: y + window.s(30); duration: 500; easing.type: Easing.OutQuart } NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: 500; easing.type: Easing.OutBack } } }
//                         highlight: gridHighlightComp; delegate: mediaGridDelegate
//                     }
//                     GridView {
//                         id: movieGrid
//                         anchors.fill: parent; visible: !window.isSearchMode && window.mediaType === "movie"
//                         model: cachedTrendingMovies; cellWidth: Math.floor(width / 10); cellHeight: cellWidth * 1.5 + window.s(60)
//                         header: dashboardHeaderComp; boundsBehavior: Flickable.StopAtBounds; highlightFollowsCurrentItem: false; clip: true
//                         ScrollBar.vertical: ScrollBar { active: true; contentItem: Rectangle { radius: window.s(2); color: window.surface2 } }
//                         Behavior on contentY { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
//                         highlight: gridHighlightComp; delegate: mediaGridDelegate
//                     }
//                     GridView {
//                         id: tvGrid
//                         anchors.fill: parent; visible: !window.isSearchMode && window.mediaType === "tv"
//                         model: cachedTrendingTv; cellWidth: Math.floor(width / 10); cellHeight: cellWidth * 1.5 + window.s(60)
//                         header: dashboardHeaderComp; boundsBehavior: Flickable.StopAtBounds; highlightFollowsCurrentItem: false; clip: true
//                         ScrollBar.vertical: ScrollBar { active: true; contentItem: Rectangle { radius: window.s(2); color: window.surface2 } }
//                         Behavior on contentY { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
//                         highlight: gridHighlightComp; delegate: mediaGridDelegate
//                     }
//                 }
//             }
//         }
//         // ==========================================
//         // SERIES VIEW
//         // ==========================================
//         RowLayout {
//             anchors.fill: parent; anchors.margins: window.s(20); spacing: window.s(25)
//             visible: window.currentView === "series"
//             ColumnLayout {
//                 Layout.preferredWidth: window.s(220); Layout.minimumWidth: window.s(220); Layout.maximumWidth: window.s(220)
//                 Layout.fillHeight: true; spacing: window.s(12)
//                 Rectangle {
//                     Layout.fillWidth: true; Layout.preferredHeight: window.s(300); radius: window.s(14); color: window.crust; clip: true
//                     Image {
//                         anchors.fill: parent
//                         source: window.selectedPoster !== "" ? window.selectedPoster : ""
//                         fillMode: Image.PreserveAspectCrop
//                         asynchronous: true; smooth: true; cache: true
//                         sourceSize.width: window.s(440); sourceSize.height: window.s(600)
//                         visible: status === Image.Ready
//                     }
//                     Rectangle {
//                         anchors.fill: parent; color: window.surface0; radius: window.s(14)
//                         visible: window.selectedPoster === "" || parent.children[0].status === Image.Error || parent.children[0].status === Image.Loading
//                         Text { anchors.centerIn: parent; width: parent.width - window.s(10); text: window.selectedTitle; color: window.subtext0; font.family: "JetBrains Mono"; font.pixelSize: window.s(14); wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter }
//                     }
//                 }
//                 Text {
//                     Layout.fillWidth: true; text: window.selectedTitle
//                     font.family: "JetBrains Mono"; font.pixelSize: window.s(16); font.weight: Font.Bold
//                     color: window.text; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
//                     maximumLineCount: 3; elide: Text.ElideRight
//                 }
//                 Flickable {
//                     Layout.fillWidth: true
//                     Layout.preferredHeight: Math.min(window.s(120), descText.implicitHeight + window.s(8))
//                     Layout.maximumHeight: window.s(120)
//                     visible: window.selectedDescription !== ""
//                     clip: true; contentHeight: descText.implicitHeight
//                     ScrollBar.vertical: ScrollBar { contentItem: Rectangle { radius: window.s(2); color: window.surface2; implicitWidth: window.s(3) } }
//                     Text {
//                         id: descText
//                         width: parent.width - window.s(8)
//                         text: window.selectedDescription
//                         font.family: "JetBrains Mono"; font.pixelSize: window.s(11)
//                         color: window.subtext0; wrapMode: Text.WordWrap; lineHeight: 1.4
//                         Behavior on opacity { NumberAnimation { duration: 400 } }
//                         opacity: window.selectedDescription !== "" ? 1 : 0
//                     }
//                 }
//                 Rectangle {
//                     Layout.fillWidth: true; Layout.preferredHeight: window.s(45); radius: window.s(10)
//                     property bool isHovered: backMouse.containsMouse
//                     color: isHovered ? window.surface2 : window.surface1
//                     Behavior on color { ColorAnimation { duration: 200 } }
//                     Text { anchors.centerIn: parent; text: "← Back"; font.family: "JetBrains Mono"; font.pixelSize: window.s(14); font.weight: Font.Medium; color: window.text }
//                     MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { window.currentView = "search"; searchInput.forceActiveFocus(); saveUiState() } }
//                 }
//                 Item { Layout.fillHeight: true }
//             }
//             ColumnLayout {
//                 Layout.fillWidth: true; Layout.fillHeight: true; spacing: window.s(12)
//                 Item {
//                     Layout.fillWidth: true; Layout.preferredHeight: window.s(44)
//                     ListView {
//                         id: seasonList
//                         anchors.fill: parent
//                         orientation: ListView.Horizontal; model: seasonModel; spacing: window.s(8); clip: true
//                         Behavior on contentX { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
//                         delegate: Rectangle {
//                             width: seasonLabelText.width + window.s(28); height: window.s(38); radius: window.s(10)
//                             property bool isActive: window.currentSeason === model.seasonNum
//                             color: isActive ? (window.mediaType === "tv" ? window.blue : window.mauve) : window.surface0
//                             border.color: isActive ? color : window.surface1; border.width: 1
//                             Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutQuart } }
//                             Behavior on border.color { ColorAnimation { duration: 280; easing.type: Easing.OutQuart } }
//                             scale: isActive ? 1.04 : 1.0
//                             Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
//                             Text {
//                                 id: seasonLabelText
//                                 anchors.centerIn: parent
//                                 text: "S" + model.seasonNum
//                                 font.family: "JetBrains Mono"; font.pixelSize: window.s(13); font.weight: isActive ? Font.Bold : Font.Medium
//                                 color: isActive ? window.crust : window.text
//                                 Behavior on color { ColorAnimation { duration: 200 } }
//                             }
//                             MouseArea {
//                                 anchors.fill: parent
//                                 onClicked: {
//                                     if (window.currentSeason !== model.seasonNum) {
//                                         window.currentSeason = model.seasonNum
//                                         updateEpisodes(model.seasonNum)
//                                         saveUiState()
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }
//                 Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5) }
//                 Item {
//                     Layout.fillWidth: true; Layout.fillHeight: true
//                     ListView {
//                         id: epList
//                         anchors.fill: parent
//                         model: episodeModel; spacing: window.s(6); clip: true
//                         opacity: window.seasonSwitching ? 0 : 1
//                         Behavior on opacity {
//                             NumberAnimation {
//                                 duration: window.seasonSwitching ? 180 : 250
//                                 easing.type: window.seasonSwitching ? Easing.InQuad : Easing.OutQuad
//                             }
//                         }
//                         transform: Translate {
//                             y: window.seasonSwitching ? window.s(8) : 0
//                             Behavior on y {
//                                 NumberAnimation {
//                                     duration: window.seasonSwitching ? 180 : 280
//                                     easing.type: window.seasonSwitching ? Easing.InQuad : Easing.OutQuart
//                                 }
//                             }
//                         }
//                         ScrollBar.vertical: ScrollBar { active: true; contentItem: Rectangle { radius: window.s(2); color: window.surface2; implicitWidth: window.s(4) } }
//                         Text {
//                             anchors.centerIn: parent
//                             visible: window.isLoadingSeries
//                             text: "Fetching episodes..."
//                             color: window.subtext0; font.family: "JetBrains Mono"; font.pixelSize: window.s(13)
//                         }
//                         highlight: Rectangle {
//                             color: window.surface0; border.color: window.surface2; border.width: 1; radius: window.s(10); z: 0
//                             Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
//                         }
//                         highlightFollowsCurrentItem: true
//                         highlightMoveVelocity: -1
//                         delegate: Item {
//                             width: ListView.view.width; height: window.s(58); z: 1
//                             property bool isCurrent: ListView.isCurrentItem
//                             Rectangle {
//                                 anchors.fill: parent; radius: window.s(10)
//                                 color: epMouse.containsMouse || isCurrent ? window.surface0 : "transparent"
//                                 border.color: epMouse.containsMouse || isCurrent ? window.surface2 : "transparent"; border.width: 1
//                                 Behavior on color { ColorAnimation { duration: 150 } }
//                                 Behavior on border.color { ColorAnimation { duration: 150 } }
//                                 RowLayout {
//                                     anchors.fill: parent; anchors.margins: window.s(10); spacing: window.s(12)
//                                     Rectangle {
//                                         Layout.preferredWidth: window.s(36); Layout.preferredHeight: window.s(36)
//                                         radius: window.s(8)
//                                         color: isCurrent || epMouse.containsMouse ? window.blue : window.surface1
//                                         Behavior on color { ColorAnimation { duration: 200 } }
//                                         Text {
//                                             anchors.centerIn: parent
//                                             text: model.epNum
//                                             font.family: "JetBrains Mono"; font.pixelSize: window.s(13); font.weight: Font.Bold
//                                             color: isCurrent || epMouse.containsMouse ? window.crust : window.subtext0
//                                             Behavior on color { ColorAnimation { duration: 200 } }
//                                         }
//                                     }
//                                     Column {
//                                         Layout.fillWidth: true; spacing: window.s(2)
//                                         Text {
//                                             width: parent.width
//                                             text: model.epTitle
//                                             font.family: "JetBrains Mono"
//                                             font.pixelSize: model.hasRealTitle ? window.s(13) : window.s(12)
//                                             font.weight: model.hasRealTitle ? Font.Medium : Font.Normal
//                                             color: model.hasRealTitle ? window.text : window.subtext0
//                                             elide: Text.ElideRight
//                                         }
//                                     }
//                                 }
//                                 MouseArea {
//                                     id: epMouse; anchors.fill: parent; hoverEnabled: true
//                                     onClicked: {
//                                         epList.currentIndex = index
//                                         startSourceCheck("tv", window.selectedImdbId, window.selectedTitle, window.selectedPoster, window.currentSeason, model.epNum)
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }
//     // ==========================================
//     // SOURCE CHECKER MODAL OVERLAY
//     // ==========================================
//     Rectangle {
//         id: sourceModalOverlay
//         anchors.fill: parent
//         color: Qt.rgba(0, 0, 0, 0.7)
//         opacity: window.isSourceModalOpen ? 1 : 0
//         visible: opacity > 0
//         Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
//         z: 100
//         MouseArea {
//             anchors.fill: parent
//             onClicked: window.closeSourceModal()
//         }
//         Rectangle {
//             width: window.s(480); height: window.s(600)
//             anchors.centerIn: parent
//             radius: window.s(14)
//             color: window.base
//             border.color: window.surface2
//             border.width: 1
//             clip: true
//             scale: window.isSourceModalOpen ? 1.0 : 0.92
//             Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }
//             MouseArea { anchors.fill: parent }
//             ColumnLayout {
//                 anchors.fill: parent; spacing: 0
//                 // Header
//                 Rectangle {
//                     Layout.fillWidth: true; Layout.preferredHeight: window.s(75); color: window.surface0
//                     Rectangle { width: parent.width; height: 1; color: window.surface1; anchors.bottom: parent.bottom }
//                     RowLayout {
//                         anchors.fill: parent; anchors.margins: window.s(16)
//                         ColumnLayout {
//                             Layout.fillWidth: true; spacing: window.s(4)
//                             Text {
//                                 text: window.checkingState === "checking" ? "Finding Stream..."
//                                     : window.checkingState === "found"    ? "Stream Ready!"
//                                     :                                       "No Streams Found"
//                                 color: window.checkingState === "found"      ? window.green
//                                      : window.checkingState === "failed_all" ? window.red
//                                      :                                         window.text
//                                 font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(17)
//                                 Behavior on color { ColorAnimation { duration: 300 } }
//                             }
//                             Text {
//                                 text: window.pendingMedia.title || "Loading..."
//                                 color: window.subtext0; font.family: "JetBrains Mono"; font.pixelSize: window.s(12)
//                                 elide: Text.ElideRight; Layout.fillWidth: true
//                             }
//                         }
//                         Rectangle {
//                             Layout.preferredWidth: window.s(32); Layout.preferredHeight: window.s(32); radius: window.s(8)
//                             color: modalCloseMouse.containsMouse ? window.surface2 : "transparent"
//                             Behavior on color { ColorAnimation { duration: 150 } }
//                             Text { anchors.centerIn: parent; text: "×"; color: window.subtext0; font.pixelSize: window.s(20) }
//                             MouseArea { id: modalCloseMouse; anchors.fill: parent; hoverEnabled: true; onClicked: window.closeSourceModal() }
//                         }
//                     }
//                 }
//                 // Body
//                 Item {
//                     Layout.fillWidth: true; Layout.fillHeight: true
//                     ListView {
//                         id: sourceListUI
//                         anchors.fill: parent; anchors.margins: window.s(14)
//                         model: sourceModel; spacing: window.s(8); clip: true
//                         visible: window.checkingState !== "failed_all"
//                         delegate: Rectangle {
//                             width: ListView.view.width; height: window.s(52); radius: window.s(10)
//                             color: {
//                                 if (model.status === "checking") return Qt.rgba(window.blue.r,  window.blue.g,  window.blue.b,  0.12)
//                                 if (model.status === "success")  return Qt.rgba(window.green.r, window.green.g, window.green.b, 0.12)
//                                 if (model.status === "failed")   return Qt.rgba(window.red.r,   window.red.g,   window.red.b,   0.07)
//                                 return window.surface0
//                             }
//                             border.color: {
//                                 if (model.status === "checking") return window.blue
//                                 if (model.status === "success")  return window.green
//                                 if (model.status === "failed")   return Qt.rgba(window.red.r, window.red.g, window.red.b, 0.3)
//                                 return window.surface1
//                             }
//                             border.width: (model.status === "checking" || model.status === "success") ? 2 : 1
//                             Behavior on color { ColorAnimation { duration: 250 } }
//                             Behavior on border.color { ColorAnimation { duration: 250 } }
//                             RowLayout {
//                                 anchors.fill: parent; anchors.leftMargin: window.s(14); anchors.rightMargin: window.s(10)
//                                 anchors.topMargin: 0; anchors.bottomMargin: 0
//                                 spacing: window.s(10)
//                                 Text {
//                                     text: "★"
//                                     font.pixelSize: window.s(13)
//                                     color: window.mauve
//                                     opacity: (window.sourcePrefs[window.pendingMedia.imdbId || ""] || "") === model.name ? 1 : 0
//                                     Behavior on opacity { NumberAnimation { duration: 200 } }
//                                     Layout.preferredWidth: window.s(16)
//                                 }
//                                 Text {
//                                     text: model.name
//                                     font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(14)
//                                     color: model.status === "checking" ? window.blue
//                                          : model.status === "success"  ? window.green
//                                          : model.status === "failed"   ? Qt.rgba(window.red.r, window.red.g, window.red.b, 0.7)
//                                          :                               window.text
//                                     Layout.fillWidth: true
//                                     Behavior on color { ColorAnimation { duration: 200 } }
//                                 }
//                                 Item {
//                                     Layout.preferredWidth: window.s(22); Layout.preferredHeight: window.s(22)
//                                     Rectangle {
//                                         anchors.fill: parent; radius: width / 2
//                                         color: "transparent"; border.color: window.surface2; border.width: 2
//                                         visible: model.status === "pending"
//                                     }
//                                     Item {
//                                         anchors.fill: parent
//                                         visible: model.status === "checking"
//                                         property real spinAngle: 0
//                                         NumberAnimation on spinAngle {
//                                             from: 0; to: 360; duration: 700
//                                             loops: Animation.Infinite
//                                             running: model.status === "checking"
//                                             easing.type: Easing.Linear
//                                         }
//                                         Canvas {
//                                             anchors.fill: parent
//                                             property real angle: parent.spinAngle
//                                             onAngleChanged: requestPaint()
//                                             onPaint: {
//                                                 var ctx = getContext("2d")
//                                                 ctx.reset()
//                                                 var cx = width / 2, cy = height / 2, r = width / 2 - 2
//                                                 var startRad = (parent.spinAngle - 90) * Math.PI / 180
//                                                 var endRad   = startRad + 1.6 * Math.PI
//                                                 ctx.beginPath()
//                                                 ctx.arc(cx, cy, r, startRad, endRad)
//                                                 ctx.strokeStyle = window.blue
//                                                 ctx.lineWidth = 2.5
//                                                 ctx.lineCap = "round"
//                                                 ctx.stroke()
//                                             }
//                                         }
//                                     }
//                                     Text {
//                                         anchors.centerIn: parent
//                                         text: "✗"; color: Qt.rgba(window.red.r, window.red.g, window.red.b, 0.7)
//                                         font.weight: Font.Bold; font.pixelSize: window.s(14)
//                                         visible: model.status === "failed"
//                                     }
//                                     Text {
//                                         anchors.centerIn: parent
//                                         text: "✓"; color: window.green
//                                         font.weight: Font.Bold; font.pixelSize: window.s(14)
//                                         visible: model.status === "success"
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                     ColumnLayout {
//                         anchors.centerIn: parent; width: parent.width - window.s(40); spacing: window.s(20)
//                         visible: window.checkingState === "failed_all"
//                         Text {
//                             Layout.fillWidth: true
//                             text: "All stream sources failed for this title."
//                             color: window.subtext0; font.family: "JetBrains Mono"; font.pixelSize: window.s(13)
//                             wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; lineHeight: 1.3
//                         }
//                         Rectangle {
//                             Layout.fillWidth: true; Layout.preferredHeight: window.s(45); radius: window.s(10)
//                             color: fmhyMouse.containsMouse ? window.blue : window.surface1
//                             Behavior on color { ColorAnimation { duration: 150 } }
//                             Text { anchors.centerIn: parent; text: "Browse Alternative Sites"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(13); color: fmhyMouse.containsMouse ? window.crust : window.text }
//                             MouseArea {
//                                 id: fmhyMouse; anchors.fill: parent; hoverEnabled: true
//                                 onClicked: { Quickshell.execDetached(["xdg-open", "https://fmhy.net/video#streaming-sites"]); window.closeSourceModal() }
//                             }
//                         }
//                     }
//                 }
//                 Rectangle {
//                     Layout.fillWidth: true
//                     Layout.preferredHeight: window.checkingState === "found" ? window.s(80) : 0
//                     color: window.surface0; clip: true
//                     Behavior on Layout.preferredHeight { NumberAnimation { duration: 280; easing.type: Easing.OutQuart } }
//                     Rectangle { width: parent.width; height: 1; color: window.surface1; anchors.top: parent.top }
//                     RowLayout {
//                         anchors.fill: parent; anchors.margins: window.s(14); spacing: window.s(10)
//                         Rectangle {
//                             Layout.fillWidth: true; Layout.preferredHeight: window.s(48); radius: window.s(10)
//                             property bool isPreferred: (window.sourcePrefs[window.pendingMedia.imdbId || ""] || "") === window.foundSourceName
//                             color: markWorksMouse.containsMouse
//                                 ? Qt.rgba(window.green.r, window.green.g, window.green.b, 0.25)
//                                 : Qt.rgba(window.green.r, window.green.g, window.green.b, isPreferred ? 0.20 : 0.10)
//                             border.color: isPreferred ? window.green : Qt.rgba(window.green.r, window.green.g, window.green.b, 0.4)
//                             border.width: isPreferred ? 2 : 1
//                             Behavior on color { ColorAnimation { duration: 150 } }
//                             ColumnLayout {
//                                 anchors.centerIn: parent; spacing: window.s(2)
//                                 Text {
//                                     Layout.alignment: Qt.AlignHCenter
//                                     text: parent.parent.isPreferred ? "★ Preferred Source" : "Mark as Working"
//                                     font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12)
//                                     color: window.green
//                                 }
//                                 Text {
//                                     Layout.alignment: Qt.AlignHCenter
//                                     text: window.foundSourceName !== "" ? window.foundSourceName : ""
//                                     font.family: "JetBrains Mono"; font.pixelSize: window.s(10)
//                                     color: Qt.rgba(window.green.r, window.green.g, window.green.b, 0.7)
//                                     visible: text !== ""
//                                 }
//                             }
//                             MouseArea {
//                                 id: markWorksMouse; anchors.fill: parent; hoverEnabled: true
//                                 onClicked: {
//                                     if (window.pendingMedia.imdbId && window.foundSourceName !== "") {
//                                         saveSourcePref(window.pendingMedia.imdbId, window.foundSourceName)
//                                     }
//                                 }
//                             }
//                         }
//                         Rectangle {
//                             Layout.preferredWidth: window.s(110); Layout.preferredHeight: window.s(48); radius: window.s(10)
//                             color: tryNextMouse2.containsMouse ? window.surface2 : window.surface1
//                             border.color: window.surface2; border.width: 1
//                             Behavior on color { ColorAnimation { duration: 150 } }
//                             ColumnLayout {
//                                 anchors.centerIn: parent; spacing: window.s(2)
//                                 Text {
//                                     Layout.alignment: Qt.AlignHCenter
//                                     text: "Try Next"
//                                     font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12)
//                                     color: window.text
//                                 }
//                                 Text {
//                                     Layout.alignment: Qt.AlignHCenter
//                                     text: "Not working?"
//                                     font.family: "JetBrains Mono"; font.pixelSize: window.s(10)
//                                     color: window.subtext0
//                                 }
//                             }
//                             MouseArea { id: tryNextMouse2; anchors.fill: parent; hoverEnabled: true; onClicked: window.skipToNextSource() }
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }
import QtQuick                                                                                  // Import QtQuick module - the core module for QML UI elements and properties
import QtQuick.Window                                                                            // Import Window module - provides access to Screen properties and window management
import QtQuick.Effects                                                                           // Import Effects module - enables visual effects like blur, shadows, etc.
import QtQuick.Layouts                                                                           // Import Layouts module - provides RowLayout, ColumnLayout, GridLayout for arranging items
import QtQuick.Controls                                                                          // Import Controls module - provides reusable UI components like ComboBox, ScrollBar, etc.
import Quickshell                                                                                // Import Quickshell module - the main shell framework for building desktop shells/windows
import Quickshell.Io                                                                             // Import Quickshell.Io module - provides I/O operations like Process, SplitParser for external commands
import "../"                                                                                     // Import parent directory - allows access to QML files in the parent folder (relative path)

Item {                                                                                           // Root Item - the main container for this widget, basic QML visual item without default visuals
    id: window                                                                                   // Assign id "window" to this root Item - used to reference this item throughout the file
    focus: true                                                                                  // Enable keyboard focus for this item - allows it to receive key events like Escape, Tab, etc.

    Scaler {                                                                                     // Create Scaler instance - custom component for responsive scaling across different screen sizes
        id: scaler                                                                               // Assign id "scaler" - used to reference this scaler instance
        currentWidth: Screen.width                                                               // Set currentWidth to Screen.width - captures the current screen width for scaling calculations
    }                                                                                            // End of Scaler definition

    function s(val) {                                                                            // Define helper function s(val) - scales a value proportionally based on screen width
        return scaler.s(val);                                                                    // Call scaler's s() method with val - returns the scaled value for responsive design
    }                                                                                            // End of s() function

    MatugenColors { id: _theme }                                                                 // Create MatugenColors instance with id _theme - loads material you color scheme from system theme
    readonly property color base: _theme.base                                                    // Define readonly color property "base" - binds to Matugen's base color (background)
    readonly property color crust: _theme.crust                                                  // Define readonly color property "crust" - binds to Matugen's crust color (darkest surface)
    readonly property color mantle: _theme.mantle                                                // Define readonly color property "mantle" - binds to Matugen's mantle color (slightly lighter than crust)
    readonly property color text: _theme.text                                                    // Define readonly color property "text" - binds to Matugen's text color (main text color)
    readonly property color subtext0: _theme.subtext0                                            // Define readonly color property "subtext0" - binds to Matugen's subtext0 (secondary text)
    readonly property color surface0: _theme.surface0                                            // Define readonly color property "surface0" - binds to Matugen's surface0 (card backgrounds)
    readonly property color surface1: _theme.surface1                                            // Define readonly color property "surface1" - binds to Matugen's surface1 (slightly elevated surfaces)
    readonly property color surface2: _theme.surface2                                            // Define readonly color property "surface2" - binds to Matugen's surface2 (more elevated surfaces)
    readonly property color mauve: _theme.mauve || "#cba6f7"                                     // Define readonly color "mauve" - theme's mauve with fallback to Catppuccin Mauve hex color
    readonly property color blue: _theme.blue || "#89b4fa"                                       // Define readonly color "blue" - theme's blue with fallback to Catppuccin Blue hex color
    readonly property color green: _theme.green || "#a6e3a1"                                     // Define readonly color "green" - theme's green with fallback to Catppuccin Green hex color
    readonly property color red: _theme.red || "#f38ba8"                                         // Define readonly color "red" - theme's red with fallback to Catppuccin Red hex color

    // --- STATE MANAGEMENT ---                                                                    // Comment header - marks the start of state management property definitions
    property string currentView: "search" // "search" or "series"                               // Define currentView property - tracks whether showing search grid ("search") or series detail view ("series")
    property string mediaType: "movie" // "movie" or "tv"                                       // Define mediaType property - tracks current media type filter (movies or TV shows)
    property string filterSort: "Default"                                                        // Define filterSort property - current sorting method for results (Default, Year, Title, Rating)
    property bool isSearching: searchInput.text.trim() !== ""                                    // Define isSearching property - dynamically true when search input has non-whitespace text
    property bool isSearchingNetwork: false                                                      // Define isSearchingNetwork property - tracks if a network search request is currently in progress
    property bool isSearchMode: window.isSearching                                               // Define isSearchMode property - mirrors isSearching for convenience, true when actively searching
    property string selectedImdbId: ""                                                           // Define selectedImdbId property - stores the IMDb ID of currently selected movie/show
    property string selectedTitle: ""                                                            // Define selectedTitle property - stores the title of currently selected movie/show
    property string selectedPoster: ""                                                           // Define selectedPoster property - stores the poster URL of currently selected item
    property string selectedDescription: ""                                                      // Define selectedDescription property - stores the description/synopsis of selected item
    property var seriesDataMap: ({})                                                             // Define seriesDataMap property - JavaScript object mapping season numbers to episode arrays
    property int currentSeason: 1                                                                // Define currentSeason property - tracks which season is currently selected (defaults to 1)
    property bool isLoadingSeries: false                                                         // Define isLoadingSeries property - tracks if series data is currently being fetched
    property bool trendingMoviesLoaded: false                                                    // Define trendingMoviesLoaded property - tracks if trending movies have been successfully loaded
    property bool trendingTvLoaded: false                                                        // Define trendingTvLoaded property - tracks if trending TV shows have been successfully loaded
    property bool isFetchingMovies: false                                                        // Define isFetchingMovies property - tracks if movie trending data fetch is in progress
    property bool isFetchingTv: false                                                            // Define isFetchingTv property - tracks if TV trending data fetch is in progress
    property bool isLoadingPopular: isFetchingMovies || isFetchingTv                             // Define isLoadingPopular property - true when either movies or TV trending is being fetched
    property var currentFetchResults: []                                                         // Define currentFetchResults property - stores raw search results array before filtering/sorting
    property var rawTrendingMovies: []                                                           // Define rawTrendingMovies property - stores unfiltered trending movies for re-sorting
    property var rawTrendingTv: []                                                               // Define rawTrendingTv property - stores unfiltered trending TV shows for re-sorting
    property real trendingMoviesLastFetch: 0                                                     // Define trendingMoviesLastFetch property - timestamp (ms) of last trending movies fetch
    property real trendingTvLastFetch: 0                                                         // Define trendingTvLastFetch property - timestamp (ms) of last trending TV fetch
    readonly property real trendingCacheMaxAge: 12 * 60 * 60 * 1000                              // Define trendingCacheMaxAge - 12 hours in milliseconds, max age before re-fetching trending
    property bool seasonSwitching: false                                                         // Define seasonSwitching property - tracks if UI is animating between season changes
    property bool stateRestored: false                                                           // Define stateRestored property - tracks if UI state has been restored from cache on startup
    property bool pendingSeriesFocusRestore: false                                               // Define pendingSeriesFocusRestore - tracks if focus needs to be restored to series view after load

    Timer {                                                                                      // Define Timer for safety loading timeout
        id: safetyLoadingTimer                                                                    // Assign id "safetyLoadingTimer" - used to reference this timer
        interval: 12000                                                                           // Set interval to 12000ms (12 seconds) - maximum time before forcing loading state off
        running: window.isLoadingPopular || window.isSearchingNetwork                             // Auto-run when either popular content or search is loading - acts as safety timeout
        repeat: false                                                                             // Don't repeat - this timer fires only once per activation
        onTriggered: {                                                                            // Handler when timer fires (12 seconds elapsed without completion)
            window.isFetchingMovies = false                                                       // Force stop movie fetching state - prevents infinite loading spinner
            window.isFetchingTv = false                                                           // Force stop TV fetching state - prevents infinite loading spinner
            window.isSearchingNetwork = false                                                     // Force stop search network state - prevents infinite loading spinner
        }                                                                                         // End of onTriggered handler
    }                                                                                            // End of safetyLoadingTimer

    Timer {                                                                                      // Define Timer for search debouncing
        id: searchDebounceTimer                                                                    // Assign id "searchDebounceTimer" - used to delay search until user stops typing
        interval: 400                                                                             // Set interval to 400ms - wait 400ms after last keystroke before searching
        repeat: false                                                                             // Don't repeat - fires once after interval expires
        onTriggered: {                                                                            // Handler when timer fires (user stopped typing for 400ms)
            if (searchInput.text.trim() !== "") {                                                  // Check if search input is not empty (ignore whitespace-only)
                doSearch(searchInput.text)                                                        // Trigger the actual search with current text - calls the doSearch function
            }                                                                                     // End of if statement
        }                                                                                         // End of onTriggered handler
    }                                                                                            // End of searchDebounceTimer

    Timer {                                                                                      // Define Timer for series focus restoration
        id: seriesFocusRestoreTimer                                                               // Assign id "seriesFocusRestoreTimer" - delays focus restoration to series view
        interval: 350                                                                             // Set interval to 350ms - wait for animations/loading before restoring focus
        repeat: false                                                                             // Don't repeat - fires once
        onTriggered: {                                                                            // Handler when timer fires
            if (window.currentView === "series" && !window.isSourceModalOpen) {                   // Check if still in series view and source modal is not open
                window.forceActiveFocus()                                                          // Force keyboard focus to the main window - enables key navigation
                window.pendingSeriesFocusRestore = false                                           // Reset the pending focus restore flag - focus has been restored
            }                                                                                     // End of if statement
        }                                                                                         // End of onTriggered handler
    }                                                                                            // End of seriesFocusRestoreTimer

    // --- SHARED DISK I/O HELPER ---                                                              // Comment header - marks disk I/O helper function section
    function saveJsonToCache(filename, dataObj) {                                                 // Define function to save JSON data to cache file - reusable disk write helper
        let jsStr = JSON.stringify(dataObj).replace(/'/g, "'\\''")                               // Convert dataObj to JSON string, then escape single quotes for bash - prevents shell injection
        Quickshell.execDetached(["bash", "-c", "mkdir -p ~/.cache && echo '" + jsStr + "' > ~/.cache/" + filename])  // Execute bash command: create cache dir then write JSON to file using echo redirection
    }                                                                                            // End of saveJsonToCache function

    // --- PERSISTENT CACHE IO ---                                                                 // Comment header - marks persistent cache I/O section
    Process {                                                                                    // Define Process to read search history from cache file
        id: readHistoryProc                                                                       // Assign id "readHistoryProc" - used to trigger reading history
        command: ["bash", "-c", "cat ~/.cache/qs_movie_history.json 2>/dev/null || echo '[]'"]    // Shell command: try to read history file, if fails return empty JSON array
        running: false                                                                            // Don't run automatically - will be started manually in Component.onCompleted
        stdout: SplitParser {                                                                     // Define stdout parser - processes the command output as it arrives
            onRead: (data) => {                                                                    // Handler called when output data is received
                try {                                                                              // Try block for JSON parsing safety
                    let parsed = JSON.parse(data.trim())                                            // Parse the JSON string, trimming whitespace - converts to JavaScript array
                    searchHistoryModel.clear()                                                      // Clear existing history model - remove all previous entries
                    for (let i = parsed.length - 1; i >= 0; i--) {                                  // Loop backwards through parsed array - reverse chronological order
                        searchHistoryModel.insert(0, { query: parsed[i] })                          // Insert each history item at beginning of model - maintains newest-first order
                    }                                                                              // End of for loop
                } catch(e) {}                                                                      // Catch and ignore any JSON parse errors - silently fails if cache is corrupt
            }                                                                                     // End of onRead handler
        }                                                                                         // End of SplitParser
    }                                                                                            // End of readHistoryProc

    Process {                                                                                    // Define Process to read watch history from cache file
        id: readWatchHistoryProc                                                                  // Assign id "readWatchHistoryProc" - used to trigger reading watch history
        command: ["bash", "-c", "cat ~/.cache/qs_movie_watch_history.json 2>/dev/null || echo '[]'"]  // Shell command: try to read watch history file, if fails return empty JSON array
        running: false                                                                            // Don't run automatically - started manually
        stdout: SplitParser {                                                                     // Define stdout parser for command output
            onRead: (data) => {                                                                    // Handler when output data is received
                try {                                                                              // Try block for JSON parsing safety
                    let parsed = JSON.parse(data.trim())                                            // Parse the JSON string to JavaScript array of watch history objects
                    watchHistoryModel.clear()                                                       // Clear existing watch history model
                    for (let i = parsed.length - 1; i >= 0; i--) {                                  // Loop backwards through array - reverse chronological
                        watchHistoryModel.insert(0, parsed[i])                                      // Insert each watch history item at beginning of model
                    }                                                                              // End of for loop
                } catch(e) {}                                                                      // Catch and ignore parse errors
            }                                                                                     // End of onRead handler
        }                                                                                         // End of SplitParser
    }                                                                                            // End of readWatchHistoryProc

    function processTrendingCache(parsed, typeStr, targetModel) {                                 // Define function to process trending cache data - handles both movies and TV
        let now = Date.now()                                                                      // Get current timestamp in milliseconds - used to check cache age
        let isMovie = typeStr === "movie"                                                          // Determine if processing movies (true) or TV shows (false)
        let lastFetch = parsed[isMovie ? "moviesLastFetch" : "tvLastFetch"] || 0                  // Get last fetch timestamp from cache, default to 0 if not present
        let items = parsed[isMovie ? "movies" : "tv"]                                              // Get the items array from cache - either movies or tv array

        if (items && items.length > 0) {                                                           // Check if items exist and have content - valid cache data
            targetModel.clear()                                                                    // Clear the target model - remove old data before populating
            if (isMovie) window.rawTrendingMovies = items; else window.rawTrendingTv = items       // Store raw items for re-sorting - preserve unfiltered data
            for (let i = 0; i < items.length; i++) targetModel.append(items[i])                    // Loop through items and append each to the target ListModel for display
            
            if (isMovie) { window.trendingMoviesLoaded = true; window.isFetchingMovies = false; window.trendingMoviesLastFetch = lastFetch }  // If movies: mark as loaded, stop fetching spinner, save fetch timestamp
            else { window.trendingTvLoaded = true; window.isFetchingTv = false; window.trendingTvLastFetch = lastFetch }                      // If TV: mark as loaded, stop fetching spinner, save fetch timestamp
            
            if ((now - lastFetch) > window.trendingCacheMaxAge) fetchTrending(typeStr === "movie" ? "movie" : "series")  // If cache is older than 12 hours, trigger a fresh fetch in background
        } else {                                                                                   // No valid cached items found
            fetchTrending(typeStr === "movie" ? "movie" : "series")                               // Fetch trending data from network immediately
        }                                                                                         // End of if-else
    }                                                                                            // End of processTrendingCache function

    Process {                                                                                    // Define Process to read trending cache file
        id: readTrendingCacheProc                                                                 // Assign id "readTrendingCacheProc" - triggered to read cached trending data
        command: ["bash", "-c", "cat ~/.cache/qs_trending_cache.json 2>/dev/null || echo '{}'"]   // Shell command: try to read trending cache, if fails return empty JSON object
        running: false                                                                            // Don't run automatically - started manually
        stdout: SplitParser {                                                                     // Define stdout parser
            onRead: (data) => {                                                                    // Handler when output is received
                try {                                                                              // Try block for JSON parsing
                    let parsed = JSON.parse(data.trim())                                            // Parse the JSON string to JavaScript object
                    processTrendingCache(parsed, "movie", cachedTrendingMovies)                     // Process movie trending data from cache
                    processTrendingCache(parsed, "tv", cachedTrendingTv)                            // Process TV trending data from cache
                } catch(e) {                                                                       // Catch parse errors
                    fetchTrending("movie")                                                          // If cache parsing fails, fetch movies from network
                    fetchTrending("series")                                                         // If cache parsing fails, fetch TV from network
                }                                                                                  // End of catch
            }                                                                                     // End of onRead handler
        }                                                                                         // End of SplitParser
    }                                                                                            // End of readTrendingCacheProc

    Process {                                                                                    // Define Process to read UI state cache (restores previous session state)
        id: readUiStateProc                                                                       // Assign id "readUiStateProc" - triggered to restore previous UI state
        command: ["bash", "-c", "cat ~/.cache/qs_ui_state.json 2>/dev/null || echo '{}'"]         // Shell command: try to read UI state file, if fails return empty JSON object
        running: false                                                                            // Don't run automatically - started manually
        stdout: SplitParser {                                                                     // Define stdout parser
            onRead: (data) => {                                                                    // Handler when output is received
                try {                                                                              // Try block for JSON parsing
                    let s = JSON.parse(data.trim())                                                 // Parse the JSON string to state object
                    if (!s || Object.keys(s).length === 0) {                                        // Check if state is null or empty object
                        window.stateRestored = true                                                 // Mark state as restored (even though empty) - proceed with defaults
                        return                                                                      // Exit early - nothing to restore
                    }                                                                              // End of if
                    if (s.mediaType) window.mediaType = s.mediaType                                // Restore media type (movie/tv) if saved
                    if (s.filterSort) {                                                             // Check if filter/sort setting was saved
                        window.filterSort = s.filterSort                                            // Restore the filter/sort selection
                        let idx = filterSelector.model.indexOf(s.filterSort)                        // Find the index of saved sort in ComboBox model
                        if (idx >= 0) filterSelector.currentIndex = idx                            // If found, set ComboBox to that index
                    }                                                                              // End of if
                    if (s.searchText && s.searchText !== "") searchInput.text = s.searchText        // Restore search text if it was non-empty
                    if (s.currentView) window.currentView = s.currentView                           // Restore current view (search or series)
                    if (s.selectedImdbId) window.selectedImdbId = s.selectedImdbId                  // Restore selected IMDb ID
                    if (s.selectedTitle) window.selectedTitle = s.selectedTitle                     // Restore selected title
                    if (s.selectedPoster) window.selectedPoster = s.selectedPoster                  // Restore selected poster URL
                    if (s.selectedDescription) window.selectedDescription = s.selectedDescription  // Restore selected description
                    if (s.currentSeason) window.currentSeason = s.currentSeason                     // Restore current season number
                    
                    if (s.isSourceModalOpen && s.pendingMedia && s.pendingMedia.imdbId) {           // Check if source modal was open with pending media
                        window.pendingMedia = s.pendingMedia                                        // Restore the pending media object (imdbId, title, etc.)
                        window.foundSourceName = s.foundSourceName || ""                            // Restore found source name if any
                        for (let i = 0; i < sourceModel.count; i++) sourceModel.setProperty(i, "status", "pending")  // Reset all source statuses to pending
                        window.isSourceModalOpen = true                                             // Re-open the source modal
                        if (s.checkingState === "found" && s.foundSourceName) {                     // If a source was already found
                            window.checkingState = "found"                                          // Set checking state to found
                            for (let i = 0; i < sourceModel.count; i++) {                           // Loop through source model
                                if (sourceModel.get(i).name === s.foundSourceName) {                // Find the source that was marked as working
                                    sourceModel.setProperty(i, "status", "success")                  // Set that source's status to success
                                    window.currentCheckIndex = i                                    // Set current check index to the found source
                                    break                                                           // Exit loop once found
                                }                                                                  // End of if
                            }                                                                      // End of for loop
                        } else {                                                                   // If checking was still in progress or failed
                            window.sourceCheckOrder = buildSourceOrder()                            // Rebuild the source checking order
                            window.sourceCheckStep = 0                                              // Reset to first step
                            window.currentCheckIndex = window.sourceCheckOrder[0]                  // Set current index to first source in order
                            window.checkingState = "checking"                                      // Set state to checking
                            checkNextSource()                                                       // Start checking sources from beginning
                        }                                                                          // End of if-else
                    }                                                                              // End of if
                    if (s.currentView === "series" && s.selectedImdbId) {                           // If series view was active
                        window.pendingSeriesFocusRestore = true                                     // Flag that focus needs to be restored after loading
                        fetchSeriesData(s.selectedImdbId, s.currentSeason || 1, "", "", true)       // Re-fetch series data (isReload=true) for the selected show
                    }                                                                              // End of if
                    window.stateRestored = true                                                     // Mark state as fully restored
                } catch(e) {                                                                       // Catch any errors during state restoration
                    window.stateRestored = true                                                     // Still mark as restored to not block UI - proceed with defaults
                }                                                                                  // End of catch
            }                                                                                     // End of onRead handler
        }                                                                                         // End of SplitParser
    }                                                                                            // End of readUiStateProc

    property var sourcePrefs: ({})                                                               // Define sourcePrefs property - object mapping IMDb IDs to preferred streaming source names
    Process {                                                                                    // Define Process to read source preferences from cache
        id: readSourcePrefsProc                                                                   // Assign id "readSourcePrefsProc" - triggered to read preferred sources
        command: ["bash", "-c", "cat ~/.cache/qs_source_prefs.json 2>/dev/null || echo '{}'"]     // Shell command: try to read source prefs file, if fails return empty object
        running: false                                                                            // Don't run automatically - started manually
        stdout: SplitParser {                                                                     // Define stdout parser
            onRead: (data) => {                                                                    // Handler when output is received
                try { window.sourcePrefs = JSON.parse(data.trim()) }                              // Parse JSON and assign to sourcePrefs property directly
                catch(e) { window.sourcePrefs = {} }                                               // If parse fails, initialize as empty object
            }                                                                                     // End of onRead handler
        }                                                                                         // End of SplitParser
    }                                                                                            // End of readSourcePrefsProc

    // --- SAVING CACHE FUNCTIONS ---                                                              // Comment header - marks cache saving functions section
    function saveUiState() {                                                                      // Define function to save current UI state to cache - called before closing
        saveJsonToCache("qs_ui_state.json", {                                                      // Call helper to save JSON - filename and object
            mediaType: window.mediaType, filterSort: window.filterSort, searchText: searchInput.text,  // Save media type, sort, and search text
            currentView: window.currentView, selectedImdbId: window.selectedImdbId,                // Save current view and selected movie/show ID
            selectedTitle: window.selectedTitle, selectedPoster: window.selectedPoster,            // Save selected title and poster URL
            selectedDescription: window.selectedDescription, currentSeason: window.currentSeason,  // Save description and season number
            isSourceModalOpen: window.isSourceModalOpen, checkingState: window.checkingState,      // Save source modal state
            pendingMedia: window.pendingMedia, foundSourceName: window.foundSourceName             // Save pending media info and found source
        })                                                                                         // End of saveJsonToCache call
    }                                                                                            // End of saveUiState function

    function saveHistory() {                                                                      // Define function to save search history to cache
        let arr = []                                                                               // Initialize empty array to hold history queries
        for (let i = 0; i < searchHistoryModel.count; i++) arr.push(searchHistoryModel.get(i).query)  // Loop through model, extract query strings into array
        saveJsonToCache("qs_movie_history.json", arr)                                             // Save the array to history cache file
    }                                                                                            // End of saveHistory function

    function saveWatchHistory() {                                                                 // Define function to save watch history to cache
        let arr = []                                                                               // Initialize empty array for watch history items
        for (let i = 0; i < watchHistoryModel.count; i++) {                                        // Loop through watch history model
            let item = watchHistoryModel.get(i)                                                     // Get each item from the model
            arr.push({ imdbId: item.imdbId, title: item.title, poster: item.poster, type: item.type })  // Push relevant fields to array (imdbId, title, poster, type)
        }                                                                                         // End of for loop
        saveJsonToCache("qs_movie_watch_history.json", arr)                                       // Save the array to watch history cache file
    }                                                                                            // End of saveWatchHistory function

    function saveTrendingCache() {                                                                // Define function to save trending data to cache
        if (cachedTrendingMovies.count === 0 || cachedTrendingTv.count === 0) return              // Don't save if either model is empty - prevents saving incomplete data
        let cacheObj = { moviesLastFetch: window.trendingMoviesLastFetch, tvLastFetch: window.trendingTvLastFetch, movies: [], tv: [] }  // Create cache object with timestamps and arrays
        for (let i = 0; i < cachedTrendingMovies.count; i++) {                                    // Loop through cached trending movies
            let m = cachedTrendingMovies.get(i)                                                     // Get each movie item
            cacheObj.movies.push({ imdbId: m.imdbId, title: m.title, poster: m.poster, type: m.type, year: m.year, rating: m.rating || 0, popularity: i })  // Push movie data with all relevant fields
        }                                                                                         // End of for loop
        for (let i = 0; i < cachedTrendingTv.count; i++) {                                        // Loop through cached trending TV shows
            let t = cachedTrendingTv.get(i)                                                         // Get each TV item
            cacheObj.tv.push({ imdbId: t.imdbId, title: t.title, poster: t.poster, type: t.type, year: t.year, rating: t.rating || 0, popularity: i })  // Push TV data with all relevant fields
        }                                                                                         // End of for loop
        saveJsonToCache("qs_trending_cache.json", cacheObj)                                       // Save the cache object to trending cache file
    }                                                                                            // End of saveTrendingCache function

    function saveSourcePref(imdbId, sourceName) {                                                  // Define function to save preferred source for a specific IMDb ID
        let prefs = window.sourcePrefs                                                             // Get current source preferences object
        prefs[imdbId] = sourceName                                                                 // Set the preferred source name for this IMDb ID
        window.sourcePrefs = prefs                                                                 // Reassign to trigger property change notification
        saveJsonToCache("qs_source_prefs.json", prefs)                                            // Save updated preferences to cache file
    }                                                                                            // End of saveSourcePref function

    // --- SOURCE MODEL ---                                                                         // Comment header - marks streaming source model section
    ListModel {                                                                                  // Define ListModel containing all streaming sources
        id: sourceModel                                                                            // Assign id "sourceModel" - referenced when checking sources
        ListElement { name: "VidSrc.net";    urlMovie: "https://vidsrc.net/embed/movie/%1";                               urlTv: "https://vidsrc.net/embed/tv/%1/%2/%3";                            status: "pending" }  // Source 1: VidSrc.net with movie and TV URL patterns
        ListElement { name: "VidLink";       urlMovie: "https://vidlink.pro/movie/%1?autoplay=1";                         urlTv: "https://vidlink.pro/tv/%1/%2/%3?autoplay=1";                      status: "pending" }  // Source 2: VidLink with autoplay parameter
        ListElement { name: "VidSrc.pro";    urlMovie: "https://vidsrc.pro/embed/movie/%1";                               urlTv: "https://vidsrc.pro/embed/tv/%1/%2/%3";                            status: "pending" }  // Source 3: VidSrc.pro
        ListElement { name: "VidSrc.in";     urlMovie: "https://vidsrc.in/embed/movie/%1";                                urlTv: "https://vidsrc.in/embed/tv/%1/%2/%3";                             status: "pending" }  // Source 4: VidSrc.in
        ListElement { name: "VidSrc.cc";     urlMovie: "https://vidsrc.cc/v2/embed/movie/%1?autoPlay=true";               urlTv: "https://vidsrc.cc/v2/embed/tv/%1/%2/%3?autoPlay=true";            status: "pending" }  // Source 5: VidSrc.cc with autoPlay
        ListElement { name: "Embed.su";      urlMovie: "https://embed.su/embed/movie/%1";                                 urlTv: "https://embed.su/embed/tv/%1/%2/%3";                              status: "pending" }  // Source 6: Embed.su
        ListElement { name: "SmashyStream";  urlMovie: "https://player.smashy.stream/movie/%1";                           urlTv: "https://player.smashy.stream/tv/%1?s=%2&e=%3";                    status: "pending" }  // Source 7: SmashyStream
        ListElement { name: "AutoEmbed";     urlMovie: "https://autoembed.to/movie/imdb/%1";                              urlTv: "https://autoembed.to/tv/imdb/%1-%2-%3";                           status: "pending" }  // Source 8: AutoEmbed
        ListElement { name: "2Embed";        urlMovie: "https://www.2embed.cc/embed/%1";                                  urlTv: "https://www.2embed.cc/embedtv/%1&s=%2&e=%3";                      status: "pending" }  // Source 9: 2Embed
        ListElement { name: "MultiEmbed";    urlMovie: "https://multiembed.mov/directstream.php?video_id=%1";             urlTv: "https://multiembed.mov/directstream.php?video_id=%1&s=%2&e=%3";  status: "pending" }  // Source 10: MultiEmbed
    }                                                                                            // End of sourceModel

    // --- ANIMATIONS & FOCUS ---                                                                   // Comment header - marks animations and focus management section
    property real introPhase: 0                                                                   // Define introPhase property - controls intro animation progress (0 to 1)
    NumberAnimation on introPhase {                                                               // Define NumberAnimation on introPhase property
        id: introPhaseAnim                                                                         // Assign id "introPhaseAnim" - can be restarted to replay animation
        from: 0; to: 1; duration: 800; easing.type: Easing.OutQuart; running: true                // Animate from 0 to 1 over 800ms with OutQuart easing, starts automatically
    }                                                                                            // End of NumberAnimation

    Timer {                                                                                      // Define Timer for initial focus management
        id: focusTimer                                                                             // Assign id "focusTimer"
        interval: 50; running: true; repeat: false                                                 // Run once after 50ms - short delay to ensure UI is ready
        onTriggered: {                                                                            // Handler when timer fires
            if (window.currentView === "search") searchInput.forceActiveFocus()                    // If in search view, focus the search input field
            else window.forceActiveFocus()                                                          // If in series view, focus the main window for key navigation
        }                                                                                         // End of onTriggered handler
    }                                                                                            // End of focusTimer

    Timer {                                                                                      // Define Timer to scroll grids to top
        id: scrollToTopTimer                                                                       // Assign id "scrollToTopTimer"
        interval: 80; running: false; repeat: false                                                // 80ms delay, doesn't start automatically, fires once
        onTriggered: {                                                                            // Handler when timer fires
            movieGrid.positionViewAtBeginning()                                                    // Scroll movie grid to the very top
            tvGrid.positionViewAtBeginning()                                                       // Scroll TV grid to the very top
            searchGrid.positionViewAtBeginning()                                                   // Scroll search grid to the very top
        }                                                                                         // End of onTriggered handler
    }                                                                                            // End of scrollToTopTimer

    Component.onCompleted: {                                                                      // Lifecycle handler - runs when this component is fully created
        readHistoryProc.running = true                                                            // Start reading search history from cache
        readWatchHistoryProc.running = true                                                       // Start reading watch history from cache
        readSourcePrefsProc.running = true                                                        // Start reading source preferences from cache
        window.isFetchingMovies = true                                                            // Set movies fetching flag to show loading state
        window.isFetchingTv = true                                                                // Set TV fetching flag to show loading state
        readTrendingCacheProc.running = true                                                      // Start reading trending data from cache
        readUiStateProc.running = true                                                            // Start reading UI state from cache (restores previous session)
    }                                                                                            // End of Component.onCompleted

    Connections {                                                                                 // Define Connections object to listen for signals from the window
        target: window                                                                             // Listen to signals from the root window item
        function onVisibleChanged() {                                                              // Handler for when window visibility changes (shown/hidden)
            if (window.visible) {                                                                    // If window becomes visible (shown)
                introPhaseAnim.restart()                                                              // Restart the intro animation - smooth fade-in effect
                if (!window.isSourceModalOpen && window.currentView === "search") {                   // If source modal not open and in search view
                    focusTimer.restart()                                                               // Restart focus timer to focus search input
                    scrollToTopTimer.restart()                                                         // Restart scroll timer to position grids at top
                } else if (window.currentView === "series") {                                         // If in series view
                    seriesFocusRestoreTimer.restart()                                                  // Restart series focus restoration timer
                }                                                                                    // End of if-else
                if (searchHistoryModel.count === 0) readHistoryProc.running = true                    // If history model is empty, re-read from cache
                if (watchHistoryModel.count === 0) readWatchHistoryProc.running = true                // If watch history model is empty, re-read from cache
                if (!window.trendingMoviesLoaded) fetchTrending("movie")                              // If movies not loaded, fetch from network
                if (!window.trendingTvLoaded) fetchTrending("series")                                 // If TV not loaded, fetch from network
                if (searchInput.text !== "") doSearch(searchInput.text)                              // If search text exists, re-execute search
                if (window.currentView === "series" && window.selectedImdbId !== "" && episodeModel.count === 0) {  // If in series view with selected show but no episodes loaded
                    fetchSeriesData(window.selectedImdbId, window.currentSeason, "", "", true)        // Re-fetch series data (isReload=true)
                }                                                                                    // End of if
            } else {                                                                                 // If window becomes hidden
                saveUiState()                                                                         // Save current UI state to cache before hiding
            }                                                                                        // End of if-else
        }                                                                                          // End of onVisibleChanged handler
    }                                                                                            // End of Connections

    Keys.onPressed: (event) => {                                                                   // Global key press handler for the window
        if (window.isSourceModalOpen) {                                                             // If source modal is currently open
            if (event.key === Qt.Key_Escape) { window.closeSourceModal(); event.accepted = true }    // Escape key closes the source modal
        } else if (window.currentView === "series") {                                               // If in series detail view
            if (event.key === Qt.Key_Escape) {                                                       // Escape key in series view
                window.currentView = "search"                                                         // Switch back to search view
                searchInput.forceActiveFocus()                                                        // Focus the search input
                event.accepted = true                                                                // Mark event as handled
            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {                  // Tab or Shift+Tab in series view - cycle seasons
                let sCount = seasonModel.count                                                        // Get number of seasons
                if (sCount > 0) {                                                                     // If there are seasons
                    let idx = -1                                                                       // Initialize season index to -1 (not found)
                    for (let i = 0; i < sCount; i++) { if (seasonModel.get(i).seasonNum === window.currentSeason) { idx = i; break } }  // Find index of current season in model
                    if (idx !== -1) {                                                                  // If current season found in model
                        let step = event.key === Qt.Key_Tab ? 1 : -1                                   // Tab goes forward (+1), Backtab goes backward (-1)
                        window.currentSeason = seasonModel.get((idx + step + sCount) % sCount).seasonNum  // Calculate new season with wrap-around using modulo
                        updateEpisodes(window.currentSeason)                                           // Update episodes list for the new season
                    }                                                                                 // End of if
                }                                                                                    // End of if
                event.accepted = true                                                                // Mark event as handled
            } else if (event.key === Qt.Key_Down) {                                                  // Down arrow in series view
                if (epList.currentIndex < epList.count - 1) epList.currentIndex++; event.accepted = true  // Move episode selection down if not at end
            } else if (event.key === Qt.Key_Up) {                                                    // Up arrow in series view
                if (epList.currentIndex > 0) epList.currentIndex--; event.accepted = true             // Move episode selection up if not at beginning
            } else if (event.key === Qt.Key_Return) {                                                // Enter key in series view - play selected episode
                let ep = episodeModel.get(epList.currentIndex)                                        // Get the currently selected episode
                if (ep) startSourceCheck("tv", window.selectedImdbId, window.selectedTitle, window.selectedPoster, window.currentSeason, ep.epNum)  // Start source check with TV episode details
                event.accepted = true                                                                // Mark event as handled
            }                                                                                       // End of if-else
        } else if (event.key === Qt.Key_Escape) {                                                    // Escape key in search view
            saveUiState()                                                                            // Save UI state before closing
            Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"])  // Execute shell script to close the quickshell window
            event.accepted = true                                                                    // Mark event as handled
        }                                                                                          // End of if-else
    }                                                                                            // End of Keys.onPressed

    property bool isKeyboardNav: false                                                            // Define isKeyboardNav property - tracks if user is navigating with keyboard (vs mouse)
    Timer { id: keyboardNavTimer; interval: 500; repeat: false; onTriggered: window.isKeyboardNav = false }  // Timer to reset keyboard nav flag after 500ms of inactivity - reverts to mouse mode

    ListModel { id: searchHistoryModel }                                                          // Define ListModel for search history - stores recent search queries
    ListModel { id: watchHistoryModel }                                                           // Define ListModel for watch history - stores recently watched items
    ListModel { id: cachedTrendingMovies }                                                        // Define ListModel for cached trending movies - display model for movie grid
    ListModel { id: cachedTrendingTv }                                                            // Define ListModel for cached trending TV shows - display model for TV grid
    ListModel { id: searchResults }                                                               // Define ListModel for search results - display model for search grid
    ListModel { id: seasonModel }                                                                  // Define ListModel for seasons - stores available seasons for a TV show
    ListModel { id: episodeModel }                                                                 // Define ListModel for episodes - stores episodes for the selected season

    function addToWatchHistory(item) {                                                             // Define function to add an item to watch history
        for (let i = 0; i < watchHistoryModel.count; i++) {                                         // Loop through existing watch history
            if (watchHistoryModel.get(i).imdbId === item.imdbId) {                                   // Check if this IMDb ID already exists in history
                watchHistoryModel.remove(i)                                                           // Remove the duplicate entry (will be re-added at top)
                break                                                                                 // Exit loop once duplicate is found and removed
            }                                                                                        // End of if
        }                                                                                          // End of for loop
        watchHistoryModel.insert(0, item)                                                           // Insert item at beginning of model (most recent first)
        if (watchHistoryModel.count > 15) watchHistoryModel.remove(15)                              // Limit history to 15 items - remove oldest if exceeded
        saveWatchHistory()                                                                          // Save updated watch history to cache file
    }                                                                                            // End of addToWatchHistory function

    function addSearchHistory(query) {                                                              // Define function to add a search query to history
        if (query.trim() === "") return                                                              // Don't add empty or whitespace-only queries
        for (let i = 0; i < searchHistoryModel.count; i++) {                                         // Loop through existing search history
            if (searchHistoryModel.get(i).query.toLowerCase() === query.toLowerCase()) {              // Check for case-insensitive duplicate
                searchHistoryModel.remove(i)                                                          // Remove duplicate (will be re-added at top)
                break                                                                                 // Exit loop once found
            }                                                                                        // End of if
        }                                                                                          // End of for loop
        searchHistoryModel.insert(0, { query: query.trim() })                                        // Insert query at beginning - trimmed of whitespace
        if (searchHistoryModel.count > 10) searchHistoryModel.remove(10)                            // Limit to 10 items - remove oldest if exceeded
        saveHistory()                                                                               // Save updated history to cache file
    }                                                                                            // End of addSearchHistory function

    // ==========================================                                                 // Decorative separator comment
    // SOURCE CHECKING SYSTEM                                                                      // Section header - marks the streaming source checking system
    // ==========================================                                                 // Decorative separator comment
    property bool isSourceModalOpen: false                                                        // Define isSourceModalOpen property - controls visibility of source checking modal
    property int currentCheckIndex: 0                                                             // Define currentCheckIndex property - index in sourceOrder array currently being checked
    property var pendingMedia: ({})                                                               // Define pendingMedia property - stores info about media being checked (imdbId, title, etc.)
    property string checkingState: "idle"                                                          // Define checkingState property - current state: "idle", "checking", "found", "failed_all"
    property string foundSourceName: ""                                                            // Define foundSourceName property - name of source that successfully passed check
    property var activeCheckXhr: null                                                              // Define activeCheckXhr property - reference to current XMLHttpRequest for abort capability
    readonly property var errorPagePatterns: [                                                      // Define errorPagePatterns - array of strings that indicate an error/not-found page
        "404", "not found", "no results", "video not found", "media not found",                     // Common error page indicators in lowercase
        "content not found", "page not found", "error 404", "does not exist"                        // Additional error patterns to detect failed sources
    ]                                                                                            // End of errorPagePatterns

    function buildSourceUrl(srcIndex) {                                                             // Define function to build URL for a specific source index
        let src = sourceModel.get(srcIndex)                                                          // Get the source object from sourceModel by index
        let m = pendingMedia                                                                         // Get the pending media object (contains type, imdbId, season, ep)
        if (m.type === "movie") return src.urlMovie.arg(m.imdbId)                                    // If movie type, format movie URL by replacing %1 with IMDb ID
        return src.urlTv.arg(m.imdbId).arg(m.season).arg(m.ep)                                       // If TV type, format TV URL by replacing %1=imdbId, %2=season, %3=episode
    }                                                                                            // End of buildSourceUrl function

    function buildSourceOrder() {                                                                  // Define function to build the order in which sources are checked
        let order = []                                                                               // Initialize empty array for source indices
        let imdbId = pendingMedia.imdbId                                                             // Get IMDb ID of pending media
        let preferred = window.sourcePrefs[imdbId] || null                                           // Get preferred source for this IMDb ID, or null if not set
        let prefIdx = -1                                                                             // Initialize preferred index to -1 (not found)
        if (preferred) {                                                                             // If a preferred source exists
            for (let i = 0; i < sourceModel.count; i++) {                                             // Loop through all sources
                if (sourceModel.get(i).name === preferred) { prefIdx = i; break }                       // Find the index of preferred source by name
            }                                                                                        // End of for loop
        }                                                                                          // End of if
        if (prefIdx !== -1) order.push(prefIdx)                                                      // If preferred source found, add it first in the order
        for (let i = 0; i < sourceModel.count; i++) { if (i !== prefIdx) order.push(i) }             // Add all other sources after preferred (skip if already added)
        return order                                                                                 // Return the ordered array of source indices
    }                                                                                            // End of buildSourceOrder function

    property var sourceCheckOrder: []                                                              // Define sourceCheckOrder property - array of source indices in checking order
    property int sourceCheckStep: 0                                                                // Define sourceCheckStep property - current position in sourceCheckOrder array

    function startSourceCheck(type, imdbId, title, poster, season, ep) {                            // Define function to start the source checking process
        pendingMedia = { type: type, imdbId: imdbId, title: title, poster: poster, season: season, ep: ep }  // Set pending media object with all provided parameters
        for (let i = 0; i < sourceModel.count; i++) sourceModel.setProperty(i, "status", "pending")  // Reset all source statuses to "pending" (not yet checked)
        addToWatchHistory({ imdbId: imdbId, title: title, poster: poster, type: type })              // Add this item to watch history
        window.sourceCheckOrder = buildSourceOrder()                                                // Build the ordered list of sources to check (preferred first)
        window.sourceCheckStep = 0                                                                  // Start at the first step (index 0)
        window.currentCheckIndex = window.sourceCheckOrder[0]                                       // Set current check index to first source in order
        window.foundSourceName = ""                                                                 // Reset found source name (none found yet)
        window.isSourceModalOpen = true                                                             // Show the source checking modal
        window.checkingState = "checking"                                                           // Set state to "checking" (actively checking sources)
        if (sourceListUI) sourceListUI.positionViewAtBeginning()                                    // If source list exists, scroll it to the top
        checkNextSource()                                                                           // Start checking the first source
        saveUiState()                                                                               // Save UI state (including modal open state) to cache
    }                                                                                            // End of startSourceCheck function

    function closeSourceModal() {                                                                  // Define function to close the source checking modal
        if (window.activeCheckXhr !== null) {                                                       // If there's an active XHR request
            try { window.activeCheckXhr.abort() } catch(e) {}                                        // Try to abort it (may fail if already completed, silently catch)
            window.activeCheckXhr = null                                                             // Clear the reference
        }                                                                                          // End of if
        window.isSourceModalOpen = false                                                            // Hide the source modal
        window.checkingState = "idle"                                                               // Reset checking state to idle
        if (window.currentView === "series") window.forceActiveFocus()                              // If in series view, focus the main window
        else searchInput.forceActiveFocus()                                                          // Otherwise focus the search input
        saveUiState()                                                                               // Save UI state (modal closed) to cache
    }                                                                                            // End of closeSourceModal function

    function skipToNextSource() {                                                                  // Define function to skip current source and try next one
        if (window.activeCheckXhr !== null) {                                                       // If there's an active XHR request
            try { window.activeCheckXhr.abort() } catch(e) {}                                        // Abort the current request (silently catch errors)
            window.activeCheckXhr = null                                                             // Clear the reference
        }                                                                                          // End of if
        sourceModel.setProperty(window.currentCheckIndex, "status", "failed")                       // Mark current source as failed in the model
        window.sourceCheckStep++                                                                    // Increment to next step
        if (window.sourceCheckStep < window.sourceCheckOrder.length) {                              // If there are more sources to check
            window.currentCheckIndex = window.sourceCheckOrder[window.sourceCheckStep]              // Set current index to next source in order
            window.checkingState = "checking"                                                       // Keep state as checking
            checkNextSource()                                                                        // Check the next source
        } else {                                                                                    // If no more sources
            window.checkingState = "failed_all"                                                     // Set state to failed_all (all sources exhausted)
        }                                                                                          // End of if-else
    }                                                                                            // End of skipToNextSource function

    function checkNextSource() {                                                                   // Define function to check the next source in order
        if (!window.isSourceModalOpen || window.checkingState !== "checking") return                 // Don't proceed if modal is closed or not in checking state
        if (window.sourceCheckStep >= window.sourceCheckOrder.length) {                             // If we've exhausted all sources
            window.checkingState = "failed_all"                                                     // Set state to failed_all
            return                                                                                  // Exit function
        }                                                                                          // End of if
        
        window.currentCheckIndex = window.sourceCheckOrder[window.sourceCheckStep]                  // Set current index to the source at current step
        sourceModel.setProperty(window.currentCheckIndex, "status", "checking")                      // Mark this source as "checking" in the model
        if (sourceListUI) sourceListUI.positionViewAtIndex(window.currentCheckIndex, ListView.Contain)  // Scroll source list to show current source
        
        let idx = window.currentCheckIndex                                                          // Capture current index for use in callback
        let step = window.sourceCheckStep                                                           // Capture current step for use in callback
        let url = buildSourceUrl(idx)                                                               // Build the URL for this source using IMDb ID/season/episode
        let xhr = new XMLHttpRequest()                                                              // Create new XMLHttpRequest object
        window.activeCheckXhr = xhr                                                                 // Store reference for potential abort
        
        xhr.open("GET", url, true)                                                                  // Open GET request to the source URL (asynchronous)
        xhr.timeout = 6000                                                                          // Set timeout to 6 seconds (6000ms)
        xhr.onreadystatechange = function() {                                                        // Define handler for request state changes
            if (xhr.readyState !== XMLHttpRequest.DONE || !window.isSourceModalOpen || window.checkingState !== "checking" || window.sourceCheckStep !== step) return  // Only process if request is complete, modal is open, still checking, and step hasn't changed
            window.activeCheckXhr = null                                                             // Clear active XHR reference (request is done)
            let code = xhr.status                                                                    // Get HTTP status code
            let body = xhr.responseText ? xhr.responseText.toLowerCase() : ""                        // Get response body as lowercase, or empty string if null
            
            if (code === 404 || code === 410) {                                                      // If HTTP 404 (not found) or 410 (gone)
                sourceModel.setProperty(idx, "status", "failed")                                     // Mark source as failed
                window.sourceCheckStep++                                                              // Move to next step
                checkNextSource()                                                                     // Check next source
                return                                                                                // Exit callback
            }                                                                                       // End of if
            if (code === 200 && body.length < 3000) {                                                // If status 200 but body is very short (< 3000 chars)
                let looksLikeError = false                                                            // Initialize error flag
                for (let i = 0; i < window.errorPagePatterns.length; i++) {                           // Loop through error page patterns
                    if (body.indexOf(window.errorPagePatterns[i]) !== -1) {                            // Check if any error pattern appears in body
                        looksLikeError = true                                                           // Set error flag
                        break                                                                           // Exit loop
                    }                                                                                 // End of if
                }                                                                                    // End of for loop
                if (looksLikeError) {                                                                 // If response looks like an error page
                    sourceModel.setProperty(idx, "status", "failed")                                   // Mark source as failed
                    window.sourceCheckStep++                                                            // Move to next step
                    checkNextSource()                                                                   // Check next source
                    return                                                                              // Exit callback
                }                                                                                    // End of if
            }                                                                                       // End of if
            let isLive = (code === 0) || (code >= 200 && code < 400) || code === 401 || code === 403  // Consider source live if: code 0 (CORS/no status), 2xx/3xx success, or 401/403 (auth required but endpoint exists)
            if (isLive) {                                                                            // If source appears to be live
                sourceModel.setProperty(idx, "status", "success")                                    // Mark source as successful
                window.foundSourceName = sourceModel.get(idx).name                                   // Store the name of the working source
                window.checkingState = "found"                                                       // Set state to found
                saveUiState()                                                                         // Save state (modal with found source) to cache
                Quickshell.execDetached(["xdg-open", url])                                            // Open the URL in default browser
            } else {                                                                                 // If source is not live
                sourceModel.setProperty(idx, "status", "failed")                                     // Mark source as failed
                window.sourceCheckStep++                                                              // Move to next step
                checkNextSource()                                                                     // Check next source
            }                                                                                        // End of if-else
        }                                                                                          // End of onreadystatechange
        xhr.ontimeout = function() {                                                                // Define handler for request timeout
            if (!window.isSourceModalOpen || window.checkingState !== "checking" || window.sourceCheckStep !== step) return  // Only process if still relevant
            window.activeCheckXhr = null                                                             // Clear XHR reference
            sourceModel.setProperty(idx, "status", "failed")                                         // Mark source as failed (timeout)
            window.sourceCheckStep++                                                                  // Move to next step
            checkNextSource()                                                                         // Check next source
        }                                                                                          // End of ontimeout
        xhr.onerror = function() {                                                                   // Define handler for network errors (CORS, DNS failure, etc.)
            if (!window.isSourceModalOpen || window.checkingState !== "checking" || window.sourceCheckStep !== step) return  // Only process if still relevant
            window.activeCheckXhr = null                                                             // Clear XHR reference
            sourceModel.setProperty(idx, "status", "success")                                        // On network error, assume source might work (CORS blocks XHR but browser may open fine)
            window.foundSourceName = sourceModel.get(idx).name                                       // Store source name
            window.checkingState = "found"                                                           // Set state to found
            saveUiState()                                                                             // Save state to cache
            Quickshell.execDetached(["xdg-open", url])                                                // Try opening URL in browser anyway
        }                                                                                          // End of onerror
        xhr.send()                                                                                   // Send the XMLHttpRequest
    }                                                                                            // End of checkNextSource function

    // --- DATA FETCHING & FILTERING ---                                                            // Comment header - marks data fetching and filtering section
    function fetchTrending(typeStr) {                                                                // Define function to fetch trending movies or TV shows
        let isMovie = typeStr === "movie"                                                            // Check if fetching movies (true) or TV (false)
        if (isMovie) window.isFetchingMovies = true; else window.isFetchingTv = true                // Set appropriate loading flag
        
        var xhr = new XMLHttpRequest()                                                              // Create new XMLHttpRequest
        xhr.open("GET", "https://v3-cinemeta.strem.io/catalog/" + typeStr + "/top.json")             // Open GET request to Stremio Cinemeta API for trending content
        xhr.onerror = function() { if (isMovie) window.isFetchingMovies = false; else window.isFetchingTv = false }  // On network error, clear loading flag
        xhr.onreadystatechange = function() {                                                        // Define handler for request state changes
            if (xhr.readyState !== XMLHttpRequest.DONE) return                                        // Wait until request is complete
            if (isMovie) window.isFetchingMovies = false; else window.isFetchingTv = false           // Clear loading flag when done
            if (xhr.status === 200) {                                                                 // If successful response
                try {                                                                                  // Try block for JSON parsing
                    let res = JSON.parse(xhr.responseText)                                             // Parse JSON response
                    if (res && res.metas) {                                                             // If response has metas array
                        let rawItems = []                                                                // Initialize array for raw items
                        let targetModel = isMovie ? cachedTrendingMovies : cachedTrendingTv             // Determine which model to populate
                        targetModel.clear()                                                              // Clear the target model
                        for (let i = 0; i < res.metas.length; i++) {                                     // Loop through all metadata items
                            let item = res.metas[i]                                                        // Get individual item
                            if (!item.id || !item.poster) continue                                         // Skip items without ID or poster (can't use them)
                            let entry = {                                                                  // Create entry object with standardized fields
                                imdbId: item.id,                                                             // Store IMDb ID
                                title: item.name || "Unknown",                                              // Store title, fallback to "Unknown"
                                poster: item.poster || item.posterShape || item.background || item.logo || "",  // Store poster URL with fallback chain
                                type: isMovie ? "movie" : "tv",                                             // Set type based on what we're fetching
                                year: item.releaseInfo || "N/A",                                            // Store release year/date, fallback to "N/A"
                                rating: item.imdbRating || 0,                                               // Store IMDb rating, fallback to 0
                                popularity: i                                                                // Store original position as popularity rank
                            }                                                                              // End of entry object
                            rawItems.push(entry)                                                            // Add entry to raw items array
                            targetModel.append(entry)                                                       // Append entry to display model
                        }                                                                                  // End of for loop
                        if (isMovie) { window.rawTrendingMovies = rawItems; window.trendingMoviesLastFetch = Date.now(); window.trendingMoviesLoaded = true }  // If movies: store raw data, update timestamp, mark as loaded
                        else { window.rawTrendingTv = rawItems; window.trendingTvLastFetch = Date.now(); window.trendingTvLoaded = true }                    // If TV: store raw data, update timestamp, mark as loaded
                        saveTrendingCache()                                                                // Save fetched data to cache
                    }                                                                                  // End of if
                } catch(e) {}                                                                         // Silently catch and ignore parse errors
            }                                                                                       // End of if
        }                                                                                          // End of onreadystatechange
        xhr.send()                                                                                   // Send the request
    }                                                                                            // End of fetchTrending function

    function getSortValue(item, field) {                                                             // Define helper function to extract sort value from an item
        if (field === "year") return parseInt(item.year || item.releaseInfo || 0) || 0               // For year field: parse year as integer, fallback to 0
        if (field === "title") return (item.title || item.name || "").toString()                      // For title field: get title string, fallback to empty string
        if (field === "rating") return parseFloat(item.rating || item.imdbRating || 0) || 0          // For rating field: parse rating as float, fallback to 0
        return 0                                                                                    // Default return 0 for unknown fields
    }                                                                                            // End of getSortValue function

    function sortItems(items) {                                                                     // Define function to sort an array of items based on current filter
        let mode = window.filterSort                                                                 // Get current sort/filter mode
        if (mode === "Year (Newest)") items.sort((a, b) => getSortValue(b, "year") - getSortValue(a, "year"))          // Sort by year descending (newest first)
        else if (mode === "Year (Oldest)") items.sort((a, b) => getSortValue(a, "year") - getSortValue(b, "year"))     // Sort by year ascending (oldest first)
        else if (mode === "Title (A-Z)") items.sort((a, b) => getSortValue(a, "title").localeCompare(getSortValue(b, "title")))   // Sort alphabetically A-Z
        else if (mode === "Title (Z-A)") items.sort((a, b) => getSortValue(b, "title").localeCompare(getSortValue(a, "title")))   // Sort alphabetically Z-A
        else if (mode === "Rating (Best)") items.sort((a, b) => getSortValue(b, "rating") - getSortValue(a, "rating"))     // Sort by rating descending (best first)
        else if (mode === "Rating (Worst)") items.sort((a, b) => getSortValue(a, "rating") - getSortValue(b, "rating"))    // Sort by rating ascending (worst first)
        return items                                                                                 // Return the sorted array
    }                                                                                            // End of sortItems function

    function applyFiltersToPopular() {                                                               // Define function to apply current sort to trending/popular items
        let rawMovies = sortItems(window.rawTrendingMovies.slice())                                   // Sort a copy of raw trending movies (slice() prevents mutating original)
        let rawTv = sortItems(window.rawTrendingTv.slice())                                           // Sort a copy of raw trending TV shows
        cachedTrendingMovies.clear(); for (let i = 0; i < rawMovies.length; i++) cachedTrendingMovies.append(rawMovies[i])  // Clear model and re-populate with sorted movies
        cachedTrendingTv.clear(); for (let i = 0; i < rawTv.length; i++) cachedTrendingTv.append(rawTv[i])              // Clear model and re-populate with sorted TV
        movieGrid.positionViewAtBeginning()                                                           // Scroll movie grid to top
        tvGrid.positionViewAtBeginning()                                                              // Scroll TV grid to top
    }                                                                                            // End of applyFiltersToPopular function

    function applyFiltersAndPopulate() {                                                              // Define function to apply filters to search results and populate model
        window.isKeyboardNav = false                                                                  // Reset keyboard navigation flag (sorting resets navigation state)
        searchResults.clear()                                                                         // Clear current search results model
        let items = sortItems(window.currentFetchResults.slice())                                      // Sort a copy of current fetch results
        for (let i = 0; i < items.length; i++) {                                                       // Loop through sorted items
            let item = items[i]                                                                         // Get each item
            if (!item.id) continue                                                                      // Skip items without ID
            searchResults.append({                                                                      // Append to search results model with standardized fields
                imdbId: item.id, title: item.name || "Unknown", poster: item.poster || "",              // Map ID, title, poster
                type: item.type === "series" ? "tv" : "movie", year: item.releaseInfo || "N/A", rating: item.imdbRating || 0  // Convert series type to "tv", map year and rating
            })                                                                                          // End of append
        }                                                                                             // End of for loop
        Qt.callLater(function() {                                                                      // Defer execution to next event loop cycle (ensures models are updated)
            if (searchGrid && searchGrid.count > 0) searchGrid.currentIndex = 0                        // Reset search grid selection to first item
            if (movieGrid && movieGrid.count > 0) movieGrid.currentIndex = 0                           // Reset movie grid selection
            if (tvGrid && tvGrid.count > 0) tvGrid.currentIndex = 0                                    // Reset TV grid selection
        })                                                                                            // End of Qt.callLater
    }                                                                                            // End of applyFiltersAndPopulate function

    function doSearch(query) {                                                                       // Define function to perform a search against the API
        let q = encodeURIComponent(query.trim())                                                      // URL-encode the trimmed search query
        let expectedType = window.mediaType                                                           // Capture current media type at time of search initiation
        let typeStr = expectedType === "movie" ? "movie" : "series"                                  // Convert media type to API parameter ("movie" or "series")
        if (q === "") { searchResults.clear(); window.isSearchingNetwork = false; return }             // If query is empty, clear results and exit
        addSearchHistory(query)                                                                       // Add this query to search history
        window.isSearchingNetwork = true                                                              // Set searching flag to show loading spinner
        searchResults.clear()                                                                         // Clear previous search results
        var xhr = new XMLHttpRequest()                                                                // Create new XMLHttpRequest
        xhr.open("GET", "https://v3-cinemeta.strem.io/catalog/" + typeStr + "/top/search=" + q + ".json")  // Open GET request to Cinemeta search API
        xhr.onerror = function() { window.isSearchingNetwork = false }                                 // On error, clear searching flag
        xhr.onreadystatechange = function() {                                                          // Define handler for state changes
            if (xhr.readyState !== XMLHttpRequest.DONE) return                                          // Wait until complete
            if (window.mediaType === expectedType) {                                                    // Only process if media type hasn't changed during request
                window.isSearchingNetwork = false                                                       // Clear searching flag
                if (xhr.status === 200) {                                                                // If successful
                    try {                                                                                // Try block for JSON parsing
                        let res = JSON.parse(xhr.responseText)                                            // Parse JSON response
                        if (res && res.metas) {                                                            // If metas array exists
                            window.currentFetchResults = res.metas                                          // Store raw results for sorting/filtering
                            applyFiltersAndPopulate()                                                       // Apply current sort filter and populate model
                            enrichSearchPosters(res.metas, typeStr)                                         // Fetch missing posters for results
                        }                                                                                 // End of if
                    } catch(e) {}                                                                        // Silently catch parse errors
                }                                                                                       // End of if
            }                                                                                          // End of if (media type check)
        }                                                                                            // End of onreadystatechange
        xhr.send()                                                                                     // Send the request
    }                                                                                            // End of doSearch function

    function enrichSearchPosters(metas, typeStr) {                                                    // Define function to fetch missing posters for search results
        for (let i = 0; i < metas.length; i++) {                                                       // Loop through all metadata items
            let item = metas[i]                                                                         // Get each item
            if (item.poster && item.poster !== "") continue                                              // Skip items that already have a poster
            let capturedImdbId = item.id                                                                // Capture IMDb ID in closure variable
            ;(function(cImdbId) {                                                                        // Immediately Invoked Function Expression (IIFE) to create closure for each ID
                var xhr2 = new XMLHttpRequest()                                                          // Create new XHR for metadata fetch
                xhr2.open("GET", "https://v3-cinemeta.strem.io/meta/" + typeStr + "/" + cImdbId + ".json")  // Fetch detailed metadata for this specific item
                xhr2.onreadystatechange = function() {                                                    // Handler for state changes
                    if (xhr2.readyState !== XMLHttpRequest.DONE) return                                    // Wait until complete
                    if (xhr2.status === 200) {                                                               // If successful
                        try {                                                                                // Try block for JSON parsing
                            let res2 = JSON.parse(xhr2.responseText)                                          // Parse metadata response
                            if (res2 && res2.meta) {                                                          // If meta object exists
                                let poster = res2.meta.poster || res2.meta.background || ""                     // Get poster or background URL
                                if (poster !== "") {                                                            // If a poster URL was found
                                    for (let j = 0; j < searchResults.count; j++) {                               // Loop through search results model
                                        if (searchResults.get(j).imdbId === cImdbId) {                              // Find the matching result by IMDb ID
                                            searchResults.setProperty(j, "poster", poster)                           // Update the poster property
                                            break                                                                   // Exit loop once found
                                        }                                                                         // End of if
                                    }                                                                           // End of for loop
                                    return                                                                      // Exit - poster found and updated
                                }                                                                             // End of if
                            }                                                                                 // End of if
                        } catch(e) {}                                                                        // Silently catch parse errors
                    }                                                                                       // End of if
                    fetchPosterFallback(cImdbId, typeStr)                                                     // If no poster found, try fallback source
                }                                                                                        // End of onreadystatechange
                xhr2.send()                                                                                // Send the metadata request
            })(capturedImdbId)                                                                          // Execute IIFE with captured IMDb ID
        }                                                                                            // End of for loop
    }                                                                                            // End of enrichSearchPosters function

    function fetchPosterFallback(imdbId, typeStr) {                                                   // Define function to try fallback poster source (RatingPosterDB)
        let rpdbUrl = "https://api.ratingposterdb.com/imdb/poster-default/" + imdbId + ".jpg"           // Build URL for RatingPosterDB API
        var xhrCheck = new XMLHttpRequest()                                                            // Create new XHR for HEAD request
        xhrCheck.open("HEAD", rpdbUrl, true)                                                           // Open HEAD request (only check if exists, don't download)
        xhrCheck.timeout = 5000                                                                        // Set 5 second timeout
        xhrCheck.onreadystatechange = function() {                                                       // Handler for state changes
            if (xhrCheck.readyState !== XMLHttpRequest.DONE) return                                       // Wait until complete
            if (xhrCheck.status === 200) {                                                                 // If poster exists (HTTP 200)
                for (let j = 0; j < searchResults.count; j++) {                                             // Loop through search results
                    if (searchResults.get(j).imdbId === imdbId) {                                            // Find matching result
                        searchResults.setProperty(j, "poster", rpdbUrl)                                        // Update poster URL
                        break                                                                                 // Exit loop once found
                    }                                                                                       // End of if
                }                                                                                          // End of for loop
            }                                                                                            // End of if
        }                                                                                             // End of onreadystatechange
        xhrCheck.onerror = function() { /* silently fail — delegate shows title fallback */ }            // On error, do nothing - UI will show title text instead
        xhrCheck.send()                                                                                 // Send the HEAD request
    }                                                                                            // End of fetchPosterFallback function

    function fetchAndUpdatePoster(imdbId, typeStr, targetModel) {                                     // Define function to fetch and update poster for a specific item
        var xhr = new XMLHttpRequest()                                                                // Create new XHR
        let metaType = typeStr === "tv" ? "series" : "movie"                                           // Convert type to API format ("series" or "movie")
        xhr.open("GET", "https://v3-cinemeta.strem.io/meta/" + metaType + "/" + imdbId + ".json")      // Fetch metadata for the specific item
        xhr.timeout = 6000                                                                            // Set 6 second timeout
        xhr.onreadystatechange = function() {                                                           // Handler for state changes
            if (xhr.readyState !== XMLHttpRequest.DONE) return                                           // Wait until complete
            let posterFound = ""                                                                         // Initialize found poster variable
            if (xhr.status === 200) {                                                                     // If successful
                try {                                                                                     // Try block for JSON parsing
                    let res = JSON.parse(xhr.responseText)                                                 // Parse response
                    if (res && res.meta) posterFound = res.meta.poster || res.meta.background || ""         // Get poster or background URL
                } catch(e) {}                                                                            // Silently catch parse errors
            }                                                                                           // End of if
            if (posterFound !== "") {                                                                    // If a poster URL was found
                for (let j = 0; j < targetModel.count; j++) {                                             // Loop through target model
                    if (targetModel.get(j).imdbId === imdbId) {                                            // Find matching item
                        targetModel.setProperty(j, "poster", posterFound)                                    // Update poster URL
                        break                                                                               // Exit loop
                    }                                                                                     // End of if
                }                                                                                        // End of for loop
            } else {                                                                                    // If no poster found
                fetchPosterFallback(imdbId, metaType)                                                     // Try the fallback poster source
            }                                                                                           // End of if-else
        }                                                                                             // End of onreadystatechange
        xhr.onerror = function() { fetchPosterFallback(imdbId, metaType) }                              // On error, try fallback poster source
        xhr.send()                                                                                      // Send the request
    }                                                                                            // End of fetchAndUpdatePoster function

    function fetchSeriesData(imdbId, targetSeason, title, poster, isReload) {                           // Define function to fetch TV series data (seasons, episodes)
        if (!isReload) {                                                                                 // If this is not a reload (initial load)
            window.selectedImdbId = imdbId                                                               // Store selected IMDb ID
            window.selectedTitle = title                                                                 // Store selected title
            window.selectedPoster = poster                                                               // Store selected poster
            window.selectedDescription = ""                                                              // Reset description
            window.currentView = "series"                                                                // Switch to series view
            window.forceActiveFocus()                                                                    // Focus main window for key navigation
        }                                                                                              // End of if
        window.isLoadingSeries = true                                                                  // Set loading flag
        seasonModel.clear()                                                                            // Clear seasons model
        episodeModel.clear()                                                                           // Clear episodes model

        var xhr = new XMLHttpRequest()                                                                 // Create new XHR
        xhr.open("GET", "https://v3-cinemeta.strem.io/meta/series/" + imdbId + ".json")                 // Fetch series metadata from Cinemeta API
        xhr.onerror = function() {                                                                      // On network error
            window.isLoadingSeries = false                                                               // Clear loading flag
            if (isReload && window.pendingSeriesFocusRestore) seriesFocusRestoreTimer.restart()           // If reloading and focus pending, restart focus timer
        }                                                                                             // End of onerror
        xhr.onreadystatechange = function() {                                                            // Handler for state changes
            if (xhr.readyState !== XMLHttpRequest.DONE) return                                            // Wait until complete
            window.isLoadingSeries = false                                                                // Clear loading flag
            if (xhr.status === 200) {                                                                      // If successful
                try {                                                                                      // Try block for JSON parsing
                    var res = JSON.parse(xhr.responseText)                                                  // Parse response
                    if (res && res.meta) {                                                                   // If meta object exists
                        if (!isReload || !window.selectedDescription) window.selectedDescription = res.meta.description || res.meta.synopsis || ""  // Set description if not already set
                        if ((!window.selectedPoster || window.selectedPoster === "") && res.meta.poster) window.selectedPoster = res.meta.poster    // Update poster if missing
                        
                        if (res.meta.videos) {                                                               // If videos (episodes) array exists
                            let seasonsMap = {}                                                               // Create empty object to map seasons to episodes
                            for (let i = 0; i < res.meta.videos.length; i++) {                                 // Loop through all videos/episodes
                                let v = res.meta.videos[i]                                                       // Get each video/episode
                                if (v.season === 0) continue                                                      // Skip season 0 (specials/extras)
                                if (!seasonsMap[v.season]) seasonsMap[v.season] = []                               // Initialize array for this season if not exists
                                let epTitle = v.name || v.title || null                                            // Get episode title from name or title field
                                if (epTitle && /^(episode\s*\d+|s\d+e\d+|ep\.?\s*\d+)$/i.test(epTitle.toLowerCase().trim())) epTitle = null  // If title is just "Episode 1" format, treat as no real title
                                seasonsMap[v.season].push({                                                       // Push episode object to season's array
                                    ep: v.episode,                                                                  // Store episode number
                                    title: epTitle || ("Episode " + v.episode),                                      // Use real title or fallback to "Episode X"
                                    hasRealTitle: epTitle !== null                                                    // Flag if this has a real descriptive title
                                })                                                                                 // End of episode object
                            }                                                                                     // End of for loop
                            let seasonKeys = Object.keys(seasonsMap).map(Number).sort((a, b) => a - b)              // Get season numbers as integers, sorted ascending
                            for (let i = 0; i < seasonKeys.length; i++) seasonModel.append({ seasonNum: seasonKeys[i] })  // Populate season model with season numbers
                            window.seriesDataMap = seasonsMap                                                      // Store the entire seasons/episodes map
                            
                            let newTargetSeason = (isReload && seasonsMap[targetSeason]) ? targetSeason : (seasonKeys[0] || 1)  // If reloading and target season exists, use it; otherwise use first season
                            window.currentSeason = newTargetSeason                                                // Set current season
                            updateEpisodes(newTargetSeason)                                                        // Update episode list for the season
                        }                                                                                        // End of if
                    }                                                                                          // End of if
                } catch(e) {}                                                                                 // Silently catch parse errors
            }                                                                                              // End of if
            if (isReload && window.pendingSeriesFocusRestore) seriesFocusRestoreTimer.restart()                // If reloading with pending focus, restart focus timer
            if (!isReload) saveUiState()                                                                      // If initial load, save UI state
        }                                                                                               // End of onreadystatechange
        xhr.send()                                                                                        // Send the request
    }                                                                                               // End of fetchSeriesData function

    function loadSeriesDetails(imdbId, title, poster) {                                                  // Convenience function to load series details (calls fetchSeriesData)
        fetchSeriesData(imdbId, 1, title, poster, false)                                                  // Fetch series data starting at season 1, not a reload
    }                                                                                               // End of loadSeriesDetails function

    function updateEpisodes(seasonNum) {                                                                // Define function to update episode list when season changes
        window.seasonSwitching = true                                                                   // Set season switching flag (triggers fade animation)
        seasonContentSwapTimer.targetSeason = seasonNum                                                 // Set target season on the swap timer
        seasonContentSwapTimer.restart()                                                                // Restart the swap timer (handles the actual swap after delay)
    }                                                                                               // End of updateEpisodes function

    Timer {                                                                                         // Define Timer for season content swapping (with animation delay)
        id: seasonContentSwapTimer                                                                    // Assign id "seasonContentSwapTimer"
        property int targetSeason: 1                                                                  // Property to store target season number
        interval: 220                                                                                 // 220ms delay before swapping content (allows fade-out animation)
        repeat: false                                                                                 // Fire only once
        onTriggered: {                                                                                // Handler when timer fires
            episodeModel.clear()                                                                       // Clear current episode model
            let eps = window.seriesDataMap[targetSeason]                                                // Get episodes for the target season from data map
            if (eps) {                                                                                  // If episodes exist for this season
                eps.sort((a, b) => a.ep - b.ep)                                                          // Sort episodes by episode number ascending
                for (let i = 0; i < eps.length; i++) {                                                    // Loop through sorted episodes
                    episodeModel.append({ epNum: eps[i].ep, epTitle: eps[i].title, hasRealTitle: eps[i].hasRealTitle || false })  // Append episode to model
                }                                                                                        // End of for loop
            }                                                                                          // End of if
            epList.currentIndex = 0                                                                     // Reset episode list selection to first episode
            epList.positionViewAtBeginning()                                                            // Scroll episode list to top
            seasonFadeInTimer.restart()                                                                 // Restart fade-in timer (shows episodes after swap)
        }                                                                                            // End of onTriggered
    }                                                                                               // End of seasonContentSwapTimer

    Timer { id: seasonFadeInTimer; interval: 30; repeat: false; onTriggered: window.seasonSwitching = false }  // Short timer to clear season switching flag, triggering fade-in animation

    function getActiveGrid() {                                                                        // Helper function to determine which grid is currently active
        if (window.isSearchMode) return searchGrid                                                     // If in search mode, return search grid
        if (window.mediaType === "movie") return movieGrid                                              // If movie type, return movie grid
        return tvGrid                                                                                   // Otherwise return TV grid
    }                                                                                               // End of getActiveGrid function

    // --- SHARED STYLES ---                                                                           // Comment header - marks shared UI component styles
    component CustomComboBox: ComboBox {                                                              // Define custom ComboBox component (reusable styled dropdown)
        id: control                                                                                    // Assign id "control" for internal reference
        font.family: "JetBrains Mono"; font.pixelSize: window.s(14)                                    // Set font to JetBrains Mono with scaled size 14
        delegate: ItemDelegate {                                                                       // Custom delegate for dropdown items
            width: control.width; height: window.s(36)                                                  // Set item width to ComboBox width, scaled height 36
            contentItem: Text { text: modelData || model.name; color: window.text; font: control.font; verticalAlignment: Text.AlignVCenter }  // Display text from model, vertically centered
            background: Rectangle { color: control.highlightedIndex === index ? window.surface1 : "transparent"; radius: window.s(10) }  // Highlight selected item with surface1 color, rounded corners
        }                                                                                             // End of delegate
        indicator: Canvas {                                                                            // Custom dropdown arrow indicator using Canvas
            id: canvas                                                                                  // Assign id "canvas"
            x: control.width - width - control.rightPadding; y: control.topPadding + (control.availableHeight - height) / 2  // Position at right side, vertically centered
            width: 12; height: 8; contextType: "2d"                                                      // Set size and 2D rendering context
            Connections { target: control; function onPressedChanged() { canvas.requestPaint() } }        // Repaint when ComboBox pressed state changes
            onPaint: { var ctx = canvas.getContext("2d"); ctx.reset(); ctx.moveTo(0, 0); ctx.lineTo(width, 0); ctx.lineTo(width / 2, height); ctx.fillStyle = window.subtext0; ctx.fill() }  // Draw triangle arrow pointing down
        }                                                                                             // End of indicator
        contentItem: Text { leftPadding: window.s(10); rightPadding: control.indicator.width + control.spacing; text: control.currentText; font: control.font; color: window.text; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }  // Display selected text with padding
        background: Rectangle { implicitWidth: window.s(180); implicitHeight: window.s(36); color: window.surface0; border.color: control.activeFocus ? window.surface2 : window.surface1; border.width: control.visualFocus ? 2 : 1; radius: window.s(10) }  // ComboBox background with border
        popup: Popup {                                                                                 // Custom popup for dropdown list
            y: control.height + window.s(4); width: control.width; implicitHeight: contentItem.implicitHeight; padding: window.s(4)  // Position below ComboBox, match width
            contentItem: ListView { clip: true; implicitHeight: contentHeight; model: control.popup.visible ? control.delegateModel : null; currentIndex: control.highlightedIndex; ScrollIndicator.vertical: ScrollIndicator { } }  // ListView for dropdown items with scroll indicator
            background: Rectangle { color: window.crust; border.color: window.surface1; radius: window.s(14) }  // Popup background with rounded corners
        }                                                                                             // End of popup
    }                                                                                               // End of CustomComboBox component

    component PosterDelegate: Rectangle {                                                             // Define PosterDelegate component (used in watch history horizontal list)
        width: window.s(120); height: width * 1.5                                                      // Set size with 2:3 aspect ratio (standard poster ratio)
        radius: window.s(10); color: window.crust; clip: true                                           // Rounded corners, crust background, clip child content
        property bool isHovered: posterMouse.containsMouse                                              // Property tracking mouse hover state
        Image {                                                                                        // Poster image
            id: posterImg                                                                               // Assign id "posterImg"
            anchors.fill: parent                                                                        // Fill entire parent rectangle
            source: model.poster !== "" ? model.poster : ""                                              // Set image source from model, empty if no poster
            fillMode: Image.PreserveAspectCrop                                                            // Crop to fill while preserving aspect ratio
            asynchronous: true                                                                           // Load image asynchronously (non-blocking)
            smooth: true                                                                                 // Enable smooth scaling
            cache: true                                                                                  // Cache loaded image
            sourceSize.width: window.s(240)                                                              // Set source size for memory efficiency (scaled)
            sourceSize.height: window.s(360)                                                             // Set source height for memory efficiency
            visible: status === Image.Ready                                                              // Only show when image is fully loaded
        }                                                                                             // End of Image
        Rectangle {                                                                                    // Fallback rectangle shown when no poster or image loading/error
            anchors.fill: parent                                                                        // Fill parent
            color: window.surface0                                                                      // Surface0 background color
            visible: model.poster === "" || posterImg.status === Image.Error || posterImg.status === Image.Null  // Show if no poster URL or image failed to load
            radius: window.s(10)                                                                        // Rounded corners
            Column {                                                                                    // Column layout for fallback content
                anchors.centerIn: parent                                                                 // Center in parent
                width: parent.width - window.s(10)                                                       // Width with margin
                spacing: window.s(6)                                                                     // Spacing between elements
                Text {                                                                                   // Media type emoji indicator
                    anchors.horizontalCenter: parent.horizontalCenter                                     // Center horizontally
                    text: model.type === "tv" ? "📺" : "🎬"                                                // TV emoji for TV shows, movie clapper for movies
                    font.pixelSize: window.s(22)                                                          // Emoji size
                }                                                                                       // End of Text
                Text {                                                                                   // Title text fallback
                    width: parent.width                                                                   // Full width of column
                    text: model.title || "Unknown"                                                        // Show title or "Unknown"
                    color: window.subtext0                                                                // Subtext0 color
                    font.family: "JetBrains Mono"                                                         // JetBrains Mono font
                    font.pixelSize: window.s(11)                                                           // Scaled font size
                    wrapMode: Text.WordWrap                                                               // Wrap long titles
                    horizontalAlignment: Text.AlignHCenter                                                // Center horizontally
                    maximumLineCount: 4                                                                   // Max 4 lines
                    elide: Text.ElideRight                                                                // Elide with ... at end if too long
                }                                                                                       // End of Text
            }                                                                                          // End of Column
        }                                                                                             // End of Rectangle (fallback)
        Rectangle {                                                                                    // Hover overlay rectangle
            anchors.fill: parent; radius: window.s(10)                                                   // Fill parent with same rounded corners
            color: window.mediaType === "tv" ? window.blue : window.mauve                                // Blue for TV, Mauve for movies
            opacity: parent.isHovered ? 0.3 : 0                                                          // 30% opacity on hover, transparent otherwise
            Behavior on opacity { NumberAnimation { duration: 200 } }                                    // Smooth opacity transition over 200ms
        }                                                                                             // End of Rectangle (overlay)
        MouseArea {                                                                                    // Mouse interaction area
            id: posterMouse; anchors.fill: parent; hoverEnabled: true                                    // Fill parent, enable hover detection
            onClicked: {                                                                                 // Click handler
                if (model.type === "movie") startSourceCheck("movie", model.imdbId, model.title, model.poster, 0, 0)  // If movie: start source check with 0 for season/ep
                else loadSeriesDetails(model.imdbId, model.title, model.poster)                           // If TV: load series details for season selection
            }                                                                                          // End of onClicked
        }                                                                                             // End of MouseArea
    }                                                                                               // End of PosterDelegate component

    Component {                                                                                      // Define dashboard header component (search history, watch history, section labels)
        id: dashboardHeaderComp                                                                       // Assign id "dashboardHeaderComp"
        Item {                                                                                        // Container item
            width: GridView.view.width                                                                 // Match the width of the parent GridView
            property bool hasSearch: searchHistoryModel.count > 0                                       // True if there are search history items
            property bool hasWatch: watchHistoryModel.count > 0                                         // True if there are watch history items
            readonly property real searchSectionH: hasSearch ? (window.s(16) + window.s(12) + window.s(32) + window.s(28)) : 0  // Calculate search section height if visible
            readonly property real watchSectionH: hasWatch ? (window.s(16) + window.s(12) + window.s(200) + window.s(28)) : 0    // Calculate watch history section height if visible
            readonly property real popularLabelH: window.s(16) + window.s(16)                            // Height for "Popular" label section
            height: searchSectionH + watchSectionH + popularLabelH                                       // Total header height = sum of visible sections
            Column {                                                                                    // Column layout for header sections
                width: parent.width                                                                      // Full width
                spacing: 0                                                                               // No spacing between sections (handled internally)
                Item {                                                                                   // Search history section container
                    width: parent.width                                                                   // Full width
                    height: parent.parent.searchSectionH                                                   // Dynamic height based on whether search history exists
                    visible: parent.parent.hasSearch                                                       // Only visible if search history has items
                    Column {                                                                               // Column for search history content
                        width: parent.width                                                                  // Full width
                        spacing: window.s(12)                                                                 // Spacing between label and list
                        Text {                                                                               // "Recent Searches" label
                            text: "Recent Searches"                                                             // Label text
                            color: window.text                                                                  // Text color
                            font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(16)  // Bold JetBrains Mono, scaled size
                        }                                                                                    // End of Text
                        ListView {                                                                           // Horizontal list of recent searches
                            width: parent.width; height: window.s(32)                                          // Full width, scaled height
                            orientation: ListView.Horizontal; spacing: window.s(8)                              // Horizontal layout with spacing
                            model: searchHistoryModel; clip: true; interactive: false                           // Use search history model, clip overflow, disable user scrolling
                            add: Transition {                                                                    // Animation when items are added
                                ParallelAnimation {                                                               // Run animations simultaneously
                                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400 }         // Fade in over 400ms
                                    NumberAnimation { property: "x"; from: -window.s(20); duration: 400; easing.type: Easing.OutQuart }  // Slide in from left over 400ms
                                }                                                                                // End of ParallelAnimation
                            }                                                                                  // End of add transition
                            remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 200 } }  // Fade out over 200ms when items are removed
                            displaced: Transition { NumberAnimation { property: "x"; duration: 300; easing.type: Easing.OutQuart } }  // Smoothly reposition items when others are removed
                            delegate: Rectangle {                                                               // Delegate for each search history item
                                width: queryText.width + window.s(35); height: window.s(32)                       // Dynamic width based on text + padding, fixed height
                                radius: window.s(8); color: window.surface0                                        // Rounded corners, surface0 background
                                border.color: histMouse.containsMouse ? window.surface2 : window.surface1          // Highlight border on hover
                                Text {                                                                             // Query text
                                    id: queryText; text: model.query; color: window.text                            // Display the search query text
                                    font.family: "JetBrains Mono"; font.pixelSize: window.s(13)                     // JetBrains Mono font, scaled size
                                    anchors.left: parent.left; anchors.leftMargin: window.s(10)                     // Left-aligned with margin
                                    anchors.verticalCenter: parent.verticalCenter                                   // Vertically centered
                                }                                                                                // End of Text
                                MouseArea {                                                                       // Click area for the whole item
                                    id: histMouse; anchors.fill: parent; hoverEnabled: true                         // Fill parent, enable hover
                                    onClicked: { searchInput.text = model.query; doSearch(model.query) }             // On click: fill search input and execute search
                                }                                                                                // End of MouseArea
                                Rectangle {                                                                       // Close/delete button
                                    width: window.s(20); height: window.s(20); radius: window.s(10)                // Small circle
                                    color: closeMouse.containsMouse ? window.surface1 : "transparent"               // Highlight on hover
                                    anchors.right: parent.right; anchors.rightMargin: window.s(5)                  // Positioned at right side
                                    anchors.verticalCenter: parent.verticalCenter                                  // Vertically centered
                                    Text { text: "×"; anchors.centerIn: parent; color: window.subtext0; font.pixelSize: window.s(14) }  // X symbol
                                    MouseArea {                                                                     // Click area for close button
                                        id: closeMouse; anchors.fill: parent; hoverEnabled: true                     // Fill button, enable hover
                                        onClicked: { searchHistoryModel.remove(index); window.saveHistory() }         // Remove item from model and save to cache
                                    }                                                                              // End of MouseArea
                                }                                                                                // End of Rectangle (close button)
                            }                                                                                  // End of delegate
                        }                                                                                    // End of ListView
                    }                                                                                      // End of Column
                }                                                                                        // End of Item (search history)
                Item {                                                                                   // Watch history section container
                    width: parent.width                                                                   // Full width
                    height: parent.parent.watchSectionH                                                    // Dynamic height based on watch history existence
                    visible: parent.parent.hasWatch                                                        // Only visible if watch history has items
                    Column {                                                                               // Column for watch history content
                        width: parent.width                                                                  // Full width
                        spacing: window.s(12)                                                                 // Spacing between label and list
                        Text {                                                                               // "Watch History" label
                            text: "Watch History"                                                               // Label text
                            color: window.text                                                                  // Text color
                            font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(16)  // Bold JetBrains Mono, scaled size
                        }                                                                                    // End of Text
                        ListView {                                                                           // Horizontal list of watch history items
                            width: parent.width; height: window.s(200)                                         // Full width, fixed height for poster row
                            orientation: ListView.Horizontal; spacing: window.s(15)                             // Horizontal with spacing
                            model: watchHistoryModel; clip: true                                                // Use watch history model, clip overflow
                            delegate: PosterDelegate {}                                                         // Use PosterDelegate for each item (defined above)
                            ScrollBar.horizontal: ScrollBar {                                                   // Horizontal scrollbar
                                active: true                                                                     // Always visible
                                contentItem: Rectangle { radius: window.s(2); color: window.surface2 }            // Styled scrollbar thumb
                            }                                                                                  // End of ScrollBar
                        }                                                                                    // End of ListView
                    }                                                                                      // End of Column
                }                                                                                        // End of Item (watch history)
                Item {                                                                                   // Popular section label container
                    width: parent.width                                                                   // Full width
                    height: parent.parent.popularLabelH                                                    // Fixed height for label section
                    Text {                                                                                 // "Popular Movies" or "Popular TV Shows" label
                        anchors.top: parent.top; anchors.topMargin: window.s(4)                               // Positioned at top with margin
                        text: window.mediaType === "movie" ? "Popular Movies" : "Popular TV Shows"            // Dynamic label based on media type
                        color: window.text                                                                   // Text color
                        font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(16)   // Bold JetBrains Mono, scaled size
                    }                                                                                     // End of Text
                }                                                                                        // End of Item (popular label)
            }                                                                                          // End of Column
        }                                                                                             // End of Item (dashboardHeaderComp)
    }                                                                                               // End of Component

    // --- UI LAYOUT ---                                                                                // Comment header - marks main UI layout section
    Rectangle {                                                                                      // Main background rectangle for the entire widget
        id: mainBg                                                                                    // Assign id "mainBg"
        width: parent.width; height: parent.height                                                     // Fill the entire parent item
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter                // Anchored to bottom center of parent
        radius: window.s(14)                                                                           // Rounded corners with scaled radius
        color: Qt.rgba(window.base.r, window.base.g, window.base.b, 0.95)                               // Semi-transparent base color (95% opacity)
        border.color: Qt.rgba(window.text.r, window.text.g, window.text.b, 0.08)                        // Very subtle border with 8% opacity text color
        border.width: 1                                                                                 // 1px border width
        clip: true                                                                                      // Clip child content to rounded rectangle bounds
        transform: Translate { y: (1 - window.introPhase) * window.s(50) }                               // Slide up animation: starts 50px down, moves to 0 as introPhase goes to 1
        opacity: window.introPhase                                                                      // Fade in from 0 to 1 as introPhase animates
        ColumnLayout {                                                                                 // Main column layout for search view content
            anchors.fill: parent                                                                        // Fill the main background
            spacing: 0                                                                                   // No spacing between layout items
            visible: window.currentView === "search"                                                      // Only visible when in search view
            Rectangle {                                                                                  // Header area for search bar and controls
                Layout.alignment: Qt.AlignTop; Layout.fillWidth: true; Layout.preferredHeight: window.s(120); color: "transparent"  // Align to top, full width, scaled height, transparent
                ColumnLayout {                                                                             // Column layout for header content
                    anchors.fill: parent; anchors.margins: window.s(15); spacing: window.s(10)                // Fill with margins, spacing between rows
                    RowLayout {                                                                              // Row for media type toggle and filter dropdown
                        Layout.fillWidth: true; spacing: window.s(15)                                          // Full width, spacing between elements
                        Rectangle {                                                                           // Media type toggle (Movies/TV Shows)
                            Layout.preferredWidth: window.s(200); Layout.preferredHeight: window.s(36); radius: window.s(10); color: window.surface0  // Fixed width, height, rounded, surface0 background
                            Rectangle {                                                                         // Animated highlight for active tab
                                id: tabHighlight                                                                  // Assign id "tabHighlight"
                                width: parent.width / 2 - window.s(4); height: parent.height - window.s(8)         // Half width minus padding, full height minus padding
                                y: window.s(4); radius: window.s(8); color: window.mediaType === "movie" ? window.mauve : window.blue; z: 0  // Positioned with padding, mauve for movies/blue for TV
                                property real targetX: window.mediaType === "movie" ? window.s(4) : (parent.width / 2)  // Target X position: left for movies, right for TV
                                property real actualX: targetX                                                    // Actual X position (used for animation)
                                Behavior on actualX { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }  // Smooth animation to target position over 300ms
                                x: actualX                                                                        // Bind x position to actualX (animated property)
                            }                                                                                  // End of tabHighlight
                            RowLayout {                                                                         // Row for the two tab buttons
                                anchors.fill: parent; spacing: 0                                                   // Fill parent, no spacing
                                MouseArea {                                                                        // Movies tab click area
                                    Layout.fillWidth: true; Layout.fillHeight: true                                 // Fill half of the row
                                    onClicked: { window.mediaType = "movie"; if (searchInput.text !== "") doSearch(searchInput.text) }  // Set type to movie, re-search if text exists
                                    Text { anchors.centerIn: parent; text: "Movies"; font.family: "JetBrains Mono"; font.weight: window.mediaType === "movie" ? Font.Bold : Font.Medium; font.pixelSize: window.s(13); color: window.mediaType === "movie" ? window.crust : window.text }  // Movies label - bold when active
                                }                                                                                // End of MouseArea
                                MouseArea {                                                                        // TV Shows tab click area
                                    Layout.fillWidth: true; Layout.fillHeight: true                                 // Fill half of the row
                                    onClicked: { window.mediaType = "tv"; if (searchInput.text !== "") doSearch(searchInput.text) }  // Set type to tv, re-search if text exists
                                    Text { anchors.centerIn: parent; text: "TV Shows"; font.family: "JetBrains Mono"; font.weight: window.mediaType === "tv" ? Font.Bold : Font.Medium; font.pixelSize: window.s(13); color: window.mediaType === "tv" ? window.crust : window.text }  // TV Shows label - bold when active
                                }                                                                                // End of MouseArea
                            }                                                                                  // End of RowLayout
                        }                                                                                    // End of Rectangle (toggle)
                        Item { Layout.fillWidth: true }                                                         // Spacer item - fills remaining space, pushes filter to right
                        CustomComboBox {                                                                        // Sort/filter dropdown (custom component defined above)
                            id: filterSelector                                                                    // Assign id "filterSelector"
                            Layout.preferredWidth: window.s(180)                                                  // Fixed width
                            model: ["Default", "Year (Newest)", "Year (Oldest)", "Title (A-Z)", "Title (Z-A)", "Rating (Best)", "Rating (Worst)"]  // Sort options
                            onActivated: {                                                                        // When a sort option is selected
                                window.filterSort = currentText                                                     // Update the filter sort property
                                applyFiltersAndPopulate()                                                           // Apply sort to search results
                                applyFiltersToPopular()                                                              // Apply sort to trending items
                            }                                                                                    // End of onActivated
                        }                                                                                      // End of CustomComboBox
                    }                                                                                        // End of RowLayout
                    TextField {                                                                               // Search input field
                        id: searchInput                                                                         // Assign id "searchInput"
                        Layout.fillWidth: true; Layout.preferredHeight: window.s(42)                              // Full width, scaled height
                        background: Rectangle {                                                                  // Custom background rectangle
                            color: searchInput.activeFocus ? Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.6) : window.surface0  // Semi-transparent surface1 when focused, surface0 otherwise
                            radius: window.s(10); border.color: searchInput.activeFocus ? window.surface2 : "transparent"  // Rounded corners, border when focused
                            Behavior on color { ColorAnimation { duration: 200 } }                                 // Smooth color transition on focus
                        }                                                                                      // End of background
                        color: window.text; font.family: "JetBrains Mono"; font.pixelSize: window.s(15); leftPadding: window.s(15)  // Text color, font, size, left padding
                        placeholderText: "Search"                                                                // Placeholder text when empty
                        placeholderTextColor: window.subtext0; verticalAlignment: TextInput.AlignVCenter         // Placeholder color, vertical center alignment
                        onTextChanged: {                                                                         // Handler when text changes
                            if (text.trim() === "") { searchResults.clear(); window.isSearchingNetwork = false; searchDebounceTimer.stop() }  // If empty: clear results, stop searching
                            else searchDebounceTimer.restart()                                                    // Otherwise restart debounce timer (delays search until typing stops)
                        }                                                                                      // End of onTextChanged
                        Keys.onRightPressed: {                                                                   // Right arrow key in search field
                            window.isKeyboardNav = true; keyboardNavTimer.restart()                                // Enable keyboard nav mode, restart timer
                            let g = getActiveGrid()                                                                // Get current active grid
                            if (g && g.count > 0 && g.currentIndex < g.count - 1) g.currentIndex++                 // Move selection right if possible
                            event.accepted = true                                                                  // Mark event as handled
                        }                                                                                       // End of Keys.onRightPressed
                        Keys.onLeftPressed: {                                                                    // Left arrow key in search field
                            window.isKeyboardNav = true; keyboardNavTimer.restart()                                // Enable keyboard nav mode                            let g = getActiveGrid()                                                                // Get active grid
                            if (g && g.count > 0 && g.currentIndex > 0) g.currentIndex--                           // Move selection left if possible
                            event.accepted = true                                                                  // Mark event as handled
                        }                                                                                       // End of Keys.onLeftPressed
                        Keys.onDownPressed: {                                                                    // Down arrow key in search field
                            window.isKeyboardNav = true; keyboardNavTimer.restart()                                // Enable keyboard nav mode
                            let g = getActiveGrid()                                                                // Get active grid
                            if (g && g.count > 0) {                                                                // If grid has items
                                let columns = Math.max(1, Math.floor(g.width / g.cellWidth))                         // Calculate number of columns in grid
                                if (g.currentIndex + columns < g.count) g.currentIndex += columns                    // Move down by one row (skip columns items)
                            }                                                                                     // End of if
                            event.accepted = true                                                                  // Mark event as handled
                        }                                                                                       // End of Keys.onDownPressed
                        Keys.onUpPressed: {                                                                      // Up arrow key in search field
                            window.isKeyboardNav = true; keyboardNavTimer.restart()                                // Enable keyboard nav mode
                            let g = getActiveGrid()                                                                // Get active grid
                            if (g && g.count > 0) {                                                                // If grid has items
                                let columns = Math.max(1, Math.floor(g.width / g.cellWidth))                         // Calculate number of columns
                                if (g.currentIndex - columns >= 0) g.currentIndex -= columns                         // Move up by one row
                            }                                                                                     // End of if
                            event.accepted = true                                                                  // Mark event as handled
                        }                                                                                       // End of Keys.onUpPressed
                        Keys.onTabPressed: { window.mediaType = window.mediaType === "movie" ? "tv" : "movie"; if (text.trim() !== "") doSearch(text); event.accepted = true }  // Tab toggles media type and re-searches
                        Keys.onBacktabPressed: { window.mediaType = window.mediaType === "movie" ? "tv" : "movie"; if (text.trim() !== "") doSearch(text); event.accepted = true }  // Shift+Tab also toggles media type
                        Keys.onReturnPressed: {                                                                  // Enter/Return key in search field
                            if (text.trim() !== "" && searchResults.count === 0 && !window.isSearchingNetwork) {    // If text exists but no results and not currently searching
                                doSearch(text)                                                                       // Force a search
                            } else if (window.isKeyboardNav) {                                                      // If in keyboard navigation mode
                                let g = getActiveGrid()                                                               // Get active grid
                                if (g && g.count > 0 && g.currentIndex >= 0 && g.currentIndex < g.count) {             // If grid has valid selection
                                    let item = g.model.get(g.currentIndex)                                              // Get the selected item
                                    if (item) {                                                                         // If item exists
                                        if (item.type === "movie") startSourceCheck("movie", item.imdbId, item.title, item.poster, 0, 0)  // If movie: start source check
                                        else loadSeriesDetails(item.imdbId, item.title, item.poster)                       // If TV: load series details
                                    }                                                                                  // End of if
                                }                                                                                    // End of if
                            }                                                                                      // End of if
                            event.accepted = true                                                                  // Mark event as handled
                        }                                                                                       // End of Keys.onReturnPressed
                    }                                                                                        // End of TextField
                }                                                                                          // End of ColumnLayout
            }                                                                                            // End of Rectangle (header)
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5) }  // Horizontal divider line
            Item {                                                                                       // Content area for grid views
                Layout.fillWidth: true; Layout.fillHeight: true                                             // Fill remaining space
                Rectangle {                                                                                // Loading overlay
                    anchors.fill: parent                                                                     // Cover entire content area
                    color: Qt.rgba(window.base.r, window.base.g, window.base.b, 0.8)                          // Semi-transparent base color overlay
                    visible: window.isSearchingNetwork || (!window.isSearchMode && window.isLoadingPopular)    // Show when searching or loading trending
                    z: 10                                                                                     // Ensure it's above grids
                    ColumnLayout {                                                                           // Centered loading indicator
                        anchors.centerIn: parent; spacing: window.s(15)                                        // Center in parent, spacing between elements
                        Item {                                                                                 // Spinning loader animation
                            Layout.alignment: Qt.AlignHCenter                                                    // Center horizontally
                            width: window.s(34); height: window.s(34)                                             // Size of spinner
                            property real spinAngle: 0                                                             // Property for rotation angle
                            NumberAnimation on spinAngle {                                                         // Continuous rotation animation
                                from: 0; to: 360; duration: 900                                                    // Full rotation every 900ms
                                loops: Animation.Infinite; running: true                                            // Loop forever while loading
                                easing.type: Easing.Linear                                                          // Linear easing for constant speed
                            }                                                                                     // End of NumberAnimation
                            Canvas {                                                                              // Canvas to draw spinner arc
                                anchors.fill: parent                                                                // Fill parent
                                property real angle: parent.spinAngle                                                // Bind to parent's spin angle
                                onAngleChanged: requestPaint()                                                       // Request redraw when angle changes
                                onPaint: {                                                                          // Paint handler
                                    var ctx = getContext("2d")                                                        // Get 2D context
                                    ctx.reset()                                                                       // Reset canvas state
                                    var cx = width / 2, cy = height / 2, r = width / 2 - 3                            // Calculate center and radius
                                    var startRad = (parent.spinAngle - 90) * Math.PI / 180                             // Convert start angle to radians (offset -90 degrees)
                                    var endRad = startRad + 1.7 * Math.PI                                              // End angle is 1.7π radians (about 306 degrees) from start
                                    ctx.beginPath()                                                                   // Begin drawing path
                                    ctx.arc(cx, cy, r, startRad, endRad)                                              // Draw arc from start to end
                                    ctx.strokeStyle = window.mauve                                                    // Mauve color for spinner
                                    ctx.lineWidth = 3                                                                 // Line width
                                    ctx.lineCap = "round"                                                             // Rounded line caps
                                    ctx.stroke()                                                                      // Render the stroke
                                }                                                                                   // End of onPaint
                            }                                                                                     // End of Canvas
                        }                                                                                       // End of Item
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Loading..."; color: window.text; font.family: "JetBrains Mono"; font.pixelSize: window.s(14) }  // "Loading..." text
                    }                                                                                         // End of ColumnLayout
                }                                                                                           // End of Rectangle (loading overlay)
                Item {                                                                                     // Container for grid views
                    anchors.fill: parent; anchors.margins: window.s(15); visible: !window.isSearchingNetwork  // Fill parent with margin, visible when not searching network
                    Component {                                                                              // Grid highlight component (keyboard selection indicator)
                        id: gridHighlightComp                                                                  // Assign id "gridHighlightComp"
                        Item {                                                                                 // Highlight item
                            z: 0                                                                                 // Below grid items
                            Rectangle {                                                                          // Highlight rectangle
                                color: window.surface0; border.color: window.surface1; border.width: 1; radius: window.s(10)  // Surface0 fill, surface1 border, rounded
                                property real actX: parent.GridView.view.currentItem ? parent.GridView.view.currentItem.x + window.s(5) : 0  // X position tracks current item with offset
                                property real actY: parent.GridView.view.currentItem ? parent.GridView.view.currentItem.y + window.s(5) : 0  // Y position tracks current item with offset
                                x: actX; y: actY; width: parent.GridView.view.cellWidth - window.s(10); height: parent.GridView.view.cellHeight - window.s(10)  // Position and size based on current item
                                Behavior on actX { enabled: window.isKeyboardNav; NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }  // Smooth X animation when keyboard navigating
                                Behavior on actY { enabled: window.isKeyboardNav; NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }  // Smooth Y animation when keyboard navigating
                                opacity: parent.GridView.view.count > 0 && parent.GridView.view.currentIndex >= 0 ? 1 : 0  // Visible when grid has items and valid selection
                                Behavior on opacity { NumberAnimation { duration: 300 } }                        // Smooth opacity transition
                            }                                                                                  // End of Rectangle
                        }                                                                                    // End of Item
                    }                                                                                      // End of Component (gridHighlightComp)
                    Component {                                                                              // Grid item delegate component
                        id: mediaGridDelegate                                                                   // Assign id "mediaGridDelegate"
                        Item {                                                                                 // Delegate item
                            width: GridView.view.cellWidth; height: GridView.view.cellHeight; z: 1                // Match grid cell size, z-index above highlight
                            Rectangle {                                                                          // Container for delegate content
                                anchors.fill: parent; anchors.margins: window.s(5); radius: window.s(10); color: "transparent"  // Fill with margin, transparent background
                                property bool isActive: index === parent.parent.GridView.view.currentIndex         // True if this item is the current selection
                                ColumnLayout {                                                                     // Column layout for poster and text
                                    anchors.fill: parent; anchors.margins: window.s(10); spacing: window.s(8)        // Fill with inner margin, spacing between elements
                                    Rectangle {                                                                      // Poster image container
                                        Layout.fillWidth: true; Layout.fillHeight: true; radius: window.s(8); color: window.crust; clip: true  // Fill space, crust background, rounded, clip
                                        scale: parent.parent.isActive && window.isKeyboardNav ? 1.03 : 1.0             // Slightly scale up (3%) when active and keyboard navigating
                                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }  // Smooth scale animation with overshoot
                                        Image {                                                                        // Poster image
                                            id: gridImage                                                               // Assign id "gridImage"
                                            anchors.fill: parent                                                        // Fill parent rectangle
                                            source: model.poster !== "" ? model.poster : ""                               // Set source from model, empty if no poster
                                            fillMode: Image.PreserveAspectCrop                                            // Crop to fill while preserving aspect ratio
                                            asynchronous: true; smooth: true; cache: true                                  // Async loading, smooth, cached
                                            visible: status === Image.Ready                                                // Only show when fully loaded
                                        }                                                                              // End of Image
                                        Rectangle {                                                                      // Fallback when no poster
                                            anchors.fill: parent; color: window.surface0                                   // Fill, surface0 background
                                            visible: model.poster === "" || gridImage.status === Image.Error || gridImage.status === Image.Loading  // Show if no poster or loading/error
                                            radius: window.s(8)                                                            // Rounded corners
                                            property bool isLoading: model.poster !== "" && gridImage.status === Image.Loading  // True if poster URL exists but still loading
                                            Rectangle {                                                                      // Shimmer/skeleton loading effect
                                                anchors.fill: parent; radius: window.s(8); color: "transparent"                // Fill, transparent, rounded
                                                visible: parent.isLoading                                                      // Only show during loading
                                                Rectangle {                                                                      // Shimmer bar
                                                    width: parent.width * 0.4; height: parent.height                              // 40% width, full height
                                                    color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.4)  // Semi-transparent surface1
                                                    property real shimX: -parent.parent.width                                      // Start position (off left edge)
                                                    x: shimX                                                                       // Bind x position
                                                    NumberAnimation on shimX {                                                     // Shimmer animation
                                                        from: -parent.parent.width                                                  // Start from left edge
                                                        to: parent.parent.width * 1.5                                                // Move to right past edge
                                                        duration: 1200; loops: Animation.Infinite                                     // 1.2s per cycle, loop forever
                                                        running: parent.parent.parent.isLoading                                      // Run only while loading
                                                        easing.type: Easing.InOutSine                                                // Smooth sine easing
                                                    }                                                                              // End of NumberAnimation
                                                }                                                                              // End of Rectangle (shimmer bar)
                                            }                                                                              // End of Rectangle (shimmer container)
                                            Text { anchors.centerIn: parent; width: parent.width - window.s(10); text: model.title || "Unknown"; color: window.subtext0; font.family: "JetBrains Mono"; font.pixelSize: window.s(12); wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; visible: !parent.isLoading }  // Title text fallback when not loading
                                        }                                                                              // End of Rectangle (fallback)
                                        Rectangle {                                                                      // Active item overlay
                                            anchors.fill: parent; radius: window.s(8)                                       // Fill poster area, rounded
                                            color: window.mediaType === "tv" ? window.blue : window.mauve                    // Blue for TV, mauve for movies
                                            opacity: parent.parent.isActive ? 0.2 : 0                                         // 20% opacity when active, transparent otherwise
                                            Behavior on opacity { NumberAnimation { duration: 200 } }                         // Smooth opacity transition
                                        }                                                                              // End of Rectangle (overlay)
                                    }                                                                                // End of Rectangle (poster)
                                    Text {                                                                           // Title text below poster
                                        Layout.fillWidth: true; text: model.title; font.family: "JetBrains Mono"; font.pixelSize: window.s(12); font.weight: Font.Bold  // Full width, title, font settings
                                        color: parent.parent.isActive ? window.text : window.subtext0                   // Brighter when active
                                        wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight; lineHeight: 1.1; horizontalAlignment: Text.AlignHCenter  // Word wrap, max 2 lines, elide, centered
                                        Behavior on color { ColorAnimation { duration: 200 } }                            // Smooth color transition
                                    }                                                                                // End of Text
                                    Text { Layout.fillWidth: true; text: model.year !== "N/A" ? model.year : ""; font.family: "JetBrains Mono"; font.pixelSize: window.s(11); color: window.surface2; horizontalAlignment: Text.AlignHCenter; visible: text !== "" }  // Year text, hidden if N/A
                                }                                                                                  // End of ColumnLayout
                                MouseArea {                                                                         // Mouse interaction for grid item
                                    anchors.fill: parent; hoverEnabled: true                                           // Fill item, enable hover
                                    onEntered: { window.isKeyboardNav = false; parent.parent.GridView.view.currentIndex = index }  // On hover: disable keyboard nav, set this item as current
                                    onClicked: {                                                                       // On click:
                                        if (model.type === "movie") startSourceCheck("movie", model.imdbId, model.title, model.poster, 0, 0)  // If movie: start source check
                                        else loadSeriesDetails(model.imdbId, model.title, model.poster)                   // If TV: load series details
                                    }                                                                                // End of onClicked
                                }                                                                                  // End of MouseArea
                            }                                                                                    // End of Rectangle (container)
                        }                                                                                      // End of Item (delegate)
                    }                                                                                        // End of Component (mediaGridDelegate)
                    GridView {                                                                               // Search results grid
                        id: searchGrid                                                                         // Assign id "searchGrid"
                        anchors.fill: parent; visible: window.isSearchMode                                      // Fill parent, visible when searching
                        model: searchResults; cellWidth: Math.floor(width / 5); cellHeight: cellWidth * 1.5 + window.s(60)  // Search results model, 5 columns, cell height includes text
                        boundsBehavior: Flickable.StopAtBounds; highlightFollowsCurrentItem: false; clip: true    // Stop at bounds, manual highlight, clip
                        ScrollBar.vertical: ScrollBar { active: true; contentItem: Rectangle { radius: window.s(2); color: window.surface2 } }  // Vertical scrollbar, always visible
                        Behavior on contentY { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }   // Smooth vertical scrolling
                        add: Transition { ParallelAnimation { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutQuart } NumberAnimation { property: "y"; from: y + window.s(30); duration: 500; easing.type: Easing.OutQuart } NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: 500; easing.type: Easing.OutBack } } }  // Add animation: fade in, slide up, scale up
                        highlight: gridHighlightComp; delegate: mediaGridDelegate                               // Use highlight and delegate components defined above
                    }                                                                                        // End of GridView (search)
                    GridView {                                                                               // Trending movies grid
                        id: movieGrid                                                                          // Assign id "movieGrid"
                        anchors.fill: parent; visible: !window.isSearchMode && window.mediaType === "movie"      // Visible when not searching and movie type selected
                        model: cachedTrendingMovies; cellWidth: Math.floor(width / 10); cellHeight: cellWidth * 1.5 + window.s(60)  // Trending movies model, 10 columns for smaller items
                        header: dashboardHeaderComp; boundsBehavior: Flickable.StopAtBounds; highlightFollowsCurrentItem: false; clip: true  // Header with search/watch history, stop at bounds
                        ScrollBar.vertical: ScrollBar { active: true; contentItem: Rectangle { radius: window.s(2); color: window.surface2 } }  // Vertical scrollbar
                        Behavior on contentY { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }   // Smooth scrolling
                        highlight: gridHighlightComp; delegate: mediaGridDelegate                               // Use same highlight and delegate
                    }                                                                                        // End of GridView (movies)
                    GridView {                                                                               // Trending TV shows grid
                        id: tvGrid                                                                             // Assign id "tvGrid"
                        anchors.fill: parent; visible: !window.isSearchMode && window.mediaType === "tv"         // Visible when not searching and TV type selected
                        model: cachedTrendingTv; cellWidth: Math.floor(width / 10); cellHeight: cellWidth * 1.5 + window.s(60)  // Trending TV model, 10 columns
                        header: dashboardHeaderComp; boundsBehavior: Flickable.StopAtBounds; highlightFollowsCurrentItem: false; clip: true  // Header with history
                        ScrollBar.vertical: ScrollBar { active: true; contentItem: Rectangle { radius: window.s(2); color: window.surface2 } }  // Vertical scrollbar
                        Behavior on contentY { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }   // Smooth scrolling
                        highlight: gridHighlightComp; delegate: mediaGridDelegate                               // Same highlight and delegate
                    }                                                                                        // End of GridView (TV)
                }                                                                                          // End of Item (grid container)
            }                                                                                            // End of Item (content area)
        }                                                                                              // End of ColumnLayout (search view)
        // ==========================================                                                 // Decorative separator
        // SERIES VIEW                                                                                  // Section header - marks TV series detail view
        // ==========================================                                                 // Decorative separator
        RowLayout {                                                                                    // Row layout for series detail view (poster + episode list)
            anchors.fill: parent; anchors.margins: window.s(20); spacing: window.s(25)                    // Fill with margins, spacing between columns
            visible: window.currentView === "series"                                                       // Only visible in series view
            ColumnLayout {                                                                               // Left column: poster and series info
                Layout.preferredWidth: window.s(220); Layout.minimumWidth: window.s(220); Layout.maximumWidth: window.s(220)  // Fixed width column
                Layout.fillHeight: true; spacing: window.s(12)                                              // Fill height, spacing between elements
                Rectangle {                                                                                // Poster image container
                    Layout.fillWidth: true; Layout.preferredHeight: window.s(300); radius: window.s(14); color: window.crust; clip: true  // Full width, fixed height, rounded, clip
                    Image {                                                                                  // Series poster
                        anchors.fill: parent                                                                   // Fill container
                        source: window.selectedPoster !== "" ? window.selectedPoster : ""                       // Selected poster URL or empty
                        fillMode: Image.PreserveAspectCrop                                                      // Crop to fill
                        asynchronous: true; smooth: true; cache: true                                            // Async, smooth, cached
                        sourceSize.width: window.s(440); sourceSize.height: window.s(600)                       // Source size for memory efficiency
                        visible: status === Image.Ready                                                          // Only show when loaded
                    }                                                                                       // End of Image
                    Rectangle {                                                                              // Poster fallback (no image)
                        anchors.fill: parent; color: window.surface0; radius: window.s(14)                      // Fill, surface0, rounded
                        visible: window.selectedPoster === "" || parent.children[0].status === Image.Error || parent.children[0].status === Image.Loading  // Show if no poster or error/loading
                        Text { anchors.centerIn: parent; width: parent.width - window.s(10); text: window.selectedTitle; color: window.subtext0; font.family: "JetBrains Mono"; font.pixelSize: window.s(14); wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter }  // Title text fallback
                    }                                                                                       // End of Rectangle
                }                                                                                         // End of Rectangle (poster)
                Text {                                                                                     // Series title
                    Layout.fillWidth: true; text: window.selectedTitle                                        // Full width, selected title
                    font.family: "JetBrains Mono"; font.pixelSize: window.s(16); font.weight: Font.Bold       // Bold, scaled size
                    color: window.text; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter       // Text color, word wrap, centered
                    maximumLineCount: 3; elide: Text.ElideRight                                               // Max 3 lines, elide if longer
                }                                                                                         // End of Text
                Flickable {                                                                                // Scrollable description area
                    Layout.fillWidth: true                                                                   // Full width
                    Layout.preferredHeight: Math.min(window.s(120), descText.implicitHeight + window.s(8))     // Height limited to 120 or content height
                    Layout.maximumHeight: window.s(120)                                                       // Maximum height
                    visible: window.selectedDescription !== ""                                                 // Only visible if description exists
                    clip: true; contentHeight: descText.implicitHeight                                         // Clip content, set content height to text height
                    ScrollBar.vertical: ScrollBar { contentItem: Rectangle { radius: window.s(2); color: window.surface2; implicitWidth: window.s(3) } }  // Small vertical scrollbar
                    Text {                                                                                   // Description text
                        id: descText                                                                           // Assign id "descText"
                        width: parent.width - window.s(8)                                                       // Width with margin for scrollbar
                        text: window.selectedDescription                                                         // Selected description/synopsis
                        font.family: "JetBrains Mono"; font.pixelSize: window.s(11)                              // Font settings
                        color: window.subtext0; wrapMode: Text.WordWrap; lineHeight: 1.4                          // Subtext0 color, word wrap, line height
                        Behavior on opacity { NumberAnimation { duration: 400 } }                                 // Smooth opacity transition
                        opacity: window.selectedDescription !== "" ? 1 : 0                                        // Visible when description exists
                    }                                                                                        // End of Text
                }                                                                                          // End of Flickable
                Rectangle {                                                                                 // Back button
                    Layout.fillWidth: true; Layout.preferredHeight: window.s(45); radius: window.s(10)         // Full width, fixed height, rounded
                    property bool isHovered: backMouse.containsMouse                                            // Track hover state
                    color: isHovered ? window.surface2 : window.surface1                                        // Highlight on hover
                    Behavior on color { ColorAnimation { duration: 200 } }                                      // Smooth color transition
                    Text { anchors.centerIn: parent; text: "← Back"; font.family: "JetBrains Mono"; font.pixelSize: window.s(14); font.weight: Font.Medium; color: window.text }  // Back button label
                    MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { window.currentView = "search"; searchInput.forceActiveFocus(); saveUiState() } }  // On click: return to search view, focus input, save state
                }                                                                                          // End of Rectangle (back button)
                Item { Layout.fillHeight: true }                                                             // Spacer to push content to top
            }                                                                                            // End of ColumnLayout (left column)
            ColumnLayout {                                                                               // Right column: seasons and episodes
                Layout.fillWidth: true; Layout.fillHeight: true; spacing: window.s(12)                       // Fill remaining space, spacing
                Item {                                                                                     // Season selector container
                    Layout.fillWidth: true; Layout.preferredHeight: window.s(44)                               // Full width, fixed height
                    ListView {                                                                               // Horizontal list of season buttons
                        id: seasonList                                                                         // Assign id "seasonList"
                        anchors.fill: parent                                                                    // Fill container
                        orientation: ListView.Horizontal; model: seasonModel; spacing: window.s(8); clip: true   // Horizontal, season model, spacing, clip
                        Behavior on contentX { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }  // Smooth horizontal scrolling
                        delegate: Rectangle {                                                                    // Season button delegate
                            width: seasonLabelText.width + window.s(28); height: window.s(38); radius: window.s(10)  // Dynamic width based on text, fixed height, rounded
                            property bool isActive: window.currentSeason === model.seasonNum                        // True if this season is selected
                            color: isActive ? (window.mediaType === "tv" ? window.blue : window.mauve) : window.surface0  // Blue/mauve when active, surface0 otherwise
                            border.color: isActive ? color : window.surface1; border.width: 1                       // Border color matches fill when active, surface1 otherwise
                            Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutQuart } }     // Smooth color transition
                            Behavior on border.color { ColorAnimation { duration: 280; easing.type: Easing.OutQuart } }  // Smooth border color transition
                            scale: isActive ? 1.04 : 1.0                                                             // Slightly larger when active (4% scale)
                            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }      // Smooth scale animation with overshoot
                            Text {                                                                                   // Season label (e.g., "S1", "S2")
                                id: seasonLabelText                                                                    // Assign id
                                anchors.centerIn: parent                                                                // Center in button
                                text: "S" + model.seasonNum                                                             // "S" prefix + season number
                                font.family: "JetBrains Mono"; font.pixelSize: window.s(13); font.weight: isActive ? Font.Bold : Font.Medium  // Bold when active
                                color: isActive ? window.crust : window.text                                             // Crust (dark) text when active, normal text otherwise
                                Behavior on color { ColorAnimation { duration: 200 } }                                    // Smooth color transition
                            }                                                                                        // End of Text
                            MouseArea {                                                                              // Click area for season button
                                anchors.fill: parent                                                                   // Fill button
                                onClicked: {                                                                           // On click:
                                    if (window.currentSeason !== model.seasonNum) {                                      // If different season clicked
                                        window.currentSeason = model.seasonNum                                            // Update current season
                                        updateEpisodes(model.seasonNum)                                                   // Update episode list
                                        saveUiState()                                                                     // Save UI state
                                    }                                                                                  // End of if
                                }                                                                                    // End of onClicked
                            }                                                                                      // End of MouseArea
                        }                                                                                        // End of delegate
                    }                                                                                          // End of ListView
                }                                                                                            // End of Item (season selector)
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5) }  // Horizontal divider
                Item {                                                                                      // Episode list container
                    Layout.fillWidth: true; Layout.fillHeight: true                                             // Fill remaining space
                    ListView {                                                                                 // Episode list
                        id: epList                                                                               // Assign id "epList"
                        anchors.fill: parent                                                                      // Fill container
                        model: episodeModel; spacing: window.s(6); clip: true                                       // Episode model, spacing, clip
                        opacity: window.seasonSwitching ? 0 : 1                                                      // Fade out when switching seasons
                        Behavior on opacity {                                                                        // Opacity animation
                            NumberAnimation {                                                                         // NumberAnimation for opacity
                                duration: window.seasonSwitching ? 180 : 250                                            // 180ms fade out, 250ms fade in
                                easing.type: window.seasonSwitching ? Easing.InQuad : Easing.OutQuad                    // Different easing for fade out/in
                            }                                                                                        // End of NumberAnimation
                        }                                                                                          // End of Behavior
                        transform: Translate {                                                                      // Slide down slightly when switching seasons
                            y: window.seasonSwitching ? window.s(8) : 0                                                // Move 8px down when switching
                            Behavior on y {                                                                            // Y animation
                                NumberAnimation {                                                                       // NumberAnimation for Y
                                    duration: window.seasonSwitching ? 180 : 280                                          // 180ms slide down, 280ms slide up
                                    easing.type: window.seasonSwitching ? Easing.InQuad : Easing.OutQuart                // InQuad for down, OutQuart for up
                                }                                                                                    // End of NumberAnimation
                            }                                                                                      // End of Behavior
                        }                                                                                          // End of Transform
                        ScrollBar.vertical: ScrollBar { active: true; contentItem: Rectangle { radius: window.s(2); color: window.surface2; implicitWidth: window.s(4) } }  // Vertical scrollbar
                        Text {                                                                                     // Loading indicator
                            anchors.centerIn: parent                                                                  // Center in list
                            visible: window.isLoadingSeries                                                            // Show when loading series data
                            text: "Fetching episodes..."                                                               // Loading text
                            color: window.subtext0; font.family: "JetBrains Mono"; font.pixelSize: window.s(13)        // Subtext0 color, font settings
                        }                                                                                          // End of Text
                        highlight: Rectangle {                                                                       // Highlight for current episode
                            color: window.surface0; border.color: window.surface2; border.width: 1; radius: window.s(10); z: 0  // Surface0 fill, surface2 border, rounded
                            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }           // Smooth Y animation when selection changes
                        }                                                                                          // End of highlight
                        highlightFollowsCurrentItem: true                                                             // Highlight follows current index
                        highlightMoveVelocity: -1                                                                      // Instant highlight movement (-1 = immediate)
                        delegate: Item {                                                                              // Episode delegate
                            width: ListView.view.width; height: window.s(58); z: 1                                       // Full width, fixed height
                            property bool isCurrent: ListView.isCurrentItem                                               // True if this episode is selected
                            Rectangle {                                                                                  // Episode item background
                                anchors.fill: parent; radius: window.s(10)                                                  // Fill, rounded
                                color: epMouse.containsMouse || isCurrent ? window.surface0 : "transparent"                  // Highlight on hover or selection
                                border.color: epMouse.containsMouse || isCurrent ? window.surface2 : "transparent"; border.width: 1  // Border on hover/select
                                Behavior on color { ColorAnimation { duration: 150 } }                                       // Smooth color transition
                                Behavior on border.color { ColorAnimation { duration: 150 } }                                  // Smooth border transition
                                RowLayout {                                                                                // Row layout for episode number and title
                                    anchors.fill: parent; anchors.margins: window.s(10); spacing: window.s(12)               // Fill with margins, spacing
                                    Rectangle {                                                                              // Episode number badge
                                        Layout.preferredWidth: window.s(36); Layout.preferredHeight: window.s(36)              // Fixed size
                                        radius: window.s(8)                                                                    // Rounded corners
                                        color: isCurrent || epMouse.containsMouse ? window.blue : window.surface1              // Blue when active/hovered, surface1 otherwise
                                        Behavior on color { ColorAnimation { duration: 200 } }                                  // Smooth color transition
                                        Text {                                                                                 // Episode number text
                                            anchors.centerIn: parent                                                            // Center in badge
                                            text: model.epNum                                                                   // Episode number
                                            font.family: "JetBrains Mono"; font.pixelSize: window.s(13); font.weight: Font.Bold  // Bold, scaled size
                                            color: isCurrent || epMouse.containsMouse ? window.crust : window.subtext0           // Crust when active, subtext0 otherwise
                                            Behavior on color { ColorAnimation { duration: 200 } }                                // Smooth color transition
                                        }                                                                                      // End of Text
                                    }                                                                                      // End of Rectangle (badge)
                                    Column {                                                                               // Episode title column
                                        Layout.fillWidth: true; spacing: window.s(2)                                         // Fill width, small spacing
                                        Text {                                                                               // Episode title
                                            width: parent.width                                                               // Full width
                                            text: model.epTitle                                                                // Episode title
                                            font.family: "JetBrains Mono"                                                      // Font
                                            font.pixelSize: model.hasRealTitle ? window.s(13) : window.s(12)                    // Larger if real title, smaller if generic
                                            font.weight: model.hasRealTitle ? Font.Medium : Font.Normal                         // Medium weight for real titles
                                            color: model.hasRealTitle ? window.text : window.subtext0                            // Brighter for real titles
                                            elide: Text.ElideRight                                                              // Elide with ... if too long
                                        }                                                                                    // End of Text
                                    }                                                                                      // End of Column
                                }                                                                                        // End of RowLayout
                                MouseArea {                                                                              // Click area for episode
                                    id: epMouse; anchors.fill: parent; hoverEnabled: true                                    // Fill item, enable hover
                                    onClicked: {                                                                           // On click:
                                        epList.currentIndex = index                                                          // Set this as current episode
                                        startSourceCheck("tv", window.selectedImdbId, window.selectedTitle, window.selectedPoster, window.currentSeason, model.epNum)  // Start source check with episode details
                                    }                                                                                     // End of onClicked
                                }                                                                                       // End of MouseArea
                            }                                                                                         // End of Rectangle
                        }                                                                                           // End of delegate
                    }                                                                                             // End of ListView
                }                                                                                               // End of Item (episode container)
            }                                                                                                 // End of ColumnLayout (right column)
        }                                                                                                   // End of RowLayout (series view)
    }                                                                                                     // End of Rectangle (mainBg)
    // ==========================================                                                          // Decorative separator
    // SOURCE CHECKER MODAL OVERLAY                                                                         // Section header - source checking modal overlay
    // ==========================================                                                          // Decorative separator
    Rectangle {                                                                                           // Modal overlay background
        id: sourceModalOverlay                                                                              // Assign id "sourceModalOverlay"
        anchors.fill: parent                                                                                // Cover entire widget
        color: Qt.rgba(0, 0, 0, 0.7)                                                                        // Semi-transparent black (70% opacity)
        opacity: window.isSourceModalOpen ? 1 : 0                                                            // Visible when modal is open
        visible: opacity > 0                                                                                 // Only visible when opacity > 0 (prevents interaction when hidden)
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }              // Smooth fade in/out
        z: 100                                                                                               // Ensure modal is above everything
        MouseArea {                                                                                          // Click area covering entire overlay (closes modal on background click)
            anchors.fill: parent                                                                              // Cover entire overlay
            onClicked: window.closeSourceModal()                                                               // Close modal on click
        }                                                                                                   // End of MouseArea
        Rectangle {                                                                                          // Modal dialog box
            width: window.s(480); height: window.s(600)                                                         // Fixed size (scaled)
            anchors.centerIn: parent                                                                            // Center in overlay
            radius: window.s(14)                                                                                // Rounded corners
            color: window.base                                                                                  // Base color background
            border.color: window.surface2                                                                       // Surface2 border
            border.width: 1                                                                                     // 1px border
            clip: true                                                                                           // Clip content to rounded corners
            scale: window.isSourceModalOpen ? 1.0 : 0.92                                                          // Scale up when open, slightly smaller when closed
            Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }                   // Smooth scale animation with overshoot
            MouseArea { anchors.fill: parent }                                                                     // Prevent clicks from passing through to overlay
            ColumnLayout {                                                                                       // Column layout for modal content
                anchors.fill: parent; spacing: 0                                                                    // Fill dialog, no spacing
                // Header                                                                                             // Comment - modal header section
                Rectangle {                                                                                        // Modal header
                    Layout.fillWidth: true; Layout.preferredHeight: window.s(75); color: window.surface0               // Full width, fixed height, surface0 background
                    Rectangle { width: parent.width; height: 1; color: window.surface1; anchors.bottom: parent.bottom }  // Bottom border line
                    RowLayout {                                                                                      // Row layout for header content
                        anchors.fill: parent; anchors.margins: window.s(16)                                              // Fill with margin
                        ColumnLayout {                                                                                 // Column for status text and title
                            Layout.fillWidth: true; spacing: window.s(4)                                                  // Fill width, small spacing
                            Text {                                                                                       // Status text
                                text: window.checkingState === "checking" ? "Finding Stream..."                             // "Finding Stream..." when checking
                                    : window.checkingState === "found"    ? "Stream Ready!"                                 // "Stream Ready!" when found
                                    :                                       "No Streams Found"                              // "No Streams Found" when failed
                                color: window.checkingState === "found"      ? window.green                                 // Green when found
                                     : window.checkingState === "failed_all" ? window.red                                    // Red when all failed
                                     :                                         window.text                                   // Normal text otherwise
                                font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(17)         // Bold, larger size
                                Behavior on color { ColorAnimation { duration: 300 } }                                       // Smooth color transition
                            }                                                                                            // End of Text
                            Text {                                                                                       // Media title in header
                                text: window.pendingMedia.title || "Loading..."                                             // Pending media title or "Loading..."
                                color: window.subtext0; font.family: "JetBrains Mono"; font.pixelSize: window.s(12)         // Subtext0 color, smaller size
                                elide: Text.ElideRight; Layout.fillWidth: true                                              // Elide if too long, fill width
                            }                                                                                            // End of Text
                        }                                                                                              // End of ColumnLayout
                        Rectangle {                                                                                    // Close button
                            Layout.preferredWidth: window.s(32); Layout.preferredHeight: window.s(32); radius: window.s(8)  // Fixed size, rounded
                            color: modalCloseMouse.containsMouse ? window.surface2 : "transparent"                        // Highlight on hover
                            Behavior on color { ColorAnimation { duration: 150 } }                                        // Smooth color transition
                            Text { anchors.centerIn: parent; text: "×"; color: window.subtext0; font.pixelSize: window.s(20) }  // X symbol
                            MouseArea { id: modalCloseMouse; anchors.fill: parent; hoverEnabled: true; onClicked: window.closeSourceModal() }  // Close on click
                        }                                                                                              // End of Rectangle (close button)
                    }                                                                                                // End of RowLayout
                }                                                                                                  // End of Rectangle (header)
                // Body                                                                                                // Comment - modal body section
                Item {                                                                                             // Modal body container
                    Layout.fillWidth: true; Layout.fillHeight: true                                                    // Fill remaining space
                    ListView {                                                                                       // Source list
                        id: sourceListUI                                                                              // Assign id "sourceListUI"
                        anchors.fill: parent; anchors.margins: window.s(14)                                             // Fill with margin
                        model: sourceModel; spacing: window.s(8); clip: true                                             // Source model, spacing, clip
                        visible: window.checkingState !== "failed_all"                                                    // Hidden when all sources failed
                        delegate: Rectangle {                                                                           // Source item delegate
                            width: ListView.view.width; height: window.s(52); radius: window.s(10)                          // Full width, fixed height, rounded
                            color: {                                                                                       // Background color based on status
                                if (model.status === "checking") return Qt.rgba(window.blue.r,  window.blue.g,  window.blue.b,  0.12)   // Blue tint when checking
                                if (model.status === "success")  return Qt.rgba(window.green.r, window.green.g, window.green.b, 0.12)   // Green tint when success
                                if (model.status === "failed")   return Qt.rgba(window.red.r,   window.red.g,   window.red.b,   0.07)    // Red tint when failed
                                return window.surface0                                                                        // Default surface0 when pending
                            }                                                                                            // End of color binding
                            border.color: {                                                                              // Border color based on status
                                if (model.status === "checking") return window.blue                                         // Blue border when checking
                                if (model.status === "success")  return window.green                                        // Green border when success
                                if (model.status === "failed")   return Qt.rgba(window.red.r, window.red.g, window.red.b, 0.3)  // Faded red border when failed
                                return window.surface1                                                                     // Default surface1 border when pending
                            }                                                                                            // End of border.color
                            border.width: (model.status === "checking" || model.status === "success") ? 2 : 1               // Thicker border for checking/success states
                            Behavior on color { ColorAnimation { duration: 250 } }                                        // Smooth color transition
                            Behavior on border.color { ColorAnimation { duration: 250 } }                                 // Smooth border color transition
                            RowLayout {                                                                                  // Row layout for source info
                                anchors.fill: parent; anchors.leftMargin: window.s(14); anchors.rightMargin: window.s(10)    // Fill with margins
                                anchors.topMargin: 0; anchors.bottomMargin: 0                                                 // No top/bottom margins
                                spacing: window.s(10)                                                                        // Spacing between elements
                                Text {                                                                                      // Preferred source star indicator
                                    text: "★"                                                                                  // Star character
                                    font.pixelSize: window.s(13)                                                                // Star size
                                    color: window.mauve                                                                         // Mauve star color
                                    opacity: (window.sourcePrefs[window.pendingMedia.imdbId || ""] || "") === model.name ? 1 : 0  // Visible if this source is preferred for this IMDb ID
                                    Behavior on opacity { NumberAnimation { duration: 200 } }                                     // Smooth opacity transition
                                    Layout.preferredWidth: window.s(16)                                                         // Fixed width for alignment
                                }                                                                                           // End of Text (star)
                                Text {                                                                                      // Source name
                                    text: model.name                                                                           // Source name from model
                                    font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(14)         // Bold, scaled size
                                    color: model.status === "checking" ? window.blue                                            // Blue when checking
                                         : model.status === "success"  ? window.green                                           // Green when success
                                         : model.status === "failed"   ? Qt.rgba(window.red.r, window.red.g, window.red.b, 0.7)  // Faded red when failed
                                         :                               window.text                                            // Normal text when pending
                                    Layout.fillWidth: true                                                                    // Fill remaining width
                                    Behavior on color { ColorAnimation { duration: 200 } }                                     // Smooth color transition
                                }                                                                                           // End of Text (source name)
                                Item {                                                                                      // Status indicator container
                                    Layout.preferredWidth: window.s(22); Layout.preferredHeight: window.s(22)                  // Fixed size
                                    Rectangle {                                                                               // Pending indicator (empty circle)
                                        anchors.fill: parent; radius: width / 2                                                  // Circle shape
                                        color: "transparent"; border.color: window.surface2; border.width: 2                      // Transparent fill, surface2 border
                                        visible: model.status === "pending"                                                       // Only visible when pending
                                    }                                                                                         // End of Rectangle
                                    Item {                                                                                    // Checking spinner
                                        anchors.fill: parent                                                                     // Fill container
                                        visible: model.status === "checking"                                                      // Only visible when checking
                                        property real spinAngle: 0                                                                // Spin angle property
                                        NumberAnimation on spinAngle {                                                             // Continuous rotation
                                            from: 0; to: 360; duration: 700                                                        // Full rotation every 700ms
                                            loops: Animation.Infinite                                                               // Loop forever
                                            running: model.status === "checking"                                                     // Run while checking
                                            easing.type: Easing.Linear                                                              // Linear constant speed
                                        }                                                                                         // End of NumberAnimation
                                        Canvas {                                                                                  // Canvas for spinner arc
                                            anchors.fill: parent                                                                     // Fill parent
                                            property real angle: parent.spinAngle                                                    // Bind to parent's spin angle
                                            onAngleChanged: requestPaint()                                                            // Redraw on angle change
                                            onPaint: {                                                                               // Paint handler
                                                var ctx = getContext("2d")                                                             // Get 2D context
                                                ctx.reset()                                                                            // Reset canvas
                                                var cx = width / 2, cy = height / 2, r = width / 2 - 2                                 // Center and radius
                                                var startRad = (parent.spinAngle - 90) * Math.PI / 180                                  // Start angle in radians
                                                var endRad   = startRad + 1.6 * Math.PI                                                 // End angle (288 degrees arc)
                                                ctx.beginPath()                                                                        // Begin path
                                                ctx.arc(cx, cy, r, startRad, endRad)                                                    // Draw arc
                                                ctx.strokeStyle = window.blue                                                           // Blue stroke
                                                ctx.lineWidth = 2.5                                                                     // Line width
                                                ctx.lineCap = "round"                                                                   // Rounded ends
                                                ctx.stroke()                                                                           // Render
                                            }                                                                                        // End of onPaint
                                        }                                                                                          // End of Canvas
                                    }                                                                                          // End of Item (spinner)
                                    Text {                                                                                     // Failed X indicator
                                        anchors.centerIn: parent                                                                   // Center in container
                                        text: "✗"; color: Qt.rgba(window.red.r, window.red.g, window.red.b, 0.7)                     // X symbol, faded red
                                        font.weight: Font.Bold; font.pixelSize: window.s(14)                                         // Bold, scaled size
                                        visible: model.status === "failed"                                                            // Only visible when failed
                                    }                                                                                          // End of Text (failed)
                                    Text {                                                                                     // Success checkmark
                                        anchors.centerIn: parent                                                                   // Center in container
                                        text: "✓"; color: window.green                                                                // Checkmark symbol, green
                                        font.weight: Font.Bold; font.pixelSize: window.s(14)                                         // Bold, scaled size
                                        visible: model.status === "success"                                                           // Only visible when success
                                    }                                                                                          // End of Text (success)
                                }                                                                                            // End of Item (status indicator)
                            }                                                                                              // End of RowLayout
                        }                                                                                                // End of delegate
                    }                                                                                                  // End of ListView
                    ColumnLayout {                                                                                     // "All failed" content (shown when no sources work)
                        anchors.centerIn: parent; width: parent.width - window.s(40); spacing: window.s(20)               // Center in body, width with margin, spacing
                        visible: window.checkingState === "failed_all"                                                      // Only visible when all sources exhausted
                        Text {                                                                                             // Failure message
                            Layout.fillWidth: true                                                                           // Full width
                            text: "All stream sources failed for this title."                                                   // Message text
                            color: window.subtext0; font.family: "JetBrains Mono"; font.pixelSize: window.s(13)                // Subtext0 color, font settings
                            wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; lineHeight: 1.3                    // Word wrap, centered, line height
                        }                                                                                                  // End of Text
                        Rectangle {                                                                                        // "Browse Alternative Sites" button
                            Layout.fillWidth: true; Layout.preferredHeight: window.s(45); radius: window.s(10)                // Full width, fixed height, rounded
                            color: fmhyMouse.containsMouse ? window.blue : window.surface1                                      // Blue when hovered, surface1 otherwise
                            Behavior on color { ColorAnimation { duration: 150 } }                                              // Smooth color transition
                            Text { anchors.centerIn: parent; text: "Browse Alternative Sites"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(13); color: fmhyMouse.containsMouse ? window.crust : window.text }  // Button label
                            MouseArea {                                                                                        // Click area
                                id: fmhyMouse; anchors.fill: parent; hoverEnabled: true                                           // Fill button, enable hover
                                onClicked: { Quickshell.execDetached(["xdg-open", "https://fmhy.net/video#streaming-sites"]); window.closeSourceModal() }  // Open FMHY streaming sites list, close modal
                            }                                                                                                 // End of MouseArea
                        }                                                                                                  // End of Rectangle (button)
                    }                                                                                                    // End of ColumnLayout (failed content)
                }                                                                                                      // End of Item (body)
                Rectangle {                                                                                            // Footer (source marking section, shown when source found)
                    Layout.fillWidth: true                                                                                // Full width
                    Layout.preferredHeight: window.checkingState === "found" ? window.s(80) : 0                              // 80px height when found, 0 otherwise (hidden)
                    color: window.surface0; clip: true                                                                       // Surface0 background, clip
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 280; easing.type: Easing.OutQuart } }     // Smooth height animation
                    Rectangle { width: parent.width; height: 1; color: window.surface1; anchors.top: parent.top }             // Top border line
                    RowLayout {                                                                                            // Row for action buttons
                        anchors.fill: parent; anchors.margins: window.s(14); spacing: window.s(10)                             // Fill with margin, spacing
                        Rectangle {                                                                                        // "Mark as Working" / "★ Preferred Source" button
                            Layout.fillWidth: true; Layout.preferredHeight: window.s(48); radius: window.s(10)                 // Fill width, fixed height, rounded
                            property bool isPreferred: (window.sourcePrefs[window.pendingMedia.imdbId || ""] || "") === window.foundSourceName  // True if this source is already preferred
                            color: markWorksMouse.containsMouse                                                                 // Color based on hover and preferred state
                                ? Qt.rgba(window.green.r, window.green.g, window.green.b, 0.25)                                   // Brighter green when hovered
                                : Qt.rgba(window.green.r, window.green.g, window.green.b, isPreferred ? 0.20 : 0.10)             // More opaque when preferred, less otherwise
                            border.color: isPreferred ? window.green : Qt.rgba(window.green.r, window.green.g, window.green.b, 0.4)  // Solid green border when preferred, faded otherwise
                            border.width: isPreferred ? 2 : 1                                                                    // Thicker border when preferred
                            Behavior on color { ColorAnimation { duration: 150 } }                                               // Smooth color transition
                            ColumnLayout {                                                                                     // Column for button text
                                anchors.centerIn: parent; spacing: window.s(2)                                                    // Center, small spacing
                                Text {                                                                                           // Button label
                                    Layout.alignment: Qt.AlignHCenter                                                              // Center horizontally
                                    text: parent.parent.isPreferred ? "★ Preferred Source" : "Mark as Working"                      // Different text based on preferred state
                                    font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12)            // Bold, scaled size
                                    color: window.green                                                                            // Green text
                                }                                                                                              // End of Text
                                Text {                                                                                           // Source name subtitle
                                    Layout.alignment: Qt.AlignHCenter                                                              // Center horizontally
                                    text: window.foundSourceName !== "" ? window.foundSourceName : ""                                // Show found source name if exists
                                    font.family: "JetBrains Mono"; font.pixelSize: window.s(10)                                     // Smaller font
                                    color: Qt.rgba(window.green.r, window.green.g, window.green.b, 0.7)                              // Faded green
                                    visible: text !== ""                                                                            // Only visible if source name exists
                                }                                                                                              // End of Text
                            }                                                                                                // End of ColumnLayout
                            MouseArea {                                                                                        // Click area
                                id: markWorksMouse; anchors.fill: parent; hoverEnabled: true                                       // Fill button, enable hover
                                onClicked: {                                                                                     // On click:
                                    if (window.pendingMedia.imdbId && window.foundSourceName !== "") {                              // If we have IMDb ID and source name
                                        saveSourcePref(window.pendingMedia.imdbId, window.foundSourceName)                            // Save this source as preferred for this title
                                    }                                                                                             // End of if
                                }                                                                                               // End of onClicked
                            }                                                                                                // End of MouseArea
                        }                                                                                                  // End of Rectangle (mark button)
                        Rectangle {                                                                                        // "Try Next" button
                            Layout.preferredWidth: window.s(110); Layout.preferredHeight: window.s(48); radius: window.s(10)   // Fixed width, height, rounded
                            color: tryNextMouse2.containsMouse ? window.surface2 : window.surface1                                // Highlight on hover
                            border.color: window.surface2; border.width: 1                                                         // Surface2 border
                            Behavior on color { ColorAnimation { duration: 150 } }                                                 // Smooth color transition
                            ColumnLayout {                                                                                     // Column for button text
                                anchors.centerIn: parent; spacing: window.s(2)                                                    // Center, small spacing
                                Text {                                                                                           // "Try Next" label
                                    Layout.alignment: Qt.AlignHCenter                                                              // Center horizontally
                                    text: "Try Next"                                                                               // Button text
                                    font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(12)            // Bold, scaled size
                                    color: window.text                                                                             // Text color
                                }                                                                                              // End of Text
                                Text {                                                                                           // "Not working?" subtitle
                                    Layout.alignment: Qt.AlignHCenter                                                              // Center horizontally
                                    text: "Not working?"                                                                           // Subtitle text
                                    font.family: "JetBrains Mono"; font.pixelSize: window.s(10)                                     // Smaller font
                                    color: window.subtext0                                                                         // Subtext0 color
                                }                                                                                              // End of Text
                            }                                                                                                // End of ColumnLayout
                            MouseArea { id: tryNextMouse2; anchors.fill: parent; hoverEnabled: true; onClicked: window.skipToNextSource() }  // On click: skip to next source
                        }                                                                                                  // End of Rectangle (try next button)
                    }                                                                                                    // End of RowLayout
                }                                                                                                      // End of Rectangle (footer)
            }                                                                                                        // End of ColumnLayout (modal content)
        }                                                                                                          // End of Rectangle (modal dialog)
    }                                                                                                            // End of Rectangle (modal overlay)
}                                                                                                              // End of root Item