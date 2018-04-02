//
//  ViewController.m
//  not-hotdog
//
//  Created by Jura on 02/04/2018.
//  Copyright © 2018 MicroBlink. All rights reserved.
//

#import "MBRootViewController.h"

#import "MBCameraViewController.h"

@interface MBRootViewController () <MBCameraViewControllerDelegate>

@end

@implementation MBRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didTapStart:(id)sender {
    MBCameraViewController *cameraViewController = [MBCameraViewController viewControllerFromStoryboard];
    cameraViewController.delegate = self;
    [self presentViewController:cameraViewController animated:YES completion:nil];
}

#pragma mark - MBCameraViewControllerDelegate

- (void)cameraViewControllerWillClose:(MBCameraViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
