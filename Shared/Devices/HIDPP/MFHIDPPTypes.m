//
// --------------------------------------------------------------------------
// MFHIDPPTypes.m
// Fixture-only HID++ report types for Mac Mouse Fix.
// --------------------------------------------------------------------------
//

#import "MFHIDPPTypes.h"
#import <stdarg.h>

NSString * const MFHIDPPErrorDomain = @"com.macmousefix.hidpp";

static NSError *MFHIDPPError(MFHIDPPErrorCode code, NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    return [NSError errorWithDomain:MFHIDPPErrorDomain
                               code:code
                           userInfo:@{ NSLocalizedDescriptionKey: message }];
}

static int MFHIDPPHexValue(unichar character) {
    if (character >= '0' && character <= '9') return (int)(character - '0');
    if (character >= 'a' && character <= 'f') return (int)(character - 'a' + 10);
    if (character >= 'A' && character <= 'F') return (int)(character - 'A' + 10);
    return -1;
}

NSData * _Nullable MFHIDPPDataFromHexString(NSString *hexString, NSError ** _Nullable error) {
    if (error != NULL) *error = nil;
    if (hexString == nil) {
        if (error != NULL) *error = MFHIDPPError(kMFHIDPPErrorInvalidArgument, @"Hex string is nil.");
        return nil;
    }

    NSMutableData *result = [NSMutableData data];
    NSInteger highNibble = -1;

    for (NSUInteger index = 0; index < hexString.length; index++) {
        unichar character = [hexString characterAtIndex:index];
        if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:character]) continue;

        int nibble = MFHIDPPHexValue(character);
        if (nibble < 0) {
            if (error != NULL) {
                *error = MFHIDPPError(kMFHIDPPErrorFixtureFormat,
                                      @"Invalid hexadecimal character at offset %lu.",
                                      (unsigned long)index);
            }
            return nil;
        }

        if (highNibble < 0) {
            highNibble = nibble;
        } else {
            uint8_t byte = (uint8_t)((highNibble << 4) | nibble);
            [result appendBytes:&byte length:sizeof(byte)];
            highNibble = -1;
        }
    }

    if (highNibble >= 0) {
        if (error != NULL) *error = MFHIDPPError(kMFHIDPPErrorFixtureFormat, @"Hex string has an odd number of digits.");
        return nil;
    }

    return [result copy];
}

NSString * MFHIDPPHexStringFromData(NSData *data) {
    if (data == nil || data.length == 0) return @"";

    const uint8_t *bytes = data.bytes;
    NSMutableString *result = [NSMutableString stringWithCapacity:data.length * 2];
    for (NSUInteger index = 0; index < data.length; index++) {
        [result appendFormat:@"%02X", bytes[index]];
    }
    return [result copy];
}

NSUInteger MFHIDPPExpectedReportLength(uint8_t reportID) {
    switch (reportID) {
        case 0x10: return 7;  // HID++ short report
        case 0x11: return 20; // HID++ long report
        default: return 0;
    }
}

@interface MFHIDPPFrame ()
@property (nonatomic, readwrite) NSData *rawReport;
@property (nonatomic, readwrite) uint8_t reportID;
@property (nonatomic, readwrite) uint8_t deviceIndex;
@property (nonatomic, readwrite) uint8_t commandByte;
@property (nonatomic, readwrite) uint8_t subcommandByte;
@property (nonatomic, readwrite) NSData *payload;
@property (nonatomic, readwrite) NSData *identity;
@property (nonatomic, readwrite) NSUInteger expectedLength;
@end

@implementation MFHIDPPFrame

