//
// --------------------------------------------------------------------------
// ApplicationPolicy.swift
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

import Foundation
import AppKit

/// The selector kinds supported by the bounded application policy.
///
/// The raw-value order is also the deterministic tie-break order for the two
/// wrapper selectors.  A bundle identifier is the strongest selector, then an
/// exact executable path, then wrapper metadata, and finally an exact process
/// name.
@objc(MFApplicationPolicyMatchKind)
public enum ApplicationPolicyMatchKind: Int {
    case bundleIdentifier = 0
    case executablePath = 1
    case wrapperBundleIdentifier = 2
    case wrapperPath = 3
    case processName = 4
}

/// The result of evaluating a policy rule.
@objc(MFApplicationPolicyEffect)
public enum ApplicationPolicyEffect: Int {
    case allow = 0
    case deny = 1
}

/// The legacy scope values used by the scrolling configuration.
@objc(MFApplicationPolicyLegacyScope)
public enum ApplicationPolicyLegacyScope: Int {
    case all = 0
    case include = 1
    case exclude = 2
}

/// Validation results exposed for callers that want to reject a config before
/// constructing a snapshot.  A snapshot can only be created when this value
/// is `valid`.
@objc(MFApplicationPolicyValidationCode)
public enum ApplicationPolicyValidationCode: Int {
    case valid = 0
    case invalidRule = 1
    case tooManyRules = 2
    case duplicateRule = 3
    case invalidLegacyScope = 4
    case invalidLegacyApplication = 5
}

/// Shared limits.  They intentionally keep policy evaluation bounded even
/// when the input originated in a manually edited plist or an IPC payload.
fileprivate enum ApplicationPolicyLimits {
    static let maximumRuleCount = 128
    static let maximumStringLength = 1_024
}

fileprivate enum ApplicationPolicyNormalization {

    private static let wildcardCharacters = CharacterSet(charactersIn: "*?[]")

    static func bundleIdentifier(_ raw: String) -> String? {
        guard isUsableString(raw), raw.utf8.count <= ApplicationPolicyLimits.maximumStringLength else {
            return nil
        }

        // Bundle identifiers are reverse-DNS-like identifiers.  Keeping the
        // grammar deliberately conservative prevents wildcard and path-like
        // values from becoming accidental broad selectors.
        guard !raw.hasPrefix("."), !raw.hasSuffix("."), !raw.contains("..") else {
            return nil
        }

        for scalar in raw.unicodeScalars {
            let value = scalar.value
            let isLowercaseLetter = value >= 97 && value <= 122
            let isUppercaseLetter = value >= 65 && value <= 90
            let isDigit = value >= 48 && value <= 57
            let isAllowedPunctuation = value == 46 || value == 45 || value == 95
            guard isLowercaseLetter || isUppercaseLetter || isDigit || isAllowedPunctuation else {
                return nil
            }
        }

        return raw
    }

    static func absolutePath(_ raw: String) -> String? {
        guard isUsableString(raw), raw.utf8.count <= ApplicationPolicyLimits.maximumStringLength else {
            return nil
        }
        guard raw.hasPrefix("/") else { return nil }

        // Exact path matching is based on a stable lexical normalization.  We
        // intentionally do not resolve symlinks or touch the file system.
        let standardized = URL(fileURLWithPath: raw).standardizedFileURL.path
        guard standardized.hasPrefix("/"), standardized != "/" else { return nil }
        return standardized
    }

    static func processName(_ raw: String) -> String? {
        guard isUsableString(raw), raw.utf8.count <= ApplicationPolicyLimits.maximumStringLength else {
            return nil
        }
        // A process-name selector is intentionally exact and never path-like.
        guard !raw.contains("/") else { return nil }
        return raw
    }

    static func value(_ raw: String, for kind: ApplicationPolicyMatchKind) -> String? {
        switch kind {
        case .bundleIdentifier, .wrapperBundleIdentifier:
            return bundleIdentifier(raw)
        case .executablePath, .wrapperPath:
            return absolutePath(raw)
        case .processName:
            return processName(raw)
        }
    }

    private static func isUsableString(_ raw: String) -> Bool {
        guard !raw.isEmpty else { return false }
        guard raw == raw.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
        guard raw.rangeOfCharacter(from: .controlCharacters) == nil else { return false }
        guard raw.rangeOfCharacter(from: wildcardCharacters) == nil else { return false }
        return true
    }
}

