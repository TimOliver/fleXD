//
//  FLEXProperty.h
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 6/30/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXRuntimeConstants.h"
@class FLEXPropertyAttributes, FLEXMethodBase;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FLEXProperty

@interface FLEXProperty : NSObject

/// Creates a property from an \c objc_property_t without class context.
///
/// Use \c property:onClass: instead if you need information about uniqueness
/// or the binary image that defines the property.
+ (instancetype)property:(objc_property_t)property;

/// Creates a property from an \c objc_property_t with class context.
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

/// The first underlying \c objc_property_t for this property.
/// \c 0 if created via \c +propertyWithName:attributes:.
@property (nonatomic, readonly) objc_property_t  objc_property;
/// All underlying \c objc_property_t values, e.g. when a property is defined in multiple images.
@property (nonatomic, readonly) objc_property_t  *objc_properties;
/// The number of underlying \c objc_property_t values.
@property (nonatomic, readonly) NSInteger        objc_propertyCount;
/// Whether this is a class property (as opposed to an instance property).
@property (nonatomic, readonly) BOOL             isClassProperty;

/// The name of the property.
@property (nonatomic, readonly) NSString         *name;
/// The broad type of the property. For the full type encoding, use \c attributes.typeEncoding.
@property (nonatomic, readonly) FLEXTypeEncoding type;
/// The property's attributes.
@property (nonatomic          ) FLEXPropertyAttributes *attributes;

/// The most likely setter selector for this property, including any custom setter.
@property (nonatomic, readonly) SEL likelySetter;
/// The string form of \c likelySetter.
@property (nonatomic, readonly) NSString *likelySetterString;
/// Whether a method matching \c likelySetter exists on the owning class.
/// Not valid unless this property was initialized with a class.
@property (nonatomic, readonly) BOOL likelySetterExists;

/// The most likely getter selector for this property, including any custom getter.
@property (nonatomic, readonly) SEL likelyGetter;
/// The string form of \c likelyGetter.
@property (nonatomic, readonly) NSString *likelyGetterString;
/// Whether a method matching \c likelyGetter exists on the owning class.
/// Not valid unless this property was initialized with a class.
@property (nonatomic, readonly) BOOL likelyGetterExists;

/// The name of the ivar most likely backing this property. Always \c nil for class properties.
@property (nonatomic, readonly, nullable) NSString *likelyIvarName;
/// Whether an ivar matching \c likelyIvarName exists on the owning class.
/// Not valid unless this property was initialized with a class.
@property (nonatomic, readonly) BOOL likelyIvarExists;

/// Whether there are multiple definitions of this property, e.g. in categories
/// from different binary images.
/// @return Whether \c objc_property differs from the value returned by \c class_getProperty,
/// or \c NO if this property was not created with \c property:onClass:.
@property (nonatomic, readonly) BOOL multiple;

/// The name of the binary image that contains this property definition,
/// or \c nil if not initialized with a class or if defined at runtime.
@property (nonatomic, readonly, nullable) NSString *imageName;

/// The full path of the binary image that contains this property definition,
/// or \c nil if not initialized with a class or if defined at runtime.
@property (nonatomic, readonly, nullable) NSString *imagePath;

/// For internal use.
@property (nonatomic) id tag;

/// A source-like description of the property, including all of its attributes.
@property (nonatomic, readonly) NSString *fullDescription;

/// Returns the current value of this property on \e target.
/// For class properties, pass the class object as \e target.
- (nullable id)getValue:(id)target;

/// Returns the current value of this property on \e target, unwrapping boxed pointers.
/// Calls \c -getValue: and passes the result through
/// \c -[FLEXRuntimeUtility potentiallyUnwrapBoxedPointer:type:].
/// For class properties, pass the class object as \e target.
- (nullable id)getPotentiallyUnboxedValue:(id)target;

/// Copies the attribute list for this property to a caller-owned buffer.
/// The caller is responsible for calling \c free() on the returned buffer.
/// Use \c attributes.list if you do not need to manage the buffer lifetime yourself.
/// @param attributesCount The number of attributes is written to this parameter.
- (objc_property_attribute_t *)copyAttributesList:(unsigned int *)attributesCount;

/// Replaces this property's definition on the given class using \c self.attributes.
- (void)replacePropertyOnClass:(Class)cls;

#pragma mark - Convenience Getters and Setters

/// Returns a getter method for this property with the given implementation.
/// @discussion Consider using the \c FLEXPropertyGetter macro instead.
- (FLEXMethodBase *)getterWithImplementation:(IMP)implementation;

/// Returns a setter method for this property with the given implementation.
/// @discussion Consider using the \c FLEXPropertySetter macro instead.
- (FLEXMethodBase *)setterWithImplementation:(IMP)implementation;

#pragma mark - FLEXProperty Getter/Setter Macros

/// Creates a getter method for a \c FLEXProperty using its backing ivar.
/// @param FLEXProperty The \c FLEXProperty instance.
/// @param type The C type of the property value, e.g. \c NSUInteger or \c id.
#define FLEXPropertyGetter(FLEXProperty, type) [FLEXProperty \
    getterWithImplementation:imp_implementationWithBlock(^(id self) { \
        return *(type *)[self getIvarAddressByName:FLEXProperty.attributes.backingIvar]; \
    }) \
];

/// Creates a setter method for a \c FLEXProperty using its backing ivar.
/// @param FLEXProperty The \c FLEXProperty instance.
/// @param type The C type of the property value, e.g. \c NSUInteger or \c id.
#define FLEXPropertySetter(FLEXProperty, type) [FLEXProperty \
    setterWithImplementation:imp_implementationWithBlock(^(id self, type value) { \
        [self setIvarByName:FLEXProperty.attributes.backingIvar value:&value size:sizeof(type)]; \
    }) \
];

/// Creates a getter method for a \c FLEXProperty using a named ivar.
/// @param FLEXProperty The \c FLEXProperty instance.
/// @param ivarName A string naming the backing ivar.
/// @param type The C type of the property value.
#define FLEXPropertyGetterWithIvar(FLEXProperty, ivarName, type) [FLEXProperty \
    getterWithImplementation:imp_implementationWithBlock(^(id self) { \
        return *(type *)[self getIvarAddressByName:ivarName]; \
    }) \
];

/// Creates a setter method for a \c FLEXProperty using a named ivar.
/// @param FLEXProperty The \c FLEXProperty instance.
/// @param ivarName A string naming the backing ivar.
/// @param type The C type of the property value.
#define FLEXPropertySetterWithIvar(FLEXProperty, ivarName, type) [FLEXProperty \
    setterWithImplementation:imp_implementationWithBlock(^(id self, type value) { \
        [self setIvarByName:ivarName value:&value size:sizeof(type)]; \
    }) \
];

@end

NS_ASSUME_NONNULL_END
