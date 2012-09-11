#import <Foundation/Foundation.h>

@interface BaseDrawer : NSObject

- (void)tearDown;
- (BOOL)loadShadersWithFilePath:(NSString*)filePath;
- (void)releaseShaders;

@property (readonly) GLuint program;

@end
