//
//  SCHTaskListViewController.m
//  scholar calendar
//
//  Created by Alex Lamar on 1/5/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHTaskListViewController.h"
#import "SCHTaskViewController.h"
#import "SCHScholarWebViewController.h"
#import "SCHSettingsViewController.h"
#import "SCHTaskViewCell.h"
#import "SCHCourseScraper.h"
#import "SCHTask.h"
#import "SCHCourse.h"
#import "SCHHeaderView.h"
#import "SCHHeaderDueTodayView.h"
#import "SCHHeaderDueThisWeekView.h"
#import "SCHHeaderDueNextWeekView.h"
#import "SCHHeaderDueFarView.h"
#import "SCHAlarmSetter.h"

#import "AGPushNoteView.h"

@interface SCHTaskListViewController ()

@end

@implementation SCHTaskListViewController {
    NSMutableArray *_courses;
    NSArray *tasksDueToday;
    NSArray *tasksDueThisWeek;
    NSArray *tasksDueNextWeek;
    NSArray *tasksDueFarFromNow;

    NSString *_username;
    NSString *_password;
    
    UIBarButtonItem* logInButton;
    
    BOOL isLoggedIn;
    BOOL authenticated; //Cookies are set w/r/t scholar page
    BOOL loggingIn;
}

static const int NUM_SECTIONS = 5;

static const int SECTION_HEIGHT = 40;

static const int DUE_TODAY_SECTION = 0;
static const int DUE_THIS_WEEK_SECTION = 1;
static const int DUE_NEXT_WEEK_SECTION = 2;
static const int DUE_FAR_SECTION = 3;
static const int EMPTY_LIST_HEADER = 4;

static NSString * const LOG_IN_TEXT = @"Log in to Scholar";
static NSString * const LOG_IN_CREDENTIALS_FAILED_TEXT = @"Invalid username or password";
static NSString * const LOG_IN_NETWORK_FAILED_TEXT = @"Could not connect to Scholar";
static NSString * const LOG_OUT_TEXT = @"Log out of Scholar?";
static NSString * const NETWORK_FETCH_FAILED_TEXT = @"Update failed from Scholar";

static NSString * const COURSES_FILE = @"/courses";
static NSString * const USER_FILE = @"/userData";

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    
    [refreshControl addTarget:self action:@selector(refreshTriggered) forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl = refreshControl;
    
    
    _courses = [NSMutableArray new];
    tasksDueToday = [NSMutableArray new];
    tasksDueThisWeek = [NSMutableArray new];
    tasksDueNextWeek = [NSMutableArray new];
    tasksDueFarFromNow = [NSMutableArray new];
    
    [self.tableView setSeparatorColor:[UIColor colorWithRed:224/255.0 green:224/255.0 blue:224/255.0 alpha:1]];
    
    [self readDataFromStorage];
    [self loadTasksIntoSeparatedTaskLists];
    
    logInButton = [[UIBarButtonItem alloc] initWithTitle:@"Log in" style:UIBarButtonItemStylePlain
                                                                  target:self action:@selector(clickedLogInButton:)];
    
    self.navigationItem.rightBarButtonItem = logInButton;
    
    
    
    isLoggedIn = [self readUsernamePasswordFromStorage];
    if (isLoggedIn) {
        [logInButton setTitle:@"Log out"];
    }
    else {
        [self launchLoginDialog];
    }
    
    
    
    /*
    SCHCourse *engineeringCourse = [[SCHCourse alloc] initWithCourseName:@"EngE 1104" andMainUrl:nil];
    
    [courses addObject:engineeringCourse];
    
    SCHTask *task1 = [[SCHTask alloc] initWithTaskName:@"Homework 1" andCourseName:@"EngE 1104" andDueDate:[NSDate date]];
    
    SCHTask *task2 = [[SCHTask alloc] initWithTaskName:@"Homework 2" andCourseName:@"EngE 1104" andDueDate:[NSDate dateWithTimeIntervalSinceNow:(3600 * 14)]];
    
    [engineeringCourse addTask:task1];
    [engineeringCourse addTask:task2];
    
    [tasksDueToday addObject:task1];
    [tasksDueThisWeek addObject:task2];
     */
    
    
    //For whatever reason, declaring a footer of any kind will get rid of any rows that do not explicitly
    //contain data. We want this, so we are going to set the footer to an empty view.
    self.tableView.tableFooterView = [UIView new];
    

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)setLoggedIn
{
    isLoggedIn = true;
    [logInButton setTitle:@"Log out"];
}

