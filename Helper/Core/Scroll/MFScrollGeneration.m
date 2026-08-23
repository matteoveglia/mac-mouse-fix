#import "MFScrollGeneration.h"

uint64_t MFScrollGenerationCurrent(MFScrollGeneration *generation) {
    return atomic_load_explicit(&generation->value, memory_order_acquire);
}

uint64_t MFScrollGenerationAdvance(MFScrollGeneration *generation) {
    uint64_t current = atomic_load_explicit(&generation->value, memory_order_acquire);
    while (true) {
        uint64_t next = current == UINT64_MAX ? 1 : current + 1;
        if (atomic_compare_exchange_weak_explicit(&generation->value,
                                                  &current,
                                                  next,
                                                  memory_order_acq_rel,
                                                  memory_order_acquire)) {
            return next;
        }
    }
}

bool MFScrollGenerationIsCurrent(MFScrollGeneration *generation, uint64_t token) {
    return token == MFScrollGenerationCurrent(generation);
}

bool MFScrollGenerationAllowsCallback(MFScrollGeneration *generation, uint64_t token, bool isTerminal, bool resetInProgress) {
    return MFScrollGenerationIsCurrent(generation, token) || (isTerminal && resetInProgress);
}
