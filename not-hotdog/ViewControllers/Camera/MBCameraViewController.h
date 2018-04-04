//
//  MBCameraViewController.h
//  not-hotdog
//
//  Created by Jura on 02/04/2018.
//  Copyright © 2018 MicroBlink. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MBCameraViewControllerDelegate;


@interface MBCameraViewController : UIViewController

@property (nonatomic, weak) id<MBCameraViewControllerDelegate> delegate;

+ (MBCameraViewController *)viewControllerFromStoryboard;

@end


@protocol MBCameraViewControllerDelegate <NSObject>

- (void)cameraViewControllerWillClose:(MBCameraViewController *)viewController;

@end
