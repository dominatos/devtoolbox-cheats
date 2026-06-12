/*
 * Main UI entry point for DevToolbox Cheats Plasmoid (Plasma 5)
 *
 * Holds the persistent cheatsheet cache in RAM so FullRepresentation
 * opens instantly without re-indexing on every popup.
 */

import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0

import "../code/cheats.js" as Cheats

Item {
    id: root

    // Plasmoid preferred representation (Compact/Full)
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    // Define representations
    Plasmoid.compactRepresentation: CompactRepresentation {}
    Plasmoid.fullRepresentation: FullRepresentation {}

    // ─── Persistent RAM cache (survives popup open/close) ─────────────────────
    property var    globalCheatsModel:   []
    property bool   globalIsLoading:     false
    property string globalStatusMessage: ""
    property string globalUpdateVersion: ""  // Set to latest version string if an update is available

    // ─── Dynamic DataSource (Plasma 5/6 compatible creation) ─────────────────
    property var shSource: null
    property var accumulatedStdoutMap: ({})

    function createDataSource() {
        try {
            // Try Plasma 6 API first
            shSource = Qt.createQmlObject(
                'import org.kde.plasma.plasma5support; DataSource { engine: "executable" }',
                root, "DynamicDataSource")
        } catch (e) {
            try {
                // Fallback to Plasma 5 API
                shSource = Qt.createQmlObject(
                    'import org.kde.plasma.core 2.0; DataSource { engine: "executable" }',
                    root, "DynamicDataSource")
            } catch (e2) {
                console.error("[DevToolbox] Failed to create DataSource for both Plasma 5 and 6:", e2)
                root.globalIsLoading = false
                root.globalStatusMessage = "⚠️ Failed to initialize DataSource. The widget cannot run shell commands."
            }
        }

        if (shSource) {
            shSource.newData.connect(function(sourceName, data) {
                var stdout   = data["stdout"]    || ""
                var stderr   = data["stderr"]    || ""
                var exitCode = data["exit code"]

                if (stdout.length > 0) {
                    var current = root.accumulatedStdoutMap[sourceName] || ""
                    root.accumulatedStdoutMap[sourceName] = current + stdout
                }

                if (exitCode !== undefined && shSource.connectedSources.indexOf(sourceName) !== -1) {
                    var finalStdout = root.accumulatedStdoutMap[sourceName] || ""
                    if (exitCode === 0) {
                        if (finalStdout.indexOf('|') !== -1) {
                            processIndexOutput(finalStdout)
                        } else {
                            if (stderr) console.error("[DevToolbox] Indexer warning (exit 0):", stderr)
                            root.globalCheatsModel = []
                            root.globalStatusMessage = "⚠️ No cheats found. Check " + plasmoid.configuration.cheatsDir + " directory."
                            root.globalIsLoading = false
                        }
                    } else {
                        console.error("[DevToolbox] Indexer error (exit " + exitCode + "):", stderr)
                        root.globalCheatsModel = []
                        root.globalStatusMessage = "⚠️ Indexer error: " + (stderr ? stderr.substring(0, 120) : "exit code " + exitCode)
                        root.globalIsLoading = false
                    }
                    root.accumulatedStdoutMap[sourceName] = ""
                    shSource.disconnectSource(sourceName)
                }
            })
        }
    }

    // ─── Functions ────────────────────────────────────────────────────────────
    function refreshCheats() {
        if (!shSource || root.globalIsLoading) return
        root.globalIsLoading     = true
        root.globalStatusMessage = "Indexing cheats..."

        var cmd = Cheats.getIndexCommand(
            plasmoid.configuration.cheatsDir.replace("~", "$HOME"),
            plasmoid.configuration.cacheFile.replace("~", "$HOME")
        )
        console.log("[DevToolbox] Refreshing cheats:", cmd)
        root.accumulatedStdoutMap[cmd] = "" // Initialize buffer for this command
        shSource.connectSource(cmd)
    }

    function processIndexOutput(output) {
        console.log("[DevToolbox] Received index output (length=" + output.length + ")")
        try {
            var parsed = Cheats.parseIndexOutput(output)
            root.globalCheatsModel   = parsed
            root.globalIsLoading     = false
            root.globalStatusMessage = "Loaded " + countCheats(parsed) + " cheats."
        } catch (e) {
            console.error("[DevToolbox] Error parsing cheats:", e)
            root.globalCheatsModel   = []
            root.globalIsLoading     = false
            root.globalStatusMessage = "⚠️ Error parsing cheats data."
        }
    }

    function countCheats(groups) {
        var c = 0
        for (var i = 0; i < groups.length; i++) c += groups[i].cheats.length
        return c
    }

    // ─── Version check ────────────────────────────────────────────────────────
    function checkForUpdate() {
        if (!plasmoid.configuration.checkForUpdates) return

        var xhr = new XMLHttpRequest()
        xhr.open("GET", "https://raw.githubusercontent.com/dominatos/devtoolbox-cheats/main/version.txt", true)

        var updateTimer = Qt.createQmlObject('import QtQuick 2.0; Timer {}', root, "UpdateTimer")
        updateTimer.interval = 10000
        updateTimer.triggered.connect(function() {
            console.warn("[DevToolbox] Update check timed out.")
            xhr.abort()
            updateTimer.destroy()
        })

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            updateTimer.stop()
            updateTimer.destroy()

            if (xhr.status !== 200) {
                console.log("[DevToolbox] Update check failed. HTTP status:", xhr.status)
                return
            }
            var remoteVersion = xhr.responseText.trim()
            var localVersion  = plasmoid.metaData.version
            if (remoteVersion && remoteVersion !== localVersion && isNewerVersion(remoteVersion, localVersion)) {
                console.log("[DevToolbox] Update available:", remoteVersion, "(current:", localVersion + ")")
                root.globalUpdateVersion = remoteVersion
            } else {
                console.log("[DevToolbox] Up to date:", localVersion)
            }
        }
        
        updateTimer.start()
        xhr.send()
    }

    function isNewerVersion(remote, local) {
        var r = remote.replace(/^v/, "").split(".").map(Number)
        var l = local.replace(/^v/, "").split(".").map(Number)
        for (var i = 0; i < Math.max(r.length, l.length); i++) {
            var rv = r[i] || 0
            var lv = l[i] || 0
            if (rv > lv) return true
            if (rv < lv) return false
        }
        return false
    }

    // ─── Startup ──────────────────────────────────────────────────────────────
    Component.onCompleted: {
        console.log("[DevToolbox] main.qml loaded (Plasma 5).")
        createDataSource()
        if (shSource) Qt.callLater(refreshCheats)
        Qt.callLater(checkForUpdate)
    }
}
