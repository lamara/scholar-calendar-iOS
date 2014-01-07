//
//  SCHHeaderView.m
//  scholar calendar
//
//  Created by Alex Lamar on 1/7/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHHeaderView.h"

@implementation SCHHeaderView

static UILabel *label;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 40)];
        [label setFont:[UIFont fontWithName:@"Helvetica-Bold" size:18]];
        [label setTextColor:[UIColor colorWithRed:128/255.0 green:128/255.0 blue:128/255.0 alpha:1]];
        [label setShadowColor:[UIColor whiteColor]];
        [label setShadowOffset:CGSizeMake(0, 1.5)];
        [label setText:@"A header view"];
        label.textAlignment = NSTextAlignmentCenter;
        [self setBackgroundColor:[UIColor colorWithRed:224/255.0 green:224/255.0 blue:224/255.0 alpha:1]];
        [label setBackgroundColor:[UIColor colorWithRed:224/255.0 green:224/255.0 blue:224/255.0 alpha:1]];
        [self addSubview:label];
    }
    return self;
}

-(void)setText:(NSString *)text
{
    [label setText:text];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
