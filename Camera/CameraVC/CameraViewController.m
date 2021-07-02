//  Created by Marc Respass on 8/2/11.
//  Copyright 2011 ILIOS Inc. All rights reserved.
//

#import "CameraViewController.h"
#define MERLog(fmt, ...) NSLog(@"%s " fmt, __PRETTY_FUNCTION__, ##__VA_ARGS__)

@interface CameraViewController ()
@property (nonatomic, readwrite, weak) IBOutlet NSView *cameraDisplayView;
@property (nonatomic, readwrite, weak) IBOutlet NSView *cameraControlView;
@property (nonatomic, readwrite, weak) IBOutlet NSButton *takePictureButton;

@property (nonatomic, readwrite, strong) NSArray *videoDevices;
@property (nonatomic, readwrite, strong) NSArray *observers;
@property (nonatomic, readwrite, strong) NSData *snapshotData;
@property (nonatomic, readwrite, strong) AVCaptureSession *avCaptureSession;
@property (nonatomic, readwrite, weak) AVCaptureDevice *selectedVideoDevice; // derived
@property (nonatomic, readwrite, strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, readwrite, strong) CountdownViewController *countdownViewController;
@property (nonatomic, readonly, assign) BOOL hasRecordingDevice;
@property (nonatomic, readwrite, assign) BOOL takingPicture;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property (nonatomic, readwrite, strong) AVCaptureStillImageOutput *stillImageOutput;
#pragma clang diagnostic pop

@end

@implementation CameraViewController

#pragma mark - KVC/KVO
+ (NSSet *)keyPathsForValuesAffectingHasRecordingDevice
{
    return [NSSet setWithObjects:@"selectedVideoDevice", nil];
}

#pragma mark - init
- (id)init;
{
    if(self = [super initWithNibName:nil bundle:nil])
    {
        // Communicate with the session and other session objects on this queue.
        _sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
        _photoOutput = [[AVCapturePhotoOutput alloc] init];

        return self;
    }

    return nil;
}

- (NSString *)nibName;
{
    return @"CameraViewController";
}

- (void)dealloc;
{
    MERLog();
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    for(id observer in _observers)
    {
        [notificationCenter removeObserver:observer];
    }
}

- (void)setupCameraPreviewLayer;
{
    CALayer *viewLayer = self.cameraDisplayView.layer;

    [viewLayer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];

    // Create the AVCaptureVideoPreviewLayer and add it as a sub layer of previewViewLayer which retains it
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.avCaptureSession];
    videoPreviewLayer.frame = viewLayer.bounds;
    videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [viewLayer addSublayer:videoPreviewLayer];

    videoPreviewLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    viewLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;

    [self refreshDevices];
}

- (void)setupAVCaptureSession;
{
    self.avCaptureSession = [[AVCaptureSession alloc] init];

    // Capture Notification Observers
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    id runtimeErrorObserver = [notificationCenter addObserverForName:AVCaptureSessionRuntimeErrorNotification
                                                              object:self.avCaptureSession
                                                               queue:[NSOperationQueue mainQueue]
                                                          usingBlock:^(NSNotification *note) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self presentError:[[note userInfo] objectForKey:AVCaptureSessionErrorKey]];
        });
    }];
//    id didStartRunningObserver = [notificationCenter addObserverForName:AVCaptureSessionDidStartRunningNotification
//                                                                 object:self.avCaptureSession
//                                                                  queue:[NSOperationQueue mainQueue]
//                                                             usingBlock:^(NSNotification *note) {
//        MERLog(@"did start running");
//    }];
//    id didStopRunningObserver = [notificationCenter addObserverForName:AVCaptureSessionDidStopRunningNotification
//                                                                object:self.avCaptureSession
//                                                                 queue:[NSOperationQueue mainQueue]
//                                                            usingBlock:^(NSNotification *note) {
//        MERLog(@"did stop running");
//    }];
    id deviceWasConnectedObserver = [notificationCenter addObserverForName:AVCaptureDeviceWasConnectedNotification
                                                                    object:nil
                                                                     queue:[NSOperationQueue mainQueue]
                                                                usingBlock:^(NSNotification *note) {
        [self refreshDevices];
    }];
    id deviceWasDisconnectedObserver = [notificationCenter addObserverForName:AVCaptureDeviceWasDisconnectedNotification
                                                                       object:nil
                                                                        queue:[NSOperationQueue mainQueue]
                                                                   usingBlock:^(NSNotification *note) {
        [self refreshDevices];
    }];
    self.observers = [[NSArray alloc] initWithObjects:runtimeErrorObserver, deviceWasConnectedObserver, deviceWasDisconnectedObserver, nil];

    // Setup output
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
#pragma clang diagnostic pop
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecTypeJPEG, AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    [self.avCaptureSession addOutput:self.stillImageOutput];

    // Select devices if any exist starting with a video device
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (videoDevice)
    {
        [self setSelectedVideoDevice:videoDevice];
    }
    else
    {
        [self setSelectedVideoDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeMuxed]];
    }

    [self setupCameraPreviewLayer];
}

