//
//  FLEXRuntimeKeyPathTokenizer.m
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

#import "FLEXRuntimeKeyPathTokenizer.h"

#define TBCountOfStringOccurence(target, str) ([target componentsSeparatedByString:str].count - 1)

@implementation FLEXRuntimeKeyPathTokenizer

#pragma mark Initialization

static NSCharacterSet *firstAllowed      = nil;
static NSCharacterSet *identifierAllowed = nil;
static NSCharacterSet *filenameAllowed   = nil;
static NSCharacterSet *keyPathDisallowed = nil;
static NSCharacterSet *methodAllowed     = nil;
+ (void)initialize {
    if (self == [self class]) {
        NSString * const _methodFirstAllowed    = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_$";
        NSString *_identifierAllowed     = [_methodFirstAllowed stringByAppendingString:@"1234567890"];
        NSString *_methodAllowedSansType = [_identifierAllowed stringByAppendingString:@":"];
        NSString *_filenameNameAllowed   = [_identifierAllowed stringByAppendingString:@"-+?!"];
        firstAllowed      = [NSCharacterSet characterSetWithCharactersInString:_methodFirstAllowed];
        identifierAllowed = [NSCharacterSet characterSetWithCharactersInString:_identifierAllowed];
        filenameAllowed   = [NSCharacterSet characterSetWithCharactersInString:_filenameNameAllowed];
        methodAllowed     = [NSCharacterSet characterSetWithCharactersInString:_methodAllowedSansType];

        NSString *_kpDisallowed = [_identifierAllowed stringByAppendingString:@"-+:\\.*"];
        keyPathDisallowed = [NSCharacterSet characterSetWithCharactersInString:_kpDisallowed].invertedSet;
    }
}

#pragma mark Public

+ (FLEXRuntimeKeyPath *)tokenizeString:(NSString *)userInput {
    if (!userInput.length) {
        return nil;
    }

    NSUInteger tokens = [self tokenCountOfString:userInput];
    if (tokens == 0) {
        return nil;
    }

    if ([userInput containsString:@"**"]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Key path cannot contain '**'" userInfo:nil];
    }

    NSNumber *instance = nil;
    NSScanner *scanner = [NSScanner scannerWithString:userInput];
    FLEXSearchToken *bundle    = [self scanToken:scanner allowed:filenameAllowed first:filenameAllowed];
    FLEXSearchToken *cls       = [self scanToken:scanner allowed:identifierAllowed first:firstAllowed];
    FLEXSearchToken *method    = tokens > 2 ? [self scanMethodToken:scanner instance:&instance] : nil;

    return [FLEXRuntimeKeyPath bundle:bundle
                       class:cls
                      method:method
                  isInstance:instance
                      string:userInput];
}

+ (BOOL)allowedInKeyPath:(NSString *)text {
    if (!text.length) {
        return YES;
    }

    return [text rangeOfCharacterFromSet:keyPathDisallowed].location == NSNotFound;
}

#pragma mark Private

+ (NSUInteger)tokenCountOfString:(NSString *)userInput {
    NSUInteger escapedCount = TBCountOfStringOccurence(userInput, @"\\.");
    NSUInteger tokenCount  = TBCountOfStringOccurence(userInput, @".") - escapedCount + 1;

    return tokenCount;
}

