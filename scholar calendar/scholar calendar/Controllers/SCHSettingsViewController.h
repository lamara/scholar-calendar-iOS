//
//  SCHSettingsViewController.h
//  scholar calendar
//
//  Created by Alex Lamar on 12/15/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCHSettingsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISwitch *alarmSwitch;

- (IBAction)alarmSwitchToggled:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *hoursField;
@property (weak, nonatomic) IBOutlet UILabel *hoursLabel;

@property (strong, nonatomic) NSArray *courses;


@end
