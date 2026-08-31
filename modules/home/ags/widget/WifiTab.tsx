import { bind } from "astal"
import { Astal, Gtk } from "astal/gtk4"
import AstalNetwork from "gi://AstalNetwork?version=0.1"

const network = AstalNetwork.get_default()

// AccessPoint.activate(password, callback, target) : les réseaux ouverts se
// connectent directement (password=null) ; les réseaux protégés affichent un
// cadenas mais ne sont pas cliquables ici (pas de saisie de mot de passe :
// hors périmètre de cette app, une vraie boîte de dialogue serait une
// fonctionnalité à part entière).
function AccessPointRow(ap: AstalNetwork.AccessPoint) {
    const openNetwork = !ap.requiresPassword

    return <button
        cssClasses={["list-row"]}
        sensitive={openNetwork}
        onClicked={() => { if (openNetwork) ap.activate(null, null, null) }}
    >
        <box spacing={8}>
            <label label={ap.ssid ?? "(réseau caché)"} hexpand halign={Gtk.Align.START} />
            {ap.requiresPassword && <label label="" cssClasses={["muted"]} />}
            <label label={`${ap.strength}%`} cssClasses={["muted"]} />
        </box>
    </button>
}

export default function WifiTab() {
    const wifi = network.wifi

    return <box vertical>
        <box>
            <label label="Wi-Fi" hexpand halign={Gtk.Align.START} cssClasses={["tab-title"]} />
            <button
                label=""
                tooltipText="Rechercher des réseaux"
                onClicked={() => { try { wifi?.scan() } catch (_) { } }}
            />
        </box>
        <box vertical>
            {wifi
                ? bind(wifi, "access_points").as(aps =>
                    aps.length
                        ? aps.map(AccessPointRow)
                        : [<label label="Aucun réseau détecté" cssClasses={["empty"]} />])
                : <label label="Pas d'interface Wi-Fi" cssClasses={["empty"]} />}
        </box>
    </box>
}
