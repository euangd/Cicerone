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
	return [self initWithMode:kCiListAllFormulae];
}

- (instancetype)initWithMode:(CiListMode)aMode
{
	self = [super init];
	if (self) {
		_mode = aMode;
	}
	[self refreshBackingArray];
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
		case kCiListAllFormulae:
			_formulaeArray = [[CiHomebrewManager sharedManager] allFormulae];
			break;
			
		case kCiListInstalledFormulae:
			_formulaeArray = [[CiHomebrewManager sharedManager] installedFormulae];
			break;
			
		case kCiListLeaves:
			_formulaeArray = [[CiHomebrewManager sharedManager] leavesFormulae];
			break;
			
		case kCiListOutdatedFormulae:
			_formulaeArray = [[CiHomebrewManager sharedManager] outdatedFormulae];
			break;
			
		case kCiListSearchFormulae:
			_formulaeArray = [[CiHomebrewManager sharedManager] searchFormulae];
			break;
			
		case kCiListRepositories:
			_formulaeArray = [[CiHomebrewManager sharedManager] repositoriesFormulae];
			
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

- (NSArray *)formulasAtIndexSet:(NSIndexSet *)indexSet
{
	if (indexSet.count > 0 && [self.formulaeArray count] > indexSet.lastIndex) {
		return [self.formulaeArray objectsAtIndexes:indexSet];
	}
	return nil;
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
				switch ([[CiHomebrewManager sharedManager] statusForFormula:element]) {
					case kCiFormulaInstalled:
						return NSLocalizedString(@"Formula_Status_Installed", nil);
						
					case kCiFormulaNotInstalled:
						return NSLocalizedString(@"Formula_Status_Not_Installed", nil);
						
					case kCiFormulaOutdated:
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
