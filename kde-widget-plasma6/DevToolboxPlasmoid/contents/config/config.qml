/*
 * Configuration model for DevToolbox Cheats Plasmoid
 * This file tells Plasma which configuration pages exist
 */

import QtQuick 2.15
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "configGeneral.qml"
    }
}
