//
// Deterministic policy checks.  The existing Tests target is a scratch app,
// so this file also exposes a small Objective-C-callable entry point and can
// be compiled directly with ApplicationPolicy.swift.
//

import Foundation

@objc(MFApplicationPolicyTests)
public final class ApplicationPolicyTests: NSObject {

    @objc public class func run() -> Bool {
        guard ApplicationPolicySelfTest.runDeterministicSelfTests() else { return false }

        guard let identity = ApplicationIdentity(
            bundleIdentifier: "com.example.editor",
            executablePath: "/Applications/Editor.app/Contents/MacOS/Editor",
            wrapperBundleIdentifier: "com.example.runtime",
            wrapperPath: "/Applications/Runtime.app",
            processName: "java",
            processNameFallbackAllowed: true
        ),
        let bundleRule = ApplicationPolicyRule(bundleIdentifier: "com.example.editor", effect: .deny),
        let executableRule = ApplicationPolicyRule(executablePath: "/Applications/Editor.app/Contents/MacOS/Editor", effect: .allow),
        let snapshot = ApplicationPolicySnapshot(defaultEffect: .allow, rules: [executableRule, bundleRule]) else {
            return false
        }

        // The stronger bundle selector must win over an exact executable
        // selector, and a different executable path must not match by name.
        guard snapshot.decision(for: identity) == .deny else { return false }
        guard let other = ApplicationIdentity(bundleIdentifier: nil,
                                               executablePath: "/Other/Editor.app/Contents/MacOS/Editor",
                                               wrapperBundleIdentifier: nil,
                                               wrapperPath: nil,
                                               processName: nil),
              snapshot.decision(for: other) == .allow else {
            return false
        }

        // Advanced mode keeps only its exact selectors and defaults unmatched
        // applications to allow; legacy bundle-ID rules are not part of this
        // mode's snapshot.
        guard let advancedWrapperRule = ApplicationPolicyRule(wrapperBundleIdentifier: "com.example.runtime", effect: .deny),
              let advancedProcessRule = ApplicationPolicyRule(processName: "java", effect: .deny),
              let advancedOnly = ApplicationPolicySnapshot(defaultEffect: .allow,
                                                            rules: [advancedWrapperRule, advancedProcessRule]),
              advancedOnly.rules.allSatisfy({ $0.matchKind != .bundleIdentifier }),
              advancedOnly.decision(for: identity) == .deny,
              advancedOnly.decision(for: other) == .allow else {
            return false
        }

        // Projecting a mixed canonical policy into Advanced must discard the
        // legacy bundle rule and its deny-by-default behavior.
        guard let mixedPolicy = ApplicationPolicySnapshot(defaultEffect: .deny,
                                                           rules: [bundleRule, advancedWrapperRule]),
              let projectedAdvanced = mixedPolicy.advancedScopeSnapshot(),
              projectedAdvanced.defaultEffect == .allow,
              projectedAdvanced.rules.allSatisfy({ $0.matchKind != .bundleIdentifier }),
              projectedAdvanced.decision(for: identity) == .deny,
              projectedAdvanced.decision(for: other) == .allow else {
            return false
        }

        // Finder is a useful concrete example for the UI: an executable rule
        // needs the absolute binary path, while a bare process name is only a
        // syntactically valid fallback selector.
        guard ApplicationPolicyRule(executablePath: "/System/Library/CoreServices/Finder.app/Contents/MacOS/Finder", effect: .deny) != nil,
              ApplicationPolicyRule(executablePath: "Finder.app", effect: .deny) == nil,
              ApplicationPolicyRule(processName: "Finder", effect: .deny) != nil else {
            return false
        }

        return true
    }

    @objc public class func runDeterministicSelfTests() -> Bool {
        run()
    }
}

#if APPLICATION_POLICY_SELF_TEST_MAIN
import Darwin

@main
private enum ApplicationPolicyTestMain {
    static func main() {
        exit(ApplicationPolicyTests.runDeterministicSelfTests() ? EXIT_SUCCESS : EXIT_FAILURE)
    }
}
#endif
