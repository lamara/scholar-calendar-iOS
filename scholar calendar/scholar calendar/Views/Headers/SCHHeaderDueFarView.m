//
//  SCHHeaderDueFarView.m
//  scholar calendar
//
//  Created by Alex Lamar on 1/8/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHHeaderDueFarView.h"

@implementation SCHHeaderDueFarView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setText:@"Due a while from now"];
    }
    return self;
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
