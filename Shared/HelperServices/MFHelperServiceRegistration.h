//
// --------------------------------------------------------------------------
// MFHelperServiceRegistration.h
// Pure registration/path rules shared by HelperServices and deterministic tests.
// --------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MFHelperServiceBundlePathKind) {
    MFHelperServiceBundlePathKindUnknown = 0,
    MFHelperServiceBundlePathKindApplications = 1,
    MFHelperServiceBundlePathKindTemporary = 2,
    MFHelperServiceBundlePathKindOther = 3,
};

/// These values intentionally mirror SMAppServiceStatus without importing
/// ServiceManagement. This keeps the reducer and path tests platform-light.
typedef NS_ENUM(NSInteger, MFHelperServiceRegistrationStatus) {
    MFHelperServiceRegistrationStatusNotRegistered = 0,
    MFHelperServiceRegistrationStatusEnabled = 1,
    MFHelperServiceRegistrationStatusRequiresApproval = 2,
    MFHelperServiceRegistrationStatusNotFound = 3,
};

typedef NS_ENUM(NSInteger, MFHelperServiceRegistrationErrorCode) {
    MFHelperServiceRegistrationErrorInvalidBundleLayout = 1,
    MFHelperServiceRegistrationErrorRequiresApproval = 2,
    MFHelperServiceRegistrationErrorUnexpectedStatus = 3,
    MFHelperServiceRegistrationErrorTemporaryBundle = 4,
};

FOUNDATION_EXPORT NSString * const MFHelperServiceRegistrationErrorDomain;
FOUNDATION_EXPORT NSString * const MFHelperServiceRegistrationBundleURLKey;
FOUNDATION_EXPORT NSString * const MFHelperServiceRegistrationExpectedHelperURLKey;
FOUNDATION_EXPORT NSString * const MFHelperServiceRegistrationObservedHelperURLKey;
FOUNDATION_EXPORT NSString * const MFHelperServiceRegistrationStatusKey;
FOUNDATION_EXPORT NSString * const MFHelperServiceRegistrationPathKindKey;

FOUNDATION_EXPORT MFHelperServiceBundlePathKind MFHelperServiceBundlePathKindForURL(NSURL *_Nullable bundleURL);
FOUNDATION_EXPORT NSURL *_Nullable MFHelperServiceExpectedHelperBundleURL(NSURL *_Nullable mainAppBundleURL);
FOUNDATION_EXPORT NSURL *_Nullable MFHelperServiceExpectedHelperExecutableURL(NSURL *_Nullable mainAppBundleURL);
FOUNDATION_EXPORT NSURL *_Nullable MFHelperServiceExpectedAgentPlistURL(NSURL *_Nullable mainAppBundleURL);
FOUNDATION_EXPORT BOOL MFHelperServiceBundlePairMatchesExpectedLayout(NSURL *_Nullable mainAppBundleURL,
                                                                       NSURL *_Nullable helperBundleURL);
FOUNDATION_EXPORT NSError *_Nullable MFHelperServicePreflightError(NSURL *_Nullable mainAppBundleURL,
                                                                    NSURL *_Nullable helperBundleURL);
FOUNDATION_EXPORT NSError *_Nullable MFHelperServiceErrorForStatus(BOOL enabling,
                                                                    MFHelperServiceRegistrationStatus status);

NS_ASSUME_NONNULL_END
