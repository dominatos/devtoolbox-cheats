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

    // ─── Bind to persistent RAM cache owned by main.qml ─────────────────────
    property var    cheatsModel:    plasmoid.rootItem.globalCheatsModel
    property var    filteredModel:  []
    property bool   isLoading:      plasmoid.rootItem.globalIsLoading
    property string statusMessage:  plasmoid.rootItem.globalStatusMessage
    property string detectedEditor: plasmoid.rootItem.globalDetectedEditor

    // ─── Local DataSource for action commands (copy, open, export, fzf) ──────
    // These are fire-and-forget — no need to cache results.
    Plasma5Support.DataSource {
        id: shSource
        engine: "executable"
        onNewData: function(sourceName, data) {
            if (connectedSources.indexOf(sourceName) !== -1)
                disconnectSource(sourceName)
        }
    }

    // Re-run the filter whenever the global model changes
    onCheatsModelChanged: updateFilter()

    Component.onCompleted: {
        updateFilter()
    }

    function runCommand(cmd) {
        shSource.connectSource(cmd)
    }

    function refreshCheats() {
        plasmoid.rootItem.refreshCheats()
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
        plasmoid.rootItem.globalStatusMessage = "✅ Copied to clipboard!";
    }

    function escapeShell(str) {
        if (!str) return "''";
        return "'" + String(str).replace(/'/g, "'\\''") + "'";
    }

    function getEditorResolutionCommand() {
        var configuredEditor = plasmoid.configuration.preferredEditor || ""
        if (configuredEditor !== "") {
            var safeConf = escapeShell(configuredEditor)
            if (detectedEditor !== "") {
                var safeDet = escapeShell(detectedEditor)
                return "if command -v " + safeConf + " >/dev/null 2>&1; then EDITOR=" + safeConf + "; " +
                    "else notify-send 'DevToolbox' \"Editor \"'" + safeConf + "'\" not found. Using \"'" + safeDet + "'\" instead.\"; EDITOR=" + safeDet + "; fi; "
            } else {
                return "if command -v " + safeConf + " >/dev/null 2>&1; then EDITOR=" + safeConf + "; " +
                    "else notify-send 'DevToolbox' \"Editor \"'" + safeConf + "'\" not found. Please install an editor.\"; exit 1; fi; "
            }
        } else if (detectedEditor !== "") {
            return "EDITOR=" + escapeShell(detectedEditor) + "; "
        } else {
            return ""
        }
    }

    function openCheat(cheatPath) {
        var editorCmd = getEditorResolutionCommand()
        if (editorCmd === "") {
            plasmoid.rootItem.globalStatusMessage = "⚠️ No editor found. Configure one in widget settings."
            return
        }
        
        var cmd = editorCmd + "\"$EDITOR\" " + escapeShell(cheatPath)
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
        plasmoid.rootItem.globalStatusMessage = "📥 Exporting all cheats..."
    }

    function exportCheat(cheatPath, cheatTitle) {
        var safeName = cheatTitle.replace(/[^a-zA-Z0-9_\-]/g, '_').replace(/__+/g, '_')
        var outFile = "$HOME/DevToolbox-" + safeName + "_" + Utils.formatDate(new Date()) + ".md"
        
        // FIXED: Direct sed command without over-escaping
        var cmd = "sed '1,80{/^Title:/d; /^Group:/d; /^Icon:/d; /^Order:/d}' \"" + cheatPath + "\" > \"" + outFile + "\" && " +
            "notify-send 'DevToolbox' 'Exported to " + outFile + "'";
        
        console.log("[DevToolbox] Export command:", cmd);
        runCommand(cmd)
        plasmoid.rootItem.globalStatusMessage = "📥 Exported: " + safeName + ".md"
    }

    function fzfSearch() {
        var cheatsDir = plasmoid.configuration.cheatsDir.replace(/^~/, "$HOME")
        var editorCmd = getEditorResolutionCommand()
        if (editorCmd === "") {
            plasmoid.rootItem.globalStatusMessage = "⚠️ No editor found. Configure one in widget settings."
            return
        }
        
        // Get path to fzf-search.sh helper
        var fzfScript = Qt.resolvedUrl("../code/fzf-search.sh").toString().replace("file://", "")
        
        // Simple command to launch terminal with our script
        var cmd = editorCmd +
            "if command -v konsole >/dev/null 2>&1; then " +
            "konsole -e bash " + escapeShell(fzfScript) + " " + escapeShell(cheatsDir) + " \"$EDITOR\"; " +
            "elif command -v xterm >/dev/null 2>&1; then " +
            "xterm -hold -e bash " + escapeShell(fzfScript) + " " + escapeShell(cheatsDir) + " \"$EDITOR\"; " +
            "else " +
            "notify-send 'DevToolbox' 'No terminal found (konsole/xterm).'; " +
            "fi"
        
        console.log("[DevToolbox] FZF command:", cmd);
        runCommand(cmd)
        plasmoid.rootItem.globalStatusMessage = "🚀 Opening FZF search..."
    }
    signal groupExpandedToggled(int groupIndex, bool isExpanded)

    function toggleGroup(index) {
        if (index >= 0 && index < filteredModel.length) {
            var newState = !filteredModel[index].expanded;
            
            // 1. Update the JS object so state persists if delegate is recreated (scrolling)
            filteredModel[index].expanded = newState;
            
            if (searchField.text === "") {
                plasmoid.rootItem.globalCheatsModel[index].expanded = newState;
            }
            
            // 2. Emit signal to update only the specific delegate in-place
            // This prevents QML from destroying and recreating all 150 delegates!
            groupExpandedToggled(index, newState);
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

            PlasmaComponents.Button {
                text: "Online"
                icon.name: "applications-internet"
                onClicked: Qt.openUrlExternally("https://cheats.alteron.net/")
                ToolTip.text: "🌐 Open Online Version"
                ToolTip.visible: hovered
            }

            PlasmaComponents.Button {
                text: "GitHub"
                icon.name: "vcs-normal"
                onClicked: Qt.openUrlExternally("https://github.com/dominatos/devtoolbox-cheats/")
                ToolTip.text: "🐙 Open GitHub Repository"
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
                onTriggered: plasmoid.rootItem.globalStatusMessage = ""
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

                    Connections {
                        target: fullRoot
                        function onGroupExpandedToggled(idx, isExpanded) {
                            if (index === idx) {
                                groupLayout.groupExpanded = isExpanded;
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        color: Kirigami.Theme.highlightColor
                        opacity: groupExpanded ? 0.3 : 0.1
                        
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
