//
//  SCHTaskListViewController.m
//  scholar calendar
//
//  Created by Alex Lamar on 1/5/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHTaskListViewController.h"
#import "SCHTaskViewCell.h"
#import "SCHCourseScraper.h"
#import "SCHTask.h"
#import "SCHCourse.h"
#import "SCHHeaderView.h"
#import "SCHHeaderDueTodayView.h"
#import "SCHHeaderDueThisWeekView.h"
#import "SCHHeaderDueNextWeekView.h"
#import "SCHHeaderDueFarView.h"

@interface SCHTaskListViewController ()

@end

@implementation SCHTaskListViewController {
    NSMutableArray *courses;
    NSArray *tasksDueToday;
    NSArray *tasksDueThisWeek;
    NSArray *tasksDueNextWeek;
    NSArray *tasksDueFarFromNow;
}

static const int NUM_SECTIONS = 4;

static const int SECTION_HEIGHT = 40;

static const int DUE_TODAY_SECTION = 0;
static const int DUE_THIS_WEEK_SECTION = 1;
static const int DUE_NEXT_WEEK_SECTION = 2;
static const int DUE_FAR_SECTION = 3;

static NSString * const COURSES_FILE = @"/courses";

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
    
    courses = [NSMutableArray new];
    tasksDueToday = [NSMutableArray new];
    tasksDueThisWeek = [NSMutableArray new];
    tasksDueNextWeek = [NSMutableArray new];
    tasksDueFarFromNow = [NSMutableArray new];
    
    [self.tableView setSeparatorColor:[UIColor colorWithRed:224/255.0 green:224/255.0 blue:224/255.0 alpha:1]];
    
    [self readDataFromStorage];
    [self loadTasksIntoSeparatedTaskLists];
    
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
    
    //course update block
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    dispatch_async(queue, ^{
        NSMutableArray *emptyCourseList = [NSMutableArray new];
        [SCHCourseScraper retrieveCoursesIntoCourseList:emptyCourseList withUsername:nil Password:nil];
        
        dispatch_queue_t main_queue = dispatch_get_main_queue();
        dispatch_async(main_queue, ^{
            [self updateDidFinishWithCourseList:emptyCourseList];
        });
    });
    
    

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    courses = courseListFromStorage;
    NSLog(@"%d", courses.count);
    for (SCHCourse *course in courses) {
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
    for (SCHCourse *course in courses) {
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

-(void)updateDidFinishWithCourseList:(NSMutableArray *)updatedCourseList
{
    [NSKeyedArchiver archiveRootObject:updatedCourseList toFile:[self pathForCourseFile]];
    courses = updatedCourseList;
    [self loadTasksIntoSeparatedTaskLists];
    [self.tableView reloadData];
    NSLog(@"Woo finished");
}

-(void)updateFailedWithError:(NSInteger)result
{
    NSLog(@"Update failed");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    
    cell.taskName.text = task.taskName;
    cell.courseName.text = task.courseName;
    cell.dueDate.text = formattedDueDate;
    
    
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
        default:
            return 0;
            break;
    }
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
