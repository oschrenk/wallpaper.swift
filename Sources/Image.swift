import AppKit
import Foundation
import UniformTypeIdentifiers

/// Image manipulation utilities for wallpaper processing
enum ImageManipulator {
  /// Calculate scaled dimensions for an image to fill screen and account for an added top margin
  static func calculateScaledDimensions(
    imageSize: CGSize,
    screen: NSScreen,
    marginTop: Int
  ) -> (width: Int, height: Int) {
    let screenWidth = Int(screen.frame.width)
    let screenHeight = Int(screen.frame.height)
    let availableHeight = screenHeight - marginTop

    let imageAspect = imageSize.width / imageSize.height
    let availableAspect = CGFloat(screenWidth) / CGFloat(availableHeight)

    if imageAspect >= availableAspect {
      let scaleFactor = CGFloat(availableHeight) / imageSize.height
      return (Int(imageSize.width * scaleFactor), availableHeight)
    } else {
      let scaleFactor = CGFloat(screenWidth) / imageSize.width
      return (screenWidth, Int(imageSize.height * scaleFactor))
    }
  }

  /// Create a path with rounded corners
  static func createRoundedRectPath(rect: CGRect, cornerRadius: CGFloat) -> CGPath {
    let path = CGMutablePath()
    let maxRadius = min(rect.width, rect.height) / 2
    let radius = min(cornerRadius, maxRadius)

    path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
    path.addArc(
      tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
      tangent2End: CGPoint(x: rect.maxX, y: rect.minY + radius),
      radius: radius
    )
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
    path.addArc(
      tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
      tangent2End: CGPoint(x: rect.maxX - radius, y: rect.maxY),
      radius: radius
    )
    path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
    path.addArc(
      tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
      tangent2End: CGPoint(x: rect.minX, y: rect.maxY - radius),
      radius: radius
    )
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
    path.addArc(
      tangent1End: CGPoint(x: rect.minX, y: rect.minY),
      tangent2End: CGPoint(x: rect.minX + radius, y: rect.minY),
      radius: radius
    )
    path.closeSubpath()

    return path
  }

  /// Render image
  /// - with (optional) margin
  /// - with (optional) rounded corners
  static func renderImageWithMargin(
    cgImage: CGImage,
    scaledSize: (width: Int, height: Int),
    screen: NSScreen,
    marginTop: Int,
    borderRadius: Int?
  ) throws -> CGImage {
    let screenWidth = Int(screen.frame.width)
    let screenHeight = Int(screen.frame.height)

    guard let context = CGContext(
      data: nil,
      width: screenWidth,
      height: screenHeight,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      throw ImageError.failedToCreateContext
    }

    context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))

    let availableHeight = screenHeight - marginTop
    let xOffset = (screenWidth - scaledSize.width) / 2
    let imageRect = CGRect(
      x: xOffset,
      y: 0,
      width: scaledSize.width,
      height: scaledSize.height
    )

    let availableRect = CGRect(x: 0, y: 0, width: screenWidth, height: availableHeight)

    if let radius = borderRadius, radius > 0 {
      let clippingRect = imageRect.intersection(availableRect)
      let roundedPath = createRoundedRectPath(rect: clippingRect, cornerRadius: CGFloat(radius))
      context.addPath(roundedPath)
      context.clip()
    } else {
      context.clip(to: availableRect)
    }

    context.draw(cgImage, in: imageRect)

    guard let finalImage = context.makeImage() else {
      throw ImageError.failedToCreateFinalImage
    }
    return finalImage
  }

  /// Save a CGImage to disk as PNG
  static func saveImage(_ cgImage: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
      url as CFURL,
      UTType.png.identifier as CFString,
      1,
      nil
    ) else {
      throw ImageError.failedToCreateDestination
    }

    CGImageDestinationAddImage(destination, cgImage, nil)
    guard CGImageDestinationFinalize(destination) else {
      throw ImageError.failedToSaveImage
    }
  }

  /// Create a manipulated version of the image with margin and/or rounded corners
  static func createManipulatedImage(
    sourceURL: URL,
    screen: NSScreen,
    marginTop: Int,
    borderRadius: Int?,
    outputURL: URL
  ) throws {
    guard
      let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    else {
      throw ImageError.failedToLoadImage
    }

    let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
    let scaledSize = calculateScaledDimensions(
      imageSize: imageSize,
      screen: screen,
      marginTop: marginTop
    )
    let finalImage = try renderImageWithMargin(
      cgImage: cgImage,
      scaledSize: scaledSize,
      screen: screen,
      marginTop: marginTop,
      borderRadius: borderRadius
    )

    try saveImage(finalImage, to: outputURL)
  }
}

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
