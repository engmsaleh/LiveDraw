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
@property(nonatomic) NSUInteger id;
@property(nonatomic) BOOL connected;
@property(nonatomic) NSMutableArray *messageQueue;
@end

@implementation LDNetworkingClient

#pragma mark Initializers

- (id)initWithDelegate:(id <LDNetworkingClientDelegate>)delegate;
{
    if (self = [super init])
    {
        _id = arc4random();
        _delegate = delegate;
        _messageQueue = [NSMutableArray arrayWithCapacity:500];
        _client = [PTPusher pusherWithKey:@"e658d927568df2c3656f" delegate:self encrypted:YES];
        _client.authorizationURL = [NSURL URLWithString:@"http://phillipcohen.net/LiveDraw/auth.php"];
        [_client subscribeToChannelNamed:kNetworkingChannel];

        // Bind to all the events we support here.
        [_client bindToEventNamed:kBatchEvent target:self action:@selector(eventReceived:)];
        [_client bindToEventNamed:kDrawEvent target:self action:@selector(eventReceived:)];

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
    [self sendMessage:[[PTPusherEvent alloc] initWithEventName:kDrawEvent channel:kNetworkingChannel data:
            @{
            @"start": [self dictionaryFromPoint:start],
            @"end": [self dictionaryFromPoint:end]
            }]];
}

#pragma mark Private Methods

/**
* "Sends" a message (really wraps it in our network queue for later transmission).
*/
- (void)sendMessage:(PTPusherEvent *)event
{
    NSMutableDictionary *data = [event.data mutableCopy];
    data[@"event"] = event.name;
    data[@"id"] = @(_id);
    [_messageQueue addObject:data];
}

/**
* Sends all events that have queued up.
*/
- (void)sendBatchedEvents
{
    if (!_connected || _messageQueue.count == 0)
        return;

    NSLog(@"Sending %d batched events...", _messageQueue.count);
    [_client sendEventNamed:kBatchEvent data:_messageQueue channel:kNetworkingChannel];
    [_messageQueue removeAllObjects];
}

/**
* Processes a networking message.
*/
- (void)eventReceived:(PTPusherEvent *)event
{
    if ([event.name isEqualToString:kBatchEvent])
    {
        for (NSDictionary *singleEvent in event.data)
        {
            // Convert every event in the batch into its own top-level event. (They must all have the "event" property!)
            [self eventReceived:[[PTPusherEvent alloc] initWithEventName:singleEvent[@"event"] channel:event.channel data:singleEvent]];
        }
    }
    else if ([event.name isEqualToString:kDrawEvent])
    {
        if (event.data[@"start"] && event.data[@"end"])
            [_delegate shouldDrawLineFromPoint:[self pointFromDictionary:event.data[@"start"]] toPoint:[self pointFromDictionary:event.data[@"end"]]];
    }
    else if ([event.name isEqualToString:kConnectEvent])
    {
        NSLog(@"Client {%d} has connected!", [event.data[@"id"] intValue]);
    }
}

/**
* Called every 0.15 seconds.
*/
- (void)handleTimer:(NSTimer *)timer
{
    [self sendBatchedEvents];
}

#pragma mark Converters

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

#pragma mark Delegates(PTPusher)

- (void)pusher:(PTPusher *)pusher connectionDidConnect:(PTPusherConnection *)connection
{
    NSLog(@"Connected to server");
    _connected = YES;
    [self sendMessage:[[PTPusherEvent alloc] initWithEventName:kConnectEvent channel:kNetworkingChannel data:@{
    }]];
}

@end
