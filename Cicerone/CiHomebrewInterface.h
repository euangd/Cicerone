//
//	BrewInterface.h
//	Cicerone – The Homebrew GUI App for OS X
//
//	Created by Vincent Saluzzo on 06/12/11.
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
#import <Cocoa/Cocoa.h>
#import "CiFormula.h"

typedef NS_ENUM(NSInteger, CiListMode) {
	kCiListModeAllFormulae,
	kCiListModeInstalledFormulae,
	kCiListModeLeaves,
	kCiListModeOutdatedFormulae,
	kCiListModeSearchFormulae, /* Don't call -[CiHomebrewInterface listMode:] with this parameter. */
    
	kCiListModeRepositories,
	
	kCiListModeAllCasks,
	kCiListModeInstalledCasks,
	kCiListModeOutdatedCasks,
	kCiListModeSearchCasks
};

@protocol CiHomebrewInterfaceDelegate <NSObject>

/**
 *  Caled when the formulae cache has been updated.
 */
- (void)homebrewInterfaceChangedDependedHomebrewPrefixState;

/**
 *  Called if homebrew is not detected in the system.
 *
 *  @param yesOrNo `YES` if brew was not found.
 */
- (void)homebrewInterfaceDidNotFindBrew:(BOOL)yesOrNo;

@end

@interface CiHomebrewInterface : NSObject <CiFormulaDataProvider>

+ (instancetype)sharedInterface;
+ (instancetype)alloc __attribute__((unavailable("alloc not available, call sharedInterface instead")));
- (instancetype)init __attribute__((unavailable("init not available, call sharedInterface instead")));
+ (instancetype)new __attribute__((unavailable("new not available, call sharedInterface instead")));

/**
 *  The delegate object.
 */
@property (weak, nonatomic) id<CiHomebrewInterfaceDelegate> delegate;

@property (strong, getter=getHomebrewPrefixPath, readonly) NSString *homebrewPrefixPath;

@property (strong, getter=getValidUserShellPath, readonly) NSString *shellPath;

@property (strong, getter=checkForBrew, readonly) NSString *brewPath;

#pragma mark - Operations with live data callback block

/**
 *  Terminates all running tasks
 */

/**
 *  Update Homebrew.
 *
 *  @param block Data callback block. This block will be called with new data to be diplayed while the process runs.
 *
 *  @return `YES` if successful.
 */
- (NSString *)update;

/**
 *  Upgrade parameter formulae to the latest available version.
 *
 *  @param formulae The list of formulae to be upgraded.
 *  @param block	Data callback block. This block will be called with new data to be diplayed while the process runs.
 *
 *  @return `YES` if successful.
 */
- (NSString *)upgradeWithFormulaeNames:(NSArray *)formulae;

/**
 *  Install formula with options.
 *
 *  @param formula The formula to be installed.
 *  @param options Options for the formula installation (as explained in the info for a formula).
 *  @param block   Data callback block. This block will be called with new data to be diplayed while the process runs.
 *
 *  @return `YES` if successful.
 */
- (NSString *)installWithFormulaName:(NSString *)formula withOptions:(NSArray*)options;

/**
 *  Uninstalls a formula.
 *
 *  @param formula The formula to be uninstalled.
 *  @param block   Data callback block. This block will be called with new data to be diplayed while the process runs.
 *
 *  @return `YES` if successful.
 */
- (NSString *)uninstallWithFormulaName:(NSString *)formula;

/**
 *  Taps a repo.
 *
 *  @param repository The repo to be tapped.
 *  @param block Data callback block. This block will be called with new data to be diplayed while the process runs.
 *
 *  @return `YES` if successful.
 */
- (NSString *)tapWithRepositoryName:(NSString *)repository;

/**
 *  Untaps a repo.
 *
 *  @param repository The repo to be untapped.
 *  @param block Data callback block. This block will be called with new data to be diplayed while the process runs.
 *
 *  @return `YES` if successful.
 */
- (NSString *)untapWithRepositoryName:(NSString *)repository;

/**
 *  Runs Homebrew cleanup tool.
 *
 *  @param block Data callback block. This block will be called with new data to be diplayed while the process runs.
 *
 *  @return `YES` if successful.
 */
- (NSString *)cleanup;

/**
 *  Runs Homebrew doctor tool.
 *
 *  @param block Data callback block. This block will be called with new data to be diplayed while the process runs.
 *
 *  @return `YES` if successful.
 */
- (NSString *)doctor;

/**
 *  Runs Homebrew bundle dump tool. Will request instalation of Homebrew-Bundle tap if it is not already tapped.
 *
 *  @param path The path where to export the dump file.
 *
 *  @return `nil` on success (no output), or the error in case something goes wrong.
 */
- (NSError *)exportWithPath:(NSString *)path;

/**
 *  Runs Homebrew bundle import tool. Will request instalation of Homebrew-Bundle tap if it is not already tapped.
 *
 *  @param path The path where to export the dump file.
 *  @param block Data callback block. This block will be called with new data to be diplayed while the process runs.
 *
 *  @return `YES` on success, `NO` otherwise.
 */
- (NSString *)importWithPath:(NSString *)path;

#pragma mark - Operations that return on finish

/**
 *  Lists all formulae that fits the description of the parameter mode.
 *
 *  @param mode All, Installed, Leaves, Outdated, etc.
 *
 *  @return List of CiFormula objects.
 */
- (NSArray*)packagesWithMode:(CiListMode)mode;

/**
 *  Executes `brew info` for parameter formula name.
 *
 *  @param name The name of the formula.
 *
 *  @return The information for the parameter formula as output by Homebrew.
 */
- (NSString *)informationWithFormulaName:(NSString *)name cask:(BOOL)isCask;

/**
 *  Executes `brew uses` for parameter formula name.
 *
 *  @param name The name of the formula.
 *  @param onlyInstalled If should only show installed dependents.
 *
 *  @return The list of dependents for the parameter formula as output by Homebrew.
 */
- (NSString *)dependentsWithFormulaName:(NSString *)name installed:(BOOL)onlyInstalled;

@end