-(void)setLoggedOut
{
    isLoggedIn = false;
    loggingIn = false;
    [logInButton setTitle:@"Log in"];
    [self saveUsername:nil andPassword:nil];
    
    [SCHCourseScraper clearAllCookies];
    authenticated = NO;
    
    NSMutableArray *emptyCourseList = [NSMutableArray new];
    [self updateDidFinishWithCourseList:emptyCourseList];
}

-(void)launchLoginDialog
{
    [self launchLoginDialogWithMessage:LOG_IN_TEXT];
}

-(void)launchLoginDialogWithMessage:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log in" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Enter", nil];
    alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [alert show];
}

-(void)launchLogoutDialog
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:LOG_OUT_TEXT delegate:self
                                          cancelButtonTitle:@"Cancel" otherButtonTitles:@"Enter", nil];
    [alert show];
}

-(void)refreshTriggered
{
    [self refreshTriggeredWithUsername:_username andPassword:_password];
}

-(void)refreshTriggeredWithUsername:(NSString*)username andPassword:(NSString*)password
{
    [self.tableView reloadData];
    [self.refreshControl beginRefreshing];
    //course update block
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    dispatch_async(queue, ^{
        NSError *error = nil;
        BOOL success = [SCHCourseScraper retrieveCoursesIntoCourseList:_courses withUsername:username Password:password error:&error]; //synchronous
        
        dispatch_queue_t main_queue = dispatch_get_main_queue();
        dispatch_async(main_queue, ^{
            if (success) {
                [self updateDidFinishWithCourseList:_courses];
                loggingIn = NO;
                [self setLoggedIn];
            }
            else {
                [self updateFailedWithError:error.code];
            }
            [self performSelector:@selector(stopRefresh)];
        });
    });
}

-(void)stopRefresh
{
    [self.refreshControl endRefreshing];
}

//Callback for when the user hits enter on the login dialog
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.message isEqualToString:LOG_OUT_TEXT]) {
        if (buttonIndex != 0) {
            //user wants to log out
            [self setLoggedOut];
        }
        return;
    }
    
    if (buttonIndex != 0) {
        loggingIn = YES;
        NSString *username = [alertView textFieldAtIndex:0].text;
        NSString *password = [alertView textFieldAtIndex:1].text;
        [self saveUsername:username andPassword:password];
        [self refreshTriggeredWithUsername:username andPassword:password];
        //[self setLoggedIn]; // we actually don't want to do this until we are confirmed logged in
    }
}

-(void)clickedLogInButton:(id)sender
{
    if (isLoggedIn) {
        [self launchLogoutDialog];
    }
    else {
        [self launchLoginDialog];
    }
    NSLog(@"Clicked");
}

-(BOOL)readUsernamePasswordFromStorage
{
    NSArray *userDataFromStorage = [NSKeyedUnarchiver unarchiveObjectWithFile:[self pathForUserFile]];
    if (![userDataFromStorage isKindOfClass:[NSArray class]]) {
        NSLog(@"username/password not stored as an array in storage, failed to retrieve data");
        return FALSE;
    }
    if (userDataFromStorage == nil || userDataFromStorage.count != 2) {
        //an empty array of count 0 is used to represent no user
        NSLog(@"username/password was not present in storage");
        return FALSE;
    }
    NSLog(@"username/password retrieved successfully from storage");
    _username = [userDataFromStorage objectAtIndex:0];
    _password = [userDataFromStorage objectAtIndex:1];
    return TRUE;
}


