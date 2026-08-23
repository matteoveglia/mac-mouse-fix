#import <Foundation/Foundation.h>
#import "MFScrollGeneration.h"

static void MFCheck(BOOL condition, NSString *message, int *failures) {
    if (!condition) {
        NSLog(@"FAIL: %@", message);
        (*failures)++;
    }
}

int main(void) {
    @autoreleasepool {
        int failures = 0;
        MFScrollGeneration generation = MF_SCROLL_GENERATION_INITIALIZER;

        uint64_t first = MFScrollGenerationCurrent(&generation);
        MFCheck(first != 0, @"initial generation is valid", &failures);
        MFCheck(MFScrollGenerationIsCurrent(&generation, first), @"fresh token is current", &failures);

        uint64_t second = MFScrollGenerationAdvance(&generation);
        MFCheck(second != first, @"reset advances generation", &failures);
        MFCheck(!MFScrollGenerationIsCurrent(&generation, first), @"queued work from the prior generation is stale", &failures);
        MFCheck(MFScrollGenerationIsCurrent(&generation, second), @"new work is admitted", &failures);
        MFCheck(!MFScrollGenerationAllowsCallback(&generation, first, false, true), @"reset never admits stale non-terminal output", &failures);
        MFCheck(!MFScrollGenerationAllowsCallback(&generation, first, true, false), @"stale terminal output is rejected after the reset barrier", &failures);
        MFCheck(MFScrollGenerationAllowsCallback(&generation, first, true, true), @"the reset barrier admits one stale terminal cleanup callback", &failures);

        uint64_t third = MFScrollGenerationAdvance(&generation);
        MFCheck(!MFScrollGenerationIsCurrent(&generation, second), @"repeated reset invalidates the immediately prior generation", &failures);
        MFCheck(MFScrollGenerationIsCurrent(&generation, third), @"repeated reset remains usable", &failures);

        uint64_t admittedDuringReset = MFScrollGenerationCurrent(&generation);
        uint64_t afterReset = MFScrollGenerationAdvance(&generation);
        MFCheck(!MFScrollGenerationIsCurrent(&generation, admittedDuringReset), @"work admitted while a reset barrier runs is stale when the barrier closes", &failures);
        MFCheck(MFScrollGenerationIsCurrent(&generation, afterReset), @"work admitted after the barrier closes is current", &failures);

        __block MFScrollGeneration concurrent = MF_SCROLL_GENERATION_INITIALIZER;
        dispatch_apply(8, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^(size_t worker) {
            for (int i = 0; i < 1000; i++) MFScrollGenerationAdvance(&concurrent);
        });
        MFCheck(MFScrollGenerationCurrent(&concurrent) == 8001, @"concurrent reset requests do not lose generation advances", &failures);

        atomic_store_explicit(&generation.value, UINT64_MAX, memory_order_release);
        uint64_t wrapped = MFScrollGenerationAdvance(&generation);
        MFCheck(wrapped == 1, @"generation wrap skips the invalid zero token", &failures);

        if (failures == 0) NSLog(@"MFScrollGenerationTests passed");
        return failures == 0 ? 0 : 1;
    }
}
