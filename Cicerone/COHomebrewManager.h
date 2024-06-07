//
//	COHomebrewManager.h
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
#import "COFormula.h"
#import "COFormulaeDataSource.h"

@class COHomebrewManager;

@protocol COHomebrewManagerDelegate <NSObject>

- (void)homebrewManagerWillLoadHomebrewPrefixState:(COHomebrewManager *)manager;
- (void)homebrewManagerDidLoadHomebrewPrefixState:(COHomebrewManager *)manager;
- (void)homebrewManager:(COHomebrewManager *)manager didFinishSearchReturningSearchResults:(NSArray *)searchResults;
- (void)homebrewManager:(COHomebrewManager *)manager didNotFindBrew:(BOOL)yesOrNo;

@end

@interface COHomebrewManager : NSObject

@property (strong) NSArray<COFormula *> *installedFormulae;
@property (strong) NSArray<COFormula *> *outdatedFormulae;
@property (strong) NSArray<COFormula *> *allFormulae;
@property (strong) NSArray<COFormula *> *leavesFormulae;
@property (strong) NSArray<COFormula *> *searchFormulae;
@property (strong) NSArray<COFormula *> *repositoriesFormulae;

@property (strong) NSArray<COFormula *> *installedCasks;
@property (strong) NSArray<COFormula *> *outdatedCasks;
@property (strong) NSArray<COFormula *> *allCasks;
@property (strong) NSArray<COFormula *> *searchCasks;

@property (strong, nonatomic) COFormulaeDataSource *formulaeDataSource;

// todo:
// installedPackages
// outdatedPackages
// allPackages
// ? leafPackages
// ? leafCasks
// searchPackages

@property (weak) id<COHomebrewManagerDelegate> delegate;

+ (instancetype)sharedManager;
+ (instancetype)alloc __attribute__((unavailable("alloc not available, call sharedManager instead")));
- (instancetype)init __attribute__((unavailable("init not available, call sharedManager instead")));
+ (instancetype)new __attribute__((unavailable("new not available, call sharedManager instead")));

- (void)loadHomebrewPrefixState;
- (void)updateSearchWithName:(NSString *)name;

- (void)cleanUp;

@end
