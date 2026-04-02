//
//  FLEXExplorerViewController.h
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

#import "FLEXExplorerToolbar.h"

@class FLEXWindow;
@class FLEXExplorerViewController;

@protocol FLEXExplorerViewControllerDelegate <NSObject>
- (void)explorerViewControllerDidFinish:(FLEXExplorerViewController *)explorerViewController;
@end

/// A view controller that manages the FLEX toolbar.
@interface FLEXExplorerViewController : UIViewController

/// The delegate that is notified when the explorer finishes.
@property (nonatomic, weak) id <FLEXExplorerViewControllerDelegate> delegate;

/// Whether the FLEX window should become the key window while the explorer is active.
@property (nonatomic, readonly) BOOL wantsWindowToBecomeKey;

/// The floating toolbar managed by this view controller.
@property (nonatomic, readonly) FLEXExplorerToolbar *explorerToolbar;

/// Returns whether the explorer should receive a touch at the given point in window coordinates.
- (BOOL)shouldReceiveTouchAtWindowPoint:(CGPoint)pointInWindowCoordinates;

/// Toggles a modal tool on or off.
///
/// If a tool is already presented, it is dismissed and the completion block is called.
/// If no tool is presented, `future()` is invoked and the resulting controller is presented.
///
/// @param future A block returning the navigation controller to present.
/// @param completion Called after dismissal or presentation completes.
- (void)toggleToolWithViewControllerProvider:(UINavigationController *(^)(void))future
                                  completion:(void (^)(void))completion;

/// Presents a modal tool, dismissing any currently presented tool first.
///
/// The completion block is called once the new tool has been fully presented.
///
/// @param future A block returning the navigation controller to present.
/// @param completion Called after the tool has been presented.
- (void)presentTool:(UINavigationController *(^)(void))future
         completion:(void (^)(void))completion;

// Keyboard shortcut helpers

- (void)toggleSelectTool;
- (void)toggleMoveTool;
- (void)toggleViewsTool;
- (void)toggleMenuTool;

/// @return YES if the explorer used the key press to perform an action, NO otherwise
- (BOOL)handleDownArrowKeyPressed;
/// @return YES if the explorer used the key press to perform an action, NO otherwise
- (BOOL)handleUpArrowKeyPressed;
/// @return YES if the explorer used the key press to perform an action, NO otherwise
- (BOOL)handleRightArrowKeyPressed;
/// @return YES if the explorer used the key press to perform an action, NO otherwise
- (BOOL)handleLeftArrowKeyPressed;

@end

