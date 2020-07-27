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

#pragma mark Device Selection
@property (nonatomic, readwrite, strong) NSArray *videoDevices;
@property (nonatomic, readwrite, weak) AVCaptureDevice *selectedVideoDevice; // derived

@property (nonatomic, readwrite, weak) IBOutlet NSButton *cancelButton;
@property (nonatomic, readwrite, weak) IBOutlet NSButton *takePictureButton;

@property (nonatomic, readwrite, strong) NSMutableArray *observers;

@property (nonatomic, readwrite, strong) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic, readwrite, strong) AVCapturePhotoOutput *stillImageOutput;

@property (nonatomic, assign) BOOL takingPicture;

//@property (nonatomic, readonly, strong) CountdownViewController *countdownViewController;

- (void)refreshDevices;

@end

@implementation CameraViewController

//@synthesize countdownViewController = countdownViewController_;

#pragma mark - init
- (id)init;
{
    if(self = [super initWithNibName:nil bundle:nil])
    {
        _observers = [[NSMutableArray alloc] initWithCapacity:6];
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

    self.stillImageOutput = [[AVCapturePhotoOutput alloc] init];
    [self.avCaptureSession addOutput:self.stillImageOutput];

    [self setupCameraPreviewLayer];
    [self refreshDevices];

    [self setupCaptureSessionNotifications];
    [self setupCaptureDeviceNotifications];
}

- (void)setupCaptureSessionNotifications;
{
    // Capture Notification Observers
    id runtimeErrorObserver = [NSNotificationCenter.defaultCenter addObserverForName:AVCaptureSessionRuntimeErrorNotification
                                                              object:self.avCaptureSession
                                                               queue:[NSOperationQueue mainQueue]
                                                          usingBlock:^(NSNotification *note) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self presentError:[[note userInfo] objectForKey:AVCaptureSessionErrorKey]];
        });
    }];
    [self.observers addObject:runtimeErrorObserver];

    id didStartRunningObserver = [NSNotificationCenter.defaultCenter addObserverForName:AVCaptureSessionDidStartRunningNotification
                                                                 object:self.avCaptureSession
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification *note) {
        NSLog(@"did start running");
    }];
    [self.observers addObject:didStartRunningObserver];

    id didStopRunningObserver = [NSNotificationCenter.defaultCenter addObserverForName:AVCaptureSessionDidStopRunningNotification
                                                                object:self.avCaptureSession
                                                                 queue:[NSOperationQueue mainQueue]
                                                            usingBlock:^(NSNotification *note) {
        NSLog(@"did stop running");
    }];
    [self.observers addObject:didStopRunningObserver];
}

- (void)setupCaptureDeviceNotifications;
{
    id deviceWasConnectedObserver = [NSNotificationCenter.defaultCenter addObserverForName:AVCaptureDeviceWasConnectedNotification
                                                                    object:nil
                                                                     queue:[NSOperationQueue mainQueue]
                                                                usingBlock:^(NSNotification *note) {
        NSLog(@"AVCaptureDeviceWasConnectedNotification");
        [self refreshDevices];
    }];
    [self.observers addObject:deviceWasConnectedObserver];
    id deviceWasDisconnectedObserver = [NSNotificationCenter.defaultCenter addObserverForName:AVCaptureDeviceWasDisconnectedNotification
                                                                       object:nil
                                                                        queue:[NSOperationQueue mainQueue]
                                                                   usingBlock:^(NSNotification *note) {
        NSLog(@"AVCaptureDeviceWasDisconnectedNotification");
        [self refreshDevices];
    }];
    [self.observers addObject:deviceWasDisconnectedObserver];
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

        [self configureVideoDevice];
    });
}

- (void)configureVideoDevice;
{
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (videoDevice)
    {
        [self setSelectedVideoDevice:videoDevice];
    }
    else
    {
        [self setSelectedVideoDevice:nil];
    }
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
- (AVCapturePhotoSettings *)photoSettings;
{
    NSDictionary *format = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecTypeJPEG, AVVideoCodecKey, nil];
    AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:format];
    return photoSettings;
}

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
    {
        return;
    }

    [self flashScreen];

    [self.stillImageOutput capturePhotoWithSettings:self.photoSettings delegate:self];
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
- (AVCaptureDevice *)selectedVideoDevice
{
    return self.videoDeviceInput.device;
}

- (void)setSelectedVideoDevice:(AVCaptureDevice *)selectedVideoDevice
{
    [self.avCaptureSession beginConfiguration];

    if(self.videoDeviceInput) // Remove the old device input from the session
    {
        [self.avCaptureSession removeInput:self.videoDeviceInput];
        self.videoDeviceInput = nil;
    }

    if(selectedVideoDevice)
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
            {
                [self.avCaptureSession setSessionPreset:AVCaptureSessionPresetHigh];
            }
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
        return self.takingPicture == NO;
    }

    return YES;
}

#pragma mark - AVCapturePhotoCaptureDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error;
{
    self.snapshotData = photo.fileDataRepresentation;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        NSString *filename = [NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"jpg"];
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
        NSURL *url = [NSURL fileURLWithPath:path];
        if([self.snapshotData writeToURL:url atomically:NO])
        {
            NSLog(@"Did write photo to: %@", url.path);
        }
    });

}
@end
