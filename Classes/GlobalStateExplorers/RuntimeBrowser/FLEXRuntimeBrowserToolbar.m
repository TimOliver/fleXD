//
//  FLEXRuntimeBrowserToolbar.m
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

#import "FLEXRuntimeBrowserToolbar.h"
#import "FLEXRuntimeKeyPathTokenizer.h"

@interface FLEXRuntimeBrowserToolbar ()
@property (nonatomic, copy) FLEXKBToolbarAction tapHandler;
@end

@implementation FLEXRuntimeBrowserToolbar

+ (instancetype)toolbarWithHandler:(FLEXKBToolbarAction)tapHandler suggestions:(NSArray<NSString *> *)suggestions {
    NSArray *buttons = [self
        buttonsForKeyPath:FLEXRuntimeKeyPath.empty suggestions:suggestions handler:tapHandler
    ];

    FLEXRuntimeBrowserToolbar *me = [self toolbarWithButtons:buttons];
    me.tapHandler = tapHandler;
    return me;
}

+ (NSArray<FLEXKBToolbarButton*> *)buttonsForKeyPath:(FLEXRuntimeKeyPath *)keyPath
                                     suggestions:(NSArray<NSString *> *)suggestions
                                         handler:(FLEXKBToolbarAction)handler {
    NSMutableArray *buttons = [NSMutableArray new];
    FLEXSearchToken *lastKey = nil;
    BOOL lastKeyIsMethod = NO;

    if (keyPath.methodKey) {
        lastKey = keyPath.methodKey;
        lastKeyIsMethod = YES;
    } else {
        lastKey = keyPath.classKey ?: keyPath.bundleKey;
    }

    switch (lastKey.options) {
        case TBWildcardOptionsNone:
        case TBWildcardOptionsAny:
            if (lastKeyIsMethod) {
                if (!keyPath.instanceMethods) {
                    [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"-" action:handler]];
                    [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"+" action:handler]];
                }
                [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"*" action:handler]];
            } else {
                [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"*" action:handler]];
                [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"*." action:handler]];
            }
            break;

        default: {
            if (lastKey.options & TBWildcardOptionsPrefix) {
                if (lastKeyIsMethod) {
                    if (lastKey.string.length) {
                        [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"*" action:handler]];
                    }
                } else {
                    if (lastKey.string.length) {
                        [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"*." action:handler]];
                    }
                }
            }

            else if (lastKey.options & TBWildcardOptionsSuffix) {
                if (!lastKeyIsMethod) {
                    [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"*" action:handler]];
                    [buttons addObject:[FLEXKBToolbarButton buttonWithTitle:@"*." action:handler]];
                }
            }
        }
    }

    for (NSString *suggestion in suggestions) {
        [buttons addObject:[FLEXKBToolbarSuggestedButton buttonWithTitle:suggestion action:handler]];
    }

    return buttons;
}

- (void)setKeyPath:(FLEXRuntimeKeyPath *)keyPath suggestions:(NSArray<NSString *> *)suggestions {
    self.buttons = [self.class
        buttonsForKeyPath:keyPath suggestions:suggestions handler:self.tapHandler
    ];
}

@end
