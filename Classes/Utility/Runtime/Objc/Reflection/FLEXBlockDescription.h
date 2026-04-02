//
//  FLEXBlockDescription.h
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

typedef NS_OPTIONS(NSUInteger, FLEXBlockOptions) {
   FLEXBlockOptionHasCopyDispose = (1 << 25),
   FLEXBlockOptionHasCtor        = (1 << 26), // helpers have C++ code
   FLEXBlockOptionIsGlobal       = (1 << 28),
   FLEXBlockOptionHasStret       = (1 << 29), // IFF BLOCK_HAS_SIGNATURE
   FLEXBlockOptionHasSignature   = (1 << 30),
};

NS_ASSUME_NONNULL_BEGIN

/// Provides introspection capabilities for Objective-C block objects.
///
/// Given a block, this class can expose the block's method signature,
/// source declaration, internal flags, and memory size, as well as
/// determine compatibility for block-based method swizzling.
@interface FLEXBlockDescription : NSObject

/// @param block Any Objective-C block object.
+ (instancetype)describing:(id)block;

/// The method signature of the block, if it has one, derived from `FLEXBlockOptionHasSignature`
@property (nonatomic, readonly, nullable) NSMethodSignature *signature;

/// A human-readable string representation of the block's signature, if available.
@property (nonatomic, readonly, nullable) NSString *signatureString;

/// The source declaration of the block as encoded at compile time, if available.
@property (nonatomic, readonly, nullable) NSString *sourceDeclaration;

/// The raw option flags of the block's internal layout structure.
@property (nonatomic, readonly) FLEXBlockOptions flags;

/// The total size of the block's internal layout structure in bytes.
@property (nonatomic, readonly) NSUInteger size;

/// A human-readable summary of the block's attributes.
@property (nonatomic, readonly) NSString *summary;

/// The original block object passed to `+describing:`
@property (nonatomic, readonly) id block;

/// @return `YES` if the block's signature is compatible with the given method signature
/// for the purpose of block-based method swizzling.
- (BOOL)isCompatibleForBlockSwizzlingWithMethodSignature:(NSMethodSignature *)methodSignature;

@end

/// A minimal interface for Objective-C block objects, enabling invocation without arguments.
@interface NSBlock : NSObject
- (void)invoke;
@end

NS_ASSUME_NONNULL_END
