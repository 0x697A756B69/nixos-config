import { bind } from "astal"
import { App, Astal, Gtk } from "astal/gtk4"
import AstalNetwork from "gi://AstalNetwork?version=0.1"
import { PANEL_WIDTH } from "../config"

const network = AstalNetwork.get_default()

// AccessPoint.activate(password, callback, target) : les réseaux ouverts se
// connectent directement (password=null) ; les réseaux protégés affichent un
// cadenas mais ne sont pas cliquables ici (pas de saisie de mot de passe :
// hors périmètre de ce dropdown "liste", voir mission partie 2.2).
function AccessPointRow(ap: AstalNetwork.AccessPoint) {
    const openNetwork = !ap.requiresPassword

    return <button
        cssClasses={["ap-row"]}
        sensitive={openNetwork}
        onClicked={() => { if (openNetwork) ap.activate(null, null, null) }}
    >
        <box spacing={8}>
            <label label={ap.ssid ?? "(réseau caché)"} hexpand halign={Gtk.Align.START} />
            {ap.requiresPassword && <label label="" cssClasses={["lock"]} />}
            <label label={`${ap.strength}%`} cssClasses={["strength"]} />
        </box>
    </button>
}

export default function NetworkPanel() {
    const wifi = network.wifi

    return <window
        name="network-panel"
        namespace="network-panel"
        visible={false}
        cssClasses={["Panel"]}
        exclusivity={Astal.Exclusivity.NORMAL}
        keymode={Astal.Keymode.ON_DEMAND}
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
        application={App}
    >
        <box vertical widthRequest={PANEL_WIDTH} cssClasses={["panel-box"]}>
            <box cssClasses={["panel-header"]}>
                <label label="Wi-Fi" hexpand halign={Gtk.Align.START} cssClasses={["panel-title"]} />
                <button
                    label=""
                    tooltipText="Rechercher des réseaux"
                    onClicked={() => { try { wifi?.scan() } catch (_) { } }}
                />
            </box>
            <box vertical cssClasses={["panel-list"]}>
                {wifi
                    ? bind(wifi, "access_points").as(aps =>
                        aps.length
                            ? aps.map(AccessPointRow)
                            : [<label label="Aucun réseau détecté" cssClasses={["empty"]} />])
                    : <label label="Pas d'interface Wi-Fi" cssClasses={["empty"]} />}
            </box>
        </box>
    </window>
}
