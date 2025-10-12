import AppKit
import ArgumentParser
import Foundation
import UniformTypeIdentifiers

/// `wallpaper set`
///
/// Set wallpaper
struct Set: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "Set wallpaper for one or more displays"
  )

  /// Get or create the temporary wallpaper directory
  private func getTempWallpaperDirectory() throws -> URL {
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

  /// Calculate scaled dimensions for an image to fit screen
  private func calculateScaledDimensions(
    imageSize: CGSize,
    screen: NSScreen
  ) -> (width: Int, height: Int) {
    let screenWidth = Int(screen.frame.width)
    let screenHeight = Int(screen.frame.height)
    let imageAspect = imageSize.width / imageSize.height
    let screenAspect = screen.frame.width / screen.frame.height

    if imageAspect >= screenAspect {
      let scaleFactor = screen.frame.height / imageSize.height
      return (Int(imageSize.width * scaleFactor), screenHeight)
    } else {
      let scaleFactor = screen.frame.width / imageSize.width
      return (screenWidth, Int(imageSize.height * scaleFactor))
    }
  }

  /// Render image with margin into a CGImage
  private func renderImageWithMargin(
    cgImage: CGImage,
    scaledSize: (width: Int, height: Int),
    screen: NSScreen,
    marginTop: Int
  ) throws -> CGImage {
    let screenWidth = Int(screen.frame.width)
    let screenHeight = Int(screen.frame.height)
    let finalHeight = screenHeight + marginTop

    guard let context = CGContext(
      data: nil,
      width: screenWidth,
      height: finalHeight,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      throw ValidationError("Failed to create graphics context")
    }

    context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: screenWidth, height: finalHeight))

    let xOffset = (screenWidth - scaledSize.width) / 2
    let imageRect = CGRect(x: xOffset, y: 0, width: scaledSize.width, height: scaledSize.height)
    context.draw(cgImage, in: imageRect)

    guard let finalImage = context.makeImage() else {
      throw ValidationError("Failed to create final image")
    }
    return finalImage
  }

  /// Save a CGImage to disk as PNG
  private func saveImage(_ cgImage: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
      url as CFURL,
      UTType.png.identifier as CFString,
      1,
      nil
    ) else {
      throw ValidationError("Failed to create image destination")
    }

    CGImageDestinationAddImage(destination, cgImage, nil)
    guard CGImageDestinationFinalize(destination) else {
      throw ValidationError("Failed to save manipulated image")
    }
  }

  /// Create a manipulated version of the image with margin at the top
  private func createManipulatedImage(
    sourceURL: URL,
    screen: NSScreen,
    marginTop: Int
  ) throws -> URL {
    guard
      let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    else {
      throw ValidationError("Failed to load image")
    }

    let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
    let scaledSize = calculateScaledDimensions(imageSize: imageSize, screen: screen)
    let finalImage = try renderImageWithMargin(
      cgImage: cgImage,
      scaledSize: scaledSize,
      screen: screen,
      marginTop: marginTop
    )

    let tempDir = try getTempWallpaperDirectory()
    let timestamp = Date().timeIntervalSince1970
    let outputURL = tempDir.appendingPathComponent("wallpaper-\(timestamp).png")

    try saveImage(finalImage, to: outputURL)
    return outputURL
  }

  /// Calculate and display how the image will be scaled to fit the screen
  private func displayScalingInfo(imageURL: URL, screen: NSScreen, screenIndex: Int) {
    guard
      let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
      let imageProperties = CGImageSourceCopyPropertiesAtIndex(
        imageSource, 0, nil
      ) as? [CFString: Any],
      let imageWidth = imageProperties[kCGImagePropertyPixelWidth] as? CGFloat,
      let imageHeight = imageProperties[kCGImagePropertyPixelHeight] as? CGFloat
    else {
      return
    }

    let screenWidth = screen.frame.width
    let screenHeight = screen.frame.height
    let name = screen.localizedName

    let imageAspect = imageWidth / imageHeight
    let screenAspect = screenWidth / screenHeight

    // Determine image orientation
    let imageOrientation: String
    if imageAspect > 1.0 {
      imageOrientation = "landscape"
    } else if imageAspect < 1.0 {
      imageOrientation = "portrait"
    } else {
      imageOrientation = "square"
    }

    // image orientation landscape (or square), will crop horizontally
    if imageAspect >= screenAspect {
      let scaleFactor = screenHeight / imageHeight
      let scaledWidth = imageWidth * scaleFactor
      let cropAmount = scaledWidth - screenWidth
      let scaleDirection = scaleFactor > 1.0 ? "up" : scaleFactor < 1.0 ? "down" : "none"
      print("Screen \(screenIndex) (\(name)):")
      print("Image orientation: \(imageOrientation)")
      print("Scaling factor: \(String(format: "%.2f", scaleFactor))x (\(scaleDirection))")
      print("Image will be scaled to \(Int(scaledWidth))x\(Int(screenHeight)),")
      print("Image cropping \(Int(cropAmount))px horizontally")
    } else {
      // image orientation portrait, will crop vertically
      let scaleFactor = screenWidth / imageWidth
      let scaledHeight = imageHeight * scaleFactor
      let cropAmount = scaledHeight - screenHeight
      let scaleDirection = scaleFactor > 1.0 ? "up" : scaleFactor < 1.0 ? "down" : "none"

      print("Screen \(screenIndex) (\(name)):")
      print("Image orientation: \(imageOrientation)")
      print("Scaling factor: \(String(format: "%.2f", scaleFactor))x (\(scaleDirection))")
      print("Image will be scaled to \(Int(screenWidth))x\(Int(scaledHeight)),")
      print("Image cropping \(Int(cropAmount))px vertically")
    }
  }

  @Argument(help: "Path to the image file")
  var imagePath: String

  @Option(
    name: .shortAndLong,
    help: "Screen index (use 'screens' command). If not specified, sets wallpaper on all screens."
  )
  var screen: Int?

  @Option(
    name: .long,
    help: "Add a black margin at the top of the image with specified height in pixels"
  )
  var marginTop: Int?

  mutating func run() throws {
    let fileURL = URL(fileURLWithPath: imagePath)
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      throw ValidationError("Image file not found: \(imagePath)")
    }

    let availableScreens = NSScreen.screens

    if availableScreens.isEmpty {
      print("No screens found")
      return
    }

    // Determine which screens to update
    let screensToUpdate: [NSScreen]
    if let screenIndex = screen {
      guard screenIndex >= 0, screenIndex < availableScreens.count else {
        throw ValidationError("Invalid screen index: \(screenIndex). Use 'screens' command.")
      }
      // only update targeted screen
      screensToUpdate = [availableScreens[screenIndex]]
    } else {
      // update all screens
      screensToUpdate = availableScreens
    }

    let workspace = NSWorkspace.shared

    // Configure wallpaper options
    // imageScaling: .scaleProportionallyUpOrDown fills the entire screen while maintaining
    // aspect ratio, centering the image and cropping any excess
    let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
      .imageScaling: NSNumber(value: NSImageScaling.scaleProportionallyUpOrDown.rawValue),
      .allowClipping: NSNumber(value: true),
    ]

    // Set wallpaper
    for screen in screensToUpdate {
      do {
        let index = availableScreens.firstIndex(of: screen) ?? -1

        displayScalingInfo(imageURL: fileURL, screen: screen, screenIndex: index)

        // Create manipulated image if margin is specified
        let imageToUse: URL
        if let margin = marginTop {
          print("Creating manipulated image with \(margin)px margin at top...")
          imageToUse = try createManipulatedImage(
            sourceURL: fileURL,
            screen: screen,
            marginTop: margin
          )
          print("Manipulated image saved to: \(imageToUse.path)")
        } else {
          imageToUse = fileURL
        }

        try workspace.setDesktopImageURL(imageToUse, for: screen, options: options)
        print("Wallpaper set successfully\n")
      } catch {
        let name = screen.localizedName
        print("Failed to set wallpaper for \(name): \(error.localizedDescription)")
      }
    }
  }
}
