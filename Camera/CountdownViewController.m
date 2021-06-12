//
//  CountdownViewController.m
//  AVCaptureTest
//
//  Created by Marc Respass on 8/3/11.
//  Copyright 2011 ILIOS Inc. All rights reserved.
//

#import "CountdownViewController.h"

NSInteger kMaxSeconds = 3;

@interface CountdownViewController()
@property (nonatomic, readwrite, weak) IBOutlet NSImageView *imageView1;
@property (nonatomic, readwrite, weak) IBOutlet NSImageView *imageView2;
@property (nonatomic, readwrite, weak) IBOutlet NSImageView *imageView3;
@property (nonatomic, readwrite, weak) IBOutlet NSImageView *imageViewCamera;

@property (nonatomic, assign) NSTimeInterval currentTimerInterval;
@property (nonatomic, assign) NSInteger currentCountdownSeconds;
@property (nonatomic, assign, getter = isTimerRunning) BOOL timerRunning;
@property (nonatomic, assign) NSTimeInterval countdownAlertTime;

@property (nonatomic, readwrite, strong) AVAudioPlayer *audioAlertPlayer;

@end

@implementation CountdownViewController
{
    // IVARS
    NSTimer *timer_;
    NSTimeInterval start_;
    NSTimeInterval stop_;
}

- (id)init;
{
    if(self = [super initWithNibName:nil bundle:nil])
    {
        return self;
    }
    return nil;
}

- (void)dealloc;
{
    [timer_ invalidate];
    timer_ = nil;
}

- (NSString *)nibName;
{
    return @"CountdownViewController";
}

- (void)resetCountdown;
{
    self.imageViewCamera.image = [NSImage imageNamed:@"countdown-camera_dim"];
    self.imageView1.image = [NSImage imageNamed:@"countdown-no1_dim"];
    self.imageView2.image = [NSImage imageNamed:@"countdown-no2_dim"];
    self.imageView3.image = [NSImage imageNamed:@"countdown-no3_dim"];
}

- (void)countdown:(NSTimer *)timer;
{
    NSTimeInterval now = NSDate.timeIntervalSinceReferenceDate;
    self.currentTimerInterval = now - start_;

    NSInteger seconds = (NSInteger)self.currentTimerInterval % 60;

    if(seconds > self.currentCountdownSeconds && seconds < (kMaxSeconds + 1))
    {
        self.currentCountdownSeconds = seconds;

        NSString *imageName = [NSString stringWithFormat:@"countdown-no%ld", self.currentCountdownSeconds];
        NSString *propertyName = [NSString stringWithFormat:@"imageView%ld", self.currentCountdownSeconds];

        NSImageView *iv = [self valueForKey:propertyName];
        [iv setImage:[NSImage imageNamed:imageName]];
    }

    if(self.currentTimerInterval >= (kMaxSeconds + 1))
    {
        self.imageViewCamera.image = [NSImage imageNamed:@"countdown-camera"];

        NSURL *beepURL = [NSBundle.mainBundle URLForResource:@"Camera" withExtension:@"wav"];
        self.audioAlertPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:beepURL error:nil];
        [self.audioAlertPlayer play];

        [timer_ invalidate];
        timer_ = nil;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate countdownDidEnd:self];
        });
    }
}

- (void)setupEndAlert;
{
    // "Preparing to play" attaches to the audio hardware and ensures that playback
    // starts quickly when invoking -play
    NSURL *beepURL = [NSBundle.mainBundle URLForResource:@"Beep" withExtension:@"wav"];
    self.audioAlertPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:beepURL error:nil];

    [self.audioAlertPlayer prepareToPlay];
    self.audioAlertPlayer.volume = 1.0;
    self.audioAlertPlayer.delegate = self;

    NSTimeInterval now = self.audioAlertPlayer.deviceCurrentTime;
    self.countdownAlertTime = now + 1.0;

    [self.audioAlertPlayer playAtTime:self.countdownAlertTime];
}

- (void)beginCountdown;
{
    [self setupEndAlert];
    [self resetCountdown];

    self.timerRunning = YES;

    start_ = [NSDate timeIntervalSinceReferenceDate];
    stop_ = start_ + kMaxSeconds;
    self.currentCountdownSeconds = 0;

    // Invalidate just in case someone triggers this method twice with no intervening stopStopwatch: call.
    [timer_ invalidate];
    timer_ = [NSTimer scheduledTimerWithTimeInterval:0.1
                                              target:self
                                            selector:@selector(countdown:)
                                            userInfo:NULL
                                             repeats:YES];
}

#pragma mark Actions
- (IBAction)cancel:(id)sender;
{
    self.timerRunning = NO;
    [self.audioAlertPlayer stop];

    [timer_ invalidate];
    timer_ = nil;
    [self.view removeFromSuperview];
    [self.delegate countdownWasCanceled:self];
}

#pragma mark AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;
{
    static NSTimeInterval endTimeCount = 1;

    if(player != self.audioAlertPlayer)
    {
        return;
    }

    endTimeCount += 1;

    if(endTimeCount > kMaxSeconds)
    {
        endTimeCount = 1;
        return;
    }

    self.countdownAlertTime += 1;
    [self.audioAlertPlayer playAtTime:self.countdownAlertTime];
}

@end
