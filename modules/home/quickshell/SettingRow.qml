import QtQuick
import QtQuick.Layouts

// Plain icon+label row with a thin bottom divider and a right-aligned
// control — the pattern used throughout the repo's actual Settings pages
// (see screenshots/6.png, Displays page): no card/segment background here.
Item {
    id: row

    property string icon: ""
    property string label: ""
    property bool clickable: false
    default property alias content: controlArea.data
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 44

    MouseArea {
        anchors.fill: parent
        enabled: row.clickable
        hoverEnabled: true
        cursorShape: row.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: row.clicked()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            text: row.icon
            font.pixelSize: 15
            color: Colors.c.text_alt
        }
        Text {
            text: row.label
            color: Colors.c.text
            Layout.fillWidth: true
        }
        RowLayout {
            id: controlArea
            spacing: 6
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Colors.c.border
        opacity: 0.25
    }
}
