//
//  NSDictionary+ObjcRuntime.m
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

#import "NSDictionary+ObjcRuntime.h"
#import "FLEXRuntimeUtility.h"

@implementation NSDictionary (ObjcRuntime)

/// See this link on how to construct a proper attributes string:
/// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
- (NSString *)propertyAttributesString {
    if (!self[kFLEXPropertyAttributeKeyTypeEncoding]) return nil;

    NSMutableString *attributes = [NSMutableString new];
    [attributes appendFormat:@"T%@,", self[kFLEXPropertyAttributeKeyTypeEncoding]];

    for (NSString *attribute in self.allKeys) {
        FLEXPropertyAttribute c = (FLEXPropertyAttribute)[attribute characterAtIndex:0];
        switch (c) {
            case FLEXPropertyAttributeTypeEncoding:
                break;
            case FLEXPropertyAttributeBackingIvarName:
                [attributes appendFormat:@"%@%@,",
                    kFLEXPropertyAttributeKeyBackingIvarName,
                    self[kFLEXPropertyAttributeKeyBackingIvarName]
                ];
                break;
            case FLEXPropertyAttributeCopy:
                if ([self[kFLEXPropertyAttributeKeyCopy] boolValue]) {
                    [attributes appendFormat:@"%@,", kFLEXPropertyAttributeKeyCopy];
                }
                break;
            case FLEXPropertyAttributeCustomGetter:
                [attributes appendFormat:@"%@%@,",
                    kFLEXPropertyAttributeKeyCustomGetter,
                    self[kFLEXPropertyAttributeKeyCustomGetter]
                ];
                break;
            case FLEXPropertyAttributeCustomSetter:
                [attributes appendFormat:@"%@%@,",
                    kFLEXPropertyAttributeKeyCustomSetter,
                    self[kFLEXPropertyAttributeKeyCustomSetter]
                ];
                break;
            case FLEXPropertyAttributeDynamic:
                if ([self[kFLEXPropertyAttributeKeyDynamic] boolValue]) {
                    [attributes appendFormat:@"%@,", kFLEXPropertyAttributeKeyDynamic];
                }
                break;
            case FLEXPropertyAttributeGarbageCollectible:
                [attributes appendFormat:@"%@,", kFLEXPropertyAttributeKeyGarbageCollectable];
                break;
            case FLEXPropertyAttributeNonAtomic:
                if ([self[kFLEXPropertyAttributeKeyNonAtomic] boolValue]) {
                    [attributes appendFormat:@"%@,", kFLEXPropertyAttributeKeyNonAtomic];
                }
                break;
            case FLEXPropertyAttributeOldTypeEncoding:
                [attributes appendFormat:@"%@%@,",
                    kFLEXPropertyAttributeKeyOldStyleTypeEncoding,
                    self[kFLEXPropertyAttributeKeyOldStyleTypeEncoding]
                ];
                break;
            case FLEXPropertyAttributeReadOnly:
                if ([self[kFLEXPropertyAttributeKeyReadOnly] boolValue]) {
                    [attributes appendFormat:@"%@,", kFLEXPropertyAttributeKeyReadOnly];
                }
                break;
            case FLEXPropertyAttributeRetain:
                if ([self[kFLEXPropertyAttributeKeyRetain] boolValue]) {
                    [attributes appendFormat:@"%@,", kFLEXPropertyAttributeKeyRetain];
                }
                break;
            case FLEXPropertyAttributeWeak:
                if ([self[kFLEXPropertyAttributeKeyWeak] boolValue]) {
                    [attributes appendFormat:@"%@,", kFLEXPropertyAttributeKeyWeak];
                }
                break;
            default:
                return nil;
                break;
        }
    }

    [attributes deleteCharactersInRange:NSMakeRange(attributes.length-1, 1)];
    return attributes.copy;
}

+ (instancetype)attributesDictionaryForProperty:(objc_property_t)property {
    NSMutableDictionary *attrs = [NSMutableDictionary new];

    for (NSString *key in FLEXRuntimeUtility.allPropertyAttributeKeys) {
        char *value = property_copyAttributeValue(property, key.UTF8String);
        if (value) {
            attrs[key] = [[NSString alloc]
                initWithBytesNoCopy:value
                length:strlen(value)
                encoding:NSUTF8StringEncoding
                freeWhenDone:YES
            ];
        }
    }

    return attrs.copy;
}

@end
