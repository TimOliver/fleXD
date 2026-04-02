//
//  FLEXSwiftInternal.m
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

#import "FLEXSwiftInternal.h"
#import <objc/runtime.h>
#include <atomic>

// class is a Swift class from the pre-stable Swift ABI
#define FAST_IS_SWIFT_LEGACY  (1UL<<0)
// class is a Swift class from the stable Swift ABI
#define FAST_IS_SWIFT_STABLE  (1UL<<1)
// data pointer
#define FAST_DATA_MASK        0xfffffffcUL

typedef uintptr_t class_data_bits_t;
#if __LP64__
typedef uint32_t mask_t;  // x86_64 & arm64 asm are less efficient with 16-bits
#else
typedef uint16_t mask_t;
#endif

/* dyld_shared_cache_builder and obj-C agree on these definitions */
struct preopt_cache_entry_t {
    uint32_t sel_offs;
    uint32_t imp_offs;
};

/* dyld_shared_cache_builder and obj-C agree on these definitions */
struct preopt_cache_t {
    int32_t fallback_class_offset;
    union {
        struct {
            uint16_t shift       :  5;
            uint16_t mask        : 11;
        };
        uint16_t hash_params;
    };
    uint16_t occupied    : 14;
    uint16_t has_inlines :  1;
    uint16_t bit_one     :  1;
    preopt_cache_entry_t entries[];
};

union isa_t {
    uintptr_t bits;
    // Accessing the class requires custom ptrauth operations
    Class cls;
};

struct cache_t {
    std::atomic<uintptr_t> _bucketsAndMaybeMask;
    union {
        struct {
            std::atomic<mask_t> _maybeMask;
            #if __LP64__
            uint16_t            _flags;
            #endif
            uint16_t            _occupied;
        };
        std::atomic<preopt_cache_t *> _originalPreoptCache;
    };
};

struct objc_object_ {
    union isa_t isa;
};

struct objc_class_ : objc_object_ {
    Class superclass;
    cache_t cache; // formerly cache pointer and vtable
    class_data_bits_t bits;    
};

extern "C" BOOL FLEXIsSwiftObjectOrClass(id objOrClass) {
    Class cls = objOrClass;
    if (!object_isClass(objOrClass)) {
        cls = object_getClass(objOrClass);
    }

    class_data_bits_t rodata = ((__bridge objc_class_ *)(cls))->bits;

    if (@available(macOS 10.14.4, iOS 12.2, tvOS 12.2, watchOS 5.2, *)) {
        return (rodata & FAST_IS_SWIFT_STABLE) != 0;
    } else {
        return (rodata & FAST_IS_SWIFT_LEGACY) != 0;
    }
}
