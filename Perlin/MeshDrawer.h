#import <Foundation/Foundation.h>

@interface MeshDrawer : NSObject

- (id)initWithAspect:(float)aspect;
- (void)tearDown;
- (void)drawWithTime:(float)time;

@end
