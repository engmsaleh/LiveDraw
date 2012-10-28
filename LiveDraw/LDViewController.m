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
@property (nonatomic) EAGLContext *context;
@end

@implementation LDViewController

- (id)init
{
    if (self = [super init])
    {
        _client = [PTPusher pusherWithKey:@"e658d927568df2c3656f" delegate:self encrypted:YES];
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
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGRect bounds = [self.view bounds];
    UITouch *touch = [[event touchesForView:self.view] anyObject];

    // Invert y axis
    CGPoint location = [touch locationInView:self];
    location.y = bounds.size.height - location.y;

    [_client sendEventNamed:@"client-touch" data:@{
    @"x" : [NSNumber numberWithFloat:location.x], @"y" : [NSNumber numberWithFloat:location.y]
    }               channel:@"app"];
}

#pragma mark Networking

- (void)eventReceived:(PTPusherEvent *)event
{
    NSLog(@"Received touch %@...", event.name);
}

#pragma mark Delegates(PTPusher)

- (void)pusher:(PTPusher *)pusher connectionDidConnect:(PTPusherConnection *)connection
{
    [_client subscribeToChannelNamed:@"app"]; // imaginative
    [_client bindToEventNamed:@"client-touch" target:self action:@selector(eventReceived:)];
}

@end
