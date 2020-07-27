//  Created by Marc Respass on 8/2/11.
//  Copyright 2011 ILIOS Inc. All rights reserved.
//

#import "CameraViewController.h"
//#import "Roast.h"
//#import "CommonMacros.h"

@interface CameraViewController ()

@property (nonatomic, weak) IBOutlet NSView *cameraDisplayView;
@property (nonatomic, weak) IBOutlet NSView *cameraControlView;

#pragma mark Recording
@property (nonatomic, readwrite, strong) AVCaptureSession *avCaptureSession;
@property (nonatomic, readwrite, strong) NSData *snapshotData;
@property (nonatomic, readonly, assign) BOOL hasRecordingDevice;

#pragma mark Device Selection
@property (nonatomic, readwrite, strong) NSArray *videoDevices;
@property (nonatomic, readwrite, weak) AVCaptureDevice *selectedVideoDevice; // derived

@property (nonatomic, readwrite, weak) IBOutlet NSButton *cancelButton;
@property (nonatomic, readwrite, weak) IBOutlet NSButton *takePictureButton;

@property (nonatomic, readwrite, strong) NSArray *observers;

@property (nonatomic, readwrite, strong) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic, readwrite, strong) AVCapturePhotoOutput *stillImageOutput;
@property (nonatomic, readwrite, strong) AVCapturePhotoSettings *photoSettings;

@property (nonatomic, assign) BOOL takingPicture;

//@property (nonatomic, readonly, strong) CountdownViewController *countdownViewController;

- (void)refreshDevices;

@end

@implementation CameraViewController

//@synthesize countdownViewController = countdownViewController_;

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
    }

    return self;
}

- (void)dealloc;
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    for(id observer in _observers)
    {
        [notificationCenter removeObserver:observer];
    }
}

- (void)setupCameraPreviewLayer;
{
    // Get the layer from the view (which is set in IB to want a layer)
    CALayer *cameraDisplayViewLayer = [self.cameraDisplayView layer];
    [cameraDisplayViewLayer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];

    // Create the AVCaptureVideoPreviewLayer and add it as a sub layer of previewViewLayer which retains it
    AVCaptureVideoPreviewLayer *newPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.avCaptureSession];
    newPreviewLayer.frame = cameraDisplayViewLayer.bounds;
    newPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    newPreviewLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    [cameraDisplayViewLayer addSublayer:newPreviewLayer];
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
    id didStartRunningObserver = [notificationCenter addObserverForName:AVCaptureSessionDidStartRunningNotification
                                                                 object:self.avCaptureSession
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification *note) {
        NSLog(@"did start running");
    }];
    id didStopRunningObserver = [notificationCenter addObserverForName:AVCaptureSessionDidStopRunningNotification
                                                                object:self.avCaptureSession
                                                                 queue:[NSOperationQueue mainQueue]
                                                            usingBlock:^(NSNotification *note) {
        NSLog(@"did stop running");
    }];
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
    self.observers = [[NSArray alloc] initWithObjects:runtimeErrorObserver, didStartRunningObserver, didStopRunningObserver, deviceWasConnectedObserver, deviceWasDisconnectedObserver, nil];

    // Setup output
    NSDictionary *format = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecTypeJPEG, AVVideoCodecKey, nil];
    self.photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:format];
    self.stillImageOutput = [[AVCapturePhotoOutput alloc] init];
    //    [self.stillImageOutput setOutputSettings:outputSettings];
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
    [self refreshDevices];
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
    self.videoDeviceInput = nil;
    self.videoDevices = nil;
    self.stillImageOutput = nil;

    [self.cameraDisplayView.layer setSublayers:nil];
}

- (void)viewDidLoad;
{
    [super viewDidLoad];
    self.view.translatesAutoresizingMaskIntoConstraints = NO;

    self.view.wantsLayer = YES;
    self.cameraDisplayView.wantsLayer = YES;

    self.cancelButton.title = NSLocalizedString(@"CancelLabel", @"");
    self.takePictureButton.toolTip = NSLocalizedString(@"TakePictureTooltip", @"");

    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupAVCaptureSession];
    });
}

#pragma mark - Device selection
- (void)refreshDevices
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *deviceTypes = @[AVCaptureDeviceTypeExternalUnknown, AVCaptureDeviceTypeBuiltInWideAngleCamera];
        AVCaptureDeviceDiscoverySession *session;
        session = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes
                                                                         mediaType:AVMediaTypeVideo
                                                                          position:AVCaptureDevicePositionUnspecified];
        self.videoDevices = session.devices;

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

#pragma mark - Lazy Init
//- (CountdownViewController *)countdownViewController;
//{
//    if(!countdownViewController_)
//    {
//        countdownViewController_ = [[CountdownViewController alloc] init];
//        countdownViewController_.delegate = self;
//    }
//
//    return countdownViewController_;
//}

