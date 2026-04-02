//
//  FLEXRuntimeUtility.h
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
@class FLEXObjectRef;

#define PropertyKey(suffix) kFLEXPropertyAttributeKey##suffix : @""
#define PropertyKeyGetter(getter) kFLEXPropertyAttributeKeyCustomGetter : NSStringFromSelector(@selector(getter))
#define PropertyKeySetter(setter) kFLEXPropertyAttributeKeyCustomSetter : NSStringFromSelector(@selector(setter))

/// Takes: min iOS version, property name, target class, property type, and a list of attributes
#define FLEXRuntimeUtilityTryAddProperty(iOS_atLeast, name, cls, type, ...) ({ \
    if (@available(iOS iOS_atLeast, *)) { \
        NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:@{ \
            kFLEXPropertyAttributeKeyTypeEncoding : @(type), \
            __VA_ARGS__ \
        }]; \
        [FLEXRuntimeUtility \
            tryAddPropertyWithName:#name \
            attributes:attrs \
            toClass:cls \
        ]; \
    } \
})

/// Takes: min iOS version, property name, target class, property type, and a list of attributes
#define FLEXRuntimeUtilityTryAddNonatomicProperty(iOS_atLeast, name, cls, type, ...) \
    FLEXRuntimeUtilityTryAddProperty(iOS_atLeast, name, cls, @encode(type), PropertyKey(NonAtomic), __VA_ARGS__);
/// Takes: min iOS version, property name, target class, property type (class name), and a list of attributes
#define FLEXRuntimeUtilityTryAddObjectProperty(iOS_atLeast, name, cls, type, ...) \
    FLEXRuntimeUtilityTryAddProperty(iOS_atLeast, name, cls, FLEXEncodeClass(type), PropertyKey(NonAtomic), __VA_ARGS__);

extern NSString * const FLEXRuntimeUtilityErrorDomain;

typedef NS_ENUM(NSInteger, FLEXRuntimeUtilityErrorCode) {
    // Start at a random value instead of 0 to avoid confusion with an absent code
    FLEXRuntimeUtilityErrorCodeDoesNotRecognizeSelector = 0xbabe,
    FLEXRuntimeUtilityErrorCodeInvocationFailed,
    FLEXRuntimeUtilityErrorCodeArgumentTypeMismatch
};

@interface FLEXRuntimeUtility : NSObject

#pragma mark - General Helpers

/// Calls into `FLEXPointerIsValidObjcObject()`
+ (BOOL)pointerIsValidObjcObject:(const void *)pointer;
/// Unwraps raw pointers to objects stored in NSValue, and re-boxes C strings into NSStrings.
+ (id)potentiallyUnwrapBoxedPointer:(id)returnedObjectOrNil type:(const FLEXTypeEncoding *)returnType;
/// Some fields have a name in their encoded string (e.g. \"width\"d)
/// @return the offset to skip the field name, 0 if there is no name
+ (NSUInteger)fieldNameOffsetForTypeEncoding:(const FLEXTypeEncoding *)typeEncoding;
/// Given name "foo" and type "int" this would return "int foo", but
/// given name "foo" and type "T *" it would return "T *foo"
+ (NSString *)appendName:(NSString *)name toType:(NSString *)typeEncoding;

/// @return The class hierarchy for the given object or class,
/// from the current class to the root-most class.
+ (NSArray<Class> *)classHierarchyOfObject:(id)objectOrClass;
/// @return Every subclass of the given class name.
+ (NSArray<FLEXObjectRef *> *)subclassesOfClassWithName:(NSString *)className;

/// Used to describe an object in brief within an explorer row
+ (NSString *)summaryForObject:(id)value;
+ (NSString *)safeClassNameForObject:(id)object;
+ (NSString *)safeDescriptionForObject:(id)object;
+ (NSString *)safeDebugDescriptionForObject:(id)object;

+ (BOOL)safeObject:(id)object isKindOfClass:(Class)cls;
+ (BOOL)safeObject:(id)object respondsToSelector:(SEL)sel;

#pragma mark - Property Helpers

+ (BOOL)tryAddPropertyWithName:(const char *)name
                    attributes:(NSDictionary<NSString *, NSString *> *)attributePairs
                       toClass:(__unsafe_unretained Class)theClass;
+ (NSArray<NSString *> *)allPropertyAttributeKeys;

#pragma mark - Method Helpers

+ (NSArray *)prettyArgumentComponentsForMethod:(Method)method;

#pragma mark - Method Calling/Field Editing

+ (id)performSelector:(SEL)selector onObject:(id)object;
+ (id)performSelector:(SEL)selector
             onObject:(id)object
        withArguments:(NSArray *)arguments
                error:(NSError * __autoreleasing *)error;
+ (id)performSelector:(SEL)selector
             onObject:(id)object
        withArguments:(NSArray *)arguments
      allowForwarding:(BOOL)mightForwardMsgSend
                error:(NSError * __autoreleasing *)error;

+ (NSString *)editableJSONStringForObject:(id)object;
+ (id)objectValueFromEditableJSONString:(NSString *)string;
+ (NSValue *)valueForNumberWithObjCType:(const char *)typeEncoding fromInputString:(NSString *)inputString;
+ (void)enumerateTypesInStructEncoding:(const char *)structEncoding
                            usingBlock:(void (^)(NSString *structName,
                                                 const char *fieldTypeEncoding,
                                                 NSString *prettyTypeEncoding,
                                                 NSUInteger fieldIndex,
                                                 NSUInteger fieldOffset))typeBlock;
+ (NSValue *)valueForPrimitivePointer:(void *)pointer objCType:(const char *)type;

#pragma mark - Metadata Helpers

+ (NSString *)readableTypeForEncoding:(NSString *)encodingString;

@end
