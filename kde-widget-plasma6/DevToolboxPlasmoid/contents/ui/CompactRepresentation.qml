/*
 * Compact representation (Panel Icon)
 */

import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents

Item {
    id: compactRoot

    // Icon handling using IconLabel (more compatible across P5/P6)
    PlasmaComponents.IconLabel {
        id: icon
        anchors.fill: parent
        icon.name: "accessories-text-editor"
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
