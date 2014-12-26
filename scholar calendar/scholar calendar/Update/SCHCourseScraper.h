//
//  SCHCourseScraper.h
//  scholar calendar
//
//  Created by Alex Lamar on 1/9/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SCHError) {
    SCHErrorNetworkFailed,
    SCHErrorLogInFailed
};

@interface SCHCourseScraper : NSObject

+(NSData *)logInToMainPageWithUsername:(NSString *)username Password:(NSString *)password error:(NSError**)error;

+(BOOL)retrieveCoursesIntoCourseList:(NSArray *)courseList withUsername:(NSString *)username Password:(NSString *)password error:(NSError**)error;

+(void)clearAllCookies;

@end
