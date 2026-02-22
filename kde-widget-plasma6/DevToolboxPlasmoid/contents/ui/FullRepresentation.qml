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
    property string scriptBasePath: ""

    // Plasma 6 DataSource for running shell commands
    Plasma5Support.DataSource {
        id: shSource
        engine: "executable"
        onNewData: function(sourceName, data) {
            var stdout = data["stdout"] || ""
            var stderr = data["stderr"] || ""
            var exitCode = data["exit code"] || 0
            
            // Log full output details for debugging
            console.log("[DevToolbox] DataSource newData received.");
            console.log("[DevToolbox] Exit code:", exitCode);
            console.log("[DevToolbox] Stdout length:", stdout.length);
            if (stderr) console.log("[DevToolbox] Stderr:", stderr);
            
            if (connectedSources.indexOf(sourceName) !== -1) {
                if (stdout.length > 0 && stdout.indexOf('|') !== -1) {
                    processIndexOutput(stdout)
                } else if (stdout.length > 0) {
                    console.log("[DevToolbox] No pipe chars found in output. Raw:", stdout.substring(0, 200));
                    console.log("[DevToolbox] Full output:", stdout);
                } else {
                    console.log("[DevToolbox] Command returned empty stdout.");
                    if (stderr) {
                        statusMessage = "⚠️ Error: " + stderr.substring(0, 100);
                    } else {
                        statusMessage = "⚠️ No cheats found. Check ~/cheats.d directory.";
                    }
                    isLoading = false;
                }
                disconnectSource(sourceName)
            }
        }
    }

    function runCommand(cmd) {
        console.log("[DevToolbox] runCommand:", cmd);
        shSource.connectSource(cmd)
    }

    function refreshCheats() {
        isLoading = true
        statusMessage = "Loading cheats..."
        
        // Construct the absolute path to our helper script
        if (scriptBasePath === "") {
            scriptBasePath = Qt.resolvedUrl("../code/indexer.sh").toString().replace("file://", "")
            console.log("[DevToolbox] Resolved script path:", scriptBasePath);
        }
        
        var scriptPath = scriptBasePath;
        var cheatsDir = plasmoid.configuration.cheatsDir.replace(/^~/, "$HOME")
        var debugLog = "/tmp/devtoolbox-debug.log"
        var cacheFile = plasmoid.configuration.cacheFile.replace(/^~/, "$HOME")
        
        console.log("[DevToolbox] Using cheats directory:", cheatsDir);
        console.log("[DevToolbox] Using cache file:", cacheFile);
        console.log("[DevToolbox] Using script:", scriptPath);
        
        // Pass cache file as third parameter to indexer
        var cmd = "bash \"" + scriptPath + "\" \"" + cheatsDir + "\" \"" + debugLog + "\" \"" + cacheFile + "\""
        
        console.log("[DevToolbox] Command to run:", cmd);
        runCommand(cmd)
    }

    function processIndexOutput(output) {
        console.log("[DevToolbox] Received index output (length=" + output.length + ")")

        var parsed = Cheats.parseIndexOutput(output)
        console.log("[DevToolbox] Parsed model with " + parsed.length + " groups.")
        
        // Initialize expanded property for each group
        for (var i = 0; i < parsed.length; i++) {
            parsed[i].expanded = false;
        }
        
        cheatsModel = parsed
        updateFilter()
        isLoading = false
        
        var totalCheats = countCheats(cheatsModel);
        if (totalCheats > 0) {
            statusMessage = "✅ Loaded " + totalCheats + " cheats.";
        } else {
            statusMessage = "⚠️ No cheats found in ~/cheats.d"
        }
    }
    
    function countCheats(groups) {
        var c = 0;
        for(var i=0; i<groups.length; i++) c += groups[i].cheats.length;
        return c;
    }

    Component.onCompleted: {
        console.log("[DevToolbox] FullRepresentation loaded. Configuration:");
        console.log("  - cheatsDir:", plasmoid.configuration.cheatsDir);
        console.log("  - cacheFile:", plasmoid.configuration.cacheFile);
        console.log("  - preferredEditor:", plasmoid.configuration.preferredEditor);
        Qt.callLater(refreshCheats)
    }

    function updateFilter() {
        var query = searchField.text.toLowerCase()
        if (query === "") {
            // Just copy the model, preserving expanded states
            filteredModel = cheatsModel.slice()
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
                        expanded: true  // Auto-expand when searching
                    }
                    result.push(newGroup)
                }
            }
            filteredModel = result
        }
    }
    
    function copyCheat(cheatPath) {
        console.log("[DevToolbox] Copy cheat:", cheatPath);
        
        // FIXED: Properly quote the path to handle spaces
        var cmd = "sed '1,80{/^Title:/d; /^Group:/d; /^Icon:/d; /^Order:/d}' \"" + cheatPath + "\" | ";
        
        // Auto-detect and use available clipboard tool
        cmd += "if command -v wl-copy >/dev/null 2>&1; then wl-copy; ";
        cmd += "elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard; ";
        cmd += "else cat; fi";
        
        console.log("[DevToolbox] Copy command:", cmd);
        runCommand(cmd);
        statusMessage = "✅ Copied to clipboard!";
    }

    function openCheat(cheatPath) {
        var editor = plasmoid.configuration.preferredEditor || "code"
        // FIXED: Properly quote the path
        var cmd = editor + " \"" + cheatPath + "\""
        console.log("[DevToolbox] Open command:", cmd);
        runCommand(cmd)
    }
    
    function exportCheats() {
        var file = "$HOME/DevToolbox-Cheatsheet_" + Utils.formatDate(new Date()) + ".md"
        var cmd = Cheats.getExportMarkdownCommand(
            plasmoid.configuration.cheatsDir.replace(/^~/, "$HOME"),
            file
        )
        runCommand(cmd)
        statusMessage = "📥 Exporting all cheats..."
    }

    function exportCheat(cheatPath, cheatTitle) {
        var safeName = cheatTitle.replace(/[^a-zA-Z0-9_\-]/g, '_').replace(/__+/g, '_')
        var outFile = "$HOME/DevToolbox-" + safeName + "_" + Utils.formatDate(new Date()) + ".md"
        
        // FIXED: Direct sed command without over-escaping
        var cmd = "sed '1,80{/^Title:/d; /^Group:/d; /^Icon:/d; /^Order:/d}' \"" + cheatPath + "\" > \"" + outFile + "\" && " +
            "notify-send 'DevToolbox' 'Exported to " + outFile + "'";
        
        console.log("[DevToolbox] Export command:", cmd);
        runCommand(cmd)
        statusMessage = "📥 Exported: " + safeName + ".md"
    }

    function fzfSearch() {
        var cheatsDir = plasmoid.configuration.cheatsDir.replace(/^~/, "$HOME")
        var editor    = plasmoid.configuration.preferredEditor || "code"
        var fzfCmd    = Cheats.getFzfSearchCommand(cheatsDir, editor)
        
        var termScript =
            "if command -v konsole >/dev/null 2>&1; then " +
            "  konsole -e " + fzfCmd + "; " +
            "elif command -v xterm >/dev/null 2>&1; then " +
            "  xterm -hold -e " + fzfCmd + "; " +
            "else " +
            "  notify-send 'DevToolbox' 'No terminal found (konsole/xterm).'; " +
            "fi"
            
        var escapedTerm = termScript.replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/\$/g, "\\$");
        var runTerm = Cheats.plasmaShield("bash -c \"" + escapedTerm + "\"");
        
        runCommand(runTerm)
        statusMessage = "🚀 Opening FZF search..."
    }

    function toggleGroup(index) {
        console.log("[DevToolbox] Toggling group at index:", index);
        
        // Create a new array from filtered model
        var newModel = []
        for (var i = 0; i < filteredModel.length; i++) {
            var group = filteredModel[i]
            if (i === index) {
                // Toggle this group's expanded state
                newModel.push({
                    name: group.name,
                    icon: group.icon,
                    cheats: group.cheats,
                    expanded: !group.expanded
                })
                console.log("[DevToolbox] Group '" + group.name + "' expanded:", !group.expanded);
            } else {
                // Keep other groups as-is
                newModel.push(group)
            }
        }
        
        // Assign the new model to trigger QML update
        filteredModel = newModel
        
        // Also update the main model if not filtering
        if (searchField.text === "") {
            cheatsModel = newModel
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            
            PlasmaComponents.Label {
                text: "🗒️ DevToolbox Cheats"
                font.bold: true
                font.pointSize: 12
            }
            
            Item { Layout.fillWidth: true }
            
            PlasmaComponents.Button {
                text: "Refresh"
                icon.name: "view-refresh"
                onClicked: refreshCheats()
                ToolTip.text: "Reload cheatsheets"
                ToolTip.visible: hovered
            }
            
            PlasmaComponents.Button {
                text: "Export"
                icon.name: "document-export"
                onClicked: exportCheats()
                ToolTip.text: "Export all cheats to ~/"
                ToolTip.visible: hovered
            }

            PlasmaComponents.Button {
                text: "FZF"
                icon.name: "search"
                onClicked: fzfSearch()
                ToolTip.text: "Open interactive search"
                ToolTip.visible: hovered
            }
        }

        PlasmaComponents.TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: "🔎 Search cheats..."
            onTextChanged: updateFilter()
            clearButtonShown: true
        }
        
        PlasmaComponents.Label {
            visible: statusMessage !== ""
            text: statusMessage
            color: statusMessage.indexOf("⚠️") === 0 || statusMessage.indexOf("❌") === 0 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.highlightColor
            font.italic: true
            Layout.alignment: Qt.AlignRight
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            
            Timer {
                interval: 5000
                running: statusMessage !== "" && statusMessage.indexOf("⚠️") === -1 && statusMessage.indexOf("❌") === -1
                onTriggered: statusMessage = ""
            }
        }
        
        PlasmaComponents.BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            visible: isLoading
            running: isLoading
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: !isLoading && filteredModel.length > 0

            ListView {
                id: cheatsList
                model: filteredModel
                spacing: Kirigami.Units.smallSpacing

                delegate: ColumnLayout {
                    id: groupLayout
                    width: cheatsList.width
                    spacing: 0
                    
                    property string groupIcon: modelData.icon
                    property bool groupExpanded: modelData.expanded

                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        color: Kirigami.Theme.highlightColor
                        opacity: groupExpanded ? 0.3 : 0.1
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[DevToolbox] Rectangle clicked for group:", modelData.name);
                                toggleGroup(index);
                            }
                        }
                    }
                    
                    ItemDelegate {
                        Layout.fillWidth: true
                        Layout.topMargin: -25
                        leftPadding: 5
                        
                        onClicked: {
                            console.log("[DevToolbox] ItemDelegate clicked for group:", modelData.name);
                            toggleGroup(index);
                        }
                        
                        contentItem: RowLayout {
                            spacing: 5

                            PlasmaComponents.Label {
                                text: groupExpanded ? "▼" : "▶"
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

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        visible: groupExpanded

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
