//
//  SCHPersistenceManager.h
//  scholar calendar
//
//  Created by Alexander Ali Lamar on 2/18/15.
//  Copyright (c) 2015 Alex Lamar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCHPersistenceManager : NSObject

+(void)saveCoursesToStorage:(NSMutableArray*)updatedCourseList;
+(BOOL)saveUsername:(NSString *)username andPassword:(NSString *)password;

+(NSArray*)readUsernamePasswordFromStorage;
+(NSMutableArray*)readDataFromStorage;

@end
