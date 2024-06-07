//
//	HomebrewController.h
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
#import <PXSourceList/PXSourceList.h>
#import "CiFormula.h"
#import "CiFormulaeTableView.h"
#import "CiFormulaPopoverViewController.h"
#import "CiSideBarController.h"

typedef NS_ENUM(NSUInteger, CiWindowOperation) {
	kCiWindowOperationInstall,
	kCiWindowOperationUninstall,
	kCiWindowOperationUpgrade,
	kCiWindowOperationTap,
	kCiWindowOperationUntap,
	kCiWindowOperationCleanup
};

@class CiUpdateDoctorController;

@interface CiHomebrewViewController : NSViewController

@property (weak) IBOutlet CiSideBarController      *sidebarController;
@property (weak) IBOutlet CiFormulaeTableView      *formulaeTableView;
@property (weak) IBOutlet NSScrollView             *scrollView_formulae;
@property (weak) IBOutlet NSTabView                *tabView;
@property (weak) IBOutlet NSTextField              *informationTextField;
@property (weak) IBOutlet NSMenu                   *menu_formula;

// Cocoa bindings
@property (readonly) BOOL hasUpgrades; // todo: possibly make this just read upgrade count directly instead of waiting for -hombrewManagerDidFinishUpdating:
@property (readonly, getter=isSearching) BOOL searching;
@property (readonly, getter=isListingPackages) BOOL listingPackages;
@property (readonly, getter=isHomebrewInstalled) BOOL homebrewInstalled; // used to have -isHomebrewInstalled selector separately, then ~synthesized into property with getter= for implementation (on empty category interface)


/// Locks to Current Content
@property (nonatomic) BOOL lock;
/// Locks to Loading Screen
@property (nonatomic) BOOL loading;

@property (nonatomic, readonly) CiFormula *selectedFormula; // used to be (copy) but then -[setSelectedFormula:] would freeze, at least when @synchronized (self) up the call stack

- (IBAction)showSelectedFormulaInfo:(id)sender;
- (IBAction)installSelectedFormulaWithOptions:(id)sender;
- (IBAction)upgradeSelectedFormulae:(id)sender;
- (IBAction)upgradeAllOutdatedFormulae:(id)sender;
- (IBAction)openSelectedFormulaWebsite:(id)sender;
- (IBAction)beginFormulaSearch:(id)sender;
- (IBAction)runHomebrewCleanup:(id)sender;
- (IBAction)runHomebrewExport:(id)sender;
- (IBAction)runHomebrewImport:(id)sender;

@end
