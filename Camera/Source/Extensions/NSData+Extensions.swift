//
//  Data+Extensions.swift
//  Camera
//
//  Created by Marc Respass on 7/28/21.
//  Copyright © 2021 ILIOS Inc. All rights reserved.
//

import Foundation
import Vision

typealias RecognizedResult = Result<[String], Error
>
// MARK: - Vision text recognition
// https://developer.apple.com/documentation/vision/recognizing_text_in_images
@objc extension NSData {
    func cgImage() -> CGImage? {
        guard let cgImageSource = CGImageSourceCreateWithData(self as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil) else {
            return nil
        }
        return cgImage
    }

    @objc(nsImageMirroring:)
    func nsImage(mirrored: Bool) -> NSImage? {
        guard let cgImage = self.cgImage() else {
            return nil
        }

        if mirrored, let mirroredImage = cgImage.rotating(to: .upMirrored) {
            return NSImage(cgImage: mirroredImage, size: NSSize.zero)
        } else {
            return NSImage(cgImage: cgImage, size: NSSize.zero)
        }
    }

    @nonobjc
    func recognizeText(completionHandler: @escaping (RecognizedResult) -> Void) {
        guard let cgImage = self.cgImage() else {
            let error = NSError(with: "Unable to get CGImage from data")
            completionHandler(.failure(error))
            return
        }
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completionHandler(.failure(error))
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string // Return the string of the top VNRecognizedText instance.
            }
            completionHandler(.success(recognizedStrings))
        }
        do {
            try requestHandler.perform([request])
        } catch {
            completionHandler(.failure(error))
        }
    }
}
