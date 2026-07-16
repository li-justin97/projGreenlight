import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 4 else {
    fputs("Usage: make-app-icon.swift <source-png> <iconset-dir> <icns-path>\n", stderr)
    exit(2)
}

let sourceURL = URL(fileURLWithPath: arguments[1])
let iconsetURL = URL(fileURLWithPath: arguments[2])
let icnsURL = URL(fileURLWithPath: arguments[3])
let fileManager = FileManager.default

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    fputs("Could not read source image at \(sourceURL.path)\n", stderr)
    exit(1)
}

let foregroundImage = imageWithSourceBackgroundRemoved(sourceImage)

try? fileManager.removeItem(at: iconsetURL)
try? fileManager.removeItem(at: icnsURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let specs: [(name: String, pixels: Int, icnsType: String?)] = [
    ("icon_16x16.png", 16, "icp4"),
    ("icon_16x16@2x.png", 32, nil),
    ("icon_32x32.png", 32, "icp5"),
    ("icon_32x32@2x.png", 64, "icp6"),
    ("icon_128x128.png", 128, "ic07"),
    ("icon_128x128@2x.png", 256, nil),
    ("icon_256x256.png", 256, "ic08"),
    ("icon_256x256@2x.png", 512, nil),
    ("icon_512x512.png", 512, "ic09"),
    ("icon_512x512@2x.png", 1024, "ic10")
]

var icnsChunks: [(type: String, data: Data)] = []
for spec in specs {
    let image = resizedImage(foregroundImage, pixels: spec.pixels)
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        fputs("Failed to render \(spec.name)\n", stderr)
        exit(1)
    }

    try png.write(to: iconsetURL.appendingPathComponent(spec.name))
    if let icnsType = spec.icnsType {
        icnsChunks.append((icnsType, png))
    }
}

try writeICNS(chunks: icnsChunks, to: icnsURL)

func resizedImage(_ source: NSImage, pixels: Int) -> NSImage {
    let size = NSSize(width: pixels, height: pixels)
    let characterScale = 0.88
    let image = NSImage(size: size)
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high

    NSColor.clear.setFill()
    NSRect(origin: .zero, size: size).fill()

    let tileRect = NSRect(
        x: size.width * 0.13,
        y: size.height * 0.13,
        width: size.width * 0.74,
        height: size.height * 0.74
    )
    let cornerRadius = tileRect.width * 0.22

    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
    shadow.shadowBlurRadius = size.width * 0.035
    shadow.shadowOffset = NSSize(width: 0, height: -size.height * 0.018)
    shadow.set()

    NSColor.white.setFill()
    NSBezierPath(roundedRect: tileRect, xRadius: cornerRadius, yRadius: cornerRadius).fill()

    NSGraphicsContext.current?.restoreGraphicsState()

    let sourceSize = source.size
    let contentRect = alphaBounds(in: source) ?? NSRect(origin: .zero, size: sourceSize)
    let insetTileRect = tileRect.insetBy(dx: tileRect.width * 0.035, dy: tileRect.height * 0.035)
    let targetSize = NSSize(width: insetTileRect.width * characterScale, height: insetTileRect.height * characterScale)
    let scale = min(targetSize.width / contentRect.width, targetSize.height / contentRect.height)
    let drawSize = NSSize(width: contentRect.width * scale, height: contentRect.height * scale)
    let drawRect = NSRect(
        x: insetTileRect.midX - drawSize.width / 2,
        y: insetTileRect.midY - drawSize.height / 2 - tileRect.height * 0.01,
        width: drawSize.width,
        height: drawSize.height
    )
    source.draw(in: drawRect, from: contentRect, operation: .sourceOver, fraction: 1)

    image.unlockFocus()
    return image
}

func imageWithSourceBackgroundRemoved(_ source: NSImage) -> NSImage {
    guard
        let cgImage = source.cgImage(forProposedRect: nil, context: nil, hints: nil),
        let pixelData = rgbaPixels(from: cgImage)
    else {
        return source
    }

    var data = pixelData.data
    for index in stride(from: 0, to: data.count, by: 4) {
        let red = Int(data[index])
        let green = Int(data[index + 1])
        let blue = Int(data[index + 2])
        let maxChannel = max(red, green, blue)
        let minChannel = min(red, green, blue)

        let isBlackFrame = red < 10 && green < 10 && blue < 10
        let isPaleBackdrop = minChannel > 150 && maxChannel - minChannel < 75

        if isBlackFrame || isPaleBackdrop {
            data[index] = 0
            data[index + 1] = 0
            data[index + 2] = 0
            data[index + 3] = 0
        }
    }

    guard let output = makeCGImage(width: pixelData.width, height: pixelData.height, rgbaData: data) else {
        return source
    }

    return NSImage(cgImage: output, size: NSSize(width: pixelData.width, height: pixelData.height))
}

func alphaBounds(in source: NSImage) -> NSRect? {
    guard
        let cgImage = source.cgImage(forProposedRect: nil, context: nil, hints: nil),
        let pixelData = rgbaPixels(from: cgImage)
    else {
        return nil
    }

    var minX = pixelData.width
    var minY = pixelData.height
    var maxX = -1
    var maxY = -1

    for y in 0..<pixelData.height {
        for x in 0..<pixelData.width {
            let alpha = pixelData.data[(y * pixelData.width + x) * 4 + 3]
            if alpha > 16 {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
    }

    guard maxX >= minX, maxY >= minY else {
        return nil
    }

    return NSRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
}

func rgbaPixels(from cgImage: CGImage) -> (width: Int, height: Int, data: [UInt8])? {
    let width = cgImage.width
    let height = cgImage.height
    let bytesPerRow = width * 4
    var data = [UInt8](repeating: 0, count: height * bytesPerRow)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    guard let context = CGContext(
        data: &data,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        return nil
    }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    return (width, height, data)
}

func makeCGImage(width: Int, height: Int, rgbaData: [UInt8]) -> CGImage? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerRow = width * 4
    guard let provider = CGDataProvider(data: Data(rgbaData) as CFData) else {
        return nil
    }

    return CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
        provider: provider,
        decode: nil,
        shouldInterpolate: true,
        intent: .defaultIntent
    )
}

func writeICNS(chunks: [(type: String, data: Data)], to url: URL) throws {
    var body = Data()
    for chunk in chunks {
        guard let typeData = chunk.type.data(using: .ascii), typeData.count == 4 else {
            continue
        }

        body.append(typeData)
        body.append(bigEndianUInt32(UInt32(chunk.data.count + 8)))
        body.append(chunk.data)
    }

    var file = Data()
    file.append(Data("icns".utf8))
    file.append(bigEndianUInt32(UInt32(body.count + 8)))
    file.append(body)
    try file.write(to: url)
}

func bigEndianUInt32(_ value: UInt32) -> Data {
    var bigEndian = value.bigEndian
    return Data(bytes: &bigEndian, count: MemoryLayout<UInt32>.size)
}
