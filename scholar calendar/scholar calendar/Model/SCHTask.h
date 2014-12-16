//
//  SCHTask.h
//  scholar calendar
//
//  Created by Alex Lamar on 1/5/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCHTask : NSObject <NSCoding>

@property NSString *taskName;
@property NSString *courseName;
@property (copy) NSDate *dueDate;

@property NSURL *url;

@property UILocalNotification *notificaion;

@property BOOL shouldSetAlarm;




-(id)initWithTaskName:(NSString *)taskName andCourseName:(NSString *)courseName andDueDateString:(NSString *)dueDateString;

-(id)initWithTaskName:(NSString *)taskName andCourseName:(NSString *)courseName andDueDate:(NSDate *)dueDate;

-(NSComparisonResult)compare:(SCHTask *)object;

-(NSDate *)parseDueDateString:(NSString *)dueDateString;


 
@end
