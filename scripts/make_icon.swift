// Draws the placeholder app icon (a branching arrow on a gradient) into out/AppIcon.iconset.
// Run via scripts/make_icon.sh, which turns it into Resources/AppIcon.icns.
import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func render(_ pixels: Int) -> Data {
    let size = CGFloat(pixels)
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let inset = rect.insetBy(dx: size * 0.1, dy: size * 0.1)
    let shape = NSBezierPath(roundedRect: inset, xRadius: size * 0.2, yRadius: size * 0.2)
    NSGradient(
        starting: NSColor(red: 0.98, green: 0.45, blue: 0.20, alpha: 1),
        ending: NSColor(red: 0.30, green: 0.35, blue: 0.95, alpha: 1)
    )!.draw(in: shape, angle: -45)
    let config = NSImage.SymbolConfiguration(pointSize: size * 0.42, weight: .bold)
        .applying(.init(paletteColors: [.white]))
    let symbol = NSImage(systemSymbolName: "arrow.triangle.branch", accessibilityDescription: nil)!
        .withSymbolConfiguration(config)!
    let origin = NSPoint(
        x: rect.midX - symbol.size.width / 2, y: rect.midY - symbol.size.height / 2)
    symbol.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}

for points in [16, 32, 128, 256, 512] {
    try render(points).write(to: output.appendingPathComponent("icon_\(points)x\(points).png"))
    try render(points * 2).write(
        to: output.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}
