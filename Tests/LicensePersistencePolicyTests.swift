import Foundation

@main
struct LicensePersistencePolicyTests {
    static func main() {
        var failures = 0
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            if !condition() {
                NSLog("FAIL: %@", message)
                failures += 1
            }
        }

        check(MFLicensePersistencePolicy.startupResolution(
            keyLookup: .found, cachedStateIsAvailable: true) == .validateStoredKey,
              "a readable key is validated normally")
        check(MFLicensePersistencePolicy.startupResolution(
            keyLookup: .missing, cachedStateIsAvailable: true) == .useCachedState,
              "an item-not-found response does not erase an existing paid cache")
        check(MFLicensePersistencePolicy.startupResolution(
            keyLookup: .missing, cachedStateIsAvailable: false) == .clearCacheAndUseUnlicensed,
              "a missing key without cached state remains unlicensed")
        check(MFLicensePersistencePolicy.startupResolution(
            keyLookup: .unavailable, cachedStateIsAvailable: true) == .useCachedState,
              "a transient Keychain failure preserves the last cached state")
        check(MFLicensePersistencePolicy.startupResolution(
            keyLookup: .unavailable, cachedStateIsAvailable: false) == .useFallbackWithoutClearingCache,
              "a transient Keychain failure without cache remains non-destructive")

        if failures == 0 { NSLog("LicensePersistencePolicyTests passed") }
        exit(failures == 0 ? EXIT_SUCCESS : EXIT_FAILURE)
    }
}
