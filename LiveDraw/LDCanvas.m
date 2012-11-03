//
//  LDCanvas.m
//  LiveDraw
//
//  Created by Ed McManus on 11/3/12.
//  Copyright (c) 2012 Phillip Cohen. All rights reserved.
//

#import "LDCanvas.h"

@interface LDCanvas()
@property (nonatomic, strong) NSMutableArray * points;
@end

@implementation LDCanvas

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSLog(@"Initialized LDCanvas in decoder");
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.points = [NSMutableArray array];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    NSLog(@"Initialized LDCanvas");
    
    if (self) {
        self.points = [NSMutableArray array];
    }
    return self;
}

- (void)drawFrom:(CGPoint)start to:(CGPoint)end
{
    NSDictionary * points = @{
        @"start": @{
            @"x": @(start.x), @"y": @(start.y)
        },
        @"end": @{
            @"x": @(end.x), @"y": @(end.y)
        }
    };
    [self.points addObject:points];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    for (NSDictionary * pair in self.points)
    {
        CGPoint start = CGPointMake([pair[@"start"][@"x"] doubleValue], [pair[@"start"][@"y"] doubleValue]);
        CGPoint end = CGPointMake([pair[@"end"][@"x"] doubleValue], [pair[@"end"][@"y"] doubleValue]);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        UIColor *color = [UIColor colorWithRed:1.f green:1.f blue:1.f alpha:1];
        
        CGContextSetStrokeColorWithColor(context, [color CGColor]);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetLineWidth(context, 15);
        
        CGContextMoveToPoint(context, end.x, end.y);
        CGContextAddLineToPoint(context, start.x, start.y);
        CGContextStrokePath(context);
    }
}

@end