//
//  COInstallationWindowController.m
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

#import "COInstallationWindowController.h"
#import "COHomebrewInterface.h"
#import "COHomebrewManager.h"
#import "COStyle.h"
#import "COAppDelegate.h"

@interface COInstallationWindowController ()

@property (weak) IBOutlet NSTextField *windowTitleLabel;
@property (weak) IBOutlet NSTextField *formulaNameLabel;
@property (unsafe_unretained) IBOutlet NSTextView *recordTextView; //NSTextView does not support weak in ARC at all (not just 10.7)
@property (weak) IBOutlet NSButton *okButton;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

@property (nonatomic) COWindowOperation windowOperation;
@property (strong, nonatomic) NSArray *formulae;
@property (strong, nonatomic) NSArray *options;

@property BOOL operationStatus;
@property (nonatomic, copy) void (^completionBlock)(BOOL);

@end

@implementation COInstallationWindowController

+ (NSDictionary*)sharedTaskMessagesMap
{
	static NSDictionary *taskMessages = nil;
	
	if (!taskMessages)
	{
		taskMessages   = @{@(kCOWindowOperationInstall)		: NSLocalizedString(@"Installation_Window_Operation_Install", nil),
						   @(kCOWindowOperationUninstall)	: NSLocalizedString(@"Installation_Window_Operation_Uninstall", nil),
						   @(kCOWindowOperationUpgrade)		: NSLocalizedString(@"Installation_Window_Operation_Update", nil),
						   @(kCOWindowOperationTap)			: NSLocalizedString(@"Installation_Window_Operation_Tap", nil),
						   @(kCOWindowOperationUntap)		: NSLocalizedString(@"Installation_Window_Operation_Untap", nil),
						   @(kCOWindowOperationCleanup)		: NSLocalizedString(@"Installation_Window_Operation_Cleanup", nil)};
	}
	
	return taskMessages;
}

- (void)awakeFromNib
{
	[self setupUI];
}

- (void)setupUI
{
	NSDictionary *messagesMap = [self.class sharedTaskMessagesMap];
	NSFont *font = [COStyle defaultFixedWidthFont];
	
    self.recordTextView.font = font;
	self.windowTitleLabel.stringValue = messagesMap[@(self.windowOperation)] ?: @"";
	
	NSUInteger count = [self.formulae count];
	
	if (count >= 1)
	{
		NSString *formulaeNames = [[self namesOfAllFormulae] componentsJoinedByString:@", "];
		self.formulaNameLabel.stringValue = formulaeNames;
	}
	else {
		if (self.windowOperation != kCOWindowOperationCleanup)
		{
			self.formulaNameLabel.stringValue = NSLocalizedString(@"Installation_Window_All_Formulae", nil);
		}
		else
		{
			self.formulaNameLabel.stringValue = @"";
		}
	}
	
	[self setOperationStatus:NO];
}

+ (COInstallationWindowController *)runWithOperation:(COWindowOperation)windowOperation
											formulae:(NSArray *)formulae
											 options:(NSArray *)options
{
	return [self runWithOperation:windowOperation formulae:formulae options:options completion:nil];
}

+ (COInstallationWindowController *)runWithOperation:(COWindowOperation)windowOperation
											formulae:(NSArray *)formulae
											 options:(NSArray *)options
										  completion:(void (^)(BOOL))completionBlock
{
	COInstallationWindowController *operationWindowController;
	operationWindowController = [[COInstallationWindowController alloc] initWithWindowNibName:@"COInstallationWindow"];
	operationWindowController.windowOperation = windowOperation;
	operationWindowController.formulae = formulae;
	operationWindowController.options = options;
	operationWindowController.completionBlock = completionBlock;
    COAppDelegateRef.runningBackgroundTask = YES;
	
	
	NSWindow *operationWindow = operationWindowController.window;
	[[NSApp mainWindow] beginSheet:operationWindow completionHandler:^(NSModalResponse returnCode) {
		[operationWindowController cleanupAfterTask];
	}];
	[operationWindowController executeInstallation];
	
	return operationWindowController;
}

- (void)windowOperationSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	[sheet orderOut:self];
	[self cleanupAfterTask];
}

- (void)cleanupAfterTask
{
    COAppDelegateRef.runningBackgroundTask = NO;
	
	if (self.completionBlock)
	{
		self.completionBlock(self.operationStatus);
	}
}

- (NSArray*)namesOfAllFormulae
{
	return [self.formulae valueForKeyPath:@"@unionOfObjects.name"];
}

- (void)executeInstallation
{
    self.okButton.enabled = NO;
	[self.progressIndicator startAnimation:nil];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *standardOutput;
        
        switch (self.windowOperation) {
            case kCOWindowOperationInstall:
                standardOutput = [[COHomebrewInterface sharedInterface] installWithFormulaName:[[self.formulae firstObject] name] withOptions:self.options];
                break;
            case kCOWindowOperationUninstall:
                standardOutput = [[COHomebrewInterface sharedInterface] uninstallWithFormulaName:[[self.formulae firstObject] name]];
                break;
            case kCOWindowOperationUpgrade:
                if (self.formulae)
                {
                    standardOutput = [[COHomebrewInterface sharedInterface] upgradeWithFormulaeNames:[self namesOfAllFormulae]];
                }
                else
                {
                    //no parameter is necessary to upgrade all formulas; recycling API with empty string
                    standardOutput = [[COHomebrewInterface sharedInterface] upgradeWithFormulaeNames:@[@""]];
                }
                break;
            case kCOWindowOperationTap:
                if (self.formulae)
                {
                    standardOutput = [[COHomebrewInterface sharedInterface] tapWithRepositoryName:[[self.formulae firstObject] name]];
                }
                break;
            case kCOWindowOperationUntap:
                if (self.formulae)
                {
                    standardOutput = [[COHomebrewInterface sharedInterface] untapWithRepositoryName:[[self.formulae firstObject] name]];
                }
                break;
            case kCOWindowOperationCleanup:
                standardOutput = [[COHomebrewInterface sharedInterface] cleanup];
                break;
            default:
                goto end;
                break;
        }
        
        self.operationStatus = standardOutput;
        
        [self.recordTextView performSelectorOnMainThread:@selector(setString:)
                                              withObject:standardOutput
                                           waitUntilDone:YES];
		
    end:
		[self finishTask];
	});
}


- (void)finishTask
{
	dispatch_async(dispatch_get_main_queue(), ^(){
		[self.progressIndicator stopAnimation:nil];
        self.okButton.enabled = YES;
		
        [COAppDelegateRef requestUserAttentionWithMessageTitle:[NSLocalizedString(@"Homebrew_Task_Finished", nil) capitalizedString] andDescription:[NSString stringWithFormat:@"%@ %@", self.windowTitleLabel.stringValue, self.formulaNameLabel.stringValue]];
	});
}

- (IBAction)okAction:(id)sender
{
	self.recordTextView.string = @"";
	
	NSWindow *mainWindow = [NSApp mainWindow];
	
	if ([mainWindow respondsToSelector:@selector(endSheet:)])
	{
		[mainWindow endSheet:self.window];
	}
	else
	{
		[[NSApplication sharedApplication] endSheet:self.window];
	}
}

@end
