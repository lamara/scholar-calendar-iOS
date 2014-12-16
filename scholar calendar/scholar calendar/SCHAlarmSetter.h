//
//  SCHAlarmSetter.h
//  scholar calendar
//
//  Created by Alex Lamar on 12/13/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCHAlarmSetter : NSObject

+(void)setAlarmsForCourseList:(NSArray *)courselist;

+(void)cancelAllAlarms;

@end
