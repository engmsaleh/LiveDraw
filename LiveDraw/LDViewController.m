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
@end

@implementation LDViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        _client = [PTPusher pusherWithKey:@"e658d927568df2c3656f" delegate:self encrypted:YES];
        [_client subscribeToChannelNamed:@"app"]; // imaginative
        [_client bindToEventNamed:@"client-touch" target:self action:@selector(eventReceived:)];
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGRect bounds = [self.view bounds];
    UITouch *touch = [[event touchesForView:self.view] anyObject];

    // Invert y axis
    CGPoint location = [touch locationInView:self.view];
    location.y = bounds.size.height - location.y;

    // Serialize info
    NSDictionary *info = @{
    @"x" : @(location.x),
    @"y" : @(location.y)
    };

    // Send it locally and over the network.
    [self addPointToCanvasWithInfo:info];
    [_client sendEventNamed:@"client-touch" data:info channel:@"app"];
}

// Called when the canvas is touched by any client, or the local user.
- (void)addPointToCanvasWithInfo:(NSDictionary *)info
{
    CGFloat x = [info[@"x"] floatValue];
    CGFloat y = [info[@"y"] floatValue];
    NSLog(@"Touched at (%f,%f)...", x, y);

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
}

@end