/// An immutable, normalized description of a running application.
@objc(MFApplicationIdentity)
public final class ApplicationIdentity: NSObject {

    @objc public let bundleIdentifier: String?
    @objc public let executablePath: String?
    @objc public let wrapperBundleIdentifier: String?
    @objc public let wrapperPath: String?
    @objc public let processName: String?
    @objc public let processNameFallbackAllowed: Bool

    /// An Objective-C-friendly initializer.  All fields are optional so an
    /// unknown or permission-denied application can still be represented and
    /// will safely fall through to the snapshot default.
    @objc(initWithBundleIdentifier:executablePath:wrapperBundleIdentifier:wrapperPath:processName:processNameFallbackAllowed:)
    public init?(bundleIdentifier: String?,
                 executablePath: String?,
                 wrapperBundleIdentifier: String?,
                 wrapperPath: String?,
                 processName: String?,
                 processNameFallbackAllowed: Bool) {

        if let bundleIdentifier {
            guard let normalized = ApplicationPolicyNormalization.bundleIdentifier(bundleIdentifier) else {
                return nil
            }
            self.bundleIdentifier = normalized
        } else {
            self.bundleIdentifier = nil
        }

        if let executablePath {
            guard let normalized = ApplicationPolicyNormalization.absolutePath(executablePath) else {
                return nil
            }
            self.executablePath = normalized
        } else {
            self.executablePath = nil
        }

        if let wrapperBundleIdentifier {
            guard let normalized = ApplicationPolicyNormalization.bundleIdentifier(wrapperBundleIdentifier) else {
                return nil
            }
            self.wrapperBundleIdentifier = normalized
        } else {
            self.wrapperBundleIdentifier = nil
        }

        if let wrapperPath {
            guard let normalized = ApplicationPolicyNormalization.absolutePath(wrapperPath) else {
                return nil
            }
            self.wrapperPath = normalized
        } else {
            self.wrapperPath = nil
        }

        if let processName {
            guard let normalized = ApplicationPolicyNormalization.processName(processName) else {
                return nil
            }
            self.processName = normalized
        } else {
            self.processName = nil
        }

        self.processNameFallbackAllowed = processNameFallbackAllowed
        super.init()
    }

    /// Swift and Objective-C convenience initializer.  Process-name fallback
    /// is exact and controlled by the process-name rules in the snapshot.
    @objc(initWithBundleIdentifier:executablePath:wrapperBundleIdentifier:wrapperPath:processName:)
    public convenience init?(bundleIdentifier: String?,
                            executablePath: String?,
                            wrapperBundleIdentifier: String?,
                            wrapperPath: String?,
                            processName: String?) {
        self.init(bundleIdentifier: bundleIdentifier,
                  executablePath: executablePath,
                  wrapperBundleIdentifier: wrapperBundleIdentifier,
                  wrapperPath: wrapperPath,
                  processName: processName,
                  processNameFallbackAllowed: true)
    }

    /// Build an identity from the stable fields available on a running
    /// application.  Wrapper metadata can be supplied separately when the
    /// caller has inspected an application or runtime wrapper.
    @available(macOS 10.10, *)
    @objc(initWithRunningApplication:)
    public convenience init?(runningApplication: NSRunningApplication) {
        self.init(bundleIdentifier: runningApplication.bundleIdentifier,
                  executablePath: runningApplication.executableURL?.path,
                  wrapperBundleIdentifier: runningApplication.bundleIdentifier,
                  wrapperPath: runningApplication.bundleURL?.path,
                  processName: runningApplication.localizedName,
                  processNameFallbackAllowed: true)
    }

