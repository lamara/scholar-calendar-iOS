//
//  SCHTaskViewController.m
//  scholar calendar
//
//  Created by Alex Lamar on 12/13/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHTaskViewController.h"

#import "SCHScholarWebViewController.h"

@interface SCHTaskViewController ()

@end

@implementation SCHTaskViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%@", self.selectedTask);
    self.taskName.text = self.selectedTask.taskName;
    
    self.className.text = self.selectedTask.courseName;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"h:mm a, MMM. dd"];
    
    self.dueDate.text = [dateFormatter stringFromDate:self.selectedTask.dueDate];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Segues

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    SCHScholarWebViewController *destination = segue.destinationViewController;
    destination.taskUrl = self.selectedTask.url;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
