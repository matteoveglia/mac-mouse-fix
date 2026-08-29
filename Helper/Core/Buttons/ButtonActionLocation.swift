import CoreGraphics

/// Retains the physical press point while ClickCycle resolves hold and
/// multi-click gestures. Synthetic click actions must not follow later pointer
/// movement to a different control.
struct ButtonActionLocation {
    private(set) var point = CGPoint.zero

    mutating func recordPress(at point: CGPoint) {
        self.point = point
    }
}