    /// Compatibility aliases for Objective-C callers that use the common ID
    /// terminology.  They are read-only views over the immutable fields.
    @objc public var bundleID: String? { bundleIdentifier }
    @objc public var wrapperBundleID: String? { wrapperBundleIdentifier }
    @objc public var executableURLPath: String? { executablePath }
    @objc public var wrapperExecutablePath: String? { wrapperPath }
    @objc public var allowsProcessNameFallback: Bool { processNameFallbackAllowed }

    @objc public var hasAnyStableIdentifier: Bool {
        bundleIdentifier != nil || executablePath != nil || wrapperBundleIdentifier != nil || wrapperPath != nil
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ApplicationIdentity else { return false }
        return bundleIdentifier == other.bundleIdentifier
            && executablePath == other.executablePath
            && wrapperBundleIdentifier == other.wrapperBundleIdentifier
            && wrapperPath == other.wrapperPath
            && processName == other.processName
            && processNameFallbackAllowed == other.processNameFallbackAllowed
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(bundleIdentifier)
        hasher.combine(executablePath)
        hasher.combine(wrapperBundleIdentifier)
        hasher.combine(wrapperPath)
        hasher.combine(processName)
        hasher.combine(processNameFallbackAllowed)
        return hasher.finalize()
    }

    public override var description: String {
        "ApplicationIdentity(bundleIdentifier: \(bundleIdentifier ?? "nil"), executablePath: \(executablePath ?? "nil"), wrapperBundleIdentifier: \(wrapperBundleIdentifier ?? "nil"), wrapperPath: \(wrapperPath ?? "nil"), processName: \(processName ?? "nil"), processNameFallbackAllowed: \(processNameFallbackAllowed))"
    }
}

/// One exact, immutable policy selector and its effect.
@objc(MFApplicationPolicyRule)
public final class ApplicationPolicyRule: NSObject {

    @objc public let matchKind: ApplicationPolicyMatchKind
    @objc public let value: String
    @objc public let effect: ApplicationPolicyEffect

    /// Larger values win when more than one selector matches an identity.
    @objc public var precedence: Int {
        switch matchKind {
        case .bundleIdentifier:
            return 4
        case .executablePath:
            return 3
        case .wrapperBundleIdentifier, .wrapperPath:
            return 2
        case .processName:
            return 1
        }
    }

    @objc(matchKind:value:effect:)
    public init?(matchKind: ApplicationPolicyMatchKind,
                 value: String,
                 effect: ApplicationPolicyEffect) {
        guard let normalized = ApplicationPolicyNormalization.value(value, for: matchKind) else {
            return nil
        }
        self.matchKind = matchKind
        self.value = normalized
        self.effect = effect
        super.init()
    }

    @objc(initWithBundleIdentifier:effect:)
    public convenience init?(bundleIdentifier: String, effect: ApplicationPolicyEffect) {
        self.init(matchKind: .bundleIdentifier, value: bundleIdentifier, effect: effect)
    }

    @objc(initWithExecutablePath:effect:)
    public convenience init?(executablePath: String, effect: ApplicationPolicyEffect) {
        self.init(matchKind: .executablePath, value: executablePath, effect: effect)
    }

    @objc(initWithWrapperBundleIdentifier:effect:)
    public convenience init?(wrapperBundleIdentifier: String, effect: ApplicationPolicyEffect) {
        self.init(matchKind: .wrapperBundleIdentifier, value: wrapperBundleIdentifier, effect: effect)
    }

    @objc(initWithWrapperPath:effect:)
    public convenience init?(wrapperPath: String, effect: ApplicationPolicyEffect) {
        self.init(matchKind: .wrapperPath, value: wrapperPath, effect: effect)
    }

    @objc(initWithProcessName:effect:)
    public convenience init?(processName: String, effect: ApplicationPolicyEffect) {
        self.init(matchKind: .processName, value: processName, effect: effect)
    }

    fileprivate var canonicalKey: String {
        "\(matchKind.rawValue):\(value)"
    }

