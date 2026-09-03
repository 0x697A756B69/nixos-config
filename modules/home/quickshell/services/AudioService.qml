pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// WirePlumber-backed audio service. Unlike the GTK pavucontrol / plain
// pamixer approach, this reads the *sink list* via `wpctl status` so the
// settings app can list every output device (HDMI, optical, etc.) and pick
// the default, plus per-device volume. Volume of the default sink still uses
// pamixer (already the volume backend for waybar, so master slider and
// waybar stay in sync) — wpctl's own volume control would be a second,
// inconsistent path.
Singleton {
    id: root

    // Parsed sinks: [ { id, name, description, default, volume } ]
    property var sinks: []
    property string defaultSinkId: ""
    property real masterVolume: 0
    // Number of the refresh currently in flight, to ignore stale stdout.
    property int refreshSeq: 0

    function refresh() {
        const seq = ++root.refreshSeq
        statusProc.exec(["wpctl", "status", "-n"])
        // capture the seq we just started; stdout handler compares against it
        statusProc.refreshSeq = seq
    }

    // Human-friendly description: nix store style node names are ugly, so
    // clean "alsa_output.pci-0000_01_00.1.hdmi-stereo" into
    // "PCI 0000:01:00.1 HDMI Stéréo".
    function describe(name) {
        let out = name
        out = out.replace(/alsa_output\./, "")
        out = out.replace(/alsa_card\./, "")
        out = out.replace(/_/g, " ")
        out = out.split(".")
        // keep card part + last eligible token as the display suffix
        const toks = out
        const card = toks[0] || ""
        const readable = card.replace(/pci /, "PCI ")
        const suffix = toks[toks.length - 2] || ""
        const suffixReadable = suffix.replace(/stereo/i, "Stéréo")
        const cleaned = suffixReadable.replace(/hdmi/i, "HDMI")
        return readable + " · " + cleaned
    }

    Process {
        id: statusProc
        property int refreshSeq: 0
        command: ["wpctl", "status", "-n"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (statusProc.refreshSeq !== root.refreshSeq) return
                const lines = text.split("\n")
                let section = ""
                const result = []
                for (const raw of lines) {
                    const line = raw
                    if (/^\s*Audio/.test(line)) { section = "sinks"; continue }
                    if (/^\s*(Video|Settings)/.test(line)) { section = ""; continue }
                    if (section !== "sinks") continue
                    if (/├─/.test(line)) continue
                    const m = line.match(/^\s*(\*)?\s*(\d+)\.\s+(\S+)/)
                    if (m) {
                        const isDefault = m[1] === "*"
                        const id = parseInt(m[2])
                        const name = m[3]
                        result.push({ id, name, default: isDefault })
                        if (isDefault) root.defaultSinkId = name
                    }
                }
                root.sinks = result
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (statusProc.refreshSeq !== root.refreshSeq) return
                if (text.trim().length) {
                    Quickshell.execDetached(["notify-send", "-u", "critical", "-t", "4000", "Audio", text.trim()])
                }
            }
        }
    }

    Process {
        id: setDefProc
    }

    function setDefaultSink(id) {
        setDefProc.exec(["wpctl", "set-default", id.toString()])
        timer.restart()
    }

    Process {
        id: setVolProc
    }

    function setMasterVolume(vol) {
        // clamp 0..1.5
        setVolProc.exec(["pamixer", "--set-volume", Math.round(vol * 150).toString()])
    }

    function setSinkVolume(id, vol) {
        setVolProc.exec(["wpctl", "set-volume", id.toString(), vol.toFixed(2)])
    }

    Timer {
        id: timer
        interval: 400
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
