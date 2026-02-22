/*
 * Configuration page for DevToolbox Cheats
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

Kirigami.FormLayout {
    id: configPage

    // Property aliases for KConfig binding
    property alias cfg_cheatsDir: cheatsDirField.text
    property alias cfg_cacheFile: cacheFileField.text
    property alias cfg_preferredEditor: editorField.text
    property alias cfg_autoRebuildCache: autoRebuildField.checked

    // Popular editors list
    property var editors: [
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
        {name: "Custom", cmd: ""}
    ]

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
            Layout.preferredWidth: 180
            model: editors
            textRole: "name"
            
            Component.onCompleted: {
                // Find matching editor on load
                var currentCmd = editorField.text || "code"
                var foundIndex = -1
                for (var i = 0; i < editors.length - 1; i++) {
                    if (editors[i].cmd === currentCmd) {
                        foundIndex = i
                        break
                    }
                }
                currentIndex = foundIndex >= 0 ? foundIndex : editors.length - 1
            }
            
            onActivated: {
                if (currentIndex >= 0 && currentIndex < editors.length) {
                    var selected = editors[currentIndex]
                    if (selected.cmd !== "") {
                        editorField.text = selected.cmd
                    }
                }
            }
        }

        TextField {
            id: editorField
            Layout.fillWidth: true
            placeholderText: "code"
            enabled: editorCombo.currentIndex === editors.length - 1
            
            onTextChanged: {
                // Update combo to "Custom" if manually edited
                if (activeFocus && editorCombo.currentIndex !== editors.length - 1) {
                    var isKnown = false
                    for (var i = 0; i < editors.length - 1; i++) {
                        if (editors[i].cmd === text) {
                            isKnown = true
                            editorCombo.currentIndex = i
                            break
                        }
                    }
                    if (!isKnown) {
                        editorCombo.currentIndex = editors.length - 1
                    }
                }
            }
        }
    }

    Label {
        text: "Popular: VS Code, Codium, Kate, Geany, Sublime, Vim, etc."
        font.pointSize: 9
        opacity: 0.7
        Kirigami.FormData.label: ""
    }
    
    CheckBox {
        id: autoRebuildField
        Kirigami.FormData.label: "Cache:"
        text: "Rebuild cache on startup"
    }
}
