//
//  CameraViewController+Extensions.swift
//  Camera
//
//  Created by Marc Respass on 7/5/21.
//  Copyright © 2021 ILIOS Inc. All rights reserved.
//

import AppKit

// MER 2021-07-16
// Many thanks for this extension to CGImage
// https://stackoverflow.com/a/68027419
// it produces a cyclomatic warning so I extracted the switch statement to return the ImageProperties struct
extension CGImage {
    func rotating(to orientation: CGImagePropertyOrientation) -> CGImage? {
        let originalWidth = self.width
        let originalHeight = self.height

        let imageProperties = self.imageProperties(for: orientation)
        let radians = imageProperties.degreesToRotate * Double.pi / 180.0
        let width = imageProperties.swapWidthHeight ? originalHeight : originalWidth
        let height = imageProperties.swapWidthHeight ? originalWidth : originalHeight

        let bytesPerRow = (width * bitsPerPixel) / 8

        guard let colorSpace = self.colorSpace,
              let contextRef = CGContext(data: nil,
                                         width: width,
                                         height: height,
                                         bitsPerComponent: self.bitsPerComponent,
                                         bytesPerRow: bytesPerRow,
                                         space: colorSpace,
                                         bitmapInfo: self.bitmapInfo.rawValue) else {
            print("ERROR: CGContext is nil!")
            return nil
        }

        contextRef.translateBy(x: CGFloat(width) / 2.0, y: CGFloat(height) / 2.0)

        if imageProperties.mirrored {
            contextRef.scaleBy(x: -1.0, y: 1.0)
        }

        contextRef.rotate(by: CGFloat(radians))

        if imageProperties.swapWidthHeight {
            contextRef.translateBy(x: -CGFloat(height) / 2.0, y: -CGFloat(width) / 2.0)
        } else {
            contextRef.translateBy(x: -CGFloat(width) / 2.0, y: -CGFloat(height) / 2.0)
        }

        let rect = CGRect(x: 0.0,
                          y: 0.0,
                          width: CGFloat(originalWidth),
                          height: CGFloat(originalHeight))
        contextRef.draw(self, in: rect)
        let orientedImage = contextRef.makeImage()
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
