import AppKit
import CoreGraphics
import Foundation

struct VisibilityState {
    var hidden = false
    var clearSince: TimeInterval?

    mutating func update(distance: CGFloat, menuOpen: Bool, now: TimeInterval) {
        // A popup alone must never hide the bar. Only entering the top edge can.
        if !hidden {
            if distance >= 0 && distance <= 1 { hidden = true }
            clearSince = nil
        } else if distance <= 40 || menuOpen {
            clearSince = nil
        } else {
            if clearSince == nil { clearSince = now }
            if now - clearSince! >= 0.3 {
                hidden = false
                clearSince = nil
            }
        }
    }
}

if CommandLine.arguments.contains("--self-test") {
    var state = VisibilityState()
    state.update(distance: 20, menuOpen: false, now: 0)
    precondition(!state.hidden, "SketchyBar must remain clickable")
    state.update(distance: 200, menuOpen: true, now: 1)
    precondition(!state.hidden, "Unrelated popups must not hide SketchyBar")
    state.update(distance: 0, menuOpen: false, now: 2)
    precondition(state.hidden, "The top edge must reveal native menus")
    state.update(distance: 200, menuOpen: true, now: 3)
    precondition(state.hidden, "An open native menu must stay usable")
    state.update(distance: 200, menuOpen: false, now: 4)
    state.update(distance: 200, menuOpen: false, now: 4.4)
    precondition(!state.hidden, "The bar must return after menu dismissal")
    print("Visibility checks passed")
    exit(0)
}

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
func runBar(_ arguments: [String]) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: barPath)
    process.arguments = arguments
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    do {
        try process.run()
        // A stalled SketchyBar IPC request must not freeze visibility monitoring.
        let deadline = Date().addingTimeInterval(1)
        while process.isRunning && Date() < deadline { Thread.sleep(forTimeInterval: 0.01) }
        if process.isRunning { process.terminate() }
    }
    catch { fputs("menu-bridge: \(error)\n", stderr) }
}

func setHidden(_ hidden: Bool) {
    runBar(["--bar", "hidden=\(hidden ? "on" : "off")", "y_offset=0"])
}

// Poll WindowServer event counters: global AppKit monitors can miss clicks
// when this command-line helper has no NSApplication event loop.
let clickTypes: [CGEventType] = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
func clickCounts() -> [UInt32] {
    clickTypes.map { CGEventSource.counterForEventType(.combinedSessionState, eventType: $0) }
}
var previousClickCounts = clickCounts()
func dismissPopupAfterOutsideClick() {
    let counts = clickCounts()
    defer { previousClickCounts = counts }
    guard counts != previousClickCounts,
          let point = CGEvent(source: nil)?.location,
          let windows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
          ) as? [[String: Any]] else { return }
    let insideBar = windows.contains { window in
        guard (window[kCGWindowOwnerName as String] as? String)?.lowercased() == "sketchybar",
              let bounds = window[kCGWindowBounds as String] as? [String: Any],
              let rect = CGRect(dictionaryRepresentation: bounds as CFDictionary) else { return false }
        return rect.contains(point)
    }
    if !insideBar { runBar(["--set", "special", "popup.drawing=off"]) }
}

var state = VisibilityState()
var lastApplied = Date.timeIntervalSinceReferenceDate
setHidden(false)
let timer = DispatchSource.makeTimerSource(queue: .main)
timer.schedule(deadline: .now(), repeating: .milliseconds(50))
timer.setEventHandler {
    dismissPopupAfterOutsideClick()
    let mouse = NSEvent.mouseLocation
    let screen = NSScreen.screens.first { $0.frame.insetBy(dx: -1, dy: -1).contains(mouse) }
    let distance = screen.map { $0.frame.maxY - mouse.y } ?? .infinity
    let now = Date.timeIntervalSinceReferenceDate
    let wasHidden = state.hidden
    state.update(distance: distance, menuOpen: state.hidden && menuIsOpen(), now: now)
    // Repair lost IPC commands or visibility changed externally, without constant IPC.
    if state.hidden != wasHidden || now - lastApplied >= 2 {
        setHidden(state.hidden)
        lastApplied = now
    }
}
timer.resume()

let resetVisibility: (Notification) -> Void = { _ in
    state = VisibilityState()
    setHidden(false)
    lastApplied = Date.timeIntervalSinceReferenceDate
}
let wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didWakeNotification, object: nil, queue: .main, using: resetVisibility
)
let screenObserver = NotificationCenter.default.addObserver(
    forName: NSApplication.didChangeScreenParametersNotification,
    object: nil, queue: .main, using: resetVisibility
)

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
