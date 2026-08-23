#import "MFEventTapHandle.h"

@interface MFSystemEventTapBackend : NSObject <MFEventTapBackend>
@end

@implementation MFSystemEventTapBackend
- (void *)createTapAtLocation:(CGEventTapLocation)location placement:(CGEventTapPlacement)placement options:(CGEventTapOptions)options mask:(CGEventMask)mask callback:(CGEventTapCallBack)callback { return CGEventTapCreate(location, placement, options, mask, callback, NULL); }
- (void *)createSourceForTap:(void *)tap { return CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0); }
- (void)addSource:(void *)source toRunLoop:(CFRunLoopRef)runLoop mode:(CFRunLoopMode)mode { CFRunLoopAddSource(runLoop, source, mode); }
- (void)removeSource:(void *)source fromRunLoop:(CFRunLoopRef)runLoop mode:(CFRunLoopMode)mode { CFRunLoopRemoveSource(runLoop, source, mode); }
- (BOOL)isTapEnabled:(void *)tap { return CGEventTapIsEnabled(tap); }
- (void)setTap:(void *)tap enabled:(BOOL)enabled { CGEventTapEnable(tap, enabled); }
- (void)invalidateTap:(void *)tap { CFMachPortInvalidate(tap); }
- (void)releaseTap:(void *)tap { CFRelease(tap); }
- (void)releaseSource:(void *)source { CFRelease(source); }
@end

@interface MFEventTapHandle ()
@property(nonatomic) void *tap;
@property(nonatomic) void *source;
@property(nonatomic) CFRunLoopRef ownerRunLoop;
@property(nonatomic) CFRunLoopMode ownerMode;
@property(nonatomic) id<MFEventTapBackend> backend;
@property(nonatomic) NSString *label;
@property(nonatomic) NSTimeInterval timeout;
@property(nonatomic) BOOL invalidated;
@property(nonatomic, readwrite) BOOL desiredEnabled;
@end

@implementation MFEventTapHandle

+ (instancetype)handleWithLocation:(CGEventTapLocation)location mask:(CGEventMask)mask options:(CGEventTapOptions)options placement:(CGEventTapPlacement)placement callback:(CGEventTapCallBack)callback runLoop:(CFRunLoopRef)runLoop mode:(CFRunLoopMode)mode label:(NSString *)label {
    return [[self alloc] initWithLocation:location mask:mask options:options placement:placement callback:callback runLoop:runLoop mode:mode label:label backend:[MFSystemEventTapBackend new] timeout:1.0];
}

- (instancetype)initWithLocation:(CGEventTapLocation)location mask:(CGEventMask)mask options:(CGEventTapOptions)options placement:(CGEventTapPlacement)placement callback:(CGEventTapCallBack)callback runLoop:(CFRunLoopRef)runLoop mode:(CFRunLoopMode)mode label:(NSString *)label backend:(id<MFEventTapBackend>)backend timeout:(NSTimeInterval)timeout {
    self = [super init];
    if (self == nil) return nil;
    _ownerRunLoop = (CFRunLoopRef)CFRetain(runLoop);
    _ownerMode = (CFRunLoopMode)CFRetain(mode);
    _backend = backend;
    _label = [label copy];
    _timeout = MAX(timeout, 0.01);

    __block BOOL created = NO;
    if (![self performOwnerOperation:^{
        self.tap = [backend createTapAtLocation:location placement:placement options:options mask:mask callback:callback];
        if (self.tap == NULL) return;
        self.source = [backend createSourceForTap:self.tap];
        if (self.source == NULL) {
            [backend releaseTap:self.tap];
            self.tap = NULL;
            return;
        }
        [backend setTap:self.tap enabled:NO];
        [backend addSource:self.source toRunLoop:self.ownerRunLoop mode:self.ownerMode];
        created = YES;
    } cancelOnTimeout:YES] || !created) {
        NSLog(@"%@: failed to create event tap or source", _label);
        [self invalidate];
        return nil;
    }
    return self;
}

- (BOOL)performOwnerOperation:(dispatch_block_t)operation cancelOnTimeout:(BOOL)cancelOnTimeout {
    if (CFRunLoopGetCurrent() == self.ownerRunLoop) { operation(); return YES; }
    dispatch_semaphore_t finished = dispatch_semaphore_create(0);
    NSObject *token = [NSObject new];
    __block BOOL cancelled = NO;
    CFRunLoopPerformBlock(self.ownerRunLoop, self.ownerMode, ^{
        @synchronized (token) { if (cancelled) { dispatch_semaphore_signal(finished); return; } }
        operation();
        dispatch_semaphore_signal(finished);
    });
    CFRunLoopWakeUp(self.ownerRunLoop);
    if (dispatch_semaphore_wait(finished, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.timeout * NSEC_PER_SEC))) == 0) return YES;
    if (cancelOnTimeout) {
        @synchronized (token) { cancelled = YES; }
    }
    NSLog(@"%@: owner run-loop operation timed out", self.label);
    return NO;
}

- (BOOL)isValid { @synchronized (self) { return !self.invalidated && self.tap != NULL && self.source != NULL; } }
- (CFMachPortRef)eventTap { @synchronized (self) { return self.invalidated ? NULL : self.tap; } }
- (BOOL)isEnabled {
    if (!self.valid) return NO;
    __block BOOL result = NO;
    return [self performOwnerOperation:^{ if (self.valid) result = [self.backend isTapEnabled:self.tap]; } cancelOnTimeout:YES] && result;
}

- (BOOL)setEnabled:(BOOL)enabled reason:(NSString *)reason {
    @synchronized (self) {
        if (self.invalidated || self.tap == NULL || self.source == NULL) {
            NSLog(@"%@: cannot %@ invalid event tap; reason=%@", self.label, enabled ? @"enable" : @"disable", reason);
            return NO;
        }
        self.desiredEnabled = enabled;
    }
    __block BOOL result = NO;
    BOOL completed = [self performOwnerOperation:^{
        if (!self.valid || self.desiredEnabled != enabled) return;
        if ([self.backend isTapEnabled:self.tap] != enabled) [self.backend setTap:self.tap enabled:enabled];
        result = [self.backend isTapEnabled:self.tap] == enabled;
    } cancelOnTimeout:YES];
    if (!completed || !result) NSLog(@"%@: failed to %@ event tap; reason=%@", self.label, enabled ? @"enable" : @"disable", reason);
    return completed && result;
}

- (BOOL)invalidate {
    @synchronized (self) { self.desiredEnabled = NO; if (self.invalidated) return YES; self.invalidated = YES; }
    return [self performOwnerOperation:^{
        if (self.tap != NULL) {
            [self.backend setTap:self.tap enabled:NO];
            [self.backend invalidateTap:self.tap];
        }
        if (self.source != NULL) [self.backend removeSource:self.source fromRunLoop:self.ownerRunLoop mode:self.ownerMode];
        if (self.source != NULL) { [self.backend releaseSource:self.source]; self.source = NULL; }
        if (self.tap != NULL) { [self.backend releaseTap:self.tap]; self.tap = NULL; }
    } cancelOnTimeout:NO];
}

- (void)dealloc {
    [self invalidate];
    if (_ownerRunLoop != NULL) CFRelease(_ownerRunLoop);
    if (_ownerMode != NULL) CFRelease(_ownerMode);
}

@end
