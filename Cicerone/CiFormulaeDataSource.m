//
//  CiFormulaeDataSource.m
//  Cicerone
//
//  Created by Marek Hrusovsky on 04/09/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import "CiFormulaeDataSource.h"
#import "CiHomebrewManager.h"
#import "CiFormulaeTableView.h"

@interface CiFormulaeDataSource()
@property (nonatomic, strong) NSArray *formulaeArray;
@end

@implementation CiFormulaeDataSource

- (instancetype)init
{
	return [self initWithMode:kCiListModeAllFormulae];
}

- (instancetype)initWithMode:(CiListMode)aMode
{
	self = [super init];
	if (self) {
        // this used to also refresh the backing array via the mode setter
//        self.mode = aMode;
        _mode = aMode;
    }
	return self;
}

- (void)setMode:(CiListMode)mode
{
	_mode = mode;
	[self refreshBackingArray];
}

- (void)refreshBackingArray
{
	switch (self.mode) {
		case kCiListModeAllFormulae:
			_formulaeArray = [[CiHomebrewManager sharedManager] allFormulae];
			break;
			
		case kCiListModeInstalledFormulae:
			_formulaeArray = [[CiHomebrewManager sharedManager] installedFormulae];
			break;
			
		case kCiListModeLeaves:
			_formulaeArray = [[CiHomebrewManager sharedManager] leavesFormulae];
			break;
			
		case kCiListModeOutdatedFormulae:
			_formulaeArray = [[CiHomebrewManager sharedManager] outdatedFormulae];
			break;
			
		case kCiListModeSearchFormulae:
			_formulaeArray = [[CiHomebrewManager sharedManager] searchFormulae];
			break;
			
		case kCiListModeRepositories:
			_formulaeArray = [[CiHomebrewManager sharedManager] repositoriesFormulae];
            break;
            
        case kCiListModeAllCasks:
            _formulaeArray = [[CiHomebrewManager sharedManager] allCasks];
            break;
            
        case kCiListModeInstalledCasks:
            _formulaeArray = [[CiHomebrewManager sharedManager] installedCasks];
            break;
            
        case kCiListModeOutdatedCasks:
            _formulaeArray = [[CiHomebrewManager sharedManager] outdatedCasks];
            break;
            
        case kCiListModeSearchCasks:
            _formulaeArray = [[CiHomebrewManager sharedManager] searchCasks];
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

- (CiFormula *)formulaAtIndex:(NSInteger)index
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

- (NSInteger)searchForFormula:(CiFormula*)formula inArray:(NSArray*)array
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

// temporary measure (ha ha... i mean it)

- (CiFormulaStatus)statusForFormula:(CiFormula *)formula {
    BOOL cask = self.mode >= kCiListModeAllCasks;
    
    if ([self searchForFormula:formula inArray:cask ? CiHomebrewManager.sharedManager.installedCasks : CiHomebrewManager.sharedManager.installedFormulae] >= 0) {
        if ([self searchForFormula:formula inArray:cask ? CiHomebrewManager.sharedManager.outdatedCasks : CiHomebrewManager.sharedManager.outdatedFormulae] >= 0) {
            return kCiFormulaStatusOutdated;
        } else {
            return kCiFormulaStatusInstalled;
        }
    } else {
        return kCiFormulaStatusNotInstalled;
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
			if ([element isKindOfClass:[CiFormula class]]) {
				return [(CiFormula*)element name];
			} else {
				return element;
			}
		} else if ([columnIdentifer isEqualToString:kColumnIdentifierVersion]) {
			if ([element isKindOfClass:[CiFormula class]]) {
				return [(CiFormula*)element version];
			} else {
				return element;
			}
		} else if ([columnIdentifer isEqualToString:kColumnIdentifierLatestVersion]) {
			if ([element isKindOfClass:[CiFormula class]]) {
				return [(CiFormula*)element shortLatestVersion];
			} else {
				return element;
			}
		} else if ([columnIdentifer isEqualToString:kColumnIdentifierStatus]) {
			if ([element isKindOfClass:[CiFormula class]]) {
				switch ([self statusForFormula:element]) {
					case kCiFormulaStatusInstalled:
						return NSLocalizedString(@"Formula_Status_Installed", nil);
						
					case kCiFormulaStatusNotInstalled:
						return NSLocalizedString(@"Formula_Status_Not_Installed", nil);
						
					case kCiFormulaStatusOutdated:
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
