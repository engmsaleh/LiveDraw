//
//  LDNetworkingClient.m
//  LiveDraw
//
//  Created by Phillip Cohen on 10/28/12.
//  Copyright (c) 2012 Phillip Cohen. All rights reserved.
//

#import "LDNetworkingClient.h"
#import "PTPusher.h"
#import "PTPusherEvent.h"

@interface LDNetworkingClient ()
@property(nonatomic) PTPusher *client;
@property(nonatomic) BOOL connected;
@property(nonatomic) NSMutableArray *messageQueue;
@end

@implementation LDNetworkingClient

- (id)initWithDelegate:(id <LDNetworkingClientDelegate>)delegate;
{
    if (self = [super init])
    {
        _delegate = delegate;
        _messageQueue = [NSMutableArray arrayWithCapacity:500];
        _client = [PTPusher pusherWithKey:@"e658d927568df2c3656f" delegate:self encrypted:YES];
        _client.authorizationURL = [NSURL URLWithString:@"http://phillipcohen.net/LiveDraw/auth.php"];
        [_client subscribeToChannelNamed:kNetworkingChannel];
        [_client bindToEventNamed:kDrawEventName target:self action:@selector(eventReceived:)];
    }

    return self;
}

- (void)sendDrawMessageFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
    if (_connected)
    {
        [_messageQueue addObject:@{
        @"event": kDrawEventName,
        @"start": [self dictionaryFromPoint:start],
        @"end": [self dictionaryFromPoint:start]
        }];
    }
}

- (NSDictionary *)dictionaryFromPoint:(CGPoint)point
{
    return @{
    @"x" : @(point.x),
    @"y" : @(point.y)
    };
}

- (CGPoint)pointFromDictionary:(NSDictionary *)dict
{
    return CGPointMake([dict[@"x"] floatValue], [dict[@"y"] floatValue]);
}


#pragma mark Networking

- (void)eventReceived:(PTPusherEvent *)event
{
    if ([event.name isEqualToString:kDrawEventName] && event.data[@"start"] && event.data[@"end"])
    {
        [_delegate shouldDrawLineFromPoint:[self pointFromDictionary:event.data[@"start"]] toPoint:[self pointFromDictionary:event.data[@"end"]]];
    }
}

#pragma mark Delegates(PTPusher)

- (void)pusher:(PTPusher *)pusher connectionDidConnect:(PTPusherConnection *)connection
{
    NSLog(@"Connected to server");
    _connected = YES;
}

@end
