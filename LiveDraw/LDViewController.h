//
//  LDViewController.h
//  LiveDraw
//
//  Created by Phillip Cohen on 10/28/12.
//  Copyright (c) 2012 Phillip Cohen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PTPusherDelegate.h"
#import "LDNetworkingClient.h"

@class PTPusher;

@interface LDViewController : UIViewController <LDNetworkingClientDelegate>

@end
