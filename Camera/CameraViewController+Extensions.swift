//
//  CameraViewController+Extensions.swift
//  Camera
//
//  Created by Marc Respass on 7/27/20.
//  Copyright © 2020 ILIOS Inc. All rights reserved.
//

import Cocoa
import AVFoundation

@objc extension CameraViewController {
    func captureAndSaveImage() {
        // get the stillImageOutput with a video connection
        guard let imageOutput = self.stillImageOutput, let connection = imageOutput.connection(with: .video) else { return }

        connection.isVideoMirrored = true // MER 2021-01-13 this is already set but just set it to be safe
        let format = [AVVideoCodecKey: AVVideoCodecType.jpeg] // MER 2021-01-13 AVCapturePhotoSettings must be created new each time
        let capturePhotoSettings = AVCapturePhotoSettings(format: format)

        self.flashScreen()
        imageOutput.capturePhoto(with: capturePhotoSettings, delegate: self)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }
        self.snapshotData = data

        DispatchQueue.main.async {
            var url = URL(fileURLWithPath: NSTemporaryDirectory())
            url.appendPathComponent("\(NSLocalizedString("Camera", comment: "")) - \(NSUUID().partialUUID())")
            url.appendPathExtension("jpg")
            if (try? data.write(to: url)) != nil {
                debugPrint("Did write photo to: \(url.path)")
                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
            }
        }

    }
}

extension NSUUID {
    func partialUUID() -> String {
        let string = self.uuidString
        let components = string.split { (c) -> Bool in
            return c == "-"
        }
        if let last = components.last {
            return String(last)
        }
        return ""
    }
}
