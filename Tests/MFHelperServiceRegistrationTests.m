#import <Foundation/Foundation.h>
#import "MFHelperServiceRegistration.h"

static void MFRegistrationCheck(BOOL condition, NSString *message, int *failures) {
    if (condition) return;
    (*failures)++;
    fprintf(stderr, "helper registration failure: %s\n", message.UTF8String);
}

int main(void) {
    @autoreleasepool {
        int failures = 0;
        NSURL *installedApp = [NSURL fileURLWithPath:@"/Applications/Mac Mouse Fix.app"];
        NSURL *userInstalledApp = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Applications/Mac Mouse Fix.app"]];
        NSURL *temporaryApp = [NSURL fileURLWithPath:@"/private/var/folders/ab/cd/T/TemporaryItems/Mac Mouse Fix.app"];
        NSURL *derivedDataApp = [NSURL fileURLWithPath:@"/tmp/mmf-build/DerivedData/Build/Products/Debug/Mac Mouse Fix.app"];

        NSURL *expectedHelper = MFHelperServiceExpectedHelperBundleURL(installedApp);
        NSURL *expectedExecutable = MFHelperServiceExpectedHelperExecutableURL(installedApp);
        NSURL *expectedPlist = MFHelperServiceExpectedAgentPlistURL(installedApp);
        MFRegistrationCheck([expectedHelper.path hasSuffix:@"Contents/Library/LoginItems/Mac Mouse Fix Helper.app"], @"helper bundle path is derived from the current app", &failures);
        MFRegistrationCheck([expectedExecutable.path hasSuffix:@"Mac Mouse Fix Helper.app/Contents/MacOS/Mac Mouse Fix Helper"], @"helper executable path is derived from the current app", &failures);
        MFRegistrationCheck([expectedPlist.path hasSuffix:@"Contents/Library/LaunchAgents/sm_launchd.plist"], @"agent plist path is derived from the current app", &failures);
        MFRegistrationCheck(MFHelperServiceBundlePairMatchesExpectedLayout(installedApp, expectedHelper), @"installed app/helper pair matches", &failures);
        MFRegistrationCheck(!MFHelperServiceBundlePairMatchesExpectedLayout(installedApp, MFHelperServiceExpectedHelperBundleURL(userInstalledApp)), @"a moved copy does not reuse the old helper path", &failures);
        MFRegistrationCheck(MFHelperServiceBundlePathKindForURL(installedApp) == MFHelperServiceBundlePathKindApplications, @"system Applications path is classified as installed", &failures);
        MFRegistrationCheck(MFHelperServiceBundlePathKindForURL(userInstalledApp) == MFHelperServiceBundlePathKindApplications, @"user Applications path is classified as installed", &failures);
        MFRegistrationCheck(MFHelperServiceBundlePathKindForURL(temporaryApp) == MFHelperServiceBundlePathKindTemporary, @"TemporaryItems path is classified as disposable", &failures);
        MFRegistrationCheck(MFHelperServiceBundlePathKindForURL(derivedDataApp) == MFHelperServiceBundlePathKindTemporary, @"DerivedData path is classified as disposable", &failures);

        MFRegistrationCheck(MFHelperServicePreflightError(installedApp, expectedHelper) == nil, @"valid bundle pair passes preflight", &failures);
        NSError *temporaryError = MFHelperServicePreflightError(temporaryApp, MFHelperServiceExpectedHelperBundleURL(temporaryApp));
        MFRegistrationCheck(temporaryError.code == MFHelperServiceRegistrationErrorTemporaryBundle, @"disposable bundle is rejected before registration", &failures);
        NSError *movedError = MFHelperServicePreflightError(installedApp, MFHelperServiceExpectedHelperBundleURL(userInstalledApp));
        MFRegistrationCheck(movedError.code == MFHelperServiceRegistrationErrorInvalidBundleLayout, @"moved helper pair fails preflight with actionable code", &failures);

        MFRegistrationCheck(MFHelperServiceErrorForStatus(YES, MFHelperServiceRegistrationStatusEnabled) == nil, @"enabled status completes enable", &failures);
        NSError *approvalError = MFHelperServiceErrorForStatus(YES, MFHelperServiceRegistrationStatusRequiresApproval);
        MFRegistrationCheck(approvalError.code == MFHelperServiceRegistrationErrorRequiresApproval, @"approval status is surfaced", &failures);
        MFRegistrationCheck(MFHelperServiceErrorForStatus(YES, MFHelperServiceRegistrationStatusNotRegistered).code == MFHelperServiceRegistrationErrorUnexpectedStatus, @"not-registered enable status is not reported as success", &failures);
        MFRegistrationCheck(MFHelperServiceErrorForStatus(NO, MFHelperServiceRegistrationStatusNotRegistered) == nil, @"already-disabled status completes disable", &failures);
        MFRegistrationCheck(MFHelperServiceErrorForStatus(NO, MFHelperServiceRegistrationStatusNotFound) == nil, @"missing service completes disable", &failures);
        MFRegistrationCheck(MFHelperServiceErrorForStatus(NO, MFHelperServiceRegistrationStatusEnabled).code == MFHelperServiceRegistrationErrorUnexpectedStatus, @"enabled disable status is not reported as complete", &failures);

        if (failures == 0) {
            puts("MFHelperServiceRegistration tests passed");
        }
        return failures;
    }
}
