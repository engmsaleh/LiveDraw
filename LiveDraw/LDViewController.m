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
@end

@implementation LDViewController

- (id)init {
  if (self = [super init]) {
    _client = [PTPusher pusherWithKey:@"e658d927568df2c3656f" delegate:self encrypted:YES];
  }
}

- (void)viewDidLoad
{
  [super viewDidLoad];
}

- (void)update
{
    // Render loop, called once per frame
}

#pragma mark Networking

- (void)eventReceived:(PTPusherEvent *)event {
  NSLog(@"Received touch %@...", event.name);
}

#pragma mark Delegates(PTPusher)

- (void)pusher:(PTPusher *)pusher connectionDidConnect:(PTPusherConnection *)connection {
  [_client bindToEventNamed:@"touch" target:self action:@selector(eventReceived:)];
}

@end
