//
//  FLEXRuntimeSafety.h
//  FLEX
//
//  Created by Tanner on 3/25/17.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#pragma mark - Classes

/// The number of entries in `FLEXKnownUnsafeClassList`
extern NSUInteger const kFLEXKnownUnsafeClassCount;
/// A C array of class pointers known to be unsafe for runtime introspection.
extern const Class * FLEXKnownUnsafeClassList(void);
/// An `NSSet` of class name strings corresponding to `FLEXKnownUnsafeClassList`
extern NSSet * FLEXKnownUnsafeClassNames(void);
/// A `CFSetRef` containing the known-unsafe classes, for fast membership testing.
extern CFSetRef FLEXKnownUnsafeClasses;

static Class cNSObject = nil, cNSProxy = nil;

__attribute__((constructor))
static void FLEXInitKnownRootClasses(void) {
    cNSObject = [NSObject class];
    cNSProxy = [NSProxy class];
}

/// @return `YES` if the class is safe to use for runtime introspection, `NO` otherwise.
static inline BOOL FLEXClassIsSafe(Class cls) {
    // Is it nil or known to be unsafe?
    if (!cls || CFSetContainsValue(FLEXKnownUnsafeClasses, (__bridge void *)cls)) {
        return NO;
    }
    
    // Is it a known root class?
    if (!class_getSuperclass(cls)) {
        return cls == cNSObject || cls == cNSProxy;
    }
    
    // Probably safe
    return YES;
}

/// @return `YES` if the class name is not in the known-unsafe class list, `NO` otherwise.
static inline BOOL FLEXClassNameIsSafe(NSString *cls) {
    if (!cls) return NO;
    
    NSSet *ignored = FLEXKnownUnsafeClassNames();
    return ![ignored containsObject:cls];
}

#pragma mark - Ivars

/// A `CFSetRef` containing ivars known to be unsafe for runtime introspection.
extern CFSetRef FLEXKnownUnsafeIvars;

/// @return `YES` if the ivar is safe to use for runtime introspection, `NO` otherwise.
static inline BOOL FLEXIvarIsSafe(Ivar ivar) {
    if (!ivar) return NO;

    return !CFSetContainsValue(FLEXKnownUnsafeIvars, ivar);
}
