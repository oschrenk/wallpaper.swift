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

  /// Calculate and display how the image will be scaled to fit the screen
  private func displayScalingInfo(imageURL: URL, screen: NSScreen, screenIndex: Int) {
    guard
      let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
      let imageProperties = CGImageSourceCopyPropertiesAtIndex(
        imageSource, 0, nil
      ) as? [CFString: Any],
      let imageWidth = imageProperties[kCGImagePropertyPixelWidth] as? CGFloat,
      let imageHeight = imageProperties[kCGImagePropertyPixelHeight] as? CGFloat
    else {
      return
    }

    let screenWidth = screen.frame.width
    let screenHeight = screen.frame.height
    let name = screen.localizedName

    let imageAspect = imageWidth / imageHeight
    let screenAspect = screenWidth / screenHeight

    // Determine image orientation
    let imageOrientation: String
    if imageAspect > 1.0 {
      imageOrientation = "landscape"
    } else if imageAspect < 1.0 {
      imageOrientation = "portrait"
    } else {
      imageOrientation = "square"
    }

    // image orientation landscape (or square), will crop horizontally
    if imageAspect >= screenAspect {
      let scaleFactor = screenHeight / imageHeight
      let scaledWidth = imageWidth * scaleFactor
      let cropAmount = scaledWidth - screenWidth
      let scaleDirection = scaleFactor > 1.0 ? "up" : scaleFactor < 1.0 ? "down" : "none"
      print("Screen \(screenIndex) (\(name)):")
      print("Image orientation: \(imageOrientation)")
      print("Scaling factor: \(String(format: "%.2f", scaleFactor))x (\(scaleDirection))")
      print("Image will be scaled to \(Int(scaledWidth))x\(Int(screenHeight)),")
      print("Image cropping \(Int(cropAmount))px horizontally")
    } else {
      // image orientation portrait, will crop vertically
      let scaleFactor = screenWidth / imageWidth
      let scaledHeight = imageHeight * scaleFactor
      let cropAmount = scaledHeight - screenHeight
      let scaleDirection = scaleFactor > 1.0 ? "up" : scaleFactor < 1.0 ? "down" : "none"

      print("Screen \(screenIndex) (\(name)):")
      print("Image orientation: \(imageOrientation)")
      print("Scaling factor: \(String(format: "%.2f", scaleFactor))x (\(scaleDirection))")
      print("Image will be scaled to \(Int(screenWidth))x\(Int(scaledHeight)),")
      print("Image cropping \(Int(cropAmount))px vertically")
    }
  }

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
      .imageScaling: NSNumber(value: NSImageScaling.scaleProportionallyUpOrDown.rawValue),
      .allowClipping: NSNumber(value: true),
    ]

    // Set wallpaper
    for screen in screensToUpdate {
      do {
        let index = availableScreens.firstIndex(of: screen) ?? -1

        displayScalingInfo(imageURL: fileURL, screen: screen, screenIndex: index)

        try workspace.setDesktopImageURL(fileURL, for: screen, options: options)
        print("Wallpaper set successfully\n")
      } catch {
        let name = screen.localizedName
        print("Failed to set wallpaper for \(name): \(error.localizedDescription)")
      }
    }
  }
}
