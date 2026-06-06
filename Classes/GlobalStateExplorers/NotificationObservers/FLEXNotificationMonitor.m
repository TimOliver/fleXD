#import "FLEXNotificationMonitor.h"
#import "FLEXNotificationRecorder.h"
#import "FLEXNotificationRegistration.h"
#import "FLEXUtility.h"
#import "NSUserDefaults+FLEX.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <execinfo.h>
#import <stdatomic.h>

// Fix 2: atomic cache so addObserver:selector:name:object: doesn't hit NSUserDefaults each call.
static _Atomic(BOOL) FLEXNotificationMonitorEnabledCache = NO;

static NSArray<NSNumber *> *FLEXCaptureReturnAddresses(void) {
    void *frames[64];
    int count = backtrace(frames, 64);
    NSMutableArray<NSNumber *> *addrs = [NSMutableArray arrayWithCapacity:count];
    // Skip frame 0 (this fn) and 1 (the swizzle block) for cleaner attribution.
    for (int i = 2; i < count; i++) {
        [addrs addObject:@((uintptr_t)frames[i])];
    }
    return addrs;
}

static BOOL FLEXShouldRecordObserver(id observer) {
    if (!observer) return NO;
    // Don't record FLEX's own observers (reduces noise).
    return ![NSStringFromClass(object_getClass(observer)) hasPrefix:@"FLEX"];
}

@implementation FLEXNotificationMonitor

+ (BOOL)enabled {
    // Fix 2: read from the atomic cache, not NSUserDefaults.
    return atomic_load_explicit(&FLEXNotificationMonitorEnabledCache, memory_order_relaxed);
}

+ (void)setEnabled:(BOOL)enabled {
    // Fix 2: write both the persisted default (Fix 4) and the cache.
    NSUserDefaults.standardUserDefaults.flex_notificationMonitorEnabled = enabled;
    atomic_store_explicit(&FLEXNotificationMonitorEnabledCache, enabled, memory_order_relaxed);
    if (enabled) {
        [self installIfEnabled];
    }
}

+ (void)load {
    // Fix 2: seed the cache from the persisted value BEFORE installIfEnabled runs.
    atomic_store_explicit(&FLEXNotificationMonitorEnabledCache,
        NSUserDefaults.standardUserDefaults.flex_notificationMonitorEnabled, memory_order_relaxed);
    dispatch_async(dispatch_get_main_queue(), ^{ [self installIfEnabled]; });
}

+ (void)installIfEnabled {
    if (!self.enabled) return;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ [self installSwizzles]; });
}

+ (void)installSwizzles {
    Class cls = NSNotificationCenter.class;

    SEL addSel = @selector(addObserver:selector:name:object:);
    SEL addSwz = [FLEXUtility swizzledSelectorForSelector:addSel];
    [FLEXUtility replaceImplementationOfKnownSelector:addSel onClass:cls
        withBlock:^(NSNotificationCenter *ctr, id observer, SEL selector, NSString *name, id object) {
            if (FLEXNotificationMonitor.enabled && FLEXShouldRecordObserver(observer)) {
                // Fix 3: use hasPrefix:@"__NSObserver" — Apple's actual block-token class
                // prefix — instead of containsString:, to prevent double-recording when
                // addObserverForName:object:queue:usingBlock: internally calls this method.
                if (![NSStringFromClass(object_getClass(observer)) hasPrefix:@"__NSObserver"]) {
                    FLEXNotificationRegistration *reg = [FLEXNotificationRegistration
                        registrationWithObserver:observer
                        selectorString:NSStringFromSelector(selector)
                        name:name object:object returnAddresses:FLEXCaptureReturnAddresses()];
                    [FLEXNotificationRecorder.sharedRecorder addRegistration:reg];
                }
            }
            ((void (*)(id, SEL, id, SEL, id, id))objc_msgSend)(ctr, addSwz, observer, selector, name, object);
        } swizzledSelector:addSwz];

    SEL blockSel = @selector(addObserverForName:object:queue:usingBlock:);
    SEL blockSwz = [FLEXUtility swizzledSelectorForSelector:blockSel];
    [FLEXUtility replaceImplementationOfKnownSelector:blockSel onClass:cls
        withBlock:^id(NSNotificationCenter *ctr, NSString *name, id object, NSOperationQueue *queue, void(^block)(NSNotification *)) {
            id token = ((id (*)(id, SEL, id, id, id, id))objc_msgSend)(ctr, blockSwz, name, object, queue, block);
            if (FLEXNotificationMonitor.enabled && token) {
                FLEXNotificationRegistration *reg = [FLEXNotificationRegistration
                    registrationWithObserver:token
                    selectorString:nil
                    name:name object:object returnAddresses:FLEXCaptureReturnAddresses()];
                [FLEXNotificationRecorder.sharedRecorder addRegistration:reg];
            }
            return token;
        } swizzledSelector:blockSwz];

    SEL rm1 = @selector(removeObserver:);
    SEL rm1Swz = [FLEXUtility swizzledSelectorForSelector:rm1];
    [FLEXUtility replaceImplementationOfKnownSelector:rm1 onClass:cls
        withBlock:^(NSNotificationCenter *ctr, id observer) {
            // Fix 1: cleanup runs whenever observer is non-nil, regardless of enabled.
            // Removing an unrecorded observer is a safe no-op in the recorder.
            if (observer) {
                [FLEXNotificationRecorder.sharedRecorder
                    removeAllRegistrationsForObserverPointer:(uintptr_t)observer];
            }
            ((void (*)(id, SEL, id))objc_msgSend)(ctr, rm1Swz, observer);
        } swizzledSelector:rm1Swz];

    SEL rm2 = @selector(removeObserver:name:object:);
    SEL rm2Swz = [FLEXUtility swizzledSelectorForSelector:rm2];
    [FLEXUtility replaceImplementationOfKnownSelector:rm2 onClass:cls
        withBlock:^(NSNotificationCenter *ctr, id observer, NSString *name, id object) {
            // Fix 1: cleanup runs whenever observer is non-nil, regardless of enabled.
            if (observer) {
                [FLEXNotificationRecorder.sharedRecorder
                    removeRegistrationsForObserverPointer:(uintptr_t)observer
                    name:name objectPointer:(uintptr_t)object];
            }
            ((void (*)(id, SEL, id, id, id))objc_msgSend)(ctr, rm2Swz, observer, name, object);
        } swizzledSelector:rm2Swz];
}

@end
