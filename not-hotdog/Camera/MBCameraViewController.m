//
//  MBCameraViewController.m
//  not-hotdog
//
//  Created by Jura on 02/04/2018.
//  Copyright © 2018 MicroBlink. All rights reserved.
//

#import "MBCameraViewController.h"
#import "MBCameraView.h"
#import <AVFoundation/AVFoundation.h>

#import "MBClassifier.h"

@interface MBCameraViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet MBCameraView *cameraView;

@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic) dispatch_queue_t sessionQueue;

@property (nonatomic) dispatch_queue_t processingQueue;

@property (nonatomic) MBClassifier *classifier;

@end

@implementation MBCameraViewController

#pragma mark - View Controller livecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL);
    self.processingQueue = dispatch_queue_create( "processing queue", DISPATCH_QUEUE_SERIAL);

    self.classifier = [[MBClassifier alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self addNotificationObserver];
}

- (void)viewDidAppear:(BOOL)animate {
    [super viewDidAppear:animate];
    [self startCaptureSession];
};

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopCaptureSession];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self removeNotificationObserver];
}

/**
 * This changes the video orientation whenever the size ch
 */
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    // Note that the app delegate controls the device orientation notifications required to use the device orientation.
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsPortrait(deviceOrientation) || UIDeviceOrientationIsLandscape(deviceOrientation)) {
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.cameraView.layer;
        previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;

        switch (deviceOrientation) {
            case UIDeviceOrientationPortrait:
                self.classifier.orientation = UIImageOrientationRight;
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                self.classifier.orientation = UIImageOrientationLeft;
                break;
            case UIDeviceOrientationLandscapeLeft:
                self.classifier.orientation = UIImageOrientationUp;
                break;
            case UIDeviceOrientationLandscapeRight:
                self.classifier.orientation = UIImageOrientationDown;
                break;
            default:
                self.classifier.orientation = UIImageOrientationUp;
                break;
        }
    }
}

#pragma mark - Notification center control

- (void)addNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appplicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackgroundNotification:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)removeNotificationObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)appplicationWillEnterForeground:(NSNotification*)note {
    NSLog(@"appplicationWillEnterForeground!");
    [self startCaptureSession];
}

- (void)applicationDidEnterBackgroundNotification:(NSNotification*)note {
    NSLog(@"applicationDidEnterBackgroundNotification!");
    [self stopCaptureSession];
}

#pragma mark - UI elements handlers

- (IBAction)didTapClose:(id)sender {
    [self.delegate cameraViewControllerWillClose:self];
}

#pragma mark - Status bar appearance

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Class label appearance

- (void)setClassLabelHotDog:(BOOL)isHotDog {
    self.classLabel.backgroundColor = (!isHotDog) ? [UIColor whiteColor] : [UIColor colorWithRed:(CGFloat)0.22823 green:0.698 blue:0.909 alpha:1.0];
    self.classLabel.textColor = (!isHotDog) ? [UIColor colorWithRed:(CGFloat)0.22823 green:0.698 blue:0.909 alpha:1.0] : [UIColor whiteColor];
    if (isHotDog) self.classLabel.text = @"Hotdog!";
}

#pragma mark - Capture session control

- (void)startCaptureSession {

    dispatch_async(self.sessionQueue, ^{

        // Create session
        self.captureSession = [[AVCaptureSession alloc] init];
        self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;

        // Init the device inputs
        AVCaptureDeviceInput *videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraWithPosition:AVCaptureDevicePositionBack]
                                                                                  error:nil];
        [self.captureSession addInput:videoInput];

        // setup video data output
        AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        [videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        [videoDataOutput setSampleBufferDelegate:self queue:self.processingQueue];
        videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        [self.captureSession addOutput:videoDataOutput];

        // Setup the preview view.
        self.cameraView.session = self.captureSession;

        [self.captureSession startRunning];
    });
}

- (void)stopCaptureSession {
    dispatch_async(self.sessionQueue, ^{
        [self.captureSession stopRunning];
        self.captureSession = nil;
    });
}

// Find a camera with the specificed AVCaptureDevicePosition, returning nil if one is not found
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                                                                                                                            mediaType:AVMediaTypeVideo
                                                                                                                             position:position];
    NSArray *devices = [captureDeviceDiscoverySession devices];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
//    [self.classifier classify:sampleBuffer];

    [self.classifier classifyRequest:sampleBuffer callbackQueue:self.processingQueue handler:^(NSString *class) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.classLabel.text = class;
            bool isHotdog = [class containsString:@"hot dog"] || [class containsString:@"hotdog"];
            [self setClassLabelHotDog:isHotdog];
        });
    }];
}

#pragma mark - Instantiation from storyboard

+ (MBCameraViewController *)viewControllerFromStoryboard {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    MBCameraViewController *cameraViewController = (MBCameraViewController *)[storyboard instantiateViewControllerWithIdentifier:@"MBCameraViewController"];
    return cameraViewController;
}

@end
