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

  /// Set wallpaper for a single screen with optional manipulations
  private func setWallpaperForScreen(
    fileURL: URL,
    screen: NSScreen,
    screenIndex _: Int,
    workspace: NSWorkspace,
    options: [NSWorkspace.DesktopImageOptionKey: Any]
  ) throws {
    // Create manipulated image if margin or border-radius is specified
    let imageToUse: URL
    if marginTop != nil || borderRadius != nil {
      var manipulations: [String] = []
      if let margin = marginTop {
        manipulations.append("\(margin)px margin at top")
      }
      if let radius = borderRadius {
        manipulations.append("\(radius)px border radius")
      }
      print("Creating manipulated image with \(manipulations.joined(separator: ", "))...")

      let outputURL = try Config.getTempWallpaperURL()
      try ImageManipulator.createManipulatedImage(
        sourceURL: fileURL,
        screen: screen,
        marginTop: marginTop ?? 0,
        borderRadius: borderRadius,
        outputURL: outputURL
      )
      imageToUse = outputURL
      print("Manipulated image saved to: \(imageToUse.path)")
    } else {
      imageToUse = fileURL
    }

    try workspace.setDesktopImageURL(imageToUse, for: screen, options: options)
    print("Wallpaper set successfully\n")
  }

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

    let workspace = NSWorkspace.shared

    // Configure wallpaper options
    // imageScaling: .scaleProportionallyUpOrDown fills the entire screen while maintaining
    // aspect ratio, centering the image and cropping any excess
    let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
      .imageScaling: NSNumber(value: NSImageScaling.scaleProportionallyUpOrDown.rawValue),
      .allowClipping: NSNumber(value: true),
    ]

    // Set wallpaper
    for screen in screensToUpdate {
      do {
        let index = availableScreens.firstIndex(of: screen) ?? -1
        try setWallpaperForScreen(
          fileURL: fileURL,
          screen: screen,
          screenIndex: index,
          workspace: workspace,
          options: options
        )
      } catch {
        let name = screen.localizedName
        print("Failed to set wallpaper for \(name): \(error.localizedDescription)")
      }
    }
  }
}
