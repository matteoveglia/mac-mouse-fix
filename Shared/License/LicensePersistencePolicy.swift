import Foundation

enum MFLicenseKeyLookupState: Equatable {
    case found
    case missing
    case unavailable
}

enum MFLicenseKeyStartupResolution: Equatable {
    case validateStoredKey
    case clearCacheAndUseUnlicensed
    case useCachedState
    case useFallbackWithoutClearingCache
}

enum MFLicensePersistencePolicy {
    static func startupResolution(
        keyLookup: MFLicenseKeyLookupState,
        cachedStateIsAvailable: Bool
    ) -> MFLicenseKeyStartupResolution {
        switch keyLookup {
        case .found:
            return .validateStoredKey
        case .missing:
            return cachedStateIsAvailable ? .useCachedState : .clearCacheAndUseUnlicensed
        case .unavailable:
            return cachedStateIsAvailable ? .useCachedState : .useFallbackWithoutClearingCache
        }
    }
}
