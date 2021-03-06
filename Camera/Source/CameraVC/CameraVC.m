//  Created by Marc Respass on 8/2/11.
//  Copyright 2011 ILIOS Inc. All rights reserved.
//

#import "CameraVC.h"
#import "NSAlert+ILIOSAdditions.h"
#import "Camera-Swift.h"

#ifdef DEBUG
#define MERLogDebug(fmt, ...) NSLog(@"%s " fmt, __PRETTY_FUNCTION__, ##__VA_ARGS__)
#else
#define MERLogDebug(...)
#endif

@interface CameraVC ()

@property (nonatomic, readwrite, weak) IBOutlet NSView *cameraDisplayView;
@property (nonatomic, readwrite, weak) IBOutlet NSButton *takePictureButton;
@property (nonatomic, readwrite, weak) IBOutlet NSButton *preferencesButton;
@property (nonatomic, readonly, assign) BOOL hasRecordingDevice;
@property (nonatomic, readwrite, assign) BOOL takingPicture;
@property (nonatomic, readwrite, assign) BOOL videoConfigured; // Cocoa Binding
@property (nonatomic, readwrite, strong) AVCaptureDeviceDiscoverySession* videoDeviceDiscoverySession;
@property (nonatomic, readwrite, strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, readwrite, strong) AVCapturePhotoOutput *capturePhotoOutput;
@property (nonatomic, readwrite, strong) AVCaptureSession *captureSession;
@property (nonatomic, readwrite, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, readwrite, strong) CountdownViewController *countdownViewController;
@property (nonatomic, readwrite, strong) NSPopover *popover;
@property (nonatomic, readwrite, strong) NSArray *observers;
@property (nonatomic, readwrite, strong) NSArray *videoDevices;
@property (nonatomic, readwrite, strong) NSWindow *flashWindow;
@property (nonatomic, readwrite, strong) dispatch_queue_t sessionQueue;

@end

@implementation CameraVC

#pragma mark - KVC/KVO
+ (NSSet *)keyPathsForValuesAffectingHasRecordingDevice
{
    return [NSSet setWithObjects:@"selectedVideoDevice", nil];
}

#pragma mark - init
- (instancetype)initWithCaptureDeviceDiscoverySession:(AVCaptureDeviceDiscoverySession *)session;
{
    if(self = [super initWithNibName:nil bundle:nil])
    {
        // Communicate with the session and other session objects on this queue.
        _sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
        _videoDeviceDiscoverySession = session;
        return self;
    }

    return nil;
}

- (instancetype)initWithNibName:(nullable NSNibName)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
{
    return nil;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
{
    return nil;
}

- (NSString *)nibName;
{
    return @"CameraVC";
}

- (void)dealloc;
{
    MERLogDebug();
    NSNotificationCenter *notificationCenter = NSNotificationCenter.defaultCenter;

    for(id observer in _observers)
    {
        [notificationCenter removeObserver:observer];
    }
}

#pragma mark - Setup
- (void)initialSetup;
{
    self.captureSession = [[AVCaptureSession alloc] init];
    [self refreshDevices];
    [self setupCameraPreviewLayer];

    [self setSelectedVideoDevice:self.videoDevices.firstObject];

    AVCapturePhotoOutput *photoOutput = [[AVCapturePhotoOutput alloc] init];
    if ([self.captureSession canAddOutput:photoOutput]) {
        [self.captureSession addOutput:photoOutput];
        self.capturePhotoOutput = photoOutput;
    }
    self.capturePhotoOutput = photoOutput;

    //     MER 2021-07-16 self.capturePhotoOutput will now have one connection
    //     find that connection and set videoMirrored = YES
    //      2021-07-25 AVCapturePhotoOutput cannot mirror its connection on M1 so rotate the image manually
    //        for(AVCaptureConnection *connection in self.capturePhotoOutput.connections) {
    //            if (connection.output == photoOutput) {
    //                connection.automaticallyAdjustsVideoMirroring = NO;
    //                if(connection.supportsVideoMirroring) {
    //                    connection.videoMirrored = YES;
    //                }
    //            }
    //        }
    [self setupObservers];
    self.videoConfigured = YES;
}

- (void)setupCameraPreviewLayer;
{
    self.cameraDisplayView.layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);

    // Create the AVCaptureVideoPreviewLayer and add it as a sub layer of previewViewLayer which retains it
    AVCaptureVideoPreviewLayer *vpLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    vpLayer.frame = self.cameraDisplayView.layer.bounds;
    vpLayer.videoGravity = AVLayerVideoGravityResizeAspect;

    [self configureVideoMirrored:vpLayer];

    [self.cameraDisplayView.layer addSublayer:vpLayer];
    vpLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    self.cameraDisplayView.layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    self.videoPreviewLayer = vpLayer;
}

