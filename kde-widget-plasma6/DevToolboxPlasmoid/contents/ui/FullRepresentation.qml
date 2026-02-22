import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

import "../code/cheats.js" as Cheats
import "../code/utils.js" as Utils

Item {
    id: fullRoot
    Layout.minimumWidth: 400
    Layout.minimumHeight: 500
    Layout.preferredWidth: 600
    Layout.preferredHeight: 600

    property var cheatsModel: []
    property var filteredModel: []
    property string statusMessage: ""
    property bool isLoading: false

    // Plasma 6 DataSource for running shell commands
    Plasma5Support.DataSource {
        id: shSource
        engine: "executable"
        onNewData: function(sourceName, data) {
            var stdout = data["stdout"] || ""
            var stderr = data["stderr"] || ""
            
            // Log full output details for debugging
            console.log("[DevToolbox] DataSource newData received.");
            console.log("[DevToolbox] Stdout length:", stdout.length);
            if (stderr) console.log("[DevToolbox] Stderr:", stderr);
            
            if (connectedSources.indexOf(sourceName) !== -1) {
                if (stdout.length > 0 && stdout.indexOf('|') !== -1) {
                    processIndexOutput(stdout)
                } else if (stdout.length > 0) {
                    console.log("[DevToolbox] No pipe chars found in output. Raw:", stdout.substring(0, 100));
                } else {
                    console.log("[DevToolbox] Command returned empty stdout.");
                }
                disconnectSource(sourceName)
            }
        }
    }

    function runCommand(cmd) {
        // Logging the shielded command might be messy, but helpful
        console.log("[DevToolbox] runCommand (shielded):", cmd.substring(0, 200));
        shSource.connectSource(cmd)
    }

    function refreshCheats() {
        isLoading = true
        statusMessage = "Indexing cheats..."
        
        // Construct the absolute path to our helper script
        // In Plasma 6, we can use Qt.resolvedUrl to get the base path correctly
        var baseUrl = Qt.resolvedUrl(".").toString().replace("file://", "")
        var scriptPath = baseUrl + "indexer.sh"

        // Use literal $HOME for robust path construction
        var cheatsDir = plasmoid.configuration.cheatsDir.replace("~", "$HOME")
        var cacheFile = plasmoid.configuration.cacheFile.replace("~", "$HOME")
        
        // getIndexCommand now points to the helper script
        var cmd = Cheats.getIndexCommand(cheatsDir, cacheFile, scriptPath)
        runCommand(cmd)
    }

    function processIndexOutput(output) {
        console.log("[DevToolbox] Received index output (length=" + output.length + ")")

        cheatsModel = Cheats.parseIndexOutput(output)
        console.log("[DevToolbox] Parsed model with " + cheatsModel.length + " groups.")
        updateFilter()
        isLoading = false
        statusMessage = "Loaded " + countCheats(cheatsModel) + " cheats."
    }
    
    function countCheats(groups) {
        var c = 0;
        for(var i=0; i<groups.length; i++) c += groups[i].cheats.length;
        return c;
    }

    // Initialize
    Component.onCompleted: {
        console.log("[DevToolbox] FullRepresentation loaded. Configuration:");
        console.log("  - cheatsDir:", plasmoid.configuration.cheatsDir);
        console.log("  - cacheFile:", plasmoid.configuration.cacheFile);
        refreshCheats()
    }

    function updateFilter() {
        var query = searchField.text.toLowerCase()
        if (query === "") {
            filteredModel = cheatsModel
        } else {
            var result = []
            for (var i = 0; i < cheatsModel.length; i++) {
                var group = cheatsModel[i]
                var matchingCheats = []
                for (var j = 0; j < group.cheats.length; j++) {
                    var cheat = group.cheats[j]
                    if (cheat.title.toLowerCase().indexOf(query) !== -1 || 
                        cheat.path.toLowerCase().indexOf(query) !== -1) {
                        matchingCheats.push(cheat)
                    }
                }
                if (matchingCheats.length > 0) {
                    var newGroup = {
                        name: group.name,
                        icon: group.icon,
                        cheats: matchingCheats,
                        expanded: true // Auto-expand when searching
                    }
                    result.push(newGroup)
                }
            }
            filteredModel = result
        }
    }
    
    function copyCheat(cheatPath) {
        var script = "if command -v wl-copy >/dev/null; then APP=wl-copy; else APP='xclip -selection clipboard'; fi; " +
                  "sed '1,80{/^Title:/d; /^Group:/d; /^Icon:/d; /^Order:/d}' \"" + cheatPath + "\" | $APP";
        
        var escapedScript = script.replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/\$/g, "\\$");
        var copyCmd = Cheats.plasmaShield("bash -c \"" + escapedScript + "\"");

        runCommand(copyCmd)
        statusMessage = "✅ Copied to clipboard!"
    }

    function openCheat(cheatPath) {
        var editor = plasmoid.configuration.preferredEditor || "code"
        var cmd = Cheats.plasmaShield(editor + " \"" + cheatPath + "\"")
        runCommand(cmd)
    }
    
    function exportCheats() {
        var file = "$HOME/DevToolbox-Cheatsheet_" + Utils.formatDate(new Date()) + ".md"
        var cmd = Cheats.getExportMarkdownCommand(
            plasmoid.configuration.cheatsDir.replace("~", "$HOME"),
            file
        )
        runCommand(cmd)
        statusMessage = "Exporting all cheats..."
    }

    function exportCheat(cheatPath, cheatTitle) {
        var safeName = cheatTitle.replace(/[^a-zA-Z0-9_\-]/g, '_').replace(/__+/g, '_')
        var outFile  = "$HOME/DevToolbox-" + safeName + "_" + Utils.formatDate(new Date()) + ".md"
        var cmd = Cheats.getExportCheatCommand(cheatPath, outFile)
        runCommand(cmd)
        statusMessage = "📥 Exported: " + safeName + ".md"
    }

    function fzfSearch() {
        var cheatsDir = plasmoid.configuration.cheatsDir.replace("~", "$HOME")
        var editor    = plasmoid.configuration.preferredEditor || "code"
        var fzfCmd    = Cheats.getFzfSearchCommand(cheatsDir, editor)
        
        // Shielded terminal launcher
        var termScript =
            "if command -v konsole >/dev/null 2>&1; then " +
            "  konsole --hold -e " + fzfCmd + "; " +
            "elif command -v xterm >/dev/null 2>&1; then " +
            "  xterm --hold -e " + fzfCmd + "; " +
            "else " +
            "  notify-send 'DevToolbox' 'No terminal found (konsole/xterm).'; " +
            "fi"
            
        var escapedTerm = termScript.replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/\$/g, "\\$");
        var runTerm = Cheats.plasmaShield("bash -c \"" + escapedTerm + "\"");
        
        runCommand(runTerm)
        statusMessage = "🚀 Opening FZF search..."
    }

    function toggleGroup(index) {
        var list = filteredModel
        var group = list[index]
        group.expanded = !group.expanded
        
        // Force update
        filteredModel = []
        filteredModel = list
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        // --- Header ---
        RowLayout {
            Layout.fillWidth: true
            
            PlasmaComponents.Label {
                text: "🗒️ DevToolbox Cheats"
                font.bold: true
                font.pointSize: 12
            }
            
            Item { Layout.fillWidth: true } // spacer
            
            PlasmaComponents.Button {
                text: "Refresh"
                icon.name: "view-refresh"
                onClicked: refreshCheats()
            }
            
            PlasmaComponents.Button {
                text: "Export"
                icon.name: "document-export"
                onClicked: exportCheats()
            }

            PlasmaComponents.Button {
                text: "FZF"
                icon.name: "search"
                onClicked: fzfSearch()
            }
        }

        // --- Search ---
        PlasmaComponents.TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: "🔎 Search cheats..."
            onTextChanged: updateFilter()
            clearButtonShown: true
        }
        
        // --- Status ---
        PlasmaComponents.Label {
            visible: statusMessage !== ""
            text: statusMessage
            color: Kirigami.Theme.highlightColor
            font.italic: true
            Layout.alignment: Qt.AlignRight
            
             // Auto clear status after 4s
            Timer {
                interval: 4000
                running: statusMessage !== ""
                onTriggered: statusMessage = ""
            }
        }

        // --- Content ---
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: cheatsList
                model: filteredModel
                spacing: Kirigami.Units.smallSpacing

                delegate: ColumnLayout {
                    id: groupLayout
                    width: cheatsList.width
                    spacing: 0
                    
                    property string groupIcon: modelData.icon

                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        color: Kirigami.Theme.highlightColor
                        opacity: modelData.expanded ? 0.3 : 0.1
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: toggleGroup(index)
                        }
                    }
                    
                    ItemDelegate {
                        Layout.fillWidth: true
                        Layout.topMargin: -25
                        leftPadding: 5
                        
                        onClicked: toggleGroup(index)
                        
                        contentItem: RowLayout {
                            spacing: 5

                            PlasmaComponents.Label {
                                text: modelData.expanded ? "▼" : "▶"
                            }

                            Kirigami.Icon {
                                source: modelData.icon.length > 3 ? modelData.icon : ""
                                width: 16
                                height: 16
                                visible: source !== ""
                            }

                            Text {
                                text: modelData.icon.length <= 3 ? modelData.icon : ""
                                visible: text !== ""
                                font.pointSize: 12
                                renderType: Text.NativeRendering
                                color: Kirigami.Theme.textColor
                            }

                            PlasmaComponents.Label {
                                text: modelData.name + " (" + modelData.cheats.length + ")"
                                font.bold: true
                                Layout.fillWidth: true
                                color: Kirigami.Theme.textColor
                            }
                        }
                    }

                    // Cheats container
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        visible: modelData.expanded

                        Repeater {
                            model: modelData.cheats
                            delegate: ItemDelegate {
                                Layout.fillWidth: true
                                
                                contentItem: RowLayout {
                                    spacing: 10
                                    
                                    Item {
                                        width: 22
                                        height: 22
                                        
                                        property string iconMeta: modelData.icon || ""
                                        property string effectiveIcon: iconMeta !== "" ? iconMeta : (groupIcon || "document-properties")
                                        property bool isSystemIcon: Cheats.isIconName(effectiveIcon)

                                        Kirigami.Icon {
                                            anchors.fill: parent
                                            source: parent.isSystemIcon ? parent.effectiveIcon : ""
                                            visible: parent.isSystemIcon
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: !parent.isSystemIcon ? parent.effectiveIcon : ""
                                            visible: !parent.isSystemIcon
                                            font.pointSize: 12
                                            renderType: Text.NativeRendering
                                            color: Kirigami.Theme.textColor
                                        }
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        PlasmaComponents.Label {
                                            text: modelData.title
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                    
                                    RowLayout {
                                        visible: hovered || visualFocus
                                        
                                        PlasmaComponents.Button {
                                            icon.name: "edit-copy"
                                            display: AbstractButton.IconOnly
                                            onClicked: copyCheat(modelData.path)
                                            ToolTip.text: "Copy to Clipboard"
                                            ToolTip.visible: hovered
                                        }
                                        PlasmaComponents.Button {
                                            icon.name: "document-open"
                                            display: AbstractButton.IconOnly
                                            onClicked: openCheat(modelData.path)
                                            ToolTip.text: "Open in Editor"
                                            ToolTip.visible: hovered
                                        }
                                        PlasmaComponents.Button {
                                            icon.name: "document-save"
                                            display: AbstractButton.IconOnly
                                            onClicked: exportCheat(modelData.path, modelData.title)
                                            ToolTip.text: "Export this cheat to ~/"
                                            ToolTip.visible: hovered
                                        }
                                    }
                                }
                                
                                onClicked: openCheat(modelData.path)
                            }
                        }
                    }
                }
            }
        }
    }
}
                  Layout.fillWidth: true
                                        }
                                    }
                                    
                                    RowLayout {
                                        visible: hovered || visualFocus
                                        
                                        PlasmaComponents.Button {
                                            icon.name: "edit-copy"
                                            display: AbstractButton.IconOnly
                                            onClicked: copyCheat(modelData.path)
                                            ToolTip.text: "Copy to Clipboard"
                                            ToolTip.visible: hovered
                                        }
                                        PlasmaComponents.Button {
                                            icon.name: "document-open"
                                            display: AbstractButton.IconOnly
                                            onClicked: openCheat(modelData.path)
                                            ToolTip.text: "Open in Editor"
                                            ToolTip.visible: hovered
                                        }
                                        PlasmaComponents.Button {
                                            icon.name: "document-save"
                                            display: AbstractButton.IconOnly
                                            onClicked: exportCheat(modelData.path, modelData.title)
                                            ToolTip.text: "Export this cheat to ~/"
                                            ToolTip.visible: hovered
                                        }
                                    }
                                }
                                
                                onClicked: openCheat(modelData.path)
                            }
                        }
                    }
                }
            }
        }
        
        // --- Empty state ---
        PlasmaComponents.Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            visible: !isLoading && filteredModel.length === 0 && statusMessage === ""
            text: "No cheatsheets found.\n\nMake sure you have .md files in:\n" + plasmoid.configuration.cheatsDir
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.disabledTextColor
        }
    }
}
