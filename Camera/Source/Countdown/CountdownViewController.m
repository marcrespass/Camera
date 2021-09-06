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
@property (nonatomic, readwrite, weak) IBOutlet NSButton *cancelButton;
@property (nonatomic, readwrite, weak) IBOutlet NSImageView *imageView1;
@property (nonatomic, readwrite, weak) IBOutlet NSImageView *imageView2;
@property (nonatomic, readwrite, weak) IBOutlet NSImageView *imageView3;
@property (nonatomic, readwrite, weak) IBOutlet NSImageView *imageView4;

@property (nonatomic, assign) NSTimeInterval currentTimerInterval;
@property (nonatomic, assign) NSInteger currentCountdownSeconds;
@property (nonatomic, assign) NSTimeInterval countdownAlertTime;
@property (nonatomic, assign) NSTimeInterval countdownStartTime;

@property (nonatomic, readwrite, strong) AVAudioPlayer *audioAlertPlayer;
@property (nonatomic, readwrite, strong) NSArray *imageNames;
@property (nonatomic, readwrite, strong) NSTimer *timer;

@end

@implementation CountdownViewController

- (id)init;
{
    if(self = [super initWithNibName:nil bundle:nil])
    {
        _imageNames = @[@"1.square", @"2.square", @"3.square", @"camera.circle"];
        return self;
    }
    return nil;
}

- (void)dealloc;
{
    [_timer invalidate];
    _timer = nil;
}

- (NSString *)nibName;
{
    return @"CountdownViewController";
}

- (void)viewDidLoad;
{
    [super viewDidLoad];
    self.view.wantsLayer = YES;
    [self resetCountdown];
}

- (void)resetCountdown;
{
    self.imageView1.image = [NSImage imageWithSystemSymbolName:self.imageNames[0] accessibilityDescription:@"1"];
    self.imageView2.image = [NSImage imageWithSystemSymbolName:self.imageNames[1] accessibilityDescription:@"2"];
    self.imageView3.image = [NSImage imageWithSystemSymbolName:self.imageNames[2] accessibilityDescription:@"3"];
    self.imageView4.image = [NSImage imageWithSystemSymbolName:self.imageNames[3] accessibilityDescription:@"take picture"];
}

- (void)countdown:(NSTimer *)timer;
{
    NSTimeInterval now = NSDate.timeIntervalSinceReferenceDate;
    self.currentTimerInterval = now - self.countdownStartTime;

    NSInteger seconds = (NSInteger)self.currentTimerInterval % 60;

    if(seconds > self.currentCountdownSeconds && seconds < (kMaxSeconds + 1))
    {
        self.currentCountdownSeconds = seconds;
        NSUInteger imageIndex = (NSUInteger)seconds - 1;
        NSString *imageName = self.imageNames[imageIndex];
        NSString *fillImageName = [NSString stringWithFormat:@"%@.fill", imageName];
        NSString *propertyName = [NSString stringWithFormat:@"imageView%ld", self.currentCountdownSeconds];

        NSImageView *iv = [self valueForKey:propertyName];
        iv.image = [NSImage imageWithSystemSymbolName:fillImageName accessibilityDescription:@"count"];
    }

    if(self.currentTimerInterval >= (kMaxSeconds + 1))
    {
        NSURL *beepURL = [NSBundle.mainBundle URLForResource:@"Camera" withExtension:@"wav"];
        self.audioAlertPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:beepURL error:nil];
        [self.audioAlertPlayer play];

        [self.timer invalidate];
        self.timer = nil;

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
    [self.view.window makeFirstResponder:self.cancelButton];
    
    [self setupEndAlert];
    [self resetCountdown];

    self.countdownStartTime = [NSDate timeIntervalSinceReferenceDate];
    self.currentCountdownSeconds = 0;

    // Invalidate just in case someone triggers this method twice with no intervening stopStopwatch: call.
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                              target:self
                                            selector:@selector(countdown:)
                                            userInfo:NULL
                                             repeats:YES];
}

#pragma mark Actions
- (IBAction)cancel:(id)sender;
{
    [self.audioAlertPlayer stop];

    [self.timer invalidate];
    self.timer = nil;
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
