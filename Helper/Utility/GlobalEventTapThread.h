//
// --------------------------------------------------------------------------
// EventTapQueue.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2022
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>
@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface GlobalEventTapThread : NSObject

+ (CFRunLoopRef)runLoop;
+ (BOOL)isInitialized;
+ (BOOL)performBlockAndWait:(dispatch_block_t)block timeout:(NSTimeInterval)timeout;

@end

NS_ASSUME_NONNULL_END
