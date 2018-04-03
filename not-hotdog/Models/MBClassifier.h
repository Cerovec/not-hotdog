//
//  MBClassifier.h
//  not-hotdog
//
//  Created by Jura on 03/04/2018.
//  Copyright © 2018 MicroBlink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface MBClassifier : NSObject

@property (nonatomic) UIImageOrientation orientation;

- (void)classify:(CMSampleBufferRef)sampleBuffer;

- (void)classifyRequest:(CMSampleBufferRef)sampleBuffer callbackQueue:(dispatch_queue_t)queue handler:(void(^)(NSString*))handler;

@end
