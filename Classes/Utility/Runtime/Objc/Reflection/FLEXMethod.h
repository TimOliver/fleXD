//
//  FLEXMethod.h
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 6/30/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

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

/// Sends a message to \e target, and returns its value, or `nil` if not applicable.
/// @discussion You may send any message with this method. Primitive return values will be wrapped
/// in instances of `NSNumber` and `NSValue` `void` and bitfield returning methods return `nil`
/// `SEL` return types are converted to strings using `NSStringFromSelector`
/// @return The object returned by this method, or an instance of `NSValue` or `NSNumber` containing
/// the primitive return type, or a string for `SEL` return types.
- (id)sendMessage:(id)target, ...;
/// Used internally by `sendMessage:`. Pass `NULL` to the first parameter for void methods.
- (void)getReturnValue:(void *)retPtr forMessageSend:(id)target, ...;

@end


@interface FLEXMethod (Comparison)

- (NSComparisonResult)compare:(FLEXMethod *)method;

@end

NS_ASSUME_NONNULL_END
