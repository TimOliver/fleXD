//
//  FLEXVariableEditorViewController.m
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

#import "FLEXColor.h"
#import "FLEXVariableEditorViewController.h"
#import "FLEXFieldEditorView.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXUtility.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXArgumentInputView.h"
#import "FLEXArgumentInputViewFactory.h"
#import "FLEXObjectExplorerViewController.h"
#import "UIBarButtonItem+FLEX.h"

@interface FLEXVariableEditorViewController () <UIScrollViewDelegate>
@property (nonatomic) UIScrollView *scrollView;
@end

@implementation FLEXVariableEditorViewController

#pragma mark - Initialization

+ (instancetype)target:(id)target data:(nullable id)data commitHandler:(void(^_Nullable)(void))onCommit {
    return [[self alloc] initWithTarget:target data:data commitHandler:onCommit];
}

- (id)initWithTarget:(id)target data:(nullable id)data commitHandler:(void(^_Nullable)(void))onCommit {
    self = [super init];
    if (self) {
        _target = target;
        _data = data;
        _commitHandler = onCommit;
        [NSNotificationCenter.defaultCenter
            addObserver:self selector:@selector(keyboardDidShow:)
            name:UIKeyboardWillShowNotification object:nil
        ];
        [NSNotificationCenter.defaultCenter
            addObserver:self selector:@selector(keyboardWillHide:)
            name:UIKeyboardWillHideNotification object:nil
        ];
    }

    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - UIViewController methods

- (void)keyboardDidShow:(NSNotification *)notification {
    CGRect keyboardRectInWindow = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGSize keyboardSize = [self.view convertRect:keyboardRectInWindow fromView:nil].size;
    UIEdgeInsets scrollInsets = self.scrollView.contentInset;
    scrollInsets.bottom = keyboardSize.height;
    self.scrollView.contentInset = scrollInsets;
    self.scrollView.scrollIndicatorInsets = scrollInsets;

    // Find the active input view and scroll to make sure it's visible.
    for (FLEXArgumentInputView *argumentInputView in self.fieldEditorView.argumentInputViews) {
        if (argumentInputView.inputViewIsFirstResponder) {
            CGRect scrollToVisibleRect = [self.scrollView convertRect:argumentInputView.bounds fromView:argumentInputView];
            [self.scrollView scrollRectToVisible:scrollToVisibleRect animated:YES];
            break;
        }
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    UIEdgeInsets scrollInsets = self.scrollView.contentInset;
    scrollInsets.bottom = 0.0;
    self.scrollView.contentInset = scrollInsets;
    self.scrollView.scrollIndicatorInsets = scrollInsets;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = FLEXColor.scrollViewBackgroundColor;

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.backgroundColor = self.view.backgroundColor;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];

    _fieldEditorView = [FLEXFieldEditorView new];
    self.fieldEditorView.targetDescription = [NSString stringWithFormat:@"%@ %p", [self.target class], self.target];
    [self.scrollView addSubview:self.fieldEditorView];

    _actionButton = [[UIBarButtonItem alloc]
        initWithTitle:@"Set"
        style:UIBarButtonItemStyleDone
        target:self
        action:@selector(actionButtonPressed:)
    ];

    self.navigationController.toolbarHidden = NO;
    self.toolbarItems = @[UIBarButtonItem.flex_flexibleSpace, self.actionButton];
}

- (void)viewWillLayoutSubviews {
    CGSize constrainSize = CGSizeMake(self.scrollView.bounds.size.width, CGFLOAT_MAX);
    CGSize fieldEditorSize = [self.fieldEditorView sizeThatFits:constrainSize];
    self.fieldEditorView.frame = CGRectMake(0, 0, fieldEditorSize.width, fieldEditorSize.height);
    self.scrollView.contentSize = fieldEditorSize;
}

#pragma mark - Public

- (FLEXArgumentInputView *)firstInputView {
    return [self.fieldEditorView argumentInputViews].firstObject;
}

- (void)actionButtonPressed:(id)sender {
    // Subclasses can override
    [self.fieldEditorView endEditing:YES];
    if (_commitHandler) {
        _commitHandler();
    }
}

- (void)exploreObjectOrPopViewController:(id)objectOrNil {
    if (objectOrNil) {
        // For non-nil (or void) return types, push an explorer view controller to display the object
        FLEXObjectExplorerViewController *explorerViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:objectOrNil];
        [self.navigationController pushViewController:explorerViewController animated:YES];
    } else {
        // If we didn't get a returned object but the method call succeeded,
        // pop this view controller off the stack to indicate that the call went through.
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
