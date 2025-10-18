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

  /// Generate a temporary wallpaper file URL with timestamp
  static func getTempWallpaperURL() throws -> URL {
    let tempDir = try getTempWallpaperDirectory()
    let timestamp = Date().timeIntervalSince1970
    let outputURL = tempDir.appendingPathComponent("wallpaper-\(timestamp).png")
    return outputURL
  }
}
