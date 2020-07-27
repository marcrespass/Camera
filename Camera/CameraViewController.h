//  Created by Marc Respass on 8/2/11.
//  Copyright 2011 ILIOS Inc. All rights reserved.
//

@import Cocoa;
@import AVFoundation;

NS_ASSUME_NONNULL_BEGIN
@interface CameraViewController : NSViewController

@property (nullable, nonatomic, readwrite, strong) NSData *snapshotData;
@property (nullable, nonatomic, readwrite, strong) AVCapturePhotoOutput *stillImageOutput;

- (void)flashScreen;
- (AVCapturePhotoSettings *)photoSettings;

@end
NS_ASSUME_NONNULL_END
