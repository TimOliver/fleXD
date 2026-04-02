//
//  FLEXShortcutsSection.h
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

#import "FLEXTableViewSection.h"
#import "FLEXObjectInfoSection.h"
@class FLEXProperty, FLEXIvar, FLEXMethod;

NS_ASSUME_NONNULL_BEGIN

/// An abstract base class for custom object "shortcuts" where every
/// row can possibly have some action. The section title is "Shortcuts".
///
/// You should only subclass this class if you need simple shortcuts
/// with plain titles and/or subtitles. This class will automatically
/// configure each cell appropriately. Since this is intended as a
/// static section, subclasses should only need to implement the
/// `viewControllerToPushForRow:` and/or `didSelectRowAction:` methods.
///
/// If you create the section using `forObject:rows:numberOfLines:`
/// then it will provide a view controller from `viewControllerToPushForRow:`
/// automatically for rows that are a property/ivar/method.
@interface FLEXShortcutsSection : FLEXTableViewSection <FLEXObjectInfoSection>

/// Uses `kFLEXDefaultCell`
+ (instancetype)forObject:(id)objectOrClass rowTitles:(nullable NSArray<NSString *> *)titles;
/// Uses `kFLEXDetailCell` for non-empty subtitles, otherwise uses `kFLEXDefaultCell`
+ (instancetype)forObject:(id)objectOrClass
                rowTitles:(nullable NSArray<NSString *> *)titles
             rowSubtitles:(nullable NSArray<NSString *> *)subtitles;

/// Uses `kFLEXDefaultCell` for rows that are given a title, otherwise
/// this uses `kFLEXDetailCell` for any other allowed object.
///
/// The section provide a view controller from `viewControllerToPushForRow:`
/// automatically for rows that are a property/ivar/method.
///
/// @param rows A mixed array containing any of the following:
/// - any `FLEXShortcut` conforming object
/// - an `NSString`
/// - a `FLEXProperty`
/// - a `FLEXIvar`
/// - a `FLEXMethodBase` (includes `FLEXMethod` of course)
/// Passing one of the latter 3 will provide a shortcut to that property/ivar/method.
+ (instancetype)forObject:(id)objectOrClass rows:(nullable NSArray *)rows;

/// Same as `forObject:rows:` but the given rows are prepended
/// to the shortcuts already registered for the object's class.
/// `forObject:rows:` does not use the registered shortcuts at all.
+ (instancetype)forObject:(id)objectOrClass additionalRows:(nullable NSArray *)rows;

/// Calls into `forObject:rows:` using the registered shortcuts for the object's class.
/// @return An empty section if the object has no shortcuts registered at all.
+ (instancetype)forObject:(id)objectOrClass;

/// Subclasses \e may override this to hide the disclosure indicator
/// for some rows. It is shown for all rows by default, unless
/// you initialize it with `forObject:rowTitles:rowSubtitles:`
///
/// When you hide the disclosure indicator, the row is not selectable.
- (UITableViewCellAccessoryType)accessoryTypeForRow:(NSInteger)row;

/// The number of lines for the title and subtitle labels. Defaults to 1.
@property (nonatomic, readonly) NSInteger numberOfLines;
/// The object used to initialize this section.
@property (nonatomic, readonly) id object;

/// Whether dynamic subtitles should always be computed as a cell is configured.
/// Defaults to NO. Has no effect on static subtitles that are passed explicitly.
@property (nonatomic) BOOL cacheSubtitles;

/// Whether this shortcut section overrides the default section or not.
/// Subclasses should not override this method. To provide a second
/// section alongside the default shortcuts section, use `forObject:rows:`
/// @return `NO` if initialized with `forObject:` or `forObject:additionalRows:`
@property (nonatomic, readonly) BOOL isNewSection;

@end

@class FLEXShortcutsFactory;
typedef FLEXShortcutsFactory *_Nonnull(^FLEXShortcutsFactoryNames)(NSArray *names);
typedef void (^FLEXShortcutsFactoryTarget)(Class targetClass);

/// The block properties below are to be used like SnapKit or Masonry.
/// `FLEXShortcutsSection.append.properties(@[@"frame",@"bounds"]).forClass(UIView.class)`
///
/// To safely register your own classes at launch, subclass this class,
/// override `+load` and call the appropriate methods on `self`
@interface FLEXShortcutsFactory : NSObject

/// Returns the list of all registered shortcuts for the given object in this order:
/// Properties, ivars, methods.
///
/// This method traverses up the object's class hierarchy until it finds
/// something registered. This allows you to show different shortcuts for
/// the same object in different parts of the class hierarchy.
///
/// As an example, UIView may have a -layer shortcut registered. But if
/// you're inspecting a UIControl, you may not care about the layer or other
/// UIView-specific things; you might rather see the target-actions registered
/// for this control, and so you would register that property or ivar to UIControl,
/// And you would still be able to see the UIView-registered shorcuts by clicking
/// on the UIView "lens" at the top the explorer view controller screen.
+ (NSArray *)shortcutsForObjectOrClass:(id)objectOrClass;

/// Adds the specified shortcuts after any already registered for the target class.
@property (nonatomic, readonly, class) FLEXShortcutsFactory *append;
/// Adds the specified shortcuts before any already registered for the target class.
@property (nonatomic, readonly, class) FLEXShortcutsFactory *prepend;
/// Replaces all shortcuts registered for the target class with the specified ones.
@property (nonatomic, readonly, class) FLEXShortcutsFactory *replace;

/// Registers shortcuts for the given instance property names.
@property (nonatomic, readonly) FLEXShortcutsFactoryNames properties;
/// Registers shortcuts for the given class property names.
/// Do not combine with `ivars` or other instance-scope registrations.
@property (nonatomic, readonly) FLEXShortcutsFactoryNames classProperties;
/// Registers shortcuts for the given instance variable names.
@property (nonatomic, readonly) FLEXShortcutsFactoryNames ivars;
/// Registers shortcuts for the given instance method names.
@property (nonatomic, readonly) FLEXShortcutsFactoryNames methods;
/// Registers shortcuts for the given class method names.
/// Do not combine with `ivars` or other instance-scope registrations.
@property (nonatomic, readonly) FLEXShortcutsFactoryNames classMethods;

/// Accepts the target class. If you pass a regular class object,
/// shortcuts will appear on instances. If you pass a metaclass object,
/// shortcuts will appear when exploring a class object.
///
/// For example, some class method shortcuts are added to the NSObject meta
/// class by default so that you can see +alloc and +new when exploring
/// a class object. If you wanted these to show up when exploring
/// instances you would pass them to the classMethods method above.
@property (nonatomic, readonly) FLEXShortcutsFactoryTarget forClass;

@end

NS_ASSUME_NONNULL_END
