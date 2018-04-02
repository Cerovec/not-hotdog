//
//  MBCameraView.m
//  not-hotdog
//
//  Created by Jura on 02/04/2018.
//  Copyright © 2018 MicroBlink. All rights reserved.
//

#import "MBCameraView.h"

@implementation MBCameraView

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session {
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    return previewLayer.session;
    return nil;
}

- (void)setSession:(AVCaptureSession *)session {
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.session = session;
}

@end
