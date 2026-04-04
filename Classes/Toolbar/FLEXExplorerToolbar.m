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
@property (nonatomic, readwrite) UIButton *closeButton;
@property (nonatomic) UIVisualEffectView *closeCircle;
@property (nonatomic) UIView *separatorView;
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
        self.clipsToBounds = NO;

        // Background
        UIVisualEffect *effect;
        if (@available(iOS 26.0, *)) {
            UIGlassEffect *const glassEffect = [UIGlassEffect effectWithStyle:UIGlassEffectStyleRegular];
            glassEffect.tintColor = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
                const BOOL isDark = traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
                return [UIColor colorWithWhite:isDark ? 1.0f : 0.0f alpha:0.1f];
            }];
            effect = glassEffect;
        } else {
            effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
        }
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        effectView.layer.cornerRadius = 24.0;
        effectView.clipsToBounds = YES;
        self.backgroundView = effectView;
        [self addSubview:self.backgroundView];

        // Buttons
        UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration
            configurationWithPointSize:21 weight:UIImageSymbolWeightMedium
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
        
        // Close button — floating circle over the top-right corner
        // The visual circle is 20x20, but the tap target is 44x44
        const CGFloat kCloseVisualSize = 20.0;
        const CGFloat kCloseHitSize = 44.0;
        UIImageSymbolConfiguration *closeConfig = [UIImageSymbolConfiguration
            configurationWithPointSize:9 weight:UIImageSymbolWeightBold
        ];
        UIImage *closeImage = [UIImage systemImageNamed:@"xmark" withConfiguration:closeConfig];
        self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.closeButton.frame = CGRectMake(0, 0, kCloseHitSize, kCloseHitSize);
        self.closeButton.tintColor = UIColor.labelColor;
        [self.closeButton setImage:closeImage forState:UIControlStateNormal];

        self.closeCircle = [[UIVisualEffectView alloc] initWithEffect:effect];
        self.closeCircle.layer.cornerRadius = kCloseVisualSize / 2.0;
        self.closeCircle.clipsToBounds = YES;
        self.closeCircle.layer.borderWidth = 0.5;
        self.closeCircle.layer.borderColor = [UIColor.separatorColor CGColor];
        self.closeCircle.userInteractionEnabled = NO;
        self.closeCircle.frame = CGRectMake(
            (kCloseHitSize - kCloseVisualSize) / 2.0,
            (kCloseHitSize - kCloseVisualSize) / 2.0,
            kCloseVisualSize, kCloseVisualSize
        );
        [self.closeButton insertSubview:self.closeCircle belowSubview:self.closeButton.imageView];

        [self addSubview:self.closeButton];

        // Selected view box //

        self.selectedViewDescriptionContainer = [UIView new];
        self.selectedViewDescriptionContainer.backgroundColor = UIColor.systemFillColor;
        self.selectedViewDescriptionContainer.hidden = YES;
        [self addSubview:self.selectedViewDescriptionContainer];

        self.selectedViewDescriptionSafeAreaContainer = [UIView new];
        self.selectedViewDescriptionSafeAreaContainer.backgroundColor = UIColor.clearColor;
        [self.selectedViewDescriptionContainer addSubview:self.selectedViewDescriptionSafeAreaContainer];

        self.selectedViewColorIndicator = [UIView new];
        self.selectedViewColorIndicator.backgroundColor = UIColor.redColor;
        [self.selectedViewDescriptionSafeAreaContainer addSubview:self.selectedViewColorIndicator];

        self.selectedViewDescriptionLabel = [UILabel new];
        self.selectedViewDescriptionLabel.backgroundColor = UIColor.clearColor;
        self.selectedViewDescriptionLabel.font = [[self class] descriptionLabelFont];
        [self.selectedViewDescriptionSafeAreaContainer addSubview:self.selectedViewDescriptionLabel];

        // toolbarItems
        self.toolbarItems = @[_hierarchyItem, _selectItem, _moveItem, _globalsItem];

        // Separator line between action buttons and the menu button
        _separatorView = [UIView new];
        _separatorView.backgroundColor = UIColor.separatorColor;
        [self addSubview:_separatorView];
    }

    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if ([super pointInside:point withEvent:event]) {
        return YES;
    }
    // Allow touches on the close button even though it overhangs our bounds
    CGPoint closePoint = [self convertPoint:point toView:self.closeButton];
    return [self.closeButton pointInside:closePoint withEvent:event];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        self.closeCircle.layer.borderColor = [UIColor.separatorColor CGColor];
        self.separatorView.backgroundColor = UIColor.separatorColor;
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // Prioritize the close button over everything else
    CGPoint closePoint = [self.closeButton convertPoint:point fromView:self];
    if ([self.closeButton pointInside:closePoint withEvent:event]) {
        return self.closeButton;
    }
    return [super hitTest:point withEvent:event];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    const CGFloat kToolbarItemHeight = [[self class] toolbarItemHeight];
    const CGFloat kRightMargin = 10.0;
    const CGFloat kSeparatorWidth = 1.0;

    // The last item is the menu button, separated from the rest
    NSArray<FLEXExplorerToolbarItem *> *leftItems = [self.toolbarItems subarrayWithRange:
        NSMakeRange(0, self.toolbarItems.count - 1)
    ];
    FLEXExplorerToolbarItem *menuItem = self.toolbarItems.lastObject;

    // All items get the same width; center the whole group horizontally
    CGFloat itemWidth = FLEXFloor((CGRectGetWidth(self.bounds) - kRightMargin) / self.toolbarItems.count);
    CGFloat contentWidth = itemWidth * self.toolbarItems.count + kSeparatorWidth;
    CGFloat leftInset = FLEXFloor((CGRectGetWidth(self.bounds) - contentWidth) / 2.0);

    // Left items
    CGFloat originX = leftInset;
    for (FLEXExplorerToolbarItem *toolbarItem in leftItems) {
        toolbarItem.currentItem.frame = CGRectMake(originX, 0, itemWidth, kToolbarItemHeight);
        originX = CGRectGetMaxX(toolbarItem.currentItem.frame);
    }

    // Separator
    CGFloat separatorX = originX;

    // Menu button — same width as the others
    menuItem.currentItem.frame = CGRectMake(separatorX + kSeparatorWidth, 0, itemWidth, kToolbarItemHeight);

    // Separator between left items and menu button
    CGFloat separatorHeight = kToolbarItemHeight * 0.7f;
    CGFloat separatorY = FLEXFloor((kToolbarItemHeight - separatorHeight) / 2.0);
    self.separatorView.frame = CGRectMake(separatorX, separatorY, kSeparatorWidth, separatorHeight);

    BOOL showingDescription = !self.selectedViewDescriptionContainer.hidden;
    CGFloat totalHeight = showingDescription
        ? kToolbarItemHeight + [[self class] descriptionContainerHeight]
        : kToolbarItemHeight;
    self.backgroundView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), totalHeight);

    // Close button — visual circle is centered within the 44x44 hit area
    // Position so the visual 20x20 circle sits over the top-right corner
    CGFloat hitSize = self.closeButton.bounds.size.width;
    CGFloat visualOffset = 20.0 / 3.0 - 1.0; // offset of the visual circle from the corner, inset 1pt
    CGFloat hitOffset = (hitSize - 20.0) / 2.0; // offset from visual center to hit area edge
    self.closeButton.frame = CGRectMake(
        CGRectGetWidth(self.bounds) - 20.0 + visualOffset - hitOffset,
        -visualOffset - hitOffset,
        hitSize, hitSize
    );

    const CGFloat kSelectedViewColorDiameter = [[self class] selectedViewColorIndicatorDiameter];
    const CGFloat kDescriptionLabelHeight = [[self class] descriptionLabelHeight];
    const CGFloat kHorizontalPadding = [[self class] horizontalPadding];
    const CGFloat kDescriptionVerticalPadding = [[self class] descriptionVerticalPadding];
    const CGFloat kDescriptionContainerHeight = [[self class] descriptionContainerHeight];

    CGRect descriptionContainerFrame = CGRectZero;
    descriptionContainerFrame.size.width = CGRectGetWidth(self.bounds);
    descriptionContainerFrame.size.height = kDescriptionContainerHeight;
    descriptionContainerFrame.origin.x = 0;
    descriptionContainerFrame.origin.y = kToolbarItemHeight;
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

        // Resize the toolbar to include/exclude the description area
        CGSize newSize = [self sizeThatFits:CGSizeMake(self.bounds.size.width, CGFLOAT_MAX)];
        CGRect frame = self.frame;
        frame.size.height = newSize.height;
        self.frame = frame;
        [self setNeedsLayout];
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
    return 61.0;
}

+ (CGFloat)maximumWidth {
    return 300.0;
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
    CGFloat height = [[self class] toolbarItemHeight];
    if (!self.selectedViewDescriptionContainer.hidden) {
        height += [[self class] descriptionContainerHeight];
    }
    CGFloat width = MIN(size.width, [[self class] maximumWidth]);
    return CGSizeMake(width, height);
}

@end
