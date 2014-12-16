//
//  SCHSettingsViewController.m
//  scholar calendar
//
//  Created by Alex Lamar on 12/15/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHSettingsViewController.h"
#import "SCHAlarmSetter.h"

@interface SCHSettingsViewController ()

@end

@implementation SCHSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Hande defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"setAlarms"] == nil) {
        //set default value to "on" if it does not exist
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"setAlarms"];
        [defaults synchronize];
    }
    if ([defaults objectForKey:@"hours"] == nil) {
        //set default time to 12 hours
        [defaults setObject:[NSNumber numberWithInt:12] forKey:@"hours"];
        [defaults synchronize];
    }
    self.alarmSwitch.on = [[defaults objectForKey:@"setAlarms"] boolValue];
    self.hoursField.text = [NSString stringWithFormat:@"%d", [[defaults objectForKey:@"hours"] intValue]];
    [self alarmSwitchToggled:self.alarmSwitch];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)alarmSwitchToggled:(id)sender
{
    if (self.alarmSwitch.on) {
        [self.hoursField setEnabled:YES];
        [self.hoursLabel setEnabled:YES];
        if (self.courses != nil) {
            [SCHAlarmSetter setAlarmsForCourseList:self.courses];
        }
    }
    else {
        [self.hoursField setEnabled:NO];
        [self.hoursLabel setEnabled:NO];
        [SCHAlarmSetter cancelAllAlarms];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:self.alarmSwitch.on] forKey:@"setAlarms"];
    [defaults synchronize];
}
- (IBAction)hourseFieldEdited:(id)sender {
    int value = [[self.hoursField text] intValue];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:value] forKey:@"hours"];
    [defaults synchronize];
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
