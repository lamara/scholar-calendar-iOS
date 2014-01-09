//
//  SCHCourseScraper.h
//  scholar calendar
//
//  Created by Alex Lamar on 1/9/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCHCourseScraper : NSObject

+(BOOL)retrieveCoursesIntoCourseList:(NSArray *)courseList withUsername:(NSString *)username Password:(NSString *)password;

@end
