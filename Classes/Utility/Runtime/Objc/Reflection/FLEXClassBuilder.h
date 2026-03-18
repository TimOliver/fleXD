//
//  FLEXClassBuilder.h
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 7/3/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FLEXIvarBuilder, FLEXMethodBase, FLEXProperty, FLEXProtocol;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FLEXClassBuilder

/// Constructs or modifies an Objective-C class at runtime.
///
/// New classes must be registered using \c registerClass before they can be used.
/// Instance variables cannot be added to existing or already-registered classes.
@interface FLEXClassBuilder : NSObject

/// The class being constructed or modified.
@property (nonatomic, readonly) Class workingClass;

/// Begins constructing a new class named \e name, inheriting from \c NSObject.
+ (instancetype)allocateClass:(NSString *)name;

/// Begins constructing a new class named \e name, inheriting from \e superclass.
+ (instancetype)allocateClass:(NSString *)name superclass:(Class)superclass;

/// Begins constructing a new class named \e name, inheriting from \e superclass,
/// with \e bytes of extra storage allocated per instance.
/// Pass \c nil for \e superclass to create a new root class.
+ (instancetype)allocateClass:(NSString *)name
                   superclass:(nullable Class)superclass
                   extraBytes:(size_t)bytes;

/// Begins constructing a new root class with no superclass.
+ (instancetype)allocateRootClass:(NSString *)name;

/// Returns a builder for modifying an existing class.
/// @warning Instance variables cannot be added to existing classes.
+ (instancetype)builderForClass:(Class)cls;

/// Adds methods to the working class.
/// @return Any methods that could not be added.
- (NSArray<FLEXMethodBase *> *)addMethods:(NSArray<FLEXMethodBase *> *)methods;

/// Adds properties to the working class.
/// @return Any properties that could not be added.
- (NSArray<FLEXProperty *> *)addProperties:(NSArray<FLEXProperty *> *)properties;

/// Adds protocol conformances to the working class.
/// @return Any protocols that could not be added.
- (NSArray<FLEXProtocol *> *)addProtocols:(NSArray<FLEXProtocol *> *)protocols;

/// Adds instance variables to the working class.
/// @warning Adding instance variables to existing classes is not supported and will always fail.
/// @return Any ivars that could not be added.
- (NSArray<FLEXIvarBuilder *> *)addIvars:(NSArray<FLEXIvarBuilder *> *)ivars;

/// Finalizes and registers the new class, making it available to the runtime.
/// Once registered, instance variables cannot be added.
/// @note Raises an exception if called on an already-registered class.
- (Class)registerClass;

/// Whether the working class has been registered with the runtime.
@property (nonatomic, readonly) BOOL isRegistered;

@end


#pragma mark - FLEXIvarBuilder

/// Describes an instance variable to be added to a class under construction.
///
/// Use the \c FLEXIvarBuilderWithNameAndType() convenience macro where possible.
@interface FLEXIvarBuilder : NSObject

/// Creates an ivar descriptor with the given name, size, alignment, and type encoding.
/// @param name The name of the ivar, e.g. \c @"_value".
/// @param size The size of the ivar in bytes, e.g. \c sizeof(type).
/// @param alignment The required alignment, e.g. \c log2(sizeof(type)).
/// @param encoding The type encoding, e.g. \c @(@encode(type)).
+ (instancetype)name:(NSString *)name
                size:(size_t)size
           alignment:(uint8_t)alignment
        typeEncoding:(NSString *)encoding;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *encoding;
@property (nonatomic, readonly) size_t   size;
@property (nonatomic, readonly) uint8_t  alignment;

@end


/// Convenience macro that creates a \c FLEXIvarBuilder from a name string and a C type.
#define FLEXIvarBuilderWithNameAndType(nameString, type) [FLEXIvarBuilder \
    name:nameString \
    size:sizeof(type) \
    alignment:log2(sizeof(type)) \
    typeEncoding:@(@encode(type)) \
]

NS_ASSUME_NONNULL_END
