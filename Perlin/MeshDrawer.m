#import "MeshDrawer.h"
#import <GLKit/GLKit.h>
#import "ShaderProgram.h"

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
    GLKMatrix4 _modelViewProjectionMatrix;
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLint _uniforms[NUM_UNIFORMS];
    GLfloat _vertexData[kSectionsU * kSectionsV * 3 * 3];
}

@property (strong, nonatomic) ShaderProgram *shader;

- (void)initVertices;

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
    
    self.shader = [[ShaderProgram alloc] init];
    [self.shader loadShadersWithFilePath:@"Shader"];
    
    // Get uniform locations.
    GLuint prog = self.shader.program;
    _uniforms[UNIFORM_COLOR] = glGetUniformLocation(prog, "color");
    _uniforms[UNIFORM_FREQ] = glGetUniformLocation(prog, "freq");
    _uniforms[UNIFORM_AMP] = glGetUniformLocation(prog, "amp");
    _uniforms[UNIFORM_OFFS_U] = glGetUniformLocation(prog, "offs_u");
    _uniforms[UNIFORM_OFFS_V] = glGetUniformLocation(prog, "offs_v");
    _uniforms[UNIFORM_OFFS_W] = glGetUniformLocation(prog, "offs_w");
    _uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(prog, "modelViewProjectionMatrix");

    [self.shader releaseShaders];

    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(30.0f), aspect, 0.1f, 100.0f);
    GLKMatrix4 modelviewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -3.0f);
    modelviewMatrix = GLKMatrix4Multiply(modelviewMatrix, GLKMatrix4MakeRotation(0.5f * 3.141592f, 0, 0, 1));
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelviewMatrix);

    return self;
}

- (void)drawWithTime:(float)time
{
    glBindVertexArrayOES(_vertexArray);
    
    glUseProgram(self.shader.program);
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
    [self.shader tearDown];
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
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

@end
