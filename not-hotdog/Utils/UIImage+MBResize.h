//
//  UIImage+MBResize.h
//  not-hotdog
//
//  Created by Jura on 03/04/2018.
//  Copyright © 2018 MicroBlink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (MBResize)

- (UIImage *)croppedImage:(CGRect)bounds;

- (UIImage *)resizedImage:(CGSize)newSize
     interpolationQuality:(CGInterpolationQuality)quality;

- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                  bounds:(CGSize)bounds
                    interpolationQuality:(CGInterpolationQuality)quality;

- (UIImage *)mb_resizedImage:(CGSize)newSize
                   transform:(CGAffineTransform)transform
              drawTransposed:(BOOL)transpose
        interpolationQuality:(CGInterpolationQuality)quality;

- (CGAffineTransform)mb_transformForOrientation:(CGSize)newSize;

- (CVPixelBufferRef)pixelBuffer;

@end
