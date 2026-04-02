//
//  FLEXArgumentInputFontView.m
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

#import "FLEXArgumentInputFontView.h"
#import "FLEXArgumentInputViewFactory.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXArgumentInputFontsPickerView.h"

@interface FLEXArgumentInputFontView ()

@property (nonatomic) FLEXArgumentInputView *fontNameInput;
@property (nonatomic) FLEXArgumentInputView *pointSizeInput;

@end

@implementation FLEXArgumentInputFontView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding {
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        self.fontNameInput = [[FLEXArgumentInputFontsPickerView alloc] initWithArgumentTypeEncoding:FLEXEncodeClass(NSString)];
        self.fontNameInput.targetSize = FLEXArgumentInputViewSizeSmall;
        self.fontNameInput.title = @"Font Name:";
        [self addSubview:self.fontNameInput];

        self.pointSizeInput = [FLEXArgumentInputViewFactory argumentInputViewForTypeEncoding:@encode(CGFloat)];
        self.pointSizeInput.targetSize = FLEXArgumentInputViewSizeSmall;
        self.pointSizeInput.title = @"Point Size:";
        [self addSubview:self.pointSizeInput];
    }
    return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    self.fontNameInput.backgroundColor = backgroundColor;
    self.pointSizeInput.backgroundColor = backgroundColor;
}

- (void)setInputValue:(id)inputValue {
    if ([inputValue isKindOfClass:[UIFont class]]) {
        UIFont *font = (UIFont *)inputValue;
        self.fontNameInput.inputValue = font.fontName;
        self.pointSizeInput.inputValue = @(font.pointSize);
    }
}

- (id)inputValue {
    CGFloat pointSize = 0;
    if ([self.pointSizeInput.inputValue isKindOfClass:[NSValue class]]) {
        NSValue *pointSizeValue = (NSValue *)self.pointSizeInput.inputValue;
        if (strcmp([pointSizeValue objCType], @encode(CGFloat)) == 0) {
            [pointSizeValue getValue:&pointSize];
        }
    }
    return [UIFont fontWithName:self.fontNameInput.inputValue size:pointSize];
}

- (BOOL)inputViewIsFirstResponder {
    return [self.fontNameInput inputViewIsFirstResponder] || [self.pointSizeInput inputViewIsFirstResponder];
}


#pragma mark - Layout and Sizing

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat runningOriginY = self.topInputFieldVerticalLayoutGuide;

    CGSize fontNameFitSize = [self.fontNameInput sizeThatFits:self.bounds.size];
    self.fontNameInput.frame = CGRectMake(0, runningOriginY, fontNameFitSize.width, fontNameFitSize.height);
    runningOriginY = CGRectGetMaxY(self.fontNameInput.frame) + [[self class] verticalPaddingBetweenFields];

    CGSize pointSizeFitSize = [self.pointSizeInput sizeThatFits:self.bounds.size];
    self.pointSizeInput.frame = CGRectMake(0, runningOriginY, pointSizeFitSize.width, pointSizeFitSize.height);
}

+ (CGFloat)verticalPaddingBetweenFields {
    return 10.0;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize fitSize = [super sizeThatFits:size];

    CGSize constrainSize = CGSizeMake(size.width, CGFLOAT_MAX);

    CGFloat height = fitSize.height;
    height += [self.fontNameInput sizeThatFits:constrainSize].height;
    height += [[self class] verticalPaddingBetweenFields];
    height += [self.pointSizeInput sizeThatFits:constrainSize].height;

    return CGSizeMake(fitSize.width, height);
}


#pragma mark -

+ (BOOL)supportsObjCType:(const char *)type withCurrentValue:(id)value {
    NSParameterAssert(type);
    return strcmp(type, FLEXEncodeClass(UIFont)) == 0;
}

@end