    fileprivate func matches(_ identity: ApplicationIdentity) -> Bool {
        switch matchKind {
        case .bundleIdentifier:
            return identity.bundleIdentifier == value
        case .executablePath:
            return identity.executablePath == value
        case .wrapperBundleIdentifier:
            return identity.wrapperBundleIdentifier == value
        case .wrapperPath:
            return identity.wrapperPath == value
        case .processName:
            guard identity.processNameFallbackAllowed,
                  identity.bundleIdentifier == nil,
                  identity.executablePath == nil,
                  identity.wrapperBundleIdentifier == nil,
                  identity.wrapperPath == nil
            else { return false }
            return identity.processName == value
        }
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ApplicationPolicyRule else { return false }
        return matchKind == other.matchKind && value == other.value && effect == other.effect
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(matchKind.rawValue)
        hasher.combine(value)
        hasher.combine(effect.rawValue)
        return hasher.finalize()
    }

    public override var description: String {
        "ApplicationPolicyRule(kind: \(matchKind.rawValue), value: \(value), effect: \(effect.rawValue))"
    }
}

/// Pure validation entry points for Objective-C callers.
@objc(MFApplicationPolicyValidator)
public final class ApplicationPolicyValidator: NSObject {

    @objc(maximumRuleCount)
    public class var maximumRuleCount: Int { ApplicationPolicyLimits.maximumRuleCount }

    @objc public class func validate(_ rule: ApplicationPolicyRule?) -> ApplicationPolicyValidationCode {
        rule == nil ? .invalidRule : .valid
    }

    @objc(validateSnapshotWithDefaultEffect:ruleArray:)
    public class func validateSnapshot(defaultEffect: ApplicationPolicyEffect,
                                       ruleArray: NSArray) -> ApplicationPolicyValidationCode {
        guard ruleArray.count <= ApplicationPolicyLimits.maximumRuleCount else {
            return .tooManyRules
        }

        var keys = Set<String>()
        for object in ruleArray {
            guard let rule = object as? ApplicationPolicyRule else { return .invalidRule }
            guard keys.insert(rule.canonicalKey).inserted else { return .duplicateRule }
        }

        _ = defaultEffect
        return .valid
    }
}

/// A validated immutable policy snapshot.  The snapshot is the hand-off
/// boundary for a helper: callers construct a new value and replace the old
/// one rather than mutating a live rule collection during event handling.
@objc(MFApplicationPolicySnapshot)
public final class ApplicationPolicySnapshot: NSObject {

    @objc public let defaultEffect: ApplicationPolicyEffect
    @objc public let rules: [ApplicationPolicyRule]

    public init?(defaultEffect: ApplicationPolicyEffect, rules: [ApplicationPolicyRule]) {
        guard rules.count <= ApplicationPolicyLimits.maximumRuleCount else { return nil }

        var keys = Set<String>()
        for rule in rules {
            guard keys.insert(rule.canonicalKey).inserted else { return nil }
        }

        // Sorting makes the precedence and wrapper tie-break deterministic,
        // independent of the order in which a config was decoded.
        self.rules = rules.sorted {
            if $0.precedence != $1.precedence {
                return $0.precedence > $1.precedence
            }
            if $0.matchKind.rawValue != $1.matchKind.rawValue {
                return $0.matchKind.rawValue < $1.matchKind.rawValue
            }
            if $0.value != $1.value {
                return $0.value < $1.value
            }
            return $0.effect.rawValue < $1.effect.rawValue
        }
        self.defaultEffect = defaultEffect
        super.init()
    }

    @objc(initWithDefaultEffect:ruleArray:)
    public convenience init?(defaultEffect: ApplicationPolicyEffect, ruleArray: NSArray) {
        var typedRules = [ApplicationPolicyRule]()
        typedRules.reserveCapacity(ruleArray.count)
        for object in ruleArray {
            guard let rule = object as? ApplicationPolicyRule else { return nil }
            typedRules.append(rule)
        }
        self.init(defaultEffect: defaultEffect, rules: typedRules)
    }

    /// Return the strongest matching rule.  The rule list is already in
    /// canonical order, so the first match is deterministic.
    @objc(matchingRuleForIdentity:)
    public func matchingRule(for identity: ApplicationIdentity) -> ApplicationPolicyRule? {
        rules.first { $0.matches(identity) }
    }

