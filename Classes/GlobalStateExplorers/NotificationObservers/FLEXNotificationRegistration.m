#import "FLEXNotificationRegistration.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>

/// Mirrors what objc's storeWeak does: respect a class that overrides
/// -allowsWeakReference to return NO, so we never trip the runtime's fatal.
static BOOL FLEXObjectSupportsWeakReference(id object) {
    if (!object) return NO;
    Class cls = object_getClass(object);
    SEL sel = NSSelectorFromString(@"allowsWeakReference");
    IMP base = class_getMethodImplementation(NSObject.class, sel);
    IMP cur = class_getMethodImplementation(cls, sel);
    if (cur == base) {
        return YES; // not overridden; default NSObject behavior allows weak refs
    }
    return ((BOOL (*)(id, SEL))objc_msgSend)(object, sel);
}

static BOOL FLEXAddressesContainAppFrame(NSArray<NSNumber *> *addresses) {
    NSString *mainPath = NSBundle.mainBundle.bundlePath;
    if (!mainPath.length) return NO;
    for (NSNumber *addr in addresses) {
        Dl_info info;
        if (dladdr((const void *)(uintptr_t)addr.unsignedLongLongValue, &info) && info.dli_fname) {
            if ([@(info.dli_fname) hasPrefix:mainPath]) {
                return YES;
            }
        }
    }
    return NO;
}

@implementation FLEXNotificationRegistration {
    __weak id _observer;
    __weak id _observedObject;
}

+ (instancetype)registrationWithObserver:(id)observer
                          selectorString:(NSString *)selectorString
                                    name:(NSString *)name
                                  object:(id)object
                         returnAddresses:(NSArray<NSNumber *> *)returnAddresses {
    FLEXNotificationRegistration *reg = [self new];
    reg->_observerPointer = (uintptr_t)observer;
    reg->_observerClassName = NSStringFromClass(object_getClass(observer));
    reg->_selectorString = [selectorString copy] ?: @"(block)";
    reg->_notificationName = [name copy];
    reg->_observedObjectPointer = (uintptr_t)object;
    reg->_observedObjectClassName = object ? NSStringFromClass(object_getClass(object)) : nil;
    reg->_returnAddresses = [returnAddresses copy] ?: @[];
    reg->_registeredAt = [NSDate date];
    reg->_isOurs = FLEXAddressesContainAppFrame(reg->_returnAddresses);

    if (FLEXObjectSupportsWeakReference(observer)) {
        reg->_observer = observer;
        reg->_weakSupported = YES;
    } else {
        reg->_weakSupported = NO;
    }
    if (object && FLEXObjectSupportsWeakReference(object)) {
        reg->_observedObject = object;
    }
    return reg;
}

- (id)observer { return _observer; }
- (id)observedObject { return _observedObject; }

- (FLEXNotificationObserverState)state {
    if (!_weakSupported) return FLEXNotificationObserverStateUnknown;
    return _observer ? FLEXNotificationObserverStateAlive : FLEXNotificationObserverStateDeallocated;
}

- (NSArray<NSString *> *)symbolicatedBacktrace {
    NSMutableArray<NSString *> *frames = [NSMutableArray array];
    for (NSNumber *addr in _returnAddresses) {
        void *ptr = (void *)(uintptr_t)addr.unsignedLongLongValue;
        Dl_info info;
        if (dladdr(ptr, &info)) {
            NSString *image = info.dli_fname ? @(info.dli_fname).lastPathComponent : @"???";
            NSString *symbol = info.dli_sname ? @(info.dli_sname) : @"???";
            unsigned long offset = (unsigned long)((uintptr_t)ptr - (uintptr_t)info.dli_saddr);
            [frames addObject:[NSString stringWithFormat:@"%@  0x%016lx  %@ + %lu",
                image, (unsigned long)(uintptr_t)ptr, symbol, offset]];
        } else {
            [frames addObject:[NSString stringWithFormat:@"0x%016lx  ???",
                (unsigned long)(uintptr_t)ptr]];
        }
    }
    return frames;
}

@end
