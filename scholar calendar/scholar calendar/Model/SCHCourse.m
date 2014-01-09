//
//  SCHCourse.m
//  scholar calendar
//
//  Created by Alex Lamar on 1/5/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHCourse.h"

@implementation SCHCourse

-(id)init {
    return [self initWithCourseName:@"N/A" andAssignmentPortletUrl:nil andQuizPortletUrl:nil];
}

-(id)initWithCourseName:(NSString *)courseName
{
    self = [super init];
    if (self) {
        self = [self initWithCourseName:courseName andAssignmentPortletUrl:nil andQuizPortletUrl:nil];
    }
    return self;
}

-(id)initWithCourseName:(NSString *)courseName andAssignmentPortletUrl:(NSString *)assignmentPortletUrl andQuizPortletUrl:(NSString *)quizPortletUrl
{
    self = [super init];
    if (self) {
        [self setCourseName:courseName];
        [self setAssignmentPortletUrl:assignmentPortletUrl];
        [self setQuizPortletUrl:quizPortletUrl];
        self.tasks = [[NSMutableArray alloc] init];
    }
    return self;
}

//Adds a task to the course's internal task list. If a task is added that already exists in the task list
//(as defined by isEqual), it will replace the existing task object. Because task equality is calculated regardless
//of due date, this has the side-effect of updating a task's due date if an administrator decides to change it on Scholar
-(void)addTask:(SCHTask *)task
{
    for (int i = 0; i < [self.tasks count]; i++) {
        SCHTask *compareTask = (SCHTask *)[self.tasks objectAtIndex:i];
        if ([compareTask isEqual:task]) {
            [self.tasks replaceObjectAtIndex:i withObject:task];
            return;
        }
    }
    [self.tasks addObject:task];
}

@end