    @objc(decisionForIdentity:)
    public func decision(for identity: ApplicationIdentity) -> ApplicationPolicyEffect {
        matchingRule(for: identity)?.effect ?? defaultEffect
    }

    @objc(isEnabledForIdentity:)
    public func isEnabled(for identity: ApplicationIdentity) -> Bool {
        decision(for: identity) == .allow
    }

    @objc public var allowsAllByDefault: Bool { defaultEffect == .allow }

    /// Project a canonical policy into the explicit Advanced scope. Legacy
    /// bundle-ID rules and their default effect are intentionally excluded so
    /// Advanced mode cannot accidentally inherit list-based behavior.
    @objc(advancedScopeSnapshot)
    public func advancedScopeSnapshot() -> ApplicationPolicySnapshot? {
        ApplicationPolicySnapshot(defaultEffect: .allow,
                                  rules: rules.filter({ $0.matchKind != .bundleIdentifier }))
    }

    /// Convert the old `all`, `include`, and `exclude` representation to a
    /// validated snapshot.  Legacy entries are bundle identifiers; paths and
    /// process names must use explicit rules so they cannot be accidentally
    /// interpreted as broad legacy selectors.
    public class func fromLegacy(scope: String, applications: [String]) -> ApplicationPolicySnapshot? {
        guard let parsedScope = parseLegacyScope(scope) else { return nil }

        var rules = [ApplicationPolicyRule]()
        var seen = Set<String>()
        if parsedScope != .all {
            guard applications.count <= ApplicationPolicyLimits.maximumRuleCount else { return nil }
            let effect: ApplicationPolicyEffect = parsedScope == .include ? .allow : .deny

            for application in applications {
                guard let rule = ApplicationPolicyRule(bundleIdentifier: application, effect: effect) else {
                    return nil
                }
                guard seen.insert(rule.canonicalKey).inserted else { continue }
                rules.append(rule)
            }
        }

        let defaultEffect: ApplicationPolicyEffect = parsedScope == .include ? .deny : .allow
        return ApplicationPolicySnapshot(defaultEffect: defaultEffect, rules: rules)
    }

    @objc(snapshotFromLegacyScope:applications:)
    public class func snapshotFromLegacyScope(_ scope: String, applications: NSArray) -> ApplicationPolicySnapshot? {
        var strings = [String]()
        strings.reserveCapacity(applications.count)
        for object in applications {
            guard let string = object as? String else { return nil }
            strings.append(string)
        }
        return fromLegacy(scope: scope, applications: strings)
    }

    @objc(snapshotFromLegacyDictionary:)
    public class func snapshotFromLegacyDictionary(_ dictionary: NSDictionary) -> ApplicationPolicySnapshot? {
        let scope = (dictionary["scope"] as? String)
            ?? (dictionary["trackpadSimulationScope"] as? String)
        let applications = (dictionary["applications"] as? NSArray)
            ?? (dictionary["trackpadSimulationApps"] as? NSArray)
            ?? NSArray()
        guard let scope else { return nil }
        return snapshotFromLegacyScope(scope, applications: applications)
    }

    /// Make bundle-ID rules from a legacy array while removing duplicate
    /// entries in their original order.  This is useful when a migration must
    /// preserve an old include/exclude list before creating a snapshot.
    @objc(rulesFromLegacyApplications:effect:)
    public class func rulesFromLegacyApplications(_ applications: NSArray,
                                                  effect: ApplicationPolicyEffect) -> NSArray? {
        guard applications.count <= ApplicationPolicyLimits.maximumRuleCount else { return nil }

        var result = [ApplicationPolicyRule]()
        var seen = Set<String>()
        for object in applications {
            guard let application = object as? String,
                  let rule = ApplicationPolicyRule(bundleIdentifier: application, effect: effect) else {
                return nil
            }
            guard seen.insert(rule.canonicalKey).inserted else { continue }
            result.append(rule)
        }
        return result as NSArray
    }

