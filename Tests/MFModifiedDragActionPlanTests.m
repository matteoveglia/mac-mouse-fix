#include "MFModifiedDragActionPlan.h"

#include <stdio.h>

int main(void) {
    int failures = 0;
    MFModifiedDragActionPlan plan = {0};

    if (!MFModifiedDragActionPlanHandleEvent(&plan, MFModifiedDragActionEventBecameInUse)) {
        fprintf(stderr, "FAIL: activation executes the configured action\n");
        failures++;
    }
    if (MFModifiedDragActionPlanHandleEvent(&plan, MFModifiedDragActionEventBecameInUse)) {
        fprintf(stderr, "FAIL: repeated activation must not repeat the action\n");
        failures++;
    }
    if (MFModifiedDragActionPlanHandleEvent(&plan, MFModifiedDragActionEventMouseInput)) {
        fprintf(stderr, "FAIL: later movement must not repeat the action\n");
        failures++;
    }
    if (MFModifiedDragActionPlanHandleEvent(&plan, MFModifiedDragActionEventDeactivated)) {
        fprintf(stderr, "FAIL: release or cancellation must not repeat the action\n");
        failures++;
    }

    if (failures == 0) printf("MFModifiedDragActionPlanTests passed\n");
    return failures == 0 ? 0 : 1;
}
