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

+(BOOL)retrieveCoursesIntoCourseList:(NSMutableArray *)courseList withUsername:(NSString *)username Password:(NSString *)password error:(NSError**)error
{
    *error = nil;
    
    if ([username isEqualToString:@"student"] && [password isEqualToString:@"stpassWD"]) {
        sleep(1);
        
        [self loadDefaultIntoCourseList:courseList];
        
        return YES;
    }
    
    NSData *mainPage = [self logInToMainPageWithUsername:username Password:password error:error];
    if (mainPage == nil) {
        //Failed to log in, check error code for details
        return false;
    }
    
    NSString *semester = [self getCurrentSemester];
    NSLog(@"Semseter: %@", semester);
    
    NSArray *retrievedCourses = [self retrieveCoursesFromMainPage:mainPage forSemester:semester intoCourseList:courseList];
    
    [self retrieveTasksIntoCourseList:retrievedCourses];
    [courseList removeAllObjects];
    [courseList addObjectsFromArray:retrievedCourses];
    
    [self clearAllCookies];
    
    return true;
} 

+(NSArray *)retrieveCoursesFromMainPage:(NSData *)mainPage forSemester:(NSString *)semester intoCourseList:(NSArray*)courseList
{
    TFHpple *parser = [TFHpple hppleWithHTMLData:mainPage];
    NSArray *elements = [parser searchWithXPathQuery:@"//a[@id='addNewSiteLink']"];
    if (elements.count == 0) {
        NSLog(@"Failed to find course membership page");
        return nil;
    }
    NSString *membershipUrl = [[elements objectAtIndex:0] objectForKey:@"href"];
    NSLog(@"%@", membershipUrl);
    return [self retrieveCoursesFromMembershipPage:[self parseScholarUrl:membershipUrl] forSemester:semester intoCourseList:courseList];
}

+(NSArray *)retrieveCoursesFromMembershipPage:(NSData *)membershipPage forSemester:(NSString *)semester intoCourseList:(NSArray*)courseList
{
    NSMutableArray *courses;
    if (courseList == nil) {
        courses = [NSMutableArray new];
    }
    else {
        courses = [NSMutableArray arrayWithArray:courseList];
    }
    TFHpple *parser = [TFHpple hppleWithHTMLData:membershipPage];
    TFHppleElement *portletElement = [[parser searchWithXPathQuery:@"//div[@class='title']/a"] objectAtIndex:0];
    NSString *portletUrl = [portletElement objectForKey:@"href"];
    
    NSData *portletPage = [self parseScholarUrl:portletUrl];
    
    //Need to change the page size, by default it limits the results to 20 (so if there are more than 20 courses they will get cut off)

    parser = [TFHpple hppleWithHTMLData:portletPage];
    
    TFHppleElement *pageSizeElement = [[parser searchWithXPathQuery:@"//form[@name='pagesizeForm']"] objectAtIndex:0];
    TFHppleElement *tokenElement = [[pageSizeElement searchWithXPathQuery:@"//input[@name='sakai_csrf_token']"] objectAtIndex:0];
    
    NSString *pageSizeActionUrl = [pageSizeElement objectForKey:@"action"];
    NSString *token = [tokenElement objectForKey:@"value"];

    NSString *postString = [[NSString alloc] initWithFormat:@"eventSubmit_doChange_pagesize=changepagesize&selectPageSize=200&sakai_csrf_token=%@", token];
    
    portletPage = [self sendPostRequestForUrl:pageSizeActionUrl andPostString:postString]; //new page with the increased page size
    
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
        name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSString *url = [nameAndUrlElement objectForKey:@"href"];
        
        SCHCourse *course = [[SCHCourse alloc] initWithCourseName:name andMainUrl:url];
        if (![courses containsObject:course]) {
            [courses addObject:course];
        }
    }
    if (courses.count == 0) {
        NSLog(@"Failed to find any courses for the semester");
    }
    return courses;
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
        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSString *urlString = [(TFHppleElement *)[titles objectAtIndex:i] objectForKey:@"href"];
        NSURL *url = [[NSURL alloc] initWithString:urlString];
        NSLog(@"URL STRING: %@", urlString);
        
        NSString *dueDate = [(TFHppleElement *)[dueDates objectAtIndex:i] text];
        dueDate = [dueDate stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSLog(@"Title: %@", title);
        NSLog(@"due date: %@", dueDate);
        SCHAssignment *assignment = [[SCHAssignment alloc] initWithTaskName:title andCourseName:courseName andDueDateString:dueDate];
        assignment.url = url;
        [course addTask:assignment]; //addTask: handles duplicate cases (refer to its method comments)
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
        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        //There aren't individual quiz links (they are just javascript calls) so we just link to the overall portlet page
        //(which encompases all of the quizes, but is still good enough)
        NSURL *url = [[NSURL alloc] initWithString:portletUrl];
        
        NSString *dueDate = [(TFHppleElement *)[quizData objectAtIndex:(i + 2)] text];
        dueDate = [dueDate stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSLog(@"Title: %@", title);
        NSLog(@"due date: %@", dueDate);
        
        SCHQuiz *quiz = [[SCHQuiz alloc] initWithTaskName:title andCourseName:courseName andDueDateString:dueDate];
        quiz.url = url;
        [course addTask:quiz]; //addTask: handles duplicate cases (refer to method comments)
    }
}

