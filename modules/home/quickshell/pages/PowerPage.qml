import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../"

// Power actions: Éteindre / Redémarrer / Verrouiller (desktop, no battery
// profile needed). Direct systemd + hyprlock calls — same tools the rofi
// power-menu used, now natively in the settings app (Wayland, themed).
Item {
    id: root

    property alias shutdownMenu: shutdownMenu
    property alias rebootMenu: rebootMenu

    function doShutdown() { Quickshell.execDetached(["systemctl", "poweroff"]) }
    function doReboot()   { Quickshell.execDetached(["systemctl", "reboot"]) }
    function doLock()     { Quickshell.execDetached(["hyprlock"]) }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Text {
            text: "Alimentation"
            font.bold: true
            font.pixelSize: 15
            color: Colors.c.text
            Layout.fillWidth: true
            Layout.bottomMargin: 16
        }

        Text {
            text: "Une action rapide désactivera Hyprland immédiatement."
            font.italic: true
            font.pixelSize: 11
            color: Colors.c.text_alt
            Layout.fillWidth: true
            Layout.bottomMargin: 16
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            columns: 2
            rowSpacing: 12
            columnSpacing: 12

            // --- Éteindre ---
            Rectangle {
                id: cardShutdown
                Layout.fillWidth: true
                Layout.preferredHeight: 96
                radius: 16
                color: Colors.baseGlassColor

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "⏻"
                        font.pixelSize: 26
                        color: Colors.c.error
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Éteindre"
                        font.pixelSize: 12
                        color: Colors.c.text
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: shutdownMenu.open()
                }
            }

            // --- Redémarrer ---
            Rectangle {
                id: cardReboot
                Layout.fillWidth: true
                Layout.preferredHeight: 96
                radius: 16
                color: Colors.baseGlassColor

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰜉"
                        font.pixelSize: 26
                        color: Colors.c.warning
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Redémarrer"
                        font.pixelSize: 12
                        color: Colors.c.text
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rebootMenu.open()
                }
            }

            // --- Verrouiller ---
            Rectangle {
                id: cardLock
                Layout.fillWidth: true
                Layout.preferredHeight: 96
                radius: 16
                color: Colors.baseGlassColor

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰍾"
                        font.pixelSize: 26
                        color: Colors.c.accent
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Verrouiller"
                        font.pixelSize: 12
                        color: Colors.c.text
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.doLock()
                }
            }
        }
    }

    // --- Confirmation Éteindre ---
    Popup {
        id: shutdownMenu
        width: 320
        anchors.centerIn: parent
        modal: true
        focus: true

        background: Rectangle { color: Colors.c.panel; radius: 16; border.color: Colors.c.border }

        contentItem: ColumnLayout {
            spacing: 14

            Text {
                text: "Éteindre la machine ?"
                font.bold: true
                color: Colors.c.text
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: 10
                    color: Colors.baseGlassColor
                    Text {
                        anchors.centerIn: parent
                        text: "Annuler"
                        font.pixelSize: 13
                        color: Colors.c.text
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: shutdownMenu.close()
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: 10
                    color: Colors.c.error
                    Text {
                        anchors.centerIn: parent
                        text: "Éteindre"
                        font.pixelSize: 13
                        color: Colors.c.on_accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.doShutdown()
                    }
                }
            }
        }
    }

    // --- Confirmation Redémarrer ---
    Popup {
        id: rebootMenu
        width: 320
        anchors.centerIn: parent
        modal: true
        focus: true

        background: Rectangle { color: Colors.c.panel; radius: 16; border.color: Colors.c.border }

        contentItem: ColumnLayout {
            spacing: 14

            Text {
                text: "Redémarrer la machine ?"
                font.bold: true
                color: Colors.c.text
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: 10
                    color: Colors.baseGlassColor
                    Text {
                        anchors.centerIn: parent
                        text: "Annuler"
                        font.pixelSize: 13
                        color: Colors.c.text
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rebootMenu.close()
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: 10
                    color: Colors.c.warning
                    Text {
                        anchors.centerIn: parent
                        text: "Redémarrer"
                        font.pixelSize: 13
                        color: Colors.c.on_accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.doReboot()
                    }
                }
            }
        }
    }
}
