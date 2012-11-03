//
//  LDViewController.m
//  LiveDraw
//
//  Created by Phillip Cohen on 10/28/12.
//  Copyright (c) 2012 Phillip Cohen. All rights reserved.
//

#import "LDViewController.h"
#import "LDSubSegment.h"

@interface LDViewController ()
@property(nonatomic) LDNetworkingClient *client;
@property(nonatomic) EAGLContext *context;
@property(nonatomic) GLuint brushTexture;
@property(nonatomic) CGPoint location;
@property(nonatomic) CGPoint previousLocation;
@property(nonatomic) BOOL firstTouch;
@property(nonatomic) GLKBaseEffect *effect;
@property(nonatomic) NSMutableArray *segmentQueue;
@end

@implementation LDViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        _client = [[LDNetworkingClient alloc] initWithDelegate:self];
        _segmentQueue = [[NSMutableArray alloc] init];
    }

    return self;
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];

    self.effect = [[GLKBaseEffect alloc] init];

    // Let's color the line
    self.effect.useConstantColor = GL_TRUE;

    // Make the line a cyan color
    self.effect.constantColor = GLKVector4Make(
            1.0f, // Red
            1.0f, // Green
            1.0f, // Blue
            1.0f);// Alpha
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context)
    {
        NSLog(@"Failed to create ES context");
    }

    GLKView *view = (GLKView *) self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [EAGLContext setCurrentContext:self.context];

    [self setupGL];
}

- (GLfloat)normalizeCoordinate:(CGFloat)coordinate fromMax:(CGFloat)max
{
    return (coordinate - max / 2.0f) / max;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
//    glClearColor(0.65f, 0.65f, 0.65f, 0.2f);
//    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // Prepare the effect for rendering
    [self.effect prepareToDraw];

    for (LDSubSegment *segment in _segmentQueue)
    {
        GLfloat x1 = [self normalizeCoordinate:segment.start.x fromMax:self.view.bounds.size.width];
        GLfloat y1 = [self normalizeCoordinate:segment.start.y fromMax:self.view.bounds.size.height];
        GLfloat x2 = [self normalizeCoordinate:segment.end.x fromMax:self.view.bounds.size.width];
        GLfloat y2 = [self normalizeCoordinate:segment.end.y fromMax:self.view.bounds.size.height];

        const GLfloat line[] =
                {
                        x1, y1, //point A
                        x2, y2, //point B
                };

        // Create an handle for a buffer object array
        GLuint bufferObjectNameArray;

        // Have OpenGL generate a buffer name and store it in the buffer object array
        glGenBuffers(1, &bufferObjectNameArray);

        // Bind the buffer object array to the GL_ARRAY_BUFFER target buffer
        glBindBuffer(GL_ARRAY_BUFFER, bufferObjectNameArray);

        // Send the line data over to the target buffer in GPU RAM
        glBufferData(
                GL_ARRAY_BUFFER,   // the target buffer
                sizeof(line),      // the number of bytes to put into the buffer
                line,              // a pointer to the data being copied
                GL_STATIC_DRAW);   // the usage pattern of the data

        // Enable vertex data to be fed down the graphics pipeline to be drawn
        glEnableVertexAttribArray(GLKVertexAttribPosition);

        // Specify how the GPU looks up the data
        glVertexAttribPointer(
                GLKVertexAttribPosition, // the currently bound buffer holds the data
                2,                       // number of coordinates per vertex
                GL_FLOAT,                // the data type of each component
                GL_FALSE,                // can the data be scaled
                2 * 4,                     // how many bytes per vertex (2 floats per vertex)
                NULL);                   // offset to the first coordinate, in this case 0

        glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
        glDrawArrays(GL_LINES, 0, 2); // render
    }

    [_segmentQueue removeAllObjects];
}

// Drawings a line onscreen based on where the user touches
- (void)renderLine
{
    LDSubSegment *segment = [[LDSubSegment alloc] init];
    segment.start = _previousLocation;
    segment.end = _location;
    [_segmentQueue addObject:segment];
    [self renderLineFromPoint:_previousLocation toPoint:_location sendToClients:YES];
}

// Drawings a line onscreen based on where the user touches
- (void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end sendToClients:(BOOL)sendToClients
{
    NSLog(@"Drawing from (%d, %d) to (%d,%d)", (int) start.x, (int) start.y, (int) end.x, (int) end.y);
    static GLfloat *vertexBuffer = NULL;
    static NSUInteger vertexMax = 64;
    NSUInteger vertexCount = 0,
            count,
            i;

    // Convert locations from Points to Pixels
    CGFloat scale = self.view.contentScaleFactor;
    start.x *= scale;
    start.y *= scale;
    end.x *= scale;
    end.y *= scale;

    // Allocate vertex array buffer
    if (vertexBuffer == NULL)
        vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));

    // Add points to the buffer so there are drawing points every X pixels
    count = (NSUInteger) MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) / kBrushPixelStep), 1);
    for (i = 0; i < count; ++i)
    {
        if (vertexCount == vertexMax)
        {
            vertexMax = 2 * vertexMax;
            vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
        }

        vertexBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat) i / (GLfloat) count);
        vertexBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat) i / (GLfloat) count);
        vertexCount += 1;
    }

    // TODO - Draw vertex array

    // If locally originated, send to other clients
    if (sendToClients)
        [_client sendDrawMessageFromPoint:[self invertYAxisOfPoint:start] toPoint:[self invertYAxisOfPoint:end]];
}

- (CGPoint)invertYAxisOfPoint:(CGPoint)point
{
    return CGPointMake(point.x, [self.view bounds].size.height - point.y);
}

- (CGPoint)processLocationFromTouchEvent:(UIEvent *)event previous:(BOOL)previous
{
    CGRect bounds = [self.view bounds];
    UITouch *touch = [[event touchesForView:self.view] anyObject];

    // Invert y axis
    CGPoint location = previous ? [touch previousLocationInView:self.view] : [touch locationInView:self.view];
    return [self invertYAxisOfPoint:location];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _firstTouch = YES;
    _location = [self processLocationFromTouchEvent:event previous:NO];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    _previousLocation = [self processLocationFromTouchEvent:event previous:YES];
    if (_firstTouch)
    {
        _firstTouch = NO;
    }
    else
    {
        _location = [self processLocationFromTouchEvent:event previous:NO];
    }

    [self renderLine];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_firstTouch)
    {
        _firstTouch = NO;
        _previousLocation = [self processLocationFromTouchEvent:event previous:YES];
        [self renderLine];
    }
}

#pragma mark (LDNetworkingClientDelegate)

- (void)shouldDrawLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
    [self renderLineFromPoint:start toPoint:end sendToClients:NO];
}

@end
