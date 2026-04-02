//
//  FLEXTableContentHeaderCell.m
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

#import "FLEXTableColumnHeader.h"
#import "FLEXColor.h"
#import "UIFont+FLEX.h"
#import "FLEXUtility.h"

static const CGFloat kMargin = 5;
static const CGFloat kArrowWidth = 20;

@interface FLEXTableColumnHeader ()
@property (nonatomic, readonly) UILabel *arrowLabel;
@property (nonatomic, readonly) UIView *lineView;
@end

@implementation FLEXTableColumnHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = FLEXColor.secondaryBackgroundColor;

        _titleLabel = [UILabel new];
        _titleLabel.font = UIFont.flex_defaultTableCellFont;
        [self addSubview:_titleLabel];

        _arrowLabel = [UILabel new];
        _arrowLabel.font = UIFont.flex_defaultTableCellFont;
        [self addSubview:_arrowLabel];

        _lineView = [UIView new];
        _lineView.backgroundColor = FLEXColor.hairlineColor;
        [self addSubview:_lineView];

    }
    return self;
}

- (void)setSortType:(FLEXTableColumnHeaderSortType)type {
    _sortType = type;

    switch (type) {
        case FLEXTableColumnHeaderSortTypeNone:
            _arrowLabel.text = @"";
            break;
        case FLEXTableColumnHeaderSortTypeAsc:
            _arrowLabel.text = @"⬆️";
            break;
        case FLEXTableColumnHeaderSortTypeDesc:
            _arrowLabel.text = @"⬇️";
            break;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGSize size = self.frame.size;

    self.titleLabel.frame = CGRectMake(kMargin, 0, size.width - kArrowWidth - kMargin, size.height);
    self.arrowLabel.frame = CGRectMake(size.width - kArrowWidth, 0, kArrowWidth, size.height);
    self.lineView.frame = CGRectMake(size.width - 1, 2, FLEXPointsToPixels(1), size.height - 4);
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat margins = kArrowWidth - 2 * kMargin;
    size = CGSizeMake(size.width - margins, size.height);
    CGFloat width = [_titleLabel sizeThatFits:size].width + margins;
    return CGSizeMake(width, size.height);
}

@end
