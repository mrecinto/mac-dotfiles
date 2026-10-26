import AppKit
import CoreGraphics
import Foundation

// Window metadata (layers and bounds) needs no screen recording permission.
func menuIsOpen() -> Bool {
    guard let windows = CGWindowListCopyWindowInfo(
        [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
    ) as? [[String: Any]] else { return false }
    return windows.contains { window in
        let layer = window[kCGWindowLayer as String] as? Int ?? 0
        // Native dropdown and popup menu levels. Exclude SketchyBar itself.
        let owner = window[kCGWindowOwnerName as String] as? String ?? ""
        return layer == Int(CGWindowLevelForKey(.popUpMenuWindow)) &&
            owner.lowercased() != "sketchybar"
    }
}

let barPath = CommandLine.arguments.dropFirst().first ?? "/opt/homebrew/bin/sketchybar"
func setHidden(_ hidden: Bool) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: barPath)
    process.arguments = ["--bar", "hidden=\(hidden ? "on" : "off")", "y_offset=0"]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    do { try process.run(); process.waitUntilExit() }
    catch { fputs("menu-bridge: \(error)\n", stderr) }
}

var hidden = false
var clearSince: Date?
setHidden(false)
let timer = DispatchSource.makeTimerSource(queue: .main)
timer.schedule(deadline: .now(), repeating: .milliseconds(100))
timer.setEventHandler {
    let mouse = NSEvent.mouseLocation
    let screen = NSScreen.screens.first { $0.frame.insetBy(dx: -1, dy: -1).contains(mouse) }
    let distance = screen.map { $0.frame.maxY - mouse.y } ?? .infinity
    let shouldHide = distance < (hidden ? 50 : 30) || menuIsOpen()
    if shouldHide {
        clearSince = nil
        if !hidden { hidden = true; setHidden(true) }
    } else if hidden {
        if clearSince == nil { clearSince = Date() }
        if Date().timeIntervalSince(clearSince!) >= 0.3 {
            hidden = false
            clearSince = nil
            setHidden(false)
        }
    }
}
timer.resume()

// Restore the bar when this helper is stopped or replaced on config reload.
var signalSources: [DispatchSourceSignal] = []
for sig in [SIGTERM, SIGINT] {
    signal(sig, SIG_IGN)
    let source = DispatchSource.makeSignalSource(signal: sig, queue: .main)
    source.setEventHandler { setHidden(false); exit(0) }
    source.resume()
    signalSources.append(source)
}
RunLoop.main.run()