- (void)viewDidLoad;
{
    [super viewDidLoad];
    ((DraggingView *)self.view).delegate = self;
    
    self.cameraDisplayView.wantsLayer = YES;
    self.countdownViewController = [[CountdownViewController alloc] init];
    self.countdownViewController.delegate = self;

    [self _setupFlashWindow];

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self initialSetup];
    });
}

- (void)_setupFlashWindow;
{
    self.flashWindow = [[NSWindow alloc] initWithContentRect:NSScreen.mainScreen.frame
                                                   styleMask:NSWindowStyleMaskBorderless
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO
                                                      screen:NSScreen.mainScreen];
    self.flashWindow.level = CGShieldingWindowLevel();
    self.flashWindow.backgroundColor = NSColor.whiteColor;
}

- (void)setupObservers;
{
    NSNotificationCenter *notificationCenter = NSNotificationCenter.defaultCenter;
    id runtimeErrorObserver = [notificationCenter addObserverForName:AVCaptureSessionRuntimeErrorNotification
                                                              object:self.captureSession
                                                               queue:[NSOperationQueue mainQueue]
                                                          usingBlock:^(NSNotification *note) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self presentError:note.userInfo[AVCaptureSessionErrorKey]];
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
    self.observers = @[runtimeErrorObserver, deviceWasConnectedObserver, deviceWasDisconnectedObserver];

    [notificationCenter addObserver:self selector:@selector(toggleMirrorPreview:) name:NSUserDefaultsDidChangeNotification object:NSUserDefaults.standardUserDefaults];
}

#pragma mark - Device selection
- (void)refreshDevices
{
    MERLogDebug();
    self.videoDevices = self.videoDeviceDiscoverySession.devices;

    [self.captureSession beginConfiguration];

    if(self.videoDeviceDiscoverySession.devices.count <= 0)
    {
        [self setSelectedVideoDevice:nil];
    }
    [self.captureSession commitConfiguration];

    [self.view.window makeFirstResponder:self.takePictureButton];
    [self.captureSession startRunning];
}

#pragma mark - Camera Helpers
- (void)flashScreen;
{
    if(![self shouldFlashScreen])
    {
        return;
    }
    self.flashWindow.alphaValue = 1.0;
    [self.flashWindow makeKeyAndOrderFront:nil];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.2;
        self.flashWindow.animator.alphaValue = 0.0;
    } completionHandler:^{
        [self.flashWindow orderOut:nil];
    }];
}

#pragma mark - Actions
- (IBAction)showPreferences:(NSButton *)sender;
{
    sender.enabled = NO;
    self.popover = [[NSPopover alloc] init];
    self.popover.contentViewController = [[PreferencesVC alloc] init];
    self.popover.behavior = NSPopoverBehaviorTransient;
    self.popover.delegate = self;
    [self.popover showRelativeToRect:sender.frame ofView:sender preferredEdge:NSRectEdgeMinX];
//    You can do this instead but then PreferencesVC is the delegate of the popover
//    So then self needs to be the delegate of PreferencesVC which would forward NSPopoverDelegate methods
//    PreferencesVC *pvc = [[PreferencesVC alloc] init];
//    [self presentViewController:pvc asPopoverRelativeToRect:sender.frame ofView:sender preferredEdge:NSRectEdgeMinY behavior:NSPopoverBehaviorTransient];
}

