//
//  SCHAssignment.m
//
//  Created by Alex Lamar on 1/5/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHAssignment.h"

@implementation SCHAssignment

//Parses a string date of the format "Apr 17, 2013 12:30 am" into a date object
-(NSDate *)parseDueDateString:(NSString *)dueDateString
{
    dueDateString = [dueDateString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setAMSymbol:@"am"];
    [dateFormatter setPMSymbol:@"pm"];
    [dateFormatter setDateFormat:@"MMM d, yyyy h:mm aaa"];
    return [dateFormatter dateFromString:dueDateString];
}

@end