+ (instancetype _Nullable)frameWithReport:(NSData *)report error:(NSError ** _Nullable)error {
    if (error != NULL) *error = nil;
    if (report == nil || report.length < 1) {
        if (error != NULL) *error = MFHIDPPError(kMFHIDPPErrorMalformedReport, @"HID++ report is empty.");
        return nil;
    }

    const uint8_t *bytes = report.bytes;
    NSUInteger expectedLength = MFHIDPPExpectedReportLength(bytes[0]);
    if (expectedLength == 0) {
        if (error != NULL) *error = MFHIDPPError(kMFHIDPPErrorUnsupportedReport, @"Unsupported HID++ report ID 0x%02X.", bytes[0]);
        return nil;
    }
    if (report.length != expectedLength) {
        if (error != NULL) {
            *error = MFHIDPPError(kMFHIDPPErrorMalformedReport,
                                  @"HID++ report ID 0x%02X has length %lu; expected %lu.",
                                  bytes[0],
                                  (unsigned long)report.length,
                                  (unsigned long)expectedLength);
        }
        return nil;
    }

    NSData *payload = [report subdataWithRange:NSMakeRange(4, expectedLength - 4)];
    return [[self alloc] initWithReportID:bytes[0]
                              deviceIndex:bytes[1]
                             commandByte:bytes[2]
                        subcommandByte:bytes[3]
                                 payload:payload
                                  error:error];
}

- (instancetype _Nullable)initWithReportID:(uint8_t)reportID
                                deviceIndex:(uint8_t)deviceIndex
                               commandByte:(uint8_t)commandByte
                          subcommandByte:(uint8_t)subcommandByte
                                   payload:(NSData *)payload
                                    error:(NSError ** _Nullable)error {
    if (error != NULL) *error = nil;
    NSUInteger expectedLength = MFHIDPPExpectedReportLength(reportID);
    if (expectedLength == 0) {
        if (error != NULL) *error = MFHIDPPError(kMFHIDPPErrorUnsupportedReport, @"Unsupported HID++ report ID 0x%02X.", reportID);
        return nil;
    }
    if (payload == nil || payload.length != expectedLength - 4) {
        if (error != NULL) {
            *error = MFHIDPPError(kMFHIDPPErrorMalformedReport,
                                  @"HID++ report ID 0x%02X requires %lu payload bytes; received %lu.",
                                  reportID,
                                  (unsigned long)(expectedLength - 4),
                                  (unsigned long)payload.length);
        }
        return nil;
    }

    self = [super init];
    if (self == nil) return nil;

    NSMutableData *rawReport = [NSMutableData dataWithLength:expectedLength];
    uint8_t *bytes = rawReport.mutableBytes;
    bytes[0] = reportID;
    bytes[1] = deviceIndex;
    bytes[2] = commandByte;
    bytes[3] = subcommandByte;
    [payload getBytes:bytes + 4 length:payload.length];

    _rawReport = [rawReport copy];
    _reportID = reportID;
    _deviceIndex = deviceIndex;
    _commandByte = commandByte;
    _subcommandByte = subcommandByte;
    _payload = [payload copy];
    _identity = [rawReport subdataWithRange:NSMakeRange(0, 4)];
    _expectedLength = expectedLength;
    return self;
}

- (BOOL)matchesResponseToFrame:(MFHIDPPFrame *)request {
    if (request == nil) return NO;
    return [self.identity isEqualToData:request.identity];
}

- (id)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithReportID:self.reportID
                                                   deviceIndex:self.deviceIndex
                                                  commandByte:self.commandByte
                                             subcommandByte:self.subcommandByte
                                                      payload:self.payload
                                                       error:NULL];
}

- (BOOL)isEqual:(id)object {
    if (object == self) return YES;
    if (![object isKindOfClass:[MFHIDPPFrame class]]) return NO;
    return [self.rawReport isEqual:((MFHIDPPFrame *)object).rawReport];
}

- (NSUInteger)hash {
    return self.rawReport.hash;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<MFHIDPPFrame id=0x%02X device=0x%02X command=0x%02X subcommand=0x%02X report=%@>",
            self.reportID,
            self.deviceIndex,
            self.commandByte,
            self.subcommandByte,
            MFHIDPPHexStringFromData(self.rawReport)];
}

@end
