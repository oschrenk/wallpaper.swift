import AppKit
import ArgumentParser
import Foundation

/// `wallpaper set`
///
/// Set wallpaper
struct Set: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Set wallpaper for one or more displays"
  )

  @Argument(help: "Path to the image file")
  var imagePath: String

  @Option(
    name: .shortAndLong,
    help: "Screen index (use 'screens' command). If not specified, sets wallpaper on all screens."
  )
  var screen: Int?

  mutating func run() throws {
    let fileURL = URL(fileURLWithPath: imagePath)
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      throw ValidationError("Image file not found: \(imagePath)")
    }

    let availableScreens = NSScreen.screens

    if availableScreens.isEmpty {
      print("No screens found")
      return
    }

    // Determine which screens to update
    let screensToUpdate: [NSScreen]
    if let screenIndex = screen {
      guard screenIndex >= 0, screenIndex < availableScreens.count else {
        throw ValidationError("Invalid screen index: \(screenIndex). Use 'screens' command.")
      }
      // only update targeted screen
      screensToUpdate = [availableScreens[screenIndex]]
    } else {
      // update all screens
      screensToUpdate = availableScreens
    }

    let workspace = NSWorkspace.shared

    // Configure wallpaper options
    // imageScaling: .scaleProportionallyUpOrDown fills the entire screen while maintaining
    // aspect ratio, centering the image and cropping any excess
    let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
      .imageScaling: NSImageScaling.scaleProportionallyUpOrDown,
      .allowClipping: true,
    ]

    // Set wallpaper
    for screen in screensToUpdate {
      do {
        try workspace.setDesktopImageURL(fileURL, for: screen, options: options)
        let name = screen.localizedName
        let index = availableScreens.firstIndex(of: screen) ?? -1
        print("Set wallpaper for screen \(index): \(name)")
      } catch {
        let name = screen.localizedName
        print("Failed to set wallpaper for \(name): \(error.localizedDescription)")
      }
    }
  }
}
