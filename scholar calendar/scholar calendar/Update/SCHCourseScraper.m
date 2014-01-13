//
//  SCHCourseScraper.m
//  scholar calendar
//
//  Created by Alex Lamar on 1/9/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHCourseScraper.h"
#import "TFHpple.h"
#import "SCHCourse.h"
#import "SCHAssignment.h"
#import "SCHQuiz.h"

@implementation SCHCourseScraper

static NSString * const LOG_IN_URL = @"https://auth.vt.edu/login?service=https%3A%2F%2Fscholar.vt.edu%2Fsakai-login-tool%2Fcontainer";

+(BOOL)retrieveCoursesIntoCourseList:(NSMutableArray *)courseList withUsername:(NSString *)username Password:(NSString *)password
{
    NSData *mainPage = [self logInToMainPageWithUsername:username Password:password];
    if (mainPage == nil) {
        //user failed to log in, going to need more robust error handling for this
        return false;
    }
    
    NSString *semester = [self getCurrentSemester];
    NSLog(@"Semseter: %@", semester);
    
    NSArray *retrievedCourses = [self retrieveCoursesFromMainPage:mainPage forSemester:semester];
    
    [self retrieveTasksIntoCourseList:retrievedCourses];
    [courseList removeAllObjects];
    [courseList addObjectsFromArray:retrievedCourses];
    return true;
} 

+(NSArray *)retrieveCoursesFromMainPage:(NSData *)mainPage forSemester:(NSString *)semester
{
    TFHpple *parser = [TFHpple hppleWithHTMLData:mainPage];
    NSArray *elements = [parser searchWithXPathQuery:@"//a[@id='addNewSiteLink']"];
    if (elements.count == 0) {
        NSLog(@"Failed to find course membership page");
        return nil;
    }
    NSString *membershipUrl = [[elements objectAtIndex:0] objectForKey:@"href"];
    NSLog(@"%@", membershipUrl);
    return [self retrieveCoursesFromMembershipPage:[self parseScholarUrl:membershipUrl] forSemester:semester];
}

+(NSArray *)retrieveCoursesFromMembershipPage:(NSData *)membershipPage forSemester:(NSString *)semester
{
    NSMutableArray *courseList = [NSMutableArray new];
    TFHpple *parser = [TFHpple hppleWithHTMLData:membershipPage];
    TFHppleElement *portletElement = [[parser searchWithXPathQuery:@"//div[@class='title']/a"] objectAtIndex:0];
    NSString *portletUrl = [portletElement objectForKey:@"href"];
    
    NSData *portletPage = [self parseScholarUrl:portletUrl];
    parser = [TFHpple hppleWithHTMLData:portletPage];
    NSArray *courseElements = [parser searchWithXPathQuery:@"//tr"];
    for (TFHppleElement *element in courseElements) {
        NSArray *semesterElements = [element searchWithXPathQuery:@"//td[@headers='term']"];
        if (semesterElements.count == 0) {
            continue;
        }
        NSString *courseSemester = [(TFHppleElement *)[semesterElements objectAtIndex:0] text];
        if ([courseSemester rangeOfString:semester].location == NSNotFound) {
            //course isn't associated with the current semester so we drop it
            continue;
        }
        NSArray *nameAndUrlElements = [element searchWithXPathQuery:@"//td[@headers='title']/h4/a"];
        if (nameAndUrlElements.count == 0) {
            continue;
        }
        TFHppleElement *nameAndUrlElement = [nameAndUrlElements objectAtIndex:0];
        NSString *name = [nameAndUrlElement text];
        NSString *url = [nameAndUrlElement objectForKey:@"href"];
        
        SCHCourse *course = [[SCHCourse alloc] initWithCourseName:name andMainUrl:url];
        [courseList addObject:course];
    }
    if (courseList.count == 0) {
        NSLog(@"Failed to find any courses for the semester");
    }
    return courseList;
}

