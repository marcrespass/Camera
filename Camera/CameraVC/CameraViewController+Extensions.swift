//
//  CountdownViewController+Extensions.swift
//  Camera
//
//  Created by Marc Respass on 7/2/21.
//  Copyright © 2021 ILIOS Inc. All rights reserved.
//

import AppKit
import AVFoundation

extension CameraViewController {
    @IBAction private func takePicture(_ sender: Any? = nil) {
        sessionQueue.async {
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            var photoSettings = AVCapturePhotoSettings()

        }
    }
}