//Not sure if keyedarchiver is thread safe so call this from the main thread from now
-(void)readDataFromStorage
{
    NSMutableArray *courseListFromStorage = [NSKeyedUnarchiver unarchiveObjectWithFile:[self pathForCourseFile]];
    if (![courseListFromStorage isKindOfClass:[NSArray class]]) {
        NSLog(@"Course data not stored as an array in storage, failed to retrieve data");
        return;
    }
    if (courseListFromStorage == nil) {
        NSLog(@"Course list was not present in storage");
        return;
    }
    NSLog(@"Courses retrieved successfully from storage");
    _courses = courseListFromStorage;
    NSLog(@"%d", _courses.count);
    for (SCHCourse *course in _courses) {
        for (SCHTask *task in course.tasks) {
            NSLog(@"Taskname: %@    dueDate: %@", task.taskName, task.dueDate);
        }
    }
}

//Loads all of the tasks in the main courselist to their respective section arrays
-(void)loadTasksIntoSeparatedTaskLists
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *today = [[NSDate alloc] init];
    //NSDate *today = [[NSDate alloc] initWithTimeIntervalSinceNow:-2592000];
    NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit
                                                        | NSDayCalendarUnit | NSHourCalendarUnit | NSWeekdayCalendarUnit
                                                        | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:today];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    NSInteger day = [components day];
    NSInteger dayOfWeek = [components weekday];
    
    NSDate *beginOfToday = [calendar dateFromComponents:components];
    [components setDay:(day + 1)]; //set to tomorrow
    NSDate *beginOfTomorrow = [calendar dateFromComponents:components];
    [components setDay:(day - dayOfWeek + 9)]; //set to beginning of next week with some date math
    NSDate *beginOfNextWeek = [calendar dateFromComponents:components];
    [components setDay:(day - dayOfWeek + 16)]; //set to beginning of two weeks from now
    NSDate *beginOfTwoWeeksFromNow = [calendar dateFromComponents:components];
    
    
    
    NSMutableArray *allTasks = [NSMutableArray new];
    for (SCHCourse *course in _courses) {
        for (SCHTask *task in course.tasks) {
            [allTasks addObject:task];
        }
    }
    /*
    NSLog(@"Begin of today: %@     Begin of tomorrow: %@      Begin of next week: %@       begin of two weeks: %@", beginOfToday, beginOfTomorrow, beginOfNextWeek, beginOfTwoWeeksFromNow);
     */
    
    tasksDueToday = [allTasks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings)
    {
        NSDate *dueDate = [(SCHTask *)evaluatedObject dueDate];
        if ([beginOfToday compare:dueDate] == NSOrderedAscending && [dueDate compare:beginOfTomorrow] == NSOrderedAscending) {
            //lies between the two dates, so we'll stick it here
            return YES;
        }
        return NO;
    }]];
    tasksDueThisWeek = [allTasks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings)
    {
        NSDate *dueDate = [(SCHTask *)evaluatedObject dueDate];
        if ([beginOfTomorrow compare:dueDate] == NSOrderedAscending && [dueDate compare:beginOfNextWeek] == NSOrderedAscending) {
            //lies between tomorrow and next week, so we'll stick it here
            return YES;
        }
        return NO;
    }]];
    tasksDueNextWeek = [allTasks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings)
    {
        NSDate *dueDate = [(SCHTask *)evaluatedObject dueDate];
        if ([beginOfNextWeek compare:dueDate] == NSOrderedAscending && [dueDate compare:beginOfTwoWeeksFromNow] == NSOrderedAscending) {
            //lies between next week and the week after, so we'll stick it here
            return YES;
        }
        return NO;
    }]];
    tasksDueFarFromNow = [allTasks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings)
    {
        NSDate *dueDate = [(SCHTask *)evaluatedObject dueDate];
        //NSLog(@"due date: %@", dueDate);
        if ([dueDate compare:beginOfTwoWeeksFromNow] == NSOrderedDescending || dueDate == nil) {
            //is older than two weeks from now, so we'll stick it here
            return YES;
        }
        return NO;
    }]];
}

