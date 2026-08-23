// Fixture-only transport. It never opens or writes to a hardware device.

#import "MFHIDPPFixtureTransport.h"
#import "MFHIDPPClient.h"
#import <math.h>

@interface MFHIDPPFixtureTransport ()
@property (nonatomic, readwrite) MFHIDPPTransportState state;
@property (nonatomic, readwrite, copy) NSArray<NSData *> *sentReports;
@property (nonatomic, readwrite, copy, nullable) NSData *lastSentReport;
@property (nonatomic, readwrite) NSUInteger startCount;
@property (nonatomic, readwrite) NSUInteger stopCount;
@end

@implementation MFHIDPPFixtureExchange

- (instancetype)initWithRequestReport:(NSData *)requestReport
                         responseReport:(NSData *)responseReport
                                  error:(NSError **)error {
    if (requestReport == nil) {
        if (error != NULL) *error = [NSError errorWithDomain:MFHIDPPErrorDomain
                                                         code:kMFHIDPPErrorInvalidArgument
                                                     userInfo:@{NSLocalizedDescriptionKey: @"Fixture request is nil."}];
        return nil;
    }

    if ([MFHIDPPFrame frameWithReport:requestReport error:error] == nil) return nil;
    if (responseReport != nil && [MFHIDPPFrame frameWithReport:responseReport error:error] == nil) return nil;

    self = [super init];
    if (self == nil) return nil;
    _requestReport = [requestReport copy];
    _responseReport = [responseReport copy];
    return self;
}

+ (instancetype)exchangeWithRequestHex:(NSString *)requestHex
                            responseHex:(NSString *)responseHex
                                  error:(NSError **)error {
    NSData *request = MFHIDPPDataFromHexString(requestHex, error);
    if (request == nil) return nil;
    NSData *response = nil;
    if (responseHex != nil) {
        response = MFHIDPPDataFromHexString(responseHex, error);
        if (response == nil) return nil;
    }
    return [[self alloc] initWithRequestReport:request responseReport:response error:error];
}

- (id)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithRequestReport:self.requestReport
                                                      responseReport:self.responseReport
                                                               error:NULL];
}

@end

@implementation MFHIDPPFixtureTransport {
    NSDictionary<NSData *, MFHIDPPFixtureExchange *> *_exchanges;
    id<MFHIDPPDeadlineScheduler> _scheduler;
    NSTimeInterval _responseDelay;
    MFHIDPPReportHandler _reportHandler;
    MFHIDPPDisconnectHandler _disconnectHandler;
    NSMutableArray<NSData *> *_mutableSentReports;
    NSMutableArray<id> *_scheduledTokens;
}

- (instancetype)initWithExchanges:(NSArray<MFHIDPPFixtureExchange *> *)exchanges
                         scheduler:(id<MFHIDPPDeadlineScheduler>)scheduler
                     responseDelay:(NSTimeInterval)responseDelay {
    self = [super init];
    if (self == nil) return nil;

    NSMutableDictionary *lookup = [NSMutableDictionary dictionary];
    for (MFHIDPPFixtureExchange *exchange in exchanges) {
        if (exchange.requestReport != nil) lookup[exchange.requestReport] = exchange;
    }
    _exchanges = [lookup copy];
    _scheduler = scheduler;
    _responseDelay = isfinite(responseDelay) && responseDelay > 0.0 ? responseDelay : 0.0;
    _mutableSentReports = [NSMutableArray array];
    _scheduledTokens = [NSMutableArray array];
    _state = kMFHIDPPTransportStateIdle;
    return self;
}

- (instancetype)initWithExchanges:(NSArray<MFHIDPPFixtureExchange *> *)exchanges {
    return [self initWithExchanges:exchanges scheduler:nil responseDelay:0.0];
}

- (NSArray<NSData *> *)sentReports {
    @synchronized (self) { return [_mutableSentReports copy]; }
}

- (NSData *)lastSentReport {
    @synchronized (self) { return [_mutableSentReports.lastObject copy]; }
}

- (void)startWithReportHandler:(MFHIDPPReportHandler)reportHandler
               disconnectHandler:(MFHIDPPDisconnectHandler)disconnectHandler {
    @synchronized (self) {
        if (_state != kMFHIDPPTransportStateIdle) return;
        _state = kMFHIDPPTransportStateRunning;
        _startCount += 1;
        _reportHandler = [reportHandler copy];
        _disconnectHandler = [disconnectHandler copy];
    }
}

- (void)sendReport:(NSData *)report completion:(MFHIDPPWriteCompletion)completion {
    MFHIDPPFixtureExchange *exchange = nil;
    @synchronized (self) {
        if (_state != kMFHIDPPTransportStateRunning) {
            if (completion != nil) completion([NSError errorWithDomain:MFHIDPPErrorDomain
                                                                    code:kMFHIDPPErrorDisconnected
                                                                userInfo:@{NSLocalizedDescriptionKey: @"Fixture transport is not running."}]);
            return;
        }
        NSData *copy = [report copy];
        [_mutableSentReports addObject:copy ?: [NSData data]];
        exchange = _exchanges[copy ?: [NSData data]];
    }

    if (exchange == nil) {
        if (completion != nil) completion([NSError errorWithDomain:MFHIDPPErrorDomain
                                                                code:kMFHIDPPErrorFixtureMismatch
                                                            userInfo:@{NSLocalizedDescriptionKey: @"No synthetic fixture matches the request."}]);
        return;
    }

    if (completion != nil) completion(nil);
    if (exchange.responseReport == nil) return;

    NSData *response = exchange.responseReport;
    __weak MFHIDPPFixtureTransport *weakSelf = self;
    if (_scheduler == nil) {
        [self injectReport:response];
        return;
    }

    __block id token = nil;
    token = [_scheduler scheduleAfter:_responseDelay handler:^{
        MFHIDPPFixtureTransport *strongSelf = weakSelf;
        if (strongSelf == nil) return;
        @synchronized (strongSelf) {
            [strongSelf->_scheduledTokens removeObject:token];
        }
        [strongSelf injectReport:response];
    }];
    @synchronized (self) {
        if (token != nil && _state == kMFHIDPPTransportStateRunning) [_scheduledTokens addObject:token];
    }
}

- (void)injectReport:(NSData *)report {
    MFHIDPPReportHandler handler = nil;
    @synchronized (self) {
        if (_state != kMFHIDPPTransportStateRunning || report == nil) return;
        handler = [_reportHandler copy];
    }
    if (handler != nil) handler([report copy]);
}

- (void)disconnectWithError:(NSError *)error {
    MFHIDPPDisconnectHandler handler = nil;
    @synchronized (self) {
        if (_state != kMFHIDPPTransportStateRunning) return;
        _state = kMFHIDPPTransportStateDisconnected;
        handler = [_disconnectHandler copy];
        _reportHandler = nil;
        _disconnectHandler = nil;
    }
    if (handler != nil) handler(error);
}

- (void)stop {
    NSArray *tokens = nil;
    @synchronized (self) {
        if (_state == kMFHIDPPTransportStateStopped) return;
        _state = kMFHIDPPTransportStateStopped;
        _stopCount += 1;
        tokens = [_scheduledTokens copy];
        [_scheduledTokens removeAllObjects];
        _reportHandler = nil;
        _disconnectHandler = nil;
    }
    for (id token in tokens) [_scheduler cancel:token];
}

@end
