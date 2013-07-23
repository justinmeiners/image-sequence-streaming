/*
 By: Justin Meiners
 
 Copyright (c) 2013 Inline Studios
 Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
 */

#import "ISSequenceView.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>
#import "TargetConditionals.h"

#pragma mark -
#pragma mark ISSequenceView
#pragma mark -


// retain cycle fix is to use the object proxy

@interface _ISSequenceDisplayLink : NSObject
{
    CADisplayLink* _displayLink;
    id _target;
    SEL _action;
}
@property(nonatomic, readonly)CADisplayLink* displayLink;
@property(nonatomic, assign)id target;
@property(nonatomic, assign)SEL action;

- (id)initWithTarget:(id)target
              action:(SEL)action
     refreshInterval:(int)refreshInterval;

- (void)shutdown;

@end

@implementation _ISSequenceDisplayLink
@synthesize displayLink = _displayLink;
@synthesize target = _target;
@synthesize action = _action;

- (id)initWithTarget:(id)target
              action:(SEL)action
     refreshInterval:(int)refreshInterval
{
    if (self = [super init])
    {
        _target = target;
        _action = action;
        
        _displayLink = [[CADisplayLink displayLinkWithTarget:self selector:@selector(refreshDisplay:)] retain];
        _displayLink.frameInterval = refreshInterval;
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
    return self;
}

- (void)refreshDisplay:(CADisplayLink*)link
{
    if (_target && _action)
    {
        [_target performSelector:_action];
    }
}

- (void)shutdown
{
    [_displayLink invalidate];
    [_displayLink release];
}

@end



@interface ISSequenceView ()
{
    EAGLContext* _context;
    CVOpenGLESTextureCacheRef _textureCache;
    GLuint _framebuffer;
    GLuint _colorbuffer;
    int _currentBuffer;
    int _bufferCount;
    GLuint _vbo;
    CVPixelBufferRef* _pixelBuffers;
    CVOpenGLESTextureRef* _cacheTextures;
    GLuint* _simulatorTextures;

    _ISSequenceDisplayLink* _displayLink;
    
    GLuint _shaderProgram;
    GLuint _imageUniform;
}

@property(nonatomic, retain)ISSequence* sequence;

- (void)setupFramebuffers;
- (void)shutdownFramebuffers;

- (void)setupPixelbuffers;
- (void)shutdownPixelbuffers;

- (void)setupTextureBuffers;
- (void)shutdownTextureBuffers;

- (void)setupOpenGL;
- (void)shutdownOpenGL;


- (void)update;
- (void)redraw;

@end

static const char* const _kISSequenceViewVSH =
"attribute mediump vec4 a_vertex; \
attribute mediump vec2 a_uv; \
varying mediump vec2 v_uv; \
void main() \
{ \
v_uv = a_uv; \
gl_Position = a_vertex; \
}";


/* note the B - R swap in this shader */
static const char* const _kISSequenceViewFSH =
"uniform lowp sampler2D u_image; \
varying mediump vec2 v_uv; \
void main() \
{ \
lowp vec4 color = texture2D(u_image, v_uv); \
gl_FragColor = vec4(color.b, color.g, color.r, color.a); \
}";



static const char* const _kISSequenceViewVertexAttribName = "a_vertex";
static const char* const _kISSequenceViewUVAttribName = "a_uv";
static const char* const _kISSequenceViewImageUniformName = "u_image";

/* vertices for OpenGL (fullscreen quad) */
static const GLfloat _kISSequenceViewVertices[] =
{
    -1.0,  -1.0,
    1.0, -1.0,
    -1.0,  1.0,
    1.0, 1.0,
};

/* UV coordinates for OpenGL (full image) */
static const GLfloat _kISSequenceViewUVs[] =
{
    0.0,  1.0,
    1.0, 1.0,
    0.0,  0.0,
    1.0, 0.0,
};


@implementation ISSequenceView
@synthesize sequence = _sequence;

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithSequence:(ISSequence*)sequence
       refreshInterval:(int)interval
       useTextureCache:(bool)textureCache
{
    assert(sequence);
    self = [super initWithFrame:CGRectMake(0, 0, [sequence width], [sequence height])];
    if (self)
    {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.layer.opaque = NO;
        
        // Setup OpenGL ES context
        CAEAGLLayer* eaglLayer = (CAEAGLLayer *)self.layer;
		
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                        nil];
		
        // OpenGL ES 2.0 FTW
		_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		
		if (!_context || ![EAGLContext setCurrentContext:_context])
		{
			NSLog(@"error creating OpenGL ES 2.0 context");
			[self release];
            return NULL;
		}
        
        /* 
         Buffer count is the amount of buffers used to cycle through updates.
         2 seems to work nicely, you shouldn't need to change this - but if you see weird pixelly artifacts
         you may want to increase this number to 3 or 4. Increasing buffer count will increase RAM usage.
         */
        _bufferCount = 2;
        
        _currentBuffer = 0;
        _framebuffer = 0;
        _colorbuffer = 0;
        _currentFrame = 0;
        _refreshInterval = interval;
        _sequence = NULL;
        _textureCache = NULL;
        
        /* simulator doesn't play nice with texture cache - force false */
        if (TARGET_IPHONE_SIMULATOR)
        {
            _useTextureCache = NO;
        }
        else
        {
            _useTextureCache = textureCache;
        }
        
        [self setupFramebuffers];
        [self setupOpenGL];
        
        self.sequence = sequence;
        
        [self setupPixelbuffers];
        [self setupTextureBuffers];
        
        _displayLink = [[_ISSequenceDisplayLink alloc] initWithTarget:self action:@selector(refreshDisplay) refreshInterval:_refreshInterval];
        
        [self redraw];
    }
    return self;
}

