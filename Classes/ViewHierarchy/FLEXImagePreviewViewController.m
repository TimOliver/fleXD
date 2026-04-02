//
//  FLEXImagePreviewViewController.m
//
//  Copyright (c) Flipboard (2014-2016); FLEX Team (2020-2026).
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice, this
//    list of conditions and the following disclaimer in the documentation and/or
//    other materials provided with the distribution.
//
//  * Neither the name of Flipboard nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
//  * You must NOT include this project in an application to be submitted
//    to the App Store™, as this project uses too many private APIs.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "FLEXImagePreviewViewController.h"
#import "FLEXActivityViewController.h"
#import "FLEXUtility.h"
#import "FLEXColor.h"
#import "FLEXResources.h"

@interface FLEXImagePreviewViewController () <UIScrollViewDelegate>
@property (nonatomic) UIImage *image;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UITapGestureRecognizer *bgColorTapGesture;
@property (nonatomic) NSInteger backgroundColorIndex;
@property (nonatomic, readonly) NSArray<UIColor *> *backgroundColors;
@end

#pragma mark -
@implementation FLEXImagePreviewViewController

#pragma mark Initialization

+ (instancetype)previewForView:(UIView *)view {
    return [self forImage:[FLEXUtility previewImageForView:view]];
}

+ (instancetype)previewForLayer:(CALayer *)layer {
    return [self forImage:[FLEXUtility previewImageForLayer:layer]];
}

+ (instancetype)forImage:(UIImage *)image {
    return [[self alloc] initWithImage:image];
}

- (id)initWithImage:(UIImage *)image {
    NSParameterAssert(image);

    self = [super init];
    if (self) {
        self.title = @"Preview";
        self.image = image;
        _backgroundColors = @[FLEXResources.checkerPatternColor, UIColor.whiteColor, UIColor.blackColor];
    }

    return self;
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:flag completion:completion];
}


#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.imageView = [[UIImageView alloc] initWithImage:self.image];
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = self.backgroundColors.firstObject;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.scrollView addSubview:self.imageView];
    self.scrollView.contentSize = self.imageView.frame.size;
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 2.0;
    [self.view addSubview:self.scrollView];

    self.bgColorTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeBackground)];
    [self.scrollView addGestureRecognizer:self.bgColorTapGesture];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAction
        target:self
        action:@selector(actionButtonPressed:)
    ];
}

- (void)viewDidLayoutSubviews {
    [self centerContentInScrollViewIfNeeded];
}


#pragma mark UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self centerContentInScrollViewIfNeeded];
}


#pragma mark Private

- (void)centerContentInScrollViewIfNeeded {
    CGFloat horizontalInset = 0.0;
    CGFloat verticalInset = 0.0;
    if (self.scrollView.contentSize.width < self.scrollView.bounds.size.width) {
        horizontalInset = (self.scrollView.bounds.size.width - self.scrollView.contentSize.width) / 2.0;
    }
    if (self.scrollView.contentSize.height < self.scrollView.bounds.size.height) {
        verticalInset = (self.scrollView.bounds.size.height - self.scrollView.contentSize.height) / 2.0;
    }
    self.scrollView.contentInset = UIEdgeInsetsMake(verticalInset, horizontalInset, verticalInset, horizontalInset);
}

- (void)changeBackground {
    self.backgroundColorIndex++;
    self.backgroundColorIndex %= self.backgroundColors.count;
    self.scrollView.backgroundColor = self.backgroundColors[self.backgroundColorIndex];
}

- (void)actionButtonPressed:(id)sender {
    static BOOL canSaveToCameraRoll = NO, didShowWarning = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (UIDevice.currentDevice.systemVersion.floatValue < 10) {
            canSaveToCameraRoll = YES;
            return;
        }

        NSBundle *mainBundle = NSBundle.mainBundle;
        if ([mainBundle.infoDictionary.allKeys containsObject:@"NSPhotoLibraryUsageDescription"]) {
            canSaveToCameraRoll = YES;
        }
    });

    UIViewController *activityVC = [FLEXActivityViewController sharing:@[self.image] source:sender];

    if (!canSaveToCameraRoll && !didShowWarning) {
        didShowWarning = YES;
        NSString * const msg = @"Add 'NSPhotoLibraryUsageDescription' to this app's Info.plist to save images.";
        [FLEXAlert makeAlert:^(FLEXAlert *make) {
            make.title(@"Reminder").message(msg);
            make.button(@"OK").handler(^(NSArray<NSString *> *strings) {
                [self presentViewController:activityVC animated:YES completion:nil];
            });
        } showFrom:self];
    } else {
        [self presentViewController:activityVC animated:YES completion:nil];
    }
}

@end
