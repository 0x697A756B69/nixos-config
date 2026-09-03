import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root
    visible: false
    color: "transparent"

    WlrLayershell.namespace: "power-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: 0

    function open() {
        root.visible = true
    }
    function close() {
        root.visible = false
    }
    function toggle() {
        if (root.visible) close()
        else open()
    }

    onVisibleChanged: if (visible) closeTimer.start()

    Timer {
        id: closeTimer
        interval: 50
        onTriggered: root.forceActiveFocus()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.78)
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 24

        Rectangle {
            Layout.preferredWidth: 110
            Layout.preferredHeight: 110
            radius: 22
            color: shutdownMouse.containsMouse ? Colors.c.error : Colors.baseGlassColor
            Behavior on color { ColorAnimation { duration: 120 } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "⏻"; font.pixelSize: 32; color: Colors.c.error }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Éteindre"; font.pixelSize: 13; color: Colors.c.text }
            }

            MouseArea {
                id: shutdownMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { Quickshell.execDetached(["systemctl", "poweroff"]) }
            }
        }

        Rectangle {
            Layout.preferredWidth: 110
            Layout.preferredHeight: 110
            radius: 22
            color: rebootMouse.containsMouse ? Colors.c.warning : Colors.baseGlassColor
            Behavior on color { ColorAnimation { duration: 120 } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰜉"; font.pixelSize: 32; color: Colors.c.warning }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Redémarrer"; font.pixelSize: 13; color: Colors.c.text }
            }

            MouseArea {
                id: rebootMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { Quickshell.execDetached(["systemctl", "reboot"]) }
            }
        }

        Rectangle {
            Layout.preferredWidth: 110
            Layout.preferredHeight: 110
            radius: 22
            color: lockMouse.containsMouse ? Colors.c.accent : Colors.baseGlassColor
            Behavior on color { ColorAnimation { duration: 120 } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰍾"; font.pixelSize: 32; color: Colors.c.accent }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Verrouiller"; font.pixelSize: 13; color: Colors.c.text }
            }

            MouseArea {
                id: lockMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { Quickshell.execDetached(["hyprlock"]); root.close() }
            }
        }
    }
}