- (void)dealloc
{
    [EAGLContext setCurrentContext:_context];

    [_displayLink shutdown];
    [_displayLink release];
    
    self.sequence = nil;
    
    [self shutdownTextureBuffers];
    [self shutdownPixelbuffers];
    [self shutdownOpenGL];
    [self shutdownFramebuffers];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Public
#pragma mark -

- (void)jumpToFrame:(int)frame
{
    if (frame < 0)
    {
        frame = 0;
    }
    
    if (frame >= [_sequence frameCount])
    {
        frame = [_sequence frameCount] - 1;
    }
    
    _currentFrame = frame;
}


#pragma mark -
#pragma mark Setters And Getters
#pragma mark -

- (ISSequence*)sequence
{
    return _sequence;
}

- (int)currentFrame
{
    return _currentFrame;
}

- (int)refreshInterval
{
    return _refreshInterval;
}

#pragma mark -
#pragma mark Private
#pragma mark -

- (void)refreshDisplay
{
    [self update];
    [self redraw];
}

#pragma mark -
#pragma mark Pixel Buffer/OpenGL
#pragma mark -

- (void)setupFramebuffers
{
    glGenFramebuffers(1, &_framebuffer);
    glGenRenderbuffers(1, &_colorbuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorbuffer);
    
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorbuffer);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        
        NSException* exception = [NSException exceptionWithName:@"failed to allocate framebuffer"
                                                         reason:[NSString stringWithFormat:@"%x", glCheckFramebufferStatus(GL_FRAMEBUFFER)]
                                                       userInfo:nil];
        [exception raise];
    }
}

- (void)shutdownFramebuffers
{
    glDeleteRenderbuffers(1, &_colorbuffer);
    glDeleteFramebuffers(1, &_framebuffer);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (![EAGLContext setCurrentContext:_context])
    {
        NSException* exception = [NSException exceptionWithName:@"failed to set context"
                                                         reason:@"unknown"
                                                       userInfo:nil];
        [exception raise];
    }
    
    [self shutdownFramebuffers];
    [self setupFramebuffers];
}

- (void)setupPixelbuffers
{
    _pixelBuffers = calloc(sizeof(CVPixelBufferRef), _bufferCount);
    assert(_pixelBuffers);
    
    CFDictionaryRef empty;
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault,
                               NULL,
                               NULL,
                               0,
                               &kCFTypeDictionaryKeyCallBacks,
                               &kCFTypeDictionaryValueCallBacks);
    
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                      1,
                                      &kCFTypeDictionaryKeyCallBacks,
                                      &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs,
                         kCVPixelBufferIOSurfacePropertiesKey,
                         empty);
    
    for (int i = 0; i < _bufferCount; i ++)
    {
        // Create backed pixel buffer
        CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                              [_sequence width],
                                              [_sequence height],
                                              kCVPixelFormatType_32BGRA,
                                              attrs,
                                              &_pixelBuffers[i]);
        
        if (status != kCVReturnSuccess)
        {
            NSException* exception = [NSException exceptionWithName:@"failed to create CVPixelBuffer"
                                                             reason:[NSString stringWithFormat:@"%d", status]
                                                           userInfo:nil];
            [exception raise];
        }
        
    }
}

