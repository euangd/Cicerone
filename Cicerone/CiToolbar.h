//
//  CiToolbar.h
//  Cicerone
//
//  Created by Marek Hrusovsky on 16/08/15.
//	Copyright (c) 2014 Bruno Philipe. All rights reserved.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program.	If not, see <http://www.gnu.org/licenses/>.
//

#import <Cocoa/Cocoa.h>

extern NSString *const kToolbarIdentifier;

extern NSString *const kToolbarItemBrewUpdateToolIdentifier;
extern NSString *const kToolbarItemBrewInfoToolIdentifier;
extern NSString *const kToolbarItemSearchIdentifier;
extern NSString *const kToolbarItemBewTapToolIdentifier;
extern NSString *const kToolbarItemRemoveListingIdentifier;
extern NSString *const kToolbarItemInstallLatestPackageVersionIdentifier;
extern NSString *const kToolbarItemConfigurePackageOptionsIdentifier;

@protocol CiToolbarProtocol <NSObject>

@required

- (IBAction)upgradeSelectedFormulae:(id)sender;
- (IBAction)showSelectedFormulaInfo:(id)sender;
- (IBAction)tap:(id)sender;
- (IBAction)removeSelectedListing:(id)sender;
- (IBAction)untapSelectedRepository:(id)sender;
- (IBAction)installSelectedFormula:(id)sender;
- (IBAction)installSelectedFormulaWithOptions:(id)sender;
- (IBAction)uninstallSelectedFormula:(id)sender;
- (IBAction)update:(id)sender;

- (void)performSearchWithString:(NSString *)search;

- (void)actualizeToolbarItem:(NSToolbarItem *)item;

@end

@interface CiToolbar : NSToolbar <NSToolbarDelegate, NSToolbarItemValidation>

// bar use mode, as in the mode which affects how the bar would be used

typedef NS_ENUM(NSUInteger, CiToolbarMode)
{
	kCiToolbarModeDud,
    
    /// any page, nothing selected
	kCiToolbarModeCore,
    
	kCiToolbarModeNotInstalledPackage,
	kCiToolbarModeInstalledPackage,
    
	kCiToolbarModeOutdatedPackage,
    
    /// added taps page, nothing selected
	kCiToolbarModeTap,
	kCiToolbarModeTappedRepository
};

@property (nonatomic) CiToolbarMode mode;

@property (nonatomic, weak) id homebrewViewController;

- (void)showSearch;
- (NSSearchField *)searchField;

- (void)actualizeVisibleItems;
- (void)actualizeToolbarItem:(NSToolbarItem *)item;

@end
