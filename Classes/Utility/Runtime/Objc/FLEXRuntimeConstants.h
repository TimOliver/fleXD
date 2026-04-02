//
//  FLEXRuntimeConstants.h
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

#define FLEXEncodeClass(class) ("@\"" #class "\"")
#define FLEXEncodeObject(obj) (obj ? [NSString stringWithFormat:@"@\"%@\"", [obj class]].UTF8String : @encode(id))

// Arguments 0 and 1 are self and _cmd always
extern const unsigned int kFLEXNumberOfImplicitArgs;

// See https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW6
extern NSString *const kFLEXPropertyAttributeKeyTypeEncoding;
extern NSString *const kFLEXPropertyAttributeKeyBackingIvarName;
extern NSString *const kFLEXPropertyAttributeKeyReadOnly;
extern NSString *const kFLEXPropertyAttributeKeyCopy;
extern NSString *const kFLEXPropertyAttributeKeyRetain;
extern NSString *const kFLEXPropertyAttributeKeyNonAtomic;
extern NSString *const kFLEXPropertyAttributeKeyCustomGetter;
extern NSString *const kFLEXPropertyAttributeKeyCustomSetter;
extern NSString *const kFLEXPropertyAttributeKeyDynamic;
extern NSString *const kFLEXPropertyAttributeKeyWeak;
extern NSString *const kFLEXPropertyAttributeKeyGarbageCollectable;
extern NSString *const kFLEXPropertyAttributeKeyOldStyleTypeEncoding;

typedef NS_ENUM(NSUInteger, FLEXPropertyAttribute) {
    FLEXPropertyAttributeTypeEncoding       = 'T',
    FLEXPropertyAttributeBackingIvarName    = 'V',
    FLEXPropertyAttributeCopy               = 'C',
    FLEXPropertyAttributeCustomGetter       = 'G',
    FLEXPropertyAttributeCustomSetter       = 'S',
    FLEXPropertyAttributeDynamic            = 'D',
    FLEXPropertyAttributeGarbageCollectible = 'P',
    FLEXPropertyAttributeNonAtomic          = 'N',
    FLEXPropertyAttributeOldTypeEncoding    = 't',
    FLEXPropertyAttributeReadOnly           = 'R',
    FLEXPropertyAttributeRetain             = '&',
    FLEXPropertyAttributeWeak               = 'W'
}; //NS_SWIFT_NAME(FLEX.PropertyAttribute);

typedef NS_ENUM(char, FLEXTypeEncoding) {
    FLEXTypeEncodingNull             = '\0',
    FLEXTypeEncodingUnknown          = '?',
    FLEXTypeEncodingChar             = 'c',
    FLEXTypeEncodingInt              = 'i',
    FLEXTypeEncodingShort            = 's',
    FLEXTypeEncodingLong             = 'l',
    FLEXTypeEncodingLongLong         = 'q',
    FLEXTypeEncodingUnsignedChar     = 'C',
    FLEXTypeEncodingUnsignedInt      = 'I',
    FLEXTypeEncodingUnsignedShort    = 'S',
    FLEXTypeEncodingUnsignedLong     = 'L',
    FLEXTypeEncodingUnsignedLongLong = 'Q',
    FLEXTypeEncodingFloat            = 'f',
    FLEXTypeEncodingDouble           = 'd',
    FLEXTypeEncodingLongDouble       = 'D',
    FLEXTypeEncodingCBool            = 'B',
    FLEXTypeEncodingVoid             = 'v',
    FLEXTypeEncodingCString          = '*',
    FLEXTypeEncodingObjcObject       = '@',
    FLEXTypeEncodingObjcClass        = '#',
    FLEXTypeEncodingSelector         = ':',
    FLEXTypeEncodingArrayBegin       = '[',
    FLEXTypeEncodingArrayEnd         = ']',
    FLEXTypeEncodingStructBegin      = '{',
    FLEXTypeEncodingStructEnd        = '}',
    FLEXTypeEncodingUnionBegin       = '(',
    FLEXTypeEncodingUnionEnd         = ')',
    FLEXTypeEncodingQuote            = '\"',
    FLEXTypeEncodingBitField         = 'b',
    FLEXTypeEncodingPointer          = '^',
    FLEXTypeEncodingConst            = 'r'
}; //NS_SWIFT_NAME(FLEX.TypeEncoding);
