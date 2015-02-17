//
//  SCHHeaderDueThisWeekView.m
//  scholar calendar
//
//  Created by Alex Lamar on 1/8/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHHeaderDueThisWeekView.h"

@implementation SCHHeaderDueThisWeekView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSDate *today = [[NSDate alloc] init];
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *dayComponents = [calendar components:(NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit) fromDate:today];
        
        //this logic will give us the beginning day of the current calendar week
        NSInteger day = [dayComponents day];
        NSInteger dayOfWeek = [dayComponents weekday];
        NSInteger beginOfWeek = day - dayOfWeek + 2;
        
        [dayComponents setDay:beginOfWeek];
        NSDate *dateAtBeginningOfWeek = [calendar dateFromComponents:dayComponents];
        [dayComponents setDay:(beginOfWeek + 6)];
        NSDate *dateAtEndOfWeek = [calendar dateFromComponents:dayComponents];
        
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MMM. d"];
        
        NSString *stringForBeginningOfWeek = [formatter stringFromDate:dateAtBeginningOfWeek];
        NSString *stringForEndOfWeek = [formatter stringFromDate:dateAtEndOfWeek];
        NSString *message = @"Due this week, ";
        message = [message stringByAppendingString:stringForBeginningOfWeek];
        NSString *em_dash = @" \u2014 ";
        message = [message stringByAppendingString:em_dash];
        message = [message stringByAppendingString:stringForEndOfWeek];
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
