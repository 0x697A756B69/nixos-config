import { Variable, bind, execAsync } from "astal"
import { Gtk } from "astal/gtk4"
import AstalHyprland from "gi://AstalHyprland?version=0.1"

const hypr = AstalHyprland.get_default()

// AstalHyprland (AstalHyprland-0.1.gir) n'expose pas l'état HDR/color-
// management (pas de propriété dédiée sur Monitor), et sa propriété
// available-modes s'est révélée toujours `null` en conditions réelles sur
// ce matériel (vérifié directement : get_available_modes() renvoie null
// même après sync_monitors(), avant et après — pas un problème de timing).
// Les deux sont donc lus via `hyprctl -j monitors`, comme le faisait
// l'ancien module waybar custom/hdr + script wb-hdr (retirés, remplacés
// par cet onglet) pour HDR déjà. hdrOn suivi localement (seule cette app
// peut le changer désormais) ; availableModes resynchronisé à chaque
// ouverture d'onglet.
const hdrOn = Variable(false)
const availableModes = Variable<string[]>([])

function refreshMonitorInfo(monitorName: string) {
    execAsync(["hyprctl", "-j", "monitors"])
        .then(out => {
            const monitors = JSON.parse(out)
            const mon = monitors.find((m: { name: string }) => m.name === monitorName)
            if (mon) {
                hdrOn.set(mon.colorManagementPreset === "hdr" || mon.colorManagementPreset === "hdredid")
                availableModes.set(mon.availableModes ?? [])
            }
        })
        .catch(() => { })
}

// Le composant n'est construit qu'une fois (fenêtre toujours mappée, voir
// SettingsWindow.tsx) : ce n'est donc pas à la construction qu'il faut
// resynchroniser l'état mais à chaque ouverture de l'onglet — appelé
// depuis showTab() dans SettingsWindow.tsx.
export function refreshOnOpen() {
    const monitors = hypr.get_monitors()
    if (monitors[0]) refreshMonitorInfo(monitors[0].name)
}

// Un seul point d'écriture : reprend le mécanisme déjà en prod dans
// l'ancien wb-hdr (hyprctl eval "hl.monitor({...})"), en fournissant
// systématiquement l'état complet connu (mode/position/scale/cm/bitdepth)
// pour éviter qu'un changement partiel (ex. juste vrr) ne réinitialise le
// reste — vérifié en conditions réelles que `vrr` est un champ accepté par
// hl.monitor (bascule on/off confirmée via hyprctl monitors -j).
function applyMonitor(monitor: AstalHyprland.Monitor, overrides: {
    mode?: string
    scale?: number
    vrr?: boolean
}) {
    const mode = overrides.mode
        ?? `${monitor.width}x${monitor.height}@${monitor.refreshRate.toFixed(2)}`
    const scale = overrides.scale ?? monitor.scale
    const vrr = overrides.vrr ?? monitor.vrr
    const cm = hdrOn.get() ? "hdr" : "srgb"
    const bitdepth = hdrOn.get() ? 10 : 8
    execAsync(["hyprctl", "eval",
        `hl.monitor({ output = "${monitor.name}", mode = "${mode}", position = "${monitor.x}x${monitor.y}", scale = ${scale}, cm = "${cm}", bitdepth = ${bitdepth}, vrr = ${vrr} })`,
    ])
        .then(() => refreshMonitorInfo(monitor.name))
        .catch(() => { })
}

function ModeRow(monitor: AstalHyprland.Monitor, mode: string) {
    const current = `${monitor.width}x${monitor.height}@${monitor.refreshRate.toFixed(2)}Hz`
    return <button
        cssClasses={["list-row"]}
        sensitive={mode !== current}
        onClicked={() => applyMonitor(monitor, { mode: mode.replace("Hz", "") })}
    >
        <box spacing={8}>
            <label label={mode} halign={Gtk.Align.START} hexpand />
            {mode === current && <label label="actuel" cssClasses={["muted"]} />}
        </box>
    </button>
}

function MonitorSection(monitor: AstalHyprland.Monitor) {
    refreshMonitorInfo(monitor.name)

    return <box vertical>
        <label
            label={bind(monitor, "description").as(d => d || monitor.name)}
            halign={Gtk.Align.START}
            cssClasses={["tab-title"]}
        />

        <box cssClasses={["display-row"]}>
            <label label="HDR" hexpand halign={Gtk.Align.START} />
            <switch
                active={bind(hdrOn)}
                onNotifyActive={self => {
                    if (self.active !== hdrOn.get()) {
                        hdrOn.set(self.active)
                        applyMonitor(monitor, {})
                    }
                }}
            />
        </box>

        <box cssClasses={["display-row"]}>
            <label label="VRR" hexpand halign={Gtk.Align.START} />
            <switch
                active={bind(monitor, "vrr")}
                onNotifyActive={self => {
                    if (self.active !== monitor.vrr) applyMonitor(monitor, { vrr: self.active })
                }}
            />
        </box>

        <box cssClasses={["display-row"]}>
            <label label="Échelle" hexpand halign={Gtk.Align.START} />
            <label label={bind(monitor, "scale").as(s => `${s.toFixed(2)}×`)} cssClasses={["muted"]} />
            <button
                label="−"
                sensitive={bind(monitor, "scale").as(s => s > 1.0)}
                onClicked={() => applyMonitor(monitor, { scale: Math.max(1.0, monitor.scale - 0.05) })}
            />
            <button
                label="+"
                sensitive={bind(monitor, "scale").as(s => s < 2.0)}
                onClicked={() => applyMonitor(monitor, { scale: Math.min(2.0, monitor.scale + 0.05) })}
            />
        </box>

        <label label="Résolution / taux de rafraîchissement" halign={Gtk.Align.START} cssClasses={["muted"]} />
        <box vertical>
            {bind(availableModes).as(modes => modes.map(m => ModeRow(monitor, m)))}
        </box>
    </box>
}

export default function DisplayTab() {
    return <box vertical>
        {bind(hypr, "monitors").as(monitors =>
            monitors.length
                ? MonitorSection(monitors[0])
                : <label label="Aucun écran détecté" cssClasses={["empty"]} />)}
    </box>
}