- (void)tearDownAVCaptureSession;
{
    [self.avCaptureSession stopRunning];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    for(id observer in self.observers)
    {
        [notificationCenter removeObserver:observer];
    }
    self.observers = nil;

    self.avCaptureSession = nil;
    self.captureDeviceInput = nil;
    self.videoDevices = nil;
    self.stillImageOutput = nil;

    [self.cameraDisplayView.layer setSublayers:nil];
}

- (void)viewDidLoad;
{
    [super viewDidLoad];
    self.cameraDisplayView.wantsLayer = YES;

    self.countdownViewController = [[CountdownViewController alloc] init];
    self.countdownViewController.delegate = self;

    [self setupAVCaptureSession];
}

#pragma mark - Device selection
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)refreshDevices
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.videoDevices = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] arrayByAddingObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeMuxed]];

        [self.avCaptureSession beginConfiguration];

        if (![[self videoDevices] containsObject:[self selectedVideoDevice]])
        {
            [self setSelectedVideoDevice:nil];
        }
        [self.avCaptureSession commitConfiguration];

        [self.view.window makeFirstResponder:self.takePictureButton];
        [self.avCaptureSession startRunning];
    });
}
#pragma clang diagnostic pop

#pragma mark - Camera Helpers
- (void)flashScreen;
{
#ifndef DEBUG
    int windowLevel = CGShieldingWindowLevel();
    NSRect screenRect = NSScreen.mainScreen.frame;
    NSWindow *window = [[NSWindow alloc] initWithContentRect:screenRect
                                                   styleMask:NSWindowStyleMaskBorderless
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO
                                                      screen:[NSScreen mainScreen]];
    window.level = windowLevel;
    window.backgroundColor = NSColor.whiteColor;
    [window makeKeyAndOrderFront:nil];
    [window.animator setAlphaValue:0.0];
#endif
}

#pragma mark - Actions
- (IBAction)captureImage:(id)sender;
{
    self.takingPicture = YES;

    NSView *countdownView = self.countdownViewController.view;
    countdownView.frame = self.cameraControlView.frame;
    self.cameraControlView.hidden = YES;
    [self.view addSubview:countdownView positioned:NSWindowAbove relativeTo:nil];

    [self.countdownViewController beginCountdown];
}

#pragma mark - Image Capture
- (AVCaptureConnection *)captureConnection;
{
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in connection.inputPorts)
        {
            if ([port.mediaType isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
                break;
            }
        }
        if(videoConnection)
        {
            break;
        }
    }

    return videoConnection;
}

- (void)captureAndSaveImage;
{
    AVCaptureConnection *videoConnection = [self captureConnection];
    if(!videoConnection)
    {
        return;
    }

    [self flashScreen];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                       completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
        self.snapshotData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.takingPicture = NO;
            if (imageSampleBuffer != NULL)
            {
                NSString *filename = NSUUID.UUID.UUIDString;
                NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
                NSURL *url = [NSURL fileURLWithPath:path];
                NSError *writeError = nil;
                if(![self.snapshotData writeToURL:url options:0 error:&writeError])
                {
                    MERLog(@"%@", writeError);
                    [NSApp presentError:writeError];
                }
                else
                {
                    [NSWorkspace.sharedWorkspace openURL:url];
                }
                [self.view.window makeFirstResponder:self.view];
            }
        });
    }];
#pragma clang diagnostic pop
}

#pragma mark - CountdownViewControllerDelegate
- (void)countdownDidEnd:(CountdownViewController *)countdown;
{
    [self captureAndSaveImage];
    [countdown.view removeFromSuperview];
    self.takingPicture = NO;

    [self.cameraControlView setHidden:NO];
}

- (void)countdownWasCanceled:(CountdownViewController *)countdown;
{
    [self.cameraControlView setHidden:NO];
    self.takingPicture = NO;
    [self.view.window makeFirstResponder:self.view];
}

#pragma mark - Accessors
- (BOOL)hasRecordingDevice
{
    return (self.captureDeviceInput != nil);
}

- (AVCaptureDevice *)selectedVideoDevice
{
    return [self.captureDeviceInput device];
}

- (void)setSelectedVideoDevice:(AVCaptureDevice *)selectedVideoDevice
{
    [self.avCaptureSession beginConfiguration];

    if(self.captureDeviceInput)
    {
        // Remove the old device input from the session
        [self.avCaptureSession removeInput:self.captureDeviceInput];
        self.captureDeviceInput = nil;
    }

    if (selectedVideoDevice)
    {
        NSError *error = nil;

        // Create a device input for the device and add it to the session
        AVCaptureDeviceInput *newVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:selectedVideoDevice error:&error];

        if (newVideoDeviceInput == nil)
        {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self presentError:error];
            });
        }
        else
        {
            if (![selectedVideoDevice supportsAVCaptureSessionPreset:[self.avCaptureSession sessionPreset]])
                [self.avCaptureSession setSessionPreset:AVCaptureSessionPresetHigh];

            [self.avCaptureSession addInput:newVideoDeviceInput];
            self.captureDeviceInput = newVideoDeviceInput;
        }
    }

    [self.avCaptureSession commitConfiguration];
}

#pragma mark - Validation
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;
{
    if([anItem action] == @selector(captureImage:))
    {
        return (self.hasRecordingDevice && self.takingPicture == NO);
    }

    return YES;
}

@end
