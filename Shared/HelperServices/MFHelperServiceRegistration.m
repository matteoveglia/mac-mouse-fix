//
// --------------------------------------------------------------------------
// MFHelperServiceRegistration.m
// Pure registration/path rules shared by HelperServices and deterministic tests.
// --------------------------------------------------------------------------
//

#import "MFHelperServiceRegistration.h"

NSString * const MFHelperServiceRegistrationErrorDomain = @"MFHelperServiceRegistrationErrorDomain";
NSString * const MFHelperServiceRegistrationBundleURLKey = @"MFHelperServiceRegistrationBundleURL";
NSString * const MFHelperServiceRegistrationExpectedHelperURLKey = @"MFHelperServiceRegistrationExpectedHelperURL";
NSString * const MFHelperServiceRegistrationObservedHelperURLKey = @"MFHelperServiceRegistrationObservedHelperURL";
NSString * const MFHelperServiceRegistrationStatusKey = @"MFHelperServiceRegistrationStatus";
NSString * const MFHelperServiceRegistrationPathKindKey = @"MFHelperServiceRegistrationPathKind";

static NSString *MFStandardizedPath(NSURL *bundleURL) {
    if (![bundleURL isFileURL]) return nil;
    NSString *path = bundleURL.path;
    if (path.length == 0) return nil;
    return [path stringByStandardizingPath];
}

static NSError *MFRegistrationError(MFHelperServiceRegistrationErrorCode code,
                                    NSString *description,
                                    NSDictionary *userInfo) {
    NSMutableDictionary *mutableInfo = [userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
    mutableInfo[NSLocalizedDescriptionKey] = description;
    return [NSError errorWithDomain:MFHelperServiceRegistrationErrorDomain
                               code:code
                           userInfo:mutableInfo];
}

MFHelperServiceBundlePathKind MFHelperServiceBundlePathKindForURL(NSURL *bundleURL) {
    NSString *path = MFStandardizedPath(bundleURL);
    if (path.length == 0) return MFHelperServiceBundlePathKindUnknown;

    if ([path hasPrefix:@"/tmp/"] ||
        [path isEqualToString:@"/tmp"] ||
        [path hasPrefix:@"/private/tmp/"] ||
        [path isEqualToString:@"/private/tmp"] ||
        [path hasPrefix:@"/var/folders/"] ||
        [path containsString:@"/DerivedData/"] ||
        [path containsString:@"/TemporaryItems/"]) {
        return MFHelperServiceBundlePathKindTemporary;
    }

    NSArray<NSString *> *components = [path pathComponents];
    if ([components containsObject:@"Applications"]) {
        return MFHelperServiceBundlePathKindApplications;
    }

    return MFHelperServiceBundlePathKindOther;
}

NSURL *MFHelperServiceExpectedHelperBundleURL(NSURL *mainAppBundleURL) {
    NSString *path = MFStandardizedPath(mainAppBundleURL);
    if (path.length == 0) return nil;
    return [NSURL fileURLWithPath:[path stringByAppendingPathComponent:@"Contents/Library/LoginItems/Mac Mouse Fix Helper.app"]
                       isDirectory:YES];
}

NSURL *MFHelperServiceExpectedHelperExecutableURL(NSURL *mainAppBundleURL) {
    NSURL *helperBundleURL = MFHelperServiceExpectedHelperBundleURL(mainAppBundleURL);
    if (helperBundleURL == nil) return nil;
    return [helperBundleURL URLByAppendingPathComponent:@"Contents/MacOS/Mac Mouse Fix Helper"
                                            isDirectory:NO];
}

NSURL *MFHelperServiceExpectedAgentPlistURL(NSURL *mainAppBundleURL) {
    NSString *path = MFStandardizedPath(mainAppBundleURL);
    if (path.length == 0) return nil;
    return [NSURL fileURLWithPath:[path stringByAppendingPathComponent:@"Contents/Library/LaunchAgents/sm_launchd.plist"]
                       isDirectory:NO];
}

BOOL MFHelperServiceBundlePairMatchesExpectedLayout(NSURL *mainAppBundleURL, NSURL *helperBundleURL) {
    NSURL *expectedHelperURL = MFHelperServiceExpectedHelperBundleURL(mainAppBundleURL);
    NSString *observedPath = MFStandardizedPath(helperBundleURL);
    NSString *expectedPath = MFStandardizedPath(expectedHelperURL);
    return expectedPath.length > 0 && [expectedPath isEqualToString:observedPath];
}

NSError *MFHelperServicePreflightError(NSURL *mainAppBundleURL, NSURL *helperBundleURL) {
    NSURL *expectedHelperURL = MFHelperServiceExpectedHelperBundleURL(mainAppBundleURL);
    MFHelperServiceBundlePathKind pathKind = MFHelperServiceBundlePathKindForURL(mainAppBundleURL);
    NSDictionary *userInfo = @{
        MFHelperServiceRegistrationBundleURLKey: mainAppBundleURL ?: [NSNull null],
        MFHelperServiceRegistrationExpectedHelperURLKey: expectedHelperURL ?: [NSNull null],
        MFHelperServiceRegistrationObservedHelperURLKey: helperBundleURL ?: [NSNull null],
        MFHelperServiceRegistrationPathKindKey: @(pathKind),
    };

    if (pathKind == MFHelperServiceBundlePathKindTemporary &&
        MFHelperServiceBundlePairMatchesExpectedLayout(mainAppBundleURL, helperBundleURL)) {
        return MFRegistrationError(MFHelperServiceRegistrationErrorTemporaryBundle,
                                   @"The app is running from a disposable build location; install the signed app before registering its Login Item.",
                                   userInfo);
    }

    if (MFHelperServiceBundlePairMatchesExpectedLayout(mainAppBundleURL, helperBundleURL)) {
        return nil;
    }

    return MFRegistrationError(MFHelperServiceRegistrationErrorInvalidBundleLayout,
                               @"The app and embedded helper do not resolve to the same bundle.",
                               userInfo);
}

NSError *MFHelperServiceErrorForStatus(BOOL enabling, MFHelperServiceRegistrationStatus status) {
    if (enabling && status == MFHelperServiceRegistrationStatusEnabled) return nil;
    if (!enabling && (status == MFHelperServiceRegistrationStatusNotRegistered ||
                      status == MFHelperServiceRegistrationStatusNotFound)) return nil;

    if (enabling && status == MFHelperServiceRegistrationStatusRequiresApproval) {
        return MFRegistrationError(MFHelperServiceRegistrationErrorRequiresApproval,
                                   @"The helper is registered but still requires approval in System Settings.",
                                   @{MFHelperServiceRegistrationStatusKey: @(status)});
    }

    NSString *operation = enabling ? @"enable" : @"disable";
    return MFRegistrationError(MFHelperServiceRegistrationErrorUnexpectedStatus,
                               [NSString stringWithFormat:@"The helper could not %@ because Service Management reported status %ld.", operation, (long)status],
                               @{MFHelperServiceRegistrationStatusKey: @(status)});
}
