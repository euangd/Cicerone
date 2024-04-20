//
//  CiFormulaPopoverViewController.h
//  Cicerone
//
//  Created by Marek Hrusovsky on 05/09/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CiFormula.h"

typedef NS_ENUM(NSInteger, CiFormulaInfoType) {
	kCiFormulaInfoTypeGeneral,
	kCiFormulaInfoTypeInstalledDependents,
	kCiFormulaInfoTypeAllDependents
};

@interface CiFormulaPopoverViewController : NSViewController

@property (strong) IBOutlet NSTextView *formulaTextView;
@property (weak) IBOutlet NSTextField *formulaTitleLabel;
@property (weak, nonatomic) CiFormula *formula;
@property (weak) IBOutlet NSPopover *formulaPopover;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

@property CiFormulaInfoType infoType;

@end
