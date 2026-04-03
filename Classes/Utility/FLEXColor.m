//
//  FLEXColor.m
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
#import "FLEXUtility.h"

#define FLEXDynamicColor(dynamic, static) [UIColor dynamic]

@implementation FLEXColor

#pragma mark - Background Colors

+ (UIColor *)primaryBackgroundColor {
    return FLEXDynamicColor(systemBackgroundColor, whiteColor);
}

+ (UIColor *)primaryBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self primaryBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)secondaryBackgroundColor {
    return FLEXDynamicColor(
        secondarySystemBackgroundColor,
        colorWithHue:2.0/3.0 saturation:0.02 brightness:0.97 alpha:1
    );
}

+ (UIColor *)secondaryBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self secondaryBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)tertiaryBackgroundColor {
    // All the background/fill colors are varying shades
    // of white and black with really low alpha levels.
    // We use systemGray4Color instead to avoid alpha issues.
    return FLEXDynamicColor(systemGray4Color, lightGrayColor);
}

+ (UIColor *)tertiaryBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self tertiaryBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)groupedBackgroundColor {
    return FLEXDynamicColor(
        systemGroupedBackgroundColor,
        colorWithHue:2.0/3.0 saturation:0.02 brightness:0.97 alpha:1
    );
}

+ (UIColor *)groupedBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self groupedBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)secondaryGroupedBackgroundColor {
    return FLEXDynamicColor(secondarySystemGroupedBackgroundColor, whiteColor);
}

+ (UIColor *)secondaryGroupedBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self secondaryGroupedBackgroundColor] colorWithAlphaComponent:alpha];
}

#pragma mark - Fill colors

+ (UIColor *)primaryFillColor {
    return FLEXDynamicColor(systemFillColor, grayColor);
}

+ (UIColor *)secondaryFillColor {
    return FLEXDynamicColor(secondarySystemFillColor, grayColor);
}

+ (UIColor *)tertiaryFillColor {
    return FLEXDynamicColor(tertiarySystemFillColor, grayColor);
}

#pragma mark - Text colors

+ (UIColor *)primaryTextColor {
    return FLEXDynamicColor(labelColor, blackColor);
}

+ (UIColor *)deemphasizedTextColor {
    return FLEXDynamicColor(secondaryLabelColor, darkGrayColor);
}

+ (UIColor *)mutedTextColor {
    return FLEXDynamicColor(tertiaryLabelColor, lightGrayColor);
}

#pragma mark - UI Element Colors

+ (UIColor *)tintColor {
    return UIColor.systemBlueColor;
}

+ (UIColor *)scrollViewBackgroundColor {
    return FLEXDynamicColor(
        systemGroupedBackgroundColor,
        colorWithHue:2.0/3.0 saturation:0.02 brightness:0.95 alpha:1
    );
}

+ (UIColor *)iconColor {
    return FLEXDynamicColor(labelColor, blackColor);
}

+ (UIColor *)borderColor {
    return [self primaryBackgroundColor];
}

+ (UIColor *)toolbarItemHighlightedColor {
    return FLEXDynamicColor(
        quaternaryLabelColor,
        colorWithHue:2.0/3.0 saturation:0.1 brightness:0.25 alpha:0.6
    );
}

+ (UIColor *)toolbarItemSelectedColor {
    return FLEXDynamicColor(
        secondaryLabelColor,
        colorWithHue:2.0/3.0 saturation:0.1 brightness:0.25 alpha:0.68
    );
}

+ (UIColor *)hairlineColor {
    return FLEXDynamicColor(systemGray3Color, colorWithWhite:0.75 alpha:1);
}

+ (UIColor *)destructiveColor {
    return FLEXDynamicColor(systemRedColor, redColor);
}

@end
