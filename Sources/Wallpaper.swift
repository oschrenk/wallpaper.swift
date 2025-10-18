import AppKit
import Foundation

/// Wallpaper setting utilities
enum Wallpaper {
  /// Set wallpaper for a single screen
  static func setWallpaper(
    imageURL: URL,
    screen: NSScreen,
    workspace: NSWorkspace
  ) throws {
    // Configure wallpaper options
    // imageScaling: .scaleProportionallyUpOrDown fills the entire screen while maintaining
    // aspect ratio, centering the image and cropping any excess
    let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
      .imageScaling: NSNumber(value: NSImageScaling.scaleProportionallyUpOrDown.rawValue),
      .allowClipping: NSNumber(value: true),
    ]

    try workspace.setDesktopImageURL(imageURL, for: screen, options: options)
    print("Wallpaper set successfully\n")
  }
}