+(void)retrieveTasksIntoCourseList:(NSArray *)courseList
{
    for (SCHCourse *course in courseList) {
        NSData *coursePage = [self parseScholarUrl:[course mainUrl]];
        TFHpple *parser = [TFHpple hppleWithHTMLData:coursePage];
        
        /* handle assignment retrieval */
        NSArray *assignmentElements = [parser searchWithXPathQuery:@"//a[@title='For posting, submitting and grading assignment(s) online']"];
        if (assignmentElements.count != 0) {
            NSString *assignmentUrl = [(TFHppleElement *)[assignmentElements objectAtIndex:0] objectForKey:@"href"];
            [self retrieveAssignmentsFromBaseUrl:assignmentUrl intoCourse:course];
        }
        
        /* handle quiz retrieval */
        NSArray *quizElements = [parser searchWithXPathQuery:@"//a[@title='For creating and taking online tests and quizzes']"];
        if (quizElements.count != 0) {
            NSString *quizUrl = [(TFHppleElement *)[quizElements objectAtIndex:0] objectForKey:@"href"];
            [self retrieveQuizzesFromBaseUrl:quizUrl intoCourse:course];
        }
    }
}

+(void)retrieveAssignmentsFromBaseUrl:(NSString *)baseUrl intoCourse:(SCHCourse *)course
{
    //The assignment page is split into two parts, the body page and the portlet page.
    //the portlet page holds the data we want, so we need the link to that and then we'll parse from there
    NSData *basePage = [self parseScholarUrl:baseUrl];
    TFHpple *parser = [TFHpple hppleWithHTMLData:basePage];
    
    NSArray *portletElements = [parser searchWithXPathQuery:@"//div[@class='title']/a"];
    if (portletElements.count != 0) {
        NSString *assignmentPortletUrl = [(TFHppleElement *)[portletElements objectAtIndex:0] objectForKey:@"href"];
        [course setAssignmentPortletUrl:assignmentPortletUrl];
        [self retrieveAssignmentsFromPortletUrl:assignmentPortletUrl intoCourse:course];
    }
}

+(void)retrieveAssignmentsFromPortletUrl:(NSString *)portletUrl intoCourse:(SCHCourse *)course
{
    NSData *portletPage = [self parseScholarUrl:portletUrl];
    TFHpple *parser = [TFHpple hppleWithHTMLData:portletPage];
    
    NSArray *titles = [parser searchWithXPathQuery:@"//td[@headers='title']/h4/a"];
    NSArray *dueDates = [parser searchWithXPathQuery:@"//td[@headers='dueDate']"];
    NSString *courseName = [course courseName];
    for (int i = 0; i < titles.count; i++) {
        NSString *title = [(TFHppleElement *)[titles objectAtIndex:i] text];
        NSString *dueDate = [(TFHppleElement *)[dueDates objectAtIndex:i] text];
        NSLog(@"Title: %@", title);
        NSLog(@"due date: %@", dueDate);
        SCHAssignment *assignment = [[SCHAssignment alloc] initWithTaskName:title andCourseName:courseName andDueDateString:dueDate];
        [course addTask:assignment];
    }
}

+(void)retrieveQuizzesFromBaseUrl:(NSString *)baseUrl intoCourse:(SCHCourse *)course
{
    //The quiz page is split into two parts, the body page and the portlet page.
    //the portlet page holds the data we want, so we need the link to that and then we'll parse from there
    NSData *basePage = [self parseScholarUrl:baseUrl];
    TFHpple *parser = [TFHpple hppleWithHTMLData:basePage];
    
    NSArray *portletElements = [parser searchWithXPathQuery:@"//div[@class='title']/a"];
    if (portletElements.count != 0) {
        NSString *quizPortletUrl = [(TFHppleElement *)[portletElements objectAtIndex:0] objectForKey:@"href"];
        [course setQuizPortletUrl:quizPortletUrl];
        [self retrieveQuizzesFromPortletUrl:quizPortletUrl intoCourse:course];
    }
}

