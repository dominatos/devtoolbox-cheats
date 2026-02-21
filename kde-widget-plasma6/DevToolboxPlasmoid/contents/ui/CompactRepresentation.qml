/*
 * Compact representation (Panel Icon) — Plasma 6
 */

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    // Icon handling using Kirigami.Icon for Plasma 6 compatibility
    Kirigami.Icon {
        id: icon
        anchors.fill: parent
        source: "accessories-text-editor"
        opacity: mouseArea.containsMouse ? 1 : 0.8
    }

    // Hover-only mouse area for visual feedback
    // Click/expansion is handled by Plasmoid.onActivated in main.qml
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    Component.onCompleted: {
        console.log("[DevToolbox] CompactRepresentation loaded");
    }
}
