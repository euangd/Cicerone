//
//  COUpdateViewController.m
//  Bruh
//
//  Created by Marek Hrusovsky on 21/08/14.
//	Copyright (c) 2014 Bruno Philipe. All rights reserved.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program.	If not, see <http://www.gnu.org/licenses/>.
//

#import "COUpdateViewController.h"
#import "COHomebrewInterface.h"
#import "COStyle.h"
#import "COAppDelegate.h"

@interface COUpdateViewController ()

@property (unsafe_unretained, nonatomic) IBOutlet NSTextView *updateTextView;
@property (weak, nonatomic) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) BOOL isPerformingUpdate;

@end

@implementation COUpdateViewController

- (void)awakeFromNib {
    self.updateTextView.font = [COStyle defaultFixedWidthFont];
	self.isPerformingUpdate = NO;
}

- (NSString *)nibName {
	return @"COUpdateView";
}

- (IBAction)runStopUpdate:(id)sender {
	COAppDelegate *appDelegate = COAppDelegateRef;
	
	if (appDelegate.isRunningBackgroundTask)
	{
		[appDelegate displayBackgroundWarning];
		return;
	}
    appDelegate.runningBackgroundTask = YES;
	
    self.updateTextView.string = @"";
	self.isPerformingUpdate = YES;
	[self.progressIndicator startAnimation:sender];
    self.homebrewViewController.lock = YES;
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *standardOutput = [[COHomebrewInterface sharedInterface] update]; // eventually sets self.homebrewViewController.loading = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.updateTextView.string = [self.updateTextView.string stringByAppendingString:standardOutput];
        });

		dispatch_async(dispatch_get_main_queue(), ^{
			[self.progressIndicator stopAnimation:sender];
			self.isPerformingUpdate = NO;
            appDelegate.runningBackgroundTask = NO;
			
			[COAppDelegateRef requestUserAttentionWithMessageTitle:[NSLocalizedString(@"Homebrew_Task_Finished", nil) capitalizedString] andDescription:NSLocalizedString(@"Notification_Update", nil)];
		});
	});
}

- (IBAction)clearLogUpdate:(id)sender {
	self.updateTextView.string = @"";
}

@end
