import Foundation

enum Config {
  /// Get or create the temporary wallpaper directory
  static func getTempWallpaperDirectory() throws -> URL {
    let homeDir = FileManager.default.homeDirectoryForCurrentUser
    let wallpaperDir = homeDir
      .appendingPathComponent(".local")
      .appendingPathComponent("share")
      .appendingPathComponent("wallpaper")

    if !FileManager.default.fileExists(atPath: wallpaperDir.path) {
      try FileManager.default.createDirectory(
        at: wallpaperDir,
        withIntermediateDirectories: true,
        attributes: nil
      )
    }

    return wallpaperDir
  }
}
