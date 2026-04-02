//
//  FLEXDBQueryRowCell.m
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

#import "FLEXDBQueryRowCell.h"
#import "FLEXMultiColumnTableView.h"
#import "NSArray+FLEX.h"
#import "UIFont+FLEX.h"
#import "FLEXColor.h"

NSString * const kFLEXDBQueryRowCellReuse = @"kFLEXDBQueryRowCellReuse";

@interface FLEXDBQueryRowCell ()
@property (nonatomic) NSInteger columnCount;
@property (nonatomic) NSArray<UILabel *> *labels;
@end

@implementation FLEXDBQueryRowCell

- (void)setData:(NSArray *)data {
    _data = data;
    self.columnCount = data.count;

    [self.labels flex_forEach:^(UILabel *label, NSUInteger idx) {
        id content = self.data[idx];

        if ([content isKindOfClass:[NSString class]]) {
            label.text = content;
        } else if (content == NSNull.null) {
            label.text = @"<null>";
            label.textColor = FLEXColor.deemphasizedTextColor;
        } else {
            label.text = [content description];
        }
    }];
}

- (void)setColumnCount:(NSInteger)columnCount {
    if (columnCount != _columnCount) {
        _columnCount = columnCount;

        // Remove existing labels
        for (UILabel *l in self.labels) {
            [l removeFromSuperview];
        }

        // Create new labels
        self.labels = [NSArray flex_forEachUpTo:columnCount map:^id(NSUInteger i) {
            UILabel *label = [UILabel new];
            label.font = UIFont.flex_defaultTableCellFont;
            label.textAlignment = NSTextAlignmentLeft;
            [self.contentView addSubview:label];

            return label;
        }];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat height = self.contentView.frame.size.height;

    [self.labels flex_forEach:^(UILabel *label, NSUInteger i) {
        CGFloat width = [self.layoutSource dbQueryRowCell:self widthForColumn:i];
        CGFloat minX = [self.layoutSource dbQueryRowCell:self minXForColumn:i];
        label.frame = CGRectMake(minX + 5, 0, (width - 10), height);
    }];
}

@end
