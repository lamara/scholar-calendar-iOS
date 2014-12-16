//
//  SCHTaskViewController.h
//  scholar calendar
//
//  Created by Alex Lamar on 12/13/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SCHTask.h"

@interface SCHTaskViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *taskName;
@property (weak, nonatomic) IBOutlet UILabel *className;
@property (weak, nonatomic) IBOutlet UILabel *dueDate;

@property (strong, nonatomic) SCHTask *selectedTask;

@end
