#import "MeshDrawer.h"
#import <GLKit/GLKit.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

static const int kSectionsU = 64;
static const int kSectionsV = 96;
static const float kLengthU = 2.0f;
static const float kLengthV = 3.0f;

enum {
    UNIFORM_COLOR,
    UNIFORM_FREQ,
    UNIFORM_AMP,
    UNIFORM_OFFS_U,
    UNIFORM_OFFS_V,
    UNIFORM_OFFS_W,
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    NUM_UNIFORMS
};

@interface MeshDrawer ()
{
    GLuint _program;
    GLKMatrix4 _modelViewProjectionMatrix;
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLint _uniforms[NUM_UNIFORMS];
    GLfloat _vertexData[kSectionsU * kSectionsV * 3 * 3];
}

- (void)initVertices;
- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation MeshDrawer

- (id)initWithAspect:(float)aspect
{
    self = [super init];
    
    [self initVertices];

    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);

    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_vertexData), _vertexData, GL_STATIC_DRAW);

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glEnableVertexAttribArray(GLKVertexAttribColor);

    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 36, BUFFER_OFFSET(0));
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 36, BUFFER_OFFSET(12));
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, 36, BUFFER_OFFSET(24));

    glBindVertexArrayOES(0);

    [self loadShaders];

    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(30.0f), aspect, 0.1f, 100.0f);
    GLKMatrix4 modelviewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -3.0f);
    modelviewMatrix = GLKMatrix4Multiply(modelviewMatrix, GLKMatrix4MakeRotation(0.5f * 3.141592f, 0, 0, 1));
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelviewMatrix);

    return self;
}

- (void)drawWithTime:(float)time
{
    glBindVertexArrayOES(_vertexArray);
    
    glUseProgram(_program);
    glUniform4f(_uniforms[UNIFORM_COLOR], 0.187f, 0.187f, 0.238f, 0.4f);
    glUniform3f(_uniforms[UNIFORM_FREQ], 1, 1, 1);
    glUniform3f(_uniforms[UNIFORM_AMP], 1.0f, 1.0f, 1.0f);
    glUniform3f(_uniforms[UNIFORM_OFFS_U], 0.05f * time, 10.0f + 0.06f * time, 0.02f * time);
    glUniform3f(_uniforms[UNIFORM_OFFS_V], 0.05f * time, 20.0f + 0.06f * time, 0.02f * time);
    glUniform3f(_uniforms[UNIFORM_OFFS_W], 0.05f * time, 30.0f + 0.06f * time, 0.02f * time);
    
    glUniformMatrix4fv(_uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    
    glDrawArrays(GL_LINE_STRIP, 0, kSectionsU * kSectionsV);
}

- (void)tearDown
{
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

- (void)initVertices
{
    int index = 0;
    for (int v = 0; v < kSectionsV; v++) {
        for (int ui = 0; ui < kSectionsU; ui++) {
            int u = (v & 1) ? kSectionsU - 1 - ui : ui;
            // Vertex position
            _vertexData[index++] = (kLengthU / (kSectionsU - 1)) * u - 0.5f * kLengthU;
            _vertexData[index++] = 0;
            _vertexData[index++] = (kLengthV / (kSectionsV - 1)) * v - 0.5f * kLengthV;
            // Normal vector
            _vertexData[index++] = 0;
            _vertexData[index++] = 1;
            _vertexData[index++] = 0;
            // Tangent vector
            _vertexData[index++] = 1;
            _vertexData[index++] = 0;
            _vertexData[index++] = 0;
        }
    }
}

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    glBindAttribLocation(_program, GLKVertexAttribColor, "tangent");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    _uniforms[UNIFORM_COLOR] = glGetUniformLocation(_program, "color");
    _uniforms[UNIFORM_FREQ] = glGetUniformLocation(_program, "freq");
    _uniforms[UNIFORM_AMP] = glGetUniformLocation(_program, "amp");
    _uniforms[UNIFORM_OFFS_U] = glGetUniformLocation(_program, "offs_u");
    _uniforms[UNIFORM_OFFS_V] = glGetUniformLocation(_program, "offs_v");
    _uniforms[UNIFORM_OFFS_W] = glGetUniformLocation(_program, "offs_w");
    _uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
