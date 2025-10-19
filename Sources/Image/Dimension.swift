import Foundation

/// Represents image or screen dimensions in pixels
struct Dimension {
  let width: Int
  let height: Int

  /// Calculate the aspect ratio (width / height)
  var aspectRatio: CGFloat {
    CGFloat(width) / CGFloat(height)
  }

  /// Create dimensions from a CGSize
  init(width: Int, height: Int) {
    self.width = width
    self.height = height
  }

  /// Create dimensions from a CGSize, rounding values
  init(_ size: CGSize) {
    self.width = Int(size.width)
    self.height = Int(size.height)
  }

  /// Convert to CGSize
  var cgSize: CGSize {
    CGSize(width: width, height: height)
  }
}
