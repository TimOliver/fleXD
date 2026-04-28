//
//  FLEXImagePreviewTitleView.m
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

#import "FLEXImagePreviewTitleView.h"
#import <QuartzCore/QuartzCore.h>

@implementation FLEXImagePreviewTitleView {
    UIVisualEffectView *_capsuleView;
    UILabel *_titleLabel;
}

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.clipsToBounds = NO;

        UIVisualEffect *effect;
        if (@available(iOS 26.0, *)) {
            UIGlassEffect *const glassEffect = [UIGlassEffect effectWithStyle:UIGlassEffectStyleRegular];
            glassEffect.tintColor = [UIColor colorWithWhite:1.0f alpha:0.08f];
            effect = glassEffect;
        } else {
            effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark];
        }

        _capsuleView = [[UIVisualEffectView alloc] initWithEffect:effect];
        _capsuleView.translatesAutoresizingMaskIntoConstraints = NO;
        _capsuleView.clipsToBounds = YES;
        _capsuleView.layer.cornerRadius = 20.0;
        _capsuleView.layer.cornerCurve = kCACornerCurveContinuous;
        _capsuleView.layer.borderWidth = 0.5;
        _capsuleView.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.24f].CGColor;
        [self addSubview:_capsuleView];

        _titleLabel = [UILabel new];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.text = title;
        UIFont *titleFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _titleLabel.font = [UIFont systemFontOfSize:titleFont.pointSize + 1.0 weight:UIFontWeightSemibold];
        _titleLabel.adjustsFontForContentSizeCategory = YES;
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        [_capsuleView.contentView addSubview:_titleLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_capsuleView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_capsuleView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_capsuleView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_capsuleView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

            [_titleLabel.topAnchor constraintEqualToAnchor:_capsuleView.contentView.topAnchor constant:9.0],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:_capsuleView.contentView.leadingAnchor constant:18.0],
            [_titleLabel.trailingAnchor constraintEqualToAnchor:_capsuleView.contentView.trailingAnchor constant:-18.0],
            [_titleLabel.bottomAnchor constraintEqualToAnchor:_capsuleView.contentView.bottomAnchor constant:-9.0],
            [_titleLabel.widthAnchor constraintLessThanOrEqualToConstant:240.0],
        ]];

        self.accessibilityLabel = title;
        self.isAccessibilityElement = YES;
    }

    return self;
}

- (CGSize)intrinsicContentSize {
    CGSize titleSize = [_titleLabel sizeThatFits:CGSizeMake(240.0, CGFLOAT_MAX)];
    return CGSizeMake(ceil(MIN(titleSize.width, 240.0) + 36.0), 40.0);
}

@end