#pragma mark - Camera Helpers
- (void)savePicture;
{
    NSError *error = nil;

    NSURL *url = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:NSTemporaryDirectory(), @"photo.jpg", nil]];
    if(![self.snapshotData writeToURL:url options:NSDataWritingAtomic error:&error])
    {
        [NSApp presentError:error];
    }
    else
    {
        NSLog(@"Picture written to:\n%@", url);
    }
}

- (void)flashScreen;
{
    // Capture the main display
    //    if (CGDisplayCapture( kCGDirectMainDisplay ) != kCGErrorSuccess)
    //    {
    //        MERLogError(@"Couldn't capture the main display!" );
    //        return;
    //    }

    int windowLevel = CGShieldingWindowLevel();

    NSRect screenRect = [[NSScreen mainScreen] frame];

    NSWindow *window = [[NSWindow alloc] initWithContentRect:screenRect
                                                   styleMask:NSWindowStyleMaskBorderless
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO
                                                      screen:[NSScreen mainScreen]];
    //    [window setReleasedWhenClosed:YES];

    [window setLevel:windowLevel];

    [window setBackgroundColor:NSColor.whiteColor];
    [window makeKeyAndOrderFront:nil];

    [[window animator] setAlphaValue:0.0];

    //    [window close];
    //    if (CGDisplayRelease( kCGDirectMainDisplay ) != kCGErrorSuccess)
    //    {
    //        NSLog( @"Couldn't release the display(s)!" );
    //        // Note: if you display an error dialog here, make sure you set
    //        // its window level to the same one as the shield window level,
    //        // or the user won't see anything.
    //    }
}

#pragma mark - Actions
- (IBAction)cancel:(id)sender;
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [NSApp sendAction:@selector(dismissCameraView) to:nil from:self];
#pragma clang diagnostic pop
}

- (IBAction)captureImage:(id)sender;
{
    //    NSView *countdownView = self.countdownViewController.view;
    //
    //    [countdownView setFrame:[self.cameraControlView frame]];
    //
    //    [self.cameraControlView setHidden:YES];
    //    [self.view addSubview:countdownView positioned:NSWindowAbove relativeTo:nil];
    //
    //    self.takingPicture = YES;
    //
    //    [self.countdownViewController beginCountdown];
    [self captureAndSaveImage];
}

#pragma mark - Image Capture
- (void)captureAndSaveImage;
{
    AVCaptureConnection *videoConnection = nil;

    for (AVCaptureConnection *connection in self.stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
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

    if(!videoConnection)
        return;

#ifndef DEBUG
    [self flashScreen];
#endif

    [self.stillImageOutput capturePhotoWithSettings:self.photoSettings delegate:self];

    //    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
    //                                                       completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
    //     {
    //         if (imageSampleBuffer != NULL)
    //         {
    //             self.snapshotData = [AVCapturePhotoOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
    //             dispatch_async(dispatch_get_main_queue(), ^(void) {
    //                 NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"image.jpeg"];
    //                 NSURL *url = [NSURL fileURLWithPath:path];
    //                 [self.snapshotData writeToURL:url atomically:NO];
    //             });
    //         }
    //     }];
}

#pragma mark - CountdownViewControllerDelegate
//- (void)countdownDidEnd:(CountdownViewController *)countdown;
//{
//    [self captureAndSaveImage];
//    [countdown.view removeFromSuperview];
//    self.takingPicture = NO;
//
//    [self.cameraControlView setHidden:NO];
//}
//
//- (void)countdownWasCanceled:(CountdownViewController *)countdown;
//{
//    self.takingPicture = NO;
//
//    [self.cameraControlView setHidden:NO];
//}

#pragma mark - Accessors
- (BOOL)hasRecordingDevice
{
    return (self.videoDeviceInput != nil);
}

- (AVCaptureDevice *)selectedVideoDevice
{
    return [self.videoDeviceInput device];
}

- (void)setSelectedVideoDevice:(AVCaptureDevice *)selectedVideoDevice
{
    [self.avCaptureSession beginConfiguration];

    if(self.videoDeviceInput)
    {
        // Remove the old device input from the session
        [self.avCaptureSession removeInput:self.videoDeviceInput];
        self.videoDeviceInput = nil;
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
            self.videoDeviceInput = newVideoDeviceInput;
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

#pragma mark - AVCapturePhotoCaptureDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error;
{
    self.snapshotData = photo.fileDataRepresentation;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"image.jpeg"];
        NSURL *url = [NSURL fileURLWithPath:path];
        [self.snapshotData writeToURL:url atomically:NO];
    });

}
@end
