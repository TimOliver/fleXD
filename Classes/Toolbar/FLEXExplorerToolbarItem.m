//
//  FLEXExplorerToolbarItem.m
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

#import "FLEXColor.h"
#import "FLEXExplorerToolbarItem.h"
#import "FLEXUtility.h"

@interface FLEXExplorerToolbarItem ()

@property (nonatomic) FLEXExplorerToolbarItem *sibling;
@property (nonatomic, copy) NSString *title;
@property (nonatomic) UIImage *image;

@property (nonatomic, readonly, class) UIColor *defaultBackgroundColor;
@property (nonatomic, readonly, class) UIColor *highlightedBackgroundColor;
@property (nonatomic, readonly, class) UIColor *selectedBackgroundColor;

@end

@implementation FLEXExplorerToolbarItem

#pragma mark - Public

+ (instancetype)itemWithTitle:(NSString *)title image:(UIImage *)image {
    return [self itemWithTitle:title image:image sibling:nil];
}

+ (instancetype)itemWithTitle:(NSString *)title image:(UIImage *)image sibling:(FLEXExplorerToolbarItem *)backupItem {
    NSParameterAssert(title); NSParameterAssert(image);

    FLEXExplorerToolbarItem *toolbarItem = [self buttonWithType:UIButtonTypeCustom];
    toolbarItem.sibling = backupItem;
    toolbarItem.title = title;
    toolbarItem.image = image;
    toolbarItem.tintColor = FLEXColor.iconColor;
    toolbarItem.backgroundColor = self.defaultBackgroundColor;
    toolbarItem.titleLabel.font = [UIFont boldSystemFontOfSize:11.0];
    [toolbarItem setTitle:title forState:UIControlStateNormal];
    [toolbarItem setImage:image forState:UIControlStateNormal];
    [toolbarItem setTitleColor:FLEXColor.primaryTextColor forState:UIControlStateNormal];
    [toolbarItem setTitleColor:FLEXColor.deemphasizedTextColor forState:UIControlStateDisabled];
    toolbarItem.layer.cornerCurve = kCACornerCurveContinuous;
    return toolbarItem;
}

- (FLEXExplorerToolbarItem *)currentItem {
    if (!self.enabled && self.sibling) {
        return self.sibling.currentItem;
    }

    return self;
}


#pragma mark - Display Defaults

+ (NSDictionary<NSString *, id> *)titleAttributes {
    return @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:11.0] };
}

+ (UIColor *)highlightedBackgroundColor {
    return FLEXColor.toolbarItemHighlightedColor;
}

+ (UIColor *)selectedBackgroundColor {
    return FLEXColor.secondaryFillColor;
}

+ (UIColor *)defaultBackgroundColor {
    return UIColor.clearColor;
}

+ (CGFloat)topMargin {
    return 2.0;
}


#pragma mark - State Changes

- (void)setHighlighted:(BOOL)highlighted {
    super.highlighted = highlighted;
    [self updateColors];
}

- (void)setSelected:(BOOL)selected {
    super.selected = selected;
    [self updateColors];
}

- (void)setEnabled:(BOOL)enabled {
    if (self.enabled != enabled) {
        if (self.sibling) {
            if (enabled) { // Replace sibling with myself
                UIView *superview = self.sibling.superview;
                [self.sibling removeFromSuperview];
                self.frame = self.sibling.frame;
                [superview addSubview:self];
            } else { // Replace myself with sibling
                UIView *superview = self.superview;
                [self removeFromSuperview];
                self.sibling.frame = self.frame;
                [superview addSubview:self.sibling];
            }
        }

        super.enabled = enabled;
    }
}

+ (id)_selectedIndicatorImage { return nil; }

- (void)updateColors {

    if (self.highlighted) {
        self.alpha = 0.4;
        self.backgroundColor = self.class.defaultBackgroundColor;
    }

    if (self.selected) {
        self.alpha = 1.0;
        self.backgroundColor = self.class.selectedBackgroundColor;
        self.layer.cornerRadius = 12.0f;
        self.layer.masksToBounds = YES;
    }

    if (self.selected || self.highlighted) { return; }
    self.alpha = 1.0;
    self.backgroundColor = self.class.defaultBackgroundColor;
    self.layer.masksToBounds = NO;
}


#pragma mark - UIButton Layout Overrides

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect contentRect = self.bounds;

    // Title: fixed distance from the bottom, so all labels align across buttons
    const CGFloat kBottomPadding = 3.0;
    const CGFloat kIconTextGap = 1.0;
    NSDictionary *attrs = [[self class] titleAttributes];
    CGSize titleSize = [self.title boundingRectWithSize:contentRect.size
                                               options:0
                                            attributes:attrs
                                               context:nil].size;
    titleSize = CGSizeMake(ceil(titleSize.width), ceil(titleSize.height));
    CGFloat titleY = CGRectGetMaxY(contentRect) - titleSize.height - kBottomPadding;
    CGFloat titleX = FLEXFloor((contentRect.size.width - titleSize.width) / 2.0);
    self.titleLabel.frame = CGRectMake(titleX, titleY, titleSize.width, titleSize.height);

    // Image: directly above the title
    CGSize imageSize = self.image.size;
    CGFloat imageY = titleY - imageSize.height - kIconTextGap;
    CGFloat imageX = FLEXFloor((contentRect.size.width - imageSize.width) / 2.0);
    self.imageView.frame = CGRectMake(imageX, imageY, imageSize.width, imageSize.height);
}

@end