    /// The reverse conversion is intentionally partial.  A snapshot that uses
    /// paths, wrappers, process names, or mixed effects has no lossless legacy
    /// representation and therefore returns nil.
    @objc public var legacyScope: String? {
        guard rules.allSatisfy({ $0.matchKind == .bundleIdentifier }) else { return nil }

        if defaultEffect == .allow && rules.isEmpty {
            return "all"
        }

        if defaultEffect == .deny && rules.allSatisfy({ $0.effect == .allow }) {
            return "include"
        }

        if defaultEffect == .allow && rules.allSatisfy({ $0.effect == .deny }) {
            return "exclude"
        }

        return nil
    }

    @objc public var legacyApplications: NSArray? {
        guard legacyScope != nil else { return nil }
        return rules.map(\.value) as NSArray
    }

    @objc public var legacyDictionary: NSDictionary? {
        guard let legacyScope, let legacyApplications else { return nil }
        return [
            "trackpadSimulationScope": legacyScope,
            "trackpadSimulationApps": legacyApplications
        ] as NSDictionary
    }

    /// Decode the canonical plist representation. Unknown keys are ignored,
    /// but every required value and every rule must validate; malformed input
    /// never falls back to an allow-all snapshot.
    @objc(snapshotFromDictionary:)
    public class func snapshotFromDictionary(_ dictionary: NSDictionary) -> ApplicationPolicySnapshot? {
        guard let defaultString = dictionary["defaultEffect"] as? String,
              let defaultEffect = effect(from: defaultString),
              let rawRules = dictionary["rules"] as? NSArray,
              rawRules.count <= ApplicationPolicyLimits.maximumRuleCount
        else { return nil }

        var rules: [ApplicationPolicyRule] = []
        rules.reserveCapacity(rawRules.count)
        for rawRule in rawRules {
            guard let ruleDictionary = rawRule as? NSDictionary,
                  let kindString = ruleDictionary["kind"] as? String,
                  let kind = matchKind(from: kindString),
                  let value = ruleDictionary["value"] as? String,
                  let effectString = ruleDictionary["effect"] as? String,
                  let effect = effect(from: effectString),
                  let rule = ApplicationPolicyRule(matchKind: kind, value: value, effect: effect)
            else { return nil }
            rules.append(rule)
        }
        return ApplicationPolicySnapshot(defaultEffect: defaultEffect, rules: rules)
    }

    /// Canonical property-list-safe representation used at the app/helper
    /// boundary. The returned dictionary contains immutable value objects.
    @objc public var dictionaryRepresentation: NSDictionary {
        let encodedRules = rules.map { rule -> NSDictionary in
            [
                "kind": Self.string(from: rule.matchKind),
                "value": rule.value,
                "effect": Self.string(from: rule.effect),
            ]
        }
        return [
            "defaultEffect": Self.string(from: defaultEffect),
            "rules": encodedRules,
        ]
    }

    private class func effect(from string: String) -> ApplicationPolicyEffect? {
        switch string {
        case "allow": return .allow
        case "deny": return .deny
        default: return nil
        }
    }

    private class func matchKind(from string: String) -> ApplicationPolicyMatchKind? {
        switch string {
        case "bundleIdentifier": return .bundleIdentifier
        case "executablePath": return .executablePath
        case "wrapperBundleIdentifier": return .wrapperBundleIdentifier
        case "wrapperPath": return .wrapperPath
        case "processName": return .processName
        default: return nil
        }
    }

    private class func string(from effect: ApplicationPolicyEffect) -> String {
        effect == .allow ? "allow" : "deny"
    }

    private class func string(from kind: ApplicationPolicyMatchKind) -> String {
        switch kind {
        case .bundleIdentifier: return "bundleIdentifier"
        case .executablePath: return "executablePath"
        case .wrapperBundleIdentifier: return "wrapperBundleIdentifier"
        case .wrapperPath: return "wrapperPath"
        case .processName: return "processName"
        }
    }

    private class func parseLegacyScope(_ raw: String) -> ApplicationPolicyLegacyScope? {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "all":
            return .all
        case "include":
            return .include
        case "exclude":
            return .exclude
        default:
            return nil
        }
    }
}

