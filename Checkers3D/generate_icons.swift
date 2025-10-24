#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func createCheckersIcon(size: Int) -> CGImage? {
    let width = size
    let height = size
    
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return nil
    }
    
    // Background color - Dark blue-gray
    context.setFillColor(CGColor(red: 0.1, green: 0.16, blue: 0.2, alpha: 1.0))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    
    // Draw checkerboard pattern
    let squareSize = CGFloat(width) / 8.0
    for i in 0..<8 {
        for j in 0..<8 {
            if (i + j) % 2 == 0 {
                context.setFillColor(CGColor(red: 0.12, green: 0.18, blue: 0.24, alpha: 1.0))
                let x = CGFloat(i) * squareSize
                let y = CGFloat(j) * squareSize
                context.fill(CGRect(x: x, y: y, width: squareSize, height: squareSize))
            }
        }
    }
    
    let radius = CGFloat(width) / 5.0
    let shadowOffset = CGFloat(width) / 60.0
    
    // Red checker piece (top-left)
    let redX = CGFloat(width) / 3.0
    let redY = CGFloat(height) / 3.0
    
    // Shadow for red piece
    context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.3))
    context.fillEllipse(in: CGRect(
        x: redX - radius + shadowOffset,
        y: redY - radius + shadowOffset,
        width: radius * 2,
        height: radius * 2
    ))
    
    // Red piece
    context.setFillColor(CGColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0))
    context.fillEllipse(in: CGRect(x: redX - radius, y: redY - radius, width: radius * 2, height: radius * 2))
    
    // Highlight on red piece
    let highlightRadius = radius / 3.0
    context.setFillColor(CGColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.6))
    context.fillEllipse(in: CGRect(
        x: redX - highlightRadius,
        y: redY - radius / 2,
        width: highlightRadius * 2,
        height: highlightRadius * 2
    ))
    
    // Black checker piece (bottom-right)
    let blackX = CGFloat(width) * 2.0 / 3.0
    let blackY = CGFloat(height) * 2.0 / 3.0
    
    // Shadow for black piece
    context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.3))
    context.fillEllipse(in: CGRect(
        x: blackX - radius + shadowOffset,
        y: blackY - radius + shadowOffset,
        width: radius * 2,
        height: radius * 2
    ))
    
    // Black piece
    context.setFillColor(CGColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0))
    context.fillEllipse(in: CGRect(x: blackX - radius, y: blackY - radius, width: radius * 2, height: radius * 2))
    
    // Highlight on black piece
    context.setFillColor(CGColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 0.6))
    context.fillEllipse(in: CGRect(
        x: blackX - highlightRadius,
        y: blackY - radius / 2,
        width: highlightRadius * 2,
        height: highlightRadius * 2
    ))
    
    // Draw center highlight circle to indicate 3D/gameplay
    let centerX = CGFloat(width) / 2.0
    let centerY = CGFloat(height) / 2.0
    let centerRadius = radius / 4.0
    
    // Draw a subtle glow in the center
    context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.15))
    context.fillEllipse(in: CGRect(
        x: centerX - centerRadius,
        y: centerY - centerRadius,
        width: centerRadius * 2,
        height: centerRadius * 2
    ))
    
    return context.makeImage()
}

func saveIcon(image: CGImage, path: String) -> Bool {
    let url = URL(fileURLWithPath: path)
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        return false
    }
    CGImageDestinationAddImage(destination, image, nil)
    return CGImageDestinationFinalize(destination)
}

// Icon specifications
let iconSpecs: [(size: Int, name: String, scale: String, idiom: String)] = [
    (1024, "1024x1024", "1x", "ios-marketing"),
    (40, "20x20", "2x", "iphone"),
    (60, "20x20", "3x", "iphone"),
    (58, "29x29", "2x", "iphone"),
    (87, "29x29", "3x", "iphone"),
    (80, "40x40", "2x", "iphone"),
    (120, "40x40", "3x", "iphone"),
    (120, "60x60", "2x", "iphone"),
    (180, "60x60", "3x", "iphone"),
    (20, "20x20", "1x", "ipad"),
    (40, "20x20", "2x", "ipad"),
    (29, "29x29", "1x", "ipad"),
    (58, "29x29", "2x", "ipad"),
    (40, "40x40", "1x", "ipad"),
    (80, "40x40", "2x", "ipad"),
    (76, "76x76", "1x", "ipad"),
    (152, "76x76", "2x", "ipad"),
    (167, "83.5x83.5", "2x", "ipad"),
]

let outputDir = "/Users/damirk/Projects/labtiva/copilot/Checkers3D/Assets.xcassets/AppIcon.appiconset"

// Create output directory
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

// Generate icons
var imageEntries: [[String: String]] = []

for spec in iconSpecs {
    let filename = "icon-\(spec.name)@\(spec.scale).png"
    let filepath = "\(outputDir)/\(filename)"
    
    if let image = createCheckersIcon(size: spec.size) {
        if saveIcon(image: image, path: filepath) {
            print("✓ Created: \(filename)")
            imageEntries.append([
                "filename": filename,
                "idiom": spec.idiom,
                "scale": spec.scale,
                "size": spec.name
            ])
        } else {
            print("✗ Failed to save: \(filename)")
        }
    } else {
        print("✗ Failed to create: \(filename)")
    }
}

// Create Contents.json
let contents: [String: Any] = [
    "images": imageEntries,
    "info": [
        "author": "xcode",
        "version": 1
    ]
]

let contentsPath = "\(outputDir)/Contents.json"
if let jsonData = try? JSONSerialization.data(withJSONObject: contents, options: .prettyPrinted) {
    try? jsonData.write(to: URL(fileURLWithPath: contentsPath))
    print("\n✓ Created Contents.json")
}

print("\nTotal icons created: \(imageEntries.count)")
print("Icons saved to: \(outputDir)")
