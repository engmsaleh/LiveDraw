//
//  LDNetworkingClient.h
//  LiveDraw
//
//  Created by Phillip Cohen on 10/28/12.
//  Copyright (c) 2012 Phillip Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PTPusherDelegate.h"

@protocol LDNetworkingClientDelegate <NSObject>
- (void)shouldDrawLineFromPoint:(CGPoint)start toPoint:(CGPoint)end withColor:(UIColor *)color;
@end

#define ARC4RANDOM_MAX      0x100000000
#define kNetworkingChannel @"private-livedraw-1.3"
#define kConnectEvent @"client-hello"
#define kBatchEvent @"client-batch"
#define kDrawEvent @"client-draw-line"

/**
* Handles network communication with other clients using Pusher.
*/
@interface LDNetworkingClient : NSObject <PTPusherDelegate>

- (id)initWithDelegate:(id <LDNetworkingClientDelegate>)delegate;

- (void)sendDrawMessageFromPoint:(CGPoint)start toPoint:(CGPoint)end;

@property(weak, nonatomic) id <LDNetworkingClientDelegate> delegate; // weak;
@property(readonly, nonatomic) UIColor *color;

@end