+ (FLEXSearchToken *)scanToken:(NSScanner *)scanner allowed:(NSCharacterSet *)allowedChars first:(NSCharacterSet *)first {
    if (scanner.isAtEnd) {
        if ([scanner.string hasSuffix:@"."] && ![scanner.string hasSuffix:@"\\."]) {
            return [FLEXSearchToken string:nil options:TBWildcardOptionsAny];
        }
        return nil;
    }

    TBWildcardOptions options = TBWildcardOptionsNone;
    NSMutableString *token = [NSMutableString new];

    // Token cannot start with '.'
    if ([scanner scanString:@"." intoString:nil]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Key path token cannot start with '.'" userInfo:nil];
    }

    if ([scanner scanString:@"*." intoString:nil]) {
        return [FLEXSearchToken string:nil options:TBWildcardOptionsAny];
    } else if ([scanner scanString:@"*" intoString:nil]) {
        if (scanner.isAtEnd) {
            return FLEXSearchToken.any;
        }

        options |= TBWildcardOptionsPrefix;
    }

    NSString *tmp = nil;
    BOOL stop = NO, didScanDelimiter = NO, didScanFirstAllowed = NO;
    NSCharacterSet *disallowed = allowedChars.invertedSet;
    while (!stop && ![scanner scanString:@"." intoString:&tmp] && !scanner.isAtEnd) {
        // Scan word chars
        // In this block, we have not scanned anything yet, except maybe leading '\' or '\.'
        if (!didScanFirstAllowed) {
            if ([scanner scanCharactersFromSet:first intoString:&tmp]) {
                [token appendString:tmp];
                didScanFirstAllowed = YES;
            } else if ([scanner scanString:@"\\" intoString:nil]) {
                if (options == TBWildcardOptionsPrefix && [scanner scanString:@"." intoString:nil]) {
                    [token appendString:@"."];
                } else if (scanner.isAtEnd && options == TBWildcardOptionsPrefix) {
                    // Only allow standalone '\' if prefixed by '*'
                    return FLEXSearchToken.any;
                } else {
                    // Token starts with a number, period, or something else not allowed,
                    // or token is a standalone '\' with no '*' prefix
                    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Key path token: '\\' must be followed by '.'" userInfo:nil];
                }
            } else {
                // Token starts with a number, period, or something else not allowed
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Key path token: first character not in allowed set" userInfo:nil];
            }
        } else if ([scanner scanCharactersFromSet:allowedChars intoString:&tmp]) {
            [token appendString:tmp];
        }
        // Scan '\.' or trailing '\'
        else if ([scanner scanString:@"\\" intoString:nil]) {
            if ([scanner scanString:@"." intoString:nil]) {
                [token appendString:@"."];
            } else if (scanner.isAtEnd) {
                // Ignore forward slash not followed by period if at end
                return [FLEXSearchToken string:token options:options | TBWildcardOptionsSuffix];
            } else {
                // Only periods can follow a forward slash
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Key path token: '\\' must be followed by '.'" userInfo:nil];
            }
        }
        // Scan '*.'
        else if ([scanner scanString:@"*." intoString:nil]) {
            options |= TBWildcardOptionsSuffix;
            stop = YES;
            didScanDelimiter = YES;
        }
        // Scan '*' not followed by .
        else if ([scanner scanString:@"*" intoString:nil]) {
            if (!scanner.isAtEnd) {
                // Invalid token, wildcard in middle of token
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Key path token: '*' wildcard cannot appear in the middle of a token" userInfo:nil];
            }
        } else if ([scanner scanCharactersFromSet:disallowed intoString:nil]) {
            // Invalid token, invalid characters
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Key path token: contains disallowed characters" userInfo:nil];
        }
    }

    // Did we scan a trailing, un-escsaped '.'?
    if ([tmp isEqualToString:@"."]) {
        didScanDelimiter = YES;
    }

    if (!didScanDelimiter) {
        options |= TBWildcardOptionsSuffix;
    }

    return [FLEXSearchToken string:token options:options];
}

+ (FLEXSearchToken *)scanMethodToken:(NSScanner *)scanner instance:(NSNumber **)instance {
    if (scanner.isAtEnd) {
        if ([scanner.string hasSuffix:@"."]) {
            return [FLEXSearchToken string:nil options:TBWildcardOptionsAny];
        }
        return nil;
    }

    if ([scanner.string hasSuffix:@"."] && ![scanner.string hasSuffix:@"\\."]) {
        // Methods cannot end with '.' except for '\.'
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Method token cannot end with '.'" userInfo:nil];
    }

    if ([scanner scanString:@"-" intoString:nil]) {
        *instance = @YES;
    } else if ([scanner scanString:@"+" intoString:nil]) {
        *instance = @NO;
    } else {
        if ([scanner scanString:@"*" intoString:nil]) {
            // Just checking... It has to start with one of these three!
            scanner.scanLocation--;
        } else {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Method token must begin with '-', '+', or '*'" userInfo:nil];
        }
    }

    // -*foo not allowed
    if (*instance && [scanner scanString:@"*" intoString:nil]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Method token: '*' wildcard cannot precede instance method indicator '-'" userInfo:nil];
    }

    if (scanner.isAtEnd) {
        return [FLEXSearchToken string:@"" options:TBWildcardOptionsSuffix];
    }

    return [self scanToken:scanner allowed:methodAllowed first:firstAllowed];
}

@end
