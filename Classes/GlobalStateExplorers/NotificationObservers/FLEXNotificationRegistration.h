#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FLEXNotificationObserverState) {
    FLEXNotificationObserverStateAlive,
    FLEXNotificationObserverStateDeallocated,
    FLEXNotificationObserverStateUnknown, // observer class doesn't support weak refs
};

/// An immutable record of one NSNotificationCenter observer registration.
/// Holds a zeroing weak reference to the observer so deallocation can be
/// detected without ever messaging a (possibly dangling) object.
@interface FLEXNotificationRegistration : NSObject

+ (instancetype)registrationWithObserver:(id)observer
                          selectorString:(nullable NSString *)selectorString
                                    name:(nullable NSString *)name
                                  object:(nullable id)object
                         returnAddresses:(NSArray<NSNumber *> *)returnAddresses;

@property (nonatomic, readonly, copy) NSString *observerClassName;
@property (nonatomic, readonly) uintptr_t observerPointer;
/// nil once the observer has been deallocated
@property (nonatomic, readonly, weak, nullable) id observer;
@property (nonatomic, readonly, copy, nullable) NSString *notificationName;
/// Selector name, or @"(block)" for the block-based API
@property (nonatomic, readonly, copy) NSString *selectorString;
@property (nonatomic, readonly, weak, nullable) id observedObject;
@property (nonatomic, readonly) uintptr_t observedObjectPointer;
@property (nonatomic, readonly, copy, nullable) NSString *observedObjectClassName;
@property (nonatomic, readonly, copy) NSArray<NSNumber *> *returnAddresses;
/// YES if a backtrace frame resolves to the main app bundle (incl. embedded frameworks)
@property (nonatomic, readonly) BOOL isOurs;
@property (nonatomic, readonly) NSDate *registeredAt;
/// NO if the observer's class does not support zeroing weak references
@property (nonatomic, readonly) BOOL weakSupported;

@property (nonatomic, readonly) FLEXNotificationObserverState state;
/// Lazily computed, readable frames like "MyApp  0x...  -[Foo bar] + 42"
@property (nonatomic, readonly, copy) NSArray<NSString *> *symbolicatedBacktrace;

@end

NS_ASSUME_NONNULL_END
