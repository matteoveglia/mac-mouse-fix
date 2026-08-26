#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "HelperUtility.h"

static void MFCheck(BOOL condition, NSString *message, int *failures) {
    if (!condition) {
        NSLog(@"FAIL: %@", message);
        (*failures)++;
    }
}

int main(void) {
    @autoreleasepool {
        int failures = 0;

        MFCheck(MFWindowNumberUnderMousePointerFromEvent(NULL) == kCGNullWindowID,
                @"a missing event has no window metadata", &failures);

        MFCheck(MFWindowNumberUnderMousePointerFromFields(1234, 5678) == 5678,
                @"the event-handler window field is preferred", &failures);
        MFCheck(MFWindowNumberUnderMousePointerFromFields(1234, kCGNullWindowID) == 1234,
                @"the visual window field is a fallback", &failures);
        MFCheck(MFWindowNumberUnderMousePointerFromFields(kCGNullWindowID, kCGNullWindowID) == kCGNullWindowID,
                @"missing WindowServer fields remain empty", &failures);

        NSArray *windowInfo = @[
            @{(__bridge NSString *)kCGWindowNumber: @111, (__bridge NSString *)kCGWindowOwnerPID: @222},
            @{(__bridge NSString *)kCGWindowNumber: @1234, (__bridge NSString *)kCGWindowOwnerPID: @5678},
        ];
        MFCheck(MFProcessIdentifierForWindowNumberFromWindowInfo(windowInfo, 1234) == 5678,
                @"the owner PID comes from the matching window entry", &failures);
        MFCheck(MFProcessIdentifierForWindowNumberFromWindowInfo(windowInfo, 9999) == -1,
                @"an unknown window ID does not borrow another window's PID", &failures);
        MFCheck(MFProcessIdentifierForWindowNumberFromWindowInfo(nil, 1234) == -1,
                @"a missing window list fails closed", &failures);

        if (failures == 0) NSLog(@"MFWindowUnderPointerTests passed");
        return failures == 0 ? 0 : 1;
    }
}
