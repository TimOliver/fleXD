//
//  FLEXManager.m
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

#import "FLEXManager.h"
#import "FLEXUtility.h"
#import "FLEXExplorerViewController.h"
#import "FLEXWindow.h"
#import "FLEXNavigationController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXFileBrowserController.h"

@interface FLEXManager () <FLEXWindowEventDelegate, FLEXExplorerViewControllerDelegate>

@property (nonatomic, readonly, getter=isHidden) BOOL hidden;

@property (nonatomic) FLEXWindow *explorerWindow;
@property (nonatomic) FLEXExplorerViewController *explorerViewController;

@property (nonatomic, readonly) NSMutableArray<FLEXGlobalsEntry *> *userGlobalEntries;
@property (nonatomic, readonly) NSMutableDictionary<NSString *, FLEXCustomContentViewerFuture> *customContentTypeViewers;

@end

@implementation FLEXManager

+ (instancetype)sharedManager {
    static FLEXManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [self new];
    });
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _userGlobalEntries = [NSMutableArray new];
        _customContentTypeViewers = [NSMutableDictionary new];
    }
    return self;
}

- (FLEXWindow *)explorerWindow {
    NSAssert(NSThread.isMainThread, @"You must use %@ from the main thread only.", NSStringFromClass([self class]));

    if (!_explorerWindow) {
        _explorerWindow = [[FLEXWindow alloc] initWithFrame:FLEXUtility.appKeyWindow.bounds];
        _explorerWindow.eventDelegate = self;
        _explorerWindow.rootViewController = self.explorerViewController;
    }

    return _explorerWindow;
}

- (FLEXExplorerViewController *)explorerViewController {
    if (!_explorerViewController) {
        _explorerViewController = [FLEXExplorerViewController new];
        _explorerViewController.delegate = self;
    }

    return _explorerViewController;
}

- (void)showExplorer {
    UIWindow *flex = self.explorerWindow;
    flex.hidden = NO;
    // Only look for a new scene if we don't have one
    if (!flex.windowScene) {
        flex.windowScene = FLEXUtility.appKeyWindow.windowScene;
    }
}

- (void)hideExplorer {
    self.explorerWindow.hidden = YES;
}

- (void)toggleExplorer {
    if (self.explorerWindow.isHidden) {
        [self showExplorerFromScene:FLEXUtility.appKeyWindow.windowScene];
    } else {
        [self hideExplorer];
    }
}

- (void)dismissAnyPresentedTools:(void (^)(void))completion {
    if (self.explorerViewController.presentedViewController) {
        [self.explorerViewController dismissViewControllerAnimated:YES completion:completion];
    } else if (completion) {
        completion();
    }
}

- (void)presentTool:(UINavigationController * _Nonnull (^)(void))future completion:(void (^)(void))completion {
    [self showExplorer];
    [self.explorerViewController presentTool:future completion:completion];
}

- (void)presentEmbeddedTool:(UIViewController *)tool completion:(void (^)(UINavigationController *))completion {
    FLEXNavigationController *nav = [FLEXNavigationController withRootViewController:tool];
    [self presentTool:^UINavigationController *{
        return nav;
    } completion:^{
        if (completion) completion(nav);
    }];
}

- (void)presentObjectExplorer:(id)object completion:(void (^)(UINavigationController *))completion {
    UIViewController *explorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:object];
    [self presentEmbeddedTool:explorer completion:completion];
}

- (void)showExplorerFromScene:(UIWindowScene *)scene {
    self.explorerWindow.windowScene = scene;
    self.explorerWindow.hidden = NO;
}

- (BOOL)isHidden {
    return self.explorerWindow.isHidden;
}

- (FLEXExplorerToolbar *)toolbar {
    return self.explorerViewController.explorerToolbar;
}


#pragma mark - FLEXWindowEventDelegate

- (BOOL)shouldHandleTouchAtPoint:(CGPoint)pointInWindow {
    // Ask the explorer view controller
    return [self.explorerViewController shouldReceiveTouchAtWindowPoint:pointInWindow];
}

- (BOOL)canBecomeKeyWindow {
    // Only when the explorer view controller wants it because
    // it needs to accept key input & affect the status bar.
    return self.explorerViewController.wantsWindowToBecomeKey;
}


#pragma mark - FLEXExplorerViewControllerDelegate

- (void)explorerViewControllerDidFinish:(FLEXExplorerViewController *)explorerViewController {
    [self hideExplorer];
}

@end
