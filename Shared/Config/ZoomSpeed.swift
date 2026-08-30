//
// --------------------------------------------------------------------------
// ZoomSpeed.swift
// Created for the Mac Mouse Fix remediation work.
// --------------------------------------------------------------------------
//

import Foundation

/// The persisted zoom sensitivity is expressed as a percentage so the
/// setting remains an integer in the property-list configuration.
enum ZoomSpeed {
    static let defaultPercentage = 100
    static let minimumPercentage = 50
    static let maximumPercentage = 200
    static let stepPercentage = 10

    static func clampedPercentage(_ percentage: Int) -> Int {
        min(max(percentage, minimumPercentage), maximumPercentage)
    }

    static func multiplier(for percentage: Int) -> Double {
        Double(clampedPercentage(percentage)) / 100.0
    }

    static func snappedPercentage(for sliderValue: Double) -> Int {
        guard sliderValue.isFinite else { return defaultPercentage }
        let rounded = Int((sliderValue / Double(stepPercentage)).rounded()) * stepPercentage
        return clampedPercentage(rounded)
    }
}
