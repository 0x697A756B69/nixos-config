import { bind } from "astal"
import { Astal, Gtk } from "astal/gtk4"
import AstalNetwork from "gi://AstalNetwork?version=0.1"
import IconToggle from "./IconToggle"

const network = AstalNetwork.get_default()

// Réseaux ouverts uniquement : pas de saisie de mot de passe ici.
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
            {wifi && <IconToggle
                active={bind(wifi, "enabled")}
                onIcon="󰖩"
                offIcon="󰖪"
                tooltip="Activer/désactiver le Wi-Fi"
                onToggle={() => wifi.set_enabled(!wifi.enabled)}
            />}
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
