import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
  fatalError("Usage: swift export_ios_screens.swift INPUT_DIR OUTPUT_DIR")
}

let input = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let output = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

for url in try FileManager.default.contentsOfDirectory(at: input, includingPropertiesForKeys: nil)
  where url.pathExtension == "png" {
  guard let image = NSImage(contentsOf: url), image.size.width > image.size.height,
        let bitmap = NSBitmapImageRep(
          bitmapDataPlanes: nil, pixelsWide: Int(image.size.width), pixelsHigh: Int(image.size.height),
          bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
          colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Cannot export landscape screenshot: \(url.path)")
  }
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = context
  image.draw(in: NSRect(origin: .zero, size: image.size))
  NSGraphicsContext.restoreGraphicsState()
  guard let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 1.0]) else {
    fatalError("Cannot encode screenshot: \(url.path)")
  }
  try jpeg.write(to: output.appendingPathComponent(url.deletingPathExtension().lastPathComponent + ".jpg"))
}
