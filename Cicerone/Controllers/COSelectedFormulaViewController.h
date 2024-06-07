//
//  COSelectedFormulaViewController.h
//  Cicerone
//
//  Created by Marek Hrusovsky on 05/09/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "COFormula.h"

@protocol COSelectedFormulaViewControllerDelegate <NSObject>

- (void)selectedFormulaViewDidUpdateFormulaInfoForFormula:(COFormula*)formula;

@end

@interface COSelectedFormulaViewController : NSViewController

@property (strong, nonatomic) NSArray *formulae;

@property (weak) id<COSelectedFormulaViewControllerDelegate> delegate;

@property (weak) IBOutlet NSTextField *formulaDescriptionLabel;
@property (weak) IBOutlet NSTextField *formulaPathLabel;
@property (weak) IBOutlet NSTextField *formulaVersionLabel;
@property (weak) IBOutlet NSTextField *formulaDependenciesLabel;
@property (weak) IBOutlet NSTextField *formulaConflictsLabel;

@end
