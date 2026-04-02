//
//  FLEXMethod.h
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

#import "FLEXRuntimeConstants.h"
#import "FLEXMethodBase.h"

NS_ASSUME_NONNULL_BEGIN

/// A class representing a concrete method which already exists in a class.
/// This class contains helper methods for swizzling or invoking the method.
///
/// Any of the initializers will return nil if the type encoding
/// of the method is unsupported by `NSMethodSignature`. In general,
/// any method whose return type or parameters involve a struct with
/// bitfields or arrays is unsupported.
///
/// I do not remember why I didn't include `signature` in the base class
/// when I originally wrote this, but I probably had a good reason. We can
/// always go back and move it to `FLEXMethodBase` if we find we need to.
@interface FLEXMethod : FLEXMethodBase

/// Defaults to instance method
+ (nullable instancetype)method:(Method)method;
+ (nullable instancetype)method:(Method)method isInstanceMethod:(BOOL)isInstanceMethod;

/// Constructs an `FLEXMethod` for the given method on the given class.
/// @param cls the class, or metaclass if this is a class method
/// @return The newly constructed `FLEXMethod` object, or `nil` if the
/// specified class or its superclasses do not contain a method with the specified selector.
+ (nullable instancetype)selector:(SEL)selector class:(Class)cls;
/// Constructs an `FLEXMethod` for the given method on the given class,
/// only if the given class itself defines or overrides the desired method.
/// @param cls the class, or metaclass if this is a class method
/// @return The newly constructed `FLEXMethod` object, or `nil` \e if the
/// specified class does not define or override, or if the specified class
/// or its superclasses do not contain, a method with the specified selector.
+ (nullable instancetype)selector:(SEL)selector implementedInClass:(Class)cls;

/// The underlying `Method` data structure.
@property (nonatomic, readonly) Method            objc_method;

/// The implementation of the method.
///
/// Setting `implementation` will change the implementation of this method for the entire
/// class that implements it. It will not modify the selector of the method.
@property (nonatomic          ) IMP               implementation;

/// Whether the method is an instance method or not.
@property (nonatomic, readonly) BOOL              isInstanceMethod;

/// The number of arguments to the method.
@property (nonatomic, readonly) NSUInteger        numberOfArguments;

/// The `NSMethodSignature` object corresponding to the method's type encoding.
@property (nonatomic, readonly) NSMethodSignature *signature;

/// Same as \e typeEncoding but with parameter sizes up front and offsets after the types.
@property (nonatomic, readonly) NSString          *signatureString;

/// The return type of the method.
@property (nonatomic, readonly) FLEXTypeEncoding  *returnType;

/// The return size of the method.
@property (nonatomic, readonly) NSUInteger        returnSize;

/// The full path of the image that contains this method definition,
/// or `nil` if this method was probably defined at runtime.
@property (nonatomic, readonly) NSString          *imagePath;

/// Like @code - (void)foo:(int)bar @endcode
@property (nonatomic, readonly) NSString *description;
/// Like @code -[Class foo:] @endcode
- (NSString *)debugNameGivenClassName:(NSString *)name;

/// Swizzles the receiving method with the given method.
- (void)swapImplementations:(FLEXMethod *)method;

#define FLEXMagicNumber 0xdeadbeef
#define FLEXArg(expr) FLEXMagicNumber,/// @encode(__typeof__(expr)), (__typeof__(expr) []){ expr }

/// Sends a message to the given target and returns its value, or `nil` if not applicable.
///
/// Primitive return values are wrapped in `NSNumber` or `NSValue`. `void` and
/// bitfield-returning methods return `nil`. `SEL` return types are converted to
/// strings via `NSStringFromSelector`.
///
/// @return The return value boxed as an object, or `nil` for void/bitfield methods.
- (id)sendMessage:(id)target, ...;
/// Used internally by `sendMessage:`. Pass `NULL` to the first parameter for void methods.
- (void)getReturnValue:(void *)retPtr forMessageSend:(id)target, ...;

@end


@interface FLEXMethod (Comparison)

- (NSComparisonResult)compare:(FLEXMethod *)method;

@end

NS_ASSUME_NONNULL_END
