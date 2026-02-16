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

    TextField {
        id: editorField
        Kirigami.FormData.label: "Preferred Editor:"
        placeholderText: "code"
    }
    
    CheckBox {
        id: autoRebuildField
        Kirigami.FormData.label: "Cache:"
        text: "Rebuild cache on startup"
    }
}
