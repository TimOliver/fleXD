//
//  FLEXExplorerToolbar.h
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

#import <UIKit/UIKit.h>

@class FLEXExplorerToolbarItem;

NS_ASSUME_NONNULL_BEGIN

/// The floating toolbar displayed by the FLEX explorer.
///
/// Users of the toolbar can configure the enabled state
/// and event target/actions for each item.
@interface FLEXExplorerToolbar : UIView

/// The items to be displayed in the toolbar. Defaults to:
/// globalsItem, hierarchyItem, selectItem, moveItem, closeItem
@property (nonatomic, copy) NSArray<FLEXExplorerToolbarItem *> *toolbarItems;

/// Toolbar item for selecting views.
@property (nonatomic, readonly) FLEXExplorerToolbarItem *selectItem;

/// Toolbar item for presenting a list with the view hierarchy.
@property (nonatomic, readonly) FLEXExplorerToolbarItem *hierarchyItem;

/// Toolbar item for moving views.
/// Its `sibling` is the `lastTabItem`
@property (nonatomic, readonly) FLEXExplorerToolbarItem *moveItem;

/// Toolbar item for presenting the currently active tab.
@property (nonatomic, readonly) FLEXExplorerToolbarItem *recentItem;

/// Toolbar item for presenting a screen with various tools for inspecting the app.
@property (nonatomic, readonly) FLEXExplorerToolbarItem *globalsItem;

/// Toolbar item for hiding the explorer.
@property (nonatomic, readonly) FLEXExplorerToolbarItem *closeItem;

/// A view suitable for attaching drag gestures. Defaults to the toolbar itself.
@property (nonatomic, readonly) UIView *dragHandle;

/// The maximum width of the toolbar. On screens narrower than this, the toolbar shrinks to fit.
@property (nonatomic, readonly, class) CGFloat maximumWidth;

/// A color matching the overlay color on the selected view.
@property (nonatomic) UIColor *selectedViewOverlayColor;

/// Description text for the selected view displayed below the toolbar items.
@property (nonatomic, copy) NSString *selectedViewDescription;

/// Area where details of the selected view are shown
/// Users of the toolbar can attach a tap gesture recognizer to show additional details.
@property (nonatomic, readonly) UIView *selectedViewDescriptionContainer;

@end

NS_ASSUME_NONNULL_END
