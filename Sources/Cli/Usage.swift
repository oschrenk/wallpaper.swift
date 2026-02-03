import ArgumentParser
import EventKit
import Foundation

/// `wallpaper usage`
///
/// Show usage and version
struct Usage: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Show help",
    shouldDisplay: false
  )

  @Flag(help: ArgumentHelp(
    "Show version"
  ))
  var version: Bool = false

  mutating func run() {
    if version {
      print(Version.value)
    } else {
      print(Wallpaper.helpMessage())
    }
  }
}
