//
//  FLEXObjectRef.h
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

@interface FLEXObjectRef : NSObject

/// Reference an object without affecting its lifespan or or emitting reference-counting operations.
+ (instancetype)unretained:(__unsafe_unretained id)object;
+ (instancetype)unretained:(__unsafe_unretained id)object ivar:(NSString *)ivarName;

/// Reference an object and control its lifespan.
+ (instancetype)retained:(id)object;
+ (instancetype)retained:(id)object ivar:(NSString *)ivarName;

/// Reference an object and conditionally choose to retain it or not.
+ (instancetype)referencing:(__unsafe_unretained id)object retained:(BOOL)retain;
+ (instancetype)referencing:(__unsafe_unretained id)object ivar:(NSString *)ivarName retained:(BOOL)retain;

+ (NSArray<FLEXObjectRef *> *)referencingAll:(NSArray *)objects retained:(BOOL)retain;
/// Classes do not have a summary, and the reference is just the class name.
+ (NSArray<FLEXObjectRef *> *)referencingClasses:(NSArray<Class> *)classes;

/// For example, "NSString 0x1d4085d0" or "NSLayoutConstraint _object"
@property (nonatomic, readonly) NSString *reference;

/// For instances, this is the result of -[FLEXRuntimeUtility summaryForObject:]
/// For classes, there is no summary.
@property (nonatomic, readonly) NSString *summary;
@property (nonatomic, readonly, unsafe_unretained) id object;

/// Retains the referenced object if it is not already retained
- (void)retainObject;
/// Releases the referenced object if it is already retained
- (void)releaseObject;

@end
