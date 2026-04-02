//
//  FLEXArgumentInputView.m
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

#import "FLEXArgumentInputView.h"
#import "FLEXUtility.h"
#import "FLEXColor.h"

@interface FLEXArgumentInputView ()

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) NSString *typeEncoding;

@end

@implementation FLEXArgumentInputView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.typeEncoding = typeEncoding != NULL ? @(typeEncoding) : nil;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (self.showsTitle) {
        CGSize constrainSize = CGSizeMake(self.bounds.size.width, CGFLOAT_MAX);
        CGSize labelSize = [self.titleLabel sizeThatFits:constrainSize];
        self.titleLabel.frame = CGRectMake(0, 0, labelSize.width, labelSize.height);
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    self.titleLabel.backgroundColor = backgroundColor;
}

- (void)setTitle:(NSString *)title {
    if (![_title isEqual:title]) {
        _title = title;
        self.titleLabel.text = title;
        [self setNeedsLayout];
    }
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [[self class] titleFont];
        _titleLabel.textColor = FLEXColor.primaryTextColor;
        _titleLabel.numberOfLines = 0;
        [self addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (BOOL)showsTitle {
    return self.title.length > 0;
}

- (CGFloat)topInputFieldVerticalLayoutGuide {
    CGFloat verticalLayoutGuide = 0;
    if (self.showsTitle) {
        CGFloat titleHeight = [self.titleLabel sizeThatFits:self.bounds.size].height;
        verticalLayoutGuide = titleHeight + [[self class] titleBottomPadding];
    }
    return verticalLayoutGuide;
}


#pragma mark - Subclasses Can Override

- (BOOL)inputViewIsFirstResponder {
    return NO;
}

+ (BOOL)supportsObjCType:(const char *)type withCurrentValue:(id)value {
    return NO;
}


#pragma mark - Class Helpers

+ (UIFont *)titleFont {
    return [UIFont systemFontOfSize:12.0];
}

+ (CGFloat)titleBottomPadding {
    return 4.0;
}


#pragma mark - Sizing

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat height = 0;

    if (self.title.length > 0) {
        CGSize constrainSize = CGSizeMake(size.width, CGFLOAT_MAX);
        height += ceil([self.titleLabel sizeThatFits:constrainSize].height);
        height += [[self class] titleBottomPadding];
    }

    return CGSizeMake(size.width, height);
}

@end
