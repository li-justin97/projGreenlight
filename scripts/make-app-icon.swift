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
    let image = resizedImage(sourceImage, pixels: spec.pixels)
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
    let image = NSImage(size: size)
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high

    NSColor.clear.setFill()
    NSRect(origin: .zero, size: size).fill()

    let sourceSize = source.size
    let scale = max(size.width / sourceSize.width, size.height / sourceSize.height)
    let drawSize = NSSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
    let drawRect = NSRect(
        x: (size.width - drawSize.width) / 2,
        y: (size.height - drawSize.height) / 2,
        width: drawSize.width,
        height: drawSize.height
    )
    source.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1)

    image.unlockFocus()
    return image
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
