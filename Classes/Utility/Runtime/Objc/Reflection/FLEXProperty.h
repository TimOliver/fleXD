//
//  FLEXProperty.h
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
@class FLEXPropertyAttributes, FLEXMethodBase;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FLEXProperty

@interface FLEXProperty : NSObject

/// Creates a property from an `objc_property_t` without class context.
///
/// Use `property:onClass:` instead if you need information about uniqueness
/// or the binary image that defines the property.
+ (instancetype)property:(objc_property_t)property;

/// Creates a property from an `objc_property_t` with class context.
///
/// This initializer enables additional information such as whether the property
/// is unique and the name of the binary image that declares it.
/// @param cls The class that owns this property, or its metaclass for class properties.
+ (instancetype)property:(objc_property_t)property onClass:(Class)cls;

/// Creates a property by looking up the given name on the given class.
/// @param cls The class that owns this property, or its metaclass for class properties.
+ (nullable instancetype)named:(NSString *)name onClass:(Class)cls;

/// Creates a new property with the given name and attributes.
+ (instancetype)propertyWithName:(NSString *)name attributes:(FLEXPropertyAttributes *)attributes;

/// The first underlying `objc_property_t` for this property.
/// `0` if created via `+propertyWithName:attributes:`
@property (nonatomic, readonly) objc_property_t  objc_property;

/// All underlying `objc_property_t` values, e.g. when a property is defined in multiple images.
@property (nonatomic, readonly) objc_property_t _Nonnull * _Nullable objc_properties;

/// The number of underlying `objc_property_t` values.
@property (nonatomic, readonly) NSInteger        objc_propertyCount;

/// Whether this is a class property (as opposed to an instance property).
@property (nonatomic, readonly) BOOL             isClassProperty;

/// The name of the property.
@property (nonatomic, readonly) NSString         *name;

/// The broad type of the property. For the full type encoding, use `attributes.typeEncoding`
@property (nonatomic, readonly) FLEXTypeEncoding type;

/// The property's attributes.
@property (nonatomic          ) FLEXPropertyAttributes *attributes;

/// The most likely setter selector for this property, including any custom setter.
@property (nonatomic, readonly) SEL likelySetter;

/// The string form of `likelySetter`
@property (nonatomic, readonly) NSString *likelySetterString;

/// Whether a method matching `likelySetter` exists on the owning class.
/// Not valid unless this property was initialized with a class.
@property (nonatomic, readonly) BOOL likelySetterExists;

/// The most likely getter selector for this property, including any custom getter.
@property (nonatomic, readonly) SEL likelyGetter;

/// The string form of `likelyGetter`
@property (nonatomic, readonly) NSString *likelyGetterString;

/// Whether a method matching `likelyGetter` exists on the owning class.
/// Not valid unless this property was initialized with a class.
@property (nonatomic, readonly) BOOL likelyGetterExists;

/// The name of the ivar most likely backing this property. Always `nil` for class properties.
@property (nonatomic, readonly, nullable) NSString *likelyIvarName;

/// Whether an ivar matching `likelyIvarName` exists on the owning class.
/// Not valid unless this property was initialized with a class.
@property (nonatomic, readonly) BOOL likelyIvarExists;

/// Whether there are multiple definitions of this property, e.g. in categories
/// from different binary images.
/// @return Whether `objc_property` differs from the value returned by `class_getProperty`
/// or `NO` if this property was not created with `property:onClass:`
@property (nonatomic, readonly) BOOL multiple;

/// The name of the binary image that contains this property definition,
/// or `nil` if not initialized with a class or if defined at runtime.
@property (nonatomic, readonly, nullable) NSString *imageName;

/// The full path of the binary image that contains this property definition,
/// or `nil` if not initialized with a class or if defined at runtime.
@property (nonatomic, readonly, nullable) NSString *imagePath;

/// For internal use.
@property (nonatomic) id tag;

/// A source-like description of the property, including all of its attributes.
@property (nonatomic, readonly) NSString *fullDescription;

/// Returns the current value of this property on \e target.
/// For class properties, pass the class object as \e target.
- (nullable id)getValue:(id)target;

/// Returns the current value of this property on \e target, unwrapping boxed pointers.
/// Calls `-getValue:` and passes the result through
/// `-[FLEXRuntimeUtility` potentiallyUnwrapBoxedPointer:type:].
/// For class properties, pass the class object as \e target.
- (nullable id)getPotentiallyUnboxedValue:(id)target;

/// Copies the attribute list for this property to a caller-owned buffer.
/// The caller is responsible for calling `free()` on the returned buffer.
/// Use `attributes.list` if you do not need to manage the buffer lifetime yourself.
/// @param attributesCount The number of attributes is written to this parameter.
- (objc_property_attribute_t *)copyAttributesList:(unsigned int *)attributesCount;

/// Replaces this property's definition on the given class using `self.attributes`
- (void)replacePropertyOnClass:(Class)cls;

#pragma mark - Convenience Getters and Setters

/// Returns a getter method for this property with the given implementation.
/// Consider using the `FLEXPropertyGetter` macro instead.
- (FLEXMethodBase *)getterWithImplementation:(IMP)implementation;

/// Returns a setter method for this property with the given implementation.
/// Consider using the `FLEXPropertySetter` macro instead.
- (FLEXMethodBase *)setterWithImplementation:(IMP)implementation;

#pragma mark - FLEXProperty Getter/Setter Macros

/// Creates a getter method for a `FLEXProperty` using its backing ivar.
/// @param FLEXProperty The `FLEXProperty` instance.
/// @param type The C type of the property value, e.g. `NSUInteger` or `id`
#define FLEXPropertyGetter(FLEXProperty, type) [FLEXProperty \
    getterWithImplementation:imp_implementationWithBlock(^(id self) { \
        return *(type *)[self getIvarAddressByName:FLEXProperty.attributes.backingIvar]; \
    }) \
];

/// Creates a setter method for a `FLEXProperty` using its backing ivar.
/// @param FLEXProperty The `FLEXProperty` instance.
/// @param type The C type of the property value, e.g. `NSUInteger` or `id`
#define FLEXPropertySetter(FLEXProperty, type) [FLEXProperty \
    setterWithImplementation:imp_implementationWithBlock(^(id self, type value) { \
        [self setIvarByName:FLEXProperty.attributes.backingIvar value:&value size:sizeof(type)]; \
    }) \
];

/// Creates a getter method for a `FLEXProperty` using a named ivar.
/// @param FLEXProperty The `FLEXProperty` instance.
/// @param ivarName A string naming the backing ivar.
/// @param type The C type of the property value.
#define FLEXPropertyGetterWithIvar(FLEXProperty, ivarName, type) [FLEXProperty \
    getterWithImplementation:imp_implementationWithBlock(^(id self) { \
        return *(type *)[self getIvarAddressByName:ivarName]; \
    }) \
];

/// Creates a setter method for a `FLEXProperty` using a named ivar.
/// @param FLEXProperty The `FLEXProperty` instance.
/// @param ivarName A string naming the backing ivar.
/// @param type The C type of the property value.
#define FLEXPropertySetterWithIvar(FLEXProperty, ivarName, type) [FLEXProperty \
    setterWithImplementation:imp_implementationWithBlock(^(id self, type value) { \
        [self setIvarByName:ivarName value:&value size:sizeof(type)]; \
    }) \
];

@end

NS_ASSUME_NONNULL_END
