//
//  SCHAlarmSetter.m
//  scholar calendar
//
//  Created by Alex Lamar on 12/13/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHAlarmSetter.h"
#import "SCHCourse.h"
#import "SCHTask.h"


@implementation SCHAlarmSetter

+(void)setAlarmsForCourseList:(NSArray *)courselist
{
    [self cancelAllAlarms];
    
    //Get alarm offset from settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"hours"] == nil) {
        //Setting might have not been set yet, if so we default to 12
        [defaults setObject:[NSNumber numberWithInt:12] forKey:@"hours"];
        [defaults synchronize];
    }
    int alarmOffset = [[defaults objectForKey:@"hours"] intValue] * 3600; //conversion to seconds
    
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"h:mm a, MMM. dd"];
    for (SCHCourse *course in courselist) {
        for (SCHTask *task in course.tasks) {
            if (task.shouldSetAlarm) {
                if ([task.dueDate compare:[NSDate date]] == NSOrderedAscending) {
                    //The due date has already passed
                    continue;
                }
                NSString *stringFromDate = [dateFormatter stringFromDate:task.dueDate];
                
                UILocalNotification *notification = [[UILocalNotification alloc] init];
                NSDate *fireDate = [task.dueDate dateByAddingTimeInterval:-alarmOffset];
                notification.fireDate = fireDate;
                notification.alertBody = [NSString stringWithFormat:@"%@ is due at %@", task.taskName, stringFromDate];
                notification.soundName = UILocalNotificationDefaultSoundName;
                notification.applicationIconBadgeNumber = 1; //setting to 1 so the user atleast gets some feedback,
                                                             //we can't do anything more complex because we won't know what
                                                             //the badge count will be in the future (so can't increment, etc)
                [[UIApplication sharedApplication] scheduleLocalNotification:notification];
                
                task.notificaion = notification;
                NSLog(@"Alarm scheduled for %@", task.taskName);
                
                break;
            }
        }
    }
}
+(void)cancelAllAlarms
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    NSLog(@"ALl alarms cancelled");
}

@end
