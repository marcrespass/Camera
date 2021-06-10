//
//  CountdownViewController.h
//  AVCaptureTest
//
//  Created by Marc Respass on 8/3/11.
//  Copyright 2011 ILIOS Inc. All rights reserved.
//

@import Cocoa;
@import AVFoundation;
#import "CountdownViewControllerDelegate.h"

@interface CountdownViewController : NSViewController <AVAudioPlayerDelegate>

@property (nonatomic, assign) id <CountdownViewControllerDelegate> delegate;

- (void)beginCountdown;

@end

