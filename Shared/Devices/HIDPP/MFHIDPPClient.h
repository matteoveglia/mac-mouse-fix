//
// --------------------------------------------------------------------------
// MFHIDPPClient.h
// Fixture-only HID++ request/response state machine for Mac Mouse Fix.
// --------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>
#import "MFHIDPPTypes.h"
#import "MFHIDPPTransport.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSInteger {
    kMFHIDPPClientStateIdle = 0,
    kMFHIDPPClientStateRunning,
    kMFHIDPPClientStateDisconnected,
    kMFHIDPPClientStateStopped,
} MFHIDPPClientState;

typedef void (^MFHIDPPFrameCompletion)(MFHIDPPFrame * _Nullable response, NSError * _Nullable error);
typedef void (^MFHIDPPDeadlineHandler)(void);

/// A scheduler is injected so timeout behavior can be tested without sleeping.
@protocol MFHIDPPDeadlineScheduler <NSObject>
- (id)scheduleAfter:(NSTimeInterval)delay handler:(MFHIDPPDeadlineHandler)handler;
- (void)cancel:(id)token;
@end

@interface MFHIDPPClient : NSObject

@property (nonatomic, readonly) MFHIDPPClientState state;
@property (nonatomic, copy) void (^ _Nullable unsolicitedReportHandler)(MFHIDPPFrame *frame);

- (instancetype)initWithTransport:(id<MFHIDPPTransport>)transport
                         scheduler:(id<MFHIDPPDeadlineScheduler> _Nullable)scheduler;

- (instancetype)init NS_UNAVAILABLE;

- (void)start;

/// Returns NO when the request was rejected immediately because the client is
/// not running, already has a request in flight, or the timeout is invalid.
/// Rejected requests still receive their NSError completion on the client queue.
- (BOOL)sendFrame:(MFHIDPPFrame *)frame
          timeout:(NSTimeInterval)timeout
       completion:(MFHIDPPFrameCompletion)completion;

/// Idempotent. Completes an in-flight request with kMFHIDPPErrorCancelled,
/// stops the transport, and suppresses all delayed reports.
- (void)stop;

@end

NS_ASSUME_NONNULL_END
