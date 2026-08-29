#import <Foundation/Foundation.h>
#import "ModifiedDrag.h"

NS_ASSUME_NONNULL_BEGIN

@interface ModifiedDragOutputAction : NSObject<ModifiedDragOutputPlugin>
+ (BOOL)canHandleEffectDict:(NSDictionary *)effectDict;
@end

NS_ASSUME_NONNULL_END
