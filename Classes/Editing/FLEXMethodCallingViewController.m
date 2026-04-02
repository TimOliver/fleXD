//
//  FLEXMethodCallingViewController.m
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

#import "FLEXMethodCallingViewController.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXFieldEditorView.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXArgumentInputView.h"
#import "FLEXArgumentInputViewFactory.h"
#import "FLEXUtility.h"

@interface FLEXMethodCallingViewController ()
@property (nonatomic, readonly) FLEXMethod *method;
@end

@implementation FLEXMethodCallingViewController

+ (instancetype)target:(id)target method:(FLEXMethod *)method {
    return [[self alloc] initWithTarget:target method:method];
}

- (id)initWithTarget:(id)target method:(FLEXMethod *)method {
    NSParameterAssert(method.isInstanceMethod == !object_isClass(target));

    self = [super initWithTarget:target data:method commitHandler:nil];
    if (self) {
        self.title = method.isInstanceMethod ? @"Method: " : @"Class Method: ";
        self.title = [self.title stringByAppendingString:method.selectorString];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.actionButton.title = @"Call";

    // Configure field editor view
    self.fieldEditorView.argumentInputViews = [self argumentInputViews];
    self.fieldEditorView.fieldDescription = [NSString stringWithFormat:
        @"Signature:\n%@\n\nReturn Type:\n%s",
        self.method.description, (char *)self.method.returnType
    ];
}

- (NSArray<FLEXArgumentInputView *> *)argumentInputViews {
    Method method = self.method.objc_method;
    NSArray *methodComponents = [FLEXRuntimeUtility prettyArgumentComponentsForMethod:method];
    NSMutableArray<FLEXArgumentInputView *> *argumentInputViews = [NSMutableArray new];
    unsigned int argumentIndex = kFLEXNumberOfImplicitArgs;

    for (NSString *methodComponent in methodComponents) {
        char *argumentTypeEncoding = method_copyArgumentType(method, argumentIndex);
        FLEXArgumentInputView *inputView = [FLEXArgumentInputViewFactory argumentInputViewForTypeEncoding:argumentTypeEncoding];
        free(argumentTypeEncoding);

        inputView.backgroundColor = self.view.backgroundColor;
        inputView.title = methodComponent;
        [argumentInputViews addObject:inputView];
        argumentIndex++;
    }

    return argumentInputViews;
}

- (void)actionButtonPressed:(id)sender {
    // Gather arguments
    NSMutableArray *arguments = [NSMutableArray new];
    for (FLEXArgumentInputView *inputView in self.fieldEditorView.argumentInputViews) {
        // Use NSNull as a nil placeholder; it will be interpreted as nil
        [arguments addObject:inputView.inputValue ?: NSNull.null];
    }

    // Call method
    NSError *error = nil;
    id returnValue = [FLEXRuntimeUtility
        performSelector:self.method.selector
        onObject:self.target
        withArguments:arguments
        error:&error
    ];

    // Dismiss keyboard and handle committed changes
    [super actionButtonPressed:sender];

    // Display return value or error
    if (error) {
        [FLEXAlert showAlert:@"Method Call Failed" message:error.localizedDescription from:self];
    } else if (returnValue) {
        // For non-nil (or void) return types, push an explorer view controller to display the returned object
        returnValue = [FLEXRuntimeUtility potentiallyUnwrapBoxedPointer:returnValue type:self.method.returnType];
        FLEXObjectExplorerViewController *explorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:returnValue];
        [self.navigationController pushViewController:explorer animated:YES];
    } else {
        [self exploreObjectOrPopViewController:returnValue];
    }
}

- (FLEXMethod *)method {
    return _data;
}

@end
