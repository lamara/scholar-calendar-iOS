//
//  SCHTaskListViewController.h
//  scholar calendar
//
//  Created by Alex Lamar on 1/5/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCHTaskListViewController : UITableViewController

- (IBAction)unwindToList:(UIStoryboardSegue *)segue;

-(void)updateDidFinish;

-(void)updateFailedWithError:(NSInteger)result;


@end
