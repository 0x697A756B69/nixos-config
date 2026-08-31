import { bind } from "astal"
import { Gtk } from "astal/gtk4"
import AstalBluetooth from "gi://AstalBluetooth?version=0.1"

const bluetooth = AstalBluetooth.get_default()

function DeviceRow(device: AstalBluetooth.Device) {
    return <button
        cssClasses={["list-row"]}
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
                pct >= 0 ? <label label={`${pct}%`} cssClasses={["muted"]} /> : <box visible={false} />)}
            <label
                label={bind(device, "connected").as(c => c ? "Connecté" : "Appairé")}
                cssClasses={["muted"]}
                visible={bind(device, "paired")}
            />
        </box>
    </button>
}

export default function BluetoothTab() {
    return <box vertical>
        <box>
            <label label="Bluetooth" hexpand halign={Gtk.Align.START} cssClasses={["tab-title"]} />
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
        <box vertical>
            {bind(bluetooth, "devices").as(devices =>
                devices.length
                    ? devices.map(DeviceRow)
                    : [<label label="Aucun appareil" cssClasses={["empty"]} />])}
        </box>
    </box>
}
