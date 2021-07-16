//
//  CameraViewController+Extensions.swift
//  Camera
//
//  Created by Marc Respass on 7/5/21.
//  Copyright © 2021 ILIOS Inc. All rights reserved.
//

import AppKit

@objc extension CameraViewController {
    func rotateImage(data: Data, angle: CGFloat, flipVertical: CGFloat, flipHorizontal: CGFloat) -> CGImage? {
        let ciImage = CIImage(data: data)

        let filter = CIFilter(name: "CIAffineTransform")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setDefaults()

        let newAngle = angle * CGFloat(-1)

        var transform = CATransform3DIdentity
        transform = CATransform3DRotate(transform, CGFloat(newAngle), 0, 0, 1)
        transform = CATransform3DRotate(transform, CGFloat(Double(flipVertical) * .pi), 0, 1, 0)
        transform = CATransform3DRotate(transform, CGFloat(Double(flipHorizontal) * .pi), 1, 0, 0)

        let affineTransform = CATransform3DGetAffineTransform(transform)

        filter?.setValue(NSValue(nonretainedObject: affineTransform), forKey: "inputTransform")

        let contex = CIContext(options: [CIContextOption.useSoftwareRenderer: true])

        let outputImage = filter?.outputImage
        let cgImage = contex.createCGImage(outputImage!, from: (outputImage?.extent)!)

        return cgImage
    }

    func rotatedImage(fromData data: Data) -> NSImage? {
        guard let cgImageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil),
              let mirrored = cgImage.rotating(to: .upMirrored) else { return nil }
        let image = NSImage(cgImage: mirrored, size: NSSize.zero)
        return image
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
        var degreesToRotate = 0.0
        var swapWidthHeight = false
        var mirrored = false

        switch orientation {
            case .up:
                break
            case .upMirrored:
                mirrored = true
            case .right:
                degreesToRotate = -90.0
                swapWidthHeight = true
            case .rightMirrored:
                degreesToRotate = -90.0
                swapWidthHeight = true
                mirrored = true
            case .down:
                degreesToRotate = 180.0
            case .downMirrored:
                degreesToRotate = 180.0
                mirrored = true
            case .left:
                degreesToRotate = 90.0
                swapWidthHeight = true
            case .leftMirrored:
                degreesToRotate = 90.0
                swapWidthHeight = true
                mirrored = true
        }
        return ImageProperties(degreesToRotate: degreesToRotate, swapWidthHeight: swapWidthHeight, mirrored: mirrored)
    }
}
