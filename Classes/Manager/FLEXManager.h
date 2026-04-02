//
//  FLEXManager.h
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

NS_ASSUME_NONNULL_BEGIN

/// A block that creates and returns a view controller for displaying
/// custom content of the given type, or `nil` if the content cannot be displayed.
typedef UIViewController * _Nullable (^FLEXCustomContentViewerFuture)(NSData *data);

/// The primary interface for configuring and controlling FLEX.
@interface FLEXManager : NSObject

/// The shared FLEX manager instance.
@property (nonatomic, readonly, class) FLEXManager *sharedManager;

/// Whether the FLEX explorer toolbar is currently hidden.
@property (nonatomic, readonly) BOOL isHidden;

/// The FLEX explorer toolbar. Visible whenever FLEX is shown.
@property (nonatomic, readonly) FLEXExplorerToolbar *toolbar;

#pragma mark - Showing and Hiding

/// Shows the FLEX explorer toolbar.
- (void)showExplorer;
/// Hides the FLEX explorer toolbar and dismisses any presented tools.
- (void)hideExplorer;
/// Toggles the visibility of the FLEX explorer toolbar.
- (void)toggleExplorer;

/// Presents the FLEX explorer in the specified scene.
///
/// Use this when the scene FLEX would select by default is not the one
/// you want it to appear in.
- (void)showExplorerFromScene:(UIWindowScene *)scene;

#pragma mark - Presenting Tools

/// Programmatically dismisses anything currently presented by FLEX,
/// leaving only the explorer toolbar visible.
- (void)dismissAnyPresentedTools:(void (^_Nullable)(void))completion;

/// Presents a custom navigation controller on top of the FLEX toolbar.
///
/// Any currently presented tool is automatically dismissed first,
/// so you do not need to call `dismissAnyPresentedTools:` beforehand.
- (void)presentTool:(UINavigationController *(^)(void))viewControllerFuture
         completion:(void (^_Nullable)(void))completion;

/// Wraps the given view controller in a navigation controller and presents it
/// on top of the FLEX toolbar. The completion block receives the new navigation controller.
- (void)presentEmbeddedTool:(UIViewController *)viewController
                 completion:(void (^_Nullable)(UINavigationController *))completion;

/// Presents an object explorer for the given object on top of the FLEX toolbar.
/// The completion block receives the new navigation controller.
- (void)presentObjectExplorer:(id)object
                   completion:(void (^_Nullable)(UINavigationController *))completion;

#pragma mark - Miscellaneous

/// The password used when opening SQLite databases. Defaults to `nil`
@property (copy, nonatomic) NSString *defaultSqliteDatabasePassword;

@end

NS_ASSUME_NONNULL_END
