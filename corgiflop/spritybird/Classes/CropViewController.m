//
//  ViewController.m
//  Test
//
//  Created by Will Chen on 8/23/14.
//  Copyright (c) 2014 TapSense. All rights reserved.
//

#import "CropViewController.h"

@interface CropViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) NSURL *url;

@property (nonatomic) CGFloat circleRadius;
@property (nonatomic) CGPoint circleCenter;

@property (nonatomic, weak) CAShapeLayer *maskLayer;
@property (nonatomic, weak) CAShapeLayer *circleLayer;

@property (nonatomic, weak) UIPinchGestureRecognizer *pinch;
@property (nonatomic, weak) UIPanGestureRecognizer   *pan;

@property (nonatomic, strong) UIImage *croppedImage;

@end


@implementation CropViewController

- (id) initWithUrl: (NSURL *) url{
    self = [super init];
    if (self) {
        self.url = url;
        self.view.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // create layer mask for the image
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    self.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.url]];
    [self.view addSubview:self.imageView];
    
    self.doneButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.doneButton setTitle:@"Use" forState:UIControlStateNormal
     ];
    self.doneButton.frame = CGRectMake(0, 0, 50, 50);
    [self.doneButton addTarget:self action:@selector(doneButtonClicked)  forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.doneButton];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    self.imageView.layer.mask = maskLayer;
    self.maskLayer = maskLayer;
    
    // create shape layer for circle we'll draw on top of image (the boundary of the circle)
    
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    circleLayer.lineWidth = 3.0;
    circleLayer.fillColor = [[UIColor clearColor] CGColor];
    circleLayer.strokeColor = [[UIColor blackColor] CGColor];
    [self.imageView.layer addSublayer:circleLayer];
    self.circleLayer = circleLayer;
    
    // create circle path
    
    [self updateCirclePathAtLocation:CGPointMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0) radius:self.view.bounds.size.width * 0.50];
    
    // create pan gesture
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    pan.delegate = self;
    [self.imageView addGestureRecognizer:pan];
    self.imageView.userInteractionEnabled = YES;
    self.pan = pan;
    
    // create pan gesture
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    pinch.delegate = self;
    [self.view addGestureRecognizer:pinch];
    self.pinch = pinch;
}

- (void)doneButtonClicked
{
    [self cropImage];
        [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateCirclePathAtLocation:(CGPoint)location radius:(CGFloat)radius
{
    self.circleCenter = location;
    self.circleRadius = radius;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:self.circleCenter
                    radius:self.circleRadius
                startAngle:0.0
                  endAngle:M_PI * 2.0
                 clockwise:YES];
    
    self.maskLayer.path = [path CGPath];
    self.circleLayer.path = [path CGPath];
}

- (void)cropImage
{
    CGFloat scale  = [[self.imageView.window screen] scale];
    CGFloat radius = self.circleRadius * scale;
    CGPoint center = CGPointMake(self.circleCenter.x * scale, self.circleCenter.y * scale);
    
    CGRect frame = CGRectMake(center.x - radius,
                              center.y - radius,
                              radius * 2.0,
                              radius * 2.0);
    
    // temporarily remove the circleLayer
    
    CALayer *circleLayer = self.circleLayer;
    [self.circleLayer removeFromSuperlayer];
    
    // render the clipped image
    
    UIGraphicsBeginImageContextWithOptions(self.imageView.frame.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if ([self.imageView respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)])
    {
        // if iOS 7, just draw it
        
        [self.imageView drawViewHierarchyInRect:self.imageView.bounds afterScreenUpdates:YES];
    }
    else
    {
        // if pre iOS 7, manually clip it
        
        CGContextAddArc(context, self.circleCenter.x, self.circleCenter.y, self.circleRadius, 0, M_PI * 2.0, YES);
        CGContextClip(context);
        [self.imageView.layer renderInContext:context];
    }
    
    // capture the image and close the context
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // add the circleLayer back
    
    [self.imageView.layer addSublayer:circleLayer];
    
    // crop the image
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], frame);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    if ([self.delegate respondsToSelector:@selector(cropViewControllerDidFinish:withImage:)]){
        [self.delegate cropViewControllerDidFinish:self withImage:croppedImage];
    }

    //    // save the image
//    
//    NSData *data = UIImagePNGRepresentation(croppedImage);
//    [data writeToFile:path atomically:YES];
//    
//    // tell the user we're done
//    
//    [[[UIAlertView alloc] initWithTitle:nil message:@"Saved" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
}

#pragma mark - Gesture recognizers

- (void)handlePan:(UIPanGestureRecognizer *)gesture
{
    static CGPoint oldCenter;
    CGPoint tranlation = [gesture translationInView:gesture.view];
    
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        oldCenter = self.circleCenter;
    }
    
    CGPoint newCenter = CGPointMake(oldCenter.x + tranlation.x, oldCenter.y + tranlation.y);
    
    [self updateCirclePathAtLocation:newCenter radius:self.circleRadius];
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gesture
{
    static CGFloat oldRadius;
    CGFloat scale = [gesture scale];
    
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        oldRadius = self.circleRadius;
    }
    
    CGFloat newRadius = oldRadius * scale;
    
    [self updateCirclePathAtLocation:self.circleCenter radius:newRadius];
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ((gestureRecognizer == self.pan   && otherGestureRecognizer == self.pinch) ||
        (gestureRecognizer == self.pinch && otherGestureRecognizer == self.pan))
    {
        return YES;
    }
    
    return NO;
}

@end