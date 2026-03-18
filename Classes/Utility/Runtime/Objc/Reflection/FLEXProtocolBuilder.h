//
//  FLEXProtocolBuilder.h
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 7/4/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FLEXProperty, FLEXProtocol;

NS_ASSUME_NONNULL_BEGIN

/// Constructs and registers a new Objective-C protocol at runtime.
///
/// You must call `registerProtocol` before the protocol can be used.
/// Once registered, no further modifications can be made.
@interface FLEXProtocolBuilder : NSObject

/// Begins constructing a new protocol with the given name.
+ (instancetype)allocateProtocol:(NSString *)name;

/// Adds a property to the protocol under construction.
/// @param property The property to add.
/// @param isRequired Whether conforming classes must implement this property.
- (void)addProperty:(FLEXProperty *)property isRequired:(BOOL)isRequired;

/// Adds a method to the protocol under construction.
/// @param selector The selector of the method to add.
/// @param typeEncoding The type encoding of the method.
/// @param isRequired Whether the method is required for conformance.
/// @param isInstanceMethod `YES` for an instance method, `NO` for a class method.
- (void)addMethod:(SEL)selector
     typeEncoding:(NSString *)typeEncoding
       isRequired:(BOOL)isRequired
 isInstanceMethod:(BOOL)isInstanceMethod;

/// Makes the protocol under construction conform to the given protocol.
- (void)addProtocol:(Protocol *)protocol;

/// Registers and returns the completed protocol, making it available to the runtime.
- (FLEXProtocol *)registerProtocol;

/// Whether the protocol has been registered with the runtime.
@property (nonatomic, readonly) BOOL isRegistered;

@end

NS_ASSUME_NONNULL_END
