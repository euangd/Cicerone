//
//	CiHomebrewManager.h
//	Cicerone – The Homebrew GUI App for OS X
//
//	Created by Bruno Philipe on 4/3/14.
//	Copyright (c) 2014 Bruno Philipe. All rights reserved.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Foundation/Foundation.h>
#import "CiFormula.h"
#import "CiFormulaeDataSource.h"

@class CiHomebrewManager;

@protocol CiHomebrewManagerDelegate <NSObject>

- (void)homebrewManagerDidFinishUpdating:(CiHomebrewManager*)manager;
- (void)homebrewManager:(CiHomebrewManager *)manager didFinishSearchReturningSearchResults:(NSArray *)searchResults;
- (void)homebrewManager:(CiHomebrewManager *)manager didNotFindBrew:(BOOL)yesOrNo;

@end

@interface CiHomebrewManager : NSObject

@property (strong) NSArray<CiFormula *> *installedFormulae;
@property (strong) NSArray<CiFormula *> *outdatedFormulae;
@property (strong) NSArray<CiFormula *> *allFormulae;
@property (strong) NSArray<CiFormula *> *leavesFormulae;
@property (strong) NSArray<CiFormula *> *searchFormulae;
@property (strong) NSArray<CiFormula *> *repositoriesFormulae;

@property (strong) NSArray<CiFormula *> *installedCasks;
@property (strong) NSArray<CiFormula *> *outdatedCasks;
@property (strong) NSArray<CiFormula *> *allCasks;
@property (strong) NSArray<CiFormula *> *searchCasks;

@property (strong, nonatomic) CiFormulaeDataSource *formulaeDataSource;

// todo:
// installedPackages
// outdatedPackages
// allPackages
// ? leafPackages
// ? leafCasks
// searchPackages

@property (weak) id<CiHomebrewManagerDelegate> delegate;

+ (instancetype)sharedManager;
+ (instancetype)alloc __attribute__((unavailable("alloc not available, call sharedManager instead")));
- (instancetype)init __attribute__((unavailable("init not available, call sharedManager instead")));
+ (instancetype)new __attribute__((unavailable("new not available, call sharedManager instead")));

- (void)loadHomebrewStateWithCacheRebuild:(BOOL)shouldRebuildCache;
- (void)updateSearchWithName:(NSString *)name;

- (void)cleanUp;

@end
