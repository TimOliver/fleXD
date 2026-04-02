//
//  FLEXHeapEnumerator.h
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
@class FLEXObjectRef;

NS_ASSUME_NONNULL_BEGIN

typedef void (^flex_object_enumeration_block_t)(__unsafe_unretained id object, __unsafe_unretained Class actualClass);

/// Counts and identifies all class instances on the heap.
@interface FLEXHeapSnapshot : NSObject

/// The names of every class instance discovered on the heap.
@property (nonatomic, readonly) NSArray<NSString *> *classNames;
/// A mapping of instance counts to class names.
@property (nonatomic, readonly) NSDictionary<NSString *, NSNumber *> *instanceCountsForClassNames;
/// A mapping of class instance size to class name.
///
/// To roughly calculate the memory usage of an entire class, multiply this number by the instance count.
@property (nonatomic, readonly) NSDictionary<NSString *, NSNumber *> *instanceSizesForClassNames;

@end

@interface FLEXHeapEnumerator : NSObject

/// Use carefully; this method puts a global lock on the heap in between callbacks.
/// 
/// Inspired by:
/// [heap_find.cpp](https://llvm.org/svn/llvm-project/lldb/tags/RELEASE_34/final/examples/darwin/heap_find/heap/heap_find.cpp)
/// and [samdmarshall](https://gist.github.com/samdmarshall/17f4e66b5e2e579fd396)
+ (void)enumerateLiveObjectsUsingBlock:(flex_object_enumeration_block_t)callback
NS_SWIFT_UNAVAILABLE("Use one of the other methods instead.");

/// Returned references are not validated beyond containing a valid isa.
/// To validate them yourself, pass each reference's object to `FLEXPointerIsValidObjcObject`
+ (NSArray<FLEXObjectRef *> *)instancesOfClassWithName:(NSString *)className retained:(BOOL)retain;

/// Returned references have been validated via `FLEXPointerIsValidObjcObject`
/// @param object the object to find references to
/// @param retain whether to retain the objects referencing `object`
+ (NSArray<FLEXObjectRef *> *)objectsWithReferencesToObject:(id)object retained:(BOOL)retain;

/// Capture all live objects on the heap and do with this information what you will.
+ (FLEXHeapSnapshot *)generateHeapSnapshot;

@end

NS_ASSUME_NONNULL_END
