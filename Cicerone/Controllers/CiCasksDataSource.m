//
//  CiCasksDataSource.m
//  Cicerone
//

#import "CiCasksDataSource.h"
#import "CiHomebrewManager.h"
#import "CiFormulaeTableView.h"

@interface CiCasksDataSource()
@property (nonatomic, strong) NSArray *CasksArray;
@end

@implementation CiCasksDataSource

- (instancetype)init
{
	return [self initWithMode:kCiListAllCasks];
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
		case kCiListAllCasks:
			_CasksArray = [[CiHomebrewManager sharedManager] allCasks];
			break;
			
		case kCiListInstalledCasks:
			_CasksArray = [[CiHomebrewManager sharedManager] installedCasks];
			break;
			
		case kCiListOutdatedCasks:
			_CasksArray = [[CiHomebrewManager sharedManager] outdatedCasks];
			break;
			
		case kCiListSearchCasks:
			_CasksArray = [[CiHomebrewManager sharedManager] searchCasks];
			break;
			
		default:
			break;
	}
}


#pragma mark - NSTableView DataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [self.CasksArray count];
}

- (CiFormula *)caskAtIndex:(NSInteger)index
{
	if ([self.CasksArray count] > index && index >= 0) {
		return [self.CasksArray objectAtIndex:index];
	}
	return nil;
}

- (NSArray *)casksAtIndexSet:(NSIndexSet *)indexSet
{
	if (indexSet.count > 0 && [self.CasksArray count] > indexSet.lastIndex) {
		return [self.CasksArray objectsAtIndexes:indexSet];
	}
	return nil;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	// the return value is typed as (id) because it will return a string in all cases with the exception of the
	if(self.CasksArray) {
		NSString *columnIdentifer = [tableColumn identifier];
		id element = [self.CasksArray objectAtIndex:(NSUInteger)row];
		
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
				switch ([[CiHomebrewManager sharedManager] statusForCask:element]) {
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
