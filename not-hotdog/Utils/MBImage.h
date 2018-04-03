//
//  MBImage.h
//  not-hotdog
//
//  Created by Jura on 03/04/2018.
//  Copyright © 2018 MicroBlink. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

@interface MBImage : NSObject

- (instancetype)initWithCMSampleBuffer:(CMSampleBufferRef)sampleBuffer orientation:(UIImageOrientation)orientation;

- (UIImage *)image;

@end