/// A small immutable façade for clients that want a policy object rather than
/// holding a snapshot directly.
@objc(MFApplicationPolicy)
public final class ApplicationPolicy: NSObject {

    @objc public let snapshot: ApplicationPolicySnapshot

    @objc(initWithSnapshot:)
    public init(snapshot: ApplicationPolicySnapshot) {
        self.snapshot = snapshot
        super.init()
    }

    @objc(initWithLegacyScope:applications:)
    public convenience init?(legacyScope: String, applications: NSArray) {
        guard let snapshot = ApplicationPolicySnapshot.snapshotFromLegacyScope(legacyScope, applications: applications) else {
            return nil
        }
        self.init(snapshot: snapshot)
    }

    @objc(decisionForIdentity:)
    public func decision(for identity: ApplicationIdentity) -> ApplicationPolicyEffect {
        snapshot.decision(for: identity)
    }

    @objc(isEnabledForIdentity:)
    public func isEnabled(for identity: ApplicationIdentity) -> Bool {
        snapshot.isEnabled(for: identity)
    }
}

/// Deterministic smoke tests that can be called from an Objective-C harness.
/// They use only in-memory values and never inspect the current process,
/// filesystem, clock, or user configuration.
@objc(MFApplicationPolicySelfTest)
public final class ApplicationPolicySelfTest: NSObject {

    @objc public class func run() -> Bool {
        guard let fullIdentity = ApplicationIdentity(
            bundleIdentifier: "com.example.strong",
            executablePath: "/Applications/Strong.app/Contents/MacOS/Strong",
            wrapperBundleIdentifier: "com.example.wrapper",
            wrapperPath: "/Applications/Wrapper.app",
            processName: "java",
            processNameFallbackAllowed: true
        ) else { return false }

        guard
            let bundleRule = ApplicationPolicyRule(bundleIdentifier: "com.example.strong", effect: .deny),
            let executableRule = ApplicationPolicyRule(executablePath: "/Applications/Strong.app/Contents/MacOS/Strong", effect: .allow),
            let wrapperBundleRule = ApplicationPolicyRule(wrapperBundleIdentifier: "com.example.wrapper", effect: .deny),
            let wrapperPathRule = ApplicationPolicyRule(wrapperPath: "/Applications/Wrapper.app", effect: .allow),
            let processRule = ApplicationPolicyRule(processName: "java", effect: .deny),
            let snapshot = ApplicationPolicySnapshot(defaultEffect: .allow,
                                                      rules: [processRule, wrapperPathRule, bundleRule, executableRule, wrapperBundleRule])
        else { return false }

        // Full identity: bundle ID wins over every weaker selector.
        guard fullIdentity.hasAnyStableIdentifier else { return false }
        guard snapshot.decision(for: fullIdentity) == .deny else { return false }

        guard let stableButDifferent = ApplicationIdentity(
            bundleIdentifier: "com.example.other",
            executablePath: "/Applications/Other.app/Contents/MacOS/Other",
            wrapperBundleIdentifier: nil,
            wrapperPath: nil,
            processName: "java",
            processNameFallbackAllowed: true
        ) else { return false }
        guard snapshot.decision(for: stableButDifferent) == .allow else { return false }

        guard let noBundle = ApplicationIdentity(
            bundleIdentifier: nil,
            executablePath: fullIdentity.executablePath,
            wrapperBundleIdentifier: fullIdentity.wrapperBundleIdentifier,
            wrapperPath: fullIdentity.wrapperPath,
            processName: fullIdentity.processName,
            processNameFallbackAllowed: true
        ) else { return false }
        guard snapshot.decision(for: noBundle) == .allow else { return false }

        guard let noExecutable = ApplicationIdentity(
            bundleIdentifier: nil,
            executablePath: nil,
            wrapperBundleIdentifier: fullIdentity.wrapperBundleIdentifier,
            wrapperPath: fullIdentity.wrapperPath,
            processName: fullIdentity.processName,
            processNameFallbackAllowed: true
        ) else { return false }
        guard snapshot.decision(for: noExecutable) == .deny else { return false }

