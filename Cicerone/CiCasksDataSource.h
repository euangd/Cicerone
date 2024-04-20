//
//  CiCasksDataSource.h
//  Cicerone
//

#import <Foundation/Foundation.h>
#import "CiHomebrewInterface.h"
#import "CiFormula.h"

@interface CiCasksDataSource : NSObject <NSTableViewDataSource>

@property (nonatomic, assign) CiListMode mode;

- (instancetype)initWithMode:(CiListMode)aMode;
- (CiFormula *)caskAtIndex:(NSInteger)index;
- (NSArray *)casksAtIndexSet:(NSIndexSet *)indexSet;
- (void)refreshBackingArray;
@end
