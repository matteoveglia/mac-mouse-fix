// Fixture-only transport. It never opens or writes to a hardware device.

#import <Foundation/Foundation.h>
#import "MFHIDPPTransport.h"
#import "MFHIDPPTypes.h"

@protocol MFHIDPPDeadlineScheduler;

NS_ASSUME_NONNULL_BEGIN

@interface MFHIDPPFixtureExchange : NSObject <NSCopying>

@property (nonatomic, readonly, copy) NSData *requestReport;
@property (nonatomic, readonly, copy, nullable) NSData *responseReport;

+ (instancetype _Nullable)exchangeWithRequestHex:(NSString *)requestHex
                                    responseHex:(NSString * _Nullable)responseHex
                                          error:(NSError ** _Nullable)error;

- (instancetype _Nullable)initWithRequestReport:(NSData *)requestReport
                                  responseReport:(NSData * _Nullable)responseReport
                                           error:(NSError ** _Nullable)error NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface MFHIDPPFixtureTransport : NSObject <MFHIDPPTransport>

- (instancetype)initWithExchanges:(NSArray<MFHIDPPFixtureExchange *> *)exchanges
                         scheduler:(id<MFHIDPPDeadlineScheduler> _Nullable)scheduler
                     responseDelay:(NSTimeInterval)responseDelay;

- (instancetype)initWithExchanges:(NSArray<MFHIDPPFixtureExchange *> *)exchanges;

@property (nonatomic, readonly) MFHIDPPTransportState state;
@property (nonatomic, readonly, copy) NSArray<NSData *> *sentReports;
@property (nonatomic, readonly, copy, nullable) NSData *lastSentReport;
@property (nonatomic, readonly) NSUInteger startCount;
@property (nonatomic, readonly) NSUInteger stopCount;

/// Test-only input injection. Reports are delivered only while the fixture
/// transport is running; the client still serializes their handling.
- (void)injectReport:(NSData *)report;
- (void)disconnectWithError:(NSError * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
