//
//  FLEXMultilineTableViewCell.m
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

#import "FLEXMultilineTableViewCell.h"
#import "UIView+FLEX_Layout.h"
#import "FLEXUtility.h"

@interface FLEXMultilineTableViewCell ()
@property (nonatomic, readonly) UILabel *_titleLabel;
@property (nonatomic, readonly) UILabel *_subtitleLabel;
@property (nonatomic) BOOL constraintsUpdated;
@end

@implementation FLEXMultilineTableViewCell

- (void)postInit {
    [super postInit];

    self.titleLabel.numberOfLines = 0;
    self.subtitleLabel.numberOfLines = 0;
}

+ (UIEdgeInsets)labelInsets {
    return UIEdgeInsetsMake(10.0, 16.0, 10.0, 8.0);
}

+ (CGFloat)preferredHeightWithAttributedText:(NSAttributedString *)attributedText
                                    maxWidth:(CGFloat)contentViewWidth
                                       style:(UITableViewStyle)style
                              showsAccessory:(BOOL)showsAccessory {
    CGFloat labelWidth = contentViewWidth;

    // Content view inset due to accessory view observed on iOS 8.1 iPhone 6.
    if (showsAccessory) {
        labelWidth -= 34.0;
    }

    UIEdgeInsets labelInsets = [self labelInsets];
    labelWidth -= (labelInsets.left + labelInsets.right);

    CGSize constrainSize = CGSizeMake(labelWidth, CGFLOAT_MAX);
    CGRect boundingBox = [attributedText
        boundingRectWithSize:constrainSize
        options:NSStringDrawingUsesLineFragmentOrigin
        context:nil
    ];
    CGFloat preferredLabelHeight = FLEXFloor(boundingBox.size.height);
    CGFloat preferredCellHeight = preferredLabelHeight + labelInsets.top + labelInsets.bottom + 1.0;

    return preferredCellHeight;
}

@end


@implementation FLEXMultilineDetailTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}

@end