- (void)shutdownPixelbuffers
{
    free(_pixelBuffers);
    _pixelBuffers = NULL;
}

- (void)setupOpenGL
{
    [EAGLContext setCurrentContext:_context];
    
    GLuint vertShader, fragShader;
    
    _shaderProgram = glCreateProgram();
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER source:_kISSequenceViewVSH])
    {
        NSLog(@"Failed to compile vertex shader");
        return;
    }
    
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER source:_kISSequenceViewFSH])
    {
        NSLog(@"Failed to compile fragment shader");
        return;
    }
    
    glAttachShader(_shaderProgram, vertShader);
    glAttachShader(_shaderProgram, fragShader);
    
    glBindAttribLocation(_shaderProgram, 0, _kISSequenceViewVertexAttribName);
    glBindAttribLocation(_shaderProgram, 1, _kISSequenceViewUVAttribName);
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);

    GLint status;
    glLinkProgram(_shaderProgram);
    
    glGetProgramiv(_shaderProgram, GL_LINK_STATUS, &status);
    if (status == 0)
    {
        GLint logLength;
        glGetProgramiv(_shaderProgram, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetProgramInfoLog(_shaderProgram, logLength, &logLength, log);
            NSLog(@"Program link log:\n%s", log);
            free(log);
        }
        
        NSLog(@"Failed to link program: %d", _shaderProgram);
        
        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        
        if (_shaderProgram)
        {
            glDeleteProgram(_shaderProgram);
            _shaderProgram = 0;
        }
        return;
    }
    
    glGenBuffers(1, &_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_kISSequenceViewVertices) + sizeof(_kISSequenceViewUVs), NULL, GL_STATIC_DRAW);
    
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(_kISSequenceViewVertices), _kISSequenceViewVertices);
    glBufferSubData(GL_ARRAY_BUFFER, sizeof(_kISSequenceViewVertices), sizeof(_kISSequenceViewUVs), _kISSequenceViewUVs);

    
    _imageUniform = glGetUniformLocation(_shaderProgram, _kISSequenceViewImageUniformName);
    
    if (vertShader)
    {
        glDetachShader(_shaderProgram, vertShader);
        glDeleteShader(vertShader);
    }
    
    if (fragShader)
    {
        glDetachShader(_shaderProgram, fragShader);
        glDeleteShader(fragShader);
    }
    
    if (_useTextureCache)
    {        
        CVReturn status = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault,
                                                       NULL,
                                                       (CVEAGLContext)_context,
                                                       NULL,
                                                       &_textureCache);
                        
        if (status != kCVReturnSuccess)
        {
            NSException* exception = [NSException exceptionWithName:@"failed to create CVOpenGLESTextureCacheCreate"
                                                             reason:[NSString stringWithFormat:@"%d", status]
                                                           userInfo:nil];
            [exception raise];
        }
    }
        
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glUseProgram(_shaderProgram);
    glUniform1i(_imageUniform, 0);
}

- (void)shutdownOpenGL
{
    [EAGLContext setCurrentContext:_context];
    
    glDeleteBuffers(1, &_vbo);
}

