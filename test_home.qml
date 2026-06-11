import QtQuick 2.15
import QtCore 5.15

Item {
    Component.onCompleted: {
        console.log("HOME: " + StandardPaths.writableLocation(StandardPaths.HomeLocation))
        Qt.quit()
    }
}
