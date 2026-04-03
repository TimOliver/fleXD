//
//  FLEXExplorerToolbar.m
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
#import "FLEXExplorerToolbar.h"
#import "FLEXExplorerToolbarItem.h"
#import "FLEXResources.h"
#import "FLEXUtility.h"

@interface FLEXExplorerToolbar ()

@property (nonatomic, readwrite) FLEXExplorerToolbarItem *globalsItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *hierarchyItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *selectItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *recentItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *moveItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *closeItem;
@property (nonatomic) UIView *selectedViewDescriptionContainer;
@property (nonatomic) UIView *selectedViewDescriptionSafeAreaContainer;
@property (nonatomic) UIView *selectedViewColorIndicator;
@property (nonatomic) UILabel *selectedViewDescriptionLabel;

@property (nonatomic,readwrite) UIView *backgroundView;

@end

@implementation FLEXExplorerToolbar

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Background
        UIVisualEffect *effect;
        if (@available(iOS 26.0, *)) {
            UIGlassEffect *const glassEffect = [UIGlassEffect effectWithStyle:UIGlassEffectStyleRegular];
            glassEffect.tintColor = [[UIColor secondarySystemBackgroundColor] colorWithAlphaComponent:0.5f];
            effect = glassEffect;
        } else {
            effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial];
        }
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        effectView.layer.cornerRadius = 16.0;
        effectView.clipsToBounds = YES;
        self.backgroundView = effectView;
        [self addSubview:self.backgroundView];

        // Buttons
        UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration
            configurationWithPointSize:22 weight:UIImageSymbolWeightMedium
        ];
        self.globalsItem   = [FLEXExplorerToolbarItem itemWithTitle:@"Menu" image:
            [UIImage systemImageNamed:@"switch.2" withConfiguration:symbolConfig]];
        self.hierarchyItem = [FLEXExplorerToolbarItem itemWithTitle:@"Views" image:
            [UIImage systemImageNamed:@"square.stack.3d.up.fill" withConfiguration:symbolConfig]];
        self.selectItem    = [FLEXExplorerToolbarItem itemWithTitle:@"Select" image:
            [UIImage systemImageNamed:@"hand.rays.fill" withConfiguration:symbolConfig]];
        self.recentItem    = [FLEXExplorerToolbarItem itemWithTitle:@"Recent" image:
            [UIImage systemImageNamed:@"clock.arrow.circlepath" withConfiguration:symbolConfig]];
        self.moveItem      = [FLEXExplorerToolbarItem itemWithTitle:@"Move" image:
            [UIImage systemImageNamed:@"arrow.up.and.down.and.arrow.left.and.right" withConfiguration:symbolConfig]
            sibling:self.recentItem];
        self.closeItem     = [FLEXExplorerToolbarItem itemWithTitle:@"Close" image:
            [UIImage systemImageNamed:@"xmark" withConfiguration:symbolConfig]];

        // Selected view box //

        UIVisualEffectView *descriptionEffectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        descriptionEffectView.layer.cornerRadius = 16.0;
        descriptionEffectView.clipsToBounds = YES;
        descriptionEffectView.hidden = YES;
        self.selectedViewDescriptionContainer = descriptionEffectView;
        [self addSubview:self.selectedViewDescriptionContainer];

        self.selectedViewDescriptionSafeAreaContainer = [UIView new];
        self.selectedViewDescriptionSafeAreaContainer.backgroundColor = UIColor.clearColor;
        [descriptionEffectView.contentView addSubview:self.selectedViewDescriptionSafeAreaContainer];

        self.selectedViewColorIndicator = [UIView new];
        self.selectedViewColorIndicator.backgroundColor = UIColor.redColor;
        [self.selectedViewDescriptionSafeAreaContainer addSubview:self.selectedViewColorIndicator];

        self.selectedViewDescriptionLabel = [UILabel new];
        self.selectedViewDescriptionLabel.backgroundColor = UIColor.clearColor;
        self.selectedViewDescriptionLabel.font = [[self class] descriptionLabelFont];
        [self.selectedViewDescriptionSafeAreaContainer addSubview:self.selectedViewDescriptionLabel];

        // toolbarItems
        self.toolbarItems = @[_globalsItem, _hierarchyItem, _selectItem, _moveItem, _closeItem];
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    const CGFloat kToolbarItemHeight = [[self class] toolbarItemHeight];

    // Toolbar Items — distribute evenly across full width
    CGFloat originX = 0;
    CGFloat height = kToolbarItemHeight;
    CGFloat width = FLEXFloor(CGRectGetWidth(self.bounds) / self.toolbarItems.count);
    for (FLEXExplorerToolbarItem *toolbarItem in self.toolbarItems) {
        toolbarItem.currentItem.frame = CGRectMake(originX, 0, width, height);
        originX = CGRectGetMaxX(toolbarItem.currentItem.frame);
    }

    // Make sure the last toolbar item goes to the edge to account for any accumulated rounding effects.
    UIView *lastToolbarItem = self.toolbarItems.lastObject.currentItem;
    CGRect lastToolbarItemFrame = lastToolbarItem.frame;
    lastToolbarItemFrame.size.width = CGRectGetWidth(self.bounds) - lastToolbarItemFrame.origin.x;
    lastToolbarItem.frame = lastToolbarItemFrame;

    self.backgroundView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), kToolbarItemHeight);

    const CGFloat kSelectedViewColorDiameter = [[self class] selectedViewColorIndicatorDiameter];
    const CGFloat kDescriptionLabelHeight = [[self class] descriptionLabelHeight];
    const CGFloat kHorizontalPadding = [[self class] horizontalPadding];
    const CGFloat kDescriptionVerticalPadding = [[self class] descriptionVerticalPadding];
    const CGFloat kDescriptionContainerHeight = [[self class] descriptionContainerHeight];

    CGRect descriptionContainerFrame = CGRectZero;
    descriptionContainerFrame.size.width = CGRectGetWidth(self.bounds);
    descriptionContainerFrame.size.height = kDescriptionContainerHeight;
    descriptionContainerFrame.origin.x = 0;
    descriptionContainerFrame.origin.y = CGRectGetMaxY(self.bounds) - kDescriptionContainerHeight;
    self.selectedViewDescriptionContainer.frame = descriptionContainerFrame;

    self.selectedViewDescriptionSafeAreaContainer.frame = self.selectedViewDescriptionContainer.bounds;

    // Selected View Color
    CGRect selectedViewColorFrame = CGRectZero;
    selectedViewColorFrame.size.width = kSelectedViewColorDiameter;
    selectedViewColorFrame.size.height = kSelectedViewColorDiameter;
    selectedViewColorFrame.origin.x = kHorizontalPadding;
    selectedViewColorFrame.origin.y = FLEXFloor((kDescriptionContainerHeight - kSelectedViewColorDiameter) / 2.0);
    self.selectedViewColorIndicator.frame = selectedViewColorFrame;
    self.selectedViewColorIndicator.layer.cornerRadius = ceil(selectedViewColorFrame.size.height / 2.0);

    // Selected View Description
    CGRect descriptionLabelFrame = CGRectZero;
    CGFloat descriptionOriginX = CGRectGetMaxX(selectedViewColorFrame) + kHorizontalPadding;
    descriptionLabelFrame.size.height = kDescriptionLabelHeight;
    descriptionLabelFrame.origin.x = descriptionOriginX;
    descriptionLabelFrame.origin.y = kDescriptionVerticalPadding;
    descriptionLabelFrame.size.width = CGRectGetMaxX(self.selectedViewDescriptionContainer.bounds) - kHorizontalPadding - descriptionOriginX;
    self.selectedViewDescriptionLabel.frame = descriptionLabelFrame;
}


