#import <Foundation/Foundation.h>
#import "MFHIDPPClient.h"

/// Deterministic test scheduler. It never sleeps and only runs work when time
/// is advanced explicitly by the caller.
@interface MFHIDPPManualScheduler : NSObject <MFHIDPPDeadlineScheduler>

@property (nonatomic, readonly) NSTimeInterval now;
@property (nonatomic, readonly) NSUInteger pendingCount;

- (void)advanceBy:(NSTimeInterval)delta;

@end
