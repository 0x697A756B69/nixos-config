import { Variable, bind } from "astal"
import { App, Astal, Gtk, astalify } from "astal/gtk4"
import WifiTab from "./WifiTab"
import BluetoothTab from "./BluetoothTab"
import DisplayTab, { refreshOnOpen as refreshDisplayTab } from "./DisplayTab"

// Gtk.ScrolledWindow n'est pas pré-emballé par astal/gtk4, d'où astalify().
const ScrolledWindow = astalify<Gtk.ScrolledWindow, Gtk.ScrolledWindow.ConstructorProps>(Gtk.ScrolledWindow)

export type TabId = "wifi" | "bluetooth" | "display"

const TABS: { id: TabId; label: string }[] = [
    { id: "wifi", label: "Wi-Fi" },
    { id: "bluetooth", label: "Bluetooth" },
    { id: "display", label: "Écran" },
]

const activeTab = Variable<TabId>("wifi")

// Rempli par `setup` à la construction, pour piloter `visible` depuis app.ts.
let win: Astal.Window | null = null

// Point d'entrée unique pour changer d'onglet (sidebar ou requestHandler) :
// garantit le refresh HDR à chaque passage sur l'onglet Écran.
function switchTo(tab: TabId) {
    activeTab.set(tab)
    if (tab === "display") refreshDisplayTab()
}

export function showTab(tab: TabId) {
    switchTo(tab)
    if (win) win.visible = true
}

// Toggle générique (icône réglages waybar) : garde l'onglet actif.
export function openSettings() {
    if (win) win.visible = !win.visible
}

// Tuile carrée remplissant toute la colonne (140x140).
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

// Un <box> par onglet, visibilité conditionnée sur l'onglet actif.
// ScrolledWindow : la fenêtre a une taille fixe, le contenu doit défiler.
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
        // Pas d'anchor : la surface layer-shell se centre par défaut.
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
