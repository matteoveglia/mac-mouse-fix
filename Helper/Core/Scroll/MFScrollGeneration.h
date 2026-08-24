#ifndef MFScrollGeneration_h
#define MFScrollGeneration_h

#include <stdbool.h>
#include <stdint.h>
#include <stdatomic.h>

typedef struct {
    _Atomic(uint64_t) value;
} MFScrollGeneration;

#define MF_SCROLL_GENERATION_INITIALIZER { ATOMIC_VAR_INIT(1) }

uint64_t MFScrollGenerationCurrent(MFScrollGeneration *generation);
uint64_t MFScrollGenerationAdvance(MFScrollGeneration *generation);
bool MFScrollGenerationIsCurrent(MFScrollGeneration *generation, uint64_t token);
bool MFScrollGenerationAllowsCallback(MFScrollGeneration *generation, uint64_t token, bool isTerminal, bool resetInProgress);

#endif
