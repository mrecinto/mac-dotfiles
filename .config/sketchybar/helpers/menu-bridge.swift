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
    let displays = [BarDisplay(arrangementID: 1, displayID: 10),
                    BarDisplay(arrangementID: 2, displayID: 20)]
    precondition(visibilityArguments(displays: displays, hidden: [10])
        == ["--bar", "hidden=off", "display=2", "y_offset=0"],
        "Revealing menus on screen 1 must keep screen 2 visible")
    precondition(visibilityArguments(displays: displays, hidden: [20])
        == ["--bar", "hidden=off", "display=1", "y_offset=0"],
        "Revealing menus on screen 2 must keep screen 1 visible")
    precondition(visibilityArguments(displays: displays, hidden: [])
        .contains("display=all"), "Dismissal must restore every display")
    precondition(visibilityArguments(displays: displays, hidden: [10, 20])
        .contains("hidden=on"), "Both screens may independently show menus")
    var first = VisibilityState()
    var second = VisibilityState()
    first.update(distance: 0, menuOpen: false, now: 0)
    second.update(distance: .infinity, menuOpen: false, now: 0)
    precondition(first.hidden && !second.hidden, "Screen state must be independent")
    first.update(distance: .infinity, menuOpen: false, now: 1)
    second.update(distance: 0, menuOpen: false, now: 1)
    first.update(distance: .infinity, menuOpen: false, now: 1.4)
    precondition(!first.hidden && second.hidden, "Moving screens must restore the old bar")
    print("Visibility and multi-monitor checks passed")
    exit(0)
}

struct BarDisplay: Decodable {
    let arrangementID: Int
    let displayID: CGDirectDisplayID
    enum CodingKeys: String, CodingKey {
        case arrangementID = "arrangement-id"
        case displayID = "DirectDisplayID"
    }
}

// WindowServer and CGDisplayBounds share coordinates, including screens above
// or to the left of the primary display. Do not mix them with NSScreen frames.
func nativeMenuBounds() -> [CGRect] {
    guard let windows = CGWindowListCopyWindowInfo(
        [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
    ) as? [[String: Any]] else { return [] }
    return windows.compactMap { window in
        let layer = window[kCGWindowLayer as String] as? Int ?? 0
        let owner = window[kCGWindowOwnerName as String] as? String ?? ""
        guard layer == Int(CGWindowLevelForKey(.popUpMenuWindow)),
              owner.lowercased() != "sketchybar",
              let bounds = window[kCGWindowBounds as String] as? [String: Any]
        else { return nil }
        return CGRect(dictionaryRepresentation: bounds as CFDictionary)
    }
}

func visibilityArguments(displays: [BarDisplay], hidden: Set<CGDirectDisplayID>) -> [String] {
    let visible = displays.filter { !hidden.contains($0.displayID) }
    if visible.isEmpty && !displays.isEmpty {
        return ["--bar", "display=all", "hidden=on", "y_offset=0"]
    }
    let selection = hidden.isEmpty ? "all" : visible.map { String($0.arrangementID) }.joined(separator: ",")
    return ["--bar", "hidden=off", "display=\(selection)", "y_offset=0"]
}

let barPath = CommandLine.arguments.dropFirst().first ?? "/opt/homebrew/bin/sketchybar"
@discardableResult
func runBar(_ arguments: [String], captureOutput: Bool = false) -> Data? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: barPath)
    process.arguments = arguments
    let output = Pipe()
    process.standardOutput = captureOutput ? output : FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    do {
        try process.run()
        // A stalled SketchyBar IPC request must not freeze visibility monitoring.
        let deadline = Date().addingTimeInterval(1)
        while process.isRunning && Date() < deadline { Thread.sleep(forTimeInterval: 0.01) }
        if process.isRunning { process.terminate(); return nil }
        guard process.terminationStatus == 0 else { return nil }
        return captureOutput ? output.fileHandleForReading.readDataToEndOfFile() : Data()
    }
    catch { fputs("menu-bridge: \(error)\n", stderr); return nil }
}

func restoreBars() {
    runBar(["--bar", "hidden=off", "display=all", "y_offset=0"])
}

func queryDisplays() -> [BarDisplay]? {
    guard let data = runBar(["--query", "displays"], captureOutput: true),
          let displays = try? JSONDecoder().decode([BarDisplay].self, from: data),
          !displays.isEmpty else { return nil }
    return displays
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

var displays = queryDisplays() ?? []
var states: [CGDirectDisplayID: VisibilityState] = [:]
var lastApplied = Date.timeIntervalSinceReferenceDate
restoreBars()
let timer = DispatchSource.makeTimerSource(queue: .main)
timer.schedule(deadline: .now(), repeating: .milliseconds(50))
timer.setEventHandler {
    dismissPopupAfterOutsideClick()
    guard let mouse = CGEvent(source: nil)?.location else { return }
    let now = Date.timeIntervalSinceReferenceDate
    let refresh = now - lastApplied >= 2
    if refresh, let updated = queryDisplays() { displays = updated }
    let menuBounds = states.values.contains { $0.hidden } ? nativeMenuBounds() : []
    var changed = false
    for display in displays {
        let bounds = CGDisplayBounds(display.displayID)
        let distance = bounds.contains(mouse) ? mouse.y - bounds.minY : CGFloat.infinity
        let menuOpen = menuBounds.contains { menu in
            bounds.contains(CGPoint(x: menu.minX + 1, y: menu.minY + 1))
        }
        var state = states[display.displayID] ?? VisibilityState()
        let wasHidden = state.hidden
        state.update(distance: distance, menuOpen: menuOpen, now: now)
        states[display.displayID] = state
        changed = changed || state.hidden != wasHidden
    }
    if changed || refresh {
        let hidden = Set(displays.filter { states[$0.displayID]?.hidden == true }.map { $0.displayID })
        runBar(visibilityArguments(displays: displays, hidden: hidden))
        lastApplied = now
    }
}
timer.resume()

let resetVisibility: (Notification) -> Void = { _ in
    states.removeAll()
    restoreBars()
    displays = queryDisplays() ?? []
    lastApplied = 0 // Retry after the display server settles on wake/reconfiguration.
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
    source.setEventHandler { restoreBars(); exit(0) }
    source.resume()
    signalSources.append(source)
}
RunLoop.main.run()
