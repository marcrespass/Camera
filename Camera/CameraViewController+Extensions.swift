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
            for inputPort in connection.inputPorts where inputPort.mediaType == AVMediaType.video {
                videoConnection = connection
                break
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