- (void)setupTextureBuffers
{
    if (!_useTextureCache)
    {
        _simulatorTextures = calloc(sizeof(GLuint), _bufferCount);
        assert(_simulatorTextures);
    }
    else
    {
        _cacheTextures = calloc(sizeof(CVOpenGLESTextureRef), _bufferCount);
        assert(_cacheTextures);
    }
    
    for (int i = 0; i < _bufferCount; i ++)
    {
        if (!_useTextureCache)
        {
            glGenTextures(1, &_simulatorTextures[i]);            
            glBindTexture(GL_TEXTURE_2D, _simulatorTextures[i]);
                        
            glTexImage2D(GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         [_sequence width],
                         [_sequence height],
                         0,
                         GL_BGRA,
                         GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(_pixelBuffers[i]));
        }
        else
        {
            CVReturn status = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                           _textureCache,
                                                                           _pixelBuffers[i],
                                                                           NULL,
                                                                           GL_TEXTURE_2D,
                                                                           GL_RGBA,
                                                                           [_sequence width],
                                                                           [_sequence height],
                                                                           GL_BGRA,
                                                                           GL_UNSIGNED_BYTE,
                                                                           0,
                                                                           &_cacheTextures[i]);
            
            if (status != kCVReturnSuccess)
            {
                NSException* exception = [NSException exceptionWithName:@"failed to create CVOpenGLESTexture"
                                                                 reason:[NSString stringWithFormat:@"%d", status]
                                                               userInfo:nil];
                [exception raise];
            }
                        
            glBindTexture(CVOpenGLESTextureGetTarget(_cacheTextures[i]), CVOpenGLESTextureGetName(_cacheTextures[i]));
        }
        
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }
}

- (void)shutdownTextureBuffers
{
    if (!_useTextureCache)
    {
        glDeleteTextures(_bufferCount, _simulatorTextures);
        free(_simulatorTextures);
    }
    else
    {
        for (int i = 0; i < _bufferCount; i ++)
        {
        }
        
        free(_cacheTextures);

    }
    
}

- (void)update
{
}

- (void)redraw
{    
    [EAGLContext setCurrentContext:_context];
    
    CVPixelBufferLockBaseAddress(_pixelBuffers[_currentBuffer], kCVPixelBufferLock_ReadOnly);
    [_sequence getBytes:CVPixelBufferGetBaseAddress(_pixelBuffers[_currentBuffer]) atFrame:_currentFrame];
    
    if (!_useTextureCache)
    {
        glBindTexture(GL_TEXTURE_2D, _simulatorTextures[_currentBuffer]);
                        
        glTexSubImage2D(GL_TEXTURE_2D,
                        0,
                        0,
                        0,
                        [_sequence width],
                        [_sequence height],
                        GL_BGRA, GL_UNSIGNED_BYTE,
                        CVPixelBufferGetBaseAddress(_pixelBuffers[_currentBuffer]));
    }
    
    CVPixelBufferUnlockBaseAddress(_pixelBuffers[_currentBuffer], kCVPixelBufferLock_ReadOnly);
    
    _currentBuffer ++;
    
    if (_currentBuffer >= _bufferCount)
    {
        _currentBuffer = 0;
    }
    
    glViewport(0, 0, self.bounds.size.width, self.bounds.size.height);
        
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (_useTextureCache)
    {
        CVOpenGLESTextureCacheFlush(_textureCache, 0);
        glBindTexture(CVOpenGLESTextureGetTarget(_cacheTextures[_currentBuffer]), CVOpenGLESTextureGetName(_cacheTextures[_currentBuffer]));
    }
    
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 0, (char*)(NULL) + sizeof(_kISSequenceViewVertices));
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
}


- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type source:(const char *)string
{
    const GLchar* source = (GLchar*)string;
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    GLint status;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        GLint logLength;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(*shader, logLength, &logLength, log);
            NSLog(@"Shader compile log:\n%s", log);
            free(log);
        }
        
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

@end

#pragma mark -
#pragma mark ISSequencePlaybackView
#pragma mark -

@interface ISSequencePlaybackView ()
{
    int _animationTimer;
}

@end

@implementation ISSequencePlaybackView
@synthesize delegate = _delegate;
@synthesize loops = _loops;
@synthesize range = _range;
@synthesize playbackDirection = _playbackDirection;
@synthesize animationInterval = _animationInterval;

- (id)initWithSequence:(ISSequence*)sequence
       refreshInterval:(int)interval
       useTextureCache:(bool)textureCache
                 loops:(BOOL)loops
                 range:(NSRange)range
     playbackDirection:(ISSequencePlaybackDirection)direction
              delegate:(id<ISSequencePlaybackViewDelegate>)delegate
{
    if (self = [super initWithSequence:sequence
                       refreshInterval:interval
                       useTextureCache:textureCache]
        )
    {
        _loops = loops;
        self.range = range;
        _paused = NO;
        _animationInterval = 0;
        _animationTimer = 0;
        _playbackDirection = direction;
        _delegate = delegate;
    }
    return self;
}