#pragma mark - Setter Overrides

- (void)setToolbarItems:(NSArray<FLEXExplorerToolbarItem *> *)toolbarItems {
    if (_toolbarItems == toolbarItems) {
        return;
    }

    // Remove old toolbar items, if any
    for (FLEXExplorerToolbarItem *item in _toolbarItems) {
        [item.currentItem removeFromSuperview];
    }

    // Trim to 5 items if necessary
    if (toolbarItems.count > 5) {
        toolbarItems = [toolbarItems subarrayWithRange:NSMakeRange(0, 5)];
    }

    for (FLEXExplorerToolbarItem *item in toolbarItems) {
        [self addSubview:item.currentItem];
    }

    _toolbarItems = toolbarItems.copy;

    // Lay out new items
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setSelectedViewOverlayColor:(UIColor *)selectedViewOverlayColor {
    if (![_selectedViewOverlayColor isEqual:selectedViewOverlayColor]) {
        _selectedViewOverlayColor = selectedViewOverlayColor;
        self.selectedViewColorIndicator.backgroundColor = selectedViewOverlayColor;
    }
}

- (void)setSelectedViewDescription:(NSString *)selectedViewDescription {
    if (![_selectedViewDescription isEqual:selectedViewDescription]) {
        _selectedViewDescription = selectedViewDescription;
        self.selectedViewDescriptionLabel.text = selectedViewDescription;
        BOOL showDescription = selectedViewDescription.length > 0;
        self.selectedViewDescriptionContainer.hidden = !showDescription;
    }
}

- (UIView *)dragHandle {
    return self;
}


#pragma mark - Sizing Convenience Methods

+ (UIFont *)descriptionLabelFont {
    return [UIFont systemFontOfSize:12.0];
}

+ (CGFloat)toolbarItemHeight {
    return 56.0;
}

+ (CGFloat)maximumWidth {
    return 375.0;
}

+ (CGFloat)descriptionLabelHeight {
    return ceil([[self descriptionLabelFont] lineHeight]);
}

+ (CGFloat)descriptionVerticalPadding {
    return 2.0;
}

+ (CGFloat)descriptionContainerHeight {
    return [self descriptionVerticalPadding] * 2.0 + [self descriptionLabelHeight];
}

+ (CGFloat)selectedViewColorIndicatorDiameter {
    return ceil([self descriptionLabelHeight] / 2.0);
}

+ (CGFloat)horizontalPadding {
    return 11.0;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat height = 0.0;
    height += [[self class] toolbarItemHeight];
    height += [[self class] descriptionContainerHeight];
    CGFloat width = MIN(size.width, [[self class] maximumWidth]);
    return CGSizeMake(width, height);
}

@end
