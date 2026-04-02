//
//  FHSViewSnapshot.m
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

#import "FHSViewSnapshot.h"
#import "NSArray+FLEX.h"

@implementation FHSViewSnapshot

+ (instancetype)snapshotWithView:(FHSView *)view {
    NSArray *children = [view.children flex_mapped:^id(FHSView *v, NSUInteger idx) {
        return [self snapshotWithView:v];
    }];
    return [[self alloc] initWithView:view children:children];
}

- (id)initWithView:(FHSView *)view children:(NSArray<FHSViewSnapshot *> *)children {
    NSParameterAssert(view); NSParameterAssert(children);

    self = [super init];
    if (self) {
        _view = view;
        _title = view.title;
        _important = view.important;
        _frame = view.frame;
        _hidden = view.hidden;
        _snapshotImage = view.snapshotImage;
        _children = children;
        _summary = view.summary;
    }

    return self;
}

- (UIColor *)headerColor {
    if (self.important) {
        return [UIColor colorWithRed: 0.000 green: 0.533 blue: 1.000 alpha: 0.900];
    } else {
        return [UIColor colorWithRed:0.961 green: 0.651 blue: 0.137 alpha: 0.900];
    }
}

- (FHSViewSnapshot *)snapshotForView:(UIView *)view {
    if (view == self.view.view) {
        return self;
    }

    for (FHSViewSnapshot *child in self.children) {
        FHSViewSnapshot *snapshot = [child snapshotForView:view];
        if (snapshot) {
            return snapshot;
        }
    }

    return nil;
}

@end
