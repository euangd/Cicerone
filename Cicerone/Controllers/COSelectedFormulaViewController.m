//
//  COSelectedFormulaViewController.m
//  Bruh
//
//  Created by Marek Hrusovsky on 05/09/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import "COSelectedFormulaViewController.h"
#import "BPTimedDispatch.h"

@interface COSelectedFormulaViewController ()

@property (strong) BPTimedDispatch *timedDispatch;

@end

@implementation COSelectedFormulaViewController

- (void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updatePreferedWidth:)
												 name:NSViewFrameDidChangeNotification
											   object:self.view];
	
    self.timedDispatch = [BPTimedDispatch new];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updatePreferedWidth:(id)sender
{
	if ([self.formulaDependenciesLabel respondsToSelector:@selector(preferredMaxLayoutWidth)])
	{
		self.formulaDescriptionLabel.preferredMaxLayoutWidth    = self.formulaDescriptionLabel.frame.size.width;
		self.formulaDependenciesLabel.preferredMaxLayoutWidth	= self.formulaDependenciesLabel.frame.size.width;
		self.formulaConflictsLabel.preferredMaxLayoutWidth		= self.formulaConflictsLabel.frame.size.width;
		self.formulaVersionLabel.preferredMaxLayoutWidth		= self.formulaVersionLabel.frame.size.width;
		self.formulaPathLabel.preferredMaxLayoutWidth			= self.formulaPathLabel.frame.size.width;
		[[self view] layoutSubtreeIfNeeded];
	}
}

- (NSString *)nibName
{
	return @"COSelectedFormulaView";
}

- (void)setFormulae:(NSArray *)formulae
{
	for (COFormula *formula in _formulae) {
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:kCOFormulaDidUpdateNotification
													  object:formula];
	}
	_formulae = formulae;
	for (COFormula *formula in formulae) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updateFormulaInformation:)
													 name:kCOFormulaDidUpdateNotification
												   object:formula];
	}
	[self displayInformationForFormulae];
	[self.timedDispatch scheduleDispatchAfterTimeInterval:0.3
												  inQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
												  ofBlock:^
    {
        COFormula *formula = [self.formulae firstObject];
        formula.needsInformation = YES;
    }];
}

- (void)updateFormulaInformation:(NSNotification *)notification
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self displayInformationForFormulae];
	});
}

- (void)displayInformationForFormulae
{
	static NSString *emptyString = @"--";
	
	NSString *multipleString = NSLocalizedString(@"Info_View_Multiple_Values", nil);
	
	if (!self.formulae || [self.formulae count] == 0)
	{
        self.formulaDescriptionLabel.stringValue = emptyString;
        self.formulaPathLabel.stringValue = emptyString;
        self.formulaVersionLabel.stringValue = emptyString;
        self.formulaDependenciesLabel.stringValue = emptyString;
        self.formulaConflictsLabel.stringValue = emptyString;
	}
	
	if ([self.formulae count] == 1)
	{
		COFormula *formula = [self.formulae firstObject];
		
		if (formula.isInstalled)
		{
			if ([formula.installPath length])
			{
                self.formulaPathLabel.stringValue = formula.installPath;
			}
			else
			{
                self.formulaPathLabel.stringValue = emptyString;
			}
		}
		else
		{
            self.formulaPathLabel.stringValue = NSLocalizedString(@"Info_View_Formula_Not_Installed", nil);
		}
		
		if (formula.latestVersion)
		{
            self.formulaVersionLabel.stringValue = formula.latestVersion;
		}
		else
		{
            self.formulaVersionLabel.stringValue = emptyString;
		}
		
		if (formula.dependencies)
		{
            self.formulaDependenciesLabel.stringValue = formula.dependencies;
		}
		else
		{
            self.formulaDependenciesLabel.stringValue = NSLocalizedString(@"Info_View_Formula_No_Dependencies", nil);
		}
		
		if (formula.conflicts)
		{
            self.formulaConflictsLabel.stringValue = formula.conflicts;
		}
		else
		{
            self.formulaConflictsLabel.stringValue = NSLocalizedString(@"Info_View_Formula_No_Conflicts", nil);
		}
		
		if (formula.shortDescription)
		{
            self.formulaDescriptionLabel.stringValue = formula.shortDescription;
		}
		else
		{
            self.formulaDescriptionLabel.stringValue = NSLocalizedString(@"Info_View_Formula_No_Description", nil);
		}
		
		if ([self.delegate respondsToSelector:@selector(selectedFormulaViewDidUpdateFormulaInfoForFormula:)])
		{
			[self.delegate selectedFormulaViewDidUpdateFormulaInfoForFormula:formula];
		}
		
		if ([self.formulae count] > 1)
		{
            self.formulaPathLabel.stringValue = multipleString;
            self.formulaDependenciesLabel.stringValue = multipleString;
            self.formulaConflictsLabel.stringValue = multipleString;
            self.formulaVersionLabel.stringValue = multipleString;
		}
	}
}

@end
