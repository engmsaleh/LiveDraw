//
//  LDCanvas.m
//  LiveDraw
//
//  Created by Ed McManus on 11/3/12.
//  Copyright (c) 2012 Phillip Cohen. All rights reserved.
//

#import "LDCanvas.h"

@interface LDCanvas ()
@property(nonatomic, strong) NSMutableArray *points;
@end

@implementation LDCanvas

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.points = [NSMutableArray array];
    }
    return self;
}

- (void)drawFrom:(CGPoint)start to:(CGPoint)end withColor:(UIColor *)color;
{
    NSDictionary * points = @{
        @"start": @{
            @"x": @(start.x), @"y": @(start.y)
        },
        @"end": @{
            @"x": @(end.x), @"y": @(end.y)
        },
		@"color": color
    };
    [self.points addObject:points];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapRound);
    
    for (NSDictionary * pair in self.points)
    {
        CGPoint start = CGPointMake([pair[@"start"][@"x"] doubleValue], [pair[@"start"][@"y"] doubleValue]);
        CGPoint end = CGPointMake([pair[@"end"][@"x"] doubleValue], [pair[@"end"][@"y"] doubleValue]);
        UIColor *color = pair[@"color"];

        CGContextSetStrokeColorWithColor(context, [color CGColor]);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetLineWidth(context, 5);

        CGContextMoveToPoint(context, end.x, end.y);
        CGContextAddLineToPoint(context, start.x, start.y);
        
        CGContextStrokePath(context);
    }
}

@end
