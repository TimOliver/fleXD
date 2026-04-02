//
//  NSString+FLEX.m
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

#import "NSString+FLEX.h"

@interface NSMutableString (Replacement)
- (void)replaceOccurencesOfString:(NSString *)string with:(NSString *)replacement;
- (void)removeLastKeyPathComponent;
@end

@implementation NSMutableString (Replacement)

- (void)replaceOccurencesOfString:(NSString *)string with:(NSString *)replacement {
    [self replaceOccurrencesOfString:string withString:replacement options:0 range:NSMakeRange(0, self.length)];
}

- (void)removeLastKeyPathComponent {
    if (![self containsString:@"."]) {
        [self deleteCharactersInRange:NSMakeRange(0, self.length)];
        return;
    }

    BOOL putEscapesBack = NO;
    if ([self containsString:@"\\."]) {
        [self replaceOccurencesOfString:@"\\." with:@"\\~"];

        // Case like "UIKit\.framework"
        if (![self containsString:@"."]) {
            [self deleteCharactersInRange:NSMakeRange(0, self.length)];
            return;
        }

        putEscapesBack = YES;
    }

    // Case like "Bund" or "Bundle.cla"
    if (![self hasSuffix:@"."]) {
        NSUInteger len = self.pathExtension.length;
        [self deleteCharactersInRange:NSMakeRange(self.length-len, len)];
    }

    if (putEscapesBack) {
        [self replaceOccurencesOfString:@"\\~" with:@"\\."];
    }
}

@end

@implementation NSString (FLEXTypeEncoding)

- (NSCharacterSet *)flex_classNameAllowedCharactersSet {
    static NSCharacterSet *classNameAllowedCharactersSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *temp = NSMutableCharacterSet.alphanumericCharacterSet;
        [temp addCharactersInString:@"_"];
        classNameAllowedCharactersSet = temp.copy;
    });

    return classNameAllowedCharactersSet;
}

- (BOOL)flex_typeIsConst {
    if (!self.length) return NO;
    return [self characterAtIndex:0] == FLEXTypeEncodingConst;
}

- (FLEXTypeEncoding)flex_firstNonConstType {
    if (!self.length) return FLEXTypeEncodingNull;
    return [self characterAtIndex:(self.flex_typeIsConst ? 1 : 0)];
}

- (FLEXTypeEncoding)flex_pointeeType {
    if (!self.length) return FLEXTypeEncodingNull;

    if (self.flex_firstNonConstType == FLEXTypeEncodingPointer) {
        return [self characterAtIndex:(self.flex_typeIsConst ? 2 : 1)];
    }

    return FLEXTypeEncodingNull;
}

- (BOOL)flex_typeIsObjectOrClass {
    FLEXTypeEncoding type = self.flex_firstNonConstType;
    return type == FLEXTypeEncodingObjcObject || type == FLEXTypeEncodingObjcClass;
}

- (Class)flex_typeClass {
    if (!self.flex_typeIsObjectOrClass) {
        return nil;
    }

    NSScanner *scan = [NSScanner scannerWithString:self];
    // Skip const
    [scan scanString:@"r" intoString:nil];
    // Scan leading @"
    if (![scan scanString:@"@\"" intoString:nil]) {
        return nil;
    }

    // Scan class name
    NSString *name = nil;
    if (![scan scanCharactersFromSet:self.flex_classNameAllowedCharactersSet intoString:&name]) {
        return nil;
    }
    // Scan trailing quote
    if (![scan scanString:@"\"" intoString:nil]) {
        return nil;
    }

    // Return found class
    return NSClassFromString(name);
}

- (BOOL)flex_typeIsNonObjcPointer {
    FLEXTypeEncoding type = self.flex_firstNonConstType;
    return type == FLEXTypeEncodingPointer ||
           type == FLEXTypeEncodingCString ||
           type == FLEXTypeEncodingSelector;
}

@end

@implementation NSString (KeyPaths)

- (NSString *)flex_stringByRemovingLastKeyPathComponent {
    if (![self containsString:@"."]) {
        return @"";
    }

    NSMutableString *mself = self.mutableCopy;
    [mself removeLastKeyPathComponent];
    return mself;
}

- (NSString *)flex_stringByReplacingLastKeyPathComponent:(NSString *)replacement {
    // replacement should not have any escaped '.' in it,
    // so we escape all '.'
    if ([replacement containsString:@"."]) {
        replacement = [replacement stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
    }

    // Case like "Foo"
    if (![self containsString:@"."]) {
        return [replacement stringByAppendingString:@"."];
    }

    NSMutableString *mself = self.mutableCopy;
    [mself removeLastKeyPathComponent];
    [mself appendString:replacement];
    [mself appendString:@"."];
    return mself;
}

@end
