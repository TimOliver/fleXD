//
//  FLEXTypeEncodingParser.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// @return `YES` if the type is supported, `NO` otherwise
BOOL FLEXGetSizeAndAlignment(const char *type, NSUInteger * _Nullable sizep, NSUInteger * _Nullable alignp);

@interface FLEXTypeEncodingParser : NSObject

/// `cleanedEncoding` is necessary because a type encoding may contain a pointer
/// to an unsupported type. `NSMethodSignature` will pass each type to `NSGetSizeAndAlignment`
/// which will throw an exception on unsupported struct pointers, and this exception is caught
/// by `NSMethodSignature` but it still bothers anyone debugging with `objc_exception_throw`
///
/// @param cleanedEncoding the "safe" type encoding you can pass to `NSMethodSignature`
/// @return whether the given type encoding can be passed to
/// `NSMethodSignature` without it throwing an exception.
+ (BOOL)methodTypeEncodingSupported:(NSString *)typeEncoding cleaned:(NSString *_Nonnull*_Nullable)cleanedEncoding;

/// @return The type encoding of an individual argument in a method's type encoding string.
/// Pass 0 to get the type of the return value. 1 and 2 are `self` and `_cmd` respectively.
+ (NSString *)type:(NSString *)typeEncoding forMethodArgumentAtIndex:(NSUInteger)idx;

/// @return The size in bytes of the typeof an individual argument in a method's type encoding string.
/// Pass 0 to get the size of the return value. 1 and 2 are `self` and `_cmd` respectively.
+ (ssize_t)size:(NSString *)typeEncoding forMethodArgumentAtIndex:(NSUInteger)idx;

/// @param unaligned whether to compute the aligned or unaligned size.
/// @return The size in bytes, or `-1` if the type encoding is unsupported.
/// Do not pass in the result of `method_getTypeEncoding`
+ (ssize_t)sizeForTypeEncoding:(NSString *)type alignment:(nullable ssize_t *)alignOut unaligned:(BOOL)unaligned;

/// Defaults to `unaligned:NO`
+ (ssize_t)sizeForTypeEncoding:(NSString *)type alignment:(nullable ssize_t *)alignOut;

@end

NS_ASSUME_NONNULL_END
