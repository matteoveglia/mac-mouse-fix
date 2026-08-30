//
// --------------------------------------------------------------------------
// KeyboardActivatorState.swift
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

import Foundation

/// The event-tap owner uses this reducer to keep keyboard activator input
/// separate from ordinary keyboard modifier flags. A configured key behaves
/// like a held mouse modifier: its first key-down activates, repeats and
/// unrelated configured keys are consumed, and the matching key-up deactivates.
@objc enum MFKeyboardActivatorEventResult: Int {
    case passThrough = 0
    case swallow = 1
    case activated = 2
    case deactivated = 3
}

@objc final class KeyboardActivatorState: NSObject {
    // These are the macOS virtual key codes for the otherwise-unused F13-F20
    // keys. Carbon does not define F21-F24 virtual key codes, so accepting
    // arbitrary values there would risk capturing arrows or other normal keys.
    private static let supportedCodes: Set<UInt16> = [
        0x69, // F13
        0x6B, // F14
        0x71, // F15
        0x6A, // F16
        0x40, // F17
        0x4F, // F18
        0x50, // F19
        0x5A, // F20
    ]

    private var heldKeyCode: UInt16?

    @objc static func isSupportedKeyCode(_ keyCode: UInt16) -> Bool {
        return supportedCodes.contains(keyCode)
    }

    @objc static func supportedKeyCodes() -> NSSet {
        return NSSet(array: supportedCodes.sorted().map { NSNumber(value: $0) })
    }

    @objc func currentKeyCode() -> NSNumber? {
        guard let heldKeyCode else { return nil }
        return NSNumber(value: heldKeyCode)
    }

    @objc func handleKeyDown(
        _ keyCode: UInt16,
        isRepeat: Bool,
        isSynthetic: Bool,
        allowedKeyCodes: NSSet
    ) -> MFKeyboardActivatorEventResult {
        if isSynthetic
            || !Self.isSupportedKeyCode(keyCode)
            || !allowedKeyCodes.contains(NSNumber(value: keyCode)) {
            return .passThrough
        }

        // Auto-repeat must never activate a key whose initial key-down was
        // missed or was intentionally ignored during a transition. Once a
        // key owns the gesture, its repeats are consumed with the rest of
        // that key's stream.
        if isRepeat {
            return heldKeyCode == nil ? .passThrough : .swallow
        }

        if heldKeyCode == nil {
            heldKeyCode = keyCode
            return .activated
        }

        // Only one activator owns the gesture at a time. The second key is
        // still consumed so a configured key cannot leak into the front app.
        return .swallow
    }

    @objc func handleKeyUp(
        _ keyCode: UInt16,
        isSynthetic: Bool,
        allowedKeyCodes: NSSet
    ) -> MFKeyboardActivatorEventResult {
        if isSynthetic
            || !Self.isSupportedKeyCode(keyCode)
            || !allowedKeyCodes.contains(NSNumber(value: keyCode)) {
            return .passThrough
        }

        if heldKeyCode == keyCode {
            heldKeyCode = nil
            return .deactivated
        }

        // If another activator is held, this key may have been consumed while
        // the active key owned the gesture. Keep its release out of the app.
        if heldKeyCode != nil {
            return .swallow
        }

        // A release after timeout, disable, or config replacement has no
        // corresponding swallowed key-down and is safe to pass through.
        return .passThrough
    }

    @objc func reset() -> Bool {
        let wasActive = heldKeyCode != nil
        heldKeyCode = nil
        return wasActive
    }
}
