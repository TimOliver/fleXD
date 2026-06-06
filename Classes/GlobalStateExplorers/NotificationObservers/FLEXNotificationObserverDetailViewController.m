#import "FLEXNotificationObserverDetailViewController.h"
#import "FLEXNotificationRegistration.h"
#import "FLEXMutableListSection.h"
#import "FLEXTableView.h"

@implementation FLEXNotificationObserverDetailViewController {
    FLEXNotificationRegistration *_registration;
}

- (instancetype)initWithRegistration:(FLEXNotificationRegistration *)registration {
    self = [super init];
    if (self) {
        _registration = registration;
        self.title = registration.observerClassName;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self reloadData];
}

- (NSArray<FLEXTableViewSection *> *)makeSections {
    FLEXNotificationRegistration *r = _registration;

    NSString *stateText;
    switch (r.state) {
        case FLEXNotificationObserverStateAlive:
            stateText = @"Alive";
            break;
        case FLEXNotificationObserverStateDeallocated:
            stateText = @"Deallocated (still registered)";
            break;
        case FLEXNotificationObserverStateUnknown:
            stateText = @"Unknown (no weak support)";
            break;
    }

    NSArray<NSString *> *fields = @[
        [NSString stringWithFormat:@"Observer:  %@ (0x%016lx)", r.observerClassName, (unsigned long)r.observerPointer],
        [NSString stringWithFormat:@"Notification:  %@", r.notificationName ?: @"(any)"],
        [NSString stringWithFormat:@"Selector:  %@", r.selectorString],
        [NSString stringWithFormat:@"Object:  %@", r.observedObjectClassName ?: @"(any)"],
        [NSString stringWithFormat:@"State:  %@", stateText],
        [NSString stringWithFormat:@"From app code:  %@", r.isOurs ? @"Yes" : @"No"],
        [NSString stringWithFormat:@"Registered:  %@", r.registeredAt],
    ];

    FLEXMutableListSection<NSString *> *info = [FLEXMutableListSection
        list:fields
        cellConfiguration:^(__kindof UITableViewCell *cell, NSString *text, NSInteger row) {
            cell.textLabel.text = text;
            cell.textLabel.numberOfLines = 0;
        }
        filterMatcher:nil];
    info.customTitle = @"Registration";

    FLEXMutableListSection<NSString *> *trace = [FLEXMutableListSection
        list:r.symbolicatedBacktrace
        cellConfiguration:^(__kindof UITableViewCell *cell, NSString *frame, NSInteger row) {
            cell.textLabel.text = frame;
            cell.textLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
            cell.textLabel.numberOfLines = 0;
        }
        filterMatcher:nil];
    trace.customTitle = @"Registration call site";

    return @[info, trace];
}

@end
