//
//  NSObject+FLEX_Reflection.h
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 6/30/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
@class FLEXMirror, FLEXMethod, FLEXIvar, FLEXProperty, FLEXMethodBase, FLEXPropertyAttributes, FLEXProtocol;

NS_ASSUME_NONNULL_BEGIN

/// Returns a type encoding string for a method with the given return type and parameter types.
///
/// Example usage for a `void` method that takes an `int:`
/// @code FLEXTypeEncodingString(@encode(void), 1, @encode(int)); @endcode
/// @param returnType The encoded return type, e.g. `\@encode(void)`
/// @param count The number of parameter type encodings that follow.
/// @return The full type encoding string, or `nil` if \e returnType is `NULL`
NSString * _Nullable FLEXTypeEncodingString(const char *returnType, NSUInteger count, ...);

NSArray<Class> * _Nullable FLEXGetAllSubclasses(_Nullable Class cls, BOOL includeSelf);
NSArray<Class> * _Nullable FLEXGetClassHierarchy(_Nullable Class cls, BOOL includeSelf);
NSArray<FLEXProtocol *> * _Nullable FLEXGetConformedProtocols(_Nullable Class cls);

NSArray<FLEXIvar *> * _Nullable FLEXGetAllIvars(_Nullable Class cls);

/// @param cls A class object to get instance properties,
/// or a metaclass object to get class properties.
NSArray<FLEXProperty *> * _Nullable FLEXGetAllProperties(_Nullable Class cls);

/// @param cls A class object to get instance methods,
/// or a metaclass object to get class methods.
/// @param instance Used to mark returned methods as instance methods or not.
/// Does not affect whether instance or class methods are retrieved.
NSArray<FLEXMethod *> * _Nullable FLEXGetAllMethods(_Nullable Class cls, BOOL instance);

/// @param cls A class object from which to retrieve all instance and class methods.
NSArray<FLEXMethod *> * _Nullable FLEXGetAllInstanceAndClassMethods(_Nullable Class cls);


#pragma mark - Reflection

@interface NSObject (Reflection)

@property (nonatomic, readonly       ) FLEXMirror *flex_reflection;
@property (nonatomic, readonly, class) FLEXMirror *flex_reflection;

/// Every subclass of the receiving class, including the receiver itself.
/// Calls `FLEXGetAllSubclasses`
@property (nonatomic, readonly, class) NSArray<Class> *flex_allSubclasses;

/// The metaclass of the receiving class, or `Nil` if the class is `Nil` or unregistered.
@property (nonatomic, readonly, class) Class flex_metaclass;

/// The size in bytes of instances of the receiving class, or `0` if the class is `Nil`
@property (nonatomic, readonly, class) size_t flex_instanceSize;

/// Changes the class of the receiving object instance.
/// @return The previous class of the object, or `Nil` if the object is `nil`
- (Class)flex_setClass:(Class)cls;

/// Sets the superclass of the receiving class.
/// @warning Apple advises against using this method.
/// @return The previous superclass.
+ (Class)flex_setSuperclass:(Class)superclass;

/// The class hierarchy starting with the receiver and ending with the root class.
/// Calls `FLEXGetClassHierarchy`
@property (nonatomic, readonly, class) NSArray<Class> *flex_classHierarchy;

/// The protocols that this class itself directly conforms to.
/// Calls `FLEXGetConformedProtocols`
@property (nonatomic, readonly, class) NSArray<FLEXProtocol *> *flex_protocols;

@end


#pragma mark - Methods

@interface NSObject (Methods)

/// All instance and class methods defined directly on the receiving class.
///
/// Only retrieves methods specific to this class; to get methods from a superclass,
/// call this on `[self` superclass].
@property (nonatomic, readonly, class) NSArray<FLEXMethod *> *flex_allMethods;

/// All instance methods defined directly on the receiving class.
///
/// Only retrieves methods specific to this class; to get methods from a superclass,
/// call this on `[self` superclass].
@property (nonatomic, readonly, class) NSArray<FLEXMethod *> *flex_allInstanceMethods;

/// All class methods defined directly on the receiving class.
///
/// Only retrieves methods specific to this class; to get methods from a superclass,
/// call this on `[self` superclass].
@property (nonatomic, readonly, class) NSArray<FLEXMethod *> *flex_allClassMethods;

/// Returns the instance method with the given name, or `nil` if not found.
+ (nullable FLEXMethod *)flex_methodNamed:(NSString *)name;

/// Returns the class method with the given name, or `nil` if not found.
+ (nullable FLEXMethod *)flex_classMethodNamed:(NSString *)name;

/// Adds a new method to the receiving class with the given selector, type encoding,
/// and implementation.
///
/// This adds an override of a superclass implementation but will not replace
/// an existing implementation in the receiving class. To change an existing
/// implementation, use `replaceImplementationOfMethod:with:useInstance:`
///
/// @param typeEncoding The type encoding string. Consider using `FLEXTypeEncodingString()`
/// For example, for an `NSArray` `count` getter: \n
/// @code FLEXTypeEncodingString(@encode(NSUInteger), 0) @endcode
/// @param instanceMethod `YES` to add an instance method, `NO` to add a class method.
/// @return `YES` if the method was added, `NO` if one with that selector already exists.
+ (BOOL)addMethod:(SEL)selector
     typeEncoding:(NSString *)typeEncoding
   implementation:(IMP)implementation
      toInstances:(BOOL)instanceMethod;

