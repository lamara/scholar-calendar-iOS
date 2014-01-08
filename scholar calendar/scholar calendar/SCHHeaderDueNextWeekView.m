//
//  SCHHeaderDueNextWeekView.m
//  scholar calendar
//
//  Created by Alex Lamar on 1/8/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHHeaderDueNextWeekView.h"

@implementation SCHHeaderDueNextWeekView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSDate *today = [[NSDate alloc] init];
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *dayComponents = [calendar components:(NSWeekdayCalendarUnit | NSDayCalendarUnit) fromDate:today];
        
        //this logic will give us the beginning day of the next calendar week
        NSInteger day = [dayComponents day];
        NSInteger dayOfWeek = [dayComponents weekday];
        NSInteger beginOfNextWeek = day - dayOfWeek + 9;
        
        [dayComponents setDay:beginOfNextWeek];
        NSDate *dateAtBeginningOfNextWeek = [calendar dateFromComponents:dayComponents];
        [dayComponents setDay:(beginOfNextWeek + 6)];
        NSDate *dateAtEndOfWeek = [calendar dateFromComponents:dayComponents];
        
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MMM. d"];
        
        NSString *stringForBeginningOfNextWeek = [formatter stringFromDate:dateAtBeginningOfNextWeek];
        NSString *stringForEndOfWeek = [formatter stringFromDate:dateAtEndOfWeek];
        NSString *message = @"Due next week, ";
        message = [message stringByAppendingString:stringForBeginningOfNextWeek];
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
