//
//  FLEXFileBrowserCell.m
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

#import "FLEXFileBrowserCell.h"
#import "FLEXColor.h"

static const CGFloat kFLEXFileCellIconLeftInset = 16.0;
static const CGFloat kFLEXFileCellIconSize = 40.0;
static const CGFloat kFLEXFileCellIconTextGap = 12.0;
static const CGFloat kFLEXFileCellThumbnailCornerRadius = 6.0;

@interface FLEXFileBrowserCell ()
@property (nonatomic, readwrite) UIImageView *iconImageView;
@property (nonatomic, readwrite) UILabel *titleLabel;
@property (nonatomic, readwrite) UILabel *subtitleLabel;
@end

@implementation FLEXFileBrowserCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self flex_setUpSubviews];
    }
    return self;
}

- (void)flex_setUpSubviews {
    self.iconImageView = [UIImageView new];
    self.iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconImageView.clipsToBounds = YES;
    [self.contentView addSubview:self.iconImageView];

    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.titleLabel.textColor = FLEXColor.primaryTextColor;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.titleLabel.numberOfLines = 1;

    self.subtitleLabel = [UILabel new];
    self.subtitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.subtitleLabel.textColor = FLEXColor.deemphasizedTextColor;
    self.subtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.subtitleLabel.numberOfLines = 1;

    UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.titleLabel, self.subtitleLabel
    ]];
    textStack.axis = UILayoutConstraintAxisVertical;
    textStack.alignment = UIStackViewAlignmentFill;
    textStack.spacing = 2.0;
    textStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:textStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.iconImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor
                                                         constant:kFLEXFileCellIconLeftInset],
        [self.iconImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.iconImageView.widthAnchor constraintEqualToConstant:kFLEXFileCellIconSize],
        [self.iconImageView.heightAnchor constraintEqualToConstant:kFLEXFileCellIconSize],

        [textStack.leadingAnchor constraintEqualToAnchor:self.iconImageView.trailingAnchor
                                                constant:kFLEXFileCellIconTextGap],
        [textStack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8.0],
        [textStack.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [textStack.topAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.topAnchor constant:8.0],
        [textStack.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-8.0],
    ]];

    // Align the separator with the title's leading edge.
    self.separatorInset = UIEdgeInsetsMake(
        0, kFLEXFileCellIconLeftInset + kFLEXFileCellIconSize + kFLEXFileCellIconTextGap, 0, 0
    );
    self.preservesSuperviewLayoutMargins = NO;
}

- (void)setSymbolIcon:(UIImage *)image tintColor:(UIColor *)tintColor {
    self.iconImageView.layer.cornerRadius = 0.0;
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconImageView.tintColor = tintColor;
    self.iconImageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)setThumbnail:(UIImage *)image {
    self.iconImageView.layer.cornerRadius = kFLEXFileCellThumbnailCornerRadius;
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.iconImageView.image = image;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.representedPath = nil;
    self.iconImageView.image = nil;
    self.iconImageView.layer.cornerRadius = 0.0;
    self.titleLabel.text = nil;
    self.subtitleLabel.text = nil;
}

@end
