//
// --------------------------------------------------------------------------
// MFHIDPPTypes.h
// Fixture-only HID++ report types for Mac Mouse Fix.
// --------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const MFHIDPPErrorDomain;

typedef enum : NSInteger {
    kMFHIDPPErrorInvalidArgument = 1,
    kMFHIDPPErrorMalformedReport,
    kMFHIDPPErrorUnsupportedReport,
    kMFHIDPPErrorBusy,
    kMFHIDPPErrorNotStarted,
    kMFHIDPPErrorWriteFailed,
    kMFHIDPPErrorTimeout,
    kMFHIDPPErrorDisconnected,
    kMFHIDPPErrorCancelled,
    kMFHIDPPErrorFixtureMismatch,
    kMFHIDPPErrorFixtureFormat,
    kMFHIDPPErrorStaleResponse,
} MFHIDPPErrorCode;

/// Decode hexadecimal text used by the synthetic fixture files.
/// Whitespace is allowed between bytes; every other character must be a hex digit.
NSData * _Nullable MFHIDPPDataFromHexString(NSString *hexString, NSError ** _Nullable error);

/// Encode bytes as uppercase hexadecimal text without separators.
NSString * MFHIDPPHexStringFromData(NSData *data);

/// Returns the only report sizes accepted by MFHIDPPFrame, or zero for an
/// unsupported report ID.
NSUInteger MFHIDPPExpectedReportLength(uint8_t reportID);

/// A strict HID++ short (0x10, 7 bytes) or long (0x11, 20 bytes) report.
/// The first four bytes are exposed generically because HID++ 1.0 and 2.0
/// interpret the command bytes differently.
@interface MFHIDPPFrame : NSObject <NSCopying>

@property (nonatomic, readonly) NSData *rawReport;
@property (nonatomic, readonly) uint8_t reportID;
@property (nonatomic, readonly) uint8_t deviceIndex;
@property (nonatomic, readonly) uint8_t commandByte;
@property (nonatomic, readonly) uint8_t subcommandByte;
@property (nonatomic, readonly) NSData *payload;
/// The immutable four-byte address used for response correlation.
@property (nonatomic, readonly) NSData *identity;
@property (nonatomic, readonly) NSUInteger expectedLength;

+ (instancetype _Nullable)frameWithReport:(NSData *)report error:(NSError ** _Nullable)error;

- (instancetype _Nullable)initWithReportID:(uint8_t)reportID
                                deviceIndex:(uint8_t)deviceIndex
                               commandByte:(uint8_t)commandByte
                          subcommandByte:(uint8_t)subcommandByte
                                   payload:(NSData *)payload
                                    error:(NSError ** _Nullable)error NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Correlation deliberately ignores payload bytes. The client permits only one
/// request at a time, so the four-byte address is sufficient and deterministic.
- (BOOL)matchesResponseToFrame:(MFHIDPPFrame *)request;

@end

NS_ASSUME_NONNULL_END
