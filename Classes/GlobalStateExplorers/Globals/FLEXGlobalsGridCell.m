//
//  FLEXGlobalsGridCell.m
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

#import "FLEXGlobalsGridCell.h"
#import "FLEXGlobalsEntry.h"

NSString * const kFLEXGlobalsGridCellIdentifier = @"FLEXGlobalsGridCell";

/// Returns a deterministic color from the palette for the given name.
static UIColor *FLEXGridColorForName(NSString *name) {
    static NSArray<UIColor *> *palette;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        palette = @[
            [UIColor systemBlueColor],
            [UIColor systemGreenColor],
            [UIColor systemOrangeColor],
            [UIColor systemPurpleColor],
            [UIColor systemRedColor],
            [UIColor systemTealColor],
            [UIColor systemIndigoColor],
            [UIColor systemPinkColor],
        ];
    });
    return palette[name.hash % palette.count];
}

@interface FLEXGlobalsGridCell ()
@property (nonatomic) UIStackView *stackView;
@property (nonatomic, copy) void(^onItemTapped)(NSInteger itemIndex);
@end

@implementation FLEXGlobalsGridCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _stackView = [[UIStackView alloc] init];
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.distribution = UIStackViewDistributionFillEqually;
        _stackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_stackView];

        [NSLayoutConstraint activateConstraints:@[
            [_stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
            [_stackView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-12],
            [_stackView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [_stackView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        ]];
    }
    return self;
}

- (void)configureWithEntries:(NSArray<FLEXGlobalsEntry *> *)entries
                 itemsPerRow:(NSInteger)itemsPerRow
               onItemTapped:(void(^)(NSInteger))onItemTapped {
    self.onItemTapped = onItemTapped;

    // Clear existing arranged subviews
    for (UIView *view in self.stackView.arrangedSubviews) {
        [self.stackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }

    for (NSInteger i = 0; i < itemsPerRow; i++) {
        if (i < (NSInteger)entries.count) {
            [self.stackView addArrangedSubview:[self itemViewForEntry:entries[i] index:i]];
        } else {
            // Empty placeholder to preserve equal column widths on partial rows
            [self.stackView addArrangedSubview:[UIView new]];
        }
    }
}

#pragma mark - Private

- (UIView *)itemViewForEntry:(FLEXGlobalsEntry *)entry index:(NSInteger)index {
    NSString *name = entry.entryNameFuture();

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = index;
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn addTarget:self action:@selector(itemTapped:)
          forControlEvents:UIControlEventTouchUpInside];
    [btn addTarget:self action:@selector(itemTouchDown:)
          forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [btn addTarget:self action:@selector(itemTouchUp:)
          forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside
                         | UIControlEventTouchCancel | UIControlEventTouchDragExit];

    // Colored rounded square icon
    UIView *iconView = [UIView new];
    iconView.backgroundColor = FLEXGridColorForName(name);
    iconView.layer.cornerRadius = 13;
    iconView.layer.cornerCurve = kCACornerCurveContinuous;
    iconView.userInteractionEnabled = NO;
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [btn addSubview:iconView];

    // Title label below icon
    UILabel *label = [UILabel new];
    label.text = name;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    label.numberOfLines = 2;
    label.textColor = UIColor.labelColor;
    label.userInteractionEnabled = NO;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [btn addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        // Icon: fixed 52×52, centered horizontally, pinned to top
        [iconView.centerXAnchor constraintEqualToAnchor:btn.centerXAnchor],
        [iconView.topAnchor constraintEqualToAnchor:btn.topAnchor constant:8],
        [iconView.widthAnchor constraintEqualToConstant:52],
        [iconView.heightAnchor constraintEqualToConstant:52],

        // Label: below icon, leading/trailing inset, pinned to bottom
        [label.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:6],
        [label.leadingAnchor constraintEqualToAnchor:btn.leadingAnchor constant:4],
        [label.trailingAnchor constraintEqualToAnchor:btn.trailingAnchor constant:-4],
        [label.bottomAnchor constraintEqualToAnchor:btn.bottomAnchor constant:-8],
    ]];

    return btn;
}

#pragma mark - Button actions

- (void)itemTapped:(UIButton *)sender {
    if (self.onItemTapped) {
        self.onItemTapped(sender.tag);
    }
}

- (void)itemTouchDown:(UIButton *)sender {
    [UIView animateWithDuration:0.1 animations:^{
        sender.alpha = 0.55;
    }];
}

- (void)itemTouchUp:(UIButton *)sender {
    [UIView animateWithDuration:0.15 animations:^{
        sender.alpha = 1.0;
    }];
}

@end
