#import <Foundation/Foundation.h>
#import "BaseDrawer.h"

@interface MeshDrawer : BaseDrawer

- (id)initWithAspect:(float)aspect;
- (void)tearDown;
- (void)drawWithTime:(float)time;

@end
