//
//  LDViewController.m
//  LiveDraw
//
//  Created by Phillip Cohen on 10/28/12.
//  Copyright (c) 2012 Phillip Cohen. All rights reserved.
//

#import "LDViewController.h"
#import "LDCanvas.h"

@interface LDViewController ()
@property(nonatomic) LDNetworkingClient *client;
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
        
        self.view = [[LDCanvas alloc] initWithFrame:self.view.frame];
        self.view.backgroundColor = [UIColor colorWithRed:0.2 green:0 blue:0 alpha:1];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    
    LDCanvas * view = (LDCanvas*)self.view;
    [view drawFrom:start to:end];

    // If locally originated, send to other clients
    if (sendToClients)
        [_client sendDrawMessageFromPoint:start toPoint:end];
}

- (CGPoint)processLocationFromTouchEvent:(UIEvent *)event previous:(BOOL)previous
{
    UITouch *touch = [[event touchesForView:self.view] anyObject];

    // Invert y axis
    CGPoint location = previous ? [touch previousLocationInView:self.view] : [touch locationInView:self.view];
    return location;
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
