//
//  SCHTaskViewCell.m
//  scholar calendar
//
//  Created by Alex Lamar on 1/5/14.
//  Copyright (c) 2014 Alex Lamar. All rights reserved.
//

#import "SCHTaskViewCell.h"

@implementation SCHTaskViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


-(void)colorCell
{
    NSString *date = self.dueDate.text;
    if (date == nil) {
        return;
    }
    NSRange orangeRange;
    if ([date isEqualToString:@"N/A"]) {
        orangeRange.location = 0;
        orangeRange.length = 3;
    }
    else {
        NSArray *components = [date componentsSeparatedByString:@" "];
        orangeRange = [date rangeOfString:[components objectAtIndex:4]]; //Hardcoded at 4th word, dateformat isn't likely to change so not too big of an issue
        orangeRange.length = orangeRange.length + 3; //include AM/PM portion
    }
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:date];
    [attrString beginEditing];
    [attrString addAttribute: NSForegroundColorAttributeName
                       value:[UIColor orangeColor]
                       range:orangeRange];
    [attrString endEditing];
    if (self.dueDate == nil) {
        return;
    }
    self.dueDate.text = nil;
    self.dueDate.attributedText = attrString;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
        if ([keyPath isEqualToString:@"text"]) {
            [self colorCell];
            /*
            NSString *newDate = [change objectForKey:@"new"];
            NSString *oldDate = [change objectForKey:@"old"];
            NSString *date = newDate;
            if (date == [NSNull null]) {
                if (oldDate == [NSNull null]) {
                    return;
                }
                date = oldDate;
            }
            NSArray *components = [date componentsSeparatedByString:@" "];
            NSRange orangeRange = [date rangeOfString:[components objectAtIndex:4]]; //Hardcoded at 4th word, dateformat isn't likely to change so not too big of an issue
            orangeRange.length = orangeRange.length + 3; //include AM/PM portion
             NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:date];
            [attrString beginEditing];
            [attrString addAttribute: NSForegroundColorAttributeName
                               value:[UIColor orangeColor]
                               range:orangeRange];
            [attrString endEditing];
            if (self.dueDate == nil) {
                return;
            }
            self.dueDate.text = nil;
            self.dueDate.attributedText = attrString;
             */
        }
}

@end
