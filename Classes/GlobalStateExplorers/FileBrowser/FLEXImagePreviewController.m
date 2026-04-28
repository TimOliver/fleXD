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

typedef struct FLEXImagePreviewScrollViewState {
    CGFloat zoomScale;
    CGPoint offset;
    CGSize contentSize;
    CGPoint contentPosition;
    CGSize frameSize;
} FLEXImagePreviewScrollViewState;

static inline FLEXImagePreviewScrollViewState FLEXImagePreviewStateForScrollView(UIScrollView *scrollView, UIView *contentView) {
    return (FLEXImagePreviewScrollViewState) {
        .zoomScale = scrollView.zoomScale,
        .offset = scrollView.contentOffset,
        .contentSize = scrollView.contentSize,
        .contentPosition = contentView.frame.origin,
        .frameSize = scrollView.frame.size,
    };
}

@interface FLEXImagePreviewController () <UIScrollViewDelegate>

@property (nonatomic, copy) NSString *imagePath;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIImageView *imageView;
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
    self.scrollView.minimumZoomScale = 1.0;
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

    // During a rotation animation, `viewDidLayoutSubviews` can potentially be
    // called multiple times that can break the animation. Instead, we use the official
    // rotation API to block layout passes as we'll be manually applying it inside the animation block.
    if (self.isTransitioningSize) { return; }

    // Capture the original size before we update so we can work out the scroll view sizing deltas.
    const CGSize originalSize = self.scrollView.frame.size;
    self.scrollView.frame = self.view.bounds;
    [self applyLayoutFromSize:originalSize];
    [self centerImage];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    // Capture the current size of the scroll view so we can apply it to our transform calculations
    const CGSize originalSize = self.scrollView.frame.size;
    
    // Disable any system layout passes for the duration of this animation since we'll manually control'
    // it inside the animation block.
    self.isTransitioningSize = YES;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> ctx) {
        self.scrollView.frame = self.view.bounds;
        [self applyLayoutFromSize:originalSize];
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
            [self applyLayoutFromSize:self.scrollView.frame.size];
            self.imageView.frame = (CGRect){CGPointZero, self.scrollView.contentSize};
            [self centerImage];
        });
    });
}

#pragma mark - Layout

- (void)applyLayoutFromSize:(CGSize)oldSize {
    // Don't layout if the scroll view hasn't received a size yet
    const CGSize frameSize = self.scrollView.frame.size;
    if (CGSizeEqualToSize(frameSize, CGSizeZero)) { return; }
    
    // Short-circuit if we're not actually performing a meaningful bounds change since our last pass
    if (!CGSizeEqualToSize(self.scrollView.contentSize, CGSizeZero) && CGSizeEqualToSize(self.scrollView.frame.size, oldSize)) {
        return;
    }
    
    UIImage *image = self.imageView.image;
    if (!image) return;

    const CGSize imageSize = image.size;
    if (imageSize.width == 0 || imageSize.height == 0) return;

    // Snapshot previous state before we touch anything. Use the scroll view's
    // contentSize (not imageView.frame.size) as the source of truth for the
    // old geometry — the scroll view resizes the zoom view by its frame while
    // zooming, so imageView.frame.size is already the zoomed size.
    FLEXImagePreviewScrollViewState oldState = FLEXImagePreviewStateForScrollView(self.scrollView, self.imageView);
    oldState.frameSize = oldSize;

    // Size the image view so that at zoomScale = 1.0 the image exactly fits.
    const CGFloat widthScale = frameSize.width / imageSize.width;
    const CGFloat heightScale = frameSize.height / imageSize.height;
    const CGFloat fitScale = MIN(widthScale, heightScale);
    const CGSize newFitSize = CGSizeMake(imageSize.width * fitScale, imageSize.height * fitScale);

    // Max zoom is 3.5× the aspect-fill scale (in fit-space), so detail at max
    // is consistent regardless of aspect ratio.
    const CGFloat newMaxZoom = (MAX(widthScale, heightScale) / fitScale) * 3.5;

    // If the user had zoomed in, preserve their visual magnification and the
    // image point at the visible centre. Otherwise snap to the new fit.
    const BOOL preserveZoom = oldState.zoomScale > 1.05;

    CGPoint normalizedCenter = CGPointMake(0.5, 0.5);
    CGFloat newZoomScale = 1.0;
    if (preserveZoom) {
        // Normalise the visible centre relative to the image. Subtract the
        // image view's origin so centring (when the image is smaller than the
        // bounds in either axis) is handled correctly.
        normalizedCenter.x = (oldState.offset.x + ((oldSize.width * 0.5f) - oldState.contentPosition.x)) / oldState.contentSize.width;
        normalizedCenter.y = (oldState.offset.y + ((oldSize.height * 0.5f) - oldState.contentPosition.y)) / oldState.contentSize.height;

        // previousFit = previousContentSize / previousZoomScale. Compensating
        // by previousFit/newFit keeps the on-screen magnification unchanged.
        CGFloat previousFitWidth = oldState.contentSize.width / oldState.zoomScale;
        newZoomScale = oldState.zoomScale * (previousFitWidth / newFitSize.width);
        newZoomScale = MAX(1.0, MIN(newZoomScale, newMaxZoom));
    }

    // Reset the transform before resizing, then apply new geometry.
    self.scrollView.maximumZoomScale = newMaxZoom;
    self.scrollView.zoomScale = newZoomScale;
    self.scrollView.contentSize = (CGSize){newFitSize.width * newZoomScale, newFitSize.height * newZoomScale};

    // Now that we've resized the content to its equivalent in the new bounds, apply the normalized offset.
    if (preserveZoom) {
        CGSize contentSize = self.scrollView.contentSize;
        CGSize boundsSize = self.scrollView.frame.size;
        CGPoint translatedPoint = CGPointZero;
        translatedPoint.x = (normalizedCenter.x * contentSize.width) - (boundsSize.width * 0.5f);
        translatedPoint.y = (normalizedCenter.y * contentSize.height) - (boundsSize.height * 0.5f);
        translatedPoint.x = MIN(translatedPoint.x, contentSize.width - boundsSize.width);
        translatedPoint.y = MIN(translatedPoint.y, contentSize.height - boundsSize.height);
        translatedPoint.x = MAX(translatedPoint.x, 0.0f);
        translatedPoint.y = MAX(translatedPoint.y, 0.0f);
        self.scrollView.contentOffset = translatedPoint;
    }
}

- (void)centerImage {
    CGRect frame = (CGRect){CGPointZero, self.scrollView.contentSize};
    CGSize viewSize = self.scrollView.frame.size;

    // Center the view, unless its size has out-grown the view region
    frame.origin.x = 0.0f;
    if (frame.size.width < viewSize.width) {
        frame.origin.x = (viewSize.width - frame.size.width) * 0.5f;
    }

    frame.origin.y = 0.0f;
    if (frame.size.height < viewSize.height) {
        frame.origin.y = (viewSize.height - frame.size.height) * 0.5f;
    }

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