/// Replaces the implementation of a method on the receiving class.
///
/// - If the method does not yet exist on the receiving class, it is added as if
///   `addMethod:typeEncoding:implementation:toInstances:` were called.
/// - If the method already exists, its `IMP` is replaced.
///
/// @param instanceMethod `YES` to replace the instance method, `NO` for the class method.
/// @return The previous `IMP` of the method.
+ (IMP)replaceImplementationOfMethod:(FLEXMethodBase *)method
                                with:(IMP)implementation
                         useInstance:(BOOL)instanceMethod;

/// Swaps the implementations of the given methods on the receiving class.
///
/// If one or neither method exists, they are added with their implementations swapped,
/// as if each method did exist. This method will not fail as long as each
/// `FLEXMethodBase` contains a valid selector.
/// @param instanceMethod `YES` to swizzle instance methods, `NO` for class methods.
+ (void)swizzle:(FLEXMethodBase *)original
           with:(FLEXMethodBase *)other
     onInstance:(BOOL)instanceMethod;

/// Swaps the implementations of the named methods on the receiving class.
/// @param instanceMethod `YES` for instance methods, `NO` for class methods.
/// @return `YES` if successful, `NO` if the selectors could not be resolved.
+ (BOOL)swizzleByName:(NSString *)original
                 with:(NSString *)other
           onInstance:(BOOL)instanceMethod;

/// Swaps the implementations of the methods corresponding to the given selectors.
+ (void)swizzleBySelector:(SEL)original with:(SEL)other onInstance:(BOOL)instanceMethod;

@end


#pragma mark - Ivars

@interface NSObject (Ivars)

/// All instance variables defined directly on the receiving class.
///
/// Only retrieves ivars specific to this class; to get ivars from a superclass,
/// call this on `[self` superclass].
@property (nonatomic, readonly, class) NSArray<FLEXIvar *> *flex_allIvars;

/// Returns the instance variable with the given name, or `nil` if not found.
+ (nullable FLEXIvar *)flex_ivarNamed:(NSString *)name;

/// Returns the address of the given ivar in the receiving object, or `NULL` if not found.
- (nullable void *)flex_getIvarAddress:(FLEXIvar *)ivar;

/// Returns the address of the named ivar in the receiving object, or `NULL` if not found.
- (nullable void *)flex_getIvarAddressByName:(NSString *)name;

/// Returns the address of the given `Ivar` in the receiving object, or `NULL` if not found.
/// Faster than `flex_getIvarAddress:` when you already have the raw `Ivar`
- (nullable void *)flex_getObjcIvarAddress:(Ivar)ivar;

/// Sets the value of the given ivar on the receiving object.
/// Use only when the target ivar holds an object.
- (void)flex_setIvar:(FLEXIvar *)ivar object:(id)value;

/// Sets the value of the named ivar on the receiving object.
/// Use only when the target ivar holds an object.
///
/// @return `YES` if successful, `NO` if the ivar was not found.
- (BOOL)flex_setIvarByName:(NSString *)name object:(id)value;

/// Sets the value of the given `Ivar` on the receiving object.
/// Use only when the target ivar holds an object.
/// Faster than `flex_setIvar:object:` when you already have the raw `Ivar`.
- (void)flex_setObjcIvar:(Ivar)ivar object:(id)value;

/// Sets the value of the given ivar to the \e size bytes at \e value.
/// Prefer one of the object-specific methods above when working with objects.
- (void)flex_setIvar:(FLEXIvar *)ivar value:(void *)value size:(size_t)size;

/// Sets the value of the named ivar to the \e size bytes at \e value.
/// Prefer one of the object-specific methods above when working with objects.
///
/// @return `YES` if successful, `NO` if the ivar was not found.
- (BOOL)flex_setIvarByName:(NSString *)name value:(void *)value size:(size_t)size;

/// Sets the value of the given `Ivar` on the receiving object to the \e size bytes at \e value.
/// Faster than `flex_setIvar:value:size:` when you already have the raw `Ivar`
- (void)flex_setObjcIvar:(Ivar)ivar value:(void *)value size:(size_t)size;

@end


#pragma mark - Properties

@interface NSObject (Properties)

/// All instance and class properties defined directly on the receiving class.
///
/// Only retrieves properties specific to this class; to get properties from a superclass,
/// call this on `[self` superclass].
@property (nonatomic, readonly, class) NSArray<FLEXProperty *> *flex_allProperties;

/// All instance properties defined directly on the receiving class.
///
/// Only retrieves properties specific to this class; to get properties from a superclass,
/// call this on `[self` superclass].
@property (nonatomic, readonly, class) NSArray<FLEXProperty *> *flex_allInstanceProperties;

/// All class properties defined directly on the receiving class.
///
/// Only retrieves properties specific to this class; to get properties from a superclass,
/// call this on `[self` superclass].
@property (nonatomic, readonly, class) NSArray<FLEXProperty *> *flex_allClassProperties;

/// Returns the instance property with the given name, or `nil` if not found.
+ (nullable FLEXProperty *)flex_propertyNamed:(NSString *)name;
/// Returns the class property with the given name, or `nil` if not found.
+ (nullable FLEXProperty *)flex_classPropertyNamed:(NSString *)name;

/// Replaces the given property on the receiving class.
+ (void)flex_replaceProperty:(FLEXProperty *)property;
/// Replaces the named property on the receiving class with the given attributes.
+ (void)flex_replaceProperty:(NSString *)name attributes:(FLEXPropertyAttributes *)attributes;

@end

NS_ASSUME_NONNULL_END
