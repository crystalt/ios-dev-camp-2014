//
//  ViewController.h
//  Test
//
//  Created by Will Chen on 8/23/14.
//  Copyright (c) 2014 TapSense. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PicturePicker;

@protocol PicturePickerDelegate <NSObject>
@optional

- (void) picturePickerFinisheed:(PicturePicker *) picturePicker withImage:(UIImage *) image;

@end

@interface PicturePicker : NSObject

@property (nonatomic, strong) UIViewController *rootViewController;
@property (nonatomic, weak) id<PicturePickerDelegate> delegate;

- (void) showFriendPicker;

@end

