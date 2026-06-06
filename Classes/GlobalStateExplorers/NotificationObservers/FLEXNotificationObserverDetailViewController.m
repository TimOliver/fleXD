#import "FLEXNotificationObserverDetailViewController.h"
#import "FLEXNotificationRegistration.h"
@implementation FLEXNotificationObserverDetailViewController {
    FLEXNotificationRegistration *_registration;
}
- (instancetype)initWithRegistration:(FLEXNotificationRegistration *)registration {
    self = [super init];
    if (self) { _registration = registration; self.title = registration.observerClassName; }
    return self;
}
@end
