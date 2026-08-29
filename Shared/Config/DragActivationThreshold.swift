import Foundation

enum DragActivationThreshold {
    static let defaultValue = 7
    static let minimumValue = 3
    static let maximumValue = 40

    static func sanitized(_ rawValue: Any?) -> Int {
        guard let number = rawValue as? NSNumber else { return defaultValue }
        return min(max(number.intValue, minimumValue), maximumValue)
    }
}
