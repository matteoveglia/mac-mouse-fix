//
// --------------------------------------------------------------------------
// MFHIDPPTransport.h
// Fixture-only HID++ transport boundary for Mac Mouse Fix.
// --------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSInteger {
    kMFHIDPPTransportStateIdle = 0,
    kMFHIDPPTransportStateRunning,
    kMFHIDPPTransportStateDisconnected,
    kMFHIDPPTransportStateStopped,
} MFHIDPPTransportState;

typedef void (^MFHIDPPReportHandler)(NSData *report);
typedef void (^MFHIDPPDisconnectHandler)(NSError * _Nullable error);
typedef void (^MFHIDPPWriteCompletion)(NSError * _Nullable error);

/// The transport owns report I/O and connection callbacks. It does not own
/// request/response deadlines or protocol retries.
@protocol MFHIDPPTransport <NSObject>

@property (nonatomic, readonly) MFHIDPPTransportState state;

- (void)startWithReportHandler:(MFHIDPPReportHandler)reportHandler
              disconnectHandler:(MFHIDPPDisconnectHandler)disconnectHandler;

- (void)sendReport:(NSData *)report completion:(MFHIDPPWriteCompletion)completion;

/// Idempotent. A stopped transport must not deliver delayed reports or a second
/// disconnect callback.
- (void)stop;

@end

NS_ASSUME_NONNULL_END
