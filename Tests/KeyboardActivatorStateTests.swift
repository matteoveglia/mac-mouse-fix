//
// Deterministic contract checks for keyboard-held gesture activation.
// This file is compiled directly by the remediation test workflow.
//

import Foundation

private func check(_ condition: @autoclosure () -> Bool, _ message: String, _ failures: inout Int) {
    if !condition() {
        NSLog("FAIL: %@", message)
        failures += 1
    }
}

@main
private enum KeyboardActivatorStateTestMain {
    static func main() {
        var failures = 0
        let f13: UInt16 = 0x69
        let f14: UInt16 = 0x6B
        let unsupported: UInt16 = 0x00
        let allowed = KeyboardActivatorState.supportedKeyCodes()
        let state = KeyboardActivatorState()

        check(KeyboardActivatorState.isSupportedKeyCode(f13),
              "F13 is supported", &failures)
        check(KeyboardActivatorState.isSupportedKeyCode(f14),
              "F14 is supported", &failures)
        check(!KeyboardActivatorState.isSupportedKeyCode(unsupported),
              "ordinary keys are outside the initial activator scope", &failures)

        let malformedAllowed = NSSet(array: [NSNumber(value: unsupported)])
        check(state.handleKeyDown(unsupported, isRepeat: false, isSynthetic: false, allowedKeyCodes: malformedAllowed) == .passThrough,
              "an unsupported key cannot be captured by a malformed allow-list", &failures)
        check(state.handleKeyUp(unsupported, isSynthetic: false, allowedKeyCodes: malformedAllowed) == .passThrough,
              "an unsupported key release passes through even with a malformed allow-list", &failures)

        check(state.handleKeyDown(unsupported, isRepeat: false, isSynthetic: false, allowedKeyCodes: allowed) == .passThrough,
              "unconfigured key-down passes through", &failures)
        check(state.handleKeyUp(unsupported, isSynthetic: false, allowedKeyCodes: allowed) == .passThrough,
              "unconfigured key-up passes through", &failures)

        check(state.handleKeyDown(f13, isRepeat: false, isSynthetic: false, allowedKeyCodes: allowed) == .activated,
              "first configured key-down activates", &failures)
        check(state.currentKeyCode()?.uint16Value == f13,
              "the active key is retained", &failures)
        check(state.handleKeyDown(f13, isRepeat: true, isSynthetic: false, allowedKeyCodes: allowed) == .swallow,
              "auto-repeat is swallowed without a second activation", &failures)
        check(state.handleKeyDown(f14, isRepeat: false, isSynthetic: false, allowedKeyCodes: allowed) == .swallow,
              "a second configured key cannot take ownership", &failures)
        check(state.handleKeyUp(f14, isSynthetic: false, allowedKeyCodes: allowed) == .swallow,
              "a secondary configured release stays consumed", &failures)
        check(state.handleKeyUp(f13, isSynthetic: false, allowedKeyCodes: allowed) == .deactivated,
              "matching key-up deactivates", &failures)
        check(state.currentKeyCode() == nil,
              "release clears the active key", &failures)
        check(state.handleKeyUp(f13, isSynthetic: false, allowedKeyCodes: allowed) == .passThrough,
              "a stale release after deactivation passes through", &failures)

        check(state.handleKeyDown(f13, isRepeat: true, isSynthetic: false, allowedKeyCodes: allowed) == .passThrough,
              "a repeat cannot activate without an initial key-down", &failures)
        check(state.handleKeyDown(f13, isRepeat: false, isSynthetic: true, allowedKeyCodes: allowed) == .passThrough,
              "synthetic key-down bypasses the activator", &failures)
        check(state.handleKeyUp(f13, isSynthetic: true, allowedKeyCodes: allowed) == .passThrough,
              "synthetic key-up bypasses the activator", &failures)

        check(state.handleKeyDown(f14, isRepeat: false, isSynthetic: false, allowedKeyCodes: allowed) == .activated,
              "a replacement key can activate after release", &failures)
        check(state.reset(), "reset reports an active key", &failures)
        check(state.currentKeyCode() == nil, "reset clears held state", &failures)
        check(state.handleKeyUp(f14, isSynthetic: false, allowedKeyCodes: allowed) == .passThrough,
              "release after reset is not swallowed", &failures)
        check(!state.reset(), "repeated reset is idempotent", &failures)

        if failures == 0 {
            NSLog("KeyboardActivatorStateTests passed")
        }
        exit(failures == 0 ? EXIT_SUCCESS : EXIT_FAILURE)
    }
}
