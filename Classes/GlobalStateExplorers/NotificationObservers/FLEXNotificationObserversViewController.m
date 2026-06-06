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

    UIBarButtonItem *trashButton = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
        target:self action:@selector(clearTapped)];
    NSString *toggleTitle = FLEXNotificationMonitor.enabled ? @"Disable" : @"Enable";
    UIBarButtonItem *toggleButton = [[UIBarButtonItem alloc]
        initWithTitle:toggleTitle
        style:UIBarButtonItemStylePlain target:self action:@selector(toggleTapped:)];
    [self addToolbarItems:@[trashButton, toggleButton]];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(recorderUpdated)
        name:kFLEXNotificationRecorderUpdatedNotification object:nil];

    [self showEnablePromptIfNeeded];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (NSArray<FLEXTableViewSection *> *)makeSections {
    self.observerSection = [FLEXNotificationObserverSection new];
    self.observerSection.appOnly = YES;
    return @[self.observerSection];
}

#pragma mark - Actions

- (void)recorderUpdated {
    // reloadSections re-pulls each section's rows from the recorder;
    // reloadData then refreshes the table. The base reloadData alone
    // would not recompute the section's row snapshot.
    [self reloadSections];
    [self reloadData];
}

- (void)clearTapped {
    // Clearing posts kFLEXNotificationRecorderUpdatedNotification, which
    // drives recorderUpdated to refresh the table.
    [FLEXNotificationRecorder.sharedRecorder clear];
}

- (void)toggleTapped:(UIBarButtonItem *)sender {
    BOOL nowOn = !FLEXNotificationMonitor.enabled;
    FLEXNotificationMonitor.enabled = nowOn;
    sender.title = nowOn ? @"Disable" : @"Enable";
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
    [super searchBar:searchBar selectedScopeButtonIndexDidChange:selectedScope];
}

@end
