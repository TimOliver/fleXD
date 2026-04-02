//
//  FLEXTableView.h
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

#pragma mark - Reuse identifiers

typedef NSString * FLEXTableViewCellReuseIdentifier;

/// A regular `FLEXTableViewCell` initialized with `UITableViewCellStyleDefault`
extern FLEXTableViewCellReuseIdentifier const kFLEXDefaultCell;
/// A `FLEXSubtitleTableViewCell` initialized with `UITableViewCellStyleSubtitle`
extern FLEXTableViewCellReuseIdentifier const kFLEXDetailCell;
/// A `FLEXMultilineTableViewCell` initialized with `UITableViewCellStyleDefault`
extern FLEXTableViewCellReuseIdentifier const kFLEXMultilineCell;
/// A `FLEXMultilineTableViewCell` initialized with `UITableViewCellStyleSubtitle`
extern FLEXTableViewCellReuseIdentifier const kFLEXMultilineDetailCell;
/// A `FLEXTableViewCell` initialized with `UITableViewCellStyleValue1`
extern FLEXTableViewCellReuseIdentifier const kFLEXKeyValueCell;
/// A `FLEXSubtitleTableViewCell` which uses monospaced fonts for both labels
extern FLEXTableViewCellReuseIdentifier const kFLEXCodeFontCell;

#pragma mark - FLEXTableView
/// A `UITableView` subclass that pre-registers FLEX's default cell reuse identifiers.
@interface FLEXTableView : UITableView

/// Creates an inset-grouped table view.
+ (instancetype)flexDefaultTableView;
/// Creates a grouped table view.
+ (instancetype)groupedTableView;
/// Creates a plain table view.
+ (instancetype)plainTableView;
/// Creates a table view with the given style.
+ (instancetype)style:(UITableViewStyle)style;

/// You do not need to register classes for any of the default reuse identifiers above
/// (annotated as `FLEXTableViewCellReuseIdentifier` types) unless you wish to provide
/// a custom cell for any of those reuse identifiers. By default, `FLEXTableViewCell`
/// `FLEXSubtitleTableViewCell` and `FLEXMultilineTableViewCell` are used, respectively.
///
/// @param registrationMapping A map of reuse identifiers to `UITableViewCell` (sub)class objects.
- (void)registerCells:(NSDictionary<NSString *, Class> *)registrationMapping;

@end

NS_ASSUME_NONNULL_END
