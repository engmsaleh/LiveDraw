//
//  LDViewController.h
//  LiveDraw
//
//  Created by Phillip Cohen on 10/28/12.
//  Copyright (c) 2012 Phillip Cohen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "PTPusherDelegate.h"

@class PTPusher;

@interface LDViewController : GLKViewController<PTPusherDelegate> {
  PTPusher *_client;
}

@end