- (void)update
{
    if (_paused)
    {
        return;
    }
    
    if (_animationInterval != 0)
    {
        if (_animationTimer < _animationInterval)
        {
            _animationTimer ++;
            return;
        }
        else
        {
            _animationTimer = 0;
        }
    }
    
    
    int newFrame = [self currentFrame] + _playbackDirection;
    
    if (_loops)
    {
        if (newFrame >= (int)(_range.location + _range.length))
        {
            newFrame = newFrame - (int)(_range.length);
        }
        else if (newFrame < _range.location)
        {
            newFrame = newFrame + (int)(_range.length);
        }
    }
    else
    {
        if (newFrame >= _range.location + _range.length)
        {
            if (_delegate && [_delegate respondsToSelector:@selector(sequencePlaybackViewFinishedPlayback:)])
            {
                [_delegate sequencePlaybackViewFinishedPlayback:self];
            }
            [self pause];
        }
        else if (newFrame < _range.location)
        {
            if (_delegate && [_delegate respondsToSelector:@selector(sequencePlaybackViewFinishedPlayback:)])
            {
                [_delegate sequencePlaybackViewFinishedPlayback:self];
            }
            [self pause];
        }
    }
    
    if (newFrame >= _range.location && newFrame < _range.location + _range.length)
    {
        [self jumpToFrame:newFrame];
    }
}

- (void)setRange:(NSRange)range
{
    assert(range.location < [_sequence frameCount]);
    
    _range = range;
    _animationTimer = 0;
    
    [self jumpToFrame:_range.location];
}

- (void)setAnimationInterval:(int)animationInterval
{
    _animationInterval = animationInterval;
    _animationTimer = 0;
}


- (void)pause
{
    _paused = YES;
}

- (void)resume
{
    _paused = NO;
}

- (BOOL)paused
{
    return _paused;
}

@end


#pragma mark -
#pragma mark ISSequenceDragView
#pragma mark -

@interface ISSequenceDragView ()
{
    CGPoint _lastDragPoint;
    CGPoint _drag;
}

@end

@implementation ISSequenceDragView
@synthesize loops = _loops;
@synthesize range = _range;
@synthesize dragSensitivity = _dragSensitivity;
@synthesize dragDirection = _dragDirection;
@synthesize reverseDragDirection = _reverseDragDirection;
@synthesize delegate = _delegate;
@synthesize dragging = _dragging;

- (id)initWithSequence:(ISSequence*)sequence
       refreshInterval:(int)interval
       useTextureCache:(bool)textureCache
                 loops:(BOOL)loops
                 range:(NSRange)range
         dragDirection:(ISSequenceDragDirection)dragDirection
       dragSensitivity:(float)dragSensitivity
              delegate:(id)delegate
{
    if (self = [super initWithSequence:sequence
                        refreshInterval:interval
                        useTextureCache:textureCache])
    {
        _loops = loops;
        
        _dragDirection = dragDirection;
        _dragSensitivity = dragSensitivity;
        _delegate = delegate;
        _dragging = NO;
        
        _reverseDragDirection = NO;
        [self setRange:range];
    }
    
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_dragging)
    {
        return;
    }
    
    _lastDragPoint = [[touches anyObject] locationInView:self];
    _drag = CGPointZero;
    
    _dragging = YES;
    
    if (_delegate && [_delegate respondsToSelector:@selector(sequenceViewDragStarted:)])
    {
        [_delegate sequenceViewDragStarted:self];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!_dragging)
    {
        return;
    }
    
    CGPoint point = [[touches anyObject] locationInView:self];
    CGPoint delta = CGPointMake(_lastDragPoint.x - point.x, _lastDragPoint.y - point.y);
    
    int newFrame = [self currentFrame];
    
    
    float frameInterval = (self.bounds.size.width / (float)_range.length) / _dragSensitivity;

    if (_dragDirection == kISSequnceDragDirectionHorizontal)
    {
        if (_reverseDragDirection)
        {
            _drag.x += delta.x;
        }
        else
        {
            _drag.x -= delta.x;
        }
        
        if (fabs(_drag.x) > frameInterval)
        {
            newFrame = [self currentFrame] + floor(_drag.x / frameInterval);
            
            _drag.x -= floor(_drag.x / frameInterval) * frameInterval;
        }
    }
    else if (_dragDirection == kISSequnceDragDirectionVertical)
    {
        if (_reverseDragDirection)
        {
            _drag.y += delta.y;
        }
        else
        {
            _drag.y -= delta.y;
        }
        
        if (fabs(_drag.y) > frameInterval)
        {
            newFrame = [self currentFrame] + floor(_drag.y / frameInterval);
            
            _drag.y -= floor(_drag.y / frameInterval) * frameInterval;
        }
    }

    if (_loops)
    {
        if (newFrame >= (int)(_range.location + _range.length))
        {
            newFrame = newFrame - (int)(_range.length);
        }
        else if (newFrame < (int)(_range.location))
        {
            newFrame = newFrame + (int)(_range.length);
        }
    }
    else
    {
        if (newFrame >= (int)(_range.location + _range.length))
        {
            newFrame = (int)(_range.location + _range.length - 1);
        }
        else if (newFrame < (int)_range.location)
        {
            newFrame = _range.location;
        }
    }
    
    [self jumpToFrame:newFrame];
    
    
    _lastDragPoint = point;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_dragging)
    {
        _dragging = NO;

        if (_delegate && [_delegate respondsToSelector:@selector(sequenceViewDragFinished:)])
        {
            [_delegate sequenceViewDragFinished:self];
        }
    }
}