+(void)retrieveQuizzesFromPortletUrl:(NSString *)portletUrl intoCourse:(SCHCourse *)course
{
    NSData *portletPage = [self parseScholarUrl:portletUrl];
    TFHpple *parser = [TFHpple hppleWithHTMLData:portletPage];
    
    NSArray *quizElements = [parser searchWithXPathQuery:@"//div[@class='tier2']"];
    if (quizElements.count == 0) {
        NSLog(@"Could not find any quizzes");
        return;
    }
    
    NSArray *quizData = [(TFHppleElement *)[quizElements objectAtIndex:0] searchWithXPathQuery:@"//td"];
    NSString *courseName = [course courseName];
    //data for each quiz comes in sets of 3, so we'll parse accordingly
    for (int i = 0; i < quizData.count; i = i + 3) {
        if (quizElements.count % 3 != 0) {
            //encountered uneven data sets, this is really bad and shouldn't happen, do some error handling
        }
        NSString *title = [[(TFHppleElement *)[quizData objectAtIndex:i] firstChild] text];
        NSString *dueDate = [(TFHppleElement *)[quizData objectAtIndex:(i + 2)] text];
        NSLog(@"Title: %@", title);
        NSLog(@"due date: %@", dueDate);
        
        SCHQuiz *quiz = [[SCHQuiz alloc] initWithTaskName:title andCourseName:courseName andDueDateString:dueDate];
        [course addTask:quiz];
    }
}

//Gets html from a page in scholar, on the procondition that the user has already logged in by calling logInToMainPage
+(NSData *)parseScholarUrl:(NSString *)url
{
    NSMutableURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                                    cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    
    return [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
}

+(NSData *)logInToMainPageWithUsername:(NSString *)username Password:(NSString *)password
{
    NSMutableURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:LOG_IN_URL]
                                                    cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    
    NSData *logInPage = [NSMutableData dataWithCapacity:0];
    
    logInPage = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    TFHpple *parser = [TFHpple hppleWithHTMLData:logInPage];
    
    NSArray *hiddenElements = [parser searchWithXPathQuery:@"//input[@type='hidden']"];
    if (hiddenElements.count == 0) {
        //If there are no hidden elements then we have already reached the main page because we logged in some time beforehand
        //if this is the case then just return the page.
        return logInPage;
    }
    

    TFHppleElement *ltElement = [hiddenElements objectAtIndex:0];
    
    NSString *ltValue = [ltElement objectForKey:@"value"];
    
    //the following post paramaters are all static except for the lt element and username/password
    NSString *postString = [[NSString alloc] initWithFormat:@"lt=%@&submit=_submit&_eventId=submit&execution=e1s1&username=%@&password=%@", ltValue, username, password];
    
    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:LOG_IN_URL]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[NSData dataWithBytes:[postString UTF8String] length:strlen([postString UTF8String])]];
    
    NSData *mainPage = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    NSString *mainPageString = [[NSString alloc] initWithData:mainPage encoding:NSUTF8StringEncoding];
    
    if ([mainPageString rangeOfString:@"\"loggedIn\": true"].location == NSNotFound) {
        //If this string is absent then the user failed to log in, TODO some error handling
        NSLog(@"user failed to log in");
        return nil;
    }
    NSLog(@"User logged in");
    
    

    return mainPage;
}

+(NSString *)getCurrentSemester
{
    NSDate *today = [[NSDate alloc] init];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:(NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:today];
    
    //first day of month is january == 1
    NSInteger month = [components month];
    month = (month + 5) % 12; //advances month by 5 so July is effectively month 0
    NSLog(@"Month: %d", month);
    if (month < 6) {
        //From July to December
        return [[NSString alloc] initWithFormat:@"Fall %d", [components year]];
    }
    else {
        //From Jaunuary to June
        return [[NSString alloc] initWithFormat:@"Spring %d", [components year]];
    }
}



@end
