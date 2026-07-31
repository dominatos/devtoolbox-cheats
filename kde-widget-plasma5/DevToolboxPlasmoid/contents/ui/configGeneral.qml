/*
 * Configuration page for DevToolbox Cheats
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

Kirigami.FormLayout {
    id: configPage

    // Property aliases for KConfig binding
    property alias cfg_cheatsDir: cheatsDirField.text
    property alias cfg_cacheFile: cacheFileField.text
    property alias cfg_preferredEditor: editorField.text
    property alias cfg_autoRebuildCache: autoRebuildField.checked
    property alias cfg_checkForUpdates: checkForUpdatesField.checked
    property string cfg_tocFormat: "obsidian"

    // DataSource for running manage-tocs.py (Plasma5 uses PlasmaCore)
    PlasmaCore.DataSource {
        id: tocFormatApplier
        engine: "executable"
        onNewData: {
            var exitCode = data["exit code"] || 0
            if (exitCode === 0) {
                tocApplyStatus.text = "✅ Formatting applied!"
            } else {
                tocApplyStatus.text = "❌ Error applying formatting"
            }
            disconnectSource(sourceName)
        }
    }

    function applyTocFormatNow() {
        var cheatsDir = cfg_cheatsDir.replace(/^~/, "$HOME")
        var script = "python3 $(find ~/.local -name 'manage-tocs.py' 2>/dev/null | head -1 || find ~/devtoolbox-cheats -name 'manage-tocs.py' 2>/dev/null | head -1) --style " + cfg_tocFormat + " --dir " + cheatsDir
        tocApplyStatus.text = "⏳ Applying..."
        tocFormatApplier.connectSource(script)
    }

    // Popular editors list
    property var allEditors: [
        {name: "VS Code", cmd: "code"},
        {name: "VS Codium", cmd: "codium"},
        {name: "Kate", cmd: "kate"},
        {name: "Geany", cmd: "geany"},
        {name: "Sublime Text", cmd: "subl"},
        {name: "Atom", cmd: "atom"},
        {name: "Gedit", cmd: "gedit"},
        {name: "Vim", cmd: "vim"},
        {name: "Neovim", cmd: "nvim"},
        {name: "Emacs", cmd: "emacs"},
        {name: "Nano", cmd: "nano"},
        {name: "KWrite", cmd: "kwrite"},
        {name: "Mousepad", cmd: "mousepad"},
        {name: "Pluma", cmd: "pluma"},
        {name: "XED", cmd: "xed"},
        {name: "Notepadqq", cmd: "notepadqq"}
    ]

    property var installedEditors: []
    property bool detectingEditors: true

    // DataSource for detecting installed editors
    PlasmaCore.DataSource {
        id: editorDetector
        engine: "executable"
        
        onNewData: {
            var stdout = data["stdout"] || ""
            
            if (stdout.trim() !== "") {
                // Parse installed editors
                var lines = stdout.trim().split('\n')
                var detected = []
                
                for (var i = 0; i < lines.length; i++) {
                    var cmd = lines[i].trim()
                    if (cmd) {
                        // Find the editor name
                        for (var j = 0; j < allEditors.length; j++) {
                            if (allEditors[j].cmd === cmd) {
                                detected.push(allEditors[j])
                                break
                            }
                        }
                    }
                }
                
                installedEditors = detected
                console.log("[DevToolbox Config] Detected editors:", detected.length)
            }
            
            detectingEditors = false
            disconnectSource(sourceName)
        }
    }

    Component.onCompleted: {
        // Detect installed editors
        var detectCmd = "for cmd in code codium kate geany subl atom gedit vim nvim emacs nano kwrite mousepad pluma xed notepadqq; do command -v $cmd >/dev/null 2>&1 && echo $cmd; done"
        editorDetector.connectSource(detectCmd)
    }

    TextField {
        id: cheatsDirField
        Kirigami.FormData.label: "Cheats Directory:"
        placeholderText: "~/cheats.d"
    }

    TextField {
        id: cacheFileField
        Kirigami.FormData.label: "Cache File Path:"
        placeholderText: "~/.cache/devtoolbox-cheats.json"
    }

    RowLayout {
        Kirigami.FormData.label: "Preferred Editor:"
        spacing: 10

        ComboBox {
            id: editorCombo
            Layout.preferredWidth: 200
            
            model: ListModel {
                id: editorModel
            }
            
            textRole: "name"
            
            // Update model when installed editors change
            Connections {
                target: configPage
                onInstalledEditorsChanged: editorCombo.updateEditorModel()
            }
            
            function updateEditorModel() {
                editorModel.clear()
                
                if (installedEditors.length > 0) {
                    // Add detected editors
                    for (var i = 0; i < installedEditors.length; i++) {
                        editorModel.append({
                            "name": installedEditors[i].name + " ✓",
                            "cmd": installedEditors[i].cmd
                        })
                    }
                    editorModel.append({"name": "---", "cmd": ""})
                }
                
                // Add all editors
                for (var j = 0; j < allEditors.length; j++) {
                    editorModel.append({
                        "name": allEditors[j].name,
                        "cmd": allEditors[j].cmd
                    })
                }
                
                editorModel.append({"name": "Custom...", "cmd": ""})
                
                // Select current editor
                selectCurrentEditor()
            }
            
            function selectCurrentEditor() {
                var currentCmd = editorField.text || "code"
                var foundIndex = -1
                
                for (var i = 0; i < editorModel.count; i++) {
                    var item = editorModel.get(i)
                    if (item.cmd === currentCmd) {
                        foundIndex = i
                        break
                    }
                }
                
                if (foundIndex >= 0) {
                    currentIndex = foundIndex
                } else {
                    // Select "Custom"
                    currentIndex = editorModel.count - 1
                }
            }
            
            Component.onCompleted: {
                updateEditorModel()
            }
            
            onActivated: {
                if (currentIndex >= 0 && currentIndex < editorModel.count) {
                    var item = editorModel.get(currentIndex)
                    if (item.cmd && item.cmd !== "") {
                        editorField.text = item.cmd
                    }
                }
            }
        }

        TextField {
            id: editorField
            Layout.fillWidth: true
            placeholderText: "code"
            enabled: editorCombo.currentIndex === editorCombo.model.count - 1
        }
    }

    Label {
        text: detectingEditors ? "🔍 Detecting installed editors..." : 
              (installedEditors.length > 0 ? 
               "✓ Found " + installedEditors.length + " installed editor(s)" : 
               "No editors auto-detected. You can still type a command.")
        font.pointSize: 9
        opacity: 0.8
        Kirigami.FormData.label: ""
    }
    
    CheckBox {
        id: autoRebuildField
        Kirigami.FormData.label: "Cache:"
        text: "Rebuild cache on startup"
    }

    CheckBox {
        id: checkForUpdatesField
        Kirigami.FormData.label: "Updates:"
        text: "Automatically check for updates on startup"
    }

    ComboBox {
        id: tocFormatCombo
        Kirigami.FormData.label: "TOC Link Style:"
        model: ListModel {
            ListElement { text: "Obsidian (Exact text, %20)"; value: "obsidian" }
            ListElement { text: "GitHub (Lowercase slugs)";   value: "github"  }
        }
        textRole: "text"
        Component.onCompleted: {
            currentIndex = cfg_tocFormat === "github" ? 1 : 0
        }
        onActivated: {
            cfg_tocFormat = currentIndex === 0 ? "obsidian" : "github"
            var confPath = "$HOME/.config/devtoolbox-cheats/toc_format.conf"
            var writeCmd = "mkdir -p $(dirname " + confPath + ") && echo '" + cfg_tocFormat + "' > " + confPath
            tocFormatApplier.connectSource(writeCmd)
        }
    }

    RowLayout {
        Kirigami.FormData.label: "Apply Now:"
        spacing: 8

        Button {
            text: "🪄 Apply TOC Formatting"
            onClicked: applyTocFormatNow()
        }

        Label {
            id: tocApplyStatus
            text: ""
            font.pointSize: 9
            opacity: 0.8
        }
    }

    Label {
        text: "DevToolbox Cheats Version: v" + plasmoid.metaData.version
        font.pointSize: 9
        opacity: 0.6
        Kirigami.FormData.label: ""
    }
}