//Gets html from a page in scholar, on the procondition that the user has already logged in by calling logInToMainPage
+(NSData *)parseScholarUrl:(NSString *)url
{
    NSMutableURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                                    cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    
    return [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
}

+(NSString*)encodeToPercentEscapeString:(NSString*)string {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                            (CFStringRef) string,
                                            NULL,
                                            (CFStringRef) @"!*'();:@+$,/?%#[]",//@"!+$/?%#[]",
                                            kCFStringEncodingUTF8));
}

+(NSData *)logInToMainPageWithUsername:(NSString *)username Password:(NSString *)password error:(NSError**)error
{
    NSMutableURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:LOG_IN_URL]
                                                    cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    
    
    NSData *logInPage = [NSMutableData dataWithCapacity:0];
    
    logInPage = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:error];
    
    if (logInPage == nil) {
        //Failed to retrieve data from the server due to a network error
        *error = [self createErrorForCode:SCHErrorNetworkFailed];
        return nil;
    }
    
    TFHpple *parser = [TFHpple hppleWithHTMLData:logInPage];
    
    NSArray *hiddenElements = [parser searchWithXPathQuery:@"//input[@type='hidden']"];
    if (hiddenElements.count == 0) {
        //If there are no hidden elements then we have already reached the main page because we logged in some time beforehand
        //if this is the case then just return the page.
        *error = nil;
        return logInPage;
    }
    

    TFHppleElement *ltElement = [hiddenElements objectAtIndex:0];
    //The lt and execution values are generated for each session and are used as hidden fields in post, but we can grab them
    //from the source and put them in our post string
    NSString *ltValue = [ltElement objectForKey:@"value"];
    
    TFHppleElement *executionElement = [hiddenElements objectAtIndex:1];
    NSString *executionValue = [executionElement objectForKey:@"value"];
    
    //the following post paramaters are all static except for the lt element, execution element and username/password
    NSString *postString = [[NSString alloc] initWithFormat:@"lt=%@&submit=_submit&_eventId=submit&execution=%@&username=%@&password=%@", ltValue, executionValue, username, password];
    
    /*
    NSString *encodedPostString = [self encodeToPercentEscapeString:postString];//[postString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:LOG_IN_URL]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[NSData dataWithBytes:[encodedPostString UTF8String] length:strlen([encodedPostString UTF8String])]];
    
    NSData *mainPage = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    */
    
    NSData *mainPage = [self sendPostRequestForUrl:LOG_IN_URL andPostString:postString];
    
    NSString *mainPageString = [[NSString alloc] initWithData:mainPage encoding:NSUTF8StringEncoding];
    
    if ([mainPageString rangeOfString:@"\"loggedIn\": true"].location == NSNotFound) {
        //If this string is absent then the user failed to log in
        NSLog(@"user failed to log in");
        *error = [self createErrorForCode:SCHErrorLogInFailed];
        return nil;
    }
    NSLog(@"User logged in");
    
    

    return mainPage;
}

+(NSData*)sendPostRequestForUrl:(NSString*)url andPostString:(NSString*)post
{
    NSString *encodedPostString = [self encodeToPercentEscapeString:post];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[NSData dataWithBytes:[encodedPostString UTF8String] length:strlen([encodedPostString UTF8String])]];
    
    return [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
}

+(NSError*)createErrorForCode:(NSInteger)code
{
    NSString *appId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSError *error = [[NSError alloc] initWithDomain:appId code:code userInfo:nil];
    return error;
}

+(void)clearAllCookies
{
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *each in cookieStorage.cookies) {
        [cookieStorage deleteCookie:each];
    }
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



+(void)loadDefaultIntoCourseList:(NSMutableArray *)courseList
{
    [courseList removeAllObjects];
    
    SCHCourse *course1 = [[SCHCourse alloc] initWithCourseName:@"EngE 1104" andMainUrl:nil];
    SCHCourse *course2 = [[SCHCourse alloc] initWithCourseName:@"ENGL 1246" andMainUrl:nil];
    [courseList addObject:course1];
    [courseList addObject:course2];
    
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:GregorianCalendar];
    NSDateComponents *components = [calendar components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:date];
    
    NSDate *today = [[[NSCalendar alloc] initWithCalendarIdentifier:GregorianCalendar] dateFromComponents:components];
    NSDate *laterToday = [today dateByAddingTimeInterval:57600];
    
    SCHTask *task1 = [[SCHTask alloc] initWithTaskName:@"Homework 1" andCourseName:@"EngE 1104" andDueDate:[laterToday dateByAddingTimeInterval:(86400)]];
    
    SCHTask *task2 = [[SCHTask alloc] initWithTaskName:@"Homework 2" andCourseName:@"EngE 1104" andDueDate:[laterToday dateByAddingTimeInterval:(86400 * 10)]];
    
    SCHTask *task3 = [[SCHTask alloc] initWithTaskName:@"Writing assignment" andCourseName:@"ENGL 1246" andDueDate:[laterToday dateByAddingTimeInterval:(86400 * 4)]];//[NSDate dateWithTimeIntervalSinceNow:(3600 * 5)]];
    
    [course1 addTask:task1];
    [course1 addTask:task2];
    [course2 addTask:task3];
}




@end
