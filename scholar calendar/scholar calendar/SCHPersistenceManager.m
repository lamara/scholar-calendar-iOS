//
//  SCHPersistenceManager.m
//  scholar calendar
//
//  Created by Alexander Ali Lamar on 2/18/15.
//  Copyright (c) 2015 Alex Lamar. All rights reserved.
//

#import "SCHPersistenceManager.h"
#import "SCHTask.h"
#import "SCHCourse.h"

@implementation SCHPersistenceManager

static NSString * const COURSES_FILE = @"/courses";
static NSString * const USER_FILE = @"/userData";

#pragma mark Read

+(NSMutableArray*)readDataFromStorage
{
    NSMutableArray *courseListFromStorage = [NSKeyedUnarchiver unarchiveObjectWithFile:[self pathForCourseFile]];
    if (![courseListFromStorage isKindOfClass:[NSArray class]]) {
        NSLog(@"Course data not stored as an array in storage, failed to retrieve data");
        return nil;
    }
    if (courseListFromStorage == nil) {
        NSLog(@"Course list was not present in storage");
        return nil;
    }
    NSLog(@"Courses retrieved successfully from storage");
    for (SCHCourse *course in courseListFromStorage) {
        for (SCHTask *task in course.tasks) {
            NSLog(@"Taskname: %@    dueDate: %@", task.taskName, task.dueDate);
        }
    }
    
    return courseListFromStorage;
}

+(NSArray*)readUsernamePasswordFromStorage
{
    NSArray *userDataFromStorage = [NSKeyedUnarchiver unarchiveObjectWithFile:[self pathForUserFile]];
    if (![userDataFromStorage isKindOfClass:[NSArray class]]) {
        NSLog(@"username/password not stored as an array in storage, failed to retrieve data");
        return nil;
    }
    if (userDataFromStorage == nil || userDataFromStorage.count != 2) {
        //an empty array of count 0 is used to represent no user
        NSLog(@"username/password was not present in storage");
        return nil;
    }
    NSLog(@"username/password retrieved successfully from storage");
    return userDataFromStorage;
}

#pragma mark Write

//Returns true if given valid input, false if not
+(BOOL)saveUsername:(NSString *)username andPassword:(NSString *)password
{
    if (username == nil || password == nil) {
        //archive an empty array
        [NSKeyedArchiver archiveRootObject:[NSArray new] toFile:[self pathForUserFile]];
        NSLog(@"nil username/password, not saved");
        return FALSE;
    }
    if (username.length == 0 || password.length == 0) {
        [NSKeyedArchiver archiveRootObject:[NSArray new] toFile:[self pathForUserFile]];
        NSLog(@"password/username length 0, not saved");
        return FALSE;
    }
    NSArray *usernamePasswordData = [[NSArray alloc] initWithObjects:username, password, nil];
    [NSKeyedArchiver archiveRootObject:usernamePasswordData toFile:[self pathForUserFile]];
    NSLog(@"password saved");
    return TRUE;
}

+(void)saveCoursesToStorage:(NSMutableArray*)updatedCourseList
{
    [NSKeyedArchiver archiveRootObject:updatedCourseList toFile:[self pathForCourseFile]];
}
#pragma mark Paths

+(NSString *)pathForCourseFile
{
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *path = nil;
    if (pathArray.count != 0) {
        path = [pathArray objectAtIndex:0];
    }
    path = [path stringByAppendingString:COURSES_FILE];
    return path;
}

+(NSString *)pathForUserFile
{
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *path = nil;
    if (pathArray.count != 0) {
        path = [pathArray objectAtIndex:0];
    }
    path = [path stringByAppendingString:USER_FILE];
    return path;
}

@end
