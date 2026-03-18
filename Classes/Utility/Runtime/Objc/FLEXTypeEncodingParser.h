//
//  FLEXTypeEncodingParser.h
//  FLEX
//
//  Created by Tanner Bennett on 8/22/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

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
