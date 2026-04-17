//
//  FLEXImagePreviewController.m
//
//  Copyright (c) FLEX Team (2020-2026).
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

#import "FLEXImagePreviewController.h"
#import "FLEXActivityViewController.h"
#import "FLEXUtility.h"

@interface FLEXImagePreviewController () <UIScrollViewDelegate>

@property (nonatomic, copy) NSString *imagePath;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) CGSize lastLaidOutBoundsSize;

@end

@implementation FLEXImagePreviewController

+ (instancetype)forImageAtPath:(NSString *)path placeholder:(UIImage *)placeholder {
    FLEXImagePreviewController *controller = [self new];
    controller.imagePath = path;
    controller.imageView = [[UIImageView alloc] initWithImage:placeholder];
    return controller;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
        target:self
        action:@selector(doneTapped:)
    ];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAction
        target:self
        action:@selector(shareTapped:)
    ];

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.delegate = self;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.scrollView];

    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.scrollView addSubview:self.imageView];

    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.scrollView addGestureRecognizer:doubleTap];

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleSingleTap:)];
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.scrollView addGestureRecognizer:singleTap];

    [self loadFullResolutionImage];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    // Only apply a new layout when the scroll view's size actually changes
    // (initial layout, rotation, size class change) — otherwise nav-bar toggles
    // would clobber the user's zoom and pan state.
    if (!CGSizeEqualToSize(self.scrollView.bounds.size, self.lastLaidOutBoundsSize)) {
        [self applyLayout];
    }
    [self centerImage];
}

- (BOOL)prefersStatusBarHidden {
    return self.navigationController.navigationBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

#pragma mark - Image loading

- (void)loadFullResolutionImage {
    NSString *path = self.imagePath;
    weakify(self)
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        UIImage *prepared = image;
        if (@available(iOS 15.0, *)) {
            prepared = [image imageByPreparingForDisplay] ?: image;
        }

        dispatch_async(dispatch_get_main_queue(), ^{ strongify(self)
            if (!self || !prepared) return;
            self.imageView.image = prepared;
            [self applyLayout];
            [self centerImage];
        });
    });
}

#pragma mark - Layout

