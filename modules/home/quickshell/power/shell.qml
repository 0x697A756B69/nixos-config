import Quickshell
import Quickshell.Io

ShellRoot {
    PowerMenu {
        id: powerMenu
    }

    IpcHandler {
        target: "power"
        function toggle(): void { powerMenu.toggle() }
        function open(): void { powerMenu.open() }
    }
}
