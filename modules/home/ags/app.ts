import { App } from "astal/gtk4"
import style from "./style.css"
import NetworkPanel from "./widget/NetworkPanel"
import BluetoothPanel from "./widget/BluetoothPanel"

App.start({
    instanceName: "waybar-dropdown",
    css: style,
    main() {
        NetworkPanel()
        BluetoothPanel()
    },
})
