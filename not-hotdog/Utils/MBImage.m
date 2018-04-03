//
//  MBImage.m
//  not-hotdog
//
//  Created by Jura on 03/04/2018.
//  Copyright © 2018 MicroBlink. All rights reserved.
//

#import "MBImage.h"

@interface MBImage()

@property (nonatomic, assign) CGImageRef imageRef;
@property (nonatomic, assign) CGColorSpaceRef colorSpace;
@property (nonatomic, assign) CGContextRef newContext;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic) UIImageOrientation orientation;

@end

@implementation MBImage

- (instancetype)initWithCMSampleBuffer:(CMSampleBufferRef)sampleBuffer orientation:(UIImageOrientation)orientation {
    self = [super init];
    if (self) {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer, 0); // Lock the image buffer

        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0); // Get information of the image
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);

        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace,
                                                        kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        _imageRef = CGBitmapContextCreateImage(newContext);
        CGContextRelease(newContext);

        CGColorSpaceRelease(colorSpace);
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

        _orientation = orientation;
    }
    return self;
}

- (UIImage *)image {
    if (_image == nil) {
        _image = [UIImage imageWithCGImage:_imageRef scale:1.0 orientation:self.orientation];
    }
    return _image;
}

- (void)dealloc {
    CGImageRelease(_imageRef);
}

@end
