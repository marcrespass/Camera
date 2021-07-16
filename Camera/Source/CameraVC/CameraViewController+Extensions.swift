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
}
