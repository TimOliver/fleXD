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
#import "UIView+FLEX_Layout.h"

@interface FLEXCarouselCell ()
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UIView *selectionIndicatorStripe;
@property (nonatomic) BOOL constraintsInstalled;
@end

@implementation FLEXCarouselCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _titleLabel = [UILabel new];
        _selectionIndicatorStripe = [UIView new];

        self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        self.selectionIndicatorStripe.backgroundColor = self.tintColor;
        self.titleLabel.adjustsFontForContentSizeCategory = YES;

        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.selectionIndicatorStripe];

        [self installConstraints];

        [self updateAppearance];
    }

    return self;
}

- (void)updateAppearance {
    self.selectionIndicatorStripe.hidden = !self.selected;

    if (self.selected) {
        self.titleLabel.textColor = self.tintColor;
    } else {
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

- (void)installConstraints {
    CGFloat stripeHeight = 2;

    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectionIndicatorStripe.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *superview = self.contentView;
    [self.titleLabel flex_pinEdgesToSuperviewWithInsets:UIEdgeInsetsMake(10, 15, 8 + stripeHeight, 15)];

    [self.selectionIndicatorStripe.leadingAnchor constraintEqualToAnchor:superview.leadingAnchor].active = YES;
    [self.selectionIndicatorStripe.bottomAnchor constraintEqualToAnchor:superview.bottomAnchor].active = YES;
    [self.selectionIndicatorStripe.trailingAnchor constraintEqualToAnchor:superview.trailingAnchor].active = YES;
    [self.selectionIndicatorStripe.heightAnchor constraintEqualToConstant:stripeHeight].active = YES;
}

- (void)setSelected:(BOOL)selected {
    super.selected = selected;
    [self updateAppearance];
}

@end
