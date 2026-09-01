import { Binding } from "astal"

// Remplace les <switch> GTK (rendu Adwaita par défaut, non thémable et jugé
// trop basique) par un bouton-icône : glyphes Nerd Font vérifiés dans
// glyphnames.json (nf-md-bluetooth/_off, nf-md-wifi/_off — voir appelants),
// teinte via .icon-toggle.active plutôt qu'un état on/off générique.
export default function IconToggle({ active, onIcon, offIcon, onToggle, tooltip }: {
    active: Binding<boolean>
    onIcon: string
    offIcon: string
    onToggle: () => void
    tooltip?: string
}) {
    return <button
        cssClasses={active.as(a => a ? ["icon-toggle", "active"] : ["icon-toggle"])}
        tooltipText={tooltip}
        onClicked={onToggle}
    >
        <label label={active.as(a => a ? onIcon : offIcon)} />
    </button>
}
