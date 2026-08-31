import { bind } from "astal"
import { App, Astal, Gtk } from "astal/gtk4"
import AstalBluetooth from "gi://AstalBluetooth?version=0.1"
import { PANEL_WIDTH } from "../config"

const bluetooth = AstalBluetooth.get_default()

function DeviceRow(device: AstalBluetooth.Device) {
    return <button
        cssClasses={["bt-row"]}
        onClicked={() => {
            try {
                if (device.connected) device.disconnect_device(null, null)
                else device.connect_device(null, null)
            } catch (_) { }
        }}
    >
        <box spacing={8}>
            <label label={device.name ?? device.address} hexpand halign={Gtk.Align.START} />
            {bind(device, "battery_percentage").as(pct =>
                pct >= 0 ? <label label={`${pct}%`} cssClasses={["battery"]} /> : <box visible={false} />)}
            <label
                label={bind(device, "connected").as(c => c ? "Connecté" : "Appairé")}
                cssClasses={["state"]}
                visible={bind(device, "paired")}
            />
        </box>
    </button>
}

export default function BluetoothPanel() {
    return <window
        namespace="bluetooth-panel"
        visible={false}
        cssClasses={["Panel"]}
        exclusivity={Astal.Exclusivity.NORMAL}
        keymode={Astal.Keymode.ON_DEMAND}
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
        application={App}
    >
        <box vertical widthRequest={PANEL_WIDTH} cssClasses={["panel-box"]}>
            <box cssClasses={["panel-header"]}>
                <label label="Bluetooth" hexpand halign={Gtk.Align.START} cssClasses={["panel-title"]} />
                <switch
                    active={bind(bluetooth, "is_powered")}
                    onNotifyActive={self => { if (self.active !== bluetooth.isPowered) bluetooth.toggle() }}
                />
                <button
                    label=""
                    tooltipText="Rechercher des appareils"
                    onClicked={() => { try { bluetooth.adapter?.start_discovery() } catch (_) { } }}
                />
            </box>
            <box vertical cssClasses={["panel-list"]}>
                {bind(bluetooth, "devices").as(devices =>
                    devices.length
                        ? devices.map(DeviceRow)
                        : [<label label="Aucun appareil" cssClasses={["empty"]} />])}
            </box>
        </box>
    </window>
}
