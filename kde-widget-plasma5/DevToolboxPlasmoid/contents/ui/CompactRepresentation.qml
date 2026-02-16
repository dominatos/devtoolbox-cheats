/*
 * Compact representation (Panel Icon)
 */

import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

Item {
    id: compactRoot

    // Icon handling for Plasma 5
    PlasmaCore.IconItem {
        id: icon
        anchors.fill: parent
        source: "accessories-text-editor"
        opacity: mouseArea.containsMouse ? 1 : 0.8
    }

    // Mouse handling
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: plasmoid.expanded = !plasmoid.expanded
    }

    // Simple tooltip for compatibility
    PlasmaComponents.ToolTip {
        visible: mouseArea.containsMouse
        text: plasmoid.title || "DevToolbox Cheats"
    }
}
