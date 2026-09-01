import QtQuick

// Icon button in place of a checkbox/switch: filled pill when active,
// transparent otherwise. Matches modules/home/ags/widget/IconToggle.tsx
// (kept for reference during the AGS -> Quickshell migration).
Rectangle {
    id: root

    property bool active: false
    property string onIcon: ""
    property string offIcon: ""
    property string tooltip: ""
    signal toggled()

    implicitWidth: 32
    implicitHeight: 32
    radius: 999
    color: active ? Colors.baseGlassColor : "transparent"

    Text {
        anchors.centerIn: parent
        text: root.active ? root.onIcon : root.offIcon
        color: root.active ? Colors.c.accent : Colors.c.text_alt
        font.pixelSize: 16
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
