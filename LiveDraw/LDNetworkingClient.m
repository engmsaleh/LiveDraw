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

#pragma mark Initializers

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

        [NSTimer scheduledTimerWithTimeInterval:0.15
                                         target:self
                                       selector:@selector(handleTimer:)
                                       userInfo:nil repeats:YES];
    }

    return self;
}

#pragma mark Public Methods

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

#pragma mark Private Methods

- (void)sendBatchedEvents
{
    if (!_connected || _messageQueue.count == 0)
        return;

    NSLog(@"Sending %d batched events...", _messageQueue.count);
    [_client sendEventNamed:kBatchMessageName data:_messageQueue channel:kNetworkingChannel];
    [_messageQueue removeAllObjects];
}

- (void)handleTimer:(NSTimer *)timer
{
    [self sendBatchedEvents];
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

- (void)actOnEventNamed:(NSString *)eventName withData:(id)data
{
    if ([eventName isEqualToString:kBatchMessageName])
    {
        for (NSDictionary *single in data)
        {
            [self actOnEventNamed:eventName withData:single];
        }
    } else if ([eventName isEqualToString:kDrawEventName] && data[@"start"] && data[@"end"])
    {
        [_delegate shouldDrawLineFromPoint:[self pointFromDictionary:data[@"start"]] toPoint:[self pointFromDictionary:data[@"end"]]];
    }
}

- (void)eventReceived:(PTPusherEvent *)event
{
    [self actOnEventNamed:event.name withData:event.data];
}

#pragma mark Delegates(PTPusher)

- (void)pusher:(PTPusher *)pusher connectionDidConnect:(PTPusherConnection *)connection
{
    NSLog(@"Connected to server");
    _connected = YES;
}

@end
