import ArgumentParser
import Foundation

/// `wallpaper set`
///
/// Set wallpaper
struct Set: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Set wallpaper"
  )

  mutating func run() {
    print("hello world")
  }
}
