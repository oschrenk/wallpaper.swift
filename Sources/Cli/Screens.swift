import ArgumentParser
import Foundation

/// `wallpaper screens`
///
/// List screens
struct Screens: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "List screens"
  )

  mutating func run() {
    print("hello world")
  }
}
