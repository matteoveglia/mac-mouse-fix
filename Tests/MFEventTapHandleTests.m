#import <Foundation/Foundation.h>
#import "MFEventTapHandle.h"

static CGEventRef Callback(CGEventTapProxy p, CGEventType t, CGEventRef e, void *u) { return e; }

@interface FakeTapBackend : NSObject <MFEventTapBackend>
@property BOOL failTap, failSource, enabled, refuseEnable;
@property NSInteger releaseTapCount, releaseSourceCount, invalidateCount;
@property NSMutableArray<NSString *> *calls;
@end
@implementation FakeTapBackend
- (instancetype)init { if ((self = [super init])) _calls = [NSMutableArray array]; return self; }
- (void *)createTapAtLocation:(CGEventTapLocation)l placement:(CGEventTapPlacement)p options:(CGEventTapOptions)o mask:(CGEventMask)m callback:(CGEventTapCallBack)c { [_calls addObject:@"createTap"]; return _failTap ? NULL : (void *)0x1; }
- (void *)createSourceForTap:(void *)t { [_calls addObject:@"createSource"]; return _failSource ? NULL : (void *)0x2; }
- (void)addSource:(void *)s toRunLoop:(CFRunLoopRef)r mode:(CFRunLoopMode)m { [_calls addObject:@"addSource"]; }
- (void)removeSource:(void *)s fromRunLoop:(CFRunLoopRef)r mode:(CFRunLoopMode)m { [_calls addObject:@"removeSource"]; }
- (BOOL)isTapEnabled:(void *)t { return _enabled; }
- (void)setTap:(void *)t enabled:(BOOL)e { [_calls addObject:e ? @"enable" : @"disable"]; if (!(e && _refuseEnable)) _enabled = e; }
- (void)invalidateTap:(void *)t { [_calls addObject:@"invalidate"]; _invalidateCount++; }
- (void)releaseTap:(void *)t { [_calls addObject:@"releaseTap"]; _releaseTapCount++; }
- (void)releaseSource:(void *)s { [_calls addObject:@"releaseSource"]; _releaseSourceCount++; }
@end

static MFEventTapHandle *Make(FakeTapBackend *b) { return [[MFEventTapHandle alloc] initWithLocation:kCGHIDEventTap mask:1 options:kCGEventTapOptionDefault placement:kCGHeadInsertEventTap callback:Callback runLoop:CFRunLoopGetCurrent() mode:kCFRunLoopDefaultMode label:@"test" backend:b timeout:0.1]; }
static void Check(BOOL c, NSString *m) { if (!c) { fprintf(stderr, "%s\n", m.UTF8String); abort(); } }

int main(void) { @autoreleasepool {
    FakeTapBackend *tapFailure = [FakeTapBackend new]; tapFailure.failTap = YES; Check(Make(tapFailure) == nil, @"tap failure must fail creation");
    FakeTapBackend *sourceFailure = [FakeTapBackend new]; sourceFailure.failSource = YES; Check(Make(sourceFailure) == nil && sourceFailure.releaseTapCount == 1, @"source failure must release tap");
    FakeTapBackend *backend = [FakeTapBackend new]; MFEventTapHandle *handle = Make(backend); Check(handle.valid && !handle.enabled, @"new handle must be valid and inert");
    Check([handle setEnabled:YES reason:@"test"] && handle.enabled && handle.desiredEnabled, @"enable must succeed");
    NSUInteger count = backend.calls.count; Check([handle setEnabled:YES reason:@"again"] && backend.calls.count == count, @"enable must be idempotent");
    backend.refuseEnable = YES; [handle setEnabled:NO reason:@"off"]; Check(![handle setEnabled:YES reason:@"refused"], @"backend enable failure must surface");
    Check([handle invalidate] && [handle invalidate], @"invalidation must be idempotent");
    Check(backend.invalidateCount == 1 && backend.releaseSourceCount == 1 && backend.releaseTapCount == 1, @"teardown must release exactly once");
    Check(![handle setEnabled:YES reason:@"late"] && !handle.desiredEnabled, @"invalid handle must reject late enable");
    NSArray *tail = [backend.calls subarrayWithRange:NSMakeRange(backend.calls.count - 5, 5)];
    Check([tail isEqual:@[@"disable", @"invalidate", @"removeSource", @"releaseSource", @"releaseTap"]], @"teardown order must be stable");
    puts("MFEventTapHandle tests passed");
} return 0; }
