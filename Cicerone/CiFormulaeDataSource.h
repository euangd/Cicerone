//
//  CiFormulaeDataSource.h
//  Cicerone
//
//  Created by Marek Hrusovsky on 04/09/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CiHomebrewInterface.h"
#import "CiFormula.h"

typedef NS_ENUM(NSInteger, CiFormulaStatus) {
    kCiFormulaStatusNotInstalled,
    kCiFormulaStatusInstalled,
    kCiFormulaStatusOutdated
};

@interface CiFormulaeDataSource : NSObject <NSTableViewDataSource>

@property (nonatomic, assign) CiListMode mode;

- (instancetype)initWithMode:(CiListMode)aMode;
- (CiFormula *)formulaAtIndex:(NSInteger)index;
- (NSArray *)formulaeAtIndexSet:(NSIndexSet *)indexSet;
- (CiFormulaStatus)statusForFormula:(CiFormula *)formula;
- (void)refreshBackingArray;
@end
