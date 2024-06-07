//
//  COFormulaPopoverViewController.m
//  Bruh
//
//  Created by Marek Hrusovsky on 05/09/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import "COFormulaPopoverViewController.h"
#import "COFormula.h"
#import "COHomebrewInterface.h"
#import "BPTimedDispatch.h"
#import "COStyle.h"

@interface COFormulaPopoverViewController ()

@property (strong) BPTimedDispatch *timedDispatch;

@end

@implementation COFormulaPopoverViewController

- (void)awakeFromNib
{
	NSFont *font = [COStyle defaultFixedWidthFont];
	[self.formulaTextView setFont:font];
	[self.formulaTextView setTextColor:[COStyle popoverTextViewColor]];
	[self.formulaPopover setContentViewController:self];
	[self setTimedDispatch:[BPTimedDispatch new]];
	[self.formulaTitleLabel setTextColor:[COStyle popoverTitleColor]];
	[self setInfoType:kCOFormulaInfoTypeGeneral];
}

- (void)setFormula:(COFormula *)formula
{
	if (_formula)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:kCOFormulaDidUpdateNotification
													  object:_formula];
	}
	
	_formula = formula;
	[_formulaTextView setString:@""];
	
	switch ([self infoType])
	{
		case kCOFormulaInfoTypeGeneral:
		{
			NSString *titleFormat = NSLocalizedString(@"Formula_Popover_Title", nil);
			[self.formulaTitleLabel setStringValue:[NSString stringWithFormat:titleFormat, [formula name]]];

			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateView:)
														 name:kCOFormulaDidUpdateNotification
													   object:formula];

			dispatch_async(dispatch_get_main_queue(), ^{
				[self displayConsoleInformationForFormula];
			});

			dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);

			[self.timedDispatch scheduleDispatchAfterTimeInterval:0.3 inQueue:bgQueue ofBlock:
				^{
					[formula setNeedsInformation:YES];
				}];
		}
		break;

		case kCOFormulaInfoTypeInstalledDependents:
		case kCOFormulaInfoTypeAllDependents:
			[self displayDependentsInformationForFormula];
			break;
	}
	
}

- (NSString *)nibName
{
	return @"COFormulaPopoverView";
}

- (void)updateView:(NSNotification *)notification
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self displayConsoleInformationForFormula];
	});
}

- (void)displayConsoleInformationForFormula
{
	NSString *string = self.formula.information;
	if (string) {
		[self.progressIndicator stopAnimation:nil];
		[self.formulaTextView setString:string];
		
		// Recognize links in info text
		[self.formulaTextView setEditable:YES];
		[self.formulaTextView checkTextInDocument:nil];
		[self.formulaTextView setEditable:NO];
		
		[self.formulaTextView scrollToBeginningOfDocument:nil];
	}
}

- (void)displayDependentsInformationForFormula
{
	NSString *name = [self.formula name];

    self.formulaTextView.string = @"";
	[self.progressIndicator startAnimation:nil];

	if (self.infoType == kCOFormulaInfoTypeInstalledDependents)
	{
        self.formulaTitleLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Formula_Installed_Dependents_Title", nil), name];

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			NSString *string = [[COHomebrewInterface sharedInterface] dependentsWithFormulaName:name installed:YES];

			dispatch_async(dispatch_get_main_queue(), ^{
				[self.progressIndicator stopAnimation:nil];
                self.formulaTextView.string = string;
				[self.formulaTextView scrollToBeginningOfDocument:nil];
                self.formulaTextView.needsDisplay = YES;
			});
		});
	}
	else if (self.infoType == kCOFormulaInfoTypeAllDependents)
	{
		[self.formulaTitleLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Formula_All_Dependents_Title", nil), name]];

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			NSString *string = [[COHomebrewInterface sharedInterface] dependentsWithFormulaName:name installed:NO];

			dispatch_async(dispatch_get_main_queue(), ^{
				[self.progressIndicator stopAnimation:nil];
                self.formulaTextView.string = string;
				[self.formulaTextView scrollToBeginningOfDocument:nil];
                self.formulaTextView.needsDisplay = YES;
			});

		});
	}
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
