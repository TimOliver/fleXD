//
//  FLEXArgumentInputView.h
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

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, FLEXArgumentInputViewSize) {
    /// 2 lines, medium-sized
    FLEXArgumentInputViewSizeDefault = 0,
    /// One line
    FLEXArgumentInputViewSizeSmall,
    /// Several lines
    FLEXArgumentInputViewSizeLarge
};

@protocol FLEXArgumentInputViewDelegate;

@interface FLEXArgumentInputView : UIView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding;

/// The name of the field. Optional (can be nil).
@property (nonatomic, copy) NSString *title;

/// To populate the filed with an initial value, set this property.
/// To retrieve the value input by the user, access the property.
/// Primitive types and structs should/will be boxed in NSValue containers.
/// Concrete subclasses should override both the setter and getter for this property.
/// Subclasses can call super.inputValue to access a backing store for the value.
@property (nonatomic) id inputValue;

/// Setting this value to large will make some argument input views increase the size of their input field(s).
/// Useful to increase the use of space if there is only one input view on screen (i.e. for property and ivar editing).
@property (nonatomic) FLEXArgumentInputViewSize targetSize;

/// Users of the input view can get delegate callbacks for incremental changes in user input.
@property (nonatomic, weak) id <FLEXArgumentInputViewDelegate> delegate;

// Subclasses can override

/// If the input view has one or more text views, returns YES when one of them is focused.
@property (nonatomic, readonly) BOOL inputViewIsFirstResponder;

/// For subclasses to indicate that they can handle editing a field the give type and value.
/// Used by FLEXArgumentInputViewFactory to create appropriate input views.
+ (BOOL)supportsObjCType:(const char *)type withCurrentValue:(id)value;

// For subclass eyes only

@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) NSString *typeEncoding;
@property (nonatomic, readonly) CGFloat topInputFieldVerticalLayoutGuide;

@end

@protocol FLEXArgumentInputViewDelegate <NSObject>

- (void)argumentInputViewValueDidChange:(FLEXArgumentInputView *)argumentInputView;

@end
