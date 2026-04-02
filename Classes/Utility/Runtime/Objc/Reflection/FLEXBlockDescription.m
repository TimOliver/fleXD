//
//  FLEXBlockDescription.m
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

#import "FLEXBlockDescription.h"
#import "FLEXRuntimeUtility.h"

struct block_object {
    void *isa;
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct block_descriptor {
        unsigned long int reserved;    // NULL
        unsigned long int size;     // sizeof(struct Block_literal_1)
        // optional helper functions
        void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
        void (*dispose_helper)(void *src);             // IFF (1<<25)
        // required ABI.2010.3.16
        const char *signature;                         // IFF (1<<30)
    } *descriptor;
    // imported variables
};

@implementation FLEXBlockDescription

+ (instancetype)describing:(id)block {
    return [[self alloc] initWithObjcBlock:block];
}

- (id)initWithObjcBlock:(id)block {
    self = [super init];
    if (self) {
        _block = block;

        struct block_object *blockRef = (__bridge struct block_object *)block;
        _flags = blockRef->flags;
        _size = blockRef->descriptor->size;

        if (_flags & FLEXBlockOptionHasSignature) {
            void *signatureLocation = blockRef->descriptor;
            signatureLocation += sizeof(unsigned long int);
            signatureLocation += sizeof(unsigned long int);

            if (_flags & FLEXBlockOptionHasCopyDispose) {
                signatureLocation += sizeof(void(*)(void *dst, void *src));
                signatureLocation += sizeof(void (*)(void *src));
            }

            const char *signature = (*(const char **)signatureLocation);
            _signatureString = @(signature);

            @try {
                _signature = [NSMethodSignature signatureWithObjCTypes:signature];
            } @catch (NSException *exception) { }
        }

        NSMutableString *summary = [NSMutableString stringWithFormat:
            @"Type signature: %@\nSize: %@\nIs global: %@\nHas constructor: %@\nIs stret: %@",
            self.signatureString ?: @"nil", @(self.size),
            @((BOOL)(_flags & FLEXBlockOptionIsGlobal)),
            @((BOOL)(_flags & FLEXBlockOptionHasCtor)),
            @((BOOL)(_flags & FLEXBlockOptionHasStret))
        ];

        if (!self.signature) {
            [summary appendFormat:@"\nNumber of arguments: %@", @(self.signature.numberOfArguments)];
        }

        _summary = summary.copy;
        _sourceDeclaration = [self buildLikelyDeclaration];
    }

    return self;
}

- (BOOL)isCompatibleForBlockSwizzlingWithMethodSignature:(NSMethodSignature *)methodSignature {
    if (!self.signature) {
        return NO;
    }

    if (self.signature.numberOfArguments != methodSignature.numberOfArguments + 1) {
        return NO;
    }

    if (strcmp(self.signature.methodReturnType, methodSignature.methodReturnType) != 0) {
        return NO;
    }

    for (int i = 0; i < methodSignature.numberOfArguments; i++) {
        if (i == 1) {
            // SEL in method, IMP in block
            if (strcmp([methodSignature getArgumentTypeAtIndex:i], ":") != 0) {
                return NO;
            }

            if (strcmp([self.signature getArgumentTypeAtIndex:i + 1], "^?") != 0) {
                return NO;
            }
        } else {
            if (strcmp([self.signature getArgumentTypeAtIndex:i], [self.signature getArgumentTypeAtIndex:i + 1]) != 0) {
                return NO;
            }
        }
    }

    return YES;
}

- (NSString *)buildLikelyDeclaration {
    NSMethodSignature *signature = self.signature;
    NSUInteger numberOfArguments = signature.numberOfArguments;
    const char *returnType       = signature.methodReturnType;

    // Return type
    NSMutableString *decl = [NSMutableString stringWithString:@"^"];
    if (returnType[0] != FLEXTypeEncodingVoid) {
        [decl appendString:[FLEXRuntimeUtility readableTypeForEncoding:@(returnType)]];
        [decl appendString:@" "];
    }

    // Arguments
    if (numberOfArguments) {
        [decl appendString:@"("];
        for (NSUInteger i = 1; i < numberOfArguments; i++) {
            const char *argType = [self.signature getArgumentTypeAtIndex:i] ?: "?";
            NSString *readableArgType = [FLEXRuntimeUtility readableTypeForEncoding:@(argType)];
            [decl appendFormat:@"%@ arg%@, ", readableArgType, @(i)];
        }

        [decl deleteCharactersInRange:NSMakeRange(decl.length-2, 2)];
        [decl appendString:@")"];
    }

    return decl.copy;
}

@end
