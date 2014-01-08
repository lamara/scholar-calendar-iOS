//
//  SCHHeaderDueTodayView.m
//  scholar calendar
//
//  Created by Alex Lamar on 1/8/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHHeaderDueTodayView.h"

@implementation SCHHeaderDueTodayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSDate *today = [[NSDate alloc] init];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MMMM d"];
        NSString *time = [formatter stringFromDate:today];
        NSString *message = @"Due today, ";
        message = [message stringByAppendingString:time];
        [self setText:message];
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
