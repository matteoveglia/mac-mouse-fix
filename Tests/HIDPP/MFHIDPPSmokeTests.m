#import "MFHIDPPSmokeTests.h"
#import "MFHIDPPFixtureTransport.h"
#import "MFHIDPPManualScheduler.h"

static void MFHIDPPCheck(BOOL condition, NSString *message, int *failures) {
    if (condition) return;
    (*failures)++;
    fprintf(stderr, "HIDPP smoke failure: %s\n", message.UTF8String);
}

static BOOL MFHIDPPWait(dispatch_semaphore_t semaphore) {
    return dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC)) == 0;
}

static NSArray<MFHIDPPFixtureExchange *> *MFHIDPPLoadFixtures(int *failures) {
    NSString *sourcePath = [NSString stringWithUTF8String:__FILE__] ?: @"";
    NSArray<NSString *> *paths = @[
        [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:@"Tests/HIDPP/Fixtures/synthetic-fixtures.json"],
        [[sourcePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Fixtures/synthetic-fixtures.json"]
    ];

    NSData *data = nil;
    for (NSString *path in paths) {
        data = [NSData dataWithContentsOfFile:path];
        if (data != nil) break;
    }
    MFHIDPPCheck(data != nil, @"synthetic fixture JSON is readable", failures);
    if (data == nil) return @[];

    NSError *error = nil;
    NSDictionary *root = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    MFHIDPPCheck([root isKindOfClass:[NSDictionary class]] && [root[@"synthetic_only"] boolValue], @"fixture metadata is synthetic-only", failures);

    NSMutableArray *exchanges = [NSMutableArray array];
    for (NSDictionary *entry in root[@"exchanges"]) {
        MFHIDPPFixtureExchange *exchange = [MFHIDPPFixtureExchange exchangeWithRequestHex:entry[@"request"] responseHex:entry[@"response"] error:&error];
        MFHIDPPCheck(exchange != nil && error == nil, [NSString stringWithFormat:@"fixture %@ is valid", entry[@"name"]], failures);
        if (exchange != nil) [exchanges addObject:exchange];
    }
    return exchanges;
}

static BOOL MFHIDPPErrorIs(NSError *error, MFHIDPPErrorCode code) {
    return error != nil && [error.domain isEqualToString:MFHIDPPErrorDomain] && error.code == code;
}

int MFHIDPPRunFixtureSmokeTests(void) {
    @autoreleasepool {
        int failures = 0;
        NSArray<MFHIDPPFixtureExchange *> *fixtures = MFHIDPPLoadFixtures(&failures);
        MFHIDPPFixtureExchange *shortExchange = fixtures.count > 0 ? fixtures[0] : nil;
        MFHIDPPFixtureExchange *longExchange = fixtures.count > 1 ? fixtures[1] : nil;
        MFHIDPPFixtureExchange *lateExchange = fixtures.count > 2 ? fixtures[2] : nil;
        MFHIDPPCheck(fixtures.count == 3, @"three synthetic exchanges loaded", &failures);

        NSError *error = nil;
        MFHIDPPFrame *shortFrame = [MFHIDPPFrame frameWithReport:shortExchange.requestReport error:&error];
        MFHIDPPFrame *longFrame = [MFHIDPPFrame frameWithReport:longExchange.requestReport error:&error];
        MFHIDPPCheck(shortFrame.expectedLength == 7 && shortFrame.payload.length == 3, @"strict short frame is seven bytes", &failures);
        MFHIDPPCheck(longFrame.expectedLength == 20 && longFrame.payload.length == 16, @"strict long frame is twenty bytes", &failures);

        NSMutableData *mutableInput = [shortExchange.requestReport mutableCopy];
        MFHIDPPFrame *immutableFrame = [MFHIDPPFrame frameWithReport:mutableInput error:NULL];
        uint8_t changed = 0xFF;
        [mutableInput replaceBytesInRange:NSMakeRange(0, 1) withBytes:&changed length:1];
        MFHIDPPCheck(immutableFrame.reportID == 0x10 && [immutableFrame.rawReport isEqualToData:shortExchange.requestReport], @"frame identity and bytes are immutable", &failures);
        MFHIDPPFrame *differentPayload = [[MFHIDPPFrame alloc] initWithReportID:0x10 deviceIndex:0x01 commandByte:0x20 subcommandByte:0x01 payload:[MFHIDPPDataFromHexString(@"00 00 00", NULL) copy] error:NULL];
        MFHIDPPCheck([differentPayload matchesResponseToFrame:shortFrame], @"response matching uses immutable four-byte identity", &failures);

        NSData *badShort = MFHIDPPDataFromHexString(@"10 01 20 01 A1 A2", NULL);
        NSData *badLong = MFHIDPPDataFromHexString(@"11 02 2A B1 00", NULL);
        NSData *unsupported = MFHIDPPDataFromHexString(@"12 01 02 03 04 05 06", NULL);
        MFHIDPPCheck([MFHIDPPFrame frameWithReport:badShort error:&error] == nil && MFHIDPPErrorIs(error, kMFHIDPPErrorMalformedReport), @"short length is rejected", &failures);
        error = nil;
        MFHIDPPCheck([MFHIDPPFrame frameWithReport:badLong error:&error] == nil && MFHIDPPErrorIs(error, kMFHIDPPErrorMalformedReport), @"long length is rejected", &failures);
        error = nil;
        MFHIDPPCheck([MFHIDPPFrame frameWithReport:unsupported error:&error] == nil && MFHIDPPErrorIs(error, kMFHIDPPErrorUnsupportedReport), @"unsupported report ID is rejected", &failures);

        MFHIDPPManualScheduler *scheduler = [MFHIDPPManualScheduler new];
        MFHIDPPFixtureTransport *transport = [[MFHIDPPFixtureTransport alloc] initWithExchanges:fixtures scheduler:scheduler responseDelay:0.0];
        MFHIDPPClient *client = [[MFHIDPPClient alloc] initWithTransport:transport scheduler:scheduler];
        [client start];
        dispatch_semaphore_t responseSemaphore = dispatch_semaphore_create(0);
        __block NSInteger responses = 0;
        __block NSError *responseError = nil;
        BOOL firstAccepted = [client sendFrame:shortFrame timeout:2.0 completion:^(MFHIDPPFrame *response, NSError *completionError) {
            responses++;
            responseError = completionError;
            if (response != nil) dispatch_semaphore_signal(responseSemaphore);
        }];
        __block NSError *busyError = nil;
        BOOL secondAccepted = [client sendFrame:longFrame timeout:2.0 completion:^(MFHIDPPFrame *response, NSError *completionError) {
            busyError = completionError;
        }];
        MFHIDPPCheck(firstAccepted && !secondAccepted && MFHIDPPErrorIs(busyError, kMFHIDPPErrorBusy), @"client permits one in-flight request", &failures);
        [scheduler advanceBy:0.0];
        MFHIDPPCheck(MFHIDPPWait(responseSemaphore) && responses == 1 && responseError == nil, @"fixture response completes request", &failures);

        MFHIDPPManualScheduler *lateScheduler = [MFHIDPPManualScheduler new];
        MFHIDPPFixtureTransport *lateTransport = [[MFHIDPPFixtureTransport alloc] initWithExchanges:fixtures scheduler:lateScheduler responseDelay:10.0];
        MFHIDPPClient *lateClient = [[MFHIDPPClient alloc] initWithTransport:lateTransport scheduler:lateScheduler];
        [lateClient start];
        dispatch_semaphore_t timeoutSemaphore = dispatch_semaphore_create(0);
        __block NSInteger lateCompletions = 0;
        __block NSInteger unsolicited = 0;
        lateClient.unsolicitedReportHandler = ^(MFHIDPPFrame *frame) { unsolicited++; };
        [lateClient sendFrame:[MFHIDPPFrame frameWithReport:lateExchange.requestReport error:NULL] timeout:2.0 completion:^(MFHIDPPFrame *response, NSError *completionError) {
            lateCompletions++;
            if (MFHIDPPErrorIs(completionError, kMFHIDPPErrorTimeout)) dispatch_semaphore_signal(timeoutSemaphore);
        }];
        [lateScheduler advanceBy:2.0];
        MFHIDPPCheck(MFHIDPPWait(timeoutSemaphore), @"injected scheduler fires deterministic timeout", &failures);
        [lateScheduler advanceBy:8.0];
        dispatch_semaphore_t nextSemaphore = dispatch_semaphore_create(0);
        [lateClient sendFrame:shortFrame timeout:30.0 completion:^(MFHIDPPFrame *response, NSError *completionError) {
            if (response != nil) dispatch_semaphore_signal(nextSemaphore);
        }];
        [lateScheduler advanceBy:10.0];
        MFHIDPPCheck(MFHIDPPWait(nextSemaphore) && lateCompletions == 1 && unsolicited == 0, @"late response is ignored and cannot complete the next request", &failures);

        MFHIDPPManualScheduler *stopScheduler = [MFHIDPPManualScheduler new];
        MFHIDPPFixtureTransport *stopTransport = [[MFHIDPPFixtureTransport alloc] initWithExchanges:fixtures scheduler:stopScheduler responseDelay:10.0];
        MFHIDPPClient *stopClient = [[MFHIDPPClient alloc] initWithTransport:stopTransport scheduler:stopScheduler];
        [stopClient start];
        dispatch_semaphore_t stopSemaphore = dispatch_semaphore_create(0);
        __block NSInteger stopCompletions = 0;
        [stopClient sendFrame:longFrame timeout:30.0 completion:^(MFHIDPPFrame *response, NSError *completionError) {
            stopCompletions++;
            if (MFHIDPPErrorIs(completionError, kMFHIDPPErrorCancelled)) dispatch_semaphore_signal(stopSemaphore);
        }];
        [stopClient stop];
        [stopClient stop];
        [stopScheduler advanceBy:30.0];
        MFHIDPPCheck(MFHIDPPWait(stopSemaphore) && stopCompletions == 1 && stopTransport.stopCount == 1, @"stop is idempotent and suppresses delayed responses", &failures);

        MFHIDPPManualScheduler *disconnectScheduler = [MFHIDPPManualScheduler new];
        MFHIDPPFixtureTransport *disconnectTransport = [[MFHIDPPFixtureTransport alloc] initWithExchanges:fixtures scheduler:disconnectScheduler responseDelay:10.0];
        MFHIDPPClient *disconnectClient = [[MFHIDPPClient alloc] initWithTransport:disconnectTransport scheduler:disconnectScheduler];
        [disconnectClient start];
        dispatch_semaphore_t disconnectSemaphore = dispatch_semaphore_create(0);
        [disconnectClient sendFrame:shortFrame timeout:30.0 completion:^(MFHIDPPFrame *response, NSError *completionError) {
            if (MFHIDPPErrorIs(completionError, kMFHIDPPErrorDisconnected)) dispatch_semaphore_signal(disconnectSemaphore);
        }];
        [disconnectTransport disconnectWithError:nil];
        MFHIDPPCheck(MFHIDPPWait(disconnectSemaphore) && disconnectClient.state == kMFHIDPPClientStateDisconnected, @"disconnect completes in-flight request", &failures);

        if (failures == 0) fprintf(stdout, "HIDPP fixture smoke: PASS\n");
        else fprintf(stderr, "HIDPP fixture smoke: %d failure(s)\n", failures);
        return failures;
    }
}

#if defined(MFHIDPP_FIXTURE_TEST_MAIN)
int main(void) {
    return MFHIDPPRunFixtureSmokeTests();
}
#endif
