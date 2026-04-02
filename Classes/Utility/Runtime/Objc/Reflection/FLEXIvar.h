//
//  FLEXIvar.h
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

NS_ASSUME_NONNULL_BEGIN

/// Wraps an Objective-C `Ivar` data structure, providing a convenient interface
/// for reading and writing instance variable values on an arbitrary object.
@interface FLEXIvar : NSObject

+ (instancetype)ivar:(Ivar)ivar;
+ (instancetype)named:(NSString *)name onClass:(Class)cls;

/// The underlying `Ivar` data structure.
@property (nonatomic, readonly) Ivar             objc_ivar;

/// The name of the instance variable.
@property (nonatomic, readonly) NSString         *name;
/// The type of the instance variable.
@property (nonatomic, readonly) FLEXTypeEncoding type;
/// The type encoding string of the instance variable.
@property (nonatomic, readonly) NSString         *typeEncoding;
/// The offset of the instance variable.
@property (nonatomic, readonly) NSInteger        offset;
/// The size of the instance variable. 0 if unknown.
@property (nonatomic, readonly) NSUInteger       size;
/// Describes the type encoding, size, offset, and objc_ivar
@property (nonatomic, readonly) NSString        *details;
/// The full path of the image that contains this ivar definition,
/// or `nil` if this ivar was probably defined at runtime.
@property (nonatomic, readonly, nullable) NSString *imagePath;

/// For internal use
@property (nonatomic) id tag;

- (nullable id)getValue:(id)target;
- (void)setValue:(nullable id)value onObject:(id)target;

/// Like `getValue:` but passes the result through
/// `-[FLEXRuntimeUtility potentiallyUnwrapBoxedPointer:type:]`,
/// which unwraps boxed pointer types where possible.
- (nullable id)getPotentiallyUnboxedValue:(id)target;

@end

NS_ASSUME_NONNULL_END
