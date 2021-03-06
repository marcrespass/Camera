//  Created by Marc Respass on 8/2/11.
//  Copyright 2011 ILIOS Inc. All rights reserved.
//

@import Cocoa;
@import AVFoundation;

#import "CountdownViewController.h"
NS_ASSUME_NONNULL_BEGIN
@protocol OCRDelegate <NSObject>

- (void)displayRecognizedTextAtURL:(NSURL *)fileURL;
- (void)displayRecognizedText:(NSImage *)image;

@end

@interface CameraVC : NSViewController <CountdownViewControllerDelegate, AVCapturePhotoCaptureDelegate, NSPopoverDelegate>

@property (nonatomic, readonly, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, readwrite, strong) id<OCRDelegate> ocrDelegate;

- (instancetype)initWithCaptureDeviceDiscoverySession:(AVCaptureDeviceDiscoverySession *)session NS_DESIGNATED_INITIALIZER;

@end
NS_ASSUME_NONNULL_END
