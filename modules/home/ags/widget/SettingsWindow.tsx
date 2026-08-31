import { Variable, bind } from "astal"
import { App, Astal, Gtk } from "astal/gtk4"
import WifiTab from "./WifiTab"

export type TabId = "wifi" | "bluetooth" | "display"

const TABS: { id: TabId; label: string }[] = [
    { id: "wifi", label: "Wi-Fi" },
    { id: "bluetooth", label: "Bluetooth" },
    { id: "display", label: "Écran" },
]

const activeTab = Variable<TabId>("wifi")

// Référence remplie par `setup` à la construction (voir _astal.ts:
// construct() invoque `setup(self)` une fois le widget créé) — permet de
// piloter `visible` depuis app.ts sans passer par `ags toggle` (voir
// commentaire dans app.ts sur pourquoi : on veut ouvrir/basculer d'onglet,
// jamais fermer par erreur depuis un autre module).
let win: Astal.Window | null = null

export function showTab(tab: TabId) {
    activeTab.set(tab)
    if (win) win.visible = true
}

function SidebarButton({ id, label }: { id: TabId; label: string }) {
    return <button
        cssClasses={bind(activeTab).as(t => t === id ? ["sidebar-btn", "active"] : ["sidebar-btn"])}
        onClicked={() => activeTab.set(id)}
    >
        <label label={label} halign={Gtk.Align.START} hexpand />
    </button>
}

// Un seul <box> par onglet, visibilité conditionnée par l'onglet actif
// (pattern déjà vérifié dans l'ancien NetworkPanel/BluetoothPanel — pas de
// <stack> GTK non testé ici).
function TabContainer(id: TabId, child: Gtk.Widget) {
    return <box visible={bind(activeTab).as(t => t === id)} cssClasses={["tab-content"]}>
        {child}
    </box>
}

// Placeholder : remplacé par de vrais composants (BluetoothTab/DisplayTab)
// aux étapes suivantes du plan.
function TabPlaceholder(id: TabId, text: string) {
    return TabContainer(id, <label label={text} />)
}

export default function SettingsWindow() {
    return <window
        name="settings-window"
        namespace="settings-window"
        visible={false}
        cssClasses={["Panel"]}
        exclusivity={Astal.Exclusivity.NORMAL}
        keymode={Astal.Keymode.ON_DEMAND}
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
        application={App}
        setup={self => { win = self }}
    >
        <box cssClasses={["panel-box"]}>
            <box vertical cssClasses={["sidebar"]}>
                {TABS.map(SidebarButton)}
                <box vexpand />
                <button cssClasses={["close-btn"]} onClicked={() => { if (win) win.visible = false }}>
                    <label label="Fermer" halign={Gtk.Align.START} hexpand />
                </button>
            </box>
            <box vertical cssClasses={["content"]}>
                {TabContainer("wifi", WifiTab())}
                {TabPlaceholder("bluetooth", "Bluetooth — à venir")}
                {TabPlaceholder("display", "Écran — à venir")}
            </box>
        </box>
    </window>
}
