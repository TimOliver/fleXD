//
//  FLEXGlobalsGridItemView.m
//
//  Copyright (c) FLEX Team (2020-2026).
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

#import "FLEXGlobalsGridItemView.h"

static const CGFloat kFLEXGridIconSize       = 64;
static const CGFloat kFLEXGridIconRadius     = 16;
static const CGFloat kFLEXGridIconLabelGap   = 6;
static const CGFloat kFLEXGridLabelInset     = 4;
static const CGFloat kFLEXGridMaxLabelHeight = 28;

@implementation FLEXGlobalsGridItemView

- (instancetype)init {
    self = [super init];
    if (self) {
        _iconView = [UIView new];
        _iconView.layer.cornerRadius = kFLEXGridIconRadius;
        _iconView.layer.cornerCurve = kCACornerCurveContinuous;
        _iconView.userInteractionEnabled = NO;
        [self addSubview:_iconView];

        _symbolImageView = [UIImageView new];
        _symbolImageView.contentMode = UIViewContentModeScaleAspectFit;
        _symbolImageView.tintColor = UIColor.whiteColor;
        _symbolImageView.userInteractionEnabled = NO;
        [_iconView addSubview:_symbolImageView];

        _titleLabel = [UILabel new];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        _titleLabel.numberOfLines = 2;
        _titleLabel.textColor = UIColor.labelColor;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.userInteractionEnabled = NO;
        [self addSubview:_titleLabel];
    }
    return self;
}

- (void)setSymbolName:(NSString *)symbolName {
    _symbolName = symbolName.copy;
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration
        configurationWithPointSize:44 weight:UIImageSymbolWeightMedium];
    _symbolImageView.image = symbolName
        ? [UIImage systemImageNamed:symbolName withConfiguration:config]
        : nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;

    CGFloat iconX = floor((width - kFLEXGridIconSize) / 2.0);
    self.iconView.frame = CGRectMake(iconX, 0.0, kFLEXGridIconSize, kFLEXGridIconSize);

    // Symbol image view centered inside the icon square
    CGFloat symbolSize = 44;
    CGFloat symbolOrigin = floor((kFLEXGridIconSize - symbolSize) / 2.0);
    self.symbolImageView.frame = CGRectMake(symbolOrigin, symbolOrigin, symbolSize, symbolSize);

    CGFloat labelY = CGRectGetMaxY(self.iconView.frame) + kFLEXGridIconLabelGap;
    CGSize maxLabelSize = (CGSize){width - kFLEXGridLabelInset * 2, kFLEXGridMaxLabelHeight};
    CGFloat labelHeight = [self.titleLabel sizeThatFits:maxLabelSize].height;
    self.titleLabel.frame = CGRectMake(
        kFLEXGridLabelInset,
        labelY,
        width - kFLEXGridLabelInset * 2,
        labelHeight
    );
}

- (CGSize)intrinsicContentSize {
    CGFloat height = kFLEXGridIconSize + kFLEXGridIconLabelGap + kFLEXGridMaxLabelHeight;
    return CGSizeMake(UIViewNoIntrinsicMetric, height);
}

@end
