//
//  NSArray+FLEX.m
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

#import "NSArray+FLEX.h"

#define FLEXArrayClassIsMutable(me) ([[self class] isSubclassOfClass:[NSMutableArray class]])

@implementation NSArray (Functional)

- (__kindof NSArray *)flex_mapped:(id (^)(id, NSUInteger))mapFunc {
    NSMutableArray *map = [NSMutableArray new];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id ret = mapFunc(obj, idx);
        if (ret) {
            [map addObject:ret];
        }
    }];

    if (self.count < 2048 && !FLEXArrayClassIsMutable(self)) {
        return map.copy;
    }

    return map;
}

- (__kindof NSArray *)flex_flatmapped:(NSArray *(^)(id, NSUInteger))block {
    NSMutableArray *array = [NSMutableArray new];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *toAdd = block(obj, idx);
        if (toAdd) {
            [array addObjectsFromArray:toAdd];
        }
    }];

    if (array.count < 2048 && !FLEXArrayClassIsMutable(self)) {
        return array.copy;
    }

    return array;
}

- (NSArray *)flex_filtered:(BOOL (^)(id, NSUInteger))filterFunc {
    return [self flex_mapped:^id(id obj, NSUInteger idx) {
        return filterFunc(obj, idx) ? obj : nil;
    }];
}

- (void)flex_forEach:(void(^)(id, NSUInteger))block {
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        block(obj, idx);
    }];
}

- (instancetype)flex_subArrayUpto:(NSUInteger)maxLength {
    if (maxLength > self.count) {
        if (FLEXArrayClassIsMutable(self)) {
            return self.mutableCopy;
        }

        return self;
    }

    return [self subarrayWithRange:NSMakeRange(0, maxLength)];
}

+ (__kindof NSArray *)flex_forEachUpTo:(NSUInteger)bound map:(id(^)(NSUInteger))block {
    NSMutableArray *array = [NSMutableArray new];
    for (NSUInteger i = 0; i < bound; i++) {
        id obj = block(i);
        if (obj) {
            [array addObject:obj];
        }
    }

    // For performance reasons, don't copy large arrays
    if (bound < 2048 && !FLEXArrayClassIsMutable(self)) {
        return array.copy;
    }

    return array;
}

+ (instancetype)flex_mapped:(id<NSFastEnumeration>)collection block:(id(^)(id obj, NSUInteger idx))mapFunc {
    NSMutableArray *array = [NSMutableArray new];
    NSInteger idx = 0;
    for (id obj in collection) {
        id ret = mapFunc(obj, idx++);
        if (ret) {
            [array addObject:ret];
        }
    }

    // For performance reasons, don't copy large arrays
    if (array.count < 2048) {
        return array.copy;
    }

    return array;
}

- (instancetype)flex_sortedUsingSelector:(SEL)selector {
    if (FLEXArrayClassIsMutable(self)) {
        NSMutableArray *me = (id)self;
        [me sortUsingSelector:selector];
        return me;
    } else {
        return [self sortedArrayUsingSelector:selector];
    }
}

- (id)flex_firstWhere:(BOOL (^)(id))meetsCriteria {
    for (id e in self) {
        if (meetsCriteria(e)) {
            return e;
        }
    }

    return nil;
}

@end


@implementation NSMutableArray (Functional)

- (void)flex_filter:(BOOL (^)(id, NSUInteger))keepObject {
    NSMutableIndexSet *toRemove = [NSMutableIndexSet new];

    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (!keepObject(obj, idx)) {
            [toRemove addIndex:idx];
        }
    }];

    [self removeObjectsAtIndexes:toRemove];
}

@end
