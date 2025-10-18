import Foundation

/// Errors that can occur during image manipulation
enum ImageError: Error, LocalizedError {
  case failedToLoadImage
  case failedToCreateContext
  case failedToCreateFinalImage
  case failedToCreateDestination
  case failedToSaveImage

  var errorDescription: String? {
    switch self {
    case .failedToLoadImage:
      return "Failed to load image"
    case .failedToCreateContext:
      return "Failed to create graphics context"
    case .failedToCreateFinalImage:
      return "Failed to create final image"
    case .failedToCreateDestination:
      return "Failed to create image destination"
    case .failedToSaveImage:
      return "Failed to save manipulated image"
    }
  }
}
