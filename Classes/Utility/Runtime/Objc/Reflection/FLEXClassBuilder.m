//
//  FLEXClassBuilder.m
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

#import "FLEXClassBuilder.h"
#import "FLEXProperty.h"
#import "FLEXMethodBase.h"
#import "FLEXProtocol.h"
#import <objc/runtime.h>


#pragma mark FLEXClassBuilder

@interface FLEXClassBuilder ()
@property (nonatomic) NSString *name;
@end

@implementation FLEXClassBuilder

- (id)init {
    [NSException
        raise:NSInternalInconsistencyException
        format:@"Class instance should not be created with -init"
    ];
    return nil;
}

#pragma mark Initializers
+ (instancetype)allocateClass:(NSString *)name {
    return [self allocateClass:name superclass:NSObject.class];
}

+ (instancetype)allocateClass:(NSString *)name superclass:(Class)superclass {
    return [self allocateClass:name superclass:superclass extraBytes:0];
}

+ (instancetype)allocateClass:(NSString *)name superclass:(Class)superclass extraBytes:(size_t)bytes {
    NSParameterAssert(name);
    return [[self alloc] initWithClass:objc_allocateClassPair(superclass, name.UTF8String, bytes)];
}

+ (instancetype)allocateRootClass:(NSString *)name {
    NSParameterAssert(name);
    return [[self alloc] initWithClass:objc_allocateClassPair(Nil, name.UTF8String, 0)];
}

+ (instancetype)builderForClass:(Class)cls {
    return [[self alloc] initWithClass:cls];
}

- (id)initWithClass:(Class)cls {
    NSParameterAssert(cls);

    self = [super init];
    if (self) {
        _workingClass = cls;
        _name = NSStringFromClass(_workingClass);
    }

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ name=%@, registered=%d>",
            NSStringFromClass(self.class), self.name, self.isRegistered];
}

#pragma mark Building
- (NSArray *)addMethods:(NSArray *)methods {
    NSParameterAssert(methods.count);

    NSMutableArray *failed = [NSMutableArray new];
    for (FLEXMethodBase *m in methods) {
        if (!class_addMethod(self.workingClass, m.selector, m.implementation, m.typeEncoding.UTF8String)) {
            [failed addObject:m];
        }
    }

    return failed;
}

- (NSArray *)addProperties:(NSArray *)properties {
    NSParameterAssert(properties.count);

    NSMutableArray *failed = [NSMutableArray new];
    for (FLEXProperty *p in properties) {
        unsigned int pcount;
        objc_property_attribute_t *attributes = [p copyAttributesList:&pcount];
        if (!class_addProperty(self.workingClass, p.name.UTF8String, attributes, pcount)) {
            [failed addObject:p];
        }
        free(attributes);
    }

    return failed;
}

- (NSArray *)addProtocols:(NSArray *)protocols {
    NSParameterAssert(protocols.count);

    NSMutableArray *failed = [NSMutableArray new];
    for (FLEXProtocol *p in protocols) {
        if (!class_addProtocol(self.workingClass, p.objc_protocol)) {
            [failed addObject:p];
        }
    }

    return failed;
}

- (NSArray *)addIvars:(NSArray *)ivars {
    NSParameterAssert(ivars.count);

    NSMutableArray *failed = [NSMutableArray new];
    for (FLEXIvarBuilder *ivar in ivars) {
        if (!class_addIvar(self.workingClass, ivar.name.UTF8String, ivar.size, ivar.alignment, ivar.encoding.UTF8String)) {
            [failed addObject:ivar];
        }
    }

    return failed;
}

- (Class)registerClass {
    if (self.isRegistered) {
        [NSException raise:NSInternalInconsistencyException format:@"Class is already registered"];
    }

    objc_registerClassPair(self.workingClass);
    return self.workingClass;
}

- (BOOL)isRegistered {
    return objc_lookUpClass(self.name.UTF8String) != nil;
}

@end


#pragma mark FLEXIvarBuilder

@implementation FLEXIvarBuilder

+ (instancetype)name:(NSString *)name size:(size_t)size alignment:(uint8_t)alignment typeEncoding:(NSString *)encoding {
    return [[self alloc] initWithName:name size:size alignment:alignment typeEncoding:encoding];
}

- (id)initWithName:(NSString *)name size:(size_t)size alignment:(uint8_t)alignment typeEncoding:(NSString *)encoding {
    NSParameterAssert(name); NSParameterAssert(encoding);
    NSParameterAssert(size > 0); NSParameterAssert(alignment > 0);

    self = [super init];
    if (self) {
        _name      = name;
        _encoding  = encoding;
        _size      = size;
        _alignment = alignment;
    }

    return self;
}

@end