        guard let processOnly = ApplicationIdentity(
            bundleIdentifier: nil,
            executablePath: nil,
            wrapperBundleIdentifier: nil,
            wrapperPath: nil,
            processName: "java",
            processNameFallbackAllowed: true
        ) else { return false }
        guard !processOnly.hasAnyStableIdentifier else { return false }
        guard snapshot.decision(for: processOnly) == .deny else { return false }

        guard let uncontrolledProcess = ApplicationIdentity(
            bundleIdentifier: nil,
            executablePath: nil,
            wrapperBundleIdentifier: nil,
            wrapperPath: nil,
            processName: "java",
            processNameFallbackAllowed: false
        ) else { return false }
        guard snapshot.decision(for: uncontrolledProcess) == .allow else { return false }

        // Paths are exact, not basename or suffix matches.
        guard let otherExecutable = ApplicationIdentity(
            bundleIdentifier: nil,
            executablePath: "/Other/Strong.app/Contents/MacOS/Strong",
            wrapperBundleIdentifier: nil,
            wrapperPath: nil,
            processName: nil,
            processNameFallbackAllowed: true
        ) else { return false }
        guard snapshot.decision(for: otherExecutable) == .allow else { return false }

        guard let include = ApplicationPolicySnapshot.fromLegacy(
            scope: "include",
            applications: ["com.example.allowed", "com.example.allowed"]
        ) else { return false }
        guard include.rules.count == 1, include.defaultEffect == .deny else { return false }

        guard let allowed = ApplicationIdentity(bundleIdentifier: "com.example.allowed", executablePath: nil, wrapperBundleIdentifier: nil, wrapperPath: nil, processName: nil) else { return false }
        guard let excluded = ApplicationIdentity(bundleIdentifier: "com.example.excluded", executablePath: nil, wrapperBundleIdentifier: nil, wrapperPath: nil, processName: nil) else { return false }
        guard include.isEnabled(for: allowed), !include.isEnabled(for: excluded) else { return false }

        guard let exclude = ApplicationPolicySnapshot.fromLegacy(scope: "exclude", applications: ["com.example.blocked"]) else { return false }
        guard let blocked = ApplicationIdentity(bundleIdentifier: "com.example.blocked", executablePath: nil, wrapperBundleIdentifier: nil, wrapperPath: nil, processName: nil) else { return false }
        guard exclude.isEnabled(for: excluded), !exclude.isEnabled(for: blocked) else { return false }
        guard exclude.legacyScope == "exclude" else { return false }
        guard let roundTrip = ApplicationPolicySnapshot.snapshotFromDictionary(exclude.dictionaryRepresentation),
              roundTrip.defaultEffect == exclude.defaultEffect,
              roundTrip.rules == exclude.rules
        else { return false }
        guard ApplicationPolicySnapshot.snapshotFromDictionary(["defaultEffect": "allow", "rules": [["kind": "unknown", "value": "x", "effect": "deny"]]]) == nil else { return false }

        guard ApplicationIdentity(bundleIdentifier: nil, executablePath: "relative/app", wrapperBundleIdentifier: nil, wrapperPath: nil, processName: nil) == nil else { return false }
        guard ApplicationPolicyRule(processName: "java*", effect: .deny) == nil else { return false }
        guard ApplicationPolicySnapshot(defaultEffect: .allow, rules: [bundleRule, bundleRule]) == nil else { return false }
        let oversizedRules = (0...ApplicationPolicyLimits.maximumRuleCount).compactMap {
            ApplicationPolicyRule(bundleIdentifier: "com.example.app\($0)", effect: .allow)
        }
        guard oversizedRules.count == ApplicationPolicyLimits.maximumRuleCount + 1 else { return false }
        guard ApplicationPolicySnapshot(defaultEffect: .deny, rules: oversizedRules) == nil else { return false }

        return true
    }

    @objc public class func runDeterministicSelfTests() -> Bool {
        run()
    }
}
