import { App } from "astal/gtk4"
import style from "./style.css"
import SettingsWindow, { showTab } from "./widget/SettingsWindow"

App.start({
    css: style,
    main() {
        SettingsWindow()
    },
    // Clic droit sur wifi/bluetooth (voir modules/home/waybar) : "ags
    // request open:<tab>" affiche la fenêtre (toujours mappée) sur l'onglet
    // demandé, plutôt que "ags toggle" qui basculerait juste le mapping —
    // ici on veut *toujours* montrer le bon onglet, jamais fermer par erreur
    // si on clique sur un autre module pendant que la fenêtre est déjà
    // ouverte sur un autre onglet.
    requestHandler(request, res) {
        switch (request) {
            case "open:wifi":
            case "open:bluetooth":
            case "open:display":
                showTab(request.split(":")[1] as "wifi" | "bluetooth" | "display")
                res("ok")
                break
            default:
                res(`unknown request: ${request}`)
        }
    },
})