-(NSString *)pathForCourseFile
{
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *path = nil;
    if (pathArray.count != 0) {
        path = [pathArray objectAtIndex:0];
    }
    path = [path stringByAppendingString:COURSES_FILE];
    return path;
}

-(NSString *)pathForUserFile
{
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *path = nil;
    if (pathArray.count != 0) {
        path = [pathArray objectAtIndex:0];
    }
    path = [path stringByAppendingString:USER_FILE];
    return path;
}

//Returns true if given valid input, false if not
-(BOOL)saveUsername:(NSString *)username andPassword:(NSString *)password
{
    _username = username;
    _password = password;
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

-(void)updateDidFinishWithCourseList:(NSMutableArray *)updatedCourseList
{
    [NSKeyedArchiver archiveRootObject:updatedCourseList toFile:[self pathForCourseFile]];
    _courses = updatedCourseList;
    
    [SCHAlarmSetter setAlarmsForCourseList:updatedCourseList];
    
    authenticated = YES;
    
    [self loadTasksIntoSeparatedTaskLists];
    [self.tableView reloadData];
    NSLog(@"Woo finished");
}

-(void)updateFailedWithError:(NSInteger)result
{
    if (result == SCHErrorLogInFailed) {
        if (loggingIn) {
            [self launchLoginDialogWithMessage:LOG_IN_CREDENTIALS_FAILED_TEXT];
            loggingIn = false;
        }
        [self setLoggedOut];
    }
    if (result == SCHErrorNetworkFailed) {
        if (loggingIn) {
            [self launchLoginDialogWithMessage:LOG_IN_NETWORK_FAILED_TEXT];
            loggingIn = false;
            [self setLoggedOut];
        }
        else {
            if (isLoggedIn) {
                //Stay logged in, but report error
                [AGPushNoteView showWithNotificationMessage:NETWORK_FETCH_FAILED_TEXT];
            }
        }
    }
    NSLog(@"Update failed");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Segues

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *path = [self.tableView indexPathForSelectedRow];
    if (![segue.destinationViewController isKindOfClass:[SCHScholarWebViewController class]]) {
        SCHSettingsViewController *destination = ((UINavigationController*)segue.destinationViewController).topViewController;
        destination.courses = _courses;
        return;
    }
    SCHScholarWebViewController *destination = segue.destinationViewController;
    SCHTaskViewCell *cell = (SCHTaskViewCell *) [self.tableView cellForRowAtIndexPath:path];
    destination.taskUrl = cell.task.url;
    destination.username = _username;
    destination.password = _password;
    destination.task = cell.task;
    destination.authenticated = authenticated;
}

- (IBAction)unwindToList:(UIStoryboardSegue *)segue
{
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case DUE_TODAY_SECTION:
            return tasksDueToday.count;
            break;
        case DUE_THIS_WEEK_SECTION:
            return tasksDueThisWeek.count;
            break;
        case DUE_NEXT_WEEK_SECTION:
            return tasksDueNextWeek.count;
            break;
        case DUE_FAR_SECTION:
            return tasksDueFarFromNow.count;
            break;
        case EMPTY_LIST_HEADER:
            return 0;
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TaskCell";
    SCHTaskViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    int index = indexPath.row;
    int section = indexPath.section;
    
    SCHTask *task;
    switch (section) {
        case DUE_TODAY_SECTION:
            task = [tasksDueToday objectAtIndex:index];
            break;
        case DUE_THIS_WEEK_SECTION:
            task = [tasksDueThisWeek objectAtIndex:index];
            break;
        case DUE_NEXT_WEEK_SECTION:
            task = [tasksDueNextWeek objectAtIndex:index];
            break;
        case DUE_FAR_SECTION:
            task = [tasksDueFarFromNow objectAtIndex:index];
            break;
    }
    
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"EEE, MMM d '\n' h:mm a"];
    
    NSString *formattedDueDate = [formatter stringFromDate:task.dueDate];
    if (task.dueDate == nil) {
        formattedDueDate = @"N/A";
    }
    
    cell.task = task;
    cell.taskName.text = task.taskName;
    cell.courseName.text = task.courseName;
    cell.dueDate.text = formattedDueDate;
    
    //[cell.dueDate addObserver:cell forKeyPath:@"text" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    // Configure the cell...
    
    return cell;
}


