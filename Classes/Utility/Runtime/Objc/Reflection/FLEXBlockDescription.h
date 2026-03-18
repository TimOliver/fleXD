//
//  FLEXBlockDescription.h
//  FLEX
//
//  Created by Oliver Letterer on 2012-09-01
//  Forked from CTObjectiveCRuntimeAdditions (MIT License)
//  https://github.com/ebf/CTObjectiveCRuntimeAdditions
//
//  Copyright (c) 2020 FLEX Team-EDV Beratung Föllmer GmbH
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this
//  software and associated documentation files (the "Software"), to deal in the Software
//  without restriction, including without limitation the rights to use, copy, modify, merge,
//  publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
//  to whom the Software is furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or
//  substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
//  BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//  DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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

/// The method signature of the block, if it has one, derived from \c FLEXBlockOptionHasSignature.
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
/// The original block object passed to \c +describing:
@property (nonatomic, readonly) id block;

/// @return \c YES if the block's signature is compatible with the given method signature
/// for the purpose of block-based method swizzling.
- (BOOL)isCompatibleForBlockSwizzlingWithMethodSignature:(NSMethodSignature *)methodSignature;

@end

/// A minimal interface for Objective-C block objects, enabling invocation without arguments.
@interface NSBlock : NSObject
- (void)invoke;
@end

NS_ASSUME_NONNULL_END
