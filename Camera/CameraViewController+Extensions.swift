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
    @objc func captureAndSaveImage() {
        var videoConnection: AVCaptureConnection?
        guard let imageOutput = self.stillImageOutput else { return }

        for connection in imageOutput.connections {
            for inputPort in connection.inputPorts {
                if inputPort.mediaType == AVMediaType.video {
                    videoConnection = connection
                    break
                }
            }
            if videoConnection != nil {
                break
            }
        }
        if videoConnection == nil { return }
        self.flashScreen()

        imageOutput.capturePhoto(with: self.photoSettings(), delegate: self)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }
        self.snapshotData = data

        DispatchQueue.main.async {
            var url = URL(fileURLWithPath: NSTemporaryDirectory())
            url.appendPathComponent(NSUUID().uuidString)
            url.appendPathExtension("jpg")
            if (try? data.write(to: url)) != nil {
                print("Did write photo to: \(url.path)")
            }
        }

    }
}