- (IBAction)openImage:(id)sender;
{
    NSOpenPanel *openPanel = NSOpenPanel.openPanel;

    openPanel.canChooseFiles = YES;
    openPanel.allowsMultipleSelection = YES;
    openPanel.canChooseDirectories = NO;
    openPanel.allowedContentTypes = @[
        [UTType typeWithIdentifier:@"public.image"]
    ];

    [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
        if(result == NSModalResponseOK)
        {
            for(NSURL *imageURL in openPanel.URLs)
            {
                [self.ocrDelegate displayRecognizedTextAtURL:imageURL];
            }
        }
    }];
}

- (IBAction)captureImage:(id)sender;
{
    if(!self.captureDeviceInput)
    {
        return;
    }

    [self.popover performClose:sender];
    
    self.takingPicture = YES;

    BOOL useCountdown = [self shouldUseCountdown];
    if(useCountdown)
    {
        [self.view.window resignFirstResponder];

        self.countdownViewController.view.alphaValue = 0;
        NSRect frame = self.countdownViewController.view.frame;
        frame.origin.y = 8.0;
        frame.origin.x = 20.0;
        frame.size.width = self.cameraDisplayView.frame.size.width;
        self.countdownViewController.view.frame = frame;
        [self.view addSubview:self.countdownViewController.view positioned:NSWindowAbove relativeTo:nil];
        [self.view.window recalculateKeyViewLoop];

        [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
            self.countdownViewController.view.alphaValue = 1.0;
        } completionHandler:^{
            [self.countdownViewController beginCountdown];
        }];
    }
    else
    {
        [self captureAndSaveImage];
    }
}

#pragma mark - Image Capture
- (void)captureAndSaveImage;
{
    [self flashScreen];
    dispatch_async(self.sessionQueue, ^{
        [self.capturePhotoOutput capturePhotoWithSettings:[AVCapturePhotoSettings photoSettings] delegate:self];
    });
}

#pragma  mark - AVCapturePhotoCaptureDelegate
- (void)saveDataToImage:(NSData *)photoData {
    BOOL mirror = [self mirrorSavedImage];
    NSImage *image = [photoData nsImageMirroring:mirror];

    NSString *filePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString] stringByAppendingPathExtension:@"jpg"];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    NSError *writeError = nil;
    if([image.TIFFRepresentation writeToURL:url options:0 error:&writeError])
    {
        [self handlePostImageOperationAt:url];
    }
    if(writeError != nil)
    {
        [NSApp presentError:writeError];
    }
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhoto:(AVCapturePhoto*)photo error:(nullable NSError*)error;
{
    MERLogDebug();
    self.takingPicture = NO;

    if(error != nil)
    {
        [NSApp presentError:error];
        return;
    }

    NSData *photoData = [photo fileDataRepresentation];
    if(photoData == nil)
    {
        NSError *dataError = [[NSError alloc] initWith:@"fileDataRepresentation is nil"];
        [NSApp presentError:dataError];
        return;
    }

    [self saveDataToImage:photoData];
    BOOL ocr = [self recognizeText];
    if(ocr)
    {
        NSImage *image = [[NSImage alloc] initWithData:photoData];
        [self.ocrDelegate displayRecognizedText:image];
    }
}

#pragma mark - CountdownViewControllerDelegate
- (void)countdownDidEnd:(CountdownViewController *)countdown;
{
    [self captureAndSaveImage];
    [countdown.view removeFromSuperview];
    [self.view.window recalculateKeyViewLoop];
}

- (void)countdownWasCanceled:(CountdownViewController *)countdown;
{
    self.takingPicture = NO;
    [self.view.window makeFirstResponder:self.view];
}

#pragma mark - NSPopoverDelegate
- (void)popoverDidClose:(NSNotification *)notification;
{
    self.preferencesButton.enabled = YES;
    self.popover = nil;
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
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:selectedVideoDevice
                                                                                       error:&error];
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
            BOOL mirrored = [self mirrorPreview];
            self.videoPreviewLayer.connection.automaticallyAdjustsVideoMirroring = NO;
            self.videoPreviewLayer.connection.videoMirrored = mirrored;
            self.captureDeviceInput = videoDeviceInput;
        }
    }

    [self.captureSession commitConfiguration];
}

#pragma mark - NSUserInterfaceValidations
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;
{
    if(anItem.action == @selector(captureImage:))
    {
        return (self.hasRecordingDevice && !self.takingPicture);
    }

    return YES;
}

@end
