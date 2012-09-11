#import "RenderTarget.h"
#import <GLKit/GLKit.h>

@interface RenderTarget ()
{
    GLuint _texture;
    GLuint _textureFBO;
    GLuint _previousFBO;
}

@end

@implementation RenderTarget

- (id)initWithWidth:(int)width height:(int)height
{
    self = [super init];

    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glGenFramebuffersOES(1, &_textureFBO);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _textureFBO);
    glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, _texture, 0);
    
    return self;
}

- (void)tearDown
{
    glDeleteTextures(1, &_texture);
    glDeleteBuffers(1, &_textureFBO);
}

- (void)activate
{
    glGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, (GLint *)&_previousFBO);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _textureFBO);
}

- (void)deactivate
{
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _previousFBO);
}

@end
