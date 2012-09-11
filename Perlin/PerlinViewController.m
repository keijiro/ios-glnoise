#import "PerlinViewController.h"
#import "MeshDrawer.h"

@interface PerlinViewController () {
    GLfloat _time;
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) MeshDrawer *meshDrawer;

@end

@implementation PerlinViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;

    self.preferredFramesPerSecond = 60.0f;

    [EAGLContext setCurrentContext:self.context];
    
    float aspect = fabsf(view.bounds.size.width / view.bounds.size.height);
    self.meshDrawer = [[MeshDrawer alloc] initWithAspect:aspect];
}

- (void)viewDidUnload
{    
    [super viewDidUnload];
    
    [EAGLContext setCurrentContext:self.context];

    [self.meshDrawer tearDown];
    self.meshDrawer = nil;

    [EAGLContext setCurrentContext:nil];
	self.context = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    _time += 1.0f / 60;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.89f, 0.92f, 0.86f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self.meshDrawer drawWithTime:_time];
}

@end
