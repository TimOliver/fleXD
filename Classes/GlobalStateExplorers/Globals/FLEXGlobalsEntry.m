//
//  FLEXGlobalsEntry.m
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

#import "FLEXGlobalsEntry.h"

@implementation FLEXGlobalsEntry

+ (instancetype)entryWithEntry:(Class<FLEXGlobalsEntry>)cls row:(FLEXGlobalsRow)row {
    BOOL providesVCs = [cls respondsToSelector:@selector(globalsEntryViewController:)];
    BOOL providesActions = [cls respondsToSelector:@selector(globalsEntryRowAction:)];
    NSParameterAssert(cls);
    NSParameterAssert(providesVCs || providesActions);

    FLEXGlobalsEntry *entry = [self new];
    entry->_entryNameFuture = ^{ return [cls globalsEntryTitle:row]; };

    if (providesVCs) {
        id action = providesActions ? [cls globalsEntryRowAction:row] : nil;
        if (action) {
            entry->_rowAction = action;
        } else {
            entry->_viewControllerFuture = ^{ return [cls globalsEntryViewController:row]; };
        }
    } else {
        entry->_rowAction = [cls globalsEntryRowAction:row];
    }

    return entry;
}

+ (instancetype)entryWithNameFuture:(FLEXGlobalsEntryNameFuture)nameFuture
               viewControllerFuture:(FLEXGlobalsEntryViewControllerFuture)viewControllerFuture {
    NSParameterAssert(nameFuture);
    NSParameterAssert(viewControllerFuture);

    FLEXGlobalsEntry *entry = [self new];
    entry->_entryNameFuture = [nameFuture copy];
    entry->_viewControllerFuture = [viewControllerFuture copy];

    return entry;
}

+ (instancetype)entryWithNameFuture:(FLEXGlobalsEntryNameFuture)nameFuture
                             action:(FLEXGlobalsEntryRowAction)rowSelectedAction {
    NSParameterAssert(nameFuture);
    NSParameterAssert(rowSelectedAction);

    FLEXGlobalsEntry *entry = [self new];
    entry->_entryNameFuture = [nameFuture copy];
    entry->_rowAction = [rowSelectedAction copy];

    return entry;
}

@end

@interface FLEXGlobalsEntry (Debugging)
@property (nonatomic, readonly) NSString *name;
@end

@implementation FLEXGlobalsEntry (Debugging)

- (NSString *)name {
    return self.entryNameFuture();
}

@end

#pragma mark - flex_concreteGlobalsEntry

@implementation NSObject (FLEXGlobalsEntry)

+ (FLEXGlobalsEntry *)flex_concreteGlobalsEntry:(FLEXGlobalsRow)row {
    if ([self conformsToProtocol:@protocol(FLEXGlobalsEntry)]) {
        return [FLEXGlobalsEntry entryWithEntry:self row:row];
    }

    return nil;
}

@end
