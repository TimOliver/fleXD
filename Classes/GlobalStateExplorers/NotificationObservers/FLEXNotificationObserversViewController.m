#import "FLEXNotificationObserversViewController.h"
#import "FLEXNotificationObserverSection.h"
#import "FLEXNotificationMonitor.h"
#import "FLEXNotificationRecorder.h"

@interface FLEXNotificationObserversViewController ()
@property (nonatomic) FLEXNotificationObserverSection *observerSection;
@end

@implementation FLEXNotificationObserversViewController

#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row {
    return @"Notification Observers";
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row {
    return [self new];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = [self.class globalsEntryTitle:FLEXGlobalsRowNotificationObservers];
    self.showsSearchBar = YES;

    // Scope: App-only (default) vs All
    self.searchController.searchBar.scopeButtonTitles = @[@"App", @"All"];
    self.observerSection.appOnly = YES;

    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
            target:self action:@selector(clearTapped)],
        [[UIBarButtonItem alloc] initWithTitle:(FLEXNotificationMonitor.enabled ? @"On" : @"Off")
            style:UIBarButtonItemStylePlain target:self action:@selector(toggleTapped:)],
    ];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recorderUpdated)
        name:kFLEXNotificationRecorderUpdatedNotification object:nil];

    [self showEnablePromptIfNeeded];
}

- (NSArray<FLEXTableViewSection *> *)makeSections {
    self.observerSection = [FLEXNotificationObserverSection new];
    self.observerSection.appOnly = YES;
    return @[self.observerSection];
}

#pragma mark - Actions

- (void)recorderUpdated {
    [self reloadData];
}

- (void)clearTapped {
    [FLEXNotificationRecorder.sharedRecorder clear];
    [self reloadData];
}

- (void)toggleTapped:(UIBarButtonItem *)sender {
    BOOL nowOn = !FLEXNotificationMonitor.enabled;
    FLEXNotificationMonitor.enabled = nowOn;
    sender.title = nowOn ? @"On" : @"Off";
    [self showEnablePromptIfNeeded];
}

- (void)showEnablePromptIfNeeded {
    if (!FLEXNotificationMonitor.enabled) {
        self.title = @"Notification Observers (off)";
    } else {
        self.title = [self.class globalsEntryTitle:FLEXGlobalsRowNotificationObservers];
    }
}

#pragma mark - Search scope

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    self.observerSection.appOnly = (selectedScope == 0);
    [self reloadData];
    [super searchBar:searchBar selectedScopeButtonIndexDidChange:selectedScope];
}

@end
