//
//  SCHTaskViewCell.h
//  scholar calendar
//
//  Created by Alex Lamar on 1/5/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHTask.h"

@interface SCHTaskViewCell : UITableViewCell

@property (weak, nonatomic) SCHTask *task;

-(void)colorCell;

@property (weak, nonatomic) IBOutlet UILabel *taskName;
@property (weak, nonatomic) IBOutlet UILabel *courseName;
@property (weak, nonatomic) IBOutlet UILabel *dueDate;

@end
