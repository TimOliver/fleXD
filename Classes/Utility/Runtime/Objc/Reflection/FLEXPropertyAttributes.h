//
//  FLEXPropertyAttributes.h
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

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark FLEXPropertyAttributes

/// See \e FLEXRuntimeUtilitiy.h for valid string tokens.
/// See this link on how to construct a proper attributes string:
/// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
@interface FLEXPropertyAttributes : NSObject <NSCopying, NSMutableCopying> {
// These are necessary for the mutable subclass to function
@protected
    NSUInteger _count;
    NSString *_string, *_backingIvar, *_typeEncoding, *_oldTypeEncoding, *_fullDeclaration;
    NSDictionary *_dictionary;
    objc_property_attribute_t *_list;
    SEL _customGetter, _customSetter;
    BOOL _isReadOnly, _isCopy, _isRetained, _isNonatomic, _isDynamic, _isWeak, _isGarbageCollectable;
}

+ (instancetype)attributesForProperty:(objc_property_t)property;
/// @warning Raises an exception if \e attributes is invalid, `nil` or contains unsupported keys.
+ (instancetype)attributesFromDictionary:(NSDictionary *)attributes;

/// Copies the attributes list to a buffer you must `free()` yourself.
/// Use `list` instead if you do not need more control over the lifetime of the list.
/// @param attributesCountOut the number of attributes is returned in this parameter.
- (objc_property_attribute_t *)copyAttributesList:(nullable unsigned int *)attributesCountOut;

/// The number of property attributes.
@property (nonatomic, readonly) NSUInteger count;

/// For use with `class_replaceProperty` and the like.
@property (nonatomic, readonly) objc_property_attribute_t *list;

/// The string value of the property attributes.
@property (nonatomic, readonly) NSString *string;

/// A human-readable version of the property attributes.
@property (nonatomic, readonly) NSString *fullDeclaration;

/// A dictionary of the property attributes.
/// Values are either a string or `YES` Boolean attributes
/// which are false will not be present in the dictionary.
@property (nonatomic, readonly) NSDictionary *dictionary;

/// The name of the instance variable backing the property.
@property (nonatomic, readonly, nullable) NSString *backingIvar;

/// The type encoding of the property.
@property (nonatomic, readonly, nullable) NSString *typeEncoding;

/// The \e old type encoding of the property.
@property (nonatomic, readonly, nullable) NSString *oldTypeEncoding;

/// The property's custom getter, if any.
@property (nonatomic, readonly, nullable) SEL customGetter;

/// The property's custom setter, if any.
@property (nonatomic, readonly, nullable) SEL customSetter;

/// The property's custom getter as a string, if any.
@property (nonatomic, readonly, nullable) NSString *customGetterString;

/// The property's custom setter as a string, if any.
@property (nonatomic, readonly, nullable) NSString *customSetterString;
@property (nonatomic, readonly) BOOL isReadOnly;
@property (nonatomic, readonly) BOOL isCopy;
@property (nonatomic, readonly) BOOL isRetained;
@property (nonatomic, readonly) BOOL isNonatomic;
@property (nonatomic, readonly) BOOL isDynamic;
@property (nonatomic, readonly) BOOL isWeak;
@property (nonatomic, readonly) BOOL isGarbageCollectable;

@end


#pragma mark FLEXMutablePropertyAttributes
@interface FLEXMutablePropertyAttributes : FLEXPropertyAttributes

/// Creates and returns an empty property attributes object.
+ (instancetype)attributes;

/// The name of the instance variable backing the property.
@property (nonatomic, nullable) NSString *backingIvar;

/// The type encoding of the property.
@property (nonatomic, nullable) NSString *typeEncoding;

/// The \e old type encoding of the property.
@property (nonatomic, nullable) NSString *oldTypeEncoding;

/// The property's custom getter, if any.
@property (nonatomic, nullable) SEL customGetter;

/// The property's custom setter, if any.
@property (nonatomic, nullable) SEL customSetter;
@property (nonatomic) BOOL isReadOnly;
@property (nonatomic) BOOL isCopy;
@property (nonatomic) BOOL isRetained;
@property (nonatomic) BOOL isNonatomic;
@property (nonatomic) BOOL isDynamic;
@property (nonatomic) BOOL isWeak;
@property (nonatomic) BOOL isGarbageCollectable;

/// A more convenient way to set the `typeEncoding` property.
/// Does not work for complex types like structs and primitive pointers.
- (void)setTypeEncodingChar:(char)type;

@end

NS_ASSUME_NONNULL_END
