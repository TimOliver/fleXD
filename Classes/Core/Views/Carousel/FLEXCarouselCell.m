//
//  FLEXCarouselCell.m
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

#import "FLEXCarouselCell.h"
#import "FLEXColor.h"

@interface FLEXCarouselCell ()
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UIView *pillBackgroundView;
@property (nonatomic, readonly) UIImageView *separatorIcon;
@property (nonatomic) BOOL constraintsInstalled;
@end

@implementation FLEXCarouselCell

static const CGFloat kPillInsetH = 14;
static const CGFloat kPillInsetV = 8;
static const CGFloat kSeparatorSpacing = 6;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _pillBackgroundView = [UIView new];
        _pillBackgroundView.clipsToBounds = YES;

        _titleLabel = [UILabel new];
        self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        self.titleLabel.adjustsFontForContentSizeCategory = YES;

        UIImageConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightSemibold];
        _separatorIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.left" withConfiguration:config]];
        _separatorIcon.contentMode = UIViewContentModeCenter;
        _separatorIcon.tintColor = FLEXColor.deemphasizedTextColor;
        _separatorIcon.hidden = YES;

        [self.contentView addSubview:self.pillBackgroundView];
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.separatorIcon];

        [self updateAppearance];
    }

    return self;
}

- (void)updateAppearance {
    if (self.selected) {
        self.pillBackgroundView.backgroundColor = FLEXColor.primaryTextColor;
        self.titleLabel.textColor = FLEXColor.primaryBackgroundColor;
    } else {
        self.pillBackgroundView.backgroundColor = FLEXColor.secondaryBackgroundColor;
        self.titleLabel.textColor = FLEXColor.deemphasizedTextColor;
    }
}

#pragma mark Public

- (NSString *)title {
    return self.titleLabel.text;
}

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
    [self.titleLabel sizeToFit];
    [self setNeedsLayout];
}

#pragma mark Overrides

- (void)prepareForReuse {
    [super prepareForReuse];
    [self updateAppearance];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = self.contentView.bounds;
    CGSize separatorSize = [self.separatorIcon sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    CGSize labelSize = [self.titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];

    CGFloat pillWidth = ceil(labelSize.width) + kPillInsetH * 2;
    CGFloat pillHeight = bounds.size.height;
    self.pillBackgroundView.frame = CGRectMake(0, 0, pillWidth, pillHeight);
    self.pillBackgroundView.layer.cornerRadius = pillHeight / 2.0;

    self.titleLabel.frame = CGRectMake(kPillInsetH, kPillInsetV, labelSize.width, labelSize.height);

    self.separatorIcon.frame = CGRectMake(pillWidth + 1.0, 0, bounds.size.width - pillWidth, pillHeight);
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize labelSize = [self.titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    CGFloat width = ceil(labelSize.width) + kPillInsetH * 2;
    if (!self.separatorIcon.hidden) {
        CGSize separatorSize = [self.separatorIcon sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        width += kSeparatorSpacing + ceil(separatorSize.width) + kSeparatorSpacing;
    }
    return CGSizeMake(width, ceil(labelSize.height) + kPillInsetV * 2);
}

- (void)setShowSeparator:(BOOL)showSeparator {
    self.separatorIcon.hidden = !showSeparator;
    [self setNeedsLayout];
    [self invalidateIntrinsicContentSize];
}

- (BOOL)showSeparator {
    return !self.separatorIcon.hidden;
}

- (void)setSelected:(BOOL)selected {
    super.selected = selected;
    [self updateAppearance];
}

@end
