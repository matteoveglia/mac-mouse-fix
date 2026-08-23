//
// --------------------------------------------------------------------------
// MFHIDPPClient.m
// Fixture-only HID++ request/response state machine for Mac Mouse Fix.
// --------------------------------------------------------------------------
//

#import "MFHIDPPClient.h"
#import <math.h>

static char kMFHIDPPClientQueueKey;

@interface MFHIDPPDispatchDeadlineToken : NSObject
@property (nonatomic) BOOL cancelled;
@property (nonatomic) BOOL fired;
@end

@implementation MFHIDPPDispatchDeadlineToken
@end

@interface MFHIDPPDispatchDeadlineScheduler : NSObject <MFHIDPPDeadlineScheduler>
@end

@implementation MFHIDPPDispatchDeadlineScheduler

- (id)scheduleAfter:(NSTimeInterval)delay handler:(MFHIDPPDeadlineHandler)handler {
    MFHIDPPDispatchDeadlineToken *token = [MFHIDPPDispatchDeadlineToken new];
    dispatch_time_t deadline = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MAX(delay, 0.0) * NSEC_PER_SEC));
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);

    dispatch_after(deadline, queue, ^{
        @synchronized (token) {
            if (token.cancelled || token.fired) return;
            token.fired = YES;
        }
        if (handler != nil) handler();
    });

    return token;
}

- (void)cancel:(id)token {
    if (![token isKindOfClass:[MFHIDPPDispatchDeadlineToken class]]) return;
    @synchronized (token) {
        ((MFHIDPPDispatchDeadlineToken *)token).cancelled = YES;
    }
}

@end

@interface MFHIDPPPendingRequest : NSObject
@property (nonatomic) NSUInteger identifier;
@property (nonatomic, strong) MFHIDPPFrame *frame;
@property (nonatomic, copy) MFHIDPPFrameCompletion completion;
@property (nonatomic, strong) id deadlineToken;
@end

@implementation MFHIDPPPendingRequest
@end

@interface MFHIDPPClient ()
@property (nonatomic, readwrite) MFHIDPPClientState state;
- (void)receiveReport:(NSData *)report;
- (void)receiveDisconnect:(NSError * _Nullable)error;
- (void)writeCompletedWithError:(NSError * _Nullable)error requestIdentifier:(NSUInteger)requestIdentifier;
- (void)deadlineFiredForRequestIdentifier:(NSUInteger)requestIdentifier;
- (void)finishPendingRequestWithResponse:(MFHIDPPFrame * _Nullable)response
                                   error:(NSError * _Nullable)error
                                  retire:(BOOL)retire;
- (void)finishPendingRequestWithResponse:(MFHIDPPFrame * _Nullable)response
                                   error:(NSError * _Nullable)error;
- (BOOL)isRetiredIdentity:(NSData *)identity;
- (void)retireIdentityForFrame:(MFHIDPPFrame *)frame;
@end

@implementation MFHIDPPClient {
    id<MFHIDPPTransport> _transport;
    id<MFHIDPPDeadlineScheduler> _scheduler;
    dispatch_queue_t _queue;
    MFHIDPPPendingRequest *_pendingRequest;
    NSMutableArray<NSData *> *_retiredIdentities;
    NSUInteger _nextRequestIdentifier;
}

