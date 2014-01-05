//
//  SCHTask.m
//  Used to represent tasks retrieved from the Scholar website. This class is meant to be abstract,
//  so use one of its implementing classes instead.
//
//  Created by Alex Lamar on 1/5/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHTask.h"

@implementation SCHTask

-(id)init
{
    return [self initWithTaskName:@"N/A" andCourseName:@"N/A" andDueDate:nil];
}

-(id)initWithTaskName:(NSString *)taskName andCourseName:(NSString *)courseName andDueDateString:(NSString *)dueDateString
{
    self = [super init];
    if (self) {
        [self setTaskName:taskName];
        [self setCourseName:courseName];
        [self setDueDate:[self parseDueDateString:dueDateString]];
    }
    return self;
}

-(id)initWithTaskName:(NSString *)taskName andCourseName:(NSString *)courseName andDueDate:(NSDate *)dueDate
{
    self = [super init];
    if (self) {
        [self setTaskName:taskName];
        [self setCourseName:courseName];
        [self setDueDate:dueDate];
    }
    return self;
}

//Compares based on two task object's dueDates. Is nil-safe, any nil due dates will always be greater
//than non-nil due dates
-(NSComparisonResult)compare:(SCHTask *)object
{
    if (self.dueDate == nil && object.dueDate == nil) {
        return NSOrderedSame;
    }
    else if (self.dueDate != nil && object.dueDate == nil) {
        return NSOrderedAscending;
    }
    else if (self.dueDate == nil && object.dueDate != nil) {
        return NSOrderedDescending;
    }
    return [self.dueDate compare:object.dueDate];
}

//This method is used to parse date strings retrieved from the Scholar website. Because date strings have different formats depending on
//where they are retrieved from (i.e. assignment pages or homework pages), this implementation is deferred to each of its subclasses.
-(NSDate *)parseDueDateString:(NSString *)dueDateString
{
    @throw([NSException exceptionWithName:@"AbstractMethodCallException"
                                     reason:@"Do not use the Task class directly, instead use one of its subclasses which implement the parseDueDateString method"
                                     userInfo:nil]);
}

@end
