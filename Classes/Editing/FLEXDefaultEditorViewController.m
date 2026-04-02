//
//  FLEXDefaultEditorViewController.m
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

#import "FLEXDefaultEditorViewController.h"
#import "FLEXFieldEditorView.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXArgumentInputView.h"
#import "FLEXArgumentInputViewFactory.h"

@interface FLEXDefaultEditorViewController ()

@property (nonatomic, readonly) NSUserDefaults *defaults;
@property (nonatomic, readonly) NSString *key;

@end

@implementation FLEXDefaultEditorViewController

+ (instancetype)target:(NSUserDefaults *)defaults key:(NSString *)key commitHandler:(void(^_Nullable)(void))onCommit {
    FLEXDefaultEditorViewController *editor = [self target:defaults data:key commitHandler:onCommit];
    editor.title = @"Edit Default";
    return editor;
}

- (NSUserDefaults *)defaults {
    return [_target isKindOfClass:[NSUserDefaults class]] ? _target : nil;
}

- (NSString *)key {
    return _data;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.fieldEditorView.fieldDescription = self.key;

    id currentValue = [self.defaults objectForKey:self.key];
    FLEXArgumentInputView *inputView = [FLEXArgumentInputViewFactory
        argumentInputViewForTypeEncoding:FLEXEncodeObject(currentValue)
        currentValue:currentValue
    ];
    inputView.backgroundColor = self.view.backgroundColor;
    inputView.inputValue = currentValue;
    self.fieldEditorView.argumentInputViews = @[inputView];
}

- (void)actionButtonPressed:(id)sender {
    id value = self.firstInputView.inputValue;
    if (value) {
        [self.defaults setObject:value forKey:self.key];
    } else {
        [self.defaults removeObjectForKey:self.key];
    }
    [self.defaults synchronize];

    // Dismiss keyboard and handle committed changes
    [super actionButtonPressed:sender];

    // Go back after setting, but not for switches.
    if (sender) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        self.firstInputView.inputValue = [self.defaults objectForKey:self.key];
    }
}

+ (BOOL)canEditDefaultWithValue:(id)currentValue {
    return [FLEXArgumentInputViewFactory
        canEditFieldWithTypeEncoding:FLEXEncodeObject(currentValue)
        currentValue:currentValue
    ];
}

@end
