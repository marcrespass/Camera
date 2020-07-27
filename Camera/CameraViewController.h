//  Created by Marc Respass on 8/2/11.
//  Copyright 2011 ILIOS Inc. All rights reserved.
//

@import Cocoa;
@import AVFoundation;
//#import "AddImageViewController.h"
//#import "CountdownViewController.h"

@interface CameraViewController : NSViewController <AVCapturePhotoCaptureDelegate>
{
}

@property (nonatomic, weak) IBOutlet NSView *cameraDisplayView;
@property (nonatomic, weak) IBOutlet NSView *cameraControlView;

#pragma mark Recording
@property (nonatomic, readwrite, strong) AVCaptureSession *avCaptureSession;
@property (nonatomic, readwrite, strong) NSData *snapshotData;
@property (nonatomic, readonly, assign) BOOL hasRecordingDevice;

#pragma mark Device Selection
@property (nonatomic, readwrite, strong) NSArray *videoDevices;
@property (nonatomic, readwrite, weak) AVCaptureDevice *selectedVideoDevice; // derived 

- (void)setupAVCaptureSession;
- (void)tearDownAVCaptureSession;

@end
