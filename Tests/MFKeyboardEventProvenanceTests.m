//
// Deterministic contract checks for the MMF synthetic keyboard-event marker.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "MFKeyboardEventProvenance.h"

static int failures = 0;

static void check(BOOL condition, const char *message) {
    if (!condition) {
        NSLog(@"FAIL: %s", message);
        failures += 1;
    }
}

int main(void) {
    CGEventRef event = CGEventCreateKeyboardEvent(NULL, 0x69, true);
    if (event == NULL) {
        NSLog(@"FAIL: could not create a keyboard event");
        return 1;
    }

    check(!MFIsSyntheticKeyboardEvent(event), "new keyboard events are unmarked");
    MFMarkKeyboardEventAsSynthetic(event);
    check(MFIsSyntheticKeyboardEvent(event), "the marker is readable on the same event");
    check(CGEventGetIntegerValueField(event, kCGEventSourceUserData) == kMFSyntheticKeyboardEventUserData,
          "the marker uses the event user-data field");
    CFRelease(event);
    CGEventRef freshEvent = CGEventCreateKeyboardEvent(NULL, 0x69, true);
    check(freshEvent != NULL && !MFIsSyntheticKeyboardEvent(freshEvent),
          "new events do not inherit the marker");
    if (freshEvent != NULL) CFRelease(freshEvent);
    if (failures == 0) NSLog(@"MFKeyboardEventProvenanceTests passed");
    return failures == 0 ? 0 : 1;
}
