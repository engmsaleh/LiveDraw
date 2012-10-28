//
//  LDViewController.m
//  LiveDraw
//
//  Created by Phillip Cohen on 10/28/12.
//  Copyright (c) 2012 Phillip Cohen. All rights reserved.
//

#import "LDViewController.h"
#import "PTPusher.h"
#import "PTPusherEvent.h"

@interface LDViewController ()
@property(nonatomic) EAGLContext *context;
@property(nonatomic) PTPusher *client;
@property(nonatomic) BOOL connected;
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
        _client = [PTPusher pusherWithKey:@"e658d927568df2c3656f" delegate:self encrypted:YES];
        _client.authorizationURL = [NSURL URLWithString:@"http://phillipcohen.net/LiveDraw/auth.php"];
        [_client subscribeToChannelNamed:@"private-app"]; // imaginative
        [_client bindToEventNamed:@"client-touch" target:self action:@selector(eventReceived:)];

        // Load the brush texture.
        CGImageRef brushImage;


        // Create a texture from an image
        // First create a UIImage object from the data in a image file, and then extract the Core Graphics image
        brushImage = [UIImage imageNamed:@"Particle.png"].CGImage;

        // Get the width and height of the image
        size_t width, height;
        width = CGImageGetWidth(brushImage);
        height = CGImageGetHeight(brushImage);

        // Texture dimensions must be a power of 2. If you write an application that allows users to supply an image,
        // you'll want to add code that checks the dimensions and takes appropriate action if they are not a power of 2.

        // Make sure the image exists
        if (brushImage)
        {
            GLubyte *brushData;
            CGContextRef brushContext;

            // Allocate  memory needed for the bitmap context
            brushData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
            // Use  the bitmatp creation function provided by the Core Graphics framework.
            brushContext = CGBitmapContextCreate(brushData, width, height, 8, width * 4, CGImageGetColorSpace(brushImage), kCGImageAlphaPremultipliedLast);
            // After you create the context, you can draw the  image to the context.
            CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat) width, (CGFloat) height), brushImage);
            // You don't need the context at this point, so you need to release it to avoid memory leaks.
            CGContextRelease(brushContext);
            // Use OpenGL ES to generate a name for the texture.
            glGenTextures(1, &_brushTexture);
            // Bind the texture name.
            glBindTexture(GL_TEXTURE_2D, _brushTexture);
            // Set the texture parameters to use a minifying filter and a linear filer (weighted average)
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            // Specify a 2D texture image, providing the a pointer to the image data in memory
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushData);
            // Release  the image data; it's no longer needed
            free(brushData);
        }
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]; // 1
    GLKView *view = (GLKView *) self.view;
    view.context = _context; // 3
    view.delegate = self; // 4
}

- (void)update
{
    // Render loop, called once per frame
    glClearColor(255, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

// Drawings a line onscreen based on where the user touches
- (void)renderLine
{
    [self renderLineFromPoint:_previousLocation toPoint:_location];
}

// Drawings a line onscreen based on where the user touches
- (void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
//    NSLog(@"Drawing from (%d, %d) to (%d,%d)", (int) start.x, (int) start.y, (int) end.x, (int) end.y);
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

    // Render the vertex array
    glVertexPointer(2, GL_FLOAT, 0, vertexBuffer);
    glDrawArrays(GL_POINTS, 0, vertexCount);
}

- (CGPoint)processLocationFromTouchEvent:(UIEvent *)event previous:(BOOL)previous
{
    CGRect bounds = [self.view bounds];
    UITouch *touch = [[event touchesForView:self.view] anyObject];

    // Invert y axis
    CGPoint location = previous ? [touch previousLocationInView:self.view] : [touch locationInView:self.view];
    location.y = bounds.size.height - location.y;

    return location;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _firstTouch = YES;
    _location = [self processLocationFromTouchEvent:event previous:NO];
//    NSDictionary *info = @{
//    @"x" : @(location.x),
//    @"y" : @(location.y)
//    };
//
//    // Send it locally and over the network.
//    [self addPointToCanvasWithInfo:info];
//    if (_connected)
//        [_client sendEventNamed:@"client-touch" data:info channel:@"private-app"];

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

// Called when the canvas is touched by any client, or the local user.
- (void)addPointToCanvasWithInfo:(NSDictionary *)info
{
    CGFloat x = [info[@"x"] floatValue];
    CGFloat y = [info[@"y"] floatValue];
    NSLog(@"Touched at (%d,%d)...", (int) x, (int) y);

    // TODO: Add it to the frame
}

#pragma mark Networking

- (void)eventReceived:(PTPusherEvent *)event
{
    [self addPointToCanvasWithInfo:event.data];
}

#pragma mark Delegates(PTPusher)

- (void)pusher:(PTPusher *)pusher connectionDidConnect:(PTPusherConnection *)connection
{
    NSLog(@"Connected to server");
    _connected = YES;
}

@end
