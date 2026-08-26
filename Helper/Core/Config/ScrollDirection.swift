//
// --------------------------------------------------------------------------
// ScrollDirection.swift
// Created for Mac Mouse Fix
// --------------------------------------------------------------------------
//

/// Pure axis-selection logic shared by the scroll configuration and its
/// deterministic contract tests. The returned value matches
/// `MFScrollInversion`: 1 keeps the input direction and -1 reverses it.
enum ScrollDirection {
    static func inversion(forAxis axis: Int,
                          verticalReversed: Bool,
                          horizontalReversed: Bool) -> Int {
        switch axis {
        case 2: // kMFAxisVertical
            return verticalReversed ? -1 : 1
        case 1: // kMFAxisHorizontal
            return horizontalReversed ? -1 : 1
        default:
            return 1
        }
    }
}
