//
//  FLEXArgumentInputFontsPickerView.m
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

#import "FLEXArgumentInputFontsPickerView.h"
#import "FLEXRuntimeUtility.h"

@interface FLEXArgumentInputFontsPickerView ()

@property (nonatomic) NSMutableArray<NSString *> *availableFonts;

@end


@implementation FLEXArgumentInputFontsPickerView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding {
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        self.targetSize = FLEXArgumentInputViewSizeSmall;
        [self createAvailableFonts];
        self.inputTextView.inputView = [self createFontsPicker];
    }
    return self;
}

- (void)setInputValue:(id)inputValue {
    self.inputTextView.text = inputValue;
    if ([self.availableFonts indexOfObject:inputValue] == NSNotFound) {
        [self.availableFonts insertObject:inputValue atIndex:0];
    }
    [(UIPickerView *)self.inputTextView.inputView selectRow:[self.availableFonts indexOfObject:inputValue] inComponent:0 animated:NO];
}

- (id)inputValue {
    return self.inputTextView.text.length > 0 ? [self.inputTextView.text copy] : nil;
}

#pragma mark - private

- (UIPickerView*)createFontsPicker {
    UIPickerView *fontsPicker = [UIPickerView new];
    fontsPicker.dataSource = self;
    fontsPicker.delegate = self;

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // Deprecated in iOS 13; from then on, selection is always shown
    fontsPicker.showsSelectionIndicator = YES;
    #pragma clang diagnostic pop

    return fontsPicker;
}

- (void)createAvailableFonts {
    NSMutableArray<NSString *> *unsortedFontsArray = [NSMutableArray new];
    for (NSString *eachFontFamily in UIFont.familyNames) {
        for (NSString *eachFontName in [UIFont fontNamesForFamilyName:eachFontFamily]) {
            [unsortedFontsArray addObject:eachFontName];
        }
    }
    self.availableFonts = [NSMutableArray arrayWithArray:[unsortedFontsArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.availableFonts.count;
}

#pragma mark - UIPickerViewDelegate

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *fontLabel;
    if (!view) {
        fontLabel = [UILabel new];
        fontLabel.backgroundColor = UIColor.clearColor;
        fontLabel.textAlignment = NSTextAlignmentCenter;
    } else {
        fontLabel = (UILabel*)view;
    }
    UIFont *font = [UIFont fontWithName:self.availableFonts[row] size:15.0];
    NSDictionary<NSString *, id> *attributesDictionary = @{NSFontAttributeName: font};
    NSAttributedString *attributesString = [[NSAttributedString alloc] initWithString:self.availableFonts[row] attributes:attributesDictionary];
    fontLabel.attributedText = attributesString;
    [fontLabel sizeToFit];
    return fontLabel;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.inputTextView.text = self.availableFonts[row];
}

@end
