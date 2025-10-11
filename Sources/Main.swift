import ArgumentParser
import EventKit
import Foundation

/// Wallpaper is a CLI tool to set wallpaper on macOS
///
/// This the main entry point
@main
struct Main: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "wallpaper",
    subcommands: [
      Set.self,
      Screens.self,
      Usage.self,
    ],
    defaultSubcommand: Usage.self
  )

  mutating func run() {}
}
