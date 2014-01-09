//
//  SCHCourse.h
//  scholar calendar
//
//  Created by Alex Lamar on 1/5/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCHTask.h"

@interface SCHCourse : NSObject

@property NSString *courseName;

@property NSString *assignmentPortletUrl;

@property NSString *quizPortletUrl;

@property NSMutableArray *tasks;


-(id)initWithCourseName:(NSString *)courseName;

-(id)initWithCourseName:(NSString *)courseName andAssignmentPortletUrl:(NSString *)assignmentPortletUrl andQuizPortletUrl:(NSString *)quizPortletUrl;

-(void)addTask:(SCHTask *)task;

@end