-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SCHHeaderView *header;
    switch (section) {
        case DUE_TODAY_SECTION:
            header = [[SCHHeaderDueTodayView alloc] initWithFrame:tableView.frame];
            break;
        case DUE_THIS_WEEK_SECTION:
            header = [[SCHHeaderDueThisWeekView alloc] initWithFrame:tableView.frame];
            break;
        case DUE_NEXT_WEEK_SECTION:
            header = [[SCHHeaderDueNextWeekView alloc] initWithFrame:tableView.frame];
            break;
        case DUE_FAR_SECTION:
            header = [[SCHHeaderDueFarView alloc] initWithFrame:tableView.frame];
            break;
        case EMPTY_LIST_HEADER:
            header = [[SCHHeaderView alloc] initWithFrame:tableView.frame];
            if (loggingIn) {
                [header setText:@"Logging in..."];
            }
            else if (!isLoggedIn) {
                [header setText:@"Not logged in"];
            }
            else {
                [header setText:@"No assignments due"];
            }
            break;
        default:
            header = [[SCHHeaderView alloc] initWithFrame:tableView.frame];
            break;
    }
    return header;
}


//It is important to set empty sections to have zero height so there is no empty space in between cells
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case DUE_TODAY_SECTION:
            if (tasksDueToday.count == 0) {
                return 0;
            }
            else {
                return SECTION_HEIGHT;
            }
            break;
        case DUE_THIS_WEEK_SECTION:
            if (tasksDueThisWeek.count == 0) {
                return 0;
            }
            else {
                return SECTION_HEIGHT;
            }
            break;
        case DUE_NEXT_WEEK_SECTION:
            if (tasksDueNextWeek.count == 0) {
                return 0;
            }
            else {
                return SECTION_HEIGHT;
            }
            break;
        case DUE_FAR_SECTION:
            if (tasksDueFarFromNow.count == 0) {
                return 0;
            }
            else {
                return SECTION_HEIGHT;
            }
            break;
        case EMPTY_LIST_HEADER:
            if ([self p_noTasksDue]) {
                return SECTION_HEIGHT;
            }
            else {
                return 0;
            }
        default:
            return 0;
            break;
    }
}


-(BOOL)p_noTasksDue
{
    return tasksDueToday.count == 0 && tasksDueThisWeek.count == 0 && tasksDueNextWeek.count == 0 && tasksDueFarFromNow.count == 0;
}

/*
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case DUE_TODAY_SECTION:
            return @"Due today";
            break;
        case DUE_THIS_WEEK_SECTION:
            return nil;
            break;
        case DUE_NEXT_WEEK_SECTION:
            return nil;
            break;
        case DUE_FAR_SECTION:
            return @"Due a while from now";
            break;
        default:
            return @"";
            break;
    }
}
*/


-(UIView *)emptySection
{
    static UIView *emptySection = nil;
    if (emptySection == nil) {
        emptySection = [[UILabel alloc] initWithFrame:CGRectZero];
        emptySection.backgroundColor = [UIColor clearColor];
    }
    return emptySection;
}

# pragma mark - Setting/Removing Observers
- (void)tableView:(UITableView *)tableView willDisplayCell:(SCHTaskViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell.dueDate addObserver:cell forKeyPath:@"text" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    [cell colorCell];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCHTaskViewCell *taskCell = (SCHTaskViewCell*) cell;
    @try {
        [taskCell.dueDate removeObserver:cell forKeyPath:@"text"];
    }
    @catch(id anException) {
        //no observer attached, do nothing
    }
    @finally {
        
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    for (SCHTaskViewCell *cell in self.tableView.visibleCells) {
        @try {
            [cell.dueDate removeObserver:cell forKeyPath:@"text"];
        }
        @catch(id anException) {
            //no observer attached, do nothing
        }
        @finally {
            
        }
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
