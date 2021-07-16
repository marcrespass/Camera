//  Created by Marc Respass on 8/2/11.
//  Copyright 2011 ILIOS Inc. All rights reserved.
//

#import "CameraViewController.h"
#import "Camera-Swift.h"

#define MERLog(fmt, ...) NSLog(@"%s " fmt, __PRETTY_FUNCTION__, ##__VA_ARGS__)

// MER 2021-07-01 Taken from Apple's sample code
@implementation AVCaptureDeviceDiscoverySession (Utilities)

- (NSUInteger)uniqueDevicePositionsCount
{
    NSMutableArray<NSNumber* >* uniqueDevicePositions = [NSMutableArray array];

    for (AVCaptureDevice* device in self.devices) {
        if (![uniqueDevicePositions containsObject:@(device.position)]) {
            [uniqueDevicePositions addObject:@(device.position)];
        }
    }

    return uniqueDevicePositions.count;
}

@end

@interface CameraViewController ()
@property (nonatomic, readwrite, weak) IBOutlet NSView *cameraDisplayView;
@property (nonatomic, readwrite, weak) IBOutlet NSView *cameraControlView;
@property (nonatomic, readwrite, weak) IBOutlet NSButton *takePictureButton;
@property (nonatomic, readonly, assign) BOOL hasRecordingDevice;
@property (nonatomic, readwrite, assign) BOOL takingPicture;
@property (nonatomic, readwrite, strong) AVCaptureDeviceDiscoverySession* videoDeviceDiscoverySession;
@property (nonatomic, readwrite, strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, readwrite, strong) AVCapturePhotoOutput *capturePhotoOutput;
@property (nonatomic, readwrite, strong) AVCaptureSession *captureSession;
@property (nonatomic, readwrite, strong) CountdownViewController *countdownViewController;
@property (nonatomic, readwrite, strong) NSArray *observers;
@property (nonatomic, readwrite, strong) NSArray *videoDevices;
@property (nonatomic, readwrite, strong) dispatch_queue_t sessionQueue;

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
    NSNotificationCenter *notificationCenter = NSNotificationCenter.defaultCenter;

    for(id observer in _observers)
    {
        [notificationCenter removeObserver:observer];
    }
}

#pragma mark - Setup
- (void)setupCameraPreviewLayer;
{
    self.cameraDisplayView.layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);

    // Create the AVCaptureVideoPreviewLayer and add it as a sub layer of previewViewLayer which retains it
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    videoPreviewLayer.frame = self.cameraDisplayView.layer.bounds;
    videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.cameraDisplayView.layer addSublayer:videoPreviewLayer];

    videoPreviewLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    self.cameraDisplayView.layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
}

- (void)setupObservers;
{
    NSNotificationCenter *notificationCenter = NSNotificationCenter.defaultCenter;
    id runtimeErrorObserver = [notificationCenter addObserverForName:AVCaptureSessionRuntimeErrorNotification
                                                              object:self.captureSession
                                                               queue:[NSOperationQueue mainQueue]
                                                          usingBlock:^(NSNotification *note) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self presentError:[[note userInfo] objectForKey:AVCaptureSessionErrorKey]];
        });
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
    self.observers = [[NSArray alloc] initWithObjects:runtimeErrorObserver, deviceWasConnectedObserver, deviceWasDisconnectedObserver, nil];
}

- (void)setupAVCaptureSession;
{
    self.captureSession = [[AVCaptureSession alloc] init];

    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (videoDevice)
    {
        [self setSelectedVideoDevice:videoDevice];
    }
    else
    {
        [self setSelectedVideoDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeMuxed]];
    }

    AVCapturePhotoOutput *photoOutput = [[AVCapturePhotoOutput alloc] init];
    if ([self.captureSession canAddOutput:photoOutput]) {
        [self.captureSession addOutput:photoOutput];
        photoOutput.connections.firstObject.videoMirrored = YES;
        self.capturePhotoOutput = photoOutput;
    }
    self.capturePhotoOutput = photoOutput;

    [self setupObservers];
    [self setupCameraPreviewLayer];
    [self refreshDevices];
}

