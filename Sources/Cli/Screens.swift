import AppKit
import ArgumentParser
import Foundation

/// `wallpaper screens`
///
/// List screens
struct Screens: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "List all connected displays"
  )

  mutating func run() {
    let screens = NSScreen.screens

    if screens.isEmpty {
      print("No screens found")
      return
    }

    print("Connected displays:")
    for (index, screen) in screens.enumerated() {
      let frame = screen.frame
      let name = screen.localizedName
      let isMain = screen == NSScreen.main ? " (main)" : ""
      let scaleFactor = screen.backingScaleFactor

      let logicalWidth = Int(frame.width)
      let logicalHeight = Int(frame.height)
      let physicalWidth = Int(frame.width * scaleFactor)
      let physicalHeight = Int(frame.height * scaleFactor)

      print("\(index): \(name)\(isMain)")
      print("   Logical Resolution: \(logicalWidth)x\(logicalHeight)")
      print("   Physical Resolution: \(physicalWidth)x\(physicalHeight)")
    }
  }
}
