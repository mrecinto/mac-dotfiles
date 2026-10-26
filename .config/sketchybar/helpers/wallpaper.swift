import AppKit
// First screen is the display with the menu bar, independent of app focus.
guard let screen = NSScreen.screens.first,
      let url = NSWorkspace.shared.desktopImageURL(for: screen),
      url.isFileURL else { exit(1) }
print(url.path)
