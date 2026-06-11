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

    // ─── Dynamic DataSource (Plasma 5/6 compatible creation) ─────────────────
    property var shSource: null
    property string accumulatedStdout: ""

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
                    accumulatedStdout += stdout
                }

                if (exitCode !== undefined && shSource.connectedSources.indexOf(sourceName) !== -1) {
                    if (exitCode === 0) {
                        if (accumulatedStdout.indexOf('|') !== -1) {
                            processIndexOutput(accumulatedStdout)
                        } else {
                            if (stderr) console.error("[DevToolbox] Indexer warning (exit 0):", stderr)
                            root.globalCheatsModel = []
                            root.globalStatusMessage = "⚠️ No cheats found. Check " + plasmoid.configuration.cheatsDir + " directory."
                            root.globalIsLoading = false
                        }
                    } else {
                        console.error("[DevToolbox] Indexer error (exit " + exitCode + "):", stderr)
                        root.globalStatusMessage = "⚠️ Indexer error: " + (stderr ? stderr.substring(0, 120) : "exit code " + exitCode)
                        root.globalIsLoading = false
                    }
                    accumulatedStdout = ""
                    shSource.disconnectSource(sourceName)
                }
            })
        }
    }

    // ─── Functions ────────────────────────────────────────────────────────────
    function refreshCheats() {
        if (!shSource) return
        root.globalIsLoading     = true
        root.globalStatusMessage = "Indexing cheats..."

        var cmd = Cheats.getIndexCommand(
            plasmoid.configuration.cheatsDir.replace("~", "$HOME"),
            plasmoid.configuration.cacheFile.replace("~", "$HOME")
        )
        console.log("[DevToolbox] Refreshing cheats:", cmd)
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

    // ─── Startup ──────────────────────────────────────────────────────────────
    Component.onCompleted: {
        console.log("[DevToolbox] main.qml loaded (Plasma 5).")
        createDataSource()
        if (shSource) Qt.callLater(refreshCheats)
    }
}
