import { App } from "astal/gtk4"
import style from "./style.css"
import SettingsWindow, { showTab, openSettings } from "./widget/SettingsWindow"

App.start({
    css: style,
    main() {
        SettingsWindow()
    },
    // open:<tab> force l'onglet et affiche la fenêtre ; open garde l'onglet actif et toggle.
    requestHandler(request, res) {
        switch (request) {
            case "open:wifi":
            case "open:bluetooth":
            case "open:display":
                showTab(request.split(":")[1] as "wifi" | "bluetooth" | "display")
                res("ok")
                break
            case "open":
                openSettings()
                res("ok")
                break
            default:
                res(`unknown request: ${request}`)
        }
    },
})
