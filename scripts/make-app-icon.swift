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

    drawGreenlightCharacter(in: rect, scale: scale)

    return image
}

func drawGreenlightCharacter(in rect: NSRect, scale: CGFloat) {
    let ink = NSColor(calibratedRed: 0.11, green: 0.14, blue: 0.18, alpha: 1)
    let green = NSColor(calibratedRed: 0.00, green: 0.79, blue: 0.49, alpha: 1)
    let strokeWidth = 18 * scale

    drawLeftArm(in: rect, scale: scale, ink: ink, strokeWidth: strokeWidth)
    drawRightArm(in: rect, scale: scale, ink: ink, strokeWidth: strokeWidth)
    drawLegs(in: rect, scale: scale, ink: ink, strokeWidth: strokeWidth)

    let bodyRect = NSRect(x: 214 * scale, y: 350 * scale, width: 548 * scale, height: 548 * scale)
    let shadow = NSShadow()
    shadow.shadowBlurRadius = 22 * scale
    shadow.shadowOffset = NSSize(width: 0, height: -12 * scale)
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.12)
    shadow.set()

    let body = NSBezierPath(roundedRect: bodyRect, xRadius: 142 * scale, yRadius: 142 * scale)
    green.setFill()
    body.fill()
    NSShadow().set()

    drawFace(in: bodyRect, scale: scale, ink: ink)
}

func drawLeftArm(in rect: NSRect, scale: CGFloat, ink: NSColor, strokeWidth: CGFloat) {
    let arm = NSBezierPath()
    arm.move(to: CGPoint(x: 228 * scale, y: 480 * scale))
    arm.curve(
        to: CGPoint(x: 138 * scale, y: 430 * scale),
        controlPoint1: CGPoint(x: 155 * scale, y: 480 * scale),
        controlPoint2: CGPoint(x: 105 * scale, y: 390 * scale)
    )
    arm.curve(
        to: CGPoint(x: 246 * scale, y: 558 * scale),
        controlPoint1: CGPoint(x: 174 * scale, y: 504 * scale),
        controlPoint2: CGPoint(x: 202 * scale, y: 546 * scale)
    )
    arm.lineWidth = strokeWidth
    arm.lineCapStyle = .round
    arm.lineJoinStyle = .round
    ink.setStroke()
    arm.stroke()

    let hand = NSBezierPath()
    hand.move(to: CGPoint(x: 252 * scale, y: 540 * scale))
    hand.line(to: CGPoint(x: 384 * scale, y: 498 * scale))
    hand.line(to: CGPoint(x: 376 * scale, y: 428 * scale))
    hand.curve(
        to: CGPoint(x: 335 * scale, y: 450 * scale),
        controlPoint1: CGPoint(x: 365 * scale, y: 420 * scale),
        controlPoint2: CGPoint(x: 350 * scale, y: 432 * scale)
    )
    hand.lineWidth = strokeWidth
    hand.lineCapStyle = .round
    hand.lineJoinStyle = .round
    hand.stroke()
}

func drawRightArm(in rect: NSRect, scale: CGFloat, ink: NSColor, strokeWidth: CGFloat) {
    let arm = NSBezierPath()
    arm.move(to: CGPoint(x: 762 * scale, y: 542 * scale))
    arm.curve(
        to: CGPoint(x: 884 * scale, y: 740 * scale),
        controlPoint1: CGPoint(x: 850 * scale, y: 558 * scale),
        controlPoint2: CGPoint(x: 856 * scale, y: 666 * scale)
    )
    arm.curve(
        to: CGPoint(x: 858 * scale, y: 852 * scale),
        controlPoint1: CGPoint(x: 900 * scale, y: 805 * scale),
        controlPoint2: CGPoint(x: 840 * scale, y: 892 * scale)
    )
    arm.curve(
        to: CGPoint(x: 830 * scale, y: 656 * scale),
        controlPoint1: CGPoint(x: 824 * scale, y: 786 * scale),
        controlPoint2: CGPoint(x: 858 * scale, y: 698 * scale)
    )
    arm.lineWidth = strokeWidth
    arm.lineCapStyle = .round
    arm.lineJoinStyle = .round
    ink.setStroke()
    arm.stroke()

    drawThumb(in: rect, scale: scale, ink: ink, strokeWidth: strokeWidth)
}

func drawThumb(in rect: NSRect, scale: CGFloat, ink: NSColor, strokeWidth: CGFloat) {
    let thumb = NSBezierPath()
    thumb.move(to: CGPoint(x: 872 * scale, y: 762 * scale))
    thumb.curve(
        to: CGPoint(x: 928 * scale, y: 758 * scale),
        controlPoint1: CGPoint(x: 880 * scale, y: 798 * scale),
        controlPoint2: CGPoint(x: 930 * scale, y: 796 * scale)
    )
    thumb.curve(
        to: CGPoint(x: 918 * scale, y: 666 * scale),
        controlPoint1: CGPoint(x: 958 * scale, y: 732 * scale),
        controlPoint2: CGPoint(x: 950 * scale, y: 682 * scale)
    )
    thumb.curve(
        to: CGPoint(x: 852 * scale, y: 692 * scale),
        controlPoint1: CGPoint(x: 900 * scale, y: 638 * scale),
        controlPoint2: CGPoint(x: 852 * scale, y: 652 * scale)
    )
    thumb.curve(
        to: CGPoint(x: 870 * scale, y: 760 * scale),
        controlPoint1: CGPoint(x: 852 * scale, y: 724 * scale),
        controlPoint2: CGPoint(x: 854 * scale, y: 744 * scale)
    )
    thumb.lineWidth = strokeWidth
    thumb.lineCapStyle = .round
    thumb.lineJoinStyle = .round
    ink.setStroke()
    NSColor(calibratedRed: 0.95, green: 0.97, blue: 0.97, alpha: 1).setFill()
    thumb.fill()
    thumb.stroke()

    let knuckle1 = NSBezierPath()
    knuckle1.move(to: CGPoint(x: 880 * scale, y: 725 * scale))
    knuckle1.line(to: CGPoint(x: 918 * scale, y: 732 * scale))
    knuckle1.lineWidth = 11 * scale
    knuckle1.lineCapStyle = .round
    ink.setStroke()
    knuckle1.stroke()

    let knuckle2 = NSBezierPath()
    knuckle2.move(to: CGPoint(x: 878 * scale, y: 690 * scale))
    knuckle2.line(to: CGPoint(x: 914 * scale, y: 698 * scale))
    knuckle2.lineWidth = 11 * scale
    knuckle2.lineCapStyle = .round
    knuckle2.stroke()
}

