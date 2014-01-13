//
//  SCHQuiz.m
//  scholar calendar
//
//  Created by Alex Lamar on 1/5/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHQuiz.h"

@implementation SCHQuiz


//Parses a string date of the format "2013-Jan-27 04:48 PM into a date object
-(NSDate *)parseDueDateString:(NSString *)dueDateString
{
    dueDateString = [dueDateString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MMM-dd hh:mm aaa"];
    return [dateFormatter dateFromString:dueDateString];
}

@end
