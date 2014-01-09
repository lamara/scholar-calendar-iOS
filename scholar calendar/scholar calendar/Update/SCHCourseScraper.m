//
//  SCHCourseScraper.m
//  scholar calendar
//
//  Created by Alex Lamar on 1/9/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHCourseScraper.h"
#import "TFHpple.h"

@implementation SCHCourseScraper

static NSString * const LOG_IN_URL = @"https://auth.vt.edu/login?service=https%3A%2F%2Fscholar.vt.edu%2Fsakai-login-tool%2Fcontainer";
+(BOOL)retrieveCoursesIntoCourseList:(NSArray *)courseList withUsername:(NSString *)username Password:(NSString *)password
{
    NSMutableURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:LOG_IN_URL]
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    
    NSData *receivedData = [NSMutableData dataWithCapacity:0];
    
    receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    NSString *string = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", string);
    return true;
}




@end
