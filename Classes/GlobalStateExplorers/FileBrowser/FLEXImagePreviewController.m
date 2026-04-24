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
@property (nonatomic) BOOL isTransitioningSize;

@end

@implementation FLEXImagePreviewController

+ (instancetype)forImageAtPath:(NSString *)path placeholder:(UIImage *)placeholder {
    NSParameterAssert(path.length > 0);
    FLEXImagePreviewController *controller = [self new];
    controller.imagePath = path;
    controller.imageView = [[UIImageView alloc] initWithImage:placeholder];
    return controller;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
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

    // Size transitions (rotation, size class change) are handled in
    // viewWillTransitionToSize: so the geometry updates run inside the
    // coordinator's animation block. Running them here too would snap the
    // layout outside that block and reintroduce the zoom flicker.
    if (self.isTransitioningSize) return;

    // Only apply a new layout when the scroll view's size actually changes
    // (initial layout) — otherwise nav-bar toggles would clobber the user's
    // zoom and pan state.
    self.scrollView.frame = self.view.bounds;
    if (!CGSizeEqualToSize(self.scrollView.bounds.size, self.lastLaidOutBoundsSize)) {
        [self applyLayout];
    }
    [self centerImage];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    // Run layout inside the coordinator's animation block so imageView frame,
    // contentSize, and zoomScale changes interpolate alongside the system's
    // rotation — rather than snapping out from under it and producing a
    // visible zoom-in / zoom-out artifact.
    self.isTransitioningSize = YES;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> ctx) {
        self.scrollView.frame = self.view.bounds;
        [self applyLayout];
        [self centerImage];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> ctx) {
        self.isTransitioningSize = NO;
    }];
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

    // Snapshot previous state before we touch anything. Use the scroll view's
    // contentSize (not imageView.frame.size) as the source of truth for the
    // old geometry — the scroll view resizes the zoom view by its frame while
    // zooming, so imageView.frame.size is already the zoomed size.
    CGFloat previousZoomScale = self.scrollView.zoomScale;
    CGPoint previousOffset = self.scrollView.contentOffset;
    CGPoint previousImagePosition = self.imageView.frame.origin;
    CGSize previousContentSize = self.scrollView.contentSize;
    CGSize previousBoundsSize = self.lastLaidOutBoundsSize;
    BOOL hasPreviousLayout = previousBoundsSize.width > 0 && previousContentSize.width > 0;

    // Size the image view so that at zoomScale = 1.0 the image exactly fits.
    CGFloat widthScale = boundsSize.width / imageSize.width;
    CGFloat heightScale = boundsSize.height / imageSize.height;
    CGFloat fitScale = MIN(widthScale, heightScale);
    CGSize newFitSize = CGSizeMake(imageSize.width * fitScale, imageSize.height * fitScale);

    // Max zoom is 3.5× the aspect-fill scale (in fit-space), so detail at max
    // is consistent regardless of aspect ratio.
    CGFloat newMaxZoom = (MAX(widthScale, heightScale) / fitScale) * 3.5;

    // If the user had zoomed in, preserve their visual magnification and the
    // image point at the visible centre. Otherwise snap to the new fit.
    BOOL preserveZoom = hasPreviousLayout && previousZoomScale > 1.0001;

    CGPoint normalizedCenter = CGPointMake(0.5, 0.5);
    CGFloat newZoomScale = 1.0;
    if (preserveZoom) {
        // Normalise the visible centre relative to the image. Subtract the
        // image view's origin so centring (when the image is smaller than the
        // bounds in either axis) is handled correctly.
        normalizedCenter.x = (previousOffset.x + previousBoundsSize.width * 0.5 - previousImagePosition.x)
            / previousContentSize.width;
        normalizedCenter.y = (previousOffset.y + previousBoundsSize.height * 0.5 - previousImagePosition.y)
            / previousContentSize.height;

        // previousFit = previousContentSize / previousZoomScale. Compensating
        // by previousFit/newFit keeps the on-screen magnification unchanged.
        CGFloat previousFitWidth = previousContentSize.width / previousZoomScale;
        newZoomScale = previousZoomScale * (previousFitWidth / newFitSize.width);
        newZoomScale = MAX(1.0, MIN(newZoomScale, newMaxZoom));
    }

    // Reset the transform before resizing, then apply new geometry.
    self.scrollView.zoomScale = 1.0;
    self.imageView.frame = CGRectMake(0, 0, newFitSize.width, newFitSize.height);
    self.scrollView.contentSize = newFitSize;
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = newMaxZoom;
    self.scrollView.zoomScale = newZoomScale;

    if (preserveZoom) {
        CGSize newContentSize = CGSizeMake(
            newFitSize.width * newZoomScale,
            newFitSize.height * newZoomScale
        );
        CGPoint newOffset = CGPointMake(
            normalizedCenter.x * newContentSize.width - boundsSize.width * 0.5,
            normalizedCenter.y * newContentSize.height - boundsSize.height * 0.5
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
    if (!self.imagePath.length) return;
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
