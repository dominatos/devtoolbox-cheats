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
    id: root

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

    property string accumulatedStdout: ""

    // ─── DataSource: indexer.sh ───────────────────────────────────────────────
    Plasma5Support.DataSource {
        id: shSource
        engine: "executable"

        onNewData: function(sourceName, data) {
            var stdout   = data["stdout"]  || ""
            var stderr   = data["stderr"]  || ""
            var exitCode = data["exit code"]

            if (stdout.length > 0) {
                accumulatedStdout += stdout
            }

            if (exitCode !== undefined && connectedSources.indexOf(sourceName) !== -1) {
                if (exitCode === 0) {
                    if (accumulatedStdout.indexOf('|') !== -1) {
                        processIndexOutput(accumulatedStdout)
                    } else {
                        console.log("[DevToolbox] Indexer returned no pipe chars.")
                        root.globalCheatsModel = []
                        root.globalStatusMessage = "⚠️ No cheats found. Check ~/cheats.d directory."
                        root.globalIsLoading = false
                    }
                } else {
                    console.error("[DevToolbox] Indexer failed. Exit code:", exitCode, "Stderr:", stderr)
                    root.globalCheatsModel = []
                    root.globalStatusMessage = "⚠️ Error: " + stderr.substring(0, 100)
                    root.globalIsLoading = false
                }
                accumulatedStdout = ""
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
            if (stdout.trim() !== "") {
                root.globalDetectedEditor = stdout.trim()
                console.log("[DevToolbox] Detected fallback editor:", root.globalDetectedEditor)
            }
            disconnectSource(sourceName)
        }
    }

    // ─── Functions ────────────────────────────────────────────────────────────
    function refreshCheats() {
        root.globalIsLoading     = true
        root.globalStatusMessage = "Loading cheats..."

        if (scriptBasePath === "") {
            scriptBasePath = Qt.resolvedUrl("../code/indexer.sh")
                .toString().replace("file://", "")
            console.log("[DevToolbox] Resolved indexer path:", scriptBasePath)
        }

        var cheatsDir = plasmoid.configuration.cheatsDir.replace(/^~/, "$HOME")
        var cacheFile = plasmoid.configuration.cacheFile.replace(/^~/, "$HOME")
        var debugLog  = "/tmp/devtoolbox-debug.log"

        // Build the command directly (no escaping needed — DataSource executable engine
        // passes the string to sh -c and handles quoting correctly as-is).
        var cmd = "bash \"" + scriptBasePath + "\" \"" + cheatsDir + "\" \""
                + debugLog + "\" \"" + cacheFile + "\""
        console.log("[DevToolbox] Running indexer:", cmd)
        shSource.connectSource(cmd)
    }

    function processIndexOutput(output) {
        try {
            var parsed = Cheats.parseIndexOutput(output)
            for (var i = 0; i < parsed.length; i++) {
                parsed[i].expanded = false
            }
            root.globalCheatsModel   = parsed
            root.globalIsLoading     = false

            var total = countCheats(parsed)
            root.globalStatusMessage = total > 0
                ? "✅ Loaded " + total + " cheats."
                : "⚠️ No cheats found in ~/cheats.d"

            console.log("[DevToolbox] Loaded", total, "cheats in", parsed.length, "groups.")
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

    // ─── Startup ──────────────────────────────────────────────────────────────
    Component.onCompleted: {
        console.log("[DevToolbox] main.qml loaded.")

        // Detect fallback editor once at startup
        var detectCmd = "for cmd in code codium kate geany gedit vim nvim nano kwrite; do " +
                        "command -v $cmd >/dev/null 2>&1 && echo $cmd && break; done"
        editorDetector.connectSource(detectCmd)

        Qt.callLater(refreshCheats)
    }
}
