//
//  FLEXFileBrowserCell.h
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

/// A Files-style file browser row: a fixed-size icon region at the leading edge
/// with a stacked title (filename) and subtitle (metadata) beside it.
@interface FLEXFileBrowserCell : UITableViewCell

/// The fixed-size icon at the leading edge. Exposed so the controller can use it
/// as the source view for the image preview zoom transition.
@property (nonatomic, readonly) UIImageView *iconImageView;

/// The primary filename label.
@property (nonatomic, readonly) UILabel *titleLabel;

/// The secondary metadata label (e.g. "6 Jun 2026 · 13 MB" or "3 items").
@property (nonatomic, readonly) UILabel *subtitleLabel;

/// The file path this cell currently represents. Used as a reuse token so that
/// async thumbnail loads only apply if the cell still shows the same file.
@property (nonatomic, copy, nullable) NSString *representedPath;

/// Display a template/symbol icon: aspect-fit, tinted, no corner rounding.
/// Use for the folder and document icons.
- (void)setSymbolIcon:(nullable UIImage *)image tintColor:(UIColor *)tintColor;

/// Display a photo thumbnail: aspect-fill, clipped to a rounded square.
- (void)setThumbnail:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
