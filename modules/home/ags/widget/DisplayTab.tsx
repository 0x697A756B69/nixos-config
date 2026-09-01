import { Variable, bind, execAsync } from "astal"
import { Gtk } from "astal/gtk4"
import AstalHyprland from "gi://AstalHyprland?version=0.1"
import IconToggle from "./IconToggle"

const hypr = AstalHyprland.get_default()

// AstalHyprland n'expose ni l'état HDR ni des available-modes fiables
// (toujours null sur ce matériel) : les deux sont lus via `hyprctl -j monitors`.
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

// Appelé depuis showTab() : le composant n'est construit qu'une fois
// (fenêtre toujours mappée), donc resync à l'ouverture, pas à la construction.
export function refreshOnOpen() {
    const monitors = hypr.get_monitors()
    if (monitors[0]) refreshMonitorInfo(monitors[0].name)
}

// Un seul point d'écriture : envoie toujours l'état complet connu
// (mode/position/scale/cm/bitdepth/vrr) pour éviter qu'un changement
// partiel ne réinitialise le reste.
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
            <IconToggle
                active={bind(hdrOn)}
                onIcon="󰵽"
                offIcon="󰵾"
                tooltip="Activer/désactiver le HDR"
                onToggle={() => {
                    hdrOn.set(!hdrOn.get())
                    applyMonitor(monitor, {})
                }}
            />
        </box>

        <box cssClasses={["display-row"]}>
            <label label="VRR" hexpand halign={Gtk.Align.START} />
            <IconToggle
                active={bind(monitor, "vrr")}
                onIcon="󰓦"
                offIcon="󰓨"
                tooltip="Activer/désactiver le taux de rafraîchissement variable"
                onToggle={() => applyMonitor(monitor, { vrr: !monitor.vrr })}
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
        <box spacing={8}>
            {bind(availableModes).as(modes => {
                const mid = Math.ceil(modes.length / 2)
                const columns = [modes.slice(0, mid), modes.slice(mid)]
                return columns.map(col =>
                    <box vertical hexpand>
                        {col.map(m => ModeRow(monitor, m))}
                    </box>)
            })}
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
