//
//  FLEXArgumentInputSwitchView.m
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

#import "FLEXArgumentInputSwitchView.h"

@interface FLEXArgumentInputSwitchView ()

@property (nonatomic) UISwitch *inputSwitch;

@end

@implementation FLEXArgumentInputSwitchView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding {
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        self.inputSwitch = [UISwitch new];
        [self.inputSwitch addTarget:self action:@selector(switchValueDidChange:) forControlEvents:UIControlEventValueChanged];
        [self.inputSwitch sizeToFit];
        [self addSubview:self.inputSwitch];
    }
    return self;
}


#pragma mark Input/Output

- (void)setInputValue:(id)inputValue {
    BOOL on = NO;
    if ([inputValue isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)inputValue;
        on = [number boolValue];
    } else if ([inputValue isKindOfClass:[NSValue class]]) {
        NSValue *value = (NSValue *)inputValue;
        if (strcmp([value objCType], @encode(BOOL)) == 0) {
            [value getValue:&on];
        }
    }
    self.inputSwitch.on = on;
}

- (id)inputValue {
    BOOL isOn = [self.inputSwitch isOn];
    NSValue *boxedBool = [NSValue value:&isOn withObjCType:@encode(BOOL)];
    return boxedBool;
}

- (void)switchValueDidChange:(id)sender {
    [self.delegate argumentInputViewValueDidChange:self];
}


#pragma mark - Layout and Sizing

- (void)layoutSubviews {
    [super layoutSubviews];

    self.inputSwitch.frame = CGRectMake(0, self.topInputFieldVerticalLayoutGuide, self.inputSwitch.frame.size.width, self.inputSwitch.frame.size.height);
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize fitSize = [super sizeThatFits:size];
    fitSize.height += self.inputSwitch.frame.size.height;
    return fitSize;
}


#pragma mark - Class Helpers

+ (BOOL)supportsObjCType:(const char *)type withCurrentValue:(id)value {
    NSParameterAssert(type);
    // Only BOOLs. Current value is irrelevant.
    return strcmp(type, @encode(BOOL)) == 0;
}

@end
