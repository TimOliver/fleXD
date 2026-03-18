//
//  FLEXMethodBase.h
//  FLEX
//
//  Derived from MirrorKit.
//  Created by Tanner on 7/5/15.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A base class representing a method that may or may not yet be registered with a class.
///
/// Useful on its own for adding methods to a class or building a new class from scratch.
/// `FLEXMethod` is the concrete subclass for methods already registered in the runtime.
@interface FLEXMethodBase : NSObject {
@protected
    SEL      _selector;
    NSString *_name;
    NSString *_typeEncoding;
    IMP      _implementation;
    NSString *_flex_description;
}

/// Creates a method descriptor with the given name, type encoding, and implementation.
+ (instancetype)buildMethodNamed:(NSString *)name
                       withTypes:(NSString *)typeEncoding
                  implementation:(IMP)implementation;

/// The selector of the method.
@property (nonatomic, readonly) SEL      selector;
/// The string form of the method's selector. Same as `name`
@property (nonatomic, readonly) NSString *selectorString;
/// The string form of the method's selector. Same as `selectorString`
@property (nonatomic, readonly) NSString *name;
/// The type encoding of the method.
@property (nonatomic, readonly) NSString *typeEncoding;
/// The implementation of the method.
@property (nonatomic, readonly) IMP      implementation;

/// For internal use.
@property (nonatomic) id tag;

@end

NS_ASSUME_NONNULL_END
