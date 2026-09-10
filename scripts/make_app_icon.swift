#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let output = root.appendingPathComponent("Foldy/Resources/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func panelPath(in rect: CGRect, left: Bool) -> CGPath {
    let path = CGMutablePath()
    let center = rect.midX
    let gap = rect.width * 0.018
    let inset = rect.width * 0.17
    let top = rect.height * 0.73
    let bottom = rect.height * 0.27
    let outerTop = left ? inset : rect.width - inset
    let outerBottom = left ? inset * 0.78 : rect.width - inset * 0.78
    let innerX = left ? center - gap : center + gap

    path.move(to: CGPoint(x: innerX, y: top + rect.height * 0.035))
    path.addLine(to: CGPoint(x: outerTop, y: top))
    path.addLine(to: CGPoint(x: outerBottom, y: bottom))
    path.addLine(to: CGPoint(x: innerX, y: bottom - rect.height * 0.035))
    path.closeSubpath()
    return path
}

func drawIcon(size: Int) throws {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: size * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { throw CocoaError(.fileWriteUnknown) }

    let scale = CGFloat(size) / 1024
    context.scaleBy(x: scale, y: scale)
    let rect = CGRect(x: 0, y: 0, width: 1024, height: 1024)
    context.setFillColor(CGColor(red: 0.025, green: 0.035, blue: 0.09, alpha: 1))
    context.fill(rect)

    let glowColors = [
        CGColor(red: 0.12, green: 0.82, blue: 1, alpha: 0.32),
        CGColor(red: 0.46, green: 0.24, blue: 1, alpha: 0)
    ] as CFArray
    let glow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0, 1])!
    context.drawRadialGradient(
        glow,
        startCenter: CGPoint(x: 512, y: 500),
        startRadius: 40,
        endCenter: CGPoint(x: 512, y: 500),
        endRadius: 570,
        options: [.drawsAfterEndLocation]
    )

    let panelGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            CGColor(red: 0.18, green: 0.9, blue: 1, alpha: 1),
            CGColor(red: 0.48, green: 0.23, blue: 1, alpha: 1)
        ] as CFArray,
        locations: [0, 1]
    )!

    context.setShadow(offset: .zero, blur: 42, color: CGColor(red: 0.22, green: 0.75, blue: 1, alpha: 0.65))
    for left in [true, false] {
        context.saveGState()
        context.addPath(panelPath(in: rect, left: left))
        context.clip()
        context.drawLinearGradient(
            panelGradient,
            start: CGPoint(x: 250, y: 750),
            end: CGPoint(x: 780, y: 250),
            options: []
        )
        context.restoreGState()
    }

    context.setShadow(offset: .zero, blur: 20, color: CGColor(red: 0.75, green: 0.96, blue: 1, alpha: 0.9))
    context.setStrokeColor(CGColor(red: 0.78, green: 0.98, blue: 1, alpha: 1))
    context.setLineWidth(18)
    context.move(to: CGPoint(x: 512, y: 720))
    context.addLine(to: CGPoint(x: 512, y: 304))
    context.strokePath()

    guard let image = context.makeImage() else { throw CocoaError(.fileWriteUnknown) }
    let url = output.appendingPathComponent("icon_\(size).png")
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else { throw CocoaError(.fileWriteUnknown) }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
}

for size in [16, 32, 64, 128, 256, 512, 1024] {
    try drawIcon(size: size)
}

print("Generated Foldy icons in \(output.path)")
