//
//  FLEXProtocolBuilder.h
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
