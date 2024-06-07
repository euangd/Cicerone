//
//  COFormulaeDataSource.h
//  Cicerone
//
//  Created by Marek Hrusovsky on 04/09/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COHomebrewInterface.h"
#import "COFormula.h"

typedef NS_ENUM(NSInteger, COFormulaStatus) {
    kCOFormulaStatusNotInstalled,
    kCOFormulaStatusInstalled,
    kCOFormulaStatusOutdated
};

@interface COFormulaeDataSource : NSObject <NSTableViewDataSource>

@property (nonatomic, assign) COListMode mode;

- (instancetype)initWithMode:(COListMode)aMode;
- (COFormula *)formulaAtIndex:(NSInteger)index;
- (NSArray *)formulaeAtIndexSet:(NSIndexSet *)indexSet;
- (COFormulaStatus)statusForFormula:(COFormula *)formula;
- (void)refreshBackingArray;
@end
