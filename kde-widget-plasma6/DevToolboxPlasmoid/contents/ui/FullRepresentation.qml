import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

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
    
    // Dynamic DataSource for compatibility between Plasma 5 (PlasmaCore) and 6 (Plasma5Support)
    property var shSource: null

    function createDataSource() {
        try {
            // Try Plasma 6 way first
            shSource = Qt.createQmlObject('import org.kde.plasma.plasma5support; DataSource { engine: "executable" }', fullRoot, "DynamicDataSource");
        } catch (e) {
            try {
                // Fallback to Plasma 5 way
                shSource = Qt.createQmlObject('import org.kde.plasma.core 2.0; DataSource { engine: "executable" }', fullRoot, "DynamicDataSource");
            } catch (e2) {
                console.error("Failed to create DataSource for both Plasma 5 and 6");
            }
        }

        if (shSource) {
            shSource.newData.connect(function(sourceName, data) {
                var stdout = data["stdout"]
                if (shSource.connectedSources.indexOf(sourceName) !== -1) {
                    if (stdout && stdout.indexOf('|') !== -1) {
                        processIndexOutput(stdout)
                    }
                    shSource.disconnectSource(sourceName)
                }
            });
        }
    }

    function runCommand(cmd) {
        if (shSource) shSource.connectedSources.push(cmd)
    }

    function refreshCheats() {
        isLoading = true
        statusMessage = "Indexing cheats..."
        var cmd = Cheats.getIndexCommand(
            plasmoid.configuration.cheatsDir.replace("~", "$HOME"),
            plasmoid.configuration.cacheFile.replace("~", "$HOME")
        )
        console.log("DevToolbox: Refreshing cheats with command:", cmd)
        runCommand(cmd)
    }

    function processIndexOutput(output) {
        console.log("DevToolbox: Received index output (length=" + output.length + ")")
        // console.log("DevToolbox: Output snippet:", output.substring(0, 200))

        cheatsModel = Cheats.parseIndexOutput(output)
        console.log("DevToolbox: Parsed model with " + cheatsModel.length + " groups.")
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
        createDataSource()
        if (shSource) refreshCheats()
    }

    function updateFilter() {
        var query = searchField.text.toLowerCase()
        if (query === "") {
            filteredModel = cheatsModel
        } else {
            // Deep filter groups
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
                    // Clone group but with filtered cheats
                    var newGroup = {
                        name: group.name,
                        icon: group.icon,
                        cheats: matchingCheats
                    }
                    result.push(newGroup)
                }
            }
            filteredModel = result
        }
    }
    
    // Clipboard Helper
    function copyCheat(cheatPath) {
        var safePath = cheatPath.replace(/'/g, "'\\''");
        var copyCmd = "if command -v wl-copy >/dev/null; then APP=wl-copy; else APP='xclip -selection clipboard'; fi; " +
                  "sed '1,80{/^Title:/d; /^Group:/d; /^Icon:/d; /^Order:/d}' '" + safePath + "' | $APP";

        runCommand(copyCmd)
        statusMessage = "✅ Copied to clipboard!"
    }

    function openCheat(cheatPath) {
        var editor = plasmoid.configuration.preferredEditor || "code"
        var cmd = editor + " '" + cheatPath + "'"
        runCommand(cmd)
    }
    
    function exportCheats() {
        var file = "$HOME/DevToolbox-Cheatsheet_" + Utils.formatDate(new Date()) + ".md"
        var cmd = Cheats.getExportMarkdownCommand(
            plasmoid.configuration.cheatsDir.replace("~", "$HOME"),
            file
        )
        runCommand(cmd + " && notify-send 'DevToolbox' 'Exported to " + file + "'")
        statusMessage = "Exporting..."
    }

    function toggleGroup(index) {
        var list = filteredModel
        var group = list[index]
        group.expanded = !group.expanded
        
        // Force update by assigning a new array reference
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
                ToolTip.text: "Export all to Markdown"
                ToolTip.visible: hovered
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
            
             // Auto clear status after 3s
            Timer {
                interval: 3000
                running: statusMessage !== ""
                onTriggered: statusMessage = ""
            }
        }

        // --- Content ---
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true // Important for clean scrolling

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
                        visible: true
                        
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
                        visible: modelData.expanded // Collapse/Expand container

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
                                        // Use group icon if specific icon is missing
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
                                            font.pointSize: 12 // Slightly larger for emojis
                                            renderType: Text.NativeRendering // Improves text crispness and sometimes glyph finding
                                            color: Kirigami.Theme.textColor
                                        }
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        PlasmaComponents.Label {
                                            text: modelData.title
                                            font.bold: false // Argos style is cleaner/lighter
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                    
                                    // Buttons
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
                                    }
                                }
                                
                                onClicked: openCheat(modelData.path) // Default action: Open in Editor
                            }
                        }
                    }
                }
            }
        }
    }
}
