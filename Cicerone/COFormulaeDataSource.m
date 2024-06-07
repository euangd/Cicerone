//
//  COFormulaeDataSource.m
//  Cicerone
//
//  Created by Marek Hrusovsky on 04/09/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import "COFormulaeDataSource.h"
#import "COHomebrewManager.h"
#import "COFormulaeTableView.h"

@interface COFormulaeDataSource()
@property (nonatomic, strong) NSArray *formulaeArray;
@end

@implementation COFormulaeDataSource

- (instancetype)init
{
	return [self initWithMode:kCOListModeAllFormulae];
}

- (instancetype)initWithMode:(COListMode)aMode
{
	self = [super init];
	if (self) {
        // this used to also refresh the backing array via the mode setter
//        self.mode = aMode;
        _mode = aMode;
    }
	return self;
}

- (void)setMode:(COListMode)mode
{
	_mode = mode;
	[self refreshBackingArray];
}

- (void)refreshBackingArray
{
	switch (self.mode) {
		case kCOListModeAllFormulae:
			_formulaeArray = [[COHomebrewManager sharedManager] allFormulae];
			break;
			
		case kCOListModeInstalledFormulae:
			_formulaeArray = [[COHomebrewManager sharedManager] installedFormulae];
			break;
			
		case kCOListModeLeaves:
			_formulaeArray = [[COHomebrewManager sharedManager] leavesFormulae];
			break;
			
		case kCOListModeOutdatedFormulae:
			_formulaeArray = [[COHomebrewManager sharedManager] outdatedFormulae];
			break;
			
		case kCOListModeSearchFormulae:
			_formulaeArray = [[COHomebrewManager sharedManager] searchFormulae];
			break;
			
		case kCOListModeRepositories:
			_formulaeArray = [[COHomebrewManager sharedManager] repositoriesFormulae];
            break;
            
        case kCOListModeAllCasks:
            _formulaeArray = [[COHomebrewManager sharedManager] allCasks];
            break;
            
        case kCOListModeInstalledCasks:
            _formulaeArray = [[COHomebrewManager sharedManager] installedCasks];
            break;
            
        case kCOListModeOutdatedCasks:
            _formulaeArray = [[COHomebrewManager sharedManager] outdatedCasks];
            break;
            
        case kCOListModeSearchCasks:
            _formulaeArray = [[COHomebrewManager sharedManager] searchCasks];
            break;
            
		default:
			break;
	}
}


#pragma mark - NSTableView DataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [self.formulaeArray count];
}

- (COFormula *)formulaAtIndex:(NSInteger)index
{
	if ([self.formulaeArray count] > index && index >= 0) {
		return [self.formulaeArray objectAtIndex:index];
	}
	return nil;
}

- (NSArray *)formulaeAtIndexSet:(NSIndexSet *)indexSet
{
	if (indexSet.count > 0 && [self.formulaeArray count] > indexSet.lastIndex) {
		return [self.formulaeArray objectsAtIndexes:indexSet];
	}
	return nil;
}

- (NSInteger)searchForFormula:(COFormula*)formula inArray:(NSArray*)array
{
    __block NSUInteger index = -1;
    
    [array enumerateObjectsUsingBlock:^(id _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[item installedName] isEqualToString:[formula installedName]])
        {
            index = idx;
            (*stop) = YES;
        }
    }];
    
    return index;
}


- (COFormulaStatus)statusForFormula:(COFormula *)formula {
    BOOL cask = formula.isCask;
    
    // temporary measure (ha ha... i mean it)... (I apparently actually meant it?????)
    //self.mode >= kCOListModeAllCasks;
    
    if ([self searchForFormula:formula inArray:cask ? COHomebrewManager.sharedManager.installedCasks : COHomebrewManager.sharedManager.installedFormulae] >= 0) {
        if ([self searchForFormula:formula inArray:cask ? COHomebrewManager.sharedManager.outdatedCasks : COHomebrewManager.sharedManager.outdatedFormulae] >= 0) {
            return kCOFormulaStatusOutdated;
        } else {
            return kCOFormulaStatusInstalled;
        }
    } else if ([self searchForFormula:formula inArray:COHomebrewManager.sharedManager.repositoriesFormulae] >= 0) { // todo: have ListingKind or something
        return kCOFormulaStatusInstalled;
    } else {
        return kCOFormulaStatusNotInstalled;
    }
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	// the return value is typed as (id) because it will return a string in all cases with the exception of the
	if(self.formulaeArray) {
		NSString *columnIdentifer = [tableColumn identifier];
		id element = [self.formulaeArray objectAtIndex:(NSUInteger)row];
		
		// Compare each column identifier and set the return value to
		// the Person field value appropriate for the column.
		if ([columnIdentifer isEqualToString:kColumnIdentifierName]) {
			if ([element isKindOfClass:[COFormula class]]) {
				return [(COFormula *)element name];
			} else {
				return element;
			}
		} else if ([columnIdentifer isEqualToString:kColumnIdentifierVersion]) {
			if ([element isKindOfClass:[COFormula class]]) {
				return [(COFormula *)element version];
			} else {
				return element;
			}
		} else if ([columnIdentifer isEqualToString:kColumnIdentifierLatestVersion]) {
			if ([element isKindOfClass:[COFormula class]]) {
				return [(COFormula *)element shortLatestVersion];
			} else {
				return element;
			}
		} else if ([columnIdentifer isEqualToString:kColumnIdentifierStatus]) {
			if ([element isKindOfClass:[COFormula class]]) {
				switch ([self statusForFormula:element]) {
					case kCOFormulaStatusInstalled:
						return NSLocalizedString(@"Formula_Status_Installed", nil);
						
					case kCOFormulaStatusNotInstalled:
						return NSLocalizedString(@"Formula_Status_Not_Installed", nil);
						
					case kCOFormulaStatusOutdated:
						return NSLocalizedString(@"Formula_Status_Outdated", nil);
						
					default:
						return @"";
				}
			} else {
				return element;
			}
		}
	}
	
	return @"";
}

@end
