//
//  LDViewController.m
//  LiveDraw
//
//  Created by Phillip Cohen on 10/28/12.
//  Copyright (c) 2012 Phillip Cohen. All rights reserved.
//

#import "LDViewController.h"

@interface LDViewController ()
@property(nonatomic) LDNetworkingClient *client;
@property(nonatomic) EAGLContext *context;
@property(nonatomic) GLuint brushTexture;
@property(nonatomic) CGPoint location;
@property(nonatomic) CGPoint previousLocation;
@property(nonatomic) BOOL firstTouch;
@end

@implementation LDViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        _client = [[LDNetworkingClient alloc] initWithDelegate:self];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!_context)
    {
        NSLog(@"Unable to create OpenGL context");
    }

    GLKView *view = (GLKView *) self.view;
    view.context = _context;
    view.contentScaleFactor = [UIScreen mainScreen].scale;

    [EAGLContext setCurrentContext:_context];

    // Create stamp texture
    NSError *error = nil;
    NSString *stampPath = [[NSBundle mainBundle] pathForResource:@"stamp.png" ofType:nil];
    if ([GLKTextureLoader textureWithContentsOfFile:stampPath options:nil error:&error])
    {
        NSLog(@"got stamp info");
    }
    else
    {
        NSLog(@"Did NOT get stamp info. Error: %@", error);
    }
}

- (void)update
{
}

// Drawings a line onscreen based on where the user touches
- (void)renderLine
{
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
