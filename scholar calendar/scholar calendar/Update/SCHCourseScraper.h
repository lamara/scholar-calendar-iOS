//
//  SCHCourseScraper.h
//  scholar calendar
//
//  Created by Alex Lamar on 1/9/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCHCourseScraper : NSObject

+(NSData *)logInToMainPageWithUsername:(NSString *)username Password:(NSString *)password;

+(BOOL)retrieveCoursesIntoCourseList:(NSArray *)courseList withUsername:(NSString *)username Password:(NSString *)password;

+(void)clearAllCookies;

@end