- (void)setRange:(NSRange)range
{
    assert(range.location < [_sequence frameCount]);
    
    _range = range;
    [self jumpToFrame:_range.location];
}


@end

#pragma mark -
#pragma mark ISSequenceGridView
#pragma mark -


@implementation ISSequenceGridView
@synthesize touchEnabled = _touchEnabled;
@synthesize range = _range;

- (id)initWithSequence:(ISSequence*)sequence
       refreshInterval:(int)interval
       useTextureCache:(bool)textureCache
                 range:(NSRange)range
          framesPerRow:(int)rowCount
          touchEnabled:(int)touchEnabled
{
    if (self = [super initWithSequence:sequence
                       refreshInterval:interval
                       useTextureCache:textureCache])
    {
        _touchEnabled = touchEnabled;
        _rowCount = rowCount;
        self.range = range;
        
    }
    return self;
}

- (void)setRange:(NSRange)range
{
    // check if the frames match the size
    if ((range.length % _rowCount) != 0)
    {
        NSLog(@"ISSequenceGridView requires frameCount: %i to be divisible by rowCount: %i", [[self sequence] frameCount], _rowCount);
    }
    
    _columnCount = range.length / _rowCount;
    
    [self jumpToFrame:_range.location];
}

- (void)jumpToFrame:(int)frame
{
    [super jumpToFrame:frame];
    
    _column = (frame - _range.location) / (_rowCount);
    _row = (frame - _range.location) % _rowCount;
}

- (void)jumpToFrameAtRow:(int)row
                  column:(int)column
{
    assert(row >= 0 && column >= 0 && row < _rowCount && column < _columnCount);
    [self jumpToFrame:(column * _rowCount + row) + _range.location];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!_touchEnabled)
    {
        return;
    }
    
    CGPoint point = [[touches anyObject] locationInView:self];
    
    float rowWidth = self.bounds.size.width / (float)_rowCount;
    float columnHeight = self.bounds.size.height / (float)_columnCount;
    
    [self jumpToFrameAtRow:(int)floor(point.x / rowWidth) column:(int)floor(point.y / columnHeight)];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!_touchEnabled)
    {
        return;
    }
    
    CGPoint point = [[touches anyObject] locationInView:self];
    
    float rowWidth = self.bounds.size.width / (float)_rowCount;
    float columnHeight = self.bounds.size.height / (float)_columnCount;
    
    [self jumpToFrameAtRow:(int)floor(point.x / rowWidth) column:(int)floor(point.y / columnHeight)];
}


- (int)row
{
    return _row;
}

- (int)column
{
    return _column;
}

- (int)rowCount
{
    return _rowCount;
}

- (int)columnCount
{
    return _columnCount;
}

@end




