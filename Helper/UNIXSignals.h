//
// --------------------------------------------------------------------------
// UNIXSignals.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2024
// Licensed under Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UNIXSignals : NSObject

+ (void)load_Manual;

/// Runs event-tap cleanup on each tap's owning run loop before process termination.
+ (void)prepareForTerminationWithTimeout:(NSTimeInterval)timeout;

@end

NS_ASSUME_NONNULL_END
