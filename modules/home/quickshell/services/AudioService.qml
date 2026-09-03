pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// WirePlumber-backed audio service. Reads the sink/source lists from
// `wpctl status -n`, tracks the default output/input, and reads/sets the
// volume of each device individually via `wpctl get-volume` / `wpctl
// set-volume`. Volume of the *default sink* is also mirrored with pamixer
// (the waybar backend) so the master slider stays in sync with waybar.
Singleton {
    id: root

    // Each entry: { id, name, default }
    property var sinks: []
    property var sources: []
    // id -> volume (0..1)
    property var volumes: ({})
    property string defaultSinkId: ""
    property string defaultSourceId: ""
    property string defaultSinkDeviceId: ""
    property string defaultSourceDeviceId: ""
    property real masterVolume: 0
    property bool masterMuted: false
    property int refreshSeq: 0

    function refresh() {
        const seq = ++root.refreshSeq
        statusProc.refreshSeq = seq
        statusProc.exec(["wpctl", "status", "-n"])
    }

    function describe(name) {
        if (name.startsWith("bluez_")) {
            let out = name.replace(/bluez_output\./, "")
                        .replace(/bluez_input\./, "")
                        .replace(/bluez_card\./, "")
                        .replace(/bluez_capture_internal\./, "capture.")
            out = out.split(".")
            const mac = (out[0] || "").replace(/_/g, ":")
            const prof = (out[1] || "").replace(/\d+$/, "")
            const label = prof === "headset" ? "Casque"
                        : prof === "capture" ? "Capture interne"
                        : "Audio Bluetooth"
            return label + " · " + mac
        }
        if (!name.startsWith("alsa_")) return name
        let stripped = name.replace(/alsa_output\./, "")
                          .replace(/alsa_card\./, "")
        const toks = stripped.split(".")
        // toks[0] = pci-0000_01_00.1 ; last = profile (hdmi-stereo)
        const cardRaw = toks[0] || ""
        const card = cardRaw.replace(/_/g, " ").replace(/pci /, "PCI ")
        const suffix = (toks[toks.length - 1] || "")
            .replace(/stereo/i, "Stéréo")
            .replace(/hdmi/i, "HDMI")
            .replace(/analog/i, "Analogique")
        return card + " · " + suffix
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
                const sinksResult = []
                const sourcesResult = []
                let defaultSink = ""
                let defaultSource = ""
                for (const raw of lines) {
                    const line = raw.replace(/[│├└─]/g, ' ')
                    if (/^\s*Audio/.test(line)) { section = ""; continue }
                    if (/^\s*Video/.test(line)) { section = ""; continue }
                    if (/^\s*Settings/.test(line)) { section = ""; continue }
                    if (/\bSinks:/.test(line)) { section = "sinks"; continue }
                    if (/\bSources:/.test(line)) { section = "sources"; continue }
                    if (/^\s*Streams:/.test(line)) { section = ""; continue }
                    const m = line.match(/^\s*(\*)?\s*(\d+)\.\s+(\S+)/)
                    if (m) {
                        const isDefault = m[1] === "*"
                        const id = parseInt(m[2])
                        const name = m[3]
                        const entry = { id, name, default: isDefault }
                        if (section === "sinks") {
                            sinksResult.push(entry)
                            if (isDefault) { defaultSink = name; root.defaultSinkDeviceId = id.toString() }
                        } else if (section === "sources") {
                            sourcesResult.push(entry)
                            if (isDefault) { defaultSource = name; root.defaultSourceDeviceId = id.toString() }
                        }
                    }
                }
                root.sinks = sinksResult
                root.sources = sourcesResult
                root.defaultSinkId = defaultSink
                root.defaultSourceId = defaultSource
                root.refreshAllVolumes()
                root.refreshMaster()
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

    // Read volume (0..1) for one device id. Result lands in root.volumes.
    function readVolume(id) {
        const key = id.toString()
        if (key in root.volumes) return
        getVolProc.queue.push(key)
        if (!getVolProc.running) runNextVolume()
    }

    Process {
        id: getVolProc
        property var queue: []
        stdout: StdioCollector {
            onStreamFinished: {
                const key = getVolProc.currentKey
                const m = text.match(/Volume:\s*([0-9.]+)/)
                if (m) {
                    const v = parseFloat(m[1])
                    const vols = root.volumes
                    vols[key] = v
                    root.volumes = vols
                }
                getVolProc.currentKey = ""
                runNextVolume()
            }
        }
        property string currentKey: ""
    }

    function runNextVolume() {
        if (getVolProc.queue.length === 0) { getVolProc.running = false; return }
        const key = getVolProc.queue.shift()
        getVolProc.currentKey = key
        getVolProc.exec(["wpctl", "get-volume", key])
    }

    function refreshAllVolumes() {
        const ids = []
        for (const s of root.sinks) ids.push(s.id.toString())
        for (const s of root.sources) ids.push(s.id.toString())
        for (const k of ids) root.readVolume(k)
    }

    // Master volume + mute via pamixer (mirrors waybar backend).
    function refreshMaster() {
        volCheck.running = false
        volCheck.running = true
        mutedCheck.running = false
        mutedCheck.running = true
    }

    Process {
        id: volCheck
        command: ["pamixer", "--get-volume"]
        stdout: StdioCollector {
            onStreamFinished: root.masterVolume = (parseInt(text) || 0) / 100
        }
    }

    Process {
        id: mutedCheck
        command: ["pamixer", "--get-mute"]
        stdout: StdioCollector {
            onStreamFinished: root.masterMuted = text.trim() === "true"
        }
    }

    Process {
        id: setDefProc
    }

    function setDefaultSink(id) {
        setDefProc.exec(["wpctl", "set-default", id.toString()])
        timer.restart()
    }

    function setDefaultSource(id) {
        setDefProc.exec(["wpctl", "set-default", id.toString()])
        timer.restart()
    }

    Process {
        id: setVolProc
        property int targetId: 0
    }

    function setSinkVolume(id, v) {
        const vols = root.volumes
        vols[id.toString()] = v
        root.volumes = vols
        setVolProc.targetId = id
        setVolProc.exec(["wpctl", "set-volume", id.toString(), v.toFixed(2)])
        if (id.toString() === root.defaultSinkDeviceId) {
            setVolProc2.exec(["pamixer", "--set-volume", String(Math.round(v * 100))])
        }
        timer.restart()
    }

    Process {
        id: setVolProc2
    }

    function toggleMute() {
        pamixerExec.exec(["pamixer", "-t"])
        timer.restart()
    }

    Process {
        id: pamixerExec
    }

    Timer {
        id: timer
        interval: 400
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
