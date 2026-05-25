import AppKit
import Foundation

let svgPath = "Awake/AppIcon.svg"
let iconsetDir = "Awake/AppIcon.iconset"

// Create iconset directory
try FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

// Load SVG
guard let svgData = FileManager.default.contents(atPath: svgPath),
      let svgImage = NSImage(data: svgData) else {
    print("ERROR: Could not load SVG from \(svgPath)")
    exit(1)
}

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for (name, size) in sizes {
    let targetSize = NSSize(width: size, height: size)
    let newImage = NSImage(size: targetSize)
    newImage.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    svgImage.draw(in: NSRect(origin: .zero, size: targetSize),
                  from: NSRect(origin: .zero, size: svgImage.size),
                  operation: .copy,
                  fraction: 1.0)
    newImage.unlockFocus()

    guard let tiffData = newImage.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("ERROR: Could not create PNG for \(name)")
        exit(1)
    }

    let outPath = (iconsetDir as NSString).appendingPathComponent(name)
    try pngData.write(to: URL(fileURLWithPath: outPath))
    print("Created \(name) (\(size)x\(size))")
}

print("Done generating PNGs")
