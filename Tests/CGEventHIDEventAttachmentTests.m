#import <Foundation/Foundation.h>
#import <stdint.h>
#import "CGEventHIDEventAttachment.h"

typedef struct {
    int modernCalls;
    int legacyCalls;
    BOOL modernResult;
    BOOL legacyResult;
} MFFakeAttachmentContext;

static BOOL MFModernSetter(void *context, const void *cgEvent, const void *hidEvent) {
    MFFakeAttachmentContext *fake = context;
    fake->modernCalls++;
    return fake->modernResult;
}

static BOOL MFLegacySetter(void *context, const void *cgEvent, const void *hidEvent) {
    MFFakeAttachmentContext *fake = context;
    fake->legacyCalls++;
    return fake->legacyResult;
}

static void MFCheck(BOOL condition, NSString *message, int *failures) {
    if (!condition) {
        NSLog(@"FAIL: %@", message);
        (*failures)++;
    }
}

int main(void) {
    @autoreleasepool {
        int failures = 0;
        const void *cgEvent = (const void *)(uintptr_t)0x1;
        const void *hidEvent = (const void *)(uintptr_t)0x2;

        MFFakeAttachmentContext fake = { .modernResult = YES, .legacyResult = YES };
        MFCGEventHIDEventAttachmentBackend backend = {
            .context = &fake,
            .modernSetter = MFModernSetter,
            .legacySetter = MFLegacySetter,
        };
        MFCheck(MFCGEventAttachHIDEvent(cgEvent, hidEvent, YES, backend), @"modern setter succeeds", &failures);
        MFCheck(fake.modernCalls == 1 && fake.legacyCalls == 0, @"modern path never touches legacy offsets", &failures);

        fake = (MFFakeAttachmentContext){ .modernResult = YES, .legacyResult = YES };
        backend.context = &fake;
        backend.modernSetter = NULL;
        MFCheck(!MFCGEventAttachHIDEvent(cgEvent, hidEvent, YES, backend), @"missing modern setter fails closed", &failures);
        MFCheck(fake.modernCalls == 0 && fake.legacyCalls == 0, @"missing modern setter does not fall back", &failures);

        fake = (MFFakeAttachmentContext){ .modernResult = NO, .legacyResult = YES };
        backend.context = &fake;
        backend.modernSetter = MFModernSetter;
        MFCheck(!MFCGEventAttachHIDEvent(cgEvent, hidEvent, YES, backend), @"modern failure propagates", &failures);
        MFCheck(fake.modernCalls == 1 && fake.legacyCalls == 0, @"failed modern setter remains isolated", &failures);

        fake = (MFFakeAttachmentContext){ .modernResult = YES, .legacyResult = YES };
        backend.context = &fake;
        MFCheck(MFCGEventAttachHIDEvent(cgEvent, hidEvent, NO, backend), @"legacy setter succeeds", &failures);
        MFCheck(fake.modernCalls == 0 && fake.legacyCalls == 1, @"legacy path is selected only on legacy systems", &failures);

        MFCheck(!MFCGEventAttachHIDEvent(NULL, hidEvent, YES, backend), @"null CGEvent is rejected", &failures);
        MFCheck(!MFCGEventAttachHIDEvent(cgEvent, NULL, YES, backend), @"null HID event is rejected", &failures);

        if (failures == 0) NSLog(@"CGEventHIDEventAttachmentTests passed");
        return failures == 0 ? 0 : 1;
    }
}
