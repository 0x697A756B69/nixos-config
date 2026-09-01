import { Binding } from "astal"

// Icon button in place of the default (non-themable) GTK <switch>.
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
