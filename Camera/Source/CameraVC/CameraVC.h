//  Created by Marc Respass on 8/2/11.
//  Copyright 2011 ILIOS Inc. All rights reserved.
//

@import Cocoa;
@import AVFoundation;

#import "CountdownViewController.h"
NS_ASSUME_NONNULL_BEGIN
@protocol OCRDelegate <NSObject>

- (void)displayRecognizedTextAtURL:(NSURL *)fileURL;
- (void)displayRecognizedTextFromData:(NSData *)imageData withTitle:(NSString *)title;

@end

@interface CameraVC : NSViewController <CountdownViewControllerDelegate, AVCapturePhotoCaptureDelegate, NSPopoverDelegate>

@property (nonatomic, readonly, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, readwrite, strong) id<OCRDelegate> ocrDelegate;

- (id)initWithCaptureDeviceDiscoverySession:(AVCaptureDeviceDiscoverySession *)session;

@end
NS_ASSUME_NONNULL_END
