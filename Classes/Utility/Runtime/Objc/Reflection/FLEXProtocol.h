//
//  FLEXProtocol.h
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
@class FLEXProperty, FLEXMethodDescription;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FLEXProtocol
/// Wraps an Objective-C `Protocol` object, providing a convenient interface
/// for inspecting its methods, properties, and conformances.
@interface FLEXProtocol : NSObject

/// Every protocol registered with the runtime.
+ (NSArray<FLEXProtocol *> *)allProtocols;
+ (instancetype)protocol:(Protocol *)protocol;

/// The underlying protocol data structure.
@property (nonatomic, readonly) Protocol *objc_protocol;

/// The name of the protocol.
@property (nonatomic, readonly) NSString *name;
/// The required methods of the protocol, if any. This includes property getters and setters.
@property (nonatomic, readonly) NSArray<FLEXMethodDescription *> *requiredMethods;
/// The optional methods of the protocol, if any. This includes property getters and setters.
@property (nonatomic, readonly) NSArray<FLEXMethodDescription *> *optionalMethods;
/// All protocols that this protocol conforms to, if any.
@property (nonatomic, readonly) NSArray<FLEXProtocol *> *protocols;
/// The full path of the image that contains this protocol definition,
/// or `nil` if this protocol was probably defined at runtime.
@property (nonatomic, readonly, nullable) NSString *imagePath;

/// The required properties in the protocol, if any.
@property (nonatomic, readonly) NSArray<FLEXProperty *> *requiredProperties;
/// The optional properties in the protocol, if any.
@property (nonatomic, readonly) NSArray<FLEXProperty *> *optionalProperties;

/// For internal use
@property (nonatomic) id tag;

/// Not to be confused with `-conformsToProtocol:` which refers to the current
/// `FLEXProtocol` instance and not the underlying `Protocol` object.
- (BOOL)conformsTo:(Protocol *)protocol;

@end


#pragma mark - Method descriptions
/// A description of a method declared in a protocol, including its selector,
/// type encoding, and whether it is an instance or class method.
@interface FLEXMethodDescription : NSObject

+ (instancetype)description:(struct objc_method_description)description;
+ (instancetype)description:(struct objc_method_description)description instance:(BOOL)isInstance;

/// The underlying method description data structure.
@property (nonatomic, readonly) struct objc_method_description objc_description;
/// The method's selector.
@property (nonatomic, readonly) SEL selector;
/// The method's type encoding.
@property (nonatomic, readonly) NSString *typeEncoding;
/// The method's return type.
@property (nonatomic, readonly) FLEXTypeEncoding returnType;
/// `YES` if this is an instance method, `NO` if it is a class method, or `nil` if unspecified
@property (nonatomic, readonly) NSNumber *instance;
@end

NS_ASSUME_NONNULL_END
