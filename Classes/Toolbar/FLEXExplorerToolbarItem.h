//
//  FLEXExplorerToolbarItem.h
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

NS_ASSUME_NONNULL_BEGIN

/// A `UIButton` subclass used as a toolbar item in the FLEX explorer toolbar.
///
/// Toolbar items support a "sibling" item concept: when a toolbar item becomes
/// disabled, it can automatically swap itself out for a sibling item in the toolbar.
@interface FLEXExplorerToolbarItem : UIButton

/// Creates a toolbar item with the given title and image.
+ (instancetype)itemWithTitle:(NSString *)title image:(UIImage *)image;

/// @param backupItem a toolbar item to use in place of this item when it becomes disabled.
/// Items without a sibling item exhibit expected behavior when they become disabled, and are greyed out.
+ (instancetype)itemWithTitle:(NSString *)title image:(UIImage *)image sibling:(nullable FLEXExplorerToolbarItem *)backupItem;

/// If a toolbar item has a sibling, the item will replace itself with its
/// sibling when it becomes disabled, and vice versa when it becomes enabled again.
@property (nonatomic, readonly) FLEXExplorerToolbarItem *sibling;

/// When a toolbar item has a sibling and it becomes disabled, the sibling is the view
/// that should be added to or removed from a new or existing toolbar. This property
/// alleviates the programmer from determining whether to use `item` or `item.sibling`
/// or `item.sibling.sibling` and so on. Yes, sibling items can also have siblings so
/// that each item which becomes disabled may present another item in its place, creating
/// a "stack" of toolbar items. This behavior is useful for making buttons which occupy
/// the same space under different states.
///
/// With this in mind, you should never access a stored toolbar item's view properties
/// such as `frame` or `superview` directly; you should access them on `currentItem`
/// If you are trying to modify the frame of an item, and the item itself is not currently
/// displayed but instead its sibling is being displayed, then your changes could be ignored.
///
/// @return the result of the item's sibling's `currentItem`
/// if this item has a sibling and this item is disabled, otherwise this item.
@property (nonatomic, readonly) FLEXExplorerToolbarItem *currentItem;

@end

NS_ASSUME_NONNULL_END
