import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "pages"

// Full-screen transparent layer-shell surface; the visible card is an
// ordinary Item inside it, centered by default and freely draggable once
// moved — same mechanism as end-4's Settings.qml (PanelWindowInterface
// itself has no x/y to drag, only anchors/margins for the whole output).
PanelWindow {
    id: root
    visible: false
    color: "transparent"
    exclusiveZone: 0

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "settings-window"
    WlrLayershell.layer: WlrLayer.Overlay
    // ON_DEMAND doesn't grab keyboard focus just by becoming visible (same
    // gotcha hit on the GTK4/Astal version) — forceActiveFocus() below is
    // what actually requests it from the compositor.
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onVisibleChanged: if (visible) card.forceActiveFocus()

    property string currentTab: "wifi"
    readonly property var tabs: [
        { id: "wifi", label: "Wi-Fi", icon: "󰖩" },
        { id: "bluetooth", label: "Bluetooth", icon: "󰂯" },
        { id: "display", label: "Écran", icon: "󰍹" }
    ]

    // Single entry point for tab switching (rail or IPC): guarantees the
    // HDR/VRR refresh on every switch to the Display tab.
    function switchTo(tab) {
        root.currentTab = tab
        if (tab === "display") displayPage.refresh()
    }

    function open() { root.visible = true }
    function toggle() { root.visible = !root.visible }
    function openTab(tab) { switchTo(tab); root.visible = true }

    // Click outside the card closes it.
    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        id: card
        width: 640
        height: 640
        radius: 22
        color: Colors.panelColor

        property bool userMoved: false
        anchors.centerIn: userMoved ? undefined : parent

        focus: root.visible
        Keys.onEscapePressed: root.visible = false

        // Swallows clicks so the background MouseArea above doesn't see
        // them and close the window while interacting with the card.
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        MouseArea {
            id: dragHandle
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 28
            cursorShape: Qt.SizeAllCursor
            drag.target: card
            onPressed: card.userMoved = true
            onDoubleClicked: card.userMoved = false
        }

        RowLayout {
            anchors.top: dragHandle.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
            spacing: 12

            // Nav rail: its own rounded surface, pill highlight on the
            // active tab (Material NavigationRail look, matugen colors).
            Rectangle {
                id: navRail
                Layout.fillHeight: true
                Layout.preferredWidth: 190
                radius: 17
                color: Colors.panelColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    Repeater {
                        model: root.tabs
                        delegate: Rectangle {
                            id: navBtn
                            required property var modelData
                            readonly property bool active: root.currentTab === modelData.id
                            Layout.fillWidth: true
                            implicitHeight: 40
                            radius: 999
                            color: active ? Colors.c.accent
                                : (navBtnMouse.containsMouse ? Colors.baseGlassColor : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 10

                                Text {
                                    text: navBtn.modelData.icon
                                    font.pixelSize: 16
                                    color: navBtn.active ? Colors.c.on_accent : Colors.c.text
                                }
                                Text {
                                    text: navBtn.modelData.label
                                    font.bold: true
                                    font.pixelSize: 14
                                    color: navBtn.active ? Colors.c.on_accent : Colors.c.text
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                id: navBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.switchTo(navBtn.modelData.id)
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                WifiPage {
                    anchors.fill: parent
                    visible: root.currentTab === "wifi"
                }
                BluetoothPage {
                    anchors.fill: parent
                    visible: root.currentTab === "bluetooth"
                }
                DisplayPage {
                    id: displayPage
                    anchors.fill: parent
                    visible: root.currentTab === "display"
                }
            }
        }
    }
}