func drawLegs(in rect: NSRect, scale: CGFloat, ink: NSColor, strokeWidth: CGFloat) {
    let baseline = NSBezierPath()
    baseline.move(to: CGPoint(x: 285 * scale, y: 124 * scale))
    baseline.line(to: CGPoint(x: 740 * scale, y: 124 * scale))
    baseline.lineWidth = strokeWidth
    baseline.lineCapStyle = .round
    ink.setStroke()
    baseline.stroke()

    let leftLeg = NSBezierPath()
    leftLeg.move(to: CGPoint(x: 430 * scale, y: 338 * scale))
    leftLeg.line(to: CGPoint(x: 412 * scale, y: 124 * scale))
    leftLeg.line(to: CGPoint(x: 356 * scale, y: 124 * scale))
    leftLeg.line(to: CGPoint(x: 390 * scale, y: 190 * scale))
    leftLeg.line(to: CGPoint(x: 408 * scale, y: 338 * scale))
    leftLeg.lineWidth = strokeWidth
    leftLeg.lineCapStyle = .round
    leftLeg.lineJoinStyle = .round
    leftLeg.stroke()

    let rightLeg = NSBezierPath()
    rightLeg.move(to: CGPoint(x: 612 * scale, y: 338 * scale))
    rightLeg.line(to: CGPoint(x: 636 * scale, y: 124 * scale))
    rightLeg.line(to: CGPoint(x: 696 * scale, y: 124 * scale))
    rightLeg.line(to: CGPoint(x: 660 * scale, y: 190 * scale))
    rightLeg.line(to: CGPoint(x: 640 * scale, y: 338 * scale))
    rightLeg.lineWidth = strokeWidth
    rightLeg.lineCapStyle = .round
    rightLeg.lineJoinStyle = .round
    rightLeg.stroke()

    let centerLeg = NSBezierPath()
    centerLeg.move(to: CGPoint(x: 520 * scale, y: 340 * scale))
    centerLeg.line(to: CGPoint(x: 502 * scale, y: 124 * scale))
    centerLeg.lineWidth = strokeWidth
    centerLeg.lineCapStyle = .round
    centerLeg.stroke()
}

func drawFace(in bodyRect: NSRect, scale: CGFloat, ink: NSColor) {
    ink.setFill()
    let faceX = bodyRect.midX + 58 * scale
    let faceY = bodyRect.midY + 160 * scale

    NSBezierPath(ovalIn: NSRect(x: faceX - 58 * scale, y: faceY + 35 * scale, width: 16 * scale, height: 18 * scale)).fill()
    NSBezierPath(ovalIn: NSRect(x: faceX + 26 * scale, y: faceY + 35 * scale, width: 16 * scale, height: 18 * scale)).fill()

    let nose = NSBezierPath()
    nose.move(to: CGPoint(x: faceX - 2 * scale, y: faceY + 86 * scale))
    nose.line(to: CGPoint(x: faceX, y: faceY + 35 * scale))
    nose.lineWidth = 15 * scale
    nose.lineCapStyle = .round
    ink.setStroke()
    nose.stroke()

    let mouth = NSBezierPath()
    mouth.move(to: CGPoint(x: faceX - 72 * scale, y: faceY - 2 * scale))
    mouth.curve(
        to: CGPoint(x: faceX + 56 * scale, y: faceY - 4 * scale),
        controlPoint1: CGPoint(x: faceX - 54 * scale, y: faceY - 72 * scale),
        controlPoint2: CGPoint(x: faceX + 20 * scale, y: faceY - 92 * scale)
    )
    mouth.curve(
        to: CGPoint(x: faceX - 72 * scale, y: faceY - 2 * scale),
        controlPoint1: CGPoint(x: faceX + 18 * scale, y: faceY - 28 * scale),
        controlPoint2: CGPoint(x: faceX - 28 * scale, y: faceY + 2 * scale)
    )
    ink.setFill()
    mouth.fill()

    let tongue = NSBezierPath()
    tongue.move(to: CGPoint(x: faceX - 8 * scale, y: faceY - 54 * scale))
    tongue.curve(
        to: CGPoint(x: faceX + 34 * scale, y: faceY - 34 * scale),
        controlPoint1: CGPoint(x: faceX + 8 * scale, y: faceY - 68 * scale),
        controlPoint2: CGPoint(x: faceX + 28 * scale, y: faceY - 58 * scale)
    )
    tongue.curve(
        to: CGPoint(x: faceX - 8 * scale, y: faceY - 54 * scale),
        controlPoint1: CGPoint(x: faceX + 22 * scale, y: faceY - 36 * scale),
        controlPoint2: CGPoint(x: faceX + 8 * scale, y: faceY - 42 * scale)
    )
    NSColor(calibratedRed: 0.00, green: 0.79, blue: 0.49, alpha: 1).setFill()
    tongue.fill()
}
