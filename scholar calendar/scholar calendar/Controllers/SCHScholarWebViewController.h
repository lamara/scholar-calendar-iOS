//
//  SCHScholarWebViewController.h
//  scholar calendar
//
//  Created by Alex Lamar on 12/14/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHTask.h"

@interface SCHScholarWebViewController : UIViewController <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (weak, nonatomic) IBOutlet UILabel *label;

@property SCHTask *task;

@property NSURL *taskUrl;

@property NSString *username;
@property NSString *password;

@property BOOL authenticated;

@end
