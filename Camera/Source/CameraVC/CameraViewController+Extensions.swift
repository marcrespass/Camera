//
//  CameraViewController+Extensions.swift
//  Camera
//
//  Created by Marc Respass on 7/5/21.
//  Copyright © 2021 ILIOS Inc. All rights reserved.
//

import AppKit

@objc extension CameraViewController {
    func image(fromData data: Data, mirrored: Bool) -> NSImage? {
        guard let cgImageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil) else { return nil }

        if mirrored, let mirroredImage = cgImage.rotating(to: .upMirrored) {
            return NSImage(cgImage: mirroredImage, size: NSSize.zero)
        } else {
            return NSImage(cgImage: cgImage, size: NSSize.zero)
        }
    }
}

struct ImageProperties {
    var degreesToRotate: Double
    var swapWidthHeight: Bool
    var mirrored: Bool

    init(degreesToRotate: Double = 0.0, swapWidthHeight: Bool = false, mirrored: Bool = false) {
        self.degreesToRotate = degreesToRotate
        self.swapWidthHeight = swapWidthHeight
        self.mirrored = mirrored
    }
}

// MER 2021-07-16
// Many thanks for this extention to CGImage
// https://stackoverflow.com/a/68027419
// it produces a cyclomatic warning so I extracted the switch statement to return the ImageProperties struct from above
extension CGImage {
    func rotating(to orientation: CGImagePropertyOrientation) -> CGImage? {
        let originalWidth = self.width
        let originalHeight = self.height
        let bitsPerComponent = self.bitsPerComponent
        let bitmapInfo = self.bitmapInfo

        guard let colorSpace = self.colorSpace else {
            return nil
        }

        let imageProperties = self.imageProperties(for: orientation)

        let radians = imageProperties.degreesToRotate * Double.pi / 180.0

        var width: Int
        var height: Int

        if imageProperties.swapWidthHeight {
            width = originalHeight
            height = originalWidth
        } else {
            width = originalWidth
            height = originalHeight
        }

        let bytesPerRow = (width * bitsPerPixel) / 8

        let contextRef = CGContext(data: nil, width: width, height: height,
                                   bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow,
                                   space: colorSpace, bitmapInfo: bitmapInfo.rawValue)

        contextRef?.translateBy(x: CGFloat(width) / 2.0, y: CGFloat(height) / 2.0)

        if imageProperties.mirrored {
            contextRef?.scaleBy(x: -1.0, y: 1.0)
        }

        contextRef?.rotate(by: CGFloat(radians))

        if imageProperties.swapWidthHeight {
            contextRef?.translateBy(x: -CGFloat(height) / 2.0, y: -CGFloat(width) / 2.0)
        } else {
            contextRef?.translateBy(x: -CGFloat(width) / 2.0, y: -CGFloat(height) / 2.0)
        }

        contextRef?.draw(self, in: CGRect(x: 0.0, y: 0.0,
                                          width: CGFloat(originalWidth), height: CGFloat(originalHeight)))

        let orientedImage = contextRef?.makeImage()
        return orientedImage
    }

    func imageProperties(for orientation: CGImagePropertyOrientation) -> ImageProperties {
        switch orientation {
            case .up:
                return ImageProperties()
            case .upMirrored:
                return ImageProperties(mirrored: true)
            case .right:
                return ImageProperties(degreesToRotate: -90.0, swapWidthHeight: true)
            case .rightMirrored:
                return ImageProperties(degreesToRotate: -90.0, swapWidthHeight: true, mirrored: true)
            case .down:
                return ImageProperties(degreesToRotate: 180.0)
            case .downMirrored:
                return ImageProperties(degreesToRotate: 180.0, mirrored: true)
            case .left:
                return ImageProperties(degreesToRotate: 90.0, swapWidthHeight: true)
            case .leftMirrored:
                return ImageProperties(degreesToRotate: 90.0, swapWidthHeight: true, mirrored: true)
        }
    }
}
