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

  @Option(
    name: .long,
    help: "Add a black margin at the top of the image with specified height in pixels"
  )
  var marginTop: Int?

  @Option(
    name: .long,
    help: "Apply rounded corners to the image with specified radius in pixels"
  )
  var borderRadius: Int?

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

    // Set wallpaper
    for screen in screensToUpdate {
      do {
        let preparedImageURL = try ImageManipulator.prepareImage(
          sourceURL: fileURL,
          screen: screen,
          marginTop: marginTop,
          borderRadius: borderRadius
        )
        try Wallpaper.setWallpaper(
          imageURL: preparedImageURL,
          screen: screen
        )
      } catch {
        let name = screen.localizedName
        print("Failed to set wallpaper for \(name): \(error.localizedDescription)")
      }
    }
  }
}
