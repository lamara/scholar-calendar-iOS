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

@property NSString *mainUrl;

@property NSString *assignmentPortletUrl;

@property NSString *quizPortletUrl;

@property NSMutableArray *tasks;


-(id)initWithCourseName:(NSString *)courseName andMainUrl:(NSString *)mainUrl;

-(id)initWithCourseName:(NSString *)courseName andMainUrl:(NSString *)mainUrl
                        andAssignmentPortletUrl:(NSString *)assignmentPortletUrl andQuizPortletUrl:(NSString *)quizPortletUrl;

-(void)addTask:(SCHTask *)task;

@end
