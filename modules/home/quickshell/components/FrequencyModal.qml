import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../"

// Frequency picker as an in-app Popup, instead of the old inline ListView
// that stretched the rest of the Display page's layout. Overlay modal so
// clicks outside close it; Escape also closes. The chosen mode is emitted
// via the `selected` signal, then the caller applies it through hyprctl.
Popup {
    id: freqModal

    property var modes: []
    property string currentMode: ""
    signal selected(string mode)

    width: 320
    height: Math.min(400, Math.max(140, modes.length * 46 + 88))
    anchors.centerIn: parent
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: Colors.c.panel
        radius: 16
        border.color: Colors.c.border
        border.width: 1
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.OutCubic }
        NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: 150; easing.type: Easing.OutCubic }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100; easing.type: Easing.InCubic }
        NumberAnimation { property: "scale"; from: 1; to: 0.95; duration: 100; easing.type: Easing.InCubic }
    }

    contentItem: ColumnLayout {
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 14
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 10

            Text {
                text: "Fréquence"
                font.bold: true
                font.pixelSize: 14
                color: Colors.c.text
                Layout.fillWidth: true
            }

            Text {
                text: "󰅃"
                color: Colors.c.text_alt
                font.pixelSize: 14
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            height: 1
            color: Colors.c.border
            opacity: 0.25
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 8
            clip: true
            spacing: 0

            model: freqModal.modes

            delegate: Item {
                id: freqDelegate
                required property var modelData
                property bool isCurrent: modelData === freqModal.currentMode

                width: ListView.view.width
                height: 46

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: 10
                    color: freqMouse.containsMouse && !freqDelegate.isCurrent
                        ? Colors.baseGlassColor : "transparent"

                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: freqDelegate.modelData.split("@")[1]
                        font.pixelSize: 13
                        color: freqDelegate.isCurrent ? Colors.c.disabled : Colors.c.text
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        visible: freqDelegate.isCurrent
                        width: 8
                        height: 8
                        radius: 4
                        color: Colors.c.accent
                    }
                }

                MouseArea {
                    id: freqMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !freqDelegate.isCurrent
                    cursorShape: freqDelegate.isCurrent ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        freqModal.selected(freqDelegate.modelData)
                        freqModal.close()
                    }
                }
            }
        }
    }
}
