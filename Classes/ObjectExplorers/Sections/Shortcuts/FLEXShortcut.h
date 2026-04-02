//
//  FLEXShortcut.h
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

#import "FLEXObjectExplorer.h"

NS_ASSUME_NONNULL_BEGIN

/// Represents a row in a shortcut section.
///
/// The purpose of this protocol is to allow delegating a small
/// subset of the responsibilities of a `FLEXShortcutsSection`
/// to another object, for a single arbitrary row.
///
/// It is useful to make your own shortcuts to append/prepend
/// them to the existing list of shortcuts for a class.
@protocol FLEXShortcut <FLEXObjectExplorerItem>

- (nonnull  NSString *)titleWith:(id)object;
- (nullable NSString *)subtitleWith:(id)object;
- (nullable void (^)(UIViewController *host))didSelectActionWith:(id)object;
/// Called when the row is selected
- (nullable UIViewController *)viewerWith:(id)object;
/// Basically, whether or not to show a detail disclosure indicator
- (UITableViewCellAccessoryType)accessoryTypeWith:(id)object;
/// If nil is returned, the default reuse identifier is used
- (nullable NSString *)customReuseIdentifierWith:(id)object;

@optional
/// Called when the (i) button is pressed if the accessory type includes it
- (UIViewController *)editorWith:(id)object forSection:(FLEXTableViewSection *)section;

@end


/// Provides default behavior for FLEX metadata objects. Also works in a limited way with strings.
/// Used internally. If you wish to use this object, only pass in `FLEX*` metadata objects.
@interface FLEXShortcut : NSObject <FLEXShortcut>

/// @param item An `NSString` or `FLEX*` metadata object.
/// @note You may also pass a `FLEXShortcut` conforming object,
/// and that object will be returned instead.
+ (id<FLEXShortcut>)shortcutFor:(id)item;

@end


/// Provides a quick and dirty implementation of the `FLEXShortcut` protocol,
/// allowing you to specify a static title and dynamic attributes for everything else.
/// The object passed into each block is the object passed to each `FLEXShortcut` method.
///
/// Does not support the `-editorWith:` method.
@interface FLEXActionShortcut : NSObject <FLEXShortcut>

+ (instancetype)title:(NSString *)title
             subtitle:(nullable NSString *(^)(id object))subtitleFuture
               viewer:(nullable UIViewController *(^)(id object))viewerFuture
        accessoryType:(nullable UITableViewCellAccessoryType(^)(id object))accessoryTypeFuture;

+ (instancetype)title:(NSString *)title
             subtitle:(nullable NSString *(^)(id object))subtitleFuture
     selectionHandler:(nullable void (^)(UIViewController *host, id object))tapAction
        accessoryType:(nullable UITableViewCellAccessoryType(^)(id object))accessoryTypeFuture;

@end

NS_ASSUME_NONNULL_END