- (instancetype)initWithTransport:(id<MFHIDPPTransport>)transport
                         scheduler:(id<MFHIDPPDeadlineScheduler> _Nullable)scheduler {
    NSParameterAssert(transport != nil);
    self = [super init];
    if (self == nil) return nil;

    _transport = transport;
    _scheduler = scheduler ?: [MFHIDPPDispatchDeadlineScheduler new];
    _queue = dispatch_queue_create("com.macmousefix.hidpp.client", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(_queue, &kMFHIDPPClientQueueKey, (__bridge void *)self, NULL);
    _retiredIdentities = [NSMutableArray array];
    _state = kMFHIDPPClientStateIdle;
    return self;
}

- (void)performSynchronously:(dispatch_block_t)block {
    if (dispatch_get_specific(&kMFHIDPPClientQueueKey) == (__bridge void *)self) {
        block();
    } else {
        dispatch_sync(_queue, block);
    }
}

- (void)performAsynchronously:(dispatch_block_t)block {
    dispatch_async(_queue, block);
}

- (void)start {
    [self performSynchronously:^{
        if (self.state != kMFHIDPPClientStateIdle) return;

        self.state = kMFHIDPPClientStateRunning;
        __weak MFHIDPPClient *weakSelf = self;
        [_transport startWithReportHandler:^(NSData *report) {
            [weakSelf receiveReport:report];
        } disconnectHandler:^(NSError *error) {
            [weakSelf receiveDisconnect:error];
        }];
    }];
}

- (BOOL)sendFrame:(MFHIDPPFrame *)frame
          timeout:(NSTimeInterval)timeout
       completion:(MFHIDPPFrameCompletion)completion {
    __block BOOL accepted = NO;
    [self performSynchronously:^{
        NSError *error = nil;
        if (frame == nil || !isfinite(timeout) || timeout < 0.0) {
            error = [NSError errorWithDomain:MFHIDPPErrorDomain
                                        code:kMFHIDPPErrorInvalidArgument
                                    userInfo:@{ NSLocalizedDescriptionKey: frame == nil ? @"HID++ frame is nil." : @"HID++ timeout must be finite and non-negative." }];
        } else if (self.state != kMFHIDPPClientStateRunning) {
            error = [NSError errorWithDomain:MFHIDPPErrorDomain
                                        code:self.state == kMFHIDPPClientStateIdle ? kMFHIDPPErrorNotStarted : kMFHIDPPErrorDisconnected
                                    userInfo:@{ NSLocalizedDescriptionKey: @"HID++ client is not running." }];
        } else if (_pendingRequest != nil) {
            error = [NSError errorWithDomain:MFHIDPPErrorDomain
                                        code:kMFHIDPPErrorBusy
                                    userInfo:@{ NSLocalizedDescriptionKey: @"HID++ client already has a request in flight." }];
        } else if ([self isRetiredIdentity:frame.identity]) {
            error = [NSError errorWithDomain:MFHIDPPErrorDomain
                                        code:kMFHIDPPErrorStaleResponse
                                    userInfo:@{ NSLocalizedDescriptionKey: @"HID++ request identity is quarantined after a late response." }];
        }

        if (error != nil) {
            if (completion != nil) completion(nil, error);
            return;
        }

        MFHIDPPPendingRequest *pending = [MFHIDPPPendingRequest new];
        pending.identifier = ++_nextRequestIdentifier;
        pending.frame = frame;
        pending.completion = completion;
        _pendingRequest = pending;
        accepted = YES;

        __weak MFHIDPPClient *weakSelf = self;
        NSUInteger requestIdentifier = pending.identifier;
        pending.deadlineToken = [_scheduler scheduleAfter:timeout handler:^{
            [weakSelf deadlineFiredForRequestIdentifier:requestIdentifier];
        }];

        [_transport sendReport:frame.rawReport completion:^(NSError *error) {
            [weakSelf writeCompletedWithError:error requestIdentifier:requestIdentifier];
        }];
    }];

    return accepted;
}

- (void)stop {
    [self performSynchronously:^{
        if (self.state == kMFHIDPPClientStateStopped) return;

        self.state = kMFHIDPPClientStateStopped;
        [self finishPendingRequestWithResponse:nil
                                         error:[NSError errorWithDomain:MFHIDPPErrorDomain
                                                                    code:kMFHIDPPErrorCancelled
                                                                userInfo:@{ NSLocalizedDescriptionKey: @"HID++ client stopped." }]
                                        retire:YES];
        [_transport stop];
    }];
}

- (void)receiveReport:(NSData *)report {
    if (report == nil) return;
    [self performAsynchronously:^{
        if (self.state != kMFHIDPPClientStateRunning) return;

        NSError *parseError = nil;
        MFHIDPPFrame *frame = [MFHIDPPFrame frameWithReport:report error:&parseError];
        if (frame == nil) {
            if (self.invalidReportHandler != nil && parseError != nil) {
                self.invalidReportHandler([report copy], parseError);
            }
            return;
        }

        if ([self isRetiredIdentity:frame.identity]) {
            return;
        }

        if (_pendingRequest != nil && [frame matchesResponseToFrame:_pendingRequest.frame]) {
            [self finishPendingRequestWithResponse:frame error:nil];
        } else if (self.unsolicitedReportHandler != nil) {
            self.unsolicitedReportHandler(frame);
        }
    }];
}

- (void)receiveDisconnect:(NSError *)error {
    [self performAsynchronously:^{
        if (self.state != kMFHIDPPClientStateRunning) return;

        self.state = kMFHIDPPClientStateDisconnected;
        NSError *disconnectError = error ?: [NSError errorWithDomain:MFHIDPPErrorDomain
                                                                  code:kMFHIDPPErrorDisconnected
                                                              userInfo:@{ NSLocalizedDescriptionKey: @"HID++ transport disconnected." }];
        [self finishPendingRequestWithResponse:nil error:disconnectError retire:YES];
    }];
}

- (void)writeCompletedWithError:(NSError *)error requestIdentifier:(NSUInteger)requestIdentifier {
    [self performAsynchronously:^{
        if (_pendingRequest == nil || _pendingRequest.identifier != requestIdentifier) return;
        if (error == nil) return;

        NSError *writeError = error;
        if (error.domain.length == 0) {
            writeError = [NSError errorWithDomain:MFHIDPPErrorDomain
                                              code:kMFHIDPPErrorWriteFailed
                                          userInfo:@{ NSLocalizedDescriptionKey: error.localizedDescription ?: @"HID++ write failed." }];
        }
        [self finishPendingRequestWithResponse:nil error:writeError retire:YES];
    }];
}

- (void)deadlineFiredForRequestIdentifier:(NSUInteger)requestIdentifier {
    [self performAsynchronously:^{
        if (_pendingRequest == nil || _pendingRequest.identifier != requestIdentifier) return;

        NSError *timeoutError = [NSError errorWithDomain:MFHIDPPErrorDomain
                                                    code:kMFHIDPPErrorTimeout
                                                userInfo:@{ NSLocalizedDescriptionKey: @"HID++ request timed out." }];
        [self finishPendingRequestWithResponse:nil error:timeoutError retire:YES];
    }];
}

- (void)finishPendingRequestWithResponse:(MFHIDPPFrame *)response
                                   error:(NSError *)error {
    [self finishPendingRequestWithResponse:response error:error retire:NO];
}

- (void)finishPendingRequestWithResponse:(MFHIDPPFrame *)response
                                   error:(NSError *)error
                                  retire:(BOOL)retire {
    MFHIDPPPendingRequest *pending = _pendingRequest;
    if (pending == nil) return;

    _pendingRequest = nil;
    [_scheduler cancel:pending.deadlineToken];
    if (retire) [self retireIdentityForFrame:pending.frame];
    if (pending.completion != nil) pending.completion(response, error);
}

- (BOOL)isRetiredIdentity:(NSData *)identity {
    return identity != nil && [_retiredIdentities containsObject:identity];
}

- (void)retireIdentityForFrame:(MFHIDPPFrame *)frame {
    if (frame == nil || [self isRetiredIdentity:frame.identity]) return;
    [_retiredIdentities addObject:frame.identity];
    if (_retiredIdentities.count > 16) [_retiredIdentities removeObjectAtIndex:0];
}

@end
