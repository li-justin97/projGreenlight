import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    fputs("Usage: make-app-icon.swift <iconset-dir> <icns-path>\n", stderr)
    exit(2)
}

let iconsetURL = URL(fileURLWithPath: arguments[1])
let icnsURL = URL(fileURLWithPath: arguments[2])
let fileManager = FileManager.default
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
    let image = drawIcon(pixels: spec.pixels)
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

func drawIcon(pixels: Int) -> NSImage {
    let size = NSSize(width: pixels, height: pixels)
    let image = NSImage(size: size)
    image.lockFocus()
    defer { image.unlockFocus() }

    let rect = NSRect(origin: .zero, size: size)
    let scale = CGFloat(pixels) / 1024.0

    let background = NSBezierPath(roundedRect: rect.insetBy(dx: 58 * scale, dy: 58 * scale), xRadius: 214 * scale, yRadius: 214 * scale)
    NSColor(calibratedRed: 0.95, green: 0.97, blue: 0.97, alpha: 1).setFill()
    background.fill()

    drawTrafficBody(in: rect, scale: scale)

    return image
}

func drawTrafficBody(in rect: NSRect, scale: CGFloat) {
    let bodyWidth = 420 * scale
    let bodyHeight = 650 * scale
    let bodyRect = NSRect(
        x: rect.midX - bodyWidth / 2,
        y: rect.midY - bodyHeight / 2,
        width: bodyWidth,
        height: bodyHeight
    )

    let shadow = NSShadow()
    shadow.shadowBlurRadius = 34 * scale
    shadow.shadowOffset = NSSize(width: 0, height: -18 * scale)
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.set()

    let body = NSBezierPath(roundedRect: bodyRect, xRadius: 122 * scale, yRadius: 122 * scale)
    NSColor(calibratedRed: 0.17, green: 0.17, blue: 0.2, alpha: 1).setFill()
    body.fill()
    NSShadow().set()

    let lampDiameter = 178 * scale
    let gap = 40 * scale
    let totalLampHeight = lampDiameter * 3 + gap * 2
    let firstY = bodyRect.midY + totalLampHeight / 2 - lampDiameter
    let colors: [NSColor] = [
        NSColor.systemRed,
        NSColor.systemOrange,
        NSColor.systemGreen
    ]

    for index in 0..<3 {
        let y = firstY - CGFloat(index) * (lampDiameter + gap)
        let lampRect = NSRect(
            x: bodyRect.midX - lampDiameter / 2,
            y: y,
            width: lampDiameter,
            height: lampDiameter
        )
        let lamp = NSBezierPath(ovalIn: lampRect)
        colors[index].setFill()
        lamp.fill()

        if index == 2 {
            drawHappyFace(in: lampRect, scale: scale)
        }
    }
}

func drawHappyFace(in rect: NSRect, scale: CGFloat) {
    NSColor.black.withAlphaComponent(0.74).setFill()
    let eyeWidth = 26 * scale
    let eyeHeight = 34 * scale
    let eyeY = rect.midY + 16 * scale
    let eyeOffset = 42 * scale

    NSBezierPath(ovalIn: NSRect(x: rect.midX - eyeOffset - eyeWidth / 2, y: eyeY, width: eyeWidth, height: eyeHeight)).fill()
    NSBezierPath(ovalIn: NSRect(x: rect.midX + eyeOffset - eyeWidth / 2, y: eyeY, width: eyeWidth, height: eyeHeight)).fill()

    let smile = NSBezierPath()
    smile.move(to: CGPoint(x: rect.midX - 50 * scale, y: rect.midY - 28 * scale))
    smile.curve(
        to: CGPoint(x: rect.midX + 50 * scale, y: rect.midY - 28 * scale),
        controlPoint1: CGPoint(x: rect.midX - 24 * scale, y: rect.midY - 76 * scale),
        controlPoint2: CGPoint(x: rect.midX + 24 * scale, y: rect.midY - 76 * scale)
    )
    smile.lineWidth = 14 * scale
    smile.lineCapStyle = .round
    NSColor.black.withAlphaComponent(0.74).setStroke()
    smile.stroke()
}
