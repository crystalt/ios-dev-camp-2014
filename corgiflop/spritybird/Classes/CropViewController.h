//
//  ViewController.h
//  Test
//
//  Created by Will Chen on 8/23/14.
//  Copyright (c) 2014 TapSense. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CropViewController;

@protocol CropViewControllerDelegate <NSObject>
@optional

- (void) cropViewControllerDidFinish:(CropViewController *) cropViewController withImage:(UIImage *) image;

@end

@interface CropViewController : UIViewController

- (id) initWithUrl: (NSURL *) url;

@property (nonatomic, weak) id<CropViewControllerDelegate> delegate;

@end

