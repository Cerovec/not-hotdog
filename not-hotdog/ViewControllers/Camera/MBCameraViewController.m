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

@property (weak, nonatomic) IBOutlet UILabel *classLabel;

@property (weak, nonatomic) IBOutlet MBCameraView *cameraView;

@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic) dispatch_queue_t sessionQueue;

@property (nonatomic) dispatch_queue_t processingQueue;

@property (nonatomic) MBClassifier *classifier;

- (IBAction)didTapClose:(id)sender;

@end

@implementation MBCameraViewController

#pragma mark - View Controller lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    self.processingQueue = dispatch_queue_create("processing queue", DISPATCH_QUEUE_SERIAL);

    self.classifier = [[MBClassifier alloc] init];

    self.classLabel.hidden = YES;
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
        [self.classifier updateWithDeviceOrientation:deviceOrientation];
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

        [self.captureSession startRunning];

        dispatch_async(dispatch_get_main_queue(), ^{
            // Setup the preview view.
            self.cameraView.session = self.captureSession;
        });
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

#pragma mark - Instantiation from storyboard

+ (MBCameraViewController *)viewControllerFromStoryboard {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    MBCameraViewController *cameraViewController = (MBCameraViewController *)[storyboard instantiateViewControllerWithIdentifier:@"MBCameraViewController"];
    return cameraViewController;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

    [self.classifier classifyRequest:sampleBuffer callbackQueue:self.processingQueue handler:^(NSString *class) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateClassLabelForClassString:class];
        });
    }];
}

#pragma mark - Class label appearance

- (void)updateClassLabelForClassString:(NSString *)classString {

    bool isHotdog = [classString containsString:@"hot dog"] || [classString containsString:@"hotdog"];

    NSUInteger location = [classString rangeOfString:@","].location;
    NSString *class = location == NSNotFound ? classString : [classString substringToIndex:location];

    UIColor *mbBlueColor = [UIColor colorWithRed:(CGFloat)0.228f green:0.698f blue:0.909f alpha:1.0f];

    self.classLabel.backgroundColor = isHotdog ? mbBlueColor: [UIColor whiteColor];
    self.classLabel.textColor = isHotdog ? [UIColor whiteColor] : mbBlueColor;
    self.classLabel.text = isHotdog ? @"Hotdog!" : class;

    self.classLabel.hidden = NO;
}

@end
