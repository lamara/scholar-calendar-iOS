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
    NSMutableArray *tasksDueToday;
    NSMutableArray *tasksDueThisWeek;
    NSMutableArray *tasksDueNextWeek;
    NSMutableArray *tasksDueFarFromNow;
}

static const int NUM_SECTIONS = 4;

static const int SECTION_HEIGHT = 40;

static const int DUE_TODAY_SECTION = 0;
static const int DUE_THIS_WEEK_SECTION = 1;
static const int DUE_NEXT_WEEK_SECTION = 2;
static const int DUE_FAR_SECTION = 3;

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
    
    SCHCourse *engineeringCourse = [[SCHCourse alloc] initWithCourseName:@"EngE 1104"];
    
    [courses addObject:engineeringCourse];
    
    SCHTask *task1 = [[SCHTask alloc] initWithTaskName:@"Homework 1" andCourseName:@"EngE 1104" andDueDate:[NSDate date]];
    
    SCHTask *task2 = [[SCHTask alloc] initWithTaskName:@"Homework 2" andCourseName:@"EngE 1104" andDueDate:[NSDate dateWithTimeIntervalSinceNow:(3600 * 14)]];
    
    [engineeringCourse addTask:task1];
    [engineeringCourse addTask:task2];
    
    [tasksDueToday addObject:task1];
    [tasksDueThisWeek addObject:task2];
    
    //For whatever reason, declaring a footer of any kind will get rid of any rows that do not explicitly
    //contain data. We want this, so we are going to set the footer to an empty view.
    self.tableView.tableFooterView = [UIView new];
    
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    dispatch_async(queue, ^{
        NSLog(@"Doing some work");
        [SCHCourseScraper retrieveCoursesIntoCourseList:nil withUsername:nil Password:nil];
        dispatch_queue_t main_queue = dispatch_get_main_queue();
        dispatch_async(main_queue, ^{
            [self updateDidFinish];
        });
    });

    

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)updateDidFinish
{
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
            task = [tasksDueToday objectAtIndex:index];
            break;
    }
    
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"EEE, MMM d '\n' h:mm a"];
    
    NSString *formattedDueDate = [formatter stringFromDate:task.dueDate];
    
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
