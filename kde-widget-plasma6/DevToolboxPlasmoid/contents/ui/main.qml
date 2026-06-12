/*
 * Main UI entry point for DevToolbox Cheats Plasmoid (Plasma 6)
 *
 * Holds the persistent cheatsheet cache in RAM so FullRepresentation
 * opens instantly without re-indexing on every popup.
 */

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

import "../code/cheats.js" as Cheats

PlasmoidItem {
    id: devToolboxRoot

    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    // Show compact (icon) in panel; clicking expands to full popup
    preferredRepresentation: compactRepresentation

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    toolTipMainText: "DevToolbox Cheats"
    toolTipSubText: "Click to search and copy cheatsheets"

    // ─── Persistent RAM cache (survives popup open/close) ─────────────────────
    property var    globalCheatsModel:    []
    property string globalDetectedEditor: ""
    property bool   globalIsLoading:      false
    property string globalStatusMessage:  ""
    property string scriptBasePath:       ""
    property string globalUpdateVersion:  ""  // Set to latest version string if an update is available

    property var accumulatedStdoutMap: ({})

    // ─── DataSource: indexer.sh ───────────────────────────────────────────────
    Plasma5Support.DataSource {
        id: shSource
        engine: "executable"

        onNewData: function(sourceName, data) {
            var stdout   = data["stdout"]  || ""
            var stderr   = data["stderr"]  || ""
            var exitCode = data["exit code"]

            if (stdout.length > 0) {
                var current = devToolboxRoot.accumulatedStdoutMap[sourceName] || ""
                devToolboxRoot.accumulatedStdoutMap[sourceName] = current + stdout
            }

            if (exitCode !== undefined && connectedSources.indexOf(sourceName) !== -1) {
                var finalStdout = devToolboxRoot.accumulatedStdoutMap[sourceName] || ""
                if (exitCode === 0) {
                    if (finalStdout.indexOf('|') !== -1) {
                        processIndexOutput(finalStdout)
                    } else {
                        console.log("[DevToolbox] Indexer returned no pipe chars.")
                        devToolboxRoot.globalCheatsModel = []
                        var cDir = plasmoid.configuration.cheatsDir || "~/cheats.d"
                        devToolboxRoot.globalStatusMessage = "⚠️ No cheats found. Check " + cDir + " directory."
                        devToolboxRoot.globalIsLoading = false
                    }
                } else {
                    console.error("[DevToolbox] Indexer failed. Exit code:", exitCode, "Stderr:", stderr)
                    devToolboxRoot.globalCheatsModel = []
                    devToolboxRoot.globalStatusMessage = "⚠️ Error: " + stderr.substring(0, 100)
                    devToolboxRoot.globalIsLoading = false
                }
                devToolboxRoot.accumulatedStdoutMap[sourceName] = ""
                disconnectSource(sourceName)
            }
        }
    }

    // ─── DataSource: editor auto-detection ───────────────────────────────────
    Plasma5Support.DataSource {
        id: editorDetector
        engine: "executable"

        onNewData: function(sourceName, data) {
            var stdout = data["stdout"] || ""
            var stderr = data["stderr"] || ""
            var exitCode = data["exit code"]

            if (exitCode !== undefined && exitCode !== 0) {
                console.warn("[DevToolbox] Editor detection failed. Exit code:", exitCode, "Stderr:", stderr.trim())
            } else if (stdout.trim() !== "") {
                devToolboxRoot.globalDetectedEditor = stdout.trim()
                console.log("[DevToolbox] Detected fallback editor:", devToolboxRoot.globalDetectedEditor)
            }
            disconnectSource(sourceName)
        }
    }

    // ─── Functions ────────────────────────────────────────────────────────────
    function refreshCheats() {
        if (devToolboxRoot.globalIsLoading) return
        devToolboxRoot.globalIsLoading     = true
        devToolboxRoot.globalStatusMessage = "Loading cheats..."

        if (scriptBasePath === "") {
            scriptBasePath = Qt.resolvedUrl("../code/indexer.sh")
                .toString().replace("file://", "")
            console.log("[DevToolbox] Resolved indexer path:", scriptBasePath)
        }

        var cheatsDir = Cheats.bashSafePath(plasmoid.configuration.cheatsDir)
        var cacheFile = Cheats.bashSafePath(plasmoid.configuration.cacheFile)
        var debugLog  = "/tmp/devtoolbox-debug.log"

        // Escape all interpolated values to prevent shell injection.
        // scriptBasePath is widget-internal (Qt.resolvedUrl), but still escaped for safety.
        var cmd = "bash " + Cheats.escapeShell(scriptBasePath) + " " + cheatsDir + " "
                + Cheats.escapeShell(debugLog) + " " + cacheFile
        console.log("[DevToolbox] Running indexer:", cmd)
        devToolboxRoot.accumulatedStdoutMap[cmd] = "" // Initialize buffer for this command
        shSource.connectSource(cmd)
    }

    function processIndexOutput(output) {
        try {
            var parsed = Cheats.parseIndexOutput(output)
            for (var i = 0; i < parsed.length; i++) {
                parsed[i].expanded = false
            }
            devToolboxRoot.globalCheatsModel   = parsed
            devToolboxRoot.globalIsLoading     = false

            var total = countCheats(parsed)
            var cDir = plasmoid.configuration.cheatsDir || "~/cheats.d"
            devToolboxRoot.globalStatusMessage = total > 0
                ? "✅ Loaded " + total + " cheats."
                : "⚠️ No cheats found in " + cDir

            console.log("[DevToolbox] Loaded", total, "cheats in", parsed.length, "groups.")
        } catch (e) {
            console.error("[DevToolbox] Error parsing cheats:", e)
            devToolboxRoot.globalCheatsModel   = []
            devToolboxRoot.globalIsLoading     = false
            devToolboxRoot.globalStatusMessage = "⚠️ Error parsing cheats data."
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

        var updateTimer = Qt.createQmlObject('import QtQuick 2.0; Timer {}', devToolboxRoot, "UpdateTimer")
        updateTimer.interval = 10000
        var timerDestroyed = false
        updateTimer.triggered.connect(function() {
            if (timerDestroyed) return
            timerDestroyed = true
            console.warn("[DevToolbox] Update check timed out.")
            xhr.abort()
            updateTimer.destroy()
        })

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (!timerDestroyed) {
                timerDestroyed = true
                updateTimer.stop()
                updateTimer.destroy()
            }

            if (xhr.status !== 200) {
                console.log("[DevToolbox] Update check failed. HTTP status:", xhr.status)
                return
            }
            var remoteVersion = xhr.responseText.trim()
            var localVersion  = plasmoid.metaData.version
            if (remoteVersion && remoteVersion !== localVersion && isNewerVersion(remoteVersion, localVersion)) {
                console.log("[DevToolbox] Update available:", remoteVersion, "(current:", localVersion + ")")
                devToolboxRoot.globalUpdateVersion = remoteVersion
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
        console.log("[DevToolbox] main.qml loaded.")

        // Detect fallback editor once at startup
        var detectCmd = "for cmd in code codium kate geany gedit vim nvim nano kwrite; do " +
                        "command -v $cmd > /dev/null 2>&1 && echo $cmd && break; done"
        editorDetector.connectSource(detectCmd)

        Qt.callLater(refreshCheats)
        Qt.callLater(checkForUpdate)
    }
}