- (void)tearDownAVCaptureSession; // MER 2021-07-02 Never called
{
    [self.captureSession stopRunning];

    NSNotificationCenter *notificationCenter = NSNotificationCenter.defaultCenter;
    for(id observer in self.observers)
    {
        [notificationCenter removeObserver:observer];
    }
    self.observers = nil;

    self.captureSession = nil;
    self.captureDeviceInput = nil;
    self.videoDevices = nil;

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
- (void)refreshDevices
{
    MERLog();
//    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray<AVCaptureDeviceType>* deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeExternalUnknown];
        self.videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes
                                                                                                  mediaType:AVMediaTypeVideo
                                                                                                   position:AVCaptureDevicePositionUnspecified];

        self.videoDevices = self.videoDeviceDiscoverySession.devices;

        [self.captureSession beginConfiguration];

        if(self.videoDeviceDiscoverySession.uniqueDevicePositionsCount <= 0)
        {
            [self setSelectedVideoDevice:nil];
        }
        [self.captureSession commitConfiguration];

        [self.view.window makeFirstResponder:self.takePictureButton];
        [self.captureSession startRunning];
//    });
}

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
    if(!self.captureDeviceInput)
    {
        return;
    }

    self.takingPicture = YES;

    self.countdownViewController.view.frame = self.cameraControlView.frame;
    self.cameraControlView.hidden = YES;
    [self.view addSubview:self.countdownViewController.view positioned:NSWindowAbove relativeTo:nil];
    [self.view.window recalculateKeyViewLoop];

    [self.countdownViewController beginCountdown];
}

#pragma mark - Image Capture
- (void)captureAndSaveImage;
{
    [self flashScreen];

    AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettings];

    dispatch_async(self.sessionQueue, ^{
        MERLog(@"%@", self.capturePhotoOutput.connections);
        AVCaptureConnection *connection = self.capturePhotoOutput.connections.firstObject;
        connection.videoMirrored = NO;
        [self.capturePhotoOutput capturePhotoWithSettings:photoSettings delegate:self];
    });
}

#pragma  mark - AVCapturePhotoCaptureDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhoto:(AVCapturePhoto*)photo error:(nullable NSError*)error;
{
    MERLog();

    NSData *data = [photo fileDataRepresentation];
    // CGImageSource - left mirrored orientation
    if(data == nil)
    {
        NSError *dataError = [NSError errorWithDomain:@"Camera" code:2112 userInfo:@{NSLocalizedDescriptionKey : @"fileDataRepresentation is nil"}];
        [NSApp presentError:dataError];
    }
    self.takingPicture = NO;

    if(error != nil)
    {
        [NSApp presentError:error];
        return;
    }

    NSError *writeError = nil;
    NSString *filePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString] stringByAppendingPathExtension:@".jpg"];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    if([data writeToURL:url options:0 error:&writeError])
    {
        [NSWorkspace.sharedWorkspace openURL:url];
    }
}

#pragma mark - CountdownViewControllerDelegate
- (void)countdownDidEnd:(CountdownViewController *)countdown;
{
    [self captureAndSaveImage];
    [countdown.view removeFromSuperview];
    [self.view.window recalculateKeyViewLoop];

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
    return self.captureDeviceInput.device;
}

- (void)setSelectedVideoDevice:(AVCaptureDevice *)selectedVideoDevice
{
    [self.captureSession beginConfiguration];

    if(self.captureDeviceInput) // Remove the old device input from the session
    {
        [self.captureSession removeInput:self.captureDeviceInput];
        self.captureDeviceInput = nil;
    }

    if(selectedVideoDevice)
    {
        NSError *error = nil;
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:selectedVideoDevice error:&error];
        if(videoDeviceInput == nil)
        {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self presentError:error];
            });
        }
        else
        {
            if(![selectedVideoDevice supportsAVCaptureSessionPreset:self.captureSession.sessionPreset])
            {
                self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
            }
            [self.captureSession addInput:videoDeviceInput];
            self.captureDeviceInput = videoDeviceInput;

            for(AVCaptureConnection *connection in self.captureSession.connections)
            {
                connection.automaticallyAdjustsVideoMirroring = NO;
                if(connection.supportsVideoMirroring)
                {
                    connection.videoMirrored = YES;
                }
            }
        }
    }

    [self.captureSession commitConfiguration];
}

#pragma mark - NSUserInterfaceValidations
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;
{
    if([anItem action] == @selector(captureImage:))
    {
        return (self.hasRecordingDevice && !self.takingPicture);
    }

    return YES;
}

@end
