//
//  COFormulaPopoverViewController.h
//  Bruh
//
//  Created by Marek Hrusovsky on 05/09/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "COFormula.h"

typedef NS_ENUM(NSInteger, COFormulaInfoType) {
	kCOFormulaInfoTypeGeneral,
	kCOFormulaInfoTypeInstalledDependents,
	kCOFormulaInfoTypeAllDependents
};

@interface COFormulaPopoverViewController : NSViewController

@property (strong) IBOutlet NSTextView *formulaTextView;
@property (weak) IBOutlet NSTextField *formulaTitleLabel;
@property (weak, nonatomic) COFormula *formula;
@property (weak) IBOutlet NSPopover *formulaPopover;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

@property COFormulaInfoType infoType;

@end
