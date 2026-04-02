//
//  FLEXShortcut.m
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

#import "FLEXShortcut.h"
#import "FLEXProperty.h"
#import "FLEXPropertyAttributes.h"
#import "FLEXIvar.h"
#import "FLEXMethod.h"
#import "FLEXRuntime+UIKitHelpers.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXFieldEditorViewController.h"
#import "FLEXMethodCallingViewController.h"
#import "FLEXMetadataSection.h"
#import "FLEXTableView.h"


#pragma mark - FLEXShortcut

@interface FLEXShortcut () {
    id _item;
}

@property (nonatomic, readonly) FLEXMetadataKind metadataKind;
@property (nonatomic, readonly) FLEXProperty *property;
@property (nonatomic, readonly) FLEXMethod *method;
@property (nonatomic, readonly) FLEXIvar *ivar;
@property (nonatomic, readonly) id<FLEXRuntimeMetadata> metadata;
@end

@implementation FLEXShortcut
@synthesize defaults = _defaults;

+ (id<FLEXShortcut>)shortcutFor:(id)item {
    if ([item conformsToProtocol:@protocol(FLEXShortcut)]) {
        return item;
    }

    FLEXShortcut *shortcut = [self new];
    shortcut->_item = item;

    if ([item isKindOfClass:[FLEXProperty class]]) {
        if (shortcut.property.isClassProperty) {
            shortcut->_metadataKind =  FLEXMetadataKindClassProperties;
        } else {
            shortcut->_metadataKind =  FLEXMetadataKindProperties;
        }
    }
    if ([item isKindOfClass:[FLEXIvar class]]) {
        shortcut->_metadataKind = FLEXMetadataKindIvars;
    }
    if ([item isKindOfClass:[FLEXMethod class]]) {
        // We don't care if it's a class method or not
        shortcut->_metadataKind = FLEXMetadataKindMethods;
    }

    return shortcut;
}

- (id)propertyOrIvarValue:(id)object {
    return [self.metadata currentValueWithTarget:object];
}

- (NSString *)titleWith:(id)object {
    switch (self.metadataKind) {
        case FLEXMetadataKindClassProperties:
        case FLEXMetadataKindProperties:
            // Since we're outside of the "properties" section, prepend @property for clarity.
            return [@"@property " stringByAppendingString:[_item description]];

        default:
            return [_item description];
    }

    NSAssert(
        [_item isKindOfClass:[NSString class]],
        @"Unexpected type: %@", [_item class]
    );

    return _item;
}

- (NSString *)subtitleWith:(id)object {
    if (self.metadataKind) {
        return [self.metadata previewWithTarget:object];
    }

    // Item is probably a string; must return empty string since
    // these will be gathered into an array. If the object is a
    // just a string, it doesn't get a subtitle.
    return @"";
}

- (void (^)(UIViewController *))didSelectActionWith:(id)object { 
    return nil;
}

- (UIViewController *)viewerWith:(id)object {
    NSAssert(self.metadataKind, @"Static titles cannot be viewed");
    return [self.metadata viewerWithTarget:object];
}

- (UIViewController *)editorWith:(id)object forSection:(FLEXTableViewSection *)section {
    NSAssert(self.metadataKind, @"Static titles cannot be edited");
    return [self.metadata editorWithTarget:object section:section];
}

- (UITableViewCellAccessoryType)accessoryTypeWith:(id)object {
    if (self.metadataKind) {
        return [self.metadata suggestedAccessoryTypeWithTarget:object];
    }

    return UITableViewCellAccessoryNone;
}

- (NSString *)customReuseIdentifierWith:(id)object {
    if (self.metadataKind) {
        return kFLEXCodeFontCell;
    }

    return kFLEXMultilineCell;
}

#pragma mark FLEXObjectExplorerDefaults

- (void)setDefaults:(FLEXObjectExplorerDefaults *)defaults {
    _defaults = defaults;

    if (_metadataKind) {
        self.metadata.defaults = defaults;
    }
}

- (BOOL)isEditable {
    if (_metadataKind) {
        return self.metadata.isEditable;
    }

    return NO;
}

- (BOOL)isCallable {
    if (_metadataKind) {
        return self.metadata.isCallable;
    }

    return NO;
}

#pragma mark - Helpers

- (FLEXProperty *)property { return _item; }
- (FLEXMethodBase *)method { return _item; }
- (FLEXIvar *)ivar { return _item; }
- (id<FLEXRuntimeMetadata>)metadata { return _item; }

@end


#pragma mark - FLEXActionShortcut

@interface FLEXActionShortcut ()
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *(^subtitleFuture)(id);
@property (nonatomic, readonly) UIViewController *(^viewerFuture)(id);
@property (nonatomic, readonly) void (^selectionHandler)(UIViewController *, id);
@property (nonatomic, readonly) UITableViewCellAccessoryType (^accessoryTypeFuture)(id);
@end

@implementation FLEXActionShortcut
@synthesize defaults = _defaults;

+ (instancetype)title:(NSString *)title
             subtitle:(NSString *(^)(id))subtitle
               viewer:(UIViewController *(^)(id))viewer
        accessoryType:(UITableViewCellAccessoryType (^)(id))type {
    return [[self alloc] initWithTitle:title subtitle:subtitle viewer:viewer selectionHandler:nil accessoryType:type];
}

+ (instancetype)title:(NSString *)title
             subtitle:(NSString * (^)(id))subtitle
     selectionHandler:(void (^)(UIViewController *, id))tapAction
        accessoryType:(UITableViewCellAccessoryType (^)(id))type {
    return [[self alloc] initWithTitle:title subtitle:subtitle viewer:nil selectionHandler:tapAction accessoryType:type];
}

- (id)initWithTitle:(NSString *)title
           subtitle:(id)subtitleFuture
             viewer:(id)viewerFuture
   selectionHandler:(id)tapAction
      accessoryType:(id)accessoryTypeFuture {
    NSParameterAssert(title.length);

    self = [super init];
    if (self) {
        id nilBlock = ^id (id obj) { return nil; };

        _title = title;
        _subtitleFuture = subtitleFuture ?: nilBlock;
        _viewerFuture = viewerFuture ?: nilBlock;
        _selectionHandler = tapAction;
        _accessoryTypeFuture = accessoryTypeFuture ?: nilBlock;
    }

    return self;
}

- (NSString *)titleWith:(id)object {
    return self.title;
}

- (NSString *)subtitleWith:(id)object {
    if (self.defaults.wantsDynamicPreviews) {
        return self.subtitleFuture(object);
    }

    return nil;
}

- (void (^)(UIViewController *))didSelectActionWith:(id)object {
    if (self.selectionHandler) {
        return ^(UIViewController *host) {
            self.selectionHandler(host, object);
        };
    }

    return nil;
}

- (UIViewController *)viewerWith:(id)object {
    return self.viewerFuture(object);
}

- (UITableViewCellAccessoryType)accessoryTypeWith:(id)object {
    return self.accessoryTypeFuture(object);
}

- (NSString *)customReuseIdentifierWith:(id)object {
    if (!self.subtitleFuture(object)) {
        // The text is more centered with this style if there is no subtitle
        return kFLEXDefaultCell;
    }

    return nil;
}

- (BOOL)isEditable { return NO; }
- (BOOL)isCallable { return NO; }

@end
