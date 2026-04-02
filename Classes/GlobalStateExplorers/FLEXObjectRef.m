//
//  FLEXObjectRef.m
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

#import "FLEXObjectRef.h"
#import "FLEXRuntimeUtility.h"
#import "NSArray+FLEX.h"

@interface FLEXObjectRef () {
    /// Used to retain the object if desired
    id _retainer;
}
@property (nonatomic, readonly) BOOL wantsSummary;
@end

@implementation FLEXObjectRef
@synthesize summary = _summary;

+ (instancetype)unretained:(__unsafe_unretained id)object {
    return [self referencing:object showSummary:YES retained:NO];
}

+ (instancetype)unretained:(__unsafe_unretained id)object ivar:(NSString *)ivarName {
    return [[self alloc] initWithObject:object ivarName:ivarName showSummary:YES retained:NO];
}

+ (instancetype)retained:(id)object {
    return [self referencing:object showSummary:YES retained:YES];
}

+ (instancetype)retained:(id)object ivar:(NSString *)ivarName {
    return [[self alloc] initWithObject:object ivarName:ivarName showSummary:YES retained:YES];
}

+ (instancetype)referencing:(__unsafe_unretained id)object retained:(BOOL)retain {
    return retain ? [self retained:object] : [self unretained:object];
}

+ (instancetype)referencing:(__unsafe_unretained id)object ivar:(NSString *)ivarName retained:(BOOL)retain {
    return retain ? [self retained:object ivar:ivarName] : [self unretained:object ivar:ivarName];
}

+ (instancetype)referencing:(__unsafe_unretained id)object showSummary:(BOOL)showSummary retained:(BOOL)retain {
    return [[self alloc] initWithObject:object ivarName:nil showSummary:showSummary retained:retain];
}

+ (NSArray<FLEXObjectRef *> *)referencingAll:(NSArray *)objects retained:(BOOL)retain {
    return [objects flex_mapped:^id(id obj, NSUInteger idx) {
        return [self referencing:obj showSummary:YES retained:retain];
    }];
}

+ (NSArray<FLEXObjectRef *> *)referencingClasses:(NSArray<Class> *)classes {
    return [classes flex_mapped:^id(id obj, NSUInteger idx) {
        return [self referencing:obj showSummary:NO retained:NO];
    }];
}

- (id)initWithObject:(__unsafe_unretained id)object
            ivarName:(NSString *)ivar
         showSummary:(BOOL)showSummary
            retained:(BOOL)retain {
    self = [super init];
    if (self) {
        _object = object;
        _wantsSummary = showSummary;

        if (retain) {
            _retainer = object;
        }

        NSString *class = [FLEXRuntimeUtility safeClassNameForObject:object];
        if (ivar) {
            _reference = [NSString stringWithFormat:@"%@ %@", class, ivar];
        } else if (showSummary) {
            _reference = [NSString stringWithFormat:@"%@ %p", class, object];
        } else {
            _reference = class;
        }
    }

    return self;
}

- (NSString *)summary {
    if (self.wantsSummary) {
        if (!_summary) {
            _summary = [FLEXRuntimeUtility summaryForObject:self.object];
        }

        return _summary;
    }
    else {
        return nil;
    }
}

- (void)retainObject {
    if (!_retainer) {
        _retainer = _object;
    }
}

- (void)releaseObject {
    _retainer = nil;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@: %@>",
        [self class], self.reference
    ];
}

@end
