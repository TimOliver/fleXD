#import "FLEXNotificationObserverSection.h"
#import "FLEXNotificationRecorder.h"
#import "FLEXNotificationRegistration.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXNotificationObserverDetailViewController.h"
#import "FLEXTableView.h"
#import "FLEXColor.h"

@interface FLEXNotificationObserverSection ()
@property (nonatomic, copy) NSArray<FLEXNotificationRegistration *> *rows;
@end

@implementation FLEXNotificationObserverSection

- (void)setAppOnly:(BOOL)appOnly {
    _appOnly = appOnly;
    [self reloadData];
}

- (void)reloadData {
    NSArray<FLEXNotificationRegistration *> *all = FLEXNotificationRecorder.sharedRecorder.registrations;
    NSString *filter = self.filterText;
    NSMutableArray<FLEXNotificationRegistration *> *result = [NSMutableArray array];
    for (FLEXNotificationRegistration *r in all) {
        if (self.appOnly && !r.isOurs) continue;
        if (filter.length) {
            NSString *haystack = [NSString stringWithFormat:@"%@ %@ %@",
                r.observerClassName, r.notificationName ?: @"", r.selectorString];
            if (![haystack localizedCaseInsensitiveContainsString:filter]) continue;
        }
        [result addObject:r];
    }
    self.rows = result;
}

- (void)setFilterText:(NSString *)filterText {
    super.filterText = filterText;
    [self reloadData];
}

- (NSString *)title { return @"Observers"; }
- (NSInteger)numberOfRows { return self.rows.count; }
- (NSString *)reuseIdentifierForRow:(NSInteger)row { return kFLEXDetailCell; }
- (BOOL)canSelectRow:(NSInteger)row { return YES; }

- (void)configureCell:(__kindof UITableViewCell *)cell forRow:(NSInteger)row {
    FLEXNotificationRegistration *r = self.rows[row];
    NSString *name = r.notificationName ?: @"(any notification)";
    cell.textLabel.text = [NSString stringWithFormat:@"%@ — %@", r.observerClassName, name];

    NSString *stateText;
    switch (r.state) {
        case FLEXNotificationObserverStateAlive: stateText = @"alive"; break;
        case FLEXNotificationObserverStateDeallocated: stateText = @"⚠️ DEALLOCATED"; break;
        case FLEXNotificationObserverStateUnknown: stateText = @"state unknown"; break;
    }
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@", r.selectorString, stateText];
    cell.detailTextLabel.textColor = (r.state == FLEXNotificationObserverStateDeallocated)
        ? UIColor.systemRedColor : FLEXColor.deemphasizedTextColor;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    FLEXNotificationRegistration *r = self.rows[row];
    if (r.state == FLEXNotificationObserverStateAlive && r.observer) {
        return [FLEXObjectExplorerFactory explorerViewControllerForObject:r.observer];
    }
    return [[FLEXNotificationObserverDetailViewController alloc] initWithRegistration:r];
}

- (NSString *)titleForRow:(NSInteger)row {
    return self.rows[row].observerClassName;
}

@end
