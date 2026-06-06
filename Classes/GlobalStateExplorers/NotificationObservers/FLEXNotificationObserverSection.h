#import "FLEXTableViewSection.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXNotificationObserverSection : FLEXTableViewSection
/// When YES, only registrations whose `isOurs` is YES are shown.
@property (nonatomic) BOOL appOnly;
@end

NS_ASSUME_NONNULL_END
