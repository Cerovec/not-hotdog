//
//  MBClassifier.m
//  not-hotdog
//
//  Created by Jura on 03/04/2018.
//  Copyright © 2018 MicroBlink. All rights reserved.
//

#import "MBClassifier.h"

#import "Inceptionv3.h"

#import <CoreML/CoreML.h>
#import <Vision/Vision.h>

#import "UIImage+MBResize.h"
#import "MBImage.h"

@interface MBClassifier ()

@property (nonatomic) Inceptionv3* inception;

@property (nonatomic) VNCoreMLModel *vnModel;

@property (nonatomic) BOOL processing;

@end

@implementation MBClassifier

- (instancetype)init {
    self = [super init];
    if (self) {
        _inception = [[Inceptionv3 alloc] init];
        _processing = NO;
        _vnModel = [VNCoreMLModel modelForMLModel:_inception.model error:nil];
        _orientation = UIImageOrientationRight;
    }
    return self;
}

- (void)classify:(CMSampleBufferRef)sampleBuffer {
    if (self.processing) {
        return;
    }
    self.processing = YES;

    MBImage *mbimage = [[MBImage alloc] initWithCMSampleBuffer:sampleBuffer orientation:self.orientation];
    UIImage *resizedImage = [[mbimage image] resizedImage:CGSizeMake(299, 299) interpolationQuality:kCGInterpolationLow];

    CVPixelBufferRef pixelRef = [resizedImage pixelBuffer];

    Inceptionv3Output *output = [self.inception predictionFromImage:pixelRef error:nil];
    NSLog(@"Class %@", output.classLabel);

    CVPixelBufferRelease(pixelRef);
}

- (void)classifyRequest:(CMSampleBufferRef)sampleBuffer callbackQueue:(dispatch_queue_t)queue handler:(void(^)(NSString*))handler {

    if (self.processing) {
        return;
    }
    self.processing = YES;
    
    MBImage *mbimage = [[MBImage alloc] initWithCMSampleBuffer:sampleBuffer orientation:self.orientation];
    UIImage *resizedImage = [[mbimage image] resizedImage:CGSizeMake(299, 299) interpolationQuality:kCGInterpolationLow];

    VNCoreMLRequest *request = [[VNCoreMLRequest alloc] initWithModel:self.vnModel completionHandler:(VNRequestCompletionHandler)^(VNRequest *request, NSError *error){
        dispatch_async(queue, ^{
            VNClassificationObservation *topResult = ((VNClassificationObservation *)(request.results[0]));
            handler(topResult.identifier);
            NSLog(@"%@", [topResult identifier]);

            self.processing = NO;
        });
    }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:resizedImage.CGImage options:@{}];
        [handler performRequests:@[request] error:nil];
    });
}

@end
