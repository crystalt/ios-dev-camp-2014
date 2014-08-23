//
//  ViewController.m
//  Test
//
//  Created by Will Chen on 8/23/14.
//  Copyright (c) 2014 TapSense. All rights reserved.
//

#import "PicturePicker.h"
#import <FacebookSDK/FacebookSDK.h>
#import "CropViewController.h"

@implementation FBFriendPickerViewController (TSFBFriendPickerViewController)

- (BOOL)prefersStatusBarHidden
{
    return YES;
}


@end

@interface PicturePicker () <FBFriendPickerDelegate, CropViewControllerDelegate>

@property (nonatomic, strong) FBFriendPickerViewController *friendPickerController;
@property (nonatomic, strong) CropViewController *cropViewController;

@end


@implementation PicturePicker


- (void) showFriendPicker {
    if (self.friendPickerController == nil) {
        // Create friend picker, and get data loaded into it.
        self.friendPickerController = [[FBFriendPickerViewController alloc] init];
        self.friendPickerController.title = @"Pick Friends";
        self.friendPickerController.delegate = self;
    }
    
    [self.friendPickerController loadData];
    [self.friendPickerController clearSelection];
    
    [self.rootViewController presentViewController:self.friendPickerController animated:YES completion:nil];
}

- (void)facebookViewControllerDoneWasPressed:(id)sender {
    NSArray *myFriends = self.friendPickerController.selection;
    
    if (myFriends.count != 1){
        [self.rootViewController presentViewController:self.friendPickerController animated:YES completion:nil];
        return;
    }
    
    NSDictionary *dict = [myFriends objectAtIndex:0];
    NSDictionary *data = [[dict objectForKey:@"picture"] objectForKey:@"data"];
    NSString *urlString = [data objectForKey:@"url"];
    NSString *idString = [dict objectForKey:@"id"] ;
    urlString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&width=1000&height=1000", idString];
    self.cropViewController = [[CropViewController alloc] initWithUrl:[NSURL URLWithString:urlString]];
    self.cropViewController.delegate = self;
    [self.friendPickerController presentViewController:self.cropViewController animated:YES completion:nil];
    return;
}

- (void) cropViewControllerDidFinish:(CropViewController *)cropViewController withImage:(UIImage *)image
{
    [self.delegate picturePickerFinisheed:self withImage:image];
    [self.rootViewController dismissViewControllerAnimated:NO completion:nil];
}

@end