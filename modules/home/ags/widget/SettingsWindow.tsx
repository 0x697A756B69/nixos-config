import { Variable, bind } from "astal"
import { App, Astal, Gtk, astalify } from "astal/gtk4"
import WifiTab from "./WifiTab"
import BluetoothTab from "./BluetoothTab"
import DisplayTab, { refreshOnOpen as refreshDisplayTab } from "./DisplayTab"

// Gtk.ScrolledWindow n'est pas pré-emballé par astal/gtk4 (absent de
// widget.ts, contrairement à Box/Button/etc.) — même technique que le
// fichier source l'utilise pour ses propres widgets : astalify() est
// exporté publiquement pour ça (voir gtk4/index.ts).
const ScrolledWindow = astalify<Gtk.ScrolledWindow, Gtk.ScrolledWindow.ConstructorProps>(Gtk.ScrolledWindow)

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

// Point d'entrée unique pour changer d'onglet, que ce soit depuis la
// sidebar (clic interne) ou depuis "ags request open:X" (clic droit
// waybar, voir app.ts) — sans ça, cliquer "Écran" dans la sidebar
// contournerait le rafraîchissement de l'état HDR (refreshOnOpen).
function switchTo(tab: TabId) {
    activeTab.set(tab)
    if (tab === "display") refreshDisplayTab()
}

export function showTab(tab: TabId) {
    switchTo(tab)
    if (win) win.visible = true
}

// Tuile carrée (140x140, largeur = hauteur = largeur de la sidebar) plutôt
// qu'une ligne de texte — remplit toute la colonne.
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

// Un seul <box> par onglet, visibilité conditionnée par l'onglet actif
// (pattern déjà vérifié dans l'ancien NetworkPanel/BluetoothPanel — pas de
// <stack> GTK non testé ici). Contenu dans un ScrolledWindow : la fenêtre
// a une taille fixe (voir .panel-box), donc un onglet avec beaucoup de
// contenu (la liste de résolutions de l'onglet Écran) doit défiler plutôt
// que faire grandir la fenêtre.
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
        // Centrée comme le sélecteur d'app (rofi, voir modules/home/rofi/
        // config-layout.rasi) plutôt qu'ancrée sous l'encoche waybar :
        // aucun anchor posé, laisse le compositeur centrer la surface
        // layer-shell (comportement par défaut sans ancrage) — à confirmer
        // visuellement, pas de doc Astal explicite là-dessus.
        application={App}
        setup={self => { win = self }}
    >
        <box cssClasses={["panel-box"]} widthRequest={640} heightRequest={640}>
            <box vertical cssClasses={["sidebar"]} widthRequest={140} spacing={8}>
                {TABS.map(SidebarButton)}
                <box vexpand />
                <button cssClasses={["close-btn"]} onClicked={() => { if (win) win.visible = false }}>
                    <label label="Fermer" halign={Gtk.Align.START} hexpand />
                </button>
            </box>
            <box vertical cssClasses={["content"]} hexpand>
                {TabContainer("wifi", WifiTab())}
                {TabContainer("bluetooth", BluetoothTab())}
                {TabContainer("display", DisplayTab())}
            </box>
        </box>
    </window>
}
