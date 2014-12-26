//
//  SCHScholarWebViewController.m
//  scholar calendar
//
//  Created by Alex Lamar on 12/14/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHScholarWebViewController.h"
#import "SCHCourseScraper.h"

static const NSString* const PAGE_FETCH_FAILED = @"Failed to retrieve page from Scholar";

@interface SCHScholarWebViewController ()

@property BOOL isLoading;

@end

@implementation SCHScholarWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect rect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    CGRect bounds = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    //self.webView.frame = rect;
    //self.webView.bounds = bounds;
    //[self.webView sizeToFit];
    //self.webView.scalesPageToFit = YES;
    //self.webView.contentMode = UIViewContentModeScaleAspectFit;
    
    //UIView *subview = self.webView;
    /*
    [subview setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-0-[subview]-0-|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(subview)]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-0-[subview]-0-|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(subview)]];
    */
    self.webView.delegate = self;
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.taskUrl];
    if (self.authenticated) {
        //we can directly request the page
        [self.webView loadRequest:request];
        [NSTimer scheduledTimerWithTimeInterval:0.3
                                         target:self
                                       selector:@selector(loading:)
                                       userInfo:nil
                                        repeats:YES];
        self.isLoading = YES;
    }
    else {
        //need to log in to the main page first
        if (self.username == nil || self.password == nil) {
            self.label.text = @"Failed to load from Scholar";
            return;
        }
        [NSTimer scheduledTimerWithTimeInterval:0.3
                                         target:self
                                       selector:@selector(loading:)
                                       userInfo:nil
                                        repeats:YES];
        self.isLoading = YES;
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_async(queue, ^{
            NSError *error = nil;
            [SCHCourseScraper logInToMainPageWithUsername:self.username Password:self.password error:&error]; //synchronous
            
            dispatch_queue_t main_queue = dispatch_get_main_queue();
            dispatch_async(main_queue, ^{
                if (error != nil) {
                    [self failedToLoadWithError:error];
                    return;
                }
                [self.webView loadRequest:request];
            });
        });
        
    }
}



-(void)loading:(NSTimer*)timer
{
    static int dots = 0;
    if (self.isLoading) {
        dots = (dots + 1) % 3;
        NSString *string = @"";
        for (int i = 0; i < dots; i++) {
            string = [string stringByAppendingString:@"."];
        }
        string = [@"Loading" stringByAppendingString:string];
        self.label.text = string;
    }
    else {
        [timer invalidate];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)failedToLoadWithError:(NSError*)error
{
    self.authenticated = NO;
    self.isLoading = NO;
    self.webView.hidden = YES;
    self.label.text = PAGE_FETCH_FAILED;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    //int textFontSize = 100;
    //NSString *jsString = [[NSString alloc] initWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%d%%'",textFontSize];
    //[webView stringByEvaluatingJavaScriptFromString:jsString];
    self.webView.hidden = NO;
    self.authenticated = YES;
    self.isLoading = NO;
    self.label.text = self.task.courseName;
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
