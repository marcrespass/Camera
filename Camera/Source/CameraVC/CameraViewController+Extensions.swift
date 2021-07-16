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
              let mirrored = cgImage.rotating(to: .leftMirrored) else { return nil }
        let image = NSImage(cgImage: mirrored, size: NSSize.zero)
        return image
    }
}

// https://stackoverflow.com/a/68027419
extension CGImage {
    func rotating(to orientation: CGImagePropertyOrientation) -> CGImage? {
        var orientedImage: CGImage?

        let originalWidth = self.width
        let originalHeight = self.height
        let bitsPerComponent = self.bitsPerComponent
        let bitmapInfo = self.bitmapInfo

        guard let colorSpace = self.colorSpace else {
            return nil
        }

        var degreesToRotate: Double
        var swapWidthHeight: Bool
        var mirrored: Bool

        switch orientation {
            case .up:
                degreesToRotate = 0.0
                swapWidthHeight = false
                mirrored = false
            case .upMirrored:
                degreesToRotate = 0.0
                swapWidthHeight = false
                mirrored = true
            case .right:
                degreesToRotate = -90.0
                swapWidthHeight = true
                mirrored = false
            case .rightMirrored:
                degreesToRotate = -90.0
                swapWidthHeight = true
                mirrored = true
            case .down:
                degreesToRotate = 180.0
                swapWidthHeight = false
                mirrored = false
            case .downMirrored:
                degreesToRotate = 180.0
                swapWidthHeight = false
                mirrored = true
            case .left:
                degreesToRotate = 90.0
                swapWidthHeight = true
                mirrored = false
            case .leftMirrored:
                degreesToRotate = 90.0
                swapWidthHeight = true
                mirrored = true
        }

//        degreesToRotate -= 90.0 // MER 2021-07-16 image comes out well but not rotated all the way and changing degreesToRotate ends up with big black bars on top and bottom
        let radians = degreesToRotate * Double.pi / 180.0

        var width: Int
        var height: Int

        if swapWidthHeight {
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

        if mirrored {
            contextRef?.scaleBy(x: -1.0, y: 1.0)
        }

        contextRef?.rotate(by: CGFloat(radians))

        if swapWidthHeight {
            contextRef?.translateBy(x: -CGFloat(height) / 2.0, y: -CGFloat(width) / 2.0)
        } else {
            contextRef?.translateBy(x: -CGFloat(width) / 2.0, y: -CGFloat(height) / 2.0)
        }

        contextRef?.draw(self, in: CGRect(x: 0.0, y: 0.0,
                                          width: CGFloat(originalWidth), height: CGFloat(originalHeight)))

        orientedImage = contextRef?.makeImage()

        return orientedImage
    }
}
