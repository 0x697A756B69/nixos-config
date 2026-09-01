import Quickshell
import Quickshell.Io

ShellRoot {
    SettingsWindow {
        id: settingsWindow
    }

    // Mirrors the previous `ags request open[:tab]` interface:
    // `quickshell ipc call settings toggle|open|openTab <tab>`.
    IpcHandler {
        target: "settings"
        function toggle(): void { settingsWindow.toggle() }
        function open(): void { settingsWindow.open() }
        function openTab(tab: string): void { settingsWindow.openTab(tab) }
    }
}
