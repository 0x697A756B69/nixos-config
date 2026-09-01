import { Variable, bind } from "astal"
import { App, Astal, Gtk, astalify } from "astal/gtk4"
import WifiTab from "./WifiTab"
import BluetoothTab from "./BluetoothTab"
import DisplayTab, { refreshOnOpen as refreshDisplayTab } from "./DisplayTab"

// Gtk.ScrolledWindow isn't pre-wrapped by astal/gtk4, hence astalify().
const ScrolledWindow = astalify<Gtk.ScrolledWindow, Gtk.ScrolledWindow.ConstructorProps>(Gtk.ScrolledWindow)

export type TabId = "wifi" | "bluetooth" | "display"

const TABS: { id: TabId; label: string }[] = [
    { id: "wifi", label: "Wi-Fi" },
    { id: "bluetooth", label: "Bluetooth" },
    { id: "display", label: "Écran" },
]

const activeTab = Variable<TabId>("wifi")

// Filled by `setup` at construction, so app.ts can drive `visible`.
let win: Astal.Window | null = null

// Single entry point for tab switching (sidebar or requestHandler):
// guarantees the HDR refresh on every switch to the Display tab.
function switchTo(tab: TabId) {
    activeTab.set(tab)
    if (tab === "display") refreshDisplayTab()
}

export function showTab(tab: TabId) {
    switchTo(tab)
    if (win) win.visible = true
}

// Generic toggle (waybar settings icon): keeps the current tab.
export function openSettings() {
    if (win) win.visible = !win.visible
}

// Square tile filling the whole column (140x140).
function SidebarButton({ id, label }: { id: TabId; label: string }) {
    return <button
        cssClasses={bind(activeTab).as(t => t === id ? ["sidebar-btn", "active"] : ["sidebar-btn"])}
        onClicked={() => switchTo(id)}
        widthRequest={140}
        heightRequest={140}
        hexpand
    >
        <label label={label} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} hexpand vexpand />
    </button>
}

// One <box> per tab, visibility gated on the active tab.
// ScrolledWindow: the window has a fixed size, content must scroll instead.
function TabContainer(id: TabId, child: Gtk.Widget) {
    return <box visible={bind(activeTab).as(t => t === id)} cssClasses={["tab-content"]} vexpand>
        <ScrolledWindow vexpand hscrollbarPolicy={Gtk.PolicyType.NEVER} vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}>
            {child}
        </ScrolledWindow>
    </box>
}

export default function SettingsWindow() {
    return <window
        name="settings-window"
        namespace="settings-window"
        visible={false}
        cssClasses={["Panel"]}
        exclusivity={Astal.Exclusivity.NORMAL}
        keymode={Astal.Keymode.ON_DEMAND}
        // No anchor: the layer-shell surface centers itself by default.
        application={App}
        setup={self => { win = self }}
    >
        <box cssClasses={["panel-box"]} widthRequest={640} heightRequest={640}>
            <box vertical cssClasses={["sidebar"]} widthRequest={140} spacing={8}>
                {TABS.map(SidebarButton)}
                <box vexpand />
            </box>
            <box vertical cssClasses={["content"]} hexpand>
                {TabContainer("wifi", WifiTab())}
                {TabContainer("bluetooth", BluetoothTab())}
                {TabContainer("display", DisplayTab())}
            </box>
        </box>
    </window>
}
