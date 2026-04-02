//
//  FLEXFileBrowserSearchOperation.m
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

#import "FLEXFileBrowserSearchOperation.h"

@implementation NSMutableArray (FLEXStack)

- (void)flex_push:(id)anObject {
    [self addObject:anObject];
}

- (id)flex_pop {
    id anObject = self.lastObject;
    [self removeLastObject];
    return anObject;
}

@end

@interface FLEXFileBrowserSearchOperation ()

@property (nonatomic) NSString *path;
@property (nonatomic) NSString *searchString;

@end

@implementation FLEXFileBrowserSearchOperation

#pragma mark - private

- (uint64_t)totalSizeAtPath:(NSString *)path {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSDictionary<NSString *, id> *attributes = [fileManager attributesOfItemAtPath:path error:NULL];
    uint64_t totalSize = [attributes fileSize];

    for (NSString *fileName in [fileManager enumeratorAtPath:path]) {
        attributes = [fileManager attributesOfItemAtPath:[path stringByAppendingPathComponent:fileName] error:NULL];
        totalSize += [attributes fileSize];
    }
    return totalSize;
}

#pragma mark - instance method

- (id)initWithPath:(NSString *)currentPath searchString:(NSString *)searchString {
    self = [super init];
    if (self) {
        self.path = currentPath;
        self.searchString = searchString;
    }
    return self;
}

#pragma mark - methods to override

- (void)main {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSMutableArray<NSString *> *searchPaths = [NSMutableArray new];
    NSMutableDictionary<NSString *, NSNumber *> *sizeMapping = [NSMutableDictionary new];
    uint64_t totalSize = 0;
    NSMutableArray<NSString *> *stack = [NSMutableArray new];
    [stack flex_push:self.path];

    //recursive found all match searchString paths, and precomputing there size
    while (stack.count) {
        NSString *currentPath = [stack flex_pop];
        NSArray<NSString *> *directoryPath = [fileManager contentsOfDirectoryAtPath:currentPath error:nil];

        for (NSString *subPath in directoryPath) {
            NSString *fullPath = [currentPath stringByAppendingPathComponent:subPath];

            if ([[subPath lowercaseString] rangeOfString:[self.searchString lowercaseString]].location != NSNotFound) {
                [searchPaths addObject:fullPath];
                if (!sizeMapping[fullPath]) {
                    uint64_t fullPathSize = [self totalSizeAtPath:fullPath];
                    totalSize += fullPathSize;
                    [sizeMapping setObject:@(fullPathSize) forKey:fullPath];
                }
            }
            BOOL isDirectory;
            if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory] && isDirectory) {
                [stack flex_push:fullPath];
            }

            if ([self isCancelled]) {
                return;
            }
        }
    }

    //sort
    NSArray<NSString *> *sortedArray = [searchPaths sortedArrayUsingComparator:^NSComparisonResult(NSString *path1, NSString *path2) {
        uint64_t pathSize1 = [sizeMapping[path1] unsignedLongLongValue];
        uint64_t pathSize2 = [sizeMapping[path2] unsignedLongLongValue];
        if (pathSize1 < pathSize2) {
            return NSOrderedAscending;
        } else if (pathSize1 > pathSize2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];

    if ([self isCancelled]) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate fileBrowserSearchOperationResult:sortedArray size:totalSize];
    });
}

@end
