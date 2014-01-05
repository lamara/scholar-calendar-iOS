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
        [self setCourseName:courseName];
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
    }
    return self;
}

@end