- (void)applyLayout {
    UIImage *image = self.imageView.image;
    CGSize boundsSize = self.scrollView.bounds.size;
    if (!image || boundsSize.width == 0 || boundsSize.height == 0) return;

    CGSize imageSize = image.size;
    if (imageSize.width == 0 || imageSize.height == 0) return;

    // Snapshot current state before we resize anything.
    CGFloat previousZoomScale = self.scrollView.zoomScale;
    CGPoint previousContentOffset = self.scrollView.contentOffset;
    CGSize previousFitSize = self.imageView.frame.size;
    CGSize previousBoundsSize = self.lastLaidOutBoundsSize;

    // Size the image view so that at zoomScale = 1.0 the image exactly fits
    // the scroll view — "fit" is the minimum zoom, consistent across images.
    CGFloat widthScale = boundsSize.width / imageSize.width;
    CGFloat heightScale = boundsSize.height / imageSize.height;
    CGFloat fitScale = MIN(widthScale, heightScale);
    CGSize newFitSize = CGSizeMake(imageSize.width * fitScale, imageSize.height * fitScale);

    // Max zoom is 3.5× the aspect-fill scale (expressed in fit-space), so the
    // ceiling represents the same level of pixel detail for every image — long
    // narrow images don't end up with a tiny maximum zoom.
    CGFloat newMaxZoom = (MAX(widthScale, heightScale) / fitScale) * 3.5;

    // Preserve the user's visual zoom level if they'd zoomed in. zoomScale 1.0
    // maps to a different absolute size at each bounds/image combination, so
    // scale previousZoomScale by previousFit/newFit to keep the on-screen
    // magnification the same. If they were at fit, just re-fit to the new size.
    BOOL hasPreviousLayout = previousBoundsSize.width > 0 && previousFitSize.width > 0;
    BOOL preserveZoom = hasPreviousLayout && previousZoomScale > 1.0001;
    CGFloat newZoomScale = 1.0;
    if (preserveZoom) {
        newZoomScale = previousZoomScale * (previousFitSize.width / newFitSize.width);
        newZoomScale = MAX(1.0, MIN(newZoomScale, newMaxZoom));
    }

    // Clear the transform before resizing the image view, then apply geometry.
    self.scrollView.zoomScale = 1.0;
    self.imageView.frame = CGRectMake(0, 0, newFitSize.width, newFitSize.height);
    self.scrollView.contentSize = newFitSize;
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = newMaxZoom;
    self.scrollView.zoomScale = newZoomScale;

    if (preserveZoom) {
        // Keep the same image point at the visible centre by normalising the
        // previous visible centre against the old content size and mapping it
        // back into the new content size.
        CGPoint previousVisibleCenter = CGPointMake(
            previousContentOffset.x + previousBoundsSize.width / 2.0,
            previousContentOffset.y + previousBoundsSize.height / 2.0
        );
        CGSize previousContentSize = CGSizeMake(
            previousFitSize.width * previousZoomScale,
            previousFitSize.height * previousZoomScale
        );
        CGPoint normalized = CGPointMake(
            previousVisibleCenter.x / previousContentSize.width,
            previousVisibleCenter.y / previousContentSize.height
        );
        CGSize newContentSize = CGSizeMake(
            newFitSize.width * newZoomScale,
            newFitSize.height * newZoomScale
        );
        CGPoint newOffset = CGPointMake(
            normalized.x * newContentSize.width - boundsSize.width / 2.0,
            normalized.y * newContentSize.height - boundsSize.height / 2.0
        );
        CGFloat maxOffsetX = MAX(0, newContentSize.width - boundsSize.width);
        CGFloat maxOffsetY = MAX(0, newContentSize.height - boundsSize.height);
        newOffset.x = MAX(0, MIN(newOffset.x, maxOffsetX));
        newOffset.y = MAX(0, MIN(newOffset.y, maxOffsetY));
        self.scrollView.contentOffset = newOffset;
    }

    self.lastLaidOutBoundsSize = boundsSize;
}

- (void)centerImage {
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect frame = self.imageView.frame;

    frame.origin.x = frame.size.width < boundsSize.width
        ? (boundsSize.width - frame.size.width) / 2.0
        : 0;
    frame.origin.y = frame.size.height < boundsSize.height
        ? (boundsSize.height - frame.size.height) / 2.0
        : 0;

    self.imageView.frame = frame;
}

#pragma mark - Gestures

- (void)handleSingleTap:(UITapGestureRecognizer *)gesture {
    BOOL nowHidden = !self.navigationController.navigationBarHidden;
    [self.navigationController setNavigationBarHidden:nowHidden animated:YES];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)gesture {
    CGFloat minScale = self.scrollView.minimumZoomScale;
    CGFloat maxScale = self.scrollView.maximumZoomScale;

    if (self.scrollView.zoomScale > minScale + 0.0001) {
        [self.scrollView setZoomScale:minScale animated:YES];
        return;
    }

    CGFloat targetScale = MIN(minScale * 3.0, maxScale);
    CGPoint point = [gesture locationInView:self.imageView];
    CGSize size = CGSizeMake(
        self.scrollView.bounds.size.width / targetScale,
        self.scrollView.bounds.size.height / targetScale
    );
    CGRect zoomRect = CGRectMake(
        point.x - size.width / 2.0,
        point.y - size.height / 2.0,
        size.width,
        size.height
    );
    [self.scrollView zoomToRect:zoomRect animated:YES];
}

#pragma mark - Actions

- (void)doneTapped:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)shareTapped:(UIBarButtonItem *)sender {
    NSURL *fileURL = [NSURL fileURLWithPath:self.imagePath];
    UIViewController *shareSheet = [FLEXActivityViewController sharing:@[fileURL] source:sender];
    [self presentViewController:shareSheet animated:YES completion:nil];
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self centerImage];
}

@end
