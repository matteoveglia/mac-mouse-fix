#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MFEventTapBackend <NSObject>
- (void * _Nullable)createTapAtLocation:(CGEventTapLocation)location placement:(CGEventTapPlacement)placement options:(CGEventTapOptions)options mask:(CGEventMask)mask callback:(CGEventTapCallBack)callback;
- (void * _Nullable)createSourceForTap:(void *)tap;
- (void)addSource:(void *)source toRunLoop:(CFRunLoopRef)runLoop mode:(CFRunLoopMode)mode;
- (void)removeSource:(void *)source fromRunLoop:(CFRunLoopRef)runLoop mode:(CFRunLoopMode)mode;
- (BOOL)isTapEnabled:(void *)tap;
- (void)setTap:(void *)tap enabled:(BOOL)enabled;
- (void)invalidateTap:(void *)tap;
- (void)releaseTap:(void *)tap;
- (void)releaseSource:(void *)source;
@end

/// Owns one event tap and its run-loop source. Every Core Graphics lifecycle
/// operation is serialized on the run loop that owns the source.
@interface MFEventTapHandle : NSObject

@property(nonatomic, readonly, getter=isValid) BOOL valid;
@property(nonatomic, readonly, getter=isEnabled) BOOL enabled;
@property(nonatomic, readonly) BOOL desiredEnabled;
@property(nonatomic, readonly, nullable) CFMachPortRef eventTap;

+ (instancetype _Nullable)handleWithLocation:(CGEventTapLocation)location
                                         mask:(CGEventMask)mask
                                      options:(CGEventTapOptions)options
                                    placement:(CGEventTapPlacement)placement
                                     callback:(CGEventTapCallBack)callback
                                      runLoop:(CFRunLoopRef)runLoop
                                          mode:(CFRunLoopMode)mode
                                         label:(NSString *)label;

/// Test seam. Production callers use the factory above.
- (instancetype _Nullable)initWithLocation:(CGEventTapLocation)location
                                       mask:(CGEventMask)mask
                                    options:(CGEventTapOptions)options
                                  placement:(CGEventTapPlacement)placement
                                   callback:(CGEventTapCallBack)callback
                                    runLoop:(CFRunLoopRef)runLoop
                                        mode:(CFRunLoopMode)mode
                                       label:(NSString *)label
                                     backend:(id<MFEventTapBackend>)backend
                                     timeout:(NSTimeInterval)timeout NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
- (BOOL)setEnabled:(BOOL)enabled reason:(NSString *)reason;
- (BOOL)invalidate;

@end

NS_ASSUME_NONNULL_END
