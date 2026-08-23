#import "MFHIDPPManualScheduler.h"
#import <math.h>

@interface MFHIDPPManualDeadline : NSObject
@property (nonatomic) NSTimeInterval due;
@property (nonatomic) NSUInteger order;
@property (nonatomic) BOOL cancelled;
@property (nonatomic, copy) MFHIDPPDeadlineHandler handler;
@end

@implementation MFHIDPPManualDeadline
@end

@implementation MFHIDPPManualScheduler {
    NSTimeInterval _now;
    NSUInteger _nextOrder;
    NSMutableArray<MFHIDPPManualDeadline *> *_deadlines;
}

- (instancetype)init {
    self = [super init];
    if (self != nil) _deadlines = [NSMutableArray array];
    return self;
}

- (NSTimeInterval)now { @synchronized (self) { return _now; } }
- (NSUInteger)pendingCount { @synchronized (self) { return _deadlines.count; } }

- (id)scheduleAfter:(NSTimeInterval)delay handler:(MFHIDPPDeadlineHandler)handler {
    MFHIDPPManualDeadline *deadline = [MFHIDPPManualDeadline new];
    @synchronized (self) {
        deadline.due = _now + MAX(delay, 0.0);
        deadline.order = _nextOrder++;
        deadline.handler = handler;
        [_deadlines addObject:deadline];
    }
    return deadline;
}

- (void)cancel:(id)token {
    if (![token isKindOfClass:[MFHIDPPManualDeadline class]]) return;
    @synchronized (self) {
        MFHIDPPManualDeadline *deadline = token;
        deadline.cancelled = YES;
        [_deadlines removeObject:deadline];
    }
}

- (void)advanceBy:(NSTimeInterval)delta {
    if (!isfinite(delta) || delta < 0.0) return;
    @synchronized (self) { _now += delta; }

    while (YES) {
        MFHIDPPManualDeadline *next = nil;
        @synchronized (self) {
            for (MFHIDPPManualDeadline *candidate in _deadlines) {
                if (candidate.cancelled || candidate.due > _now) continue;
                if (next == nil || candidate.due < next.due || (candidate.due == next.due && candidate.order < next.order)) next = candidate;
            }
            if (next != nil) {
                [_deadlines removeObject:next];
                next.cancelled = YES;
            }
        }
        if (next == nil) return;
        if (next.handler != nil) next.handler();
    }
}

@end
